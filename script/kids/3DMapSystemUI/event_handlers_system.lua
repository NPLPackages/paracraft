--[[
Title: The map system Event handlers
Author(s): LiXizhi
Date: 2008/10/20
Desc: only included in event_handlers.lua
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_system.lua");
Map3DSystem.ReBindEventHandlers();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/ide/EventDispatcher.lua");


function Map3DSystem_OnSystemEvent()
	if(event_type == Sys_Event.SYS_COMMANDLINE) then
		local msg = msg;
		
		if( not commonlib.EventSystem.getInstance():DispatchEvent({type = "CommandLine", msg=msg})) then
			Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetSysCommandLineCommand(), msg);
		end

	elseif(event_type == Sys_Event.SYS_WM_DROPFILES) then
		if(type(msg) == "string") then
			local filelist = {};
			local filename
			for filename in string.gmatch(msg, "[^;]+") do
				filelist[#filelist+1] = filename;
			end
			local ret = Map3DSystem.App.Commands.Call("File.DropFiles", filelist)
			if not ret.bInterested then
				Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetDefaultCommand("SYS_WM_DROPFILES"), filelist);
			end
		end
	elseif(event_type == Sys_Event.SYS_WM_CLOSE) then	
		if(commonlib.getfield("MyCompany.Aries")) then
			Map3DSystem.App.Commands.Call("Profile.Aries.OnCloseApp");
		else
			_guihelper.MessageBox("您确定要退出么？", function()
				ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
				ParaGlobal.ExitApp();
			end)
		end
	elseif(event_type == Sys_Event.SYS_WM_DESTROY) then
		if(commonlib.getfield("MyCompany.Aries")) then
			Map3DSystem.App.Commands.Call("Profile.Aries.OnCloseApp", {IsDestroy=true});
		end
	elseif(event_type == Sys_Event.SYS_WM_SETTINGCHANGE) then
		--LOG.std(nil, "info", "system", "SYS_WM_SETTINGCHANGE received");
		Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetDefaultCommand("SYS_WM_SETTINGCHANGE"), msg);
	elseif (event_type == Sys_Event.SYS_RENDERER_RECREATED) then
		--LOG.std(nil, "info", "system", "SYS_RENDERER_RECREATED received");
		commonlib.EventSystem.getInstance():DispatchEvent({type = "RendererRecreated"});
	end
end