--[[
Title: Edit Code Actor Manipulator
Author(s): LiXizhi@yeah.net
Date: 2019/1/31
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditCodeActorManipContainer.lua");
local EditCodeActorManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditCodeActorManipContainer");
local manipCont = EditCodeActorManipContainer:new();
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
local EditCodeActorManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditCodeActorManipContainer"));
EditCodeActorManipContainer:Property({"Name", "EditCodeActorManipContainer", auto=true});
-- EditCodeActorManipContainer:Property({"EnablePicking", true});
EditCodeActorManipContainer:Property({"PenWidth", 0.01});
EditCodeActorManipContainer:Property({"showGrid", true, "IsShowGrid", "SetShowGrid", auto=true});
EditCodeActorManipContainer:Property({"mainColor", "#ffff00"});
-- attribute name for position on the dependent node that we will bound to. it should be vector3d type like {0,0,0}
EditCodeActorManipContainer:Property({"PositionPlugName", "pos", auto=true});
EditCodeActorManipContainer:Property({"ScalePlugName", "scaling", auto=true});
EditCodeActorManipContainer:Property({"YawPlugName", "yaw", auto=true});
EditCodeActorManipContainer:Property({"PitchPlugName", "pitch", auto=true});
EditCodeActorManipContainer:Property({"RollPlugName", "roll", auto=true});

function EditCodeActorManipContainer:ctor()
	self:AddValue("position", {0,0,0});
end

function EditCodeActorManipContainer:createChildren()
	self.translateManip = self:AddTranslateManip();
	self.translateManip:SetFixOrigin(true);
	self.translateManip:SetRealTimeUpdate(false);
	self.translateManip:SetUpdatePosition(false);

	self.scaleManip = self:AddScaleManip();
	self.scaleManip.radius = 0.5;
	self.scaleManip:SetUniformScaling(true);
	self.rotateManip = self:AddRotateManip();
	self.rotateManip:SetYawPitchRollMode(true);
	self.rotateManip:SetYawEnabled(true);
	self.rotateManip:SetPitchEnabled(true);
	self.rotateManip:SetRollEnabled(true);
	self.rotateManip:SetInitialVector({1,0,0})
	self.rotateManip:SetShowVector(true);
end

function EditCodeActorManipContainer:paintEvent(painter)
	EditCodeActorManipContainer._super.paintEvent(self, painter);
end

function EditCodeActorManipContainer:OnValueChange(name, value)
	EditCodeActorManipContainer._super.OnValueChange(self);
	if(name == "position") then
		self:SetPosition(unpack(value));
	end
end

-- @param node: it should be EntityBlockModel object. 
function EditCodeActorManipContainer:connectToDependNode(node)
	local plugPos = node:findPlug(self.PositionPlugName);
	local plugScale = node:findPlug(self.ScalePlugName);
	local plugYaw = node:findPlug(self.YawPlugName);
	local plugPitch = node:findPlug(self.PitchPlugName);
	local plugRoll = node:findPlug(self.RollPlugName);
	
	self.node = node;

	if(plugPos) then
		-- two way binding 
		local manipPosPlug = self:findPlug("position");
		local manipTranslatePlug = self.translateManip:findPlug("position");
		self:addManipToPlugConversionCallback(plugPos, function(self, plug)
			local offsetPos = manipTranslatePlug:GetValue();
			local pos = plugPos:GetValue();
			local x, y, z = pos[1]+BlockEngine:block_float(offsetPos[1]), pos[2]+BlockEngine:block_float(offsetPos[2]), pos[3]+BlockEngine:block_float(offsetPos[3])
			-- tricky: we SetRealTimeUpdate to false, and use offset from manipulator and then set manipulator's value back to 0
			self.translateManip:SetField("position", {0, 0, 0});
			return {x, y, z};
		end);
		self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
			local pos = plugPos:GetValue();
			local x, y, z = BlockEngine:real_min(pos[1]+0.5, pos[2], pos[3]+0.5)
			return {x, y, z};
		end);
		
		
		-- two-way binding for scaling conversion:
		if(plugScale) then
			local manipScalePlug = self.scaleManip:findPlug("scaling");
			self:addManipToPlugConversionCallback(plugScale, function(self, plug)
				return (manipScalePlug:GetValue()[1] or 1)*100;
			end);
			self:addPlugToManipConversionCallback(manipScalePlug, function(self, manipPlug)
				local scaling = (plugScale:GetValue() or 100)/100;
				scaling = {scaling, scaling, scaling};
				return scaling;
			end);
		end

		-- two-way binding for yaw conversion:
		if(plugYaw) then
			local manipYawPlug = self.rotateManip:findPlug("yaw");
			self:addManipToPlugConversionCallback(plugYaw, function(self, plug)
				return math.floor((manipYawPlug:GetValue() or 0)/3.14*180 + 0.5);
			end);
			self:addPlugToManipConversionCallback(manipYawPlug, function(self, manipPlug)
				return (plugYaw:GetValue() or 0)/180*3.14;
			end);
		end
		if(plugRoll) then
			local manipRollPlug = self.rotateManip:findPlug("roll");
			self:addManipToPlugConversionCallback(plugRoll, function(self, plug)
				return math.floor((manipRollPlug:GetValue() or 0)/3.14*180 + 0.5);
			end);
			self:addPlugToManipConversionCallback(manipRollPlug, function(self, manipPlug)
				return (plugRoll:GetValue() or 0)/180*3.14;
			end);
		end
		if(plugPitch) then
			local manipPitchPlug = self.rotateManip:findPlug("pitch");
			self:addManipToPlugConversionCallback(plugPitch, function(self, plug)
				return math.floor((manipPitchPlug:GetValue() or 0)/3.14*180 + 0.5);
			end);
			self:addPlugToManipConversionCallback(manipPitchPlug, function(self, manipPlug)
				return (plugPitch:GetValue() or 0)/180*3.14;
			end);
		end
	end
	-- should be called only once after all conversion callbacks to setup real connections
	self:finishAddingManips();
	EditCodeActorManipContainer._super.connectToDependNode(self, node);
end