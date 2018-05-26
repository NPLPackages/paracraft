--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/5/16
Desc: sandbox API environment 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI.lua");
local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local api = CodeAPI:new(codeBlock, codeActor);
-------------------------------------------------------
]]
-- all public environment methods. 
local s_env_methods = {
	"resume", 
	"yield", 
	"checkyield",
	"GetEntity",
	"exit",
	"print",
	"log",
	"echo",
	"gettable",
	"createtable",
	"inherit",
	"say",
	"wait",
	"move",
	"walk",
	"goto",
	"teleport",
	"anim",
	"play",
	"playLoop",
	"stop",
}

NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActor.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");
CodeAPI.__index = CodeAPI;

-- SECURITY: expose global _G to server env, this can be useful and dangourous.
setmetatable(CodeAPI, {__index = function(tab, name)
	if(name == "__LINE__") then
		local info = debug.getinfo(2, "l")
		if(info) then
			return info.currentline;
		end
	end
	return _G[name];
end});


-- @param actor: CodeActor that this code API is controlling. 
function CodeAPI:new(codeBlock, actor)
	local o = {
		actor = actor,
		codeblock = codeBlock,
		check_count = 0,
	};
	CodeAPI.InstallMethods(o);
	setmetatable(o, self);
	return o;
end

-- install functions to code environment
function CodeAPI.InstallMethods(o)
	for _, func_name in ipairs(s_env_methods) do
		local f = function(...)
			local self = getfenv(1);
			return env_imp[func_name](self, ...);
		end
		setfenv(f, o);
		o[func_name] = f;
	end
end


-- yield control until all async jobs are completed
-- @param bExitOnError: if true, this function will handle error 
-- @return err, msg: err is true if there is error. 
function env_imp:yield(bExitOnError)
	local err, msg;
	if(self.co) then
		if(self.fake_resume_res) then
			err, msg = unpack(self.fake_resume_res);
			self.fake_resume_res = nil;
			return err, msg;
		else
			self.check_count = 0;
			err, msg = coroutine.yield(self);
			if(err and bExitOnError) then
				env_imp.exit(self);
			end
		end
	end
	return err, msg;
end

-- resume from where jobs are paused last. 
-- @param err: if there is error, this is true, otherwise it is nil.
-- @param msg: error message in case err=true
function env_imp:resume(err, msg)
	if(self.co) then
		if(coroutine.status(self.co) == "running") then
			self.fake_resume_res = {err, msg};
			return;
		else
			self.fake_resume_res = nil;
		end
		local res, err, msg = coroutine.resume(self.co, err, msg);
	end
end

-- calling this function 100 times will automatically yield and resume until next tick (1/30 seconds)
-- we will automatically insert this function into while and for loop. One can also call this manually
function env_imp:checkyield()
	self.check_count = self.check_count + 1;
	if(self.check_count > 100) then
		env_imp.wait(self, env_imp.GetDefaultTick(self));
	end
end

-- Output a message and terminate the current script
-- @param msg: output this message. usually nil. 
function env_imp:exit(msg)
	-- the caller use xpcall with custom error function, so caller will catch it gracefully and end the request
	self.is_exit_call = true;
	self.exit_msg = msg;
	error("exit_call");
end

-- simple log any object, same as echo. 
function env_imp:log(...)
	commonlib.echo(...);
end

function env_imp:echo(...)
	commonlib.echo(...);
end

-- get the entity associated with the actor.
function env_imp:GetEntity()
	if(self.actor) then
		return self.actor:GetEntity();
	end		
end

function env_imp:GetActor()
	return self.actor;
end

-- similar to commonlib.gettable(tabNames) but in page scope.
-- @param tabNames: table names like "models.users"
function env_imp:gettable(tabNames)
	return commonlib.gettable(tabNames, self);
end

-- similar to commonlib.createtable(tabNames) but in page scope.
-- @param tabNames: table names like "models.users"
function env_imp:createtable(tabNames, init_params)
	return commonlib.createtable(tabNames, self);
end

-- same as commonlib.inherit()
function env_imp:inherit(baseClass, new_class, ctor)
	return commonlib.inherit(baseClass, new_class, ctor);
end

-- wait some time
-- @param seconds: in seconds
function env_imp:wait(seconds)
	if(seconds and seconds>0) then
		self.codeblock:SetTimeout(math.floor(seconds*1000), function()
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
			entity:Say(text, duration or -1)
		else
			GameLogic.AddBBS("codeblock", text, 10000);
		end
	end
end

-- walk relative to current block position and make it not dummy(has physics simulations)
-- the entity maybe blocked if target unreachable. 
-- it will move at the default speed. 
-- @param dx,dy,dz: if z is nil, y is z
-- @param duration: default to walkdist / walkspeed()
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

-- private: 
function env_imp:GetDefaultTick()
	if(not self.default_tick) then
		self.default_tick = self.codeBlock and self.codeBlock:GetDefaultTick() or 0.02;
	end
	return self.default_tick;
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
		if(actor) then
			actor:SetTime(time);
			actor:ResetOffsetPosAndRotation();
			actor:FrameMove(0, false);
		end

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
						self.codeblock:KillTimer(self.playTimer);
					end
				end
				actor:SetTime(time);
				actor:FrameMove(0, false);
			end
			self.playTimer = self.playTimer or self.codeblock:SetTimer(frameMove_, 0, deltaTime);
			self.playTimer.callbackFunc = frameMove_;
			self.playTimer:Change(0, deltaTime);
		end
	end
end

-- same as play(), but looping
function env_imp:playLoop(timeFrom, timeTo)
	env_imp.play(self, timeFrom, timeTo, true);
end

function env_imp:stop()
	if(self.playTimer) then
		self.codeblock:KillTimer(self.playTimer);
	end
end