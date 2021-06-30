--[[
Title: ItemSlot
Author(s): chenjinxian
Date: 2020/8/6
Desc: A 3D canvas container for displaying picture, 3D scene, etc
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/ItemSlot.lua");
local ItemSlot = commonlib.gettable("MyCompany.Aries.Game.mcml2.ItemSlot");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local ItemSlot = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("MyCompany.Aries.Game.mcml2.ItemSlot"));
ItemSlot:Property("Name", "ItemSlot");
ItemSlot:Property({"BackgroundColor", "#ffffff", auto=true});
ItemSlot:Property({"Background", nil, auto=true});
ItemSlot:Property({"Slot", nil, auto=true});
ItemSlot:Property({"BlockId", nil, "GetBlockId", "SetBlockId"});

function ItemSlot:ctor()
end

function ItemSlot:SetBlockId(block_id, agent_name)
	if (block_id) then
		self.itemStack = ItemStack:new():Init(block_id, 1);
		if (agent_name) then
			self.itemStack:SetDataField("name", agent_name);
		end
	end
end

function ItemSlot:paintEvent(painter)
	local slot = self:GetSlot();
	if (slot) then
		local itemStack = slot:GetStack();
		if (itemStack) then
			local item = itemStack:GetItem();
			if (item) then
				item:DrawIcon(painter, self:width(), self:height(), itemStack);
			end
		end
	elseif (self.itemStack) then
		local item = self.itemStack:GetItem();
		if (item) then
			item:DrawIcon(painter, self:width(), self:height(), self.itemStack);
		end
	end
end