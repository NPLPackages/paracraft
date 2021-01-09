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

-- read world_id from template.goto_world
-- template.goto_world = ["ONLINE","RELEASE","LOCAL"]
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