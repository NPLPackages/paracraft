--[[
Title: Quad Manipulator
Author(s): LiXizhi@yeah.net
Date: 2021/6/6
Desc: quad node in a quad tree, such as used in BoxTrigger.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/QuadManipContainer.lua");
local QuadManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.QuadManipContainer");
local manipCont = QuadManipContainer:new();
manipCont:init();
self:AddManipulator(manipCont);
manipCont:connectToDependNode(boxTrigger);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/ManipContainer.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local QuadManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.QuadManipContainer"));
QuadManipContainer:Property({"mainColor", "#00ffff"});
QuadManipContainer:Property({"Name", "QuadManipContainer", auto=true});

function QuadManipContainer:ctor()
	self.offsetX = 0;
	self.offsetZ = 0;

	self.dx = 1;
	self.dz = 1;
end


function QuadManipContainer:paintEvent(painter)
	if(self.node and self.node.IsVisible and not self.node:IsVisible()) then
		return
	end
	QuadManipContainer._super.paintEvent(self, painter);
	
	painter:SetPen(self.pen);
	self:SetColorAndName(painter, self.mainColor);
	ShapesDrawer.DrawAABB(painter, self.offsetX, -0.5, self.offsetZ, self.offsetX+self.dx, 3, self.offsetZ+self.dz, false)
end

-- @param node: it should be an QuadObject
function QuadManipContainer:connectToDependNode(object)
	self.object = object;
	local x, y, z = object:GetPosition()
	
	local minX, minZ = object:GetLeftTopWorldPos()
	local maxX, maxZ = object:GetRightBottomWorldPos()
	x = (minX + maxX) / 2 
	z = (minZ + maxZ) / 2 
	self:SetPosition(x, y, z)
	self.offsetX = minX - x;
	self.offsetZ = minZ - z;
	self.dx = maxX - minX;
	self.dz = maxZ - minZ;
	self:SetBoundRadius(math.sqrt(self.dx ^ 2 + self.dz ^2) / 2)
end