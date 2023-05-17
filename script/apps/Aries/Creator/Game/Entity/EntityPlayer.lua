--[[
Title: entity player
Author(s): LiXizhi
Date: 2013/12/8
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayer.lua");
local EntityPlayer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayer")
local entity = MyCompany.Aries.Game.EntityManager.EntityPlayer:new({x,y,z,radius});
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryPlayer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerCapabilities.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Variables.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockInEntityHand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerHeadController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovable.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local PlayerHeadController = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerHeadController");
local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");
local Variables = commonlib.gettable("MyCompany.Aries.Game.Common.Variables");
local PlayerCapabilities = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerCapabilities");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryPlayer = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryPlayer");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local math_abs = math.abs;
local math_random = math.random;
local math_floor = math.floor;
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovable"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayer"));
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerGSL.lua");

-- the group id
Entity:Property({"group_id", GameLogic.SentientGroupIDs.Player})

-- persistent object by default. 
Entity.is_persistent = false;
-- class name
Entity.class_name = "Player";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.name="default"
-- whether this object is trackable from the server side. 
Entity.isServerEntity = true;
-- player is always framemoved as fast as possible
Entity.framemove_interval = 0.01;
-- for simple HP based games
Entity.maxHP = 100;
Entity.hp = Entity.maxHP;


-- one step dist in meters
local one_step_dist = 0.9;
local min_step_interval = 400; -- 280;

function Entity:ctor()
	-- distance walked
	self.username = self.username or "default";
	self.item_id = block_types.names["player"];
	self.dist_walked = 0;
	self.inventory = InventoryPlayer:new():Init();
	self.inventory:SetParentEntity(self);
	self.capabilities = PlayerCapabilities:new():Init();
	self.capabilities.allowEdit = true;
	self.can_push_block = true;
	self.variables = Variables:new();
	self.variables:CreateVariable("name", self.GetDisplayName, self);
	self.rotationHeadYaw = 0;
	self.rotationHeadPitch = 0;
	-- making this entity always sentient
	self.bAlwaysSentient = true;
	local dataWatcher = self:GetDataWatcher(true);
	-- animation data. 
	self.dataFieldAnim = dataWatcher:AddField(nil, nil);
	-- scale data. 
	self.dataFieldScale = dataWatcher:AddField(nil, nil);
	-- skin data. 
	self.dataFieldSkin = dataWatcher:AddField(nil, nil);
	-- block in hand. only used in network mode.  
	self.dataBlockInHand = dataWatcher:AddField(nil, nil);
	-- main asset path. only used in network mode.  
	self.dataMainAsset = dataWatcher:AddField(nil, nil);
	self:SetPhysicsRadius(0.5);
	self:SetPhysicsHeight(1.765);

end

-- @param Entity: the half radius of the object. 
function Entity:init(world)
	self.worldObj = world;
	-- TODO: create scene object representing this object. 
	-- self:RefreshClientModel();
	return self;
end

-- set main model
function Entity:SetMainAssetPath(name)
	if(self:GetMainAssetPath() ~= name) then
		self.mainAssetPath = name;
		self:RefreshClientModel(true);
		self:GetDataWatcher():SetField(self.dataMainAsset, self:GetMainAssetPath());
		return true;
	end
end

function Entity:CanSelectModel()
	return false;
end

function Entity:IsPlayer()
	return true;
end

-- get the item stack in right hand
function Entity:GetItemInRightHand()
	return self.inventory:GetItemInRightHand();
end

-- return the block id in the right hand of the player. 
function Entity:GetBlockInRightHand()
	return self.inventory:GetBlockInRightHand();
end

function Entity:SetHandToolIndex(nIndex)
	local res = self.inventory:SetHandToolIndex(nIndex, true);
	self:GetDataWatcher():SetField(self.dataBlockInHand, self:GetBlockInRightHand());
	return res;
end

-- toggle the last selected tool
function Entity:ToggleHandToolIndex()
	self:SetHandToolIndex(self.inventory.last_handtool_bagpos);
end

-- set block in right hand
-- @param blockid_or_item_stack:  block_id or ItemStack object. 
-- @param bIsReplace: if true, we will replace instead of moving to other empty slot
function Entity:SetBlockInRightHand(blockid_or_item_stack, bIsReplace)
	local res = self.inventory:SetBlockInRightHand(blockid_or_item_stack, bIsReplace);
	self:GetDataWatcher():SetField(self.dataBlockInHand, self:GetBlockInRightHand());
	return res;
end

-- the actual name is "__MP__"..username
function Entity:SetUserName(username)
	self.username = username or "";
	self.name = "__MP__"..self.username;
end

-- Gets the name of the entity
function Entity:GetUserName()
    return self.username;
end

function Entity:CreateInnerObject(...)
	local obj = Entity._super.CreateInnerObject(self, ...);
	if(obj) then
		obj:SetField("SentientField", 0xffff);
		obj:SetGroupID(self.group_id or 0);
	end
	return obj;
end

-- bind to a ParaObject. this is a client side only function. 
-- and it automatically SetClient. 
-- @param obj: this is usually ParaScene.GetPlayer() on client side
function Entity:BindToScenePlayer(obj, isOPC)
	if(obj) then
		self:SetClient();
		if(not self.obj) then
			self:SetInnerObject(obj);
			EntityManager.SetEntityByObjectID(self.obj_id, self);
		else
			self:SetInnerObject(obj);
		end
		
		obj:SetField("SentientField", 0xffff);
		obj:SetGroupID(self.group_id or 0);

		self:RefreshClientModel();
		self:UpdateBlockContainer();
		local x, y, z = self:GetPosition();
		-- this fix a bug that when binding, the player position is different from the entity position. 
		if(x > 256 and z>256) then
			obj:SetPosition(x, y, z);
		end
		self.isOPC = isOPC;
	else
		self:DestroyInnerObject();
	end
end

function Entity:SetAnimId(nAnimId)
	self.dataWatcher:SetField(self.dataFieldAnim, nAnimId);
end

function Entity:GetAnimId()
	return self.dataWatcher:GetField(self.dataFieldAnim);
end

--virtual function:
function Entity:SetScaling(v)
	Entity._super.SetScaling(self, v);
	local dataWatcher = self:GetDataWatcher();
	local watchedScale = dataWatcher:GetField(self.dataFieldScale);
	if(watchedScale ~= v) then
		dataWatcher:SetField(self.dataFieldScale, v);
	end
end


function Entity:Destroy()
	if(not self:HasFocus()) then
		self:DestroyInnerObject();
	end
	Entity._super.Destroy(self);
end

-- set the character slot
function Entity:SetCharacterSlot(slot_id, item_id)
	local obj = self:GetInnerObject();
	if(obj) then
		obj:ToCharacter():SetCharacterSlot(slot_id, item_id);
		-- TODO: save to inner data
	end
end

-- virtual function: overwrite to customize physical object
function Entity:CreatePhysicsObject()
	local physic_obj = Entity._super.CreatePhysicsObject(self);
	physic_obj:SetRadius(BlockEngine.half_blocksize);
	physic_obj:SetCanBounce(false);
	physic_obj:SetSurfaceDecay(5);
	physic_obj:SetAirDecay(0);
	physic_obj:SetMinSpeed(0.3);
	return physic_obj;
end

function Entity:OnRespawn()
	self.hp = self.maxHP;
	GameLogic.RunCommand(format("/runat @all /goto @%s home", self:GetName()))
end

function Entity:OnDead()
	self:OnRespawn()
end

function Entity:CanTeleport()
	return true;
end


-- virtual function: when the entity is hit (attacked) by the missile
function Entity:OnHit(attack_value, fromX, fromY, fromZ)
	local obj = self:GetInnerObject();
	if(not obj) then
		return;
	end
	
--	if(obj:HasAnimation(73)) then
--		obj:PlayAnimation(73);
--	end

	local spritestyle = "CombatDigits";
	local color = "da2d2d";
	-- TODO: attack - defense, plus some bonus point
	local damage = math.random(attack_value, attack_value+10);
	self.hp = self.hp - damage;
	
	if(self.hp <= 0) then
		self:OnDead();
	end

	local content = string.format("-%d", damage);
	
	local anim_type = "plain";
	local mcml_str = string.format([[<aries:textsprite spritestyle="%s" color="#%s" text="%s" default_fontsize="12" fontsize="19"/>]], spritestyle, color, content);
	local sCtrlName = headon_speech.Speek(obj.name, mcml_str, 2, true, true, true, -1);
	if(sCtrlName) then
		if(anim_type == "plain") then
			UIAnimManager.PlayCustomAnimation(800, function(elapsedTime)
				local parent = ParaUI.GetUIObject(sCtrlName);
				if(parent:IsValid()) then
					local t = elapsedTime / 1000
					parent.translationx = math.floor( - 100 * t );
					parent.translationy = math.floor( -60 * t + 50 * t * t);
					
					if(elapsedTime < 400) then
					else
						parent.colormask = format("255 255 255 %d", math.floor( (1 - (elapsedTime-400) / 400)*255) );
					end
					parent:ApplyAnim();
				end
			end);
		end
	end
end

-- @param x, y, z: if nil, player faces front. 
-- @param isAngle: if x, y, z is angle. 
function Entity:FaceTarget(x,y,z, isAngle)
	PlayerHeadController.FaceTarget(self, x, y, z, isAngle);
end

-- let the camera focus on this player and take control of it. 
-- @return return true if focus is set
function Entity:SetFocus()
	EntityManager.SetFocus(self);
	return true;
end

-- called after focus is set
function Entity:OnFocusIn()
	self.has_focus = true;
	self.inventory.isClient = true;
	local obj = self:GetInnerObject();
	if(obj) then
		obj:ToCharacter():SetFocus();
		-- make it normal movement style
		obj:SetField("MovementStyle", 0)
		-- obj:SetField("SkipPicking", true);
	end
end

-- called before focus is lost
function Entity:OnFocusOut()
	self.has_focus = nil;
	-- self.inventory.isClient = nil;
	local obj = self:GetInnerObject();
	if(obj) then
		-- this fixed a bug that the player may be moving forward while focus is set to camera in a movie block. 
		obj:ToCharacter():Stop();
		-- if walking or running animation is being played, stop it. 
		local animId = obj:GetField("AnimID", 0);
		if(animId == 4 or animId == 5) then
			obj:SetField("AnimID", 0);
		end
		-- make it linear movement style
		obj:SetField("MovementStyle", 3);
		-- obj:SetField("SkipPicking", false);
	end
end

-- get teleport position list
function Entity:GetPosList()
	self.tp_list = self.tp_list or {};
	return self.tp_list;
end

-- the item that the player is currently dragging (in the UI interface)
function Entity:GetDragItem()
	return self.drag_item;
end

function Entity:SetDragItem(itemStack)
	self.drag_item = itemStack;
end

function Entity:CanPlayerEdit(x,y,z,data, itemStack)
    if(self.capabilities.allowEdit and (not itemStack or itemStack:CanEditBlocks())) then
		return true
	end
end

-- when picked up an entity. 
function Entity:OnItemPickup(entityItem, count)
end

function Entity:doesEntityTriggerPressurePlate()
	return true;
end

function Entity:TriggerAchievement(achievement_id)
end

function Entity:IsOnGround()
	return self.onGround;
end

function Entity:FallDown(deltaTime)
	if(not self.y or self.y > (ParaTerrain.GetElevation(self.x, self.z)+0.1)) then
		local obj = self:GetInnerObject();
		if(obj) then
			obj:ToCharacter():FallDown();
		end
	end
end

-- called every frame, it will play step sound when walking over one step length.
function Entity:PlayStepSound()
	local cur_time = commonlib.TimerManager.GetCurrentTime();
	if((cur_time-(self.last_step_time or 0)) > min_step_interval and (self.dist_walked - (self.last_step_dist or 0)) > one_step_dist) then
		self.last_step_time = cur_time;
		self.last_step_dist = self.dist_walked;
		local x,y,z = self:GetBlockPos();
		local step_block = BlockEngine:GetBlock(x,y, z);
		if(step_block and step_block.step_sound) then
			-- in case of slab block
			step_block:play_step_sound();
		else
			-- solid block
			step_block = BlockEngine:GetBlock(x,y-1, z);
			if(step_block) then
				step_block:play_step_sound();
			end	
		end
	end
end

-- this is used to test whether this entity can pick the block. 
function Entity:CanReachBlockAt(x,y,z)
	return (GameLogic.GameMode:IsEditor() and (not GameLogic.IsFPSView or System.options.IsMobilePlatform)) or (self:DistanceSqTo(x,y,z) <= ((self:GetPickingDist()+0.5) ^ 2));
end

-- if the block above this is empty we will allow placing the block
function Entity:canPlaceBlockAt(x,y,z, block)
	if(not block or not block.obstruction) then
		return true;
	else
		local block1 = BlockEngine:GetBlock(x,y+1,z);
		local block2 = BlockEngine:GetBlock(x,y+2,z);
		if( (not block2 or not block2.obstruction) and (not block1 or not block1.obstruction) ) then
			return true;
		end
	end
	return false;
end

function Entity:UpdateRotation()
	local obj = self:GetInnerObject();
	if(obj) then
		local facing = obj:GetFacing(); 
		if(self:GetFacing() ~= facing) then
			self:SetFacing(facing);
		end
		local value = obj:GetField("HeadTurningAngle", 0);
		if( value ~= self.rotationHeadYaw) then
			self.rotationHeadYaw = value;
		end
		local value = obj:GetField("HeadUpdownAngle", 0);
		if( value ~= self.rotationHeadPitch) then
			self.rotationHeadPitch = value;
		end
	end
end

-- update the tile position
function Entity:UpdatePosition(x,y,z)
	local player;
	if(not x) then
		player = self:GetInnerObject() or ParaScene.GetPlayer();
		x,y,z = player:GetPosition();
	end
	local old_x, old_y, old_z = self.x or x, self.y or y, self.z or z;
	Entity._super.UpdatePosition(self, x, y, z);

	local dist = (old_x - x)^2+(old_y-y)^2+(old_z-z)^2;
	if(dist > 0.01) then
		dist = math.min(10, math.sqrt(dist));
	end
	self.dist_walked = self.dist_walked + dist;
	return player;
end


function Entity:CanBePushedBy(fromEntity)
    if(fromEntity and fromEntity.class_name == "EntityBlockDynamic") then
		return true;
	else
		return false;
	end
end

-- check collisiton with nearby entities
function Entity:CheckCollision(deltaTime)
	if(not self:IsCheckCollision()) then
		return
	end
	Entity._super.CheckCollision(self);
	local bx,by,bz = self:GetBlockPos();
	
	-- checking collision with other entities
	local entities = EntityManager.GetEntitiesByAABBExcept(self:GetCollisionAABB(), self)
	if(entities) then
		for _, entity in ipairs(entities) do
			entity:OnCollideWithPlayer(self, bx,by,bz);
			if(entity:CanBePushedBy(self)) then
				self:CollideWithEntity(entity, deltaTime);
			end
		end
	end
	self:UpdateStandOnPhysicalEntity()
end


-- return entity that the this entity is standing on. 
-- @param entityPlayer: check if this player on surface of the current entity. The current entity is usually a physical object. 
-- @param maxHeightDiff: [0.01, 0.0.5],  default to 0.15
function Entity:GetStandOnPhysicalEntity(maxHeightDiff)
	local x, y, z = self:GetPosition();
	local pt = ParaScene.Pick(x, y+0.5, z, 0, -1, 0, 5, "point")
	if(pt:IsValid())then
		local entityName = pt:GetName();
		if(entityName and entityName~="") then
			local entity = EntityManager.GetEntity(entityName);
			if(entity ~= self) then
				local x1, y1, z1 = pt:GetPosition()
				if(math.abs(y - y1) < (maxHeightDiff or 0.15)) then
					return entity;
				end
			end
		end
	end
end

-- this function should be called when collision changes and when value changed. 
-- currently, we simply call it periodically in framemove's CheckCollision function. 
function Entity:UpdateStandOnPhysicalEntity()
	if(self.lastStandOnEntity and self.lastStandOnEntity:IsDragging()) then
		return
	end
	local currentStandOnEntity = self:GetStandOnPhysicalEntity(0.2)
	if(currentStandOnEntity) then
		if(not self.lastStandOnEntity) then
			-- tricky: we will do a more precise check for first standing on, and a more fuzzy check when leaving. 
			currentStandOnEntity = self:GetStandOnPhysicalEntity(0.01)
		end
	end
	if(currentStandOnEntity ~= self.lastStandOnEntity) then
		if(self.lastStandOnEntity) then
			self:UnLink()
		end
		self:LinkTo(currentStandOnEntity)
		self.lastStandOnEntity = currentStandOnEntity
	elseif(currentStandOnEntity) then
		self:LinkTo(currentStandOnEntity)
	end
end

function Entity:CollideWithEntity(fromEntity, deltaTime)
    fromEntity:ApplyEntityCollision(self, deltaTime);
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self.skin = node.attr.skin;
	if(self.skin) then
		Files.FindFile(self.skin);
	end
	for _, subnode in ipairs(node) do 
		if(subnode.name == "teleport_list") then
			self.tp_list = NPL.LoadTableFromString(subnode[1] or "");
		end
	end
	self.capabilities:LoadFromXMLNode(node);
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	node.attr.skin = self.skin;
	if(self.tp_list) then
		node[#node+1] = {[1]=commonlib.serialize_compact(self.tp_list, bSort), name="teleport_list"};
	end
	self.capabilities:SaveToXMLNode(node, bSort);
	return node;
end

function Entity:FrameMoveRules(deltaTime)
	
	if(not self.m_bRuleLoaded) then
		self.m_bRuleLoaded = true;
		local entities = GameLogic.EntityManager.GetEntitiesByItemID(20002)

		if entities==nil or #entities==0 then --有出生点就走出生点的逻辑
			local tempList = nil
			local dft_cmds = (System.options.world_enter_cmds and commonlib.split(System.options.world_enter_cmds,";")) or {}
			for i=#dft_cmds,1,-1 do
				tempList = tempList or {}
				local str = dft_cmds[i]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "") --去掉字符串首尾的空格、引号
				table.insert(tempList,1,str)
			end
			if tempList and #tempList>0 then
				self:SetCommandTable(tempList)
				local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

				local variables = self:GetVariables();
				local last_result;
				local cmd_list = self:GetCommandList();
				if(cmd_list) then
					last_result = CommandManager:RunCmdList(cmd_list, variables, self);
				end

				self:SetCommandTable(nil)
			end
		end
	end
end

-- adjust using the block below the character's feet. 
function Entity:AdjustSlipperiness()
	local bx,by,bz = self:GetBlockPos();
	local block = BlockEngine:GetBlock(bx,by-1,bz);
	if(block) then
		local player = self:GetInnerObject();
		if(player) then
			player:SetField("AccelerationDist", block:GetSlipperiness());
		end
	end
end

-- Adds to the current motion of the entity. 
-- @param x,y,z: velocity in x,y,z direction. 
function Entity:AddMotion(dx,dy,dz)
	if(not self:HasFocus()) then
		-- never add motion when we have focus. Use SetMotion instead.
		Entity._super.AddMotion(self, dx,dy,dz);
	end
end

function Entity:MoveEntity(deltaTime)
	if(self:HasMotion()) then
		Entity._super.MoveEntity(self, deltaTime);	
	end
	deltaTime = math.min(0.3, deltaTime);
	self:CheckCollision(deltaTime);
	-- self:CheckWings();
end

function Entity:CheckWings()
	if (EntityManager.GetPlayer() == self) then
		self:ShowWings(self.bFlying)
	end
end

function Entity:ShowWings(bShowWings)
	if(self.bShowWings ~= bShowWings) then
		self.bShowWings = bShowWings;
		local player = self:GetInnerObject();
		if(player) then
			PlayerAssetFile:ShowWingAttachment(player, self:GetSkinId(), bShowWings);
		end			
	end
end

-- called every framemove by the ridden entity, instead of framemove.
function Entity:FrameMoveRidding(deltaTime)
	if (not self.ridingEntity or self.ridingEntity:IsDead()) then
        self.ridingEntity = nil;
    else
		
		if (self.ridingEntity) then
			local preX, preY, preZ = self:GetPosition();
			self.ridingEntity:UpdateRiderPosition();
			local x, y, z = self:GetPosition();
			local deltaY = preY - y;
			local obj = self:GetInnerObject();
			if(obj) then
				if(obj:GetField("VerticalSpeed", 0) ~= 0) then
					obj:SetField("VerticalSpeed", 0);
					obj:CallField("ForceStop");
				end
				--[[
				if(deltaY > 2) then
					-- unmount if jumps up too high
					if(GameLogic.isRemote) then
						self:AddToSendQueue(GameLogic.Packets.PacketEntityAction:new():Init(1, nil));
					else
						self:MountEntity(nil);
						local bx, by, bz = self:GetBlockPos();
						self:PushOutOfBlocks(bx, by, bz);
					end
				elseif(deltaY > 0) then
					if(obj:GetField("VerticalSpeed", 0) ~= 0) then
						-- allow jumping using C++ biped. 
						self:SetPosition(x, preY, z);
					else
						obj:SetField("VerticalSpeed", 0);
						obj:ToCharacter():Stop();
						-- obj:ToCharacter():PlayAnimation(0);
					end
				else
					obj:SetField("VerticalSpeed", 0);
					obj:ToCharacter():Stop();
					-- obj:ToCharacter():PlayAnimation(0);
				end
				]]
			end
		end
		
    end
	self:UpdateActionState();
	self:OnUpdate();
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(self:HasFocus()) then
		if(self:FrameMoveMemoryContext(deltaTime)) then
			-- entity is autonomously animated, we will skip physics. 

		elseif(self:HasMotion()) then
			-- if there is motion, we will move by motion
			Entity._super.FrameMove(self, deltaTime);
		else
			-- whether the entity is having focus.
			Entity._super.FrameMove(self, deltaTime);
			self:AdjustSlipperiness();
			self:MoveEntity(deltaTime);
		
			self:PlayStepSound();
			self:UpdateActionState();
		end
	else
		if(GameLogic.isServer) then
			-- server side entity needs to check collision. 
			self:CheckCollision(deltaTime);
		end
	end
	self:OnUpdate();
end

function Entity:IsNearbyChunkLoaded()
	return self.isNearbyChunkLoaded;
end

-- update the entity's position logic. usually called per tick. 
function Entity:OnUpdate()
	self:OnLivingUpdate();
end

-- Called in OnUpdate() of Framemove() to frequently update entity state every tick as required. 
function Entity:OnLivingUpdate()
	local bx, by, bz = self:GetBlockPos();
	local chunkX = rshift(bx, 4);
	local chunkZ = rshift(bz, 4);
	local chunk = self.worldObj:GetChunkFromChunkCoords(chunkX, chunkZ);
	if(not chunk or chunk:GetTimeStamp()<=0) then
		self.isNearbyChunkLoaded = false;

		-- making the player having no vertical speed. 
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetField("VerticalSpeed", 0);
		end
	else
		if(self.isNearbyChunkLoaded ~= true) then
			self.isNearbyChunkLoaded = true;
			self:AutoFindPosition();
		end
	end
end

-- @param bUseSpawnPoint: whether to use the spawn point. 
function Entity:AutoFindPosition(bUseSpawnPoint)
	local x, y, z = self.worldObj:GetSpawnPoint();
	if(bUseSpawnPoint and x and y and z) then
		self:SetPosition(x,y,z);
		GameLogic.options:SetLoginPosition(x, y, z);
		local bx, by, bz = self:GetBlockPos();
		LOG.std(nil, "info", "AutoFindVerticalPosition", "player is spawned at world spawn point: %d %d %d", bx, by, bz);
	else
		-- if no spawn point is found, snap to ground. 
		local bx, by, bz = self:GetBlockPos();
		local dist
		if(bx == 0 and by == 0 and bz == 0) then
			dist = -1;
		else
			-- find the first non-water solid block. 
			-- find the first non-air block and use it as spawn
			dist = ParaTerrain.FindFirstBlock(bx, by, bz, 5, 255, 255);
			if(dist<0) then
				by = 255;
				dist = ParaTerrain.FindFirstBlock(bx, by, bz, 5, 255, 255);	
			end
		end
		if(dist>0) then
			by = by - dist; 
			x,y,z = BlockEngine:real(bx,by,bz);	
			y = y + BlockEngine.half_blocksize + 0.1;

			self:SetPosition(x,y,z);
			GameLogic.options:SetLoginPosition(x, y, z);
			local bx, by, bz = self:GetBlockPos();
			LOG.std(nil, "info", "AutoFindVerticalPosition", "player is spawned at highest solid block: %d %d %d", bx, by, bz);
		else
			local block_generator = GameLogic.GetBlockGenerator();
			local x, y, z = 20000, -120, 20000;
			if(block_generator and block_generator.GetDefaultLoginPos) then
				x, y, z = block_generator:GetDefaultLoginPos();
			end
			if(bx == 0 and bz == 0) then
				-- just in case there is no last saved position. 
				self:SetPosition(x,y,z);
			end
			GameLogic.options:SetLoginPosition(x, y, z);
		end	
	end
end

function Entity:UpdateEntityActionState()
end

function Entity:SetFacing(facing)
	Entity._super.SetFacing(self, facing);
	self.rotationYaw = facing;
end

-- if this entity is runing on client side and represent the current player
function Entity:SetClient()
	self.isClient = true;
	self.inventory:SetClient();
end

-- @param chatmsg: ChatMessage or string. 
function Entity:SendChatMsg(chatmsg, chatdata)
end

-- set new skin texture by filename. 
function Entity:SetSkin(skin, bIgnoreSetSkinId)
	if System.options.channelId_431 then
		self:SetSkinIn431Platform(skin)
		return 
	end
	Entity._super.SetSkin(self, skin, bIgnoreSetSkinId);
	if(not bIgnoreSetSkinId) then
		self.dataWatcher:SetField(self.dataFieldSkin, self:GetSkin());
	end
end

-- set new skin texture by filename. 
-- @param skin: if nil, it will use the default skin. 
-- if it only contains file path, then by default it will always be set at replaceable texture id 2.
-- if the string is of format "id:filename;id:filename;...", it can be used to set multiple replaceable textures at custom index. 
-- it can also be model and texture ids like "id1;id2;...", which is used in movie block actor. 
--[[进入校园版的角色，使用同—衣着(对其他版本无影响)
老师服装编号
80001;84060;81010;85081;83190
学生服装编号
80001;82029;84012;81070;85009]]

function Entity:SetSkinIn431Platform(skin)
	-- local isTeacher = KeepWorkItemManager.IsTeacher()
	-- local skin = skin
	-- if isTeacher then
	-- 	skin = "80001;84060;81010;85081;83190"
	-- else
	-- 	skin = "80001;82029;84012;81070;85009"
	-- end
	local skin = "80001;82011;84012;81018;85009"
	if(self.skin ~= skin) then
		if(skin) then
			skin = tostring(skin)
			local customSkin = skin;
			if (self:HasCustomGeosets()) then
				if(skin:match("^(%d+):[^;+]")) then
					-- this never happens in a movie block actor, since movie block actor uses "id1;id2;..."
					customSkin = CustomCharItems:ReplaceSkinTexture(self.skin, skin);
				end
			end
			self.skin = customSkin;
			if (not self.isCustomModel and not self.hasCustomGeosets) then
				if (skin:match("^%d+;") and EntityManager.GetPlayer() == self) then
					self.skin = nil;
				elseif (not self:FindSkinFiles(skin)) then
					LOG.std(nil, "warn", "Entity:SetSkin", "skin files does not exist %s", tostring(skin));
				end
			end
		else
			if (not self:HasCustomGeosets()) then
				self.skin = skin;
				self:RefreshSkin();
			end
		end

		if(self.username == System.User.username) then
			PlayerAssetFile.Store.skin = self.skin;
		end

		self:RefreshClientModel();
	end
end


function Entity:GetSkinId()
	return self.dataWatcher:GetField(self.dataFieldSkin, nil);
end

-- only mc version is biped
function Entity:IsBiped()
	return self.isBiped;
end

-- refresh the client's model according to current inventory settings, such as 
-- armor and hand tool. 
function Entity:RefreshClientModel(bForceRefresh, playerObj)
	if(bForceRefresh or GameLogic.isRemote or System.options.mc) then
		Entity._super.RefreshClientModel(self, bForceRefresh, playerObj)
	end
end

function Entity:UpdateDisplayName(text)
	if(self:GetDisplayName()~=text) then
		self:SetDisplayName(text);
		local obj = self:GetInnerObject();
		if(self:IsShowHeadOnDisplay() and System.ShowHeadOnDisplay) then
			System.ShowHeadOnDisplay(true, obj, text or "", GameLogic.options.NPCHeadOnTextColor);	
		end
	end
end

-- this is called on each tick, when this entity has focus and user is pressing and holding shift key. 
function Entity:OnShiftKeyPressed()
	if (self.ridingEntity) then
		if(GameLogic.isRemote) then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketEntityAction:new():Init(1, nil));
		else
			self:MountEntity(nil);
			-- teleport entity to a free block nearby
			local bx, by, bz = self:GetBlockPos();
			self:PushOutOfBlocks(bx, by, bz);
			if(GameLogic.Macros:IsRecording()) then
				GameLogic.Macros:AddMacro("KeyPress", "shift+DIK_LSHIFT");
			end
		end
	else
		local obj = self:GetInnerObject();
		if(obj) then
			obj:ToCharacter():PlayAnimation(66);
		end
	end
end

-- this is called, when this entity has focus and user is just released the shift key. 
function Entity:OnShiftKeyReleased()
	local obj = self:GetInnerObject();
	if(obj) then
		obj:ToCharacter():PlayAnimation(0);
	end
end

-- user clicks on an OPC
function Entity:OnClick(x,y,z, mouse_button)
	return true;
end

function Entity:RefreshRightHand(player)
	if(self:HasPet()) then
		BlockInEntityHand.RefreshRightHand(nil, self.inventory:GetItemInRightHand(), self.petObj)
	end

	if(GameLogic.isRemote or System.options.mc and (not self:HasPet())) then
		BlockInEntityHand.RefreshRightHand(self, self.inventory:GetItemInRightHand(), player);	
	end
end

function Entity:IsFlying()
	return self.bFlying;
end

function Entity:SetDead()
	if(not self:IsRemote()) then
		GameLogic.OnDead();
	end
end

-- press "F" to toggle the fly mode
-- @param bFly: nil to toggle. otherise force fly or not. 
-- @return is_flying
function Entity:ToggleFly(bFly)
	local player = self:GetInnerObject();
	if(not player) then
		return
	end
	if(bFly == nil) then
		if(not self:IsFlying()) then
			bFly = true;
		elseif(self:IsFlying() == true) then
			bFly = false;
		end
	end
	if(bFly) then
		-- make it light to fly
		player:SetDensity(0);
		-- jump up a little
		player:ToCharacter():AddAction(action_table.ActionSymbols.S_JUMP_START);
		
		self.bFlying = true;
		
		player:SetField("CanFly",true);
		player:SetField("AlwaysFlying",true);
		player:ToCharacter():SetSpeedScale(self:GetCurrentSpeedScale());
		--tricky: this prevent switching back to walking immediately
		player:SetField("VerticalSpeed", self:GetSpeedScale());
		-- this fixed camera direction in mobile device. 
		player:SetField("FlyUsingCameraDir", true);

		-- BroadcastHelper.PushLabel({id="fly_tip", label = "�������ģʽ����ס����Ҽ����Ʒ���, W��ǰ��", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
		local cam_facing = Direction.GetFacingFromCamera();
		local facing = cam_facing
		if(player) then
			player:SetFacing(facing);
		end
	elseif(bFly == false) then
		-- restore to original density
		player:SetDensity(GameLogic.options.NormalDensity);
		self.bFlying = false;

		player:SetField("CanFly",false);
		player:SetField("AlwaysFlying",false);
		player:ToCharacter():SetSpeedScale(GameLogic.options.WalkSpeedScale * (self.speedscale or 1));
		player:ToCharacter():FallDown();

		-- BroadcastHelper.PushLabel({id="fly_tip", label = "�˳�����ģʽ", max_duration=1500, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
	return self.bFlying;
end

--[[ examples: 
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local player = EntityManager.GetPlayer();
player:BeginTouchMove();
player:TouchMove(0);
local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
	player:EndTouchMove();
end})
-- walk 1 seconds
mytimer:Change(1000, nil)
]]
-- begin touch move towards a given position. 
function Entity:BeginTouchMove()
	local attr = ParaCamera.GetAttributeObject();
	attr:SetField("ControlBiped", false);
end

-- move according to a facing angle in screen space relative to current camera view. 
-- call this function between BeginTouchMove() and EndTouchMove(). 
-- Please note, it will walk forever until EndTouchMove() is called. 
-- @param screen_facing: [0,2pi], where 0 is running away from camera, pi is running towards camera, etc. 
function Entity:TouchMove(screen_facing)
	local cam_facing = Direction.GetFacingFromCamera();
	local facing = cam_facing + (screen_facing or 0);
	local player = self:GetInnerObject();
	if(player) then
		player:SetFacing(facing);
		player:ToCharacter():AddAction(action_table.ActionSymbols.S_WALK_FORWORD, facing);
	end
end

-- end touch move towards a given position. 
function Entity:EndTouchMove()
	local attr = ParaCamera.GetAttributeObject();
	attr:SetField("ControlBiped", true);
	local player = self:GetInnerObject();
	if(player) then
		player:ToCharacter():Stop();
	end
end

-- called when W key is pressed.
function Entity:MoveForward(speed)
	self.moveForward = speed;
end

function Entity:UpdateActionState()
	self.moveForward = 0;
	local obj = self:GetInnerObject();
	if(obj) then
		self.facing = obj:GetFacing();
		self:SetAnimId(obj:GetField("AnimID", 0));
	end
end

function Entity:GetCurrentSpeedScale()
	local speed;
	if(self:IsFlying()) then
		speed = GameLogic.options.FlySpeedScale;
		if (System.User.isVip) then
			speed = speed * 1.2;
		else
			speed = speed * 0.8;
		end
	elseif(GameLogic.IsRunning) then
		speed = GameLogic.options.RunSpeedScale;
	else
		speed = GameLogic.options.WalkSpeedScale;
	end
	return speed * (self.speedscale or 1);	
end

-- Wake up the player if they're sleeping.
function Entity:WakeUpPlayer(bResetSleepTime, bUpdateSleepFlag, bSpawnInChunk)
	-- TODO:
end

-- Returns whether player is sleeping or not
function Entity:IsPlayerSleeping()
    return self.sleeping;
end

-- Returns whether or not the player is asleep 
function Entity:IsPlayerFullyAsleep()
    return self.sleeping and self.sleepTimer >= 100;
end

-- get the item index with the given index. 
-- @param index: [1,5]. 1 is for left hand
function Entity:GetCurrentItemOrArmor(index)
	-- TODO:
	return nil;
end

-- @param value: if nil, it will use the global gravity. 
function Entity:SetGravity(value)
	Entity._super.SetGravity(self, value);
	local obj = self:GetInnerObject();
	if(obj) then
		-- secretly double it in C++ engine
		obj:SetField("Gravity", self:GetGravity()*2);
	end
end

-- return true if we can take control of this entity by external agent like movie or code block.
function Entity:CanBeAgent()
	return true;
end

-- whether it can be searched via Ctrl+F FindBlockTask
function Entity:IsSearchable()
	return true;
end

-- @param actor: the parent ActorNPC
function Entity:SetActor(actor)
	self.m_actor = actor;
end

-- @param actor: the parent ActorNPC
function Entity:GetActor()
	return self.m_actor;
end

function Entity:SetCanRandomMove(bEnable)
 -- empty implementation just to be compatible with EntityNPC as used in ActorNPC
end

-- this is the c++ mount method. 
-- please note one needs to set focus to the targetEntity to take control of it. 
function Entity:MountOn(targetEntity, mountID)
	local player = self:GetInnerObject();
	if(player and targetEntity) then
		local target = targetEntity:GetInnerObject();
		if(target) then
			player:ToCharacter():MountOn(target, mountID or -1);
			target:SetField("IsControlledExternally", false);
			target:SetField("EnableAnim", true);
			-- make it normal movement style
			target:SetField("MovementStyle", 0)

			self.pet = targetEntity;
			targetEntity:SetFocus();
		end
	end
end

function Entity:IsMountOnRailCar()
	if self.ridingEntity and self.ridingEntity.class_name == "Railcar" then
		return true
	end

	return false
end

function Entity:GetRidingEntity()
	return self.ridingEntity
end


-- support modify facing when linked
function Entity:OnUpdateLinkFacing()
	if(self.linkInfo and self.linkInfo.entity) then
		self.linkInfo.facing = self:GetFacing() - self.linkInfo.entity:GetFacing();
	end
end

-- do not support modify position when linked
function Entity:OnUpdateLinkPosition()
end

-- but we use the current relative position between this and link target. 
-- and if we move the current entity after the a link is established, we will modify the relative position.
-- when the linkTarget's position and facing changes, the entity will also move according to the last relative position. 
-- LinkTo function is suitable for linking between two static objects, like an apple can be linked to a table. 
-- if we already attachedTo an object, we will detach from it, before link to it. 
-- @param targetEntity: string or entity object. which entity to link to. if nil, it will detach from existing entity. 
-- @param boneName: nil or a given bone name. If specified, we will use a timer to update. 
-- @param pos: nil or 3d position offset
-- @param rot: nil or 3d rotation 
function Entity:LinkTo(targetEntity, boneName, pos, rot)
	if(targetEntity) then
		self.linkInfo = self.linkInfo or {};
		local srcEntity = self
		local x, y, z = srcEntity:GetPosition()
		local tx, ty, tz = targetEntity:GetPosition()

		local quatRot = Quaternion:new():FromEulerAnglesSequence(-targetEntity:GetRoll(), -targetEntity:GetPitch(), -targetEntity:GetFacing(), "zxy")

		self.linkInfo.x, self.linkInfo.y, self.linkInfo.z = quatRot:RotateVector3(x - tx, y - ty, z - tz)
		self.linkInfo.facing = srcEntity:GetFacing() - targetEntity:GetFacing();
		self.linkInfo.scaling = targetEntity:GetScaling()
		self.linkInfo.quatRot = quatRot;
		self.linkInfo.boneName = boneName;
		self.linkInfo.pos = pos;
		self.linkInfo.rot = rot;

		if(self.linkInfo.entity ~= targetEntity) then
			self:UnLinkEntity(self.linkInfo.entity)
			self.linkInfo.entity = targetEntity
			targetEntity:Connect("valueChanged", self, self.UpdateEntityLink);
			targetEntity:Connect("facingChanged", self, self.UpdateEntityLink);
			targetEntity:Connect("scalingChanged", self, self.UpdateEntityLink);
			targetEntity:Connect("beforeDestroyed", self, self.UnLink);
			self:Connect("beforeDestroyed", self, self.UnLink);
			--self:Connect("facingChanged", self, self.OnUpdateLinkFacing);
			--self:Connect("valueChanged", self, self.OnUpdateLinkPosition);
			targetEntity.childLinks = targetEntity.childLinks or commonlib.UnorderedArraySet:new();
			targetEntity.childLinks:add(self);
		end
	else
		self:UnLink();
	end
end

-- private function:
-- use UnLink, instead of this function
function Entity:UnLinkEntity(entity)
	if(entity) then
		entity:Disconnect("valueChanged", self, self.UpdateEntityLink);
		entity:Disconnect("facingChanged", self, self.UpdateEntityLink);
		entity:Disconnect("scalingChanged", self, self.UpdateEntityLink);
		entity:Disconnect("beforeDestroyed", self, self.UnLink);
		--self:Disconnect("facingChanged", self, self.OnUpdateLinkFacing);
		--self:Disconnect("valueChanged", self, self.OnUpdateLinkPosition);
		entity.childLinks:removeByValue(self);
	end
end

function Entity:UnLink()
	if(self.linkInfo) then
		self:UnLinkEntity(self.linkInfo.entity)
		self.linkInfo = nil;
	end
	self.lastStandOnEntity = nil;
end

-- update this entity's position according to its link target
function Entity:UpdateEntityLink()
	local targetEntity = self:GetLinkToTarget()
	if(targetEntity) then
		if (self.linkInfo.boneName) then
			local new_x, new_y, new_z, roll, pitch, yaw = targetEntity:ComputeBoneWorldPosAndRot(self.linkInfo.boneName, self.linkInfo.pos, self.linkInfo.rot); 
			if(new_x) then
				self:SetPosition(new_x, new_y, new_z);

				-- we will simply ignore rotation. 
				if(false) then
					local obj = self:GetInnerObject();
					obj:SetField("yaw", yaw or 0);
					obj:SetField("roll", roll or 0);
					obj:SetField("pitch", pitch or 0);	
				end
			end
		else
			local x, y, z = targetEntity:GetPosition();
			--self.linkInfo.quatRot:FromAngleAxis(targetEntity:GetFacing(), mathlib.vector3d.unit_y)
			self.linkInfo.quatRot:FromEulerAnglesSequence(targetEntity:GetRoll(), targetEntity:GetPitch(), targetEntity:GetFacing(), "zxy")

			local rx, ry, rz = self.linkInfo.quatRot:RotateVector3(self.linkInfo.x, self.linkInfo.y, self.linkInfo.z)
			local curScaling = targetEntity:GetScaling();
			if(curScaling ~= self.linkInfo.scaling) then
				local scaling = curScaling / self.linkInfo.scaling;
				rx, ry, rz = rx * scaling, ry * scaling, rz * scaling;
			end
			self:SetPosition(x + rx, y + ry, z + rz)
			self:SetFacing(targetEntity:GetFacing() + self.linkInfo.facing);
		end
	end
end

function Entity:HasLinkParent(parentEntity)
	if(self == parentEntity) then
		return true
	else
		local parent = self:GetLinkToTarget()
		return parent and parent:HasLinkParent(parentEntity)
	end
end

function Entity:GetLinkToTarget()
	if(self.linkInfo) then
		return self.linkInfo.entity;
	end
end

-- @param callbackFunc: function(childEntity) end
function Entity:ForEachChildLinkEntity(callbackFunc, ...)
end

-- @return true 
function Entity:HasLinkChild(childEntity)
end

function Entity:GetLinkChild()
end

function Entity:BeginModify()
end

function Entity:EndModify()
end

-- virtual: for players, invisible players are always non-pickable. 
function Entity:SetVisible(bVisible)
	Entity._super.SetVisible(self, bVisible)
	self:SetSkipPicking(not bVisible);
end

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
	-- disable editors
end