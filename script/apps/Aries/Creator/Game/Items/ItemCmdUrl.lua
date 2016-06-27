--[[
Title: ItemCmdUrl
Author(s): LiXizhi
Date: 2014/3/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCmdUrl.lua");
local ItemCmdUrl = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCmdUrl");
local item_ = ItemCmdUrl:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCommandLine.lua");
NPL.load("(gl)script/ide/math/vector.lua");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local ItemCmdUrl = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemCommandLine"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCmdUrl"));

block_types.RegisterItemClass("ItemCmdUrl", ItemCmdUrl);


-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemCmdUrl:ctor()

end

-- not stackable
function ItemCmdUrl:GetMaxCount()
	return 64;
end

-- called when this function is activated when the entity is activated. 
-- @param entity: this is usually a command block or entity. 
-- @return true if the entity should stop activating other items in its bag. 
function ItemCmdUrl:OnActivate(itemStack, entityContainer, entityPlayer)
	local url = itemStack:GetData();
	if(url and url:match("^http://")) then
		CommandManager:RunCommand("open", url, entityContainer);
		return true;
	else
		return ItemCmdUrl._super.OnActivate(self, itemStack, entityContainer, entityPlayer)
	end
end



