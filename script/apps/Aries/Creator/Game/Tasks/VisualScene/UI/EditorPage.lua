--[[
Title: EditorPage
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local EditorPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/EditorPage.lua");
EditorPage.ShowPage();
------------------------------------------------------------
--]]
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
local EditorPage = NPL.export();
EditorPage.Current_Item_DS = {};
local page;
function EditorPage.OnInit()
	page = document:GetPageCtrl();
end

function EditorPage.ShowPage()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/EditorPage.html",
			name = "EditorPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			directPosition = true,
				align = "_lt",
				x = 10,
				y = 30,
				width = 600,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
    EditorPage.OnRefresh();
end
function EditorPage.OnRefresh()
    local editor = VisualSceneLogic.createOrGetEditor("first_editor");
    local ds = {};
    local parent = editor.Scene.RootNode;
    local len = parent:getChildCount();
    for k = 1, len do
        local child = parent:getChild(k);
        table.insert(ds,{
            node = child
        });
    end

    EditorPage.Current_Item_DS = ds;
    if(page)then
        page:Refresh(0);
    end
end
