--[[
Title: Scene
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local Scene = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Scene.lua");
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
local SceneNode = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/SceneNode.lua");
local Scene = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
Scene:Property({"Uid", "", auto = true, camelCase = true, });
Scene:Property({"Name", "", auto = true, camelCase = true, });
Scene:Property({"RootNode", auto = true, type = "SceneNode", camelCase = true, });

function Scene:ctor()
    self.RootNode  = SceneNode:new();
    self.RootNode.Scene = self;
    self.RootNode.IsRoot = true;
end
function Scene:clear()
    self.RootNode:clearAllChildren();
end
function Scene:toJson()
    local object = {};
    object.Uid = self.Uid;
    object.Name = self.Name;
    object.RootNode = self.RootNode:toJson();
    return object;
end