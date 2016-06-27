--[[
Title: Edit Entity Page
Author(s): LiXizhi
Date: 2013/12/22
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditItemPage.lua");
local EditItemPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditItemPage");
EditItemPage.ShowPage(item_id)
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EditItemPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditItemPage");

local curItem;

function EditItemPage.OnInit()
end

function EditItemPage.GetItem()
	return curItem;
end

function EditItemPage.GetItemID()
	return curItem.id;
end

function EditItemPage.GetItemName()
    return curItem:GetDisplayName();
end

function EditItemPage.ShowPage(item_id)
	if(not item_id) then
		return;
	end
	curItem = ItemClient.GetItem(item_id);
	if(not curItem) then
		return;
	end

	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/EditItemPage.html", 
			name = "EditItemPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -180,
				y = -200,
				width = 360,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
