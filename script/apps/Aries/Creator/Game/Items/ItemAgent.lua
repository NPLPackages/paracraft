--[[
Title: ItemAgent
Author(s): LiXizhi
Date: 2021/2/17
Desc: Agent item is a special item that is defined in code blocks. The appearance and functions of the agent item 
are implemented by registerAgentEvent in code blocks. Agent Item is usually listed in the inventory of agent sign block. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemAgent.lua");
local ItemAgent = commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgent");
local item = ItemAgent:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Identicon.lua");
local Identicon = commonlib.gettable("System.Windows.Controls.Identicon");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemAgent = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgent"));

block_types.RegisterItemClass("ItemAgent", ItemAgent);

function ItemAgent:ctor()
	self.m_bIsOwnerDrawIcon = true;
end
 
function ItemAgent:GetAgentName(itemStack)
	return itemStack and itemStack:GetDataField("tooltip");
end

function ItemAgent:SetAgentName(itemStack, name)
	if(itemStack) then
		itemStack:SetDataField("tooltip", name);
	end
end

function ItemAgent:IsInited(itemStack)
	if(itemStack) then
		local name = self:GetAgentName(itemStack)
		if(not name or name == "") then
			return true
		end
	end
end

-- @return true if agent item has a name and initialized. 
function ItemAgent:TryInitAgent(itemStack)
	if(itemStack) then
		local name = self:GetAgentName(itemStack)
		if(not name or name == "") then
			self:OnOpenEditAgentNameDialog(itemStack)
			return;
		else
			return true
		end
	end
end

function ItemAgent:OnOpenEditAgentNameDialog(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
	local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
	EnterTextDialog.ShowPage(L"请输入智能人物的名字", function(result)
		if(result and result~="") then
			self:SetAgentName(itemStack, result)
		end
	end, self:GetAgentName(itemStack))
end

function ItemAgent:OnItemRightClick(itemStack, entityPlayer)
	if(self:TryInitAgent(itemStack)) then
		return itemStack, false;	
	else
		return itemStack, true;	
	end
end

function ItemAgent:GetIcon(itemStack)
	if(itemStack and type(itemStack) == "table") then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			local icon = itemStack.icon_;
			if(not icon) then
				icon = GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".GetIcon")
				if(icon) then
					icon = Files.GetWorldFilePath(icon)
					itemStack.icon_ = icon;
					return icon
				end
			elseif(icon ~= "") then
				return icon;
			end
		end
	end
	return ItemAgent._super.GetIcon(self)
end

-- virtual: draw icon with given size at current position (0,0)
-- this function is only called when IsOwnerDrawIcon property is true. 
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemAgent:DrawIcon(painter, width, height, itemStack)
	painter:SetPen(self:GetIconColor());
	painter:DrawRectTexture(0, 0, width, height, self:GetIcon(itemStack));
	if(itemStack and not itemStack.icon_) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			-- render identi-icon
			local size = width;
			local hash = ParaMisc.md5(name);
			local margin = 4
			painter:SetPen("#000000");
			painter:DrawRect(0, 0, width, height);
			Identicon.drawIdentiIcon(painter, hash, size, margin)
		end
	end

	if(itemStack) then
		if(itemStack.count>1) then
			-- draw count at the corner: no clipping, right aligned, single line
			painter:SetPen("#000000");	
			painter:DrawText(0, height-15+1, width, 15, tostring(itemStack.count), 0x122);
			painter:SetPen("#ffffff");	
			painter:DrawText(0, height-15, width-1, 15, tostring(itemStack.count), 0x122);
		end
	end
end

-- virtual function: use the item. 
function ItemAgent:OnUse()
end

-- virtual function: when selected in right hand
function ItemAgent:OnSelect(itemStack)
	if(self:TryInitAgent(itemStack)) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			self.curItemStack = itemStack;
			GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".OnSelect")
		end
	end
end

-- virtual function: when deselected in right hand
function ItemAgent:OnDeSelect()
	local itemStack = self.curItemStack;
	self.curItemStack = nil;
	if(self:TryInitAgent(itemStack)) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".OnDeSelect")
		end
	end
end

function ItemAgent:OnClickInHand(itemStack, entityPlayer)
	if(self:TryInitAgent(itemStack)) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".OnClickInHand")
		end
	end
end

-- Right clicking in 3d world with the block in hand will trigger this function. 
-- Alias: OnUseItem;
-- @param itemStack: can be nil
-- @param entityPlayer: can be nil
-- @param side: this is OPPOSITE of the touching side
-- @return isUsed, entityCreated: isUsed is true if something happens.
function ItemAgent:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if(self:TryInitAgent(itemStack)) then
		local name = self:GetAgentName(itemStack)
		if(name and name~="") then
			GameLogic.GetCodeGlobal():BroadcastTextEvent(name..".TryCreate", {x=x,y=y,z=z, side=side, data=data, side_region=side_region})
		end
	end
end

