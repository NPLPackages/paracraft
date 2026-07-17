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

function MountPoint:IsAnchor()
	if(self.name and self.name:match("^@")) then
		return true;
	end
end

function MountPoint:SetMatchedAnchor(mp)
	if(self:IsAnchor()) then
		if(self.matchedAnchor) then
			self.matchedAnchor.matchedAnchor = nil;
		end
		if(mp and mp:IsAnchor()) then
			self.matchedAnchor = mp;
			mp.matchedAnchor = self;
		else
			self.matchedAnchor = nil;
		end
	end
end

function MountPoint:GetMatchedAnchor()
	if(self:IsAnchor()) then
		return self.matchedAnchor;
	end
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

function MountPoint:GetEntity()
	return self.parentEntity;
end

function MountPoint:IsTwoAnchorMatched(mp)
	if(self:IsAnchor() and mp:IsAnchor()) then
		if(self:GetEntity() == mp:GetEntity()) then
			return false
		end
		local name1 = self:GetName()
		local name2 = mp:GetName()
		local function nameToTable(name)
			local t = {}
			local n = 0
			local c = name:match("{(.-)}")
			if(c) then
				for k in c:gmatch("%w+") do
					t[k] = true
					n = n + 1
				end
			end
			return t, n
		end
		local bothHasCategory = false
		local categoryMap1, n1 = nameToTable(name1)
		local categoryMap2, n2 = nameToTable(name2)
		if(n1 > 0 and n2 > 0) then
			bothHasCategory = true
		end
		local checkFacing = true
		local hasSameCategory = false
		for c1, _ in pairs(categoryMap1) do
			if((c1 == "up" and categoryMap2["down"]) or (c1 == "down" and categoryMap2["up"])) then
				checkFacing = false
				if(hasSameCategory) then
					break
				end
			elseif(categoryMap2[c1]) then
                if(c1 == "up" or c1 == "down") then
                    return false
                end
				hasSameCategory = true
				if(not checkFacing) then
					break
				end
			end
		end
		if(bothHasCategory and not hasSameCategory) then
			return false
		end
		if(checkFacing) then
			local function formatFacing(facing)
				if(facing >= math.rad(360)) then
					facing = facing - math.rad(360)
				elseif(facing < 0) then
					if(math.abs(facing) < 0.002) then
						facing = 0
					else
						facing = facing + math.rad(360)
					end
				end
				return facing
			end
			local facing1 = formatFacing(self:GetFacing() + self:GetEntity():GetFacing())
			local facing2 = formatFacing(mp:GetFacing() + mp:GetEntity():GetFacing())
			if(math.abs(math.abs(facing1 - facing2) - math.rad(180)) > 0.002) then
				return false
			end
		end
		local function startsWith(str, prefix)
			return str:sub(1, #prefix) == prefix
		end
		local startsWithPlus1 = startsWith(name1, "@+")
		local startsWithPlus2 = startsWith(name2, "@+")
		if(startsWithPlus1 and startsWithPlus2) then
			return false
		end
		local startsWithMinus1 = startsWith(name1, "@-")
		local startsWithMinus2 = startsWith(name2, "@-")
		if(startsWithMinus1 and startsWithMinus2) then
			return false
		end
		return true
	end
end