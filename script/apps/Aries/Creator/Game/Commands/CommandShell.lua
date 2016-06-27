--[[
Title: this is shell loop
Author(s): LiXizhi
Date: 2015/1/25
Desc: command line shell loop for paracraft for running CI jobs.
Run with command line like this:

"bootstrapper=script/apps/Aries/Creator/Game/Commands/CommandShell.lua mc=true servermode=true"

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandShell.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/ParaWorldCore.lua"); -- ParaWorld platform includes
NPL.load("(gl)script/ide/app_ipc.lua");

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local function RunTests()
	return 0;
end

main_state = nil;
local function activate()
	-- commonlib.echo("heart beat: 30 times per sec");
	if(main_state==0) then
		-- this is the main game 
	elseif(main_state==nil) then
		main_state=0;
		local servermode = ParaEngine.GetAppCommandLineByParam("servermode","false");
		local func = ParaEngine.GetAppCommandLineByParam("func","");
		LOG.std(nil, "info", "CommandShell", "server mode: %s func: %s", tostring(servermode),tostring(func));

		local nReturnValue;
		if(func == "Tests") then
			nReturnValue = RunTests();
		elseif(func == "BUILD_ZIP_FROM_OSX") then
			NPL.load("(gl)script/installer/BuildParaWorld.lua");
			commonlib.BuildParaWorld.BUILD_FROM_MAC = true;
			commonlib.BuildParaWorld.BuildComplete_Mobile()
			commonlib.BuildParaWorld.BUILD_FROM_MAC = nil;
		elseif(func == "BUILD_PKG_FROM_OSX") then
			NPL.load("(gl)script/installer/BuildParaWorld.lua");
			commonlib.BuildParaWorld.EncryptZipFiles({"main_complete_mobile"})
		elseif(func == "BUILD_PKG_FROM_WIN32") then
			NPL.load("(gl)script/installer/BuildParaWorld.lua");
			commonlib.BuildParaWorld.BuildComplete_Mobile()
			commonlib.BuildParaWorld.EncryptZipFiles({"main_complete_mobile"})
		else
			-- TODO: for other jobs, add here. 
		end
		ParaGlobal.Exit(nReturnValue or 0);
	end	
end
NPL.this(activate);