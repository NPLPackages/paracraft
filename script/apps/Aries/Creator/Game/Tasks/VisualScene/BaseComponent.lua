--[[
Title: BaseComponent 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local BaseComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BaseComponent.lua");
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local BaseComponent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

BaseComponent:Property({"Uid", "", auto = true,  camelCase = true, });
BaseComponent:Property({"Name", "", auto = true,  camelCase = true, });
BaseComponent:Property({"ComponentName", "BaseComponent", auto = true,  camelCase = true, });
BaseComponent:Property({"SceneNode", auto = true, type = "SceneNode", camelCase = true, });

function BaseComponent:ctor()
end

function BaseComponent:toJson()
    local object = {};
    object.Uid = self.Uid;
    object.Name = self.Name;
    object.ComponentName = self.ComponentName;
    return object;
end
