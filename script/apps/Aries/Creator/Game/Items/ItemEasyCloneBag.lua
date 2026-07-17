--[[
Title: ItemEasyCloneBag
Author(s): LiXizhi
Date: 2025/10/14
Desc: Clone Bag Tool - A tool to clone live models from the scene into bag slots 
and create them anywhere across different worlds or editable worlds.

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemEasyCloneBag.lua");
local ItemEasyCloneBag = commonlib.gettable("MyCompany.Aries.Creator.Game.Items.ItemEasyCloneBag");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local ItemEasyCloneBag = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.Items.ItemEasyCloneBag"));

-- allow running task in game mode too
ItemEasyCloneBag:Property({"allowTaskInGameMode", true, auto=true})

block_types.RegisterItemClass("ItemEasyCloneBag", ItemEasyCloneBag);

function ItemEasyCloneBag:ctor()
end

-- virtual function: when selected in right hand
function ItemEasyCloneBag:OnSelect(itemStack)
    ItemEasyCloneBag._super.OnSelect(self, itemStack);
end

function ItemEasyCloneBag:OnDeSelect()
    GameLogic.SetStatus(nil);
    ItemEasyCloneBag._super.OnDeSelect(self);
end

-- virtual: create the task when this item is selected
function ItemEasyCloneBag:CreateTask(itemStack)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCloneBag.lua");
    local EasyCloneBag = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyCloneBag");
    if(EasyCloneBag.new) then
        local task = EasyCloneBag:new();
        return task;
    end
end

-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
-- by default, if there is selected blocks, we will replace selection with current block in hand. 
function ItemEasyCloneBag:OnClickInHand(itemStack, entityPlayer)
	self:ReloadTask(itemStack);
end
