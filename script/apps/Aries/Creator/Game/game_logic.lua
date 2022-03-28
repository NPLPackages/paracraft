--[[
Title: main game logic goes here
Author(s): LiXizhi
Date: 2012/10/18
Desc: 
GameLogic filters:
	OnBeforeLoadBlockRegion(bContinue, x, y):OnBeforeLoadBlockRegion(bContinue, x, y): false to disable loading region from file
	OnSaveBlockRegion(x, y, type); x,y: block coordinates; type:raw/region.xml
	OnLoadBlockRegion(bContinue, x, y)
	OnUnLoadBlockRegion(bContinue, x, y)

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
GameLogic.Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TaskManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/PhysicsWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/ide/TooltipHelper.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronSimulator.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
NPL.load("(gl)script/ide/EventDispatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/World.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldSim.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameRules.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/PlayerController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Ticks.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherAgent.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/FolderManager.lua");
local FolderManager = commonlib.gettable("MyCompany.Aries.Game.GameLogic.FolderManager")
local TeacherAgent = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherAgent");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local ModManager = commonlib.gettable("Mod.ModManager");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
local npl_profiler = commonlib.gettable("commonlib.npl_profiler");
local Ticks = commonlib.gettable("MyCompany.Aries.Game.Common.Ticks");
local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local GameRules = commonlib.gettable("MyCompany.Aries.Game.GameRules");
local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options")
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local World = commonlib.gettable("MyCompany.Aries.Game.World.World");
local WorldSim = commonlib.gettable("MyCompany.Aries.Game.WorldSim")
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local NeuronSimulator = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronSimulator");
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");

-- block names enumeration
local names;
-- TODO: testing only, replace this with 
-- local BlockTerrain = ParaTerrain;
local BlockTerrain = commonlib.gettable("MyCompany.Aries.Game.Fake_ParaTerrain")
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
-- expose to global environment
_G["GameLogic"] = commonlib.gettable("MyCompany.Aries.Game.GameLogic"); 
_G["Game"] = commonlib.gettable("MyCompany.Aries.Game");

-- create class
local GameLogic = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GameLogic"));
GameLogic:Signal("WorldLoaded");
GameLogic:Signal("WorldUnloaded");
GameLogic:Signal("beforeWorldSaved");
GameLogic:Signal("WorldSaved");
GameLogic:Signal("ModeChanged", function(mode) end);
-- user has performed a given action, such as open an GUI or clicked somewhere. 
GameLogic:Signal("userActed", function(actionName) end);
GameLogic:Signal("texturePackChanged", function() end);
-- whenever a file in the current directory changed. 
GameLogic:Signal("worldFileChanged");
GameLogic:Signal("frameMoved");
-- when some UI wants to change the desktop layout significantly. 
GameLogic:Signal("desktopLayoutRequested", function(requesterName) end);
-- for code war
GameLogic:Signal("CodeWarLoadLevel");
-- called after game event is fired
GameLogic:Signal("gameEventFired", function(event, lastReturnValue) end);

-- current game mode. 
GameLogic.mode = "editor";
local game_level;

-- right hand block template id. 
GameLogic.right_hand_block_id = 1;
GameLogic.autoBackupInterval = 1000*60*10; -- 10 minutes
GameLogic.picking_dist = options.picking_dist_walkmode;

local SentientGroupIDs = commonlib.gettable("MyCompany.Aries.Game.GameLogic.SentientGroupIDs");
SentientGroupIDs.Player = 3;
SentientGroupIDs.Collectable = 5;
SentientGroupIDs.NPC = 7;
SentientGroupIDs.Mob = 7;
SentientGroupIDs.OPC = 4;

GameLogic.current_worlddir = "temp/emptyworld/";

-- one time singleton init
function GameLogic:ctor()
	self:InitAPIPath();
	NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/DefaultFilters.lua");
	local DefaultFilters = commonlib.gettable("MyCompany.Aries.Game.DefaultFilters");
	DefaultFilters:Install();

	GameLogic.GetFilters():add_filter("OnBeforeLoadBlockRegion", GameLogic.OnBeforeLoadBlockRegion);
	GameLogic.GetFilters():add_filter("OnSaveBlockRegion", GameLogic.OnSaveBlockRegion);
	GameLogic.GetFilters():add_filter("OnLoadBlockRegion", GameLogic.OnLoadBlockRegion);
	
	if(System.options.mc) then
		-- do not leak events to hook chain. 
		SceneContextManager:SetAcceptAllEvents(true);
	end
	--[[
	ParaWorldAnalytics = ParaWorldAnalytics or NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldAnalytics.lua");
	if(ParaWorldAnalytics) then
		-- ParaWorldAnalytics:staticInit()
		GameLogic:GetFilters():add_filter("user_event_stat", function(category, action, value, label)
			ParaWorldAnalytics:Send(category, action, value, label);
			return catetory;
		end)

		-- GameLogic:GetFilters():add_filter("user_behavior", function(action, value, otherParam)
		-- 	ParaWorldAnalytics:behaviorStateEnter( action, value, otherParam);
		-- 	return catetory;
		-- end)
	end
	]]
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UserJobStatistics.lua");
	local UserJobStatistics = commonlib.gettable("MyCompany.Aries.Game.Common.UserJobStatistics")
	UserJobStatistics.OnInit()
end


function GameLogic:InitAPIPath()
	-- create shortcut for major API. 
	GameLogic.BlockEngine = BlockEngine;
	GameLogic.EntityManager = EntityManager;
	GameLogic.CommandManager = CommandManager;
	GameLogic.block_types = block_types;
	GameLogic.ItemClient = ItemClient;
    GameLogic.QuestAction = QuestAction;
	GameLogic.SelectionManager = SelectionManager;

	_G["GameLogic"] = GameLogic; 
	_G["Game"] = commonlib.gettable("MyCompany.Aries.Game");

	-- register DOM for advanced editors.  
	NPL.load("(gl)script/ide/System/Core/DOM.lua");
	NPL.load("(gl)script/ide/System/Core/TableAttribute.lua");
	local TableAttribute = commonlib.gettable("System.Core.TableAttribute")
	local DOM = commonlib.gettable("System.Core.DOM")
	DOM.AddDOM("Game", function() return TableAttribute:create(MyCompany.Aries.Game) end);
	DOM.AddDOM("GameLogic", function() return TableAttribute:create(GameLogic) end);
	DOM.AddDOM("EntityManager", function() return TableAttribute:create(GameLogic.EntityManager) end);
	DOM.AddDOM("System", function() return TableAttribute:create(System) end);
	DOM.AddDOM("commonlib", function() return TableAttribute:create(commonlib) end);
	GameLogic.gameFRC = DOM.GetDOM("gameFRC");
end

-- static method called at the very beginning when paracraft start
function GameLogic.InitMod()
	ModManager:Init();
	ModManager:GetLoader():LoadAllPlugins();

	-- internal mod
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeUI.lua");
	local CodeUI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUI");
	CodeUI.InstallMod();
end

-- called by both Init() and StaticInit()
function GameLogic.InitCommon()
	math.randomseed(ParaGlobal.GetGameTime());

	NPL.load("(gl)script/apps/Aries/Creator/Game/APISandbox/CreatorAPISandbox.lua");
	local CreatorAPISandbox = commonlib.gettable("MyCompany.Aries.Game.APISandbox.CreatorAPISandbox");
	CreatorAPISandbox.Cleanup();

	GameLogic.InitMod();
	GameLogic:InitSingleton();
	
	if(not GameLogic.theParticleManager) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ParticlePoolManager.lua");
		local ParticlePoolManager = commonlib.gettable("MyCompany.Aries.Game.Effects.ParticlePoolManager");
		GameLogic.theParticleManager = ParticlePoolManager:new();
	end
	GameLogic.theParticleManager:Clear();
	GameLogic.GetShaderManager():RemoveAllPostProcessingEffects();
	GameLogic.Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

	NPL.load("(gl)script/apps/Aries/Creator/Game/World/StereoVisionController.lua");
	local StereoVisionController = commonlib.gettable("MyCompany.Aries.Game.StereoVisionController")
	StereoVisionController:InitSingleton();

	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/PlayModeController.lua");
	local PlayModeController = commonlib.gettable("MyCompany.Aries.Game.Movie.PlayModeController");
	PlayModeController:InitSingleton();
	GameLogic:Connect("ModeChanged", PlayModeController, "OnModeChanged", "UniqueConnection");

	Game.SelectionManager:Clear();

	GameLogic.CreateGetAutoSaver();

	if (not System.options.isCodepku) then
		local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
		KpChatChannel.StaticInit();

		local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
		KeepWorkItemManager.StaticInit();

		GameLogic.KeepWorkItemManager = KeepWorkItemManager;

        local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
        VisualSceneLogic.staticInit();

		if ((not System.options.isCodepku) and ParaEngine.GetAppCommandLineByParam("open_ci", false) == "true") then
			local ParacraftCI = NPL.load("(gl)script/apps/Aries/ParacraftCI/ParacraftCI.lua");
			ParacraftCI.StaticInit();
		end
	
		--local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
		--ClassManager.StaticInit();
	end

	local SchoolCenter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/SchoolCenter.lua")
	SchoolCenter.OnInt()

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMain.lua");
	local ParaWorldMain = commonlib.gettable("Paracraft.Controls.ParaWorldMain");
	ParaWorldMain:Init()

	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
	local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

	PhysicsWorld:StaticInit()
end

-- for checking desktop state after activate desktop
function GameLogic.After_OnActivateDesktop()	
	local isKeepworkSignIn = not System.options.isCodepku and GameLogic.GetFilters():apply_filters('is_signed_in');

    NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
    local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");


    if(GameLogic.IsReadOnly() and GameLogic.options:GetProjectId() and isKeepworkSignIn) then
	    local generatorName = WorldCommon.GetWorldTag("world_generator");
        if(generatorName == "paraworld")then
            NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/GameDock.lua");
            NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BuilderDock.lua");
            NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
            local GameDock = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GameDock");
            local BuilderDock = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderDock");
            local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
            GameDock.ShowPage(false);
		    BuilderDock.ShowPage(false);
		    QuickSelectBar.ShowPage(false);
        end
	end
end
-- call this when user first enters a game world.
function GameLogic.Init(worldObj)
	GameLogic.InitCommon();
	GameLogic.IsStarted = true;
	if(not GameLogic.is_one_time_inited) then
		GameLogic.is_one_time_inited = true;
		-- load creator sound wave bank
		AudioEngine.LoadSoundWaveBank("config/Aries/Audio/CreatorSound.bank.xml");
	end
	GameLogic.events = GameLogic.events or commonlib.EventSystem:new();
	GameLogic.events:ClearAllEvents();
	local attr =ParaTerrain.GetAttributeObject();

	if(GameLogic.IsReadOnly()) then
		GameLogic.SetMode("game", false); -- TODO: "survival" maybe default mode.
		attr:SetField("IsReadOnly", true);
	else
		GameLogic.SetMode("editor", false);
		attr:SetField("IsReadOnly", false);
	end
	
	attr:SetField("BlockSelectionTexture", "0:Texture/blocks/state_white.png"); -- select_block
	attr:SetField("BlockSelectionTexture", "1:Texture/blocks/state_white.png");
	attr:SetField("BlockSelectionTexture", "2:Texture/blocks/state_grey.png");
	attr:SetField("BlockSelectionTexture", "3:Texture/blocks/state_red.png");
	attr:SetField("BlockSelectionTexture", "4:Texture/blocks/state_hint.png");
	attr:SetField("BlockSelectionTexture", "5:Texture/blocks/state_green.png");
	attr:SetField("BlockSelectionTexture", "6:Texture/blocks/state_green.png");
	attr:SetField("BlockDamageTexture", "Texture/blocks/destroy.png");

	options:SetPlayerName(System.User.nid);

	block_types.init();
	block_types.update_registered_templates();

	-- world manager
	GameLogic.world = worldObj or World:new():Init(NetworkMain:GetServerManager(), WorldCommon.GetSaveWorldHandler());
	GameLogic.world:OnPreloadWorld();
	GameLogic.world_sim = WorldSim:new():Init();
	GameLogic.world_revision = WorldRevision:new():init();
	GameLogic.world_revision:Checkout();

	CommandManager:Init(true);

	MovieManager:Init();
	
	PhysicsWorld:Init()

	GameLogic.OnBeforeBlockWorldLoaded();

	local sun_light = math.min(1, 1.1-math.abs(ParaScene.GetTimeOfDaySTD()));
	ParaTerrain.SetBlockWorldSunIntensity(sun_light);

	block_types.block_history = commonlib.List:new();
	names = block_types.names;

	GameLogic.Pause();

	local bEnableGlobalTerrain = WorldCommon.GetWorldTag("global_terrain") == "true";
	local attr = ParaTerrain.GetAttributeObject()
	if(attr:GetField("EnableTerrain", true) ~= bEnableGlobalTerrain) then
		attr:SetField("EnableTerrain", bEnableGlobalTerrain)
		attr:SetField("RenderTerrain", bEnableGlobalTerrain)
	end

	BlockEngine:Connect();
	BlockEngine:SetGameLogic(GameLogic);
	GameLogic.SetBlockWorld(ParaBlockWorld.GetWorld(""));

	NeuronSimulator.Init();
	
	GameLogic.LoadGame();

	GameLogic.is_started = true;

	GameLogic.GetEvents();

	LOG.std(nil, "system", "GameLogic", "Game Logics is initialized for the current world");

	collectgarbage("collect");
end

function GameLogic.OnBeforeBlockWorldLoaded()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Image3DDisplay.lua");
	local Image3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Image3DDisplay");
	Image3DDisplay.Reset();

	NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Text3DDisplay.lua");
	local Text3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Text3DDisplay");
	Text3DDisplay.InitHeadOnTemplates(true);
end

-- get the current world. 
function GameLogic.GetWorld()
	return GameLogic.world;
end

function GameLogic.getCurrentWorldId( ... )
	local world  	= GameLogic.world
	return world.projectId or world.kpProjectId
end

function GameLogic.GetPlayerController()
	if(not GameLogic.playerController) then
		GameLogic.playerController = MyCompany.Aries.Game.PlayerController:new();
	end
	return GameLogic.playerController;
end

function GameLogic.GetPlayer()
	return EntityManager.GetPlayer();
end

function GameLogic.CreateGetAutoSaver()
	if(not GameLogic.auto_saver) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/AutoSaver.lua");
		local AutoSaver = commonlib.gettable("MyCompany.Aries.Creator.Game.AutoSaver");
		GameLogic.auto_saver = AutoSaver:new();
	end
	return GameLogic.auto_saver;
end

-- @return false to disable loading region from file
function GameLogic.OnBeforeLoadBlockRegion(bContinue, region_x, region_y)
	-- LOG.std(nil, "system", "BlockEngine", "before load block region %d %d", region_x, region_y);
	return bContinue;
end

-- @return false to disable loading region entities
function GameLogic.OnLoadBlockRegion(bContinue, region_x, region_y)
	if(not GameLogic.IsRegionLoadedFired) then
		GameLogic.loadWorldTimer = GameLogic.loadWorldTimer or commonlib.Timer:new({callbackFunc = function(timer)
			if(not GameLogic.IsRegionLoadedFired) then
				if(GameLogic.GetTickCount() > 30) then
					GameLogic.IsRegionLoadedFired = true
					LOG.std(nil, "system", "GameLogic", "OnWorldInitialRegionsLoaded");
					GameLogic.GetFilters():apply_filters("OnWorldInitialRegionsLoaded", true);
				else
					timer:Change(500);
				end
			end
		end})
		GameLogic.loadWorldTimer:Change(500);
	end
	return bContinue;
end


function GameLogic.OnSaveBlockRegion(bContinue, region_x, region_y, region_type)
	return bContinue;
end

-- this is used to secretely replace current world object, such as from a standalone world into a multplayer worldserver. 
function GameLogic.ReplaceWorld(world)
	if(GameLogic.world ~= world) then
		-- replace the old world.
		if(GameLogic.world) then
			world:ReplaceWorld(GameLogic.world);
		end
		-- now replace the world only on the scripting interface. 
		GameLogic.world = world;
		GameLogic.SetIsRemoteWorld(world:isa(MyCompany.Aries.Game.Network.WorldClient), world:isa(MyCompany.Aries.Game.Network.WorldServer));
		LOG.std(nil, "info", "GameLogic", "Game World replaced with %s", world.class_name);
	end
end

function GameLogic.GetParticleManager()
	return self.theParticleManager;
end

-- Returns the current world's current save handler
function GameLogic.GetSaveHandler()
	return GameLogic.GetWorld():GetSaveHandler();
end

-- get events
function GameLogic.GetEvents()
	if(not GameLogic.events) then
		GameLogic.events = commonlib.EventSystem:new();
	end
	return GameLogic.events;
end

-- get current user profile. 
function GameLogic.GetProfile()
	return GameLogic.profile;
end

-- get the block world raw pointer
function GameLogic.GetBlockWorld()
	if(GameLogic.blockworld)then
		return GameLogic.blockworld;
	else
		GameLogic.blockworld = ParaBlockWorld.GetWorld("");
		return GameLogic.blockworld;
	end
end

-- set current block world.
function GameLogic.SetBlockWorld(world)
	GameLogic.blockworld = world;
end

function GameLogic.GetTeacherAgent()
	return TeacherAgent;
end

-- set cody's text
-- @param text: any HTML text
-- @param target: nil or "<player>"
-- @param duration: in seconds
-- @param onclickCallback: when user clicks the teacher icon. it can be "F1"
function GameLogic.SetTipText(text, target, duration, onclickCallback)
	GameLogic.GetTeacherAgent():ShowTipText(text, duration, onclickCallback);
	GameLogic.GetTeacherAgent():ShowTipOnTarget(target, text, duration)
end

-- hide cody's text
function GameLogic.HideTipText(target)
	GameLogic.GetTeacherAgent():ShowTipText(nil);
	GameLogic.GetTeacherAgent():ShowTipOnTarget(target, "")
end

-- login a given server
-- @param server:if nil, it means the local server
function GameLogic.Login(server, callback)
	NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
	local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
	GameLogic.profile = UserProfile.GetUser(System.User.nid);
	GameLogic.profile:Login(server, callback);
end

function GameLogic.GetBlockGenerator()
	return GameLogic.world:GetChunkProvider():GetGenerator();
end

-- this function is used for loading static world without editing features. 
-- @param load_level: nil to load only blocks, 1 load NPC and neuron logics.
function GameLogic.StaticInit(load_level)
	GameLogic.InitCommon();
	GameLogic.IsStarted = true;
	block_types.init();
	block_types.update_registered_templates();
	CommandManager:Init();
	MovieManager:Init();
	GameLogic.OnBeforeBlockWorldLoaded();
	BlockEngine:Connect();
	GameLogic.SetBlockWorld(ParaBlockWorld.GetWorld(""));

	block.auto_gen_terrain_block = true;

	local sun_light = math.min(1, 1.1-math.abs(ParaScene.GetTimeOfDaySTD()));
	ParaTerrain.SetBlockWorldSunIntensity(sun_light);

	GameLogic.world = World:new({cpp_chunk = true}):Init(NetworkMain:GetServerManager(), WorldCommon.GetSaveWorldHandler());
	GameLogic.world_revision = WorldRevision:new():init();
	options:SetPlayerName(System.User.nid);

	load_level = load_level or 0;
	if(load_level ==1) then
		local attr =ParaTerrain.GetAttributeObject();
		attr:SetField("IsReadOnly", true);

		if(not GameLogic.is_one_time_inited) then
			GameLogic.is_one_time_inited = true;
			-- load creator sound wave bank
			AudioEngine.LoadSoundWaveBank("config/Aries/Audio/CreatorSound.bank.xml");
		end
		GameLogic.events = GameLogic.events or commonlib.EventSystem:new();
		GameLogic.events:ClearAllEvents();

		GameLogic.world_sim = WorldSim:new():Init();
		GameLogic.is_started = true;

		NeuronSimulator.Init();

		-- load level related. 
		GameLogic.current_worlddir = ParaWorld.GetWorldDirectory();

		ItemClient.OnInit();

		LocalNPC:Init();
		if(LocalNPC:LoadFromFile()) then
			-- local NPC file loaded. 
		end

		NeuronManager.LoadFromFile();
		EntityManager.LoadFromFile();
		GameLogic.world_sim:Load();

		GameLogic.AutoFindLoginPos();
	else
		GameLogic.world_sim = WorldSim:new():Init();
	end

	LOG.std(nil, "system", "GameLogic", "Block Game Logics static is initialized at load level %d", load_level);
end

-- find the most suitable login position. 
function GameLogic.AutoFindLoginPos()
	EntityManager.GetPlayer():AutoFindPosition(true);
end


-- clear all old game level objects. 
function GameLogic.Reset()
end

function GameLogic.NewGame()
	
end

-- return current world directory (fast)
function GameLogic.GetWorldDirectory(bx, bz)
	return GameLogic.current_worlddir;
end

-- @param bx, bz: if nil, we will use the current player position. 
-- return current world directory (fast)
function GameLogic.GetWorldDirectoryAt(bx, bz)
	if(not bx) then
		local by;
		if(EntityManager.GetPlayer()) then
			bx, by, bz = EntityManager.GetPlayer():GetBlockPos();
		end
	end
	if(bx) then
		local region = EntityManager.GetRegion(bx,bz)
		if(region) then
			return region:GetWorldDirectory()
		end
	end
	return GameLogic.current_worlddir;
end

-- load from the current world directory. 
function GameLogic.LoadGame()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
	local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	Files:ClearFindFileCache();
	-- Files:UnloadAllWorldAssets();
	Files:SafeUnloadAllAssets();

	GameLogic.IsRegionLoadedFired = nil;
	GameLogic.tickCount = 0;

	System.os.options.DisableInput(true);

	GameLogic.current_worlddir = ParaWorld.GetWorldDirectory();
	-- GameLogic.script_dir = GameLogic.current_worlddir.."script/blocks/";

	LOG.std(nil, "system", "GameLogic", "loading block world for %s", GameLogic.current_worlddir);
	
	ItemClient.OnInit();

	GameLogic.GetFilters():apply_filters("OnBeforeLoadWorld");

	LocalNPC:Init();
	if(LocalNPC:LoadFromFile()) then
		-- local NPC file loaded. 
	end

	NeuronManager.LoadFromFile();
	EntityManager.LoadFromFile();
	
	GameLogic.world_sim:Load();

	GameLogic.GetProfile():SetTotalGold(EntityManager.GetItemCount("gold_count"));

	GameLogic.AutoFindLoginPos();
	
	options:OnLoadWorld();
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipEditors.lua");
	local MovieClipEditors = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipEditors");
	MovieClipEditors.SetDefaultMovieClipPlayer()

	CameraController.OnInit();

	-- Exclude mac system beacause of crash
	if (System.os.GetPlatform() ~= 'mac') then
		GameLogic.CheckCreateFileWatcher();
	end

	GameRules:LoadFromFile();

	if(not System.options.servermode) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/SwfLoadingBar.lua");
		local SwfLoadingBar = commonlib.gettable("MyCompany.Aries.Game.GUI.SwfLoadingBar");
		SwfLoadingBar.ShowForLightCalculation(function()
			GameLogic.Resume();
			SwfLoadingBar.ShowForCodeTicks(function()
				System.os.options.DisableInput(false);	
			end)
		end);
	else
		GameLogic.Resume();
		System.os.options.DisableInput(false);
	end
	GameLogic.world:OnLoadWorld();
	ModManager:OnWorldLoad();
	GameLogic:WorldLoaded()
	GameLogic.GetFilters():apply_filters("OnWorldLoaded");

	local worldname = GameLogic.GetWorldDirectory():match("([^/\\]+)$")
	GameLogic.GetFilters():apply_filters("user_event_stat", "world", "enter:"..tostring(worldname), 3, nil);
end

function GameLogic.Pause()
	GameLogic.bIsPaused = true;
end

function GameLogic.Resume()
	GameLogic.bIsPaused = nil;
end

function GameLogic.IsPaused()
	return GameLogic.bIsPaused;
end

function GameLogic.RemoveWorldFileWatcher()
	if(GameLogic.file_watcher) then
		GameLogic.file_watcher:Destroy();
		GameLogic.file_watcher = nil;
	end
end

function GameLogic.CheckCreateFileWatcher()
	if(not GameLogic.IsReadOnly() or GameLogic.isRemote) then
		NPL.load("(gl)script/ide/FileSystemWatcher.lua");

		GameLogic.RemoveWorldFileWatcher();

		-- watch files under model/ and character/ directory and Refresh it in case they are changed
		local watcher = commonlib.FileSystemWatcher:new()
		watcher.filter = function(filename)
			return string.find(filename, ".*") and not string.find(filename, "%.svn")
		end
		watcher:AddDirectory(GameLogic.current_worlddir)
		watcher.OnFileChanged = function (msg)
			msg = GameLogic.GetFilters():apply_filters("worldFileChanged", msg);
			GameLogic:worldFileChanged(msg); -- signal
		end
		GameLogic.file_watcher = watcher;

		LOG.std(nil, "info", "game.filewatcher", "file monitor created for %s", GameLogic.current_worlddir);
	end
end

-- build resource filepath
-- @param filename: relative to current world directory. 
function GameLogic.BuildResourceFilepath(filename)
	if(filename) then
		return GameLogic.current_worlddir..filename;
	end
end

function GameLogic.ToggleGameMode()
	if(not GameLogic.options.LockedGameMode) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
		local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
		Desktop.OnActivateDesktop();
		return true;
	else
		GameLogic.AddBBS("desktop", L"编辑模式被锁定");
	end
end

function GameLogic.ToggleFly()
	if(GameMode:CanFly()) then
		GameLogic.GetPlayerController().force_can_fly = true;
		local entity = EntityManager.GetFocus();
		if(entity) then
			if(entity.disable_toggle_fly) then
				return;
			end
			if(entity:ToggleFly()) then
				GameLogic.picking_dist = options.picking_dist_flymode;
				CameraController.ToggleFly(true);
			else
				GameLogic.picking_dist = options.picking_dist_walkmode;
				CameraController.ToggleFly(false);
			end

			if System.os.IsTouchMode() then
				NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniRightKeyboard.lua");
				local TouchMiniRightKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniRightKeyboard");
				if TouchMiniRightKeyboard then
					TouchMiniRightKeyboard = TouchMiniRightKeyboard.GetSingleton();
					TouchMiniRightKeyboard:ChangeFlyBtImg()
				end
			end
		end
	end
end

function GameLogic.GetPickingDist()
	return GameLogic.picking_dist;
end

-- call this function every 1 min
function GameLogic.QuickSave()
	GameLogic.SaveAll(true);
end

function GameLogic.GetUnSavedTime()
	
end

-- @param bSaveToLastSaveFolder: whether to save block to "blockWorld.lastsave" folder
-- @param bForceSave: default to nil, if true, we will save regardless the world is readonly or remote. 
function GameLogic.SaveAll(bSaveToLastSaveFolder, bForceSave)
	if(not bForceSave and (System.World.readonly or GameLogic.isRemote)) then
		_guihelper.MessageBox(format(L"您打开的是只读世界，无法保存。是否另存为本地世界?", commonlib.Encoding.DefaultToUtf8(folderName)), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				WorldCommon.SaveWorldAs()
			end
		end, _guihelper.MessageBoxButtons.YesNo);
		return false;
	end
	if(not EnterGamePage.CheckRight("savegame")) then
		return false;
	end
	GameLogic:beforeWorldSaved();
	if(not GameLogic.world_revision:Commit()) then
		GameLogic.world_revision:Backup();
		GameLogic.world_revision:Commit(true);
	elseif(GameLogic.world_revision:GetNonBackupTime() > GameLogic.autoBackupInterval) then
		GameLogic.world_revision:Backup();
	end

	GameLogic.options:SetLastSaveTime();
	if(GameLogic.profile) then
		GameLogic.profile:SaveToDB();
	end
	ParaTerrain.SaveBlockWorld(bSaveToLastSaveFolder==true);
	if( System.options.mc ) then
		if(ParaTerrain.GetAttributeObject():GetField("EnableTerrain", true)) then
			WorldCommon.SetWorldTag("global_terrain", true);
			if(ParaTerrain.IsModified()) then
				ParaTerrain.SaveTerrain(true,true);
			end
		else
			WorldCommon.SetWorldTag("global_terrain", nil);
		end
	end

	autotips.Show(false);
	WorldCommon.SaveWorld();
	autotips.Show(true);

	GameLogic.world:OnSaveWorld();

	GameLogic.GetPlayerController():SaveToCurrentWorld();
	ItemClient.SaveToCurrentWorld();
	if(GameLogic.world_sim) then
		GameLogic.world_sim:Save();
	end
	NeuronManager.SaveToFile(bSaveToLastSaveFolder);
	EntityManager.SaveToFile(bSaveToLastSaveFolder==true);
	BroadcastHelper.PushLabel({id="GameLogic", label = format(L"保存成功 [版本:%d]", GameLogic.options:GetRevision()), max_duration=4000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	-- DailyTaskManager.AchieveTask(DailyTaskManager.task_id_list.UpdataWorld)

	ModManager:OnWorldSave();
	GameLogic.world_revision:UpdateWorldFileSize();
	GameLogic:WorldSaved(); -- signal

	GameLogic.GetFilters():apply_filters("OnSaveWrold");
end

-- let a given character to play an animation. 
-- @param params: {nid, animationName=string, facingTarget={x,y,z}}
function GameLogic.PlayAnimation(params)
	local player = EntityManager.GetFocus();
	if(player and not player:IsControlledExternally()) then
		if(params.facingTarget) then
			player:FaceTarget(params.facingTarget.x, params.facingTarget.y, params.facingTarget.z)
		end
		local anim = params.animationName or params.filename;
		if(anim) then
			player:SetAnimation(anim);
		end
	end
end

-- called before the entire NPLRuntime is restarted to a different application. 
function GameLogic.BeforeRestart(appName)
	GameLogic.GetFilters():apply_filters("OnBeforeRestart");
end

function GameLogic.Exit(bSoft)
	GameLogic.GetFilters():apply_filters("OnWillUnloadWorld");
	ModManager:OnWillLeaveWorld();

	GameLogic.IsStarted = false;
	GameLogic.SetTipText(nil);
	local playerController = GameLogic.GetPlayerController();
	if(playerController) then
		playerController:DeselectMainPlayerHandTool();
		-- playerController:FlushLocalData();
	end
	
	MovieManager:Exit();
	
	if(GameLogic.world_revision) then
		if(GameLogic.world_revision:IsModifiedAndNotBackedup()) then
			-- always backup on exit when modified
			GameLogic.world_revision:Backup();
		end
	end

	if(GameLogic.world) then
		GameLogic.world:OnExit();
	end
	if(GameLogic.world_sim) then
		GameLogic.world_sim:OnExit();
	end
	TaskManager.Clear();	
	UndoManager.Clear();
	PhysicsWorld.Clear();
	EntityManager.Clear();
	FolderManager:Clear();

	if(playerController) then
		playerController.force_can_fly = false;
	end
	
	BlockEngine:Disconnect();
	GameLogic.is_started = false;
	GameLogic.RemoveWorldFileWatcher();

	CameraController.OnExit();
	ParaTerrain.GetAttributeObject():SetField("RenderTerrain",true);
	
	if(GameLogic.env_timer) then
		GameLogic.env_timer:Change();
	end

	options:OnLeaveWorld();
	ItemClient.OnLeaveWorld();
	if(SoundManager.StopAllSounds) then
		SoundManager:StopAllSounds();
	end

	if(GameLogic.theParticleManager) then
		GameLogic.theParticleManager:Clear();
	end
	
	-- just in case there is any movie gui left. 
	ParaUI.Destroy("MovieGUIRoot");

	ModManager:OnLeaveWorld();
	GameLogic:WorldUnloaded();
	GameLogic.GetFilters():apply_filters("OnWorldUnloaded");
	
	if(GameLogic.codeGlobal) then
		GameLogic.codeGlobal:Destroy();
		GameLogic.codeGlobal = nil;
	end

	if(GameLogic.loadWorldTimer) then
		GameLogic.loadWorldTimer:Change();
		GameLogic.loadWorldTimer = nil;
	end

	GameLogic.current_worlddir = "temp/emptyworld/";
end

local slow_timer_tick = 1;

-- global sandbox user defined variables in the world. It is recreated on each world load on demand.
-- @return CodeGlobals object associated with the current world.
function GameLogic.GetCodeGlobal()
	if(not GameLogic.codeGlobal) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeGlobals.lua");
		local CodeGlobals = commonlib.gettable("MyCompany.Aries.Game.Code.CodeGlobals");
		GameLogic.codeGlobal = CodeGlobals:new();
	end
	return GameLogic.codeGlobal;
end

function GameLogic.CheckTickShiftWalkingMode()
	local focused_entity = EntityManager.GetFocus();
	if(focused_entity) then
		local shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
		if(shift_pressed and not focused_entity:IsWalking()) then
			focused_entity:ToggleWalkRun(true);
		elseif(not shift_pressed and focused_entity:IsWalking()) then
			focused_entity:ToggleWalkRun(false);
		end
	end
end

function GameLogic.GetCurrentPlayerObj()
	local entityPlayer = EntityManager.GetPlayer();
	if(entityPlayer) then
		return entityPlayer:GetInnerObject();
	end 
end

-- ensure the player never goes too high or too low. If too low, it should die in game mode. 
-- disable fly mode, if player feet is on ground
function GameLogic.CheckCurrentPlayerLocation()
	local player = GameLogic.GetCurrentPlayerObj();
	local entityPlayer = EntityManager.GetFocus();
	if(not player or not entityPlayer) then
		return;
	end
	

	local x, y, z = player:GetPosition();
	local bx,by,bz = BlockEngine:block(x, y-0.1, z);
	if(not options.has_real_terrain) then
		if(by < 0) then
			-- ensure the player never goes too high or too low. 
			if(not GameMode:WillDieWhenFallTooDeep()) then
				local _, min_y, _ = BlockEngine:real(0, 1, 0);
				player:SetPosition(x, min_y, z);
				
				if(not entityPlayer:IsFlying()) then
					-- enter fly mode
					GameLogic.ToggleFly();
				end
				local block_generator = GameLogic.GetBlockGenerator();
				if(block_generator and block_generator.is_empty_generator) then
					if(not GameLogic.IsReadOnly()) then
						-- for empty world, if we fall down, we will create one block at the bottom.
						BlockEngine:SetBlock(bx, math.max(by-1, 1), bz, block_types.names.Grass);
						player:SetPosition(x, min_y, z);
					end
				end
			else
				GameLogic.OnDead();
			end
		elseif(by > BlockEngine.region_height*2) then
			local _, min_y, _ = BlockEngine:real(0, BlockEngine.region_height*2-2, 0);
			player:SetPosition(x, min_y, z);
		end
	end

	if(entityPlayer:IsFlying() and GameLogic.options.auto_disable_fly_when_on_ground) then
		local speed = math.abs(player:GetField("VerticalSpeed", -1000));
		if(speed == 0) then
			-- disable fly mode, if player feet is on ground
			if(not BlockEngine:IsBlockFreeSpace(bx,by,bz) or (ParaTerrain.GetElevation(x,z) + 0.1)>y) then
				GameLogic.ToggleFly();
			end
		end
	end
end

-- if true, we will disable all block entity simulation on the local world. 
function GameLogic.IsRemoteWorld()
	return GameLogic.isRemote;
end

-- if true, the entity may need to send update to clients. 
function GameLogic.IsServerWorld()
	return GameLogic.isServer;
end

-- if true, we will disable all block entity simulation on the local world. 
-- @param bRemoteWorld: this is set to true, if self.world is a WorldClient type. 
function GameLogic.SetIsRemoteWorld(bRemoteWorld, bIsServerWorld)
	LOG.std(nil, "info", "GameLogic", "remote_world:%s, server_world: %s", tostring(bRemoteWorld), tostring(bIsServerWorld));
	GameLogic.isRemote = bRemoteWorld;
	GameLogic.isServer = bIsServerWorld;
end

function GameLogic:IsTick(deltaTime)
	if(not self.ticks) then
		self.ticks = Ticks:new():Init(20);
	end
	return self.ticks:IsTick(deltaTime)
end

-- the number of frame moves that has been called. 
function GameLogic.GetTickCount()
	return GameLogic.tickCount or 0;
end

GameLogic.eye_pos = {0, 0, 0};

-- @return {x, y, z} array
function GameLogic.GetEyePosition()
	return GameLogic.eye_pos;
end

-- called 30 FPS framemove.
function GameLogic.FrameMove(timer)
	if(GameLogic.IsPaused()) then
		return
	end
	-- deltaTime at most 5 FPS, on some mobile device, the movie at least animated at 5FPS. 
	local deltaTime = timer:GetDelta(200);

	if(GameLogic.gameFRC:GetField("Paused", false)) then
		local curTime = GameLogic.gameFRC:GetField("Time", 0);
		if(curTime > (GameLogic.lastGameTime or 0)) then
			deltaTime = math.min(200, curTime - (GameLogic.lastGameTime or 0));
		else
			return
		end
	end

	GameLogic.eye_pos = System.Scene.Cameras:GetCurrent():GetEyePosition()

	GameLogic.lastGameTime = GameLogic.gameFRC:GetField("Time", 0);
	GameLogic.tickCount = (GameLogic.tickCount or 0) + 1;
	
	local simDeltaTime = math.min(100,deltaTime);
	-- 20FPS simulation tick
	local bIsTick = GameLogic:IsTick(deltaTime);
	npl_profiler.perf_begin("GameLogic.FrameMove")
	
	TaskManager.FrameMove(deltaTime);

	PhysicsWorld.FrameMove(simDeltaTime);
	EntityManager.FrameMove(deltaTime);
	MovieManager:FrameMove(deltaTime);
	if(GameLogic.world_sim) then
		GameLogic.world_sim:FrameMove(simDeltaTime);
	end
	NeuronSimulator.FrameMove(deltaTime);

	if(bIsTick) then
		if(GameLogic.world:IsClient()) then
			GameLogic.world:Tick();
		else
			-- server world ticks elsewhere in servermanager. 
		end
		if( (GameLogic.world:GetWorldInfo():GetWorldTotalTime() % 20) == 0) then
			GameLogic.RefreshPlayerDensity();
			GameLogic.world_revision:Tick();
		end
	end
	
	GameLogic.CheckTickShiftWalkingMode();
	GameLogic.CheckCurrentPlayerLocation();

	CameraController.OnFrameMove();
	GameLogic:frameMoved(timer); -- signal

	npl_profiler.perf_end("GameLogic.FrameMove");
end

function GameLogic.OnDead()
	_guihelper.MessageBox(L"您已被重置回出生点。", function()
		CommandManager:RunCommand("/tp home");
	end)
end

function GameLogic.RunCommand(...)
	return CommandManager:RunCommand(...);
end

function GameLogic.RefreshPlayerDensity()
	-- only refresh when focused entity is the main player. 
	if(EntityManager.GetPlayer() == EntityManager.GetFocus()) then
		local density = options.NormalDensity;

		local player = ParaScene.GetPlayer();
		if(ParaScene.IsGlobalWaterEnabled()) then
			if(player) then
				local x, y, z = player:GetPosition();
				if(ParaTerrain.IsHole(x,z)) then
					density = options.DiveDensity;
				else
					local terrain_height = ParaTerrain.GetElevation(x,z);
					if(terrain_height > y) then
						density = options.DiveDensity;
					end
				end
			end	
		end
		player:SetDensity(density);
	end
end

-- whether we can collect items when player hit it. 
function GameLogic.CanCollectItem()
	if(GameMode:CanCollectItem()) then
		return true;
	end
end

-- @return "edit" or "game" or "movie"
function GameLogic.GetGameMode()
	if(GameMode:GetMode() == "editor") then
		return "edit"
	else
		return GameMode:GetMode();
	end
end

-- whether we can edit the world 
function GameLogic.IsReadOnly()
	return System.World.readonly or GameLogic.isRemote;
end

-- return true if read only and display a message box. 
function GameLogic.CheckReadOnly()
	if(GameLogic.IsReadOnly()) then
		_guihelper.MessageBox(L"只读世界不能进行这个操作");
		return true;
	end
end

-- set mode 
function GameLogic.SetMode(mode, bFireModeChangeEvent)
	GameLogic.GetFilters():apply_filters('set_mode', mode, bFireModeChangeEvent);

	GameLogic.mode = mode;
	GameMode:SetInnerMode(mode);
	if(bFireModeChangeEvent~=false) then
		-- deprecated: use the new ModeChanged() signal function instead. 
		GameLogic.events:DispatchEvent({type = "game_mode_change" , mode = mode,});	
		-- signal:
		GameLogic:ModeChanged(mode);
	end
end

-- call this to enter game mode and begin to spawn all kinds of creatures and display game UI 
-- @param bStrictGame: no commands, no chatting, no cheating. 
function GameLogic.EnterGameMode(bIsSurvival, bStrictGame)
	if(bIsSurvival) then
		GameLogic.SetMode("survival", true);
	elseif(bStrictGame) then
		GameLogic.SetMode("strictgame", true);
	else
		GameLogic.SetMode("game", true);
	end

	local entityPlayer = EntityManager.GetFocus();
	if( (entityPlayer and entityPlayer:IsFlying()) and not GameMode:CanFly()) then
		GameLogic.ToggleFly();
	end
end

-- call this to enter editor mode and disable game creature AI and display editor UI 
function GameLogic.EnterEditorMode()
	GameLogic.SetMode("editor", true);
end

function GameLogic.EnterTutorialMode()
	GameLogic.SetMode("tutorial", true);
end

-- call this to enter editor mode and disable game creature AI and display editor UI 
function GameLogic.EnterMovieMode()
	GameLogic.SetMode("movie", true);
end

-- get the current game mode
-- @return "game", "editor", "survival"
function GameLogic.GetMode()
	return GameLogic.mode;
end

-- return the block id in the right hand of the player. 
function GameLogic.GetBlockInRightHand()
	return GameLogic.GetPlayerController():GetBlockInRightHand();
end

function GameLogic.SetBlockInRightHand(blockid_or_item_stack)
	GameLogic.GetPlayerController():SetBlockInRightHand(blockid_or_item_stack);
end

-- create a game object at the given position. 
-- please note that all creation must ensure a closed space. 
-- @param name: tons of object types can be created.
-- @param bAddToHistory: true to add to history for a possible undo function in future. Only some object support history.
function GameLogic.CreateObject(name, x, y, z, bAddToHistory)
	if (not x) then
		x, y, z = GameLogic.GetPlayerPosition();
		y = y+0.1;
	end
	-- TODO: allow XML config file to add mod object dynamically. In future, each type may be written in a file.
	-- currently i just hard code some important types here, like "spawn_room", "teleport_column", "random_block"
	if(name == "spawn_room") then	
		local y_pos = BlockEngine.offset_y + 2;
		local bx, by, bz = BlockEngine:block(x,y_pos,z);
		
		local room_half_width, room_height, room_half_length = 2, 5, 3;
		local i, j, k;
		for i = bx-room_half_width, bx+room_half_width do
			for j = bz - room_half_length, bz + room_half_length do
				for k = by, by + room_height do
					local x_, y_, z_ = BlockEngine:real(i,k,j)
					if( i == (bx-room_half_width) or i == (bx+room_half_width) or
						j == (bz - room_half_length) or j == (bz + room_half_length) or 
						k == by or k == (by + room_height) ) then
						
						BlockTerrain.SetBlockType(x_, y_, z_, names["block"]);
					else
						BlockTerrain.SetBlockType(x_, y_, z_, names["empty"]);
					end
				end
			end
		end
		local cx, cy, cz = bx, by + 1, bz;
		GameLogic.CreateObject("spawn_point", cx, cy, cz);
		GameLogic.CreateObject("spawn_point", cx, cy+1, cz);
		GameLogic.CreateObject("spawn_point", cx, cy+2, cz);
		x, y, z = BlockEngine:real(cx, cy, cz);
		-- return the block real position where player should be spawned.
		return { x = x, y = y, z = z };
	elseif(name == "empty") then
		BlockTerrain.SetBlockType(x,y,z, names.empty);
	elseif(name == "random_block") then
		if(bAddToHistory) then
			block_types.block_history:add({x=x,y=y,z=z, new_type = names.block, last_type = nil,})
		end
		BlockTerrain.SetBlockType(x,y,z, names.block);
	elseif(name == "teleport_column") then
		BlockTerrain.SetBlockType(x,y,z, names.teleport_column);
	elseif(name == "spawn_point") then
		BlockTerrain.SetBlockType(x,y,z, names.spawn_point);
	else
		local block_id = tonumber(name);
		if(block_id) then
			local bx, by, bz = BlockEngine:block(x,y,z);
			local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = bx,blockY = by, blockZ = bz, block_id = block_id})
			task:Run();
		end
	end
end


-- undo the block creation, only for testing
function GameLogic.UndoBlock()
	local item = block_types.block_history:last();
	if(item and item.x) then
		block_types.block_history:remove(item);
		BlockTerrain.SetBlockType(item.x,item.y,item.z, names.empty);
	end
end


-- create a portal at the current player's position to the block world.
function GameLogic.CreatePortal(x, y, z)
	portal = game_level:NewPortal({x=x, y=y, z=z});
	return portal;
end

-- teleport the user to the closest block world teleport position. If there is no such a position, we will create one in the block world. 
function GameLogic.GotoBlockWorld()
	local portal = game_level:GetPortal(1);
	if(not portal) then
		local spawn_room = GameLogic.CreateObject("spawn_room")
		portal = GameLogic.CreatePortal(spawn_room.x, spawn_room.y, spawn_room.z);
	end
	if(portal) then
		GameLogic.TeleportPlayer(portal.x, portal.y, portal.z);
	end
end

-- teleport the current player to a givn position. 
function GameLogic.TeleportPlayer(x, y, z)
	ParaScene.GetPlayer():SetPosition(x, y, z);
end

function GameLogic.GetPlayerPosition()
	return ParaScene.GetPlayer():GetPosition();
end

-- is owner
function GameLogic.IsOwner()
	local nid = tostring(WorldCommon.GetWorldTag("nid"));
	return nid == "0" or nid== "" or  nid==tostring(System.User.nid);
end

-- teleport the user to the over world at the current block world position. 
function GameLogic.GotoOverworld()
	local x, y, z = GameLogic.GetPlayerPosition();
	local elev = ParaTerrain.GetElevation(x,z);
	if(y<elev)then
		GameLogic.TeleportPlayer(x, elev, z);
	end
end

-- get the nearest npc around the current player position. 
-- @param radius: we will search for all npcs within this radius. if nil, it is 6 meters
-- @return npc_object, dist: nil may be returned if not found. 
function GameLogic.GetNearestNPC(radius)
	radius = radius or 6;
	-- search for any objects within 6 meters from the current player. 
	local player = ParaScene.GetPlayer();
	local fromX, fromY, fromZ = player:GetPosition();

	local objlist = {};
	local nCount = ParaScene.GetObjectsBySphere(objlist, fromX, fromY, fromZ, radius, "biped");
	local k = 1;
	local closest = nil;
	local min_dist = 100000;
	local npc_id, instance;
	for k = 1, nCount do
		local obj = objlist[k];
		if(obj:GetDynamicField("DisplayName", "") ~= "" and obj:GetField("GroupID", 0) == 0) then
			local dist = obj:DistanceTo(player);
			if( dist < min_dist) then
				closest = obj;
				min_dist = dist;
			end
		end
	end
	if(closest) then
		return closest, min_dist
	end
end

function GameLogic.WalkForward()
	local player = EntityManager.GetFocus();
	if(player) then
		if(not player:IsControlledExternally()) then
			if(player.MoveForward) then
				player:MoveForward(0.2);
			end
		end
	end
end

-- talk with the nearest npc if any. 
function GameLogic.TalkToNearestNPC()
	local char = GameLogic.GetNearestNPC();
	if(char) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectCharacterTask.lua");
		local task = MyCompany.Aries.Game.Tasks.SelectCharacter:new({obj=char})
		task:Run();
	end
end

local last_jump_tick = 0;
local jump_key_timer;

function GameLogic.DoJump()
	local player = EntityManager.GetFocus();
	if(player and player:IsControlledExternally()) then
		return 
	end
	if(GameMode:HasJumpRestriction()) then
		if(GameLogic.GetPlayerController():IsInWater()) then
			if(not GameLogic.options.CanJumpInWater) then
				return false;
			end
		else
			if(not GameLogic.options.CanJump) then
				return false;
			elseif(not GameLogic.options.CanJumpInAir) then
 				if(GameLogic.GetPlayerController():IsInAir()) then
					return false;
				end
			end
		end
	end

	if(	options.double_click_flying and 
		GameMode:AllowDoubleClickJump()) then
		-- if already in air, double click space will disable flying
		if(not jump_key_timer) then
			jump_key_timer = commonlib.Timer:new({callbackFunc = function(timer)
				if(not ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_SPACE)) then
					jump_key_timer:Change();
					last_jump_tick = commonlib.TimerManager.GetCurrentTime();
				end
			end})
		end
		if(not jump_key_timer:IsEnabled()) then
			jump_key_timer:Change(30,30);
		end
	end

	if( options.double_click_flying and (commonlib.TimerManager.GetCurrentTime() - last_jump_tick)< options.double_click_ticks) then
		-- double click space to toggle fly
		last_jump_tick = 0;
		jump_key_timer:Change();

		if(not ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_W)) then
			GameLogic.ToggleFly();
		end
	else
		local player = EntityManager.GetFocus();
		if(player) then
			player:Jump();
		end
	end
end

-- @param mode: "add", "del"
function GameLogic.SetTouchMode(mode)
	GameLogic.touch_mode = mode or "add";
end

-- @return: "add", "del"
function GameLogic.GetTouchMode()
	return GameLogic.touch_mode or "add";
end

-- set player home position. 
-- @param x, y, z: if nil, the current player position is used. 
function GameLogic.SetHomePosition(x,y,z)
	return GameLogic.GetWorld():SetSpawnPoint(x,y,z);
end

-- get player home spawn position. 
function GameLogic.GetHomePosition()
	return GameLogic.GetWorld():GetSpawnPoint();
end

-- create get desktop entity
function GameLogic.GetDesktopEntity()
	local entity = EntityManager.GetEntity("desktop")
	if(entity) then
		return entity;
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityDesktop.lua");
		local EntityDesktop = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityDesktop")
		local entity = EntityDesktop:new():init();
		entity:SetDefaultDesktop();
		entity:Attach();
		return EntityManager.GetEntity("desktop");
	end
end


-- create get sky entity
function GameLogic.GetSkyEntity()
	local entity = EntityManager.GetEntity("sky")
	if(entity) then
		return entity;
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntitySky.lua");
		local EntitySky = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySky");
		local entity = EntitySky:new():init();
		entity:Attach();
		return EntityManager.GetEntity("sky");
	end
end

-- create get free camera entity
function GameLogic.GetFreeCamera()
	local name = "freecamera"
	local entity = EntityManager.GetEntity(name)
	if(entity) then
		return entity;
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCamera.lua");
		local EntityCamera = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera");
		local x, y, z = EntityManager.GetPlayer():GetPosition();
		local entity = EntityCamera:Create({name=name, x=x,y=y,z=z, item_id = block_types.names.TimeSeriesCamera});
		entity:HideCameraModel();
		entity:SetPersistent(false);
		entity:SetCameraCollision(true);
		entity:SetScaling(0.2); -- a smaller camera
		entity:Attach();
		return EntityManager.GetEntity(name);
	end
end	

-- may return nil if there is no home entity. 
function GameLogic.GetHomeEntity()
	return EntityManager.GetEntity("player_spawn_point") or EntityManager.GetEntity("player_spawn");
end

-- append chat message
-- @param entity: if not nil, entity display name is prepended
function GameLogic.AppendChat(text, entity)
	if(entity) then
		local name = entity:GetDisplayName();
		if(name and name~="") then
			text = name..":"..(text or "");
		end
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
	MyCompany.Aries.ChatSystem.ChatWindow.InitSystem();
	ChatChannel.AppendChat({
			ChannelIndex=ChatChannel.EnumChannels.NearBy, 
			words=text,
			fromname = "", 
			fromschool = 0, 
			fromisvip = false, 
			bHideSubject = true,
			bHideTooltip = true,
			bHideColon = true,
		});
end

-- display message such as script syntax or runtime error. 
-- @param level: default to 1, which only show in bbs window. 
function GameLogic.ShowMsg(text, level)
	if(type(text) ~= "string") then
		return;
	end
	level = level or 1;

	GameLogic.error_count = (GameLogic.error_count or 0) + 1;
	
	local date_str, time_str = commonlib.log.GetLogTimeString();

	if(level >= 1) then
		GameLogic.AppendChat(format("%s|%s", time_str, text))
	end
	if(level >= 2) then
		local short_text = text:sub(1, 60);
		GameLogic.AddBBS("game_error"..tostring(GameLogic.error_count%3), short_text, 20000, "255 0 0");
	end
end

function GameLogic.ToggleRunning(bRunning)
	if(bRunning == nil) then
		bRunning = not GameLogic.IsRunning;
	end
	local entity = EntityManager:GetFocus();
	if(entity and not entity:IsControlledExternally()) then
		if(bRunning~= GameLogic.IsRunning) then
			if( (GameLogic.options.AllowRunning and bRunning) or not bRunning) then
				GameLogic.IsRunning = bRunning;

				entity:ToggleRunning(bRunning);
				if(bRunning) then
					CameraController.AnimateFieldOfView(options.run_fov, options.slow_speed_fov);
				else
					CameraController.AnimateFieldOfView(options.normal_fov, options.slow_speed_fov);
				end
			end
		end
	end
end

local last_run_key_down_tick = 0;
local last_run_key_up_tick = 0;

function GameLogic.OnCameraFrameMove()
	if(GameLogic.IsPaused()) then
		return
	end
	CameraController.OnCameraFrameMove();

	local cur_time = commonlib.TimerManager.GetCurrentTime();
	if(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_W)) then
		last_run_key_down_tick = commonlib.TimerManager.GetCurrentTime();
		if(not GameLogic.IsRunning) then
			if((cur_time - last_run_key_up_tick) < GameLogic.options.double_click_ticks) then
				GameLogic.ToggleRunning(true);
			end
		end
	else
		if((cur_time - last_run_key_down_tick) < GameLogic.options.double_click_ticks) then
			last_run_key_up_tick = cur_time;
		end
		if(GameLogic.IsRunning) then
			GameLogic.ToggleRunning(false);
		end
	end
end


function GameLogic.GetShaderManager()
	if(not GameLogic.shader_manager) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderManager.lua");
		local ShaderManager = commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderManager");
		GameLogic.shader_manager = ShaderManager:new():Init();
	end
	return GameLogic.shader_manager;
end

-- toggle desktop view
function GameLogic.ToggleDesktop(name)
	if(name == "esc") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
		local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
		local projectId = GameLogic.options:GetProjectId();

		-- if (projectId and tonumber(projectId) == ParaWorldLoginAdapter.MainWorldId and GameLogic.IsReadOnly()) then
		-- 	ParaWorldLoginAdapter.ShowExitWorld(true);
		-- else
		-- 	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EscFramePage.lua");
		-- 	local EscFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EscFramePage");
		-- 	EscFramePage.ShowPage();
		-- end

		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EscFramePage.lua");
		local EscFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EscFramePage");
		EscFramePage.ShowPage();
	elseif(name == "builder") then
		if(GameMode:IsUseCreatorBag()) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/CreatorDesktop.lua");
			local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
			CreatorDesktop.ShowNewPage();
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InventoryPage.lua");
			local InventoryPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InventoryPage");
			InventoryPage.ShowPage();
		end
	elseif(name == "bag") then
		if(EntityManager.GetPlayer() ~= EntityManager.GetFocus()) then
			local player = EntityManager.GetFocus();
			if(player and player.inventory and player:isa(EntityManager.EntityMovable)) then
				player:OpenEditor("entity");
				return;
			end
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InventoryPage.lua");
		local InventoryPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InventoryPage");
		InventoryPage.ShowPage();
	end
end

function GameLogic.OnToggleViewBobbing(bChecked)
	options:ToggleViewBobbing(bChecked);
end

function GameLogic.OnToggleLockMouseWheel(bChecked)
	options.lock_mouse_wheel = if_else(bChecked == nil, not bChecked, bChecked);
end

-- @param text: nil to clear text on that channel.
-- e.g. GameLogic.AddBBS("channel", format("hi"), 4000, "0 255 0")
function GameLogic.AddBBS(channel, text, max_duration, color, font_size)
	BroadcastHelper.PushLabel({id=channel or "GameLogic", label = text, max_duration=max_duration or 4000, color = color or "0 255 0", scaling=1.1, bold=true, shadow=true, font_size=font_size});
end

-- @param text: text to show in the status bar.  if nil, it will clear it. 
function GameLogic.SetStatus(text)
	GameLogic.AddBBS("statusBar", text, 15000, "0 255 0");
end

function GameLogic.OnToggleUIScaling(bChecked)
	options:SetEnableAutoUIScaling(if_else(bChecked == nil, not bChecked, bChecked));
	MyCompany.Aries.Creator.Game.Desktop.DoAutoAdjustUIScaling(true);
end

-- @param IsFPSView: nil to toggle, otherwise to set
function GameLogic.ToggleCamera(IsFPSView)
	CameraController.ToggleCamera(IsFPSView);
end

-- get world simulator
function GameLogic.GetSim()
	return GameLogic.world_sim;
end

function GameLogic.GetCurrentSelection()
	return SelectBlocks.GetCurrentSelection();
end

-- filters are only used by plugins, mods. Standard customization should use Entity:event() and rule bag items.
-- some commands, or items use filters for plugin functions. 
function GameLogic.GetFilters()
	if(not GameLogic.filters) then
		NPL.load("(gl)script/ide/System/Core/Filters.lua");
		local Filters = commonlib.gettable("System.Core.Filters");
		GameLogic.filters = Filters:new();
	end
	return GameLogic.filters;
end

-- please note this function may return nil if context can not be switched since we are in the middle of some operation. 
function GameLogic.ActivateDefaultContext()
	return GameLogic.GameMode:ActivateDefaultContext();
end

function GameLogic.ActivateNullContext()
	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
	local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
	local context = AllContext:GetContext("null");
	if(context) then
		return context:activate();
	end
end

-- get current scene context
function GameLogic.GetSceneContext()
	return SceneContextManager:GetCurrentContext();
end

-- record a user action to keep track of user behavior. 
function GameLogic:UserAction(name)
	self.lastActionName = name;
	-- signal
	self:userActed(name);
end

function GameLogic:GetLastUserAction()
	return self.lastActionName;
end

-- get a translated text
function GameLogic:GetText(text)
	return options:GetText(text);
end

-- @param title: additional text to show to the user in the login box
-- @param callbackFunc: optional callback function when user actually signed in
function GameLogic.SignIn(title, callbackFunc)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
	local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
	if(ParaWorldLoginDocker) then
		ParaWorldLoginDocker.SignIn(title, callbackFunc)
	else
		if(callbackFunc) then
			callbackFunc(false);
		end
	end
end

function GameLogic.CheckSignedIn(desc, callback)
	GameLogic.GetFilters():apply_filters(
		"LoginModal.CheckSignedIn",
		false,
		desc,
		function(result)
			if (type(callback) == "function") then
				callback(result);
			end
		end
	);
end

-- global custom user or game event
-- @param bIsImmediate: if true, the code block needs to immediately process it. 
function GameLogic:event(event, bIsImmediate)
	local homeEntity = GameLogic.GetHomeEntity();
	if(homeEntity) then
		homeEntity:event(event);
	end
	local lastReturnValue = GameLogic.GetCodeGlobal():HandleGameEvent(event, bIsImmediate);
	return self:gameEventFired(event, lastReturnValue) or lastReturnValue;
end

-- @param name: vip permission to check. 
-- @param bOpenUIIfNot: if true, we will display a message box asking user to login and guide the user to activate VIP if not. 
-- @param callbackFunc: only called if user is vip and bOpenUIIfNot is true
-- return true if the user is vip
function GameLogic.IsVip(name, bOpenUIIfNot, callbackFunc, uiType)
	local bEnabled = 
		GameLogic.GetFilters():apply_filters(
			"KeepworkPermission",
			false,
			name,
			bOpenUIIfNot,
			function(result)
				if type(callbackFunc) == "function" then
					callbackFunc(result);
				end
			end,
			uiType
		);

	if not bEnabled then
		if (System.User.isVip) then
			return true;
		elseif (bOpenUIIfNot) then
			_guihelper.MessageBox(L"您需要登录并成为VIP用户，才能使用此功能")
		end
	else
		if(System.User.isVip) then
			return true;
		end
	end
end

--没有VIP不能打开功能，进行提示跳转到VIP充值界面
function GameLogic.ShowVipGuideTip(authName)
	local desc = L"您需要登录并成为VIP用户，才能使用此功能"
	if authName=="UnlimitWorldsNumber" then 
		-- L'操作被禁止了，免费用户最多只能拥有3个本地世界，请删除不要的本地世界，或者联系老师（或家长）开通权限。'
		desc = L'你目前的权限只能创建家园和一个本地世界，快去开通会员，解锁不限量创建本地世界的权限，以及更多的存储空间。'
	end
	_guihelper.MessageBox(desc, function(result)
		if result == _guihelper.DialogResult.OK then
			local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
			VipPage.ShowPage();
		end
	   
	end, _guihelper.MessageBoxButtons.OKCancel_CustomLabel_Highlight_Right, nil, nil, nil, nil, {cancel="取消",ok="开通会员"});
end

-- if the current world is social, where the current player maintains its social outfit. 
function GameLogic.IsSocialWorld()
	return Paracraft.Controls.ParaWorldMain:IsCurrentParaWorld();
end

local errorCount = 1;
function GameLogic.OnCodeError(errorMessage, stackInfo)
	errorCount=errorCount+1;
	if(errorMessage and errorCount < 10000) then
		GameLogic.AddBBS("nplError"..(errorCount%3), errorMessage:sub(1, 100), 5000, "255 0 0");
		local date_str, time_str = commonlib.log.GetLogTimeString();
		GameLogic.AppendChat(format("Error %d: %s %s", errorCount, date_str, time_str));
		GameLogic.AppendChat(errorMessage);
		if(stackInfo) then
			GameLogic.AppendChat(stackInfo);
		end
	end
end

local testCases = ""; 
function GameLogic.AppendABPath(test_case)
	if (test_case and not string.find(testCases, test_case)) then
		testCases = testCases..test_case..";";
	end
end

function GameLogic.GetABPath()
	return testCases;
end

function GameLogic.ResetABPath()
	testCases = "";
end

-- select by percentage, not accurate
function GameLogic.IsInABTest(percent)
	local divisor = math.floor(1 / percent);
	local name_hash = ParaMisc.md5(System.User.username);
	if (string.len(name_hash) == 32) then
		local num = tonumber(string.sub(name_hash, 25));
		return (num % divisor == 0);
	end
	return false;
end

-- check lesson is vip
--[[
	-- @return type 
		0.未到开放时间
		1.

]]

function GameLogic.CheckVIPItem(isVip,openTime,freeTime,freeVipSchoolTime,isSchoolTimeOnly)	
	local response = {isInTime = false,strTip = "",type = 0,}
	local server_time = QuestAction.GetServerTime()
	local year = tonumber(os.date("%Y", server_time))	
	local month = tonumber(os.date("%m", server_time))
	local day = tonumber(os.date("%d", server_time))
	local function formatTime(strTime)
		local nTime = tonumber(strTime)
		local year1 = math.floor(nTime/10000) 
		local month1 = math.floor((nTime - year1*10000)/100)   
		local day1 = nTime - year1*10000 - month1*100 
		return {year1,month1,day1}
	end

	local function checkIsInTime(strTime)
		local times={}
		for temp in string.gfind(strTime, "([^;]+)") do
			times[#times + 1] = formatTime(temp)
		end
		if #times == 0 then
			times[#times + 1] = formatTime(strTime)
		end
		local nTimeNum = #times
		local strTip = ""
		for i=1,nTimeNum do
			local temp=string.format("%d年%d月%d日",times[i][1],times[i][2],times[i][3])
			if times[i][1] > year or (times[i][1] == year and times[i][2] >month) or (times[i][1] == year and times[i][2] == month and times[i][3] > day) then
				if strTip ~= "" then
					strTip = strTip..","..temp
				else
					strTip = strTip..temp
				end				
			end			
		end
		for i=1,nTimeNum do
			local nCurTime = times[i]
			if(nCurTime[1] == year and nCurTime[2]==month and nCurTime[3]==day)then
				return true,strTip
			end
		end
		return false,strTip
	end

	if not GameLogic.IsReadOnly() then
		response.isInTime = true
		response.strTip=""
		response.type = 7 --可以进入，课程开发人员
		return response
	end

	local projectId = GameLogic.options:GetProjectId()
	GameLogic.GetFilters():apply_filters('service.keepwork_service_project.is_project_read_only',projectId,function(isReadOnly,code) 
		if(code == 1) then
			response.isInTime = true
			response.strTip=""
			response.type = 10 --可以进入，团购课程人员
			return response
		end
	end)


	if type(isSchoolTimeOnly) == "boolean" and isSchoolTimeOnly == true then
		local week_day = os.date("*t",server_time).wday-1 == 0 and 7 or os.date("*t",server_time).wday-1
		local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time)
        if week_day ~= 6 and week_day ~= 7 then
            local limit_time_stamp = today_weehours + 9 * 60 * 60 + 0 * 60
            --local limit_time_end_stamp = today_weehours + 18 * 60 * 60 + 0 * 60
			-- 临时延长到20点， 记得开学后改成18点
			local limit_time_end_stamp = today_weehours + 20 * 60 * 60 + 0 * 60
            if server_time < limit_time_stamp or server_time > limit_time_end_stamp then
                response.isInTime = false
				response.strTip=""
				response.type = 8 --是否学校专用
				return response
            end
        end		
	end

	local tOpenTime = formatTime(openTime)
	local openTimeStamp = os.time({year = tOpenTime[1], month = tOpenTime[2], day = tOpenTime[3], hour=0, minute=0, second=0})
	if server_time < openTimeStamp then
		response.isInTime = false
		response.strTip=""
		response.type = 0 
		return response --不可以进入，还没有到开放时间
	end

	if not isVip then
		response.isInTime = true
		response.strTip=""
		response.type = 1 --免费课程
		return response
	end
	local time = nil
	if GameLogic.IsVip() then
		time = freeTime or freeVipSchoolTime
	elseif System.User.isVipSchool then
		time = freeVipSchoolTime
	else
		time = freeTime
	end
	if not time then
		--GameLogic.AddBBS(nil,"没有配置课程免费时间")
		response.isInTime = false
		response.strTip=""
		response.type = 9 --没有配置免费时间，任何时间都不可以上课
		return response
	end
	local isInTime,strTip=checkIsInTime(time)	
	if  isInTime then
		response.isInTime = true
		response.strTip=""
		response.type = 2 --可以进入，正好在免费时间内
		return response
	end
	response.isInTime = false
	response.strTip= strTip
	if GameLogic.IsVip() then
		if strTip == "" then --Vip错过免费时间
			response.type = 3
		else				 
			response.type = 4 --Vip还没到免费时间
		end
		return response
	end

	if strTip == "" then
		response.type = 5 --非Vip错过免费时间
	else
		response.type = 6 --非Vip还没到免费时间
	end
	return response
end


--判断是否本地版本
function GameLogic.IsLocalVersion()
	local localVersion = ParaEngine.GetAppCommandLineByParam("localVersion", nil)    
    return localVersion == 'SCHOOL'
end

-- 判断是否校本课时间
function GameLogic.CheckCanLearn(type)
	local strType = type or "school_lesson"
	if GameLogic.IsVip() or GameLogic.KeepWorkItemManager.IsOrgVip() then
		return true
	end
	local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
	if UserPermission.IsInVipSchoolCourseDay() and UserPermission.IsInVipSchoolCourseTime() then
		return true,""
	else
		if not System.User.isVipSchool then
			strTip = "该课程是vip专属课程，需要vip权限才能学习。"
			return false, strTip
		end
		return false,"现在不是上课时间哦，请在上课时间（周一至周五7:30-18:30）内再来上课吧。"
	end
	return true
end