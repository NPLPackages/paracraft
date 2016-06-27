--[[
Title: Programming related command
Author(s): LiXizhi
Date: 2014/2/17
Desc: command program
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandProgram.lua");
-------------------------------------------------------
]]
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["return"] = {
	name="return", 
	quick_ref="/return true|integer", 
	desc=[[return a result. e.g.
/return false
/return true
/return 7
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text == "true") then
			return true;
		elseif(cmd_text:match("^%d+$")) then
			return tonumber(cmd_text);
		else
			return false;
		end
	end,
};

Commands["if"] = {
	name="if", 
	quick_ref="/if var1==var2 [/othercommand|then]", 
	desc=[[do a command if var1==var2, also support operators like < <= >= >
To embed other commands in variables use $(other command text), such as $(rand)
Examples: 
/if %name% == 0 /tip your name is 0
/if %name% == "0" /tip your name is 0
/if "%name%" == "0" /tip your name is 0
/if 2 >= 1 /tip 2>=1
/if 1 < 2 /tip 1 < 2
if $(rand)>=0.5 then
	echo ">=0.5"
else
	echo "else"
fi
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local var1, var2, other_cmd;
		local var1 = cmd_text:match("^(.*)%s+then%s*$");
		if(var1) then
			var1, op, var2 = var1:match("^([^=></]+)([=><]+)([^=></]+)$");
			other_cmd = "then";
		else
			var1, op, var2, other_cmd = cmd_text:match("^([^=></]+)([=><]+)([^=></]+)%s*(/.*)$");
		end

		if(var1 and var2 and other_cmd) then
			var1 = var1:gsub("^%s*\"?", ""):gsub("\"?%s*$", "");
			var2 = var2:gsub("^%s*\"?", ""):gsub("\"?%s*$", "");
			local bCondition;
			if(op == "==") then
				if(var1 == var2) then
					bCondition = true;
				end
			else
				var1 = tonumber(var1);
				var2 = tonumber(var2);
				if(var1 and var2) then
					if(op == ">") then
						if(var1 > var2) then
							bCondition = true;
						end
					elseif(op == ">=") then
						if(var1 >= var2) then
							bCondition = true;
						end
					elseif(op == "<") then
						if(var1 < var2) then
							bCondition = true;
						end
					elseif(op == "<=") then
						if(var1 <= var2) then
							bCondition = true;
						end
					end
				end
			end
			if(bCondition) then
				if(other_cmd ~= "then") then
					return CommandManager:Run(other_cmd, fromEntity);
				end
			else
				if(other_cmd == "then") then
					return false, "else";
				end
			end
		end
	end,
};

Commands["else"] = {
	name="else", 
	quick_ref="/else", 
	desc=[[jump to the next "else", "elseif", "fi", "end" command
examples: 
if $(rand)>=0.5 then
	echo "1"
elseif $(rand)>0.5 then
	if $(rand)>0.5 then
		echo "2.1"
	else
		echo "2.2"
	fi
	echo "2.3"
else
	echo "3"
fi

set abc=$(rand)
if %abc%<0.3 then
     echo "1"
elif %abc%<0.6 then
     echo "2"
else
     echo "4"
fi
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		return false, "if_end";
	end,
};

-- only used by CommandManager for multiline commands.
Commands["elseif"] =  {
	name="elseif", 
	quick_ref="/elseif", 
	desc=[[jump to the next "else", "elseif", "fi", "end" command]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		return false, "if_end";
	end,
};
Commands["elif"] = {
	name="elif", 
	quick_ref="/elif", 
	desc=[[jump to the next "else", "elseif", "fi", "end" command]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		return false, "if_end";
	end,
};

Commands["jumpto"] = {
	name="jumpto", 
	quick_ref="/jumpto [line_offset|end|begin]", 
	desc=[[goto a given line or start or end of line
Examples: 
/if %name% == "0" /jumpto 3
/tip your name is NOT 0
/jumpto end
/tip your name is 0
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local line_offset, label;
		line_offset, cmd_text = CmdParser.ParseInt(cmd_text);
		if(line_offset) then
			return false, line_offset;
		else
			label, cmd_text = CmdParser.ParseString(cmd_text);
			if(label) then
				return false, label;
			end
		end
	end,
};

Commands["call"] = {
	name="call", 
	quick_ref="/call [code with return value]", 
	desc=[[execute code and return value
/set %name% == /call return 1
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameRules.lua");
		local GameRules = commonlib.gettable("MyCompany.Aries.Game.GameRules");
		return GameRules:DoString(cmd_text);
	end,
};

Commands["rand"] = {
	name="rand", 
	quick_ref="/rand [from to] [-f]", 
	desc=[[return a random number between from and to. default to 0,1
@param [-f]: if specified, it means a floating point output. otherwise if from to is specified, it is an integer
example:
/rand    : random float between [0,1]
/rand  1,3  : random int 1,2,3
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameRules.lua");
		local from, to;
		from, cmd_text = CmdParser.ParseNumber(cmd_text);
		to, cmd_text = CmdParser.ParseNumber(cmd_text);
		
		if(from and to and CmdParser.ParseOption(cmd_text) ~= "f") then
			return math.random(from, to);
		else
			from = from or 0;
			to = to or 1;
			return math.random()*(to - from) + from;
		end
	end,
};


Commands["function"] = {
	name="function", 
	quick_ref="/function [name]", 
	desc=[[define start of a command function 
Examples: 
function helloworld
  tip hello!
functionend
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		-- skip execution until functionend
		return false, "functionend";
	end,
};


Commands["functionend"] = {
	name="functionend", 
	quick_ref="/functionend", 
	desc=[[define end of a command function
Examples: 
function helloworld
  tip hello!
functionend
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
	end,
};

Commands["callfunction"] = {
	name="callfunction", 
	quick_ref="/callfunction [name]", 
	desc=[[invoke a local function defined anywhere inside the current command list. 
and return what the function returns
Examples: 
function helloworld
  tip hello!
functionend

callfunction helloworld
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(cmd_text and cmd_text~="") then
			local bFound, res = CommandManager:CallFunction(nil, cmd_text, nil, fromEntity);
			if(bFound) then
				return res;
			else
				LOG.std(nil, "warn", "command", "callfunction %s function not found", cmd_text);
			end
		end
	end,
};
