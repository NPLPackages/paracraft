--[[
Title: Block Model
Author(s): LiXizhi
Date: 2015/5/25
Desc: 
- non-physics model: left click to activate and ctrl+right click to edit model.
- physics model: left click to activate and right click to edit model.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockModel.lua");
local EntityBlockModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockModel")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockModel"));

Entity:Property({"scale", 1, "getScale", "setScale"});
Entity:Property({"minScale", 0.02});
Entity:Property({"maxScale", 1000});
Entity:Property({"yaw", 0, "getYaw", "setYaw"});
Entity:Property({"offsetPos", {0,0,0}, "GetOffsetPos", "SetOffsetPos"});

-- class name
Entity.class_name = "EntityBlockModel";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- if model is invalid, use this model file. 
Entity.default_file = "character/common/headquest/headquest.x";
-- whether to force load physics, if false, it will only load when player collide with it. 
Entity.bIsForceLoadPhysics = true;

function Entity:ctor()
	self.inventory = self.inventory or InventoryBase:new():Init();
	self.inventory:SetClient();
	self.offsetPos = vector3d:new(0,0,0);
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	local block_template = block_types.get(self:GetBlockId());
	if(block_template) then
		self.useRealPhysics = not block_template.obstruction;
	end
	self:CreateInnerObject(self.filename, self.scaling);
	return self;
end

-- we will use C++ polygon-level physics engine for real physics. 
function Entity:HasRealPhysics()
	return self.useRealPhysics;
end

-- this function may remove entity object and create a new one inplace
function Entity:EnablePhysics(bEnabled)
	if(bEnabled ~= self.useRealPhysics) then
		local x, y, z = self:GetBlockPos()
		local block_id, block_data, entity_data = Game.BlockEngine:GetBlockFull(x,y,z)
		local item_id = bEnabled and 22 or 254;
		if(bEnabled) then
			entity_data.attr.item_id = item_id;
		else
		end
		BlockEngine:SetBlock(x,y,z, item_id, block_data, 3, entity_data)
		return true;
	end
end

-- @param filename: if nil, self.filename is used
function Entity:GetModelDiskFilePath(filename)
	return Files.GetFilePath(commonlib.Encoding.Utf8ToDefault(filename or self:GetModelFile()));
end

-- the title text to display (can be mcml)
function Entity:GetBagTitle()
	return L"背包";
end

-- bool: whether show the bag panel
function Entity:HasBag()
	return true;
end

-- whether to force load physics, if false, it will only load when player collide with it. 
function Entity:IsForceLoadPhysics()
	return self.bIsForceLoadPhysics;
end

-- this is helper function that derived class can use to create an inner mesh or character object. 
function Entity:CreateInnerObject(filename, scale)
	filename = Files.GetFilePath(self:GetModelDiskFilePath(filename)) or self.default_file;
	local x, y, z = self:GetPosition();

	if(filename == self.default_file) then
		if(self.filename and self.filename~="") then
			-- TODO: fetch from remote server?
			LOG.std(nil, "warn", "EntityBlockModel", "filename: %s not found at %d %d %d", self.filename or "", self.bx or 0, self.by or 0, self.bz or 0);	
		end
	end

	local model = ParaScene.CreateObject("BMaxObject", self:GetBlockEntityName(), x+self.offsetPos[1],y+self.offsetPos[2],z+self.offsetPos[3]);
	model:SetField("assetfile", filename);
	if(self.scaling) then
		model:SetScaling(self.scaling);
	end
	if(self.facing) then
		model:SetFacing(self.facing);
	end
	-- OBJ_SKIP_PICKING = 0x1<<15:
	-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
	model:SetAttribute(0x8080, true);
	model:SetField("RenderDistance", 100);
	if(self:HasRealPhysics()) then
		model:SetField("EnablePhysics", true);
		if(self:IsForceLoadPhysics()) then
			model:LoadPhysics(); 
		end
	end

	self:SetInnerObject(model);
	ParaScene.Attach(model);
	return model;
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

function Entity:getScale()
	return self.scaling or 1;
end

function Entity:setScale(scale)
	if(self.scaling ~= scale) then
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
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

function Entity:Refresh()
	local obj = self:GetInnerObject();
	if(obj) then
		obj:SetField("assetfile", self:GetModelDiskFilePath() or self.default_file);
	end
end


function Entity:EndEdit()
	Entity._super.EndEdit(self);
	self:MarkForUpdate();
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	if(attr) then
		if(attr.filename) then
			self:SetModelFile(attr.filename);
		end
		if(attr.scale) then
			self:setScale(tonumber(attr.scale));
		end
		if(attr.offsetX) then
			self.offsetPos[1] = tonumber(attr.offsetX);
		end
		if(attr.offsetY) then
			self.offsetPos[2] = tonumber(attr.offsetY);
		end
		if(attr.offsetZ) then
			self.offsetPos[3] = tonumber(attr.offsetZ);
		end
	end
end

function Entity:SetModelFile(filename)
	self.filename = filename;
end

function Entity:GetModelFile()
	return self.filename;
end

function Entity:SetSkin(skin)
end

function Entity:SetBlockInRightHand(blockid)
end

function Entity:SetSpeedScale(vale)
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	node.attr.filename = self:GetModelFile();
	if(self:getScale()~= 1) then
		node.attr.scale = self:getScale();
	end
	if(self.offsetPos[1]~=0) then
		node.attr.offsetX = self.offsetPos[1];
	end
	if(self.offsetPos[2]~=0) then
		node.attr.offsetY = self.offsetPos[2];
	end
	if(self.offsetPos[3]~=0) then
		node.attr.offsetZ = self.offsetPos[3];
	end
	return node;
end

-- Overriden in a sign to provide the text.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	local offsetPos;
	if(self.offsetPos[1]~=0 or self.offsetPos[2]~=0 or self.offsetPos[3]~=0) then
		offsetPos = self.offsetPos
	end
	return Packets.PacketUpdateEntityBlock:new():Init(x,y,z, self:GetModelFile(), self:getYaw(), self:getScale(), offsetPos);
end

-- update from packet. 
function Entity:OnUpdateFromPacket(packet_UpdateEntityBlock)
	if(packet_UpdateEntityBlock:isa(Packets.PacketUpdateEntityBlock)) then
		local filename = packet_UpdateEntityBlock.data1;
		local yaw = packet_UpdateEntityBlock.data2;
		local scaling = packet_UpdateEntityBlock.data3;
		if(filename) then
			self:SetModelFile(filename);
		end
		if(yaw) then
			self:setYaw(yaw);
		end
		if(scaling) then
			self:setScale(scaling);
		end
		local offset = packet_UpdateEntityBlock.data4;
		if(not offset and (self.offsetPos[1]~=0 or self.offsetPos[2]~=0 or self.offsetPos[3]~=0)) then
			offset = {0,0,0}
		end
		if(offset) then
			self:SetOffsetPos(offset)
		end
		self:Refresh();
	end
end

function Entity:OnBlockAdded(x,y,z)
	if(not self.facing) then
		--self.facing = Direction.GetFacingFromCamera();
		self.facing = Direction.directionTo3DFacing[Direction.GetDirection2DFromCamera()];
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetFacing(self.facing);
		end
	end
end

function Entity:HasAnyRule()
	return (self.cmd or "")~="" or not self.inventory:IsEmpty();
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		if(mouse_button=="left") then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		elseif(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			self:OpenEditor("entity", entity);
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

	-- this is run for both client and server. 
	if(entity and entity == EntityManager.GetPlayer()) then
		local obj = self:GetInnerObject();
		if(obj) then
			-- check if the entity has mount position. If so, we will set current player to this location.  
			if(obj:HasAttachmentPoint(0)) then
				local x, y, z = obj:GetAttachmentPosition(0);
				local entityPlayer = entity;
				if(entityPlayer) then
					entityPlayer:SetPosition(x,y,z);
				end
				return true;
			end
		end
	end
	
	if(self:HasRealPhysics() or self:HasAnyRule()) then
		return true;
	end
end

function Entity:OpenEditor(editor_name, entity)
	local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
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

-- virtual function: get array of item stacks that will be displayed to the user when user try to create a new item. 
-- @return nil or array of item stack.
function Entity:GetNewItemsList()
	local itemStackArray = Entity._super.GetNewItemsList(self) or {};
	local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.CommandLine,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.Code,1);
	return itemStackArray;
end


-- virtual function: handle some external input. 
-- default is do nothing. return true is something is processed. 
function Entity:OnActivated(triggerEntity)
	if(triggerEntity) then
		EntityManager.SetLastTriggerEntity(triggerEntity);
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
	local EntityCommandBlock = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock")
	-- tricky: just emulate the command block. 
	EntityCommandBlock.ExecuteCommand(self, triggerEntity, true, true);
end

function Entity:GetOffsetPos()
	return self.offsetPos;
end

function Entity:SetOffsetPos(v)
	if(not self.offsetPos:equals(v)) then
		local x, y, z = self:GetPosition();
		v[1] = math.min(math.max(-BlockEngine.half_blocksize, v[1]), BlockEngine.half_blocksize);
		v[2] = math.min(math.max(0, v[2]), BlockEngine.blocksize);
		v[3] = math.min(math.max(-BlockEngine.half_blocksize, v[3]), BlockEngine.half_blocksize);
		self.offsetPos:set(v);
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetPosition(x + v[1], y + v[2], z + v[3]);
			obj:UpdateTileContainer();
		end
		self:valueChanged();
	end
end

-- @param text: string to match
-- @param bExactMatch: if for exact match
-- return true, filename: if the file text is found. filename contains the full filename
function Entity:FindFile(text, bExactMatch)
	local filename = self:GetModelFile();
	if( (bExactMatch and filename == text) or (not bExactMatch and filename and filename:find(text))) then
		return true, filename
	end
end