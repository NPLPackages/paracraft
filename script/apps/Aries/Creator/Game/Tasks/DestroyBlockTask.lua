--[[
Title: Create Block task
Author(s): LiXizhi
Date: 2013/1/20
Desc: Destroy a block at the given position. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyBlockTask.lua");
local task = MyCompany.Aries.Game.Tasks.DestroyBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local DestroyBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.DestroyBlock"));

function DestroyBlock:ctor()
end

function DestroyBlock:Run()
	self.finished = true;

	if(not self.blockX) then
		return;
	end
	local add_to_history;
	
	local block_id = BlockEngine:GetBlockId(self.blockX,self.blockY,self.blockZ);
	if(block_id > 0) then
		local block_template = block_types.get(block_id);
		if(block_template) then
			self.last_block_id = block_id;
			self.last_block_data = BlockEngine:GetBlockData(self.blockX,self.blockY,self.blockZ);
			self.last_entity_data = BlockEngine:GetBlockEntityData(self.blockX,self.blockY,self.blockZ);
		
			-- needs to be called before Remove() so that we can get entity data
			local dropped_itemStack = block_template:GetDroppedItemStack(self.blockX,self.blockY,self.blockZ);

			local blocks_modified = block_template:Remove(self.blockX,self.blockY,self.blockZ);
			if(blocks_modified) then
				-- invoke callback. 
				local entityPlayer = EntityManager.GetPlayer();
				block_template:OnUserBreakItem(self.blockX,self.blockY,self.blockZ, entityPlayer);

				GameLogic.events:DispatchEvent({type = "DestroyBlockTask" , block_id = block_id, x = self.blockX, y = self.blockY, z = self.blockZ,
					last_block_id = self.last_block_id, last_block_data = self.last_block_data,
				});

				if(dropped_itemStack) then
					-- automatically pick the block when deleted. 
					if(entityPlayer) then
						entityPlayer:PickItem(dropped_itemStack, self.blockX,self.blockY,self.blockZ);
					end
				end

				-- only allow history operation if no auto generated blocks are created when the block is destroyed. 
				if(GameLogic.GameMode:CanAddToHistory()) then
					add_to_history = true;
				end
			end
		end
	else
		-- if there is no block, we may have hit the terrain. 
		-- TODO: block.RemoveTerrainBlock(self.blockX,self.blockY,self.blockZ); ?
	end
	
	if(add_to_history) then
		UndoManager.PushCommand(self);
	end
end

function DestroyBlock:Redo()
	if(self.blockX and self.last_block_id) then
		BlockEngine:SetBlockToAir(self.blockX,self.blockY,self.blockZ, 0);
	end
end

function DestroyBlock:Undo()
	if(self.blockX and self.last_block_id) then
		BlockEngine:SetBlock(self.blockX,self.blockY,self.blockZ, self.last_block_id, self.last_block_data, nil, self.last_entity_data);
	end
end