--[[
Title: NplCadWebServer
Author(s): leio
Date: 2021/3/11
Desc: 
setup webserver for building nplcad
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadWebServer.lua");

paraengineclient.exe script/apps/Aries/Creator/Game/Code/NplCad/NplCadWebServer.lua hide_main_window=true  port=8099 package=npl_packages/paracraftbuildinmod/ 

-------------------------------------------------------
]]
NPL.load("(gl)script/apps/WebServer/WebServer.lua");

local NplCadWebServer = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadWebServer");

local function activate()
	local msg = msg;
	if(WebServer:IsStarted()) then
		return;
	end
	if(not msg) then
		local rootDir = ParaEngine.GetAppCommandLineByParam("root", "script/apps/WebServer/admin");
		local ip = ParaEngine.GetAppCommandLineByParam("ip", "0.0.0.0");
		local port = ParaEngine.GetAppCommandLineByParam("port", "8099");

		local hide_main_window = ParaEngine.GetAppCommandLineByParam("hide_main_window", false);
		if(hide_main_window == "true" or hide_main_window == true )then
			NPL.ShowWindow(false);
		end

		NPL.load("(gl)script/ide/IDE.lua");

		-- commar separated list of packages like "npl_packages/paracraftwiki/"
		local package = ParaEngine.GetAppCommandLineByParam("package", "");
	    LOG.std(nil, "info", "NplCadWebServer package", package);
		if(package and package~="" and package:match("/$")) then
			for folder in package:gmatch("[^;,]+") do
				LOG.std(nil, "info", "NplCadWebServer load:", folder);
				NPL.load(folder);
			end
		end
		WebServer:Start(rootDir, ip, port);
	end
end
NPL.this(activate)