--[[
Title: ItemLight
Author(s): LiXizhi
Date: 2016/9/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLight.lua");
local ItemLight = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLight");
local item = ItemLight:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemLight = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemLight"));

block_types.RegisterItemClass("ItemLight", ItemLight);


-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemLight:ctor()
	self:SetOwnerDrawIcon(true);
end

function ItemLight:GetModelFileName(itemStack)
	return itemStack and itemStack:GetDataField("tooltip");
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemLight:DrawIcon(painter, width, height, itemStack)
	ItemLight._super.DrawIcon(self, painter, width, height, itemStack);
	local filename = self:GetModelFileName(itemStack);
	if(filename and filename~="") then
		filename = filename:match("[^/]+$"):gsub("%..*$", "");
		filename = filename:sub(1, 6);
		painter:SetPen("#33333380");
		painter:DrawRect(0,0, width, 14);
		painter:SetPen("#ffffff");
		painter:DrawText(1,0, filename);
	end
end

-- virtual function: 
function ItemLight:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditLight/EditLightTask.lua");
	local EditLightTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditLightTask");
	return EditLightTask:new();
end