--[[
Title: WorldClient
Author(s): LiXizhi
Date: 2014/6/4
Desc: client side to login to the server. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/WorldClient.lua");
local WorldClient = commonlib.gettable("MyCompany.Aries.Game.Network.WorldClient");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/World.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetClientHandler.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local NetClientHandler = commonlib.gettable("MyCompany.Aries.Game.Network.NetClientHandler");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local WorldClient = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.World"), commonlib.gettable("MyCompany.Aries.Game.Network.WorldClient"));

WorldClient.class_name = "WorldClient";

function WorldClient:ctor()
end
 
 -- @param name: must be a unique name, the client side server defaults to "default"
function WorldClient:Init(name)
	self.world_generator= "null";
	self:SetName(name);
	self:PrepareNetWorkWorld();
	WorldClient._super.Init(self);

	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/PlayerManagerClient.lua");
	local PlayerManagerClient = commonlib.gettable("MyCompany.Aries.Game.Network.PlayerManagerClient");
	self.thePlayerManager =  PlayerManagerClient:new():Init(self);

	NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldTrackerClient.lua");
	WorldTrackerClient = commonlib.gettable("MyCompany.Aries.Game.World.WorldTrackerClient")
	self.worldTracker = WorldTrackerClient:new():Init(self);

	return self;
end

-- create empty local disk path. 
function WorldClient:PrepareNetWorkWorld()
	-- create a new empty world here, we will never save the world
	local worldpath = "temp/clientworld";
	ParaIO.DeleteFile(worldpath.."/");
	ParaIO.CreateDirectory(worldpath.."/");
	ParaWorld.NewEmptyWorld("temp/clientworld", 533.3333, 64);
	self.worldpath = worldpath;
end

function WorldClient:GetWorldPath()
	return self.worldpath;
end

function WorldClient:InitBlockGenerator()
	-- always use a null generator for client 
	local block_generator = self:GetChunkProvider():CreateGenerator("null");
	self:GetChunkProvider():SetGenerator(block_generator);
	ParaTerrain.GetAttributeObject():SetField("RenderTerrain",false);
	GameLogic.options.has_real_terrain = ParaTerrain.GetAttributeObject():GetField("RenderTerrain",true);
	LOG.std(nil, "info", "WorldClient", "null generator is used");
end

function WorldClient:OnPreloadWorld()
	GameLogic.SetIsRemoteWorld(true, false);

	-- initialize with null block generator that does not generate terrain. 
	-- disable real world terrain 
	local block = commonlib.gettable("MyCompany.Aries.Game.block")
	block.auto_gen_terrain_block = false;
	ParaTerrain.GetAttributeObject():SetField("RenderTerrain",false);
	GameLogic.options.has_real_terrain = false;
end

function WorldClient:SetName(name)
	self.name = name;
end

function WorldClient:GetName(name)
	return self.name;
end

function WorldClient:OnWeaklyDestroyWorld()
	WorldClient._super.OnWeaklyDestroyWorld(self);
	self:Disconnect();
end

function WorldClient:OnExit()
	WorldClient._super.OnExit(self);

	if(self.net_handler) then
		self.net_handler:Cleanup();
	end
	return self;
end

-- virtual function: Creates the chunk provider for this world. Called in the constructor. 
function WorldClient:CreateChunkProvider()
    NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkProviderClient.lua");
	local ChunkProviderClient = commonlib.gettable("MyCompany.Aries.Game.World.ChunkProviderClient");
	return ChunkProviderClient:new():Init(self);
end

function WorldClient:GetPlayerManager()
	return self.thePlayerManager;
end

-- @param params: {ip, port, thread, username, password, name, tunnelClient}
function WorldClient:Login(params)
	local ip = params.ip or "127.0.0.1";
	local port = params.port or "8099";
	-- a random username
	local username = params.username;
	local password = params.password;
	local thread = params.thread or "gl";
	LOG.std(nil, "info", "WorldClient", "Start login %s %s as username:%s", ip, port, username);
	
	self.username = username;
	self.password = password;

	-- prepare address
	-- this is a pure client, so do not listen on any port. Just start the network interface. 
	NPL.StartNetServer("127.0.0.1", "0");
	local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
	Connections:Init();
	self.net_handler = NetClientHandler:new():Init(ip, port, username, password, self, params.tunnelClient);
	self.nid = self.net_handler:GetNid();

	-- TODO: it should be the server to enable world editing mode instead of client. 
	-- For demo, we will enable it anyway for debugging. if(GameLogic.GameMode:IsEditor()) then
	self:EnableAdvancedWorldEditing(true);
end

-- whether we will edit remote world in any way we like. 
function WorldClient:EnableAdvancedWorldEditing(bEnabled)
	if(bEnabled) then
		self:AddWorldTracker(self.worldTracker);
	else
		self:RemoveWorldTracker(self.worldTracker);
	end
end
	

function WorldClient:Disconnect()
	if(self.net_handler) then
		self.net_handler:Cleanup();
	end
end

function WorldClient:IsClient()
	return true;
end

function WorldClient:Tick()
	self:GetWorldInfo():SetTotalWorldTime(self:GetWorldInfo():GetWorldTotalTime() + 1);
	self:GetPlayerManager():SendAllChunkUpdates();
end


function WorldClient:CreateClientPlayer(clientEntityId, netClientHandler)
	local entityMP = GameLogic.GetPlayerController():CreateNewClientPlayerMP(self, clientEntityId, netClientHandler or self.net_handler);
	entityMP:Attach();
	GameLogic.GetPlayerController():SetMainPlayer(entityMP);
	return entityMP;
end

function WorldClient:GetPlayer()
	return EntityManager.GetPlayer();
end

function WorldClient:RemoveEntityFromWorld(entityId)
    local entity = self:GetEntityByID(entityId);
    if (entity) then
        self:RemoveEntity(entity);
    end
    return entity;
end

function WorldClient:CreateBlockPieces(block_template, blockX, blockY, blockZ, granularity, texture_filename, cx, cy, cz)
	WorldClient._super.CreateBlockPieces(self, block_template, blockX, blockY, blockZ, granularity, texture_filename, cx, cy, cz);
	if(block_template) then
		self:GetPlayer():AddToSendQueue(Packets.PacketBlockPieces:new():Init(block_template.id, blockX, blockY, blockZ, granularity));
	end
end
