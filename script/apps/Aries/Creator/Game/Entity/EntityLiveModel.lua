--[[
Title: Live Model
Author(s): LiXizhi
Date: 2021/12/3
Desc: Live model entity is an iteractive model that can be moved around the scene and stacked upon one another. 
This class is almost identical to EntityBlockModel. 
- If model filename contains "_char", we will use auto turning
- If model filename contains "_drag", we will enable dragging even if it has real physics

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
local EntityLiveModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel")
local entity = GameLogic.EntityManager.EntityLiveModel:Create({bx,by,bz});
entity:SetModelFile(filename);
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ModelMountPoints.lua");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
local ModelMountPoints = commonlib.gettable("MyCompany.Aries.Game.Common.ModelMountPoints");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Event = commonlib.gettable("System.Core.Event");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");


local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel"));

Entity:Property({"scale", 1, "getScale", "setScale"});
Entity:Property({"minScale", 0.02});
Entity:Property({"maxScale", 1000});
Entity:Property({"yaw", 0, "getYaw", "setYaw"});
Entity:Property({"useRealPhysics", false, "HasRealPhysics", "EnablePhysics", auto=true});
-- used by ItemLiveModel:GetNearbyPhysicalModelDropPoints
Entity:Property({"gridSize", BlockEngine.blocksize*0.25, "GetGridSize", "SetGridSize", auto=true});
Entity:Property({"dropRadius", 0.2, "GetDropRadius", "SetDropRadius", auto=true});
Entity:Property({"isAlwaysLoadPhysics", true, "IsAlwaysLoadPhysics", "SetAlwaysLoadPhysics"});
Entity:Property({"bIsAutoTurning", nil, "IsAutoTurningDuringDragging", "SetAutoTurningDuringDragging"});
Entity:Property({"isStackable", nil, "IsStackable", "SetIsStackable"});
Entity:Property({"stackHeight", 0.2, "GetStackHeight", "SetStackHeight"});
Entity:Property({"canDrag", nil, "GetCanDrag", "SetCanDrag"});
-- TODO: if the object can only be dragged along the given axis.
Entity:Property({"dragDirection", nil, "GetDragDirection", "SetDragDirection"});
Entity:Property({"idleAnim", 0, "GetIdleAnim", "SetIdleAnim", auto=true});

Entity:Property({"onclickEvent", nil, "GetOnClickEvent", "SetOnClickEvent", auto=true});
Entity:Property({"onhoverEvent", nil, "GetOnHoverEvent", "SetOnHoverEvent", auto=true});
Entity:Property({"onmountEvent", nil, "GetOnMountEvent", "SetOnMountEvent", auto=true});
Entity:Property({"tag", nil, "GetTag", "SetTag", auto=true});
Entity:Property({"category", nil, "GetCategory", "SetCategory", auto=true});

Entity:Signal("beforeDestroyed")
Entity:Signal("clicked", function(mouse_button) end)

Entity.default_file = "character/common/headquest/headquest.x";
-- persistent object by default. 
Entity.is_persistent = true;
-- whether this entity can be synchronized on the network by EntityTrackerEntry. 
Entity.isServerEntity = true;
-- class name
Entity.class_name = "LiveModel";
-- register class
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
-- enabled frame move for syncing  
Entity.framemove_interval = 1;
Entity.group_id = GameLogic.SentientGroupIDs.NPC;
-- we will disable code actor picking control
Entity.disable_codeactor_picking_control = true

function Entity:ctor()
	self.item_id = self.item_id or block_types.names.LiveModel;
	self.inventory = InventoryBase:new():Init();
	self.inventory:SetClient();
	self:SetRuleBagSize(16);

	local dataWatcher = self:GetDataWatcher(true);
	-- main asset data. 
	self.dataFieldAsset = dataWatcher:AddField(nil, nil);
	-- animation data. 
	self.dataFieldAnim = dataWatcher:AddField(nil, nil);
	-- scale data. 
	self.dataFieldScale = dataWatcher:AddField(nil, nil);
	-- skin data. 
	self.dataFieldSkin = dataWatcher:AddField(nil, nil);
	-- self:SetDummy(true);
end 

function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	if(not self.name) then
		self.name = ParaGlobal.GenerateUniqueID()
	end
	self:CreateInnerObject(self.filename, self.scaling);

	-- self:SetDummy(true);

	if(AppGeneralGameClient.SyncEntityLiveModel and self:GetCanDrag()) then
		AppGeneralGameClient:SyncEntityLiveModel(self);
	end
	
	return self;
end

-- virtual: set as dead and will be destroyed
function Entity:SetDead()
	Entity._super.SetDead(self)
	self:Destroy();
end

-- bool: whether has command panel
function Entity:HasCommand()
	return false;
end

function Entity:GetCommandTitle()
	return L"输入初始化命令"
end

-- bool: whether show the rule panel
function Entity:HasRule()
	return false;
end

-- the title text to display (can be mcml)
function Entity:GetRuleTitle()
	return L"规则";
end

-- bool: whether show the bag panel
function Entity:HasBag()
	return false;
end

-- the title text to display (can be mcml)
function Entity:GetBagTitle()
	return L"背包";
end

-- send data watcher from client to server
-- @param bForceAll: if true it will send all fields, otherwise just changed ones.
function Entity:UpdateAndSendDataWatcher(bForceAll)
	self:SaveToDataWatcher()
	GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketEntityMetadata:new():Init(self.entityId, self:GetDataWatcher(), bForceAll));
end

-- update watched data according to current entity's value
function Entity:SaveToDataWatcher()
	local dataWatcher = self:GetDataWatcher();
	local obj = self:GetInnerObject();
	if(not obj) then
		return;
	end
	local newAsset = self:GetModelFile();
	local watchedAsset = dataWatcher:GetField(self.dataFieldAsset);
	if(watchedAsset ~= newAsset) then
		dataWatcher:SetField(self.dataFieldAsset, newAsset);
	end
	local watchedAnimId = dataWatcher:GetField(self.dataFieldAnim);
	local curAnimId = obj:GetField("AnimID", curAnimId);
	if(watchedAnimId ~= curAnimId) then
		dataWatcher:SetField(self.dataFieldAnim, curAnimId);
	end
	local watchedScale = dataWatcher:GetField(self.dataFieldScale);
	local curScale = obj:GetScale();
	if(watchedScale ~= curScale) then
		dataWatcher:SetField(self.dataFieldScale, curScale);
	end
	local watchedSkin = dataWatcher:GetField(self.dataFieldSkin);
	local curSkin = self:GetSkin();
	if(watchedSkin ~= curSkin and curSkin) then
		dataWatcher:SetField(self.dataFieldSkin, curSkin);
	end
end

-- update entity's value according to watched data received from server.
function Entity:LoadFromDataWatcher()
	local dataWatcher = self:GetDataWatcher();
	local obj = self:GetInnerObject();
	if(not obj) then
		return;
	end
		
	local curAsset = dataWatcher:GetField(self.dataFieldAsset);
	if(curAsset and self:GetModelFile() ~= curAsset) then
		self:SetModelFile(curAsset);
	end
	local curAnimId = dataWatcher:GetField(self.dataFieldAnim);
	if(obj:GetField("AnimID", 0) ~= curAnimId and curAnimId) then
		obj:SetField("AnimID", curAnimId);
	end
	local curScale = dataWatcher:GetField(self.dataFieldScale);
	if(obj:GetScale() ~= curScale and curScale) then
		obj:SetScale(curScale);
	end
	local curSkinId = dataWatcher:GetField(self.dataFieldSkin);
	if(self:GetSkin() ~= curSkinId and curSkinId) then
		self:SetSkin(curSkinId, true);
	end
end

function Entity:SetAnimation(animId)
	Entity._super.SetAnimation(self, animId);
end

function Entity:OnMainAssetLoaded()
	if(self:GetIdleAnim() ~= 0 or (self.lastAnimId or 0)~=0) then
		self:SetAnimation(self.lastAnimId or self:GetIdleAnim());
	end
	self:CheckLoadPhysics()
end

-- set the model name
function Entity:SetMainAssetPath(name)
	if(self:GetMainAssetPath() ~= name) then
		self.mainAssetPath = name;
		self.asset_rendertech = 0;
		return true;
	end
end

function Entity:SetBlockInRightHand(blockinhand)
end

-- update data in data watcher, such as asset, skin, anim, etc
function Entity:SyncDataWatcher()
	if(self:IsRemote()) then
		-- on client: update entity's value according to watched data received from server.
		self:LoadFromDataWatcher();
	elseif(GameLogic.isServer) then
		-- on server: update watched data according to current entity's value
		self:SaveToDataWatcher();
	end
end

-- return the number of entities replaced
function Entity:ReplaceFile(from, to)
	if(self:GetModelFile() == from) then
		self:SetModelFile(to);
		return 1;
	end
	return 0;
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

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	if(attr) then
		self:setScale(tonumber(attr.scale or 1));
		
		self.skin = node.attr.skin;
		if(self.skin) then
			self:FindSkinFiles(self.skin);
		end
		if(attr.useRealPhysics) then
			self.useRealPhysics = (attr.useRealPhysics == "true") or (attr.useRealPhysics == true);
		end
		if(attr.isStackable) then
			self.isStackable = (attr.isStackable == "true") or (attr.isStackable == true);
		end
		if(attr.stackHeight) then
			self.stackHeight = tonumber(attr.stackHeight);
		end
		if(attr.bIsAutoTurning) then
			self.bIsAutoTurning = (attr.bIsAutoTurning == "true") or (attr.bIsAutoTurning == true);
		end
		if(attr.canDrag) then
			self.canDrag = (attr.canDrag == "true") or (attr.canDrag == true);
		end
		if(attr.onclickEvent) then
			self:SetOnClickEvent(attr.onclickEvent);
		end
		if(attr.onhoverEvent) then
			self:SetOnHoverEvent(attr.onhoverEvent);
		end
		if(attr.onmountEvent) then
			self:SetOnMountEvent(attr.onmountEvent);
		end
		if(attr.tag) then
			self:SetTag(attr.tag);
		end
		if(attr.category) then
			self.category = attr.category
		end
		if(attr.hasMount) then
			self:CreateGetMountPoints():LoadFromXMLNode(node)
		end
		if(attr.filename) then
			self:SetModelFile(attr.filename);
		end
		if(attr.linkTo) then
			self:TryLinkToEntityByName(attr.linkTo)
		end
		if(attr.idleAnim) then
			self.idleAnim = tonumber(attr.idleAnim)
		end
		if(attr.lastAnim) then
			self.lastAnimId = tonumber(attr.lastAnim)
		end
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	node.attr.filename = self:GetModelFile();
	if(self:getScale()~= 1) then
		node.attr.scale = self:getScale();
	end
	if(self.skin and self.skin~="") then
		node.attr.skin = self.skin;
	end
	if(self.onclickEvent) then
		node.attr.onclickEvent = self.onclickEvent
	end
	if(self.onhoverEvent) then
		node.attr.onhoverEvent = self.onhoverEvent
	end
	if(self.onmountEvent) then
		node.attr.onmountEvent = self.onmountEvent
	end
	if(self.tag and self.tag~="") then
		node.attr.tag = self.tag
	end
	if(self.category and self.category~="") then
		node.attr.category = self.category
	end
	if(self.linkInfo and self.linkInfo.entity) then
		node.attr.linkTo = self.linkInfo.entity:GetName();
	end
	if(self.idleAnim ~= 0) then
		node.attr.idleAnim = self.idleAnim;
	end
	node.attr.x, node.attr.y, node.attr.z = self:GetPosition()
	if(self.useRealPhysics) then
		node.attr.useRealPhysics = true;
	end
	node.attr.canDrag = self.canDrag;
	node.attr.stackHeight = self.stackHeight;
	node.attr.isStackable = self.isStackable;
	node.attr.bIsAutoTurning = self.bIsAutoTurning;
	local lastAnim = self:GetLastAnimId();
	if((lastAnim or 0) ~= (self.idleAnim or 0)) then
		node.attr.lastAnim = lastAnim
	end

	if(self:GetMountPoints()) then
		self:GetMountPoints():SaveToXMLNode(node, bSort)
	end

	return node;
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	Entity._super.OnClick(self, x, y, z, mouse_button);
	return true;
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(GameLogic.isRemote) then
	end
end

-- we will use C++ polygon-level physics engine for real physics. 
function Entity:HasRealPhysics()
	return self.useRealPhysics;
end

-- this function may remove entity object and create a new one inplace
function Entity:EnablePhysics(bEnabled)
	if( (self.useRealPhysics==true) ~= (bEnabled==true)) then
		self.useRealPhysics = bEnabled == true;
		local obj = self:GetInnerObject()
		if(obj) then
			obj:SetField("EnablePhysics", self.useRealPhysics);
			if(self.useRealPhysics) then
				self:LoadPhysics()
			end
		end
	end
end

function Entity:LoadPhysics()
	local obj = self:GetInnerObject()
	if(obj) then
		-- tricky code: we will make the geometry dirty by set facing and back for CBipedObject 
		local facing = obj:GetFacing()
		obj:SetFacing(facing+0.001)
		obj:SetFacing(facing)
		if(self:IsAlwaysLoadPhysics()) then
			obj:LoadPhysics()
		end
		-- for bmax model, one can simply call obj:LoadPhysics()
	end
end

-- we wil ensure physics are loaded.  This function can be called very often, such as during mouse picking. 
-- @return true if we have loaded physics
function Entity:CheckLoadPhysics()
	if(self:HasRealPhysics()) then
		local obj = self:GetInnerObject()
		if(obj and obj:GetField("EnablePhysics", false) and obj:GetPrimaryAsset():IsLoaded()) then
			obj:LoadPhysics()
			return true;
		end
	end
end

-- whether to force load physics, if false, it will only load when player collide with it. 
function Entity:IsAlwaysLoadPhysics()
	return self.isAlwaysLoadPhysics;
end

function Entity:GetDisplayName()
	local displayName = Entity._super.GetDisplayName(self);
	if(not displayName) then
		displayName = format("%s:%s", self:GetModelFile() or "", self:GetName() or "");
	end
	return displayName;
end

-- this is helper function that derived class can use to create an inner mesh or character object. 
function Entity:CreateInnerObject()
	local x, y, z = self:GetPosition();
	
	local obj = ObjEditor.CreateObjectByParams({
		name = self.name or self.class_name,
		IsCharacter = true,
		AssetFile = self:GetMainAssetPath() or self.default_file,
		ReplaceableTextures = ReplaceableTextures,
		x = x,
		y = y,
		z = z,
		scaling = self.scaling,
		facing = self.facing, 
		IsPersistent = false,
	});

	if(obj) then
		-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
		obj:SetAttribute(128, true);
		obj:SetField("MovementStyle", 3); -- linear
		obj:SetField("RenderDistance", 100);
		if(self:HasRealPhysics()) then
			obj:SetField("EnablePhysics", true);
			if(self:IsAlwaysLoadPhysics()) then
				self:LoadPhysics(); 
			end
		end
	
		self:SetInnerObject(obj);
		ParaScene.Attach(obj);
		if(self:GetIdleAnim() ~= 0 or (self.lastAnimId or 0) ~= 0) then
			self:SetAnimation(self.lastAnimId or self:GetIdleAnim())
		end

		self:Refresh(nil, obj)

		self:UpdateBlockContainer();
	end
	return obj;
end


function Entity:getYaw()
	return self:GetFacing();
end

function Entity:setYaw(yaw)
	if(self:getYaw() ~= yaw) then
		self:SetFacing(yaw);
		self:valueChanged();
	end
end

function Entity:SetScaling(v)
	self:setScale(v)
end

function Entity:GetScaling()
	return self:getScale()
end

function Entity:getScale()
	return self.scaling or 1;
end

function Entity:setScale(scale)
	if(self:getScale() ~= scale) then
		scale = math.min(math.max(self.minScale, scale), self.maxScale);
		self.scaling = scale;
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetScale(scale);
		end
		self:valueChanged();
	end
end

function Entity:Destroy()
	self:beforeDestroyed();
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

function Entity:Refresh(bForceRefresh, playerObj)
	local playerObj = playerObj or self:GetInnerObject();
	if(playerObj) then
		-- refresh skin and base model, preserving all custom bone info
		local assetPath = self:GetMainAssetPath()
		if(playerObj:GetField("assetfile", "") ~= assetPath) then
			local skin = CustomCharItems:GetSkinByAsset(assetPath);
			if (skin) then
				self.mainAssetPath = CustomCharItems.defaultModelFile;
				self.skin = skin;
				assetPath = self.mainAssetPath;
				self:GetDataWatcher():SetField(self.dataMainAsset, assetPath);
			end;
			playerObj:SetField("assetfile", assetPath);
		end
		self.isCustomModel = PlayerAssetFile:IsCustomModel(assetPath);
		self.hasCustomGeosets = PlayerAssetFile:HasCustomGeosets(assetPath);
		self:RefreshSkin(playerObj);
	end
end


function Entity:EndEdit()
	Entity._super.EndEdit(self);
	self:MarkForUpdate();
end

-- @param filename: if nil, self.filename is used
function Entity:GetModelDiskFilePath(filename)
	return Files.GetFilePath(commonlib.Encoding.Utf8ToDefault(filename or self:GetModelFile()));
end

function Entity:SetModelFile(filename)
	if(self.filename ~= filename) then
		self.filename = filename;
		filename = self:GetModelDiskFilePath(filename);
		self:SetMainAssetPath(filename);
		self:Refresh();
	end
end

function Entity:GetModelFile()
	return self.filename;
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
			PlayerAssetFile:RefreshCustomGeosets(player, skin, self);
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
			elseif(skin:match("^%d+;")) then
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

function Entity:SetSkin(skin)
	if(self.skin ~= skin) then
		self.skin = skin;
		if(skin) then
			local customSkin = skin;
			if (self:HasCustomGeosets()) then
				if(skin:match("^(%d+):[^;+]")) then
					-- this never happens in a movie block actor, since movie block actor uses "id1;id2;..."
					customSkin = CustomCharItems:ReplaceSkinTexture(self.skin, skin);
				end
			end
			self.skin = customSkin;
			if (not self.isCustomModel and not self.hasCustomGeosets) then
				if (not self:FindSkinFiles(skin)) then
					LOG.std(nil, "warn", "Entity:SetSkin", "skin files does not exist %s", tostring(skin));
				end
			end
		else
			if (not self:HasCustomGeosets()) then
				self.skin = skin;
			end
		end
		self:Refresh();
	end
end

-- get skin texture file name
function Entity:GetSkin()
	return self.skin;
end

-- get mount points and create it if not exist
function Entity:CreateGetMountPoints()
	if(not self.mountpoints) then
		self.mountpoints = ModelMountPoints:new():Init(self)
	end
	return self.mountpoints;
end

-- this function may return nil if no mount points are created. 
function Entity:GetMountPoints()
	return self.mountpoints;
end

-- this function may return nil if no mount points are created. 
function Entity:HasMountPoints()
	return self.mountpoints and self.mountpoints:GetCount() > 0;
end

-- this function may return nil if no mount points are created. 
function Entity:GetMountPointsCount()
	return self.mountpoints and self.mountpoints:GetCount() or 0;
end

function Entity:HasAnyRule()
	return (self.cmd or "")~="" or not self.inventory:IsEmpty();
end

function Entity:OnMount(mountPointName, mountpointIndex, mountedEntity)
	local event = Event:new():init("onmount");	
	self:event(event);
	if(self.onmountEvent) then
		local x, y, z = self:GetBlockPos();
		GameLogic.RunCommand(string.format("/sendevent %s {x=%d, y=%d, z=%d, name=%q, mountname=%q, mountindex = %d}", self.onmountEvent, x, y, z, self.name, mountPointName or "", mountpointIndex or 0))
		return true;
	end
end

function Entity:OnHover(hoverEntity)
	if(self.onhover) then
		local event = Event:new():init("onhover");	
		self:event(event);

		local x, y, z = self:GetBlockPos();
		GameLogic.RunCommand(string.format("/sendevent %s {x=%d, y=%d, z=%d, name=%q, }", self.onmountEvent, x, y, z, self.name))
		return true;
	end
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		if(mouse_button=="left" or self.onclickEvent) then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		elseif(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			self:OpenEditor("entity", entity);
			return true;
		end
	else
		if(mouse_button == "left") then
			local event = Event:new():init("onclick");	
			event.button = mouse_button;
			self:event(event);
			-- signal
			self:clicked(mouse_button);

			if(self.onclickEvent) then
				local x, y, z = self:GetBlockPos();
				GameLogic.RunCommand(string.format("/sendevent %s {x=%d, y=%d, z=%d, name=%q}", self.onclickEvent, x, y, z, self.name))
				return true;
			end
		else
			if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
				self:OpenEditor("entity", entity);
				return true;
			elseif(mouse_button=="left") then
				self:OnActivated(entity);
			end
		end
	end

	-- let us handle mount point interactions here. 
	if(self:GetMountPoints()) then
		local mp = self:GetMountPoints():GetMountPointByXY();
		if(mp) then
			local entityPlayer = entity;
			if(entityPlayer) then
				local x, y, z = self:GetMountPoints():GetMountPositionInWorldSpace(mp:GetIndex())
				local facing = self:GetMountPoints():GetMountFacingInWorldSpace(mp:GetIndex())
				entityPlayer:SetPosition(x,y,z);
				entityPlayer:SetFacing(facing)
			end
		end
		return true
	end

	if(self:HasRealPhysics() or self:HasAnyRule()) then
		return true;
	end
end


function Entity:OpenEditor(editor_name, entity)
	local ctrl_pressed = System.Windows.Keyboard:IsCtrlKeyPressed();
	if(ctrl_pressed) then
		Entity._super.OpenEditor(self, editor_name, entity);
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
		local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
		if(EditModelTask.GetInstance()) then
			EditModelTask.GetInstance():SetTransformMode(true)
			EditModelTask.GetInstance():SelectModel(self);
		end
	end
end

-- but we use the current relative position between this and link target. 
-- and if we move the current entity after the a link is established, we will modify the relative position.
-- when the linkTarget's position and facing changes, the entity will also move according to the last relative position. 
-- LinkTo function is suitable for linking between two static objects, like an apple can be linked to a table. 
-- if we already attachedTo an object, we will detach from it, before link to it. 
-- @param targetEntity: string or entity object. which entity to link to. if nil, it will detach from existing entity. 
function Entity:LinkTo(targetEntity)
	if(targetEntity) then
		if(self:HasLinkChild(targetEntity)) then
			-- recursive link is ignored. 
			return
		end
		self.linkInfo = self.linkInfo or {};
		local srcEntity = self
		local x, y, z = srcEntity:GetPosition()
		local tx, ty, tz = targetEntity:GetPosition()

		local quatRot = Quaternion:new():FromAngleAxis(-targetEntity:GetFacing(), mathlib.vector3d.unit_y)
		self.linkInfo.x, self.linkInfo.y, self.linkInfo.z = quatRot:RotateVector3(x - tx, y - ty, z - tz)
		self.linkInfo.facing = srcEntity:GetFacing() - targetEntity:GetFacing();
		self.linkInfo.scaling = targetEntity:GetScaling()
		self.linkInfo.quatRot = quatRot;
		

		if(self.linkInfo.entity ~= targetEntity) then
			self:UnLinkEntity(self.linkInfo.entity)
			self.linkInfo.entity = targetEntity
			targetEntity:Connect("valueChanged", self, self.UpdateEntityLink);
			targetEntity:Connect("facingChanged", self, self.UpdateEntityLink);
			targetEntity:Connect("scalingChanged", self, self.UpdateEntityLink);
			targetEntity:Connect("beforeDestroyed", self, self.UnLink);
			targetEntity.childLinks = targetEntity.childLinks or {};
			targetEntity.childLinks[self] = true;
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
		entity.childLinks[self] = nil;
	end
end

function Entity:UnLink()
	if(self.linkInfo) then
		self:UnLinkEntity(self.linkInfo.entity)
		self.linkInfo = nil;
	end
end

-- update this entity's position according to its link target
function Entity:UpdateEntityLink()
	local targetEntity = self:GetLinkToTarget()
	if(targetEntity) then
		local x, y, z = targetEntity:GetPosition();
		self.linkInfo.quatRot:FromAngleAxis(targetEntity:GetFacing(), mathlib.vector3d.unit_y)
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

-- @param callbackFunc: function(childEntity) end
function Entity:ForEachChildLinkEntity(callbackFunc, ...)
	if(self.childLinks) then
		for child, _ in pairs(self.childLinks) do
			callbackFunc(child, ...)
		end
	end
end

-- @return true 
function Entity:HasLinkChild(childEntity)
	if(self.childLinks) then
		for child, _ in pairs(self.childLinks) do
			if(child == childEntity) then
				return true;
			elseif(child:HasLinkChild(childEntity)) then
				return true;
			end
		end
	end
end

function Entity:GetLinkChildCount()
	local count = 0
	if(self.childLinks) then
		for child, _ in pairs(self.childLinks) do
			count = count + 1
		end
	end
	return count
end

function Entity:GetLinkToTarget()
	if(self.linkInfo) then
		return self.linkInfo.entity;
	end
end

-- this function is only used during world loading, in case the entity name is not loaded yet, 
-- we will wait some time and try again. 
function Entity:TryLinkToEntityByName(name)
	if(not self:LinkToEntityByName(name)) then
		local tryCount = 0;
		local maxTryCount = 3;
		local tryInterval = 200; --ms
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			tryCount = tryCount + 1;
			if(not self.linkInfo and not self:LinkToEntityByName(name) and tryCount >= maxTryCount) then
				timer:Change(tryInterval, nil)
			end
		end})
		mytimer:Change(tryInterval, nil)
	end
end

-- use LinkTo() in most cases
-- @return true if target entity is found and linked. 
function Entity:LinkToEntityByName(name)
	local entity = EntityManager.GetEntity(name)
	if(entity) then
		self:LinkTo(entity)
		return true;
	end
end

-- during dragging, we will disable picking and physics. 
function Entity:BeginDrag()
	self:SetSkipPicking(true);
	self.beforeDragHasPhysics = self:HasRealPhysics();
	if(self.beforeDragHasPhysics) then
		self:EnablePhysics(false);
	end
	self:ForEachChildLinkEntity(Entity.BeginDrag)
end

-- when dragging ends, we will restore picking and physics. 
function Entity:EndDrag()
	self:SetSkipPicking(false);
	if(self.beforeDragHasPhysics) then
		self:EnablePhysics(true);
		self.beforeDragHasPhysics = nil;
	end
	self:ForEachChildLinkEntity(Entity.EndDrag)
end

-- if model filename contains "_char", we will use auto turning
function Entity:IsAutoTurningDuringDragging()
	if(self.bIsAutoTurning == nil) then
		-- some automatic guess for default value
		if(self:HasCustomGeosets() or (self.filename and self.filename:match("_char"))) then
			return true;
		else
			return false;
		end
	end
	return self.bIsAutoTurning
end

function Entity:SetAutoTurningDuringDragging(bAutoTurn)
	self.bIsAutoTurning = bAutoTurn
end

-- if the entity can be placed in the same location
function Entity:IsStackable()
	if(self.isStackable== nil) then
		-- some automatic guess for default value
		if(self:HasCustomGeosets()) then
			return false;
		else
			return true;
		end
	end
	return self.isStackable
end

function Entity:SetIsStackable(isStackable)
	self.isStackable = isStackable
end

function Entity:GetStackHeight()
	return self.stackHeight;
end

function Entity:SetStackHeight(stackHeight)
	self.stackHeight = stackHeight;
end

function Entity:CanHighlight()
	return self:GetCanDrag();
end

function Entity:GetCanDrag()
	if(self.canDrag== nil) then
		-- some default value
		if(self:HasRealPhysics() and (not self.filename or not self.filename:match("_drag"))) then
			return false
		else
			return true
		end
	end
	return self.canDrag;
end

function Entity:SetCanDrag(canDrag)
	if(self.canDrag ~= canDrag) then
		self.canDrag = canDrag;

		if(AppGeneralGameClient.UnsyncEntityLiveModel) then
			if(canDrag) then
				AppGeneralGameClient:SyncEntityLiveModel(self);
			else
				AppGeneralGameClient:UnsyncEntityLiveModel(self);
			end
		end
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

-- whether it can be searched via Ctrl+F FindBlockTask
function Entity:IsSearchable()
	return true;
end

-- virtual function:
-- this function is called when mouse press event is fired when cursor in on the entity. 
-- if self:isCaptureMouse() is true, all subsequent mouse move and mouse release are also invoked on the entity. 
function Entity:mousePressEvent(event)
	local item = self:GetItemClass()
	item:mousePressEvent(event)
	self:setCaptureMouse(event:isAccepted())
end

function Entity:mouseMoveEvent(event)
	local item = self:GetItemClass()
	item:mouseMoveEvent(event)
end

function Entity:mouseReleaseEvent(event)
	local item = self:GetItemClass()
	item:mouseReleaseEvent(event)
	self:setCaptureMouse(false)
end

-- called every frame
function Entity:FrameMove(deltaTime)
	-- Entity._super.FrameMove(self, deltaTime);
	self:SyncDataWatcher();

	if(self.asset_rendertech) then
		local obj = self:GetInnerObject()
		if(obj and obj:GetField("render_tech", 0) > 0) then
			self.asset_rendertech = nil;
			self:OnMainAssetLoaded()
		end
	end
end

-- virtual function: this function is called by the basecontext to highlight picking entity. 
-- return true if we handled picking effect ourselves.. 
function Entity:OnHighlightPickingEntity(result)
	local item = self:GetItemClass()
	result, hoverEntity = item:CheckMousePick()
	if(hoverEntity) then
		return true;
	end
end

function Entity:SetIdleAnim(id)
	self.idleAnim = id;
	local obj = self:GetInnerObject();
	if(obj) then
		self:SetAnimation(id)
	end
end