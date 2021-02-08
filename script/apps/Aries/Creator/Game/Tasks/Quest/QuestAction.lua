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

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestProvider.lua");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");
-- read world_id from template.goto_world
local QuestCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestCoursePage.lua");
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
    end
end

function QuestAction.AchieveTask(task_id, value, fresh_dock)
    QuestAction.SetValue(task_id, value);

    if fresh_dock then
        local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
        DockPage.isShowTaskIconEffect = true
        DockPage.page:Refresh(0.01)
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
    
    KeepWorkItemManager.SetClientData(QuestAction.task_gsid, clientData)
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
    end, 1500)
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
        KeepWorkItemManager.SetClientData(QuestAction.task_gsid, clientData)
    end
end

function QuestAction.GetClientData()
	local clientData = KeepWorkItemManager.GetClientData(QuestAction.task_gsid) or {};
    local is_new_day, time_stamp = QuestAction.CheckIsNewDay(clientData)
    if is_new_day then
        course_world_id = clientData.course_world_id

		clientData = QuestAction.DailyTaskData
		clientData.time_stamp = time_stamp
        clientData.is_auto_open_view = false
        clientData.exp = 0
        clientData.play_course_times = 0
        clientData.course_world_id = course_world_id
    end
	return clientData
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

    KeepWorkItemManager.SetClientData(QuestAction.task_gsid, clientData, cb)
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

    KeepWorkItemManager.SetClientData(QuestAction.task_gsid, clientData)
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
    return QuestProvider:GetInstance():GetServerTime();
end

function QuestAction.ShowSpeciapTask()
    local QuestSpecialCourse = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestSpecialCourse.lua");
    QuestSpecialCourse.Show();
    
end

function QuestAction.SetServerTime(server_time_stamp)
    QuestProvider:GetInstance():SetServerTime(server_time_stamp)
end

function QuestAction.OpenCampCourseView()
    keepwork.user.server_time({
    },function(err, msg, data)
        if(err == 200)then
            local server_time_stamp = commonlib.timehelp.GetTimeStampByDateTime(data.now, true)
            QuestProvider:GetInstance():SetServerTime(server_time_stamp)
			local begain_day_weehours = os.time(QuestCoursePage.begain_time_t)
            if server_time_stamp < begain_day_weehours then
                QuestAction.ShowSpeciapTask()
            else
                QuestAction.ShowCourseView()
			end
        end
    end)
end

function QuestAction.CanFinishCampCourse()
    return QuestCoursePage.CheckIsAllCourseFinish()
end