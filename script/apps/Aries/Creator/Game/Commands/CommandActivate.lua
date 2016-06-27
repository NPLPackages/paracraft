--[[
Title: activate command
Author(s): LiXizhi
Date: 2014/3/5
Desc: activate command
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandActivate.lua");
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


Commands["activate"] = {
	name="activate", 
	quick_ref="/activate [x y z] [@entityname]", 
	desc=[[ activate a given block or entity and return its value. 
Examples:
/activate x y z   call activate function of the given block.
/activate		  default to fromEntity
/t ~2 /activate   a simple loop to activate every 2 second
]], 
	category="logic",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local x, y, z;
		x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
		if(not x) then
			-- activate entity
			local targetPlayer;
			targetPlayer, cmd_text = CmdParser.ParsePlayer(cmd_text, fromEntity);
			targetPlayer = targetPlayer or fromEntity;
			if(targetPlayer) then
				targetPlayer:OnActivated(fromEntity);
				return;
			end
		else
			-- activate block 
			fromEntity = fromEntity or EntityManager.GetPlayer();
			local block = BlockEngine:GetBlock(x,y,z);
			if(block) then
				block:OnActivated(x,y,z, fromEntity);
			end
		end
	end,
};
