local originalThis = NPL.this;
local ariesActivate;

NPL.this = function(activate)
	ariesActivate = activate;
end
NPL.load("(gl)script/apps/Aries/main_loop.lua");
NPL.this = originalThis;

local isRegistered = false;
local isStarted = false;

local function tryRegisterTest()
	if isRegistered then
		return;
	end

	local testScript = ParaEngine.GetAppCommandLineByParam("mujoco_test_script", "");
	if testScript == "" then
		isRegistered = true;
		return;
	end

	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
	if type(GameLogic.GetFilters) ~= "function" then
		return;
	end

	isRegistered = true;
	GameLogic.GetFilters():add_filter("OnWorldLoaded", function()
		if isStarted then
			return;
		end
		isStarted = true;
		LOG.std(nil, "info", "MuJoCoBootstrapper", "loading test script: %s", testScript);
		NPL.load("(gl)" .. testScript);
	end);
end

local function activate(msg)
	if ariesActivate then
		ariesActivate(msg);
	end
	tryRegisterTest();
end

NPL.this(activate);