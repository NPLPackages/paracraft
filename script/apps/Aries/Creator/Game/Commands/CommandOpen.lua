--[[
Title: CommandOpen
Author(s): LiXizhi
Date: 2014/3/18
Desc: open url, folder etc
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandOpen.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


local OpenCommand = {};

local mcml2_window = nil;

Commands["open"] = {
	name="open", 
	quick_ref="/open [-p] [-d] url", 
	desc=[[open url in external browser
@param -p: if -p is used, it will ask user for permission. 
@param -d: url is a directory
Examples: 
/open http://www.paraengine.com
/open -name test_wnd_1 -title 窗口 -width 800 -height 600 -alignment _ct https://keepwork.com
/open -p http://www.paraengine.com
/open npl://learn	open NPL code wiki pages
/open -d temp/
/open hello.html  open mcml file relative to world or root directory. Page is always center aligned and auto sized.
/open mcml://hello.html     default to open with mcml v1 (may change in future)
/open mcml1://hello.html    open with mcml v1
/open mcml2://hello.html    open with mcml v2
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options = {};
		local option, value;
		while(true) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);	
			if(not option) then
				break;
			elseif(option == "width" or option == "height"  or option == "x"  or option == "y") then
				value, cmd_text = CmdParser.ParseNumber(cmd_text);
				options[option] = value;
			elseif(option == "name" or option == "alignment" or option == "title") then
				value, cmd_text = CmdParser.ParseString(cmd_text, fromEntity);
				options[option] = value;
			else
				options[option] = true;
			end
		end

		local url = cmd_text;
		url = GameLogic.GetFilters():apply_filters("cmd_open_url", url, options);

		if(not url) then
			return;
		end

		if(options.d) then
			Map3DSystem.App.Commands.Call("File.WinExplorer", url);
		elseif(url) then
			local protocol = url:match("^(%w+)://");
			if(not protocol) then
				if(url:match("%.html")) then
					protocol = "mcml";
				end
			end
			if(protocol == "mcml" or protocol == "mcml1" or protocol == "mcml2") then
				url = url:gsub("^%w+://", "");

				NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
				local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
				local filepath = Files.GetFilePath(url); 
				if(not filepath) then
					LOG.std(nil, "warn", "cmd_open", "can not find file %s", url);
					return;
				end

				if(protocol == "mcml" or protocol == "mcml1") then
					local params = {
							url = filepath, 
							name = "cmd_open.ShowPage", 
							isShowTitleBar = false,
							DestroyOnClose = true,
							bToggleShowHide=false, 
							style = CommonCtrl.WindowFrame.ContainerStyle,
							allowDrag = true,
							enable_esc_key = true,
							bShow = true,
							click_through = false, 
							refresh = true,
							zorder = 1,
							app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
							bAutoSize = true,
							directPosition = true,
								align = "_ct",
								x = -400,
								y = -300,
								width = 800,
								height = 600,
						};
					System.App.Commands.Call("File.MCMLWindowFrame", params);
				
				elseif(protocol == "mcml2") then
					-- remove old window
					if(mcml2_window and mcml2_window.CloseWindow) then
						mcml2_window:CloseWindow(true);
					end
					-- create a new window
					NPL.load("(gl)script/ide/System/Windows/Window.lua");
					local Window = commonlib.gettable("System.Windows.Window");
					mcml2_window = Window:new();
					mcml2_window:Show({
						url=filepath, 
						DestroyOnClose = true,
						enable_esc_key = true,
						alignment="_ct", left = -400, top = -300, width = 800, height = 600,
					});
				end

			elseif(protocol) then
				if(options.p) then
					_guihelper.MessageBox(L"你确定要打开:"..url, function()
						ParaGlobal.ShellExecute("open", url, "", "", 1);
					end)
				elseif(not options.width and not options.height) then
					ParaGlobal.ShellExecute("open", url, "", "", 1);
				else
					-- only when width or height is specified, we will use NPL cef browser
                    NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
                    NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPage.lua");
                    local NplBrowserPage = commonlib.gettable("NplBrowser.NplBrowserPage");
                    local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
                    NplBrowserLoaderPage.Check()
                    if(not NplBrowserLoaderPage.IsLoaded())then
					    ParaGlobal.ShellExecute("open", url, "", "", 1);
                    else
                        local name = options.name;
                        local title = options.title;
                        local alignment = options.alignment;
                        local width = options.width;
                        local height = options.height;
                        NplBrowserPage.Open(name,url,title,nil,alignment,nil,nil,width, height);    
                    end
				end
			else
				if(url and url~="")then
					_guihelper.MessageBox(L"只能打开http://开头的URL地址");
				end
			end
		end
	end,
};


Commands["registerurlprotocol"] = {
	name="registerurlprotocol", 
	quick_ref="/registerurlprotocol", 
	desc=[[register url protocol, so that we can download and open url from web browser directly. 
Currently only supported on window platform.
Examples:
paracraft://cmd/loadworld https://github.com/LiXizhi/HourOfCode/archive/master.zip
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UrlProtocolHandler.lua");
		local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");
		UrlProtocolHandler:RegisterUrlProtocol()
	end,
};

Commands["hasurlprotocol"] = {
	name="hasurlprotocol", 
	quick_ref="/hasurlprotocol [protocolname]", 
	desc=[[return true if url protocol is installed
@param protocolname: default to paracraft://
Examples:
/hasurlprotocol
/hasurlprotocol paracraft://     check url protocol
/if $(hasurlprotocol paracraft)==true /tip protocol installed
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local protocol_name;
		if(cmd_text and cmd_text~="") then
			protocol_name = cmd_text:gsub("[://]+","");
		end
		protocol_name = protocol_name or "paracraft";

		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UrlProtocolHandler.lua");
		local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");
		return UrlProtocolHandler:HasUrlProtocol(protocol_name)
	end,
};