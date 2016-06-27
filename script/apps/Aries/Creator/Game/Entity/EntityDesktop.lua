--[[
Title: Desktop
Author(s): LiXizhi
Date: 2014/3/18
Desc: this is a singlton entity that stores user's customization of the user desktop, which is not editable in game mode. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityDesktop.lua");
local EntityDesktop = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityDesktop")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityDesktop"));

-- class name
Entity.class_name = "EntityDesktop";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = false;
-- this is singleton desktop entity. 
Entity.name = "desktop";

function Entity:ctor()
	self.inventory = InventoryBase:new():Init();
	self.inventoryView = ContainerView:new():Init(self.inventory);
	self.inventory:SetClient();
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	return self;
end

-- make it the default desktop layout. This is usually called when the desktop is first created. 
function Entity:SetDefaultDesktop()
	local itemstack;
	--itemstack = ItemStack:new():Init(block_types.names.CmdUrl, 1, GameLogic.options.ask_for_help_url);
	--itemstack:SetTooltip("问题求助");
	itemstack = ItemStack:new():Init(block_types.names.Book, 1, 
		format(L"欢迎来到我的世界#请仔细阅读规则#=到创意论坛来支持我的作品哦~=#[[%s][点我进入论坛]]", GameLogic.options.bbs_home_url));
	itemstack:SetTooltip(L"作者的话");
	self.inventory:AddItem(itemstack, 1);

	itemstack = ItemStack:new():Init(block_types.names.CmdUrl, 1, GameLogic.options.bbs_upload_url);
	itemstack:SetTooltip(L"到论坛支持作者 给作者留言[bbs]");
	self.inventory:AddItem(itemstack, 2);
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

function Entity:OpenDesktop()
	if(not self.isOpened) then
		self:OnDesktopOpen();
	end
end

function Entity:CloseDesktop()
	if(self.isOpened) then
		self:OnDesktopClose()
	end
end

function Entity:OnDesktopOpen()
	self.isOpened = true;
end

function Entity:OnDesktopClose()
	self.isOpened = nil;
end

-- called every frame
function Entity:FrameMove(deltaTime)
end