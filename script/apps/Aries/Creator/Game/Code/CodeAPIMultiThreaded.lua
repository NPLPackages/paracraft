--[[
Title: CodeAPIMultiThreaded
Author(s): LiXizhi
Date: 2023/5/18
Desc: sandbox API environment for code block that is running in worker thread, such as in runTask function. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPIMultiThreaded.lua");
local CodeAPIMultiThreaded = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPIMultiThreaded");
local apiEnv = CodeAPIMultiThreaded:new();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/ide/System/Concurrent/AsyncTask.lua");
local AsyncTask = commonlib.gettable("System.Concurrent.AsyncTask");

-- all public environment methods. 
local s_env_methods = {
	"resume",  -- dummy
	"yield", -- dummy
	"checkyield", -- dummy
	"wait", -- dummy

	-- Data
	"print",
	"printStack",
	"log",
	"echo",
	"cmd",
	"tip",
	"showVariable",
	"setBlock",

	-- Events
	"broadcast",
	"registerClickEvent", -- dummy
	"registerBroadcastEvent", -- dummy
	"registerKeyPressedEvent", -- dummy

	-- Control
	"run",
	"runTask",
	"runTaskOn",
}
local CodeAPIMultiThreaded = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPIMultiThreaded");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_mt_imp");
CodeAPIMultiThreaded.__index = CodeAPIMultiThreaded;
-- all code blocks that are cloned on each thread. 
local globalCodeBlocks = {}
-- all worker threads that contains CodeAPI env. 
local workerThreads = {}

-- only called in worker thread, instead of the main thread. 
-- @param actor: CodeActor that this code API is controlling. 
function CodeAPIMultiThreaded:new()
	local o = {
		codeblock = nil,
		check_count = 0,
	};
	o._G = GameLogic.GetCodeGlobal():GetCurrentGlobals();

	CodeAPIMultiThreaded.InstallMethods(o);
	setmetatable(o, GameLogic.GetCodeGlobal():GetCurrentMetaTable());
	return o;
end

local function dummy_function()
end

-- install functions to code environment
function CodeAPIMultiThreaded.InstallMethods(o)
	for _, func_name in ipairs(s_env_methods) do
		if(env_imp[func_name]) then
			local f = function(...)
				return env_imp[func_name](o, ...);
			end
			o[func_name] = f;
		else
			o[func_name] = dummy_function;
		end
	end
end

function CodeAPIMultiThreaded.OneTimeInit()
	if(CodeAPIMultiThreaded.inited) then
		return
	end
	CodeAPIMultiThreaded.inited = true;
	if(NPL.IsMainThread()) then
		GameLogic:Connect("WorldUnloaded", CodeAPIMultiThreaded, CodeAPIMultiThreaded.OnWorldUnload, "UniqueConnection");
	end
end

function CodeAPIMultiThreaded:OnWorldUnload()
	globalCodeBlocks = {};
	_G.CodeAPIMainEnv = nil;
end

-- only called in the main thread
function CodeAPIMultiThreaded.AddAndUpdateCodeblock(codeBlock)
	if(NPL.IsMainThread() and codeBlock:IsGliaFile()) then
		CodeAPIMultiThreaded.OneTimeInit()
		globalCodeBlocks[codeBlock:GetFilename()] = codeBlock;

		if(codeBlock.code_func and codeBlock:IsLoaded() and next(workerThreads)) then
			-- update target thread's code function
			local globalCodeFuncs = {}
			globalCodeFuncs[codeBlock:GetFilename()] = string.dump(codeBlock.code_func)
			for name, worker in pairs(workerThreads) do
				local task = AsyncTask.CreateTask(CodeAPIMultiThreaded.InstallCodeFuncsToCodeAPI, globalCodeFuncs)
				task:Run(name)
			end	
		end
	end
end

-- this function is send to a worker thread to install globalCodeFuncs into CodeAPIMultiThreaded
-- @param globalCodeFuncs: a table of filename to code function string.
-- @param bForceNewCodeAPI: if true, it will create a new CodeAPIMultiThreaded instance.
function CodeAPIMultiThreaded.InstallCodeFuncsToCodeAPI(globalCodeFuncs, bForceNewCodeAPI)
	if(not _G.CodeAPIEnv or bForceNewCodeAPI) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPIMultiThreaded.lua");
		local CodeAPIMultiThreaded = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPIMultiThreaded");
		local apiEnv = CodeAPIMultiThreaded:new();
		_G.CodeAPIEnv = apiEnv;
		LOG.std(nil, "info", "CodeAPIMultiThreaded", "created a new CodeAPIMultiThreaded %s:CodeAPI", NPL.GetThreadName())

		GameLogic.MultiThreadedInit()
	end
	local env = _G.CodeAPIEnv
	for filename, codeStr in pairs(globalCodeFuncs) do
		local codeFunc, errmsg = loadstring(codeStr, filename);
		if(codeFunc) then
			LOG.std(nil, "info", "CodeAPIMultiThreaded", "installed %s in multi-threaded (%s)CodeAPI", filename, NPL.GetThreadName())
			setfenv(codeFunc, env)
			ok, result = pcall(codeFunc)
			if(not ok) then
				LOG.std(nil, "error", "CodeAPIMultiThreaded", "failed to run multi-threaded codeblock %s: %s", filename, tostring(result))
			end
		else
			LOG.std(nil, "error", "CodeAPIMultiThreaded", "failed to load multi-threaded code for %s: %s", filename, errmsg);
		end
	end
end

function CodeAPIMultiThreaded:OnBeforeSetWorkerEnv(worker, envName)
	if(envName == "CodeAPI" and NPL.IsMainThread()) then
		local name = worker:GetName();
		if(name ~= "main") then
			workerThreads[name] = worker;
			local globalCodeFuncs = {};
			for filename, codeBlock in pairs(globalCodeBlocks) do
				if(not codeBlock:IsCopiedToWorkerThread(name) and codeBlock:IsLoaded() and codeBlock.code_func) then
					codeBlock:SetCopiedToWorkerThread(name)
					globalCodeFuncs[filename] = string.dump(codeBlock.code_func)
				end
			end
			-- install global functions on the thread
			local task = AsyncTask.CreateTask(CodeAPIMultiThreaded.InstallCodeFuncsToCodeAPI, globalCodeFuncs, true)
			task:Run(name)
		end
	end
end

-- this function is usually called in the main thread, but can also be in the worker thread. 
function CodeAPIMultiThreaded.RegisterCodeAPIMultiThreadedEnv()
	if(not AsyncTask.GetSandBoxEnvFunc("CodeAPI")) then
		AsyncTask:Connect("beforeSetWorkerEnv", CodeAPIMultiThreaded, CodeAPIMultiThreaded.OnBeforeSetWorkerEnv, "UniqueConnection")

		-- This function is executed before each task and returns an environment table.
		AsyncTask.RegisterSandBoxEnvFunc("CodeAPI", function()
			if(not _G.CodeAPIEnv) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPIMultiThreaded.lua");
				local CodeAPIMultiThreaded = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPIMultiThreaded");
				local apiEnv = CodeAPIMultiThreaded:new();
				_G.CodeAPIEnv = apiEnv;
			end
			-- no coroutine is used
			GameLogic.GetCodeGlobal():SetCurrentCoroutine(nil);
			return _G.CodeAPIEnv;
		end)
	end
end

function env_imp:cmd(...)
	env_imp:runTaskOn("main", function(...)
		GameLogic.RunCommand(...)
	end, ...)
end

-- broadcast a global message.
-- @param msg: if nil, default to current actor's name
function env_imp:broadcast(text, msg)
	env_imp:runTaskOn("main", function(text, msg)
		GameLogic:GetCodeGlobal():BroadcastTextEvent(text, msg)
	end, text, msg)
end

-- simple log any object, similar to echo. 
function env_imp:log(...)
	env_imp:runTaskOn("main", function(...)
		GameLogic:GetCodeGlobal():log(...)
	end, ...)
end

-- similar to log, but without formatting support like %d in first parameter
function env_imp:print(...)
	env_imp:runTaskOn("main", function(...)
		GameLogic:GetCodeGlobal():print(...)
	end, ...)
end

-- @param level: default to 5 
function env_imp:printStack(level)
	local stack = commonlib.debugstack(2, level or 5, 1)
	for line in stack:gmatch("([^\r\n]+)") do
		if(not line:match("C function") and not line:match("CodeCoroutine.lua")) then
			log(line.."\n");
		end
	end
end

function env_imp:echo(obj, ...)
	echo(obj, ...);
	local text;
	if(type(obj) == "string") then
		text = obj:sub(1, 100)
	else
		text = commonlib.serialize_in_length(obj, 100)
	end
	env_imp:runTaskOn("main", function(text)
		GameLogic.RunCommand("/echo "..text)
	end, text)
end

-- simple log any object, similar to echo. 
function env_imp:tip(...)
	env_imp:runTaskOn("main", function(...)
		tip(...)
	end, ...)
end

function env_imp:showVariable(name, title, color, fontSize)
	local value = self.get(name);
	env_imp:runTaskOn("main", function(name, value, title, color, fontSize)
		set(name, value)
		showVariable(name, title, color, fontSize)
	end, name, value, title, color, fontSize)
end

-- run a task on the main thread and return immediately
-- @param threadName: if nil, it will randomly pick a thread to use, it can be "main" to run on main thread
-- @param mainFunc: function to run
-- @param ...: arguments to pass to the function
-- @return the task object, one can use task:OnFinish(function(result) end) for result.
function env_imp:runTaskOn(threadName, mainFunc, ...)
	if(type(mainFunc) == "function") then
		local task = AsyncTask.CreateTask(mainFunc, ...);

		if (threadName == "main") then
			if(not AsyncTask.GetSandBoxEnvFunc("CodeAPIMain")) then
				-- This function is executed before each task and returns an environment table.
				AsyncTask.RegisterSandBoxEnvFunc("CodeAPIMain", function()
					if(not _G.CodeAPIMainEnv) then
						NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI.lua");
						local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
						local apiEnv = CodeAPI:new();
						_G.CodeAPIMainEnv = apiEnv;
					end
					-- no coroutine is used
					GameLogic.GetCodeGlobal():SetCurrentCoroutine(nil);
					return _G.CodeAPIMainEnv;
				end)
			end

			task:Run(threadName, "CodeAPIMain")
			return task;
		else
			CodeAPIMultiThreaded.RegisterCodeAPIMultiThreadedEnv()
			task:Run(threadName, "CodeAPI")
			return task;
		end
	end
end

function env_imp:run(mainFunc)
	env_imp:runTask(mainFunc);
end

-- @return the task object, one can use task:OnFinish(function(result) end) for result.
function env_imp:runTask(mainFunc, ...)
	local task = AsyncTask.CreateTask(mainFunc, ...);
	CodeAPIMultiThreaded.RegisterCodeAPIMultiThreadedEnv()
	task:Run(nil, "CodeAPI")
	return task;
end

local pendingBlocks = {}
function env_imp:setBlock(x,y,z, blockId, blockData, entity_data)
	if(NPL.IsMainThread()) then
		return self.setBlock(x,y,z, blockId, blockData, entity_data)
	else
		local index = GameLogic.BlockEngine:GetSparseIndex(x, y, z)
		pendingBlocks[index] = {x,y,z, blockId, blockData, entity_data};

		CodeAPIMultiThreaded.timer = CodeAPIMultiThreaded.timer or commonlib.Timer:new({callbackFunc = function(timer)
			if(next(pendingBlocks)) then
				env_imp:runTaskOn("main", function(pendingBlocks)
					for _, block in pairs(pendingBlocks) do
						GameLogic.BlockEngine:SetBlock(block[1], block[2], block[3], block[4], block[5], nil, block[6])
					end
				end, pendingBlocks)

				pendingBlocks = {};
			end
			timer:Change();
		end})
		if(not CodeAPIMultiThreaded.timer:IsEnabled()) then
			CodeAPIMultiThreaded.timer:Change(100, nil);
		end
	end
end