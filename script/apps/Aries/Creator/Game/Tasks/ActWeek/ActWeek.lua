
--[[
Title: ActWeek
Author(s): yangguiyi
Date: 2020/12/30
Desc:  
Use Lib:
-------------------------------------------------------
local ActWeek = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActWeek/ActWeek.lua")
ActWeek.ShowView()
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local ActWeek = NPL.export()
local server_time = 0
ActWeek.act_gisd = 90001
ActWeek.GetRewardState = {
    can_not = 1,    -- 待完成
    can_get = 2,    -- 可领取
    has_get = 3,    -- 已领取
}

ActWeek.ActState = {
    not_start = 1,  --活动未开启
    going = 2,      --活动进行中
    act_end = 3,    --活动已结束
}

ActWeek.ExidList = {
    30009,
    30010,
}

ActWeek.InitData = {
    {get_reward_state = ActWeek.GetRewardState.can_not},
    {get_reward_state = ActWeek.GetRewardState.can_not},
    timestamp = 0,
}

ActWeek.poster = {{}}
local page

function ActWeek.OnInit()
	page = document:GetPageCtrl();
end

function ActWeek.closeView()
    -- body
end

function ActWeek.ShowView()
    local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(ActWeek.act_gisd)
    if not bOwn then
        return
    end
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.promotion.weekend')
    keepwork.user.server_time({},function(err, msg, data)
        server_time = ActWeek.GetTimeStamp(data.now)
        local act_state = ActWeek.GetActState()
        if act_state ~= ActWeek.ActState.going then
            if act_state == ActWeek.ActState.not_start then
                GameLogic.AddBBS(nil, L"活动尚未开始，敬请关注");
            end
            if act_state == ActWeek.ActState.act_end then
                GameLogic.AddBBS(nil, L"活动已结束，感谢您的参与");
            end
            return
        end

        local view_width = 870
        local view_height = 523
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/ActWeek/ActWeek.html",
            name = "ActWeek.ShowView", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = true,
            enable_esc_key = true,
            zorder = 0,
            app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
            directPosition = true,
                align = "_ct",
                x = -view_width/2 - 80,
                y = -view_height/2,
                width = view_width,
                height = view_height,
        };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
    end)
end

function ActWeek.FlushView()
    if page and page:IsVisible() then
        page:Refresh(0)
    end
end

function ActWeek.GetReward(index)
    if index == nil then
        return
    end
    index = tonumber(index)
    local reward_state = ActWeek.GetGetRewardState(index)
    if reward_state ~= ActWeek.GetRewardState.can_get then
        return
    end

    local exid = ActWeek.ExidList[index]
    if exid == nil then
        return
    end

    KeepWorkItemManager.DoExtendedCost(exid,function()
        GameLogic.AddBBS(nil, L"领取成功");
        local client_data = KeepWorkItemManager.GetClientData(ActWeek.act_gisd);
        client_data[index].get_reward_state = ActWeek.GetRewardState.has_get

        KeepWorkItemManager.SetClientData(ActWeek.act_gisd, client_data, function()
            if ActWeek then
                ActWeek.FlushView()
            end
        end)
    end)
end

function ActWeek.GetGetRewardState(index)
    local client_data = KeepWorkItemManager.GetClientData(ActWeek.act_gisd);
    -- 没数据说明还没完成过任务
    if client_data == nil or client_data[1] == nil then
        return ActWeek.GetRewardState.can_not
    end

    if client_data[index] then
        return client_data[index].get_reward_state
    end

    return ActWeek.GetRewardState.can_not
end

-- ActWeek.ActState = {
--     not_start = 1,  --活动未开启
--     going = 2,      --活动进行中
--     act_end = 3,    --活动已结束
-- }
function ActWeek.GetActState()
    local act_item = KeepWorkItemManager.GetItemTemplate(ActWeek.act_gisd)
    if nil == act_item then
        return ActWeek.ActState.act_end
    end

    local extra = act_item.extra or {}
    
    local start_time_t = ActWeek.StringToTable(extra.act_start_time)
    local end_time_t = ActWeek.StringToTable(extra.act_end_time)
    local start_timestamp = os.time(start_time_t)
    local end_timestamp = os.time(end_time_t)
    if server_time < start_timestamp then
        return ActWeek.ActState.not_start
    end

    if server_time >= end_timestamp then
        return ActWeek.ActState.act_end
    end

    return ActWeek.ActState.going
end

function ActWeek.GetServerTime(callback)
    keepwork.user.server_time({}, function(err, msg, data)
        server_time = ActWeek.GetTimeStamp(data.now)
        if callback then
            callback()
        end
    end)
end

-- 完成活动目标
function ActWeek.AchieveActTarget()
    -- 得先判断有没登录
    if(not GameLogic.GetFilters():apply_filters('is_signed_in'))then
        return
	end

    -- 判断任务状态
    local client_data = KeepWorkItemManager.GetClientData(ActWeek.act_gisd);
    if client_data == nil or client_data[1] == nil then
        client_data = ActWeek.InitData
    end

    -- 这两个任务是会同时完成的 所以只要有一个不是未完成状态 就说明两个都完成过了
    local reward_state = client_data[1].get_reward_state
    if reward_state ~= ActWeek.GetRewardState.can_not then
        return
    end

    keepwork.user.server_time({}, function(err, msg, data)
        server_time = ActWeek.GetTimeStamp(data.now)

        local act_state = ActWeek.GetActState()
        if act_state ~= ActWeek.ActState.going then
            return
        end

        -- 判断是不是周末
        local week_day = ActWeek.GetWeekNum(server_time)
        if week_day ~= 6 and week_day ~= 7 then
        -- if week_day ~= 3 then
            return
        end

        client_data[1].get_reward_state = ActWeek.GetRewardState.can_get
        client_data[2].get_reward_state = ActWeek.GetRewardState.can_get

        KeepWorkItemManager.SetClientData(ActWeek.act_gisd, client_data, function()
            GameLogic.AddBBS(nil, L"恭喜你达成创造周末活动目标");
            if ActWeek then
                ActWeek.FlushView()
            end
        end)
    end)
end


--根据时间戳获取星期几
function ActWeek.GetWeekNum(time_stamp)
    time_stamp = time_stamp or 0
    local weekNum = os.date("*t",time_stamp).wday  -1
    if weekNum == 0 then
        weekNum = 7
    end
    return weekNum
end

function ActWeek.GetTimeStamp(at_time)
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    if httpwrapper_version == "RELEASE" or httpwrapper_version == "LOCAL" then
        return os.time()
    end

    if at_time == nil then
        return 0
    end
    -- at_time = "2020-09-09T06:52:43.000Z"
    local year, month, day, hour, min, sec = at_time:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
    local time_stamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour) + 8}) -- 这个时间是带时区的 要加8小时
    time_stamp = time_stamp + min * 60 + sec

    return time_stamp
end

function ActWeek.StringToTable(str)
    local tab = loadstring("return " .. str)
    return tab()
end

function ActWeek.OpenVipNotice()
    GameLogic.GetFilters():apply_filters("VipNotice", true, "vip_goods",function()
        if (KeepWorkItemManager.IsVip()) then
            local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
            KeepWorkMallPage.HandleDataSources()
            KeepWorkMallPage.FlushView()
        end
    end);
end