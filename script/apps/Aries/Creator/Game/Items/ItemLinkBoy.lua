--[[
Title: ItemLinkBoy
Author(s): leio
Date: 2021/7/15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLinkBoy.lua");
local ItemLinkBoy = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLinkBoy");
local item_ = ItemLinkBoy:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local ItemLinkBoy = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemLinkBoy"));

block_types.RegisterItemClass("ItemLinkBoy", ItemLinkBoy);


function ItemLinkBoy:ctor()
end

function ItemLinkBoy:GetMaxCount()
	return 1;
end
-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemLinkBoy:OnItemRightClick(itemStack, entityPlayer)
	if(Keyboard.IsCtrlKeyPressed() or GameLogic.GameMode:CanDirectClickToActivateItem()) then
		-- in game mode, right click will trigger the command, in editor mode, Ctrl+right click will trigger. 
		self:OnActivate(itemStack, entityPlayer);
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/LinkBoyPage.lua");
		local LinkBoyPage = commonlib.gettable("MyCompany.Aries.Game.GUI.LinkBoyPage");
		LinkBoyPage.ShowPage();
	end
    return itemStack, true;
end


