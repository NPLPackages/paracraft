--[[
Title: Actor Link Manipulator
Author(s): LiXizhi@yeah.net
Date: 2016/5/23
Desc: relative move, rotate to parent actor.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/ParentLinkManipContainer.lua");
local ParentLinkManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.ParentLinkManipContainer");
local manipCont = ParentLinkManipContainer:new();
manipCont:init();
self:AddManipulator(manipCont);
manipCont:connectToDependNode(actor);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/ManipContainer.lua");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local ParentLinkManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.ParentLinkManipContainer"));
ParentLinkManipContainer:Property({"Name", "ParentLinkManipContainer", auto=true});
ParentLinkManipContainer:Property({"PenWidth", 0.01});
ParentLinkManipContainer:Property({"mainColor", "#ffff00"});
ParentLinkManipContainer:Property({"IKHandleColor", "#00ffff"});
ParentLinkManipContainer:Property({"showGrid", false, "IsShowGrid", "SetShowGrid", auto=true});
ParentLinkManipContainer:Property({"snapToGrid", false, "IsSnapToGrid", "SetSnapToGrid", auto=true});
ParentLinkManipContainer:Property({"gridSize", 0.1, "GetGridSize", "SetGridSize", auto=true});
ParentLinkManipContainer:Property({"gridOffset", {0,0,0}, "GetGridOffset", "SetGridOffset", auto=true});

function ParentLinkManipContainer:ctor()
	self:AddValue("position", {0,0,0});
end

function ParentLinkManipContainer:createChildren()
	self.translateManip = self:AddTranslateManip();
	self.translateManip:SetShowGrid(self:IsShowGrid());
	self.translateManip:SetSnapToGrid(self:IsSnapToGrid());
	self.translateManip:SetGridSize(self:GetGridSize());
	self.translateManip:SetUpdatePosition(false);
	self.translateManip:SetFixOrigin(true);
	self.rotateManip = self:AddRotateManip();
end

function ParentLinkManipContainer:paintEvent(painter)
	ParentLinkManipContainer._super.paintEvent(self, painter);

	painter:SetPen(self.pen);

	if(self.actor) then
		local parent, curTime, parentActor, keypath = self.actor:GetParentLink();
		if(keypath and parentActor and parentActor.ComputeWorldTransform)then
			local p_x, p_y, p_z, p_roll, p_pitch, p_yaw = parentActor:ComputeWorldTransform(keypath, curTime);
			if(p_x) then
				-- draw parent pivot location.
				local x,y,z = self:GetPosition();
				local px,py,pz = p_x-x, p_y-y, p_z-z;
				self:SetColorAndName(painter, self.IKHandleColor);
				ShapesDrawer.DrawLine(painter, 0,0,0, px,py,pz);
				painter:TranslateMatrix(px,py,pz);
				local length = 0.2;
				ShapesDrawer.DrawLine(painter, 0,0,0, length,0,0);
				ShapesDrawer.DrawLine(painter, 0,0,0, 0,length,0);
				ShapesDrawer.DrawLine(painter, 0,0,0, 0,0,length);
				painter:TranslateMatrix(-px,-py,-pz);
			end
		end
	end
end

function ParentLinkManipContainer:UpdateFromParentTransform()
	if(self.actor) then
		local parent, curTime, parentActor, keypath = self.actor:GetParentLink();
		if(keypath and parentActor and parentActor.ComputeWorldTransform)then
			local p_x, p_y, p_z, p_roll, p_pitch, p_yaw = parentActor:ComputeWorldTransform(keypath, curTime);
			if(p_roll) then
				-- prepare and draw child manipulators 
				self.quat = self.quat or mathlib.Quaternion:new();
				self.quat:FromEulerAngles(p_yaw, p_roll, p_pitch);
				self.localTrans = self.quat:ToRotationMatrix(self.localTrans);
				self.translateManip:SetLocalTransform(self.localTrans);
				self.rotateManip:SetLocalTransform(self.localTrans);
			end
		end
	end
end

function ParentLinkManipContainer:OnValueChange(name, value)
	ParentLinkManipContainer._super.OnValueChange(self);
	if(name == "position") then
		self:SetPosition(unpack(value));
		self:UpdateFromParentTransform();
	end
end

-- @param node: it should be an actor object, etc. 
function ParentLinkManipContainer:connectToDependNode(actor)
	self.actor = actor;
	-- tracking the position of the actor's entity
	local node = actor:GetEntity();
	local plugEntityPos = node:findPlug("position");
	local parentLinkPlug = actor:findPlug("parent");
	if(plugEntityPos and parentLinkPlug) then
		local manipPosPlug = self:findPlug("position");
		-- connect parent.rot to rotateManip's yaw, pitch, roll
		local manipYawPlug = self.rotateManip:findPlug("yaw");
		local manipPitchPlug = self.rotateManip:findPlug("pitch");
		local manipRollPlug = self.rotateManip:findPlug("roll");

		if(actor.BeginModify and actor.EndModify) then
			self.translateManip:Connect("modifyBegun",  actor, actor.BeginModify);
			self.translateManip:Connect("modifyEnded",  actor, actor.EndModify);
			self.rotateManip:Connect("modifyBegun",  actor, actor.BeginModify);
			self.rotateManip:Connect("modifyEnded",  actor, actor.EndModify);
		end
	
		-- connect entity's current position to the container's position.
		self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
			return plugEntityPos:GetValue();
		end);

		-- connect parent.pos to translateManip's position
		local manipLocalPosPlug = self.translateManip:findPlug("position");
		self:addPlugToManipConversionCallback(manipLocalPosPlug, function(self, manipPlug)
			local parent = self.actor:GetParentLink();
			return (parent and parent.pos or {0,0,0});
		end);
		
		-- connect parent.rot to rotateManip's yaw, pitch, roll
		self:addPlugToManipConversionCallback(manipYawPlug, function(self, manipPlug)
				local parent = self.actor:GetParentLink();
				return (parent and parent.rot and parent.rot[3] or 0);
			end);
		self:addPlugToManipConversionCallback(manipPitchPlug, function(self, manipPlug)
				local parent = self.actor:GetParentLink();
				return (parent and parent.rot and parent.rot[2] or 0);
			end);
		self:addPlugToManipConversionCallback(manipRollPlug, function(self, manipPlug)
				local parent = self.actor:GetParentLink();
				return (parent and parent.rot and parent.rot[1] or 0);
			end);

		-- finally if either translation or rotation manipulator changes, update parent link's local pos and rot.
		self:addManipToPlugConversionCallback(parentLinkPlug, function(self, plug)
			local parent = commonlib.clone(self.actor:GetParentLink());
			if(parent) then
				parent.pos = commonlib.clone(manipLocalPosPlug:GetValue());
				parent.rot = {manipRollPlug:GetValue(), manipPitchPlug:GetValue(), manipYawPlug:GetValue()};
			else
				parent = {pos={0,0,0}, rot={0,0,0}};
			end
			return parent;
		end);
	end
	ParentLinkManipContainer._super.connectToDependNode(self, node);
end