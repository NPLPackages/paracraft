--[[
Title: Flowing Water Block
Author(s): LiXizhi
Date: 2013/12/1
Desc: 
To keep track of which blocks are actively flowing, Water and Lava each have a pair of block IDs. 
For water, there is Water (75) and Still Water (76). Still Water will stay in place until it receives a block update. 
Water updates periodically and will change itself to Still Water when it cannot spread any further.
Updating a block next to Still Water will turn it back to Water so it can spread some more.
If you edit either type of liquid block, they will spread when placed, since placing a block causes updates.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLiquidFlow.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLiquidFlow")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockLiquidFlow"));

-- register
block_types.RegisterBlockClass("BlockLiquidFlow", block);


-- Number of horizontally adjacent liquid source blocks. Diagonal doesn't count. Only source blocks of the same
-- liquid as the block using the field are counted.
local numAdjacentSources = 0;

--  Indicates whether the flow direction is optimal. Each array index corresponds to one of the four cardinal directions.
local isOptimalFlowDirection = {false, false, false, false};

-- The estimated cost to flow in a given direction from the current point. Each array index corresponds to one of
-- the four cardinal directions.
local flowCost = {0,0,0,0};

function block:ctor()
	self.isAutoUserData = true;
end

function block:Init()
end

function block:tickRate()
	return 5;
end

function block:OnToggle(bx, by, bz)
end

function block:OnBlockAdded(x, y, z)
	--block._super.OnBlockAdded(self, x, y, z);
	if(not GameLogic.isRemote) then
		if (ParaTerrain.GetBlockTemplateByIdx(x,y,z) == self.id) then
			GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
		end
	end
end

-- Returns the amount of fluid decay at the coordinates, or -1 if the block at the coordinates is not the same material as the fluid.
-- Source blocks have a decay of 0, and the maximum decay depends on liquid type. water is 7, lava is 3. 
-- The "decay" value increases as the water is further from the source. A high value means that the water is actually physically downhill.
function block:getFlowDecay(x, y, z)
	if(BlockEngine:GetBlockMaterial(x, y, z) == self.material) then
		return ParaTerrain.GetBlockUserDataByIdx(x,y,z);
	else
		return -1;
	end
end

-- getSmallestFlowDecay(World world, intx, int y, int z, int currentSmallestFlowDecay) - Looks up the flow decay at
-- the coordinates given and returns the smaller of this value or the provided currentSmallestFlowDecay. If one
-- value is valid and the other isn't, the valid value will be returned. Valid values are >= 0. Flow decay is the
-- amount that a liquid has dissipated. 0 indicates a source block.
function block:getSmallestFlowDecay(x, y, z, last_value)
    local my_value = self:getFlowDecay(x, y, z);

    if (my_value < 0) then
        return last_value;
    else
        if (my_value == 0) then
            numAdjacentSources = numAdjacentSources + 1;
        end

        if (my_value >= 8) then
            my_value = 0;
        end

        if(last_value >= 0 and my_value >= last_value) then
			return last_value;
		else
			return my_value;
		end
    end
end

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	
end

-- Updates the flow for the BlockFlowing object.
-- making the block still again. 
function block:updateFlowToStill(x, y, z)
	-- update block flow
	local data = ParaTerrain.GetBlockUserDataByIdx(x,y,z);
	BlockEngine:SetBlock(x, y, z, self.id + 1, data);
end

-- Returns true if the block at the coordinates can be displaced by the liquid.
function block:liquidCanDisplaceBlock(x, y, z)
	local material = BlockEngine:GetBlockMaterial(x, y, z);
	if( material == self.material) then
		return false;
	else
		if(material == Materials.lava) then
			return false;
		else
			return not self:blockBlocksFlow(x,y,z);
		end
	end
end

local block_flow_ids;

local function block_flow(block_id)
	if(not block_flow_ids) then
		block_flow_ids = {
			[block_types.names.Ladder] = true,
			--[block_types.names.doorIron] = true,
			--[block_types.names.signPost] = true,
			--[block_types.names.reed] = true,
		};
	end
	return block_flow_ids[block_id];
end

-- Returns true if block at coords blocks fluids
function block:blockBlocksFlow(x, y, z)
    local block_id = ParaTerrain.GetBlockTemplateByIdx(x, y, z);

    if (not block_flow(block_id)) then
        if (block_id == 0) then
            return false;
        else
			local block = block_types.get(block_id);
			if(block and block.material:blocksMovement())  then
				return true;
			else
				return false;
			end
        end
    else
        return true;
    end
end

-- determine the path of least resistance, this method returns the lowest possible flow cost for the direction of
-- flow indicated. Each necessary horizontal flow adds to the flow cost.
function block:calculateFlowCost(x,y,z, accumulatedCost, previousDirectionOfFlow)
    local final_cost = 1000;

    for dir = 0, 3 do
        if ((dir ~= 0 or previousDirectionOfFlow ~= 1) and (dir ~= 1 or previousDirectionOfFlow ~= 0) and (dir ~= 2 or previousDirectionOfFlow ~= 3) and (dir ~= 3 or previousDirectionOfFlow ~= 2)) then
            local x_ = x;
            local z_ = z;

            if (dir == 0) then
                x_ = x - 1;
            end

            if (dir == 1) then
                x_ = x_ + 1;
            end

            if (dir == 2) then
                z_ = z - 1;
            end

            if (dir == 3) then
                z_ = z_ + 1;
            end

            if (not self:blockBlocksFlow(x_, y, z_) and (BlockEngine:GetBlockMaterial(x_, y, z_) ~= self.material or ParaTerrain.GetBlockUserDataByIdx(x_, y, z_) ~= 0)) then
                if (not self:blockBlocksFlow(x_, y - 1, z_)) then
                    return accumulatedCost;
                end

                if (accumulatedCost < 4) then
                    local tmp_cost = self:calculateFlowCost(x_, y, z_, accumulatedCost + 1, dir);

                    if (tmp_cost < final_cost) then
                        final_cost = tmp_cost;
                    end
                end
            end
        end
    end

    return final_cost;
end

-- Returns a boolean array indicating which flow directions are optimal based on each direction's calculated flow
-- cost. Each array index corresponds to one of the four cardinal directions. A value of true indicates the
-- direction is optimal.
function block:getOptimalFlowDirections(x,y,z)
    for dir = 0, 3 do
        flowCost[dir] = 1000;
        local x_ = x;
        local z_ = z;

        if (dir == 0) then
            x_ = x - 1;
        end

        if (dir == 1) then
            x_ = x_ + 1;
        end

        if (dir == 2) then
            z_ = z - 1;
        end

        if (dir == 3) then
            z_ = z_ + 1;
        end

        if (not self:blockBlocksFlow(x_, y, z_) and (BlockEngine:GetBlockMaterial(x_, y, z_) ~= self.material or ParaTerrain.GetBlockUserDataByIdx(x_, y, z_) ~= 0)) then
            if (self:blockBlocksFlow(x_, y - 1, z_)) then
                flowCost[dir] = self:calculateFlowCost(x_, y, z_, 1, dir);
            else
                flowCost[dir] = 0;
            end
        end
    end

    local dir = flowCost[0];

    for i = 1, 3 do
        if (flowCost[i] < dir) then
            dir = flowCost[i];
        end
    end

    for i = 0, 3 do
        isOptimalFlowDirection[i] = flowCost[i] == dir;
    end
    return isOptimalFlowDirection;
end

-- flowIntoBlock(World world, int x, int y, int z, int newFlowDecay) - Flows into the block at the coordinates and
-- changes the block type to the liquid.
function block:flowIntoBlock(x,y,z, newFlowDecay)
    if (self:liquidCanDisplaceBlock(x,y,z) and y>=0) then
        local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);

        if (block_id > 0) then
            if (self.material == Materials.lava) then
                -- self:triggerLavaMixEffects(x,y,z);
            else
                -- Block.blocksList[block_id].DropBlockAsItem(x,y,z);
            end
        end
        BlockEngine:SetBlock(x,y,z, self.id, newFlowDecay, 3);
    end
end

-- framemove 
function block:updateTick(x,y,z)
	if(GameLogic.isRemote) then
		return
	end
	local cur_decay = self:getFlowDecay(x,y,z);
	local decay_step = 1;
	local final_decay;

	if (cur_decay > 0) then
        local smallest_decay = -100;
        numAdjacentSources = 0;
        smallest_decay = self:getSmallestFlowDecay(x - 1, y, z, smallest_decay);
        smallest_decay = self:getSmallestFlowDecay(x + 1, y, z, smallest_decay);
        smallest_decay = self:getSmallestFlowDecay(x, y, z - 1, smallest_decay);
        smallest_decay = self:getSmallestFlowDecay(x, y, z + 1, smallest_decay);

        final_decay = smallest_decay + decay_step;

        if (final_decay >= 8 or smallest_decay < 0) then
            final_decay = -1;
        end

        if (self:getFlowDecay(x, y + 1, z) >= 0) then
            local decay_top = self:getFlowDecay(x, y + 1, z);

            if (decay_top >= 8) then
                final_decay = decay_top;
            else
                final_decay = decay_top + 8;
			end
		end
        
        if (numAdjacentSources >= 2 and self.material == Materials.water) then
            if (BlockEngine:GetBlockMaterial(x, y - 1, z):isSolid()) then
                final_decay = 0;
            elseif (BlockEngine:GetBlockMaterial(x, y - 1, z) == self.material and ParaTerrain.GetBlockUserDataByIdx(x, y - 1, z) == 0) then
                final_decay = 0;
            end
        end

        if (final_decay == cur_decay) then
            self:updateFlowToStill(x, y, z);
        else
            cur_decay = final_decay;

            if (final_decay < 0) then
                BlockEngine:SetBlockToAir(x, y, z, 3);
            else
				BlockEngine:SetBlockData(x, y, z, final_decay);
                GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
				BlockEngine:NotifyNeighborBlocksChange(x, y, z, self.id);
            end
        end
    else
        self:updateFlowToStill(x,y,z);
	end

	if (self:liquidCanDisplaceBlock(x, y - 1, z)) then
        if (cur_decay >= 8) then
            self:flowIntoBlock(x, y - 1, z, cur_decay);
        else
            self:flowIntoBlock(x, y - 1, z, cur_decay + 8);
        end
    elseif (cur_decay >= 0 and (cur_decay == 0 or self:blockBlocksFlow(x, y - 1, z))) then
        local optimal_directions = self:getOptimalFlowDirections( x, y, z);
        final_decay = cur_decay + decay_step;

        if (cur_decay >= 8) then
            final_decay = 1;
        end

        if (final_decay >= 8) then
            return;
        end

        if (optimal_directions[0]) then
            self:flowIntoBlock(x - 1, y, z, final_decay);
        end

        if (optimal_directions[1]) then
            self:flowIntoBlock(x + 1, y, z, final_decay);
        end

        if (optimal_directions[2]) then
            self:flowIntoBlock(x, y, z - 1, final_decay);
        end

        if (optimal_directions[3]) then
            self:flowIntoBlock(x, y, z + 1, final_decay);
        end
	end
end