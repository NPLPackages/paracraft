--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/5/16
Desc: sandbox API environment, see also CodeGlobals for shared API and globals.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI.lua");
local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local api = CodeAPI:new(codeBlock);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Events.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_MotionLooks.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Sensing.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Sound.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Data.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Control.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Microbit.lua");

-- all public environment methods. 
local s_env_methods = {
	"resume", 
	"yield", 
	"checkyield",
	"checkstep",
	"checkstep_nplblockly",
	"terminate",
	"restart",
	"exit",
	"xpcall",
	"GetEntity",
	
	-- Data
	"print",
	"printStack",
	"log",
	"echo",
	"alert",
	"setActorValue",
	"getActorValue",
	"getActorEntityValue",
	"showVariable",
	"include",
	"import",
	"getActor",
	"cmd",
	"getPlayTimer",

	-- operator
	"string_length",
	"string_char",
	"string_contain",

	-- Motion
	"move",
	"moveTo",
	"moveForward",
	"walk",
	"walkForward",
	"turn",
	"turnTo",
	"rotate",
	"rotateTo",
	"bounce",
	"velocity",
	"getX",
	"getY",
	"getZ",
	"getFacing",
	"getPos",
	"setPos",
	"setBlockPos",
	"getPlayerPos",
	-- Looks
	"say",
	"show",
	"hide",
	"anim",
	"play",
	"playAndWait",
	"playLoop",
	"playSpeed",
	"playBone",
	"stop",
	"scale",
	"scaleTo",
	"getPlayTime",
	"getScale",
	"attachTo",
	"focus",
	"camera",
	"getCamera",
	"setMovie",
	"isMatchMovie",
	"playMatchedMovie",
	"setMovieProperty",
	"playMovie",
	"stopMovie",
	"window",

	-- Events
	"registerClickEvent",
	"registerKeyPressedEvent",
	"registerAnimationEvent",
	"registerBroadcastEvent",
	"registerBlockClickEvent",
	"registerTickEvent",
	"registerStopEvent",
	"registerAgentEvent",
	"broadcast",
	"broadcastAndWait",
	"broadcastTo",
	"registerNetworkEvent",
	"broadcastNetworkEvent",
	"sendNetworkEvent",

	-- Control
	"wait",
	"waitUntil",
	"registerCloneEvent",
	"clone",
	"delete",
	"run",
	"runForActor",
	"becomeAgent",
	"setOutput",

	-- Sensing
	"isTouching",
	"registerCollisionEvent",
	"broadcastCollision",
	"distanceTo",
	"calculatePushOut",
	"isKeyPressed",
	"isMouseDown",
	"getTimer",
	"resetTimer",
	"ask",

	-- Sound
	"playNote",
	"playSound",
	"playSoundAndWait",
	"stopSound",
	"playMusic",
	"playText",
    --------------- NplMicroRobot
    "start_NplMicroRobot",
    -- Motion
    "createOrGetAnimationClip_NplMicroRobot",
    "createAnimationClip_NplMicroRobot",
    "createTimeLine_NplMicroRobot",
    "playAnimationClip_NplMicroRobot",
    "stopAnimationClip_NplMicroRobot",
    -- Looks
    "microbit_show_leds",
    "microbit_show_string",
    "microbit_pause",
    -- Events
    "registerKeyPressedEvent_NplMicroRobot",
    "registerGestureEvent_NplMicroRobot",
    -- Sensing
    "microbit_is_pressed",

    --------------- Microbit
    -- Animation
    "createRobotAnimation",
    "addRobotAnimationChannel",
    "endRobotAnimationChannel",
    "addAnimationTimeValue_Rotation",
    -- Motion
    "playRobotAnimation",
    "microbit_servo",
    "microbit_sleep",
    "rotateBone",
    -- Looks
    "microbit_display_show",
    "microbit_display_scroll",
	"microbit_display_clear",
}
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");
CodeAPI.__index = CodeAPI;


-- @param actor: CodeActor that this code API is controlling. 
function CodeAPI:new(codeBlock)
	local o = {
		codeblock = codeBlock,
		check_count = 0,
	};
	o._G = GameLogic.GetCodeGlobal():GetCurrentGlobals();

	CodeAPI.InstallMethods(o);
	GameLogic.GetFilters():apply_filters("CodeAPIInstallMethods",o);
	setmetatable(o, GameLogic.GetCodeGlobal():GetCurrentMetaTable());
	return o;
end

-- install functions to code environment
function CodeAPI.InstallMethods(o)
	for _, func_name in ipairs(s_env_methods) do
		local f = function(...)
			return env_imp[func_name](o, ...);
		end
		o[func_name] = f;
	end
end

-- get function by name
function CodeAPI.GetAPIFunction(func_name)
	return env_imp[func_name];
end

-- yield control until all async jobs are completed
-- @param bExitOnError: if true, this function will handle error 
-- @return err, msg: err is true if there is error. 
function env_imp:yield(bExitOnError)
	local err, msg, p3, p4;
	if(self.co) then
		if(self.fake_resume_res) then
			err, msg = unpack(self.fake_resume_res);
			self.fake_resume_res = nil;
			return err, msg;
		else
			self.check_count = 0;
			err, msg, p3, p4 = self.co:Yield();
			if(err and bExitOnError) then
				env_imp.exit(self);
			end
		end
	end
	return err, msg, p3, p4;
end

-- resume from where jobs are paused last. 
-- @param err: if there is error, this is true, otherwise it is nil.
-- @param msg: error message in case err=true
function env_imp:resume(err, msg, p3, p4)
	if(self.co) then
		if(self.co:GetStatus() == "running") then
			self.fake_resume_res = {err, msg, p3, p4};
			return;
		else
			self.fake_resume_res = nil;
		end
		local res, err, msg = self.co:Resume(err, msg, p3, p4);
	end
end

-- calling this function 100 times will automatically yield and resume until next tick (1/30 seconds)
-- we will automatically insert this function into while and for loop. One can also call this manually
-- @param count: default to 1. heavy operations can make this larger
function env_imp:checkyield(count)
	self.check_count = self.check_count + (count or 1);
	if(self.check_count > 100) then
		if(self.codeblock:IsAutoWait() and (self.co and coroutine.running() == self.co.co)) then
			env_imp.wait(self, env_imp.GetDefaultTick(self));
		else
			self.check_count = 0;
		end
	end
end

-- @param duration: wait for this seconds. default to 1.
function env_imp:checkstep(duration)
	-- 图块模式直接跳过
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
	if (CodeBlockWindow.IsSupportNplBlockly()) then return end

	local locationInfo = commonlib.debug.locationinfo(2)
	if(locationInfo) then
		GameLogic.GetFilters():apply_filters("OnCodeBlockLineStep", locationInfo);
	end
	env_imp.wait(self, 1);
end

function env_imp:checkstep_nplblockly(blockid, before, duration)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
	local entity = CodeBlockWindow.GetCodeEntity()
	if(not entity or not entity:IsStepMode()) then return end 
	if (not CodeBlockWindow.IsSupportNplBlockly()) then return end

	if (before) then   -- 代码执行前
		GameLogic.GetFilters():apply_filters("OnCodeBlockNplBlocklyLineStep", blockid);
		env_imp.wait(self, duration or 0.5);
	else               -- 代码执行后
		env_imp.wait(self, duration or 0.5);
		GameLogic.GetFilters():apply_filters("OnCodeBlockNplBlocklyLineStep", blockid);
	end
end


-- private: 
function env_imp:GetDefaultTick()
	if(not self.default_tick) then
		self.default_tick = self.codeBlock and self.codeBlock:GetDefaultTick() or 0.02;
	end
	return self.default_tick;
end
