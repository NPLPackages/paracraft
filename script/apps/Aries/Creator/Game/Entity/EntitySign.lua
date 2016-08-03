--[[
Title: Sign
Author(s): LiXizhi
Date: 2013/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntitySign.lua");
local EntitySign = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySign")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Text3DDisplay.lua");
local Text3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Text3DDisplay");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntitySign"));

-- class name
Entity.class_name = "EntitySign";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
Entity.text_color = "0 0 0";
Entity.text_offset = {x=0,y=0.42,z=0.37};

function Entity:ctor()
end

function Entity:OnBlockAdded(x,y,z, data)
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

function Entity:UpdateBlockDataByFacing()
	local x,y,z = self:GetBlockPos();
	local dir_id = Direction.GetDirectionFromFacing(self.facing or 0);
	self.block_data = dir_id;
	BlockEngine:SetBlockData(x,y,z, dir_id);	
end

function Entity:Refresh()
	local hasText = self.cmd and self.cmd~=""
	if(hasText) then
		-- only create C++ object when cmd is not empty
		if(not self.obj) then
			-- Node: we do not draw the model, it is only used for drawing UI overlay. 
			obj = self:CreateInnerObject("model/blockworld/TextFrame/TextFrame.x", nil, BlockEngine.half_blocksize, BlockEngine.blocksize);
			if(obj) then
				-- making it using custom renderer since we are using chunk buffer to render. 
				obj:SetAttribute(0x20000, true);
			end	
		end
	end
	local obj = self:GetInnerObject();
	if(obj) then
		if(hasText) then
			-- update text rotation based on block data
			local data = self.block_data or 0;
			if(data < 4) then
				obj:SetFacing(Direction.directionTo3DFacing[data]);
			elseif(data < 12) then
				obj:SetFacing(0);
				obj:SetRotation(Direction.GetQuaternionByData(data));
			end
		end
		Text3DDisplay.ShowText3DDisplay(true, obj, if_else(self.cmd, self.cmd, ""), self.text_color, self.text_offset, -1.57);
	end
end

function Entity:Destroy()
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

-- Overriden in a sign to provide the text.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	return Packets.PacketUpdateEntitySign:new():Init(x,y,z, self.cmd, self.block_data);
end

-- update from packet. 
function Entity:OnUpdateFromPacket(packet_UpdateEntitySign)
	if(packet_UpdateEntitySign:isa(Packets.PacketUpdateEntitySign)) then
		self:SetCommand(packet_UpdateEntitySign.text);
		self.block_data = packet_UpdateEntitySign.data;
		self:Refresh();
	end
end

function Entity:EndEdit()
	Entity._super.EndEdit(self);
	self:MarkForUpdate();
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	return "";
end

-- called every frame
function Entity:FrameMove(deltaTime)
end

function Entity:OnClick(x, y, z, mouse_button, entity)
	if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
		self:OpenEditor("entity", entity);
	end
	return true;
end
