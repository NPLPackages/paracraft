--[[
    author:{pbb}
    time:2021-09-27 15:10:26
    use lib:
    local ActNationalDay = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Activity/ActNationalDay/ActNationalDay.lua") 
    ActNationalDay.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local ActNationalDay = NPL.export()
local page_root
local strPath = ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Activity/ActNationalDay/ActNationalDay.lua") '
local national_gsId = 65044
local national_exid = 30057
local isRegisterEvent = false
ActNationalDay.ClientData = nil
ActNationalDay.btn_types = {
    task_lock = 1,
    task_unlock = 2,
    task_finish = 3,
    task_get = 4,
}
ActNationalDay.taskCnf = {
    {
        name="login",
        content = "第一天登陆帕拉卡",
        world_id = -1,
        gift = "知识豆20个",
    },
    {
        name="creative",
        content = "进入“创意空间”世界",
        world_id = 19759,
        gift = "知识豆50个",
    },
    {
        name="tunnel",
        content = "第三天体验“寻龙密道”（9162）",
        world_id = 9162,
        gift = "知识豆300个【知识豆可兑换皮肤】",
    },
    {
        name="movie",
        content = "观看成长日记第6课视频",
        world_id = -1,
        gift = "知识豆50个",
    },
    {
        name="lesson",
        content = "观看课程“卡卡之家”",
        world_id = 42670,
        gift = "知识豆50个",
    },
    {
        name="world",
        content = "创建一个世界，创建动画方块",
        world_id = -1,
        gift = "知识豆50个",
    },
    {
        name="share",
        content = "分享昨天创建的世界",
        world_id = -1,
        gift = "知识豆200个,红旗小书包（永久）",
    },

}

local page = nil
function ActNationalDay.OnInit()
    ParacraftLearningRoomDailyPage.OnInit()
    page = document:GetPageCtrl();
    if page then
        page_root = page:GetParentUIObject()
    end

    ActNationalDay.click_funcs = {
        [1] =ActNationalDay.DoSignTask,
        [2] =ActNationalDay.DoCreativeTask,
        [3] =ActNationalDay.DoTunnelTask,
        [4] =ActNationalDay.DoMovieLessonTask,
        [5] =ActNationalDay.DoLessonTask,
        [6] =ActNationalDay.DoCreateWorldTask,
        [7] =ActNationalDay.DoShareWorldTask,
    }
end

function ActNationalDay.ShowView()
    local view_width = 1030
    local view_height = 650
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Activity/ActNationalDay/ActNationalDay.html",
        name = "ActNationalDay.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    ActNationalDay.InitPageView()
end

function ActNationalDay.ShowPage()
    ActNationalDay.RegisterEvent()
    local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(national_gsId)
    if bOwn and copies > 0 then
        ActNationalDay.ShowView()
    else
        KeepWorkItemManager.DoExtendedCost(national_exid,function()
            ActNationalDay.ShowView()
        end)
    end
end

function ActNationalDay.RegisterEvent()
    if not isRegisterEvent then
        GameLogic.GetFilters():add_filter("OnWorldCreate", function(worldPath)
            -- print("worldPath========",worldPath)
            if worldPath and worldPath ~= "" then
                ActNationalDay.FinishCreateTask()
            end
        end);
    
        GameLogic.GetFilters():add_filter("SyncWorldFinish", function()
            if ActNationalDay.CheckHasShareProject() then
                ActNationalDay.FinishShareTask()
            end
        end);
        isRegisterEvent = true
    end
end

function ActNationalDay.RefreshPage()
    if page then
        page:Refresh(0)
        ActNationalDay.InitPageView()
    end
end

function ActNationalDay.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function ActNationalDay.InitPageView()
    local startX,startY = 45,23
    local startX1,startY1 = 17,195
    local width,height = 136,152
    local width1,height1 = 192,152
    local parentNode = ParaUI.GetUIObject("gift_container")
    if parentNode and parentNode:IsValid() then
        for i,v in ipairs(ActNationalDay.taskCnf) do  
            local uitype = ActNationalDay.GetBtnBackImgType(i)          
            if i <= 4 then
                if uitype == ActNationalDay.btn_types.task_get or uitype == ActNationalDay.btn_types.task_lock then
                    local shadowBg = ParaUI.CreateUIObject("container", "shadowBg"..i, "_lt", startX + (i-1)*153, startY, width, height);
                    shadowBg.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B7_32X32_32bits.png;0 0 32 32 : 14 14 14 14 "; 
                    parentNode:AddChild(shadowBg)
                    ActNationalDay.AddSignIcon(shadowBg,uitype,i)
                end
                if uitype == ActNationalDay.btn_types.task_unlock then
                    local go_bt = ParaUI.CreateUIObject("button", "gobutton"..i, "_lt", startX-4 + (i-1)*152, startY +102, 144, 54);
                    go_bt.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B5_144X54_32bits.png;0 0 144 54";
                    go_bt.onclick = string.format([[%s.OnClick(%d);]],strPath,i)           
                    parentNode:AddChild(go_bt)
                end
                if uitype == ActNationalDay.btn_types.task_finish then
                    local get_bt = ParaUI.CreateUIObject("button", "getbutton"..i, "_lt", startX-4 + (i-1)*152, startY +102, 144, 54);
                    get_bt.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B4_144X54_32bits.png;0 0 144 54";
                    get_bt.onclick = string.format([[%s.OnClick(%d);]],strPath,i)           
                    parentNode:AddChild(get_bt)
                end
            elseif i < 7 then
                if uitype == ActNationalDay.btn_types.task_get or uitype == ActNationalDay.btn_types.task_lock then
                    local shadowBg = ParaUI.CreateUIObject("container", "shadowBg"..i, "_lt", startX1 + (i-5)*150, startY1, width, height);
                    shadowBg.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B7_32X32_32bits.png;0 0 32 32 : 14 14 14 14 "; 
                    parentNode:AddChild(shadowBg)
                    ActNationalDay.AddSignIcon(shadowBg,uitype,i)
                end
                if uitype == ActNationalDay.btn_types.task_unlock then
                    local go_bt = ParaUI.CreateUIObject("button", "gobutton"..i, "_lt", startX1 - 4 + (i-5)*152, startY1 +102, 144, 54);
                    go_bt.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B5_144X54_32bits.png;0 0 144 54";
                    go_bt.onclick = string.format([[%s.OnClick(%d);]],strPath,i)           
                    parentNode:AddChild(go_bt)
                end
                if uitype == ActNationalDay.btn_types.task_finish then
                    local get_bt = ParaUI.CreateUIObject("button", "getbutton"..i, "_lt", startX1-4 + (i-5)*152, startY1 +102, 144, 54);
                    get_bt.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B4_144X54_32bits.png;0 0 144 54";
                    get_bt.onclick = string.format([[%s.OnClick(%d);]],strPath,i)           
                    parentNode:AddChild(get_bt)
                end
            else
                if uitype == ActNationalDay.btn_types.task_get or uitype == ActNationalDay.btn_types.task_lock then
                    local shadowBg = ParaUI.CreateUIObject("container", "shadowBg"..i, "_lt", startX1 + (i-5)*152, startY1, width1, height1);
                    shadowBg.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B7_32X32_32bits.png;0 0 32 32 : 14 14 14 14 "; 
                    parentNode:AddChild(shadowBg)
                    ActNationalDay.AddSignIcon(shadowBg,uitype,i)
                end
                if uitype == ActNationalDay.btn_types.task_unlock then
                    local go_bt = ParaUI.CreateUIObject("button", "gobutton"..i, "_lt", startX1 + (i-5)*153 + 20, startY1 +102, 144, 54);
                    go_bt.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B5_144X54_32bits.png;0 0 144 54";
                    go_bt.onclick = string.format([[%s.OnClick(%d);]],strPath,i)           
                    parentNode:AddChild(go_bt)
                end
                if uitype == ActNationalDay.btn_types.task_finish then
                    local get_bt = ParaUI.CreateUIObject("button", "getbutton"..i, "_lt", startX1 + (i-5)*153 + 20, startY1 +102, 144, 54);
                    get_bt.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B4_144X54_32bits.png;0 0 144 54";
                    get_bt.onclick = string.format([[%s.OnClick(%d);]],strPath,i)           
                    parentNode:AddChild(get_bt)
                end
            end
        end
    end
end


function ActNationalDay.OnClick(index)
    local click_index = tonumber(index) or 1
    local uitype = ActNationalDay.GetBtnBackImgType(click_index)  
    if uitype == ActNationalDay.btn_types.task_unlock then
        local call = ActNationalDay.click_funcs[index]
        if call then
            call(index)
        end
    end
    if uitype == ActNationalDay.btn_types.task_finish then
        ActNationalDay.DoGetGift(click_index)
    end
end

local exids = {30052,30053,30054,30053,30053,30053,30056}
function ActNationalDay.DoGetGift(index)
    local clientData = ActNationalDay.GetClientData()
    local data = clientData[index]
    echo(data)
    if data and data.finish == 1 and data.get == 0 then
        local curExid = exids[index]
        KeepWorkItemManager.DoExtendedCost(curExid,function()
            data.get = 1
            data.finish = 1
            clientData[index] = data
            ActNationalDay.SetClientData(clientData,function()
                local gift = ActNationalDay.taskCnf[index].gift
                local tipStr = string.format("恭喜你领取了%s,你可以前往人物界面查看",gift)
                _guihelper.MessageBox(tipStr,function ()
                    -- GameLogic.AddBBS(nil,"奖励已领取，你可以前往人物界面查看")
                    ActNationalDay.RefreshPage()
                end)
                ActNationalDay.RefreshPage()
            end)
        end)
    end
end

function ActNationalDay.FinishTask(index)
    local clientData = ActNationalDay.GetClientData()
    local data = clientData[index] or {}
    data.finish = 1
    data.get = 0
    clientData[index]  = data
    ActNationalDay.SetClientData(clientData,function()
        GameLogic.AddBBS(nil,"国庆任务已完成，你可以前往活动页面领取奖励")
        ActNationalDay.RefreshPage()
    end)
end

function ActNationalDay.AddSignIcon(parentNode,uiType,index)
    if index < 7 then
        if uiType == ActNationalDay.btn_types.task_get then
            local getIcon = ParaUI.CreateUIObject("container", "getIcon", "_lt", 30, 46, 81, 66);
            getIcon.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B1_81X66_32bits.png;0 0 81 66";
            parentNode:AddChild(getIcon);
        end
        if uiType == ActNationalDay.btn_types.task_lock then
            local loclIcon = ParaUI.CreateUIObject("container", "loclIcon", "_lt", 0, 66, 159, 31);
            loclIcon.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B3_159X31_32bits.png;0 0 159 31";
            parentNode:AddChild(loclIcon);
            
        end
    else
        if uiType == ActNationalDay.btn_types.task_get then
            local getIcon = ParaUI.CreateUIObject("container", "getIcon", "_lt", 50, 66, 81, 66);
            getIcon.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B1_81X66_32bits.png;0 0 81 66";
            parentNode:AddChild(getIcon);
        end
        if uiType == ActNationalDay.btn_types.task_lock then
            local loclIcon = ParaUI.CreateUIObject("container", "loclIcon", "_lt", 20, 66, 159, 31);
            loclIcon.background = "Texture/Aries/Creator/keepwork/ActNationalDay/B3_159X31_32bits.png;0 0 159 31";
            parentNode:AddChild(loclIcon);
        end
    end
end

function ActNationalDay.GetBtnBackImgType(index) --ActNationalDay.btn_types
    local isLock = ActNationalDay.GetIsLockByIndex(index)
    if isLock then
        return ActNationalDay.btn_types.task_lock
    end
    local clientData = ActNationalDay.GetClientData()
    local data = clientData[index]
    if not data then
        return ActNationalDay.btn_types.task_unlock
    end

    if data.get and data.get == 1 then
        return ActNationalDay.btn_types.task_get
    end

    if data.finish and data.finish == 1 then
        return ActNationalDay.btn_types.task_finish
    end
end

function ActNationalDay.DoSignTask(index)
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        GameLogic.GetFilters():apply_filters('check_signed_in', "请先登录", function(result)
            if result == true then
                commonlib.TimerManager.SetTimeout(function()
                    ActNationalDay.FinishTask(index)                       
                end, 500)
            end
        end)
        return
    end
    ActNationalDay.FinishTask(index)
end

function ActNationalDay.DoCreativeTask(index)
    local id_list = {
		ONLINE = 19759,
		RELEASE = 1296 ,
	};
	local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
	local worldId = id_list[HttpWrapper.GetDevVersion()]
    GameLogic.RunCommand(format('/loadworld -s -force %d', worldId))
    ActNationalDay.FinishTask(index)
end

function ActNationalDay.DoTunnelTask(index)
    local cnf = ActNationalDay.taskCnf[index]
    local worldId = cnf.world_id
    if worldId > 0 then
        GameLogic.RunCommand(format('/loadworld -s -force %d', worldId))
        ActNationalDay.FinishTask(index)
    end
end

function ActNationalDay.DoMovieLessonTask(index)
    ParacraftLearningRoomDailyPage.FillDays()
    ParacraftLearningRoomDailyPage.OnOpenWeb(6,true);
    commonlib.TimerManager.SetTimeout(function()
        ActNationalDay.FinishTask(index)                       
    end, 1000)
end

function ActNationalDay.DoLessonTask(index)
    local info = string.format("是否立即进入【%s】","卡卡之家");
    _guihelper.MessageBox(info, function(res)
		if(res and res == _guihelper.DialogResult.OK) then
            local command = string.format("/loadworld -s -force %s", 42670)
            GameLogic.RunCommand(command)   
            commonlib.TimerManager.SetTimeout(function()
                ActNationalDay.FinishTask(index)                       
            end, 1000)         
		end
	end, _guihelper.MessageBoxButtons.OKCancel);
end

function ActNationalDay.DoCreateWorldTask(index)
    GameLogic.AddBBS(nil,"请创建一个你的世界")
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");
    local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
    CreateNewWorld.ShowPage(true)
end

function ActNationalDay.DoShareWorldTask()
    GameLogic.AddBBS(nil,"请在这个界面上或者进入世界分享你的世界")
    local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
	Opus:Show()
end

function ActNationalDay.FinishCreateTask()
    local state = ActNationalDay.GetBtnBackImgType(6)
    if state == ActNationalDay.btn_types.task_unlock then
        ActNationalDay.FinishTask(6)
    end
end

function ActNationalDay.FinishShareTask()
    local state = ActNationalDay.GetBtnBackImgType(7)
    if state == ActNationalDay.btn_types.task_unlock then
        ActNationalDay.FinishTask(7)
    end
end

function ActNationalDay.CheckHasShareProject()
    local curTime = ActNationalDay.GetCurDate()
    local shareStartTime = os.time({year = 2021, month = 10, day = 7, hour=0, min=0, sec=0})
    if curTime >= shareStartTime then
        return true
    end
    return false
end

function ActNationalDay.GetCurDate()
    local server_time = QuestAction.GetServerTime()
    local year = tonumber(os.date("%Y", server_time))	
	local month = tonumber(os.date("%m", server_time))
	local day = tonumber(os.date("%d", server_time))
    local dateStamp = os.time({year = year, month = month, day = day, hour=0, min=0, sec=0})
    return dateStamp
end

function ActNationalDay.GetIsLockByIndex(index)
    local curTime = ActNationalDay.GetCurDate()
    if curTime < ActNationalDay.GetActStartTime() then
        return true
    end
    if curTime < ActNationalDay.GetTimeByIndex(index) then
        return true
    end
    return false
end

function ActNationalDay.GetActStartTime()
    return os.time({year = 2021, month = 10, day = 1, hour=0, min=0, sec=0})
end

function ActNationalDay.GetTimeByIndex(index)
    return 	os.time({year = 2021, month = 10, day = index or 1, hour=0, min=0, sec=0})
end

function ActNationalDay.GetClientData()
    if ActNationalDay.ClientData == nil then
        ActNationalDay.ClientData = KeepWorkItemManager.GetClientData(national_gsId) or {};
    end
    local clientData = ActNationalDay.ClientData
    return clientData
end

function ActNationalDay.SetClientData(clientData,cb)
    KeepWorkItemManager.SetClientData(national_gsId, clientData, function()
        ActNationalDay.clientData = clientData
        if cb then
            cb()
        end
    end)
end