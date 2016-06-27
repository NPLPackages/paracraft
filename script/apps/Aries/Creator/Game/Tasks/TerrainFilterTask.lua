--[[
Title: Block terrain filter
Author(s): LiXizhi
Date: 2013/11/27
Desc: filtering the terrain 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainFilterTask.lua");
local task = MyCompany.Aries.Game.Tasks.TerrainFilter:new()
task:Flatten(nil, 62, 7, nil, nil, 10, 0.6);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local TerrainFilter = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.TerrainFilter"));

TerrainFilter.radius = 5;
-- this can be "flatten" or ""
TerrainFilter.operation = "flatten";


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
local FlattenOperation = TerrainFilter.FlattenOperation;

function TerrainFilter:ctor()
	self.history = {};
	self.TTerrain = {};
end

--  Flatten the terrain both up and down to the specified elevation, using using the 
-- tightness parameter to determine how much the altered points are allowed 
-- to deviate from the specified elevation. 
-- @param flatten_op: nil default to FlattenOperation.Flatten_Op
-- @param elevation: the desired height
-- @param factor: value is between [0,1]. 1 means fully transformed; 0 means nothing is changed
-- @param xcent: the center of the affected circle. value in the range [0,1]
-- @param ycent: the center of the affected circle.value in the range [0,1]
-- @param radius: the radius of the affected circle.value in the range [0,0.5]
-- @param min_thickness: at least 3 blocks thick of the terrain shell
function TerrainFilter:Flatten(flatten_op, block_id, elevation, xcent, ycent,radius, factor, min_thickness)
	flatten_op = flatten_op or FlattenOperation.Flatten_Op;
	min_thickness = min_thickness or 3;
	block_id = block_id or names.Grass;
	if(not elevation or not xcent) then
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		x, y, z = BlockEngine:block(x, y-0.1, z);
		elevation = elevation or y;
		xcent = xcent or x;
		ycent = ycent or z;
	end
	radius = radius or 8;
	factor = factor or 0.8;

	local x, y;
	local xmin, xmax, ymin, ymax;
	local pos;
	xmin = xcent - radius;
	xmax = xcent + radius;
	ymin = ycent - radius;
	ymax = ycent + radius;
	
	local inner_radius = radius * factor;
	local thinkness = math.max(radius - inner_radius,1);

	for y = ymin, ymax do
		for x = xmin, xmax do
			local distance = (xcent - x)^2 + (ycent - y)^2;
			if(distance>0.001) then
				distance = math.sqrt(distance);
			end
			local factor_ = 1;
			
			if (distance <= inner_radius) then
				factor_ = 1;
			else
				factor_ = math.max(0, math.min(1, (radius-distance)/thinkness));
			end
			
			if(factor_ > 0 ) then
				local old_height = ParaTerrain.FindFirstBlock(x, 255, y, 5, 255);
				if(old_height<0) then
					old_height = 0;
				else
					old_height = 255 - old_height;
				end

			
				local new_height = math.floor(elevation - (elevation - old_height) * (1 - factor_) + 0.5);
				local min_thickness = 3;
				for height = math.max(0, math.min(elevation, new_height-min_thickness)), new_height do 
					BlockEngine:SetBlock(x, height, y, block_id);
				end
				
				if(new_height < old_height) then
					
					for height = new_height+1, old_height do 
						BlockEngine:SetBlock(x, height, y, 0);
					end
				end
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
function TerrainFilter:RadialScale (center_x, center_y, scale_factor, min_dist,max_dist, smooth_factor, frequency)
end

--  This creates a Gaussian hill at the specified location with the specified parameters.
--  it actually adds the hill to the original terrain surface.
--  Here ElevNew(x,y) = 
--		|(x,y)-(center_x,center_y)| < radius*smooth_factor,	ElevOld(x,y)+hscale*exp(-[(x-center_x)^2+(y-center_y)^2]/(2*standard_deviation^2) ),
--		|(x,y)-(center_x,center_y)| > radius*smooth_factor, minimize hill effect.
-- @param center_x: the center of the affected circle. value in the range [0,1]
-- @param center_y: the center of the affected circle.value in the range [0,1]
-- @param radius: the radius of the affected circle.value in the range [0,0.5]
-- @param hscale: scale factor. One can think of it as the maximum height of the Gaussian Hill. this value can be negative
-- @param standard_deviation: standard deviation of the unit height value. should be in the range (0,1). 
--  0.1 is common value. larger than that will just make a flat hill with smoothing.
-- @param smooth_factor: value is between [0,1]. 1 means fully transformed; 0 means nothing is changed
function TerrainFilter:GaussianHill (x,y,radius,hscale,standard_deviation,smooth_factor)
end

-- offset in a spherical region
function TerrainFilter:Spherical( offset)
end

function TerrainFilter:grid_neighbour_sum_size(terrain,x, y,size)
end

-- return the average of the neighboring cells in a square size with 
-- sides 1+(size*2) long
local function grid_neighbour_average_size(terrain, x, y,size)
end

-- 	square filter for sharpening and smoothing. 
-- Use neighbour-averaging to roughen or smooth the height field. The factor 
-- determines how much of the computed roughening is actually applied to the 
-- height field. In it's default invocation, the 4 directly neighboring 
-- squares are used to calculate the roughening. If you select big sampling grid, 
-- all 8 neighboring cells will be used. 
-- @param roughen: true for sharpening, false for smoothing.
-- @param big_grid: true for 8 neighboring cells, false for 4. 
-- @param factor: value is between [0,1]. 1 means fully transformed; 0 means nothing is changed
function TerrainFilter:Roughen_Smooth (roughen, big_grid, factor)
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

function TerrainFilter:Run()
	if(GameLogic.GameMode:CanAddToHistory()) then
		if(#(self.history) > 0) then
			UndoManager.PushCommand(self);
		end
	end
end

function TerrainFilter:Redo()
	if((#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0, b[7]);
		end
	end
end

function TerrainFilter:Undo()
	if((#self.history)>0) then
		local i, b;
		for i = #(self.history), 1, -1  do
			local b = self.history[i];
			BlockEngine:SetBlock(b[1],b[2],b[3], b[5] or 0, b[6]);
		end
	end
end
