--[[
Title: ItemToolBase
Author(s): LiXizhi
Date: 2016/7/27
Desc: Base class to tool items. A tool item is an item that once selected will automatically
run a task command with GUI and dedicated scene context. 
We usually store tool properties into itemStack instead of the temporary task object, 
so that all properties are persistent on disk and the tool item can have many instances on the quick launch slots.  
Please see "tool_name" property for an example, or see `ItemTerrainBrush` for a full implementation. 

virtual function:
 - CreateTask()  : overwrite to create the task command when this item is selected. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
local ItemToolBase = commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemToolBase = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"));

ItemToolBase:Property({"tool_name", nil, "GetToolName", "SetToolName"})
ItemToolBase:Property({"position", {0,0,0}, "GetPosition", "SetPosition"})

block_types.RegisterItemClass("ItemToolBase", ItemToolBase);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemToolBase:ctor()
	self.position = vector3d:new(0,0,0);
end

function ItemToolBase:SetPosition(vec)
	if(vec and not self.position:equals(vec)) then
		self.position:set(vec);
		self:valueChanged();
	end
end

function ItemToolBase:GetPosition()
	return self.position;
end

-- @param itemStack: if nil it is current selected one
function ItemToolBase:GetToolName(itemStack)
	itemStack = itemStack or self:GetCurrentItemStack()
	return itemStack and itemStack:GetDataField("tool_name") or self.tool_name;
end

function ItemToolBase:SetToolName(tool_name)
	local itemStack = self:GetCurrentItemStack()
	return itemStack and itemStack:SetDataField("tool_name", tool_name);
end

function ItemToolBase:GetCurrentItemStack()
	return self.curItemStack;
end

function ItemToolBase:SetCurrentItemStack(curItemStack)
	self.curItemStack = curItemStack;
end

-- virtual function: when selected in right hand
function ItemToolBase:OnSelect(itemStack)
	self:DeleteTask();
	self:SetCurrentItemStack(itemStack);
	if(not GameLogic.GameMode:IsEditor()) then
		return;
	end
	self.curTask = self:CreateTask(itemStack);
	if(self.curTask) then
		self.curTask:Run();
	end
end

function ItemToolBase:DeleteTask()
	if(self.curTask) then
		self.curTask:OnExit();
		self.curTask = nil;
	end
end

function ItemToolBase:OnDeSelect()
	self:DeleteTask();
	self:SetCurrentItemStack(nil);
end

function ItemToolBase:GetTask()
	return self.curTask;
end

-- virutal function: return a new task command object
function ItemToolBase:CreateTask(itemStack)
end
