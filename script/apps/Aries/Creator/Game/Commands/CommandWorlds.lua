--[[
Title: Commands
Author(s): LiXizhi
Date: 2013/2/9
Desc: slash command 
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

Commands["save"] = {
	name="save", 
	quick_ref="/save", 
	desc="save the world Ctrl+S", 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not GameLogic.is_started) then
			return 
		end
		GameLogic.QuickSave();
	end,
};

Commands["upload"] = {
	name="upload", 
	quick_ref="/upload", 
	desc="upload the world", 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
		local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
		WorldUploadPage.ShowPage(true)
	end,
};


Commands["pushworld"] = {
	name="pushworld", 
	quick_ref="/pushworld [displayname]", 
	desc=[[push current world to world stack. The world will be popped from the stack, 
when it is loaded again. 
When there are worlds on the world stack, the esc window will show a big link button to load the world
on top of stack if the current world is different from it. 
@param displayname: the text to display on the big link button which bring the user back to world on top of the stack.
e.g.
/pushworld return to portal world
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldStacks.lua");
		local WorldStacks = commonlib.gettable("MyCompany.Aries.Game.WorldStacks");
		WorldStacks:PushWorld(cmd_text);
	end,
};


Commands["loadworld"] = {
	name="loadworld", 
	quick_ref="/loadworld [worldname|url|filepath]", 
	desc=[[load a world by worldname or url or filepath relative to parent directory
e.g.
/loadworld https://github.com/xxx/xxx.zip
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		cmd_text = cmd_text:gsub("\\", "/");
		local filename = cmd_text;

		if(filename) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua");
			local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld");
				
			local world;
			if(filename:match("^https?://")) then
				world = RemoteWorld.LoadFromHref(filename, "self");
			else
				-- local worldpath = filename:gsub("%.zip$", "");
				local worldpath = commonlib.Encoding.Utf8ToDefault(filename);
				
				if(System.world:DoesWorldExist(worldpath, true)) then
					world = RemoteWorld.LoadFromLocalFile(worldpath);
				else
					if(GameLogic.current_worlddir) then
						-- search relative to current world dir. 
						local parent_dir = GameLogic.current_worlddir:gsub("[^/]+/?$", "")
						local test_worldpath = parent_dir..worldpath;
						if(System.world:DoesWorldExist(test_worldpath, true)) then
							world = RemoteWorld.LoadFromLocalFile(test_worldpath);
						end
					end
				end
			end
			if(world) then
				local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
					NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
					local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
					InternetLoadWorld.LoadWorld(world, nil, "auto");
				end});
				-- prevent recursive calls.
				mytimer:Change(1,nil);
			else
				_guihelper.MessageBox("无效的世界文件");
			end
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
			local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
			InternetLoadWorld.ShowPage(true)
		end
	end,
};


Commands["terrain"] = {
	name="terrain", 
	quick_ref="/terrain -remove", 
	desc=[[making a terrain whole around a block radius of the current player position
format: /terrain -(r|remove|hole) [block_radius]  
@param block_radius:  default to 256
e.g.: /terrain -r 256

repair terrain hole around a block radius of the current player position
format: /terrain -repair [block_radius]  
@param block_radius:  default to 256

query information about the terrain tile 
format: /terrain [-info]
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options = {};
		local option;
		for option in cmd_text:gmatch("%s*%-(%w+)") do 
			options[option] = true;
		end

		local value = cmd_text:match("%s+(%S*)$");

		-- remove all terrain where the player stand
		if(options.r or options.remove or options.hole or options.repair) then
			local cx, cy, cz = ParaScene.GetPlayer():GetPosition();
			if(value) then
				value = tonumber(value);
			end
			local radius = (value or 256)/8;

			local is_making_hole = not options.repair;

			local step = BlockEngine.blocksize*8;
			for i = -radius, radius do 
				for j = -radius, radius do 
					local xx = cx + i * step - 1;
					local zz = cz + j * step - 1;
					if(not ParaTerrain.IsHole(xx,zz)) then
						ParaTerrain.SetHole(xx,zz, is_making_hole);
						ParaTerrain.UpdateHoles(xx,zz);
					end
				end
			end
		elseif(options.info or next(options) == nil) then
			-- query info
			local cx, cy, cz = ParaScene.GetPlayer():GetPosition();
			local bx, by, bz = BlockEngine:block(cx,cy,cz)
			local tile_x, tile_z = math.floor(bx/512), math.floor(bz/512);
			local o = {
				format("block tile:%d %d", tile_x, tile_z),
				format("block offset:%d %d", bx % 512, bz % 512),
			};
			local text = table.concat(o, "\n");
			LOG.std(nil, "info", "terrain_result", text);
			_guihelper.MessageBox(text);
		end
	end,
};


Commands["loadregion"] = {
	name="loadregion", 
	quick_ref="/loadregion [x y z] [radius]", 
	desc=[[force loading a given region that contains a given point.
/loadregion ~ ~ ~
/loadregion 20000 128 20000 200
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		local x, y, z, radius;
		x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity or EntityManager.GetPlayer());
		if(x) then
			radius, cmd_text = CmdParser.ParseInt(cmd_text);
			radius = radius or 0;
			for i = x-radius, x+radius do
				for j = z-radius, z+radius do
					ParaBlockWorld.LoadRegion(GameLogic.GetBlockWorld(), i, y, j);
				end
			end
		end
	end,
};


Commands["worldsize"] = {
	name="worldsize", 
	quick_ref="/worldsize radius [center_x center_y center_z]", 
	desc=[[set the world size. mostly used on 32/64bits server to prevent running out of memory. 
Please note, it does not affect regions(512*512) that are already loaded in memory. Combine this with /loadregion command to restrict 
severing of blocks in any shape. 
@param radius: in meters such as 512. 
@param center_x center_y center_z: default to current home position. 
e.g.
/worldsize 256     
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local radius, x,y,z;
		radius, cmd_text = CmdParser.ParseInt(cmd_text);
		if(radius) then
			x,y,z = CmdParser.ParsePos(cmd_text);
			GameLogic.GetWorld():SetWorldSize(x, y, z, radius, BlockEngine.region_height, radius);
		end
	end,
};


Commands["leaveworld"] = {
	name="leaveworld", 
	quick_ref="/leaveworld [-f]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[leaving the world and back to login screen.
@param [-f]: whether to force leave without saving
examples:
/leaveworld -f		:force leaving. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local option, bForceLeave;
		option, cmd_text = CmdParser.ParseOption(cmd_text);
		if(option == "f") then
			bForceLeave = true;
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
		local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
		Desktop.OnLeaveWorld(bForceLeave, true);
	end,
};

