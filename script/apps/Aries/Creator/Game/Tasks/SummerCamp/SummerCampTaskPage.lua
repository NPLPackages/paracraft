--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampTaskPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampTaskPage.lua") 
SummerCampTaskPage.ShowView()
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua")
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local SummerCampTaskPage = NPL.export()

local SummerCampDailyTask = {
	{
        {name="探索世界：FindYou", world_id = 242},
        {name="学习课程：拜访帕帕的家", world_id = 42457, course_id = 1},
    },

    {
        {name="探索世界：当下的力量", world_id = 1070},
        {name="学习课程：拜访拉拉的家", world_id = 42701, course_id = 2},
    },

    {
        {name="探索世界：伟大的发明家", world_id = 470},
        {name="学习课程：拜访卡卡的家", world_id = 42670, course_id = 3},
    },

    {
        {name="探索世界：火星探险", world_id = 1082},
        {name="学习课程：快速移动的方法", world_id = 44620, course_id = 11},
    },

    {
        {name="探索世界：圆的故事", world_id = 94},
        {name="学习课程：跳转：在场景中穿梭", world_id = 44747, course_id = 16},
    },

    {
        {name="探索世界：在山的那边", world_id = 96},
        {name="学习课程：如何选择一组方块", world_id = 44708, course_id = 12},
    },

    {
        {name="探索世界：晓出净慈寺送林子方", world_id = 7945},
        {name="学习课程：跳转：在场景中穿梭", world_id = 49658, course_id = 37},
    },

    {
        {name="探索世界：象形之美", world_id = 2769},
        {name="学习课程：选择方块的命令/take", world_id = 44859, course_id = 19},
    },

    {
        {name="探索世界：永生的雪人", world_id = 158},
        {name="学习课程：通知提醒命令/tip", world_id = 44628, course_id = 10},
    },

    {
        {name="探索世界：父亲", world_id = 1073},
        {name="学习课程：控制阴影的命令/shader", world_id = 44627, course_id = 6},
    },

    {
        {name="探索世界：有了想法你怎么做", world_id = 455},
        {name="学习课程： 旋转木马", world_id = 49764, course_id = 92},
    },
	-- 12号到18号
	{
        {name="探索世界：地球的颜色", world_id = 1066},
        {name="学习课程：神秘空间1", world_id = 49661, course_id = 38},
    },
	{
        {name="探索世界：森林之王", world_id = 569},
        {name="学习课程：神秘空间2", world_id = 49665, course_id = 39},
    },
	{
        {name="探索世界：宇宙快递", world_id = 506},
        {name="学习课程：神秘空间3", world_id = 49678, course_id = 40},
    },
	{
        {name="探索世界：美丽心灵", world_id = 164},
        {name="学习课程：自动录制与视频输出", world_id = 49682, course_id = 41},
    },
	{
        {name="探索世界：StoryOfMyLife", world_id = 211},
        {name="学习课程：变装小魔术", world_id = 49686, course_id = 42},
    },
	{
        {name="探索世界：吃货的一天", world_id = 459},
        {name="学习课程：滚动吧！轮子", world_id = 49688, course_id = 44},
    },
	{
        {name="探索世界：游乐园", world_id = 48674},
        {name="学习课程：计时动画", world_id = 49687, course_id = 43},
    },
	-- 19号到25号
	-- {
    --     {name="探索世界：这就是我", world_id = 1164},
    --     {name="学习课程：椅子", world_id = 49651, course_id = 92},
    -- },
	-- {
    --     {name="探索世界：雨思", world_id = 175},
    --     {name="学习课程：铅笔", world_id = 49653, course_id = 92},
    -- },
	-- {
    --     {name="探索世界：苍玺城·梦的旅人", world_id = 1079},
    --     {name="学习课程：拱形门", world_id = 49654, course_id = 92},
    -- },
	-- {
    --     {name="探索世界：排队", world_id = 150},
    --     {name="学习课程：铁链", world_id = 49657, course_id = 92},
    -- },
	-- {
    --     {name="探索世界：威斯特利亚别墅", world_id = 169},
    --     {name="学习课程：导出CAD模型", world_id = 49660, course_id = 92},
    -- },
	-- {
    --     {name="探索世界：大徽宫", world_id = 156},
    --     {name="学习课程：爱心", world_id = 49663, course_id = 92},
    -- },
	-- {
    --     {name="探索世界：烟雨庄", world_id = 513},
    --     {name="学习课程：西瓜", world_id = 49675, course_id = 92},
    -- },

	-- 19号到25号
}

local VersionToKey = {
	ONLINE = 1,
	RELEASE = 2,
	LOCAL = 3,
}
local page = nil

function SummerCampTaskPage.OnInit()
    page = document:GetPageCtrl();
end

function SummerCampTaskPage.ShowView(parent)
    SummerCampTaskPage.InitData()

    local view_width = 1035
    local view_height = 623

    page = Map3DSystem.mcml.PageCtrl:new({ 
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampTaskPage.html" ,
        click_through = false,
    } );
    SummerCampTaskPage._root = page:Create("SummerCampTaskPage.ShowView", parent, "_lt", 0, 0, view_width, view_height)

    return page
end

function SummerCampTaskPage.CloseView()
    -- body
end

function SummerCampTaskPage.InitData()
-- QuestAction.SummerCampTaskData = {
--     [70009] = {name = "闪闪红星", exid = 31066, gsid = 70009, max_pro = 1},
--     [70010] = {name = "不忘初心", exid = 31067, gsid = 70010, max_pro = 20},
--     [70011] = {name = "红色先锋", exid = 31068, gsid = 70011, max_pro = 10},
--     [70012] = {name = "时代接班人", exid = 31069, gsid = 70012, max_pro = 15},
-- }
    SummerCampTaskPage.TaskData = {}
    local gsid_list = {
        {gsid = 70010},
        {gsid = 70011},
        {gsid = 70012},
        {gsid = 70009},
    }

    SummerCampTaskPage.TaskData = {}
    for i, v in ipairs(gsid_list) do
        local task_data = QuestAction.GetSummerCampTaskData(v.gsid)
        local data = {}
        data.name = task_data.name
        data.task_desc = task_data.desc

        data.value = QuestAction.GetSummerTaskProgress(task_data.gsid)
        data.task_pro_desc = data.value .. "/" .. task_data.max_pro
        data.task_state = data.value >= task_data.max_pro and QuestPage.TaskState.has_complete or QuestPage.TaskState.can_go
        data.task_id = task_data.gsid
        data.gsid = task_data.gsid
        data.max_pro = task_data.max_pro
        data.is_summer_task = true
        data.bg_img = SummerCampTaskPage.GetItemBgImg(data)
        data.is_show_progress = true

        SummerCampTaskPage.TaskData[#SummerCampTaskPage.TaskData + 1] = data
    end

	SummerCampTaskPage.HandleSummerSpecialTaskData()
	SummerCampTaskPage.HandleSummerDailyTaskData()
    SummerCampTaskPage.HandleQuestTaskData()
end

local kangyi_task_data = {
	{taskId="40025_60028_1"},
	{taskId="40026_60029_1"},
	{taskId="40026_60029_2"},
	{taskId="40026_60029_3"},
	{taskId="40026_60029_4"},
	{taskId="40026_60029_5"},
	{taskId="40026_60029_6"},
	{taskId="40026_60029_7"},
	{taskId="40026_60029_8"},
	{taskId="40026_60029_9"},
	{taskId="40026_60029_10"},
	{taskId="40026_60029_11"},
	{taskId="40026_60029_12"},
	{taskId="40026_60029_13"},
	{taskId="40026_60029_14"},
	{taskId="40026_60029_15"},
	{taskId="40026_60029_16"},
	{taskId="40027_60030_1"},
}

-- 处理夏令营一些特殊任务 比如抗疫
function SummerCampTaskPage.HandleSummerSpecialTaskData()
	local exid = 40025
	local data = {}
	local name = "抗疫小能手"
	local desc = "完成抗疫小能手任务"
	data.name = name
	data.task_id = exid
	data.task_desc = desc
	data.max_pro = 0
	data.value = 0
	data.max_pro = #kangyi_task_data
	for i, v in ipairs(kangyi_task_data) do
		local child_value = GameLogic.QuestAction.GetValue(v.taskId) or 0
		if child_value > 0 then
			data.value = data.value + 1
		end
	end
	
	data.task_state = data.value >= data.max_pro and QuestPage.TaskState.has_complete or QuestPage.TaskState.can_go
	data.is_show_progress = true
	data.task_pro_desc = data.value .. "/" .. data.max_pro
	
	data.is_summer_task = true
	data.bg_img = SummerCampTaskPage.GetItemBgImg(data)
	-- data.questItemContainer = v.questItemContainer

	SummerCampTaskPage.TaskData[#SummerCampTaskPage.TaskData + 1] = data
end

-- 处理夏令营日常任务
function SummerCampTaskPage.HandleSummerDailyTaskData()
	local data_list = QuestAction.GetTodaySummerDailyTaskData()
    for i, v in ipairs(data_list) do
        local task_data = v
		local max_pro = 1
        local data = {}
        data.name = "【每日专属】" .. task_data.name
        data.task_desc = task_data.desc or ""

        data.value = QuestAction.GetSummerDailyTaskProgress(i)
        data.task_pro_desc = data.value .. "/" .. max_pro
        data.task_state = data.value >= max_pro and QuestPage.TaskState.has_complete or QuestPage.TaskState.can_go
        data.task_id = i
		data.world_id = v.world_id
		data.course_id = v.course_id
        data.max_pro = max_pro
        data.is_summer_daily_task = true
        data.bg_img = SummerCampTaskPage.GetItemBgImg(data)
        data.is_show_progress = true

        SummerCampTaskPage.TaskData[#SummerCampTaskPage.TaskData + 1] = data
    end
end

-- 加入原本的任务
function SummerCampTaskPage.HandleQuestTaskData()
	-- 先把新手引导任务插进去 新手引导任务用的是新的数据读取方式	
    SummerCampTaskPage.QusetTaskData = {}
	local quest_datas = QuestProvider:GetInstance():GetQuestItems()
	for i, v in ipairs(quest_datas) do
		-- 获取兑换规则
		if QuestPage.GetTaskVisible(v) then
			local exid = v.exid
			local index = #SummerCampTaskPage.QusetTaskData + 1
			local data = {}
			local exchange_data = KeepWorkItemManager.GetExtendedCostTemplate(exid) or {}
			local name = exchange_data.name or ""
			local desc = exchange_data.desc or ""
            data.quest_data_index = i
			data.name = name
			data.task_id = v.exid
			data.task_desc = desc
            
            data.task_type = QuestPage.GetTaskType(v)
            local childrens = v.questItemContainer.children or {}
            local data_item = childrens[1] or {}
            data.value = data_item.value or 0
            if data.task_type == "loop" then
                data.value = QuestAction.GetDailyTaskValue(data_item.id)
            end
            data.is_show_progress = true

            
			
			data.task_pro_desc = SummerCampTaskPage.GetTaskProDescByQuest(v, data.task_type)

            if type(data_item.finished_value) == "number" then
                data.max_pro = data_item.finished_value
            else
                data.is_show_progress = false
            end

            if data.task_pro_desc == "" then
                data.is_show_progress = false
            end
			data.task_state = QuestPage.GetTaskStateByQuest(v, data.task_type)
            
            data.is_main_task = data.task_type == "main"
			data.exp = QuestPage.GetTaskExp(v)
			data.order = QuestPage.GetTaskOrder(v)
            data.is_quest_task = true
			data.bg_img = SummerCampTaskPage.GetItemBgImg(data)
			-- data.questItemContainer = v.questItemContainer


			SummerCampTaskPage.QusetTaskData[index] = data
		end
	end

	-- 主线任务在前
	table.sort(SummerCampTaskPage.QusetTaskData, function(a, b)
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

    for index, v in ipairs(SummerCampTaskPage.QusetTaskData) do
        SummerCampTaskPage.TaskData[#SummerCampTaskPage.TaskData + 1] = v
    end
end

function SummerCampTaskPage.GetTaskProDesc(index)
    local task_data = SummerCampTaskPage.TaskData[index]
    if task_data.is_quest_task then
        local quest_datas = QuestProvider:GetInstance():GetQuestItems()
        local data = quest_datas[task_data.quest_data_index]
        local desc = SummerCampTaskPage.GetTaskProDescByQuest(data, task_data.task_type)
        return desc
    end

    local value = QuestAction.GetSummerTaskProgress(task_data.gsid)
    return value .. "/" .. task_data.max_pro
end

function SummerCampTaskPage.GetItemBgImg(data)
    if data.is_summer_task == true then
        return "Texture/Aries/Creator/keepwork/SummerCamp/item_bg_1_994x112_32bits.png#0 0 994 112"
    end

    if data.is_quest_task == true then
        return "Texture/Aries/Creator/keepwork/SummerCamp/item_bg_3_994x112_32bits.png#0 0 994 112"
    end

    return "Texture/Aries/Creator/keepwork/SummerCamp/item_bg_2_994x112_32bits.png#0 0 994 112"
end

function SummerCampTaskPage.GetTaskProDescByQuest(data, task_type)
    local childrens = data.questItemContainer.children
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
		local temp_desc = ""
		
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

function SummerCampTaskPage.GetQuestTaskFinishValue(data)
    local childrens = data.questItemContainer.children
	local desc = ""

	local data_item = childrens[1]
	local child_task_desc = ""
	if data_item.id == "40005_1" then
		return 0
	end
	if type(data_item.finished_value) == "number" then
		local value = data_item.value or 0
		if task_type == "loop" then
			value = QuestAction.GetDailyTaskValue(data_item.id)
		end
		local temp_desc = ""
		
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

function SummerCampTaskPage.RefreshData()
	if page == nil or not page:IsVisible() then
		return
	end
    SummerCampTaskPage.InitData()
    page:Refresh(0.01)
end

function SummerCampTaskPage.GetProgressBarValue(index)
    local task_data = SummerCampTaskPage.TaskData[index]
    local value = QuestAction.GetSummerTaskProgress(task_data.gsid)
    return value
end

function SummerCampTaskPage.GetReward(index)
    local task_data = SummerCampTaskPage.TaskData[index]
    if task_data.is_quest_task then
        SummerCampTaskPage.GetQuestTaskReward(index)
        return
    end
end

function SummerCampTaskPage.Goto(index)
    local task_data = SummerCampTaskPage.TaskData[index]
    if task_data.is_quest_task then
        SummerCampTaskPage.QuestTaskGoto(task_data.task_id)
        return
    end

	-- QuestAction.SummerCampTaskData = {
--     [70009] = {name = "闪闪红星", exid = 31066, gsid = 70009, max_pro = 1},
--     [70010] = {name = "不忘初心", exid = 31067, gsid = 70010, max_pro = 20},
--     [70011] = {name = "红色先锋", exid = 31068, gsid = 70011, max_pro = 10},
--     [70012] = {name = "时代接班人", exid = 31069, gsid = 70012, max_pro = 15},
-- }
	if task_data.is_summer_task then
		local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
		SummerCampMainPage.CloseView()
		if task_data.task_id == 70009 then
			local SummerCampSignShowView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignShowView.lua") 
			SummerCampSignShowView.ShowView()

		elseif task_data.task_id == 70010 then
			GameLogic.GetCodeGlobal():BroadcastTextEvent("openRemainOriginalUI", {name = "mainPage"}, function()
			end);
		elseif task_data.task_id == 70011 then
			GameLogic.GetCodeGlobal():BroadcastTextEvent("openLongMarchUI", {name = "mainPage"});
		elseif task_data.task_id == 70012 then
			GameLogic.RunCommand(string.format("/goto %s %s %s", 18876,12,19189))
		elseif task_data.name == "抗疫小能手" then
			GameLogic.GetCodeGlobal():BroadcastTextEvent("openUI", {name = "taskMain"}, function()
			end);
		end
	end

	if task_data.is_summer_daily_task then
		if task_data.course_id then
			local id_str = tostring(task_data.course_id)

			keepwork.quest_course.search({
				ids=id_str,
			}, function(err, msg, data)
				-- print("xxxxxx", err)
				-- echo(data, true)
				if err == 200 then
					data = data[1]
					local course_id = data.id
					keepwork.quest_complete_course.get({
						aiCourseId = course_id,
					}, function(err2, msg2, data2)
						-- print("bbbbb", err2)
						-- echo(data2, true)
						if err2 == 200 then
							local work_data = data.aiHomework or {}
								
							local client_data = QuestAction.GetClientData()
				
							client_data.course_id = course_id
							client_data.home_work_id = work_data.id or -1
							client_data.is_home_work = false
							
							client_data.course_step = 0
							if data2.userAiCourse and data2.userAiCourse.progress then
								client_data.course_step = data2.userAiCourse.progress.stepNum or 0
							end
							KeepWorkItemManager.SetClientData(QuestAction.task_gsid, client_data)
				
							local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
							SummerCampMainPage.CloseView()
							GameLogic.GetFilters():apply_filters('cellar.common.common_load_world.enter_course_world', course_id, false, data.projectReleaseId)
						end
					end)
				end
			end)
		else
			local world_id = task_data.world_id
			local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
			SummerCampMainPage.CloseView()
			local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
			CommandManager:RunCommand(string.format('/loadworld -force -s %s', world_id))
		end
    end
end

function SummerCampTaskPage.QuestTaskGoto(task_id)
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
						if page and page:IsVisible() then
							page:CloseWindow()
							QuestPage.CloseView()
						end
						QuestPage.EnterWorld(world_id)
					end

					break
				elseif v.template.click and v.template.click ~= "" then
					if string.find(v.template.click, "loadworld ") then
						if page and page:IsVisible() then
							page:CloseWindow()
							QuestPage.CloseView()
						end
					end
					NPL.DoString(v.template.click)
				end
				-- echo(v, true)
			end
		end
	end

	GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.quest_action.click_go_button')
end

-- 这里的task_id 其实就是exid
function SummerCampTaskPage.GetQuestTaskReward(index)
	local task_data = SummerCampTaskPage.TaskData[index]
	if nil == task_data then
		return
	end

	local quest_data = QuestPage.GetQuestData(task_data.task_id)
	if quest_data == nil then
		return
	end

	if task_data.task_type == "loop" then
		-- 先加上探索力
		if task_data.exp and task_data.exp > 0 then
			QuestAction.AddExp(task_data.exp, function()
			end)
		end

		local childrens = quest_data.questItemContainer.children or {}
		
		for i, v in ipairs(childrens) do
			QuestAction.FinishDailyTask(v.template.id)
		end
		
		SummerCampTaskPage.RefreshData()
	else
		
		if quest_data.questItemContainer then
			quest_data.questItemContainer:DoFinish()
		end
	end
end

function SummerCampTaskPage.GetSummerCampDailyTask()
	return SummerCampDailyTask
end