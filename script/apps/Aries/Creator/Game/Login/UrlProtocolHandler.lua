--[[
Title: URL protocol handler
Author(s): LiXizhi
Date: 2016/1/19
Desc: singleton class

---++ paracraft://cmd/loadworld/[url_filename]
paracraft://cmd/loadworld/https://github.com/LiXizhi/HourOfCode/archive/master.zip

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UrlProtocolHandler.lua");
local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");
UrlProtocolHandler:ParseCommand()
if(not UrlProtocolHandler:HasUrlProtocol("paracraft")) then
	UrlProtocolHandler:RegisterUrlProtocol();
end
-------------------------------------------------------
]]
local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");

--@param cmdline: if nil we will read from current cmd line
function UrlProtocolHandler:ParseCommand(cmdline)
	local cmdline = cmdline or ParaEngine.GetAppCommandLine();
	local urlProtocol = string.match(cmdline or "", "paracraft://(.*)$");
	if(urlProtocol) then
		NPL.load("(gl)script/ide/Encoding.lua");
		urlProtocol = commonlib.Encoding.url_decode(urlProtocol);
		LOG.std(nil, "info", "UrlProtocolHandler", "protocol paracraft://%s", urlProtocol);
		-- paracraft://cmd/loadworld/[url_filename]
		local world_url = urlProtocol:match("^cmd/loadworld[%s/]+([%S]*)");
		if(world_url and world_url:match("^http(s)://")) then
			System.options.cmdline_world = world_url;
		end
	end
end

-- this will spawn a new process that request for admin right
-- @param protocol_name: TODO: default to "paracraft"
function UrlProtocolHandler:RegisterUrlProtocol(protocol_name)
	local protocol_name = protocol_name or "paracraft";
	local res = System.os([[reg query "HKCR\]]..protocol_name)
	if(res and res:match("URL Protocol")) then
		LOG.std(nil, "info", "RegisterUrlProtocol", "%s url protocol is already installed. We will overwrite it anyway", protocol_name);
	end
	local bindir = ParaIO.GetCurDirectory(0):gsub("/", "\\");
	local file = ParaIO.open("path.txt", "w");
	file:WriteString(bindir.."ParaEngineClient.exe");
	file:close();
	local res = System.os.runAsAdmin([[
reg add "HKCR\paracraft" /ve /d "URL:paracraft" /f
reg add "HKCR\paracraft" /v "URL Protocol" /d ""  /f
set /p EXEPATH=<"%~dp0path.txt"
reg add "HKCR\paracraft\shell\open\command" /ve /d "\"%EXEPATH%\" mc=\"true\" %%1" /f
del "%~dp0path.txt"
]]);
	LOG.std(nil, "info", "RegisterUrlProtocol", "%s to %s", protocol_name, bindir.."ParaEngineClient.exe");
end

-- return true if url protocol is installed
-- @param protocol_name: default to "paracraft://"
function UrlProtocolHandler:HasUrlProtocol(protocol_name)
	protocol_name = protocol_name or "paracraft";
	protocol_name = protocol_name:gsub("[://]+","");

	local has_protocol = ParaGlobal.ReadRegStr("HKCR", protocol_name, "URL Protocol");
	if(has_protocol == "") then
		-- following code is further check, which is not needed. 
		has_protocol = ParaGlobal.ReadRegStr("HKCR", protocol_name, "");
		if(has_protocol == "URL:"..protocol_name) then
			local cmd = ParaGlobal.ReadRegStr("HKCR", protocol_name.."/shell/open/command", "");
			if(cmd) then
				local filename = cmd:gsub("/", "\\"):match("\"([^\"]+)");
				if(ParaIO.DoesFileExist(filename, false)) then
					LOG.std(nil, "info", "Url protocol", "%s:// is %s", protocol_name, cmd);
					return true;
				else
					LOG.std(nil, "warn", "Url protocol", "%s:// file not found at %s", protocol_name, filename);
				end
			end
		end
	end
end

function UrlProtocolHandler:CheckInstallUrlProtocol()
	if(System.options.mc and System.os.GetPlatform() == "win32") then
		if(self:HasUrlProtocol()) then
			return true;
		else
			_guihelper.MessageBox(L"安装URL Protocol, 可用浏览器打开3D世界, 是否现在安装？(可能需要管理员权限)", function(res)
				if(res and res == _guihelper.DialogResult.Yes) then
					self:RegisterUrlProtocol();
				end
			end, _guihelper.MessageBoxButtons.YesNo);
		end	
	end
end