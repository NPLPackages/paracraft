--[[
Title: CommandBlockType
Author(s): LiXizhi
Date: 2014/3/5
Desc: BlockType related command
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandBlockType.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["block"] = {
	name="block", 
	quick_ref="/block block_id attr_name attr_value", 
	desc=[[ set a block attribute currently only "speedReduction" is supported. e.g.
/block block_id attr_name attr_value
/block 8 speedReduction 0.3
/block 9 speedReduction 0.3
/block 118 speedReduction 0.1
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local blockid, name, value;
		blockid, cmd_text = CmdParser.ParseBlockId(cmd_text);
		if(blockid) then
			name, cmd_text = CmdParser.ParseString(cmd_text);
			if(name) then
				value, cmd_text = CmdParser.ParseInt(cmd_text);
				value = value or cmd_text;
				local block_template = block_types.get(blockid);
				if(block_template) then
					if(name == "speedReduction") then
						if(type(value) == "number") then
							block_template:SetSpeedReduction(value);
						end
					else
						-- TODO: 
					end
				
				end
			end
		end
	end,
};
