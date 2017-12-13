--[[
Title: Edit CheckPoint Page
Author(s): dummy
Date: 2017/12/06
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/CheckpointEditPage.lua");
local CheckpointEditPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CheckpointEditPage");
CheckpointEditPage.ShowPage(block_entity);
-------------------------------------------------------
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local CheckpointEditPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CheckpointEditPage");

local cur_entity;
local page;

function CheckpointEditPage.OnInit()
	page = document:GetPageCtrl();
end

function CheckpointEditPage.GetEntity()
	return cur_entity;
end

function CheckpointEditPage.GetItemID()
	if(cur_entity) then
		return cur_entity:GetBlockId();
	else
		return 0;
	end
end

function CheckpointEditPage.GetItemName()
	local name;
	if(CheckpointEditPage.GetEntity()) then
		name = CheckpointEditPage.GetEntity():GetDisplayName();
	end
	local type_name;
    local block = block_types.get(CheckpointEditPage.GetItemID())
    if(block) then
        type_name = block:GetDisplayName();
	else
		local item = ItemClient.GetItem(CheckpointEditPage.GetItemID());
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

function CheckpointEditPage.GetCheckPointCommand()
	if(cur_entity) then
		local cpData = cur_entity:GetBindCheckPoint();
		if (cpData) then
			return cpData.attr.cmdList;
		end
	end
end

function CheckpointEditPage.GetCheckpointPos()
	if(cur_entity) then
		local cpData = cur_entity:GetBindCheckPoint();
		if (cpData) then
			if cpData.attr.x then
				return string.format("%d %d %d", cpData.attr.x, cpData.attr.y, cpData.attr.z);
			end
		end
		
		
		local x,y,z = cur_entity:GetBlockPos();
		return string.format("%d %d %d", x, y + 1, z);
	end
end

function CheckpointEditPage.GetCheckpointName()
	if(cur_entity) then
		return cur_entity:GetCheckpointName();
	end
end

function CheckpointEditPage.ShowPage(entity, triggerEntity)
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
	local params = {
			url = format("script/apps/Aries/Creator/Game/GUI/CheckpointEditPage.html?id=%d", entity:GetBlockId()), 
			name = "CheckpointEditPage.ShowPage", 
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

	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		EntityManager.SetLastTriggerEntity(nil);
		entity:EndEdit();
		page = nil;
	end
end

function CheckpointEditPage.CloseWindow()
	if(page) then
		page:CloseWindow();
	end
end

function CheckpointEditPage.OnClickOK()
	local entity = CheckpointEditPage.GetEntity();
	if(entity) then

		
		local cpname = page:GetValue("cpname", "")
		entity:SetCheckpointName(cpname);
		
		local command = page:GetValue("command", "")
		command = command:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\r\n]+$", "");
		local posStr = page:GetValue("CheckpointPos", "")
		
		local x, y, z, posStr = posStr:match("^([~%-%d]%-?%d*)%s+([~%-%d]%-?%d*)%s+([~%-%d]%-?%d*)%s*(.*)$");
		if(x) then
			x = tonumber(x);
			y = tonumber(y);
			z = tonumber(z);
		end
		
		entity:writeCheckPoint({cmdList = command, x = x, y = y, z = z});

		entity:Refresh(true);
	end
	page:CloseWindow();
end

function CheckpointEditPage.OnClickEmptyRuleSlot(slotNumber)
	local entity = CheckpointEditPage.GetEntity()
	if(entity) then
		local contView = entity.cmpBagView;
		if(contView and slotNumber) then
			local slot = contView:GetSlot(slotNumber);
			entity:OnClickEmptySlot(slot);
		end
	end
end

function CheckpointEditPage.OnClickEmptyBagSlot(slotNumber)
	local entity = CheckpointEditPage.GetEntity()
	if(entity) then
		local contView = entity.inventoryView;
		if(contView and slotNumber) then
			local slot = contView:GetSlot(slotNumber);
			entity:OnClickEmptySlot(slot);
		end
	end
end