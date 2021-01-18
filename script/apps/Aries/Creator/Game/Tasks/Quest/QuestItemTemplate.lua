--[[
Title: QuestItemTemplate
Author(s): leio
Date: 2020/12/8
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestItemTemplate.lua");
local QuestItemTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestItemTemplate");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/EventDispatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestProvider.lua");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local QuestItemTemplate = commonlib.inherit(nil,commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestItemTemplate"))
QuestItemTemplate.Types = {
    NONE = "NONE", 

    VIRTUAL = "VIRTUAL", -- for virtual target
    REAL = "REAL",  -- for real item 

}
function QuestItemTemplate:ctor()
    -- property list
    self.exid = nil; -- number
    self.gsid = nil; -- number
    self.id = nil; -- string or number
    self.type = QuestItemTemplate.Types.NONE;
    self.finished_value = nil;
    self.title = nil;
    self.desc = nil;
    self.goto_world = nil; -- ["ONLINE","RELEASE","LOCAL"]
    self.click = nil;
    self.task_type = nil; --main branch loop
    self.custom_show = nil; -- true to custom showing label, see QuestAction.GetLabel(task_id)
    self.exp = nil;  -- exp for gift
    self.order = nil -- "order" be use to sort task
end
function QuestItemTemplate:GetUniqueKey()
    local key = string.format("%s_%s",tostring(self.gsid), tostring(self.id));
    return key;
end
function QuestItemTemplate:GetData()
    local data = {
        exid = self.exid,
        gsid = self.gsid,
        id = self.id,
        type = self.type,
        finished_value = self.finished_value,
        title = self.title,
        desc = self.desc,
        goto_world = self.goto_world,
        click = self.click,
        task_type = self.task_type,
        custom_show = self.custom_show,
        exp = self.exp,
        order = self.order,
    }
    return data;
end
function QuestItemTemplate:GetCurVersionValue(key)
    local arr = self[key]
    if(type(arr) == "table")then
        local values = self:ArrayToVersions(arr);
        local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
	    local v = values[httpwrapper_version];
        return v;
    end
    return arr;
end
function QuestItemTemplate:ArrayToVersions(arr)
    if(not arr)then
        return {};
    end
    local result = {};
    result["ONLINE"] = arr[1];
    result["RELEASE"] = arr[2];
    result["LOCAL"] = arr[3];
    return result;
end
