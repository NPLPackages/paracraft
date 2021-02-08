--[[
Title: base class for AI controlled movable entities like mob, animals, npc, etc. 
Author(s): LiXizhi
Date: 2013/12/17
Desc: random walking is implemented. basic physics is implemented. 
Since all moveable entity has linear movement style, physics has to be simulated in script. (does not go to the C++ physics engine). 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovable.lua");
local EntityMovable = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovable")
local entity = MyCompany.Aries.Game.EntityManager.EntityMovable:new({x,y,z,radius});
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerHeadController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
local PlayerHeadController = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerHeadController");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local Event = commonlib.gettable("System.Core.Event");

NPL.load("(gl)script/ide/headon_speech.lua");

local math_abs = math.abs;
local math_random = math.random;
local math_floor = math.floor;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovable"));
Entity:Property({"randomWalkSteps", 1, "GetRandomWalkSteps", "SetRandomWalkSteps", auto=true});
Entity:Signal("clicked", function(mouse_button) end)

-- class name
Entity.class_name = "Movable";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
-- enabled frame move. 
Entity.framemove_interval = 0.2;
Entity.smoothFrames = 0;

Entity:Property({"group_id", GameLogic.SentientGroupIDs.Mob})

Entity.sentient_fields = {[GameLogic.SentientGroupIDs.Player] = true};

-- between (0,1), how much the player's head can look up.  1 is full. 
Entity.lookup_angle_percent = 0.8;
-- between (0,1), how much the player's head can look down.  1 is full. 
Entity.lookdown_angle_percent = 0.8;

-- How high this entity can step up when running into a block to try to get over it 
Entity.stepHeight = 0.55;

--private: 
Entity.targetX = nil;
Entity.targetY = nil;
Entity.targetZ = nil;
Entity.targetFacing = 0;
Entity.targetPitch = 0;
Entity.smoothFrames = 0;
Entity.motionX = 0;
Entity.motionY = 0;
Entity.motionZ = 0;

function Entity:ctor()
end

-- @param Entity: the half radius of the object. 
function Entity:init()
	local item = self:GetItemClass();
	if(item) then
		local x, y, z = self:GetPosition();
		if(not self.x) then
			self:SetPosition(x, y, z);
		end
		local ReplaceableTextures;
		if(not self.skin) then
			if(item:GetAssetFile() == self:GetMainAssetPath()) then
				local skin = item:GetSkinFile();
				if(skin) then
					ReplaceableTextures = {[2] = skin};
				end
			end
		end

		local obj = ObjEditor.CreateObjectByParams({
			name = self.name or self.class_name,
			IsCharacter = true,
			AssetFile = self:GetMainAssetPath(),
			ReplaceableTextures = ReplaceableTextures,
			x = x,
			y = y + item:GetOffsetY(),
			z = z,
			scaling = self.scaling or item:GetScaling(),
			facing = self.facing, 
			IsPersistent = false,
		});
		if(obj) then
			-- obj:SetField("GroupID", self.group_id);
			-- make it linear movement style
			obj:SetField("MovementStyle", 3);
		
			obj:SetField("PerceptiveRadius", self:GetSentientRadius()*BlockEngine.blocksize);
			obj:SetField("Sentient Radius", self:GetSentientRadius()*BlockEngine.blocksize);
			obj:SetField("Gravity", GameLogic.options.Gravity*2);

			self.group_id = item.group_id or self.group_id;
			obj:SetField("GroupID", self.group_id);
			for field, _ in pairs(self.sentient_fields) do
				obj:SetSentientField(field, true); 
			end

			if(item.autofacing) then
				obj:ToCharacter():AssignAIController("face", "true");
			end
			if(self.opacity and self.opacity < 1) then
				obj:SetField("opacity", self.opacity);	
			end

			-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
			obj:SetAttribute(128, true);
		
			self:SetInnerObject(obj);
			ParaScene.Attach(obj);	
		
			if(self.anim) then
				self:SetAnimation(self.anim);
			end

			self:RefreshClientModel(nil, obj);

			if(self:IsShowHeadOnDisplay()) then
				System.ShowHeadOnDisplay(true, obj, self:GetDisplayName(), GameLogic.options.NPCHeadOnTextColor);	
			end
		end

		item:UpdateInWorldCount(1);
		self:UpdateBlockContainer();
		return self;
	end
end

function Entity:IsBiped()
	return true;
end

function Entity:IsFlying()
	return self.bFlying;
end

function Entity:ToggleRunning(bRunning)
	self.isRunning = bRunning;
end

function Entity:IsRunning()
	return self.isRunning;
end

function Entity:ToggleFly(bFly)
	local player = self:GetInnerObject();
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
		player:ToCharacter():SetSpeedScale(self:GetSpeedScale()*3);
		--tricky: this prevent switching back to walking immediately
		player:SetField("VerticalSpeed", self:GetJumpupSpeed());
		
		-- BroadcastHelper.PushLabel({id="fly_tip", label = "进入飞行模式：按住鼠标右键控制方向, W键前进", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});

	elseif(bFly == false) then
		-- restore to original density
		player:SetDensity(GameLogic.options.NormalDensity);
		self.bFlying = false;

		player:SetField("CanFly",false);
		player:SetField("AlwaysFlying",false);
		player:ToCharacter():SetSpeedScale(self:GetSpeedScale());
		player:ToCharacter():FallDown();
		
		-- BroadcastHelper.PushLabel({id="fly_tip", label = "退出飞行模式", max_duration=1500, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
	return self.bFlying;
end

-- this is called on each tick, when this entity has focus and user is pressing and holding shift key. 
function Entity:OnShiftKeyPressed()
	if (self.ridingEntity) then
		self:DoUserUnmount();
	else
		local obj = self:GetInnerObject();
		if(obj) then
			obj:ToCharacter():PlayAnimation(66);
		end
	end
end

function Entity:DoUserUnmount()
	if (self.ridingEntity) then
		if(GameLogic.isRemote) then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketEntityAction:new():Init(1, nil));
		else
			self:MountEntity(nil);
			-- teleport entity to a free block nearby
			local bx, by, bz = self:GetBlockPos();
			self:PushOutOfBlocks(bx, by, bz);
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

function Entity:Jump()
	if(self.ridingEntity) then
		self:DoUserUnmount();
	end
	return Entity._super.Jump(self);
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);

	local attr = node.attr;
	if(attr) then
		self.skin = node.attr.skin;
		
		if(self.skin) then
			self:FindSkinFiles(self.skin);
		end

		if(attr.random_walk_steps) then
			self:SetRandomWalkSteps(tonumber(attr.random_walk_steps));
		end

		if(attr.scaling) then
			self.scaling = tonumber(attr.scaling);
		end
		if(attr.showHeadOn) then
			self.showHeadOn = attr.showHeadOn == "true" or attr.showHeadOn == true;
		end
		if(attr.motionX) then
			self.motionX = tonumber(attr.motionX);
		end
		if(attr.motionY) then
			self.motionY = tonumber(attr.motionX);
		end
		if(attr.motionZ) then
			self.motionZ = tonumber(attr.motionZ);
		end
		if (attr.onGround) then
			self.onGround = attr.onGround == "true" or attr.onGround == true;
		end
		if (attr.rotationPitch) then
			self.rotationPitch = tonumber(attr.rotationPitch);
			self.prevRotationPitch = self.rotationPitch;
		end
		if (attr.rotationYaw) then
			self.rotationYaw = tonumber(attr.rotationYaw);
			self.prevRotationYaw = self.rotationYaw;
		end
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	local attr = node.attr;
	if(self.scaling) then
		attr.scaling = self.scaling;
	end
	if(self.skin and self.skin~="") then
		attr.skin = self.skin;
	end
	if(self.showHeadOn) then
		attr.showHeadOn = self.showHeadOn;
	end

	if(self:GetRandomWalkSteps()~=1) then
		attr.random_walk_steps =  self:GetRandomWalkSteps();
	end
	
	if(self.motionX) then
		attr.motionX = self.motionX
	end
	if(self.motionY) then
		attr.motionY = self.motionX
	end
	if(self.motionZ) then
		attr.motionZ = self.motionZ
	end
	if (self.onGround) then
		attr.onGround = self.onGround
	end
	if (self.rotationPitch) then
		attr.rotationPitch = self.rotationPitch;
	end
	if (self.rotationYaw) then
		attr.rotationYaw = self.rotationYaw;
	end
	return node;
end

-- return the number of entities replaced
function Entity:ReplaceFile(from, to)
	if(self:GetModelFile() == from) then
		self:SetModelFile(to);
		return 1;
	end
	return 0;
end

-- get skin texture file name
function Entity:GetSkin()
	return self.skin;
end

-- @param skin: if nil, it will use the default skin. 
-- if it only contains file path, then by default it will always be set at replaceable texture id 2.
-- if the string is of format "id:filename;id:filename;...", it can be used to set multiple replaceable textures at custom index. 
-- @return true if all files exist, false if not
function Entity:FindSkinFiles(skin)
	local allExists = true;
	if(skin and skin:match("^(%d+):[^;+]")) then
		for id, filename in skin:gmatch("(%d+):([^;]+)") do
			allExists = Files.FindFile(filename) and allExists;
		end
	elseif(skin ~= "") then
		allExists = Files.FindFile(skin) and allExists;
	end
	return allExists;
end

-- set new skin texture by filename. 
-- @param skin: if nil, it will use the default skin. 
-- if it only contains file path, then by default it will always be set at replaceable texture id 2.
-- if the string is of format "id:filename;id:filename;...", it can be used to set multiple replaceable textures at custom index. 
function Entity:SetSkin(skin)
	if(self.skin ~= skin) then
		self.skin = skin;
		if(skin) then
			if(not self.isCustomModel and not self.hasCustomGeosets and not self:FindSkinFiles(skin)) then
				LOG.std(nil, "warn", "Entity:SetSkin", "skin files does not exist %s", tostring(skin));
			end
			self:RefreshClientModel();
		else
			self:RefreshSkin();
		end
	end
end

function Entity:CheckAndRemoveAttachment(player)
	local player = player or self:GetInnerObject();
	if (player) then
		if (PlayerAssetFile:HasCustomGeosets(self:GetMainAssetPath())) then
			local skin = self:GetSkin();
			local geosets, textures, attachments =  string.match(skin, "([^@]+)@([^@]+)@?(.*)");
			local charater = player:ToCharacter();

			if (attachments) then
				for id, filename in attachments:gmatch("(%d+):([^;]+)") do
					id = tonumber(id);
					charater:RemoveAttachment(id);
				end
			end
		end
	end
end

-- refresh the client's model according to current inventory settings, such as 
-- armor and hand tool. 
function Entity:RefreshClientModel(bForceRefresh, playerObj)
	local playerObj = playerObj or self:GetInnerObject();
	if(playerObj) then
		-- refresh skin and base model, preserving all custom bone info
		local assetPath = self:GetMainAssetPath()
		if(playerObj:GetField("assetfile", "") ~= assetPath) then
			playerObj:SetField("assetfile", assetPath);
			self.isCustomModel = PlayerAssetFile:IsCustomModel(assetPath);
			self.hasCustomGeosets = PlayerAssetFile:HasCustomGeosets(assetPath);
		end
		self:RefreshSkin(playerObj);
		self:RefreshRightHand(playerObj);
	end
end

function Entity:RefreshRightHand(player)
end

-- whether it is a custom model
function Entity:IsCustomModel()
	return self.isCustomModel
end

function Entity:HasCustomGeosets()
	return self.hasCustomGeosets
end

function Entity:RefreshSkin(player)
	local player = player or self:GetInnerObject();
	if(player) then
		local skin = self:GetSkin();

		if(self.isCustomModel) then
			PlayerAssetFile:RefreshCustomModel(player, skin)
			return 
		end

		if(self.hasCustomGeosets) then
			PlayerAssetFile:RefreshCustomGeosets(player, skin);
			return;
		end

		self.skins_ = self.skins_ or {};
		local skins = self.skins_;
		for id, skin in pairs(skins) do
			skin.last_filename = skin.filename;
			skin.filename = nil;
		end

		if(skin and skin~="") then
			if(skin:match("^(%d+):")) then
				for id, filename in skin:gmatch("(%d+):([^;]+)") do
					id = tonumber(id)
					skins[id] = skins[id] or {};
					skins[id].filename = filename;
					player:SetReplaceableTexture(id, ParaAsset.LoadTexture("", PlayerSkins:GetFileNameByAlias(filename), 1));
				end
			elseif(skin:match("^%d+#")) then
				-- ignore ccs skins
			else
				player:SetReplaceableTexture(2, ParaAsset.LoadTexture("", PlayerSkins:GetFileNameByAlias(skin), 1));
				skins[2] = skins[2] or {};
				skins[2].filename = skin;
			end
		end
		if(not skins[2] or not skins[2].filename) then
			-- if model has shared skin file at id 2
			local mainAssetPath = self:GetMainAssetPath()
			if(PlayerSkins:CheckModelHasSkin(mainAssetPath)) then
				local skin = PlayerSkins:GetDefaultSkinForModel(mainAssetPath)
				if(skin) then
					player:SetReplaceableTexture(2, ParaAsset.LoadTexture("", PlayerSkins:GetFileNameByAlias(skin), 1));
					skins[2] = skins[2] or {}
					skins[2].filename = skin;
				end
			end
		end
		
		for id, skin in pairs(skins) do
			if(not skin.filename and skin.last_filename) then
				player:SetReplaceableTexture(id, player:GetDefaultReplaceableTexture(id));	
			end
		end
	end
end

function Entity:doesEntityTriggerPressurePlate()
	return true;
end

-- if true, this entity can not be pushed by other movable entities
function Entity:SetStaticBlocker(bIsBlocker)
	self.isBlocker = bIsBlocker;
end

-- return true if this entity can not be pushed by other movable entities
function Entity:IsStaticBlocker()
	return self.isBlocker;
end

-- Returns true if the entity takes up space in its containing block, such as animals,mob and players. 
function Entity:CanBeCollidedWith(entity)
    return self:IsStaticBlocker();
end

-- Returns true if this entity should push and be pushed by other entities when colliding.
-- such as mob and players.
function Entity:CanBePushedBy(fromEntity)
    return not self:IsStaticBlocker();
end

function Entity:Destroy()
	self:DestroyInnerObject();
	
	local item;
	if(self.item_id and self.item_id>0) then
		item = ItemClient.GetItem(self.item_id);
	end
	if(item) then
		item:UpdateInWorldCount(-1);
	end
	Entity._super.Destroy(self);
end

-- @param x, y, z: if nil, player faces front. 
-- @param isAngle: if x, y, z is angle. 
function Entity:FaceTarget(x,y,z, isAngle)
	PlayerHeadController.FaceTarget(self, x, y, z, isAngle);
end

-- whether we shall move around 
function Entity:ShallMoveAround()
	local nTime = commonlib.TimerManager.GetCurrentTime();
	if(not self.random_interval_second) then
		-- random interval
		self.random_interval_second = math_random(3,7);
	end
	local LastWalkTime = self.LastWalkTime or 0;

	-- changes direction every [3, 5] seconds.
	if((nTime - LastWalkTime) > 1000 * self.random_interval_second) then
		-- save to memory
		self.LastWalkTime = commonlib.TimerManager.GetCurrentTime();
		self.random_interval_second = nil;
		return true;
	end
end

-- move to the given block(can only be one block from where the entity is)
-- @return true if successfully moved
function Entity:MoveTo(x,y,z)
	local canMove, new_x, new_y, new_z = self:CanMoveTo(x,y,z);
	if(canMove) then
		--local mobChar = mob:ToCharacter();
		--local s = mobChar:GetSeqController();	
		--local x, y, z = BlockEngine:real(new_x, new_y, new_z);
		--y = y - BlockEngine.half_blocksize;
		--s:RunTo(x-self.x, y-self.y, z-self.z);
		self:SetBlockTarget(x,y,z);
		return true;
	end 
end

-- automatically walk to a given position. 
function Entity:WalkTo(x,y,z)
	-- TODO: needs to calculate valid path to given pos. 
	-- echo({self.name, "walkto", x,y,z})
	self:MoveTo(x,y,z);
end

-- how much this entity likes the block
function Entity:GetPathBlocksWeight(id)
	if(not self.path_blocks_weight) then
		self.path_blocks_weight = {
			[block_types.names.Grass] = 500,
			[block_types.names.Wheat] = 1000,
			[block_types.names.Water] = -1000,
			[block_types.names.Still_Water] = -1000,
			[block_types.names.Lava] = -1000,
		};
	end
	return self.path_blocks_weight[id or 0] or 0
end

-- virtual:
-- returns a weight to determine how likely this entity will try to path to the block.
-- usually the block type at (x,y-1,z) or light value of (x,y,z) determines the likelyhood.
-- @return [0,XXX]
function Entity:GetBlockPathWeight(x, y, z)
	local weight = 0
	
	local block = BlockEngine:GetBlock(x,y,z);
	if(block and block.obstruction) then
		-- can not walk over fence, or closed BlockTrapDoor
		if(block.shape == "Fence" or block.class == "BlockTrapDoor") then
			weight = weight - 1000;
		else
			y = y + 1;
			local block = BlockEngine:GetBlock(x,y,z);
			if((block and block.obstruction) or EntityManager.HasEntityInBlock(x,y,z)) then
				weight = weight - 1000;
			end
		end
	elseif(EntityManager.HasEntityInBlock(x,y,z)) then
		weight = weight - 1000;
	else 
		-- if does not need to walk up one stair, give it some more weight. 
		weight = weight + 3;
	end

	local block = BlockEngine:GetBlock(x,y+1,z);
	if( (block and block.obstruction) or (EntityManager.HasEntityInBlock(x,y+1,z)) ) then
		weight = weight - 1000;
	end

	if(weight >= 0) then
		weight = weight + 1;
		local block = BlockEngine:GetBlock(x, y-1, z);
		if(block) then
			weight = weight + self:GetPathBlocksWeight(block.id);
		end
		if(block and block.obstruction) then
			-- add some low likelyhood for solid block types. 
			-- a very low likelyhood that entity will fall down. 
			weight = weight + 2;
		else
			local block = BlockEngine:GetBlock(x, y-2, z);
			if(not block or not block.obstruction) then
				-- never jump off cliff. two blocks below are all transparet.
				weight = weight - 1000;
			end
		end
	end
	if(weight < 0) then
		weight = 0;
	end
	return weight;
end

-- public: 
-- @return x,y,z where the entity may walk to. may return nil
function Entity:GetRandomMovePos()
	local x,y,z = self:GetBlockPos();
	local steps = self:GetRandomWalkSteps()
	if(steps>1) then
		steps = math.random(1, steps);
	end
	local w0 = self:GetBlockPathWeight(x-1, y, z);
	local w1 = self:GetBlockPathWeight(x+1, y, z);
	local w2 = self:GetBlockPathWeight(x, y, z-1);
	local w3 = self:GetBlockPathWeight(x, y, z+1);
	local w_all = w0+w1+w2+w3;
	if(w_all > 0) then
		local w = math_random(0, w_all);
		w = w - w3;
		if(w <=0 and w3~=0) then
			return x, y, z+steps;
		else
			w = w - w2;	
			if(w <=0 and w2~=0) then
				return x, y, z-steps;
			else
				w = w - w1;	
				if(w <=0 and w1~=0) then
					return x+steps, y, z;
				elseif(w0~=0) then
					return x-steps, y, z;
				end
			end
		end
	end
end

function Entity:FallDown(deltaTime)
	local obj = self:GetInnerObject();
	if(obj and obj:IsStanding()) then
		-- ignore physics when walking or running. 
		Entity._super.FallDown(self, deltaTime);
	end
end

-- try move randomly
function Entity:TryMoveRandomly()
	if(self:ShallMoveAround()) then
		local x, y, z = self:GetRandomMovePos();
		if(x) then
			if(not self:MoveTo(x,y,z)) then
				-- mob:SetFacing(Direction.directionTo3DFacing[math.random(0,3)]);
			end
		end
	end
end

-- enable headon display
function Entity:ShowHeadOnDisplay(bShow)
	local obj = self:GetInnerObject();
	if(obj) then
		if(bShow) then
			System.ShowHeadOnDisplay(true, obj, self:GetDisplayName(), GameLogic.options.NPCHeadOnTextColor);	
			self.showHeadOn = true;
		else
			System.ShowHeadOnDisplay(false, obj);	
			self.showHeadOn = nil;
		end
	end
end

function Entity:IsShowHeadOnDisplay()
	return self.showHeadOn;
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	if(mouse_button == "right" and GameLogic.GameMode:CanEditBlock()) then
		if(self:IsServerEntity() and self:IsRemote()) then
			-- LOG.std(nil, "info", "Entity:OnClick", "access denied, entity is only editable on server");
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectModelTask.lua");
			local task = MyCompany.Aries.Game.Tasks.SelectModel:new({obj=self:GetInnerObject()})
			task:Run();
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectModelTask.lua");
			local task = MyCompany.Aries.Game.Tasks.SelectModel:new({obj=self:GetInnerObject()})
			task:Run();
		end
	else
		if(self:IsRemote() and self:IsServerEntity()) then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		else
			local event = Event:new():init("onclick");	
			event.button = mouse_button;
			self:event(event);

			-- signal
			self:clicked(mouse_button);
		end
	end
	return true;
end

-- called when W key is pressed.
function Entity:MoveForward(speed)
	self.moveForward = speed;
end

-- framemove this entity when it is riding (mounted) on another entity. 
-- we will update according to mounted entity's position. 
function Entity:FrameMoveRidding(deltaTime)
	
	if(self:HasFocus()) then
		-- just in case the user changed the position.
		self:UpdatePosition();
		self.moveForward = 0;
	end
	EntityManager.Entity.FrameMoveRidding(self, deltaTime);
end

function Entity:HasTarget()
	return (self.targetX ~= nil);
end

-- walk to the top center position of given block. usually by is ignored. 
function Entity:SetBlockTarget(bx, by, bz)
	if(bx) then
		self.targetX, self.targetY, self.targetZ = BlockEngine:real_top(bx, by, bz);
	else
		self.targetX, self.targetY, self.targetZ = nil, nil, nil;
	end
end

function Entity:IsOnGround()
	return self.onGround;
end

-- called by framemove to move to target position and according to its current motion and walk speed. 
function Entity:MoveEntity(deltaTime, bTryMove)
	if(self:IsRemote()) then
		if (self.smoothFrames > 0) then
            local newX = self.x + (self.targetX - self.x) / self.smoothFrames;
            local newY = self.y + (self.targetY - self.y) / self.smoothFrames;
            local newZ = self.z + (self.targetZ - self.z) / self.smoothFrames;
            self.rotationYaw = (self.rotationYaw + mathlib.WrapAngleTo180(self.targetYaw - self.rotationYaw) / self.smoothFrames);
            self.rotationPitch = (self.rotationPitch + mathlib.WrapAngleTo180(self.targetPitch - self.rotationPitch) / self.smoothFrames);
			self.smoothFrames = self.smoothFrames - 1;
            self:SetPosition(newX, newY, newZ);
        else
			local newX = self.targetX or self.x;
			local newY = self.targetY or self.y;
			local newZ = self.targetZ or self.z;
			self.rotationYaw = self.targetYaw or self.rotationYaw;
			self.rotationPitch = self.targetPitch or self.rotationPitch;
            self:SetPosition(newX, newY, newZ);
        end
		if(self.prevRotationPitch~=self.rotationPitch or self.prevRotationYaw~=self.RotationYaw) then
			self.prevRotationPitch = self.rotationPitch;
			self.prevRotationYaw = self.rotationYaw;
			self:SetRotation(self.rotationYaw, self.rotationPitch);
		end
	else
		deltaTime = math.min(0.05, deltaTime);
		local obj = self:GetInnerObject();
		if(not obj) then
			return;
		end
		local bFlying = self:IsFlying();
		local bHasMotionLast = self:HasMotion();
		if(self:HasTarget()) then
			local dx, dy, dz;
			dx = self.targetX - self.x;
			dz = self.targetZ - self.z;
			
			local moveLength = self:GetWalkSpeed() * deltaTime;
			if(not bFlying) then
				local dist = (dx)^2 + (dz)^2;
				if(dist <= (moveLength^2) or dist < 0.01) then
					-- reached position
					self:SetPosition(self.targetX, self.y, self.targetZ);
					self:SetBlockTarget(nil, nil, nil);
					self.motionX = 0;
					self.motionY = 0;
					self.motionZ = 0;
				else
					local inverse_dist = 1 / (dist ^ 0.5) * moveLength;
					self.motionX = dx * inverse_dist;
					-- self.motionY = dy * inverse_dist;
					self.motionZ = dz * inverse_dist;
				
					local facing = self:GetFacing()*0.4 + Direction.GetFacingFromOffset(dx, 0, dz) * 0.6;
					self:SetFacing(facing);
				end
			else
				--  flying now 
				local dy = self.targetY - self.y;
				local dist = (dx)^2 + (dz)^2 + (dy)^2;
				if(dist <= moveLength or dist < 0.01) then
					-- reached position
					self:SetBlockTarget(nil, nil, nil);
					self:SetPosition(self.targetX, self.y, self.targetZ);
					self.motionX = 0;
					self.motionY = 0;
					self.motionZ = 0;
				else
					local inverse_dist = 1 / (dist ^ 0.5) * moveLength;
					self.motionX = dx * inverse_dist;
					self.motionY = dy * inverse_dist;
					self.motionZ = dz * inverse_dist;
					local facing = self:GetFacing()*0.4 + Direction.GetFacingFromOffset(dx, 0, dz) * 0.6;
					self:SetFacing(facing);
				end
			end
		else
			if (self.onGround and bHasMotionLast) then
				local dist_sq = self.motionX ^ 2 + self.motionZ ^ 2;
				local decayFactor = 1-self:GetSurfaceDecay();
				self.motionX = self.motionX * decayFactor;
				self.motionZ = self.motionZ * decayFactor;
				if(dist_sq < 0.00001) then
					-- make it stop when motion is very small
					self.motionX = 0;
					-- self.motionY = 0;
					self.motionZ = 0;
				end
			end
		end

		local dist_sq = self.motionX ^ 2 + self.motionZ ^ 2;
		
		if(bFlying) then
			dist_sq = dist_sq + self.motionY ^ 2;
		end

		if(not self.ridingEntity and (dist_sq > 0.0001 or (bFlying and not self.onGround) )) then
			obj:SetField("AnimID", 5);
		else
			obj:SetField("AnimID", self:GetLastAnimId() or 0);
		end

		-- LOG.std(nil, "info", "category", {self.motionX,self.motionY,self.motionZ, self:GetGravity()*2*deltaTime*deltaTime});

		-- apply gravity
		if(not bFlying) then
			-- we will double gravity to make it look better
			self.motionY = math.max(-1, self.motionY - self:GetGravity()*2*deltaTime*deltaTime);
		end
		
		self:MoveEntityByDisplacement(self.motionX,self.motionY,self.motionZ);

		if(dist_sq == 0 and self.onGround) then
			-- restore to normal frame move interval. 
			self:SetFrameMoveInterval(nil);
		else
			-- tick at high FPS
			self:SetFrameMoveInterval(self:GetTickRateInterval());
		end
	end
end

-- @param posRotIncrements: smooth movement over this number of ticks
function Entity:SetPositionAndRotation2(x,y,z, facing, pitch, posRotIncrements)
    self.targetX = x;
    self.targetY = y;
    self.targetZ = z;
    self.targetFacing = facing or self.targetFacing;
    self.targetPitch = pitch or self.targetPitch;
	self.smoothFrames = (posRotIncrements or 1);
			
	if(self.framemove_interval>=0.1) then
		self.lastFrameMoveInterval = self.framemove_interval;
		self:SetFrameMoveInterval(0.02);
	end
end

function Entity:FrameMoveRidding(deltaTime)
	if(GameLogic.isRemote and not self:HasFocus()) then
		if (self.smoothFrames > 0) then
			local lastFacing = self:GetFacing();
			local deltaFacing = mathlib.ToStandardAngle(self.targetFacing - lastFacing);
			local facing = lastFacing + deltaFacing / self.smoothFrames;
			local lastRotPitch = self.rotationPitch or 0;
			local rotationPitch = lastRotPitch + (self.targetPitch - lastRotPitch) / self.smoothFrames;
			self.smoothFrames = self.smoothFrames - 1;
			self:SetRotation(facing, lastRotPitch);
		else
			if(self.lastFrameMoveInterval) then
				self:SetFrameMoveInterval(self.lastFrameMoveInterval);
			end
        end
	end
	Entity._super.FrameMoveRidding(self, deltaTime);
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(GameLogic.isRemote and not self:HasFocus()) then
		if (self.smoothFrames > 0) then
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
			local lastFacing = self:GetFacing();
			local deltaFacing = mathlib.ToStandardAngle(self.targetFacing - lastFacing);
			local facing = lastFacing + deltaFacing / self.smoothFrames;
			local lastRotPitch = self.rotationPitch or 0;
			local rotationPitch = lastRotPitch + (self.targetPitch - lastRotPitch) / self.smoothFrames;
			self.smoothFrames = self.smoothFrames - 1;

			self:SetPosition(x, y, z);
			self:SetRotation(facing, lastRotPitch);
		else
			if(self.lastFrameMoveInterval) then
				self:SetFrameMoveInterval(self.lastFrameMoveInterval);
			end
        end
	else
		local mob = self:UpdatePosition();
		if(not mob) then
			return;
		end
		if(not mob:IsSentient()) then
			-- only update non-critical data here. since object is far from the player. 
			return;
		end
		if(self:HasFocus() and not self:HasMotion()) then
			self.moveForward = 0;
		else
			-- only move physically and autonomously when not focused. 
			if(not self:IsDummy()) then
				self:MoveEntity(deltaTime);
			end
		end
		Entity._super.FrameMove(self, deltaTime);	
	end
end