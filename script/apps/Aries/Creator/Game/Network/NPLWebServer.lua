--[[
Title: Web Server for Paracraft
Author(s): LiXizhi
Date: 2019/5/13
Desc: web server for paracraft
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");
local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");
local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)
end)
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local NPLWebServer = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer"));

function NPLWebServer:ctor()
end

-- static public function
-- @param callbackFunc: function(bStarted, site_url)  end
--  site_url contains port number incase multiple instances are opened. 
-- @return true, site_url:  if server is already started. 
function NPLWebServer.CheckServerStarted(callbackFunc)
	callbackFunc = callbackFunc or function(bStarted) 
		LOG.std(nil, "info", "CheckServerStarted", "%s", tostring(bStarted));
	end;

	NPL.load("(gl)script/apps/WebServer/WebServer.lua");
	local addr = WebServer:site_url();
	if(addr) then
		callbackFunc(true, addr);
		return true, addr;
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
		local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
		CommandManager:Init()
		CommandManager:RunCommand("/webserver");
		addr = WebServer:site_url();
		if(addr) then
			callbackFunc(true, addr);	
			return true, addr;
		else
			local count = 0;
			local function CheckServerStarted()
				commonlib.TimerManager.SetTimeout(function()  
					local addr = WebServer:site_url();
					if(addr) then
						callbackFunc(true, addr);
					else
						count = count + 1;
						-- try 5 times in 5 seconds
						if(count < 5)  then
							CheckServerStarted();
						else
							callbackFunc(false);
						end
					end
				end, 1000);
			end
			CheckServerStarted();
		end
	end
end