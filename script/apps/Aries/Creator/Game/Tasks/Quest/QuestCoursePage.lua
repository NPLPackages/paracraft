--[[
Title: QuestCoursePage
Author(s): yangguiyi
Date: 2021/01/17
Desc:  
Use Lib:
-------------------------------------------------------
local QuestCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestCoursePage.lua");
QuestCoursePage.Show();
--]]
local QuestCoursePage = NPL.export();
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

commonlib.setfield("MyCompany.Aries.Creator.Game.Task.Quest.QuestCoursePage", QuestCoursePage);
local page;
QuestCoursePage.isOpen = false
QuestCoursePage.TaskData = {}
QuestCoursePage.is_add_event = false
QuestCoursePage.begain_time_t = {year=2021, month=1, day=28, hour=0, min=0, sec=0}

QuestCoursePage.GiftState = {
	can_not_get = 0,		--未能领取
	can_get = 1,			--可领取
	has_get = 2,			--已领取
}

QuestCoursePage.TaskState = {
	can_go = 0,
	has_go = 1,
	can_not_go = 2,
}

QuestCoursePage.CourseData = {}

QuestCoursePage.CourseTimeLimit = {
	{begain_time = {hour=0,min=0}, end_time = {hour=24,min=0}},
	-- {begain_time = {hour=13,min=30}, end_time = {hour=13,min=45}},
	-- {begain_time = {hour=16,min=0}, end_time = {hour=16,min=15}},
	-- {begain_time = {hour=18,min=0}, end_time = {hour=18,min=15}},
	-- {begain_time = {hour=19,min=0}, end_time = {hour=19,min=15}},
}

QuestCoursePage.ToCourseState = {
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

function QuestCoursePage.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = QuestCoursePage.CloseView
	page.OnCreate = QuestCoursePage.OnCreate()
end

function QuestCoursePage.OnCreate()
end

-- is_make_up 是否补课面板
function QuestCoursePage.Show(is_make_up)
	QuestCoursePage.is_make_up = is_make_up
    if(not GameLogic.GetFilters():apply_filters('is_signed_in'))then
        return
    end
	keepwork.user.server_time({}, function(err, msg, data)
		if err == 200 then
			server_time = commonlib.timehelp.GetTimeStampByDateTime(data.now, true)
			today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time)
			QuestAction.SetServerTime(server_time)

			local begain_day_weehours = os.time(QuestCoursePage.begain_time_t)
			if server_time < begain_day_weehours then
				GameLogic.QuestAction.ShowDialogPage({"还没到课程开启时间哟！", "从1月28日起，每天记得在10:30 13:30 16:00 18:00 19:00过来听课吧！"})
				return
			end

			-- 如果是补课的话 判断下是否在不建议的时间段 正常课程的前45分钟之后 就属于不建议时间段
			if not QuestCoursePage.IsGraduateTime(server_time) then
				if QuestCoursePage.is_make_up then
					for i, v in ipairs(QuestCoursePage.CourseTimeLimit) do
						local begain_time_stamp = today_weehours + v.begain_time.min * 60 + v.begain_time.hour * 3600 - 45 * 60
						local end_time_stamp = today_weehours + v.end_time.min * 60 + v.end_time.hour * 3600
				
						if server_time >= begain_time_stamp and server_time <= end_time_stamp then
							-- _guihelper.MessageBox("现在补课可能会耽误新课程的正常学习，请稍后再来", nil, nil,nil,nil,nil,nil,{ ok = L"确定"});
							-- _guihelper.MsgBoxClick_CallBack = function(res)
							-- 	if(res == _guihelper.DialogResult.OK) then
							-- 		QuestCoursePage.ShowView()
							-- 	end
							-- end

							-- GameLogic.QuestAction.ShowDialogPage(L"现在补课可能会耽误新课程的正常学习，请稍后再来", function()
							-- 	QuestCoursePage.ShowView()
							-- end)
							QuestCoursePage.ShowView()
							return
						end
					end
				else
					local course_time_state, next_time_index = QuestCoursePage.CheckCourseTimeState(server_time)
					if course_time_state ~= QuestCoursePage.ToCourseState.in_time then
						if course_time_state == QuestCoursePage.ToCourseState.late then
							next_time_index = next_time_index or 0
							local next_time_data = QuestCoursePage.CourseTimeLimit[next_time_index]
							local cur_time_data = QuestCoursePage.CourseTimeLimit[next_time_index - 1]
							if next_time_data and cur_time_data then
								local hour = next_time_data.begain_time.hour >= 10 and next_time_data.begain_time.hour or "0" .. next_time_data.begain_time.hour
								local min = next_time_data.begain_time.min >= 10 and next_time_data.begain_time.min or "0" .. next_time_data.begain_time.min
								local next_time = string.format("%s:%s", hour, min)

								local next_time_stamp = today_weehours + next_time_data.begain_time.min * 60 + next_time_data.begain_time.hour * 3600
								
								local second_limit = 10 * 60
								local left_time = next_time_stamp - server_time
								local pre_desc = "您已迟到"
								if left_time < second_limit then
									local min = math.ceil( left_time / 60 )  -- 取整数
									-- local sec = math.fmod( left_time, 60 )    -- 取余数
									pre_desc = string.format("课程%s分钟后开始", min)
								else
									local cur_hour = cur_time_data.begain_time.hour >= 10 and cur_time_data.begain_time.hour or "0" .. cur_time_data.begain_time.hour
									local cur_min = cur_time_data.begain_time.min >= 10 and cur_time_data.begain_time.min or "0" .. cur_time_data.begain_time.min
									pre_desc = string.format("您已错过本堂课(%s:%s)", cur_hour, cur_min)
								end
								
								local desc = string.format(L"%s，请下一堂课(%s)再来，切记不可再迟到了哟！", pre_desc, next_time)
								GameLogic.QuestAction.ShowDialogPage(desc)
							else
								GameLogic.QuestAction.ShowDialogPage(L"您已迟到，请下一堂课再来，切记不可再迟到了哟！")
							end
							-- GameLogic.QuestAction.ShowDialogPage(L"您已迟到，请下一堂课再来，切记不可再迟到了哟！")
						elseif course_time_state == QuestCoursePage.ToCourseState.before then
							local first_time_data = QuestCoursePage.CourseTimeLimit[1]
							local hour = first_time_data.begain_time.hour >= 10 and first_time_data.begain_time.hour or "0" .. first_time_data.begain_time.hour
							local min = first_time_data.begain_time.min >= 10 and first_time_data.begain_time.min or "0" .. first_time_data.begain_time.min
							local next_time = string.format("%s:%s", hour, min)
							GameLogic.QuestAction.ShowDialogPage(string.format("今日课程还未开始，请在门口课程表上指定的开始时间(%s)来上课哟！", next_time))
						elseif course_time_state == QuestCoursePage.ToCourseState.finish then
							GameLogic.QuestAction.ShowDialogPage(L"今日课程已经结束，请在门口课程表上指定的时间段内前来上课哟！")
						else
							GameLogic.QuestAction.ShowDialogPage(L"请在门口课程表上指定的时间段内前来上课哟！")
						end
						
						return
					end
				end
			end

			QuestCoursePage.ShowView()
		end
	end)
end

function QuestCoursePage.RefreshData()
	if page == nil or not page:IsVisible() then
		return
	end
	
	keepwork.user.server_time({}, function(err, msg, data)
		if err == 200 then
			if not QuestCoursePage.IsVisible() then
				return
			end

			server_time = commonlib.timehelp.GetTimeStampByDateTime(data.now, true)
			today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time)

			QuestCoursePage.HandleTaskData()
			QuestCoursePage.HandleCourseData()
			QuestCoursePage.OnRefreshGridView()
			QuestCoursePage.OnRefreshGiftGridView()
		end
	end)
end

function QuestCoursePage.ShowView()
	if page and page:IsVisible() then
		page:CloseWindow()
		-- QuestCoursePage.CloseView()
	end

	-- if QuestProvider.GetInstance == nil then
	-- 	return
	-- end
	QuestCoursePage.HandleTaskData()
	QuestCoursePage.HandleCourseData()
	
	if not QuestCoursePage.is_add_event then
		QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnRefresh,function()
			if not page or not page:IsVisible() then
				return
			end
			QuestCoursePage.RefreshData()
			
		end, nil, "QuestCoursePage_Event_Init")

		QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnFinished,function(__, event)
			if not page or not page:IsVisible() then
				return
			end

			-- local questItemContainer = event.quest_item_container
			-- local childrens = questItemContainer.children
			-- QuestCoursePage.RefreshData()
		end, nil, "QuestCoursePage_OnFinished")

		QuestCoursePage.is_add_event = true
	end

    local bagNo = 1007;
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            modele_bag_id = bag.id;
            break;
        end
    end
	

	QuestCoursePage.isOpen = true
	local view_width = 960
	local view_height = 580
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestCoursePage.html",
			name = "QuestCoursePage.Show", 
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

function QuestCoursePage.IsVisible()
	if page == nil then
		return false
	end
	return page:IsVisible()
end

function QuestCoursePage.OnRefreshGridView()
    -- if(page)then
    --     page:Refresh(0);
	-- end
	
	local gvw_name = "item_gridview";
	local node = page:GetNode(gvw_name);
	pe_gridview.DataBind(node, gvw_name, false);
end

function QuestCoursePage.OnRefreshGiftGridView()
    -- if(page)then
    --     page:Refresh(0);
	-- end
	
	local gvw_name = "gift_gridview";
	local node = page:GetNode(gvw_name);
	pe_gridview.DataBind(node, gvw_name, false);
end

function QuestCoursePage.CloseView()
	QuestCoursePage.isOpen = false
	NPL.KillTimer(10086);

	local file_fold_name = "Texture/Aries/Creator/keepwork/Quest/"
	local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	Files:UnloadFoldAssets(file_fold_name);
end

function QuestCoursePage.EnterWorld(world_id)
	page:CloseWindow()
	QuestCoursePage.CloseView()
	local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
	CommandManager:RunCommand(string.format('/loadworld -force -s %s', world_id))

	-- QuestCoursePage.RefreshData()
end

function QuestCoursePage.WeekWork()
	local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
	TeachingQuestLinkPage.ShowPage();
end

function QuestCoursePage.Classroom()
	local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
	StudyPage.clickArtOfWar();
end

function QuestCoursePage.UpdataWorld()
	if(mouse_button == "right") then
		GameLogic.GetFilters():apply_filters('show_console_page')
	else
		-- the new version
		GameLogic.GetFilters():apply_filters('show_create_page')
	end
end

function QuestCoursePage.VisitWorld()
	GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
end

function QuestCoursePage.GetCompletePro(data)
	local task_id = data.task_id or "0"
	local task_data = DailyTaskManager.GetTaskData(task_id)
	local complete_times = task_data.complete_times or 0

	return complete_times .. "/" .. task_data.max_times
end

function QuestCoursePage.HandleTaskData(data)
	QuestCoursePage.TaskData = {}

	if QuestCoursePage.TaskAllData == nil then
		local quest_datas = QuestProvider:GetInstance().templates_map
		local exid_list = {}
		QuestCoursePage.TaskAllData = {}
		for i, v in pairs(quest_datas) do
			-- 获取兑换规则
			if exid_list[v.exid] == nil and v.exid >= QuestAction.begain_exid and v.exid <= QuestAction.end_exid then
				exid_list[v.exid] = 1
				local index = #QuestCoursePage.TaskAllData + 1
				QuestCoursePage.TaskAllData[index] = v
			end
		end

        table.sort(QuestCoursePage.TaskAllData,function(a,b)
            return a.gsid < b.gsid
        end)
	end
	local quest_datas = QuestProvider:GetInstance().templates_map
	for i, v in pairs(QuestCoursePage.TaskAllData) do
		-- 获取兑换规则
		if QuestCoursePage.GetTaskVisible(v) then
			local index = #QuestCoursePage.TaskData + 1
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
			task_data.task_type = QuestCoursePage.GetTaskType(v)
			task_data.is_main_task = task_data.task_type == "main"
			task_data.goto_world = v.goto_world
			task_data.click = v.click
			task_data.task_pro_desc = QuestCoursePage.GetTaskProDescByQuest(v)
			task_data.task_state = QuestCoursePage.GetTaskStateByQuest(task_data)
			task_data.order = QuestCoursePage.GetTaskOrder(v)
			task_data.bg_img = QuestCoursePage.GetBgImg(task_data)
			-- task_data.questItemContainer = v.questItemContainer

			task_data.goods_data = {}
			-- for i2, v2 in ipairs(exchange_data.exchangeTargets[1].goods) do
			-- 	if v2.goods.gsId < 60001 or v2.goods.gsId > 70000 then
			-- 		if #task_data.goods_data < 3 then
			-- 			task_data.goods_data[#task_data.goods_data + 1] = v2
			-- 		end
			-- 	end
			-- end
			QuestCoursePage.TaskData[index] = task_data
		end
	end

	-- 主线任务在前
	table.sort(QuestCoursePage.TaskData, function(a, b)
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

		-- if a.task_state == QuestCoursePage.TaskState.has_complete then
		-- 	value_a = value_a - 10000
		-- end
		-- if b.task_state == QuestCoursePage.TaskState.has_complete then
		-- 	value_b = value_b - 10000
		-- end

		return value_a > value_b
	end)
end

function QuestCoursePage.GetTaskProDesc(task_id)
	task_id = task_id or "0"
	local task_data = DailyTaskManager.GetTaskData(task_id)
	local complete_times = task_data.complete_times or 0

	return "进度： "  .. complete_times .. "/" .. task_data.max_times
end

function QuestCoursePage.GetTaskProDescByQuest(data)
	local value = QuestAction.GetValue(data.id) or 0
	local finish_value = data.finished_value
	local desc = string.format("进度：%s/%s", value, finish_value)

	return desc
end

function QuestCoursePage.GetTaskOrder(data)
	if data and data.order then
		return tonumber(data.order)
	end

	return 0
end

function QuestCoursePage.GetTaskVisible(data)
	local exid = data.exid
	if exid < QuestAction.begain_exid or exid > QuestAction.end_exid then
		return false
	end

	-- 第几天
	local second_day = QuestCoursePage.GetSecondDay(exid)
	local date_t = commonlib.copy(QuestCoursePage.begain_time_t)
	date_t.day = date_t.day + second_day - 1
	local day_weehours = os.time(date_t)

	-- 补课要展示今天以前的课程
	if QuestCoursePage.is_make_up then
		-- print("bbbbbbbb", day_weehours < today_weehours)
		-- echo(os.date("*t",day_weehours), true)
		-- echo(os.date("*t",today_weehours), true)
		if day_weehours < today_weehours then
			return true
		end
	else -- 非补课的话 要展示今天当天的课程

		-- 毕业任务常驻
		
		if exid == QuestAction.is_always_exist_exid then
			return not QuestAction.IsFinish(data.gsid)
		end
		
		if today_weehours == day_weehours then
			return true
		end
	end

	return false
end

function QuestCoursePage.GetTaskStateByQuest(data)
	if data.task_id == QuestAction.is_always_exist_exid then
		if not QuestCoursePage.IsGraduateTime(server_time) then
			return QuestCoursePage.TaskState.can_not_go
		end

		return QuestCoursePage.TaskState.can_go
	end

	if data.is_finish then
		return QuestCoursePage.TaskState.has_go
	end

	-- 补课的话不需要管时间
	-- if QuestCoursePage.is_make_up then
	-- 	return QuestCoursePage.TaskState.can_go
	-- end

	-- local is_in_course_time = QuestCoursePage.CheckCourseTimeState(server_time)
	-- if not is_in_course_time then
	-- 	return QuestCoursePage.TaskState.can_not_go
	-- end

	return QuestCoursePage.TaskState.can_go
end

function QuestCoursePage.GetBgImg(task_data)
	local img = "Texture/Aries/Creator/keepwork/Quest/bjtiao2_226X90_32bits.png#0 0 226 90:195 20 16 20"
	if QuestCoursePage.CheckIsMissClass(task_data) then
		img = "Texture/Aries/Creator/keepwork/Quest/bjtiao_226X90_32bits.png#0 0 226 90:195 20 16 20"
	end

	return img
end

function QuestCoursePage.HandleCourseData()
	local gift_state_list = QuestAction.GetGiftStateList()
	QuestCoursePage.CourseData = {}
	for i, v in ipairs(QuestCoursePage.TaskAllData) do
		local data = {}
		data.is_finish = QuestAction.IsFinish(v.gsid)
		data.img = QuestCoursePage.GetIconImg(i, v)
		-- data.number_img = QuestCoursePage.GetNumImg(v)
		data.desc = string.format("第%s课", i)
		if i == #QuestCoursePage.TaskAllData then
			data.desc = "GOAL"
		end
		QuestCoursePage.CourseData[#QuestCoursePage.CourseData + 1] = data
	end
end


function QuestCoursePage.GetIconImg(index, item)
	-- 最后一个礼拜要做不同显示
	if index == #QuestCoursePage.TaskAllData then
		return "Texture/Aries/Creator/keepwork/Quest/boshimao_81X60_32bits.png#0 0 81 60"
	end

	return ""
end

function QuestCoursePage.GetNumImg(item)
	local num = item.catch_value
	
	return string.format("Texture/Aries/Creator/keepwork/Quest/zi_%s_23X12_32bits.png#0 0 23 12", num)
end

-- 这里的task_id 其实就是exid
function QuestCoursePage.GetReward(task_id)
	local task_data = nil
	for key, v in pairs(QuestCoursePage.TaskData) do
		if v.task_id == task_id then
			task_data = v
			break
		end
	end
	
	if nil == task_data then
		return
	end

	-- local quest_data = QuestCoursePage.GetQuestData(task_data.task_id)

	-- if quest_data == nil then
	-- 	return
	-- end

	-- if task_data.task_type == "loop" then
	-- 	local childrens = quest_data.questItemContainer.children or {}
		
	-- 	for i, v in ipairs(childrens) do
	-- 		QuestAction.FinishDailyTask(v.template.id)
	-- 	end
		
	-- 	QuestCoursePage.RefreshData()
	-- else
		
	-- 	if quest_data.questItemContainer then
	-- 		quest_data.questItemContainer:DoFinish()
	-- 	end
	-- end


end

function QuestCoursePage.Goto(task_id)
	keepwork.user.server_time({}, function(err, msg, data)
		if err == 200 then
			server_time = commonlib.timehelp.GetTimeStampByDateTime(data.now, true)
			today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time)
			local task_data = QuestCoursePage.GetQuestData(task_id)
			if task_data == nil then
				return
			end

			if task_id == QuestAction.is_always_exist_exid then
				QuestCoursePage.ToGraduate(task_data)
				return
			end

			local show_vip_view = function(desc, form)
				_guihelper.MessageBox(desc, nil, nil,nil,nil,nil,nil,{ ok = L"确定"});
				_guihelper.MsgBoxClick_CallBack = function(res)
					if(res == _guihelper.DialogResult.OK) then
						-- GameLogic.GetFilters():apply_filters("VipNotice", true, form,function()
						-- 	QuestCoursePage.Goto(task_id)
						-- end);
						-- local MacroCodeCampActIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampActIntro.lua");
						-- MacroCodeCampActIntro.ShowView(true)
						
						VipToolNew.Show(form)
						GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.funnel.open', { from = form })
					else
					end
				end
			end

			if task_data.task_state == QuestCoursePage.TaskState.can_not_go then
				return
			end

			if QuestCoursePage.is_make_up then
				if not System.User.isVip then
					show_vip_view("对不起，只有会员才能重新体验课程。立即加入会员，无限次体验全部课程！", "vip_wintercamp1_resign")
					return
				end	
			else
				-- 是否五校用户
				if not System.User.isVipSchool then
					-- 是否vip
					if not System.User.isVip then
						show_vip_view("对不起，本功能暂时只对会员开放。立即加入会员，一起学习生长吧！", "vip_wintercamp1_join")
						return
					end
				end

				-- 时间判断
				local course_time_state = QuestCoursePage.CheckCourseTimeState(server_time)
				if course_time_state ~= QuestCoursePage.ToCourseState.in_time then
					if course_time_state == QuestCoursePage.ToCourseState.late then
						GameLogic.AddBBS(nil, L"您已迟到，请下一堂课再来，切记不可再迟到了哟！");
					else
						GameLogic.AddBBS(nil, L"请在门口课程表上指定的时间段内前来上课哟！");
					end
					
					return
				end
				
				if not System.User.isVip then
					if task_data.is_finish then
						show_vip_view("对不起，您已免费体验过今日的课程。立即加入会员，无限次体验全部课程！", "vip_wintercamp1_replay")
						return
					end

					-- local value = QuestAction.GetValue(task_data.id) or 0
					-- if value >= 1 then
					-- 	show_vip_view("对不起，您已免费体验过今日的课程。立即加入会员，无限次体验全部课程！", "vip_wintercamp1_replay")
					-- 	return
					-- end
				end	
			end

			local function user_behavior()
				local value = QuestAction.GetValue(task_data.id) or 0
				if value == 0 then
					GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.promotion.winter_camp.lessons.hour_of_code', { from = task_id })
				end
			end

			local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
			local target_index = VersionToKey[httpwrapper_version]
			if task_data.goto_world and #task_data.goto_world > 0 then
				local world_id = task_data.goto_world[target_index]
				if world_id then
					if QuestAction.IsJionWinterCamp() then
						user_behavior()
						-- GameLogic.QuestAction.SetValue(task_data.id, 1);
						QuestCoursePage.EnterWorld(world_id)
					else
						KeepWorkItemManager.DoExtendedCost(QuestAction.winter_camp_jion_exid, function()
							keepwork.wintercamp.joincamp({
								gsId=QuestAction.winter_camp_jion_gsid,        
							},function(err, msg, data)
								if err == 200 then
									user_behavior()
									-- GameLogic.QuestAction.SetValue(task_data.id, 1);
									QuestCoursePage.EnterWorld(world_id)
								end
							end)							
						end);
					end
				end

			elseif task_data.click and task_data.click ~= "" then
				if QuestAction.IsJionWinterCamp() then
					if string.find(task_data.click, "loadworld ") then
						page:CloseWindow()
						QuestCoursePage.CloseView()
					end
					NPL.DoString(task_data.click)
					user_behavior()
					-- GameLogic.QuestAction.SetValue(task_data.id, 1);
				else
					KeepWorkItemManager.DoExtendedCost(QuestAction.winter_camp_jion_exid, function()
						keepwork.wintercamp.joincamp({
							gsId=QuestAction.winter_camp_jion_gsid,        
						},function(err, msg, data)
							if err == 200 then
								if string.find(task_data.click, "loadworld ") then
									page:CloseWindow()
									QuestCoursePage.CloseView()
								end
								NPL.DoString(task_data.click)
								user_behavior()
								-- GameLogic.QuestAction.SetValue(task_data.id, 1);
							end
						end)							
					end);
				end
			end
			GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.quest_action.click_go_button')
		end
	end)
end

function QuestCoursePage.GetQuestData(task_id)
	for i, v in ipairs(QuestCoursePage.TaskData) do
		if v.task_id == task_id then
			return v
		end
	end
end

function QuestCoursePage.GetTaskType(data)
	return data.type
end

function QuestCoursePage.IsOpen()
	if nil == page then
		return false
	end

	return page:IsVisible()
end

function QuestCoursePage.IsRoleModel(item_data)
	if item_data and item_data.bagId == modele_bag_id then
		return true
	end

	return false
end

function QuestCoursePage.OnClikcGift(gift_data)
end

-- 获取今天是第几天
function QuestCoursePage.GetSecondDay(exid)
	if exid == nil then
		return 0
	end
	return exid - QuestAction.begain_exid + 1
end

function QuestCoursePage.Close()
	if nil == page then
		return
	end
	page:CloseWindow()
	QuestCoursePage.CloseView()
end

function QuestCoursePage.ToGraduate(task_data)
	if not QuestCoursePage.IsGraduateTime(server_time) then
		return
	end

	if not QuestCoursePage.CheckIsAllCourseFinish() then
		_guihelper.MessageBox("亲爱的同学，你还没有完成全部9天课程.赶快前往张老师那里，把落下的学习进度.给补回来吧！", nil, nil,nil,nil,nil,nil,{ ok = L"我要补课", title = L"无法毕业"});
		_guihelper.MsgBoxClick_CallBack = function(res)
			if(res == _guihelper.DialogResult.OK) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
				local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX = 19259, blockY = 12, blockZ = 19132})
				task:Run();	

				QuestCoursePage.Close()

				commonlib.TimerManager.SetTimeout(function()  
					local QuestCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestCoursePage.lua");
					QuestCoursePage.Show(true);
				end, 1000);
			end
		end
		return
	end

	local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
	local codeEntity = BlockEngine:GetBlockEntity(19211, 1, 19189)
	if codeEntity then
		GameLogic.QuestAction.SetValue(task_data.id, 1);
		GameLogic.QuestAction.DoFinish(60020)
		
		QuestCoursePage.Close()
		codeEntity:Restart();
	end
end

-- 是否所有课程以后的时间
function QuestCoursePage.IsGraduateTime(cur_time_stamp)
	local second_day = QuestCoursePage.GetSecondDay(QuestAction.is_always_exist_exid)
	local date_t = commonlib.copy(QuestCoursePage.begain_time_t)
	date_t.day = date_t.day + second_day - 1
	local day_weehours = os.time(date_t)

	if cur_time_stamp < day_weehours then
		return false
	end

	return true
end

function QuestCoursePage.CheckIsAllCourseFinish()
	local quest_datas = QuestProvider:GetInstance().templates_map
	local exid_list = {}
	local is_all_finish = true
	for i, v in pairs(quest_datas) do
		-- 获取兑换规则
		if exid_list[v.exid] == nil and v.exid >= QuestAction.begain_exid and v.exid < QuestAction.end_exid then
			exid_list[v.exid] = 1
			if not QuestAction.IsFinish(v.gsid) then
				is_all_finish = false
				break
			end
		end
	end

	return is_all_finish
end

function QuestCoursePage.CheckCourseTimeState(cur_time_stamp)
	local day_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(cur_time_stamp)
	for i, v in ipairs(QuestCoursePage.CourseTimeLimit) do
		local begain_time_stamp = day_weehours + v.begain_time.min * 60 + v.begain_time.hour * 3600
		local end_time_stamp = day_weehours + v.end_time.min * 60 + v.end_time.hour * 3600

		if cur_time_stamp >= begain_time_stamp and cur_time_stamp <= end_time_stamp then
			return QuestCoursePage.ToCourseState.in_time
		end

		if i == 1 and cur_time_stamp < begain_time_stamp then
			return QuestCoursePage.ToCourseState.before
		end
		-- print("saaaaaaaaaaaaaa", i, #QuestCoursePage.CourseTimeLimit, cur_time_stamp, begain_time_stamp, cur_time_stamp > begain_time_stamp)
		if i == #QuestCoursePage.CourseTimeLimit and cur_time_stamp > begain_time_stamp then
			return QuestCoursePage.ToCourseState.finish
		end
	end

	for i, v in ipairs(QuestCoursePage.CourseTimeLimit) do
		local begain_time_stamp = day_weehours + v.begain_time.min * 60 + v.begain_time.hour * 3600
		local end_time_stamp = day_weehours + v.end_time.min * 60 + v.end_time.hour * 3600

		if cur_time_stamp < begain_time_stamp then
			return QuestCoursePage.ToCourseState.late, i
		end
	end

	return QuestCoursePage.ToCourseState.late
end

function QuestCoursePage.CheckIsMissClass(data)
	return QuestCoursePage.is_make_up and not data.is_finish
end