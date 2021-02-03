--[[
Title: QuestSpecialCourse
Author(s): yangguiyi
Date: 2021/01/28
Desc:  
Use Lib:
-------------------------------------------------------
local QuestSpecialCourse = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestSpecialCourse.lua");
QuestSpecialCourse.Show();
--]]
local QuestSpecialCourse = NPL.export();
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
-- local QuestProvider = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestProvider.lua");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
local TaskIdList = DailyTaskManager.GetTaskIdList()
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local QuestRewardPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestRewardPage.lua");
local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")

local page;
QuestSpecialCourse.isOpen = false
QuestSpecialCourse.TaskData = {}
QuestSpecialCourse.is_add_event = false
QuestSpecialCourse.begain_time_t = {year=2021, month=1, day=28, hour=0, min=0, sec=0}
QuestSpecialCourse.begain_exid = 40028
QuestSpecialCourse.end_exid = 40030

QuestSpecialCourse.GiftState = {
	can_not_get = 0,		--未能领取
	can_get = 1,			--可领取
	has_get = 2,			--已领取
}

QuestSpecialCourse.TaskState = {
	can_go = 0,
	has_go = 1,
	can_not_go = 2,
}

QuestSpecialCourse.CourseData = {}

QuestSpecialCourse.CourseTimeLimit = {
	{begain_time = {hour=10,min=30}, end_time = {hour=10,min=45}},
	{begain_time = {hour=13,min=30}, end_time = {hour=13,min=45}},
	{begain_time = {hour=16,min=0}, end_time = {hour=16,min=15}},
	{begain_time = {hour=18,min=0}, end_time = {hour=18,min=15}},
	{begain_time = {hour=19,min=0}, end_time = {hour=19,min=15}},
}

QuestSpecialCourse.ToCourseState = {
	before = 0, 	-- 提前
	in_time = 1,	-- 课程时间内
	late = 2,		-- 迟到
	finish = 3,		-- 今日课程结束
}

local VersionToKey = {
	ONLINE = 1,
	RELEASE = 2,
	LOCAL = 3,
}

local ProInitData = {}

local TargetProgerssValue = 60
local MaxProgressValue = 100
local RewardNums = 5
local modele_bag_id = 0
local server_time = 0
local today_weehours = 0

function QuestSpecialCourse.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = QuestSpecialCourse.CloseView
	page.OnCreate = QuestSpecialCourse.OnCreate()
end

function QuestSpecialCourse.OnCreate()
end

-- is_make_up 是否补课面板
function QuestSpecialCourse.Show(is_make_up)
	QuestSpecialCourse.is_make_up = is_make_up
    if(not GameLogic.GetFilters():apply_filters('is_signed_in'))then
        return
    end
	QuestSpecialCourse.ShowView()
end

function QuestSpecialCourse.RefreshData()	
	if not QuestSpecialCourse.IsVisible() then
		return
	end

	QuestSpecialCourse.HandleTaskData()
	QuestSpecialCourse.HandleCourseData()
	QuestSpecialCourse.OnRefreshGridView()
end

function QuestSpecialCourse.ShowView()
	if page and page:IsVisible() then
		page:CloseWindow()
		-- QuestSpecialCourse.CloseView()
	end

	QuestSpecialCourse.HandleTaskData()
	QuestSpecialCourse.HandleCourseData()
	
	if not QuestSpecialCourse.is_add_event then
		QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnRefresh,function()
			if not page or not page:IsVisible() then
				return
			end
			QuestSpecialCourse.RefreshData()
			
		end, nil, "QuestSpecialCourse_Event_Init")

		QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnFinished,function(__, event)
			if not page or not page:IsVisible() then
				return
			end
		end, nil, "QuestSpecialCourse_OnFinished")

		QuestSpecialCourse.is_add_event = true
	end

    local bagNo = 1007;
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            modele_bag_id = bag.id;
            break;
        end
    end
	

	QuestSpecialCourse.isOpen = true
	local view_width = 960
	local view_height = 480
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestSpecialCourse.html",
			name = "QuestSpecialCourse.Show", 
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

function QuestSpecialCourse.IsVisible()
	if page == nil then
		return false
	end
	return page:IsVisible()
end

function QuestSpecialCourse.OnRefreshGridView()
    -- if(page)then
    --     page:Refresh(0);
	-- end
	
	local gvw_name = "item_gridview";
	local node = page:GetNode(gvw_name);
	pe_gridview.DataBind(node, gvw_name, false);
end

function QuestSpecialCourse.CloseView()
	QuestSpecialCourse.isOpen = false

	local file_fold_name = "Texture/Aries/Creator/keepwork/Quest/"
	local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	Files:UnloadFoldAssets(file_fold_name);
end

function QuestSpecialCourse.EnterWorld(world_id)
	page:CloseWindow()
	QuestSpecialCourse.CloseView()
	local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
	CommandManager:RunCommand(string.format('/loadworld -force -s %s', world_id))

	-- QuestSpecialCourse.RefreshData()
end

function QuestSpecialCourse.WeekWork()
	local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
	TeachingQuestLinkPage.ShowPage();
end

function QuestSpecialCourse.GetCompletePro(data)
	local task_id = data.task_id or "0"
	local task_data = DailyTaskManager.GetTaskData(task_id)
	local complete_times = task_data.complete_times or 0

	return complete_times .. "/" .. task_data.max_times
end

function QuestSpecialCourse.HandleTaskData(data)
	QuestSpecialCourse.TaskData = {}

	if QuestSpecialCourse.TaskAllData == nil then
		local quest_datas = QuestProvider:GetInstance().templates_map
		local exid_list = {}
		QuestSpecialCourse.TaskAllData = {}
		for i, v in pairs(quest_datas) do
			-- 获取兑换规则
			if exid_list[v.exid] == nil and v.exid >= QuestSpecialCourse.begain_exid and v.exid <= QuestSpecialCourse.end_exid then
				exid_list[v.exid] = 1
				local index = #QuestSpecialCourse.TaskAllData + 1
				QuestSpecialCourse.TaskAllData[index] = v
			end
		end

        table.sort(QuestSpecialCourse.TaskAllData,function(a,b)
            return a.gsid < b.gsid
        end)
	end
	local quest_datas = QuestProvider:GetInstance().templates_map
	for i, v in pairs(QuestSpecialCourse.TaskAllData) do
		-- 获取兑换规则
		if QuestSpecialCourse.GetTaskVisible(v) then
			local index = #QuestSpecialCourse.TaskData + 1
			local task_data = {}
			local exchange_data = KeepWorkItemManager.GetExtendedCostTemplate(v.exid)
			local name = exchange_data.name
			local desc = exchange_data.desc
	
			task_data.name = name
			task_data.task_id = v.exid
			task_data.task_desc = desc
			task_data.id = v.id
			task_data.gsid = v.gsid
			task_data.is_finish = QuestAction.IsFinish(v.gsid)
			task_data.task_type = QuestSpecialCourse.GetTaskType(v)
			task_data.is_main_task = task_data.task_type == "main"
			task_data.goto_world = v.goto_world
			task_data.click = v.click
			task_data.task_pro_desc = QuestSpecialCourse.GetTaskProDescByQuest(v)
			task_data.task_state = QuestSpecialCourse.GetTaskStateByQuest(task_data)
			task_data.order = QuestSpecialCourse.GetTaskOrder(v)
			task_data.bg_img = QuestSpecialCourse.GetBgImg(task_data)

			task_data.goods_data = {}
			QuestSpecialCourse.TaskData[index] = task_data
		end
	end

	-- 主线任务在前
	table.sort(QuestSpecialCourse.TaskData, function(a, b)
		local value_a = 10000
		local value_b = 10000
		if a.is_main_task then
			value_a = value_a + 10000
		end
		if b.is_main_task then
			value_b = value_b + 10000
		end

		if a.task_type == "branch" then
			value_a = value_a + 1000
		end
		if b.task_type == "branch" then
			value_b = value_b + 1000
		end

		if a.task_type == "loop" then
			value_a = value_a + 100
		end
		if b.task_type == "loop" then
			value_b = value_b + 100
		end

		if a.order < b.order then
			value_a = value_a + 10
		end
		if b.order < a.order then
			value_b = value_b + 10
		end

		if a.task_id < b.task_id then
			value_a = value_a + 1
		end
		if b.task_id < a.task_id then
			value_b = value_b + 1
		end

		return value_a > value_b
	end)
end

function QuestSpecialCourse.GetTaskProDescByQuest(data)
	local value = QuestAction.GetValue(data.id) or 0
	local finish_value = data.finished_value
	local desc = string.format("进度：%s/%s", value, finish_value)

	return desc
end

function QuestSpecialCourse.GetTaskOrder(data)
	if data and data.order then
		return tonumber(data.order)
	end

	return 0
end

function QuestSpecialCourse.GetTaskVisible(data)
	local exid = data.exid
	if exid < QuestSpecialCourse.begain_exid or exid > QuestSpecialCourse.end_exid then
		return false
	end

	return true
end

function QuestSpecialCourse.GetTaskStateByQuest(data)
	if data.task_id == QuestAction.is_always_exist_exid then
		if not QuestSpecialCourse.IsGraduateTime(server_time) then
			return QuestSpecialCourse.TaskState.can_not_go
		end

		return QuestSpecialCourse.TaskState.can_go
	end

	if data.is_finish then
		return QuestSpecialCourse.TaskState.has_go
	end

	return QuestSpecialCourse.TaskState.can_go
end

function QuestSpecialCourse.GetBgImg(task_data)
	local img = "Texture/Aries/Creator/keepwork/Quest/bjtiao2_226X90_32bits.png#0 0 226 90:195 20 16 20"
	if QuestSpecialCourse.CheckIsMissClass(task_data) then
		img = "Texture/Aries/Creator/keepwork/Quest/bjtiao_226X90_32bits.png#0 0 226 90:195 20 16 20"
	end

	return img
end

function QuestSpecialCourse.HandleCourseData()
	local gift_state_list = QuestAction.GetGiftStateList()
	QuestSpecialCourse.CourseData = {}
	for i, v in ipairs(QuestSpecialCourse.TaskAllData) do
		local data = {}
		data.is_finish = QuestAction.IsFinish(v.gsid)
		data.img = QuestSpecialCourse.GetIconImg(i, v)
		-- data.number_img = QuestSpecialCourse.GetNumImg(v)
		data.desc = string.format("第%s课", i)
		if i == #QuestSpecialCourse.TaskAllData then
			data.desc = "GOAL"
		end
		QuestSpecialCourse.CourseData[#QuestSpecialCourse.CourseData + 1] = data
	end
end


function QuestSpecialCourse.GetIconImg(index, item)
	-- 最后一个礼拜要做不同显示
	if index == #QuestSpecialCourse.TaskAllData then
		return "Texture/Aries/Creator/keepwork/Quest/boshimao_81X60_32bits.png#0 0 81 60"
	end

	return ""
end

function QuestSpecialCourse.GetNumImg(item)
	local num = item.catch_value
	
	return string.format("Texture/Aries/Creator/keepwork/Quest/zi_%s_23X12_32bits.png#0 0 23 12", num)
end

-- 这里的task_id 其实就是exid
function QuestSpecialCourse.GetReward(task_id)
	local task_data = nil
	for key, v in pairs(QuestSpecialCourse.TaskData) do
		if v.task_id == task_id then
			task_data = v
			break
		end
	end
	
	if nil == task_data then
		return
	end

	-- local quest_data = QuestSpecialCourse.GetQuestData(task_data.task_id)

	-- if quest_data == nil then
	-- 	return
	-- end

	-- if task_data.task_type == "loop" then
	-- 	local childrens = quest_data.questItemContainer.children or {}
		
	-- 	for i, v in ipairs(childrens) do
	-- 		QuestAction.FinishDailyTask(v.template.id)
	-- 	end
		
	-- 	QuestSpecialCourse.RefreshData()
	-- else
		
	-- 	if quest_data.questItemContainer then
	-- 		quest_data.questItemContainer:DoFinish()
	-- 	end
	-- end


end

function QuestSpecialCourse.Goto(task_id)
	local task_data = QuestSpecialCourse.GetQuestData(task_id)
	if task_data == nil then
		return
	end

	local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
	local target_index = VersionToKey[httpwrapper_version]
	if task_data.goto_world and #task_data.goto_world > 0 then
		local world_id = task_data.goto_world[target_index]
		if world_id then
			QuestSpecialCourse.EnterWorld(world_id)
		end

	elseif task_data.click and task_data.click ~= "" then
		if string.find(task_data.click, "loadworld ") then
			page:CloseWindow()
			QuestSpecialCourse.CloseView()
		end
		NPL.DoString(task_data.click)
	end
	GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.quest_action.click_go_button')
end

function QuestSpecialCourse.GetQuestData(task_id)
	for i, v in ipairs(QuestSpecialCourse.TaskData) do
		if v.task_id == task_id then
			return v
		end
	end
end

function QuestSpecialCourse.GetTaskType(data)
	return data.type
end

function QuestSpecialCourse.IsOpen()
	if nil == page then
		return false
	end

	return page:IsVisible()
end

function QuestSpecialCourse.IsRoleModel(item_data)
	if item_data and item_data.bagId == modele_bag_id then
		return true
	end

	return false
end

function QuestSpecialCourse.OnClikcGift(gift_data)
end

-- 获取今天是第几天
function QuestSpecialCourse.GetSecondDay(exid)
	if exid == nil then
		return 0
	end
	return exid - QuestSpecialCourse.begain_exid + 1
end

function QuestSpecialCourse.Close()
	if nil == page then
		return
	end
	page:CloseWindow()
	QuestSpecialCourse.CloseView()
end

function QuestSpecialCourse.CheckCourseTimeState(cur_time_stamp)
	local day_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(cur_time_stamp)
	for i, v in ipairs(QuestSpecialCourse.CourseTimeLimit) do
		local begain_time_stamp = day_weehours + v.begain_time.min * 60 + v.begain_time.hour * 3600
		local end_time_stamp = day_weehours + v.end_time.min * 60 + v.end_time.hour * 3600

		if cur_time_stamp >= begain_time_stamp and cur_time_stamp <= end_time_stamp then
			return QuestSpecialCourse.ToCourseState.in_time
		end

		if i == 1 and cur_time_stamp < begain_time_stamp then
			return QuestSpecialCourse.ToCourseState.before
		end
		-- print("saaaaaaaaaaaaaa", i, #QuestSpecialCourse.CourseTimeLimit, cur_time_stamp, begain_time_stamp, cur_time_stamp > begain_time_stamp)
		if i == #QuestSpecialCourse.CourseTimeLimit and cur_time_stamp > begain_time_stamp then
			return QuestSpecialCourse.ToCourseState.finish
		end
	end

	for i, v in ipairs(QuestSpecialCourse.CourseTimeLimit) do
		local begain_time_stamp = day_weehours + v.begain_time.min * 60 + v.begain_time.hour * 3600
		local end_time_stamp = day_weehours + v.end_time.min * 60 + v.end_time.hour * 3600

		if cur_time_stamp < begain_time_stamp then
			return QuestSpecialCourse.ToCourseState.late, v
		end
	end

	return QuestSpecialCourse.ToCourseState.late
end

function QuestSpecialCourse.CheckIsMissClass(data)
	return QuestSpecialCourse.is_make_up and not data.is_finish
end