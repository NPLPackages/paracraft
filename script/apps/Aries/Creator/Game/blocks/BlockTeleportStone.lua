--[[
Title: TeleportStone
Author(s): LiXizhi
Date: 2013/12/15
Desc: Block TeleportStone
use the lib: if toggled, we will teleport player to it. 
when the player step on it and that the block is weakly powered or the block below it is a light block, it will be activated. 
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockTeleportStone.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTeleportStone")
-------------------------------------------------------
]]
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local NeuronBlock = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronBlock");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTeleportStone"));

-- register
block_types.RegisterBlockClass("BlockTeleportStone", block);

function block:ctor()
end

function block:Init()
end

function block:tickRate()
	return 20;
end

-- if a still water block's neighbor changes, we will turn this water to flow water. 
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	-- TODO: remove block when no neighbor is solid. 
end

-- if the block under the teleport stone is a light block or indirectly powered, we will return true
function block:IsFunctional(x, y, z)
	local block_template = BlockEngine:GetBlock(x, y-1, z)
	if(block_template and block_template.light) then
		return true;
	else
		return BlockEngine:isBlockIndirectlyGettingPowered(x, y, z);
	end
end

-- this function is the default handler when player steps on a teleport block. 
function block:OnStep(x,y,z, entity)
	if(not GameLogic.isRemote) then
		if(not entity:CanTeleport()) then
			return;
		end

		local neuron = NeuronManager.GetNeuron(x,y,z, true);
		if(not neuron:IsCoolDown()) then
			-- add 0.6 seconds to cool down. 
			neuron:AddCoolDown(0.6);
				
			if(self:IsFunctional(x,y,z)) then
				if(not neuron:IsEmpty()) then
					-- activate the teleport stone, if it has axons
					if(neuron.filename) then
						neuron:AddCoolDown(3);
						neuron:Activate(NeuronBlock.msg_templates["script"]);
					else
						self:OnActivated(x,y,z)
					end
				else
					neuron:AddCoolDown(1.5);
					-- if no axon is found on the teleport stone, we will try to run the follow blocks
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FollowBlocksTask.lua");
					local task = MyCompany.Aries.Game.Tasks.FollowBlocks:new({blockX = x,blockY = y, blockZ = z, block_id=self.id})
					task:Run();
				end
			end
		end
	end
end

-- teleport the player to this block. It will only teleport if 2 blocks above this block is empty. 
function block:OnToggle(x, y, z)
	if(not GameLogic.isRemote) then
		if(BlockEngine:IsBlockFreeSpace(x, y+1, z) and BlockEngine:IsBlockFreeSpace(x, y+2, z)) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
			local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX = x,blockY = y, blockZ = z})
			task:Run();
		end
	end
end