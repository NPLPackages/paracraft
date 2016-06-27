--[[
Title: main loop file for creator game
Author(s): LiXizhi
Date: 2012/10/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
local Game = commonlib.gettable("MyCompany.Aries.Game")
Game.Start();
-------------------------------------------------------
]]
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

	-- this is for offline mode just in case it happens.
	Map3DSystem.User.nid = Map3DSystem.User.nid or 0;

	if(not System.options.mc) then
		NPL.load("(gl)script/apps/Aries/Desktop/Areas/BattleChatArea.lua");
		MyCompany.Aries.Combat.UI.BattleChatArea.Init(true);
	end

	-- leaving the previous block world. 
	ParaTerrain.LeaveBlockWorld();

	local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
	local _vip_item_gsid = 17394;
	local bHas = ItemManager.IfOwnGSItem(_vip_item_gsid);
	paraworld.PostLog({action = "mc_enter_world", ver=System.options.version, hasright=_right},"mc_enter_world", function(msg)  end);

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
			GameLogic.Login(nil, function(msg)
				Game.OnLogin(worldObj);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end)
		end,
	};
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
