--[[
Title: Entity Invisible Click Sensor
Author(s): LiXizhi
Date: 2022/1/15
Desc: a block that can define a custom aabb. When the user clicks any normal block inside the aabb area, we will trigger the entity's on click event. 
in addition to onclick, the touch block also support player enter and leave event. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityInvisibleClickSensor.lua");
local EntityInvisibleClickSensor = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityInvisibleClickSensor")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local FolderManager = commonlib.gettable("MyCompany.Aries.Game.GameLogic.FolderManager")

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityInvisibleClickSensor"));
Entity:Property({"isDisplayModel", false, "IsDisplayModel", "SetDisplayModel", auto=true});
Entity:Property({"isMountpointDetached", true});

Entity.class_name = "EntityInvisibleClickSensor";
Entity.defaultFolderName = "InvisibleClickSensor";

EntityManager.RegisterEntityClass(Entity.class_name, Entity);


function Entity:ctor()
end

-- @param Entity: the half radius of the object. 
function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	-- 227 detector block
	self:BecomeBlockItem(227); 
	self:SetOpacity(0.5)
	
	FolderManager:AddEntityToFolder(self, self.defaultFolderName)
	return self;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	return node;
end

function Entity:OpenEditor(editor_name, entity)
	local ctrl_pressed = System.Windows.Keyboard:IsCtrlKeyPressed();
	if(ctrl_pressed) then
		Entity._super.OpenEditor(self, editor_name, entity);
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditSensorTask.lua");
		local EditSensorTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditSensorTask");
		if(EditSensorTask.GetInstance()) then
			EditSensorTask.GetInstance():SetTransformMode(true)
			EditSensorTask.GetInstance():SelectModel(self);
		end
	end
end