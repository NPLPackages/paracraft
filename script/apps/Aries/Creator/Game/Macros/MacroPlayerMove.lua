--[[
Title: Macro Button Click Trigger
Author(s): LiXizhi
Date: 2021/1/4
Desc: a trigger for player movement to a scene position

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Macros.lua");
local Macros = commonlib.gettable("MyCompany.Aries.Game.Macros");
-------------------------------------------------------
]]
local mathlib = commonlib.gettable("mathlib");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

Macros.AnimatePlayerMove = true;
Macros.AnimateCameraMove = true;

--@param bx, by, bz: block world position
--@param facing: player facing
function Macros.PlayerMove(bx, by, bz, facing)
	local player = EntityManager.GetPlayer();
	if(player) then
		local nOffset = 0;
		local interval = 0;
		local fromX, fromY, fromZ, fromFacing;
		while(true) do
			nOffset = nOffset - 1;
			local nextMacro = Macros:PeekNextMacro(nOffset)
			if(nextMacro and (nextMacro.name == "Idle" or nextMacro.name == "PlayerMoveTrigger" or nextMacro.name == "CameraMove" or nextMacro.name == "PlayerMove")) then
				if(nextMacro.name == "PlayerMove") then
					local params = nextMacro:GetParams();
					fromX, fromY, fromZ, fromFacing = params[1], params[2], params[3], params[4]
					break;
				elseif(nextMacro.name == "Idle") then
					local dTime = nextMacro:GetParams()[1] or 0;
					interval = interval + dTime;
				end
			else
				break;
			end
		end

		player:SetFocus();
		bx, by, bz = Macros.ComputeBlockPosition(bx, by, bz)

		local isFirstPlayerMove = Macros:FindNextMacro("PlayerMove") == Macros:PeekNextMacro(0);
		if(Macros.AnimatePlayerMove and not isFirstPlayerMove) then
			-- play animation and smoothly move to target location. 
			interval = math.min(interval, 1000);
			if(interval == 0) then
				interval = 500
			end
			local bIsControlled = player:IsControlledExternally()
			if(not bIsControlled) then
				player:SetControlledExternally(true)
			end

			local function RestorePlayerControl_()
				if(not bIsControlled) then
					player:SetControlledExternally(false)
				end
			end
			local x1, y1, z1 = player:GetPosition()
			local x2, y2, z2 = BlockEngine:real_bottom(bx, by, bz);
					
			local callback = {};
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				if(Macros:IsPlaying() and callback.OnFinish) then
					local dist = math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2);
					local speed = 0.3;
					if(dist > speed) then
						local r = speed / dist;
						x1 = x2 * r + x1 * (1-r);
						y1 = y2 * r + y1 * (1-r);
						z1 = z2 * r + z1 * (1-r);
						player:SetPosition(x1, y1, z1)
						timer:Change(30);
					else
						player:SetBlockPos(bx, by, bz)
						if(facing) then
							player:SetFacing(facing);
						end

						RestorePlayerControl_();

						callback.OnFinish();
					end
				else
					RestorePlayerControl_();
				end
			end})
			mytimer:Change(30);
			return callback;
		else
			player:SetBlockPos(bx, by, bz)
			if(facing) then
				player:SetFacing(facing);
			end
			return Macros.Idle(1);
		end
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
	
	local isFirstCameraMove = Macros:FindNextMacro("CameraMove") == Macros:PeekNextMacro(0);
	if(Macros.AnimateCameraMove and not isFirstCameraMove) then
		local player = EntityManager.GetPlayer();
		local bIsControlled = player:IsControlledExternally()
		if(not bIsControlled) then
			player:SetControlledExternally(true)
		end

		local callback = {};
		local x1, y1, z1 = ParaCamera.GetEyePos()
		local x2, y2, z2 = camobjDist, LiftupAngle, CameraRotY;
				
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			if(Macros:IsPlaying() and callback.OnFinish) then
				local fDif = mathlib.ToStandardAngle(y2-y1);
				y1 = y2 - fDif;
				local fDif = mathlib.ToStandardAngle(z2-z1);
				z1 = z2 - fDif;
				
				-- tricky: dY*4 just treats angle as distance
				local dist = math.sqrt((x2 - x1)^2 + ((y2 - y1)*4)^2 + ((z2 - z1)*4)^2);
				local speed = 0.5;
				if(dist > speed) then
					local r = speed / dist;
					x1 = x2 * r + x1 * (1-r);
					y1 = y2 * r + y1 * (1-r);
					z1 = z2 * r + z1 * (1-r);
					ParaCamera.SetEyePos(x1, y1, z1)
					timer:Change(30);
				else
					ParaCamera.SetEyePos(camobjDist, LiftupAngle, CameraRotY)

					local focusEntity = EntityManager.GetFocus();
					if(focusEntity and focusEntity:isa(EntityManager.EntityCamera) and not focusEntity:IsControlledExternally()) then
						focusEntity:FaceTarget(nil)
					end
					if(not bIsControlled) then
						player:SetControlledExternally(false)
					end
					callback.OnFinish();
				end
			else
				if(not bIsControlled) then
					player:SetControlledExternally(false)
				end
			end
		end})
		mytimer:Change(30);
		return callback;
	else
		ParaCamera.SetEyePos(camobjDist, LiftupAngle, CameraRotY)

		local focusEntity = EntityManager.GetFocus();
		if(focusEntity and focusEntity:isa(EntityManager.EntityCamera) and not focusEntity:IsControlledExternally()) then
			focusEntity:FaceTarget(nil)
		end

		return Macros.Idle(1);
	end
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
		
		local focusEntity = EntityManager.GetFocus();
		if(focusEntity and focusEntity:isa(EntityManager.EntityCamera) and not focusEntity:IsControlledExternally()) then
			-- animate this
			if(Macros.AnimateCameraMove) then
				-- play animation and smoothly move to target location. 
				local x1, y1, z1 = focusEntity:GetPosition()
				local x2, y2, z2 = x, y, z;
						
				local callback = {};
				local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
					if(Macros:IsPlaying() and callback.OnFinish) then
						local dist = math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2);
						local speed = 0.3;
						if(dist > speed) then
							local r = speed / dist;
							x1 = x2 * r + x1 * (1-r);
							y1 = y2 * r + y1 * (1-r);
							z1 = z2 * r + z1 * (1-r);
							ParaCamera.SetLookAtPos(x1, y1, z1);
							focusEntity:SetPosition(x1, y1, z1)
							timer:Change(30);
						else
							ParaCamera.SetLookAtPos(x, y, z);
							focusEntity:SetPosition(x, y, z)
							callback.OnFinish();
						end
					end
				
				end})
				mytimer:Change(30);
				return callback;
			else
				ParaCamera.SetLookAtPos(x, y, z);
				focusEntity:SetPosition(x, y, z);
				return Macros.Idle(1);
			end
		else
			ParaCamera.SetLookAtPos(x, y, z);
		end

		return Macros.Idle(1);
	end
end

--@param bx, by, bz: block world position
function Macros.PlayerMoveTrigger(bx, by, bz)

end
