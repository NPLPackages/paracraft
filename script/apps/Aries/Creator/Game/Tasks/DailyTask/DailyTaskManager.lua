--[[
Title: DailyTaskManager
Author(s): yangguiyi
Date: 2020/10/19
Desc:  
Use Lib:
-------------------------------------------------------
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
DailyTaskManager.Show();
--]]
local DailyTaskManager = NPL.export();
commonlib.setfield("MyCompany.Aries.Creator.Game.DailyTask.DailyTaskManager", DailyTaskManager);

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
local TaskKey = "daily_task_data"
DailyTaskManager.gsid = 40002;

DailyTaskManager.task_id_list = {
	-- NewPlayerGuid = "100",
	GrowthDiary = "101",
	WeekWork = "102",
	Classroom = "103",
	UpdataWorld = "104",
	VisitWorld = "105",
}

DailyTaskManager.task_data = {
	-- [DailyTaskManager.task_id_list.NewPlayerGuid] = {complete_times = 0, max_times = 1, is_get_reward = false},
	[DailyTaskManager.task_id_list.GrowthDiary] = {complete_times = 0, max_times = 1},
	[DailyTaskManager.task_id_list.WeekWork] = {complete_times = 0, max_times = 1},
	[DailyTaskManager.task_id_list.Classroom] = {complete_times = 0, max_times = 1},
	[DailyTaskManager.task_id_list.UpdataWorld] = {complete_times = 0, max_times = 1},
	[DailyTaskManager.task_id_list.VisitWorld] = {complete_times = 0, max_times = 5, visit_world_list = {}, },
	is_auto_open_view = false, -- 每日首次登陆是否有过弹窗的标记
	time_stamp = 0, -- 保存数据的日期
}

DailyTaskManager.exid_list = {
	-- [DailyTaskManager.task_id_list.NewPlayerGuid] = 40001,
	[DailyTaskManager.task_id_list.GrowthDiary] = 10001,
	[DailyTaskManager.task_id_list.WeekWork] = 10024,
	[DailyTaskManager.task_id_list.Classroom] = 10025,
	[DailyTaskManager.task_id_list.UpdataWorld] = 10026,
	[DailyTaskManager.task_id_list.VisitWorld] = 10027,
}

DailyTaskManager.desc_list = {
	-- [DailyTaskManager.task_id_list.NewPlayerGuid] = "你太棒了！奖励你%s个知识豆，再接再厉哦~",
	[DailyTaskManager.task_id_list.GrowthDiary] = "你太棒了！奖励你%s个知识豆，再接再厉哦~",
	[DailyTaskManager.task_id_list.WeekWork] = "为你的学习点赞，奖励你%s个知识豆，再接再厉哦~",
	[DailyTaskManager.task_id_list.Classroom] = "你太棒了！奖励你%s个知识豆，再接再厉哦~",
	[DailyTaskManager.task_id_list.UpdataWorld] = "为你的更新点赞！奖励你%s个知识豆，记得经常更新世界哦~",
	[DailyTaskManager.task_id_list.VisitWorld] = "你太棒了！奖励你%s个知识豆，再接再厉哦~",
}

function DailyTaskManager.GetTaskIdList()
	return DailyTaskManager.task_id_list
end

function DailyTaskManager.GetTaskData(task_id)
	local clientData = DailyTaskManager.GetClientData()
	local task_data = clientData[TaskKey]
	return task_data[task_id]
end

function DailyTaskManager.GetTaskRewardNum(exid)
	local bean_gsid = 998
	local template = KeepWorkItemManager.GetGoal(exid);
	local reward_num = 0
	if template and template[1] and template[1].goods then
		for k, v in pairs(template[1].goods) do
			if v.goods.gsId == bean_gsid then
				reward_num = v.amount
				break
			end
		end
	end

	return reward_num
end

-- local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
-- DailyTaskManager.AchieveTask(DailyTaskManager.task_id_list.Classroom)

-- 完成某个任务
function DailyTaskManager.AchieveTask(task_id, callback, exid)
	-- 没登录的话不记录数据
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        return
	end

	local clientData = DailyTaskManager.GetClientData()
	local task_data = clientData[TaskKey]
	local data = task_data[task_id]
	if data == nil then
		return
	end

	if DailyTaskManager.CheckTaskCompelete(task_id) then
		return
	end

	exid = exid or DailyTaskManager.GetTaskExidByTaskId(task_id)
	local reward_num = DailyTaskManager.GetTaskRewardNum(exid)

	KeepWorkItemManager.DoExtendedCost(exid, function()
		data.complete_times = data.complete_times + 1

		local desc = DailyTaskManager.desc_list[task_id] or "你太棒了！奖励你%s个知识豆，再接再厉哦~"
		desc = string.format(desc, reward_num)
		GameLogic.AddBBS("desktop", desc, 3000, "0 255 0");
		if callback then
			callback()
		end

		KeepWorkItemManager.SetClientData(DailyTaskManager.gsid, clientData)
	end);

	-- data.complete_times = data.complete_times + 1

	-- local desc = DailyTaskManager.desc_list[task_id] or "你太棒了！奖励你%s个知识豆，再接再厉哦~"
	-- if desc ~= "" then
	-- 	desc = string.format(desc, reward_num)
	-- 	GameLogic.AddBBS("desktop", desc, 3000, "0 255 0");
	-- 	if callback then
	-- 		callback()
	-- 	end
	-- end

	-- KeepWorkItemManager.SetClientData(DailyTaskManager.gsid, clientData)
end

function DailyTaskManager.GetClientData()
	local clientData = KeepWorkItemManager.GetClientData(DailyTaskManager.gsid) or {};
	local is_new_day, time_stamp = DailyTaskManager.CheckIsNewDay(clientData)
	if is_new_day then
		-- 新手引导任务 完成了之后 不清除数据
		if clientData[TaskKey] then
			local new_player_guid_task_data = clientData[TaskKey][DailyTaskManager.task_id_list.NewPlayerGuid]
			if new_player_guid_task_data then
				DailyTaskManager.task_data[DailyTaskManager.task_id_list.NewPlayerGuid] = new_player_guid_task_data
			end
		end

		clientData[TaskKey] = DailyTaskManager.task_data
		clientData[TaskKey].time_stamp = time_stamp
		clientData[TaskKey].is_auto_open_view = false
	end
	return clientData
end

-- 检测是否新一天的数据
function DailyTaskManager.CheckIsNewDay(clientData)
	if clientData[TaskKey] == nil then
		return true, 0
	end
    local time_stamp = clientData[TaskKey].time_stamp or 0;
	-- 获取今日凌晨的时间戳 1603949593
	local cur_time_stamp = os.time()
    local cur_year = os.date("%Y", cur_time_stamp)	
    local cur_month = os.date("%m", cur_time_stamp)
	local cur_day = os.date("%d", cur_time_stamp)
	local day_time_stamp = os.time({year = cur_year, month = cur_month, day = cur_day, hour=0, minute=0, second=0})

	-- 天数改变 清除数据
	if day_time_stamp > time_stamp then
		return true, day_time_stamp
	end

	return false, time_stamp
end

function DailyTaskManager.GetTaskExidByTaskId(task_id)
	return DailyTaskManager.exid_list[task_id] or 0
end

function DailyTaskManager.CheckTaskCompelete(task_id)
	local clientData = DailyTaskManager.GetClientData()
	local task_data = clientData[TaskKey]
	local data = task_data[task_id]
	if data == nil then
		return true
	end

	if task_id == DailyTaskManager.task_id_list.GrowthDiary then
		return ParacraftLearningRoomDailyPage.HasCheckedToday()-- 成长日记 以是否签到了为标准 现在是否签到成功改成看20秒之后才算成功
	end

	if data.complete_times >= data.max_times then
		return true
	end

	return false
end

function DailyTaskManager.AutoOpenDailyTaskView()
	if TaskKey == nil then
		return
	end
	
	if MyCompany.Aries.Creator.Game.Desktop.App == nil then
		return
	end

	if DailyTaskManager.CheckIsFirstOpenView() then
		return
	end

	-- local DailyTask = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTask.lua");
	-- DailyTask.Show();
	local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
	QuestPage.Show();

	local clientData = DailyTaskManager.GetClientData()
	clientData[TaskKey].is_auto_open_view = true
	KeepWorkItemManager.SetClientData(DailyTaskManager.gsid, clientData)
end

function DailyTaskManager.DelayOpenDailyTaskView()	
	commonlib.TimerManager.SetTimeout(function()
		-- 没过新手 不弹这个窗口
        if not KeepWorkItemManager.HasGSItem(60000) and (System.User.realname == nil or System.User.realname == "") then
            return
		end
		
		local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
		if DockPage.IsShow() then
			if(not KeepWorkItemManager.IsLoaded())then
				KeepWorkItemManager.GetFilter():add_filter("loaded_all", open_cb);
				return
			end
		
			DailyTaskManager.AutoOpenDailyTaskView()
		end
	end, 3000);
end

-- 检测当天是否自动弹出过任务面板
function DailyTaskManager.CheckIsFirstOpenView()
	local clientData = DailyTaskManager.GetClientData()
	return clientData[TaskKey].is_auto_open_view
end

function DailyTaskManager.AchieveVisitWorldTask(key)
	-- 探索同一个世界的话无效
	local task_id = DailyTaskManager.task_id_list.VisitWorld
	local task_data = DailyTaskManager.GetTaskData(task_id)

	if task_data.visit_world_list == nil then
		task_data.visit_world_list = {}
	end

	local visit_world_list = task_data.visit_world_list or {}
	if task_data.visit_world_list[key] == nil then
		task_data.visit_world_list[key] = 1
		DailyTaskManager.AchieveTask(task_id)
	end
end

function DailyTaskManager.GetTaskExidList()
	return DailyTaskManager.exid_list
end

function DailyTaskManager.AchieveNewPlayerTask()
	-- 没登录的话不记录数据
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        return
	end
	local task_id = DailyTaskManager.task_id_list.NewPlayerGuid
	local clientData = DailyTaskManager.GetClientData()
	local task_data = clientData[TaskKey]
	local data = task_data[task_id]
	if data == nil then
		return
	end

	if DailyTaskManager.CheckTaskCompelete(task_id) then
		return
	end

	data.complete_times = data.complete_times + 1
	KeepWorkItemManager.SetClientData(DailyTaskManager.gsid, clientData)
end

function DailyTaskManager.IsAllTaskComplete()
	local id_list = DailyTaskManager.GetTaskIdList()
	local is_all_complete = true
	for k, v in pairs(id_list) do
		if not DailyTaskManager.CheckTaskCompelete(v) then
			is_all_complete = false
			break
		end
	end

	return is_all_complete
end