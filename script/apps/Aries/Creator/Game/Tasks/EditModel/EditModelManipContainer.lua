--[[
Title: Edit Model Manipulator
Author(s): LiXizhi@yeah.net
Date: 2016/8/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelManipContainer.lua");
local EditModelManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditModelManipContainer");
local manipCont = EditModelManipContainer:new();
manipCont:init();
self:AddManipulator(manipCont);
manipCont:connectToDependNode(entity);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/ManipContainer.lua");
local Plane = commonlib.gettable("mathlib.Plane");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EditModelManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditModelManipContainer"));
EditModelManipContainer:Property({"Name", "EditModelManipContainer", auto=true});
-- EditModelManipContainer:Property({"EnablePicking", true});
EditModelManipContainer:Property({"PenWidth", 0.01});
EditModelManipContainer:Property({"showGrid", true, "IsShowGrid", "SetShowGrid", auto=true});
EditModelManipContainer:Property({"mainColor", "#ffff00"});
-- attribute name for position on the dependent node that we will bound to. it should be vector3d type like {0,0,0}
EditModelManipContainer:Property({"PositionPlugName", "position", auto=true});
EditModelManipContainer:Property({"ScalePlugName", "scale", auto=true});
EditModelManipContainer:Property({"YawPlugName", "yaw", auto=true});
EditModelManipContainer:Property({"OffsetPosPlugName", "offsetPos", auto=true});

function EditModelManipContainer:ctor()
	self:AddValue("position", {0,0,0});
end

function EditModelManipContainer:createChildren()
	self.translateManip = self:AddTranslateManip();
	self.translateManip:SetFixOrigin(true);
	self.scaleManip = self:AddScaleManip();
	self.scaleManip.radius = 0.5;
	self.scaleManip:SetUniformScaling(true);
	self.rotateManip = self:AddRotateManip();
	self.rotateManip:SetYawPitchRollMode(true);
	self.rotateManip:SetYawEnabled(true);
	self.rotateManip:SetPitchEnabled(false);
	self.rotateManip:SetRollEnabled(false);
end

function EditModelManipContainer:paintEvent(painter)
	EditModelManipContainer._super.paintEvent(self, painter);
end

function EditModelManipContainer:OnValueChange(name, value)
	EditModelManipContainer._super.OnValueChange(self);
	if(name == "position") then
		self:SetPosition(unpack(value));
	end
end

-- @param node: it should be EntityBlockModel object. 
function EditModelManipContainer:connectToDependNode(node)
	local plugPos = node:findPlug(self.PositionPlugName);
	local plugScale = node:findPlug(self.ScalePlugName);
	local plugYaw = node:findPlug(self.YawPlugName);
	local plugOffsetPos = node:findPlug(self.OffsetPosPlugName);

	self.node = node;

	if(plugPos) then
		-- one way binding 
		local manipPosPlug = self:findPlug("position");
		self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
			return plugPos:GetValue() + plugOffsetPos:GetValue();
		end);

		-- two-way binding for offset position conversion:
		if(plugOffsetPos) then
			local manipTranslatePlug = self.translateManip:findPlug("position");
			self:addManipToPlugConversionCallback(plugOffsetPos, function(self, plug)
				return manipTranslatePlug:GetValue() - plugPos:GetValue();
			end);
			self:addPlugToManipConversionCallback(manipTranslatePlug, function(self, manipPlug)
				local pos = plugOffsetPos:GetValue();
				return pos + plugPos:GetValue();
			end);
		end

		-- two-way binding for scaling conversion:
		if(plugScale) then
			local manipScalePlug = self.scaleManip:findPlug("scaling");
			self:addManipToPlugConversionCallback(plugScale, function(self, plug)
				return manipScalePlug:GetValue()[1] or 1;
			end);
			self:addPlugToManipConversionCallback(manipScalePlug, function(self, manipPlug)
				local scaling = plugScale:GetValue() or 1;
				if(type(scaling) == "number") then
					scaling = {scaling, scaling, scaling};
				end
				return scaling;
			end);
		end

		-- two-way binding for yaw conversion:
		if(plugYaw) then
			local manipYawPlug = self.rotateManip:findPlug("yaw");
			self:addManipToPlugConversionCallback(plugYaw, function(self, plug)
				return manipYawPlug:GetValue() or 0;
			end);
			self:addPlugToManipConversionCallback(manipYawPlug, function(self, manipPlug)
				return plugYaw:GetValue() or 0;
			end);
		end

		-- force Begin/End edit pairs for updating result to network.
		if(node.BeginEdit) then
			node:BeginEdit();
			self:Connect("beforeDestroyed", node, "EndEdit"); 
		end
	end
	-- should be called only once after all conversion callbacks to setup real connections
	self:finishAddingManips();
	EditModelManipContainer._super.connectToDependNode(self, node);
end