--[[
Title: Transform 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local Transform = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Components/Transform.lua");
------------------------------------------------------------
--]]
local BaseComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BaseComponent.lua");
local Transform = commonlib.inherit(BaseComponent, NPL.export());

Transform:Property({"ComponentName", "Transform", auto = true,  camelCase = true, });
Transform:Property({"Position", {0,0,0}, auto = true,  camelCase = true, });
Transform:Property({"Rotation", {0,0,0,1}, auto = true,  camelCase = true, });
Transform:Property({"Scale", {1,1,1}, auto = true,  camelCase = true, });

function Transform:ctor()
end

function Transform:onAddedToNode(node)
    node.Transform = self;
end
function Transform:onRemovedFromNode(node)
    node.Transform = nil;
end
function Transform:toJson()
    local object = self._super:toJson();
    object.ComponentName = self.ComponentName;
    object.Position = { self.Position[1], self.Position[2], self.Position[3], };
    object.Rotation = { self.Rotation[1], self.Rotation[2], self.Rotation[3], self.Rotation[4], };
    object.Scale = { self.Scale[1], self.Scale[2], self.Scale[3], };
    return object;
end





