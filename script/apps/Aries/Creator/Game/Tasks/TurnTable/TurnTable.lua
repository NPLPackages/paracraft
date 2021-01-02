--[[
Title: TurnTable
Author(s): yangguiyi
Date: 2020/12/25
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TurnTable/TurnTable.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local TurnTable = NPL.export();
commonlib.setfield("MyCompany.Aries.Creator.Game.Tasks.TurnTable", TurnTable);
NPL.load("(gl)script/ide/Transitions/Tween.lua");

local ShowQuestionNum = 5
local ActCode = "lamp"

TurnTable.RewardData = {
    {exid = 30004, probility = 40, value = 0, bean_num = 10},
    {exid = 30006, probility = 12, value = 0, bean_num = 30},
    {exid = 30008, probility = 2, value = 0, bean_num = 50},
    {exid = 0, probility = 15, value = 0, bean_num = "明天再来"},
    {exid = 30007, probility = 6, value = 0, bean_num = 40},
    {exid = 30005, probility = 25, value = 0, bean_num = 20},
    
}

TurnTable.IsInDraw = false
TurnTable.DrawData = {}
local server_time = 0
TurnTable.DrawState = {
    can_draw = 1,
    can_not_draw = 2,
    has_draw = 3,
}
function TurnTable.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = TurnTable.CloseView
end

function TurnTable.Show()
    keepwork.user.server_time({}, function(err, msg, data)
        server_time = TurnTable.GetTimeStamp(data.now)
        TurnTable.ShowView()
    end)
end

function TurnTable.ShowView()
    if page and page:IsVisible() then
        return
    end
    TurnTable.radian = nil
    local profile = KeepWorkItemManager.GetProfile()
    local id = profile.id or 0
    TurnTable.IsInDraw = false
    TurnTable.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/TurnTable/TurnTable.html",
        name = "TurnTable.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -637/2,
        y = -583/2 + 20,
        width = 637,
        height = 583,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    local obj = page:GetNode("table")
    
    -- print("ddddddddddddddddd", obj, ParaUI.GetUIObject("table"))
    -- local testobj[x = obj]

    TurnTable.OnRefresh()
end

function TurnTable.FreshView()
    local parent  = page:GetParentUIObject()

	local left,top,width,hight=105,80,426,433;
    local bg_turntabl = ParaUI.CreateUIObject("container", "TurnTable.BG", "_lt", left,top,width,hight)
    bg_turntabl.background = "Texture/Aries/Creator/keepwork/TurnTable/yuanpan_426x433_32bits.png;0 0 426 433";
    bg_turntabl:SetField("ClickThrough", true);
    if TurnTable.radian then
        bg_turntabl.rotation = TurnTable.radian
    end
    parent:AddChild(bg_turntabl);
    
    local draw_bt = ParaUI.CreateUIObject("button", "TurnTable.DrawBt", "_lt", 266, 230, 106, 116);
    draw_bt.background = "Texture/Aries/Creator/keepwork/TurnTable/btn_choujiang_106x116_32bits.png; 0 0 106 116";
    draw_bt.onclick = ";MyCompany.Aries.Creator.Game.Tasks.TurnTable.StartDraw();";
    parent:AddChild(draw_bt);

    
    keepwork.user.server_time({}, function(err, msg, data)
        server_time = TurnTable.GetTimeStamp(data.now)

        local draw_bt = ParaUI.GetUIObject("TurnTable.DrawBt")
        local state = TurnTable.GetDrawState()
        if state == TurnTable.DrawState.can_draw then
            draw_bt.background = "Texture/Aries/Creator/keepwork/TurnTable/btn_choujiang_106x116_32bits.png; 0 0 106 116";
        elseif state == TurnTable.DrawState.can_not_draw then
            draw_bt.background = "Texture/Aries/Creator/keepwork/TurnTable/btn_choujiang2_106x116_32bits.png; 0 0 106 116";
            draw_bt.onclick = "";
        else
            draw_bt.background = "Texture/Aries/Creator/keepwork/TurnTable/btn_choujiang3_106x116_32bits.png; 0 0 106 116";
            draw_bt.onclick = "";
        end
    end)
end

function TurnTable.GetDesc()
    local state = TurnTable.GetDrawState()
    
    if state == TurnTable.DrawState.can_draw then
        return "你已获得1次猫头鹰幸运转盘抽奖机会，快点击下方抽奖按钮抽取幸运大奖吧！"
    elseif state == TurnTable.DrawState.can_not_draw then
        return "猫头鹰幸运转盘将在每天下午18:00之后开放，你只需要在下午18:00后登录帕拉卡即可获得幸运转盘的抽奖机会哦。"
    else
        return "你已完成今天的抽奖，请明天下午18:00之后再来吧！"
    end
end

function TurnTable.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    TurnTable.FreshView()
end

function TurnTable.CloseView()
    TurnTable.ClearData()
end

function TurnTable.ClearData()
    TurnTable.select_answer_list = {}
    TurnTable.act_data = {}
    TurnTable.id = 0
    -- TurnTable.Current_Item_DS = {}
end

function TurnTable.HandleData()
    local last_value= 0
    for i, v in ipairs(TurnTable.RewardData) do
        v.value = v.probility + last_value
        last_value = v.value
    end
end

function TurnTable.StartDraw()
    keepwork.user.server_time({}, function(err, msg, data)
        server_time = TurnTable.GetTimeStamp(data.now)
        if TurnTable.IsInDraw then
            return
        end

        math.randomseed(os.time())
        local random_num = math.random(1, 100)
        local index = nil
    
        for i, v in ipairs(TurnTable.RewardData) do
            if random_num <= v.value then
                index = i
                break
            end
        end
    
        if index == nil then
            return
        end
        TurnTable.DrawData = TurnTable.RewardData[index]
        local circle_num = 7
        local action_time = 2
    
        local rad_iterval = 2 * math.pi / #TurnTable.RewardData
        -- local radian = circle_num * math.pi + rad_iterval * index
        local radian =  - (circle_num * 2 * math.pi + rad_iterval * (index - 1))
        TurnTable.radian = radian
        TurnTable.IsInDraw = true
        local tween=CommonCtrl.Tween:new{
            obj=ParaUI.GetUIObject("TurnTable.BG"),
            prop="rotation",
            begin=0,
            change=	radian,
            duration=action_time,
            -- MotionFinish = TurnTable.MotionFinish,
                }
            tween.func=CommonCtrl.TweenEquations.easeNone;
            tween:Start();
            
            commonlib.TimerManager.SetTimeout(function()
                if page and page:IsVisible() then
                    TurnTable.MotionFinish()
                end
            end, action_time * 1000);
    end)
end

-- 检测今天是否抽过奖了
function TurnTable.TodayHasDraw()
    local time_stamp = GameLogic.GetPlayerController():LoadRemoteData("TurnTableDrawTime",0);
    time_stamp = tonumber(time_stamp)
    if time_stamp == 0 then
        return false
    end
	-- 获取今日凌晨的时间戳 1603949593
	local day_time_stamp = TurnTable.GetWeeHours(server_time)

	if day_time_stamp <= time_stamp then
		return true, day_time_stamp
	end

	return false, time_stamp
end

function TurnTable.GetWeeHours(time)
    local year = os.date("%Y", time)	
    local month = os.date("%m", time)
	local day = os.date("%d", time)
    local day_time_stamp = os.time({year = year, month = month, day = day, hour=0, minute=0, second=0})
    
    return day_time_stamp
end

function TurnTable.MotionFinish()
    keepwork.user.server_time({}, function(err, msg, data)
        server_time = TurnTable.GetTimeStamp(data.now)
        TurnTable.IsInDraw = false
        if TurnTable.DrawData.exid then
            local exid = TurnTable.DrawData.exid
            local callback = function()
                GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.promotion.turnable')
                if exid == 0 then
                    GameLogic.AddBBS(nil, "很遗憾没有抽中奖励，别灰心，明天还可以再来哦");
                else
                    local desc = string.format("恭喜你抽中%s知识豆", TurnTable.DrawData.bean_num)
                    GameLogic.AddBBS(nil, desc);
                end
                GameLogic.GetPlayerController():SaveRemoteData("TurnTableDrawTime", TurnTable.GetWeeHours(server_time), 0);
    
                TurnTable.OnRefresh()
            end
    
            if exid == 0 then
                callback()
            else
                KeepWorkItemManager.DoExtendedCost(exid, callback);
            end
        end
    end)
end

function TurnTable.GetDrawState()
   if TurnTable.TodayHasDraw() then
       return TurnTable.DrawState.has_draw
   end

   -- 18点之前不能抽奖
   local time = server_time
   local year = os.date("%Y", time)	
   local month = os.date("%m", time)
   local day = os.date("%d", time)

   local time_limit1 = os.time({year = year, month = month, day = day, hour=18, minute=0, second=0})
   local time_limit2 = os.time({year = year, month = month, day = day, hour=24, minute=0, second=0})
   if time >= time_limit1 and time <= time_limit2 then
        return TurnTable.DrawState.can_draw
   end

   return TurnTable.DrawState.can_not_draw
end

function TurnTable.GetTimeStamp(at_time)
    -- local httpwrapper_version = HttpWrapper.GetDevVersion();
    -- if httpwrapper_version == "RELEASE" or httpwrapper_version == "LOCAL" then
    --     return os.time()
    -- end

    at_time = at_time or ""
    -- at_time = "2020-09-09T06:52:43.000Z"
    local year, month, day, hour, min, sec = at_time:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
    local time_stamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour) + 8}) -- 这个时间是带时区的 要加8小时
    time_stamp = time_stamp + min * 60 + sec
    return time_stamp
end