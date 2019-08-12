--[[
Title: entity player multiplayer client
Author(s): LiXizhi
Date: 2014/6/29
Desc: the main player entity on the client side. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPClient.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayer.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayer"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPClient"));

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

-- player is always framemoved as fast as possible
Entity.framemove_interval = 0.01;

function Entity:ctor()
	self.rotationYawHead = 0;
	self.rotationYawPitch = 0;
	self.isNearbyChunkLoaded = false;
end

-- @param entityId: this is usually from the server. 
function Entity:init(world, netHandler, entityId)
	self:SetEntityId(entityId);
	self:SetUserName(netHandler:GetUserName());
	self:SetDisplayName(netHandler:GetUserName());
	self.worldObj = world; -- Entity._super.init(self, world);
	self.netHandler = netHandler;
	self.oldPosX = 0;
	self.oldPosY = 0;
	self.oldPosZ = 0;
	self.oldRotationYaw = 0;
	self.oldRotationPitch = 0;
	self.motionUpdateTickCount = 0;
	self.oldRotHeadYaw = 0;
	self.oldRotHeadPitch = 0;

	local x, y, z = world:GetSpawnPoint();
	self:SetLocationAndAngles(x, y, z, 0, 0);

	self:CreateInnerObject();
	self:RefreshClientModel();

	self:SetGravity(GameLogic.options:GetGravity());
	return self;
end

function Entity:IsShowHeadOnDisplay()
	return true;
end

function Entity:doesEntityTriggerPressurePlate()
	return false;
end

function Entity:CreateInnerObject(...)
	local obj = Entity._super.CreateInnerObject(self, self:GetMainAssetPath(), true, 0, 1);

	if(self:IsShowHeadOnDisplay() and System.ShowHeadOnDisplay) then
		System.ShowHeadOnDisplay(true, obj, self:GetDisplayName(), GameLogic.options.PlayerHeadOnTextColor);	
	end
	return obj;
end

-- framemove this entity when it is riding (mounted) on another entity. 
-- we will update according to mounted entity's position. 
function Entity:FrameMoveRidding(deltaTime)
	Entity._super.FrameMoveRidding(self, deltaTime);

	self:SendMotionUpdates();
end

-- Called to update the entity's position/logic.
function Entity:FrameMove(deltaTime)
	Entity._super.FrameMove(self, deltaTime);
        
    if (self:IsRiding()) then
        -- this is never called, instead self:FrameMoveRidding() is called.  
    else
		-- LOG.std(nil, "debug", "EntityMPClient", "SendMotionUpdates entity id %d", self.entityId);
        self:SendMotionUpdates();
    end
end

-- not controlled remotely, this avoid MoveEntity to be controlled by server.
function Entity:IsRemote()
	return false;
end

function Entity:MoveEntity(deltaTime)
	Entity._super.MoveEntity(self, deltaTime);	
end

function Entity:IsNearbyChunkLoaded()
	return self.isNearbyChunkLoaded;
end

-- Called in OnUpdate() of Framemove() to frequently update entity state every tick as required. 
function Entity:OnLivingUpdate()
	local bx, by, bz = self:GetBlockPos();
	local chunkX = rshift(bx, 4);
	local chunkZ = rshift(bz, 4);
	local chunk = self.worldObj:GetChunkFromChunkCoords(chunkX, chunkZ);

	-- check if nearby chunk is already loaded from server. 
	if(not chunk or chunk:GetTimeStamp()<=0) then
		self.isNearbyChunkLoaded = false;

		-- making the player having no vertical speed. 
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetField("VerticalSpeed", 0);
		end

		-- fixed bug: this will force client position to be sent to server.
		-- because SendMotionUpdates() is not called when nearly chunks are not loaded on server
		local dx = self.x - self.oldPosX;
		local dy = self.y - self.oldPosY;
		local dz = self.z - self.oldPosZ;
		local distSqMoved = (dx * dx + dy * dy + dz * dz);
		local hasMovedOrForceTick = distSqMoved > 0.001;
		if(hasMovedOrForceTick) then
			self.oldPosX = self.x;
			self.oldMinY = self.y;
			self.oldPosY = self.y;
			self.oldPosZ = self.z;
			self:AddToSendQueue(Packets.PacketPlayerPosition:new():Init(self.x, self.y, self.y, self.z, self.onGround));
		end

		-- TODO: if chunk is not loaded, do not let the player to move. 
		-- for simplicity, just goto the spawn point. This is not the case, when server teleport the player to a position. 
		-- it should be the server to reset the player position. after chunk is loaded. 
		-- local x, y, z = self.worldObj:GetSpawnPoint();
		-- self:SetPosition(x, y, z);
	else
		self.isNearbyChunkLoaded = true;
	end
end

function Entity:AddToSendQueue(packet)
	return self.netHandler:AddToSendQueue(packet);
end

-- @param chatmsg: ChatMessage or string. 
function Entity:SendChatMsg(chatmsg, chatdata)
	self:AddToSendQueue(Packets.PacketChat:new():Init(chatmsg, chatdata));
	return true;
end

-- Send updated motion and position information to the server
function Entity:SendMotionUpdates()
	local obj = self:GetInnerObject();
	if(not obj) then
		return;
	end
	if(not self:IsNearbyChunkLoaded()) then
		return;
	end
	-- send animation and action
	-- the channel 0 of the animation is always the Entity action. channel 1,2,3,... are for PacketAnimation
    local curAnimID = obj:GetField("AnimID", 0);
	self:SetAnimId(curAnimID);

    if (self.dataWatcher:HasChanges()) then
		self:AddToSendQueue(Packets.PacketEntityMetadata:new():Init(self.entityId, self.dataWatcher, false));
    end

	-- send head rotation if any 
	local dHeadRot = self.rotationHeadYaw - self.oldRotHeadYaw;
	local dHeadPitch = self.rotationHeadPitch - self.oldRotHeadPitch;
	if(dHeadRot~=0 or dHeadPitch~=0) then
		self:AddToSendQueue(Packets.PacketEntityHeadRotation:new():Init(nil, self.rotationHeadYaw, self.rotationHeadPitch));
		self.oldRotHeadYaw = self.rotationHeadYaw;
		self.oldRotHeadPitch = self.rotationHeadPitch;
	end

	-- send movement and body facing. 
    local dx = self.x - self.oldPosX;
    local dy = self.y - self.oldPosY;
    local dz = self.z - self.oldPosZ;
    local dRotY = self.facing - self.oldRotationYaw;
    local dRotPitch = self.rotationPitch - self.oldRotationPitch;
	local distSqMoved = (dx * dx + dy * dy + dz * dz);
    local hasMovedOrForceTick = distSqMoved > 0.001 or self.motionUpdateTickCount >= 20;
    local hasRotation = dRotY ~= 0 or dRotPitch ~= 0;

    if (self:IsRiding()) then
		-- make riding entity send movement update less frequently, such as when moving one meter. 
        hasMovedOrForceTick = hasMovedOrForceTick and (distSqMoved > 2 or self.motionUpdateTickCount >= 20);
	end

    if (hasMovedOrForceTick and hasRotation) then
        self:AddToSendQueue(Packets.PacketPlayerLookMove:new():Init(self.x, self.y, self.y, self.z, self.facing, self.rotationPitch, self.onGround));
    elseif (hasMovedOrForceTick) then
        self:AddToSendQueue(Packets.PacketPlayerPosition:new():Init(self.x, self.y, self.y, self.z, self.onGround));
    elseif (hasRotation) then
        self:AddToSendQueue(Packets.PacketPlayerLook:new():Init(self.facing, self.rotationPitch, self.onGround));
    else
        self:AddToSendQueue(Packets.PacketMove:new():Init(self.onGround));
    end

    self.motionUpdateTickCount = self.motionUpdateTickCount + 1;
    self.wasOnGround = self.onGround;

    if (hasMovedOrForceTick) then
        self.oldPosX = self.x;
        self.oldMinY = self.y;
        self.oldPosY = self.y;
        self.oldPosZ = self.z;
        self.motionUpdateTickCount = 0;
    end

    if (hasRotation) then
        self.oldRotationYaw = self.facing;
        self.oldRotationPitch = self.rotationPitch;
    end
end