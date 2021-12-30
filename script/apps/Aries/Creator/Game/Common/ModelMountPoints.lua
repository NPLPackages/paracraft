--[[
Title: Model mount points
Author(s): LiXizhi
Date: 2021/12/4
Desc: helper functions for entities with mount points. 
Each mount point can has its size, offset position, orientation, and other custom attributes. 
such as what animation to play when player is mounted, whether to allow player to mount, 
what event to fire when mounted, etc. 

This class is designed to be used as owned instance inside Entity object. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ModelMountPoints.lua");
local ModelMountPoints = commonlib.gettable("MyCompany.Aries.Game.Common.ModelMountPoints");
local mountpoint = ModelMountPoints:new():Init(parentEntity)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/MountPoint.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local math3d = commonlib.gettable("mathlib.math3d");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Cameras = commonlib.gettable("System.Scene.Cameras");
local MountPoint = commonlib.gettable("MyCompany.Aries.Game.Common.MountPoint");
local ModelMountPoints = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Common.ModelMountPoints"));

function ModelMountPoints:ctor()
	self.points = commonlib.Array:new();
	self.localTransform = Matrix4:new():identity();
	self.isTransformDirty = true
end

function ModelMountPoints:Init(parentEntity)
	self.parentEntity = parentEntity;
	-- parentEntity:Connect("valueChanged", self, self.SetTransformDirty)
	-- parentEntity:Connect("facingChanged", self, self.SetTransformDirty)
	-- parentEntity:Connect("scalingChanged", self, self.SetTransformDirty)
	return self;
end

function ModelMountPoints:SetTransformDirty()
	self.isTransformDirty = true
end

function ModelMountPoints:GetEntity()
	return self.parentEntity;
end

-- @param point: nil or table of {name, x, y, z, dx, dy, dz, facing} or instace of MountPoint class. 
function ModelMountPoints:AddMountPoint(point)
	local autoPos = false;
	if(not point or not point.ctor) then
		if(not point or not point.y) then
			autoPos = true;
		end
		point = MountPoint:new(point)
	end
	self.points:push_back(point)

	-- tricky: we will make mount point vertically spaced by default. 
	point.name = point.name or tostring(self:GetCount());
	point.index = self:GetCount()
	if(autoPos) then
		point.y = 0.4 * self:GetCount()
	end
	self:SetTransformDirty()
end

function ModelMountPoints:GetMountPoint(index)
	return self.points[index]
end

-- return array of all mount point
function ModelMountPoints:GetAllPoints()
	return self.points;
end

function ModelMountPoints:GetCount()
	return self.points:size();
end

-- @param num: total number of mount points
function ModelMountPoints:Resize(num)
	num = num or 0;
	if (self:GetCount() < num) then
		for i = self:GetCount(), num - 1 do
			self:AddMountPoint()
		end
	else
		self.points:resize(num);
	end
	self:SetTransformDirty()
end

function ModelMountPoints:Clear()
	self:Resize(0);
end

function ModelMountPoints:LoadFromXMLNode(node)
	if(self:GetCount() > 0) then
		self:Clear();
	end
	
	local points;
	for i=1, #node do
		if(node[i].name == "mountpoints") then
			points = node[i];
			break;
		end
	end
	if(points) then
		for i = 1, #points do
			local attr = points[i].attr;
			if(attr) then
				attr.x = attr.x and tonumber(attr.x);
				attr.y = attr.y and tonumber(attr.y);
				attr.z = attr.z and tonumber(attr.z);
				attr.facing = attr.facing and tonumber(attr.facing);
				attr.dx = attr.dx and tonumber(attr.dx);
				attr.dy = attr.dy and tonumber(attr.dy);
				attr.dz = attr.dz and tonumber(attr.dz);
				self:AddMountPoint(attr)
			end
		end
	end
	self:SetTransformDirty()
end

function ModelMountPoints:SaveToXMLNode(node, bSort)
	if(self:GetCount() > 0) then
		node.attr.hasMount = true
		local points = {name = "mountpoints"}
		node[#node + 1] = points
		for i = 1, self:GetCount() do
			local mp = self:GetMountPoint(i)
			local attr = {
				x = mp.x, y = mp.y, z = mp.z,
				dx = mp.dx, dy = mp.dy, dz = mp.dz,
				facing = mp.facing,
				name = mp.name,
			}
			points[i] = {name = "point", attr = attr}
		end
	end
	return node;
end

-- compute and return the parent entity's local transform. 
-- @param localTransform: if nil, we will use self.localTransform
function ModelMountPoints:GetEntityLocalTransform(localTransform)
	localTransform = localTransform or self.localTransform or Matrix4:new():identity();
	local entity = self:GetEntity();
	if(entity) then
		local facing = entity:GetFacing();
		if(facing ~= 0) then
			self.localRotQuat = self.localRotQuat or Quaternion:new();
			self.localRotQuat:FromAngleAxis(facing, vector3d.unit_y)
			self.localRotQuat:ToRotationMatrix(localTransform)
		else
			localTransform:identity()
		end
		local scaling = entity:GetScaling()
		if(scaling ~= 1) then
			self.matScale = self.matScale or Matrix4:new():identity();
			self.matScale:setScale(scaling, scaling, scaling);
			localTransform:multiply(self.matScale);
		end
	end
	return localTransform;
end

-- recalculate world matrix all the way up to root overlay. 
-- this is slow, do not calculate it every frame
-- @param mWorld: if not nil, we will pre-multiply this matrix.
-- @param bUseRenderOffset: if true, we will substract render origin 
-- @return Matrix4 
function ModelMountPoints:CalculateWorldMatrix(mWorld, bUseRenderOffset)
	local entity = self:GetEntity();
	if(not entity) then
		return 
	end
	local mWorld = self:GetEntityLocalTransform():clone();
	local x, y, z = entity:GetPosition();
	mWorld:offsetTrans(x, y, z);
	if(bUseRenderOffset) then
		local origin = ParaCamera.GetAttributeObject():GetField("RenderOrigin", {0,0,0});
		mWorld:offsetTrans(-origin[1], -origin[2], -origin[3]);
	end
	return mWorld;
end


-- transform mount point bottom center vectors to screen space (projection space / w). 
-- @return array of vectors, only v[1], v[2] should be used in returned value
function ModelMountPoints:GetMountPointsInScreenSpace()
	local worldMat = self:CalculateWorldMatrix(nil, true);
	local viewMat = Cameras:GetCurrent():GetViewMatrix();
	local projMat = Cameras:GetCurrent():GetProjMatrix();
	local finalMat = worldMat*viewMat*projMat;

	local viewport = ViewportManager:GetSceneViewport()
	local left, top, screenWidth, screenHeight = viewport:GetUIRect()
	
	local vecList = {};
	for i, point in ipairs(self.points) do
		local vec = point:GetPivot();
		math3d.Vector4MultiplyMatrix(vec, vec, finalMat);
		vec:MulByFloat(1/vec[4]);
		vec[1] = ((vec[1]+1)*0.5) * screenWidth;
		vec[2] = ((1-vec[2])*0.5) * screenHeight;
		vec[3] = 0;
		vec[4] = nil;
		vecList[i] = vec;
	end
	return vecList;
end

-- transform in local model space to world space. 
function ModelMountPoints:TransformLocalPointToWorldSpace(point)
	if(point) then
		local worldMat = self:CalculateWorldMatrix(nil, true);
		math3d.Vector4MultiplyMatrix(point, point, worldMat);
		local origin = ParaCamera.GetAttributeObject():GetField("RenderOrigin", {0,0,0});
		return point[1]+origin[1], point[2]+origin[2], point[3]+origin[3]
	end
end

-- @param index: mount point index
-- @return x, y, z: world position
function ModelMountPoints:GetMountPositionInWorldSpace(index)
	local mp = self:GetMountPoint(index)
	if(mp) then
		local pivot = mp:GetPivot();
		return self:TransformLocalPointToWorldSpace(pivot);
	end
end

function ModelMountPoints:GetMountFacingInWorldSpace(index)
	local mp = self:GetMountPoint(index)
	if(mp) then
		-- TODO: in case we support full orientation, we will need to do some matrix computations here. 
		return mp:GetFacing() + self:GetEntity():GetFacing();
	end
end

-- get mount point by a 3d point
-- @param x, y, z: in real world coordinates
-- @param bIgnoreY: true to ignore y position 
-- @param maxDiff: default to 0.1;
-- @return mountPoint
function ModelMountPoints:GetMountPointByXYZ(x, y, z, bIgnoreY, maxDiff)
	local mountPoint;
	maxDiff = maxDiff or 0.01;
	for i= 1, self:GetCount() do
		local x1, y1, z1 = self:GetMountPositionInWorldSpace(i)
		local diff = math.abs(x1 - x) + math.abs(z1 - z)
		if(not bIgnoreY) then
			diff = diff + math.abs(y1 - y)
		end
		if(diff < maxDiff) then
			mountPoint = self:GetMountPoint(i);
			break;
		end
	end
	return mountPoint;
end

-- check if a mount point is inside a mount point's aabb. the one that is closest to the mount point center is returned. 
-- @param x, y, z: a world space point
-- @param maxDiff: default to 0. we will expand the aabb by this value. usually 0.1
-- return true, mountpoint:  the first return value is true, if the mount point is inside one of the mount point's aabb. 
-- the second value is the mountpoint
function ModelMountPoints:IsPointInMountPointAABB(x, y, z, maxDiff)
	-- transform in local model space to camera space. 
	local worldMat = self:CalculateWorldMatrix(nil, true);
	
	local origin = ParaCamera.GetAttributeObject():GetField("RenderOrigin", {0,0,0});
	x, y, z = x - origin[1], y - origin[2], z - origin[3]
	
	for i= 1, self:GetCount() do
		local mountpoint = self:GetMountPoint(i);
		local cx, cy, cz = mountpoint:GetBottomCenter();
		local dx, dy, dz = mountpoint:GetAABBSize()
		local aabb = mathlib.ShapeAABB:new_from_pool(cx, cy+dy/2, cz, dx/2, dy/2, dz/2, true)
		if((maxDiff or 0) ~= 0) then
			aabb:Expand(maxDiff, maxDiff, maxDiff)
		end
		aabb:Rotate(worldMat);
		if(aabb:ContainsPoint(x, y, z)) then
			return true, mountpoint;
		end
	end
end

-- get mount point by screen position
-- @param x, y: current mouse position in screen coordinate, if nil we will use the current mouse position. 
-- @param maxDiff: default to 30 px, we will not return if mount point and x,y differs too big. 
-- @return mountPoint, diffDistance
function ModelMountPoints:GetMountPointByXY(x, y, maxDiff)
	maxDiff = maxDiff or 30
	if(not x) then
		x, y = Mouse:GetMousePosition()
	end
	local entity = self:GetEntity();
	if(not entity) then
		return 
	end
	local viewport = ViewportManager:GetSceneViewport()
	local left, top, screenWidth, screenHeight = viewport:GetUIRect()
	x = x - left;
	y = y - top;

	local screenPoints = self:GetMountPointsInScreenSpace()
	local closetIndex;
	local closetDistSq = maxDiff * maxDiff;
	
	for i, pt in ipairs(screenPoints) do
		local distSq = ((pt[1] - x) ^ 2) + ((pt[2] - y) ^ 2);
		if (distSq < closetDistSq) then
			closetIndex = i;
			closetDistSq = distSq
		end
	end
	if(closetIndex) then
		if(closetDistSq > 0.01) then
			closetDistSq = math.sqrt(closetDistSq);
		end
		return self:GetMountPoint(closetIndex), closetDistSq;
	end
end