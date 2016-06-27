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

Commands["open"] = {
	name="open", 
	quick_ref="/open [-p] [-d] url", 
	desc=[[open url in external browser
@param -p: if -p is used, it will ask user for permission. 
@param -d: url is a directory
Examples: 
/open http://www.paraengine.com
/open -p http://www.paraengine.com
/open npl://learn	open NPL code wiki pages
/open -d temp/
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		local url = GameLogic.GetFilters():apply_filters("cmd_open_url", cmd_text);
		if(not url) then
			return;
		end
		if(options.d) then
			Map3DSystem.App.Commands.Call("File.WinExplorer", url);
		elseif(url and (url:match("^https?:") or url:match("^%w+://"))) then
			if(options.p) then
				_guihelper.MessageBox(L"你确定要打开:"..url, function()
					ParaGlobal.ShellExecute("open", url, "", "", 1);
				end)
			else
				ParaGlobal.ShellExecute("open", url, "", "", 1);
			end
		elseif(url and url~="")then
			_guihelper.MessageBox(L"只能打开http://开头的URL地址");
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