--[[
Title: VisualSceneLogic 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
VisualSceneLogic.staticInit();
------------------------------------------------------------
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local SkySpacePairBlock = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BlockPositionAllocations/SkySpacePairBlock.lua");

local Editor = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/Editor.lua");

local VisualSceneLogic = NPL.export();
VisualSceneLogic.active_scripts = {};
VisualSceneLogic.editors = {};

VisualSceneLogic.PresetEditors = {
    GlobalEditor = "GlobalEditor",
}
function VisualSceneLogic.staticInit()
    GameLogic:Connect("WorldLoaded", VisualSceneLogic, VisualSceneLogic.OnWorldLoaded, "UniqueConnection");
	GameLogic:Connect("WorldUnloaded", VisualSceneLogic, VisualSceneLogic.OnWorldUnload, "UniqueConnection");
end
function VisualSceneLogic.OnWorldLoaded()
	LOG.std(nil, "info", "VisualSceneLogic", "OnWorldLoaded");
    VisualSceneLogic.is_init = true;

    local editor = VisualSceneLogic.createOrGetEditor();
    if(editor)then
        editor:reload();
    end
end
function VisualSceneLogic.OnWorldUnload()
	LOG.std(nil, "info", "VisualSceneLogic", "OnWorldUnload");
    VisualSceneLogic.is_init = false;
end
-- @param name: default name is "GlobalEditor"
function VisualSceneLogic.createOrGetEditor(name)
    if(not VisualSceneLogic.is_init)then
		LOG.std(nil, "info", "VisualSceneLogic", "VisualSceneLogic isn't initiated");
        return
    end
    name = name or VisualSceneLogic.PresetEditors.GlobalEditor;
    local block_pos_allocation = VisualSceneLogic.block_pos_allocation;
    if(not block_pos_allocation)then
        block_pos_allocation = SkySpacePairBlock:new();
        VisualSceneLogic.block_pos_allocation = block_pos_allocation;
    end
    local editor = VisualSceneLogic.editors[name];
    if(not editor)then
        --NOTE: using global position allocation for every editor
        editor = Editor:new():onInit(block_pos_allocation);
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