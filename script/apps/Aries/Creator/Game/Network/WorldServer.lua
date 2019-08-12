--[[
Title: WorldServer
Author(s): LiXizhi
Date: 2014/6/4
Desc: Server side class to start listening for client login and manage data sync. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/WorldServer.lua");
local WorldServer = commonlib.gettable("MyCompany.Aries.Game.Network.WorldServer");
WorldServer:new():Init(...)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/World.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/PlayerManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/EntityTracker.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ChunkProviderServer.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local ChunkProviderServer = commonlib.gettable("MyCompany.Aries.Game.World.ChunkProviderServer");
local EntityTracker = commonlib.gettable("MyCompany.Aries.Game.Network.EntityTracker");
local PlayerManager = commonlib.gettable("MyCompany.Aries.Game.Network.PlayerManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local WorldServer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.World"), commonlib.gettable("MyCompany.Aries.Game.Network.WorldServer"));

-- if true, the server world will spawn a MP player on behalf of itself and assign it to PlayerController. 
-- this is the case, where the server process is a on private server with 3D rendering.  
WorldServer.isIntegratedServer = true;
WorldServer.class_name = "WorldServer";

function WorldServer:ctor()
	self.playerEntities = commonlib.UnorderedArraySet:new();
end

-- @param name: must be a unique name, the client side server defaults to "default"
function WorldServer:Init(name, worldpath, server_manager, save_handler)
	WorldServer._super.Init(self, server_manager, save_handler);
	self.server_manager = server_manager;
	self.thePlayerManager = PlayerManager:new():Init(self, server_manager:GetViewDistance());
	self.theEntityTracker = EntityTracker:new():Init(self);
	-- simply create the default server side world tracker. 
	NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldTrackerServer.lua");
	local WorldTrackerServer = commonlib.gettable("MyCompany.Aries.Game.World.WorldTrackerServer")
	local tracker = WorldTrackerServer:new():Init(self);
	self:AddWorldTracker(tracker);
	tracker:TrackAllExistingEntities();

	ParaTerrain.GetBlockAttributeObject():SetField("IsServerWorld", true);

	GameLogic:Connect("texturePackChanged", self, self.OnTexturePackChanged, "UniqueConnection");

	return self;
end

function WorldServer:OnTexturePackChanged()
	if(self:GetServerManager()) then
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
		local texturePack = { 
			type = WorldCommon.GetWorldInfo().texture_pack_type,
			path = WorldCommon.GetWorldInfo().texture_pack_path,
			url = WorldCommon.GetWorldInfo().texture_pack_url,
			text = WorldCommon.GetWorldInfo().texture_pack_text, -- for fuzzy search
		};
		self:GetServerManager():SendPacketToAllPlayers(Packets.PacketUpdateEnv:new():Init(texturePack, nil));
	end
end

function WorldServer:ReplaceWorld(oldWorld)
	if(oldWorld) then
		self:GetChunkProvider():GetGenerator():AddPendingChunksFrom(oldWorld:GetChunkProvider():GetGenerator());
		oldWorld:OnWeaklyDestroyWorld();
	end
end

function WorldServer:OnExit()
	WorldServer._super.OnExit(self);
	self:SetDead();
	self.server_manager:Shutdown();
	ParaTerrain.GetBlockAttributeObject():SetField("IsServerWorld", false);

	GameLogic:Disconnect("texturePackChanged", self, self.OnTexturePackChanged, "UniqueConnection");
	return self;
end

function WorldServer:OnPreloadWorld()
	GameLogic.SetIsRemoteWorld(false, true);
end

function WorldServer:GetAdminUserName()
	local admin_name = System.User.username; -- or System.User.NickName
	if(not admin_name or admin_name == "") then
		admin_name = "admin"
	else
		admin_name = admin_name.."_admin";
	end
	return admin_name;
end

-- the server world will spawn a admin MP player on behalf of itself and assign it to PlayerController. 
-- this is the case, where the server process is a on private server with 3D rendering.  
function WorldServer:CreateAdminPlayer()
	if(self.isIntegratedServer) then
		
		local entityMP = self:GetServerManager():CreatePlayerForUser(self:GetAdminUserName());
		local oldPlayer = EntityManager.GetPlayer();
		if(oldPlayer) then
			entityMP:SetAdmin(true);
			entityMP:SetMainAssetPath(oldPlayer:GetMainAssetPath());
			entityMP:SetSkin(oldPlayer:GetSkin());
			entityMP:SetGravity(oldPlayer:GetGravity());
			entityMP:SetPosition(oldPlayer:GetPosition());
			if(entityMP:IsShowHeadOnDisplay() and System.ShowHeadOnDisplay) then
				System.ShowHeadOnDisplay(true, entityMP:GetInnerObject(), entityMP:GetDisplayName(), GameLogic.options.PlayerHeadOnTextColor);	
			end
		end
		entityMP:Attach();
		GameLogic.GetPlayerController():SetMainPlayer(entityMP);
	end
end

function WorldServer:GetEntityTracker()
   return self.theEntityTracker;
end

function WorldServer:GetServerManager()
	return self.server_manager;
end

function WorldServer:GetPlayerManager()
	return self.thePlayerManager;
end

-- clear in-memory data and flush to disk.  FlushToDisk is disabled on GSL lite server. 
function WorldServer:Flush()
end

-- Always load empty world for GSL lite server. For full server, this will load from BlockWorldProvider. 
function WorldServer:Load()
end

-- if baseworld md5 is same as the current one on the server, it is used.  otherwise ignored. 
function WorldServer:Login(user, baseworld_md5)
end

-- rebase the md5
function WorldServer:Rebase(md5)
end

-- called externally when this server is just stoped. 
function WorldServer:Destroy()
	self.playerEntities:clear();
end

-- run a given command
function WorldServer:RunCommand(cmd)
	if(cmd == "stop") then
		self.is_removed = true;
	else
		-- TODO:
	end
end

-- return true to remove this world server from server list. 
function WorldServer:IsRemoved()
	return self.is_removed;
end

-- remove this world server
function WorldServer:SetDead()
	self.is_removed = true;
end


function WorldServer:Tick()
	WorldServer._super.Tick(self);
	self:GetEntityTracker():UpdateTrackedEntities();
	self:GetPlayerManager():SendAllChunkUpdates();
end

function WorldServer:AddPlayerEntity(entityMP)
	self.playerEntities:add(entityMP);
end

function WorldServer:RemovePlayerEntity(entityMP)
	self.playerEntities:removeByValue(entityMP);
end

function WorldServer:GetPlayerEntities()
	return self.playerEntities;
end

function WorldServer:CreateBlockPieces(block_template, blockX, blockY, blockZ, granularity, texture_filename, cx, cy, cz)
	WorldServer._super.CreateBlockPieces(self, block_template, blockX, blockY, blockZ, granularity, texture_filename, cx, cy, cz);
	
	if(block_template) then
		self:GetPlayerManager():SendToObservingPlayers(blockX, blockY, blockZ, 
			Packets.PacketBlockPieces:new():Init(block_template.id, blockX, blockY, blockZ, granularity), self:GetPlayer());
	end
end