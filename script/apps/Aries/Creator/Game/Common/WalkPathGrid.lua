--[[
Title: a walk path finding grid
Author(s): LiXizhi
Date: 2022/2/4
Desc: given a center point, compute all other walkable point from it. 
The A(*) star map handler has almost no memory allocations for each query. 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/WalkPathGrid.lua");
local WalkPathGrid = commonlib.gettable("MyCompany.Aries.Game.WalkPathGrid");

local pathgrid = WalkPathGrid:new();
pathgrid:ComputeGridByCenterAndFacing()
pathgrid:Print()
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/AStar.lua");
local AStar = commonlib.gettable("System.Util.AStar");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local WalkPathGrid = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.WalkPathGrid"));

-- can be 0 or 1, how many blocks to allow to automatically walk upward during path finding
WalkPathGrid:Property({"autoClimbup", 1});
-- can be [0-256], how many blocks to allow walk downward during path finding
WalkPathGrid:Property({"maxFallDown", 2});
-- enable walking on physical mesh
WalkPathGrid:Property({"enablePhysicalMesh", true});

local block_attributes
function WalkPathGrid:ctor()
	self.gridmap = {};
	self.tick = 0;
	self.center = {0,0,0};
	if(not block_attributes) then
		block_attributes = MyCompany.Aries.Game.block.attributes
	end
end

function WalkPathGrid:Init()
	return self;
end

-- set center position in block world coordinates
-- once center is set, we will clear all previous grid data by increase the tick count. 
function WalkPathGrid:SetCenter(bx, by, bz)
	self.tick = self.tick + 1;
	self.center[1], self.center[2], self.center[3] = bx, by, bz;
end

-- get center position in block world coordinates
function WalkPathGrid:GetCenter()
	return self.center[1], self.center[2], self.center[3];
end

function WalkPathGrid:GetTick()
	return self.tick;
end

-- @param x,y,z: ray origin in world space
-- @param dirX, dirY, dirZ: ray direction, default to 0, -1, 0
-- @param maxDistance: default to 10
-- @return entityLiveModel, hitX, hitY, hitZ: return entity live model that is hit by the ray. 
function WalkPathGrid:RayPickPhysicalModel(x, y, z, dirX, dirY, dirZ, maxDistance)
	local pt = ParaScene.Pick(x, y, z, dirX or 0, dirY or -1, dirZ or 0, maxDistance or 10, "point")
	if(pt:IsValid())then
		local entityName = pt:GetName();
		if(entityName and entityName~="") then
			local entity = EntityManager.GetEntity(entityName);
			if(entity) then
				local x1, y1, z1 = pt:GetPosition();
				return entity, x1, y1, z1;
			end
		end
	end
end

-- it will return true if player can stay in current block. 
-- The current block and the block above must be non-obstruction, and there should be no physical mesh that is higher than 1 block of the block bottom. 
-- @return boolean, minRealY: the second parameter is the lowest point in the block that the player can stay in real coordinate system. 
-- if there is no physical mesh, this should be the block bottom, if not, it it is physical mesh height at this block's center point. 
function WalkPathGrid:CanPlayerStayAtBlock(bx, by, bz)
	local block = BlockEngine:GetBlock(bx, by, bz)
	-- TODO: slab or half-block is a obstruction block, but shall we stay on top of it?
	if(not block or not block.obstruction) then
		local x, y, z = BlockEngine:real_bottom(bx, by, bz)
		local realY = y;
		block = BlockEngine:GetBlock(bx, by+1, bz)
		if(not block or not block.obstruction) then
			if(self.enablePhysicalMesh) then
				local entity, x1, y1, z1 = self:RayPickPhysicalModel(x, y + 2.5, z, 0, -1, 0, 10)
				if(entity and y1) then
					if(y1 >= y + BlockEngine.blocksize) then
						return
					elseif(y1 > y) then
						realY = y1
					end
				end
			end
			return true, realY;
		end
	end
end

function WalkPathGrid:GetGridItem(bx, by, bz)
	local cx, cy, cz = self:GetCenter();
	local index = (bx - cx)*10000+(bz - cz)
	local item = self.gridmap[index]
	return item;
end

function WalkPathGrid:GetLocationIndex(bx, by, bz)
	local cx, cy, cz = self:GetCenter();
	local index = (bx - cx)*10000+(bz - cz)
	return index;
end


function WalkPathGrid:CreateGetGridItem(bx, by, bz)
	local cx, cy, cz = self:GetCenter();
	local index = (bx - cx)*10000+(bz - cz)
	local item = self.gridmap[index]
	if(not item) then
		item = {location={x=0, y=0}};
		self.gridmap[index] = item;
	end
	return item;
end

function WalkPathGrid:SetGridWalkable(bx, by, bz, isWalkable, realY)
	local item = self:CreateGetGridItem(bx, by, bz);
	item.tick = self.tick;
	item.location.x, item.location.y = bx, bz;
	item.bx, item.by, item.bz = bx, by, bz;
	item.isWalkable = isWalkable == true;
	item.realY = realY;
end

function WalkPathGrid:IsGridComputed(bx, by, bz)
	local item = self:GetGridItem(bx, by, bz);
	return item and item.tick == self.tick;
end

-- return true, false, or nil: nil means not computed. 
function WalkPathGrid:IsGridWalkable(bx, by, bz)
	local item = self:GetGridItem(bx, by, bz);
	if(item and item.tick == self.tick) then
		return item.isWalkable;
	else
		return nil;
	end
end

-- private: breadth first tranversal
function WalkPathGrid:ComputeWalkableMap(bx, by, bz, radius)
	local queue = commonlib.Queue:new(); 
	queue:push(mathlib.vector3d:new_from_pool(bx, by, bz))
	local cx, cy, cz = bx, by, bz
	while(true) do
		local pos = queue:pop()
		if(pos) then
			local bx, by, bz = pos[1], pos[2], pos[3]
			local fromX, fromY, fromZ = BlockEngine:real_top(bx, by, bz);
			for i = 0, 3 do
				local dx, dy, dz = Direction.GetOffsetBySide(i)
				local x, y, z = bx + dx, by, bz + dz; 
				if(not self:IsGridComputed(x, y, z)) then
					local isWalkable;
					local realY;
					local block = BlockEngine:GetBlock(x, y, z)
					if(block and block.obstruction) then
						if(self.autoClimbup > 0) then
							y = y + 1
							isWalkable, realY = self:CanPlayerStayAtBlock(x, y, z)
						end
					else
						local newY;
						local block_id, solid_y = BlockEngine:GetNextBlockOfTypeInColumn(x, y, z, block_attributes.obstruction, 5)
						if(block_id) then
							local y1 = solid_y + 1
							if(y1 >= (by - self.maxFallDown)) then
								newY = y1;
							end
						end
						if(self.enablePhysicalMesh) then
							local rx, ry, rz = BlockEngine:real_bottom(x, y, z)
							local entity, x1, y1, z1 = self:RayPickPhysicalModel(rx, ry+1.5, rz, 0, -1, 0, 10)
							if(entity and y1) then
								x1, y1, y2 = BlockEngine:block(x1, y1, z1)
								if(y1 > ry) then
									if(self.autoClimbup > 0) then
										newY = y1;
									end
								elseif(y1 >= (by - self.maxFallDown)) then
									if(not newY) then
										newY = y1;
									else
										newY = math.max(y1, newY);	
									end
								end
							end
						end
						if(newY) then
							y = newY
							isWalkable, realY = self:CanPlayerStayAtBlock(x, y, z)
						end
					end
					if(isWalkable and self.enablePhysicalMesh) then
						-- we need also ensure that we can walk horizontally from last grid to the new grid point. 
						local toX, toY, toZ = BlockEngine:real_top(x, y, z);
						local dx, dy, dz = toX-fromX, toY-fromY, toZ - fromZ
						local dist = math.sqrt(dx ^ 2 + dy ^ 2 + dz^ 2)
						-- TODO: for accuracy, we may cast more rays in future
						local entity, x1, y1, z1 = self:RayPickPhysicalModel(fromX, fromY+0.5, fromZ, dx, dy, dz, dist+0.5)
						if(entity and y1) then
							isWalkable = false;
						end
					end
					self:SetGridWalkable(x, y, z, isWalkable==true, realY);
					if(isWalkable) then
						if(math.max(math.abs(cx-x), math.abs(cz - z)) < radius) then
							queue:push(mathlib.vector3d:new_from_pool(x, y, z))
						end
					end
				end
			end
		else
			break;
		end
	end
end

-- the play can only stay if current block and its closest neighbour blocks are walkable. 
-- @param bx, by, bz: is block_float position. 
-- @return true if we can
function WalkPathGrid:CanPlayerStayAtPoint(bx, by, bz)
	local x, y, z = math.floor(bx), math.floor(by), math.floor(bz)
	if(self:IsGridWalkable(x, y, z) == true) then
		local dx, dz = bx - x - 0.5, bz - z - 0.5;
		dx = (math.abs(dx) < 0.1) and 0 or (dx > 0 and 1 or -1)
		dz = (math.abs(dz) < 0.1) and 0 or (dz > 0 and 1 or -1)
		if(dx~=0 and self:IsGridWalkable(x+dx, y, z) ~= true) then
			return false;
		end
		if(dz~=0 and self:IsGridWalkable(x, y, z+dz) ~= true) then
			return false;
		end
		if(dx~=0 and dz~=0 and self:IsGridWalkable(x+dx, y, z+dz) ~= true) then
			return false;
		end
		return true
	end
	return false;
end

-- @param startX, startY, startZ: the starting location in real world coordinates
-- @param facing: direction 
-- @param walkDist: the desired walk (block) distance to go along the direction. default to 1, this can be floating values. 
-- @param maxSteps: default to 5 blocks along the direction. 
-- @return destX, destY, destZ: may be nil if no path is found
function WalkPathGrid:GetTargetPositionByPosAndFacing(startX, startY, startZ, facing, walkDist, maxSteps)
	walkDist = walkDist or 1
	maxSteps = math.max(walkDist, maxSteps or 5);
	local fromX, fromY, fromZ = BlockEngine:block_float(startX, startY+0.1, startZ)
	fromY = math.floor(fromY)
	local toX, toY, toZ = fromX + maxSteps*math.cos(facing), fromY, fromZ - maxSteps*math.sin(facing);
	local dx = toX - fromX;
	local dz = toZ - fromZ;
	local dist = dx^2 + dz^2;
	dist = math.sqrt(dist);

	local step = 1/dist;
	local lastX, lastZ;
	local destX, destY, destZ
	local distanceWalked = 0;
	local bNeedPathFinding = false;
	local pathDestX, pathDestY, pathDestZ;
	for i = 1, math.floor(dist)+1 do
		local percent = math.min(1, step * i);
		local bx, by, bz = fromX + percent * dx, fromY, fromZ + percent * dz
		local x, z = math.floor(bx), math.floor(bz);
		if(lastX~=x or lastZ~=z) then
			lastX, lastZ = x, z
			if(self:CanPlayerStayAtPoint(bx, by, bz) == true) then
				if(walkDist <= i and i <= maxSteps) then
					pathDestX, pathDestY, pathDestZ = x, fromY, z
					break;
				end
			else
				bNeedPathFinding = true;
			end
		end
	end
	if(pathDestX) then
		if(bNeedPathFinding) then
			-- a* path finding here
			local item = self:GetGridItem(pathDestX, pathDestY, pathDestZ);
			local astar = AStar:new():Init(self);
			local fromX, fromY, fromZ = self:GetCenter();
			local maxIterations = 1000
			local path, iterationCount = astar:findPath({x=fromX,y=fromZ}, {x=item.bx,y=item.bz}, maxIterations) 
			-- LOG.std(nil, "info", "WalkPathGrid", "iteraction count %d", iterationCount)
			if(path) then
				local curX, curY, curZ = startX, startY+0.1, startZ
				local distToWalk = walkDist;
				for _m, node in ipairs(path:getNodes()) do
					local item = self:GetGridItem(node.location.x, 0, node.location.y);
					if(item) then
						if(item.bx ~= fromX or item.bz ~= fromZ) then
							destX, destY, destZ = BlockEngine:real_bottom(item.bx, item.by, item.bz)
							destY = item.realY or destY;
							local deltaDist = math.sqrt((curX - destX)^2 + (curZ - destZ)^2);
							if(deltaDist < distToWalk * BlockEngine.blocksize or deltaDist<0.01) then
								curX, curY, curZ = destX, destY, destZ;
								distToWalk = distToWalk - deltaDist / BlockEngine.blocksize;
								if(distToWalk < 0.02) then
									break;
								end
							else
								-- already walked enough distance
								local percent = distToWalk * BlockEngine.blocksize / deltaDist;
								destX = curX + (destX - curX) * percent;
								destZ = curZ + (destZ - curZ) * percent;
								local x1, y1, z1 = BlockEngine:block(destX, 0, destZ);
								local item1 = self:GetGridItem(x1, 0, z1);
								if(item1) then
									destY = item1.realY or BlockEngine:realY(item1.by);
								end
								break;
							end
						end
					else
						break;
					end
				end
			else
				if(iterationCount >= maxIterations) then
					LOG.std(nil, "warn", "WalkPathGrid", "iteraction count too big %d", iterationCount)
				end
			end
		else
			-- just go in straight line along facing
			destX, destY, destZ = fromX + walkDist*math.cos(facing), fromY, fromZ - walkDist*math.sin(facing);
			local item = self:GetGridItem(math.floor(destX), 0, math.floor(destZ));
			if(item) then
				destY = item.by;
				destX, destY, destZ = BlockEngine:real_min(destX, destY, destZ)
				destY = item.realY or destY;
			end
		end
	end
	return destX, destY, destZ;
end

-- same as GetTargetPositionByFacing except that player can only be at block center instead of any where. 
function WalkPathGrid:GetTargetPositionByFacing(facing, minSteps, maxSteps, freeSpaceRadius)
	minSteps = minSteps or 1
	maxSteps = maxSteps or 5
	local fromX, fromY, fromZ = self:GetCenter();
	fromX, fromZ = fromX + 0.5, fromZ + 0.5;
	local toX, toY, toZ = fromX + maxSteps*math.cos(facing), fromY, fromZ - maxSteps*math.sin(facing);
	local dx = toX - fromX;
	local dz = toZ - fromZ;
	local dist = dx^2 + dz^2;
	dist = math.sqrt(dist);

	local step = 1/dist;
	local lastX, lastZ;
	local destX, destY, destZ
	for i = 1, math.floor(dist)+1 do
		local percent = math.min(1, step * i);
		local x, z = math.floor(fromX + percent * dx), math.floor(fromZ + percent * dz);
		if(lastX~=x or lastZ~=z) then
			lastX, lastZ = x, z
			if(self:IsGridWalkable(x, fromY, z) == true) then
				if(minSteps<=i and i<maxSteps) then
					local item = self:GetGridItem(x, fromY, z);
					
					local astar = AStar:new():Init(self);
					local fromX, fromY, fromZ = self:GetCenter();
					local maxIterations = 1000
					local path, iterationCount = astar:findPath({x=fromX,y=fromZ}, {x=item.bx,y=item.bz}, maxIterations) 
					-- LOG.std(nil, "info", "WalkPathGrid", "iteraction count %d", iterationCount)
					if(path) then
						for _m, node in ipairs(path:getNodes()) do
							local item = self:GetGridItem(node.location.x, 0, node.location.y);
							if(item) then
								destX, destY, destZ = BlockEngine:real_bottom(item.bx, item.by, item.bz)
								destY = item.realY or destY;
							end
							break;
						end
					else
						if(iterationCount >= maxIterations) then
							LOG.std(nil, "warn", "WalkPathGrid", "iteraction count too big %d", iterationCount)
						end
					end
					break;
				end
			end
		end
	end
	return destX, destY, destZ;
end

-- given a center point, compute all other walkable points from it with a preferred facing.  
-- @param cx, cy, cz: center world position in real coordinate.  default to current player position
-- @param facing: default to current player's facing. 
-- @param maxSteps: default to 16 blocks. 
-- @param minDist: default to 1, mini move distance
-- @param maxDist: default to 5, max move distance
-- @return hasSolution, toX, toY, toZ: hasSolution is true, if we have a solution.
function WalkPathGrid:ComputeGridByCenterAndFacing(cx, cy, cz, facing, maxSteps, minDist, maxDist)
	if(not cx or not facing) then
		local player = EntityManager.GetPlayer();
		if(not cx) then
			cx, cy, cz = player:GetPosition();
		end
		facing = facing or player:GetFacing();
	end
	maxSteps = maxSteps or 16
	local bx, by, bz = BlockEngine:block(cx, cy+0.1, cz)
	self:SetCenter(bx, by, bz)

	local bCanStay, realY = self:CanPlayerStayAtBlock(bx, by, bz)
	if (bCanStay) then
		self:SetGridWalkable(bx, by, bz, true, realY);
		self:ComputeWalkableMap(bx, by, bz, maxSteps)

		local toX, toY, toZ = self:GetTargetPositionByPosAndFacing(cx, cy, cz, facing, minDist or 1, maxDist or 5)
		if(toX) then
			return true, toX, toY, toZ;
		end
	end
end

function WalkPathGrid:Print()
	local cx, cy, cz = self:GetCenter()
	echo({"WalkPathGrid:Print", cx, cy, cz})
	for dz = -16, 16 do
		for dx = -16, 16 do
			if(self:IsGridWalkable(cx+dx, cy, cz+dz) == true) then
				log("1")
			else
				log("0")
			end
		end
		log("\n")
	end
end

-------------------
-- a star map handler: virtual functions
-- this implementation has no new memory allocations
-------------------

local function GetLocationId(x, y)
	return y * 100000 + x
end

-- virtual function: for A star map handler
function WalkPathGrid:getNode(location)
	local item = self:GetGridItem(location.x, 0, location.y);
	if(item and item.tick == self.tick) then
		if(item.isWalkable) then
			item.astarNode = item.astarNode or AStar.Node:new()
			item.astarNode:Init(item.location, 1, GetLocationId(location.x, location.y))
			return item.astarNode
		end
	end
end

-- virtual function: for A star map handler
function WalkPathGrid:locationsAreEqual(a, b)
	return a.x == b.x and a.y == b.y
end

local result = {}
-- virtual function: for A star map handler
function WalkPathGrid:getAdjacentNodes(curNode, dest, openNodes, closedNodes)
	local cl = curNode.location
	local dl = dest
  
	local n
	result[4] = nil
	result[3] = nil
	result[2] = nil
	result[1] = nil

	n = self:_handleNode(cl.x + 1, cl.y, curNode, dl.x, dl.y, openNodes, closedNodes)
	if n then
		table.insert(result, n)
	end

	n = self:_handleNode(cl.x - 1, cl.y, curNode, dl.x, dl.y, openNodes, closedNodes)
	if n then
		table.insert(result, n)
	end

	n = self:_handleNode(cl.x, cl.y + 1, curNode, dl.x, dl.y, openNodes, closedNodes)
	if n then
		table.insert(result, n)
	end

	n = self:_handleNode(cl.x, cl.y - 1, curNode, dl.x, dl.y, openNodes, closedNodes)
	if n then
		table.insert(result, n)
	end

	return result
end

local location_ = {x=0, y=0}
-- Fetch a Node for the given location and set its parameters
function WalkPathGrid:_handleNode(x, y, fromNode, destx, desty, openNodes, closedNodes)
	local locationId = GetLocationId(x, y)
	local lastNode = openNodes[locationId]
	if(closedNodes[locationId]) then
		return lastNode
	elseif(lastNode) then
		-- reuse existing node
		local mCost = fromNode.mCost + 1;
		if(mCost < lastNode.mCost) then
			lastNode.mCost = mCost;
			lastNode.score = lastNode.mCost + lastNode.emCost
			lastNode.parent = fromNode
		end
		return lastNode;
	else
		location_.x, location_.y = x, y;
		local n = self:getNode(location_)
		if n ~= nil then
			local dx = math.abs(x-destx)
			local dy = math.abs(y-desty)
			local emCost = dx + dy
			n.emCost = emCost; -- estimated cost to destination
			n.mCost = fromNode.mCost + 1;
			n.score = n.mCost + emCost
			n.parent = fromNode
    
			return n
		end
	end
end