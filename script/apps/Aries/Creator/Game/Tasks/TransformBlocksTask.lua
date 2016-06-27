--[[
Title: Transform a given block set
Author(s): LiXizhi
Date: 2013/2/11
Desc: Current translation, rotation and scaling are supported. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformBlocksTask.lua");

-- translation
local task = MyCompany.Aries.Game.Tasks.TransformBlocks:new({dx = 1, dy=0, dz=0, blocks={},})
local task = MyCompany.Aries.Game.Tasks.TransformBlocks:new({x = 20000, y=0, z=20000, blocks={},operation="add"}) -- absolute position. 

-- rotation
local task = MyCompany.Aries.Game.Tasks.TransformBlocks:new({rot_y = 1, aabb=aabb, blocks={},})
-- scaling
local task = MyCompany.Aries.Game.Tasks.TransformBlocks:new({scaling = 1.2, scalingY=2, aabb=aabb, blocks={},})

task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local math_floor = math.floor;
local math_abs = math.abs;
local TransformBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.TransformBlocks"));

TransformBlocks.max_radius = 30;
-- this can be "move" or "add"
TransformBlocks.operation = "move";

function TransformBlocks:ctor()
	self.history = {};
end

function TransformBlocks:Run()
	
	if(self.blocks and #(self.blocks) > 0 ) then
		self.finished = true;
		
		GameLogic.PlayAnimation({animationName = "RaiseTerrain",});

		local final_blocks = {};

		local dx, dy, dz = self:GetDeltaPosition(self.x, self.y, self.z, self.aabb)
		
		-- for translation
		self:DoTranslation(dx,dy,dz, self.blocks, final_blocks);

		-- for rotation an axis
		if(self.rot_y and self.rot_y~=0) then
			self:DoRotation(self.rot_y, "y", self.blocks, final_blocks);
		elseif(self.rot_x and self.rot_x~=0) then
			self:DoRotation(self.rot_x, "x", self.blocks, final_blocks);
		elseif(self.rot_z and self.rot_z~=0) then
			self:DoRotation(self.rot_z, "z", self.blocks, final_blocks);
		end
		
		-- for scaling
		self:DoScaling(self.scalingX or self.scaling, self.scalingY or self.scaling, self.scalingZ or self.scaling, self.blocks, final_blocks);
		
		-- perform translation to final_blocks, by first removing all old blocks and then creating the new ones. 
		local bRemoveSourceBlocks = (self.operation == "move" or self.operation == "no_clone");
		self:DoTransform(self.blocks, final_blocks, bRemoveSourceBlocks)

		self.final_blocks = final_blocks;
	end
	if(GameLogic.GameMode:CanAddToHistory()) then
		if(#(self.history) > 0) then
			UndoManager.PushCommand(self);
		end
	end
end

function TransformBlocks:FrameMove()
	self.finished = true;
end

-- perform translation to final_blocks, by first removing all old blocks and then creating the new ones. 
function TransformBlocks:DoTransform(blocks, final_blocks, bRemoveSourceBlocks)
	if (#final_blocks > 0) then
		local i;
		if(bRemoveSourceBlocks) then
			for i = 1, #(blocks) do
				local b = blocks[i];
				
				local last_id, last_data, last_entity_data = BlockEngine:GetBlockFull(b[1],b[2],b[3]);
				if(last_id > 0) then
					BlockEngine:SetBlockToAir(b[1],b[2],b[3], 3);
					self.history[#(self.history)+1] = {b[1],b[2],b[3], 0, last_id,last_data, b[5],b[6],last_entity_data};
				end
			end
		end

		for i = 1, #(final_blocks) do
			local b = final_blocks[i];
			local last_id, last_data, last_entity_data = BlockEngine:GetBlockFull(b[1],b[2],b[3]);
			local block_template = block_types.get(b[4]);
			if(block_template) then
				BlockEngine:SetBlock(b[1],b[2],b[3], b[4], b[5], 3, b[6]);
				self.history[#(self.history)+1] = {b[1],b[2],b[3], b[4], last_id, last_data, b[5],b[6],last_entity_data};
			end
		end
	end
end


-- this function can also be used as static function. 
-- @param x,y,z: new bottom center position
-- @param aabb: old source aabb
-- @return dx,dy,dz: may all be zero
function TransformBlocks:GetDeltaPosition(x,y,z, aabb)
	local dx = self.dx or 0;
	local dy = self.dy or 0;
	local dz = self.dz or 0;

	if(x and y and z and aabb) then
		local mExtents = aabb.mExtents;
		local center = aabb:GetCenter();
		dx = math_floor(x - center[1]+0.1);
		dy = math_floor(y - (center[2]-mExtents[2])+0.1);
		dz = math_floor(z - center[3]+0.1);
	end
	return dx, dy, dz;
end

-- @param scaling factor: scaling factor
-- @param blocks: source block
-- @param aabb: aabb  of source block. 
-- @param final_blocks: the transformed block output. 
function TransformBlocks:DoScaling(scalingX, scalingY, scalingZ, blocks, final_blocks)
	scalingX = scalingX or 1;
	scalingY = scalingY or 1;
	scalingZ = scalingZ or 1;
	local scaling = math.min(scalingX, scalingY, scalingZ);
	if((scalingX~=1 or scalingY~=1 or scalingZ~=1) and self.aabb) then
		-- scaling is at the min of the aabb. 
		local pivot_x, pivot_y, pivot_z = self.aabb:GetMinValues();
		local extend_x, extend_y, entend_z = self.aabb:GetExtendValues();
		pivot_x, pivot_y, pivot_z = math_floor(pivot_x+0.5), math_floor(pivot_y+0.5), math_floor(pivot_z+0.5)
		-- offseting the final center, so that it is repostioned to the bottom center. 
		local bottomCenter_x, bottomCenter_y, bottomCenter_z = self.aabb:GetBottomPosition();
		local offset_x = pivot_x - math.floor((bottomCenter_x-pivot_x)*scalingX+0.5 - extend_x);
		local offset_y = pivot_y - 0;
		local offset_z = pivot_z - math.floor((bottomCenter_z-pivot_z)*scalingZ+0.5 - entend_z);

		local k = 0;
		for i = 1, #(blocks) do
			local b = blocks[i];
			local dx, dy, dz = b[1] - pivot_x, b[2] - pivot_y, b[3] - pivot_z;

			if(scaling<1) then
				-- min-point-filtering
				k = k + 1;
				final_blocks[k] = {
					math_floor(dx*scalingX + 0.499) + offset_x,
					math_floor(dy*scalingY + 0.499) + offset_y,
					math_floor(dz*scalingZ + 0.499) + offset_z,
					b[4],b[5],b[6],
				};
			else
				-- max-point-filtering
				for x = if_else(dx==0, 0, math_floor((dx)*scalingX)), math_floor((dx+1)*scalingX)-1 do
					for y = if_else(dy==0, 0, math_floor((dy)*scalingY)), math_floor((dy+1)*scalingY)-1  do
						for z = if_else(dz==0, 0, math_floor((dz)*scalingZ)), math_floor((dz+1)*scalingZ)-1  do
							k = k + 1;
							final_blocks[k] = {
								x + offset_x,
								y + offset_y,
								z + offset_z,
								b[4],b[5],b[6],
							};
						end
					end
				end
			end
		end
	end
end

-- @param dx,dy,dz: translation
-- @param blocks: source block
-- @param aabb: aabb  of source block. 
-- @param final_blocks: the transformed block output. 
function TransformBlocks:DoTranslation(dx,dy,dz, blocks, final_blocks)
	if(dx~=0 or dy~=0 or dz~=0) then
		for i = 1, #(blocks) do
			local b = blocks[i];
			final_blocks[i] = {b[1]+dx, b[2]+dy, b[3]+dz, b[4], b[5], b[6]};
		end
	end
end

-- @param rot_y: angle in radian
-- @param blocks: source block
-- @param aabb: aabb  of source block. 
-- @param final_blocks: the transformed block output. 
function TransformBlocks:DoRotation(rot_angle, axis, blocks, final_blocks)
	if(rot_angle and rot_angle~=0 and self.aabb) then
		local center = self.aabb:GetCenter();
		local cx, cy, cz;
		if(self.pivot_x and self.pivot_y and self.pivot_z) then
			cx, cy, cz = self.pivot_x, self.pivot_y, self.pivot_z;
		else
			cx, cy, cz = math_floor(center[1]), math_floor(center[2]), math_floor(center[3]);
		end
		
		local sin_t, cos_t = math_floor(math.sin(rot_angle)+0.5), math_floor(math.cos(rot_angle)+0.5);
		
		for i = 1, #(blocks) do
			local b = blocks[i];
			local blockTemplate = block_types.get(b[4]);
			local blockData = b[5];
			if(blockTemplate and blockData) then
				blockData = blockTemplate:RotateBlockData(blockData, -rot_angle, axis);
			end
			if(axis== "x") then
				local x, y = b[2] - cy, b[3] - cz;
				final_blocks[i] = {
					b[1],
					x*cos_t - y*sin_t + cy,
					x*sin_t + y*cos_t + cz,
					b[4],
					blockData,
					b[6],
				};
			elseif(axis== "z") then
				local x, y = b[1] - cx, b[2] - cy;
				final_blocks[i] = {
					x*cos_t - y*sin_t + cx,
					x*sin_t + y*cos_t + cy,
					b[3],
					b[4],
					blockData,
					b[6],
				};
			else -- if(axis== "y") then
				local x, y = b[1] - cx, b[3] - cz;
				final_blocks[i] = {
					x*cos_t - y*sin_t + cx,
					b[2],
					x*sin_t + y*cos_t + cz,
					b[4],
					blockData,
					b[6],
				};
			end
		end
	end
end

function TransformBlocks:Redo()
	if((#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0, b[7], nil, b[8]);
		end
	end
end

function TransformBlocks:Undo()
	if((#self.history)>0) then
		local i, b;
		for i = #(self.history), 1, -1  do
			local b = self.history[i];
			BlockEngine:SetBlock(b[1],b[2],b[3], b[5] or 0, b[6], nil, b[9]);
		end
	end
end
