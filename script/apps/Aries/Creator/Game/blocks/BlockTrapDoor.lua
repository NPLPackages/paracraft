--[[
Title: TrapDoor
Author(s): LiXizhi
Date: 2013/12/3
Desc: Block TrapDoor
revision: if needPower, it will power the same door one block above it. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockTrapDoor.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTrapDoor")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTrapDoor"));

-- register
block_types.RegisterBlockClass("BlockTrapDoor", block);

-- whether the block will power the same door one block above it. 
block.ignore_open_door_power = false;

local side_to_data = {[0] = 1, [1] = 2, [2] = 3, [3] = 4, }
local data_to_side = {[1] = 0, [2] = 1, [3] = 2, [4] = 3,} 
local op_side_to_data = {[0] = 1, [1] = 2, [2] = 3, [3] = 4, }

function block:ctor()
	-- need power to open the door. 
	self.needPower = not self.hasAction;
	self.isOpen = not self.obstruction;
end

local associated_block_ids = {
	[232] = {[232] = true, [233]=true, [108] = true, [109]=true},
	[233] = {[231] = true, [233]=true, [108] = true, [109]=true},
	[108] = {[231] = true, [233]=true, [108] = true, [109]=true},
	[109] = {[231] = true, [233]=true, [108] = true, [109]=true},

	[194] = {[194] = true, [195]=true, [230] = true, [231]=true},
	[195] = {[194] = true, [195]=true, [230] = true, [231]=true},
	[230] = {[194] = true, [195]=true, [230] = true, [231]=true},
	[231] = {[194] = true, [195]=true, [230] = true, [231]=true},
}

-- return true if the block_id is associated block, such as an open door and closed door. 
function block:IsAssociatedBlockID(block_id)
	-- return self.id == block_id or (self.associated_blockid == block_id and block_id);
	return associated_block_ids[self.id][block_id];
end

function block:Init()
	
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	if(side and side <4) then
		return op_side_to_data[side];
	elseif(side == 5) then
		local dir = Direction.GetDirection2DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z);
		if(dir == 0 or dir==1) then
			if(BlockEngine:isBlockNormalCube(blockX, blockY, blockZ-1)) then
				return 4
			else
				return 3;
			end
		else
			if(BlockEngine:isBlockNormalCube(blockX-1, blockY, blockZ)) then
				return 2
			else
				return 1;
			end
		end
	else
		return 1;
	end
end

-- if neighbor block is indirectly powered, toggle to open state. 
function block:onPoweredBlockChange(x,y,z, neighbor_has_power)
    if ( neighbor_has_power == self.obstruction) then
        if(self.toggle_blockid) then
			-- play a different sound
			self:play_toggle_sound();
			self:ToggleTo(x, y, z, not self.isOpen);
		end
    end
end

-- Can this block provide power. 
function block:canProvidePower()
    return self.needPower;
end

function block:isProvidingWeakPower(x, y, z, direction)
	if(self.needPower and self.isOpen and not self.ignore_open_door_power) then
		if(direction == 5 and self:IsAssociatedBlockID(BlockEngine:GetBlockId(x,y+1,z))) then
			return 15;
		--elseif(direction == 4) then
			--self.ignore_open_door_power = true;
			--local neighbor_has_power = isBlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
			--self.ignore_open_door_power = false;
			--if(neighbor_has_power and self:IsAssociatedBlockID(BlockEngine:GetBlockId(x,y-1,z))) then
				--return 15;
			--end
		end
	end
	return 0;
end

-- if neighbor block is indirectly powered, toggle to open state. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		if(self.needPower) then
			local neighbor_has_power = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
			local neighbor_can_has_power;
			if(not neighbor_has_power and neighbor_block_id) then
				local block = block_types.get(neighbor_block_id);
				if(block and block:canProvidePower()) then
					neighbor_can_has_power = true;
				end
			end
			if(neighbor_has_power or neighbor_can_has_power) then
				self:onPoweredBlockChange(x,y,z, neighbor_has_power);
			end
		end
	end
end

function block:OnActivated(x, y, z)
	if(not GameLogic.isRemote) then
		if(not self.needPower) then
			-- do neuron activation
			return block._super.OnActivated(self, x, y, z);
		end
	end
end

function block:OnToggle(x, y, z)
	-- disable default toggle function. 
	if(not self.needPower) then
		if(self.toggle_blockid) then
			self:play_toggle_sound();

			self:ToggleTo(x, y, z, not self.isOpen);
		end
	end
end

-- private: this function will recursively toggle all nearby blocks
function block:ToggleTo(x, y, z, isOpen)
	local block_id = BlockEngine:GetBlockId(x, y, z)
	if(self:IsAssociatedBlockID(block_id)) then
		local this_block = block_types.get(block_id);
		if(this_block.isOpen and not isOpen or not this_block.isOpen and isOpen) then
			local data = BlockEngine:GetBlockData(x, y, z);
			BlockEngine:SetBlock(x, y, z, this_block.toggle_blockid, data, 3);

			if(not this_block.needPower) then
				-- recursively sync all blocks for wood door
				--this_block:ToggleTo(x-1, y, z, isOpen);
				--this_block:ToggleTo(x+1, y, z, isOpen);
				--this_block:ToggleTo(x, y-1, z, isOpen);
				--this_block:ToggleTo(x, y+1, z, isOpen);
				--this_block:ToggleTo(x, y, z-1, isOpen);
				--this_block:ToggleTo(x, y, z+1, isOpen);
			end
		end
	end
end

-- revert back to unpressed state
function block:updateTick(x,y,z)
    if(not GameLogic.isRemote) then
	end
end

-- rotate the block data by the given angle and axis. This is mosted reimplemented in blocks with orientations stored in block data, such as stairs, bones, etc. 
-- @param blockData: current block data
-- @param angle: usually 1.57, -1.57, 3.14, -3.14, 0. if 0 it means mirror along the given axis.
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the rotated block data. 
function block:RotateBlockData(blockData, angle, axis)
	axis = axis or "y"
	-- rotation around axis
	if(axis == "y") then
		local side = data_to_side[blockData or 0];
		if(side < 4) then
			local facing = Direction.directionTo3DFacing[side];
			blockData = side_to_data[Direction.GetDirectionFromFacing(facing + angle)];
		end
	else
		-- TODO: for other axis;
	end
	return blockData;
end


