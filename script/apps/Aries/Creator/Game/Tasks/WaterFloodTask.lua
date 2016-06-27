--[[
Title: Create Line
Author(s): LiXizhi
Date: 2013/1/19
Desc: Replace blocks in the direction specifed until it is blocked by another block or max_radius is reached. 
Support undo/redo
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WaterFloodTask.lua");
local task = MyCompany.Aries.Game.Tasks.WaterFlood:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, 
	fill_id=nil, radius = 5,})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local WaterFlood = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.WaterFlood"));

-- the water spread strength for the first block
WaterFlood.radius = 10;
-- if a water block is near another water block, it will gain additional spread speed
WaterFlood.water_spread_blocks = 5;
-- min y that can has water. 
WaterFlood.min_y = 0;

local coords;
function WaterFlood:ctor()
	self.step = 1;
	self.history = {};
	self.active_points = {};
	
	if(self.blockX) then
		if(not self.fill_id) then
			self.fill_id = block_types.names.Still_Water;
		end
		self:AddActivePoint(self.blockX,self.blockY,self.blockZ, self.radius);	
		
		local tx, ty, tz = BlockEngine:real(self.blockX,self.blockY,self.blockZ);
		if(not ParaTerrain.IsHole(tx, tz)) then
			local y = ParaTerrain.GetElevation(tx, tz);
			local _, by, _ = BlockEngine:block(0,y, 0);
			self.min_y = by;
		end
		
		GameLogic.PlayAnimation({animationName = "RaiseTerrain",facingTarget = {x=tx, y=ty, z=tz},});
	end
end

-- add simulation point
function WaterFlood:AddActivePoint(x,y,z, flood_strength)
	flood_strength = flood_strength or self.radius;
	local sparse_index = BlockEngine:GetSparseIndex(x, y, z);
	local last_strength = self.active_points[sparse_index];
	if(not last_strength or last_strength < flood_strength) then
		self.active_points[sparse_index] = flood_strength;
	end
end

-- flood a single block
function WaterFlood:FloodBlock(x, y, z, flood_strength)
	flood_strength = flood_strength or self.radius;
	local block_id = BlockEngine:GetBlockId(x,y,z);
	if(self.fill_id == 0) then
		if(block_id == block_types.names.Water or block_id == block_types.names.Still_Water ) then
			BlockEngine:SetBlock(x,y,z, 0);
			if(GameLogic.GameMode:CanAddToHistory()) then
				self.history[#(self.history)+1] = {x,y,z, block_id};
			end
		end
		if(y>self.min_y) then
			local below_block_id = BlockEngine:GetBlockId(x,y-1,z);
			if(below_block_id == block_types.names.Water or below_block_id == block_types.names.Still_Water ) then
				-- flood downward
				self:AddActivePoint(x,y-1,z, flood_strength);
			elseif(below_block_id == self.fill_id) then
				-- do nothing if connected with water block
			end
			if(flood_strength > 0)then
				-- flood in x,z direction
				self:AddActivePoint(x-1, y, z, flood_strength-1);
				self:AddActivePoint(x+1, y, z, flood_strength-1);
				self:AddActivePoint(x, y, z-1, flood_strength-1);
				self:AddActivePoint(x, y, z+1, flood_strength-1);
			end
		end
	elseif(block_id == 0 or block_id == self.fill_id) then
		if(block_id == 0) then
			BlockEngine:SetBlock(x,y,z, self.fill_id);
			if(GameLogic.GameMode:CanAddToHistory()) then
				self.history[#(self.history)+1] = {x,y,z};
			end
		end
		if(y>self.min_y) then
			local below_block_id = BlockEngine:GetBlockId(x,y-1,z);
			if(below_block_id == 0 ) then	
				-- flood downward
				self:AddActivePoint(x,y-1,z, flood_strength);
			elseif(below_block_id == self.fill_id) then
				-- do nothing if connected with water block
			end
			if(below_block_id ~= 0 and flood_strength > 0)then
				-- flood in x,z direction
				self:AddActivePoint(x-1, y, z, flood_strength-1);
				self:AddActivePoint(x+1, y, z, flood_strength-1);
				self:AddActivePoint(x, y, z-1, flood_strength-1);
				self:AddActivePoint(x, y, z+1, flood_strength-1);
			end
		end
	end
end

function WaterFlood:FrameMove()
	self.blockX = self.blockX;
	self.blockY = self.blockY - self.step;
	self.blockZ = self.blockZ;

	local last_active_points = self.active_points;
	self.active_points = {};
	local index, flood_strength
	for index, flood_strength in pairs(last_active_points) do
		local x, y, z = BlockEngine:FromSparseIndex(index);
		self:FloodBlock(x, y, z, flood_strength);
	end
	
	if(next(self.active_points) == nil) then
		self.finished  = true;
		if(GameLogic.GameMode:CanAddToHistory()) then
			if(#(self.history) > 0) then
				UndoManager.PushCommand(self);
			end
		end
	end
	self.step = self.step + 1;
end

function WaterFlood:Redo()
	if(self.blockX and self.fill_id and (#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or self.fill_id);
		end
	end
end

function WaterFlood:Undo()
	if(self.blockX and self.fill_id and (#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0);
		end
	end
end
