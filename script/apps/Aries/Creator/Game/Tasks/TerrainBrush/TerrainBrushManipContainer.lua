--[[
Title: Terrain Brush Manipulator
Author(s): LiXizhi@yeah.net
Date: 2016/7/15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/TerrainBrushManipContainer.lua");
local TerrainBrushManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.TerrainBrushManipContainer");
local manipCont = TerrainBrushManipContainer:new();
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
local TerrainBrushManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.TerrainBrushManipContainer"));
TerrainBrushManipContainer:Property({"Name", "TerrainBrushManipContainer", auto=true});
TerrainBrushManipContainer:Property({"EnablePicking", false});
TerrainBrushManipContainer:Property({"PenWidth", 0.01});
TerrainBrushManipContainer:Property({"showGrid", true, "IsShowGrid", "SetShowGrid", auto=true});
TerrainBrushManipContainer:Property({"mainColor", "#ffff00"});
-- attribute name for position on the dependent node that we will bound to. it should be vector3d type like {0,0,0}
TerrainBrushManipContainer:Property({"PositionPlugName", "position", auto=true});
TerrainBrushManipContainer:Property({"RadiusPlugName", "pen_radius", auto=true});

function TerrainBrushManipContainer:ctor()
	self:AddValue("position", {0,0,0});
end

function TerrainBrushManipContainer:createChildren()
	-- self.scaleManip = self:AddScaleManip();
	-- self.translateManip = self:AddTranslateManip();
end

function TerrainBrushManipContainer:paintEvent(painter)
	TerrainBrushManipContainer._super.paintEvent(self, painter);
	
	local isDrawingPickable = self:IsPickingPass();
	if(isDrawingPickable) then
		return;
	end

	painter:SetPen(self.pen);

	self:SetColorAndName(painter, self.mainColor);

	local x,y,z = self:GetPosition();
	local radius = self:GetRadius();
	ShapesDrawer.DrawCircle(painter, 0, 0, 0, radius * BlockEngine.blocksize, "y", false, 8);

	-- TODO: draw more accurate border & hint according to terrain blocks.
	local cx, cy, cz = BlockEngine:block(x,y-0.1,z);

	-- show grid line
	if(self:IsShowGrid()) then
		-- self:SetColorAndName(painter, self.gridColor);
		local moveDir = self:GetMoveDirByAxis();
		for i=0, radius do
			local gx = moveDir[1]*i*BlockEngine.blocksize;
			local gy = moveDir[2]*i*BlockEngine.blocksize;
			local gz = moveDir[3]*i*BlockEngine.blocksize;
			ShapesDrawer.DrawCube(painter, gx, gy, gz, 0.02, true);
		end
		if(self.isDrawRadiusText) then
			painter:PushMatrix();
			painter:TranslateMatrix(0,1,0);
			painter:LoadBillboardMatrix();
			painter:DrawTextScaled(0, 0, format("r=%s",radius), self.textScale*2);
			painter:PopMatrix();
		end
	end
end

local axis_dirs = {
	x = vector3d:new({-1,0,0}),
	y = vector3d:new({0,1,0}),
	z = vector3d:new({0,0,1}),
}
-- @param axis: "x|y|z". default to x
-- @return vector3d
function TerrainBrushManipContainer:GetMoveDirByAxis(axis)
	return axis_dirs[axis or "x"];
end


function TerrainBrushManipContainer:GetRadius()
	local radius;
	if(self.node and self.node.GetPenRadius) then
		radius = self.node:GetPenRadius();
	end
	return radius or 1;
end

function TerrainBrushManipContainer:OnValueChange(name, value)
	TerrainBrushManipContainer._super.OnValueChange(self);
	if(name == "position") then
		self:SetPosition(unpack(value));
	end
end

-- @param node: it should be ItemTerrainBrush object. 
function TerrainBrushManipContainer:connectToDependNode(node)
	local plugPos = node:findPlug(self.PositionPlugName);
	local plugScale = node:findPlug(self.RadiusPlugName);

	self.node = node;

	if(plugPos and plugScale) then
		-- one way binding 
		local manipPosPlug = self:findPlug("position");
		self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
			return plugPos:GetValue():clone();
		end);

		-- two-way binding for scaling(pen_radius) conversion:
		--local manipScalePlug = self.scaleManip:findPlug("scaling");
		--self:addManipToPlugConversionCallback(plugScale, function(self, plug)
			--return manipScalePlug:GetValue();
		--end);
		--self:addPlugToManipConversionCallback(manipScalePlug, function(self, manipPlug)
			--local scaling = plugScale:GetValue() or 1;
			--if(type(scaling) == "number") then
				--scaling = {scaling, scaling, scaling};
			--end
			--return scaling;
		--end);
	end
	-- should be called only once after all conversion callbacks to setup real connections
	self:finishAddingManips();
	TerrainBrushManipContainer._super.connectToDependNode(self, node);
end