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

    SummerCampTaskPage.HandleQuestTaskData()
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

    return "Texture/Aries/Creator/keepwork/SummerCamp/item_bg_1_994x112_32bits.png#0 0 994 112"
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
	if task_data.task_id == 70009 then
        local SummerCampSignShowView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignShowView.lua") 
        SummerCampSignShowView.ShowView()
	elseif task_data.task_id == 70010 then
        GameLogic.GetCodeGlobal():BroadcastTextEvent("openRemainOriginalUI", {name = "mainPage"}, function()
           
        end);
	elseif task_data.task_id == 70011 then
		-- GameLogic.AddBBS(nil,"敬请期待~")
		GameLogic.GetCodeGlobal():BroadcastTextEvent("openLongMarchUI", {name = "mainPage"});
	elseif task_data.task_id == 70012 then
		GameLogic.AddBBS(nil,"敬请期待~")
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