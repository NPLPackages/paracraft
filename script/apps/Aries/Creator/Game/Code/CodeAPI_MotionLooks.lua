--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/5/16
Desc: sandbox API environment
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_MotionLooks.lua");
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");

-- wait some time
-- @param seconds: in seconds
function env_imp:wait(seconds)
	if(seconds and seconds>0) then
		self.co:SetTimeout(math.floor(seconds*1000), function()
			env_imp.resume(self);
		end) 
		env_imp.yield(self);
	end
end

-- say some text and wait for some time. 
-- @param text: if nil, it will remove text
-- @param duration: in seconds. if nil, it means forever
function env_imp:say(text, duration)
	if(duration) then
		env_imp.say(self, text);
		env_imp.wait(self, duration);
		env_imp.say(self, nil);
	else
		local entity = env_imp.GetEntity(self);
		if(entity) then
			if(text~=nil) then
				text = tostring(text);
			end
			entity:Say(text, -1)
		else
			GameLogic.AddBBS("codeblock", text, 10000);
		end
	end
end

-- walk relative to current block position and make it not dummy(has physics simulations)
-- the entity maybe blocked if target unreachable. 
-- it will move at the default speed. 
-- @param dx,dy,dz: if z is nil, y is z
-- @param duration: default to none
function env_imp:walk(dx,dy,dz, duration)
	if(not dz) then
		dz = dy;
		dy = nil;
	end
	local entity = env_imp.GetEntity(self);
	if(entity) then
		local x,y,z = entity:GetBlockPos();
		x = x + (dx or 0);
		y = y + (dy or 0);
		z = z + (dz or 0);
		if(entity.MoveTo) then
			entity:EnableAnimation(true);
			entity:SetDummy(false);
			entity:WalkTo(x,y,z);
			if(not duration) then
				duration = math.sqrt(dx*dx + dz*dz) * BlockEngine.blocksize / entity:GetWalkSpeed();
			end
			env_imp.wait(self, duration);
		end
	end
end

-- move delta position and wait a tick. unlike walk, it will ignore physics and always move there. 
-- @param dx,dy,dz: if z is nil, y is z
-- @param duration: default to 1 tick
function env_imp:move(dx,dy,dz, duration)
	if(not dz) then
		dz = dy;
		dy = nil;
	end
	local entity = env_imp.GetEntity(self);
	if(entity) then
		local x,y,z = entity:GetPosition();
		x = x + (dx or 0)*BlockEngine.blocksize;
		y = y + (dy or 0)*BlockEngine.blocksize;
		z = z + (dz or 0)*BlockEngine.blocksize;
		if(entity.MoveTo) then
			entity:SetDummy(true);
			entity:SetPosition(x,y,z);
			env_imp.wait(self, duration or env_imp.GetDefaultTick(self));
		end
	end
end

function env_imp:turn(degree)
	local entity = env_imp.GetEntity(self);
	if(entity) then
		entity:SetFacingDelta(degree*math.pi/180);
	end
	env_imp.wait(self, env_imp.GetDefaultTick(self));
end

function env_imp:turnTo(degree)
	local entity = env_imp.GetEntity(self);
	if(entity) then
		entity:SetFacing(degree*math.pi/180);
	end
	env_imp.checkyield(self);
end

function env_imp:scale(scaleDeltaPercentage)
	local entity = env_imp.GetEntity(self);
	if(entity) then
		entity:SetScalingDelta(scaleDeltaPercentage/100);
	end
	env_imp.wait(self, env_imp.GetDefaultTick(self));
end

function env_imp:scaleTo(scalePercentage)
	local entity = env_imp.GetEntity(self);
	if(entity) then
		entity:SetScaling(scalePercentage/100);
	end
	env_imp.checkyield(self);
end

-- goto absolute position in real coordinates
-- Use teleport for block position
-- @param x,y,z: if z is nil, y is z
function env_imp:setPosition(x, y, z)
	local entity = env_imp.GetEntity(self);
	if(entity and x and y) then
		env_imp.stop(self);
		local ox,oy,oz = entity:GetPosition();
		if(not z) then
			y,z = oy, y;
		end
		entity:SetDummy(true);
		entity:SetPosition(x,y,z);
		env_imp.checkyield(self);
	end
end
env_imp["goto"] = env_imp.setPosition;

-- goto block position
-- @param x,y,z: if z is nil, y is z
function env_imp:teleport(x, y, z)
	local entity = env_imp.GetEntity(self);
	if(entity and x and y) then
		env_imp.stop(self);
		local ox,oy,oz = entity:GetBlockPos();
		if(not z) then
			y,z = oy, y;
		end
		entity:SetDummy(true);
		entity:SetBlockPos(x,y,z);
		env_imp.checkyield(self);
	end
end

-- set animation id
-- @param anim_id: 0 for standing (default), 4 for walk. 
-- @param duration: default to 1 tick
function env_imp:anim(anim_id, duration)
	anim_id = anim_id or 0;
	local entity = env_imp.GetEntity(self);
	if(entity) then
		entity:EnableAnimation(true);
		entity:SetAnimation(anim_id);
		env_imp.wait(self, duration or env_imp.GetDefaultTick(self));
	end
end


-- play a time series animation in the movie block.
-- this function will return immediately.
-- @param timeFrom: time in milliseconds, default to 0.
-- @param timeTo: if nil, default to timeFrom
-- @param isLooping: default to false.
function env_imp:play(timeFrom, timeTo, isLooping)
	timeFrom = timeFrom or 0;
	local time = timeFrom;
	local entity = env_imp.GetEntity(self);
	if(entity) then
		entity:SetDummy(true);
		entity:EnableAnimation(false);
		local actor = env_imp.GetActor(self);
		if(not actor) then
			return
		end
		actor:SetTime(time);
		actor:ResetOffsetPosAndRotation();
		actor:FrameMove(0, false);
		self.codeblock:OnAnimateActor(actor, time);

		if(timeTo and timeTo>timeFrom) then
			local deltaTime = math.floor(env_imp.GetDefaultTick(self)*1000);
			local function frameMove_(timer)
				time = time + timer:GetDelta();
				if(time >= timeTo) then
					if(isLooping) then
						if((time - timer:GetDelta()) == timeTo) then
							time = timeFrom;
						else
							time = timeTo;
						end
					else
						time = timeTo;
						timer:Change();
					end
				end
				actor:SetTime(time);
				actor:FrameMove(0, false);
				if(timeTo == time) then
					self.codeblock:OnAnimateActor(actor, time);
				end
			end
			if(not self.actor.playTimer) then
				self.actor.playTimer = self.codeblock:SetTimer(self.co:MakeCallbackFunc(frameMove_), 0, deltaTime);
				self.actor:Connect("beforeRemoved", function(actor)
					if(actor.playTimer) then
						self.codeblock:KillTimer(actor.playTimer);
						actor.playTimer = nil;
					end
				end)
			else
				self.actor.playTimer.callbackFunc = self.co:MakeCallbackFunc(frameMove_);
			end
			self.actor.playTimer:Change(0, deltaTime);
		end
	end
end

-- same as play(), but looping
function env_imp:playLoop(timeFrom, timeTo)
	env_imp.play(self, timeFrom, timeTo, true);
	env_imp.checkyield(self);
end

function env_imp:stop()
	if(self.actor and self.actor.playTimer) then
		self.codeblock:KillTimer(self.actor.playTimer);
		self.actor.playTimer = nil;
	end
	env_imp.checkyield(self);
end

function env_imp:show()
	if(self.actor) then
		self.actor:SetVisible(true);
	end
	env_imp.checkyield(self);
end

function env_imp:hide()
	if(self.actor) then
		self.actor:SetVisible(false);
	end
	env_imp.checkyield(self);
end
