--[[
Title: ItemInvisibleClickSensor
Author(s): LiXizhi
Date: 2022/1/15
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemInvisibleClickSensor.lua");
local ItemInvisibleClickSensor = commonlib.gettable("MyCompany.Aries.Game.Items.ItemInvisibleClickSensor");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLiveModel.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemInvisibleClickSensor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemInvisibleClickSensor"));

block_types.RegisterItemClass("ItemInvisibleClickSensor", ItemInvisibleClickSensor);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemInvisibleClickSensor:ctor()
end

function ItemInvisibleClickSensor:OnSelect(itemStack)
	ItemInvisibleClickSensor._super.OnSelect(self);
end

function ItemInvisibleClickSensor:OnDeSelect()
	ItemInvisibleClickSensor._super.OnDeSelect(self);
end


function ItemInvisibleClickSensor:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditSensorTask.lua");
	local EditSensorTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditSensorTask");
	EditSensorTask:SetItemInHand(itemStack)
	return EditSensorTask:new();
end


-- only spawn entity if player is holding a LiveModel item in right hand. 
-- @param serverdata: default to item stack in player's hand item
function ItemInvisibleClickSensor:SpawnNewEntityModel(bx, by, bz)
	local entity = EntityManager.EntityInvisibleClickSensor:Create({bx=bx,by=by,bz=bz, 
		item_id = block_types.names.InvisibleClickSensor});
	entity:Refresh();
	entity:Attach();
	return entity
end

-- virtual: convert entity to item stack. 
-- such as when alt key is pressed to pick a entity in edit mode. 
function ItemInvisibleClickSensor:ConvertEntityToItem(entity, itemStack)
	if(entity and entity:isa(EntityManager.EntityInvisibleClickSensor))then
		itemStack = itemStack or ItemStack:new():Init(block_types.names.InvisibleClickSensor, 1);
		local node = entity:SaveToXMLNode()
		node.attr.x, node.attr.y, node.attr.z = nil, nil, nil
		node.attr.bx, node.attr.by, node.attr.bz = nil, nil, nil
		node.attr.name = nil;
		node.attr.linkTo = nil;
		node.attr.class = nil;
		node.attr.item_id = nil;
		itemStack:SetDataField("xmlNode", node)
		return itemStack
	end
end