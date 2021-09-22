--[[
Title: Camera functions
Author(s): chenjinxian, LiXizhi
Date: 2021.8.1
Desc: camera functions are mostly run in code environment. 

use the lib:
-------------------------------------------------------
local Camera = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/Camera.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCamera.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EntityCamera = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Cameras = NPL.load("./Cameras.lua");
local Camera = NPL.export()


-- @param entity: if nil, it is the currently running code block. 
local function cameraTryInit(entity)
	local codeblock;
	if(entity) then
		codeblock = entity:GetCodeBlock();
	else
		codeblock = GameLogic.GetCodeGlobal():GetCurrentCodeBlock();
	end
	if(Camera.codeBlock ~= codeblock and codeblock) then
		Camera.init(codeblock)
		local currentCamera = Cameras.getCurrentCamera();
		if(not currentCamera) then
			Camera.use(1, entity)
		end
	end
end

function Camera.init(codeblock)
	if(Camera.isIniting) then
		return
	end
	Camera.isIniting = true
	Camera.codeBlock = codeblock
	Camera.codeEnv = codeblock:GetCodeEnv();
	Cameras.clear()
	local entity = Camera.codeBlock:GetEntity();
	
	codeblock:Connect("codeUnloaded", function()
		if(Camera.codeBlock == codeblock) then
			Camera.close();
		end
	end)

	codeblock:GetEntity():Connect("beforeRemoved", function()
		if(Camera.codeBlock == codeblock) then
			Camera.close();
		end
	end);
	codeblock:GetEntity():Connect("afterRunThisBlock", function()
		if(Cameras.getTargetTime() >= 0) then
			
		else
			EntityManager.SetFocus(EntityManager.GetPlayer());
		end
	end);
	Camera.isIniting = false;
end

function Camera.InvokeMethod(name, ...)
	return Camera.codeEnv[name](...);
end

-- @param pos: table of {x, y, z, yaw, pitch, roll}
function Camera.setCamera(i, pos)
	cameraTryInit();
	local x, y, z = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z);
	local yaw, pitch, roll = tonumber(pos.yaw or 0), tonumber(pos.pitch or 0), tonumber(pos.roll or 0);
	local allCameras = Cameras.getAllCameras();
	allCameras[i] = allCameras[i] or EntityCamera:Create({x = x, y = y, z = z, item_id = block_types.names.TimeSeriesCamera});
	allCameras[i]:SetFacing(yaw);
	allCameras[i]:SetEyeLifeup(pitch);
	allCameras[i]:SetEyeRoll(roll);
	allCameras[i]:SetPersistent(false);
	allCameras[i]:Attach();
	allCameras[i]:HideCameraModel();
end

function Camera.showWithEditor(entity)
	Cameras.clear()
	cameraTryInit(entity);
	Cameras.setCurrentCameraId(1);
	Camera.createCamera(Cameras.getDefaultCameraCount(), entity);
	EntityManager.SetFocus(EntityManager.GetPlayer());
end

-- called from UI click event when user wants to define the initial position of the camera in movie block
function Camera.showCamera(index, entity)
	cameraTryInit(entity);
	Cameras.setCurrentCameraId(index);
	Camera.createCamera(index, entity);
	
	local currentCamera = Cameras.getCurrentCamera();
	if(not currentCamera) then
		return;
	end
	currentCamera:SetFocus();
	currentCamera:PlayToTime()
	currentCamera:ShowCameraModel();

	local CameraViewport = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraViewport.lua");
	currentCamera:Connect("beforeDestroyed", CameraViewport, CameraViewport.OnClose, "UniqueConnection");

	CameraViewport.ShowPage(index, function(result)
		if(result) then
			local x, y, z = currentCamera:GetPosition();
			local eye_dist, eye_liftup, eye_rot_y = ParaCamera.GetEyePos();
			Cameras.eyeDist = eye_dist;
			Camera.setMovieCameraPosition(index, entity, {x, y, z}, {eye_dist, eye_liftup, eye_rot_y});
			local myItemStack = Camera.CreateGetCameraItemStackInMovieblock(index, entity);
			if(myItemStack) then
				-- force rebind, since there may be edit
				currentCamera:BindToItemStack(myItemStack)
				currentCamera:PlayToTime(0)
			end
		end
		
		EntityManager.SetFocus(EntityManager.GetPlayer());
	end)
end

-- this is a private function: create if not exist
-- @param index: camera index like [1, 8]
-- @param entity: code entity
function Camera.CreateGetCameraItemStackInMovieblock(index, entity)
	local movieEntity = entity:FindNearByMovieEntity();
	local myItemStack;
	if(movieEntity and movieEntity.inventory) then
		local clip = movieEntity:GetMovieClip();
		local slot = 0;
		for j = 1, movieEntity.inventory:GetSlotCount() do
			local itemStack = movieEntity.inventory:GetItem(j)
			if(itemStack and itemStack.id == block_types.names.TimeSeriesCamera) then
				slot = slot + 1;
				if(slot == index) then
					myItemStack = itemStack;
					break;
				end
			end 
		end
		if(not myItemStack) then
			-- add EntityCamera in movie block
			myItemStack = movieEntity:CreateCamera()
		end
		return myItemStack;
	end
end

function Camera.createCamera(index, entity)
	cameraTryInit(entity);
	entity = entity or Camera.codeBlock:GetEntity();

	if(entity) then
		local x, y, z = entity:GetPosition();
		Camera.origin = {x, y+1, z};
	end
	if(not Camera.origin) then
		return;
	end

	local allCameras = Cameras.getAllCameras();
	local x, y, z = Camera.origin[1], Camera.origin[2], Camera.origin[3];
	for i = 1, index do
		if(allCameras[i] == nil) then
			allCameras[i] = EntityCamera:Create({x = x, y = y, z = z, item_id = block_types.names.TimeSeriesCamera});
			allCameras[i]:SetPersistent(false);
			allCameras[i]:Attach();

			local movieEntity = entity:FindNearByMovieEntity();
			local myItemStack = Camera.CreateGetCameraItemStackInMovieblock(i, entity);
			if(myItemStack) then
				allCameras[i]:BindToItemStack(myItemStack)
				allCameras[i]:PlayToTime(0)
			end
		end
	end
end

-- @param pos: array of {x, y, z}
-- @param rot: array of {eye_dist, eye_liftup, eye_rot_y}
function Camera.setMovieCameraPosition(index, entity, pos, rot)
	cameraTryInit(entity);
	local function setActorData(actor, x, y, z, eye_dist, eye_liftup, eye_rot_y)
		actor:BeginUpdate();
		local time = 0;
		actor:AddKeyFrameByName("lookat_x", time, x);
		actor:AddKeyFrameByName("lookat_y", time, y);
		actor:AddKeyFrameByName("lookat_z", time, z);
		actor:AddKeyFrameByName("eye_dist", time, eye_dist);
		actor:AddKeyFrameByName("eye_rot_y", time, eye_rot_y);
		actor:AddKeyFrameByName("eye_liftup", time, eye_liftup);
		actor:AddKeyFrameByName("eye_roll", time, 0);
		actor:EndUpdate();
	end

	local movieEntity = entity:FindNearByMovieEntity();
	if(movieEntity and movieEntity.inventory) then
		local clip = movieEntity:GetMovieClip();
		local slot = 0;
		for i = 1, movieEntity.inventory:GetSlotCount() do
			local itemStack = movieEntity.inventory:GetItem(i)
			if(itemStack and itemStack.id == block_types.names.TimeSeriesCamera) then
				slot = slot + 1;
				if(slot == index) then
					local actor = clip:GetActorFromItemStack(itemStack, true);
					setActorData(actor, pos[1], pos[2], pos[3], Cameras.eyeDist, rot[2], rot[3]);
					return;
				end
			end 
		end

		local itemStack = movieEntity:CreateCamera();
		local actor = clip:GetActorFromItemStack(itemStack, true);
		setActorData(actor, pos[1], pos[2], pos[3], Cameras.eyeDist, rot[2], rot[3]);
	end
end


function Camera.use(id, entity)
	cameraTryInit(entity);
	local index
	if(type(id) == "number" or not id) then
		index = id or 1;
	elseif(id:match("#%d+")) then
		index = tonumber(string.sub(id, 2)) or 1;
	end

	if(index) then
		Cameras.setCurrentCameraId(index);
		Camera.createCamera(index, entity);
		local currentCamera = Cameras.getCurrentCamera();
		if(currentCamera) then
			currentCamera:SetFocus();
			currentCamera:PlayToTime()
			if(Camera.codeBlock and Camera.codeBlock:IsEditing()) then
				currentCamera:ShowCameraModel();
			else
				currentCamera:HideCameraModel();
			end
		end
	end
end

function Camera.setPosition(x, y, z)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		actor:SetBlockPos(x, y, z);
	end
end

function Camera.move(actor, dx, dy, dz, duration)
	cameraTryInit();
	if(not dz) then
		dz = dy;
		dy = nil;
	end

	local x, y, z = actor:GetPosition();
	dx =(dx or 0) * BlockEngine.blocksize
	dy =(dy or 0) * BlockEngine.blocksize
	dz =(dz or 0) * BlockEngine.blocksize
	local targetX = x + dx;
	local targetY = y + dy;
	local targetZ = z + dz;
	if(not duration) then
		actor:SetPosition(targetX, targetY, targetZ);
		local yaw, pitch = actor:GetFacing(), actor:GetEyeLifeup();
		ParaCamera.SetEyePos(actor:GetEyeDist(), pitch, mathlib.ToStandardAngle(yaw));
	elseif(duration == 0) then
		actor:SetPosition(targetX, targetY, targetZ);
	else
		local startTime = commonlib.TimerManager.GetCurrentTime() / 1000
		local endTime = startTime + duration;
		local stepTime = Camera.GetDefaultTick();
		while(true) do
			local curTime = commonlib.TimerManager.GetCurrentTime() / 1000;
			local timeLeft = endTime - curTime;
			local shouldBe;
			if((curTime + stepTime) >= endTime) then
				shouldBe = 1
			else
				shouldBe =(curTime + stepTime - startTime) / duration;
			end
			local cur_x, cur_y, cur_z = actor:GetPosition();
			if(cur_x) then
				local sx, sy, sz = x + shouldBe * dx, y + shouldBe * dy, z + shouldBe * dz
				local dx1, dy1, dz1 = sx - cur_x, sy - cur_y, sz - cur_z;
				Camera.move(actor, dx1 * BlockEngine.blocksize_inverse, dy1 * BlockEngine.blocksize_inverse, dz1 * BlockEngine.blocksize_inverse)
				Camera.InvokeMethod("wait", Camera.GetDefaultTick());
				if(shouldBe == 1) then
					break;
				end
			else
				break;
			end
		end
	end
end

-- 60FPS at most
function Camera.GetDefaultTick()
	return 0.016;
end

function Camera.moveForward(dist, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		local yaw, pitch = actor:GetFacing(), actor:GetEyeLifeup();
		local dist2 = math.abs(math.cos(pitch) * dist);
		
		local fromTime = Cameras.getTotalTimes()
		Cameras.setTotalTimes(fromTime + duration);
		local progress =  math.min(1, (duration and duration > 0) and ((Cameras.getTargetTime() - fromTime) / duration) or 1);

		if(progress > 0) then
			Camera.move(actor, math.cos(yaw) * dist2 * progress, math.sin(pitch) * dist * progress, -math.sin(yaw) * dist2 * progress);
			if(progress < 1) then
				Camera.pause()
			end
		else
			Camera.move(actor, math.cos(yaw) * dist2, math.sin(pitch) * dist, -math.sin(yaw) * dist2, duration);
		end
	end
end

function Camera.moveHorizontal(dist, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		local facing = actor:GetFacing() + math.pi * 0.5;
		
		local fromTime = Cameras.getTotalTimes()
		Cameras.setTotalTimes(fromTime + duration);
		local progress =  math.min(1, (duration and duration > 0) and ((Cameras.getTargetTime() - fromTime) / duration) or 1);

		if(progress > 0) then
			Camera.move(actor, math.cos(facing) * dist * progress, 0, -math.sin(facing) * dist * progress);
			if(progress < 1) then
				Camera.pause()
			end
		else
			Camera.move(actor, math.cos(facing) * dist, 0, -math.sin(facing) * dist, duration);
		end
	end
end

function Camera.moveVertical(dist, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		local fromTime = Cameras.getTotalTimes()
		Cameras.setTotalTimes(fromTime + duration);
		local progress =  math.min(1, (duration and duration > 0) and ((Cameras.getTargetTime() - fromTime) / duration) or 1);

		if(progress > 0) then
			Camera.move(actor, 0, dist * progress, 0);
			if(progress < 1) then
				Camera.pause()
			end
		else
			Camera.move(actor, 0, dist, 0, duration);
		end
	end
end

function Camera.rotate(actor, degree, pitch, roll, duration)
	cameraTryInit();
	degree = degree or 0;
	pitch = pitch or 0;
	roll = roll or 0;
	local y, p, r = actor:GetFacing(), actor:GetEyeLifeup(), actor:GetEyeRoll();
	local ty, tp, tr = y + degree * math.pi / 180, p + pitch * math.pi / 180, r + roll * math.pi / 180;
	if(not duration) then
		actor:SetFacing(mathlib.ToStandardAngle(ty));
		actor:SetEyeLifeup(tp);
		actor:SetEyeRoll(tr);
		ParaCamera.SetEyePos(actor:GetEyeDist(), tp, mathlib.ToStandardAngle(ty));
	elseif(duration == 0) then
		actor:SetFacing(mathlib.ToStandardAngle(ty));
		actor:SetEyeLifeup(tp);
		actor:SetEyeRoll(tr);
	else
		local startTime = commonlib.TimerManager.GetCurrentTime() / 1000
		local endTime = startTime + duration;
		local stepTime = Camera.GetDefaultTick();
		while(true) do
			local curTime = commonlib.TimerManager.GetCurrentTime() / 1000;
			local timeLeft = endTime - curTime;
			local shouldBe;
			if((curTime + stepTime) >= endTime) then
				shouldBe = 1
			else
				shouldBe =(curTime + stepTime - startTime) / duration;
			end
			local cur_y, cur_p, cur_roll = actor:GetFacing(), actor:GetEyeLifeup(), actor:GetEyeRoll();
			if(cur_y and cur_p and cur_roll) then
				local sx, sy, sz = y + shouldBe * degree * math.pi / 180, p + shouldBe * pitch * math.pi / 180, r + shouldBe * roll * math.pi / 180;
				local dx1, dy1, dz1 = sx - cur_y, sy - cur_p, sz - cur_roll;
				Camera.rotate(actor, dx1 * 180 / math.pi, dy1 * 180 / math.pi, dz1 * 180 / math.pi)
				Camera.InvokeMethod("wait", Camera.GetDefaultTick());

				if(shouldBe == 1) then
					break;
				end
			else
				break;
			end
		end
	end
end

function Camera.rotateYaw(degree, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		local fromTime = Cameras.getTotalTimes()
		Cameras.setTotalTimes(fromTime + duration);
		local progress =  math.min(1, (duration and duration > 0) and ((Cameras.getTargetTime() - fromTime) / duration) or 1);

		if(progress > 0) then
			Camera.rotate(actor, degree * progress, nil, nil);
			if(progress < 1) then
				Camera.pause()
			end
		else
			Camera.rotate(actor, degree, nil, nil, duration);
		end
	end
end

function Camera.rotatePitch(degree, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		degree = math.max(math.min(degree, 90), -90);

		local fromTime = Cameras.getTotalTimes()
		Cameras.setTotalTimes(fromTime + duration);
		local progress =  math.min(1, (duration and duration > 0) and ((Cameras.getTargetTime() - fromTime) / duration) or 1);

		if(progress > 0) then
			Camera.rotate(actor, nil, degree * progress, nil);
			if(progress < 1) then
				Camera.pause()
			end
		else
			Camera.rotate(actor, nil, degree, nil, duration);
		end
	end
end

function Camera.rotateRoll(degree, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		degree = math.max(math.min(degree, 90), -90);

		local fromTime = Cameras.getTotalTimes()
		Cameras.setTotalTimes(fromTime + duration);
		local progress =  math.min(1, (duration and duration > 0) and ((Cameras.getTargetTime() - fromTime) / duration) or 1);

		if(progress > 0) then
			Camera.rotate(actor, nil, nil, degree * progress);
			if(progress < 1) then
				Camera.pause()
			end
		else
			Camera.rotate(actor, nil, nil, degree, duration);
		end
	end
end

function Camera.circle(degree, duration, radius)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		degree = degree + actor:GetFacing() * 180 / math.pi;

		local function moveArc(x, y, z, degree, radius)
			local dx = math.cos(degree * math.pi / 180) * radius;
			local dz = -math.sin(degree * math.pi / 180) * radius;
			local targetX = x + radius - dx;
			local targetZ = z + dz;
			actor:SetPosition(targetX, y, targetZ);
			actor:SetFacing(mathlib.ToStandardAngle(-degree * math.pi / 180));
			ParaCamera.SetEyePos(actor:GetEyeDist(), actor:GetEyeLifeup(), mathlib.ToStandardAngle(-degree * math.pi / 180));
		end

		local function circleImp(degree, radius, duration)
			local x, y, z = actor:GetPosition();
			if(not duration) then
				moveArc(x, y, z, degree, radius);
			elseif(duration == 0) then
				moveArc(x, y, z, degree, radius);
			else
				local startTime = commonlib.TimerManager.GetCurrentTime() / 1000
				local endTime = startTime + duration;
				local stepTime = Camera.GetDefaultTick();
				local current = 0;
				while(true) do
					local curTime = commonlib.TimerManager.GetCurrentTime() / 1000;
					local timeLeft = endTime - curTime;
					local shouldBe;
					if((curTime + stepTime) >= endTime) then
						shouldBe = 1
					else
						shouldBe =(curTime + stepTime - startTime) / duration;
					end

					moveArc(x, y, z, degree * shouldBe, radius);
					Camera.InvokeMethod("wait", Camera.GetDefaultTick());

					if(shouldBe == 1) then
						break;
					end
				end
			end
		end

		local fromTime = Cameras.getTotalTimes()
		Cameras.setTotalTimes(fromTime + duration);
		local progress =  math.min(1, (duration and duration > 0) and ((Cameras.getTargetTime() - fromTime) / duration) or 1);
		
		if(progress > 0) then
			circleImp(degree * progress, radius);
		else
			circleImp(degree, radius, duration);
		end
	end
end

function Camera.play(begin_t, end_t, entity)
	cameraTryInit(entity);
	local currentCamera = Cameras.getCurrentCamera();
	if(currentCamera) then
		if(not end_t) then
			end_t = begin_t;
		end
		local duration =(end_t - begin_t) / 1000;
		
		local fromTime = Cameras.getTotalTimes()
		Cameras.setTotalTimes(fromTime + duration);
		local progress =  math.min(1, (duration and duration > 0) and ((Cameras.getTargetTime() - fromTime) / duration) or 1);


		if(progress > 0) then
			currentCamera:PlayToTime(begin_t + duration * progress * 1000);
			if(progress < 1) then
				Camera.pause()
			end
		else
			local startTime = commonlib.TimerManager.GetCurrentTime();
			local endTime = startTime + end_t - begin_t;
			local stepTime = Camera.GetDefaultTick();
			local current = 0;
			while(true) do
				local curTime = commonlib.TimerManager.GetCurrentTime();
				if((curTime + stepTime) >= endTime) then
					currentCamera:PlayToTime(endTime - startTime + begin_t);
					break;
				end
				currentCamera:PlayToTime(curTime - startTime + begin_t);
				Camera.InvokeMethod("wait", Camera.GetDefaultTick());
			end
		end
	end
end

-- TODO
function Camera.follow()
	cameraTryInit();
end

-- TODO
function Camera.moveTo()
	cameraTryInit();
end
	
-- TODO
function Camera.lockLookat()
	cameraTryInit();
end

function Camera.wait(seconds)
	cameraTryInit();
	local totalTimes = Cameras.getTotalTimes() + seconds;
	local targetTime = Cameras.getTargetTime();
	Cameras.setTotalTimes(totalTimes);
	if(targetTime > totalTimes) then
		return;
	end

	Camera.InvokeMethod("wait", seconds);
end

-- TODO
function Camera.stop()
	cameraTryInit();
end

function Camera.exit()
	if(Camera.codeEnv) then
		Camera.codeEnv:exit();
	end
end

function Camera.pause()
	if(Camera.codeEnv) then
		Camera.codeEnv:yield();
	end
end

function Camera.close()
	Camera.codeBlock = nil;
	Camera.origin = nil
	Camera.codeEnv = nil;
	Cameras.clear()
end

function Camera.reopen()
	cameraTryInit();
	local entity = Camera.codeBlock:GetEntity();
	if(entity) then
		entity:OpenEditor("entity", entity);
		Camera.showWithEditor(entity);
	end
end

