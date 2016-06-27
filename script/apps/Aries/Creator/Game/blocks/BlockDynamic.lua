--[[
Title: BlockDynamic
Author(s): LiXizhi
Date: 2014/2/25
Desc: dynamic block can be pushed, and can falldown when there is no block beneath it. 
It can also be given a force on any of its direction. And it can be moved. 
right click to push forward on the touched side, when holding a climbable item in hand(like vine), 
it will pull intead of push. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockDynamic.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockDynamic")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local EntityBlockDynamic = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockDynamic")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockDynamic"));

-- register
block_types.RegisterBlockClass("BlockDynamic", block);

-- Do blocks move instantly to where they stop or do they fall over time
block.moveInstantly = nil;

-- initial speed for pushed block
local push_block_speed = 2.6;

function block:ctor()
	
end

function block:tickRate()
	return 2;
end

function block:OnBlockAdded(x, y, z)
	GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
end


function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
end

-- Checks to see if the block can move into the given block
-- it can only move into empty space, fire or liquid object. 
function block:CanMoveTo(x,y,z)
    local block_id = BlockEngine:GetBlockId(x,y,z);

    if (block_id == 0 or block_id == block_types.names.Fire) then
        return true;
    else
		local block_template = block_types.get(block_id);
		if(block_template and block_template:getMobilityFlag()==1) then
			return true;
		end
    end
end

-- Called when the block entity for this block stops (hits the ground) and 
-- turns back into a normal static block
function block:OnFinishMove(x,y,z)
end

-- Called when the dynamic block entity for this block is created
function block:OnBeginMove(x,y,z)
	
end

--  If there is space to fall below will start this block moving
function block:TryToMove(x,y,z)
	if (self:CanMoveTo(x, y-1, z)) then
        local var8 = 32;

        if (not self.moveInstantly) then
            local entity = EntityBlockDynamic:new():init(x,y,z, self.id, nil);
            self:OnBeginMove();
            entity:Attach();
        else
			BlockEngine:SetBlockToAir(x,y,z, 3);

            while (self:CanMoveTo(x, y- 1, z) and y>0) do
                y = y - 1;
            end

            if (y > 0) then
                BlockEngine:SetBlock(x,y,z, self.id, nil, 3);
            end
        end
    end
end


-- we will not be able to move the block if its above block is obstruction. 
function block:IsAboveBlockObstucted(x,y,z)
	local top_block = BlockEngine:GetBlock(x,y+1,z);
	if(top_block and top_block.obstruction) then
		return true;
	end
end

-- push on which side
-- @return true if successfully pushed. 
function block:PushOnSide(x,y,z, side)
	if(not self:IsAboveBlockObstucted(x,y,z)) then
		local op_side = BlockEngine:GetOppositeSide(side)
		local dx,dy,dz = BlockEngine:GetBlockIndexBySide(x,y,z, op_side)
		if(self:CanMoveTo(dx,dy,dz)) then
			-- we can only push when the top block is empty
			local vX, vY, vZ;
			if(side == 0) then
				vX = push_block_speed;
			elseif(side == 1) then
				vX = -push_block_speed;
			elseif(side == 2) then
				vZ = push_block_speed;
			elseif(side == 3) then
				vZ = -push_block_speed;
			end	
			if(vX or vY or vZ) then
				local entity = EntityBlockDynamic:new():init(x,y,z, self.id, nil);
				self:OnBeginMove();
				entity:Attach();
				entity:AddVelocity(vX or 0, vY or 0, vZ or 0);
				return true;
			end
		end
	end
end

-- called when the user clicks on the block
-- @param side: on which side the block is clicked. 
-- @return: return true if it is an action block and processed . 
function block:OnClick(x, y, z, mouse_button, entity, side)
	if(self.hasAction) then
		if(GameLogic.isRemote) then
			return block._super.OnClick(self, x, y, z, mouse_button, entity, side);
		else
			if(mouse_button == "right") then
				-- if user is holding an climbable item, we will be able to pull the block
				local usedItemStack;
				if(entity and entity.inventory and entity.inventory.GetItemInRightHand) then
					local item = entity.inventory:GetItemInRightHand();
					if(item) then
						local block_template = item:GetBlock();
					
						if(block_template and block_template.climbable) then
							side = BlockEngine:GetOppositeSide(side)
							usedItemStack = item;
						end
					end
				end
				if(self:PushOnSide(x,y,z, side)) then
					if(usedItemStack) then
						usedItemStack:GetItem():OnUseItem(usedItemStack, entity);
					end
					return true;
				end
			end
		end
	end
end

-- revert back to unpressed state
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		self:TryToMove(x,y,z);
	end
end