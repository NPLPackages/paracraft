--[[
Title: CommandSet
Author(s): LiXizhi
Date: 2014/3/16
Desc: set command
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSet.lua");
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


Commands["set"] = {
	name="set", 
	quick_ref="/set [-p] [@playername] name [=] value_prompt_msg", 
	desc=[[set variable to a given entity
@param -p: if -p is used, it will pop a dialog for user input, and then resume
/set a hello world
/set a=hello world
/set -p password=Please enter password:
/tip %a%
/set a=/call return 1
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		local playerEntity;
		playerEntity, cmd_text = CmdParser.ParsePlayer(cmd_text);
		playerEntity = playerEntity or EntityManager.GetPlayer();

		local name, value;
		name, cmd_text = CmdParser.ParseString(cmd_text);
		value, cmd_text = CmdParser.ParseText(cmd_text, "=");
		value = cmd_text;

		local cmd = value:match("^%s*(/.+)$");
		if(cmd) then
			value = CommandManager:RunWithVariables(nil, cmd, fromEntity);
		end
		if(not name or not value) then
			return 
		end
		if(options.p) then
			local prompt_msg = value;
			
			local variables = playerEntity:GetVariables();
			if(variables) then
				if(fromEntity) then
					fromEntity:Pause();
				end
				-- set variable via user interface (Shall we let user enter from ChatEdit window directly?)
				NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
				local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
				EnterTextDialog.ShowPage(prompt_msg, function(result)
					variables:SetVariable(name, result);
					if(fromEntity) then
						fromEntity:Resume();
					end
				end)
			end
		else
			local variables = playerEntity:GetVariables();
			if(variables) then
				variables:SetVariable(name, value);
			end
		end
	end,
};
