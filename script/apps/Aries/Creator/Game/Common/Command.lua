--[[
Title: a command object base class
Author(s): LiXizhi
Date: 2011/4/10
Desc: There are two usage of command:
	1. create a singleton of the command and register it in SlashCommand, and invoke commands via the same command object. 
		Redo/undo is not possible in this way. 
	2. create a new instance of the command object for each invocation. This is what the task manager will normally do. 
		Redo/undo is usually implemented by keeping history data locally on the instanced command object. 
		The Command's Run method is responsible to add the command to UndoManager if any. 

virtual functions:
	Run(...)
	Undo()
	Redo()

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Command.lua");
local Command = commonlib.gettable("MyCompany.Aries.Game.Command");

local cmd_table = Command:new({
	name="MyCmd", 
	quick_ref="/MyCmd [x y z] [@entityname]", 
	desc="description", 
	category="logic",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local x, y, z;
		x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
	end,
});

-------------------------------------------------------
]]
-------------------------------------
-- single command base
-------------------------------------
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local Command = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Command"));
Command:Property({"Name", "Command"});
Command:Property({"quick_ref", ""});
Command:Property({"desc", ""});

Command.name = "UnnamedCommand";
Command.category = nil;
Command.handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
	LOG.std(nil, "warn", "Command", "%s Not implemented", cmd_name)
end;

function Command:ctor()
	-- comma seperated list of mode list. 
	self.mode_deny = self.mode_deny or "game";
	self.mode_allow = self.mode_allow or "";
	if(self.isLocal==nil) then
		self.isLocal = true;
	end
end

function Command:GetName()
	return self.name;
end

-- whether the command can be executed only locally, otherwise it will be send to the server for execution. 
function Command:IsLocal()
	return self.isLocal;
end

-- only called when the player wants to run the code from console. 
-- command in blocks is always executed. 
function Command:CheckGameMode(gamemode)
	if(self.mode_deny and self.mode_deny~="" and self.mode_deny:match(gamemode)) then
		return false;
	end
	if(self.mode_allow and self.mode_allow~="" and not self.mode_allow:match(gamemode)) then
		return false;
	end
	return true;
end

-- parse command
function Command:ParseParamsFromCmd(cmd_str)
	-- in case, there is an optional [cmd_target]
	local cmd_params = {};

	local cmd_next = cmd_str;
	if(not cmd_next or cmd_next=="") then
		return cmd_params;
	end 
	
	local cmd_target, tmp = cmd_next:match("^(%S+)%s+(.*)$");
	if(cmd_target) then
		cmd_next = tmp;
		cmd_params.target = cmd_target;
	end

	-- get the optional [any_number_string_or_table_format]
	if(cmd_next:match("^{")) then
		tmp = NPL.LoadTableFromString(cmd_next);
		if(tmp) then
			if(cmd_target) then
				commonlib.partialcopy(cmd_params, tmp);
			else
				cmd_params = tmp;
			end
		end
	else
		cmd_params.value = cmd_next;
	end
	return cmd_params;
end

function Command:SetCompiler(compiler)
	self.compiler = compiler;
end

-- return text and cmd_params.
function Command:Compile(cmd_text)
	cmd_text = cmd_text or "";
	local cmd_params;
	if(self.compiler) then
		cmd_text = self.compiler:Compile(cmd_text);
	end
	cmd_params = self:ParseParamsFromCmd(cmd_text);
	return cmd_text, cmd_params;
end

-- virtual :
-- compile and run the given command and return the result. 
-- @return p1, p2: if p1 is false, then p2 is the label name where to goto. If p2 is nil, it means end of all lines. 
-- if p1 is not false, such as nil or any other value, the next command will be invoked normally. 
function Command:Run(cmd_name, cmd_text, ...)
	if(self.handler) then
		local cmd_params;
		cmd_text, cmd_params = self:Compile(cmd_text);
		if(cmd_text) then
			return self.handler(cmd_name, cmd_text, cmd_params, ...);
		else
			return "";
		end
	else
		return "";
	end
end

-- this is only for backword compatible with System.command interface. 
function Command:Call(params)
	if(self.handler) then
		return self.handler(self.name, "", params);
	else
		return "";
	end
end

--virtual :
function Command:Undo()
end

--virtual :
function Command:Redo()
end



