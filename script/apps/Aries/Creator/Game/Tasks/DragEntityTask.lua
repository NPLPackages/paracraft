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

function DragEntity:StartDraggingEntity(dragEntity)
	self.draggingEntity = dragEntity;
	if(self.draggingEntity) then
		self.fromXmlNode = self.draggingEntity:SaveToXMLNode()
	end
end

function DragEntity:DropDraggingEntity()
	if(self.draggingEntity) then
		self.toXmlNode = self.draggingEntity:SaveToXMLNode();
		TaskManager.AddTask(self);

		if(GameLogic.GameMode:CanAddToHistory()) then
			UndoManager.PushCommand(self);
		end
	end	
end

function DragEntity:Run()
end


function DragEntity:Redo()
	if(self.draggingEntity and self.toXmlNode) then
		if(self:IsCreateMode()) then
			-- recreate the entity and attach to scene
			self.draggingEntity:UpdateFromXMLNode(self.toXmlNode)
		else
			self.draggingEntity:UpdateFromXMLNode(self.toXmlNode)
		end
	end
end

function DragEntity:Undo()
	if(self.draggingEntity and self.fromXmlNode) then
		if(self:IsCreateMode()) then
			self.draggingEntity:Destroy();
		else
			self.draggingEntity:UpdateFromXMLNode(self.fromXmlNode)
		end
	end
end

-- in create mode, when undo, we will delete the object. 
function DragEntity:SetCreateMode()
	self.mode = "create"
end

function DragEntity:IsCreateMode()
	return self.mode == "create"
end