--[[
Title: Live Model
Author(s): LiXizhi
Date: 2021/12/3
Desc: Live model entity is an iteractive model that can be moved around the scene and stacked upon one another. 
This class is almost identical to EntityBlockModel. 
- If model filename contains "_char", we will use auto turning
- If model filename contains "_drag", we will enable dragging even if it has real physics

A general event "__entity_onclick", "__entity_onhover", "__entity_onmount", "__entity_onbegindrag", "__entity_onenddrag" will be fired if no custom event is specified. 

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
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockInEntityHand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BonesVariable.lua");
local BonesVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BonesVariable");
local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");
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
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local Event = commonlib.gettable("System.Core.Event");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");
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
Entity:Property({"isDisplayModel", true, "IsDisplayModel", "SetDisplayModel", auto=true});
Entity:Property({"isMountpointDetached", false});
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
Entity:Property({"onbeginDragEvent", nil, "GetOnBeginDragEvent", "SetOnBeginDragEvent", auto=true});
Entity:Property({"onendDragEvent", nil, "GetOnEndDragEvent", "SetOnEndDragEvent", auto=true});
Entity:Property({"tag", nil, "GetTag", "SetTag", auto=true});
Entity:Property({"staticTag", nil, "GetStaticTag", "SetStaticTag", auto=true});
Entity:Property({"category", nil, "GetCategory", "SetCategory", auto=true});
Entity:Property({"yawOffset", 0, "GetYawOffset", "SetYawOffset", auto=true});

Entity:Signal("beforeDestroyed")
Entity:Signal("clicked", function(mouse_button) end)
Entity:Signal("assetfileChanged");

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

-- internal name 
function Entity:SetName(v)
	if(self.name~=v) then
		Entity._super.SetName(self, v)
		if(self.name == v) then
			local obj = self:GetInnerObject()
			if(obj) then
				obj:SetName(self.name);
			end
		end
	end
end

-- virtual function: return cloned entity. 
function Entity:CloneMe()
	local xmlNode = self:SaveToXMLNode()
	xmlNode.attr.name = nil;
	xmlNode.attr.linkTo = nil;
	local x, y, z = self:GetPosition()
	local entity = self:Create({x=x, y=y, z=z, facing=self:GetFacing()}, xmlNode);
	entity:Attach();
	return entity
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

function Entity:BeginModify()
end

function Entity:EndModify()
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
		self:assetfileChanged();
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

-- update from XML node
function Entity:UpdateFromXMLNode(node)
	if(self.obj) then
		local lastPitch = self:GetPitch()
		local lastRoll = self:GetRoll()
		Entity._super.UpdateFromXMLNode(self, node)
		local newPitch = self:GetPitch();
		local newRoll = self:GetRoll();
		self.pitch = lastPitch
		self.roll = lastRoll
		self:SetPitch(newPitch);
		self:SetRoll(newRoll);
	else
		Entity._super.UpdateFromXMLNode(self, node)
	end
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
		self.isDisplayModel = (attr.isDisplayModel ~= "false") and (attr.isDisplayModel ~= false);
		
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
		if(attr.onbeginDragEvent) then
			self.onbeginDragEvent = attr.onbeginDragEvent
		end
		if(attr.onendDragEvent) then
			self.onendDragEvent = attr.onendDragEvent
		end
		if(attr.tag) then
			self:SetTag(attr.tag);
		end
		if(attr.staticTag) then
			self.staticTag = attr.staticTag;
		end
		if(attr.category) then
			self.category = attr.category
		end
		if(attr.yawOffset) then
			self.yawOffset = tonumber(attr.yawOffset)
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
		if(attr.pitch) then
			self.pitch = tonumber(attr.pitch) or self.pitch;
		else
			self.pitch = nil
		end
		if(attr.roll) then
			self.roll = tonumber(attr.roll) or self.roll;
		else
			self.roll = nil
		end
		if(attr.bootHeight) then
			self.bootHeight = tonumber(attr.bootHeight) or self.bootHeight;
		else
			self.bootHeight = nil
		end
	end
end

-- find a tag in static tag. 
function Entity:HasStaticTag(tagName)
	if(tagName and self.staticTag and self.staticTag:find(tagName, 1, true)) then
		return true
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	local attr = node.attr;
	attr.filename = self:GetModelFile();
	if(self:getScale()~= 1) then
		attr.scale = self:getScale();
	end
	if(self.skin and self.skin~="") then
		attr.skin = self.skin;
	end
	if(self.onclickEvent and self.onclickEvent~="") then
		attr.onclickEvent = self.onclickEvent
	end
	if(self.onhoverEvent and self.onhoverEvent~="") then
		attr.onhoverEvent = self.onhoverEvent
	end
	if(self.onmountEvent and self.onmountEvent~="") then
		attr.onmountEvent = self.onmountEvent
	end
	if(self.onbeginDragEvent and self.onbeginDragEvent~="") then
		attr.onbeginDragEvent = self.onbeginDragEvent
	end
	if(self.onendDragEvent and self.onendDragEvent~="") then
		attr.onendDragEvent = self.onendDragEvent
	end
	if(self.tag and self.tag~="") then
		attr.tag = self.tag
	end
	if(self.staticTag and self.staticTag~="") then
		attr.staticTag = self.staticTag
	end
	if(self.category and self.category~="") then
		attr.category = self.category
	end
	if(self.yawOffset and yawOffset~=0) then
		attr.yawOffset = self.yawOffset
	end

	attr.linkTo = self:ConvertLinkInfoToString(self.linkInfo)
	
	if(self.idleAnim ~= 0) then
		attr.idleAnim = self.idleAnim;
	end
	if(self.pitch and self.pitch ~= 0) then
		attr.pitch = self.pitch;
	end
	if(self.roll and self.roll ~= 0) then
		attr.roll = self.roll;
	end
	if(self.bootHeight and self.bootHeight ~= 0) then
		attr.bootHeight = self.bootHeight;
	end

	attr.x, attr.y, attr.z = self:GetPosition()
	if(self.useRealPhysics) then
		attr.useRealPhysics = true;
	end
	attr.canDrag = self.canDrag;
	attr.stackHeight = self.stackHeight;
	attr.isStackable = self.isStackable;
	attr.bIsAutoTurning = self.bIsAutoTurning;

	if(self.isDisplayModel == false) then
		attr.isDisplayModel = false;
	end

	local lastAnim = self:GetLastAnimId();
	if((lastAnim or 0) ~= (self.idleAnim or 0)) then
		attr.lastAnim = lastAnim
	end

	if(self:GetMountPoints()) then
		self:GetMountPoints():SaveToXMLNode(node, bSort)
	end

	return node;
end

-- convert all link info into a string, such as "name1::L_Hand@{rot={1,0,0},pos={0,1,0}}"
function Entity:ConvertLinkInfoToString(linkInfo)
	if(linkInfo and linkInfo.entity) then
		local str = linkInfo.entity:GetName();
		if(linkInfo.boneName) then
			str = format("%s::%s", str, linkInfo.boneName)
			if(linkInfo.pos) then
				str = format("%s@%s", str, commonlib.serialize_compact({rot=linkInfo.rot, pos = linkInfo.pos}))
			end
		end
		return str;
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
		if(self.pitch and self.pitch ~= 0) then
			obj:SetField("pitch", self.pitch);
		end
		if(self.roll and self.roll ~= 0) then
			obj:SetField("roll", self.roll);
		end
		if(self:GetBootHeight() ~= 0) then
			obj:SetField("BootHeight", self:GetBootHeight());
		end
		self:Refresh(nil, obj)

		self:UpdateBlockContainer();
	end
	return obj;
end

function Entity:SetBootHeight(bootHeight)
	if((self.bootHeight or 0) ~= bootHeight) then
		self.bootHeight = bootHeight
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetField("BootHeight", bootHeight or 0);
		end
	end
end

function Entity:GetBootHeight()
	return self.bootHeight or 0
end

-- rotation around Z axis
function Entity:SetRoll(roll)
	if((self.roll or 0) ~= roll) then
		self.roll = roll
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetField("roll", roll or 0);
		end
	end
end

-- rotation around Z axis
function Entity:GetRoll()
	return self.roll or 0;
end

-- rotation around X axis
function Entity:SetPitch(pitch)
	if((self.pitch or 0) ~= pitch) then
		self.pitch = pitch;
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetField("pitch", pitch or 0);
		end
	end
end

-- rotation around X axis
function Entity:GetPitch()
	return self.pitch or 0;
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

-- similar to LinkTo function, except that it will take mount points into consideration. 
-- mount current entity to another entity's mount point at mountPointIndex. 
-- if no mountpoint is found, we will simply linkto the target entity
-- @param mountPointIndex: default to 1, 
-- @param bUseCurrentLocation: if true, we will use the current entity's facing and position, instead of the target mount point's settings. 
function Entity:MountTo(mountTarget, mountPointIndex, bUseCurrentLocation)
	mountPointIndex = mountPointIndex or 1
	if(mountTarget) then
		if(not bUseCurrentLocation and mountTarget:GetMountPoints()) then
			local x, y, z = mountTarget:GetMountPoints():GetMountPositionInWorldSpace(mountPointIndex)
			local facing = mountTarget:GetMountPoints():GetMountFacingInWorldSpace(mountPointIndex)
			if(x and facing) then
				self:SetPosition(x, y, z)
				self:SetFacing(facing)
			end
		end
		self:LinkTo(mountTarget)
		
		if(mountPointIndex and mountPointIndex>0 and mountTarget:GetMountPoints()) then
			local mountpoint = mountTarget:GetMountPoints():GetMountPoint(mountPointIndex)
			if(mountpoint) then
				mountTarget:OnMount(mountpoint.name, mountPointIndex, self)
				if(mountpoint.name == "lie") then
					self:SetAnimation(100); -- 100 lie facing up; 88 lie facing side ways
				elseif(mountpoint.name == "sit") then
					self:SetAnimation(72); -- sit on ground
				elseif(mountpoint.name == "eat") then
				elseif(mountpoint.name == "create") then
				elseif(mountpoint.name == "run") then
					self:SetAnimation(5);
				end
			end
		end
	end
end

function Entity:GetMountedEntityAt(mountPointIndex)
	mountPointIndex = mountPointIndex or 1;
	if(self:GetMountPoints()) then
		local x, y, z = self:GetMountPoints():GetMountPositionInWorldSpace(mountPointIndex)
		if(x and self.childLinks) then
			for child, _ in pairs(self.childLinks) do
				local x1, y1, z1 = child:GetPosition()
				if((math.abs(x-x1)+math.abs(z-z1)) < 0.05 and math.abs(y-y1) < 0.3) then
					return child;
				end
			end
		end
	end
end


function Entity:OnMount(mountPointName, mountpointIndex, mountedEntity)
	local event = Event:new():init("onmount");	
	self:event(event);
	-- send a general event or user defined one
	local onmountEvent = self.onmountEvent or "__entity_onmount"
	if(mountedEntity) then
		local x, y, z = self:GetBlockPos();
		GameLogic.RunCommand(string.format("/sendevent %s {x=%d, y=%d, z=%d, name=%q, mountname=%q, mountindex=%d, mountedEntityName=%q}", onmountEvent, x, y, z, self.name, mountPointName or "", mountpointIndex or 0, mountedEntity.name or ""))
		return true;
	end
end

-- called every 1500 milliseconds
function Entity:OnHover(hoverEntity)
	local event = Event:new():init("onhover");	
	self:event(event);

	-- send a general event or user defined one
	local onhoverEvent = self.onhoverEvent or "__entity_onhover"
	if(hoverEntity) then
		local x, y, z = self:GetBlockPos();
		GameLogic.RunCommand(string.format("/sendevent %s {x=%d, y=%d, z=%d, name=%q, hoverEntityName=%q}", onhoverEvent, x, y, z, self.name, hoverEntity.name or ""))
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

			-- send a general event or user defined one
			local onclickEvent = self.onclickEvent or "__entity_onclick"
			if(onclickEvent) then
				local x, y, z = self:GetBlockPos();
				local event = Event:new():init(onclickEvent);	
				local facing = Direction.directionTo3DFacing[side or 0]
				event.cmd_text = string.format("{x=%d, y=%d, z=%d, name=%q, facing=%f}", x, y, z, self.name, facing or 0);
				local result = GameLogic:event(event, true);
				if(result) then
					return true;
				end
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
		if(not EditModelTask.GetInstance()) then
			GameLogic.GetPlayerController():PickItemByEntity(self);
		end
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
-- @param boneName: nil or a given bone name. If specified, we will use a timer to update. 
-- @param pos: nil or 3d position offset
-- @param rot: nil or 3d rotation 
function Entity:LinkTo(targetEntity, boneName, pos, rot)
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
			targetEntity.childLinks = targetEntity.childLinks or {};
			targetEntity.childLinks[self] = true;
		end
		if(targetEntity and boneName) then
			local animId = targetEntity:GetCurrentAnimId()
			if(animId == 153 or animId == 154) then
				-- tricky, in case we are playing random standing loop animation, we will set to 0 and wait 500ms to apply attach. 
				targetEntity:SetAnimation(0);
				local count = 0;
				local linkToTimer = commonlib.Timer:new({callbackFunc = function(timer)
					count = count + 1;
					self:UpdateEntityLink();
					if(count > 5) then
						timer:Change()
					end
				end})
				linkToTimer:Change(0, 100)
			else
				self:UpdateEntityLink();
			end
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

function Entity:GetBonesVariable()
	if(not self.bones_variable) then
		self.bones_variable = BonesVariable:new():initFromEntity(self);
		self:Connect("assetfileChanged", self.bones_variable, self.bones_variable.OnAssetFileChanged)
	end
	return self.bones_variable;
end

-- get bone's world position and rotation. 
-- @param boneName: like "R_Hand". can be nil.
-- @param localPos: if not nil, this is the local offset
-- @param localRot: if not nil, this is the local rotation {roll, pitch yaw}
-- @param bUseParentRotation: use the parent rotation.
-- @return x,y,z, roll, pitch yaw, scale: in world space.  
-- return nil, if such information is not available, such as during async loading.
function Entity:ComputeBoneWorldPosAndRot(boneName, localPos, localRot, bUseParentRotation)
	local link_x, link_y, link_z = self:GetPosition()
	local bFoundTarget;
	self.parentPivot = self.parentPivot or mathlib.vector3d:new();
		
	local parentBoneRotMat;
	if(boneName) then
		local bones = self:GetBonesVariable();
		local boneVar = bones:GetChild(boneName);
		if(boneVar) then
			bones:UpdateAnimInstance();
			local pivot = boneVar:GetPivot(true);
			self.parentPivot:set(pivot);
			if(bUseParentRotation) then
				parentBoneRotMat = boneVar:GetPivotRotation(true);
			end
			bFoundTarget = true;
		end
	else
		self.parentPivot:set(0,0,0);
		bFoundTarget = true;
	end 
	if(bFoundTarget) then
		local parentObj = self:GetInnerObject();
		local parentScale = parentObj:GetScale() or 1;
		local dx,dy,dz = 0,0,0;
		if(not bUseParentRotation and localPos) then
			self.parentPivot:add((localPos[1] or 0), (localPos[2] or 0), (localPos[3] or 0));
		end

		self.parentTrans = self.parentTrans or mathlib.Matrix4:new();
		self.parentTrans = parentObj:GetField("LocalTransform", self.parentTrans);
		self.parentPivot:multiplyInPlace(self.parentTrans);
		self.parentQuat = self.parentQuat or Quaternion:new();
		if(parentScale~=1) then
			self.parentTrans:RemoveScaling();
		end
		self.parentQuat:FromRotationMatrix(self.parentTrans);
		if(bUseParentRotation and parentBoneRotMat) then
			self.parentPivotRot = self.parentPivotRot or Quaternion:new();
			self.parentPivotRot:FromRotationMatrix(parentBoneRotMat);
			self.parentQuat:multiplyInplace(self.parentPivotRot);

			if(localRot) then
				self.localRotQuat = self.localRotQuat or Quaternion:new();
				self.localRotQuat:FromEulerAngles((localRot[3] or 0), (localRot[1] or 0), (localRot[2] or 0));
				self.parentQuat:multiplyInplace(self.localRotQuat);
			end
		
			if(localPos) then
				self.localPos = self.localPos or mathlib.vector3d:new();
				self.localPos:set((localPos[1] or 0), (localPos[2] or 0), (localPos[3] or 0));
				self.localPos:rotateByQuatInplace(self.parentQuat);
				dx, dy, dz = self.localPos[1], self.localPos[2], self.localPos[3];
			end
		end
			
		local p_roll, p_pitch, p_yaw = self.parentQuat:ToEulerAnglesSequence("zxy");
			
		if(not bUseParentRotation and localRot) then
			-- just for backward compatibility, bUseParentRotation should be enabled in most cases
			p_roll = (localRot[1] or 0) + p_roll;
			p_pitch = (localRot[2] or 0) + p_pitch;
			p_yaw = (localRot[3] or 0) + p_yaw;
		end
		local x, y, z = link_x + self.parentPivot[1] + dx, link_y + self.parentPivot[2] + dy, link_z + self.parentPivot[3] + dz
		-- This fixed a bug where x or y or z could be NAN(0/0), because GetPivotRotation and GetPivot could return NAN
		if(x == x and y==y and z==z) then
			return x, y, z, p_roll, p_pitch, p_yaw, parentScale;
		end
	end
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

function Entity:GetLinkChildAtBone(boneName)
	if(boneName and self.childLinks) then
		for child, _ in pairs(self.childLinks) do
			if(child.linkInfo and child.linkInfo.boneName == boneName) then
				return child;
			end
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
-- @param name: entityName[::boneName], such as "player1::L_Hand"
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
-- @param name: entityName[::boneName], such as "player1::L_Hand"
-- @return true if target entity is found and linked. 
function Entity:LinkToEntityByName(name)
	local entity = EntityManager.GetEntity(name)
	if(entity) then
		self:LinkTo(entity)
		return true;
	else
		local entityName, boneName, location = name:match("([^:]+)::([^:@]+)@?(.*)");
		if(entityName and boneName) then
			local entity = EntityManager.GetEntity(entityName)
			if(entity) then
				local rot, pos
				if(location and location ~= "") then
					location = NPL.LoadTableFromString(location)
					if(location) then
						rot = location.rot
						pos = location.pos
					end
				end
				self:LinkTo(entity, boneName, pos, rot)
				return true;
			end
		end
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
	self:OnBeginDrag()
	self:BeginModify()
end

-- when dragging ends, we will restore picking and physics. 
function Entity:EndDrag()
	self:SetSkipPicking(false);
	if(self.beforeDragHasPhysics) then
		self:EnablePhysics(true);
		self.beforeDragHasPhysics = nil;
	end
	self:ForEachChildLinkEntity(Entity.EndDrag)
	self:OnEndDrag()
	self:EndModify()
end

function Entity:OnBeginDrag()
	-- send a general event or user defined one
	local onbeginDragEvent = self.onbeginDragEvent or "__entity_onbegindrag"
	if(onbeginDragEvent) then
		local x, y, z = self:GetBlockPos();
		GameLogic.RunCommand(string.format("/sendevent %s {x=%d, y=%d, z=%d, name=%q}", onbeginDragEvent, x, y, z, self.name))
		return true;
	end
end

function Entity:OnEndDrag()
	-- send a general event or user defined one
	local onendDragEvent = self.onendDragEvent or "__entity_onenddrag"
	if(onendDragEvent) then
		local x, y, z = self:GetBlockPos();
		GameLogic.RunCommand(string.format("/sendevent %s {x=%d, y=%d, z=%d, name=%q}", onendDragEvent, x, y, z, self.name))
		return true;
	end
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
	--if(self.linkInfo and self.linkInfo.boneName) then
		--self:UpdateEntityLink()
	--end
	if(GameLogic.GameMode:IsEditor()) then
		if(not self:IsVisible()) then
			self:SetVisible(true)
		end
	else
		if(self:IsVisible() ~= self:IsDisplayModel()) then
			self:SetVisible(self:IsDisplayModel())
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

-- make this live model to look like a given block. 
-- @param itemStackOrItemId: the item to hold in hand or nil. usually one that is in the inventory of entity. 
-- it can also be item id, such as 62 for grass block
function Entity:BecomeBlockItem(itemStackOrItemId)
	BlockInEntityHand.TransformEntityToBlockItem(self, itemStackOrItemId)
end

-- make this live model to look like a given custom char icon. 
-- @param itemId: custom character item id, such as 83127
function Entity:BecomeCustomCharacterItem(itemId)
	BlockInEntityHand.TransformEntityToCustomCharItem(self, itemId)
	self:SetYawOffset(-1.57)
end

-- only call this function when the entity is a custom character.
-- we will put on the item, and it will return item_id that has been replaced. 
-- @param itemId: custom character item id, such as 83127
-- @return replacedItemId: this can be nil or the same as the itemId. 
function Entity:PutOnCustomCharItem(itemId)
	local item = CustomCharItems:GetItemById(itemId)
	if(item and self:HasCustomGeosets()) then
		local oldSkins = self:GetSkin();
		local newSkins = CustomCharItems:AddItemToSkin(oldSkins, item);
		if(newSkins and newSkins ~= oldSkins) then
			local oldItems, newItems;
			if(oldSkins) then
				oldItems = commonlib.split(oldSkins, ";")
			end
			if(newSkins) then
				newItems = commonlib.split(newSkins, ";")
			end
			local replacedItemId;
			if(oldSkins) then
				for _, id in pairs(oldItems) do
					local bHasItem;
					for _, id2 in pairs(newItems) do
						if(id == id2) then
							bHasItem = true
							break;
						end
					end
					if(not bHasItem and CustomCharItems:GetItemById(id)) then
						replacedItemId = id
						break
					end
				end
			else
				replacedItemId = tostring(itemId);
			end
			self:SetSkin(newSkins)
			return replacedItemId
		end
	end
	return itemId;
end

-- let the entity fall down immediately to ground or physical mesh 
function Entity:FallDown()
	local item = self:GetItemClass()
	local x, y, z = self:GetPosition()
	local bx, by, bz = self:GetBlockPos()
	local dropLocation = {target = nil, x=x, y=y, z=z, dropX = x, dropY = y, dropZ = z, bx = bx, by = by, bz = bz, side = 5}
	item:CalculateFreeFallDropLocation(self, dropLocation);	
	self:SetPosition(dropLocation.dropX, dropLocation.dropY, dropLocation.dropZ);
end

-- get the entity that this entity is stacked on, they usually have the same x,z location and 
-- differs only by y and the diff matches the stackable height of thee below entity
-- @return nil or an entity
function Entity:GetStackedOnEntity()
	local x, y, z = self:GetPosition();
	local mountedEntities = EntityManager.GetEntitiesByAABBOfType(EntityManager.EntityLiveModel, ShapeAABB:new_from_pool(x, y-0.5, z, 0.1, 0.55, 0.1, true))
	if(mountedEntities) then
		table.sort(mountedEntities, function(left, right)
			local _, y1, _ = left:GetPosition()
			local _, y2, _ = right:GetPosition()
			return y1 < y2;
		end)
		local myIndex;
		for i, entity in ipairs(mountedEntities) do
			if(entity==self) then
				myIndex = i;
				break;
			end
		end
		local stackedEntity
		if(myIndex and myIndex>1) then
			for i = myIndex-1, 1, -1 do
				local entity = mountedEntities[i]
				local x1, y1, z1 = entity:GetPosition();
				if(math.abs(x1 - x) + math.abs(z1 - z) < 0.1) then
					stackedEntity = stackedEntity or entity;
					if(entity:IsStackable() and math.abs(entity:GetStackHeight() + y - y1) < 0.02) then
						stackedEntity = entity;
						break;
					end
				end
			end
		end
		return stackedEntity;
	end
end