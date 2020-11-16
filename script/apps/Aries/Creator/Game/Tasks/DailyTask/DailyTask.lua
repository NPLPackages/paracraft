--[[
Title: DailyTask
Author(s): yangguiyi
Date: 2020/10/19
Desc:  
Use Lib:
-------------------------------------------------------
local DailyTask = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTask.lua");
DailyTask.Show();
--]]
local DailyTask = NPL.export();

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
local TaskIdList = DailyTaskManager.GetTaskIdList()


commonlib.setfield("MyCompany.Aries.Creator.Game.DailyTask.DailyTask", DailyTask);
local page;
DailyTask.isOpen = false
DailyTask.ButtonData = {
	{name = "成长日记", reward_bean = 20, click_cb = "GrowthDiary", task_id = TaskIdList.GrowthDiary, bg_img = "Texture/Aries/Creator/keepwork/DailyTask/chengzhangriji_263X170_32bits.png#0 0 263 170"},
	{name = "实战提升", reward_bean = 20, click_cb = "WeekWork", task_id = TaskIdList.WeekWork, bg_img = "Texture/Aries/Creator/keepwork/DailyTask/shizhantisheng_263X170_32bits.png#0 0 263 170"},
	{name = "玩学课堂", reward_bean = 20, click_cb = "Classroom", task_id = TaskIdList.Classroom, bg_img = "Texture/Aries/Creator/keepwork/DailyTask/wanxueketang_263X170_32bits.png#0 0 263 170"},
	{name = "更新世界", reward_bean = 20, click_cb = "UpdataWorld", task_id = TaskIdList.UpdataWorld, bg_img = "Texture/Aries/Creator/keepwork/DailyTask/gengxinshijie_263X170_32bits.png#0 0 263 170"},
	{name = "参观5个世界", reward_bean = 20, click_cb = "VisitWorld", task_id = TaskIdList.VisitWorld, bg_img = "Texture/Aries/Creator/keepwork/DailyTask/canguanwugeshijie_263X170_32bits.png#0 0 263 170"},
}
function DailyTask.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = DailyTask.CloseView
end

function DailyTask.Show()
    if(KeepworkServiceSession:IsSignedIn())then
        DailyTask.ShowView()
        return
    end
    LoginModal:CheckSignedIn(L"请先登录", function(result)
        if result == true then
            Mod.WorldShare.Utils.SetTimeOut(function()
                if result then
					DailyTask.ShowView()
                end
            end, 500)
        end
	end)
end

function DailyTask.ShowView()
	if page then
		page:CloseWindow();
		DailyTask.CloseView()
	end

	DailyTask.isOpen = true
	local view_width = 850
	local view_height = 443
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTask.html",
			name = "DailyTask.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -view_width/2,
				y = -view_height/2,
				width = view_width,
				height = view_height,
				isTopLevel = true
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function DailyTask.FlushView(only_refresh_grid)
	if only_refresh_grid then
		local gvw_name = "item_gridview";
		local node = page:GetNode(gvw_name);
		pe_gridview.DataBind(node, gvw_name, false);
	else
		DailyTask.OnRefresh()
	end
end

function DailyTask.CloseView()
	DailyTask.isOpen = false
end

function DailyTask.GrowthDiary()
	page:CloseWindow();
	ParacraftLearningRoomDailyPage.DoCheckin();
end

function DailyTask.WeekWork()
	local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
	TeachingQuestLinkPage.ShowPage();
end

function DailyTask.Classroom()
	local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
	StudyPage.clickArtOfWar();
end

function DailyTask.UpdataWorld()
	if(mouse_button == "right") then
		-- the new version
		local UserConsoleCreate = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Create/Create.lua")
		UserConsoleCreate:Show();
	else
		local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
		UserConsole:ShowPage();
	end
end

function DailyTask.VisitWorld()
	local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
	UserConsole.OnClickOfficialWorlds();
end

function DailyTask.GetCompletePro(data)
	local task_id = data.task_id or "0"
	local task_data = DailyTaskManager.GetTaskData(task_id)
	local complete_times = task_data.complete_times or 0
	if task_id == TaskIdList.GrowthDiary then
		complete_times = ParacraftLearningRoomDailyPage.HasCheckedToday() and 1 or 0 -- 成长日记 以是否签到了为标准 现在是否签到成功改成看20秒之后才算成功
	end

	return complete_times .. "/" .. task_data.max_times
end

function DailyTask.GetRewardDesc(data)
	local exid = DailyTaskManager.GetTaskExidByTaskId(data.task_id)
	local reward_num = DailyTaskManager.GetTaskRewardNum(exid)

	if data.task_id == TaskIdList.VisitWorld then
		return reward_num .. "/个"
	end

	return reward_num
end