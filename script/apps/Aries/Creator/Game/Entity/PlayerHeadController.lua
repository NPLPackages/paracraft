--[[
Title: For controlling the player's heading 
Author(s): LiXizhi
Date: 2014/4/10
Desc: For controlling the player's heading. This class is actually part of the class of EntityPlayer and EntityMovable. 
For clarity, I put them into a separate file. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerHeadController.lua");
local PlayerHeadController = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerHeadController");
PlayerHeadController.FaceTarget(entity, x,y,z)
PlayerHeadController.DisableFaceTarget(entity);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/mathlib.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local mathlib = commonlib.gettable("mathlib");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")


local PlayerHeadController = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerHeadController");

local head_turning_max_speed = 31.4;
-- between (0,1), how much the player's head can look up.  1 is full. 
local lookup_angle_percent = 0.8;

-- between (0,1), how much the player's head can look down.  1 is full. 
local lookdown_angle_percent = 0.4;

-- max head turning angle, if bigger than this value, we will adjust the facing instead of head facing. 
local max_turn_angle = 1.2;

-- face the current player to the given target. 
-- @param entity: the entity to be animated. 
-- @param x, y, z: if nil, player faces front. 
-- @param isAngle: if x, y, z is angle. 
function PlayerHeadController.FaceTarget(entity, x,y,z, isAngle)
	if(not entity or MovieManager:IsCurrentActorPlayingback()) then
		return;
	end
	local last_face_target = PlayerHeadController.GetLastFacingTarget(entity);

	local player = entity:GetInnerObject();
	
	if(not player or player:GetField("IsControlledExternally", false)) then
		return;
	end

	if(not x) then
		PlayerHeadController.SmoothAnimationFacing(entity, 0, nil, 0);
		return;
	end
	entity.head_turning_speed = entity.head_turning_speed or head_turning_max_speed;

	-- disable facing target when player is running. I.e. face tracking is enabled for walking(sneaking) and standing. 
	local disable_facing;
	if(not entity:IsBiped()) then
		-- for haqi characters.
		if(not player:IsStanding()) then
			if(player:GetField("LastSpeed",0) == 0) then
				player:SetField("HeadTurningAngle", 0);
				player:SetField("HeadUpdownAngle", 0);
				entity.rotationHeadPitch = 0;
				entity.rotationHeadYaw = 0;
			else
				entity.head_turning_speed = GameLogic.options.head_turning_max_speed;
				--PlayerHeadController.SmoothAnimationFacing(entity, nil, nil, nil);
				--player:SetField("HeadTurningAngle", 0);
				--player:SetField("HeadUpdownAngle", 0);
			end
			return
		end
	else
		-- for paracraft characters
		if(player:GetField("AnimID", 0)~=4) then
			if(not player:IsStanding()  or player:GetField("LastSpeed",0) ~= 0) then
				entity.head_turning_speed = GameLogic.options.head_turning_max_speed;
				PlayerHeadController.SmoothAnimationFacing(entity, nil, nil, nil);
				return;
			end
		else
			-- if player is walking or sneaking (AnimID 4)
			disable_facing = true;
		end
	end
	if(last_face_target.x == x and last_face_target.y == y and last_face_target.z == z) then
		return;
	else
		last_face_target.x, last_face_target.y, last_face_target.z = x, y, z;
	end

	local updown_angle, turning_angle = 0, 0;
	if(isAngle) then
		updown_angle, turning_angle = y,z;
	else
		local src_x, src_y, src_z = player:GetPosition();
		updown_angle, turning_angle = PlayerHeadController.GetTurningAngleFromPos(entity, src_x, src_y, src_z, x, y, z);
	end
	
	if(updown_angle and turning_angle) then
		-- turning angle plus facing
		local facing = player:GetFacing();
		local delta_angle = mathlib.ToStandardAngle(turning_angle - facing);
	
		local new_facing;
		if(not disable_facing) then
			if(delta_angle > max_turn_angle) then
				new_facing = (facing + delta_angle - max_turn_angle);
				delta_angle = max_turn_angle;
			elseif(delta_angle < -max_turn_angle) then
				new_facing = (facing + delta_angle + max_turn_angle);
				delta_angle = -max_turn_angle;
			end
		end
		PlayerHeadController.SmoothAnimationFacing(entity, updown_angle, new_facing, delta_angle);
	end
end

-- private function
function PlayerHeadController.GetTurningAngleFromPos(entity, src_x, src_y, src_z, x, y, z)
	local updown_angle, turning_angle = 0, 0;
	
	src_y = src_y + 1.2;

	local diff_x = x - src_x;
	local diff_z = src_z - z;
	
	local dist = diff_x^2 + diff_z^2;
	if(dist > 0.01) then
		dist = math.sqrt(dist);
	else
		return;
	end
	diff_x = diff_x/dist;
	diff_z = diff_z/dist;

	if(diff_z > 1) then	diff_z = 1; end
	if(diff_z < -1) then	diff_z = -1; end

	if (diff_x>0) then
		turning_angle = math.asin(diff_z);
		if(turning_angle < 0) then
			turning_angle = 2*3.14159265359 + turning_angle;
		end
	else
		turning_angle = 3.14159265359 - math.asin(diff_z);
	end

	-- up down angle
	updown_angle = math.atan((y - src_y) / dist);
	if(updown_angle > 0) then
		updown_angle = updown_angle * (entity.lookup_angle_percent or lookup_angle_percent);
	else
		updown_angle = updown_angle * (entity.lookdown_angle_percent or lookdown_angle_percent);
	end
	return updown_angle, turning_angle;
end

-- call this to disable facing target
function PlayerHeadController.DisableFaceTarget(entity)
	if(entity and entity.facing_timer) then
		entity.facing_timer:Change(nil);
	end
end

function PlayerHeadController.GetLastFacingTarget(entity)
	entity.last_face_target = entity.last_face_target or {};
	return entity.last_face_target;
end

-- smoothly animate head turning for current player. 
function PlayerHeadController.SmoothAnimationFacing(entity, head_updown_angle, facing, head_turning_angle)
	local last_face_target = PlayerHeadController.GetLastFacingTarget(entity);
	last_face_target.target_head_updown_angle = head_updown_angle;
	last_face_target.target_facing = facing;
	last_face_target.target_head_turning_angle = head_turning_angle;
	
	if(not entity.facing_timer) then
		entity.facing_timer = commonlib.Timer:new({callbackFunc = function(timer)
			PlayerHeadController.OnFrameMoveTimer(entity, timer)
		end})
	end
	-- animate as fast as possible
	entity.facing_timer:Change(0, 30);
end

-- called when required to face a target. 
function PlayerHeadController.OnFrameMoveTimer(entity, timer)
	local last_face_target = PlayerHeadController.GetLastFacingTarget(entity);
	local delta_time = timer:GetDelta() / 1000;
	entity.head_turning_speed = entity.head_turning_speed or head_turning_max_speed;
	local delta_angle = delta_time * entity.head_turning_speed; 
	local bIsStillTurning;

	local player = entity:GetInnerObject();
	if(player and not player:GetField("IsControlledExternally", false)) then 
		
		if(player:GetField("AnimID", 0)==4 or (player:IsStanding() and player:GetField("LastSpeed",0) == 0)) then
			entity.head_turning_speed = mathlib.SmoothMoveFloat(entity.head_turning_speed, head_turning_max_speed,  delta_time * head_turning_max_speed);
		end
			
		if(last_face_target.target_head_updown_angle) then
			local last_value = player:GetField("HeadUpdownAngle", 0);
			local value, bReached = mathlib.SmoothMoveAngle(last_value, last_face_target.target_head_updown_angle, delta_angle);
			if(bReached) then
				last_face_target.target_head_updown_angle = nil;
			else
				bIsStillTurning = true;
			end
			player:SetField("HeadUpdownAngle", value);
			entity.rotationHeadPitch = value;
		end

		if(last_face_target.target_facing) then
			local last_value = player:GetFacing();
			local value, bReached = mathlib.SmoothMoveAngle(last_value, last_face_target.target_facing, delta_angle);
			if(bReached) then
				last_face_target.target_facing = nil;
			else
				bIsStillTurning = true;
			end
			entity:SetFacing(value);
		end

		if(last_face_target.target_head_turning_angle) then
			local last_value = player:GetField("HeadTurningAngle", 0);
			local value, bReached = mathlib.SmoothMoveAngle(last_value, last_face_target.target_head_turning_angle, delta_angle);
			if(bReached) then
				last_face_target.target_head_turning_angle = nil;
			else
				bIsStillTurning = true;
			end
			player:SetField("HeadTurningAngle", value);
			entity.rotationHeadYaw = value;
		end
	end

	if(not bIsStillTurning) then
		timer:Change(nil);
	end
end