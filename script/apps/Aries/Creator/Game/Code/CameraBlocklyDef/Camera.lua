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

function camera.init(codeblock)
	GameLogic.Camera_setTotalTimes(0);
	camera.codeBlock = codeblock
	camera.codeEnv = codeblock:GetCodeEnv();
	if (not camera.origin) then
		local entity = camera.codeBlock:GetEntity();
		if (entity) then
			local x, y, z = entity:GetPosition();
			camera.origin = {x, y+1, z};
		end
	end
	camera.resetPositions();

	codeblock:Connect("codeUnloaded", function()
		camera.close();
	end)
	codeblock:GetEntity():Connect("afterRunThisBlock", function()
		if (GameLogic.Camera_getCurrentTime() > 0) then
			
		else
			camera.resetPositions(true);
			EntityManager.SetFocus(EntityManager.GetPlayer());
		end
	end);
end

function camera.resetPositions()
	local allCameras = GameLogic.Camera_getAllCameras();
	for i = 1, #allCameras do
		if (allCameras[i]) then
			if (GameLogic.positions[i]) then
				allCameras[i]:SetPosition(GameLogic.positions[i][1], GameLogic.positions[i][2], GameLogic.positions[i][3])
			end
			if (GameLogic.rotations[i]) then
				allCameras[i]:SetFacing(GameLogic.rotations[i][1]);
				allCameras[i]:SetRoll(GameLogic.rotations[i][2]);
			end
			allCameras[i]:ShowCameraModel();
		end
	end
end

function camera.InvokeMethod(name, ...)
	return camera.codeEnv[name](...);
end

function camera.setCamera(i, pos)
	local x, y, z = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z);
	GameLogic.positions[i] = {x, y, z};
	local yaw, pitch, roll = tonumber(pos.yaw or 0), tonumber(pos.pitch or 0), tonumber(pos.roll or 0);
	GameLogic.rotations[i] = {yaw, roll, pitch};
	local allCameras = GameLogic.Camera_getAllCameras();
	allCameras[i] = EntityCamera:Create({x = x, y = y, z = z, item_id = block_types.names.TimeSeriesCamera});
	allCameras[i]:SetFacing(yaw);
	allCameras[i]:SetPitch(pitch);
	allCameras[i]:SetRoll(roll);
	allCameras[i]:SetPersistent(false);
	allCameras[i]:Attach();
	allCameras[i]:HideCameraModel();
end

function camera.showWithEditor(entity)
	if (entity) then
		local x, y, z = entity:GetPosition();
		camera.origin = {x, y+1, z};
	end
	camera.createCamera(GameLogic.Camera_getDefaultCameraCount(), entity);
	GameLogic.Camera_setCurrentCameraId(1);
	EntityManager.SetFocus(EntityManager.GetPlayer());
end

function camera.showCamera(index, entity)
	camera.createCamera(index, entity);

	GameLogic.Camera_setCurrentCameraId(index);
	local currentCamera = GameLogic.Camera_getCurrentCamera();
	if (not currentCamera) then
		return;
	end
	currentCamera:SetFocus();
	currentCamera:ShowCameraModel();

	local CameraViewport = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraViewport.lua");
	CameraViewport.ShowPage(index, function(result)
		if (result) then
			local x, y, z = currentCamera:GetPosition();
			GameLogic.positions[index][1] = x;
			GameLogic.positions[index][2] = y;
			GameLogic.positions[index][3] = z;
			local eye_dist, eye_liftup, eye_rot_y = ParaCamera.GetEyePos();
			GameLogic.rotations[index][1] = eye_rot_y;
			GameLogic.rotations[index][2] = eye_liftup;
			GameLogic.eyeDist = eye_dist;
		end
		currentCamera:SetPosition(GameLogic.positions[index][1], GameLogic.positions[index][2], GameLogic.positions[index][3]);
		currentCamera:SetFacing(GameLogic.rotations[index][1]);
		currentCamera:SetRoll(GameLogic.rotations[index][2]);
		camera.setMovieCameraPosition(index, entity, GameLogic.positions[index], GameLogic.rotations[index]);
		EntityManager.SetFocus(EntityManager.GetPlayer());
	end)
end

function camera.createCamera(index, entity)
	if (not camera.origin and entity) then
		local x, y, z = entity:GetPosition();
		camera.origin = {x, y+1, z};
	end
	if (not camera.origin) then
		return;
	end

	local allCameras = GameLogic.Camera_getAllCameras();
	local x, y, z = camera.origin[1], camera.origin[2], camera.origin[3];
	for i = 1, index do
		if (allCameras[i] == nil) then
			GameLogic.positions[i] = {x, y, z};
			GameLogic.rotations[i] = {0, 0, 0};
			allCameras[i] = EntityCamera:Create({x = x, y = y, z = z, item_id = block_types.names.TimeSeriesCamera});
			allCameras[i]:SetPersistent(false);
			allCameras[i]:Attach();

			-- add EntityCamera in movie block
			if (entity) then
				camera.setMovieCameraPosition(i, entity, GameLogic.positions[i], GameLogic.rotations[i]);
				--[[
				local movieEntity = entity:FindNearByMovieEntity();
				if (movieEntity) then
					movieEntity:CreateCamera();
				end
				]]
			end
		end
		allCameras[i]:ShowCameraModel();
	end
end

function camera.setMovieCameraPosition(index, entity, pos, rot)
	function setActorData(actor, x, y, z, eye_dist, eye_rot_y, eye_liftup)
		actor:BeginUpdate();
		actor:AutoAddKey("lookat_x", 0, x);
		actor:AutoAddKey("lookat_y", 0, y);
		actor:AutoAddKey("lookat_z", 0, z);
		actor:AutoAddKey("eye_dist", 0, eye_dist);
		actor:AutoAddKey("eye_rot_y", 0, eye_rot_y);
		actor:AutoAddKey("eye_liftup", 0, eye_liftup);
		actor:AutoAddKey("eye_roll", 0, 0);
		actor:EndUpdate();
	end

	local movieEntity = entity:FindNearByMovieEntity();
	if (movieEntity and movieEntity.inventory) then
		local clip = movieEntity:GetMovieClip();
		local slot = 0;
		for i = 1, movieEntity.inventory:GetSlotCount() do
			local itemStack = movieEntity.inventory:GetItem(i)
			if (itemStack and itemStack.id == block_types.names.TimeSeriesCamera) then
				slot = slot + 1;
				if (slot == index) then
					local actor = clip:GetActorFromItemStack(itemStack, true);
					setActorData(actor, pos[1], pos[2], pos[3], GameLogic.eyeDist, rot[1], rot[2]);
					return;
				end
			end 
		end

		local itemStack = movieEntity:CreateCamera();
		local actor = clip:GetActorFromItemStack(itemStack, true);
		setActorData(actor, pos[1], pos[2], pos[3], GameLogic.eyeDist, rot[1], rot[2]);
	end
end

function camera.getCurrentMovieCamera()
	local index = GameLogic.Camera_getCurrentCameraId();
	local entity = camera.codeBlock:GetEntity();
	if (entity) then
		local movieEntity = entity:FindNearByMovieEntity();
		if (movieEntity and movieEntity.inventory) then
			local clip = movieEntity:GetMovieClip();
			local slot = 0;
			for i = 1, movieEntity.inventory:GetSlotCount() do
				local itemStack = movieEntity.inventory:GetItem(i)
				if (itemStack and itemStack.id == block_types.names.TimeSeriesCamera) then
					slot = slot + 1;
					if (slot == index) then
						local actor = clip:GetActorFromItemStack(itemStack, true);
						return actor;
					end
				end 
			end
		end
	end
end

function camera.use(id)
	if (id:match("#%d+")) then
		local index = tonumber(string.sub(id, 2)) or 1;
		camera.createCamera(index);
		GameLogic.Camera_setCurrentCameraId(index);
		local currentCamera = GameLogic.Camera_getCurrentCamera();
		if (currentCamera) then
			currentCamera:SetFocus();
			--currentCamera:HideCameraModel();
		end
	end
end

function camera.setPosition(x, y, z)
	local actor = GameLogic.Camera_getCurrentCamera();
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
		local yaw, pitch = actor:GetFacing(), actor:GetRoll();
		ParaCamera.SetEyePos(GameLogic.eyeDist, pitch, mathlib.ToStandardAngle(yaw));
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
	local actor = GameLogic.Camera_getCurrentCamera();
	if(actor) then
		local yaw, pitch = actor:GetFacing(), actor:GetRoll();
		local dist2 = math.abs(math.cos(pitch)*dist);
		local totalTimes = GameLogic.Camera_getTotalTimes() + duration;
		local currentTime = GameLogic.Camera_getCurrentTime();
		GameLogic.Camera_setTotalTimes(totalTimes);
		if (currentTime > totalTimes) then
			camera.move(actor, math.cos(yaw)*dist2, math.sin(pitch)*dist, -math.sin(yaw)*dist2);	
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if (usedTime > 0) then
			local r = usedTime / duration;
			camera.move(actor, math.cos(yaw)*dist2* r, math.sin(pitch)*dist* r, -math.sin(yaw)*dist2* r);
			--camera.move(actor, math.cos(yaw)*dist2, math.sin(pitch)*dist, -math.sin(yaw)*dist2, remainTime);
		elseif (currentTime > 0) then
			--
		else
			camera.move(actor, math.cos(yaw)*dist2, math.sin(pitch)*dist, -math.sin(yaw)*dist2, duration);
		end
	end
end

function camera.moveHorizontal(dist, duration)
	local actor = GameLogic.Camera_getCurrentCamera();
	if(actor) then
		local facing = actor:GetFacing();
		local totalTimes = GameLogic.Camera_getTotalTimes() + duration;
		local currentTime = GameLogic.Camera_getCurrentTime();
		GameLogic.Camera_setTotalTimes(totalTimes);
		if (currentTime > totalTimes) then
			camera.move(actor, math.cos(facing)*dist, 0, -math.sin(facing)*dist);
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if (usedTime > 0) then
			local r = usedTime / duration;
			camera.move(actor, math.cos(facing)*dist * r, 0, -math.sin(facing)*dist * r);
			--camera.move(actor, math.cos(facing)*dist, 0, -math.sin(facing)*dist, remainTime);
		elseif (currentTime > 0) then
			--
		else
			camera.move(actor, math.cos(facing)*dist, 0, -math.sin(facing)*dist, duration);
		end
	end
end

function camera.moveVertical(dist, duration)
	local actor = GameLogic.Camera_getCurrentCamera();
	if(actor) then
		local totalTimes = GameLogic.Camera_getTotalTimes() + duration;
		local currentTime = GameLogic.Camera_getCurrentTime();
		GameLogic.Camera_setTotalTimes(totalTimes);
		if (currentTime > totalTimes) then
			camera.move(actor, 0, dist, 0);
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if (usedTime > 0) then
			local r = usedTime / duration;
			camera.move(actor, 0, dist * r, 0);
			--camera.move(actor, 0, dist, 0, remainTime);
		elseif (currentTime > 0) then
			--
		else
			camera.move(actor, 0, dist, 0, duration);
		end
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
		ParaCamera.SetEyePos(GameLogic.eyeDist, tp, mathlib.ToStandardAngle(ty));
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
	local actor = GameLogic.Camera_getCurrentCamera();
	if(actor) then
		local totalTimes = GameLogic.Camera_getTotalTimes() + duration;
		local currentTime = GameLogic.Camera_getCurrentTime();
		GameLogic.Camera_setTotalTimes(totalTimes);
		if (currentTime > totalTimes) then
			camera.rotate(actor, degree, nil, nil);
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if (usedTime > 0) then
			local r = usedTime / duration;
			camera.rotate(actor, degree * r, nil, nil);
			--camera.rotate(actor, degree, nil, nil, remainTime);
		elseif (currentTime > 0) then
			--
		else
			camera.rotate(actor, degree, nil, nil, duration);
		end
	end
end

function camera.rotatePitch(degree, duration)
	local actor = GameLogic.Camera_getCurrentCamera();
	if(actor) then
		local totalTimes = GameLogic.Camera_getTotalTimes() + duration;
		local currentTime = GameLogic.Camera_getCurrentTime();
		GameLogic.Camera_setTotalTimes(totalTimes);
		if (currentTime > totalTimes) then
			camera.rotate(actor, nil, nil, degree);
			return;
		end

		degree = math.min(degree, 90);
		degree = math.max(degree, -90);

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if (usedTime > 0) then
			local r = usedTime / duration;
			camera.rotate(actor, nil, nil, degree * r);
			--camera.rotate(actor, nil, nil, degree, remainTime);
		elseif (currentTime > 0) then
			--
		else
			camera.rotate(actor, nil, nil, degree, duration);
		end
	end
end

function camera.rotateRoll(degree, duration)
	local actor = GameLogic.Camera_getCurrentCamera();
	if(actor) then
		local totalTimes = GameLogic.Camera_getTotalTimes() + duration;
		local currentTime = GameLogic.Camera_getCurrentTime();
		GameLogic.Camera_setTotalTimes(totalTimes);
		if (currentTime > totalTimes) then
			camera.rotate(actor, nil, degree, nil);
			return;
		end

		degree = math.min(degree, 90);
		degree = math.max(degree, -90);

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if (usedTime > 0) then
			local r = usedTime / duration;
			camera.rotate(actor, nil, degree * r, nil);
			--camera.rotate(actor, nil, degree, nil, remainTime);
		elseif (currentTime > 0) then
			--
		else
			camera.rotate(actor, nil, degree, nil, duration);
		end
	end
end

function camera.circle(degree, duration, radius)
	local actor = GameLogic.Camera_getCurrentCamera();
	if(actor) then
		degree = degree + actor:GetFacing()*180/math.pi;

		function moveArc(x, y, z, degree, radius)
			local dx = math.cos(degree*math.pi/180) * radius;
			local dz = -math.sin(degree*math.pi/180) * radius;
			local targetX = x + radius - dx;
			local targetZ = z + dz;
			actor:SetPosition(targetX, y, targetZ);
			actor:SetFacing(mathlib.ToStandardAngle(-degree*math.pi/180));
			ParaCamera.SetEyePos(GameLogic.eyeDist, actor:GetRoll(), mathlib.ToStandardAngle(-degree*math.pi/180));
		end

		function circleImp(degree, radius, duration)
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

		local totalTimes = GameLogic.Camera_getTotalTimes() + duration;
		local currentTime = GameLogic.Camera_getCurrentTime();
		GameLogic.Camera_setTotalTimes(totalTimes);
		if (currentTime > totalTimes) then
			circleImp(degree, radius);
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if (usedTime > 0) then
			local r = usedTime / duration;
			circleImp(degree * r, radius);
			--circleImp(degree, radius, remainTime);
		elseif (currentTime > 0) then
			--
		else
			circleImp(degree, radius, duration);
		end
	end
end

function camera.play(begin_t, end_t)
	local currentCamera = GameLogic.Camera_getCurrentCamera();
	local actor = camera.getCurrentMovieCamera();
	if (currentCamera and actor) then
		if (not end_t) then
			end_t = begin_t;
		end

		function setPos(curTime)
			local x = actor:GetValue("lookat_x", curTime);
			local y = actor:GetValue("lookat_y", curTime);
			local z = actor:GetValue("lookat_z", curTime);
			local eye_dist = actor:GetValue("eye_dist", curTime) or GameLogic.eyeDist;
			local eye_liftup = actor:GetValue("eye_liftup", curTime) or 0;
			local eye_rot_y = actor:GetValue("eye_rot_y", curTime) or 0;
			local eye_roll = actor:GetValue("eye_roll", curTime) or 0;
			currentCamera:SetPosition(x, y, z);
			currentCamera:SetFacing(eye_rot_y);
			currentCamera:SetRoll(eye_liftup);
			currentCamera:SetPitch(eye_roll);
			ParaCamera.SetEyePos(eye_dist, eye_liftup, eye_rot_y);
		end

		local duration = (end_t - begin_t) / 1000;
		local totalTimes = GameLogic.Camera_getTotalTimes() + duration;
		local currentTime = GameLogic.Camera_getCurrentTime();
		GameLogic.Camera_setTotalTimes(totalTimes);
		if (currentTime > totalTimes) then
			setPos(end_t);
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if (usedTime > 0) then
			setPos(begin_t + usedTime * 1000);
			--begin_t = begin_t + usedTime * 1000;
			return;
		elseif (currentTime > 0) then
			return;
		else
		end

		local startTime = commonlib.TimerManager.GetCurrentTime();
		local endTime = startTime + end_t - begin_t;
		local stepTime = camera.codeBlock:GetDefaultTick();
		local current = 0;
		while(true) do
			local curTime = commonlib.TimerManager.GetCurrentTime();
			if((curTime+stepTime) >= endTime) then
				setPos(endTime - startTime + begin_t);
				break;
			end

			setPos(curTime - startTime + begin_t);
			camera.InvokeMethod("wait", camera.codeBlock:GetDefaultTick());
		end
	end
end

function camera.follow()
end

function camera.moveTo()
end

function camera.lockLookat()
end

function camera.wait(seconds)
	local totalTimes = GameLogic.Camera_getTotalTimes() + seconds;
	local currentTime = GameLogic.Camera_getCurrentTime();
	GameLogic.Camera_setTotalTimes(totalTimes);
	if (currentTime > totalTimes) then
		return;
	end

	camera.InvokeMethod("wait", seconds);
end

function camera.stop()
end

function camera.close()
	local allCameras = GameLogic.Camera_getAllCameras();
	for i = 1, #allCameras do
		if (allCameras[i]) then
			allCameras[i]:HideCameraModel();
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

