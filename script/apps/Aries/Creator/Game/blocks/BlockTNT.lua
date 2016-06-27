--[[
Title: TNT Block
Author(s): LiXizhi
Date: 2014/1/22
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockTNT.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTNT")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTNT"));

-- register
block_types.RegisterBlockClass("BlockTNT", block);

function block:ctor()
end

-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	local last_block_id = ParaTerrain.GetBlockTemplateByIdx(x, y-1, z);
	if(last_block_id == 0) then
		-- TNT do not grow on air
		return false;
	else
		local below_block = block_types.get(last_block_id);
		if(below_block and below_block.transparent) then
			-- TNT do not grow on other transparent object (possibly other TNT). 
			return false;
		end	
	end
	return true;
end

function block:OnBlockAdded(x,y,z)
    block._super.OnBlockAdded(self, x,y,z);
	if(not GameLogic.isRemote) then
		if(BlockEngine:isBlockIndirectlyGettingPowered(x, y, z)) then
			self:OnBlockDestroyedByPlayer(x,y,z,1);
			BlockEngine:SetBlockToAir(x, y, z);
		end
	end
end


-- Called right before the block is destroyed by a player.  Args: world, x, y, z, metaData
function block:OnBlockDestroyedByPlayer(x, y, z, data)
	if(not GameLogic.isRemote) then
		self:ExplodeNearbyBlocks(x, y, z, data, nil);
	end
end

-- if a still water block's neighbor changes, we will turn this water to flow water. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		if(BlockEngine:isBlockIndirectlyGettingPowered(x, y, z)) then
			self:OnBlockDestroyedByPlayer(x, y, z, 1);
			BlockEngine:SetBlockToAir(x, y, z);
		end
	end
end

-- if player is holding these blocks in hand, it will trigger explosion
function block:IsTriggerBlock(block_id)
	if(not self.trigger_blocks) then
		self.trigger_blocks	= {
			[block_types.names.Torch] = true,
		};
	end
	return self.trigger_blocks[block_id]
end

-- Called upon block activation (right click on the block.)
function block:OnActivated(x, y, z, entityPlayer)
	if(not GameLogic.isRemote) then
		if (entityPlayer and entityPlayer:GetItemInRightHand() and self:IsTriggerBlock(entityPlayer:GetItemInRightHand().id)) then
			BlockEngine:SetBlockToAir(x, y, z);
			self:ExplodeNearbyBlocks(x, y, z, 1, entityPlayer);
			-- TODO: decrease count
			entityPlayer:GetItemInRightHand():DamageItem(1, entityPlayer);
			return true;
		else
			return block._super.OnActivated(self, x, y, z, entityPlayer);
		end
	end
end

-- Triggered whenever an entity collides with this block (enters into the block)
function block:OnEntityCollided(x,y,z, entity)
	-- TODO: if colliding with a burning entity, explode
	if(not GameLogic.isRemote) then
		local isEntityBurning = false;
		if(isEntityBurning) then
			BlockEngine:SetBlockToAir(x, y, z);
			self:ExplodeNearbyBlocks(x, y, z, 1, entity);
		end
	end
end

-- explode blocks
function block:ExplodeNearbyBlocks(x,y,z, data, entity)
    if (data == 1) then
		local i, j, k;
		local radius = 2;
		local radiusSq = radius*radius;
		for i = -radius, radius do 
			for j = -radius, radius do 
				for k = -radius, radius do 
					if((i*i+j*j+k*k)<=radiusSq) then
						local bx, by, bz = x+i,y+k, z+j;
						local block = BlockEngine:GetBlock(bx, by, bz);
						if(block) then
							if(block.id == self.id) then
								-- explode after 20 ticks, it if triggered another TNT. 
								BlockEngine:SetBlockData(bx, by, bz, 1);
								GameLogic.GetSim():ScheduleBlockUpdate(bx, by, bz, self.id, 5);
							else
								BlockEngine:SetBlockToAir(bx, by, bz, 3);
								block:CreateBlockPieces(bx,by,bz, 0.2);
							end
						end
					end
				end
			end
		end
        -- TODO: play effect and sound. 
		self:play_break_sound();
    end
end

-- Ticks the block if it's been scheduled
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		if(BlockEngine:GetBlockData(x, y, z) == 1 and BlockEngine:GetBlockId(x, y, z) == self.id) then
			BlockEngine:SetBlockToAir(x, y, z, 3);
			self:ExplodeNearbyBlocks(x,y,z, 1);	
		end
	end
end