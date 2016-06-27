--[[
Title: sandbox api environment for the creator
Author(s): LiXizhi
Date: 2013/8/19
Desc: moved from NeuronAPISandbox.lua to here for easy file location and extension management. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/APISandbox/CreatorAPISandbox.lua");
local CreatorAPISandbox = commonlib.gettable("MyCompany.Aries.Game.APISandbox.CreatorAPISandbox");
CreatorAPISandbox.Cleanup();
local sandbox = CreatorAPISandbox.CreateGetSandbox();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
NPL.load("(gl)script/ide/AudioEngine/AudioEngine.lua");
NPL.load("(gl)script/ide/timer.lua");
local AudioEngine = commonlib.gettable("AudioEngine");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local CreatorAPISandbox = commonlib.gettable("MyCompany.Aries.Game.APISandbox.CreatorAPISandbox");

local env;

-- called when first loading the world
function CreatorAPISandbox.Cleanup()
	LOG.std(nil, "info", "APISandbox", "cleaned up sandbox scripting environment")
	env = nil;
end

-- create get sandbox
function CreatorAPISandbox.CreateGetSandbox()
	if(not env) then
		env = CreatorAPISandbox.CreateSandbox()
	end
	return env;
end

function CreatorAPISandbox.CreateSandbox()
	local env = {
	  ipairs = ipairs,
	  next = next,
	  pairs = pairs,
	  pcall = pcall,
	  tonumber = tonumber,
	  tostring = tostring,
	  type = type,
	  unpack = unpack,
	  coroutine = { create = coroutine.create, resume = coroutine.resume, 
		  running = coroutine.running, status = coroutine.status, 
		  wrap = coroutine.wrap },
	  string = { byte = string.byte, char = string.char, find = string.find, 
		  format = string.format, gmatch = string.gmatch, gsub = string.gsub, 
		  len = string.len, lower = string.lower, match = string.match, 
		  rep = string.rep, reverse = string.reverse, sub = string.sub, 
		  upper = string.upper },
	  table = { insert = table.insert, maxn = table.maxn, remove = table.remove, 
		  sort = table.sort },
	  math = { abs = math.abs, acos = math.acos, asin = math.asin, 
		  atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos, 
		  cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor, 
		  fmod = math.fmod, frexp = math.frexp, huge = math.huge, 
		  ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max, 
		  min = math.min, modf = math.modf, pi = math.pi, pow = math.pow, 
		  rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh, 
		  sqrt = math.sqrt, tan = math.tan, tanh = math.tanh },
	  os = { clock = os.clock, difftime = os.difftime, time = os.time },
	};

	local meta = getmetatable (env)
	if not meta then
		meta = {}
		setmetatable (env, meta)
	end
	-- Note: do not expose the _G
	-- SECURITY NOTE: 
	-- expose global environment to the inline script via meta table
	-- meta.__index = _G;

	LOG.std(nil, "info", "CreatorAPISandbox", "new sandbox env is created");
	
	CreatorAPISandbox.InstallCommon(env);
	CreatorAPISandbox.InstallBlock(env);
	CreatorAPISandbox.InstallAudio(env);
	CreatorAPISandbox.InstallMovie(env);
	CreatorAPISandbox.InstallRawAPI(env);
	CreatorAPISandbox.InstallClasses(env);

	env.__index = env;
	return env;
end

function CreatorAPISandbox.InstallRawAPI(env)
	env.ParaCamera = ParaCamera;
end

-- common functions
function CreatorAPISandbox.InstallCommon(env)
	env.echo = echo;
	env.LOG = LOG;
	env.alert = function(content, ...) 
		-- disable mcml in content for security reasons
		content = commonlib.Encoding.EncodeStr(content);
		_guihelper.MessageBox(content, ...)
	end;
	-- load file in current directory
	env.load = function(filename)
		-- TODO: how to handle cross reference.
	end;
	-- activate a given neuron
	env.activate = function(filename)
		-- TODO: how to handle cross reference.
	end;

	-- load a mod outside sandbox env
	env.mod = function(mod_name)
		return NeuronManager.LoadMod(mod_name);
	end;

	-- run a command
	env.cmd = function(cmd_name, cmd_text, ...)
		return CommandManager:RunCommand(cmd_name, cmd_text, ...)
	end
	-- conver to real position
	env.real = function(bx,by,bz)
		return BlockEngine:real(bx,by,bz);
	end
	-- conver to block position
	env.block = function(x,y,z)
		return BlockEngine:block(x,y,z);
	end
	-- take a given block in right hand
	env.select = function(block_id)
		GameLogic.SetBlockInRightHand(block_id)
	end
	-- commonlib
	env.commonlib = {
		Timer = commonlib.Timer,
		TimerManager = commonlib.TimerManager,
	};
end

-- blocks related functions
function CreatorAPISandbox.InstallBlock(env)
	env.blocks = {
		-- set(bx,by,bz,block_id)		
		set = function(...)
			return BlockEngine:SetBlock(...);
		end,
		-- get(bx,by,bz)
		get = ParaTerrain.GetBlockTemplateByIdx,
		-- get script environment of a given neuron . may return nil. 
		-- @param bCreateIfNotExist: default to true
		getscript = function(x,y,z, bCreateIfNotExist)
			local neuron = NeuronManager.GetNeuron(x,y,z, bCreateIfNotExist~=false)
			if(neuron) then
				return neuron:GetScriptScope();
			end
		end,

	};
end

function CreatorAPISandbox.InstallAudio(env)
	env.audio = {
		-- play audio file. either 2d or 3d. 
		-- @param filename: predefined audio name such ash "portal" in "CreatorSound.bank.xml" or any file relative to current world directory. 
		play = function(filename, x, y, z, loop)
			local audio_src = AudioEngine.Get(filename);
			if(not audio_src) then
				filename = GameLogic.BuildResourceFilepath(filename);
				if(filename) then
					audio_src = AudioEngine.CreateGet(filename);
					audio_src.file = filename;
				end
			end
			if(loop) then
				audio_src.loop = true;
			end
			if(not x) then
				audio_src:play();
			else
				audio_src:play3d(x,y,z, loop);
			end
		end,
		stop = function(filename)
			local audio_src = AudioEngine.Get(filename) or AudioEngine.Get(GameLogic.BuildResourceFilepath(filename));
			if(audio_src) then
				audio_src:stop();
			end
		end,
	};
	
end

function CreatorAPISandbox.InstallMovie(env)
	env.movie = {
		-- show a movie sub script
		text = function(content, callbackFunc)
			NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/Mod/MovieText.lua");
			local MovieText = commonlib.gettable("MyCompany.Aries.Game.Mod.MovieText");
			MovieText.ShowPage(content, callbackFunc)
		end,
	};
end

-- exposing some oftenly used classes to sandbox environment
function CreatorAPISandbox.InstallClasses(env)
	env.Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");
	env.ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
	env.BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
	env.block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
	env.GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
	env.EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
	env.WorldSim = commonlib.gettable("MyCompany.Aries.Game.WorldSim");
	env.CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
	env.CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
	env.Game = commonlib.gettable("MyCompany.Aries.Game");
	env.Event = commonlib.gettable("System.Core.Event");
	env.System = commonlib.gettable("System");

	local additionalEnv = {};
	GameLogic.GetFilters():apply_filters("register_classes_into_sandbox_api", additionalEnv);
	for k,v in pairs(additionalEnv) do
		if not env[k] then
			env[k]=v;
		end
	end
end
