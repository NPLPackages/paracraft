--[[
Title: URL protocol handler
Author(s): LiXizhi, big
CreateDate: 2016.1.19
ModifyDate: 2022.1.5
Desc: singleton class

## load world command
paracraft://cmd/loadworld/[url_filename]
`paracraft://cmd/loadworld/https://github.com/LiXizhi/HourOfCode/archive/master.zip`

## in-world command
`paracraft://world/cmd(/stereo 0.3 5)

## any command 
`paracraft://cmd("/stereo 0.3 5")

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

-- @return nil if not found, otherwise it is a string containing the protocol
function UrlProtocolHandler:GetParacraftProtocol(cmdline)
	local preCmdLine = cmdline
	cmdline = cmdline or ParaEngine.GetAppCommandLine();
	if System.options.channelId_431 and cmdline and cmdline:find("paracraft://") then
		cmdline = cmdline:gsub("paracraft://","palakaedu://")
	end
	if System.options.isShenzhenAi5 and cmdline and cmdline:find("paracraft://") then
		cmdline = cmdline:gsub("paracraft://","palakaai://")
	end
	-- the c++ ConvertToCanonicalForm may replace : with space for standard command line
	
	local regStr = self:GetProtocolName().."%W?//(.*)$"
	local urlProtocol = string.match(cmdline or "", regStr);
	if System.options.isDevMode then
		print("urlProtocol===============",urlProtocol)
		print("regStr============",regStr)
		print("cmdline================",cmdline)
		print("preCmdLine===========",preCmdLine)
	end
	return urlProtocol;
end

--@param cmdline: if nil we will read from current cmd line
function UrlProtocolHandler:ParseCommand(cmdline)
	local cmdline = cmdline or ParaEngine.GetAppCommandLine();
	-- the c++ ConvertToCanonicalForm may replace : with space for standard command line
	local urlProtocol = self:GetParacraftProtocol(cmdline);

	if (urlProtocol) then
		NPL.load("(gl)script/ide/Encoding.lua");
		urlProtocol = commonlib.Encoding.url_decode(urlProtocol);
		LOG.std(nil, "debug", "UrlProtocolHandler", "protocol " .. self:GetProtocolName() .. "://%s", urlProtocol);
		local action_text = urlProtocol:match("action=(%w+)");

		if (action_text == "runcode") then
			local action_text_text = urlProtocol:match("text=(.+)");
			if (not action_text_text) then
				return false;
			end

			local code = action_text_text;

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

		local world_cmd_text = urlProtocol:match("world/cmd%((.+)%)");
		if (world_cmd_text) then
			local is_edu_do_works = urlProtocol:match("cmd%(/edu_do_works");
			local is_loadworld = urlProtocol:match("cmd/loadworld");

			urlProtocol = urlProtocol:gsub("world/cmd%(.+%)", "");
			if (is_loadworld) then
				local WorldShareCommand = NPL.load('(gl)Mod/WorldShare/command/Command.lua');
				WorldShareCommand:PushAfterLoadWorldCommand(world_cmd_text or '');
			elseif (is_edu_do_works) then
				world_cmd_text = world_cmd_text:gsub("/edu_do_works", "")
				world_cmd_text = world_cmd_text:gsub("^%s+", "")
				System.options.cmdline_world = "edu_do_works/" .. world_cmd_text;
				print("pbb System.options.cmdline_world",System.options.cmdline_world)
			else
				System.options.cmdline_cmd = world_cmd_text;
			end
		end

		local cmd_text = urlProtocol:match("cmd%(\"(.+)\"%)");

		if (cmd_text) then
			if (cmd_text:match("loadworld")) then
				System.options.cmdline_world = cmd_text;

				if (System.options.isDevMode) then
					LOG.std(nil, "info", "UrlProtocolHandler:ParseCommand", "System.options.cmdline_world: %s", System.options.cmdline_world);
				end
			else
				local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
				CommandManager:RunCommand(cmd_text);
			end
		end

		local secretkey = urlProtocol:match("secretkey=\"(%w+)\""); --智慧教育
		if (secretkey) then
			--print("pbb ---------------->secretkey",secretkey)
			System.options.cmdline_secretkey = secretkey;
		end

		-- paracraft://cmd/loadworld/[url or filename or id]
		local cmdline_world = urlProtocol:match("cmd/loadworld[%s/]+([%S]*)");

		if (cmdline_world) then
			-- remote duplicated ? in url, just a quick client fix to keepwork url bug. 
			cmdline_world = cmdline_world:gsub("^([^%?]*%?[^%?]*)(%?.*)$", "%1");

			-- remove the trailing /, just a quick fix to keepwork url bug. 
			cmdline_world = cmdline_world:gsub("/$", "");
			System.options.cmdline_world = cmdline_world;
		end
	
		local cmdline_options = urlProtocol:match("cmd/edu_do_works[%s/]+([%S]*)");

		if (cmdline_options) then
			cmdline_options = cmdline_options:gsub("/$", "");
			System.options.cmdline_world = "edu_do_works/" .. cmdline_options;

			if System.options.isDevMode then
				print("pbb System.options.cmdline_world",System.options.cmdline_world)
			end
		end

		local cmdline_token = urlProtocol:match('usertoken="([%S]+)"')
		if cmdline_token then
			System.options.cmdline_token = cmdline_token
		end

		local cmdline_mod = urlProtocol:match('mod="([%S]+)"')
		if cmdline_mod then
			System.options.cmdline_mod = cmdline_mod
			LOG.std(nil, "info", "UrlProtocolHandler:ParseCommand", "System.options.cmdline_mod: %s", System.options.cmdline_mod);
		end

		NPL.load("(gl)script/ide/System/Windows/Screen.lua");
		local Screen = commonlib.gettable("System.Windows.Screen");
		local safeAreaLeft = urlProtocol:match('safeAreaLeft="([%S]+)"')
		if safeAreaLeft then
			Screen:SetSafeAreaLeft(tonumber(safeAreaLeft) or 0);
		end

		local safeAreaRight = urlProtocol:match('safeAreaRight="([%S]+)"')
		if safeAreaRight then
			Screen:SetSafeAreaRight(tonumber(safeAreaRight) or 0);
		end

	end
end

-- this will spawn a new process that request for admin right. It will also register file extension .p3d
-- @param protocol_name: TODO: default to "paracraft"
function UrlProtocolHandler:RegisterUrlProtocol(protocol_name)
	if System.options.isPapaAdventure then
		_guihelper.MessageBox(L"该客户端暂不支持此功能")
		return 
	end
	local protocol_name = protocol_name or "paracraft";
	local res = System.os([[reg query "HKCR\]]..protocol_name)
	if(res and res:match("URL Protocol")) then
		LOG.std(nil, "info", "RegisterUrlProtocol", "%s url protocol is already installed. We will overwrite it anyway", protocol_name);
	end
	local bindir = ParaIO.GetCurDirectory(0):gsub("/", "\\");
	
	local file = ParaIO.open("path.txt", "w");
	file:WriteString(bindir.."ParaEngineClient.exe");
	file:close();
	local cmdStr = [[
reg add "HKCR\paracraft" /ve /d "URL:paracraft" /f
reg add "HKCR\paracraft" /v "URL Protocol" /d ""  /f
set /p EXEPATH=<"%~dp0path.txt"
reg add "HKCR\paracraft\shell\open\command" /ve /d "\"%EXEPATH%\" mc=\"true\" %%1" /f

reg add "HKCU\Software\Classes\.p3d" /ve /d "paracraft.world.v1" /f
reg add "HKCU\Software\Classes\paracraft.world.v1\shell\open\command" /ve /d "\"%EXEPATH%\" world=\"%%1\"" /f

del "%~dp0path.txt"
]]
	if ParaEngine.GetAttributeObject():GetField("DefaultFileAPIEncoding", "")=="utf-8" then
		cmdStr = "chcp 65001 >nul\n"..cmdStr
		--	chcp 65001 requires \r\n in windows. 
		cmdStr = cmdStr:gsub("\r?\n", "\r\n");
	end
	if System.options.isEducatePlatform then
		cmdStr = cmdStr:gsub("paracraft",self:GetProtocolName())
	end
	local res = System.os.runAsAdmin(cmdStr);
	LOG.std(nil, "info", "RegisterUrlProtocol", "%s to %s", protocol_name, bindir.."ParaEngineClient.exe");
end

function UrlProtocolHandler:GetProtocolName()
	if System.options.channelId_431 then
		return "palakaedu"
	end
	if System.options.isShenzhenAi5 then
		return "palakaai"
	end
	if System.options.isPapaAdventure then
		return "papa"
	end
	return "paracraft"
end

-- return true if url protocol is installed
-- @param protocol_name: default to "paracraft://"
-- @return bFound, exeName
function UrlProtocolHandler:HasUrlProtocol(protocol_name)
	protocol_name = protocol_name or self:GetProtocolName();
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
					return true, filename;
				else
					LOG.std(nil, "warn", "Url protocol", "%s:// file not found at %s", protocol_name, filename);
				end
			end
		end
	end
end

-- check if we have registered file extension. 
function UrlProtocolHandler:HasFileExtensionProtocol()
	local cmd = ParaGlobal.ReadRegStr("HKCU", "Software/Classes/paracraft.world.v1/shell/open/command", "");
	if(cmd and cmd ~= "") then
		return true;
	end
end

-- register ".p3d" file extension. 
function UrlProtocolHandler:RegisterFileExtensionProtocol()
	local res = System.os([[reg query "HKCU\Software\Classes\.p3d]])
	if(res and res:match("paracraft")) then
		LOG.std(nil, "info", "RegisterUrlProtocol", ".p3d file extension protocol is already installed. We will overwrite it anyway");
	end
	local exeFilepath = ParaIO.GetCurDirectory(0):gsub("/", "\\");
	exeFilepath = exeFilepath.."ParaEngineClient.exe";
	
	local file = ParaIO.open("path.txt", "w");
	file:WriteString(exeFilepath);
	file:close();
	local cmdStr = [[
reg add "HKCU\Software\Classes\.p3d" /ve /d "paracraft.world.v1" /f
set /p EXEPATH=<"%~dp0path.txt"
reg add "HKCU\Software\Classes\paracraft.world.v1\shell\open\command" /ve /d "\"%EXEPATH%\" world=\"%%1\"" /f
del "%~dp0path.txt"
]]
	if ParaEngine.GetAttributeObject():GetField("DefaultFileAPIEncoding", "")=="utf-8" then
		cmdStr = "chcp 65001 > nul\n"..cmdStr
	end
	
	local res = System.os.runAsAdmin(cmdStr);
	LOG.std(nil, "info", "RegisterUrlProtocol", ".p3d file extension to %s", exeFilepath);
end

function UrlProtocolHandler:CheckInstallUrlProtocol()
	if System.options.isPapaAdventure then
		return
	end
	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
	local customInstallUrlProtocol = GameLogic.GetFilters():apply_filters("CheckInstallUrlProtocol", false)
	
	local LocalStorageUtil = commonlib.gettable("System.localserver.LocalStorageUtil");
	local version_last_urlProtocal_tip = LocalStorageUtil.Load_localserver("version_last_urlProtocal_tip","0.0.0",true)
	local version_now = GameLogic.options.GetClientVersion()
	local isFristLaunch = commonlib.CompareVer(version_last_urlProtocal_tip,version_now)<0
	if System.options.isDevMode then
		print("version_last_urlProtocal_tip",version_last_urlProtocal_tip)
		print("version_now",version_now)
		print("CheckInstallUrlProtocol isFristLaunch",isFristLaunch,"customInstallUrlProtocol",customInstallUrlProtocol)
	end
	
	if not customInstallUrlProtocol or System.options.isEducatePlatform then --isFristLaunch 不需要跟着版本
		if(System.os.GetPlatform() == "win32" and not (System.options and (System.options.isFromQQHall or System.options.isSchool))) then
			local bFound, exeName = self:HasUrlProtocol()
			if System.options.isDevMode then
				print("bFound, exeName",bFound, exeName)
			end
			if(bFound) then
				local curPath = ParaIO.GetCurDirectory(0):gsub("\\", "/")
				exeName = exeName:gsub("\\", "/")
				if(exeName:sub(1, #curPath) == curPath) then
					return true
				else
					-- _guihelper.MessageBox(format(L"发现多个Paracraft版本在您的电脑上, 是否用当前目录下的版本%s作为默认的世界浏览器?<br/>安装paracraft://URL协议，需要管理员权限", commonlib.Encoding.DefaultToUtf8(curPath)), function(res)
					-- 	if(res and res == _guihelper.DialogResult.Yes) then
					-- 		self:RegisterUrlProtocol();
					-- 	end
					-- end, _guihelper.MessageBoxButtons.YesNo);
				end
			else
				if System.options.isEducatePlatform then
					self:RegisterUrlProtocol();
					GameLogic.AddBBS(nil,L"为了方便您体验更完整的帕拉卡学习创作服务，正在安装URL协议，用于浏览器打开3D世界，是否现在安装？（可能需要管理员权限）")
					return
				end
				commonlib.TimerManager.SetTimeout(function() --delay call because 'ParaUI.GetUIObject('root'):RemoveAll()' is called in WorldShare/cellar/MainLogin/MainLogin:Show()
					LocalStorageUtil.Save_localserver("version_last_urlProtocal_tip",version_now,true)
					LocalStorageUtil.Flush_localserver()
					_guihelper.MessageBox(L"为了方便您体验更完整的帕拉卡学习创作服务，请先安装URL协议，用于浏览器打开3D世界，是否现在安装？（可能需要管理员权限）", function(res)
						if(res and res == _guihelper.DialogResult.Yes) then
							self:RegisterUrlProtocol();
						end
					end, _guihelper.MessageBoxButtons.YesNo);
				end,10)
			end	
		else
			LOG.std(nil, "info", "Url protocol", "skipped because of qq or school mode");
		end
	end
	
end