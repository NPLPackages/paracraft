--[[
Title: Drag/Modify/Create/Delete live model entity task
Author(s): LiXizhi
Date: 2021/12/28
Desc: used for saving operations to undo/redo task history. 
Support undo/redo
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
local task = MyCompany.Aries.Game.Tasks.DragEntity:new({})

-- drag and drop
task:StartDraggingEntity(entity);
task:DropDraggingEntity();

-- modify properties
task:BeginModifyEntity(entity)
task:EndModifyEntity();

-- create entity
task:CreateEntity(entity)

-- delete entity
task:DeleteEntity(entity)
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

function DragEntity:BeginModifyEntity(dragEntity)
	self.draggingEntity = dragEntity;
	if(self.draggingEntity) then
		self.fromXmlNode = self.draggingEntity:SaveToXMLNode()
		self:SetModifyMode()
	end
end


function DragEntity:EndModifyEntity()
	if(self.draggingEntity) then
		self.toXmlNode = self.draggingEntity:SaveToXMLNode();
		if(not self.nohistory and GameLogic.GameMode:CanAddToHistory()) then
			-- do nothing if they are equal.
			if(not commonlib.compare(self.fromXmlNode, self.toXmlNode)) then
				UndoManager.PushCommand(self);
			end
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

function DragEntity:SetDeleteMode()
	self.mode = "delete"
	self.toXmlNode = nil;
end

function DragEntity:SetModifyMode()
	self.mode = "modify"
end
