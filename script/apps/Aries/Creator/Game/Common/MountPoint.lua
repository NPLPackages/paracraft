--[[
Title: Model mount point
Author(s): LiXizhi
Date: 2021/12/5
Desc: a single mount point used by ModelMountPoints

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/MountPoint.lua");
local MountPoint = commonlib.gettable("MyCompany.Aries.Game.Common.MountPoint");
local mp = MountPoint:new({})
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local MountPoint = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.MountPoint"));

function MountPoint:ctor()
	if(self.x and self.y and self.z) then
		
	else
		self.x = 0;
		self.y = 0;
		self.z = 0;
	end
	self.facing = self.facing or 0;
	self.dx = self.dx or 0.25;
	self.dy = self.dy or 0.25;
	self.dz = self.dz or 0.25;
end

function MountPoint:GetName()
	return self.name or ""
end

function MountPoint:Clone()
	return MountPoint:new(commonlib.copy(self));
end

-- @return vector3d {x,y,z} of type array
function MountPoint:GetPivot()
	return vector3d:new_from_pool(self.x, self.y, self.z)
end

function MountPoint:SetPivot(pivot)
	self.x, self.y, self.z = pivot[1], pivot[2], pivot[3]
end

function MountPoint:GetBottomCenter()
	return self.x, self.y, self.z
end

function MountPoint:SetBottomCenter(x, y, z)
	self.x, self.y, self.z = x, y, z
end

--@return dx, dy, dz
function MountPoint:GetAABBSize()
	return self.dx, self.dy, self.dz
end

function MountPoint:SetAABBSize(dx, dy, dz)
	self.dx, self.dy, self.dz = dx, dy, dz
end

function MountPoint:GetDisplayName()
	return self.name or "mount"
end

function MountPoint:IsSelected()
	return self.isSelected;
end

function MountPoint:SetSelected(bValue)
	self.isSelected = bValue;
end

function MountPoint:GetIndex()
	return self.index or 1;
end

-- return "trans", "rot", "scale"
function MountPoint:GetPreferredHandleMode()
	return self.handleMode or "trans";
end

-- @param handleMode: "trans", "rot", "scale" or nil. default to "trans"
function MountPoint:SetPreferredHandleMode(handleMode)
	self.handleMode = handleMode
end

-- default to only allow rotation around "y" axis, we may also support "xyz" in future
function MountPoint:GetRotationAxis()
	return "y"
end

function MountPoint:GetFacing()
	return self.facing or 0;
end

function MountPoint:SetFacing(facing)
	self.facing = facing;
end

function MountPoint:SaveLastRotation()
	self.lastFacing = self.facing or 0;
end

function MountPoint:GetLastRotation()
	return self.lastFacing;
end

function MountPoint:SaveLastTranslation()
	self.lastX, self.lastY, self.lastZ = self.x, self.y, self.z;
end

function MountPoint:GetLastTranslation()
	return self.lastX, self.lastY, self.lastZ;
end

function MountPoint:SaveLastAABB()
	self.lastDX, self.lastDY, self.lastDZ = self.dx, self.dy, self.dz;
end

function MountPoint:GetLastAABB()
	return self.lastDX, self.lastDY, self.lastDZ
end