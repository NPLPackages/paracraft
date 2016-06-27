--[[
Title: Entity's EditModel 
Author(s): LiXizhi
Date: 2015/1/5
Desc: the base class for model editors. Usage pattern:
	Entity class itself is thin and fast, containing no complex editor event handlers. 
	When editing entity with external complex editors, we usually need to bind it with the entity's EditModel, which is created on demand, 
	and provide a editor-friendly view and events into the entity's internal data. 
Generally editmodel does not contain the data directly, instead everything is read/write to the contained entity member object. 
Some special editors may contain editor specific information. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/Entity.EditModel.lua");
local EntityEditModel = commonlib.gettable("MyCompany.Aries.Game.EditModels.EntityEditModel")
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");

local EditModel = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.EditModels.EntityEditModel"));

EditModel:Property("Name", "Entity.EditModel");

EditModel:Signal("Destroy", function() end);
EditModel:Signal("Selected", function() end);
EditModel:Signal("Deselected", function() end);
EditModel:Signal("BeginEdit", function() end);
EditModel:Signal("EndEdit", function() end);

function EditModel:ctor()
end

function EditModel:GetEntity()
	return self.entity;
end

-- @param entity: the underlying edit model. 
function EditModel:init(entity)
	self.entity = entity;
	return self;
end

-- when model is destroyed. 
function EditModel:OnDestroy(x,y,z)
	self:Destroy();
end



