--[[
Title: BlockBoneManipContainer
Author(s): LiXizhi@yeah.net
Date: 2015/9/23
Desc: used to draw helpers for selected BlockBone
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/Manipulators/BlockBoneManipContainer.lua");
local BlockBoneManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.BlockBoneManipContainer");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/ManipContainer.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local BlockBoneManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.BlockBoneManipContainer"));
BlockBoneManipContainer:Property({"Name", "BlockBoneManipContainer", auto=true});

BlockBoneManipContainer:Property({"PivotColor", "#40ff20"});
BlockBoneManipContainer:Property({"editColor", "#ff4264"});
BlockBoneManipContainer:Property({"RootPivotColor", "#ff0000"});
-- for skin hightlight block selection effect. 
BlockBoneManipContainer:Property({"groupindex_hint", 3});
BlockBoneManipContainer:Signal("boneChanged", function(boneEntity) end);

function BlockBoneManipContainer:ctor()
	self.boneEntity = nil;
	self:SetZPassOpacity(0.5);
end

function BlockBoneManipContainer:Destroy()
	BlockBoneManipContainer._super.Destroy(self);
	ParaTerrain.DeselectAllBlock(self.groupindex_hint);
end

function BlockBoneManipContainer:createChildren()
	self.translateManip = self:AddTranslateManip();
	self.translateManip:SetShowGrid(true);
	self.translateManip:SetSnapToGrid(true);
	self.translateManip:SetGridSize(BlockEngine.blocksize/4);
	self.translateManip:SetUpdatePosition(false);
end

-- @param node: bone entity
function BlockBoneManipContainer:connectToDependNode(node)
	local plugPos = node:findPlug("LocalPivot");
	self.boneEntity = node;
	-- update all connected bones's parent, color and skins
	self.allBones = self.boneEntity:RefreshBones();
	-- hightlight skins
	self:HightLightSkinForBone(self.boneEntity, true)
	local manipPosPlug = self.translateManip:findPlug("position");
	local x, y, z = node:GetCenterPosition();
	if(x and y and z) then
		self:SetPosition(x,y,z);
		self:addManipToPlugConversionCallback(plugPos, function(self, plug)
			return manipPosPlug:GetValue();
		end);
		self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
			return plugPos:GetValue();
		end);
	end
	
	-- should be called only once after all conversion callbacks to setup real connections
	self:finishAddingManips();
	BlockBoneManipContainer._super.connectToDependNode(self, node);
end

-- @return lowestBone, minY : minY is the bone position, if no bone is found, it is 0
function BlockBoneManipContainer:GetLowestBone(allBones)
	allBones = allBones or self.allBones;
	local lastHeight = 9999999999;
	local lowestBone;
	for bone in pairs(self.allBones) do
		if(bone.by < lastHeight) then
			lastHeight = bone.by;
			lowestBone = bone;
		end
	end
	if(not lowestBone) then
		lastHeight = 0;
	end
	return lowestBone, lastHeight;
end

function BlockBoneManipContainer:HightLightSkinForBone(boneEntity, bRefresh)
	ParaTerrain.DeselectAllBlock(self.groupindex_hint);
	if(boneEntity) then
		-- skin blocks connecting to the ground (lowest bone) is ignored during block bone editing
		local lowestBone, minY = self:GetLowestBone(allBones);
		local cx, cy, cz = boneEntity.bx, boneEntity.by, boneEntity.bz;
		local skins = boneEntity:GetSkin(bRefresh, minY);
		if(skins) then
			for _, pos in ipairs(skins) do
				local rx, ry, rz = unpack(pos);
				local x, y, z = cx+rx, cy+ry, cz+rz;
				ParaTerrain.SelectBlock(x, y, z, true, self.groupindex_hint);
			end
		end
	end
end

-- virtual: 
function BlockBoneManipContainer:mousePressEvent(event)
	if(event:button() ~= "left") then
		return
	end
	if(self:SelectBoneByPickName(self:GetActivePickingName())) then
		event:accept();
	end
end

-- return true if selected
function BlockBoneManipContainer:SelectBoneByPickName(pickName)
	local bone = self:GetBoneByPickName(pickName);
	if(bone) then
		self:boneChanged(bone);
		return true;
	end
end

function BlockBoneManipContainer:GetBoneByPickName(pickingName)
	for bone in pairs(self.allBones) do
		if(bone.pickName == pickingName) then
			return bone;
		end
	end
end

function BlockBoneManipContainer:HasPickingName(pickingName)
	for bone in pairs(self.allBones) do
		if(bone.pickName == pickingName) then
			return true;
		end
	end
end

function BlockBoneManipContainer:paintEvent(painter)
	BlockBoneManipContainer._super.paintEvent(self, painter);
	if(not self.boneEntity or not self.allBones) then
		return;
	end
	local isDrawingPickable = self:IsPickingPass();
	local name = self:GetActivePickingName();
	local lineScale = self:GetLineScale(painter);
	self.pen.width = self.PenWidth * lineScale;
	painter:SetPen(self.pen);
	
	local cx,cy,cz = self.boneEntity:GetCenterPosition();
	local pivot_radius = 0.2;
	
	for boneEntity in pairs(self.allBones) do
		local x,y,z = unpack(boneEntity:GetPivotPosition());
		local parent = boneEntity:GetParentBone();
		local pickName;
		if(isDrawingPickable) then
			pickName = self:GetNextPickingName();
			boneEntity.pickName = pickName;
		end
		local boneColor = boneEntity:GetBoneColor();
		if(boneColor) then
			painter:PushMatrix();
			painter:TranslateMatrix(x-cx, y-cy, z-cz);
			painter:LoadBillboardMatrix();
			self:SetColorAndName(painter, Color.ChangeOpacity(boneColor, 255), pickName);
			ShapesDrawer.DrawCircle(painter, 0,0,0, pivot_radius, "z", true);
			painter:PopMatrix();
		end

		if(not isDrawingPickable and name == boneEntity.pickName and self.boneEntity ~= boneEntity) then
			self:SetColorAndName(painter, self.hoverColor, pickName);
		else
			if(parent) then
				if(self.boneEntity == boneEntity) then
					self:SetColorAndName(painter, self.editColor, pickName);
				else
					self:SetColorAndName(painter, self.PivotColor, pickName);
				end
			else
				self:SetColorAndName(painter, self.RootPivotColor, pickName);
			end
		end
		
		if(not isDrawingPickable or self.boneEntity ~= boneEntity) then
			-- draw the pickable pivot point;
			ShapesDrawer.DrawCircle(painter, x-cx, y-cy, z-cz, pivot_radius, "x", false);
			ShapesDrawer.DrawCircle(painter, x-cx, y-cy, z-cz, pivot_radius, "y", false);
			ShapesDrawer.DrawCircle(painter, x-cx, y-cy, z-cz, pivot_radius, "z", false);
		
			if(parent and not isDrawingPickable) then
				local px,py,pz = unpack(parent:GetPivotPosition());
				-- draw a line to parent bone
				ShapesDrawer.DrawLine(painter, x-cx, y-cy, z-cz, px-cx, py-cy, pz-cz);
			end
		end
	end
end