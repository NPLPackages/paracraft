--[[
Title: ItemCodeActorInstance
Author(s): LiXizhi
Date: 2019/1/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCodeActorInstance.lua");
local ItemCodeActorInstance = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodeActorInstance");
local item_ = ItemCodeActorInstance:new({});
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemCodeActorInstance = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodeActorInstance"));

block_types.RegisterItemClass("ItemCodeActorInstance", ItemCodeActorInstance);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemCodeActorInstance:ctor()
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemCodeActorInstance:OnItemRightClick(itemStack, entityPlayer)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCodeActor/EditCodeActor.lua");
	local EditCodeActor = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor");
	EditCodeActor.SetFocusToItemStack(itemStack);
    return itemStack, true;
end

