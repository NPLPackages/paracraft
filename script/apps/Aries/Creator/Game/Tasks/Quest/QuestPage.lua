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
-- QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnRefreshGridView,function()
--     commonlib.echo("==============GetQuestItems");
--     echo(QuestProvider:GetInstance():GetQuestItems(),true)
-- end)

-- local QuestDateCondition = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestDateCondition");
-- keepwork.user.server_time({},function(err, msg, data)
-- 	if(err == 200)then
-- 		QuestDateCondition.cur_time = data.now;
-- 		QuestDateCondition.values = {
-- 			{date="2021-1-12",duration = "10:00:00-12:00:00"},
-- 			{date="2021-1-12",duration = "14:00:00-16:00:00"},
-- 			{date="2021-1-12",duration = "20:00:00-22:00:00"},
-- 		}
-- 		QuestDateCondition.strict = true;
-- 		QuestDateCondition.endtime = "2021-01-13 11:28:21"
-- 		print(QuestDateCondition:IsValid())
-- 	end
-- end)

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
local TaskIdList = DailyTaskManager.GetTaskIdList()
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local QuestRewardPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestRewardPage.lua");

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
	{catch_value = 20, state = QuestPage.GiftState.can_not_get, img = "", gift_id = 1, exid = 30023},
	{catch_value = 40, state = QuestPage.GiftState.can_not_get, img = "", gift_id = 2, exid = 30024},
	{catch_value = 60, state = QuestPage.GiftState.can_not_get, img = "", gift_id = 3, exid = 30025},
	{catch_value = 80, state = QuestPage.GiftState.can_not_get, img = "", gift_id = 4, exid = 30026},
	{catch_value = 100, state = QuestPage.GiftState.can_not_get, img = "", gift_id = 5, exid = 30027},
}

local VersionToKey = {
	ONLINE = 1,
	RELEASE = 2,
	LOCAL = 3,
}

local HideTaskList = {
	[40002] = 1,
}

local ProInitData = {}

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

function QuestPage.OnCreate()
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
	if page == nil or not page:IsVisible() then
		return
	end

	QuestPage.CheckIsTaskCompelete()
	QuestPage.HandleTaskData()
	QuestPage.HandleGiftData()
	QuestPage.OnRefreshGridView()
	QuestPage.OnRefreshGiftGridView()
	QuestPage.FreshExpShow()
end

function QuestPage.ShowView()
	if page and page:IsVisible() then
		return
	end

	-- if QuestProvider.GetInstance == nil then
	-- 	return
	-- end
	QuestPage.CheckIsTaskCompelete()
	QuestPage.HandleTaskData()
	QuestPage.HandleGiftData()
	
	ProInitData = {
		width = 0,
		to_exp = 0,
		ui_object = nil,
		change_width = 4, --每次timer增加的宽度
		target_width = 0,
	}
	
	if not QuestPage.is_add_event then
		QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnRefresh,function()
			if not page or not page:IsVisible() then
				return
			end
			QuestPage.RefreshData()
		end, nil, "QuestPage_Event_Init")

		QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnFinished,function(__, event)
			if not page or not page:IsVisible() then
				return
			end

			-- local questItemContainer = event.quest_item_container
			-- local childrens = questItemContainer.children
			-- QuestPage.RefreshData()
		end, nil, "QuestPage_OnFinished")

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
	local view_height = 580
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

	local pro_mcml_node = page:GetNode("pro")
	local pro_ui_object = ParaUI.GetUIObject(pro_mcml_node.uiobject_id)
	ProInitData.width = 704
	ProInitData.ui_object = pro_ui_object
	pro_ui_object.width = 0;

	QuestPage.OnGridViewCreate()
	local exp = QuestAction.GetExp()
	QuestPage.ProgressToExp(false, exp)
	commonlib.TimerManager.SetTimeout(function()
		QuestPage.FreshExpShow()
	end, 50)
end

function QuestPage.IsVisible()
	if page == nil then
		return false
	end
	return page:IsVisible()
end

function QuestPage.OnGridViewCreate()
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
			if not page:IsVisible() then
				return
			end

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

	-- local pro_mcml_node = page:GetNode("pro")
	-- local pro_ui_object = ParaUI.GetUIObject(pro_mcml_node.uiobject_id)
	-- ProInitData.ui_object = pro_ui_object
	-- QuestPage.ProgressToExp(false, ProInitData.to_exp)
end

function QuestPage.OnRefreshGridView()
    -- if(page)then
    --     page:Refresh(0);
	-- end
	
	local gvw_name = "item_gridview";
	local node = page:GetNode(gvw_name);
	pe_gridview.DataBind(node, gvw_name, false);

	QuestPage.OnGridViewCreate()
end

function QuestPage.OnRefreshGiftGridView()
    -- if(page)then
    --     page:Refresh(0);
	-- end
	
	local gvw_name = "gift_gridview";
	local node = page:GetNode(gvw_name);
	pe_gridview.DataBind(node, gvw_name, false);
end

function QuestPage.CloseView()
	QuestPage.isOpen = false
	NPL.KillTimer(10086);

	local file_fold_name = "Texture/Aries/Creator/keepwork/Quest/"
	local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	Files:UnloadFoldAssets(file_fold_name);
end

function QuestPage.EnterWorld(world_id)
	page:CloseWindow()
	QuestPage.CloseView()
	local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
	CommandManager:RunCommand(string.format('/loadworld -force -s %s', world_id))

	-- QuestPage.RefreshData()
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

function QuestPage.HandleTaskData(data)
	QuestPage.TaskData = {}
	-- 先把新手引导任务插进去 新手引导任务用的是新的数据读取方式	
	local quest_datas = QuestProvider:GetInstance():GetQuestItems()
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

			task_data.task_type = QuestPage.GetTaskType(v)
			task_data.is_main_task = task_data.task_type == "main"

			task_data.task_pro_desc = QuestPage.GetTaskProDescByQuest(v, task_data.task_type)
			task_data.task_state = QuestPage.GetTaskStateByQuest(v, task_data.task_type)

			task_data.exp = QuestPage.GetTaskExp(v)
			task_data.order = QuestPage.GetTaskOrder(v)
			task_data.bg_img = QuestPage.GetBgImg(task_data)
			-- task_data.questItemContainer = v.questItemContainer

			task_data.goods_data = {}
			for i2, v2 in ipairs(exchange_data.exchangeTargets[1].goods) do
				if v2.goods.gsId < 60001 or v2.goods.gsId > 70000 then
					if #task_data.goods_data < 3 then
						task_data.goods_data[#task_data.goods_data + 1] = v2
					end
				end
			end
			-- task_data.exp = 20
			if task_data.exp > 0 then
				local exp_data = {reward_exp = task_data.exp}
				
				if #task_data.goods_data < 3 then
					task_data.goods_data[#task_data.goods_data + 1] = exp_data
				end
			end

			QuestPage.TaskData[index] = task_data
		end
	end

	-- 主线任务在前
	table.sort(QuestPage.TaskData, function(a, b)
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

		if a.task_state == QuestPage.TaskState.has_complete then
			value_a = value_a - 10000
		end
		if b.task_state == QuestPage.TaskState.has_complete then
			value_b = value_b - 10000
		end

		return value_a > value_b
	end)
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

	return is_complete and QuestPage.TaskState.has_complete or QuestPage.TaskState.can_go
end

function QuestPage.GetTaskProDescByQuest(data, task_type)
	local childrens = data.questItemContainer.children
	-- print("gggggggggggggggggggggggg", #childrens)
	-- echo(childrens, true)
	local desc = ""

	local data_item = childrens[1]
	local child_task_desc = ""
	if data_item.id == "40005_1" then
		return ""
	end
	if type(data_item.finished_value) == "number" then
		local value = data_item.value or 0
		if task_type == "loop" then
			value = QuestAction.GetDailyTaskValue(data_item.id)
		end
		local temp_desc = "进度： "
		
		if data_item.template.desc and data_item.template.desc ~= "" then
			temp_desc = data_item.template.desc .. ": "
		end

		local value_desc = string.format("%s/%s", value, data_item.finished_value)
		if data_item.template.custom_show == true then
			value_desc = QuestAction.GetLabel(data_item.template.id, data_item);
		end
		child_task_desc = string.format("%s%s", temp_desc, value_desc)
	else
		child_task_desc = data_item.finished_value
	end
	
	local div_desc = [[
		<div>%s</div>
	]]

	desc = desc .. string.format(div_desc, child_task_desc)

	return desc
end

function QuestPage.GetTaskOrder(data)
	local childrens = data.questItemContainer.children
	local data_item = childrens[1]
	if data_item and data_item.template.order then
		return tonumber(data_item.template.order)
	end

	return 0
end

function QuestPage.GetTaskStateByQuest(data, task_type)
	if task_type == "loop" then
		local childrens = data.questItemContainer.children	
		local data_item = childrens[1]
		
		local state = QuestAction.GetDailyTaskState(data_item.id)
		if state == QuestPage.TaskState.not_complete and data_item.template.click and data_item.template.click ~= "" then
			state = QuestPage.TaskState.can_go
		end
		return state
	end
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
	local exp = QuestAction.GetExp()
	local gift_state_list = QuestAction.GetGiftStateList()
	for i, v in ipairs(QuestPage.GiftData) do
		v.state = gift_state_list[i] or QuestPage.GiftState.can_not_get
		v.img = QuestPage.GetIconImg(i, v)
		v.number_img = QuestPage.GetNumImg(v)
	end
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
function QuestPage.GetReward(task_id)
	local task_data = nil
	for key, v in pairs(QuestPage.TaskData) do
		if v.task_id == task_id then
			task_data = v
			break
		end
	end
	
	if nil == task_data then
		return
	end

	-- 先加上探索力
	if task_data.exp and task_data.exp > 0 then
		QuestAction.AddExp(task_data.exp, function()
			local exp = QuestAction.GetExp()
			QuestPage.ProgressToExp(true, exp)
			QuestPage.HandleGiftData()
			QuestPage.OnRefreshGiftGridView()
		end)
	end

	local quest_data = QuestPage.GetQuestData(task_data.task_id)

	if quest_data == nil then
		return
	end

	if task_data.task_type == "loop" then
		local childrens = quest_data.questItemContainer.children or {}
		
		for i, v in ipairs(childrens) do
			QuestAction.FinishDailyTask(v.template.id)
		end
		
		QuestPage.RefreshData()
	else
		-- local questItemContainer = quest_data.questItemContainer
		-- print("axxxxxxxxxxxxxxxx", questItemContainer)
		-- if questItemContainer then
		-- 	questItemContainer:DoFinish()
		-- end
		
		if quest_data.questItemContainer then
			quest_data.questItemContainer:DoFinish()
		end
		-- local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
		-- DockPage.page:Refresh(0.01)
	end

	-- local quest_data = QuestPage.GetQuestData(task_id)
	-- if quest_data then
	-- 	quest_data.questItemContainer:DoFinish()
	-- end


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

function QuestPage.GetTaskExp(data)
	local exp = 0
	local childrens = data.questItemContainer.children
	for i, v in ipairs(childrens) do
		if v.template.exp then
			exp = tonumber(v.template.exp)
			break
		end
	end

	if exp == "" then
		exp = 0
	end

	return exp
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
--         QuestAction.SetValue("40002_1",1);
--    end 

    -- 是否新的实名认证
	if GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        QuestAction.SetValue("40006_1",1);
   end 

   -- 是否选择了学校
   if profile and profile.schoolId and profile.schoolId > 0 then
        QuestAction.SetValue("40003_1",1);
   end

   -- 是否已选择了区域
   if profile and profile.region and profile.region.hasChildren == 0 then
        QuestAction.SetValue("40004_1",1);
   end
end

function QuestPage.IsRoleModel(item_data)
	if item_data and item_data.bagId == modele_bag_id then
		return true
	end

	return false
end

function QuestPage.ProgressToExp(is_play_ani, to_exp)
	ProInitData.to_exp = to_exp
	local all_width = ProInitData.width
	ProInitData.target_width = to_exp/100 * all_width
	if ProInitData.target_width > all_width then
		ProInitData.target_width = all_width
		is_play_ani = false
	end

	if is_play_ani then
		if ProInitData.is_playing then
			return
		end
		ProInitData.is_playing = true
		NPL.SetTimer(10086, 0.05, ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua").Timer()');
	else
		ProInitData.ui_object.width = ProInitData.target_width
	end
	
end

function QuestPage.Timer()
	local width = ProInitData.ui_object.width + ProInitData.change_width
	if width < ProInitData.target_width then
		ProInitData.ui_object.width = width
	else
		ProInitData.ui_object.width = ProInitData.target_width
		NPL.KillTimer(10086)
		ProInitData.is_playing = false
	end
end

function QuestPage.OnClikcGift(gift_data)
	if gift_data.state == QuestPage.GiftState.can_get then
		local exid = gift_data.exid
		KeepWorkItemManager.DoExtendedCost(exid,function()
			local template = KeepWorkItemManager.GetGoal(exid);
			QuestRewardPage.Show(template[1].goods);

			QuestAction.SetGiftState(gift_data.gift_id, QuestPage.GiftState.has_get)
			QuestPage.RefreshData()
		end)
	end
end

function QuestPage.GetExp()
	return QuestAction.GetExp()
end

function QuestPage.FreshExpShow()
	if page == nil or not page:IsVisible() then
		return
	end
	
	page:SetUIValue("exp_desc", QuestAction.GetExp())
end