--[[
Title: Follow blocks task
Author(s): LiXizhi
Date: 2013/6/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FollowBlocksTask.lua");
local task = MyCompany.Aries.Game.Tasks.FollowBlocks:new({blockX = 1,blockY = 0, blockZ = 1, block_id})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local FollowBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.FollowBlocks"));

-- how many ticks to move the player one block. 
local move_tick_count = 2;

function FollowBlocks:ctor()
end

function FollowBlocks:Run()
	if(not self.block_id or not self.blockX) then
		self.finished = true;
		return;
	end

	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end

	local oldPosX, oldPosY, oldPosZ = ParaScene.GetPlayer():GetPosition();
	self.oldPosX, self.oldPosY, self.oldPosZ = oldPosX, oldPosY, oldPosZ;
	
	self.ticks = 0;

	-- UndoManager.PushCommand(self);
end

function FollowBlocks:TryMoveTo(bx,by,bz)
	local block_id = ParaTerrain.GetBlockTemplateByIdx(bx, by, bz);
	if(block_id == self.block_id) then
		if(not self.last_blockX or self.last_blockX~=bx or self.last_blockY~=by or self.last_blockZ~=bz) then
			local up_block_id = ParaTerrain.GetBlockTemplateByIdx(bx, by+1, bz);
			
			if(up_block_id==0 or not block_types.get(up_block_id).obstruction) then
				local neuron = NeuronManager.GetNeuron(bx, by, bz, true);
				if(not neuron:IsCoolDown()) then
					-- add 0.6 seconds to cool down. 
					neuron:AddCoolDown(1.6);

					self.last_blockX = self.blockX;
					self.last_blockY = self.blockY;
					self.last_blockZ = self.blockZ;
					self.blockX = bx;
					self.blockY = by;
					self.blockZ = bz;

					local player = ParaScene.GetPlayer();
					if(player:IsStanding()) then
						local newPosX, newPosY, newPosZ = BlockEngine:real(bx, by, bz);
						newPosY = newPosY + BlockEngine.half_blocksize + 0.1;
						self.newPosX, self.newPosY, self.newPosZ = newPosX, newPosY, newPosZ;
						ParaScene.GetPlayer():SetPosition(self.newPosX, self.newPosY, self.newPosZ);

						return true;
					end
				end
			end
		end
	end
end

function FollowBlocks:FrameMove()
	-- if player is off the ground, cancel it. 
	self.ticks = self.ticks + 1;
	if(self.ticks >= move_tick_count) then
		self.ticks = 0;
	end
	if(self.ticks ~= 0) then
		return;
	end

	local bx, by, bz = self.blockX, self.blockY, self.blockZ;
	local bHasMoved = 
		self:TryMoveTo(bx-1,by,bz) or self:TryMoveTo(bx+1,by,bz) or 
		self:TryMoveTo(bx,by,bz+1) or self:TryMoveTo(bx,by,bz-1) or 
		self:TryMoveTo(bx-1,by+1,bz) or self:TryMoveTo(bx+1,by+1,bz) or 
		self:TryMoveTo(bx,by+1,bz+1) or self:TryMoveTo(bx,by+1,bz-1) or 
		self:TryMoveTo(bx-1,by-1,bz) or self:TryMoveTo(bx+1,by-1,bz) or 
		self:TryMoveTo(bx,by-1,bz+1) or self:TryMoveTo(bx,by-1,bz-1);
	if(not bHasMoved) then
		self.finished = true;
	end
end
