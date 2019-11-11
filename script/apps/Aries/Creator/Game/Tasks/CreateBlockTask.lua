--[[
Title: Create Block task
Author(s): LiXizhi
Date: 2013/1/20
Desc: Create a single or a chunk of blocks at the given position.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
-- @param side: this is OPPOSITE of the touching side
local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, data=nil, side = nil, side_region=[nil, "upper", "lower"], block_id = 1, entityPlayer, itemStack})
task:Run();

-- create several blocks
local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, blocks = {{1,1,1,1}}})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CreateBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateBlock"));

-- if true, we will skip history
CreateBlock.nohistory = nil

function CreateBlock:ctor()
end

-- @return bCreated
function CreateBlock:TryCreateSingleBlock()
	local item = ItemClient.GetItem(self.block_id);
	if(item) then
		local entityPlayer = self.entityPlayer;
		local itemStack;
		local isUsed;
		if(entityPlayer) then
			itemStack = self.itemStack or entityPlayer.inventory:GetItemInRightHand();
			if(itemStack) then
				if(GameLogic.GameMode:IsEditor()) then
					EntityManager.GetPlayer().inventory:PickBlock(block_id);
					-- does not decrease count in creative mode. 
					local oldCount = itemStack.count;
					isUsed = itemStack:TryCreate(entityPlayer, self.blockX,self.blockY,self.blockZ, self.side, self.data, self.side_region);
					itemStack.count = oldCount;
				else
					isUsed = itemStack:TryCreate(entityPlayer, self.blockX,self.blockY,self.blockZ, self.side, self.data, self.side_region);	
					if(isUsed) then
						entityPlayer.inventory:OnInventoryChanged(entityPlayer.inventory:GetHandToolIndex());
					end
				end
			end
		else
			isUsed = item:TryCreate(nil, EntityManager.GetPlayer(), self.blockX,self.blockY,self.blockZ, self.side, self.data, self.side_region);
		end
			
		return isUsed;
	end
end

function CreateBlock:Run()
	self.finished = true;
	self.history = {};

	local add_to_history;

	local blocks;

	if(self.block_id) then
		if(not self.blockX) then
			local player = self.entityPlayer or EntityManager.GetPlayer();
			if(player) then
				self.blockX, self.blockY, self.blockZ = player:GetBlockPos();
			end
			if(not self.blockX) then
				return;
			end
		end

		self.last_block_id = BlockEngine:GetBlockId(self.blockX,self.blockY,self.blockZ);
		self.last_block_data = BlockEngine:GetBlockData(self.blockX,self.blockY,self.blockZ);
		self.last_entity_data = BlockEngine:GetBlockEntityData(self.blockX,self.blockY,self.blockZ);

		if(self:TryCreateSingleBlock()) then

			local block_id, block_data, entity_data = BlockEngine:GetBlockFull(self.blockX, self.blockY, self.blockZ);
			if(block_id == self.block_id) then
				self.data = block_data;
				self.entity_data = entity_data;

				local tx, ty, tz = BlockEngine:real(self.blockX,self.blockY,self.blockZ);
				GameLogic.PlayAnimation({facingTarget = {x=tx, y=ty, z=tz},});
				GameLogic.events:DispatchEvent({type = "CreateBlockTask" , block_id = self.block_id, block_data = block_data, x = self.blockX, y = self.blockY, z = self.blockZ,
					last_block_id = self.last_block_id, last_block_data = self.last_block_data});
			end
			if(not self.nohistory) then
				if(GameLogic.GameMode:CanAddToHistory()) then
					add_to_history = true;
					self.add_to_history = true;
				end
			end
		else
			return
		end
	elseif(self.blocks) then
		-- create a chunk of blocks
		local dx = self.blockX or 0;
		local dy = self.blockY or 0;
		local dz = self.blockZ or 0;

		if(not self.nohistory) then
			if(GameLogic.GameMode:CanAddToHistory()) then
				add_to_history = true;
				self.add_to_history = true;
			end
		end

		blocks = {};
		local _, b;
		for _, b in ipairs(self.blocks) do
			local x, y, z = b[1]+dx, b[2]+dy, b[3]+dz;
			if(b[4]) then
				local block_template = block_types.get(b[4]);
				if(block_template) then
					blocks[#blocks+1] = {x, y, z};
					self:AddBlock(block_template, x,y,z,b[5],b[6], false);
				end
			end
		end
	end
	
	if(add_to_history) then
		UndoManager.PushCommand(self);
	end

	if(self.blockX) then
		local tx, ty, tz = BlockEngine:real(self.blockX,self.blockY,self.blockZ);
		GameLogic.PlayAnimation({animationName = "Create",facingTarget = {x=tx, y=ty, z=tz},});
	end

	if(self.bSelect and blocks) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
		local task = MyCompany.Aries.Game.Tasks.SelectBlocks:new({blocks = blocks})
		task:Run();
	end
end

function CreateBlock:AddBlock(block_template, x,y,z,block_data, entity_data, bCheckCanCreate)
	if(self.add_to_history) then
		local from_id = BlockEngine:GetBlockId(x,y,z);
		local from_data, last_entity_data;
		if(from_id and from_id>0) then
			from_data = BlockEngine:GetBlockData(x,y,z);
			from_entity_data = BlockEngine:GetBlockEntityData(x,y,z);
		end
		self.history[#(self.history)+1] = {x,y,z, block_template.id, from_id, from_data, block_data, entity_data, from_entity_data};
	end
	block_template:Create(x,y,z, bCheckCanCreate~=false, block_data, nil, nil, entity_data);
end

function CreateBlock:Redo()
	if(self.blockX and self.block_id) then
		BlockEngine:SetBlock(self.blockX,self.blockY,self.blockZ, self.block_id, self.data, 3, self.entity_data);
	elseif((#self.history)>0) then
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0, b[7], nil, b[8]);
		end
	end
end

function CreateBlock:Undo()
	if(self.blockX and self.block_id) then
		BlockEngine:SetBlock(self.blockX,self.blockY,self.blockZ, self.last_block_id or 0, self.last_block_data,3, self.last_entity_data);
	elseif((#self.history)>0) then
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[5] or 0, b[6], nil, b[9]);
		end
	end
end
