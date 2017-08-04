--[[
Title: ItemFrame
Author(s): LiXizhi
Date: 2013/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityItemFrame.lua");
local EntityItemFrame = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityItemFrame")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Image3DDisplay.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local Image3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Image3DDisplay");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityItemFrame"));

-- class name
Entity.class_name = "EntityItemFrame";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
Entity.text_offset = {x=0,y=0.42,z=0.315};

function Entity:ctor()
end

-- return empty collision AABB, since it does not have physics. 
function Entity:GetCollisionAABB()
	if(not self.aabb) then
		self.aabb = ShapeAABB:new();
	end
	return self.aabb;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	if(node.attr.itemframe_id) then
		self.itemframe_id = tonumber(node.attr.itemframe_id);
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	node.attr.itemframe_id = self.itemframe_id;
	return node;
end

-- Overriden in a sign to provide the text.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	return Packets.PacketUpdateEntitySign:new():Init(x,y,z, self.itemframe_id, self.block_data);
end

-- update from packet. 
function Entity:OnUpdateFromPacket(packet_UpdateEntitySign)
	if(packet_UpdateEntitySign:isa(Packets.PacketUpdateEntitySign)) then
		self.itemframe_id = packet_UpdateEntitySign.text and tonumber(packet_UpdateEntitySign.text);
		self:Refresh();
	end
end

function Entity:UpdateBlockDataByFacing()
	local x,y,z = self:GetBlockPos();
	local dir_id = Direction.GetDirectionFromFacing(self.facing or 0);
	self.block_data = dir_id;
	BlockEngine:SetBlockData(x,y,z, dir_id);	
end

function Entity:OnBlockAdded(x,y,z,data)
	self.block_data = data or self.block_data or 0;
	self:Refresh();
end

function Entity:OnBlockLoaded(x,y,z, data)
	self.block_data = data or self.block_data or 0;
	-- backward compatibility, since we used to store facing instead of data in very early version. 
	-- this should never happen in versions after late 2014
	if(self.block_data == 0 and (self.facing or 0) ~= 0) then
		LOG.std(nil, "warn", "info", "fix BlockSign entity facing and block data incompatibility in early version: %d %d %d", self.bx, self.by, self.bz);
		self:UpdateBlockDataByFacing();
	end
	self:Refresh();
end

function Entity:Destroy()
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

function Entity:Refresh()
	local icon_path; 
	local item = ItemClient.GetItem(tonumber(self.itemframe_id));
	if(item) then
		icon_path = item:GetIcon();
	end
	if(icon_path) then
		-- only create C++ object when cmd is not empty
		if(not self.obj) then
			local obj = self:CreateInnerObject("model/blockworld/ItemFrame/ItemFrame.x", nil, BlockEngine.half_blocksize, BlockEngine.blocksize);
			if(obj) then
				-- making it using custom renderer since we are using chunk buffer to render. 
				obj:SetAttribute(0x20000, true);
			end
		end
	end
	local obj = self:GetInnerObject();
	if(obj) then
		if(icon_path) then
			-- update rotation based on block data
			local data = self.block_data or 0;
			if(data < 4) then
				obj:SetFacing(Direction.directionTo3DFacing[data]);
			elseif(data < 12) then
				obj:SetFacing(0);
				obj:SetRotation(Direction.GetQuaternionByData(data));
			end
		end
		Image3DDisplay.ShowHeadonDisplay(true, obj, icon_path or "", 80, 80, nil, self.text_offset, -1.57);
	end
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
		self.itemframe_id = GameLogic.GetPlayerController():GetBlockInRightHand();
		self:Refresh();
		self:MarkForUpdate();
	end
	return true;
end