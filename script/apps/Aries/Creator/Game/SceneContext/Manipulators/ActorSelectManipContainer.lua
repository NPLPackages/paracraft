--[[
Title: Actor/Entity Select Manipulator
Author(s): LiXizhi@yeah.net
Date: 2016/1/28
Desc: actor/entity selection. Display bounding sphere at the bottom. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/ActorSelectManipContainer.lua");
local ActorSelectManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.ActorSelectManipContainer");
local manipCont = ActorSelectManipContainer:new();
manipCont:init();
self:AddManipulator(manipCont);
manipCont:connectToDependNode(entity);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/ManipContainer.lua");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local ActorSelectManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.ActorSelectManipContainer"));
ActorSelectManipContainer:Property({"Name", "ActorSelectManipContainer", auto=true});
ActorSelectManipContainer:Property({"EnablePicking", false});
ActorSelectManipContainer:Property({"PenWidth", 0.01});
ActorSelectManipContainer:Property({"mainColor", "#ffff00"});
-- attribute name for position on the dependent node that we will bound to. it should be vector3d type like {0,0,0}
ActorSelectManipContainer:Property({"PositionPlugName", "position", auto=true});

function ActorSelectManipContainer:ctor()
	self:AddValue("position", {0,0,0});
end

function ActorSelectManipContainer:paintEvent(painter)
	if(self.node and self.node.IsVisible and not self.node:IsVisible()) then
		return
	end
	ActorSelectManipContainer._super.paintEvent(self, painter);
	
	painter:SetPen(self.pen);

	self:SetColorAndName(painter, self.mainColor);

	local x,y,z = self:GetPosition();
	local dx, dy, dz = 0,0,0;
	local radius = 0.01;
	if(self.node and self.node.GetInnerObject) then
		local obj = self.node:GetInnerObject();
		if(obj) then
			local tx, ty, tz = obj:GetPosition();
			dx, dy, dz = tx-x, ty-y, tz-z;
			radius = obj:GetField("width", 0)*0.5;
			radius = math.max(0.01, radius);
		end
	end
	-- local radius = self:GetActorRadius();
	ShapesDrawer.DrawCircle(painter, dx, dy, dz, radius, "y", false, 10);
end

function ActorSelectManipContainer:GetActorRadius()
	local radius;
	if(self.node and self.node.GetBoundRadius) then
		radius = self.node:GetBoundRadius();
	end
	return math.max(0.2, radius or 0);
end

function ActorSelectManipContainer:OnValueChange(name, value)
	ActorSelectManipContainer._super.OnValueChange(self);
	if(name == "position") then
		self:SetPosition(unpack(value));
	end
end

-- @param node: it should be an entity object, etc. 
function ActorSelectManipContainer:connectToDependNode(node)
	local plugPos = node:findPlug(self.PositionPlugName);

	self.node = node;

	if(plugPos) then
		local manipPosPlug = self:findPlug("position");
		
		self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
			return plugPos:GetValue();
		end);
	end
	-- should be called only once after all conversion callbacks to setup real connections
	self:finishAddingManips();
	ActorSelectManipContainer._super.connectToDependNode(self, node);
end