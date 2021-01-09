--[[
Title: QuestPage
Author(s): yangguiyi
Date: 2020/12/7
Desc:  
Use Lib:
-------------------------------------------------------
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
QuestPage.Show();
--]]
local QuestPage = NPL.export();
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
-- local QuestProvider = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestProvider.lua");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
-- QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnRefresh,function()
--     commonlib.echo("==============GetQuestItems");
--     echo(QuestProvider:GetInstance():GetQuestItems(),true)
-- end)

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
local TaskIdList = DailyTaskManager.GetTaskIdList()

commonlib.setfield("MyCompany.Aries.Creator.Game.Task.Quest.QuestPage", QuestPage);
local page;
QuestPage.isOpen = false
QuestPage.TaskData = {}
QuestPage.is_add_event = false

local OwlTaskId = 40005

QuestPage.TaskIdToClickCb = {
	-- [40001] = "EnterWorld",
	[TaskIdList.GrowthDiary] = "GrowthDiary",
	[TaskIdList.WeekWork] = "WeekWork",
	[TaskIdList.Classroom] = "Classroom",
	[TaskIdList.UpdataWorld] = "UpdataWorld",
	[TaskIdList.VisitWorld] = "VisitWorld",
}

QuestPage.GiftState = {
	can_not_get = 0,		--未能领取
	can_get = 1,			--可领取
	has_get = 2,			--已领取
}

QuestPage.TaskState = {
	not_complete = 0,		--未完成
	can_complete = 1,		--可完成
	has_complete = 2,		--已完成
	can_go = 3,				-- 前往
	
}

QuestPage.GiftData = {
	{is_catch = false, catch_value = 20, state = QuestPage.GiftState.can_not_get, img = "", is_get = true},
	{is_catch = false, catch_value = 40, state = QuestPage.GiftState.can_not_get, img = "", is_get = true},
	{is_catch = false, catch_value = 60, state = QuestPage.GiftState.can_not_get, img = "", is_get = true},
	{is_catch = false, catch_value = 80, state = QuestPage.GiftState.can_not_get, img = "", is_get = true},
	{is_catch = false, catch_value = 100, state = QuestPage.GiftState.can_not_get, img = "", is_get = true},
}

local ShowRewardIdList = {
	[998] = 1,
	[888] = 1,
}

local VersionToKey = {
	ONLINE = 1,
	RELEASE = 2,
	LOCAL = 3,
}

local HideTaskList = {
	[40002] = 1,
}

local TargetProgerssValue = 60
local MaxProgressValue = 100
local RewardNums = 5
local exp_gsid = 998
local modele_bag_id = 0

function QuestPage.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = QuestPage.CloseView
	page.OnCreate = QuestPage.OnCreate()
end

function QuestPage.Show()
    if(GameLogic.GetFilters():apply_filters('is_signed_in'))then
        QuestPage.ShowView()
        return
    end
    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                if result then
					QuestPage.ShowView()
                end
            end, 500)
        end
	end)
end

function QuestPage.RefreshData()
	QuestPage.CheckIsTaskCompelete()
	QuestPage.HandleTaskData()
	QuestPage.HandleGiftData()
	QuestPage.OnRefresh()
end

function QuestPage.ShowView()
	if page then
		page:CloseWindow();
		QuestPage.CloseView()
	end

	-- if QuestProvider.GetInstance == nil then
	-- 	return
	-- end
	QuestPage.CheckIsTaskCompelete()
	QuestPage.HandleTaskData()
	QuestPage.HandleGiftData()
	
	
	if not QuestPage.is_add_event then
		QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnRefresh,function()
			if not page then
				return
			end

			if not page:IsVisible() then
				return
			end

			QuestPage.RefreshData()
		end, nil, "QuestPage_Event_Init")

		QuestPage.is_add_event = true
	end

    local bagNo = 1007;
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            modele_bag_id = bag.id;
            break;
        end
    end
	

	QuestPage.isOpen = true
	local view_width = 960
	local view_height = 450
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.html",
			name = "QuestPage.Show", 
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

	-- local expbar = page:FindControl("expbar");
	-- expbar.Maximum = MaxProgressValue
	-- -- TargetProgerssValue = MaxProgressValue
	-- QuestPage.UpdateExpProgress()

	
	
end

function QuestPage.OnCreate()
	-- local exp_num = 88
	-- QuestPage.SetExpProgress(exp_num)


	-- 找到猫头鹰item 创建toolsbag
	local owl_item_index = 0
	for k, v in pairs(QuestPage.TaskData) do
		if v.task_id == OwlTaskId then
			owl_item_index = k
			break
		end
	end

	if owl_item_index > 0 then
		commonlib.TimerManager.SetTimeout(function()
			local tree_view = page:GetNode("item_gridview"):GetChild("pe:treeview")
			local owl_item = tree_view[owl_item_index]
			local button = owl_item:GetChildWithAttribute("name", "item_root"):GetChildWithAttribute("name", "canvas")

			local QuestItemToolTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestItemToolTip.lua");
			local desc_data = {
				"如果家里电脑没有安装帕拉卡，让爸爸妈妈百度搜索<div style='color: #ffff00 ;float: left;'>帕拉卡</div>帮你下载安装哦。",
			}
			QuestItemToolTip.Show(button.uiobject_id, desc_data)
		end, 10)
	end
end

function QuestPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function QuestPage.FlushView(only_refresh_grid)
	if only_refresh_grid then
		local gvw_name = "item_gridview";
		local node = page:GetNode(gvw_name);
		pe_gridview.DataBind(node, gvw_name, false);
	else
		QuestPage.OnRefresh()
	end
end

function QuestPage.CloseView()
	QuestPage.isOpen = false
end

function QuestPage.EnterWorld(world_id)
	local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
	CommandManager:RunCommand(string.format('/loadworld -force -s %s', world_id))

	QuestPage.RefreshData()
end

function QuestPage.GrowthDiary()
	page:CloseWindow();
	ParacraftLearningRoomDailyPage.DoCheckin();
end

function QuestPage.WeekWork()
	local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
	TeachingQuestLinkPage.ShowPage();
end

function QuestPage.Classroom()
	local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
	StudyPage.clickArtOfWar();
end

function QuestPage.UpdataWorld()
	if(mouse_button == "right") then
		-- the new version
		GameLogic.GetFilters():apply_filters('show_create_page')
	else
		GameLogic.GetFilters():apply_filters('show_console_page')
	end
end

function QuestPage.VisitWorld()
	GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
end

function QuestPage.GetCompletePro(data)
	local task_id = data.task_id or "0"
	local task_data = DailyTaskManager.GetTaskData(task_id)
	local complete_times = task_data.complete_times or 0
	if task_id == TaskIdList.GrowthDiary then
		complete_times = ParacraftLearningRoomDailyPage.HasCheckedToday() and 1 or 0 -- 成长日记 以是否签到了为标准 现在是否签到成功改成看20秒之后才算成功
	end

	return complete_times .. "/" .. task_data.max_times
end

function QuestPage.GetRewardDesc(data)
	local exid = DailyTaskManager.GetTaskExidByTaskId(data.task_id)
	local reward_num = DailyTaskManager.GetTaskRewardNum(exid)

	if data.task_id == TaskIdList.VisitWorld then
		return reward_num .. "/个"
	end

	return reward_num
end

function QuestPage.UpdateExpProgress(target_pro)
	local value = page:GetValue("expbar");
	if value < target_pro then
		value = value + 1
		page:SetValue("expbar", value);

		commonlib.TimerManager.SetTimeout(function()
			QuestPage.UpdateExpProgress(target_pro)
		end, 2)
	elseif value >= target_pro then
		QuestPage.OnRefresh()
	end
end

function QuestPage.HandleTaskData(data)
	QuestPage.TaskData = {}
	-- 先把新手引导任务插进去 新手引导任务用的是新的数据读取方式	
	local quest_datas = QuestProvider:GetInstance():GetQuestItems()
	-- print("ggggggggggggggg")
	-- echo(quest_datas, true)
	for i, v in ipairs(quest_datas) do
		-- 获取兑换规则
		if HideTaskList[v.exid] == nil then
			local exid = v.exid
			local index = #QuestPage.TaskData + 1
			local task_data = {}
			local exchange_data = KeepWorkItemManager.GetExtendedCostTemplate(exid)
			local name = exchange_data.name
			local desc = exchange_data.desc
	
			task_data.name = name
			task_data.task_id = v.exid
			task_data.task_desc = desc
			task_data.task_pro_desc = QuestPage.GetTaskProDescByQuest(v)
			task_data.task_state = QuestPage.GetTaskStateByQuest(v)
			task_data.task_type = QuestPage.GetTaskType(v)
			task_data.is_main_task = task_data.task_type == "main"
	
			task_data.bg_img = QuestPage.GetBgImg(task_data)
			task_data.questItemContainer = v.questItemContainer
			-- 限定最多1个
			task_data.goods_data = {}
			for i2, v2 in ipairs(exchange_data.exchangeTargets[1].goods) do
				if v2.goods.gsId < 60001 or v2.goods.gsId > 70000 then
					task_data.goods_data[#task_data.goods_data + 1] = v2
				end
			end

			QuestPage.TaskData[index] = task_data
		end
	end

	-- 主线任务在前
	table.sort(QuestPage.TaskData, function(a, b)
		if a.is_main_task then
			return true
		end

		return false
	end)

	---------------------------------------这块代码使用的是旧版的任务数据---------------------------------------
	-- local task_id_list = DailyTaskManager.GetTaskIdList()
	-- local id_list = {}
	-- for k, v in pairs(task_id_list) do
	-- 	id_list[#id_list + 1] = v
	-- end
	-- table.sort(id_list, function(a, b)
	-- 	return b > a
	-- end)
	-- for k, v in pairs(id_list) do
	-- 	-- 获取兑换规则
	-- 	local exid = DailyTaskManager.GetTaskExidByTaskId(v)
	-- 	if exid ~= 0 then
	-- 		local index = #QuestPage.TaskData + 1
	-- 		local task_data = {}
	-- 		local exchange_data = KeepWorkItemManager.GetExtendedCostTemplate(exid)
	-- 		local name = exchange_data.name
	-- 		local desc = exchange_data.desc
	-- 		if v == DailyTaskManager.task_id_list.GrowthDiary then
	-- 			name = "成长日记"
	-- 			desc = "成长日记"
	-- 		end
	-- 		-- if v == DailyTaskManager.task_id_list.NewPlayerGuid then
	-- 		-- 	name = "完成新手引导"
	-- 		-- 	desc = "完成新手引导"
	-- 		-- end

	-- 		desc = ""
	-- 		task_data.name = name
	-- 		task_data.task_id = v
	-- 		task_data.task_desc = desc
	-- 		task_data.task_pro_desc = QuestPage.GetTaskProDesc(v)
	-- 		task_data.task_state = QuestPage.GetTaskState(v)
	-- 		task_data.is_main_task = false
	-- 		task_data.bg_img = QuestPage.GetBgImg(task_data)
	
	-- 		-- 限定最多1个
	-- 		task_data.goods_data = {}
	-- 		for i, v in ipairs(exchange_data.exchangeTargets[1].goods) do
	-- 			if v.goods.gsId == 998 then
	-- 				task_data.goods_data[#task_data.goods_data + 1] = v
	-- 			end
	-- 		end
	-- 		-- print("aaaaaaaaaaaaaaaaaa", v)
	-- 		-- echo(task_data.goods_data, true)
	-- 		QuestPage.TaskData[index] = task_data
	-- 	end
	-- end

	---------------------------------------这块代码使用的是旧版的任务数据/end---------------------------------------
end

function QuestPage.GetTaskProDesc(task_id)
	task_id = task_id or "0"
	local task_data = DailyTaskManager.GetTaskData(task_id)
	local complete_times = task_data.complete_times or 0
	if task_id == TaskIdList.GrowthDiary then
		complete_times = ParacraftLearningRoomDailyPage.HasCheckedToday() and 1 or 0 -- 成长日记 以是否签到了为标准 现在是否签到成功改成看20秒之后才算成功
	end

	return "进度： "  .. complete_times .. "/" .. task_data.max_times
end

function QuestPage.GetTaskState(task_id)
	local is_complete = DailyTaskManager.CheckTaskCompelete(task_id)
	-- return data.questItemContainer:CanFinish() and QuestPage.TaskState.can_complete or QuestPage.TaskState.not_complete
	-- 新手引导任务特殊处理
	-- if task_id == DailyTaskManager.task_id_list.NewPlayerGuid then
	-- 	local task_data = DailyTaskManager.GetTaskData(task_id)
	-- 	if is_complete then
	-- 		return task_data.is_get_reward and QuestPage.TaskState.has_complete or QuestPage.TaskState.can_complete
	-- 	end	
	-- end

	return is_complete and QuestPage.TaskState.has_complete or QuestPage.TaskState.can_go
end

function QuestPage.GetTaskProDescByQuest(data)
	local childrens = data.questItemContainer.children
	-- print("gggggggggggggggggggggggg", #childrens)
	-- echo(childrens, true)
	local desc = ""

	for i, v in ipairs(childrens) do
		local child_task_desc = ""
		if v.id == "40005_1" then
			return ""
		end
		if type(v.finished_value) == "number" then
			local value = v.value or 0
			local temp_desc = "进度： "
			
			if v.template.desc and v.template.desc ~= "" then
				temp_desc = v.template.desc .. ": "
			end

			local value_desc = string.format("%s/%s", value, v.finished_value)
			if v.template.custom_show == true then
				value_desc = GameLogic.QuestAction.GetLabel(v.template.id, v);
			end
			child_task_desc = string.format("%s%s", temp_desc, value_desc)
		else
			child_task_desc = v.finished_value
		end
		
		local div_desc = [[
			<div>%s</div>
		]]

		desc = desc .. string.format(div_desc, child_task_desc)
	end

	return desc
end

function QuestPage.GetTaskStateByQuest(data)
	return data.questItemContainer:CanFinish() and QuestPage.TaskState.can_complete or QuestPage.TaskState.can_go
end

function QuestPage.GetBgImg(task_data)
	local img = "Texture/Aries/Creator/keepwork/Quest/bjtiao2_226X90_32bits.png#0 0 226 90:195 20 16 20"
	if task_data.is_main_task then
		img = "Texture/Aries/Creator/keepwork/Quest/bjtiao_226X90_32bits.png#0 0 226 90:195 20 16 20"
	end

	return img
end

function QuestPage.HandleGiftData()
	for i, v in ipairs(QuestPage.GiftData) do
		-- v.state = QuestPage.GetGiftState(v)
		v.img = QuestPage.GetIconImg(i, v)
		v.number_img = QuestPage.GetNumImg(v)
	end
end

function QuestPage.GetGiftState(gift_data)
	return QuestPage.GiftState.can_not_get
end

function QuestPage.GetIconImg(index, item)
	-- 最后一个礼拜要做不同显示
	if index == #QuestPage.GiftData then
		return "Texture/Aries/Creator/keepwork/Quest/liwu3_86X70_32bits.png#0 0 86 70"
	end

	local path = "Texture/Aries/Creator/keepwork/Quest/liwu1_55X56_32bits.png#0 0 55 56"
	if item.state == QuestPage.GiftState.can_not_get then
		path = "Texture/Aries/Creator/keepwork/Quest/liwu2_55X56_32bits.png#0 0 55 56"
	end

	return path
end

function QuestPage.GetNumImg(item)
	local num = item.catch_value
	
	return string.format("Texture/Aries/Creator/keepwork/Quest/zi_%s_23X12_32bits.png#0 0 23 12", num)
end

function QuestPage.SetExpProgress(value)
	page:SetValue("expbar", value);
end
-- 这里的task_id 其实就是exid
function QuestPage.GetReard(task_id)
	-- 目前只有新手引导任务是要主动领取奖励

	-- local quest_datas = QuestProvider:GetInstance():GetQuestItems()
	local quest_data = QuestPage.GetQuestData(task_id)
	if quest_data then
		quest_data.questItemContainer:DoFinish()
	end

    local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
    DockPage.page:Refresh(0.01)
end

function QuestPage.Goto(task_id)
	if QuestPage.TaskIdToClickCb[task_id] and QuestPage[QuestPage.TaskIdToClickCb[task_id]] then
		QuestPage[QuestPage.TaskIdToClickCb[task_id]]()
	else
		local quest_data = QuestPage.GetQuestData(task_id)
		if quest_data then
			local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
			local target_index = VersionToKey[httpwrapper_version]
			local questItemContainer = quest_data.questItemContainer
			local childrens = questItemContainer.children or {}
		
			for i, v in ipairs(childrens) do
				if v.template.goto_world and #v.template.goto_world > 0 then
					local world_id = v.template.goto_world[target_index]
					if world_id then
						QuestPage.EnterWorld(world_id)
					end

					break
				elseif v.template.click and v.template.click ~= "" then
					NPL.DoString(v.template.click)
				end
				-- echo(v, true)
			end
		end
	end

	GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.quest_action.click_go_button')
end

function QuestPage.GetQuestData(task_id)
	local quest_datas = QuestProvider:GetInstance():GetQuestItems()
	for i, v in ipairs(quest_datas) do
		if v.exid == task_id then
			return v
		end
	end
end

function QuestPage.GetTaskType(data)
	local childrens = data.questItemContainer.children
	for i, v in ipairs(childrens) do
		if v.template.task_type then
			return v.template.task_type
		end
	end
end

function QuestPage.IsOpen()
	if nil == page then
		return false
	end

	return page:IsVisible()
end

function QuestPage.CheckIsTaskCompelete()
    local profile = KeepWorkItemManager.GetProfile()
    -- 是否实名认证
--    if GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
--         GameLogic.QuestAction.SetValue("40002_1",1);
--    end 

    -- 是否新的实名认证
	if GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        GameLogic.QuestAction.SetValue("40006_1",1);
   end 

   -- 是否选择了学校
   if profile and profile.schoolId and profile.schoolId > 0 then
        GameLogic.QuestAction.SetValue("40003_1",1);
   end

   -- 是否已选择了区域
   if profile and profile.region and profile.region.hasChildren == 0 then
        GameLogic.QuestAction.SetValue("40004_1",1);
   end
end

function QuestPage.IsRoleModel(item_data)
	if item_data and item_data.bagId == modele_bag_id then
		return true
	end

	return false
end