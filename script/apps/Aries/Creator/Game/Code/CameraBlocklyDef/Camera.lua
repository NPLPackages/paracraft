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


local function cameraTryInit()
	local codeblock = GameLogic.GetCodeGlobal():GetCurrentCodeBlock();
	if(Camera.codeBlock ~= codeblock and codeblock) then
		Camera.init(codeblock)
		local currentCamera = Cameras.getCurrentCamera();
		if(not currentCamera) then
			Camera.use(1)
		end
	end
end

function Camera.init(codeblock)
	Cameras.clear()
	Camera.codeBlock = codeblock
	Camera.codeEnv = codeblock:GetCodeEnv();
	if(not Camera.origin) then
		local entity = Camera.codeBlock:GetEntity();
		if(entity) then
			local x, y, z = entity:GetPosition();
			Camera.origin = {x, y + 1, z};
		end
	end
	Camera.resetPositions();
	
	codeblock:Connect("codeUnloaded", function()
		Camera.close();
	end)
	codeblock:GetEntity():Connect("afterRunThisBlock", function()
		if(Cameras.getCurrentTime() > 0) then
			
		else
			Camera.resetPositions(true);
			EntityManager.SetFocus(EntityManager.GetPlayer());
		end
	end);
end

function Camera.resetPositions()
	cameraTryInit()
	local allCameras = Cameras.getAllCameras();
	for i = 1, #allCameras do
		if(allCameras[i]) then
			if(Cameras.positions[i]) then
				allCameras[i]:SetPosition(Cameras.positions[i][1], Cameras.positions[i][2], Cameras.positions[i][3])
			end
			if(Cameras.rotations[i]) then
				allCameras[i]:SetFacing(Cameras.rotations[i][1]);
				allCameras[i]:SetRoll(Cameras.rotations[i][2]);
			end
		end
	end
end

function Camera.InvokeMethod(name, ...)
	return Camera.codeEnv[name](...);
end

-- @param pos: table of {x, y, z, yaw, pitch, roll}
function Camera.setCamera(i, pos)
	cameraTryInit();
	local x, y, z = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z);
	Cameras.positions[i] = {x, y, z};
	local yaw, pitch, roll = tonumber(pos.yaw or 0), tonumber(pos.pitch or 0), tonumber(pos.roll or 0);
	Cameras.rotations[i] = {yaw, roll, pitch};
	local allCameras = Cameras.getAllCameras();
	allCameras[i] = allCameras[i] or EntityCamera:Create({x = x, y = y, z = z, item_id = block_types.names.TimeSeriesCamera});
	allCameras[i]:SetFacing(yaw);
	allCameras[i]:SetPitch(pitch);
	allCameras[i]:SetRoll(roll);
	allCameras[i]:SetPersistent(false);
	allCameras[i]:Attach();
	allCameras[i]:HideCameraModel();
end

function Camera.showWithEditor(entity)
	cameraTryInit();
	if(entity) then
		local x, y, z = entity:GetPosition();
		Camera.origin = {x, y + 1, z};
	end
	Cameras.setCurrentCameraId(1);
	Camera.createCamera(Cameras.getDefaultCameraCount(), entity);
	EntityManager.SetFocus(EntityManager.GetPlayer());
end

function Camera.showCamera(index, entity)
	cameraTryInit();
	Cameras.setCurrentCameraId(index);
	Camera.createCamera(index, entity);
	
	local currentCamera = Cameras.getCurrentCamera();
	if(not currentCamera) then
		return;
	end
	currentCamera:SetFocus();
	currentCamera:ShowCameraModel();

	local CameraViewport = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraViewport.lua");
	CameraViewport.ShowPage(index, function(result)
		if(result) then
			local x, y, z = currentCamera:GetPosition();
			Cameras.positions[index][1] = x;
			Cameras.positions[index][2] = y;
			Cameras.positions[index][3] = z;
			local eye_dist, eye_liftup, eye_rot_y = ParaCamera.GetEyePos();
			Cameras.rotations[index][1] = eye_rot_y;
			Cameras.rotations[index][2] = eye_liftup;
			Cameras.eyeDist = eye_dist;
		end
		currentCamera:SetPosition(Cameras.positions[index][1], Cameras.positions[index][2], Cameras.positions[index][3]);
		currentCamera:SetFacing(Cameras.rotations[index][1]);
		currentCamera:SetRoll(Cameras.rotations[index][2]);
		Camera.setMovieCameraPosition(index, entity, Cameras.positions[index], Cameras.rotations[index]);
		EntityManager.SetFocus(EntityManager.GetPlayer());
	end)
end

function Camera.createCamera(index, entity)
	cameraTryInit();
	entity = entity or Camera.codeBlock:GetEntity();

	if(not Camera.origin and entity) then
		local x, y, z = entity:GetPosition();
		Camera.origin = {x, y + 1, z};
	end
	if(not Camera.origin or not entity) then
		return;
	end

	local allCameras = Cameras.getAllCameras();
	local x, y, z = Camera.origin[1], Camera.origin[2], Camera.origin[3];
	for i = 1, index do
		if(allCameras[i] == nil) then
			Cameras.positions[i] = {x, y, z};
			Cameras.rotations[i] = {0, 0, 0};
			allCameras[i] = EntityCamera:Create({x = x, y = y, z = z, item_id = block_types.names.TimeSeriesCamera});
			allCameras[i]:SetPersistent(false);
			allCameras[i]:Attach();

			local movieEntity = entity:FindNearByMovieEntity();
			local myItemStack;
			if(movieEntity and movieEntity.inventory) then
				local clip = movieEntity:GetMovieClip();
				local slot = 0;
				for i = 1, movieEntity.inventory:GetSlotCount() do
					local itemStack = movieEntity.inventory:GetItem(i)
					if(itemStack and itemStack.id == block_types.names.TimeSeriesCamera) then
						slot = slot + 1;
						if(slot == i) then
							myItemStack = itemStack;
							break;
						end
					end 
				end
				if(not myItemStack) then
					myItemStack = movieEntity:CreateCamera()
				end
				allCameras[i]:BindToItemStack(myItemStack)
			end
			Camera.play(0)

			-- add EntityCamera in movie block
			if(entity) then
				-- Camera.setMovieCameraPosition(i, entity, Cameras.positions[i], Cameras.rotations[i]);
				--[[
				local movieEntity = entity:FindNearByMovieEntity();
				if (movieEntity) then
					movieEntity:CreateCamera();
				end
				]]
			end
		end
	end
end

function Camera.setMovieCameraPosition(index, entity, pos, rot)
	cameraTryInit();
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
	if(movieEntity and movieEntity.inventory) then
		local clip = movieEntity:GetMovieClip();
		local slot = 0;
		for i = 1, movieEntity.inventory:GetSlotCount() do
			local itemStack = movieEntity.inventory:GetItem(i)
			if(itemStack and itemStack.id == block_types.names.TimeSeriesCamera) then
				slot = slot + 1;
				if(slot == index) then
					local actor = clip:GetActorFromItemStack(itemStack, true);
					setActorData(actor, pos[1], pos[2], pos[3], Cameras.eyeDist, rot[1], rot[2]);
					return;
				end
			end 
		end

		local itemStack = movieEntity:CreateCamera();
		local actor = clip:GetActorFromItemStack(itemStack, true);
		setActorData(actor, pos[1], pos[2], pos[3], Cameras.eyeDist, rot[1], rot[2]);
	end
end


function Camera.use(id)
	cameraTryInit();
	local index
	if(type(id) == "number" or not id) then
		index = id or 1;
	elseif(id:match("#%d+")) then
		index = tonumber(string.sub(id, 2)) or 1;
	end

	if(index) then
		Cameras.setCurrentCameraId(index);
		Camera.createCamera(index);
		local currentCamera = Cameras.getCurrentCamera();
		if(currentCamera) then
			currentCamera:SetFocus();
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
		local yaw, pitch = actor:GetFacing(), actor:GetRoll();
		ParaCamera.SetEyePos(actor:GetEyeDist(), pitch, mathlib.ToStandardAngle(yaw));
		Camera.InvokeMethod("wait", Camera.codeBlock:GetDefaultTick());
	elseif(duration == 0) then
		actor:SetPosition(targetX, targetY, targetZ);
	else
		local startTime = commonlib.TimerManager.GetCurrentTime() / 1000
		local endTime = startTime + duration;
		local stepTime = Camera.codeBlock:GetDefaultTick();
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
				if(shouldBe == 1) then
					break;
				end
			else
				break;
			end
		end
	end
end

function Camera.moveForward(dist, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		local yaw, pitch = actor:GetFacing(), actor:GetRoll();
		local dist2 = math.abs(math.cos(pitch) * dist);
		local totalTimes = Cameras.getTotalTimes() + duration;
		local currentTime = Cameras.getCurrentTime();
		Cameras.setTotalTimes(totalTimes);
		if(currentTime > totalTimes) then
			Camera.move(actor, math.cos(yaw) * dist2, math.sin(pitch) * dist, -math.sin(yaw) * dist2);	
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if(usedTime > 0) then
			local r = usedTime / duration;
			Camera.move(actor, math.cos(yaw) * dist2 * r, math.sin(pitch) * dist * r, -math.sin(yaw) * dist2 * r);
			--Camera.move(actor, math.cos(yaw)*dist2, math.sin(pitch)*dist, -math.sin(yaw)*dist2, remainTime);
		elseif(currentTime > 0) then
			--
		else
			Camera.move(actor, math.cos(yaw) * dist2, math.sin(pitch) * dist, -math.sin(yaw) * dist2, duration);
		end
	end
end

function Camera.moveHorizontal(dist, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		local facing = actor:GetFacing();
		local totalTimes = Cameras.getTotalTimes() + duration;
		local currentTime = Cameras.getCurrentTime();
		Cameras.setTotalTimes(totalTimes);
		if(currentTime > totalTimes) then
			Camera.move(actor, math.cos(facing) * dist, 0, -math.sin(facing) * dist);
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if(usedTime > 0) then
			local r = usedTime / duration;
			Camera.move(actor, math.cos(facing) * dist * r, 0, -math.sin(facing) * dist * r);
			--Camera.move(actor, math.cos(facing)*dist, 0, -math.sin(facing)*dist, remainTime);
		elseif(currentTime > 0) then
			--
		else
			Camera.move(actor, math.cos(facing) * dist, 0, -math.sin(facing) * dist, duration);
		end
	end
end

function Camera.moveVertical(dist, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		local totalTimes = Cameras.getTotalTimes() + duration;
		local currentTime = Cameras.getCurrentTime();
		Cameras.setTotalTimes(totalTimes);
		if(currentTime > totalTimes) then
			Camera.move(actor, 0, dist, 0);
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if(usedTime > 0) then
			local r = usedTime / duration;
			Camera.move(actor, 0, dist * r, 0);
			--Camera.move(actor, 0, dist, 0, remainTime);
		elseif(currentTime > 0) then
			--
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
	local y, p, r = actor:GetFacing(), actor:GetRoll(), actor:GetPitch();
	local ty, tp, tr = y + degree * math.pi / 180, p + pitch * math.pi / 180, r + roll * math.pi / 180;
	if(not duration) then
		actor:SetFacing(mathlib.ToStandardAngle(ty));
		actor:SetPitch(tp);
		actor:SetRoll(tr);
		ParaCamera.SetEyePos(actor:GetEyeDist(), tp, mathlib.ToStandardAngle(ty));
		Camera.InvokeMethod("wait", Camera.codeBlock:GetDefaultTick());
	elseif(duration == 0) then
		actor:SetFacing(mathlib.ToStandardAngle(ty));
		actor:SetPitch(tp);
		actor:SetRoll(tr);
	else
		local startTime = commonlib.TimerManager.GetCurrentTime() / 1000
		local endTime = startTime + duration;
		local stepTime = Camera.codeBlock:GetDefaultTick();
		while(true) do
			local curTime = commonlib.TimerManager.GetCurrentTime() / 1000;
			local timeLeft = endTime - curTime;
			local shouldBe;
			if((curTime + stepTime) >= endTime) then
				shouldBe = 1
			else
				shouldBe =(curTime + stepTime - startTime) / duration;
			end
			local cur_y, cur_p, cur_roll = actor:GetFacing(), actor:GetRoll(), actor:GetPitch();
			if(cur_y and cur_p and cur_roll) then
				local sx, sy, sz = y + shouldBe * degree * math.pi / 180, p + shouldBe * pitch * math.pi / 180, r + shouldBe * roll * math.pi / 180;
				local dx1, dy1, dz1 = sx - cur_y, sy - cur_p, sz - cur_roll;
				Camera.rotate(actor, dx1 * 180 / math.pi, dy1 * 180 / math.pi, dz1 * 180 / math.pi)
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
		local totalTimes = Cameras.getTotalTimes() + duration;
		local currentTime = Cameras.getCurrentTime();
		Cameras.setTotalTimes(totalTimes);
		if(currentTime > totalTimes) then
			Camera.rotate(actor, degree, nil, nil);
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if(usedTime > 0) then
			local r = usedTime / duration;
			Camera.rotate(actor, degree * r, nil, nil);
			--Camera.rotate(actor, degree, nil, nil, remainTime);
		elseif(currentTime > 0) then
			--
		else
			Camera.rotate(actor, degree, nil, nil, duration);
		end
	end
end

function Camera.rotatePitch(degree, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		local totalTimes = Cameras.getTotalTimes() + duration;
		local currentTime = Cameras.getCurrentTime();
		Cameras.setTotalTimes(totalTimes);
		if(currentTime > totalTimes) then
			Camera.rotate(actor, nil, nil, degree);
			return;
		end

		degree = math.min(degree, 90);
		degree = math.max(degree, -90);

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if(usedTime > 0) then
			local r = usedTime / duration;
			Camera.rotate(actor, nil, nil, degree * r);
			--Camera.rotate(actor, nil, nil, degree, remainTime);
		elseif(currentTime > 0) then
			--
		else
			Camera.rotate(actor, nil, nil, degree, duration);
		end
	end
end

function Camera.rotateRoll(degree, duration)
	cameraTryInit();
	local actor = Cameras.getCurrentCamera();
	if(actor) then
		local totalTimes = Cameras.getTotalTimes() + duration;
		local currentTime = Cameras.getCurrentTime();
		Cameras.setTotalTimes(totalTimes);
		if(currentTime > totalTimes) then
			Camera.rotate(actor, nil, degree, nil);
			return;
		end

		degree = math.min(degree, 90);
		degree = math.max(degree, -90);

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if(usedTime > 0) then
			local r = usedTime / duration;
			Camera.rotate(actor, nil, degree * r, nil);
			--Camera.rotate(actor, nil, degree, nil, remainTime);
		elseif(currentTime > 0) then
			--
		else
			Camera.rotate(actor, nil, degree, nil, duration);
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
			ParaCamera.SetEyePos(actor:GetEyeDist(), actor:GetRoll(), mathlib.ToStandardAngle(-degree * math.pi / 180));
		end

		local function circleImp(degree, radius, duration)
			local x, y, z = actor:GetPosition();
			if(not duration) then
				moveArc(x, y, z, degree, radius);
				Camera.InvokeMethod("wait", Camera.codeBlock:GetDefaultTick());
			elseif(duration == 0) then
				moveArc(x, y, z, degree, radius);
			else
				local startTime = commonlib.TimerManager.GetCurrentTime() / 1000
				local endTime = startTime + duration;
				local stepTime = Camera.codeBlock:GetDefaultTick();
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
					Camera.InvokeMethod("wait", Camera.codeBlock:GetDefaultTick());

					if(shouldBe == 1) then
						break;
					end
				end
			end
		end

		local totalTimes = Cameras.getTotalTimes() + duration;
		local currentTime = Cameras.getCurrentTime();
		Cameras.setTotalTimes(totalTimes);
		if(currentTime > totalTimes) then
			circleImp(degree, radius);
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if(usedTime > 0) then
			local r = usedTime / duration;
			circleImp(degree * r, radius);
			--circleImp(degree, radius, remainTime);
		elseif(currentTime > 0) then
			--
		else
			circleImp(degree, radius, duration);
		end
	end
end

function Camera.play(begin_t, end_t)
	cameraTryInit();
	local currentCamera = Cameras.getCurrentCamera();
	if(currentCamera) then
		if(not end_t) then
			end_t = begin_t;
		end

		local duration =(end_t - begin_t) / 1000;
		local totalTimes = Cameras.getTotalTimes() + duration;
		local currentTime = Cameras.getCurrentTime();
		Cameras.setTotalTimes(totalTimes);
		if(currentTime > totalTimes) then
			currentCamera:PlayToTime(end_t)
			return;
		end

		local remainTime = totalTimes - currentTime;
		local usedTime = duration - remainTime;
		if(usedTime > 0) then
			currentCamera:PlayToTime(begin_t + usedTime * 1000);
			--begin_t = begin_t + usedTime * 1000;
			return;
		elseif(currentTime > 0) then
			return;
		else
		end

		local startTime = commonlib.TimerManager.GetCurrentTime();
		local endTime = startTime + end_t - begin_t;
		local stepTime = Camera.codeBlock:GetDefaultTick();
		local current = 0;
		while(true) do
			local curTime = commonlib.TimerManager.GetCurrentTime();
			if((curTime + stepTime) >= endTime) then
				currentCamera:PlayToTime(endTime - startTime + begin_t);
				break;
			end
			currentCamera:PlayToTime(curTime - startTime + begin_t);
			Camera.InvokeMethod("wait", Camera.codeBlock:GetDefaultTick());
		end
	end
end

function Camera.follow()
	cameraTryInit();
end

function Camera.moveTo()
	cameraTryInit();
end
	
function Camera.lockLookat()
	cameraTryInit();
end

function Camera.wait(seconds)
	cameraTryInit();
	local totalTimes = Cameras.getTotalTimes() + seconds;
	local currentTime = Cameras.getCurrentTime();
	Cameras.setTotalTimes(totalTimes);
	if(currentTime > totalTimes) then
		return;
	end

	Camera.InvokeMethod("wait", seconds);
end

function Camera.stop()
	cameraTryInit();
end

function Camera.close()
	EntityManager.SetFocus(EntityManager.GetPlayer());
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

