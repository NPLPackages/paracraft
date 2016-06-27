--[[
Title: Chest
Author(s): LiXizhi
Date: 2013/12/17
Desc: only open chest when block above it is empty or liquid
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityChest.lua");
local EntityChest = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityChest")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityChest"));

-- class name
Entity.class_name = "EntityChest";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

function Entity:ctor()
	self.inventory = InventoryBase:new():Init();
	self.inventoryView = ContainerView:new():Init(self.inventory);
	self.inventory:SetClient();
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end

	self:CreateInnerObject("character/CC/02human/chest/Chest.x", true, BlockEngine.half_blocksize, BlockEngine.blocksize);
	self:Refresh();

	return self;
end

function Entity:Destroy()
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

function Entity:Refresh()
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
end

function Entity:SaveToXMLNode(node)
	node = Entity._super.SaveToXMLNode(self, node);
	return node;
end

function Entity:OpenChest()
	if(not self.isOpeningOrClosing and not self.isOpened) then
		local x,y,z = self:GetBlockPos();

		-- only open chest when block above it is empty or liquid
		local top_block = BlockEngine:GetBlock(x,y+1,z);
		if(not top_block or top_block.material:isLiquid()) then
			self.isOpeningOrClosing = true;
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				self:OnChestOpen()
			end})
			mytimer:Change(100, nil);

			local obj = self:GetInnerObject();
			if(obj) then
				AudioEngine.CreateGet("chestopen"):play2d(0.3);
				obj:ToCharacter():PlayAnimation({37, 38});
			end
		end
	end
end

function Entity:CloseChest()
	if(not self.isOpeningOrClosing and self.isOpened) then
		self.isOpeningOrClosing = true;
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			self:OnChestClose()
		end})
		mytimer:Change(500, nil);

		local obj = self:GetInnerObject();
		if(obj) then
			AudioEngine.CreateGet("chestclosed"):play2d(0.3);
			obj:ToCharacter():PlayAnimation({39, 0});
		end
	end
end

function Entity:OnChestOpen()
	self.isOpeningOrClosing = nil;
	self.isOpened = true;

	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ChestPage.lua");
	local ChestPage = commonlib.gettable("MyCompany.Aries.Game.GUI.ChestPage");
	ChestPage.ShowPage(self, function()
		self:CloseChest();
	end);
end

function Entity:OnChestClose()
	self.isOpeningOrClosing = nil;
	self.isOpened = nil;
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	if(not self.isOpened) then
		self:OpenChest();
	else
		self:CloseChest();
	end
	return true;
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

-- called every frame
function Entity:FrameMove(deltaTime)
end