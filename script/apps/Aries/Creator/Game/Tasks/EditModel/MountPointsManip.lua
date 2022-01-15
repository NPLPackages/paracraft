--[[
Title: MountPointsManip
Author(s): LiXizhi@yeah.net
Date: 2021/12/5
Desc: MountPointsManip is manipulator for editing mount points in entity

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/MountPointsManip.lua");
local MountPointsManip = commonlib.gettable("MyCompany.Aries.Game.Manipulators.MountPointsManip");
local manip = MountPointsManip:new():init();
manip:SetPosition(x,y,z);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/Manipulator.lua");
NPL.load("(gl)script/ide/math/Plane.lua");
NPL.load("(gl)script/ide/math/Quaternion.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/MountPoint.lua");
local MountPoint = commonlib.gettable("MyCompany.Aries.Game.Common.MountPoint");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local Color = commonlib.gettable("System.Core.Color");
local Plane = commonlib.gettable("mathlib.Plane");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local MountPointsManip = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.Manipulator"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.MountPointsManip"));

MountPointsManip:Property({"Name", "MountPointsManip", auto=true});
MountPointsManip:Property({"PenWidth", 0.001});
MountPointsManip:Property({"editColor", "#ff4264"});
MountPointsManip:Property({"AABBColor", "#00ffff"});
MountPointsManip:Property({"TextColor", "#663399"});
MountPointsManip:Property({"hoverAABBColor", "#88ffff"});
MountPointsManip:Property({"ShowMountPointName", false});
-- whether to update values during dragging
MountPointsManip:Property({"RealTimeUpdate", true, "IsRealTimeUpdate", "SetRealTimeUpdate", auto=true});
MountPointsManip:Property({"MountCount", 0, "GetMountCount"});
MountPointsManip:Property({"UIScaling", 1, "GetUIScaling", "SetUIScaling"});
-- default to nil, if not, the returned angle will always be snap to steps, such pi/2, pi/4, pi/6
MountPointsManip:Property({"GridStep", math.pi/12, "GetGridStep", "SetGridStep", auto=true});
-- each mount point has trans, scale, rotate three variables. when mountpoint is changed, varNameChanged is always changed. 
MountPointsManip:Signal("mountPointChanged", function(mountpoint_name) end);

function MountPointsManip:ctor()
	self:AddValue("position", {0,0,0});
	-- array of mountpoint attribute model
	self:SetZPassOpacity(0.5);
	self.mountpoints = {};
	self:AddValue("SelectedMountPointName", nil);
end

function MountPointsManip:SetUIScaling(scaling)
	if(self.UIScaling ~= scaling) then
		self.UIScaling = scaling;
		self:UpdateManipRadius(self.curManip);
	end
end

function MountPointsManip:GetUIScaling()
	return self.UIScaling or 1;
end

function MountPointsManip:GetPointByPickName(pickingName)
	for i, mountpoint in ipairs(self.mountpoints) do
		if(mountpoint.pickName == pickingName) then
			return mountpoint;
		end
	end
end

function MountPointsManip:HasPickingName(pickingName)
	for i, mountpoint in ipairs(self.mountpoints) do
		if(mountpoint.pickName == pickingName) then
			return true;
		end
	end
end

function MountPointsManip:GetMountPointByName(name)
	if(name) then
		for i, mountpoint in ipairs(self.mountpoints) do
			if(mountpoint.name == name) then
				return mountpoint;
			end
		end
	end
end

-- select mount points by picking name
function MountPointsManip:SelectMountPointsByPickName(pickName)
	local selected_mountpoint = self:GetMountPointByPickName(pickName)
	local handleMode;
	if(selected_mountpoint) then
		handleMode = selected_mountpoint:GetPreferredHandleMode();
		for i, mountpoint in ipairs(self.mountpoints) do
			mountpoint:SetSelected(mountpoint == selected_mountpoint);
		end
	else
		for i, mountpoint in ipairs(self.mountpoints) do
			mountpoint:SetSelected(false);
		end
	end
	if(selected_mountpoint) then
		self:SetField("SelectedMountPointName", selected_mountpoint:GetName());
		self:SetSelectedMountPoint(selected_mountpoint, handleMode)
	end
end

function MountPointsManip:GetMountPointByPickName(pickingName)
	for i, mountpoint in ipairs(self.mountpoints) do
		if(mountpoint.pickName == pickingName) then
			return mountpoint;
		end
	end
end


-- @return handleMode:  
-- if "trans", mountpoint local translation mode is used, such as for lips and pelvis. 
-- if nil, it means a standard mountpoint is selected, and we use the Rotate manipulator
function MountPointsManip:GetHandleMode()
	return self.handleMode;
end

-- select mountpoint and show default manipulator accordingly. 
-- @param handleMode:  
-- if "trans", mountpoint local translation mode is used, such as for lips and pelvis. 
-- if "scale", mountpoint local scaling mode is used, such as for lips and pelvis. 
-- if "rot", it means a standard mountpoint is selected, and we use the Rotate manipulator
function MountPointsManip:SetSelectedMountPoint(mountpoint, handleMode)
	if( self.selectedMountPoint ~= mountpoint or (handleMode~=self.handleMode) ) then
		self.handleMode = handleMode;
		self.selectedMountPoint = mountpoint;
		if(self.selectedMountPoint) then
			GameLogic.AddBBS("mountPointsManip", L"按2,3,4键修改插件点, ESC取消选择", 20000, "0 255 0")
			if(handleMode == "trans") then
				-- show trans handle manip
				self:ShowTransManipForMountPoint(self.selectedMountPoint);
			elseif(handleMode == "scale") then
				-- show scale handle manip
				self:ShowScaleManipForMountPoint(self.selectedMountPoint);
			else
				self:ShowRotateManipForMountPoint(self.selectedMountPoint);
			end
			self.selectedMountPoint:SetPreferredHandleMode(handleMode);
		else
			GameLogic.AddBBS("mountPointsManip", nil)
			self:deleteChildren();
			self.curManip = nil;
		end
	end
end

function MountPointsManip:UpdateManipRadius(manip)
	local radius = 0.5;
	if(manip and manip:GetName() == "RotateManip") then
		radius = 0.6;
	end
	if(manip) then
		manip.radius = radius * self:GetUIScaling();
	end
end

-- show trans manip 
function MountPointsManip:ShowTransManipForMountPoint(mountpoint)
	if(mountpoint) then
		self:deleteChildren();
		NPL.load("(gl)script/ide/System/Scene/Manipulators/TranslateManip.lua");
		local TranslateManip = commonlib.gettable("System.Scene.Manipulators.TranslateManip");
		self.curManip = TranslateManip:new():init(self);
		self:UpdateManipRadius(self.curManip);
		self.curManip.PenWidth = 0.01;
		self.curManip:SetUpdatePosition(false);
		self.curManip:Connect("valueChanged", self, self.OnMountPointTransHandlePosChanged)
		self.curManip:Connect("modifyBegun", self, self.BeginModify)
		self.curManip:Connect("modifyEnded", self, self.EndModify)
	end
end

-- show scaling manip 
function MountPointsManip:ShowScaleManipForMountPoint(mountpoint)
	if(mountpoint) then
		self:deleteChildren();
		NPL.load("(gl)script/ide/System/Scene/Manipulators/ScaleManip.lua");
		local ScaleManip = commonlib.gettable("System.Scene.Manipulators.ScaleManip");
		self.curManip = ScaleManip:new():init(self);
		self:UpdateManipRadius(self.curManip);
		self.curManip.PenWidth = 0.01;
		self.curManip:Connect("valueChanged", self, self.OnMountPointScaleHandlePosChanged)
		self.curManip:Connect("modifyBegun", self, self.BeginModify)
		self.curManip:Connect("modifyEnded", self, self.EndModify)
	end
end

-- show rotate manip 
function MountPointsManip:ShowRotateManipForMountPoint(mountpoint)
	if(mountpoint) then
		self:deleteChildren();
		NPL.load("(gl)script/ide/System/Scene/Manipulators/RotateManip.lua");
		local RotateManip = commonlib.gettable("System.Scene.Manipulators.RotateManip");
		self.curManip = RotateManip:new():init(self);
		
		local rotAxis = mountpoint:GetRotationAxis()
		if(rotAxis) then
			if(not rotAxis:match("x")) then
				self.curManip:SetPitchEnabled(false)
			end
			if(not rotAxis:match("y")) then
				self.curManip:SetYawEnabled(false)
			end
			if(not rotAxis:match("z")) then
				self.curManip:SetRollEnabled(false)
			end
			--[[ we are using delta angles, so following is not necessary
			if(mountpoint:GetMinAngle()) then
				self.curManip:SetMinRotAngle(mountpoint:GetMinAngle());
			end
			if(mountpoint:GetMaxAngle()) then
				self.curManip:SetMaxRotAngle(mountpoint:GetMaxAngle());
			end
			]]
		end

		self:UpdateManipRadius(self.curManip);
		self.curManip:Connect("valueChanged", self, self.OnChangeMountPointRotation)
		self.curManip:Connect("modifyBegun", self, self.BeginModify)
		self.curManip:Connect("modifyEnded", self, self.EndModify)
	end
end

function MountPointsManip:OnMountPointTransHandlePosChanged()
	if(self.selectedMountPoint) then
		local lineScaling = self:GetLineScale();
		local mountpoint = self.selectedMountPoint;
		local lastX, lastY, lastZ = mountpoint:GetLastTranslation();
		local offset =  vector3d:new(self.curManip:GetField("position"))*lineScaling;
		mountpoint:SetBottomCenter(lastX + offset[1], lastY + offset[2], lastZ + offset[3]);
		self:SetModified();
	end
end

function MountPointsManip:OnMountPointScaleHandlePosChanged()
	if(self.selectedMountPoint) then
		local mountpoint = self.selectedMountPoint;
		local scaling = self.curManip:GetField("scaling")
		local dx, dy, dz = mountpoint:GetLastAABB();
		dx, dy, dz = dx*scaling[1], dy*scaling[2], dz*scaling[3];
		mountpoint:SetAABBSize(dx, dy, dz)
		self:SetModified();
	end
end

function MountPointsManip:OnChangeMountPointRotation()
	if(self.selectedMountPoint) then
		local mountpoint = self.selectedMountPoint;
		local yaw = self.curManip:GetField("yaw")
		if(yaw) then
			local angle = mountpoint:GetLastRotation() + yaw;
			angle = mathlib.ToStandardAngle(angle);
			if(self:GetGridStep()) then
				local step = self:GetGridStep()
				angle = math.floor( angle / step + 0.5) * step
			end
			mountpoint:SetFacing(angle)
		end
		self:SetModified();
	end
end

function MountPointsManip:UnselectAll()
	for i, mountpoint in ipairs(self.mountpoints) do
		mountpoint:SetSelected(false);
	end
	self:SetSelectedMountPoint(nil, nil);
	self:SetField("SelectedMountPointName", nil);
end


function MountPointsManip:OnValueChange(name, value)
	MountPointsManip._super.OnValueChange(self);
	if(name == "position") then
		self:SetPosition(unpack(value));
	elseif(name == "SelectedMountPointName") then
		local selected_mountpoint = self:GetMountPointByName(value)
		if(selected_mountpoint) then
			local name = selected_mountpoint:GetName();
			self:mountPointChanged(name);
		else
			self:mountPointChanged(nil);
		end
	end
end

function MountPointsManip:init(parent)
	MountPointsManip._super.init(self, parent);
	return self;
end


function MountPointsManip:RefreshManipulator()
	local mountPointName = self:GetField("SelectedMountPointName", nil);
	
	if(not self.curManip and mountPointName) then
		local selected_mountpoint = self:GetMountPointByName(mountPointName);
		if(selected_mountpoint) then
			local handleMode = "trans";
			self:SetSelectedMountPoint(selected_mountpoint, handleMode);
		else
			self:SetFieldInternal("SelectedMountPointName", nil);
		end
	end
end

-- bind this manipulator to the given entity object
-- @param entity: this is usually EntityBlockModel 
function MountPointsManip:ShowForEntity(entity)
	self.entity = entity;
	self.mpoints = entity:CreateGetMountPoints()
	
	local mountpoints = {};
	for i = 1, self.mpoints:GetCount() do
		mountpoints[#mountpoints+1] = self.mpoints:GetMountPoint(i);
	end
	self.mountpoints = mountpoints;
end

function MountPointsManip:GetMountPointCount()
	return #(self.mountpoints);
end

-- virtual: 
function MountPointsManip:mousePressEvent(event)
	if(event:button() ~= "left") then
		return
	end
	if(event:isAccepted()) then
		self.isChildActive = true;
		if(self.selectedMountPoint) then
			if(self.curManip:GetName() == "RotateManip") then
				self.curManip:SetYawPitchRoll(0,0,0);
				self.selectedMountPoint:SaveLastRotation();
			elseif(self.curManip:GetName() == "TranslateManip") then
				self.curManip:SetField("position", {0,0,0});
				self.selectedMountPoint:SaveLastTranslation();
			elseif(self.curManip:GetName() == "ScaleManip") then
				self.curManip:SetField("scaling", {1,1,1});
				self.selectedMountPoint:SaveLastAABB();
			end
		end
		return
	end
	event:accept();
end

-- virtual: 
function MountPointsManip:mouseMoveEvent(event)
end

-- virtual: 
function MountPointsManip:mouseReleaseEvent(event)
	if(event:button() ~= "left") then
		return
	end
	if(event:isAccepted()) then
		self.isChildActive = false;
		if(self.curManip:GetName() == "RotateManip") then
			self.curManip:SetYawPitchRoll(0,0,0);
		elseif(self.curManip:GetName() == "TranslateManip") then
			self.curManip:SetFieldInternal("position", {0,0,0});
		elseif(self.curManip:GetName() == "ScaleManip") then
			self.curManip:SetFieldInternal("scaling", {1,1,1});
		end
		return
	end
	event:accept();

	local name = self:GetActivePickingName();
	self:SelectMountPointsByPickName(name);
end

function MountPointsManip:GrabValues()
end

-- virtual: actually means key stroke. 
function MountPointsManip:keyPressEvent(event)
	local keyname = event.keyname;
	if(self.selectedMountPoint) then
		if(keyname == "DIK_ESCAPE") then
			-- cancel selection on esc key
			event:accept();
			self:UnselectAll();
		elseif(keyname == "DIK_2") then
			-- toggle to translation mode. 
			self:SetSelectedMountPoint(self.selectedMountPoint, "trans");
			event:accept();
		elseif(keyname == "DIK_3") then
			-- toggle to standard mountpoint rotation
			self:SetSelectedMountPoint(self.selectedMountPoint, nil);
			event:accept();
		elseif(keyname == "DIK_4") then
			-- toggle to standard mountpoint scaling
			self:SetSelectedMountPoint(self.selectedMountPoint, "scale");
			event:accept();
		elseif(keyname == "DIK_ADD" or keyname == "DIK_EQUALS") then
			-- select first child mountpoint
			local childMountPoint = self.selectedMountPoint:GetChildAt(1);
			while(childMountPoint) do
				if(childMountPoint:IsEditable()) then
					self:SelectMountPointsByPickName(childMountPoint.pickName);
					break;
				else
					childMountPoint = childMountPoint:GetChildAt(1);
				end
			end
			event:accept();
		elseif(keyname == "DIK_SUBTRACT" or keyname == "DIK_MINUS") then
			-- select parent mountpoint
			local parentMountPoint = self.selectedMountPoint:GetParent();
			while(parentMountPoint) do
				if(parentMountPoint:IsEditable()) then
					self:SelectMountPointsByPickName(parentMountPoint.pickName);
					break;
				else
					parentMountPoint = parentMountPoint:GetParent();
				end
			end
			event:accept();
		elseif(keyname == "DIK_K") then
			-- force making a new key at the current pos. 
			self:AddKeyWithCurrentValue()
			event:accept();
		end
	end
	if(keyname == "DIK_LBRACKET" or keyname == "DIK_RBRACKET") then
		-- [ and ] key to change manipulator scaling. 
		local scaling = 2;
		if(keyname == "DIK_LBRACKET") then
			scaling = 0.5;
		end
		local scaling = (self:GetUIScaling() * scaling);
		if(scaling < 1) then
			scaling = 1;
		end
		self:SetUIScaling(scaling);
		event:accept();
	end
end

-- this ensures that model instance's final matrix is calculated and up to date. 
function MountPointsManip:UpdateModel()
	-- following may not need to be called every frame. 
	if(self.entity) then
		if(not self.entity.isMountpointDetached) then
			local facing = self.entity:GetFacing();
			if(facing ~= 0) then
				self.localRotQuat = self.localRotQuat or Quaternion:new();
				self.localRotQuat:FromAngleAxis(facing, vector3d.unit_y)
				self.localRotQuat:ToRotationMatrix(self.localTransform)
			else
				self.localTransform:identity()
			end
			local scaling = self.entity:GetScaling()
			if(scaling ~= 1) then
				self.matScale = self.matScale or Matrix4:new():identity();
				self.matScale:setScale(scaling, scaling, scaling);
				self.localTransform:multiply(self.matScale);
			end
		else
			self.localTransform:identity()
		end

		-- TODO: bmax's local transform does not contain scaling, we will compute local transform manually
		-- self.localTransform = self.entity:GetInnerObject():GetField("LocalTransform", self.localTransform);
		self:SetLocalTransform(self.localTransform);

		-- update selected bone manipulators. 
		if(self.selectedMountPoint and self.curManip) then
			if(not self.curManip:IsDragging()) then
				local trans = self.curManip:GetLocalTransform();
				local lineScale = self:GetLineScale();
				trans:identity();
				trans:setScale(lineScale, lineScale, lineScale);
				trans:setTrans(self.selectedMountPoint:GetBottomCenter());
				self.curManip:SetLocalTransform(trans);
			end
		end
	end
end

function MountPointsManip:paintEvent(painter)
	local UIScaling = self:GetUIScaling();
	local lineScale = self:GetLineScale(painter) * UIScaling;
	self.pen.width = self.PenWidth * lineScale;
	painter:SetPen(self.pen);
	local isDrawingPickable = self:IsPickingPass();

	if(Keyboard:IsAltKeyPressed()) then
		-- hide everything when alt key is pressed. 
		return;
	end

	self:UpdateModel();
	local name = self:GetActivePickingName();
	if(self.isChildActive) then
		name = -1;
	end
	local mountpoints = self.mountpoints;
	for i, mountpoint in ipairs(mountpoints) do
		
		local pickName;
		if(isDrawingPickable) then
			pickName = self:GetNextPickingName();
		end
		
		local cx, cy, cz = mountpoint:GetBottomCenter();
		local dx, dy, dz = mountpoint:GetAABBSize()

		-- draw this mountpoint if any
		painter:PushMatrix();
		painter:TranslateMatrix(cx, cy, cz);
		
		if(self.selectedMountPoint == mountpoint) then
			self:SetColorAndName(painter, self.editColor, pickName);
		else
			if(name == mountpoint.pickName) then
				-- hover over color
				self:SetColorAndName(painter, self.hoverAABBColor, pickName);
			else
				self:SetColorAndName(painter, self.AABBColor, pickName);
			end
		end
		-- draw this mountpoint AABB
		ShapesDrawer.DrawAABB(painter, - dx / 2, 0, - dz / 2, dx / 2, dy, dz / 2, false)
		
		-- draw mountpoint facing
		if(mountpoint:GetFacing() ~= 0) then
			painter:RotateMatrix(mountpoint:GetFacing(), 0, 1, 0)
		end
		ShapesDrawer.DrawLine(painter, 0, 0, 0, dx + 0.1, 0, 0)

		if(not isDrawingPickable and 
			(((self.ShowMountPointName) and (name == mountpoint.pickName or self.selectedMountPoint == mountpoint))
				or (not self.selectedMountPoint and name == mountpoint.pickName))) then
			-- display mountpoint text for mouse hover mountpoint
			painter:PushMatrix();
			painter:TranslateMatrix(dx + 0.1, 0.1*lineScale, 0);
			painter:LoadBillboardMatrix();
			self:SetColorAndName(painter, self.TextColor, pickName);
			painter:DrawTextScaled(0, 0, mountpoint:GetDisplayName(), self.textScale*lineScale);
			painter:PopMatrix();
		end
		painter:PopMatrix();

		if(isDrawingPickable) then
			mountpoint.pickName = pickName;
		end
	end
end

