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
Entity:Property({"yaw", 0, "getYaw", "setYaw"});

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
	self.inventoryView = ContainerView:new():Init(self.inventory);
	self.inventory:SetClient();
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	local block_template = block_types.get(self:GetBlockId());
	if(block_template) then
		self.useRealPhysics = not block_template.obstruction;
	end
	self:CreateInnerObject(self.filename, self.scale);
	return self;
end

-- we will use C++ polygon-level physics engine for real physics. 
function Entity:HasRealPhysics()
	return self.useRealPhysics;
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

	local model = ParaScene.CreateObject("BMaxObject", self:GetBlockEntityName(), x,y,z);
	model:SetField("assetfile", filename);
	if(self.scale) then
		model:SetScaling(self.scale);
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
	return self.scale or 1;
end

function Entity:setScale(scale)
	if(self.scale ~= scale) then
		self.scale = scale;
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetScale(scale);
		end
		self:valueChanged();
	end
end

function Entity:EndEdit()
	Entity._super.EndEdit(self);
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
	end
end

function Entity:SetModelFile(filename)
	self.filename = filename;
end

function Entity:GetModelFile()
	return self.filename;
end

function Entity:SaveToXMLNode(node)
	node = Entity._super.SaveToXMLNode(self, node);
	node.attr.filename = self:GetModelFile();
	if(self:getScale()~= 1) then
		node.attr.scale = self:getScale();
	end
	return node;
end

-- Overriden in a sign to provide the text.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	return Packets.PacketUpdateEntityBlock:new():Init(x,y,z, self:GetModelFile(), self:getYaw(), self:getScale());
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
		end
	else
		if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
			if(ctrl_pressed or self:HasRealPhysics()) then
				self:OpenEditor("entity", entity);
				return true;
			end
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

