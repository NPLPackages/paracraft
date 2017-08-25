--[[
Title: slash commands in the chat box
Author(s): LiXizhi
Date: 2011/4/10
Desc: Slash commands begins with a slash and usually entered in the chat window.
Any game module can register their own commands, usually in their init function. There is some predefined commands defined in cmd_system
Any module
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");

-- Example of creating and registering a simple command
SlashCommand.GetSingleton():RegisterSlashCommand({name="hello", quick_ref="/hello text", desc="some description", handler = function(cmd_name, cmd_text, cmd_params)
	_guihelper.MessageBox("Hello World! "..cmd_text);
end});

-- the recommended way of creating a command
local cmd_helloworld = {
	name={"hello", "hi"},
	quick_ref="/hello [string]",
	desc="long help string here",
	handler = function(cmd_name, cmd_text, cmd_params)
		_guihelper.MessageBox("Hello World! "..cmd_text);
	end
};
SlashCommand.GetSingleton():RegisterSlashCommand(cmd_helloworld);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Command.lua");
local Command = commonlib.gettable("MyCompany.Aries.Game.Command");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local proxy_addr_templ = "(%s)%s:script/apps/Aries/Debug/GMCmd_Server.lua";


-------------------------------------
-- slash commands
-------------------------------------

-- the global instance, because there is only one instance of this object
local g_singleton;

-- array of supported slash command. each command is a table of {name={"name1", "name2"}, quick_ref="", desc="", handler = function(cmd_name, cmd_text, cmd_params) end}
local slash_command_list = {};
SlashCommand.slash_command_list = slash_command_list;
-- mapping from names to command table.
local slash_command_maps = {};
SlashCommand.slash_command_maps = slash_command_maps;

-- create new instance
function SlashCommand:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self

	o:Init();
	return o
end

-- get the global singleton.
function SlashCommand.GetSingleton()
	if(not g_singleton) then
		g_singleton = GMCmd_Server:new();
	end
	return g_singleton;
end

-- init the instance
function SlashCommand:Init()
	if(self.is_Inited) then
		return
	end
	self.is_Inited = true;
	-- each client must be associated with a gsl client object, even if none is provided.
	-- self:SetClient();
	
	-- system command is always registered
	NPL.load("(gl)script/apps/Aries/SlashCommand/cmd_system.lua");
	local SystemCmds = commonlib.gettable("MyCompany.Aries.SlashCommand.SystemCmds");
	if(SystemCmds.Register) then
		SystemCmds:Register(self)
	end
end

-- set the gsl client object
-- @param client: if nil it is the global default client object. 
function SlashCommand:SetClient(client)
	self.client = client or commonlib.gettable("Map3DSystem.GSL_client");
end

-- get the global singleton.
function SlashCommand.GetSingleton()
	if(not g_singleton) then
		g_singleton = SlashCommand:new();
	end
	return g_singleton;
end

-- register a slash command
-- @param cmd_table: a table of {name="", alter_names={"", ""}, quick_ref="", desc="", handler = function(cmd_name, cmd_text, cmd_params) end}
function SlashCommand:RegisterSlashCommand(cmd_table)
	local bHasCommand;

	if(not cmd_table.ctor) then
		-- create a new table
		cmd_table = Command:new(cmd_table);
	end

	if(type(cmd_table.name) == "string") then
		bHasCommand = SlashCommand.GetSlashCommand(cmd_table.name);
		slash_command_maps[cmd_table.name] = cmd_table;
	elseif(type(cmd_table.name) == "table") then
		local _, cmd_name;
		for _, cmd_name in ipairs(cmd_table.name) do
			bHasCommand = bHasCommand or SlashCommand.GetSlashCommand(cmd_name);
			slash_command_maps[cmd_name] = cmd_table;
		end
	end

	if(not bHasCommand) then
		slash_command_list[#slash_command_list+1] = cmd_table;
	else
		LOG.std(nil, "warn", "SlashCommand", "duplicated slash command registered: %s", commonlib.serialize_compact(cmd_table.name));
	end
end

-- Get a slash command by name
-- @param name: it can be any of its shortcut
function SlashCommand:GetSlashCommand(name)
	return slash_command_maps[name];
end

-- whether there is an existing slash command
-- @param name: this can be a string name or a table array of strings
function SlashCommand:RemoveSlashCommand(name)
	if(type(name) == "string") then
		slash_command_maps[name] = nil;
	elseif(type(name) == "table") then
		local _, cmd_name;
		for _, cmd_name in ipairs(name) do
			slash_command_maps[name] = nil;
		end
	end
end

-- show text in a scrollable manual popup window
function SlashCommand:ShowTextDialog(text)
	_guihelper.MessageBox(text);
end

-- public: call this function when user enters in the chat box
-- @param sentText: the text string to be sent
-- @return sentText, bSendMessage
function SlashCommand:Run(sentText)
	if(not sentText) then return end

	local cmd_name, cmd_text = sentText:match("^/+([%S]+)%s*(.*)$");
	if(cmd_name) then
		cmd_text = cmd_text:gsub("%s*$", "");
		return self:RunCommand(cmd_name, cmd_text);
	else
		return sentText, true;
	end
end

-- run a command by its name and text
-- @return value returned by command line. 
function SlashCommand:RunCommand(cmd_name, cmd_text, ...)
	local cmd_table =  slash_command_maps[cmd_name];
	if(cmd_table) then
		return cmd_table:Run(cmd_name, cmd_text, ...);
	else
		-- _guihelper.MessageBox("unknown command. Try /help your_command_name");
		return "";
	end
end

-- parse command
function SlashCommand:ParseParamsFromCmd(cmd_str)
	return Command:ParseParamsFromCmd(cmd_str);
end
