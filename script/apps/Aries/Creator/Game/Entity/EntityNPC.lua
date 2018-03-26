--[[
Title: Mob entity
Author(s): LiXizhi
Date: 2013/7/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNPC.lua");
local EntityNPC = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC")
local entity = MyCompany.Aries.Game.EntityManager.EntityNPC:new({x,y,z,radius});
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMob.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockInEntityHand.lua");
local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");


local math_abs = math.abs;
local math_random = math.random;
local math_floor = math.floor;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMob"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC"));

-- persistent object by default. 
Entity.is_persistent = true;
-- whether this entity can be synchronized on the network by EntityTrackerEntry. 
Entity.isServerEntity = true;
-- class name
Entity.class_name = "NPC";
-- register class
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

Entity.obj_rotate_speed = 1;
-- enabled frame move. 
Entity.framemove_interval = 0.2;

Entity.group_id = GameLogic.SentientGroupIDs.NPC;

function Entity:ctor()
	self.inventory = InventoryBase:new():Init();
	self.inventory:SetClient();

	self:SetRuleBagSize(16);
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
	return true;
end

-- the title text to display (can be mcml)
function Entity:GetRuleTitle()
	return L"规则";
end

-- bool: whether show the bag panel
function Entity:HasBag()
	return true;
end

-- the title text to display (can be mcml)
function Entity:GetBagTitle()
	return L"背包";
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	return node;
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	Entity._super.OnClick(self, x, y, z, mouse_button);
	return true;
end

function Entity:RefreshRightHand(player)
	BlockInEntityHand.RefreshRightHand(self, self.inventory:GetItemInRightHand(), player);
end

-- @param blockid_or_item_stack: 0 or nil if takes nothing. 
function Entity:SetBlockInRightHand(blockid_or_item_stack)
	local block_id, count;
	if(type(blockid_or_item_stack) == "table") then
		block_id, count = blockid_or_item_stack.id, blockid_or_item_stack.count;
	else
		block_id = blockid_or_item_stack;
	end
	block_id = block_id or 0;
	local cur_block_id = self:GetBlockInRightHand();
	if(cur_block_id ~= block_id) then
		if(block_id == 0) then
			block_id = nil;
		end
		self.inventory:SetBlockInRightHand(block_id);
		self:RefreshRightHand();
	end
end

-- return 0 instead of nil if not exist
function Entity:GetBlockInRightHand()
	local block_id = self.inventory:GetBlockInRightHand();
	return block_id or 0;
end

function Entity:EndEdit()
	Entity._super.EndEdit(self);

	-- just in case the inventory changed. 
	self:RefreshRightHand();
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(GameLogic.isRemote) then
		Entity._super.FrameMove(self, deltaTime);
	else
		if(not self:HasFocus()) then
			Entity._super.FrameMove(self, deltaTime);
		else
			self:UpdatePosition();
			EntityManager.Entity.FrameMove(self, deltaTime);
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

