--[[
Title: Command Terrain
Author(s): LiXizhi
Date: 2021/4/29
Desc: 
use the lib:
------------------------------------------------------------
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");	
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["terraingen"] = {
	name="terraingen", 
	quick_ref="/terraingen [flat|nature|paraworld|paraworldMini] [-seed value] [x y z] [radius] ", 
	desc=[[generate terrain at given world position
Please note it does not clear the previous terrain, it just generate on top of existing terrain. 
e.g.
/terraingen flat ~ ~ ~ 16
/terraingen paraworld ~ ~ ~ 32
/terraingen nature -seed 1234 ~ ~ ~
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not GameLogic.is_started) then
			return 
		end

		local generatorName;
		generatorName, cmd_text = CmdParser.ParseString(cmd_text);

		NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkGenerators.lua");
		local ChunkGenerators = commonlib.gettable("MyCompany.Aries.Game.World.ChunkGenerators");
		local gen_class = ChunkGenerators:GetGeneratorClass(generatorName or "flat");

		if(generatorName) then
			local seed;
			seed, cmd_text = CmdParser.ParseOption(cmd_text);
			if(seed == "seed") then
				seed, cmd_text = CmdParser.ParseInt(cmd_text)
			else
				seed = nil;
			end

			local generator = gen_class:new():Init(GameLogic.GetWorld(), seed or GameLogic.GetWorld():GetSeed());
			local x, y, z, radius;
			x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity or EntityManager.GetPlayer());
			radius, cmd_text = CmdParser.ParseInt(cmd_text);
			if(not x) then
				x, y, z = EntityManager.GetPlayer():GetBlockPos();
			end
			if(x and y and z) then
				radius = radius or 0;
				for cx = math.floor((x - radius)/16)*16, math.floor((x + radius)/16)*16, 16 do
					for cz = math.floor((z - radius)/16)*16, math.floor((z + radius)/16)*16, 16 do
						local chunkX, chunkZ = math.floor(cx/16), math.floor(cz/16)
						local chunk = GameLogic.GetWorld():GetChunk(chunkX, chunkZ, true)
						generator:GenerateChunk(chunk, chunkX, chunkZ, true)
					end
				end
			end
		end
	end,
};

