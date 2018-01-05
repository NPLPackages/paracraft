--[[
Title: Block commands
Author(s): Dummy
Date: 2017/12/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandBuildTask.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CheckPointIO.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCheckpoint.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/CheckpointListPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");


local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");


local BuildQuest = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local BuildQuestProvider =  commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");

Commands["buildtask"] = {
	name="buildtask",  
	quick_ref="/buildtask ", 
	desc=[[
/buildtask start x y z [-free] [src=filename] 
//buildtask  start 19203 4 19200 {src="aaa1.bmax"} -free
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		

		
		local cp_options, cmd_text = CmdParser.ParseString(cmd_text);
		
		if cp_options == "start" then
			local to_x, to_y, to_z;
			to_x, to_y, to_z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			
			if to_x and to_y and to_z then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
				local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX = to_x,blockY = to_y, blockZ = to_z});
				task:Run();
			end	
			
			local cmd_table;
			cmd_table, cmd_text = CmdParser.ParseTable(cmd_text);
			
			local options;
			options, cmd_text = CmdParser.ParseOptions(cmd_text);			
		
			--"blocktemplates/aaa1.bmax";
			if cmd_table.src then
				local task = BuildQuestProvider.getCustomBmaxTask(GameLogic.current_worlddir .. cmd_table.src);
				if(task) then
					BuildQuest:new({isCustomBuild = true, 
									isFree = options.free,
									task = task, 
									custom_src = GameLogic.current_worlddir .. cmd_table.src,
									finished_name = cmd_table.dst or cmd_table.src}):Run();
				end
			end
			
		elseif cp_options == "end" then
			GameLogic.RunCommand("/quest finish");
		end
	end,
};