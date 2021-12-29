--[[
Title: Edit Model Manipulator
Author(s): LiXizhi@yeah.net
Date: 2016/8/30
Desc: Manipulator for EntityBlockModel and EntityLiveModel
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
EditModelManipContainer:Property({"AngleGridStep", math.pi / 12, "GetAngleGridStep", "SetAngleGridStep", auto=true});
EditModelManipContainer:Property({"SupportUndo", true, "IsSupportUndo", "SetSupportUndo", auto=true});

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
	self.rotateManip:SetGridStep(self:GetAngleGridStep());
	self:AddMountPointsManip()
end

function EditModelManipContainer:AddMountPointsManip()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/MountPointsManip.lua");
	local MountPointsManip = commonlib.gettable("MyCompany.Aries.Game.Manipulators.MountPointsManip");
	self.mountPointsManip = MountPointsManip:new():init(self);
	self.mountPointsManip:Connect("valueChanged",  self, self.valueChanged);
	self.mountPointsManip:Connect("mountPointChanged",  self, self.OnSelectMountPoint, "UniqueConnection");
end

function EditModelManipContainer:OnSelectMountPoint(name)
	local bGlobalTransVisible = (name == nil)
	if(self.scaleManip) then
		self.translateManip:SetVisible(bGlobalTransVisible)
		self.translateManip.enabled = bGlobalTransVisible
		self.rotateManip:SetVisible(bGlobalTransVisible)
		self.rotateManip.enabled = bGlobalTransVisible
		self.scaleManip:SetVisible(bGlobalTransVisible)
		self.scaleManip.enabled = bGlobalTransVisible
	end
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
		if(node.BeginModify and node.EndModify) then
			self.mountPointsManip:Connect("modifyBegun",  node, node.BeginModify);
			self.mountPointsManip:Connect("modifyEnded",  node, node.EndModify);
		end
		if(node.GetMountPoints) then
			self.mountPointsManip:ShowForEntity(node);
		end

		-- one way binding 
		local manipPosPlug = self:findPlug("position");

		-- two-way binding for offset position conversion:
		if(plugOffsetPos) then
			self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
				return plugPos:GetValue() + plugOffsetPos:GetValue();
			end);
			local manipTranslatePlug = self.translateManip:findPlug("position");
			self:addManipToPlugConversionCallback(plugOffsetPos, function(self, plug)
				return manipTranslatePlug:GetValue() - plugPos:GetValue();
			end);
			self:addPlugToManipConversionCallback(manipTranslatePlug, function(self, manipPlug)
				local pos = plugOffsetPos:GetValue();
				return pos + plugPos:GetValue();
			end);
		else
			-- use global position if offset pos not found, such as for EntityLiveModel 
			self.translateManip:SetRealTimeUpdate(false);
			self.translateManip:SetUpdatePosition(false);
			self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
				return plugPos:GetValue();
			end);
			local manipTranslatePlug = self.translateManip:findPlug("position");
			self:addManipToPlugConversionCallback(plugPos, function(self, plug)
				local offsetPos = manipTranslatePlug:GetValue();
				local pos = plugPos:GetValue();
				local x, y, z = pos[1]+offsetPos[1], pos[2]+offsetPos[2], pos[3]+offsetPos[3]
				-- tricky: we SetRealTimeUpdate to false, and use offset from manipulator and then set manipulator's value back to 0
				self.translateManip:SetField("position", {0, 0, 0});
				commonlib.TimerManager.SetTimeout(function() self:SnapshotToHistory() end, 1000)
				return {x, y, z};
			end);
		end

		-- two-way binding for scaling conversion:
		if(plugScale) then
			local manipScalePlug = self.scaleManip:findPlug("scaling");
			self:addManipToPlugConversionCallback(plugScale, function(self, plug)
				commonlib.TimerManager.SetTimeout(function() self:SnapshotToHistory() end, 1000)
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
			self.rotateManip:SetGridStep(self:GetAngleGridStep());

			local manipYawPlug = self.rotateManip:findPlug("yaw");
			self:addManipToPlugConversionCallback(plugYaw, function(self, plug)
				commonlib.TimerManager.SetTimeout(function() self:SnapshotToHistory() end, 1000)
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

	self:SnapshotToHistory()
end

function EditModelManipContainer:SnapshotToHistory()
	if(self:IsSupportUndo()) then
		self.history = self.history or {}
		-- TODO: remove duplicated calls
		local lastItem = self:GetHistoryItem()
		local newItem = self.node:SaveToXMLNode();
		if(not lastItem or not commonlib.compare(newItem, lastItem)) then
			self.history[#(self.history) + 1] = newItem;
		end
	end
end

function EditModelManipContainer:GetHistoryItem()
	return self.history and self.history[#(self.history)];
end

function EditModelManipContainer:Undo()
	local xmlNode = self:GetHistoryItem()
	if(xmlNode and self.node) then
		local lastItem = xmlNode
		local newItem = self.node:SaveToXMLNode();
		if(commonlib.compare(newItem, lastItem)) then
			if(#(self.history) > 1) then
				self.history[#(self.history)] = nil;
				xmlNode = self:GetHistoryItem()
			else
				return true;
			end
		end
		-- always preserve last one and pop others. 
		if(#(self.history) > 1) then
			self.history[#(self.history)] = nil;
		end
		self.node:UpdateFromXMLNode(xmlNode)
	end
	return true
end

function EditModelManipContainer:Redo()
	return true
end

-- virtual: actually means key stroke. 
function EditModelManipContainer:keyPressEvent(key_event)
	if(self:IsSupportUndo()) then
		local keyseq = key_event:GetKeySequence();
		if(keyseq == "Undo") then
			if(self:Undo()) then
				key_event:accept()
			end
		elseif(keyseq == "Redo") then
			if(self:Redo()) then
				key_event:accept()
			end
		end
	end
end