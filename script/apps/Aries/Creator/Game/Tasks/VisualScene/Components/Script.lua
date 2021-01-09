--[[
Title: Script 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local Script = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Components/Script.lua");
------------------------------------------------------------
--]]
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
local BaseComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BaseComponent.lua");
local Script = commonlib.inherit(BaseComponent, NPL.export());

Script:Property({"ComponentName", "Script", auto = true,  camelCase = true, });
Script:Property({"Code", "", auto = true,  camelCase = true, });

function Script:ctor()
end

function Script:processCode()
    -- install methods
end
function Script:onAddedToNode(node)
    node.Script = self;
end
function Script:onRemovedFromNode(node)
    node.Script = nil;
end
function Script:onAddedToScene(scene)
    if(self.Name)then
        VisualSceneLogic.active_scripts[self.Name] = self;
    end
end
function Script:onRemovedFromScene(scene)
    VisualSceneLogic.active_scripts[self.Name] = nil;
end
function Script:toJson()
    local object = self._super:toJson();
    object.ComponentName = self.ComponentName;
    object.Code = self.Code;
    return object;
end





