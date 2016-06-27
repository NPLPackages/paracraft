--[[
Title: Create Simple Shapes
Author(s): LiXizhi
Date: 2013/2/10
Desc: Create Simple Shapes like ring, circle, sphere, box, cylinder, etc
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateSimpleShapeTask.lua");
local task = MyCompany.Aries.Game.Tasks.CreateSimpleShape:new({shape="ring", radius=12})
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
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local CreateSimpleShape = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateSimpleShape"));

function CreateSimpleShape:ctor()
	
end

function CreateSimpleShape:Run()
	self.finished = true;
	self.history = {};

	local plane = self.plane;
	local shape = self.shape;
	local radius = self.radius or 10;
	local radiusX = self.radiusX or 10;
	local radiusY = self.radiusY or 10;
	local radiusZ = self.radiusZ or 10;
	local beSolid = self.beSolid;
	local x = self.x;
	local y = self.y;
	local z = self.z;
	self.block_id = self.block_id or GameLogic.GetBlockInRightHand() or block_types.names.Grass;

	if(radius>1000) then
		LOG.std(nil, "info", "CreateSimpleShape", "radius is too big");
		return;
	end

	if(not x) then
		local px, py, pz = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(px, py+0.1, pz);
		x,y,z = bx, by, bz;
	end

	if(shape == "ring") then
		radius = radius or 10;
		--self:CreateRing(x,y,z, radius, radius-(self.thickness or 0));
		self:CreateRingInPlane(x,y,z, radius, radius-(self.thickness or 0), plane)
	elseif(shape == "circle") then
		radius = radius or 10;
		--self:CreateRing(x,y,z, radius, 0);
		self:CreateRingInPlane(x,y,z, radius, 0, plane)
	elseif(shape == "box") then
		self:CreateBox(x,y,z, self.dx or 1, self.dy or 1, self.dz or 1);
	elseif(shape == "sphere") then
		radius = radius or 10;
		--self:CreateRing(x,y,z, radius, 0);
		self:CreateSphere(x, y, z, radius, beSolid);
	elseif(shape == "ellipsoid") then
		--self:CreateSphere(x, y, z, radiusX, radiusY, radiusZ, beSolid);
		local diameterX = 2 * radiusX + 1;
		local diameterY = 2 * radiusY + 1;
		local diameterZ = 2 * radiusZ + 1;
		self:CreateEllipsoid(x,y,z,diameterX,diameterY,diameterZ,beSolid);
	end

	if(GameLogic.GameMode:CanAddToHistory()) then
		if(#(self.history) > 0) then
			UndoManager.PushCommand(self);
		end
	end
end

function CreateSimpleShape:FrameMove()
	self.finished = true;
end

function CreateSimpleShape:AddBlock(block_template, x,y,z)
	local from_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z);
	--block_template:Create(x,y,z, true);
	local block_id;
	if(block_template and block_template.id) then
		block_id = block_template.id;
	else
		block_id = self.block_id
	end
	BlockEngine:SetBlock(x, y, z, block_id);
	self.history[#(self.history)+1] = {x,y,z, block_id, from_id};
end


-- @param min_x,min_y,min_z: minimum position
function CreateSimpleShape:CreateBox(min_x,min_y,min_z, dx, dy, dz)
	local block_id = self.block_id;
	local block_template = block_types.get(block_id);
	if(block_template) then
		local x,y,z = min_x,min_y,min_z;
	
		for i=1, dx, if_else(dx>0, 1, -1) do
			for j = 1, dy, if_else(dy>0, 1, -1) do
				for k = 1, dz, if_else(dz>0, 1, -1) do
					self:AddBlock(block_template, min_x+i-1,min_y+j-1,min_z+k-1);
				end
			end
		end
	end
end
	
function CreateSimpleShape:CreateRing(cx,cy,cz, outer_radius, inner_radius)
	local block_id = self.block_id;
	local block_template = block_types.get(block_id);
	if(block_template) then
		local x,y,z,zi = 0,0,0,0;
		inner_radius = inner_radius or outer_radius;
		
		local radius_sq = outer_radius*outer_radius
		local radius_inner_sq = inner_radius*inner_radius

		local last_z = outer_radius;
		for x=0, outer_radius do
			z = math.floor(math.sqrt(radius_sq - x*x)+0.5);
			if(x<inner_radius) then
				zi = math.floor(math.sqrt(radius_inner_sq - x*x)+0.5);
			else
				zi = 0;
			end

			local z_;
			local z_to = math.max(last_z -1, z);
			for z_ = zi, z_to do
				self:AddBlock(block_template, x+cx,y+cy,z_+cz);
				if(z_ ~=0) then
					self:AddBlock(block_template, x+cx,y+cy,-z_+cz);
				end
				if(x ~= 0) then
					self:AddBlock(block_template, -x+cx,y+cy,z_+cz);
					if(z_ ~=0) then
						self:AddBlock(block_template, -x+cx,y+cy,-z_+cz);
					end
				end
			end
				
			last_z = z;
		end
	end
end

function CreateSimpleShape:CreateRingInPlane(cx,cy,cz, outer_radius, inner_radius, plane)

	local function generateBlockCoordinate(x, y, z, offse_coor1, offse_coor2, plane)
		local new_x, new_y, new_z;
		if(plane == "x" or plane == "X") then
			new_x = x;
			new_y = y + offse_coor1;
			new_z = z + offse_coor2;
			--return x, y + offse_coor1, z + offse_coor2;
		elseif(plane == "y" or plane == "Y") then
			new_x = x + offse_coor1;
			new_y = y;
			new_z = z + offse_coor2;
			--return x, y + offse_coor1, z + offse_coor2;
		elseif(plane == "z" or plane == "Z") then
			new_x = x + offse_coor1;
			new_y = y + offse_coor2;
			new_z = z;
			--return x, y + offse_coor1, z + offse_coor2;
		else
			new_x = x;
			new_y = y;
			new_z = z;
		end
		return new_x, new_y, new_z;
	end

	local block_id = self.block_id;
	local block_template = block_types.get(block_id);
	if(block_template) then
		local x,y,z;
		inner_radius = inner_radius or outer_radius;
		
		local radius_sq = outer_radius*outer_radius
		local radius_inner_sq = inner_radius*inner_radius

		local plane_coor1, plane_coor2;
		local plane_coor2_min, plane_coor2_max;

		--local last_z = outer_radius;
		local last_plane_coor2_max = outer_radius;
		for plane_coor1 = 0, outer_radius do
			plane_coor2_max = math.floor(math.sqrt(radius_sq - plane_coor1 * plane_coor1)+0.5);
			if(plane_coor1<inner_radius) then
				plane_coor2_min = math.floor(math.sqrt(radius_inner_sq - plane_coor1 * plane_coor1)+0.5);
			else
				plane_coor2_min = 0;
			end

			--local z_;
			--local z_to = math.max(last_z -1, z);
			local now_plane_coor2_max = math.max(last_plane_coor2_max -1, plane_coor2_max);
			for plane_coor2 = plane_coor2_min, now_plane_coor2_max do
				x, y, z = generateBlockCoordinate(cx, cy, cz, plane_coor1, plane_coor2, plane)
				--self:AddBlock(block_template, x+cx,y+cy,z_+cz);
				self:AddBlock(block_template, x, y, z);
				if(plane_coor2 ~=0) then
					x, y, z = generateBlockCoordinate(cx, cy, cz, plane_coor1, -plane_coor2, plane)
					self:AddBlock(block_template, x, y, z);
					--self:AddBlock(block_template, x+cx,y+cy,-z_+cz);
				end
				if(plane_coor1 ~= 0) then
					--self:AddBlock(block_template, -x+cx,y+cy,z_+cz);
					x, y, z = generateBlockCoordinate(cx, cy, cz, -plane_coor1, plane_coor2, plane)
					self:AddBlock(block_template, x, y, z);
					if(plane_coor2 ~=0) then
						--self:AddBlock(block_template, -x+cx,y+cy,-z_+cz);
						x, y, z = generateBlockCoordinate(cx, cy, cz, -plane_coor1, -plane_coor2, plane)
						self:AddBlock(block_template, x, y, z);
					end
				end
			end
				
			last_plane_coor2_max = plane_coor2_max;
		end
	end
end

function CreateSimpleShape:CreateCircle(x,y,z, radius)

end

function CreateSimpleShape:CreateSphere(cx,cy,cz, outer_radius, beSolid)
	local diameterX,diameterY,diameterZ = outer_radius*2 + 1, outer_radius*2 + 1, outer_radius*2 + 1;
	self:CreateEllipsoid(cx,cy,cz,diameterX,diameterY,diameterZ,beSolid);
end

function CreateSimpleShape:Redo()
	if((#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0);
		end
	end
end

function CreateSimpleShape:Undo()
	if((#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[5] or 0);
		end
	end
end

local function ellipsoidLocusCheck(x, y, z, radiusX, radiusY, radiusZ)
    return (x * x) / (radiusX * radiusX) + (y * y) / (radiusY * radiusY) + (z * z) / (radiusZ * radiusZ) < 1;
end

local neighbour_coor_offsets = {
	{-1,0,0},
	{0,-1,0},
	{0,0,-1},
	{1,0,0},
	{0,1,0},
	{0,0,1},
}

local function getOrthogonalNeighbours(x, y, z, neighbourIndex)
	local offset = neighbour_coor_offsets[neighbourIndex];
	local nx, ny, nz = x + offset[1], y + offset[2], z + offset[3];
	return nx, ny, nz;
end

local function onSurfaceEdgeCheck(x, y, z, radiusX, radiusY, radiusZ, beSolid)
    local neighboursSet = 0;
    local neighboursNotSet = 0;

	local nx, ny, nz;
	for i = 1, 6 do
		nx, ny, nz = getOrthogonalNeighbours(x, y, z, i);
		if(ellipsoidLocusCheck(nx, ny, nz, radiusX, radiusY, radiusZ)) then
			neighboursSet = neighboursSet + 1;
		else
			neighboursNotSet = neighboursNotSet + 1;
		end

		 if (neighboursSet > 0 and neighboursNotSet > 0) then
			return true;
		 end            
	end

	if(beSolid and neighboursSet == 6) then
		return true;
	end

	return false;
end

function CreateSimpleShape:CreateEllipsoid(cx,cy,cz,diameterX,diameterY,diameterZ,beSolid)
	local block_id = self.block_id;
	local block_template = block_types.get(block_id);

	local radiusX = diameterX / 2;
    local radiusY = diameterY / 2;
    local radiusZ = diameterZ / 2;

    local radiusCeilingX = math.ceil(radiusX);
    local radiusCeilingY = math.ceil(radiusY);
    local radiusCeilingZ = math.ceil(radiusZ);

    local midX = (diameterX - 1) / 2;
    local midY = (diameterY - 1) / 2;
    local midZ = (diameterZ - 1) / 2;

    local diameterOffsetX = diameterX - 1;
    local diameterOffsetY = diameterY - 1;
    local diameterOffsetZ = diameterZ - 1;

	--for (var x = 0; x < radiusCeilingX; ++x)
        --for (var y = 0; y < radiusCeilingY; ++y)
            --for (var z = 0; z < radiusCeilingZ; ++z)
	for x = 0, radiusCeilingX do
        for y = 0, radiusCeilingY do
            for z = 0, radiusCeilingZ do
                --if (ellipsoidLocusCheck(x - midX, y - midY, z - midZ, radiusX, radiusY, radiusZ) and onSurfaceEdgeCheck(x, y, z, radiusX, radiusY, radiusZ)) then
				if (ellipsoidLocusCheck(x, y, z, radiusX, radiusY, radiusZ) and onSurfaceEdgeCheck(x, y, z, radiusX, radiusY, radiusZ, beSolid)) then
					self:AddBlock(block_template, cx + x, cy + y, cz + z);
					self:AddBlock(block_template, cx - x, cy + y, cz + z);
					self:AddBlock(block_template, cx + x, cy + y, cz - z);
					self:AddBlock(block_template, cx - x, cy + y, cz - z);

					self:AddBlock(block_template, cx + x, cy - y, cz + z);
					self:AddBlock(block_template, cx - x, cy - y, cz + z);
					self:AddBlock(block_template, cx + x, cy - y, cz - z);
					self:AddBlock(block_template, cx - x, cy - y, cz - z);
					

					--self:AddBlock(block_template, cx + x, cy + y, cz + z);
					--self:AddBlock(block_template, cx + diameterOffsetX - x, cy + y, cz + z);
					--self:AddBlock(block_template, cx + x, cy + diameterOffsetY - y, cz + z);
					--self:AddBlock(block_template, x, cy + y, cz + diameterOffsetZ - z);
					--self:AddBlock(block_template, cx + diameterOffsetX - x, cy + diameterOffsetY - y, cz + z);
					--self:AddBlock(block_template, cx + x, cy + diameterOffsetY - y, cz + diameterOffsetZ - z);
					--self:AddBlock(block_template, cx + diameterOffsetX - x, cy + y, cz + diameterOffsetZ - z);
					--self:AddBlock(block_template, cx + diameterOffsetX - x, cy + diameterOffsetY - y, cz + diameterOffsetZ - z);

					--Block(x, y, z);
					--Block(diameterOffsetX - x, y, z);
					--Block(x, diameterOffsetY - y, z);
					--Block(x, y, diameterOffsetZ - z);
					--Block(diameterOffsetX - x, diameterOffsetY - y, z);
					--Block(x, diameterOffsetY - y, diameterOffsetZ - z);
					--Block(diameterOffsetX - x, y, diameterOffsetZ - z);
					--Block(diameterOffsetX - x, diameterOffsetY - y, diameterOffsetZ - z);
				end
			end
		end
	end
end