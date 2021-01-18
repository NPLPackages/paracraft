--[[
Title: Macro Button Click Trigger
Author(s): LiXizhi
Date: 2021/1/4
Desc: a trigger for player movement to a scene position

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Macro.lua");
local Macro = commonlib.gettable("MyCompany.Aries.Game.Macro");
-------------------------------------------------------
]]
-------------------------------------
-- single Macro base
-------------------------------------
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

--@param bx, by, bz: block world position
--@param facing: player facing
function Macros.PlayerMove(bx, by, bz, facing)
	-- TODO: use animation?
	local player = EntityManager.GetPlayer();
	if(player) then
		bx, by, bz = Macros.ComputeBlockPosition(bx, by, bz)
		player:SetBlockPos(bx, by, bz)
		if(facing) then
			player:SetFacing(facing);
		end
		return Macros.Idle(1);
	end
end

function Macros.FocusPlayer(x, y, z)
	local player = EntityManager.GetPlayer();
	if(player) then
		player:SetFocus();
		local obj = player:GetInnerObject();
		if(obj and obj.ToCharacter) then
			x, y, z = Macros.ComputePosition(x, y, z)
			obj:SetPosition(x, y, z);
			obj:ToCharacter():SetFocus();
		end
	end
end

-- @param camobjDist, LiftupAngle, CameraRotY: if nil, we will restore the last CameraMove macro's values
function Macros.CameraMove(camobjDist, LiftupAngle, CameraRotY)
	local lastCamera = Macros:GetLastCameraParams();
	if(not camobjDist) then
		camobjDist, LiftupAngle, CameraRotY = lastCamera.camobjDist, lastCamera.LiftupAngle, lastCamera.CameraRotY;
	else
		lastCamera.camobjDist, lastCamera.LiftupAngle, lastCamera.CameraRotY = camobjDist, LiftupAngle, CameraRotY
	end
	-- TODO: use animation?
	ParaCamera.SetEyePos(camobjDist, LiftupAngle, CameraRotY)

	local focusEntity = EntityManager.GetFocus();
	if(focusEntity and focusEntity:isa(EntityManager.EntityCamera) and not focusEntity:IsControlledExternally()) then
		focusEntity:FaceTarget(nil)
	end

	return Macros.Idle(1);
end

-- @param x,y,z: camera look at position. if nil it will default to last camera lookat call. 
function Macros.CameraLookat(x, y, z)
	local lastCamera = Macros:GetLastCameraParams();
	if(not x) then
		x, y, z = lastCamera.lookatX, lastCamera.lookatY, lastCamera.lookatZ
	else
		lastCamera.lookatX, lastCamera.lookatY, lastCamera.lookatZ = x, y, z;
	end
	if(x) then
		x, y, z = Macros.ComputePosition(x, y, z)
		ParaCamera.SetLookAtPos(x, y, z);

		local focusEntity = EntityManager.GetFocus();
		if(focusEntity and focusEntity:isa(EntityManager.EntityCamera) and not focusEntity:IsControlledExternally()) then
			focusEntity:SetPosition(x, y, z);
		end

		return Macros.Idle(1);
	end
end

--@param bx, by, bz: block world position
function Macros.PlayerMoveTrigger(bx, by, bz)

end
