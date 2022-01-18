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
EntityManager.AddObject(entity)
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
	Entity._super.SetSkin(self, skin, bIgnoreSetSkinId);
	if(not bIgnoreSetSkinId) then
		self.dataWatcher:SetField(self.dataFieldSkin, self:GetSkin());
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