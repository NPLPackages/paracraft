--[[
Title: main loop file for creator game
Author(s): LiXizhi
Date: 2012/10/18
Desc: 
```
npl servermode="true" world="worlds/DesignHouse/test" ip="0.0.0.0" port="6001" autosave="10" mc="true" bootstrapper="script/apps/Aries/Creator/Game/main.lua"
```
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
local Game = commonlib.gettable("MyCompany.Aries.Game")
Game.Start();
-------------------------------------------------------
]]
-- load paracraft packages if any
if(ParaEngine.GetAppCommandLineByParam("isDevEnv", "") == "" and ParaEngine.GetAppCommandLineByParam("src_paraworldapp", "")=="") then
	NPL.load("npl_packages/paracraft/");
end
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("(gl)script/kids/ParaWorldCore.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local GameLevel = commonlib.gettable("MyCompany.Aries.Game.GameLevel")
local Player = commonlib.gettable("MyCompany.Aries.Player");

-- create class
local Game = commonlib.gettable("MyCompany.Aries.Game")

-- clear all folders in user download directory
function Game.CleanupUserDownloadFolder()
	NPL.load("(gl)script/ide/Files.lua");
	local root_folder = "worlds/DesignHouse/userworlds/"
	local result = commonlib.Files.Find({}, root_folder, 0, 1000, "*");
	for _, file in ipairs(result) do 
		if(file.filename:match("%.zip$")) then
			-- accessdate="2014-1-17-18-54"
			if(file.accessdate) then
				-- TODO: delete files that is no longer accessed. 
			end
		else
			local filename = root_folder..file.filename.."/";
			ParaIO.DeleteFile(filename);
			LOG.std(nil, "info", "Game", "clean up folder %s", filename);
		end
	end
end

-- one time static init
function Game.OnStaticInit()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/DamageSource.lua");
	local DamageSource = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld.DamageSource")
	DamageSource:StaticInit();

	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
	local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
	PlayerAssetFile:Init();
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
	local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
	PlayerSkins:Init();
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
	local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
	CustomCharItems:Init();
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
	local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
	SoundManager:Init();
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
	local EntityAnimation = commonlib.gettable("MyCompany.Aries.Game.Effects.EntityAnimation");
	EntityAnimation.Init();
	
	-- change default height
	ParaTerrain.GetAttributeObject():SetField("DefaultHeight", -1000);
end

-- @param callbackFunc: callback function when world is fully loaded
function Game.StartEmptyClientWorld(worldClient, callbackFunc)
	return Game.Start(worldClient, nil, nil, nil, nil, callbackFunc);
end

-- start and reload a given game
-- @param filename_or_world: can be filename for local world. or a WorldClient Object
-- @param is_standalone: for local world, this shall be true. default to false
function Game.Start(filename_or_world, is_standalone, force_nid, gs_nid, ws_id, callbackFunc)
	local filename;
	local worldObj;
	local isRemoteWorld;
	if(type(filename_or_world) == "string" or not filename_or_world) then
		filename = filename_or_world or "worlds/MyWorlds/flatgrassland";
		worldObj = nil;
	else
		worldObj = filename_or_world;
		filename = worldObj:GetWorldPath(); 
		isRemoteWorld = worldObj:IsClient();
	end
	
	GameLogic:InitSingleton();

	-- exit last game if any
	Game.Exit();

	Game.OnStaticInit();

	-- load scene
	local commandName = System.App.Commands.GetDefaultCommand("LoadWorld");
	
	if(Player.EnterEnvEditMode) then
		Player.EnterEnvEditMode(true);
	end
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_mcml.lua");
	MyCompany.Aries.Game.mcml_controls.register_all();

	-- mcml v2
	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/mcml.lua");
	MyCompany.Aries.Game.mcml2.mcml_controls.register_all();

	-- this is for offline mode just in case it happens.
	System.User.nid = System.User.nid or 0;

	if(not System.options.mc) then
		NPL.load("(gl)script/apps/Aries/Desktop/Areas/BattleChatArea.lua");
		MyCompany.Aries.Combat.UI.BattleChatArea.Init(true);
	end

	-- leaving the previous block world. 
	ParaTerrain.LeaveBlockWorld();

	-- paraworld.PostLog({action = "mc_enter_world", ver=System.options.version, hasright=_right},"mc_enter_world", function(msg)  end);

	if(filename:match("^worlds/DesignHouse/userworlds/")) then
		Game.CleanupUserDownloadFolder();
	end
	
	if(System.options.version == "teen") then
		-- tricky: always use 0.5 scaling for teen character unless in combat
		NPL.load("(gl)script/apps/Aries/Pet/main.lua");
		local Pet = commonlib.gettable("MyCompany.Aries.Pet");
		Pet.ResetDefaultScaling(0.5, 1.2, 1.2);
	end

	-- totally disable terrain in mc version
	if(System.options.mc) then
		ParaTerrain.GetAttributeObject():SetField("EnableTerrain", false);
	end
	Game.loadworld_params = {
		name = "mcworld", tag="MCWorld",
		worldpath = filename, 
		is_standalone = is_standalone,
		isRemoteWorld = isRemoteWorld,
		nid = force_nid,
		gs_nid = gs_nid, ws_id = ws_id,
		on_finish = function()
			if(System.World.worldzipfile) then
				NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
				local ZipFile = commonlib.gettable("System.Util.ZipFile");
				local zipFile = ZipFile:new();
				if(zipFile:open(System.World.worldzipfile)) then
					zipFile:addUtf8ToDefaultAlias();
					-- zipFile:close();
				end
			end
			GameLogic.Login(nil, function(msg)
				Game.OnLogin(worldObj);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end)
		end,
	};

	LOG.std(nil,"debug","GameStart",commandName);
	LOG.std(nil,"debug","Game.loadworld_params",Game.loadworld_params);

	System.App.Commands.Call(commandName, Game.loadworld_params);
end

-- return the parameter table that is used to load the current world.
function Game.GetLoadWorldParams()
	return Game.loadworld_params;
end

-- after logged in. 
function Game.OnLogin(worldObj)
	NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local world_tag = WorldCommon.LoadWorldTag();

	-- now the low level game engine world is loaded. 
	Game.worldpath = ParaWorld.GetWorldDirectory();

	-- init game logics under the current world directory
	GameLogic.Init(worldObj);
	
	if(not System.options.mc) then		
		-- clear cursor selection to be compatible with public world.
		MyCompany.Aries.HandleMouse.ClearCursorSelection();
	end

	NPL.load("(gl)script/apps/Aries/Creator/ToolTipsPage.lua");
	MyCompany.Aries.Creator.ToolTipsPage.isExpanded = false;
	-- MyCompany.Aries.Creator.ToolTipsPage.ShowPage("getting_started_mc");
	
	-- init desktop and UI
	Desktop.OnActivateDesktop(GameLogic.GetMode());


	-- mark as started. 
	Game.is_started = true;
	
	if(not System.options.mc) then
		-- play bg music
		MyCompany.Aries.Scene.PlayRegionBGMusic("ambForest");

		NPL.load("(gl)script/apps/Aries/Scene/AutoCameraController.lua");
		MyCompany.Aries.AutoCameraController:ApplyStyle({
			min_dist=1.5, min_liftup_angle=0, max_liftup_angle=1.57,
			adjust_dist_step_percentage = 0.2,
			adjust_angle_step_percentage = 0.2,
			CameraRollbackSpeed = 3,
			disable_delay_adjustment = true,
		});
	end
			
	GameLogic.ToggleCamera(false);
	
	if(not System.options.mc) then		
		-- hide pet
		MyCompany.Aries.Player.SendCurrentPetToHome();
		-- disable mount pet
		MyCompany.Aries.Pet.EnterIndoorMode(Map3DSystem.User.nid);
	end		

	Game.mytimer = Game.mytimer or commonlib.Timer:new({callbackFunc = Game.FrameMove})
	Game.mytimer:Change(30,30);

    GameLogic.After_OnActivateDesktop();
	LOG.std(nil, "info", "Game", "Game.OnLogin finished");
end

-- exit the current game
function Game.Exit()
	Desktop.CleanUp();
	Game.is_started = false;
	GameLogic.Exit();

	-- enable mount pet
	if(not System.options.mc) then
		MyCompany.Aries.Pet.LeaveIndoorMode(Map3DSystem.User.nid)
	end

	if(Game.mytimer) then
		Game.mytimer:Change();
	end

	if(System.options.version == "teen") then
		-- tricky: always use 0.5 scaling for teen character unless in combat
		NPL.load("(gl)script/apps/Aries/Pet/main.lua");
		local Pet = commonlib.gettable("MyCompany.Aries.Pet");
		Pet.ResetDefaultScaling(0.8, 1.6105, 1.6105);
	end
end

-- @param mode: "game", "edit"
function Game.ChangeMode(mode)
end

-- the main game loop
function Game.FrameMove(timer)
	GameLogic.FrameMove(timer);
end

function Game.StartServer(worldpath)
	System.options.mc = true;
	System.options.cmdline_world = System.options.cmdline_world or ParaEngine.GetAppCommandLineByParam("world","");
	worldpath = worldpath or System.options.cmdline_world;

	Game.Start(worldpath, nil, 0, nil, nil, function()
		LOG.std(nil, "info", "Game", "server mode load world: %s", worldpath);
		NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
		local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
		CommandManager:Init();
		local ip = ParaEngine.GetAppCommandLineByParam("ip", "0.0.0.0");
		local port = ParaEngine.GetAppCommandLineByParam("port", "");
		local autosaveInterval = ParaEngine.GetAppCommandLineByParam("autosave", "");
		-- Fixed onsoleted code, we have done this in c++: UseAsyncLoadWorld must be set to false in server mode, otherwise server chunks can not be served properly. 
		-- GameLogic.RunCommand("property", "UseAsyncLoadWorld false");
		GameLogic.RunCommand("startserver", ip.." "..port);
				
		if(autosaveInterval and autosaveInterval~="") then
			if(autosaveInterval == "true") then
				autosaveInterval = "";
				GameLogic.RunCommand("autosave", "on");
			elseif(autosaveInterval:match("^%d+$")) then
				GameLogic.RunCommand("autosave", "on "..autosaveInterval);
			else
				GameLogic.RunCommand("autosave", autosaveInterval);
			end
		end
	end);
end

-- handle load world command
function Game.handleLoadWorldCmd(params)
	System.options.is_mcworld = true;
	LOG.std(nil, "info", "Game", "Load World from %s", params.worldpath);
	ParaTerrain.GetAttributeObject():SetField("EnableTerrain", false);

	local errMsg;
	params.res, errMsg = System.Scene.World:LoadWorld({
		worldpath = params.worldpath,
	})
	ParaTerrain.GetBlockAttributeObject():SetField("IsRemote", params.isRemoteWorld == true);

	if(params.res and type(params.on_finish) == "function") then
		params.on_finish(params.res);
	end
	if(not params.res) then
		LOG.std(nil, "warn", "loadWorldCmd", "failed to load %s because %s", params.worldpath, errMsg or "");
	end
	return params.res, errMsg;
end

-- only for server mode.
local function activate()
	if(not Game.main_state) then
		Game.main_state = "started";
		System.options.mc = true;
		System.options.servermode = ParaEngine.GetAppCommandLineByParam("servermode", "true") == "true";
		System.init();
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Command.lua");
		local Command = commonlib.gettable("MyCompany.Aries.Game.Command");
		local cmdLoadWorld = Command:new({
			name="Paracraft.LoadWorld", 
			handler = function(cmd_name, cmd_text, cmd_params)
				Game.handleLoadWorldCmd(cmd_params);
			end,
		});
		System.App.Commands.Add(cmdLoadWorld);
		-- change the load world command to use our own module
		System.App.Commands.SetDefaultCommand("LoadWorld", cmdLoadWorld.name);

		Game.StartServer();
	end
end
NPL.this(activate);