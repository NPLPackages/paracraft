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
		local function callback()
			GameLogic.QuickSave();
		end

		if GameLogic.GetFilters():apply_filters("SaveWorld", false, callback) then
			return;
		end
		callback();
	end,
};

Commands["autosave"] = {
	name="autosave", 
	quick_ref="/autosave [on|off] [mins]", 
	desc=[[automatically save the world every few mins. 
@param interval: how many minutes to auto save the world. 
e.g.
/autosave        :enable auto save
/autosave on     :enable auto save
/autosave off    :disable autosave
/autosave on 10  :enable auto save every 10 minutes
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
		local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
		local interval, bEnabled;
		bEnabled, cmd_text = CmdParser.ParseBool(cmd_text);
		if(bEnabled == false) then
			GameLogic.CreateGetAutoSaver():SetTipMode();
			GameLogic.AddBBS("autosave", L"自动保存模式关闭");
		else
			GameLogic.CreateGetAutoSaver():SetSaveMode();
			GameLogic.AddBBS("autosave", L"自动保存模式开启");
		end

		interval, cmd_text = CmdParser.ParseInt(cmd_text);
		if(interval) then
			GameLogic.CreateGetAutoSaver():SetInterval(interval);
		end
	end,
};

Commands["upload"] = {
	name="upload", 
	quick_ref="/upload", 
	desc="upload the world", 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(System.options.is_mcworld) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
			local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
			ShareWorldPage.ShowPage()
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
			local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
			WorldUploadPage.ShowPage(true);
		end
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
	quick_ref="/loadworld [-i|e|force] [worldname|url|filepath|projectId|home]", 
	mode_deny = "", -- allow load world in all game modes
	desc=[[load a world by worldname or url or filepath relative to parent directory
@param -i: interactive mode, which will ask the user whether to use existing world or not. 
@param -e: always use existing world if it exist without checking if it is up to date.  
@param -force: always use online world without checking if it is different to local.  
e.g.
/loadworld 530
/loadworld https://github.com/xxx/xxx.zip
/loadworld -i https://github.com/xxx/xxx.zip
/loadworld -e https://github.com/xxx/xxx.zip
/loadworld -force 530
/loadworld home
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);


		cmd_text = GameLogic.GetFilters():apply_filters("cmd_loadworld", cmd_text, options);

		if(not cmd_text) then
			return;
		end

		cmd_text = cmd_text:gsub("\\", "/");
		local filename = cmd_text;
		
		if(filename) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
			local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua");
			local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld");
				
			local world;
			local isHttp;

			local function LoadWorld_(world, refreshMode)
				if(world) then
					local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
						NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");

						local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
						InternetLoadWorld.LoadWorld(world, nil, refreshMode or "auto", function(bSucceed, localWorldPath)
							DownloadWorld.Close();
						end);
					end});
					-- prevent recursive calls.
					mytimer:Change(1,nil);
				else
					_guihelper.MessageBox(L"无效的世界文件");
				end
			end

			if(filename:match("^https?://")) then
				isHttp = true;
				world = RemoteWorld.LoadFromHref(filename, "self");
				DownloadWorld.ShowPage(filename);
				if(options.i) then
					-- interactive mode, which will ask the user whether to use existing world or not. 
					if(isHttp) then
						local filename = world:GetLocalFileName();
						if(ParaIO.DoesFileExist(filename)) then
							_guihelper.MessageBox(L"世界已经存在，是否重新下载?", function(res)
								if(res == _guihelper.DialogResult.Yes) then
									LoadWorld_(world, "auto");
								elseif(res == _guihelper.DialogResult.No) then
									LoadWorld_(world, "never");
								else
									DownloadWorld.Close();
								end
							end, _guihelper.MessageBoxButtons.YesNoCancel);
						end
					end
					return;
				end
				LoadWorld_(world, options.e and "never" or "auto");
			elseif(filename == "home") then
				GameLogic.CheckSignedIn(L"此功能需要登陆后才能使用",
					function(result)
						if (result) then
							NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
							local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
							local homeWorldPath = LocalLoadWorld.CreateGetHomeWorld()
							if(homeWorldPath) then
								world = RemoteWorld.LoadFromLocalFile(homeWorldPath);
								if(System.world:DoesWorldExist(homeWorldPath, true)) then
									world = RemoteWorld.LoadFromLocalFile(homeWorldPath);
									LoadWorld_(world);
								end
							end
						end
					end)
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
				LoadWorld_(world);
			end
			
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
			local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
			InternetLoadWorld.ShowPage(true)
		end
	end,
};

-- alias to /loadworld command
Commands["load"] = {
	name="load", 
	quick_ref="/load [-i|e|force] [worldname|url|filepath|projectId|home]", 
	mode_deny = "", -- allow load world in all game modes
	desc=[[load a world by worldname or url or filepath relative to parent directory
@param -i: interactive mode, which will ask the user whether to use existing world or not. 
@param -e: always use existing world if it exist without checking if it is up to date.  
@param -force: always use online world without checking if it is different to local.  
e.g.
/load 530
/load https://github.com/xxx/xxx.zip
/load -i https://github.com/xxx/xxx.zip
/load -e https://github.com/xxx/xxx.zip
/load -force 530
/load home
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		return Commands["loadworld"].handler(cmd_name, cmd_text, cmd_params);
	end,
};

Commands["terrain"] = {
	name="terrain", 
	quick_ref="/terrain -[r|remove|hole|repair|info|show|hide] [block_radius]", 
	desc=[[make or repair a terrain hole around a block radius (default to 256) of the current player position
/terrain -[remove|hole|r] 256
/terrain -repair 256    repair terrain hole
/terrain -show  show global terrain 
/terrain -hide  hide global terrain 
/terrain -info  query information about the terrain tile 
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options = {};
		local option;
		for option in cmd_text:gmatch("%s*%-(%w+)") do 
			options[option] = true;
		end

		local value = cmd_text:match("%s+(%S*)$");

		if(options.show or options.hide) then
			local attr = ParaTerrain.GetAttributeObject()
			local bIsTerrainVisible = attr:GetField("EnableTerrain", true) and attr:GetField("RenderTerrain", true);
			if(options.show and not bIsTerrainVisible) then
				attr:SetField("EnableTerrain", true)
				attr:SetField("RenderTerrain", true)

				local x, y, z = ParaScene.GetPlayer():GetPosition()
				-- we can flatten at the current height if needed
				-- ParaTerrain.Flatten(x,z, 30, 2, y, 1);
				local newY = ParaTerrain.GetElevation(x, z);
				if(newY > y) then
					ParaScene.GetPlayer():SetPosition(x, newY, z)
				end
			elseif(options.hide and bIsTerrainVisible) then
				attr:SetField("EnableTerrain", false)
				attr:SetField("RenderTerrain", false)
			end

			if(options.show) then
				if(System.options.mc and GameLogic.GetSceneContext()) then
					-- leak events to hook chain for old haqi interfaces, such as terrain painting. 
					GameLogic.GetSceneContext():SetAcceptAllEvents(false);
					System.Core.SceneContextManager:SetAcceptAllEvents(false);
				end
				NPL.load("(gl)script/apps/Aries/Creator/MainToolBar.lua");
				local MainToolBar = commonlib.gettable("MyCompany.Aries.Creator.MainToolBar")
				MainToolBar.OnClickTerrainBtn()
			end
		elseif(options.r or options.remove or options.hole or options.repair) then
			-- remove all terrain where the player stand
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
					if(ParaTerrain.IsHole(xx,zz) ~= is_making_hole) then
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
		--Desktop.ForceExit(true);
		--Desktop.OnLeaveWorld(bForceLeave, true);
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
		local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
		ParaWorldLoginAdapter:EnterWorld(true);
	end,
};

Commands["saveas"] = {
	name="saveas", 
	quick_ref="/saveas", 
	desc="save the world to another directory", 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not GameLogic.is_started) then
			return 
		end
		NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
		WorldCommon.SaveWorldAs()
	end,
};

Commands["setworldinfo"] = {
	name="setworldinfo", 
	quick_ref="/setworldinfo [-isVipWorld true|false]", 
	desc=[[set a given world tag
--this will make world accessible to only vip users
/setworldinfo -isVipWorld true    
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local option_name = "";
		while (option_name and cmd_text) do
			option_name, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option_name == "isVipWorld") then
				local isVipWorld;
				isVipWorld, cmd_text = CmdParser.ParseBool(cmd_text);
				GameLogic.options:SetVipWorld(isVipWorld);
			end
		end
	end,
};