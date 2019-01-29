--[[
Title: ItemCodeActor
Author(s): LiXizhi
Date: 2019/1/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCodeActor.lua");
local ItemCodeActor = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodeActor");
local item_ = ItemCodeActor:new({});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorNPC.lua");
local ActorNPC = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorNPC");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemCodeActor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodeActor"));

block_types.RegisterItemClass("ItemCodeActor", ItemCodeActor);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemCodeActor:ctor()
	self:SetOwnerDrawIcon(true);
end

function ItemCodeActor:GetActorName(itemStack)
	return itemStack:GetDataField("tooltip");
end

function ItemCodeActor:SetActorName(itemStack, name)
	itemStack:SetDataField("tooltip", name);
end

function ItemCodeActor:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	local actorName = self:GetActorName(itemStack);
	if(not actorName) then
		self:SelectActor(itemStack)
		return
	end
	local actor = GameLogic.GetCodeGlobal():GetActorByName(actorName)
	if(actor) then
		local codeblock = actor:GetCodeBlock()
		if(codeblock) then
			local newActor = codeblock:CloneMyself();
			if(newActor) then
				newActor:SetBlockPos(x, y, z);
			end
		end
	else
		LOG.std(nil, "info", "ItemCodeActor", "code actor %s can not be found in the scene", actorName);
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemCodeActor:DrawIcon(painter, width, height, itemStack)
	ItemCodeActor._super.DrawIcon(self, painter, width, height, itemStack);
	local name = self:GetActorName(itemStack);
	if(name and name~="") then
		painter:SetPen("#33333380");
		painter:DrawRect(0,0, width, 14);
		painter:SetPen("#ffffff");
		painter:DrawText(1,0, name);
	end
end

-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
function ItemCodeActor:OnClickInHand(itemStack, entityPlayer)
	-- if there is selected blocks, we will replace selection with current block in hand. 
	if(GameLogic.GameMode:IsEditor() and entityPlayer == EntityManager.GetPlayer()) then
		self:SelectActor(itemStack);
	end
end

-- display a list for user to select a code actor	
function ItemCodeActor:SelectActor(itemStack)
	local options = {};
	for name, _ in pairs(GameLogic.GetCodeGlobal().actors) do
		if(name ~= "") then
			options[#options+1] = {value = name, text = name}	
		end
	end
					
	local old_value = self:GetActorName(itemStack);
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
	local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
	EnterTextDialog.ShowPage(L"演员名字", function(result)
		if(result and result ~= "" and result~=old_value) then
			self:SetActorName(itemStack, result);
		end
	end,old_value, "select", options);
end