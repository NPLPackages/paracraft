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
local Event = commonlib.gettable("System.Core.Event");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local FolderManager = commonlib.gettable("MyCompany.Aries.Game.GameLogic.FolderManager")

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityInvisibleClickSensor"));
Entity:Property({"isDisplayModel", false, "IsDisplayModel", "SetDisplayModel", auto=true});
Entity:Property({"isMountpointDetached", true});

Entity.class_name = "EntityInvisibleClickSensor";
Entity.defaultFolderName = "InvisibleClickSensor";

EntityManager.RegisterEntityClass(Entity.class_name, Entity);


function Entity:ctor()
	self.aabbDirty = true
	self.clickAABBs = {}
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

		if(not EditSensorTask.GetInstance()) then
			GameLogic.GetPlayerController():PickItemByEntity(self);
		end

		if(EditSensorTask.GetInstance()) then
			EditSensorTask.GetInstance():SetTransformMode(true)
			EditSensorTask.GetInstance():SelectModel(self);
		end
	end
end

function Entity:BeginModify()
	Entity._super.BeginModify(self)
end

function Entity:EndModify()
	Entity._super.EndModify(self)
	self.aabbDirty = true
end

function Entity:GetClickAABB(index)
	index = index or 1;
	if(self.aabbDirty) then
		self.aabbDirty = false;
		local count = self:GetMountPointsCount()
		if(count == 0) then
			-- if no mount point aabb is found, we will use the current entity's aabb
			local aabb = self.clickAABBs[1];
			local x, y, z = self:GetPosition();
			local radius = self:GetScaling() * 0.5
			if(not aabb) then
				aabb = ShapeAABB:new();
				self.clickAABBs[1] = aabb
			end
			aabb:SetCenterExtentValues(x, y+radius, z, radius, radius, radius)
			aabb.facing = self:GetFacing();
			return aabb;
		else
			local mountpoints = self:CreateGetMountPoints()
			self.clickAABBs = mountpoints:GetWorldSpaceAABBs(true)
		end
	end
	return self.clickAABBs[index];
end

function Entity:GetClickAABBCount()
	local count = self:GetMountPointsCount()
	return count > 0 and count or 1;
end


-- @param x, y, z: in real world coordinate
-- @param pointRadius: if nil, it means 0
-- @return boolean, facing:  the first parameter is true if the point is inside one of its clickable aabb
-- the second parameter contains the facing of the aabb. 
function Entity:IsPointInClickableAABB(x, y, z, pointRadius)
	for i=1, self:GetClickAABBCount() do
		local aabb = self:GetClickAABB(i)
		if(aabb and aabb:ContainsPoint(x, y, z, pointRadius)) then
			return true, aabb.facing;
		end
	end
end
