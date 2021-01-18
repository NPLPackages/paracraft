--[[
Title: VisualSceneLogic 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
VisualSceneLogic.OnWorldLoaded();
------------------------------------------------------------
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local Editor = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/Editor.lua");

local VisualSceneLogic = NPL.export();
VisualSceneLogic.active_scripts = {};
VisualSceneLogic.editors = {};

VisualSceneLogic.PresetEditors = {
    GlobalEditor = "GlobalEditor",
}
function VisualSceneLogic.OnWorldLoaded()
    local editor = VisualSceneLogic.onSelectedEditorByName(VisualSceneLogic.PresetEditors.GlobalEditor);
    if(not editor)then
        return
    end
    local node, code_component, movieclip_component = editor:createOrGetFollowMagic();
    if(node and code_component and movieclip_component)then
        -- active magic by internal code
        node:run();
    end
end
function VisualSceneLogic.OnWorldUnload()
    local editor = VisualSceneLogic.onSelectedEditorByName(VisualSceneLogic.PresetEditors.GlobalEditor);
    if(not editor)then
        return
    end
    local node, code_component, movieclip_component = editor:createOrGetFollowMagic();
    if(node and code_component and movieclip_component)then
        -- stop magic by internal code
        node:stop();
    end
end
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