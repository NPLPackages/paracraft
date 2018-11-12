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
	desc=[[set a block template's attribute 
@param block_id: block id or name
@param attr_name: "speedReduction", "visible", "light", "lightvalue", 
"obstruction", "blockcamera", "climbable", etc 
e.g.
/block MovieClip visible false     :hide all movie blocks
/block 8 speedReduction 0.3
/block 62 light true
/block 52 lightvalue 8
/block ColorBlock blockcamera false
/block ColorBlock climbable true
/block ColorBlock obstruction false
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local blockid, name, value;
		blockid, cmd_text = CmdParser.ParseBlockId(cmd_text);
		if(blockid) then
			name, cmd_text = CmdParser.ParseString(cmd_text);
			if(name) then
				local block_template = block_types.get(blockid);
				if(block_template) then
					if(name == "speedReduction") then
						value, cmd_text = CmdParser.ParseInt(cmd_text);
						value = value or cmd_text;
						if(type(value) == "number") then
							block_template:SetSpeedReduction(value);
						end
					elseif(name == "visible") then
						value, cmd_text = CmdParser.ParseBool(cmd_text);
						block_template:SetVisible(value);
					elseif(name == "light") then
						value, cmd_text = CmdParser.ParseBool(cmd_text);
						block_template:SetLightValue(value and 15 or 0);
					elseif(name == "lightvalue") then
						value, cmd_text = CmdParser.ParseInt(cmd_text);
						if(value and value>=0 and value<=15) then
							block_template:SetLightValue(value);
						end
					elseif(name == "obstruction") then
						value, cmd_text = CmdParser.ParseBool(cmd_text);
						block_template:SetObstruction(value);
					elseif(name == "blockcamera") then
						value, cmd_text = CmdParser.ParseBool(cmd_text);
						block_template:SetBlockCamera(value)
					elseif(name == "climbable") then
						value, cmd_text = CmdParser.ParseBool(cmd_text);
						block_template:SetClimbable(value)
					else
						-- TODO: 
					end
				
				end
			end
		end
	end,
};
