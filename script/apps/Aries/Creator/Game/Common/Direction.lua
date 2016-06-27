--[[
Title: Direction Helper class
Author(s): LiXizhi
Date: 2012/12/1
Desc: 
	0 is x:-1 	1 is x:+1 	2 is z:-1	3 is z:+1
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/math3d.lua");
local math3d = commonlib.gettable("mathlib.math3d");

local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");

-- see also : Direction.GetOffsetBySide
Direction.offsetX = {[0]=-1, 1, 0, 0, 0, 0};
Direction.offsetY = {[0]=0, 0, 0, 0, -1, 1,};
Direction.offsetZ = {[0]=0, 0, -1, 1, 0, 0};

-- mapping to Direction.GetDirection2DFromCamera()'s return value. 
Direction.directions = {[0]="negX", "posX", "negZ", "posZ", };


-- Maps a Direction value (2D) to a Facing value. This is not necessary since direction is same as facing. 
Direction.directionToFacing = { [0]=0, 1, 2, 3};

Direction.directionTo3DFacing = { [0]=0, 3.14, -1.57, 1.57};

-- direction to opposite side(facing)
Direction.directionToOpFacing = { [0]=1, 0, 3, 2, 5, 4};

-- Maps a Facing value (3D) to a Direction value (2D). 
Direction.facingToDirection = { [0]=0, 1, 2, 3, -1,-1};

-- Maps a direction to that opposite of it. */
Direction.rotateOpposite = {[0]=1, 0, 2, 3};

-- Maps a direction to that to the right of it. */
Direction.rotateRight = {[0]=3, 2, 0, 1};

-- Maps a direction to that to the left of it. */
Direction.rotateLeft = {[0]=2, 3, 1, 0};


local facing_to_dir = {
	[0] = 0, [1] = 3, [2] = 1, [3] = 2,
}

function Direction.GetOffsetBySide(side)
	local dx, dy, dz = 0,0,0;
	if(side == 0) then
		dx = -1;
	elseif(side == 1) then
		dx = 1;
	elseif(side == 2) then
		dz = -1;
	elseif(side == 3) then
		dz = 1;
	elseif(side == 4) then
		dy = -1;
	elseif(side == 5) then
		dy = 1;
	end
	return dx, dy, dz;
end
-- convert from facing to closest direction id. 
-- such that 0 to 0, 3.14 to 1, -1.57 to 2, 1.57 to 3
function Direction.GetDirectionFromFacing(facing)
	if(facing <0) then
		facing = facing + 6.28;
	end
	return facing_to_dir[math.floor(facing/1.57+0.5) % 4];
end

-- @param camx,camy,camz: camera eye position  if nil current camera is used
-- @param lookat_x,lookat_y,lookat_z: camera lookat position. if nil current camera lookat is used. 
function Direction.GetDirectionFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local dx, dy, dz = math3d.CameraToWorldSpace(0, 0 ,1, camx,camy,camz, lookat_x,lookat_y,lookat_z);
	if(math.abs(dz) > math.abs(dx)) then
		if(dz>0) then
			return 2;
		else
			return 3;
		end
	else
		if(dx>0) then
			return 1;
		else
			return 4;
		end
	end
end

-- @param camx,camy,camz: camera eye position  if nil current camera is used
-- @param lookat_x,lookat_y,lookat_z: camera lookat position. if nil current camera lookat is used. 
function Direction.GetDirection2DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local dx, dy, dz = math3d.CameraToWorldSpace(0, 0 ,1, camx,camy,camz, lookat_x,lookat_y,lookat_z);
	if(math.abs(dz) > math.abs(dx)) then
		if(dz>0) then
			return 3;
		else
			return 2;
		end
	else
		if(dx>0) then
			return 1;
		else
			return 0;
		end
	end
end

function Direction.GetFacingFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local dx, dy, dz = math3d.CameraToWorldSpace(0, 0 ,1, camx,camy,camz, lookat_x,lookat_y,lookat_z);
	local len = dx^2+dz^2;
	if(len>0.01) then
		len = math.sqrt(len)
		local facing = math.acos(dx/len);
		if(dz>0) then	
			facing = -facing;
		end
		return facing;
	else
		return 0;
	end
end

function Direction.GetFacingFromOffset(dx, dy, dz)
	local len = dx^2+dz^2;
	if(len>0.01) then
		len = math.sqrt(len)
		local facing = math.acos(dx/len);
		if(dz>0) then	
			facing = -facing;
		end
		return facing;
	else
		return 0;
	end
end

-- @return [0,5] based on camera position
function Direction.GetDirection3DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z)
	local dx, dy, dz = math3d.CameraToWorldSpace(0, 0 ,1, camx,camy,camz, lookat_x,lookat_y,lookat_z);
	if(dy>0.4) then
		return 5;
	elseif(dy<-0.8) then
		return 4;
	elseif(math.abs(dz) > math.abs(dx)) then
		if(dz>0) then
			return 3;
		else
			return 2;
		end
	else
		if(dx>0) then
			return 1;
		else
			return 0;
		end
	end
end