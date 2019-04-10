--[[
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditLight/EditLightManipContainer.lua");
local EditLightManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditLightManipContainer");
local manipCont = EditLightManipContainer:new();
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
local EditLightManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditLightManipContainer"));
EditLightManipContainer:Property({"Name", "EditLightManipContainer", auto=true});
EditLightManipContainer:Property({"PenWidth", 0.01});
EditLightManipContainer:Property({"showGrid", true, "IsShowGrid", "SetShowGrid", auto=true});
EditLightManipContainer:Property({"mainColor", "#ffff00"});

function EditLightManipContainer:ctor()
	self:AddValue("position", {0,0,0});
end

function EditLightManipContainer:init(node)
	self.node = node;
	EditLightManipContainer._super.init(self);
	return self;
end

function EditLightManipContainer:createChildren()
	self.translateManip = self:AddTranslateManip();
	self.translateManip:SetFixOrigin(true);
	self.translateManip:SetRealTimeUpdate(false);
	self.translateManip:SetUpdatePosition(false);

	if self.node:isPointLight() or self.node:isSpotLight() then
		self.scaleManip = self:AddScaleManip();
		self.scaleManip:SetRealTimeUpdate(true);
		self.scaleManip.radius = 0.7;
		self.scaleManip:SetUniformScaling(true);
	end

	if self.node:isSpotLight() or self.node:isDirectionalLight() then
		self.rotateManip = self:AddRotateManip();
		self.rotateManip:SetRealTimeUpdate(true);
		self.rotateManip.radius = 1.2;
		self.rotateManip:SetYawPitchRollMode(true);
		self.rotateManip:SetYawEnabled(true);
		self.rotateManip:SetPitchEnabled(true);
		self.rotateManip:SetRollEnabled(true);
	end

	if self.node:isSpotLight() then
		self.thetaManip = self:AddRotateManip();
		self.thetaManip:SetRealTimeUpdate(true);
		self.thetaManip.radius = 0.4;
		self.thetaManip.yColor = "#ffffff";
		self.thetaManip:SetYawPitchRollMode(true);
		self.thetaManip:SetYawEnabled(true);
		self.thetaManip:SetPitchEnabled(false);
		self.thetaManip:SetRollEnabled(false);

		self.phiManip = self:AddRotateManip();
		self.phiManip:SetRealTimeUpdate(true);
		self.phiManip.radius = 0.7;
		self.phiManip.yColor = "#666666";
		self.phiManip:SetYawPitchRollMode(true);
		self.phiManip:SetYawEnabled(true);
		self.phiManip:SetPitchEnabled(false);
		self.phiManip:SetRollEnabled(false);
	end
end

function EditLightManipContainer:paintEvent(painter)
	EditLightManipContainer._super.paintEvent(self, painter);
	self.pen.width = self.PenWidth;
	painter:SetPen(self.pen);

	local node = self.node;
	if node then
		local nodeRangePlug = node:findPlug("Range");
		local range = nodeRangePlug:GetValue();

		local nodeDirPlug = node:findPlug("Direction");
		local dir = nodeDirPlug:GetValue();

		local nodePosPlug = node:findPlug("Position");
		local worldPos = nodePosPlug:GetValue();
		local camx,camy,camz = ParaCamera.GetPosition();
		local toCam = {camx - worldPos[1], camy - worldPos[2] - 0.5, camz - worldPos[3]}

		-- yellow color
		self:SetColorAndName(painter, "#ffff00");
		-- draw sphere edge facing to camera
		if self.node:isPointLight() then
			ShapesDrawer.DrawCircleEdge(painter, range, toCam[1], toCam[2], toCam[3], 0, 0, 0);
		end

		-- draw directional line
		if self.node:isSpotLight() or self.node:isDirectionalLight() then
			ShapesDrawer.DrawLine(painter, 0, 0, 0, dir[1] * range, dir[2] * range, dir[3] * range);
		end

		-- draw cone edge
		if self.node:isSpotLight() then
			local nodeThetaPlug = node:findPlug("Theta");
			local nodePhiPlug = node:findPlug("Phi");
			local theta = nodeThetaPlug:GetValue();
			local phi = nodePhiPlug:GetValue();
			theta = theta * 3.14 / 180;
			phi = phi * 3.14 / 180;

			local dirVec = vector3d:new(dir);
			local toCamVec = vector3d:new(toCam);
			local normal = toCamVec:cross(dirVec);
			normal:normalize();

			-- theta edge
			local sin_half_theta = math.sin(theta/2);
			local cos_half_theta = math.cos(theta/2);

			local first_edge = (dirVec * cos_half_theta + normal * sin_half_theta) * range;
			local second_edge = (dirVec * cos_half_theta - normal * sin_half_theta) * range;

			self:SetColorAndName(painter, "#ffffff");
			ShapesDrawer.DrawLine(painter, 0, 0, 0, first_edge[1], first_edge[2], first_edge[3]);
			ShapesDrawer.DrawLine(painter, 0, 0, 0, second_edge[1], second_edge[2], second_edge[3]);

			self:SetColorAndName(painter, "#ffff00");
			-- draw cone bottom circle of theta
			ShapesDrawer.DrawCircleEdge(painter, range * sin_half_theta, dir[1], dir[2], dir[3], dir[1] * cos_half_theta * range, dir[2] * cos_half_theta * range, dir[3] * cos_half_theta * range)

			-- phi edge
			local sin_half_phi = math.sin(phi/2);
			local cos_half_phi = math.cos(phi/2);

			local first_edge = (dirVec * cos_half_phi + normal * sin_half_phi) * range;
			local second_edge = (dirVec * cos_half_phi - normal * sin_half_phi) * range;

			self:SetColorAndName(painter, "#666666");
			ShapesDrawer.DrawLine(painter, 0, 0, 0, first_edge[1], first_edge[2], first_edge[3]);
			ShapesDrawer.DrawLine(painter, 0, 0, 0, second_edge[1], second_edge[2], second_edge[3]);

			self:SetColorAndName(painter, "#ffff00");
			-- draw cone bottom circle of phi
			ShapesDrawer.DrawCircleEdge(painter, range * sin_half_phi, dir[1], dir[2], dir[3], dir[1] * cos_half_phi * range, dir[2] * cos_half_phi * range, dir[3] * cos_half_phi * range)
		end
	end

end

function EditLightManipContainer:OnValueChange(name, value)
	EditLightManipContainer._super.OnValueChange(self);
	if(name == "position") then
		self:SetPosition(unpack(value));
	end
end

function EditLightManipContainer:connectToDependNode(node)
	self.node = node;

	local nodePosPlug = node:findPlug("Position");
	local parentManipPosPlug = self:findPlug("position");
	self:addPlugToManipConversionCallback(parentManipPosPlug, function(self, manipPlug)
		local p = nodePosPlug:GetValue();
		return {p[1], p[2]+0.5, p[3]};
	end);

	-- ATTENTION: trick part about position
	local manipPosPlug = self.translateManip:findPlug("position");

	self:addManipToPlugConversionCallback(nodePosPlug, function(self, nodePlug)
		local pos = nodePosPlug:GetValue();
		local offsetPos = manipPosPlug:GetValue();
		self.translateManip:SetField("position", {0, 0, 0});
		return {pos[1]+offsetPos[1], pos[2]+offsetPos[2], pos[3]+offsetPos[3]};
	end);


	if self.node:isPointLight() or self.node:isSpotLight() then
		local nodeRangePlug = node:findPlug("Range");
		local manipScalePlug = self.scaleManip:findPlug("scaling");

		self:addManipToPlugConversionCallback(nodeRangePlug, function(self, plug)
			return manipScalePlug:GetValue()[1] or 1;
		end);
		self:addPlugToManipConversionCallback(manipScalePlug, function(self, manipPlug)
			local scaling = nodeRangePlug:GetValue() or 1;
			if(type(scaling) == "number") then
				scaling = {scaling, scaling, scaling};
			end
			return scaling;
		end);
	end
	

	local degToRad = function(deg)
		return deg * 3.14 / 180;
	end
	local radToDeg = function(rad)
		return rad * 180 / 3.14;
	end

	if self.node:isSpotLight() or self.node:isDirectionalLight() then
		local nodeYawPlug = node:findPlug("Yaw");
		local manipYawPlug = self.rotateManip:findPlug("yaw");

		self:addManipToPlugConversionCallback(nodeYawPlug, function(self, plug)
			return radToDeg(manipYawPlug:GetValue() or 0);
		end);
		self:addPlugToManipConversionCallback(manipYawPlug, function(self, manipPlug)
			return degToRad(nodeYawPlug:GetValue() or 0);
		end);

		local nodePitchPlug = node:findPlug("Pitch");
		local manipPitchPlug = self.rotateManip:findPlug("pitch");

		self:addManipToPlugConversionCallback(nodePitchPlug, function(self, plug)
			return radToDeg(manipPitchPlug:GetValue() or 0);
		end);
		self:addPlugToManipConversionCallback(manipPitchPlug, function(self, manipPlug)
			return degToRad(nodePitchPlug:GetValue() or 0);
		end);

		local nodeRollPlug = node:findPlug("Roll");
		local manipRollPlug = self.rotateManip:findPlug("roll");

		self:addManipToPlugConversionCallback(nodeRollPlug, function(self, plug)
			return radToDeg(manipRollPlug:GetValue() or 0);
		end);
		self:addPlugToManipConversionCallback(manipRollPlug, function(self, manipPlug)
			return degToRad(nodeRollPlug:GetValue() or 0);
		end);
	end

	if self.node:isSpotLight() then
		local nodeThetaPlug = node:findPlug("Theta");
		local manipThetaPlug = self.thetaManip:findPlug("yaw");

		self:addManipToPlugConversionCallback(nodeThetaPlug, function(self, plug)
			return radToDeg(manipThetaPlug:GetValue() or 0);
		end);
		self:addPlugToManipConversionCallback(manipThetaPlug, function(self, manipPlug)
			return degToRad(nodeThetaPlug:GetValue() or 0);
		end);

		local nodePhiPlug = node:findPlug("Phi");
		local manipPhiPlug = self.phiManip:findPlug("yaw");

		self:addManipToPlugConversionCallback(nodePhiPlug, function(self, plug)
			return radToDeg(manipPhiPlug:GetValue() or 0);
		end);
		self:addPlugToManipConversionCallback(manipPhiPlug, function(self, manipPlug)
			return degToRad(nodePhiPlug:GetValue() or 0);
		end);
	end

	self:finishAddingManips();
	EditLightManipContainer._super.connectToDependNode(self, node);
end