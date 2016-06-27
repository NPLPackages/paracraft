--[[
Title: Destroy nearby blocks
Author(s): LiXizhi
Date: 2013/1/24
Desc: Destroy all blocks in 3*3*3 area around a given point. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
-- just around the player
local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({direction="front", detect_key="DIK_W"})
-- just below the player
local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({direction="down", detect_key="DIK_X"})
-- at given position. 
local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({blockX=self.blockX, blockY=self.blockY, blockZ=self.blockZ, explode_time=200, })
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
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local DestroyNearbyBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks"));

-- ms seconds to cancel destroy. 
DestroyNearbyBlocks.explode_time = 500;

function DestroyNearbyBlocks:ctor()
	self.direction = self.direction or "front";
end

function DestroyNearbyBlocks:Run()
	
	self.player_x, self.player_y, self.player_z = ParaScene.GetPlayer():GetPosition();

	if(not self.destroy_blocks) then
		local offset_y = 0;

		local bx,by,bz = self.blockX, self.blockY, self.blockZ;
	
		if(bx) then
			offset_y = -1;
		else
			-- use player location if not provided
			bx,by,bz = BlockEngine:block(self.player_x, self.player_y+0.1, self.player_z);
			if(self.direction == "down") then
				offset_y = -1;
			elseif(self.direction == "up") then
				offset_y = 1;
			end
		end

		local destroy_blocks = {};
		local i, j, k;
		for i = 0, 2 do 
			for j = 0, 2 do 
				for k = 0, 2 do 
					local x, y, z = bx+i-1,by+k+offset_y, bz+j-1
					local block_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
					if(block_id~=0 and (not self.block_id or self.block_id == block_id)) then
						-- highlight it
						ParaTerrain.SelectBlock(x,y,z, true);
						destroy_blocks[#destroy_blocks+1] = {x,y,z}
					end
				end
			end
		end
		self.destroy_blocks = destroy_blocks;
	end

	if(#(self.destroy_blocks) > 0)then
		self.start_time = commonlib.TimerManager.GetCurrentTime();
		TaskManager.AddTask(self);
	end
end

function DestroyNearbyBlocks:FrameMove()
	local cur_time = commonlib.TimerManager.GetCurrentTime();
	
	local can_explode = ( (cur_time - (self.start_time or 0)) > self.explode_time);

	local confirm_key_pressed = self.detect_key and ParaUI.IsKeyPressed(DIK_SCANCODE[self.detect_key]);
	if(not confirm_key_pressed) then
		self.has_key_released = true;
	end
	if( (confirm_key_pressed and self.has_key_released) or can_explode) then
		self.finished = true;

		local x, y, z = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(x, y+0.1, z);
		
		local total_count = #(self.destroy_blocks);
		local pieces_granularity = 3/total_count;
		local is_sound_played;
		local count = 0;
		local b;
		for _, b in ipairs(self.destroy_blocks) do
			local block_id, last_block_data, last_entity_data = BlockEngine:GetBlockFull(b[1],b[2],b[3]);
			if(block_id and block_id > 0) then
				-- keep block_id for redo. 
				local block_template = block_types.get(block_id);
				if(block_template) then
					local block_modified = block_template:Remove(b[1],b[2],b[3]);
					if(block_modified and block_modified>=1) then
						b.block_id = block_id;
						b.last_block_data = last_block_data;
						b.last_entity_data = last_entity_data;
						count = count + 1;
							
						block_template:CreateBlockPieces(b[1],b[2],b[3], pieces_granularity);

						if(not is_sound_played) then
							is_sound_played = true;
							block_template:play_break_sound();
						end
						
						if(bx == b[1] and (by-1) == b[2] and bz == b[3]) then
							-- let the player fall down if the block beneath is removed. 
							ParaScene.GetPlayer():ToCharacter():FallDown();
						end
					end
				end
			end
		end
			
		if(count and count>0) then
			self.count = count;

			if(self.blockX) then
				local tx, ty, tz = BlockEngine:real(self.blockX,self.blockY,self.blockZ);
				GameLogic.PlayAnimation({animationName = "Break",facingTarget = {x=tx, y=ty, z=tz},});
			end

			if(GameLogic.GameMode:CanAddToHistory()) then
				UndoManager.PushCommand(self);
			end
		end
	end

	-- update the selector effect
	local b;
	for _, b in ipairs(self.destroy_blocks) do
		ParaTerrain.SelectBlock(b[1],b[2],b[3], not self.finished);
	end
end

function DestroyNearbyBlocks:Redo()
	if(self.count and self.count>0) then
		-- update the selector effect
		local b;
		for _, b in ipairs(self.destroy_blocks) do
			if(b.block_id) then
				BlockEngine:SetBlockToAir(b[1],b[2],b[3], 3);
			end
		end
	end
end

function DestroyNearbyBlocks:Undo()
	if(self.count and self.count>0) then
		-- update the selector effect
		local b;
		for _, b in ipairs(self.destroy_blocks) do
			if(b.block_id) then
				BlockEngine:SetBlock(b[1],b[2],b[3], b.block_id, b.last_block_data, 3, b.last_entity_data);
			end
		end
		if(self.player_x) then
			ParaScene.GetPlayer():SetPosition(self.player_x, self.player_y, self.player_z);
		end
	end
end