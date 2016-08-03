--[[
Title: Block terrain filters
Author(s): LiXizhi
Date: 2013/11/27
Desc: apply filters to block terrain 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/TerrainFilterTask.lua");
local task = MyCompany.Aries.Game.Tasks.TerrainFilter:new()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local TerrainFilter = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.TerrainFilter"));

TerrainFilter.radius = 5;
-- this can be "flatten" or ""
TerrainFilter.operation = "flatten";
-- when user keeps holding the mouse button, the task may be run repeatedly every 1000ms. 
TerrainFilter.step_duration = 200;


-- Perform filtering on a terrain height field.
-- set or get the terrain data by calling GetTerrainData() function.

TerrainFilter.MergeOperation = {
		Addition = 0,
		Subtract = 1,
		Multiplication = 2,
		Division = 3,
		Minimum = 4,
		Maximum = 5,
};

TerrainFilter.FlattenOperation = {
		-- Flatten the terrain up to the specified elevation 
		Fill_Op = 1,
		-- Flatten the terrain down to the specified elevation
		ShaveTop_Op = 2,
		-- Flatten the terrain up and down to the specified elevation 
		Flatten_Op = 3
};

TerrainFilter.PaintOperation = {
		-- replace blocks
		Replace_Op = 1,
		-- overlay on top of existing blocks
		Ontop_Op = 2,
};

local FlattenOperation = TerrainFilter.FlattenOperation;

function TerrainFilter:ctor()
	self.history = {};
	self.TTerrain = {};
	self.add_to_history = true;
end

-- @param paint_op: TerrainFilter.PaintOperation, default to Replace. 
-- @param x,y,z: center of the paint brush
-- @param block_id: the block to paint. can be 0
-- @param radius: the block radius, default to 5 
-- @param strength: (0, 1] the average probability to paint on each of the specified paint location.
-- @param side: the side to paint on default to 5 (which is the top block)
-- 1 means all blocks in the ciruclar region will be painted. default 0.3. 
function TerrainFilter:PaintBlocks(paint_op, block_id, block_data, xcent,ycent,zcent, radius, strength, side)
	paint_op = paint_op or TerrainFilter.PaintOperation.Replace_Op;
	radius = radius or 5;
	strength = strength or 0.3;
	side = side or 5;
	local xmin, xmax, ymin, ymax, zmin, zmax;
	
	xmin = xcent - radius;
	xmax = xcent + radius;
	ymin = math.max(1, ycent - radius);
	ymax = ycent + radius;
	zmin = zcent - radius;
	zmax = zcent + radius;
	local radiusSq = (radius-0.5)^2;
	if(side == 5) then
		for x = xmin, xmax do
			for z = zmin, zmax do
				local r_sq = ((x - xcent)^2+(z - zcent)^2);
				if(r_sq <= radiusSq) then
					for y = self:GetHeight(x, z, ymax), ymin, -1 do
						local block_template = BlockEngine:GetBlock(x,y,z);
						if(block_template and (block_id == 0 or block_template:isNormalCube())) then
							if( math.random() <= strength) then
								if(paint_op == self.PaintOperation.Ontop_Op) then
									self:SetBlock(x, y+1, z, block_id, block_data, 3);
								else
									-- default to replace operation
									self:SetBlock(x, y, z, block_id, block_data);
								end
							end
							break;
						end
					end
				end
			end
		end 
	end
end


--  Flatten the terrain both up and down to the specified elevation, using using the 
-- tightness parameter to determine how much the altered points are allowed 
-- to deviate from the specified elevation. 
-- @param flatten_op: nil default to FlattenOperation.Fill_Op
-- @param elevation: the desired height
-- @param factor: value is between [0,1]. 1 means fully transformed; 0 means nothing is changed
-- @param xcent: the center of the affected circle.
-- @param ycent: the center of the affected circle.
-- @param radius: the radius of the affected circle. 
-- @param min_thickness: at least blocks thick of the terrain shell
function TerrainFilter:Flatten(flatten_op, elevation, xcent, ycent, radius, factor)
	flatten_op = flatten_op or FlattenOperation.Flatten_Op;
	radius = radius or 5;
	factor = factor or 0.8;

	local max_height = elevation + radius*2;
	local xmin, xmax, ymin, ymax;
	xmin = xcent - radius;
	xmax = xcent + radius;
	ymin = ycent - radius;
	ymax = ycent + radius;
	
	local inner_radius = radius * factor;
	local thinkness = math.max(radius - inner_radius,1);

	for y = ymin, ymax do
		for x = xmin, xmax do
			local distance = (xcent+0.5 - x)^2 + (ycent+0.5 - y)^2;
			if(distance>0.001) then
				distance = math.sqrt(distance);
			end
			if (distance <= radius) then
				local factor_ = 1;
				if (distance <= inner_radius) then
					factor_ = 1;
				else
					factor_ = math.max(0, math.min(1, (radius-distance)/thinkness));
				end
				if(factor_ > 0 ) then
					local old_height = self:GetHeight(x, y, max_height, 5);
					local new_height = math.floor(elevation - (elevation - old_height) * (1 - factor_) + 0.5);
					self:MorphTerrainHeight(x, y, new_height, old_height, max_height);
				end
			end
		end
	end
end

-- @param filters: 5 for solid ones, or it will match all blocks.
function TerrainFilter:GetHeight(x, y, max_height, filters)
	max_height = max_height or 255;
	local dist = ParaTerrain.FindFirstBlock(x, max_height, y, 5, max_height, filters);
	if(dist<0) then
		return 0;
	else
		return max_height - dist;
	end
end


--  This creates a Gaussian hill at the specified location with the specified parameters.
--  it actually adds the hill to the original terrain surface.
--  Here ElevNew(x,y) = 
--		|(x,y)-(center_x,center_y)| < radius*smooth_factor,	ElevOld(x,y)+height_scale*exp(-[(x-center_x)^2+(y-center_y)^2]/(2*standard_deviation^2) ),
--		|(x,y)-(center_x,center_y)| > radius*smooth_factor, minimize hill effect.
-- @param xcent: the center of the affected circle. value in the range [0,1]
-- @param ycent: the center of the affected circle.value in the range [0,1]
-- @param radius: the radius of the affected circle.value in the range [0,0.5]
-- @param height_scale: scale factor. One can think of it as the maximum height of the Gaussian Hill. this value can be negative
-- @param standard_deviation: standard deviation of the unit height value. should be in the range (0,1). 
--  0.5 is common value. larger than that will just make a flat hill with smoothing.
-- @param smooth_factor: value is between [0,1]. 1 means fully transformed; 0 means nothing is changed
function TerrainFilter:GaussianHill(elevation, xcent, ycent, radius, height_scale, standard_deviation, smooth_factor)
	radius = radius or 8;
	standard_deviation = standard_deviation or 0.1;
	standard_deviation = 2*(standard_deviation^2);
	height_scale = height_scale or 0.5;
	smooth_factor = smooth_factor or 0.6;

	local xmin, xmax, ymin, ymax;
	xmin = xcent - radius;
	xmax = xcent + radius;
	ymin = ycent - radius;
	ymax = ycent + radius;
	height_scale = radius * height_scale;
	local smooth_radius = radius * smooth_factor;
	local max_height = elevation + radius*2;

	for y = ymin, ymax do
		for x = xmin, xmax do
			local distance = (xcent+0.5 - x)^2 + (ycent+0.5 - y)^2;
			if(distance>0.001) then
				distance = math.sqrt(distance);
			end
			if (distance <= radius) then
				local old_height = self:GetHeight(x, y, max_height, 5);
				local deltaHeight = height_scale * math.exp(-((distance/radius)^2)*standard_deviation);
				-- see if we should be smoothing
				if (distance > smooth_radius) then
					deltaHeight = deltaHeight*(1.0 - (distance-smooth_radius) / smooth_radius);
				end
				local new_height = math.max(1, old_height + math.floor(deltaHeight+0.5));
			
				self:MorphTerrainHeight(x, y, new_height, old_height, max_height);
			end
		end
	end
end

-- @param size: default to 5. 
-- @param max_height: if nil, it is max world height
-- return the average of the neighboring cells in a square size with 
function TerrainFilter:GetNeighbourAverageHeight(xcent, ycent, size, max_height)
	size = size or 5;
	local minx = math.floor(xcent-(size-1)/2+0.5);
	local miny = math.floor(ycent-(size-1)/2+0.5);
	local sum_height = 0;
	local count = 0;
	for y = miny, miny+size do
		for x = minx, minx+size do
			local height = self:GetHeight(x, y, max_height);
			if(height>0) then
				count = count + 1;
				sum_height = sum_height + height;
			end
		end
	end
	if(count > 0) then
		return math.floor(sum_height/count+0.5);
	end
	return 0;
end

-- changing terrain from old height to new height, it will use existing terrain blocks for morphing
-- we will maintain the top layer and extend using second layer.
-- @param x,y: block world horizontal coordinate. 
-- @param old_height: if nil, we will find max terrain height at x,y. 
function TerrainFilter:MorphTerrainHeight(x, y, new_height, old_height, max_height)
	old_height = old_height or self:GetHeight(x, y, max_height, 5);

	if(new_height ~= old_height) then
		local block_id_top, block_data_top, block_entity_top = BlockEngine:GetBlockFull(x, old_height, y);
		local block_id_second, block_data_second, block_entitydata_second = BlockEngine:GetBlockFull(x, old_height-1, y);
		if(block_id_top == 0) then
			block_id_top = names.Bedrock or 123;
		end
		if(block_id_second == 0) then
			block_id_second = block_id_top;
		end
		if(new_height > old_height) then
			for height = old_height+1, new_height do 
				local block_id_up, block_data_up, block_entitydata_up = BlockEngine:GetBlockFull(x, height, y);
				if(block_id_up > 0) then
					-- shifting non-solid blocks upwards
					local block_template = block_types.get(block_id_up);
					if(block_template and not block_template.liquid) then
						-- ignore liquid like water
						self:SetBlock(x, new_height+(height-old_height), y, block_id_up, block_data_up, nil, block_entitydata_up);	
					end
				end
				if(height <new_height) then
					self:SetBlock(x, height, y, block_id_second, block_data_second, nil, block_entitydata_second);
				else
					self:SetBlock(x, new_height, y, block_id_top, block_data_top, nil, block_entity_top);
				end
			end
		else
			for height = old_height, (new_height+1), -1 do 
				local block_id_up, block_data_up, block_entitydata_up = BlockEngine:GetBlockFull(x, old_height+(height-new_height), y);
				if(block_id_up > 0) then
					-- shifting non-solid blocks downwards
					self:SetBlock(x, height, y, block_id_up, block_data_up, nil, block_entitydata_up);	
					local block_template = block_types.get(block_id_up);
					if(block_template and not block_template.liquid) then
						-- ignore liquid like water
						self:SetBlock(x, old_height+(height-new_height), y, 0);	
					end
				else
					self:SetBlock(x, height, y, 0);
				end
			end
		end
	end
end

-- 	square filter for sharpening and smoothing. 
-- Use neighbour-averaging to roughen or smooth the height field. The factor 
-- determines how much of the computed roughening is actually applied to the 
-- height field. In it's default invocation, the 4 directly neighboring 
-- squares are used to calculate the roughening. If you select big sampling grid, 
-- all 8 neighboring cells will be used. 
-- @param elevation: if nil the max terrain height is used. 
-- @param roughen: true for sharpening, false for smoothing.
-- @param filter_size: default to 4 neighboring cells
-- @param factor: value is between [0,1]. 1 means fully transformed; 0 means nothing is changed
function TerrainFilter:Roughen_Smooth(elevation, xcent, ycent, radius, roughen, filter_size, factor)
	radius = radius or 8;
	filter_size = filter_size or 4;
	factor = factor or 0.5;

	local xmin, xmax, ymin, ymax;
	xmin = xcent - radius;
	xmax = xcent + radius;
	ymin = ycent - radius;
	ymax = ycent + radius;
	max_height = elevation;
	if(max_height) then
		max_height = elevation + radius*2;
	end

	local new_grid = {};
	for y = ymin, ymax do
		new_grid[y] = {};
		for x = xmin, xmax do
			local distance = (xcent+0.5 - x)^2 + (ycent+0.5 - y)^2;
			if(distance>0.001) then
				distance = math.sqrt(distance);
			end
			if (distance <= radius) then
				local originalHeight = self:GetHeight(x, y, max_height, 5);
				
				if(not max_height or originalHeight < max_height) then
					local averageHeight = self:GetNeighbourAverageHeight(x, y, 5, max_height);
					local value;
					if (roughen) then
						value = originalHeight - factor * (averageHeight - originalHeight);
					else
						value = originalHeight + factor * (averageHeight - originalHeight);
					end
					new_grid[y][x] = math.floor(value+0.5);
				end
			end
		end
	end
	for y = ymin, ymax do
		for x = xmin, xmax do
			if(new_grid[y][x]) then
				self:MorphTerrainHeight(x, y, new_grid[y][x], nil, max_height);
			end
		end
	end
end


-- Note: terrain data should be in normalized space with height in the range [0,1]. 
-- Picks a point and scales the surrounding terrain in a circular manner. 
-- Can be used to make all sorts of circular shapes. Still needs some work. 
--  radial_scale: pick a point (center_x, center_y) and scale the points 
--      where distance is mindist<=distance<=maxdist linearly.  The formula
--      we'll use for a nice sloping smoothing factor is (-cos(x*3)/2)+0.5.
function TerrainFilter:RadialScale(center_x, center_y, scale_factor, min_dist,max_dist, smooth_factor, frequency)
end

-- offset in a spherical region
function TerrainFilter:Spherical( offset)
end

function TerrainFilter:grid_neighbour_sum_size(terrain,x, y,size)
end

--  create a ramp (inclined slope) from height(x1,y1) to height(x2,y2). The ramp's half width is radius. 
-- this is usually used to created a slope path connecting a high land with a low land. 
-- @param radius: The ramp's half width
-- @param borderpercentage: borderpercentage*radius is how long the ramp boarder is to linearly interpolate with the original terrain. specify 0 for sharp ramp border.
-- @param factor: in range[0,1]. it is the smoothness to merge with other border heights.Specify 1.0 for a complete merge
function TerrainFilter:Ramp(x1, y1, height1, x2, y2, height2, radius, borderpercentage, factor)
	borderpercentage=borderpercentage or 0.5;
	factor=factor or 1.0;
end
		
-- 
-- load height field from file
-- @param fHeight : height of the edge 
-- @param nSmoothPixels:  the number of pixels to smooth from the edge of the height field. 
-- if this is 0, the original height field will be loaded unmodified. if it is greater than 0, the loaded height field 
-- will be smoothed for nSmoothPixels from the edge, where the edge is always fHeight. The smooth function is linear. For example,
-- - 0% of original height  for the first pixel from the edge 
-- - 1/nSmoothPixels of original height for the second pixel from the edge. Lerp(1/nSmoothPixels, fheight, currentHeight)
-- - 2/nSmoothPixels of original height for the third.Lerp(2/nSmoothPixels, fheight, currentHeight )
-- - 100% for the nSmoothPixels-1 pixel 
	
function TerrainFilter:SetConstEdgeHeight(fHeight, nSmoothPixels)
	fHeight= fHeight or 0;
	nSmoothPixels= nSmoothPixels or 7;
end

-- merge two terrains, and save the result to the current terrain. The three terrains are aligned by their center. 
-- the input terrain can be the current terrain. The two input terrain must not be normalized.
function TerrainFilter:Merge (terrain_1, terrain_2,weight_1, weight_2,operation)
end

function TerrainFilter:AddToUndoManager()
	self:SetFinished();
	if(next(self.history)) then
		TerrainFilter._super.AddToUndoManager(self);
	end
end

-- set block and add changed data to history
function TerrainFilter:SetBlock(x, y, z, block_id, block_data, flag, block_entitydata)
	if(self.add_to_history) then
		local index = BlockEngine:GetSparseIndex(x, y, z);
		if(not self.history[index]) then
			local from_id, from_data, from_entity_data = BlockEngine:GetBlockFull(x,y,z)
			if(from_id == block_id and (from_data or 0) == (block_data or 0)) then
				return;
			else
				BlockEngine:SetBlock(x, y, z, block_id, block_data, flag, block_entitydata);
				self.history[index] = {x,y,z, block_id, block_data, block_entitydata, from_id, from_data, from_entity_data};	
			end
		end
	end
end

function TerrainFilter:Redo()
	if(next(self.history)) then
		for _, b in pairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0, b[5], nil, b[6]);
		end
	end
end

function TerrainFilter:Undo()
	if(next(self.history)) then
		for i, b in pairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[7] or 0, b[8], nil, b[9]);
		end
	end
end
