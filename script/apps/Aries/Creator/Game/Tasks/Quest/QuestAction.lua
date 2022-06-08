--[[
Title: QuestAction
Author(s): leio
Date: 2020/12/10
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");

QuestAction.SetValue("60003_1",2);
echo("===================test");
echo(QuestAction.GetValue("60003_1"));
echo(QuestAction.GetFinishedValue("60003_1"));
echo(QuestAction.GetItemTemplate("60003_1"));
QuestAction.SetValue("60003_2","abc");
QuestAction.SetValue("60003_3",5);

QuestAction.DoFinish(60003);



NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
GameLogic.QuestAction.SetValue(id,value);
GameLogic.QuestAction.GetValue(id);
GameLogic.QuestAction.DoFinish(quest_gsid);


-- 设置任务目标"60001_1"的值为:1
GameLogic.QuestAction.SetValue("60001_1",1);

-- 获取任务目标"60001_1"的值
GameLogic.QuestAction.GetValue("60001_1");

-- 完成任务60001
GameLogic.QuestAction.DoFinish(60001);

if(GameLogic.QuestAction and GameLogic.QuestAction.SetValue)then
    GameLogic.QuestAction.SetValue("60001_1",1);
end
-------------------------------------------------------
]]


NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestProvider.lua");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");
-- read world_id from template.goto_world
local QuestCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestCoursePage.lua");
local Quest2in1Lesson = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/Quest2in1Lesson.lua");
-- template.goto_world = ["ONLINE","RELEASE","LOCAL"]

QuestAction.VersionToKey = {
	ONLINE = 1,
	RELEASE = 2,
	LOCAL = 3,
}

QuestAction.DailyTaskData = {
    time_stamp = 0,
    is_auto_open_view = false,
    exp = 0,
    gift_state = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
    },
    visit_paraworld_list = {},
    visit_world_list = {},
    play_course_times = 0,
    course_world_id = 0,
}
QuestAction.task_gsid = 40003

QuestAction.TaskState = {
	not_complete = 0,		--未完成
	can_complete = 1,		--可完成
    has_complete = 2,		--已完成
    can_go = 3,				-- 前往
}

QuestAction.SummerCampDailyTask = {
    
}

QuestAction.winter_camp_jion_gsid = 90004
QuestAction.winter_camp_jion_exid = 30028

QuestAction.begain_exid = 40015
QuestAction.end_exid = 40024
QuestAction.is_always_exist_exid = 40024

QuestAction.camp_beagin_gsid = 60011
QuestAction.camp_end_gsid = 60019

QuestAction.server_time_stamp = 0

function QuestAction.GetGoToWorldId(target_id)
    local template = QuestAction.GetItemTemplate(target_id);
    if(template)then
        return template:GetCurVersionValue("goto_world");
    end
end

function QuestAction.Clear()
    QuestAction.clientData = nil
end

function QuestAction.GetVersionValue(target_id, key)
    key = key or "goto_world"
    local template = QuestAction.GetItemTemplate(target_id);
    if(template)then
        return template:GetCurVersionValue(key);
    end
end
--[[
	desc: 用于设置任务进度
	param:
		id：对应兑换规则中的自定义json字符串里的id字段 如兑换规则40015中 id配置的是 40015_60011_1
		value: 任务进度 上限是自定义字符串中 finished_value字段中配置的值
]]

function QuestAction.SetValue(id,value)
    if(not id)then
        return
    end
    
    QuestProvider:GetInstance():SetValue(id,value);
end

--[[
	desc: 获取任务进度 返回SetValue过的最大值
	param:
		id：对应兑换规则中的自定义json字符串里的id字段
]]
function QuestAction.GetValue(id)
    return QuestProvider:GetInstance():GetValue(id);
end

function QuestAction.GetFinishedValue(id)
    local template = QuestAction.GetItemTemplate(id);
    if(template)then
        return template.finished_value;
    end
end
function QuestAction.GetItemTemplate(id)
    local item = QuestAction.FindItemById(id);
    if(item and item.template)then
        return item.template;
    end
end
function QuestAction.FindItemById(id)
    return QuestProvider:GetInstance():FindItemById(id);
end

--[[
	desc: 结束任务 会判断所有子任务中的value是否都已经达到配置的finished_value
	param:
		quest_gsid：对应兑换规则中的所配置的交换目标物品 如兑换规则40015 配置的标志物品是 60011
]]

function QuestAction.DoFinish(quest_gsid)
    if(not quest_gsid)then
        return
    end
    local item = QuestProvider:GetInstance():CreateOrGetQuestItemContainer(quest_gsid);
    -- 
    if(item)then
        item:DoFinish();
    end
end
--[[
	desc: 任务是否结束
	param:
		quest_gsid：对应兑换规则中的所配置的交换目标物品 如兑换规则40015 配置的标志物品是 60011
]]

function QuestAction.IsFinish(quest_gsid)
    if(not quest_gsid)then
        return true
    end
    
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(quest_gsid)
    return bHas
end

function QuestAction.OpenPage(name)
    if name == 'certificate' then
        GameLogic.GetFilters():apply_filters('show_certificate', function(result)
            if result then
                -- QuestAction.AchieveTask("40002_1", 1, true)
                QuestAction.AchieveTask("40006_1", 1, true)
            end
            
        end);
    elseif name == 'school' then
        local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")
        MySchool:ShowJoinSchool(function()
            KeepWorkItemManager.LoadProfile(false, function()
                local profile = KeepWorkItemManager.GetProfile()
                -- 是否选择了学校
                if profile and profile.schoolId and profile.schoolId > 0 then
                    GameLogic.QuestAction.AchieveTask("40003_1", 1, true)
                end
            end)
        end)
    elseif name == 'region' then
        local profile = KeepWorkItemManager.GetProfile()
        local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
        Page.Show({
            UserRegion = profile.region,
            userId = profile.id,
            confirm = function(region)
                if region and region.hasChildren == 0 then
                    GameLogic.QuestAction.AchieveTask("40004_1", 1, true)
                end
            end
        }, {
            url = "%vue%/Page/User/AreaSelect.html",
            width = 500,
            height = 342,
            draggable = false,
        });
    elseif name == 'turntable' then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TurnTable/TurnTable.lua").Show();
    elseif name == 'growth_diary' then
        local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
        ParacraftLearningRoomDailyPage.DoCheckin();     
    elseif name == 'ai_course' then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAllCourse.lua").Show();
    elseif name == 'user' then
        local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
        page.ShowUserInfoPage({username = System.User.keepworkUsername});
    end
end

function QuestAction.AchieveTask(task_id, value, fresh_dock)
    QuestAction.SetValue(task_id, value);

    if fresh_dock then
        local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
        DockPage.isShowTaskIconEffect = true
        DockPage.RefreshPage(0.01)
    end
end
function QuestAction.GetLabel(task_id, task_data)
    if(not task_id)then
        return
    end
    -- if(task_id == "60001_1")then
    --     return QuestAction.GetLabel_60001_1(task_id, task_data)
    -- end

    -- if(task_id == "60007_1")then
    --     return QuestAction.GetLabel_60007_1(task_id, task_data)
    -- end

    local value = task_data.value == task_data.finished_value and 1 or 0
    local finished_value = 1
    return string.format("%s/%s", value, finished_value)
end

function QuestAction.GetLabel_60001_1(task_id, task_data)
    if task_data == nil then
        return
    end
    
    local value = task_data.value == 52 and 1 or 0
    local finished_value = 1
    return string.format("%s/%s", value, finished_value)
end

function QuestAction.GetLabel_60007_1(task_id, task_data)
    if task_data == nil then
        return
    end
    
    local value = task_data.value == 26 and 1 or 0
    local finished_value = 1
    return string.format("%s/%s", value, finished_value)
end

------------------------------------------日常任务处理---------------------------------------------------
-- 完成某个任务
function QuestAction.SetDailyTaskValue(task_id, value, change_value)
	-- 没登录的话不记录数据
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        return
    end

    -- 没拿到数据的话后面的不处理
    local quest_datas = QuestProvider:GetInstance().templates_map
    if quest_datas == nil or next(quest_datas) == nil then
        return
    end

	if QuestAction.CheckTaskCompelete(task_id) then
		return
	end

	local clientData = QuestAction.GetClientData()
	local data = clientData[task_id]
    if data == nil then
        data = {value = 0}
        clientData[task_id] = data
    end

    if change_value and change_value > 0 then
        data.value = data.value + change_value
    else
        data.value = value or 0
    end

    local finished_value = QuestAction.GetDailyTaskFinishValue(task_id)
    if data.value >= finished_value then
        data.state = QuestAction.TaskState.can_complete
    end
    
    QuestAction.SetClientData(clientData)
    QuestPage.RefreshData()
end

-- 访问世界任务
function QuestAction.DailyWorldTask()
    -- 探索世界任务
	local projectId = GameLogic.options:GetProjectId();
    projectId = tonumber(projectId);
    
	local world_generator = WorldCommon.GetWorldTag("world_generator");
	local world_id = WorldCommon.GetWorldTag("kpProjectId");
	local world_name = WorldCommon.GetWorldTag("name");

    -- 在这里加ppt的世界访问
    commonlib.TimerManager.SetTimeout(function()  
        local world_id = GameLogic.options:GetProjectId()
        if world_id then
            RedSummerCampPPtPage.OnVisitWrold(world_id)
        end

        local MsgTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/MsgTip.lua");
        MsgTip.Check()
    end, 1500);

	local key = world_id
	if key == nil then
		key = world_name or ""
	end
	
	local exclude_world = {
		["Paracraft小课堂"] = 1,
		["孙子兵法"] = 1,
    }

    commonlib.TimerManager.SetTimeout(function()
        if world_generator == "paraworld" then
            if QuestAction.CheckTaskCompelete("40010_1") then
                return
            end
            local clientData = QuestAction.GetClientData()
            if clientData.visit_paraworld_list == nil then
                clientData.visit_paraworld_list = {}
            end
            local visit_paraworld_list = clientData.visit_paraworld_list
            if visit_paraworld_list[key] == nil then
                visit_paraworld_list[key] = 1
    
                QuestAction.SetDailyTaskValue("40010_1", nil, 1)
            end
        elseif world_generator ~= "paraworld" and GameLogic.IsReadOnly() and exclude_world[world_name] == nil and not TeachingQuestPage.IsTaskProject(tostring(projectId)) then
            if QuestAction.CheckTaskCompelete("40011_1") then
                return
            end
    
            local clientData = QuestAction.GetClientData()
            if clientData.visit_world_list == nil then
                clientData.visit_world_list = {}
            end
            local visit_world_list = clientData.visit_world_list
            if visit_world_list[key] == nil then
                visit_world_list[key] = 1
    
                QuestAction.SetDailyTaskValue("40011_1", nil, 1)
            end
        end
    end, 2500)
end

function QuestAction.Print(...)
    if System.User.username == 'changjl' then
        local arg={...}
        local str = ""
        for index, v in ipairs(arg) do
            str = str .. ", " .. tostring(v)
        end
        str = str .. "   time:" .. os.time()
        commonlib.echo(str)
    end
end

-- 结束某个任务
function QuestAction.FinishDailyTask(task_id)
    local clientData = QuestAction.GetClientData()
    local data = clientData[task_id]
    if data == nil then
        return
    end

    if data.state == QuestAction.TaskState.can_complete then
        data.state = QuestAction.TaskState.has_complete
        QuestAction.SetClientData(clientData)
    end
end

function QuestAction.GetClientData()
    if QuestAction.clientData == nil then
        QuestAction.clientData = KeepWorkItemManager.GetClientData(QuestAction.task_gsid) or {};
    end

	local clientData = QuestAction.clientData
    local is_new_day, time_stamp = QuestAction.CheckIsNewDay(clientData)

    if is_new_day then
        local course_world_id = clientData.course_world_id
        QuestAction.DailyTaskData.course_teacher_id = clientData.course_teacher_id
        QuestAction.DailyTaskData.target_level_id = clientData.course_level_id
        QuestAction.DailyTaskData.ask_times = clientData.ask_times
		clientData = QuestAction.DailyTaskData
		clientData.time_stamp = time_stamp
        clientData.is_auto_open_view = false
        clientData.exp = 0
        clientData.play_course_times = 0
        clientData.course_world_id = course_world_id

        QuestAction.clientData = clientData
    end
	return clientData
end

function QuestAction.SetClientData(clientData, cb)
    KeepWorkItemManager.SetClientData(QuestAction.task_gsid, clientData, function()
        QuestAction.clientData = clientData
        if cb then
            cb()
        end
    end)
end

-- 检测是否新一天的数据
function QuestAction.CheckIsNewDay(clientData)
	if clientData == nil then
		return true, 0
	end
    local time_stamp = clientData.time_stamp or 0;
	-- 获取今日凌晨的时间戳 1603949593
    local cur_time_stamp = QuestAction.GetServerTime() or 0
    if cur_time_stamp == nil or cur_time_stamp == 0 then
        cur_time_stamp = os.time()
    end
    
	local day_time_stamp = commonlib.timehelp.GetWeeHoursTimeStamp(cur_time_stamp)
	-- 天数改变 清除数据
	if day_time_stamp > time_stamp then
		return true, day_time_stamp
	end

	return false, time_stamp
end

function QuestAction.CheckTaskCompelete(task_id)
    local state = QuestAction.GetDailyTaskState(task_id)
    if state == QuestAction.TaskState.can_complete or state == QuestAction.TaskState.has_complete then
        return true
    end

	return false
end

function QuestAction.GetDailyTaskValue(task_id)
	local clientData = QuestAction.GetClientData()
	local data = clientData[task_id]
	if data == nil or data.value == nil then
		return 0
    end

    return data.value
end

function QuestAction.GetDailyTaskFinishValue(task_id)
    local quest_datas = QuestProvider:GetInstance().templates_map
    for k, v in pairs(quest_datas) do
        if v.id == task_id and type(v.finished_value) == "number" then
            return v.finished_value
        end
    end

    return 0
end

function QuestAction.GetDailyTaskState(task_id)
	local clientData = QuestAction.GetClientData()
	local data = clientData[task_id]
	if data == nil or data.state == nil then
		return QuestAction.TaskState.not_complete
    end
    
    return data.state
end

function QuestAction.GetExp()
	local clientData = QuestAction.GetClientData()
	if clientData == nil or clientData.exp == nil then
		return 0
    end
    
    return clientData.exp
end

function QuestAction.AddExp(exp, cb)
    exp = exp or 0
	local clientData = QuestAction.GetClientData()
	if clientData.exp == nil then
		clientData.exp = 0
    end

    clientData.exp = clientData.exp + exp

    local gift_state_list = clientData.gift_state or {}
    for i, v in ipairs(QuestPage.GiftData) do
        local gift_state = gift_state_list[v.gift_id] or 0
        if clientData.exp >= v.catch_value and gift_state == QuestPage.GiftState.can_not_get then
            gift_state_list[v.gift_id] = QuestPage.GiftState.can_get
        end
    end

    QuestAction.SetClientData(clientData, cb)
end

function QuestAction.GetGiftStateList()
	local clientData = QuestAction.GetClientData()
    return clientData.gift_state or {}
end

function QuestAction.SetGiftState(gift_id, state)
    local clientData = QuestAction.GetClientData()
    local gift_state_list = clientData.gift_state
    if gift_state_list[gift_id] == nil then
        gift_state_list[gift_id] = 0
    end

    gift_state_list[gift_id] = state

    QuestAction.SetClientData(clientData)
end
----------------------------------------日常任务处理/end-------------------------------------------------
-- 是否补课界面
function QuestAction.ShowCourseView(is_make_up)
    QuestCoursePage.Show(is_make_up)
end

function QuestAction.ShowDialogPage(dialog_data, end_callback)
    local QuestDialogPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestDialogPage.lua");
    QuestDialogPage.Show(dialog_data, end_callback);
end

function QuestAction.IsJionWinterCamp()
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(QuestAction.winter_camp_jion_gsid)
    return bHas
end

function QuestAction.CanAccept(quest_gsid)
    -- 九天课程判断 需要判断是否五校用户 是否vip 是否到达时间
    if quest_gsid >= QuestAction.camp_beagin_gsid and quest_gsid <= QuestAction.camp_end_gsid then
        local server_time_stamp = QuestAction.GetServerTime() or 0
        -- 判断九天课程开启时间
        local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time_stamp)
        local begain_day_weehours = os.time(QuestCoursePage.begain_time_t)
        if server_time_stamp < begain_day_weehours then
            -- print("aaaaaaaaaaaaaaaaaaaaaaa未到达九天课程开启时间")
            return false
        end

        -- 判断是否到达对应课程日期
        local second_day = QuestAction.GetCourseSecondDay(quest_gsid)
        local date_t = commonlib.copy(QuestCoursePage.begain_time_t)
        date_t.day = date_t.day + second_day - 1
        local day_weehours = os.time(date_t)
    
        if server_time_stamp < day_weehours then
            -- print("aaaaaaaaaaaaaaaaaaaaaaa未到达对应课程日期")
            return false
        end

        -- 上述条件都满足的话 只要是vip 那就全部满足条件
        if System.User.isVip then
           return true
        end
        -- 五校用户判断
        if System.User.isVipSchool then
            -- 五校用户 第一次允许进入
            local id = QuestAction.GetIdByGsid(quest_gsid) or 0
            local value = QuestAction.GetValue(id) or 0
            if not QuestAction.IsFinish(quest_gsid) then
                return true
            end
            -- print("bbbbbbbbbbbbbbbbbbbbbbbbbbb五校用户 第二次允许进入")
            return false
        end

        return false
    end

    local questItemContainer_map = QuestProvider:GetInstance().questItemContainer_map
    if questItemContainer_map[quest_gsid] then
        return questItemContainer_map[quest_gsid]:IsActivated()
    end
end

function QuestAction.GetIdByGsid(quest_gsid)
    for i, v in pairs(QuestProvider:GetInstance().templates_map) do
        if v.gsid == quest_gsid then
            return v.id
        end
    end

    return 0
end

function QuestAction.GetCourseSecondDay(gsid)
	if gsid == nil then
		return 0
	end
	return gsid - QuestAction.camp_beagin_gsid + 1
end

function QuestAction.GetServerTime()
    if System.options.isDevMode then
        return os.time()
    end
    local timp_stamp = GameLogic.GetFilters():apply_filters('store_get', 'world/currentServerTime')
    return timp_stamp
end

function QuestAction.ShowSpeciapTask()
    local QuestSpecialCourse = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestSpecialCourse.lua");
    QuestSpecialCourse.Show();
    
end

function QuestAction.OpenCampCourseView()
    local server_time_stamp = GameLogic.QuestAction.GetServerTime()
    local begain_day_weehours = os.time(QuestCoursePage.begain_time_t)
    if server_time_stamp < begain_day_weehours then
        QuestAction.ShowSpeciapTask()
    else
        QuestAction.ShowCourseView()
    end
end

function QuestAction.CanFinishCampCourse()
    return QuestCoursePage.CheckIsAllCourseFinish()
end

function QuestAction.RequestAiHomeWork(cb)
    keepwork.quest_work_list.get({
        status = 0, -- 0,未完成；1已完成
    },function(err, msg, data)
        if err == 200 then
            local list_data = {}
            for i, v in ipairs(data.rows) do
                if v.aiHomework then
                    list_data[#list_data + 1] = v
                end
            end
            QuestAction.AiHomeworkList = list_data
            if cb then
                cb()
            end
        end
    end)
end

function QuestAction.GetAiHomeWork()
    return QuestAction.AiHomeworkList
end

function QuestAction.RequestCompleteCourseIdList(cb)
    keepwork.quest_all_complete_course.get({}, function(err, msg, data)
        -- print(">>>>>>>>>>>>完成的课程列表")
        -- echo(data, true)
        if err == 200 then

            QuestAction.CompleteCourseIdList = {}
            for k, v in pairs(data) do
                QuestAction.CompleteCourseIdList[v] = 1
            end

            if cb then
                cb(data)
            end
        end
    end)
end

function QuestAction.GetCompleteCourseIdList()
    return QuestAction.CompleteCourseIdList
end

function QuestAction.HasCompleteCourse(id)
    if id == nil or nil == QuestAction.CompleteCourseIdList then
        return false
    end

    return QuestAction.CompleteCourseIdList[id] ~= nil
end

function QuestAction.CompleteAiHomeWork()
    if QuestAction.AiHomeworkList == nil then
        return
    end

    local server_time = GameLogic.QuestAction.GetServerTime()
    local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time)

    -- 用来做ai课程作业的完成
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local world_generator = WorldCommon.GetWorldTag("world_generator");
    local last_key = nil
    local function complete_homework(id, key)
        keepwork.quest_complete_homework.set({
            aiHomeworkId = id,
            grades = 0,
            status = 1,
        },function(err, message, data)
            -- print(">>>>>>>>>>>>>>>>>>>完成作业返回", err)
            -- echo(data, true)
            if err == 200 then
                if key == last_key then
                    GameLogic.QuestAction.RequestAiHomeWork(function()
                        local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
                        if DockPage.IsShow() then
                            DockPage.FreshHomeWorkIcon()
                        end
                    end)
                end
            end
        end)
    end
    if world_generator == "paraworldMini" then
        for k, v in pairs(QuestAction.AiHomeworkList) do
            if v.aiHomeworkId and v.aiHomework and v.aiHomework.type == 1 then
                if v.aiHomework.aiCourse and v.aiHomework.aiCourse.isForSchool == 1 then
                    local limit_time_stamp = today_weehours + 16 * 60 * 60 + 30 * 60
                    if server_time >= limit_time_stamp then
                        last_key = k
                        complete_homework(v.aiHomeworkId, k)
                    end
                else
                    last_key = k
                    complete_homework(v.aiHomeworkId, k)
                end
            end
        end
    else
        for k, v in pairs(QuestAction.AiHomeworkList) do
            if v.aiHomeworkId and v.aiHomework and v.aiHomework.type == 0 then
                if v.aiHomework.aiCourse and v.aiHomework.aiCourse.isForSchool == 1 then
                    local limit_time_stamp = today_weehours + 16 * 60 * 60 + 30 * 60
                    if server_time >= limit_time_stamp then
                        last_key = k
                        complete_homework(v.aiHomeworkId, k)
                    end
                else
                    last_key = k
                    complete_homework(v.aiHomeworkId, k)
                end
            end
        end
    end
end

function QuestAction.AddAskTimes()
	local clientData = QuestAction.GetClientData()
    local ask_times = clientData.ask_times or 0
    clientData.ask_times = ask_times + 1
    
    QuestAction.SetClientData(clientData)
end

function QuestAction.GetAskTimes()
	local clientData = QuestAction.GetClientData()
    local ask_times = clientData.ask_times or 0
    return ask_times
end

local world2in1_gsid = 90007
function QuestAction.GetSummerTaskProgress(gsid)
    if gsid == 70010 then
        local task_data = QuestAction.GetSummerCampTaskData(gsid)
        local is_task_finish = QuestAction.CheckSummerTaskFinish(gsid)
        if is_task_finish then
            return task_data.max_pro
        end

        local value = QuestAction.GetSummerTaskBuWangProgress()
        return value
    end

    if gsid == 70011 then
        local task_data = QuestAction.GetSummerCampTaskData(gsid)
        local is_task_finish = QuestAction.CheckSummerTaskFinish(gsid)
        if is_task_finish then
            return task_data.max_pro
        end

        local value = QuestAction.GetSummerTaskGameProgress()
        return value
    end

    local client_data = KeepWorkItemManager.GetClientData(world2in1_gsid)
    if client_data == nil then
        return 0
    end
    
    local summer_progress_data = client_data.summer_progress_data or {}

    local task_data = summer_progress_data[gsid] or summer_progress_data[tostring(gsid)]
    if task_data then
        return task_data.value or 0
    end

    return 0
end

function QuestAction.SetSummerTaskBuWangProgress()
end

local buwang_task_data = {
    {gsid=65013,exid=31070,name="秋收起义"},
    {gsid=65014,exid=31071,name="武装起义"},
    {gsid=65015,exid=31072,name="护宝"},
    {gsid=65016,exid=31073,name="东纵展馆"},
    {gsid=65017,exid=31074,name="洛川会议"},
    {gsid=65018,exid=31075,name="山地游击战"},
    {gsid=65019,exid=31076,name="古田会议"},
    {gsid=65020,exid=31077,name="批阅"},
    {gsid=65021,exid=31078,name="毛泽东故居"},
    {gsid=65022,exid=31079,name="革命根据地"},
    {gsid=65023,exid=31080,name="红八军军部"},
    {gsid=65024,exid=31081,name="种树"},
    {gsid=65025,exid=31082,name="红井"},
    {gsid=65026,exid=31083,name="挖井人"},
    {gsid=65027,exid=31084,name="朱德旧居"},
    {gsid=65028,exid=31085,name="朱德生平"},
    {gsid=65029,exid=31086,name="瓦窑堡会议"},
    {gsid=65030,exid=31087,name="统一战线"},
    {gsid=65031,exid=31088,name="中共七大"},
    {gsid=65032,exid=31089,name="从容就义"},
}
function QuestAction.GetSummerTaskBuWangProgress()
    local value = 0
    for index, v in ipairs(buwang_task_data) do
        local bOwn = KeepWorkItemManager.HasGSItem(v.gsid)
        if bOwn then
            value = value + 1
        end
    end

    return value
end

local summer_game_task_data = {
    {gsid=65033,exid=31090,name="ruijin",displayName="瑞金"},
    {gsid=65034,exid=31091,name="shootGame",displayName="血战湘江"},
    {gsid=65035,exid=31092,name="zunyi",displayName="遵义会议"},
    {gsid=65036,exid=31093,name="boatingGame",displayName="四渡赤水"},
    {gsid=65037,exid=31094,name="findBoat",displayName="巧渡金沙江"},
    {gsid=65038,exid=31095,name="ludingqiao",displayName="飞夺泸定桥"},
    {gsid=65039,exid=31096,name="crossSnowMountain",displayName="爬雪山"},
    {gsid=65040,exid=31097,name="crossGrass",displayName="过草地"},
    {gsid=65041,exid=31098,name="lazikou",displayName="激战腊子口"},
    {gsid=65042,exid=31099,name="yanan",displayName="延安会师"},
}

function QuestAction.GetSummerTaskGameProgress()
    local value = 0
    for index, v in ipairs(summer_game_task_data) do
        local bOwn = KeepWorkItemManager.HasGSItem(v.gsid)
        if bOwn then
            value = value + 1
        end
    end

    return value
end

function QuestAction.SetSummerTaskProgress(gsid, change_value, finish_cb)
    local is_task_finish = QuestAction.CheckSummerTaskFinish(gsid)
    if is_task_finish then
        return
    end

    local task_data = QuestAction.GetSummerCampTaskData(gsid)
    if task_data == nil then
        return
    end

    local client_data = KeepWorkItemManager.GetClientData(world2in1_gsid)
    if client_data == nil then
        client_data = {}
    end
    
    if client_data.summer_progress_data == nil then
        client_data.summer_progress_data = {}
    end

    if client_data.summer_progress_data[gsid] == nil then
        client_data.summer_progress_data[gsid] = {value = 0}
    end

    

    local value = client_data.summer_progress_data[gsid].value or 0
    if value >= task_data.max_pro then
        QuestAction.SummerTaskDoFinish(gsid)
        return
    end

    if gsid == 70010 then
        value = QuestAction.GetSummerTaskBuWangProgress()
    end
    
    if gsid == 70011 then
        value = QuestAction.GetSummerTaskGameProgress()
    else
        if change_value then
            if change_value <= value then
                return
            end
            value = change_value
        else
            value = value + 1
        end
    end
    

    if value >= task_data.max_pro then
        value = task_data.max_pro
        QuestAction.SummerTaskDoFinish(gsid, function()
            client_data.summer_progress_data[gsid].value = value

            KeepWorkItemManager.SetClientData(world2in1_gsid, client_data, function()
                GameLogic.GetFilters():apply_filters("summer_task_change", gsid);
            end)

            if task_data.name == "红色先锋" then
                GameLogic.GetCodeGlobal():BroadcastTextEvent("openLongMarchUI",{name = "certiRedPioneer"})
            end

            if finish_cb then
                finish_cb()
            end
        end)
    else
        client_data.summer_progress_data[gsid].value = value
        KeepWorkItemManager.SetClientData(world2in1_gsid, client_data, function()
            GameLogic.GetFilters():apply_filters("summer_task_change", gsid);
        end)
    end
    
    if client_data.summer_progress_data[gsid] then
        return client_data.summer_progress_data[gsid].value or 0
    end

    return 0
end

function QuestAction.CheckSummerTaskFinish(gsid)
    local bOwn = KeepWorkItemManager.HasGSItem(gsid)
    if bOwn then
        return true
    end

    return false
end

function QuestAction.SummerTaskDoFinish(gsid, success_cb)
    local is_task_finish = QuestAction.CheckSummerTaskFinish(gsid)
    if is_task_finish then
        return
    end

    local task_data = QuestAction.GetSummerCampTaskData(gsid) 
    KeepWorkItemManager.DoExtendedCost(task_data.exid, function()
        if success_cb then
            success_cb()
        end
    end) 
end

function QuestAction.GetSummerCampTaskData(gsid)
    if QuestAction.SummerCampTaskData == nil then
        QuestAction.SummerCampTaskData = {
            [70009] = {name = "闪闪红星", exid = 31066, gsid = 70009, max_pro = 1, desc = "完成共筑红旗渠活动"},
            [70010] = {name = "不忘初心", exid = 31067, gsid = 70010, max_pro = 21, desc = "完成梦回党的摇篮活动"},
            [70011] = {name = "红色先锋", exid = 31068, gsid = 70011, max_pro = 10, desc = "完成重走长征路活动"},
            [70012] = {name = "时代接班人", exid = 31069, gsid = 70012, max_pro = 15, desc = "完成3D动画编程课程学习"},
        }
    end

    if gsid and QuestAction.SummerCampTaskData[gsid] then
        return QuestAction.SummerCampTaskData[gsid]
    end

    return QuestAction.SummerCampTaskData
end

function QuestAction.OpenSummerVipView()
    local SummerCampVipView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampVipView.lua") 
    SummerCampVipView.ShowView()
end

function QuestAction.GetSummerRewardHasGet(index)
    local client_data = KeepWorkItemManager.GetClientData(world2in1_gsid)
    if client_data == nil then
        client_data = {}
    end
    
    if client_data.summer_progress_data == nil then
        return false
    end

    if client_data.summer_progress_data.reward_state == nil then
        return false
    end

    return client_data.summer_progress_data.reward_state[index]
end

function QuestAction.SetSummerRewardGet(index, cb)
    local client_data = KeepWorkItemManager.GetClientData(world2in1_gsid)
    if client_data == nil then
        client_data = {}
    end
    
    if client_data.summer_progress_data == nil then
        client_data.summer_progress_data = {}
    end

    if client_data.summer_progress_data.reward_state == nil then
        client_data.summer_progress_data.reward_state = {}
    end

    if client_data.summer_progress_data.reward_state[index] then
        return
    end

    client_data.summer_progress_data.reward_state[index] = true
    KeepWorkItemManager.SetClientData(world2in1_gsid, client_data, function()
        if cb then
            cb()
        end
    end)
end

function QuestAction.GetCertificateNum()
    local certificate_num = 0
    local task_data = QuestAction.GetSummerCampTaskData()
    for key, v in pairs(task_data) do
        local has = KeepWorkItemManager.HasGSItem(v.gsid)
        if has then
            certificate_num = certificate_num + 1
        end
    end

    return certificate_num
end
-- GameLogic.QuestAction.ChangeFirstPerson(true)
function QuestAction.ChangeFirstPerson(is_change)
    if is_change then
        GameLogic.RunCommand("/fps 1");
        ParaUI.Destroy("FPS_Cursor");
        -- commonlib.TimerManager.SetTimeout(function()  
        --     local _this = ParaUI.GetUIObject("FPS_Cursor");
        --     --print("ccccccccccccccc", _this:IsValid())
        --     if _this:IsValid() then
        --         _this.visible = false;
        --     end
        -- end, 1000);
    else
        GameLogic.RunCommand("/fps 0");
    end
end

function QuestAction.CreateBlock(x,y,z,block_id,side)
    local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
    local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x,blockY = y, blockZ = z, block_id = block_id, side = side, entityPlayer = EntityManager.GetPlayer()})
    task:Run();
end

function QuestAction.OnWorldLoaded()
    local world_id = WorldCommon.GetWorldTag("kpProjectId") or 0
    local name = WorldCommon.GetWorldTag("name") or ""
    local today_daily_data = QuestAction.GetTodaySummerDailyTaskData()
    for i, v in ipairs(today_daily_data) do
        if v.world_id == world_id or string.find(v.name, name) then
            QuestAction.SetSummerDailyTaskProgress(i)
            break
        end
    end

    if world_id == 70351 or world_id == 72945 then
        GameLogic.GetPlayerController():SaveRemoteData("summer_camp_last_worldid", world_id);
    end
    
end

function QuestAction.CheckSummerGameTask()
    -- 夏令营游戏证书id（重走长征路）
    local game_gsid = 70011
    if not QuestAction.CheckSummerTaskFinish(game_gsid) then
        local task_data = QuestAction.GetSummerCampTaskData(game_gsid)
        local value = QuestAction.GetSummerTaskGameProgress()
        if value >= task_data.max_pro then
            QuestAction.SummerTaskDoFinish(game_gsid)
        end
    end
end

-- 夏令营每日任务每天只有两个 所以task_id只有1 和 2
function QuestAction.SetSummerDailyTaskProgress(task_id, change_value)
    local client_data = QuestAction.GetSummerTaskClientData()
    if client_data == nil then
        client_data = {}
    end
    
    if client_data.summer_dailytask_data == nil then
        client_data.summer_dailytask_data = {}
    end

    if client_data.summer_dailytask_data[task_id] == nil then
        client_data.summer_dailytask_data[task_id] = {value = 0}
    end

    local value = client_data.summer_dailytask_data[task_id].value or 0
    local max_pro = 1
    if value >= max_pro then
        if client_data.summer_dailytask_data.today_weehours == nil then
            local server_time_stamp = QuestAction.GetServerTime() or 0
            local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time_stamp)
            client_data.summer_dailytask_data.today_weehours = today_weehours
            KeepWorkItemManager.SetClientData(world2in1_gsid, client_data, function()
        
            end)
        end
        return
    end

    if change_value then
        value = change_value
    else
        value = value + 1
    end

    if value >= max_pro then
        value = max_pro
    end

    client_data.summer_dailytask_data[task_id].value = value
    local server_time_stamp = QuestAction.GetServerTime() or 0
    local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time_stamp)
    client_data.summer_dailytask_weehours = today_weehours

    -- print("xxaaaaaaaaaaa保存每日任务数据")
    -- echo(client_data, true)
    KeepWorkItemManager.SetClientData(world2in1_gsid, client_data, function()
        
    end)
end

function QuestAction.GetSummerDailyTaskProgress(task_id)
    local client_data = QuestAction.GetSummerTaskClientData()
    if client_data == nil then
        return 0
    end
    
    local summer_dailytask_data = client_data.summer_dailytask_data
    if summer_dailytask_data == nil then
        return 0
    end

    local task_data = summer_dailytask_data[task_id] or summer_dailytask_data[tostring(task_id)]
    if task_data then
        return task_data.value or 0
    end

    return 0
end

function QuestAction.GetSummerTaskClientData()
    local client_data = KeepWorkItemManager.GetClientData(world2in1_gsid)
    if client_data == nil then
        return
    end

    local last_day_weehours = client_data.summer_dailytask_weehours or 0
    local server_time_stamp = QuestAction.GetServerTime() or 0
    local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time_stamp)
    if today_weehours > last_day_weehours then
        client_data.summer_dailytask_data = {}
    end
    return client_data
end

function QuestAction.GetTodaySummerDailyTaskData()
    local day_index = QuestAction.GetSummerDay()
    local SummerCampTaskPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampTaskPage.lua") 
    local task = SummerCampTaskPage.GetSummerCampDailyTask()
    local data = task[day_index]

    return data or {}
end

-- 获取今天是夏令营第几天 7.1号是第一天
local SummerStartDate = {year = 2021, month = 7, day = 1, hour=0, min=0, sec=0}
function QuestAction.GetSummerDay()
    local begain_time_stamp = os.time(SummerStartDate)
    local now_time_stamp = QuestAction.GetServerTime()
    local on_day_second = 24 * 60 * 60
    local past_second = now_time_stamp - begain_time_stamp
    if past_second < 0 then
        return 0
    end

    local day_index = math.modf(past_second/on_day_second) + 1

    return day_index
end

function QuestAction.Get2In1LessonProgress(course_id,callback)
    return Quest2in1Lesson.GetLessonProgress(course_id,callback)
end

function QuestAction.UpdateLessonProgress(course_id,lessonId,progress,status,callback)
    Quest2in1Lesson.UpdateLessonProgress(course_id,lessonId,progress,status,callback)
end

function QuestAction.GetAppCommandLine(key, default)
    return ParaEngine.GetAppCommandLineByParam(key, default)
end

local dongao_gsid = 40008

--[[ 
    param: lesson_type：
        anim 动画课
        code 编程课
        build 建造课

    param: lesson_index:课程索引 第几节课
]]--
function QuestAction.GetDongaoLessonState(lesson_type, lesson_index)
    if QuestAction.DongAoClientData == nil then
        QuestAction.DongAoClientData = KeepWorkItemManager.GetClientData(dongao_gsid)
    end
    local client_data = QuestAction.DongAoClientData
    if client_data == nil then
        return false
    end
    local key = lesson_type .. "_lesson_progress"
    local lesson_state_data = client_data[key]
    if not lesson_state_data then
        return false
    end

    local result = lesson_state_data[tonumber(lesson_index)] or lesson_state_data[tostring(lesson_index)]
    if not result then
        return false
    end

    return result.is_finish
end

function QuestAction.SetDongaoLessonState(lesson_type, lesson_index, is_finish)
    if QuestAction.DongAoClientData == nil then
        QuestAction.DongAoClientData = KeepWorkItemManager.GetClientData(dongao_gsid) or {}
    end

    local client_data = QuestAction.DongAoClientData

    local key = lesson_type .. "_lesson_progress"
    client_data[key] = client_data[key] or {}
    local lesson_state_data = client_data[key]

    lesson_index = tonumber(lesson_index)
    if not lesson_state_data[lesson_index] then
        lesson_state_data[lesson_index] = {}
    end

    if lesson_state_data[lesson_index].is_finish == is_finish then
        return
    end

    lesson_state_data[lesson_index].is_finish = is_finish
    KeepWorkItemManager.SetClientData(dongao_gsid, client_data, function()
    end)
end

function QuestAction.ReportEvent(action, data)
    data = data or {}
    data.userId = Mod.WorldShare.Store:Get('user/userId') or 0
    data.beginAt = data.beginAt or QuestAction.GetServerTime()
    data.traceId = System.Encoding.guid.uuid()
    if System.options.channelId~="" then
        data.channelId = System.options.channelId
    end
    local project_id = GameLogic.options:GetProjectId()
    if project_id and tonumber(project_id) > 0 then
        data.projectId = project_id
    end
    keepwork.burieddata.sendSingleBuriedData({
        category 	= 'behavior',
        action 		= action,
        data 		= data
    },function(err, msg, data)
        if err == 200 then 
        end
    end)
end

function QuestAction.SetCurWorldData(world_data)
    QuestAction.cur_world_data = world_data
end

function QuestAction.GetCurWorldData()
    return QuestAction.cur_world_data or {}
end

function QuestAction.OnLoadedWorldEnd()
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        return
    end

    if not QuestAction.enter_world_by_id_timestamp then
        return
    end
    local duration = QuestAction.GetServerTime() - QuestAction.enter_world_by_id_timestamp
    QuestAction.enter_world_by_id_timestamp = nil

    if duration == 0 then
        return
    end
    local data = {duration = duration}
    local project_id = GameLogic.options:GetProjectId()
    if project_id and tonumber(project_id) > 0 then
        QuestAction.ReportEvent("duration.world_load", data)
    end
   
    -- GameLogic.GetFilters():apply_filters("user_behavior", 1, "duration.world_load", {projectId};
end

function QuestAction.ReportLoginTime()
    if not QuestAction.click_login_timestamp then
        return
    end
    local duration = QuestAction.GetServerTime() - QuestAction.click_login_timestamp
    QuestAction.click_login_timestamp = nil
    if duration == 0 then
        return
    end

    local data = {duration = duration}
    QuestAction.ReportEvent("duration.login", data)
    -- GameLogic.GetFilters():apply_filters("user_behavior", 1, "duration.world_load", {projectId};
end

function QuestAction.EnterWorldById()
    QuestAction.enter_world_by_id_timestamp = QuestAction.GetServerTime()
end

function QuestAction.OnClickLogin()
    QuestAction.click_login_timestamp = QuestAction.GetServerTime()
end