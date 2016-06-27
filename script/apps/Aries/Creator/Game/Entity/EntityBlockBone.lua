--[[
Title: BlockBone Entity
Author(s): LiXizhi
Date: 2015/9/23
Desc: ctrl+right click to open editor. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBone.lua");
local EntityBlockBone = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBone")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local vector3d = commonlib.gettable("mathlib.vector3d");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBone"));
-- local bone pivot point
Entity:Property({"LocalPivot", {0,0,0}, "GetLocalPivot", "SetLocalPivot", auto=true});
-- world bone pivot position of vector3d
Entity:Property({"PivotPosition", nil, "GetPivotPosition", "SetPivotPosition"});
Entity:Property({"boneColor", 0xffffff,});

-- class name
Entity.class_name = "EntityBlockBone";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

function Entity:ctor()
	self.LocalPivot = vector3d:new();
	self:SetRuleBagSize(16);
end

function Entity:Detach()
	-- TODO: deselect from context?
	return Entity._super.Detach(self);
end

-- virtual function: 
function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	return self;
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	return L"输入骨骼名称: 例如wheel, left hand, right hand, etc";
end

function Entity:HasCommand()
	return true;
end

-- bool: whether show the rule panel
function Entity:HasRule()
	return true;
end

-- the title text to display (can be mcml)
function Entity:GetRuleTitle()
	return L"规则";
end

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BlockBoneContext.lua");
	local BlockBoneContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.BlockBoneContext");
	local context = BlockBoneContext:CreateGetInstance("BlockBoneContext");
	context:SetSelectedBone(self);
	context:activate();
	return true;
end

function Entity:OpenBagEditor(editor_name, entity)
	return Entity._super.OpenEditor(self, editor_name or "entity", entity);
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	if(attr.px and attr.py and attr.pz) then
		self.LocalPivot:set(tonumber(attr.px) or 0, tonumber(attr.py) or 0, tonumber(attr.pz) or 0);
	end
end

function Entity:SaveToXMLNode(node)
	node = Entity._super.SaveToXMLNode(self, node);
	local attr = node.attr;
	attr.px = self.LocalPivot[1];
	attr.py = self.LocalPivot[2];
	attr.pz = self.LocalPivot[3];
	return node;
end

-- virtual
function Entity:OnNeighborChanged(x,y,z, from_block_id)
	return Entity._super.OnNeighborChanged(self, x,y,z, from_block_id);
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		-- GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		return true;
	else
		if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
			if(ctrl_pressed) then
				self:OpenEditor("entity", entity);
				return true;
			else
				GameLogic.AddBBS(nil, L"Ctrl+右键点击骨骼方块可编辑");
			end
		end
	end
end

-- max distance to parent bone horizontally, we will stop finding parent bone after this length
local MaxBoneLengthHorizontal = 10;
-- max distance to parent bone vertically, we will stop finding parent bone after this length
local MaxBoneLengthVertical = 50;
-- how many blocks can be bind to a bone, just for safe checking. 
local MaxSkinsPerBone = 1000;

-- @param bRefresh: if true, we will search again for parent bone of this entity
function Entity:GetParentBone(bRefresh)
	if(bRefresh) then
		local boneId = self:GetBlockId(); -- block_types.names.Bone;
		local cx, cy, cz = self.bx, self.by, self.bz;
		local side = BlockEngine:GetBlockData(cx, cy, cz) or 0;
		local dx, dy, dz = Direction.GetOffsetBySide(side);
		local maxBoneLength = MaxBoneLengthHorizontal
		if(dy~=0) then
			maxBoneLength = MaxBoneLengthVertical;
		end
		for i=1, maxBoneLength do
			local x,y,z = cx+dx*i, cy+dy*i, cz+dz*i;
			if(BlockEngine:GetBlockId(x, y, z) == boneId) then
				local parentSide = BlockEngine:GetBlockData(x, y, z) or 0;
				-- if two bones are opposite to each other, the lower one is the parent
				if(Direction.directionToOpFacing[parentSide] ~= side or (dx+dy+dz) < 0) then
					self.parentBone = BlockEngine:GetBlockEntity(x,y,z)
				else
					self.parentBone = nil;
				end
				break;
			end
		end
	end
	return self.parentBone;
end

-- @param allBones: bones that have been recalculated, if nil a new empty table is used and returned.
-- return a map of all bones connected with the current bone, including the current bone. 
function Entity:RecalculateAllConnectedBones(allBones)
	allBones = allBones or {} -- prevent recursion
	if(not allBones[self]) then
		allBones[self] = true;
		local boneId = self:GetBlockId(); -- block_types.names.Bone;
		local cx, cy, cz = self.bx, self.by, self.bz;
		local mySide = BlockEngine:GetBlockData(cx, cy, cz) or 0;
		for side=0,5 do
			if(side==mySide) then
				-- looking for parent
				local parentBone = self:GetParentBone(true);
				if(parentBone and not allBones[parent]) then
					parentBone:RecalculateAllConnectedBones(allBones);
				end
			end
			-- looking for child
			local dx, dy, dz = Direction.GetOffsetBySide(side);
			local maxBoneLength = MaxBoneLengthHorizontal
			if(dy~=0) then
				maxBoneLength = MaxBoneLengthVertical;
			end
			for i=1, maxBoneLength do
				local x,y,z = cx+dx*i, cy+dy*i, cz+dz*i;
				if(BlockEngine:GetBlockId(x, y, z) == boneId) then
					local childBone = BlockEngine:GetBlockEntity(x,y,z);
					if(not allBones[childBone]) then
						if( childBone:GetParentBone(true) == self) then
							childBone:RecalculateAllConnectedBones(allBones);
						end
					end
					break;
				end
			end
		end
	end
	return allBones;
end

-- calculate all parent bones
-- @return true if recursion is detected, false if not. 
function Entity:RecalculateAllParentBones()
	local recalulatedBones = {} -- prevent recursion
	local bone = self;
	while (bone) do
		recalulatedBones[bone] = true;
		local parent = bone:GetParentBone(true);
		if(recalulatedBones[parent]) then
			-- recursion detected
			bone.parentBone = nil;
			bone = nil;
			return true;
		else
			bone = parent;
		end
	end
end

function Entity:GetCenterPosition()
	local x, y, z = self:GetPosition();
	return x, y+BlockEngine.half_blocksize, z;
end
-- get pivot point in world coordinate
function Entity:GetPivotPosition()
	local x, y, z = self:GetCenterPosition();
	return {x + self.LocalPivot[1], y + self.LocalPivot[2], z + self.LocalPivot[3]};
end

function Entity:SetLocalPivot(pos)
	if(not self.LocalPivot:equals(pos)) then
		-- we do not allow local pivot to deviate too much from the center
		local maxSize = BlockEngine.half_blocksize;
		self.LocalPivot[1] = mathlib.clamp(pos[1], -maxSize, maxSize);
		self.LocalPivot[2] = mathlib.clamp(pos[2], -maxSize, maxSize);
		self.LocalPivot[3] = mathlib.clamp(pos[3], -maxSize, maxSize);
		-- self:valueChanged();
	end
end

-- set pivot point in world coordinate
function Entity:SetPivotPosition(vPos)
	local x, y, z = self:GetCenterPosition();
	self.LocalPivot:set(vPos[1] - x, vPos[2] - y, vPos[3] - z);
end

-- only call this funciton when all bone parents are calculated. 
-- it will use the color of its first neighbour block except for the one in parent direction. 
-- if no neighbor is found, it will use the color of parent bone. 
-- please note it will search for a neighbor in order, -x, x,-z, z, -y, y.
-- @param bRefresh: true to recalculate
function Entity:GetBoneColor(bRefresh)
	if(bRefresh) then
		local color;
		local cx, cy, cz = self.bx, self.by, self.bz;
		local mySide = BlockEngine:GetBlockData(cx, cy, cz) or 0;
		for side=0,5 do
			if(side~=mySide or not self.parentBone) then
				local dx, dy, dz = Direction.GetOffsetBySide(side);
				local x,y,z = cx+dx, cy+dy, cz+dz;
				local blockTemplate = BlockEngine:GetBlock(x,y,z);
				if(blockTemplate and blockTemplate.solid) then
					color = blockTemplate:GetBlockColor(x,y,z)
					break;
				end
			end
		end
		if(not color and self.parentBone) then
			color = self.parentBone:GetBoneColor(bRefresh);
		end
		self.boneColor = color or 0xffffff;
	end
	return self.boneColor;
end

-- this function can only be called when all connected bone's color and parent have been calculated. 
-- return all block's relative position that is connected with the current bone. 
-- @param bRefresh: true to recalculate
-- @param minY: if nil, this is the minimum y position(inclusive) to search for skin blocks. 
-- @return relative position like, {{0,0,0}, {0,0,0}}
function Entity:GetSkin(bRefresh, minY)
	if(bRefresh) then
		local skins = {};
		local blockIndices = {}; -- mapping from block index to true for processed bones
		self.skins = skins;
		local cx, cy, cz = self.bx, self.by, self.bz;
		local boneColor = self:GetBoneColor(); -- note: bone color must be pre-computed
		local function AddToSkin(x, y, z)
			local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz)
			if(not blockIndices[boneIndex]) then
				blockIndices[boneIndex] = true;
				skins[#skins+1] = {x-cx,y-cy,z-cz};	
			end
		end
		local function IsBlockProcessed(x, y, z)
			local boneIndex = BlockEngine:GetSparseIndex(x-cx,y-cy,z-cz);
			return blockIndices[boneIndex];
		end
		-- add current bone to skin. 
		AddToSkin(cx, cy, cz);
		-- add other connected bones recursively. 
		local function FindBoneForBlock(x,y,z)
			if(not IsBlockProcessed(x,y,z) and #skins < MaxSkinsPerBone and (minY and minY<=y) ) then
				local blockTemplate = BlockEngine:GetBlock(x,y,z);
				if(blockTemplate and blockTemplate.solid) then
					if(blockTemplate:GetBlockColor(x,y,z) == boneColor) then
						AddToSkin(x,y,z);
						for side=0,5 do
							local dx, dy, dz = Direction.GetOffsetBySide(side);
							FindBoneForBlock(x+dx, y+dy, z+dz);
						end
					end
				end
			end
		end
		local mySide = BlockEngine:GetBlockData(cx, cy, cz) or 0;
		for side=0,5 do
			if(side~=mySide or not self.parentBone) then
				local dx, dy, dz = Direction.GetOffsetBySide(side);
				FindBoneForBlock(cx+dx, cy+dy, cz+dz);
			end
		end
	end
	return self.skins;
end

-- @return all bones
function Entity:RefreshBones()
	local bones = self:RecalculateAllConnectedBones();
	for bone in pairs(bones) do
		bone:GetBoneColor(true);
	end
	return bones;
end