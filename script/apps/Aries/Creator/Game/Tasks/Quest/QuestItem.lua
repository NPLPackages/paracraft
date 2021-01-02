--[[
Title: QuestItem
Author(s): leio
Date: 2020/12/8
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestItem.lua");
local QuestItem = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestItem");
-------------------------------------------------------
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestItemTemplate.lua");
local QuestItemTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestItemTemplate");

NPL.load("(gl)script/ide/EventDispatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestProvider.lua");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");

local QuestItem = commonlib.inherit(commonlib.gettable("commonlib.EventSystem"),commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestItem"))

QuestItem.Events = {
    OnChanged = "OnChanged",
}
function QuestItem:ctor()
end
function QuestItem:OnInit(id, value, template, parent)
    self.id = id;
    self.value = value;
    self.finished_value = template.finished_value;
    self.template = template;
    self.parent = parent;
    return self;
end

function QuestItem:GetValue()
    return self.value;
end
function QuestItem:SetValue(value)
    self.value = value;
    self:DispatchEvent({ type = QuestItem.Events.OnChanged, });
end
function QuestItem:GetValueType()
    local type = type(self.finished_value);
    return type;
end
function QuestItem:CanFinish()
    if(self.value and self.finished_value)then
        local type = self:GetValueType();
        if(type == "number")then
            return self.value >= self.finished_value;
        elseif(type == "string")then
            return self.value == self.finished_value;
        end
    end
end
-- only saving this data to server
function QuestItem:GetData()
    local data = {
        id = self.id,
        value = self.value,
    }
    return data;
end
function QuestItem:Refresh()
    if(self.template.type == QuestItemTemplate.Types.REAL)then
        local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(self.id)
        if(bOwn)then
            self.value = copies or 0;
        end
    end
end
function QuestItem:GetDumpData()
    local data = {
        id = self.id,
        value = self.value,
        finished_value = self.finished_value,
    }
    return data;
end
