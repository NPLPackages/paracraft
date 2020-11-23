--[[
Title: entity player multiplayer
Author(s): LiXizhi
Date: 2014/7/14
Desc: other player entities on the client side. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPOther.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayer.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
local mathlib = commonlib.gettable("mathlib");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayer"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPOther"));

-- player is always framemoved as fast as possible
Entity.framemove_interval = 0.02;

--private: 
Entity.targetX = 0;
Entity.targetY = 0;
Entity.targetZ = 0;
Entity.targetFacing = 0;
Entity.targetPitch = 0;
Entity.smoothFrames = 0;
Entity.smoothFramesHead = 0;

function Entity:ctor()
	self.rotationYawHead = 0;
	self.rotationYawPitch = 0;
	self.serverPosX = 0
end

-- @param entityId: this is usually from the server. 
function Entity:init(world, username, entityId)
	self:SetUserName(username);
	self:SetEntityId(entityId);
	self.worldObj = world; -- Entity._super.init(self, world);
	-- append "other_" for debugging
	self:SetDisplayName(self.username);
	local x, y, z = world:GetSpawnPoint();
	self:SetLocationAndAngles(x, y, z, 0, 0);

	self:CreateInnerObject();
	self:RefreshClientModel();
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
		System.ShowHeadOnDisplay(true, obj, self:GetDisplayName(), GameLogic.options.NPCHeadOnTextColor);	
	end
	return obj;
end

-- @param posRotIncrements: smooth movement over this number of ticks
function Entity:SetPositionAndRotation2(x,y,z, facing, pitch, posRotIncrements)
    self.targetX = x or self.targetX;
    self.targetY = y or self.targetY;
    self.targetZ = z or self.targetZ;
    self.targetFacing = facing or self.targetFacing;
    self.targetPitch = pitch or self.targetPitch;
    self.smoothFrames = posRotIncrements or 1;
end

-- @param posRotIncrements: smooth movement over this number of ticks
function Entity:SetTargetHeadRotation(yaw, pitch, posRotIncrements)
    self.targetHeadYaw = yaw or self.targetHeadYaw;
    self.targetHeadPitch = pitch or self.targetHeadPitch;
    self.smoothFramesHead = posRotIncrements or 1;
end

function Entity:UpdateEntityActionState()
	local curAnimId = self:GetAnimId();
	if(self.lastAnimId ~= curAnimId and curAnimId) then
		self.lastAnimId = curAnimId;
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetField("AnimID", curAnimId);
		end
	end
	local curSkinId = self:GetSkinId();
	if(self.lastSkinId ~= curSkinId and curSkinId) then
		self.lastSkinId = curSkinId;
		self:SetSkin(curSkinId, true);
	end
	local dataWatcher = self:GetDataWatcher();
	local curBlockIdInHand = dataWatcher:GetField(self.dataBlockInHand);
	if(curBlockIdInHand~=self:GetBlockInRightHand()) then
		self:SetBlockInRightHand(curBlockIdInHand);
		self:RefreshRightHand();
	end
	local curMainAsset = dataWatcher:GetField(self.dataMainAsset);
	if(curMainAsset~=self:GetMainAssetPath()) then
		self:SetMainAssetPath(curMainAsset);
	end
	local curScale = dataWatcher:GetField(self.dataFieldScale);
	if(curScale and curScale ~= self:GetScaling()) then
		self:SetScaling(curScale)
	end
	GameLogic.GetFilters():apply_filters("entity_player_mp_other_entity_action_state_updated", self);
end

-- Called in OnUpdate() of Framemove() to frequently update entity state every tick as required. 
function Entity:OnLivingUpdate()
	self:UpdateEntityActionState();

	if (self.smoothFrames > 0) then
		if(not self:IsRiding()) then
			local x = self.targetX - self.x
			local y = self.targetY - self.y;
			local z = self.targetZ - self.z;
			if(math.abs(x) < 20 and math.abs(y) < 20 and math.abs(z) < 20) then
				x = self.x + x / self.smoothFrames;
				y = self.y + y / self.smoothFrames;
				z = self.z + z / self.smoothFrames;
			else
				x = self.targetX;
				y = self.targetY;
				z = self.targetZ;
			end
			self:SetPosition(x, y, z);
		end
		
		local deltaFacing = mathlib.ToStandardAngle(self.targetFacing - self.facing);
		self.facing = self.facing + deltaFacing / self.smoothFrames;
		self.rotationPitch = self.rotationPitch + (self.targetPitch - self.rotationPitch) / self.smoothFrames;
		self.smoothFrames = self.smoothFrames - 1;
		self:SetRotation(self.facing, self.rotationPitch);
	end
	if(self.smoothFramesHead > 0) then
		self.rotationHeadYaw = self.rotationHeadYaw + (self.targetHeadYaw - self.rotationHeadYaw) / self.smoothFramesHead;
		self.rotationHeadPitch = self.rotationHeadPitch + (self.targetHeadPitch - self.rotationHeadPitch) / self.smoothFramesHead;
		self.smoothFramesHead = self.smoothFramesHead - 1;
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetField("HeadTurningAngle", self.rotationHeadYaw);
			obj:SetField("HeadUpdownAngle", self.rotationHeadPitch);
		end
	end
end
