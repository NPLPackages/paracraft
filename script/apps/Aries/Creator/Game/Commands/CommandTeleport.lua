--[[
Title: Commands
Author(s): LiXizhi
Date: 2013/2/9
Desc: slash command 
use the lib:
------------------------------------------------------------
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["tp"] = {
	name="tp", 
	quick_ref="/tp [x] [y] [z]", 
	desc=[[teleport to a given position. 
format: /tp [x] [y] [z]  
format: /tp [y]  -- teleport to y
format: /tp  -- teleport to current position (making a checkpoint)
format: /tp home -- teleport to home   
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options = {};
		local option;
		for option in cmd_text:gmatch("%s*%-(%w+)") do 
			options[option] = true;
		end
		
		if(cmd_text == "") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TeleportListPage.lua");
			local TeleportListPage = commonlib.gettable("MyCompany.Aries.Game.GUI.TeleportListPage");
			TeleportListPage.ShowPage(nil, true);
			return
		end
		if(System.options.is_mcworld) then
			local x, y, z = cmd_text:match("%s*(%S*)%s*(%S*)%s*(%S*)$");
		
			if(x) then
				if(x == "home") then
					x, y, z = GameLogic.GetHomePosition();
				end
			end
			x = tonumber(x);
			y = tonumber(y);
			z = tonumber(z);

			local cx, cy, cz = ParaScene.GetPlayer():GetPosition();

			if(not x and not y and not z) then
				x, y, z = cx, cy, cz;
			elseif(x and not y and not z) then
				y = x;
				x,z = cz, cz;
			elseif(x and y and not z) then
				x,z = x,y;
				if(x<64 and y <64) then
					x = x * BlockEngine.region_width;
					z = z * BlockEngine.region_width;
				end
				y = cy;
			end
			if(x and y and z) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
				local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({x=x, y=y, z=z})
				task:Run();
			end
		end
	end,
};


Commands["goto"] = {
	name="goto", 
	quick_ref="/goto [@playername] [x y z]", 
	desc=[[teleport current player to a given block position relative to given player. Similar to /tp except that it uses block position. 
format: /goto x y z  abs position
format: /goto ~ ~1 ~  relative position
format: /goto home -- teleport to home   
format: /goto [@playername] [x y z]
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		
		if(cmd_text == "") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TeleportListPage.lua");
			local TeleportListPage = commonlib.gettable("MyCompany.Aries.Game.GUI.TeleportListPage");
			TeleportListPage.ShowPage(nil, true);
			return
		end

		if(System.options.mc or System.options.is_mcworld) then
			local playerEntity, x, y, z, home;
			playerEntity, cmd_text = CmdParser.ParsePlayer(cmd_text);
			home, cmd_text = CmdParser.ParseText(cmd_text, "home");

			x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, playerEntity);
			if(home and not x) then
				-- TODO: get home pos from fromEntity
				x, y, z = GameLogic.GetHomePosition();
				x, y, z = BlockEngine:block(x, y, z);
			end
			playerEntity = playerEntity or EntityManager.GetPlayer();
			if( not x and playerEntity) then
				x, y, z = playerEntity:GetBlockPos();
			end

			if(x and y and z and playerEntity) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
				local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX=x, blockY=y, blockZ=z})
				task:Run();
			end
		end
	end,
};


Commands["home"] = {
	name="home", 
	quick_ref="/home", 
	desc="go to home born position" , 
	handler = function(cmd_name, cmd_text, cmd_params)
		local x, y, z = GameLogic.GetHomePosition();
		if(x and y and z) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
			local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({x=x, y=y, z=z})
			task:Run();
		end
	end,
};


Commands["sethome"] = {
	name="sethome", 
	quick_ref="/sethome", 
	desc="set home born position" , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(not System.options.is_mcworld) then
			return;
		end
		local x, y, z;
		x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
		GameLogic.SetHomePosition(x,y,z);
	end,
};