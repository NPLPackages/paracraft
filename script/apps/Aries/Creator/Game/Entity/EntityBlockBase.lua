--[[
Title: EntityBlockBase 
Author(s): LiXizhi
Date: 2013/12/17
Desc: The base class for entity that is usually associated with a given block.
 It overwrite the Create() method to delay entity init() until the block is loaded. 
 Please note that a block entity saves to regional(512*512) xml file,  instead of global entity file.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
local EntityBlockBase = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"));

-- class name
Entity.class_name = "EntityBlockBase";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- block entity will only init when its belonging block is loaded from file. 
Entity.is_block_entity = true;


function Entity:ctor()
end

-- @param Entity: the half radius of the object. 
function Entity:init()
	Entity._super.init(self);
	if(BlockEngine:GetBlockId(self.bx, self.by, self.bz) == self:GetBlockId()) then
		self:UpdateBlockContainer();
		return self;
	else
		LOG.std(nil, "warn", "EntityBlock", "block (%d %d %d) of id %d not found", self.bx, self.by, self.bz, self:GetBlockId());
	end
end

function Entity:IsBlockEntity()
	return true;
end

-- call init when block is first loaded. 
function Entity:OnBlockLoaded(x,y,z)
end

-- virtual
function Entity:OnBlockAdded(x,y,z)
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		-- GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		return true;
	else
		if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
			if(ctrl_pressed) then
				-- ctrl+right click to activate the entity in editor mode, such as for CommandEntity. 
				self:OnActivated(entity);
			else
				self:OpenEditor("entity", entity);
			end
		end
	end
	return true;
end

-- virtual
function Entity:OnNeighborChanged(x,y,z, from_block_id)
end

