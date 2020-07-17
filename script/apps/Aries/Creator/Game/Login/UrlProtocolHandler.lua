--[[
Title: URL protocol handler
Author(s): LiXizhi
Date: 2016/1/19
Desc: singleton class

## paracraft://cmd/loadworld/[url_filename]
`paracraft://cmd/loadworld/https://github.com/LiXizhi/HourOfCode/archive/master.zip`

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

	-- the c++ ConvertToCanonicalForm may replace : with space for standard command line
	local urlProtocol = string.match(cmdline or "", "paracraft%W?//(.*)$");

	if urlProtocol then
		NPL.load("(gl)script/ide/Encoding.lua");
		urlProtocol = commonlib.Encoding.url_decode(urlProtocol);
		LOG.std(nil, "debug", "UrlProtocolHandler", "protocol paracraft://%s", urlProtocol);

		local action_text = urlProtocol:match("action=(%w+)")

		if action_text == "runcode" then
			local action_text_text = urlProtocol:match("text=(.+)")

			if not action_text_text then
				return false
			end

			local code = action_text_text

			local function CreateSandBoxEnv()
				local env = {
					alert = _guihelper and _guihelper.MessageBox or commonlib.echo,
					GameLogic = commonlib.gettable("GameLogic"),
					cmd = GameLogic and GameLogic.RunCommand or commonlib.echo,
				};
				local meta = {__index = _G};
				setmetatable(env, meta);
				return env;
			end

			local function SaveCode()
				local filename = "temp/console.lua";
				local tmp_file = ParaIO.open(filename, "w");
				if(tmp_file) then
					if(code) then
						tmp_file:write(code, #code);
					end
					tmp_file:close();
				end
				return filename;
			end

			-- Run code and print result
			local function RunWithResult()
				if (not code or code == "") then
					return;
				end

				local fromLogPos = commonlib.log.GetLogPos();
				local filename = SaveCode();
				NPL.load("(gl)script/ide/System/Compiler/nplc.lua");
				local code_func, errormsg = NPL.loadstring(code, filename);

				if (code_func) then
					local env = CreateSandBoxEnv();
					setfenv(code_func, env);

					local ok, result = pcall(code_func);
					
					if (ok) then
						if (type(env.main) == "function") then
							setfenv(env.main, env);
							ok, result = pcall(env.main);
						end
					end
				end
			end

			RunWithResult()
		end

		local cmd_text = urlProtocol:match("cmd%(\"(.+)\"%)")

		if cmd_text then
			local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
			CommandManager:Init()
			CommandManager:RunCommand(cmd_text)
		end

		-- paracraft://cmd/loadworld/[url_filename]
		local world_url = urlProtocol:match("cmd/loadworld[%s/]+([%S]*)");
		if world_url then
			-- remote duplicated ? in url, just a quick client fix to keepwork url bug. 
			world_url = world_url:gsub("^([^%?]*%?[^%?]*)(%?.*)$", "%1")
			-- remove the trailing /, just a quick fix to keepwork url bug. 
			world_url = world_url:gsub("/$", "")
			System.options.cmdline_world = world_url;
		end

		local usertoken = urlProtocol:match("usertoken=\"([%S]+)\"");
		if(usertoken) then
			LOG.std(nil, "debug", "UrlProtocolHandler", "usertoken found: %s", usertoken);
			-- TODO: signin with user token
			
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
					LOG.std(nil, "info", "Url protocol", "%s:// found in registry as %s", protocol_name, cmd);
					return true;
				else
					LOG.std(nil, "warn", "Url protocol", "%s:// file not found at %s", protocol_name, filename);
				end
			end
		end
	end
end

function UrlProtocolHandler:CheckInstallUrlProtocol()
	if(System.os.GetPlatform() == "win32" and not (System.options and (System.options.isFromQQHall or System.options.isSchool))) then
		if(self:HasUrlProtocol()) then
			return true;
		else
			_guihelper.MessageBox(L"安装paracraft://URL协议后, 可用浏览器打开3D世界, 是否现在安装？(可能需要管理员权限)", function(res)
				if(res and res == _guihelper.DialogResult.Yes) then
					self:RegisterUrlProtocol();
				end
			end, _guihelper.MessageBoxButtons.YesNo);
		end	
	else
		LOG.std(nil, "info", "Url protocol", "skipped because of qq or school mode");
	end
end