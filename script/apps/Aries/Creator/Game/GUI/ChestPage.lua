--[[
Title: ChestPage
Author(s): LiXizhi
Date: 2014/1/7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ChestPage.lua");
local ChestPage = commonlib.gettable("MyCompany.Aries.Game.GUI.ChestPage");
ChestPage.ShowPage(entity);
-------------------------------------------------------
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local ChestPage = commonlib.gettable("MyCompany.Aries.Game.GUI.ChestPage");

local cur_entity;
local page;

function ChestPage.OnInit()
	page = document:GetPageCtrl();
end

function ChestPage.GetEntity()
	return cur_entity;
end

function ChestPage.GetContainerView()
	if(cur_entity) then
		return cur_entity.inventoryView;
	end
end

function ChestPage.GetItemID()
	if(cur_entity) then
		return cur_entity:GetBlockId();
	else
		return 0;
	end
end

function ChestPage.GetItemName()
    local block = block_types.get(ChestPage.GetItemID())
    if(block) then
        return block:GetDisplayName();
    end
end

function ChestPage.GetCommand()
	if(cur_entity) then
		return cur_entity:GetCommand();
	end
end

function ChestPage.ShowPage(entity, OnClose)
	if(not entity) then
		return;
	end
	cur_entity = entity;
	entity:BeginEdit();
	local params;
	if(System.options.IsMobilePlatform) then
		params = {
			url = "script/apps/Aries/Creator/Game/GUI/ChestPage.mobile.html", 
			name = "ChestPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -280,
				y = -270,
				width = 560,
				height = 520,
		};
	else
		params = {
			url = "script/apps/Aries/Creator/Game/GUI/ChestPage.html", 
			name = "ChestPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -210,
				y = -190,
				width = 420,
				height = 380,
		};
	end
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		entity:EndEdit();
		if(OnClose) then
			OnClose();
		end
	end
end
