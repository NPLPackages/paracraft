--[[
Title: QuestProvider
Author(s): leio
Date: 2020/12/8
use the lib:
------------------------------------------------------------
NOTE：
Quest Item is in UserBagNo 1005, gsid start from 60000
ExID from 40000 to 49999
------------------------------------------------------------------------------------------------------------------------
extra in 兑换规则
{
  "activeconditions": [
        {   
            "type" : "QuestDateCondition", 
            "values" : [ 
                { "date": "2021-1-11", "duration": "10:00:00-12:00:00" },
                { "date": "2021-1-11", "duration": "14:00:00-16:00:00" },
                { "date": "2021-1-11", "duration": "20:00:00-22:00:00" },
            ],
            "strict": false,
        }
    ],
  "preconditions": [
    { "id": "60003_1", "title": "", "desc": "", "finished_value": 5, "goto_world": [29477,1376,1376], "click":"" , "task_type":"main", "custom_show": true, },
    { "id": "60003_2", "title": "", "desc": "", "finished_value": "abc" },
    { "id": "60003_3", "title": "", "desc": "", "finished_value": 5 }
  ]
}
------------------------------------------------------------------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestProvider.lua");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");

QuestProvider:GetInstance():SetValue("60003_2","ABC");
QuestProvider:GetInstance():Refresh();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");

NPL.load("(gl)script/ide/EventDispatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/Quest.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestItem.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestItemContainer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestItemTemplate.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local Quest = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.Quest");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local QuestItemContainer = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestItemContainer");
local QuestItem = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestItem");
local QuestItemTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestItemTemplate");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local QuestProvider = commonlib.inherit(commonlib.gettable("commonlib.EventSystem"),commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider"))

QuestProvider.Events = {
    OnInit = "OnInit",
    OnChanged = "OnChanged",
    OnFinished = "OnFinished",
    OnRefresh = "OnRefresh",
}

QuestProvider.bags = { 1005 };
QuestProvider.min_exid = 40001;
QuestProvider.max_exid = 49999;
QuestProvider.templates_map = {};
QuestProvider.gsid_exid_map = {};
QuestProvider.questItemContainer_map = {};

function QuestProvider:GetInstance()
    if(not QuestProvider.provider_instance)then
        QuestProvider.provider_instance = QuestProvider:new(); 
    end
    return QuestProvider.provider_instance;
end

function QuestProvider:Clear()
    QuestProvider.templates_map = {};
    QuestProvider.gsid_exid_map = {};
    QuestProvider.questItemContainer_map = {};
    QuestProvider.provider_instance = nil

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
    local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
    QuestAction.Clear()
end

function QuestProvider:OnInit()

    QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnInit,function(__, event)
    end, nil, "QuestProvider_OnInit")
    QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnRefresh,function(__, event)
    end, nil, "QuestProvider_OnRefresh")

    QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnChanged,function(__, event)
        local quest_item_container = event.quest_item_container;
        local quest_item = event.quest_item;
        -- 埋点
        -- 抗疫知识埋点=
        if quest_item_container and quest_item_container.gsid == 60029 then
            GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.promotion.winter_camp.lessons.epidemic', { from = quest_item.id })
        end
        if quest_item.value == quest_item.finished_value then
            GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.quest_action.when_finish')
        end

    end, nil, "QuestProvider_OnChanged")
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
    local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
    QuestProvider:GetInstance():AddEventListener(QuestProvider.Events.OnFinished,function(__, event)
        -- 埋点
        GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.quest_action.when_finish')
        if event.quest_item_container and event.quest_item_container.gsid then
            
            local exid = QuestProvider:GetInstance().gsid_exid_map[event.quest_item_container.gsid] or 0
            
            if exid >= QuestAction.begain_exid and exid < QuestAction.end_exid then
                keepwork.wintercamp.finishcourse({
                    gsId=QuestAction.winter_camp_jion_gsid,
                    courseGsId=event.quest_item_container.gsid,
                },function(err, msg, data)
                end)
            end

            if exid == QuestAction.end_exid or exid == 40027 then
                local gsid = exid == 40027 and 60025 or 60026
                keepwork.wintercamp.finishcertificate({
                    gsId=QuestAction.winter_camp_jion_gsid,
                    certificateGsId=gsid,
                },function(err, msg, data)
                end)

                if exid == QuestAction.end_exid then
                    -- _guihelper.MessageBox("恭喜您顺利结业，证书已发放，点击确定前往查看", nil, nil,nil,nil,nil,nil,{ ok = L"确定"});
                    -- _guihelper.MsgBoxClick_CallBack = function(res)
                    --     if(res == _guihelper.DialogResult.OK) then
                    --         local user_page = NPL.load("(gl)Mod/GeneralGameServerMod/App/ui/page.lua");
                    --         user_page.ShowUserInfoPage({username=System.User.keepworkUsername, HeaderTabIndex="honor"});
                    --     end
                    -- end
                end
            end
            
            -- 探索力处理
            for i, quest_item in ipairs(event.quest_item_container.children) do
                if quest_item.template and quest_item.template.exp then
                    QuestAction.AddExp(quest_item.template.exp, function()
                        if i == #event.quest_item_container.children then
                            local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
                            if QuestPage and QuestPage.IsOpen() then
                                local exp = QuestAction.GetExp()
                                QuestPage.ProgressToExp(true, exp)
                                QuestPage.HandleGiftData()
                                QuestPage.OnRefreshGiftGridView()
                            end
                        end
                    end)
                end
            end


        end
    end, nil, "QuestProvider_OnFinished")
    GameLogic.GetFilters():add_filter("AICourse.ActivateHomework", QuestProvider.OnActivateHomework);
    GameLogic.GetFilters():add_filter("AICourse.SetStep", QuestProvider.SetStep);
    GameLogic.GetFilters():add_filter("AICourse.GetStep", QuestProvider.GetStep);
    GameLogic.GetFilters():add_filter("enter_world_by_id", function()
        QuestAction.EnterWorldById()
    end);

    GameLogic.GetFilters():add_filter("became_vip", function()
        local Act51AskAlert = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskAlert.lua")
        Act51AskAlert.CheckGetVipItem()
    end);

    GameLogic.GetFilters():add_filter("OnWorldLoaded", function()
        QuestAction.OnWorldLoaded()
    end);

    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page", function()
        QuestAction.OnLoadedWorldEnd()
        return true
    end);

    QuestProvider:GetInstance():OnInit__();

end
function QuestProvider:OnInit__()
    if(self.is_init)then
        return
    end
    self.is_init = true;

    self.templates_map = {};
    self.gsid_exid_map = {};
   
    self.questItemContainer_map = {};

    keepwork.questitem.list({},function(err, msg, data)
	    LOG.std(nil, "info", "QuestProvider load err:", err);
	    LOG.std(nil, "info", "QuestProvider load data:", data);
        local clientdata_list = {};
        if(err == 200)then
            for k,v in ipairs(data) do
                local gsid = v.gsId;
                if(v.data)then
                    local quest_targets = v.data.quest_targets;
                    if(gsid and quest_targets)then
                        local out = {};
                        if(NPL.FromJson(quest_targets, out)) then
                            table.insert(clientdata_list,{
                                gsid = gsid,
                                data = out,
                            })
                        end    
                    end
                end
                
            end
        end
	    LOG.std(nil, "info", "QuestProvider clientdata_list:", clientdata_list);
        self.quest_graph = Quest:new():Init(KeepWorkItemManager.extendedcost);
        --self.quest_graph:SaveQuestToDgml("test/quest.dgml");

        self:FillTemplates();
        self:FillData(clientdata_list)

        self:DispatchEvent({ type = QuestProvider.Events.OnInit });

        KeepWorkItemManager.GetFilter():add_filter("LoadItems_Finished", function()
            self:Refresh();
        end);
        self:Refresh();
    end)
    
end
--[[
local quest_nodes = {
    { exid = 40000, },
    { exid = 40001, },
    { exid = 40002, },
    { exid = 40003, },
}
-]]
function QuestProvider:GetActivedQuestNodes()
    return self.quest_graph:GetQuestNodes();
end
--[[
local clientdata_list = {
    { gsid = 1, data = nil, },
    { gsid = 2, data = nil, },
    { gsid = 3, data = nil, },
    { gsid = 4, data = nil, },
}
]]
function QuestProvider:FillData(clientdata_list)
    if(not clientdata_list)then
        return
    end
     for k,v in ipairs(clientdata_list) do
        local gsid = v.gsid;
        local data = v.data;
        local item = self:CreateOrGetQuestItemContainer(gsid);  
        item:Parse(data);
    end
end
function QuestProvider:FillTemplates()
    for k,v in ipairs(KeepWorkItemManager.extendedcost) do
        local exid = v.exId;
        if(self:IsValidExid(exid))then
            self:FillQuestItemTemplateBy_Virtual_Condition(exid);
            self:FillQuestItemTemplateBy_Real_Condition(exid);
        end
    end
end
function QuestProvider:AddQuestItemTemplate(template)
    if(not template)then
        return
    end
    local key = template:GetUniqueKey();
    local t = self.templates_map[key];
    if(t)then
        return
    end
    self.templates_map[key] = template;
end
function QuestProvider:GetQuestItemTemplate(gsid, id)
    local key = string.format("%s_%s",tostring(gsid), tostring(id));
    return self.templates_map[key];
end
function QuestProvider:IsValidExid(exid)
    if(not exid)then
        return
    end
    if(exid >= self.min_exid and exid <= self.max_exid)then
        return true;
    end
end
function QuestProvider:IsValidBag(bagNo)
    if(not bagNo)then
        return
    end
    for k,v in ipairs(self.bags) do
        if(v == bagNo)then
            return true;
        end
    end
end
function QuestProvider:GetExtra(exid)
    local ex_template = KeepWorkItemManager.GetExtendedCostTemplate(exid);
    if(ex_template)then
        return ex_template.extra;
    end
end
function QuestProvider:SearchExidFromQuestGsid(gsid)
    if(not gsid)then
        return
    end
    return self.gsid_exid_map[gsid];
end
-- search quest item gsid from exchangeTargets
function QuestProvider:SearchQuestGsidFromExid(exid)
    local goal = KeepWorkItemManager.GetGoal(exid);
    for k,group in ipairs(goal) do
        local goods = group.goods;
        if(goods)then
            for kk,item in ipairs(goods) do
                if(item.goods)then
                    local bagId = item.goods.bagId;
                    local gsId = item.goods.gsId;
                    local bagNo = KeepWorkItemManager.SearchBagNo(bagId)
                    if(self:IsValidBag(bagNo))then
                        -- map quest gsid and exid
                        self.gsid_exid_map[gsId] = exid;
                        return gsId;
                    end
                end
            end
        end
    end
end

function QuestProvider:FillQuestItemTemplateBy_Virtual_Condition(exid)
    if(not exid)then
        return
    end
    local ex_template = KeepWorkItemManager.GetExtendedCostTemplate(exid);
    local quest_gsid = self:SearchQuestGsidFromExid(exid);
    if(ex_template and quest_gsid)then
        local extra = self:GetExtra(exid);
        if(extra and extra.preconditions)then
            local preconditions = extra.preconditions;
            for k,v in ipairs(preconditions) do
                local id = v.id;
                local quest_template = self:GetQuestItemTemplate(quest_gsid, id);
                if(not quest_template)then
                    quest_template = QuestItemTemplate:new();
                    quest_template.exid = exid;
                    quest_template.gsid = quest_gsid;
                    quest_template.id = id;
                    quest_template.type = QuestItemTemplate.Types.VIRTUAL;
                    quest_template.finished_value = v.finished_value;
                    quest_template.name = v.name;
                    quest_template.desc = v.desc;
                    quest_template.goto_world = v.goto_world;
                    quest_template.click = v.click;
                    quest_template.task_type = v.task_type;
                    quest_template.custom_show = v.custom_show;
                    quest_template.exp = v.exp;
                    quest_template.order = v.order
                    quest_template.visible = v.visible
                    quest_template.belong = v.belong
                    quest_template.course_level = v.course_level
                    quest_template.command = v.command
                    quest_template.level_name = v.level_name
                    self:AddQuestItemTemplate(quest_template);
                end
            end
        end
    end
end

-- parse template with preconditions
function QuestProvider:FillQuestItemTemplateBy_Real_Condition(exid)
    if(not exid)then
        return
    end
    local quest_gsid = self:SearchQuestGsidFromExid(exid);
    local preconditions = KeepWorkItemManager.GetPrecondition(exid);
    if(quest_gsid and preconditions)then
        local item_template = KeepWorkItemManager.GetItemTemplate(quest_gsid);
        if(item_template)then
            for k,v in ipairs(preconditions) do
                local goods = v.goods;
                local amount = v.amount;
                if(goods and amount)then
                    local gsid = goods.gsId;
                    local quest_template = self:GetQuestItemTemplate(quest_gsid, gsid);
                    if(not quest_template)then
                        quest_template = QuestItemTemplate:new();
                        quest_template.exid = exid;
                        quest_template.gsid = quest_gsid;
                        quest_template.id = gsid;
                        quest_template.type = QuestItemTemplate.Types.REAL;
                        quest_template.finished_value = amount;
                        quest_template.name = item_template.name;
                        quest_template.desc = item_template.desc;
                        self:AddQuestItemTemplate(quest_template);
                    end
                end
            end
        end
    end
end
-- refresh the state of valid quest node
function QuestProvider:Refresh()
    
    local quest_nodes = self:GetActivedQuestNodes();
	LOG.std(nil, "info", "QuestProvider quest_nodes:", quest_nodes);
    if(not quest_nodes)then
        return
    end
     for k,v in ipairs(quest_nodes) do
        
        local exid = v.exid;
        local quest_gsid = self:SearchQuestGsidFromExid(exid)
        if(quest_gsid)then
            local itemContainer = self:CreateOrGetQuestItemContainer(quest_gsid);

            -- check virtual active condition
            local extra = self:GetExtra(exid);
            if(extra and extra.activeconditions)then
                itemContainer:ParseActiveConditions(extra.activeconditions);
            end
            -- check virtual condition
            if(extra and extra.preconditions)then
                for kk,vv in ipairs(extra.preconditions) do
                    local id = vv.id
                    local item = itemContainer:GetChildById(id);
                    if(not item)then
                        local template = self:GetQuestItemTemplate(quest_gsid, id);
                        local quest_item = QuestItem:new():OnInit(id, nil, template);      
                        itemContainer:AddChild(quest_item);
                    end
                end
            end
             -- check real condition
            local preconditions = KeepWorkItemManager.GetPrecondition(exid);
            if(preconditions)then
                for k,v in ipairs(preconditions) do
                    local goods = v.goods;
                    if(goods)then
                        local id = goods.gsId;
                        local bagId = goods.bagId;
                        local bagNo = KeepWorkItemManager.SearchBagNo(bagId)
                        if(not self:IsValidBag(bagNo))then
                            local item = itemContainer:GetChildById(id);
                            if(not item)then
                                local template = self:GetQuestItemTemplate(quest_gsid, id);
                                local quest_item = QuestItem:new():OnInit(id, nil, template);      
                                itemContainer:AddChild(quest_item);
                            end
                        end
                        
                    end
                end
            end
            itemContainer:Refresh();
        end
    end
    self:DispatchEvent({ type = QuestProvider.Events.OnRefresh, });

end
function QuestProvider:CreateOrGetQuestItemContainer(gsid,data)
    if(not gsid)then
        return
    end
    local item = self.questItemContainer_map[gsid];
    if(not item)then
        item = QuestItemContainer:new():OnInit(self, gsid, data);  

        item:AddEventListener(QuestItemContainer.Events.OnChanged,function(__,event)
            local quest_item = event.quest_item;
            if(item:HasVirtualTarget())then
                keepwork.questitem.save({
                    gsId = gsid,
                    data = {
                        quest_targets = NPL.ToJson(item:GetData());
                    };
                },function(err, msg, data)
	                LOG.std(nil, "info", "QuestProvider saving virtual target item:GetData():", item:GetData());
	                LOG.std(nil, "info", "QuestProvider saving virtual target err:", err);
	                LOG.std(nil, "info", "QuestProvider saving virtual target msg:", msg);
	                LOG.std(nil, "info", "QuestProvider saving virtual target data:", data);
                end)
            end
            self:DispatchEvent({ type = QuestProvider.Events.OnChanged, quest_item_container = item, quest_item = quest_item, });
            self:Refresh();
        end)
        item:AddEventListener(QuestItemContainer.Events.OnFinish,function(__,event)

            local exid = self:SearchExidFromQuestGsid(item.gsid);
            -- post log
	        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.quest_action.do_finish", { quest_gsid = item.gsid, exid = exid, });
            if(exid)then
                KeepWorkItemManager.DoExtendedCost(exid, function()
                    self:DispatchEvent({ type = QuestProvider.Events.OnFinished, quest_item_container = item, });
                    self:Refresh();
                end)
            end
        end)
        self.questItemContainer_map[gsid] = item;
    end
    return item;
end
function QuestProvider:IncreaseNumberValue(id,value)
    if(not self.is_init)then
	    LOG.std(nil, "error", "QuestProvider:IncreaseNumberValue", "QuestProvider isn't init, target_id:%s",tostring(id));
        return
    end
    
    if(not id)then
        return 
    end
    for k,v in pairs(self.questItemContainer_map) do
        v:IncreaseNumberValue(id,value);
    end
end
function QuestProvider:SetValue(id,value)
    if(not id)then
        return
    end
    if(not self.is_init)then
	    LOG.std(nil, "error", "QuestProvider:SetValue", "QuestProvider isn't init, target_id:%s",tostring(id));
        return
    end
    -- post log
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.quest_action.setvalue", { id = id, value = value, });
    for k,v in pairs(self.questItemContainer_map) do
        v:SetValue(id,value);
    end
end
function QuestProvider:GetValue(id)
    if(not self.is_init)then
	    LOG.std(nil, "error", "QuestProvider:GetValue", "QuestProvider isn't init, target_id:%s",tostring(id));
        return
    end
    local item = self:FindItemById(id)
    if(item)then
        return item:GetValue();
    end
    
end
function QuestProvider:FindItemById(id)
    for k,v in pairs(self.questItemContainer_map) do
        local item = v:FindItemById(id);
        if(item )then
            return item;
        end
    end
end
function QuestProvider:Dump()
    local result = {};
    for k,v in pairs(self.questItemContainer_map) do
        table.insert(result, {
            gsid = v.gsid,
            v:GetData()
        });
    end
    return result;
end
function QuestProvider:DumpTemplates()
    local result = {};
    for k,template in pairs(self.templates_map) do
         result[k] = template:GetData();
    end 
    return result;
end
-- only return actived quest
function QuestProvider:GetQuestItems(isDump)
    local result = {};
    if(self.questItemContainer_map)then
        for k,v in pairs(self.questItemContainer_map) do
            if(not v:IsFinished() and v:IsActivated())then
                local gsid = v.gsid;
                local exid = self:SearchExidFromQuestGsid(gsid);
                if(exid)then
                    local extra = self:GetExtra(exid)
                    local questItemContainer = v;
                    if(isDump)then
                        questItemContainer = v:GetDumpData();
                    end
                    table.insert(result,{
                        gsid = gsid,
                        exid = exid, 
                        questItemContainer = questItemContainer,
                    })
                end
            end
        end
        table.sort(result,function(a,b)
            return a.gsid < b.gsid
        end)
    end
    return result;
end

function QuestProvider.SetStep(stepNum, allStepNum)
    
    local client_data = GameLogic.QuestAction.GetClientData()
    -- local projectId = WorldCommon.GetWorldTag("kpProjectId") or 0
    -- projectId = tonumber(projectId)
    -- if projectId ~= client_data.course_world_id then
    --     return
    -- end

    local is_home_work = client_data.is_home_work

    if not is_home_work and client_data.course_id == nil then
        return
    end

    if is_home_work and client_data.home_work_id == nil then
        return
    end

    -- 要是课程已经完成了 不再继续后面的逻辑
    if client_data.course_step and client_data.course_step >= 10 then
        return
    end

    client_data.course_step = stepNum
    KeepWorkItemManager.SetClientData(GameLogic.QuestAction.task_gsid, client_data)
    -- print(">>>>>>>>>>>>>>>>>>>是否作业", is_home_work)
    -- 判断是课程还是作业
    if is_home_work then
        local status = 0
        local progress = {}
        if stepNum == 10 or stepNum == allStepNum then
            status = 1
        end
        progress.stepNum = stepNum
        -- print(">>>>>>>>>>>>>>>>>>>完成作业", status, stepNum)
        keepwork.quest_complete_homework.set({
            aiHomeworkId = client_data.home_work_id,
            grades = stepNum,
            status = status,
            progress = progress,
        },function(err, message, data)
            if err == 200 then
                if status == 1 then
                    GameLogic.QuestAction.RequestAiHomeWork(function()
                        local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
                        if DockPage.IsShow() then
                            DockPage.FreshHomeWorkIcon()
                        end
                    end)
                end
            end
        end)
    else

        local status = 0
        local progress = {}
        if stepNum == 10 or stepNum == allStepNum then
            status = 1
        end

        progress.stepNum = stepNum

        keepwork.quest_complete_course.set({
            aiCourseId = client_data.course_id,
            status = status,
            progress = progress
        },function(err, message, data)
            -- print(">>>>>>>>>>>>>>>>>>>>>>ai课程设置进度", projectId, stepNum)
            if err == 200 then
                if status == 1 then
                    GameLogic.QuestAction.RequestAiHomeWork(function()
                        GameLogic.QuestAction.RequestCompleteCourseIdList(function()
                            local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
                            if DockPage.IsShow() then
                                DockPage.FreshHomeWorkIcon()
                            end
                        end)
                    end)
                    
                end
            end
        end)
    end
end

function QuestProvider.GetStep()
    -- if projectId == nil then
    --     projectId = WorldCommon.GetWorldTag("kpProjectId") or 0
    --     projectId = tonumber(projectId)
    -- end

    local client_data = GameLogic.QuestAction.GetClientData()
    -- if projectId ~= client_data.course_world_id then
    --     return 0
    -- end
    
    return client_data.course_step or 0
end

function QuestProvider.OnActivateHomework()
    
    -- local projectId = WorldCommon.GetWorldTag("kpProjectId") or 0
    -- projectId = tonumber(projectId)
    local client_data = GameLogic.QuestAction.GetClientData()
    -- if projectId ~= client_data.course_world_id then
    --     return
    -- end

    if client_data.home_work_id == nil or client_data.home_work_id < 0 then
        return
    end

    keepwork.quest_complete_homework.get({
        aiHomeworkId = client_data.home_work_id,
    },function(err, message, data)
        -- print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>查询作业", err)
        -- echo(data, true)
        if err == 200 then
            local userAiHomework = data.userAiHomework
            if userAiHomework then
                return
            end

            keepwork.quest_complete_homework.set({
                aiHomeworkId = client_data.home_work_id,
                grades = 0,
                progress = {},
                status = 0,
            },function(err2, message2, data2)
                -- print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>激活作业", err)
                -- echo(data, true)
                if err == 200 then
                    GameLogic.QuestAction.RequestAiHomeWork(function()
                        local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
                        if DockPage.IsShow() then
                            DockPage.FreshHomeWorkIcon()
                        end
                    end)
                end
            end)
        end

    end)


end