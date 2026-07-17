--[[
Title: ItemPlayerAnim
Author(s): leio
Date: 2021/7/15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemPlayerAnim.lua");
local ItemPlayerAnim = commonlib.gettable("MyCompany.Aries.Game.Items.ItemPlayerAnim");
local item_ = ItemPlayerAnim:new({icon,});
-------------------------------------------------------
]]

local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local ItemPlayerAnim = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemPlayerAnim"));

block_types.RegisterItemClass("ItemPlayerAnim", ItemPlayerAnim);


function ItemPlayerAnim:ctor()
	self:SetOwnerDrawIcon(true);
end

function ItemPlayerAnim:GetMaxCount()
	return 1;
end

function ItemPlayerAnim:OnSelect(itemStack)
	ItemPlayerAnim._super.OnSelect(self, itemStack)
	GameLogic.SetStatus(L"右键点击世界可以播放动画");
end

function ItemPlayerAnim:OnDeSelect()
	ItemPlayerAnim._super.OnDeSelect(self)
	GameLogic.SetStatus(nil);
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemPlayerAnim:OnItemRightClick(itemStack, entityPlayer)
	local animId = itemStack:GetDataField("animId");
	if(animId) then
		self:PlayAnim(animId);
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemPlayerAnim:DrawIcon(painter, width, height, itemStack)
	if not itemStack then
		return
	end
	local icon = itemStack:GetDataField("customIcon")
	if(icon) then
		painter:SetPen("#ffffff");
		painter:DrawRectTexture(0, 0, width, height, icon);
	else
		ItemPlayerAnim._super.DrawIcon(self, painter, width, height, itemStack);
	end
end

function ItemPlayerAnim:PlayAnim(animId)
	if not animId or tonumber(animId) <= 0 then
		return
	end
	self:UserItemImmediate()
	if not self.PlayAnimFunc then
		self.PlayAnimFunc = commonlib.debounce(function(animId)
			local cmd = string.format("/anim %d", tonumber(animId));
			GameLogic.RunCommand(cmd);
		end, 50)
	end
	self.PlayAnimFunc(animId)
end

function ItemPlayerAnim:UserItemImmediate()
	local player = GameLogic.GetPlayer();
	if not player then
		return
	end
	local inventory = player:GetInventory()
	if not inventory then
		return
	end
	local handIndex = inventory:GetHandToolIndex()
	inventory:RemoveItem(handIndex)
	self:OnDeSelect()
end

