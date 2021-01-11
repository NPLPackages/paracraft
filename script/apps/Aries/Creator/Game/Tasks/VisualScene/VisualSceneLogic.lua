--[[
Title: VisualSceneLogic 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
local editor = VisualSceneLogic.onSelectedEditorByName(VisualSceneLogic.PresetEditors.GlobalEditor);
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

VisualSceneLogic.PresetEditors = {
    GlobalEditor = "GlobalEditor",
}
function VisualSceneLogic.createOrGetEditor(name)
    if(not name)then
        return
    end
    local editor = VisualSceneLogic.editors[name];
    if(not editor)then
        editor = Editor:new();
        editor.Name = name;
    end
    VisualSceneLogic.editors[name] = editor;
    return editor;
end
-- getSelectedEditor
function VisualSceneLogic.getSelectedEditor()
    return VisualSceneLogic.cur_editor;
end
-- reSelectedEditor
function VisualSceneLogic.reSelectedEditor()
    VisualSceneLogic.onSelectedEditorByName(VisualSceneLogic.getSelectedEditorName())
end
-- getSelectedEditorName
function VisualSceneLogic.getSelectedEditorName()
    if(VisualSceneLogic.cur_editor)then
        return VisualSceneLogic.cur_editor.Name;
    end
end
-- onSelectedEditorByName
function VisualSceneLogic.onSelectedEditorByName(name)
    if(not name)then
        return
    end
    VisualSceneLogic.cur_editor = VisualSceneLogic.createOrGetEditor(name);
	GameLogic.GetFilters():apply_filters("VisualSceneLogic.onSelectedEditorByName", name);
    return VisualSceneLogic.cur_editor;
end
function VisualSceneLogic.nofityChanged()
	GameLogic.GetFilters():apply_filters("VisualSceneLogic.nofityChanged");
end