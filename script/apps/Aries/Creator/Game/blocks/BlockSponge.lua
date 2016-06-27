--[[
Title: BlockSponge
Author(s): LiXizhi
Date: 2013/12/19
Desc: all water above or below it in area of 5*5*(+/-10) is erased. 
find a better way to erase water, sponge breaks water simulation, since it uses raw API to remove water. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSponge.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockSponge")
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockSponge"));

-- register
block_types.RegisterBlockClass("BlockSponge", block);

function block:ctor()

end

function block:Init()
end

function block:tickRate()
	return 20;
end

function block:OnBlockAdded(x, y, z)
	if(not GameLogic.isRemote) then
		GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
	end
end


-- if a still water block's neighbor changes, we will turn this water to flow water. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		local block = block_types.get(neighbor_block_id);
		if( block and block.material:isLiquid()) then
			GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id, self:tickRate());
		end
	end
end

-- framemove 
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		local tx, ty, tz;
		for i=-2, 2 do
			for j=-2, 2 do
				for k = 0, 10 do
					tx, ty, tz = x + i,  y + k, z + j;
					local block = BlockEngine:GetBlock(tx, ty, tz);
					if(block and block.material:isLiquid()) then
						-- Using flag==0, since it will not causes the water to flow back. 
						BlockEngine:SetBlock(tx, ty, tz, 0, nil, 0);
					end
				end
			end
		end
	end
end