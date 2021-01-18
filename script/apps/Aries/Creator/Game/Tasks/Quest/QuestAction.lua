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
-- template.goto_world = ["ONLINE","RELEASE","LOCAL"]

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
}
QuestAction.task_gsid = 40003

QuestAction.TaskState = {
	not_complete = 0,		--未完成
	can_complete = 1,		--可完成
    has_complete = 2,		--已完成
    can_go = 3,				-- 前往
}

function QuestAction.GetGoToWorldId(target_id)
    local template = QuestAction.GetItemTemplate(target_id);
    if(template)then
        return template:GetCurVersionValue("goto_world");
        
    end
end
function QuestAction.SetValue(id,value)
    if(not id)then
        return
    end
    
    QuestProvider:GetInstance():SetValue(id,value);
end
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
function QuestAction.DoFinish(quest_gsid)
    if(not quest_gsid)then
        return
    end
    local item = QuestProvider:GetInstance():CreateOrGetQuestItemContainer(quest_gsid);
    if(item)then
        item:DoFinish();
    end
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
    if(task_id == "60001_1")then
        return QuestAction.GetLabel_60001_1(task_id, task_data)
    end

    if(task_id == "60007_1")then
        return QuestAction.GetLabel_60007_1(task_id, task_data)
    end
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
		clientData = QuestAction.DailyTaskData
		clientData.time_stamp = time_stamp
        clientData.is_auto_open_view = false
        clientData.exp = 0
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
    local cur_time_stamp = os.time()
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