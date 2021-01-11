--[[
Title: SceneNodeInspector
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local SceneNodeInspector = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/Inspector/SceneNodeInspector.lua");
------------------------------------------------------------
--]]
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
local SceneNodeInspector = NPL.export();
local page;
local editor;
local node;

SceneNodeInspector.components = {};
function SceneNodeInspector.OnInit()
    page = document:GetPageCtrl();


    SceneNodeInspector.components = {};

    editor = VisualSceneLogic.getSelectedEditor();
    if(editor and editor.selected)then
        node = editor.selected;
        local ds = {};

        for k,v in ipairs(node.components) do
            table.insert(ds,{
                component = v
            });
        end
        SceneNodeInspector.components = ds;
    end
    
end

function SceneNodeInspector.RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end