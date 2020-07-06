--[[
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditLightModel/EditLightModelManipContainer.lua");
local EditLightModelManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditLightModelManipContainer");
local manipCont = EditLightModelManipContainer:new();
manipCont:init();
self:AddManipulator(manipCont);
manipCont:connectToDependNode(entity);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/ManipContainer.lua");
local Color = commonlib.gettable("System.Core.Color");
local Plane = commonlib.gettable("mathlib.Plane");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EditLightModelManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditLightModelManipContainer"));
EditLightModelManipContainer:Property({"Name", "EditLightModelManipContainer", auto=true});
EditLightModelManipContainer:Property({"PenWidth", 0.01});
EditLightModelManipContainer:Property({"showGrid", true, "IsShowGrid", "SetShowGrid", auto=true});
EditLightModelManipContainer:Property({"mainColor", "#ffff00"});

function EditLightModelManipContainer:ctor()
	self:AddValue("position", {0,0,0});
end

function EditLightModelManipContainer:init(node)
	self.node = node;
	EditLightModelManipContainer._super.init(self);
	return self;
end

function EditLightModelManipContainer:createChildren()
	self.translateManip = self:AddTranslateManip();
	self.translateManip:SetFixOrigin(true);
	self.translateManip:SetRealTimeUpdate(false);
	self.translateManip:SetUpdatePosition(false);

	self.scaleManip = self:AddScaleManip();
	self.scaleManip:SetRealTimeUpdate(true);
	self.scaleManip.radius = 0.7;
	self.scaleManip:SetUniformScaling(true);

	self.rotateManip = self:AddRotateManip();
	self.rotateManip:SetRealTimeUpdate(true);
	self.rotateManip.radius = 1.2;
	self.rotateManip:SetYawPitchRollMode(true);
	self.rotateManip:SetYawEnabled(true);
	self.rotateManip:SetPitchEnabled(true);
	self.rotateManip:SetRollEnabled(true);
end

function EditLightModelManipContainer:paintEvent(painter)
	EditLightModelManipContainer._super.paintEvent(self, painter);
end

function EditLightModelManipContainer:OnValueChange(name, value)
	EditLightModelManipContainer._super.OnValueChange(self);
	if(name == "position") then
		self:SetPosition(unpack(value));
	end
end

function EditLightModelManipContainer:connectToDependNode(node)
	self.node = node;

	local plugPos = node:findPlug("position");
	local plugOffsetPos = node:findPlug("modelOffsetPos");

	-- one way binding 
	local manipPosPlug = self:findPlug("position");
	self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
		local p1 = plugPos:GetValue();
		local p2 = plugOffsetPos:GetValue();
		return {p1[1]+p2[1], p1[2]+p2[2], p1[3]+p2[3]}
	end);

	-- two-way binding for offset position conversion:
	if(plugOffsetPos) then
		local manipTranslatePlug = self.translateManip:findPlug("position");
		self:addManipToPlugConversionCallback(plugOffsetPos, function(self, plug)
			local p1 = manipTranslatePlug:GetValue();
			local p2 = plugPos:GetValue();
			return {p1[1]-p2[1], p1[2]-p2[2], p1[3]-p2[3]}
		end);
		self:addPlugToManipConversionCallback(manipTranslatePlug, function(self, manipPlug)
			local p1 = plugOffsetPos:GetValue();
			local p2 = plugPos:GetValue();
			return {p1[1]+p2[1], p1[2]+p2[2], p1[3]+p2[3]}
		end);
	end

	local nodeScalePlug = node:findPlug("modelScale");
	local manipScalePlug = self.scaleManip:findPlug("scaling");

	self:addManipToPlugConversionCallback(nodeScalePlug, function(self, plug)
		return manipScalePlug:GetValue()[1] or 1;
	end);
	self:addPlugToManipConversionCallback(manipScalePlug, function(self, manipPlug)
		local scaling = nodeScalePlug:GetValue() or 1;
		if(type(scaling) == "number") then
			scaling = {scaling, scaling, scaling};
		end
		return scaling;
	end);

	local nodeYawPlug = node:findPlug("modelYaw");
	local manipYawPlug = self.rotateManip:findPlug("yaw");

	self:addManipToPlugConversionCallback(nodeYawPlug, function(self, plug)
		return manipYawPlug:GetValue() or 0;
	end);
	self:addPlugToManipConversionCallback(manipYawPlug, function(self, manipPlug)
		return nodeYawPlug:GetValue() or 0;
	end);

	local nodePitchPlug = node:findPlug("modelPitch");
	local manipPitchPlug = self.rotateManip:findPlug("pitch");

	self:addManipToPlugConversionCallback(nodePitchPlug, function(self, plug)
		return manipPitchPlug:GetValue() or 0;
	end);
	self:addPlugToManipConversionCallback(manipPitchPlug, function(self, manipPlug)
		return nodePitchPlug:GetValue() or 0;
	end);

	local nodeRollPlug = node:findPlug("modelRoll");
	local manipRollPlug = self.rotateManip:findPlug("roll");

	self:addManipToPlugConversionCallback(nodeRollPlug, function(self, plug)
		return manipRollPlug:GetValue() or 0;
	end);
	self:addPlugToManipConversionCallback(manipRollPlug, function(self, manipPlug)
		return nodeRollPlug:GetValue() or 0;
	end);

	self:finishAddingManips();
	EditLightModelManipContainer._super.connectToDependNode(self, node);
end