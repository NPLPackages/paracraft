--[[
Title: 
Author(s): chenjinxian
Date: 
Desc: 
use the lib:
-------------------------------------------------------
local camera = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/camera.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCamera.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EntityCamera = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local camera = NPL.export()

camera.Cameras = {};
camera.positions = {};
camera.currentCamera = nil;
function camera.init(codeblock)
	camera.codeBlock = codeblock
	camera.codeEnv = codeblock:GetCodeEnv();

	codeblock:Connect("codeUnloaded", function()
		camera.close();
	end)
	codeblock:GetEntity():Connect("afterRunThisBlock", function()
		camera.resetPositions();
		camera.showWithEditor();
	end);
end

function camera.resetPositions()
	for i = 1, #camera.Cameras do
		if (camera.positions[i] and camera.Cameras[i]) then
			camera.Cameras[i]:SetPosition(camera.positions[i][1], camera.positions[i][2], camera.positions[i][3])
		end
	end
end

function camera.InvokeMethod(name, ...)
	return camera.codeEnv[name](...);
end

function camera.getCurrentCamera()
	if (camera.currentCamera == nil) then
		camera.use("#1");
	end
	return camera.currentCamera;
end

function camera.getCameras()
	return camera.Cameras;
end

function camera.setCamera(i, pos)
	local x, y, z = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z);
	camera.positions[i] = {x, y, z};
	camera.Cameras[i] = EntityCamera:Create({x = x, y = y, z = z, item_id = block_types.names.TimeSeriesCamera});
	camera.Cameras[i]:SetPersistent(false);
	camera.Cameras[i]:Attach();
	camera.Cameras[i]:HideCameraModel();
end

function camera.showWithEditor(entity)
	if (entity) then
		local x, y, z = entity:GetPosition();
		camera.origin = {x, y+1, z};
	end
	camera.createCamera(4);
	EntityManager.SetFocus(EntityManager.GetPlayer());
end

function camera.showCamera(index)
	camera.createCamera(index);
	camera.currentCamera = camera.Cameras[index];
	camera.currentCamera:SetFocus();
	camera.currentCamera:ShowCameraModel();
	local CameraViewport = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraViewport.lua");
	CameraViewport.ShowPage(index, function(result)
		if (result) then
			local x, y, z = camera.currentCamera:GetPosition();
			camera.positions[index][1] = x;
			camera.positions[index][2] = y;
			camera.positions[index][3] = z;
		else
			camera.currentCamera:SetPosition(camera.positions[index][1], camera.positions[index][2], camera.positions[index][3]);
		end
	end)
end

function camera.createCamera(index)
	local x, y, z = camera.origin[1], camera.origin[2], camera.origin[3];
	for i = 1, index do
		if (camera.Cameras[i] == nil) then
			camera.positions[i] = {x, y, z};
			camera.Cameras[i] = EntityCamera:Create({x = x, y = y, z = z, item_id = block_types.names.TimeSeriesCamera});
			camera.Cameras[i]:SetPersistent(false);
			camera.Cameras[i]:Attach();
		end
		camera.Cameras[i]:ShowCameraModel();
	end
end

function camera.use(id)
	if (id:match("#%d+")) then
		local index = tonumber(string.sub(id, 2)) or 1;
		camera.createCamera(index);
		camera.currentCamera = camera.Cameras[index];
		camera.currentCamera:SetFocus();
		camera.currentCamera:HideCameraModel();
	end
end

function camera.setPosition(x, y, z)
	local actor = camera.currentCamera;
	if (actor) then
		actor:SetBlockPos(x, y, z);
	end
end

function camera.move(actor, dx, dy, dz, duration)
	if(not dz) then
		dz = dy;
		dy = nil;
	end

	local x,y,z = actor:GetPosition();
	dx = (dx or 0)*BlockEngine.blocksize
	dy = (dy or 0)*BlockEngine.blocksize
	dz = (dz or 0)*BlockEngine.blocksize
	local targetX = x + dx;
	local targetY = y + dy;
	local targetZ = z + dz;
	if(not duration) then
		actor:SetPosition(targetX,targetY,targetZ);
		camera.InvokeMethod("wait", camera.codeBlock:GetDefaultTick());
	elseif(duration == 0) then
		actor:SetPosition(targetX,targetY,targetZ);
	else
		local startTime = commonlib.TimerManager.GetCurrentTime()/1000
		local endTime = startTime + duration;
		local stepTime = camera.codeBlock:GetDefaultTick();
		while(true) do
			local curTime = commonlib.TimerManager.GetCurrentTime()/1000;
			local timeLeft = endTime - curTime;
			local shouldBe;
			if((curTime+stepTime) >= endTime) then
				shouldBe = 1
			else
				shouldBe = (curTime+stepTime - startTime) / duration;
			end
			local cur_x,cur_y,cur_z = actor:GetPosition();
			if(cur_x) then
				local sx, sy, sz = x + shouldBe*dx, y + shouldBe*dy, z + shouldBe*dz
				local dx1, dy1, dz1 = sx - cur_x, sy - cur_y, sz - cur_z;
				camera.move(actor, dx1*BlockEngine.blocksize_inverse,dy1*BlockEngine.blocksize_inverse,dz1*BlockEngine.blocksize_inverse)
				if(shouldBe == 1) then
					break;
				end
			else
				break;
			end
		end
	end
end

function camera.moveForward(dist, duration)
	local actor = camera.getCurrentCamera();
	if(actor) then
		local yaw, pitch = actor:GetFacing(), actor:GetRoll();
		local dist2 = math.abs(math.cos(pitch)*dist);
		camera.move(actor, math.cos(yaw)*dist2, math.sin(pitch)*dist, -math.sin(yaw)*dist2, duration);
	end
end

function camera.moveHorizontal(dist, duration)
	local actor = camera.getCurrentCamera();
	if(actor) then
		local facing = actor:GetFacing();
		camera.move(actor, math.cos(facing)*dist, 0, -math.sin(facing)*dist, duration);
	end
end

function camera.moveVertical(dist, duration)
	local actor = camera.getCurrentCamera();
	if(actor) then
		camera.move(actor, 0, dist, 0, duration);
	end
end

function camera.rotate(actor, degree, pitch, roll, duration)
	degree = degree or 0;
	pitch = pitch or 0;
	roll = roll or 0;
	local y, p, r = actor:GetFacing(), actor:GetRoll(), actor:GetPitch();
	local ty, tp, tr = y + degree*math.pi/180, p + pitch*math.pi/180, r + roll*math.pi/180;
	if(not duration) then
		actor:SetFacing(mathlib.ToStandardAngle(ty));
		actor:SetPitch(tp);
		actor:SetRoll(tr);
		camera.InvokeMethod("wait", camera.codeBlock:GetDefaultTick());
	elseif(duration == 0) then
		actor:SetFacing(mathlib.ToStandardAngle(ty));
		actor:SetPitch(tp);
		actor:SetRoll(tr);
	else
		local startTime = commonlib.TimerManager.GetCurrentTime()/1000
		local endTime = startTime + duration;
		local stepTime = camera.codeBlock:GetDefaultTick();
		while(true) do
			local curTime = commonlib.TimerManager.GetCurrentTime()/1000;
			local timeLeft = endTime - curTime;
			local shouldBe;
			if((curTime+stepTime) >= endTime) then
				shouldBe = 1
			else
				shouldBe = (curTime+stepTime - startTime) / duration;
			end
			local cur_y, cur_p, cur_roll = actor:GetFacing(), actor:GetRoll(), actor:GetPitch();
			if(cur_y and cur_p and cur_roll) then
				local sx, sy, sz = y + shouldBe*degree*math.pi/180, p + shouldBe*pitch*math.pi/180, r + shouldBe*roll*math.pi/180;
				local dx1, dy1, dz1 = sx - cur_y, sy - cur_p, sz - cur_roll;
				camera.rotate(actor, dx1*180/math.pi, dy1*180/math.pi, dz1*180/math.pi)
				if(shouldBe == 1) then
					break;
				end
			else
				break;
			end
		end
	end
end

function camera.rotateYaw(degree, duration)
	local actor = camera.getCurrentCamera();
	if(actor) then
		camera.rotate(actor, degree, nil, nil, duration);
	end
end

function camera.rotatePitch(degree, duration)
	local actor = camera.getCurrentCamera();
	if(actor) then
		degree = math.min(degree, 90);
		degree = math.max(degree, -90);
		camera.rotate(actor, nil, nil, degree, duration);
	end
end

function camera.rotateRoll(degree, duration)
	local actor = camera.getCurrentCamera();
	if(actor) then
		degree = math.min(degree, 90);
		degree = math.max(degree, -90);
		camera.rotate(actor, nil, degree, nil, duration);
	end
end

function camera.circle(degree, radius, duration)
	local actor = camera.getCurrentCamera();
	if(actor) then
		function moveArc(x, y, z, degree, radius)
			local dx = math.cos(degree*math.pi/180) * radius;
			local dz = -math.sin(degree*math.pi/180) * radius;
			local targetX = x + radius - dx;
			local targetZ = z + dz;
			actor:SetPosition(targetX, y, targetZ);
			actor:SetFacing(mathlib.ToStandardAngle(-degree*math.pi/180));
		end

		local x, y, z = actor:GetPosition();
		if (not duration) then
			moveArc(x, y, z, degree, radius);
			camera.InvokeMethod("wait", camera.codeBlock:GetDefaultTick());
		elseif (duration == 0) then
			moveArc(x, y, z, degree, radius);
		else
			local startTime = commonlib.TimerManager.GetCurrentTime()/1000
			local endTime = startTime + duration;
			local stepTime = camera.codeBlock:GetDefaultTick();
			local current = 0;
			while(true) do
				local curTime = commonlib.TimerManager.GetCurrentTime()/1000;
				local timeLeft = endTime - curTime;
				local shouldBe;
				if((curTime+stepTime) >= endTime) then
					shouldBe = 1
				else
					shouldBe = (curTime+stepTime - startTime) / duration;
				end

				moveArc(x, y, z, degree *shouldBe, radius);
				camera.InvokeMethod("wait", camera.codeBlock:GetDefaultTick());

				if(shouldBe == 1) then
					break;
				end
			end
		end
	end
end

function camera.play()
end

function camera.follow()
end

function camera.moveTo()
end

function camera.lockLookat()
end

function camera.wait(seconds)
	camera.InvokeMethod("wait", seconds);
end

function camera.stop()
end

function camera.close()
	for i = 1, #camera.Cameras do
		if (camera.Cameras[i]) then
			camera.Cameras[i]:HideCameraModel();
		end
	end
	EntityManager.SetFocus(EntityManager.GetPlayer());
end

function camera.reopen()
	local entity = camera.codeBlock:GetEntity();
	if (entity) then
		entity:OpenEditor("entity", entity);
		camera.showWithEditor(entity);
	end
end

