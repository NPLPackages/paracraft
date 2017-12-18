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
local CheckPointIO = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CheckPointIO");

local cur_checkpoint;
local cur_entity;
local page;

function CheckpointEditPage.OnInit()
	page = document:GetPageCtrl();
end

function CheckpointEditPage.OnClose()
    page:CloseWindow();
	page = nil;
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

function CheckpointEditPage.isSelected(index)
	if(CheckpointEditPage.select_checkpoint_index == index) then
		return true;
	else
		return false;
	end	
end	


function CheckpointEditPage.SetCurCheckpoint(index)
	CheckpointEditPage.select_checkpoint_index = index;
	cur_checkpoint = CheckPointIO.world_points[index];
	
	if cur_checkpoint then
		local cpData = CheckPointIO.read(cur_checkpoint.name);
		if cpData and cpData[1] and cpData[1].name == "cmpBag" then
			if cur_entity then
				cur_entity.cmpBag:Clear();
				cur_entity.cmpBag:LoadFromXMLNode(cpData[1]);
				
				if page then
					page:Refresh(0.01);
				end
			end
		end
	end
end	

function CheckpointEditPage.GetRulebagView()
	return cur_entity.cmpBagView;
end

function CheckpointEditPage.GetItemName()
	local name;
	if(cur_entity) then
		name = cur_entity:GetDisplayName();
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
	if (cur_checkpoint) then
		return cur_checkpoint.attr.cmdList;
	else
		return "";
	end
end

function CheckpointEditPage.GetCheckpointPos()
	if (cur_checkpoint) then
		if cur_checkpoint.attr.x then
			return string.format("%d %d %d", cur_checkpoint.attr.x, cur_checkpoint.attr.y, cur_checkpoint.attr.z);
		end
	elseif (cur_entity) then	
		local x,y,z = cur_entity:GetBlockPos();
		return string.format("%d %d %d", x, y + 1, z);		
	end
end

function CheckpointEditPage.GetBindName()
	if(cur_entity) then
		return cur_entity:GetBindName();
	end
end

function CheckpointEditPage.GetCheckpointName()
	if cur_checkpoint then
		return cur_checkpoint.name;
	elseif cur_entity then
		return cur_entity:GetDefaultCheckPointName();
	end
end

function CheckpointEditPage.ShowPage(entity, triggerEntity)
	if(not entity) then
		return;
	end
	EntityManager.SetLastTriggerEntity(entity);
	
	CheckpointEditPage.select_checkpoint_index = nil;
	cur_checkpoint = nil;
	
	if(page) then
		page:CloseWindow();
	end
	cur_entity = entity;
	cur_checkpoint = cur_entity:GetBindCheckPoint();
	
	if cur_checkpoint then
		for inx, wp in ipairs(CheckPointIO.world_points) do
			if wp.name == cur_checkpoint.name then
				CheckpointEditPage.SetCurCheckpoint(inx);
				break;
			end
		end
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
				width = 800,
				height = 500,
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

function CheckpointEditPage.OnClickDelete()
	local entity = cur_entity;
	if(entity) then
		local cpname = page:GetValue("cpname", "");
		if CheckPointIO.writeEmpty(cpname) then
			if page then
				page:Refresh(0.01);
			end
		end
	end
end

function CheckpointEditPage.OnClickSave()
	local entity = cur_entity;
	if(entity) then		
		local cpname = page:GetValue("cpname", "")
		local command = page:GetValue("command", "")
		command = command:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\r\n]+$", "");
		local posStr = page:GetValue("CheckpointPos", "")
		
		local x, y, z, posStr = posStr:match("^([~%-%d]%-?%d*)%s+([~%-%d]%-?%d*)%s+([~%-%d]%-?%d*)%s*(.*)$");
		if(x) then
			x = tonumber(x);
			y = tonumber(y);
			z = tonumber(z);
		end
		
		entity:writeCheckPoint({cmdList = command, x = x, y = y, z = z}, cpname);

		entity:Refresh(true);
		
		cur_checkpoint = CheckPointIO.read(cpname);
		
		if cur_checkpoint then
			for inx, wp in ipairs(CheckPointIO.world_points) do
				if wp.name == cur_checkpoint.name then
					CheckpointEditPage.SetCurCheckpoint(inx);
					break;
				end
			end
		end
	end

end

function CheckpointEditPage.OnClickEmptyRuleSlot(slotNumber)
	local entity = cur_entity
	if(entity) then
		local contView = entity.cmpBagView;
		if(contView and slotNumber) then
			local slot = contView:GetSlot(slotNumber);
			entity:OnClickEmptySlot(slot);
		end
	end
end

function CheckpointEditPage.OnClickEmptyBagSlot(slotNumber)
	local entity = cur_entity
	if(entity) then
		local contView = entity.inventoryView;
		if(contView and slotNumber) then
			local slot = contView:GetSlot(slotNumber);
			entity:OnClickEmptySlot(slot);
		end
	end
end

function CheckpointEditPage.getCheckPointDs()
	local worldPointDs = {};
	
	
	for kk, vv in ipairs(CheckPointIO.world_points) do
		worldPointDs[kk] = {};
		worldPointDs[kk].name = vv.name;
		worldPointDs[kk].id = kk;
	end
	return worldPointDs;
end

function CheckpointEditPage.OnClickBind()
	if(cur_entity and cur_checkpoint) then
		cur_entity:SetBindName(cur_checkpoint.name);
		if page then
			page:Refresh(0.01);
		end
	end
end

function CheckpointEditPage.OnClickCreate()
	CheckpointEditPage.select_checkpoint_index = nil;
	cur_checkpoint = nil;
	
	cur_entity.cmpBag:Clear();
	--cur_entity:SetCheckpointName();
	if page then
		page:Refresh(0.01);
	end
end

function CheckpointEditPage.OnClickUp()
	if CheckpointEditPage.select_checkpoint_index > 1 then
		CheckPointIO.switchWorldPos(CheckpointEditPage.select_checkpoint_index, CheckpointEditPage.select_checkpoint_index - 1);
		CheckPointIO._writeWorld();
		CheckpointEditPage.SetCurCheckpoint(CheckpointEditPage.select_checkpoint_index - 1)
	end	
end

function CheckpointEditPage.OnClickDown()
	if CheckpointEditPage.select_checkpoint_index < #CheckPointIO.world_points then
		CheckPointIO.switchWorldPos(CheckpointEditPage.select_checkpoint_index, CheckpointEditPage.select_checkpoint_index + 1);
		CheckPointIO._writeWorld();
		CheckpointEditPage.SetCurCheckpoint(CheckpointEditPage.select_checkpoint_index + 1)
	end	
end