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
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
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
EditModelManipContainer:Property({"PitchPlugName", "pitch", auto=true});
EditModelManipContainer:Property({"RollPlugName", "roll", auto=true});
EditModelManipContainer:Property({"OffsetPosPlugName", "offsetPos", auto=true});
EditModelManipContainer:Property({"AngleGridStep", math.pi / 12, "GetAngleGridStep", "SetAngleGridStep", auto=true});
EditModelManipContainer:Property({"SupportUndo", true, "IsSupportUndo", "SetSupportUndo", auto=true});
EditModelManipContainer:Property({"showRotation", true, "IsShowRotation", "ShowRotation", auto=true});
EditModelManipContainer:Property({"showScaling", true, "IsShowScaling", "ShowScaling", auto=true});

function EditModelManipContainer:ctor()
	self:AddValue("position", {0,0,0});
end

function EditModelManipContainer:createChildren()
	self.translateManip = self:AddTranslateManip();
	self.translateManip:SetFixOrigin(true);
	self.translateManip:SetShowGroundSnap(true);
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
	if(self.translateManip) then
		self.translateManip:SetVisible(bGlobalTransVisible)
		self.translateManip.enabled = bGlobalTransVisible
	end
	if(self.scaleManip and self:IsShowScaling()) then
		self.scaleManip:SetVisible(bGlobalTransVisible)
		self.scaleManip.enabled = bGlobalTransVisible
	end
	if(self.rotateManip and self:IsShowRotation()) then
		self.rotateManip:SetVisible(bGlobalTransVisible)
		self.rotateManip.enabled = bGlobalTransVisible
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
	local plugRoll = node:findPlug(self.RollPlugName);
	local plugPitch = node:findPlug(self.PitchPlugName);
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

			-- ctrl key to drag to copy and move. 
			local old_x, old_y, old_z;
			local old_facing;
			local old_linkTo;
			self.translateManip:Connect("modifyBegun", function()
				if(node.GetLinkToName) then
					old_x, old_y, old_z = node:GetPosition()
					old_facing = node:GetFacing();
					old_linkTo = node:GetLinkToName();
				end
			end)
			
			self.translateManip:Connect("modifyEnded", function()
				
				if(self:SnapshotToHistory()) then
					if(old_x and Keyboard:IsCtrlKeyPressed() and node:isa(EntityManager.EntityLiveModel) and node.CloneMe) then
						-- Ctrl + drag to copy and move the entity
						local entity = node:CloneMe()
						entity:SetPosition(old_x, old_y, old_z);
						entity:SetFacing(old_facing);
						if(old_linkTo) then
							entity:LinkToEntityByName(old_linkTo)
						end
						-- add entity to undo history
						if(GameLogic.GameMode:IsEditor()) then
							NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
							local task = MyCompany.Aries.Game.Tasks.DragEntity:new({nohistory=true})
							task:CreateEntity(entity)
							local lastOne = self:GetHistoryItem(-1);
							if(lastOne) then
								lastOne.batchedTask = task
							end
						end
					end
				end
			end)
			
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
				return {x, y, z};
			end);
		end

		-- two-way binding for scaling conversion:
		if(plugScale and self:IsShowScaling()) then
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
		else
			self.scaleManip:SetVisible(false)
			self.scaleManip.enabled = false
		end

		-- two-way binding for yaw conversion:
		if(plugYaw and self:IsShowRotation()) then
			self.rotateManip:SetGridStep(self:GetAngleGridStep());

			local manipYawPlug = self.rotateManip:findPlug("yaw");
			self:addManipToPlugConversionCallback(plugYaw, function(self, plug)
				commonlib.TimerManager.SetTimeout(function() self:SnapshotToHistory() end, 1000)
				return manipYawPlug:GetValue() or 0;
			end);
			self:addPlugToManipConversionCallback(manipYawPlug, function(self, manipPlug)
				return plugYaw:GetValue() or 0;
			end);

			if(plugPitch) then
				local manipPitchPlug = self.rotateManip:findPlug("pitch");
				self:addManipToPlugConversionCallback(plugPitch, function(self, plug)
					commonlib.TimerManager.SetTimeout(function() self:SnapshotToHistory() end, 1000)
					return manipPitchPlug:GetValue() or 0;
				end);
				self:addPlugToManipConversionCallback(manipPitchPlug, function(self, manipPlug)
					return plugPitch:GetValue() or 0;
				end);
			end

			if(plugRoll) then
				local manipRollPlug = self.rotateManip:findPlug("roll");
				self:addManipToPlugConversionCallback(plugRoll, function(self, plug)
					commonlib.TimerManager.SetTimeout(function() self:SnapshotToHistory() end, 1000)
					return manipRollPlug:GetValue() or 0;
				end);
				self:addPlugToManipConversionCallback(manipRollPlug, function(self, manipPlug)
					return plugRoll:GetValue() or 0;
				end);
			end
			if((plugRoll and plugRoll:GetValue() ~= 0) or (plugPitch and plugPitch:GetValue() ~= 0)) then
				self.rotateManip:SetPitchEnabled(true);
				self.rotateManip:SetRollEnabled(true);
			end
		else
			self.rotateManip:SetVisible(false)
			self.rotateManip.enabled = false
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

-- @return true if added to history
function EditModelManipContainer:SnapshotToHistory()
	if(self:IsSupportUndo()) then
		self.history = self.history or {}
		local lastItem = self:GetHistoryItem()
		local newItem = {self.node:SaveToXMLNode()};
		-- remove duplicated calls
		if(not lastItem or not commonlib.compare(newItem[1], lastItem[1])) then
			self.history[#(self.history) + 1] = newItem;
			return true
		end
	end
end

-- @param offsetFromTop: default to 0, which is the top most one. this can be -1 to fetch the one before top most one
function EditModelManipContainer:GetHistoryItem(offsetFromTop)
	return self.history and self.history[#(self.history) + (offsetFromTop or 0)];
end

function EditModelManipContainer:Undo()
	local historyItem = self:GetHistoryItem()
	local xmlNode = historyItem and historyItem[1];
	if(xmlNode and self.node) then
		local lastItem = xmlNode
		local newItem = self.node:SaveToXMLNode();
		local isLastOne;
		if(commonlib.compare(newItem, lastItem)) then
			if(#(self.history) > 1) then
				self.history[#(self.history)] = nil;
				historyItem = self:GetHistoryItem()
				xmlNode = historyItem[1]
			else
				isLastOne = true;
			end
		end
		if(historyItem.batchedTask) then
			historyItem.batchedTask:Undo()
			historyItem.batchedTask = nil;
		end
		if(not isLastOne) then
			-- always preserve last one and pop others. 
			if(#(self.history) > 1) then
				self.history[#(self.history)] = nil;
			end
			self.node:UpdateFromXMLNode(xmlNode)
			self.node:valueChanged();
		end
	end
	return true
end

function EditModelManipContainer:Redo()
	return true
end

function EditModelManipContainer:ToggleRotationMode()
	if(self.rotateManip) then
		local isEnabled = not self.rotateManip:IsPitchEnabled()
		self.rotateManip:SetPitchEnabled(isEnabled);
		self.rotateManip:SetRollEnabled(isEnabled);
	end
end

-- virtual: actually means key stroke. 
function EditModelManipContainer:keyPressEvent(event)
	local keyname = event.keyname;
	if(keyname == "DIK_3") then
		self:ToggleRotationMode();
	end
	if(self:IsSupportUndo()) then
		local keyseq = event:GetKeySequence();
		if(keyseq == "Undo") then
			if(self:Undo()) then
				event:accept()
			end
		elseif(keyseq == "Redo") then
			if(self:Redo()) then
				event:accept()
			end
		end
	end
end