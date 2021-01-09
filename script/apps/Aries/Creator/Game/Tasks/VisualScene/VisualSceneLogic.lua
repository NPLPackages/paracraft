--[[
Title: VisualSceneLogic 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
local editor = VisualSceneLogic.activedEditor("first_editor");
local node, code_component, movieclip_component = editor:createBlockCodeNode();
if(node and code_component)then
    code_component:setCodeFileName("test/follow.lua")
    node:run();
end
echo(editor:toJson(),true);
------------------------------------------------------------
--]]
local Editor = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/Editor.lua");

local VisualSceneLogic = NPL.export();
VisualSceneLogic.active_scripts = {};
VisualSceneLogic.editors = {};

function VisualSceneLogic.createOrGetEditor(name)
    if(not name)then
        return
    end
    local editor = VisualSceneLogic.editors[name];
    if(not editor)then
        editor = Editor:new();
    end
    VisualSceneLogic.editors[name] = editor;
    return editor;
end
function VisualSceneLogic.activedEditor(name)
    VisualSceneLogic.cur_editor = VisualSceneLogic.createOrGetEditor(name);
    return VisualSceneLogic.cur_editor;
end
function VisualSceneLogic.getActivedEditor()
    return VisualSceneLogic.cur_editor;
end