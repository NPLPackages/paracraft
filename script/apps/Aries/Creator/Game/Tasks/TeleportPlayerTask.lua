--[[
Title: Teleport the player
Author(s): LiXizhi
Date: 2013/1/20
Desc: Teleport the player to a given position. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({mode="vertical", isUpward = true})
task:Run();

local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX = 1,blockY = 0, blockZ = 1})
task:Run();

local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({x = 1,y = 0, z= 1})
task:Run({add_to_history = false});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local TeleportPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.TeleportPlayer"));

function TeleportPlayer:ctor()
end

function TeleportPlayer:Run()
	self.finished = true;

	local entityPlayer = EntityManager.GetFocus();
	if(not entityPlayer) then
		return;
	end
	local oldPosX, oldPosY, oldPosZ = entityPlayer:GetPosition();
	self.oldPosX, self.oldPosY, self.oldPosZ = oldPosX, oldPosY, oldPosZ;
	
	local add_to_history;
	local mode = self.mode;
	if(mode == "vertical") then
		local blocksize = BlockEngine.blocksize;
		local fElev = ParaTerrain.GetElevation(oldPosX,oldPosZ);
		
		local bx, by, bz = BlockEngine:block(oldPosX, oldPosY+0.1, oldPosZ);

		if(self.isUpward) then
			-- upward
			local i;
			
			local top_block;
			local height = BlockEngine.region_height * 2;
			for i=by+1, height-2 do
				if(ParaTerrain.GetBlockTemplateByIdx(bx, i, bz)~=0) then
					top_block = i;
					break;
				end
			end
			local dest_block_min, dest_block_max;
			if(top_block) then
				for i=top_block, height-2 do
					if(ParaTerrain.GetBlockTemplateByIdx(bx, i, bz)==0 and ParaTerrain.GetBlockTemplateByIdx(bx, i+1, bz)==0) then
						dest_block_min = i;
						local j;
						for j=dest_block_min+2, height do
							if(ParaTerrain.GetBlockTemplateByIdx(bx, j, bz)~=0) then
								dest_block_max = j;
								break;
							end
						end
						dest_block_max = dest_block_max or height;
						break;
					end
				end
			end
			local newPosY;
			if(dest_block_min and dest_block_max) then
				local dest_block_min_y, dest_block_max_y, _;
				_, dest_block_min_y, _ = BlockEngine:real(bx, dest_block_min, bz);
				_, dest_block_max_y, _ = BlockEngine:real(bx, dest_block_max, bz);
				if(dest_block_min_y<=fElev and fElev<=(dest_block_max_y+(blocksize*2))) then
					-- really tricky here: TODO: not tested
					_, top_block, _ = BlockEngine:block(oldPosX, fElev+blocksize, oldPosZ);

					for i=top_block, height-2 do
						if(ParaTerrain.GetBlockTemplateByIdx(bx, i, bz)==0 and ParaTerrain.GetBlockTemplateByIdx(bx, i+1, bz)==0) then
							dest_block_min = i;
							_, dest_block_min_y, _ = BlockEngine:real(bx, dest_block_min, bz);
							newPosY = dest_block_min_y - blocksize*0.5;
							break;
						end
					end
					if(not newPosY) then
						newPosY = fElev;
					end
				else
					newPosY = dest_block_min_y - blocksize*0.5;
				end
			end
			if(newPosY) then
				self.newPosX, self.newPosY, self.newPosZ = oldPosX, newPosY, oldPosZ;
				self.oldPosX, self.oldPosY, self.oldPosZ = oldPosX, oldPosY, oldPosZ;
				entityPlayer:SetPosition(self.newPosX, self.newPosY, self.newPosZ);
				add_to_history = true;
			end
		else
			-- downward
			local i;
			
			local top_block;
			
			for i=by-1, 1,-1 do
				if(ParaTerrain.GetBlockTemplateByIdx(bx, i, bz)~=0) then
					top_block = i;
					break;
				end
			end
			local dest_block_min, dest_block_max;

			if(top_block) then
				for i=top_block-1, 1,-1 do
					if(ParaTerrain.GetBlockTemplateByIdx(bx, i, bz)==0 and ParaTerrain.GetBlockTemplateByIdx(bx, i-1, bz)==0) then
						dest_block_max = i;
						local j;
						for j=dest_block_max-2, 1, -1 do
							if(ParaTerrain.GetBlockTemplateByIdx(bx, j, bz)~=0) then
								dest_block_min = j;
								break;
							end
						end
						break;
					end
				end
			end
			
			local newPosY;
			if(dest_block_min and dest_block_max) then
				local dest_block_min_y, dest_block_max_y, _;
				_, dest_block_min_y, _ = BlockEngine:real(bx, dest_block_min, bz);
				_, dest_block_max_y, _ = BlockEngine:real(bx, dest_block_max, bz);
				if(dest_block_min_y<=fElev and fElev<=(dest_block_max_y+(blocksize*2))) then
					-- really tricky here: escape crack between terrain the block surface. 
					top_block = dest_block_min;
					for i=top_block-1, 1,-1 do
						if(ParaTerrain.GetBlockTemplateByIdx(bx, i, bz)==0 and ParaTerrain.GetBlockTemplateByIdx(bx, i-1, bz)==0) then
							dest_block_max = i;
							local j;
							for j=dest_block_max-2, 1, -1 do
								if(ParaTerrain.GetBlockTemplateByIdx(bx, j, bz)~=0) then
									dest_block_min = j;
									_, dest_block_min_y, _ = BlockEngine:real(bx, dest_block_min, bz);
									newPosY = dest_block_min_y + blocksize*0.5;
								end
							end
							break;
						end
					end
				else
					newPosY = dest_block_min_y + blocksize*0.5;
				end
			elseif(oldPosY > fElev) then
				newPosY = fElev;
			end
			if(newPosY) then
				self.newPosX, self.newPosY, self.newPosZ = oldPosX, newPosY, oldPosZ;
				self.oldPosX, self.oldPosY, self.oldPosZ = oldPosX, oldPosY, oldPosZ;
				entityPlayer:SetPosition(self.newPosX, self.newPosY, self.newPosZ);
				add_to_history = true;
			end
		end
	elseif(self.blockX) then
		-- teleport to given block's top surface. 
		-- for other nodes. 
		local bx, by, bz = self.blockX,self.blockY,self.blockZ;
		local newPosX, newPosY, newPosZ = BlockEngine:real(bx, by, bz);
		newPosY = newPosY + BlockEngine.half_blocksize + 0.1;
		self.newPosX, self.newPosY, self.newPosZ = newPosX, newPosY, newPosZ;
		entityPlayer:SetPosition(self.newPosX, self.newPosY, self.newPosZ);
		add_to_history = true;
	elseif(self.x) then
		-- teleport to a real world position. 
		local newPosX, newPosY, newPosZ = self.x, self.y, self.z;
		self.newPosX, self.newPosY, self.newPosZ = newPosX, newPosY, newPosZ;
		entityPlayer:SetPosition(self.newPosX, self.newPosY, self.newPosZ);
		add_to_history = true;
	end

	if(add_to_history and self.add_to_history == nil) then
		UndoManager.PushCommand(self);
	end
end

function TeleportPlayer:Redo()
	if(self.newPosX) then
		EntityManager.GetFocus():SetPosition(self.newPosX, self.newPosY, self.newPosZ);
	end
end

function TeleportPlayer:Undo()
	if(self.oldPosX) then
		EntityManager.GetFocus():SetPosition(self.oldPosX, self.oldPosY, self.oldPosZ);
	end
end


