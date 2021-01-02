--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldCodeList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldCodeList.lua");
ParaWorldCodeList.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapSurface.lua");
local ParaWorldMinimapSurface = commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ParaWorldCodeList = NPL.export();

local codeList = {};
local isCodeListShow = false;
local page;
function ParaWorldCodeList.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldCodeList.ShowPage(codeBlocks)
	if (not isCodeListShow) then
		isCodeListShow = true;
		codeList = codeBlocks or codeList;

		local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldCodeList.html",
			name = "ParaWorldCodeList.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
			align = "_lt",
			x = 70,
			y = 72,
			width = 200,
			height = 130,
		};
		System.App.Commands.Call("File.MCMLWindowFrame", params);

		params._page.OnClose = function()
			isCodeListShow = false;
		end
	else
		ParaWorldCodeList.OnClose();
	end
end

function ParaWorldCodeList.OnClose()
	if (page) then
		page:CloseWindow();
	end
end

function ParaWorldCodeList.GetCodeList()
	return codeList;
end

function ParaWorldCodeList.CanOpenCodeBlock(index)
	local codeBlock = codeList[index];
	local entity = EntityManager.GetBlockEntity(codeBlock.x, codeBlock.y, codeBlock.z);
	return entity and entity:IsOpenSource();
end

function ParaWorldCodeList.OpenCode(index)
	local codeBlock = codeList[index];
	local entity = EntityManager.GetBlockEntity(codeBlock.x, codeBlock.y, codeBlock.z);
	if (entity) then
		local y = ParaWorldMinimapSurface:GetHeightByWorldPos(codeBlock.x+2, codeBlock.z+2);
		GameLogic.RunCommand(string.format("/goto %d %d %d", codeBlock.x+2, y, codeBlock.z+2));
		entity:OpenEditor("entity", entity);
		page:CloseWindow();
	end
end
