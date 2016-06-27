--[[
Title: Piston
Author(s): LiXizhi
Date: 2013/12/3
Desc: Block Piston
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPiston.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPiston")
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

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockPiston"));

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

-- register
block_types.RegisterBlockClass("BlockPiston", block);

local op_side_to_data = {
	[0] = 1,[1] = 0,[2] = 3,[3] = 2,[4] = 5,[5] = 4,
}

-- user data to direction side
local data_to_side = {
	[0] = 0, [1] = 1,[2] = 2,[3] = 3,[4] = 4,[5] = 5,
}

-- [0-5), 7 means middle state
local function getOrientation(data)
    return band(data, 7);
end

-- Determine if the metadata is related to something powered.
local function isExtended(data)
    return band(data, 8) ~= 0;
end
block.isExtended = isExtended;

-- returns true if the piston can push the specified block
local function canPushBlock(block_id, x,y,z, canMoveFreeBlock)
    if (block_id == block_types.names.Obsidian) then
        return false;
    else
        if (block_id ~= block_types.names.Piston and block_id ~= block_types.names.StickyPiston) then
			local block = block_types.get(block_id);
			if(block) then
				if (block:getBlockHardness(x,y,z) == -1) then
					return false;
				elseif (block:getMobilityFlag() == 2) then
					return false;
				elseif (block:getMobilityFlag() == 1) then
					if (not canMoveFreeBlock) then
						return false;
					end
					return true;
				else
					-- do not push hard object with action 
					return not block.hasAction;
				end
			end
        elseif (isExtended(BlockEngine:GetBlockData(x,y,z))) then
            return false;
        end

        return true;
    end
end

-- checks to see if this piston could push the blocks in front of it.
local function canExtend(x,y,z, dir)
	local x1 = x + Direction.offsetX[dir];
	local y1 = y + Direction.offsetY[dir];
	local z1 = z + Direction.offsetZ[dir];
	local dist = 0;

	
	while (dist < 13) do
		if (y1 <= 0 or y1 >= 255) then
			return false;
		end

		local block_id = BlockEngine:GetBlockId(x1, y1, z1);
			
		if (block_id ~= 0) then
			if (not canPushBlock(block_id, x1, y1, z1, true)) then
				return false;
			elseif (block_types.get(block_id):getMobilityFlag() ~= 1) then
				if (dist == 12) then
					return false;
				end

				x1 = x1 + Direction.offsetX[dir];
				y1 = y1 + Direction.offsetY[dir];
				z1 = z1 + Direction.offsetZ[dir];
				dist = dist + 1;
			else
				return true;
			end
		else
			return true;
		end
	end
	return true;
end

function block:ctor()
	self.isSticky = self.isSticky == "true" or self.isSticky;
	self.isAutoUserData = true;
end

function block:Init()
end

function block:tickRate()
	return 20;
end

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	return Direction.directionToOpFacing[Direction.GetDirection3DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z)];
end

-- if a still water block's neighbor changes, we will turn this water to flow water. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		self:updatePistonState(x,y,z);
	end
end

function block:OnBlockAdded(x, y, z)
	if(not GameLogic.isRemote) then
		self:updatePistonState(x,y,z);
	end
end

function block:OnBlockRemoved(x, y, z, last_id, last_data)

end

-- checks the block to that side to see if it is indirectly powered.
function block:isIndirectlyPowered(x,y,z, side)
	return (side~=0 and BlockEngine:hasWeakPowerOutputTo(x-1,y,z,1)) or 
		(side~=1 and BlockEngine:hasWeakPowerOutputTo(x+1,y,z,0)) or 
		(side~=2 and BlockEngine:hasWeakPowerOutputTo(x,y,z-1,3)) or 
		(side~=3 and BlockEngine:hasWeakPowerOutputTo(x,y,z+1,2)) or 
		(side~=4 and BlockEngine:hasWeakPowerOutputTo(x,y-1,z,5)) or 
		(side~=5 and BlockEngine:hasWeakPowerOutputTo(x,y+1,z,4));
end

-- handles attempts to extend or retract the piston.
function block:updatePistonState(x,y,z)
    local data = BlockEngine:GetBlockData(x, y, z);
    local dir = getOrientation(data);

    if ( dir ~= 7) then
        local isPowered = self:isIndirectlyPowered(x, y, z, dir);

        if (isPowered and not isExtended(data)) then
            if (canExtend(x, y, z, dir)) then
                GameLogic.GetSim():AddBlockEvent(x, y, z, self.id, 0, dir);
            end
        elseif (not isPowered and isExtended(data)) then
            BlockEngine:SetBlockData(x, y, z, dir);
            GameLogic.GetSim():AddBlockEvent(x, y, z, self.id, 1, dir);
        end
    end
end

-- attempts to extend the piston. returns false if impossible.
function block:tryExtend(x,y,z,dir)
    local x1 = x + Direction.offsetX[dir];
    local y1 = y + Direction.offsetY[dir];
    local z1 = z + Direction.offsetZ[dir];
    local dist = 0;

	local canExtend;
	while (dist < 13) do
        local block_id;

        if (y1 <= 0 or y1 >= 255) then
            return false;
        end

        block_id = BlockEngine:GetBlockId(x1, y1, z1);

        if (block_id ~= 0) then
            if (not canPushBlock(block_id, x1, y1, z1, true)) then
                return false;
            elseif (block_types.get(block_id):getMobilityFlag() ~= 1) then
                if (dist == 12) then
                    return false;
                end

                x1 = x1+Direction.offsetX[dir];
                y1 = y1+Direction.offsetY[dir];
                z1 = z1+Direction.offsetZ[dir];
                dist = dist + 1;
            else
				block_types.get(block_id):DropBlockAsItem(x1, y1, z1);
				BlockEngine:SetBlockToAir(x1, y1, z1);
				break;
            end
		else
			break;
		end
	end

	local last_x, last_y, last_z = x1,y1,z1;
	local targets = {};
	while( x1 ~= x or y1 ~= y or z1 ~= z) do
		local x2 = x1 - Direction.offsetX[dir];
		local y2 = y1 - Direction.offsetY[dir];
		local z2 = z1 - Direction.offsetZ[dir];
		local target_block_id = BlockEngine:GetBlockId(x2, y2, z2);
		local target_block_data = BlockEngine:GetBlockData(x2, y2, z2);

		if (target_block_id == self.id and x2 == x and y2 == y and z2 == z) then
			BlockEngine:SetBlock(x1, y1, z1, block_types.names.PistonHead, bor(dir, 8));
		else
			BlockEngine:SetBlock(x1, y1, z1, target_block_id, target_block_data);
		end

		targets[#targets + 1] = {target_block_id, target_block_data};
		x1 = x2;
		y1 = y2;
		z1 = z2;
	end

	x1,y1,z1 = last_x, last_y, last_z
	
	local i=1;
	if(#targets>0) then
		-- fixing error: call onchange for the last block
		BlockEngine:NotifyNeighborBlocksChange(x1, y1, z1, targets[i][1]);
		while( x1 ~= x or y1 ~= y or z1 ~= z) do
			local x2 = x1 - Direction.offsetX[dir];
			local y2 = y1 - Direction.offsetY[dir];
			local z2 = z1 - Direction.offsetZ[dir];
			BlockEngine:NotifyNeighborBlocksChange(x2, y2, z2, targets[i][1]);
			i = i + 1;
			x1 = x2;
			y1 = y2;
			z1 = z2;
		end
	end
	return true;
end

-- @param event_id: 0 to extend, 1 to retract. 
function block:OnBlockEvent(x, y, z, event_id, dir)
	if(not GameLogic.isRemote) then
		local isPowered = self:isIndirectlyPowered(x, y, z, dir);

		if (isPowered and event_id == 1) then
			BlockEngine:SetBlockData(x, y, z, bor(dir,8), 2);
			return false;
		elseif (not isPowered and event_id == 0) then
			return false;
		end

		if (event_id == 0) then
			if (not self:tryExtend(x, y, z, dir)) then
				return false;
			end

			BlockEngine:SetBlockData(x, y, z, bor(dir, 8));
			self:play_toggle_sound(x,y,z);

		elseif (event_id == 1) then
			BlockEngine:SetBlockData(x, y, z, dir);

			if (self.isSticky) then
				local x1 = x + Direction.offsetX[dir] * 2;
				local y1 = y + Direction.offsetY[dir] * 2;
				local z1 = z + Direction.offsetZ[dir] * 2;
				local target_block_id = BlockEngine:GetBlockId(x1, y1, z1);
				local target_block_data = BlockEngine:GetBlockData(x1, y1, z1);
			
				if (target_block_id > 0 and canPushBlock(target_block_id, x1, y1, z1, false) and 
					(block_types.get(target_block_id):getMobilityFlag() == 0 or target_block_id == block_types.names.Piston or target_block_id == block_types.names.StickyPiston)) then
					x = x + Direction.offsetX[dir];
					y = y + Direction.offsetY[dir];
					z = z + Direction.offsetZ[dir];
					BlockEngine:SetBlockToAir(x1, y1, z1, 3);
					BlockEngine:SetBlock(x, y, z, target_block_id, target_block_data, 3);
				else 
					BlockEngine:SetBlockToAir(x + Direction.offsetX[dir], y + Direction.offsetY[dir], z + Direction.offsetZ[dir], 3);
				end
			else
				BlockEngine:SetBlockToAir(x + Direction.offsetX[dir], y + Direction.offsetY[dir], z + Direction.offsetZ[dir], 3);
			end
			self:play_toggle_sound(x,y,z);
		end
		return true;
	end
end

-- goto pressed state and then schedule tickUpdate to go off again after some ticks
function block:OnActivated(x, y, z)
end

function block:OnToggle(x, y, z)
end

-- revert back to unpressed state
function block:updateTick(x,y,z)

end



