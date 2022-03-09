--[[
Title: Drag live model entity task
Author(s): LiXizhi
Date: 2021/12/28
Desc: drag and drop live model entity
Support undo/redo
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
local task = MyCompany.Aries.Game.Tasks.DragEntity:new({})
task:StartDraggingEntity(entity);
task:DropDraggingEntity();

local task = MyCompany.Aries.Game.Tasks.DragEntity:new({nohistory=true})
task:CreateEntity(entity)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");

local DragEntity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.DragEntity"));

function DragEntity:ctor()
	
end

-- we have just created an entity
function DragEntity:CreateEntity(entity)
	self:StartDraggingEntity(entity);
	self:DropDraggingEntity(entity)
	self:SetCreateMode()
end

-- we are about to delete an entity
function DragEntity:DeleteEntity(entity)
	self:StartDraggingEntity(entity);
	self:DropDraggingEntity(entity)
	self:SetDeleteMode()
end

function DragEntity:StartDraggingEntity(dragEntity)
	self.draggingEntity = dragEntity;
	if(self.draggingEntity) then
		self.fromXmlNode = self.draggingEntity:SaveToXMLNode()
	end
end

function DragEntity:DropDraggingEntity()
	if(self.draggingEntity) then
		self.toXmlNode = self.draggingEntity:SaveToXMLNode();

		if(not self.nohistory and GameLogic.GameMode:CanAddToHistory()) then
			UndoManager.PushCommand(self);
		end
	end	
end

function DragEntity:Run()
end


function DragEntity:Redo()
	if(self.draggingEntity) then
		if(self.toXmlNode) then
			-- recreate the entity and attach to scene
			self.draggingEntity:UpdateFromXMLNode(self.toXmlNode)
		else
			self.draggingEntity:Destroy();
		end
	end
end

function DragEntity:Undo()
	if(self.draggingEntity) then
		if(self.fromXmlNode) then
			self.draggingEntity:UpdateFromXMLNode(self.fromXmlNode)
		else
			self.draggingEntity:Destroy();
		end
	end
end

-- in create mode, when undo, we will delete the object. 
function DragEntity:SetCreateMode()
	self.fromXmlNode = nil;
	self.mode = "create"
end

-- in create mode, when undo, we will delete the object. 
function DragEntity:SetDeleteMode()
	self.mode = "delete"
	self.toXmlNode = nil;
end
