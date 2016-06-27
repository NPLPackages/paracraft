--[[
Title: filters
Author(s): LiXizhi
Date: 2015/7/2
Desc: filters allows plugins or mod to modify command input/output. 
Some commands and items run filters for some of its input and output values. 
This class defines default filters handlers used in the system. 

Filters: 
	cmd_open_url

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/DefaultFilters.lua");
local DefaultFilters = commonlib.gettable("MyCompany.Aries.Game.DefaultFilters");
DefaultFilters:Install();
-------------------------------------------------------
]]

local DefaultFilters = commonlib.gettable("MyCompany.Aries.Game.DefaultFilters")

function DefaultFilters:Install()
	local filters = GameLogic.GetFilters();
	filters:add_filter("cmd_open_url", DefaultFilters.cmd_open_url)	
end

function DefaultFilters.cmd_open_url(url)
	if(url and url:match("^npl")) then
		if(GameLogic.IsReadOnly()) then
			-- _guihelper.MessageBox(L"安全警告: NPL code wiki 只能在你自己创建的非只读世界中运行, 命令被终止");
			-- return;
		end

		NPL.load("(gl)script/apps/WebServer/WebServer.lua");
		local addr = WebServer:site_url();
		if(not addr) then
			GameLogic.CommandManager:RunCommand("/webserver");
			addr = WebServer:site_url();
		end
		if(addr) then
			url = url:gsub("^npl:?/*", addr);
		end
	end
	return url;
end