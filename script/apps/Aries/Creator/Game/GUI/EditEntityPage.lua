--[[
Title: Edit Entity Page
Author(s): LiXizhi
Date: 2013/12/22
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
EditEntityPage.ShowPage(block_id);
-------------------------------------------------------
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");

local cur_entity;
local page;

function EditEntityPage.OnInit()
	page = document:GetPageCtrl();
end

function EditEntityPage.GetEntity()
	return cur_entity;
end

function EditEntityPage.GetItemID()
	if(cur_entity) then
		return cur_entity:GetBlockId();
	else
		return 0;
	end
end

function EditEntityPage.GetItemName()
	local name;
	if(EditEntityPage.GetEntity()) then
		name = EditEntityPage.GetEntity():GetDisplayName();
	end
	local type_name;
    local block = block_types.get(EditEntityPage.GetItemID())
    if(block) then
        type_name = block:GetDisplayName();
	else
		local item = ItemClient.GetItem(EditEntityPage.GetItemID());
		if(item) then
			type_name = item:GetDisplayName();
		end
    end
	if(not name) then
		return type_name;
	else
		return name..":"..(type_name or "");
	end
end

function EditEntityPage.GetCommand()
	if(cur_entity) then
		return cur_entity:GetCommand();
	end
end

function EditEntityPage.ShowPage(entity, triggerEntity)
	if(not entity) then
		return;
	end
	EntityManager.SetLastTriggerEntity(entity);
	
	if(cur_entity~=entity) then
		if(page) then
			page:CloseWindow();
		end
		cur_entity = entity;
	end
	entity:BeginEdit();
	local params;
	if(System.options.IsMobilePlatform) then
		params = {
			url = format("script/apps/Aries/Creator/Game/GUI/EditEntityPage.mobile.html?id=%d", entity:GetBlockId()), 
			name = "EditEntityPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			bShow = true,
			click_through = true, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			bAutoSize = true,
			bAutoHeight = true,
			-- cancelShowAnimation = true,
			directPosition = true,
				align = "_ct",
				x = -280,
				y = -300,
				width = 560,
				height = 600,
		};
	else
		params = {
			url = format("script/apps/Aries/Creator/Game/GUI/EditEntityPage.html?id=%d", entity:GetBlockId()), 
			name = "EditEntityPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			bShow = true,
			click_through = true, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			bAutoSize = true,
			bAutoHeight = true,
			-- cancelShowAnimation = true,
			directPosition = true,
				align = "_ct",
				x = -200,
				y = -250,
				width = 400,
				height = 560,
		};
	end
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		EntityManager.SetLastTriggerEntity(nil);
		entity:EndEdit();
		page = nil;
	end
end

function EditEntityPage.CloseWindow()
	if(page) then
		page:CloseWindow();
	end
end

function EditEntityPage.OnClickOK()
	local entity = EditEntityPage.GetEntity();
	if(entity) then
		local command = page:GetValue("command", "")
		command = command:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\r\n]+$", "");
		entity:SetCommand(command);
		entity:Refresh(true);
	end
	page:CloseWindow();
end

function EditEntityPage.OnClickEmptyRuleSlot(slotNumber)
	local entity = EditEntityPage.GetEntity()
	if(entity) then
		local contView = entity.rulebagView;
		if(contView and slotNumber) then
			local slot = contView:GetSlot(slotNumber);
			entity:OnClickEmptySlot(slot);
		end
	end
end

function EditEntityPage.OnClickEmptyBagSlot(slotNumber)
	local entity = EditEntityPage.GetEntity()
	if(entity) then
		local contView = entity.inventoryView;
		if(contView and slotNumber) then
			local slot = contView:GetSlot(slotNumber);
			entity:OnClickEmptySlot(slot);
		end
	end
end