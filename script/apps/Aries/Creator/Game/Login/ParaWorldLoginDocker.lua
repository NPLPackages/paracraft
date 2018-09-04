--[[
Title: ParaWorldLoginDocker
Author(s): LiXizhi
Date: 2018/9/1
Desc: 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
ParaWorldLoginDocker.Show()
-------------------------------------------------------
]]
local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")

ParaWorldLoginDocker.page = nil;

System.options.paraworldapp = ParaEngine.GetAppCommandLineByParam("paraworldapp", "");

-- init function. page script fresh is set to false.
function ParaWorldLoginDocker.OnInit()
	ParaWorldLoginDocker.page = document:GetPageCtrl();
	
	if(System.options.paraworldapp == "user_worlds") then
		ParaWorldLoginDocker.OnClickApp("user_worlds");
	end
end

-- show page
function ParaWorldLoginDocker.ShowPage()
	local params;
	params = {
		url = "script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.html", 
		name = "ParaWorldLoginDocker.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = bShow,
		zorder = 5,
		click_through = true, 
		directPosition = true,
			align = "_mt",
			x = 0,
			y = 0,
			width = 512,
			height = 64,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaWorldLoginDocker.AutoMarkLoadedApp(appButtons)
	for i, app in pairs(appButtons) do
		app.isLoaded = ParaWorldLoginDocker.IsLoadedApp(app.name);
	end
	return appButtons;
end

function ParaWorldLoginDocker.IsLoadedApp(name)
	if(System.options.mc) then
		if(name == "paracraft" or name == "user_worlds" or name == "tutorial_worlds") then
			return true;
		end
	elseif(System.options.version == "kids") then
		if(name == "haqi") then
			return true;
		end
	elseif(System.options.version == "teen") then
		if(name == "haqi2") then
			return true;
		end
	elseif(System.options.version == "paraworld") then
		-- TODO: our social platform
	end
end

function ParaWorldLoginDocker.OnClickApp(name)
	if(name == "paracraft" or name == "user_worlds" or name == "tutorial_worlds") then
		if(not ParaWorldLoginDocker.IsLoadedApp(name))then
			ParaWorldLoginDocker.Restart("paracraft", format('paraworldapp="%s"', name))
		else
			if(name == "user_worlds") then
				System.options.showUserWorldsOnce = true
			elseif(name == "tutorial_worlds") then
				ParaGlobal.ShellExecute("open", "https://keepwork.com/official/paracraft/animation-tutorials", "", "", 1)
				return
			end

			if(ParaWorldLoginDocker.page) then
				ParaWorldLoginDocker.page:CloseWindow()
				System.options.loginmode = "local";
				local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
				MainLogin:next_step({IsLoginModeSelected = true});
			end
		end
	elseif(name == "haqi") then
		if(not ParaWorldLoginDocker.IsLoadedApp(name))then
			ParaWorldLoginDocker.Restart("haqi", 'paraworldapp="haqi"')
		end
	end
end

-- Restart the entire NPLRuntime to a different application. e.g.
-- Desktop.Restart("haqi")
-- Desktop.Restart("paracraft")
-- @param appName: nil default to "paracraft", it can also be "haqi"
function ParaWorldLoginDocker.Restart(appName, additional_commandline_params)
	local oldCmdLine = ParaEngine.GetAppCommandLine();
	local newCmdLine = oldCmdLine;
	if(not appName or appName == "paracraft") then
		newCmdLine = 'mc="true" bootstrapper="script/apps/Aries/main_loop.lua"'
	elseif(appName == "haqi") then
		newCmdLine = 'mc="false" bootstrapper="script/apps/Aries/main_loop.lua" version="kids" partner="keepwork" config="config/GameClient.config.xml"'
	end

	if(additional_commandline_params) then
		newCmdLine = newCmdLine.." "..additional_commandline_params;
	end
	ParaEngine.SetAppCommandLine(newCmdLine);
	
	System.reset();
	-- flush all local server 
	if(System.localserver) then
		System.localserver.FlushAll();
	end	
	ParaScene.UnregisterAllEvent();
	-- reset to default value
	ParaTerrain.LeaveBlockWorld();
	ParaTerrain.GetAttributeObject():SetField("RenderTerrain", true);

	local restart_code = [[
	ParaUI.ResetUI();
	ParaScene.Reset();
	NPL.load("(gl)script/apps/Aries/main_loop.lua");
	System.options.cmdline_world="";
	NPL.activate("(gl)script/apps/Aries/main_loop.lua");
]];

	-- TODO: close world archives, packages and search paths

	-- clear pending messages before reset
	while(true) do
		local nSize = __rts__:GetCurrentQueueSize();
		if(nSize>0) then
			__rts__:PopMessageAt(0, {process = true});
		else
			break;
		end
	end
	__rts__:Reset(restart_code);
end