--[[
Title: EditorInspector
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local EditorInspector = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/Inspector/EditorInspector.lua");
------------------------------------------------------------
--]]
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
local EditorInspector = NPL.export();
local page;
local editor;

EditorInspector.Current_Item_DS = {};
function EditorInspector.OnInit()
    page = document:GetPageCtrl();


    EditorInspector.Current_Item_DS = {};

    editor = VisualSceneLogic.getSelectedEditor();
    if(editor)then
        local ds = {};
        local parent = editor.Scene.RootNode;
        local len = parent:getChildCount();
        for k = 1, len do
            local child = parent:getChild(k);
            table.insert(ds,{
                node = child
            });
        end

        EditorInspector.Current_Item_DS = ds;
    end
    
end

function EditorInspector.RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end