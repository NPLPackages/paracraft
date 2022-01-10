--[[
Title: item live model
Author(s): LiXizhi
Date: 2021/12/2
Desc: Live model entity is an iteractive model that can be moved around the scene and stacked upon one another. 
An example of Drop and drop EntityLiveModel are implemented here, see the virtual functions for details: mouseReleaseEvent, mouseMoveEvent, mousePressEvent
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLiveModel.lua");
local ItemLiveModel = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel");
local item_ = ItemLiveModel:new({block_id, text, icon, tooltip, max_count, scaling, filename, gold_count, hp, respawn_time});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ModelTextureAtlas.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BlockSound.lua");
local BlockSound = commonlib.gettable("MyCompany.Aries.Game.Sound.BlockSound");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ModelTextureAtlas = commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Cameras = commonlib.gettable("System.Scene.Cameras");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local ItemLiveModel = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel"));

block_types.RegisterItemClass("ItemLiveModel", ItemLiveModel);

-- health point
ItemLiveModel.hp = 100;
-- respawn in 300 000 ms. 
ItemLiveModel.respawn_time = 300*1000;

-- ItemLiveModel.CreateAtPlayerFeet = true;

function ItemLiveModel:ctor()
	self:SetOwnerDrawIcon(true);
	self.hp = tonumber(self.hp);
	self.respawn_time = tonumber(self.respawn_time);
	self.create_sound = BlockSound:new():Init({"cloth1", "cloth2", "cloth3",});
end

function ItemLiveModel:HasFacing()
	return true;
end


-- virtual function: use the item. 
function ItemLiveModel:OnUse()
end

-- virtual function: when selected in right hand
function ItemLiveModel:OnSelect(itemStack)
	ItemLiveModel._super.OnSelect(self, itemStack);
	GameLogic.SetStatus(L"按住鼠标左键可以拖动模型, 右键点击编辑模型");
	
end

-- virtual function: when deselected in right hand
function ItemLiveModel:OnDeSelect()
	ItemLiveModel._super.OnDeSelect(self);
	GameLogic.SetStatus(nil);
end

function ItemLiveModel:CanSpawn()
	return false;
end

-- called every frame
function ItemLiveModel:FrameMove(deltaTime)
end

function ItemLiveModel:GetModelFileName(itemStack)
	return itemStack and itemStack:GetDataField("tooltip");
end

function ItemLiveModel:SetModelFileName(itemStack, filename)
	if(itemStack) then
		itemStack:SetDataField("tooltip", filename);
		itemStack:SetDataField("xmlNode", nil)
		local task = self:GetTask();
		if(task) then
			task:SetItemInHand(itemStack);
			task:RefreshPage();
		end
	end
end

-- virtual: convert entity to item stack. 
-- such as when alt key is pressed to pick a entity in edit mode. 
function ItemLiveModel:ConvertEntityToItem(entity, itemStack)
	if(entity and (entity:isa(EntityManager.EntityBlockModel) or entity:isa(EntityManager.EntityLiveModel)))then
		itemStack = itemStack or ItemStack:new():Init(block_types.names.LiveModel, 1);
		itemStack:SetDataField("tooltip", entity:GetModelFile())
		local node = entity:SaveToXMLNode()
		node.attr.x, node.attr.y, node.attr.z = nil, nil, nil
		node.attr.bx, node.attr.by, node.attr.bz = nil, nil, nil
		node.attr.name = nil;
		node.attr.linkTo = nil;
		node.attr.class = nil;
		node.attr.item_id = nil;
		if(entity:HasRealPhysics()) then
			node.attr.useRealPhysics = true;
		end
		itemStack:SetDataField("xmlNode", node)
		return itemStack
	end
end

-- whether we can create item at given block position.
function ItemLiveModel:CanCreateItemAt(x,y,z)
	if(ItemLiveModel._super.CanCreateItemAt(self, x,y,z)) then
		if(not EntityManager.HasNonPlayerEntityInBlock(x,y,z) and not EntityManager.HasNonPlayerEntityInBlock(x,y+1,z)) then
			return true;
		end
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemLiveModel:DrawIcon(painter, width, height, itemStack)
	local filename = self:GetModelFileName(itemStack);
	if(filename and filename~="") then
		itemStack.renderedTexturePath = ModelTextureAtlas:CreateGetModel(filename)
		
		if(itemStack.renderedTexturePath) then
			painter:SetPen("#ffffff");
			painter:DrawRectTexture(0, 0, width, height, itemStack.renderedTexturePath);
		else
			ItemLiveModel._super.DrawIcon(self, painter, width, height, itemStack);
		end
		filename = filename:match("[^/]+$"):gsub("%..*$", "");
		filename = filename:sub(1, 6);
		
		painter:SetPen("#33333380");
		painter:DrawRect(0,0, width, 14);
		painter:SetPen("#ffffff");
		painter:SetFont("System;12")
		painter:DrawText(1,0, filename);
	else
		ItemLiveModel._super.DrawIcon(self, painter, width, height, itemStack);
	end
end


function ItemLiveModel:PickItemFromPosition(x,y,z)
	local entity = self:GetBlock():GetBlockEntity(x,y,z);
	if(entity) then
		if(entity.GetModelFile) then
			local filename = entity:GetModelFile();
			if(filename) then
				local itemStack = ItemStack:new():Init(self.id, 1);
				-- transfer filename from entity to item stack. 
				itemStack:SetTooltip(filename);
				if(entity.onclickEvent) then
					itemStack:SetDataField("onclickEvent", entity.onclickEvent);
				end
				return itemStack;
			end
		end
	end
end

-- return true if items are the same. 
-- @param left, right: type of ItemStack or nil. 
function ItemLiveModel:CompareItems(left, right)
	if(ItemLiveModel._super.CompareItems(self, left, right)) then
		if(left and right and left:GetTooltip() == right:GetTooltip()) then
			return true;
		end
	end
end

function ItemLiveModel:OpenChangeFileDialog(itemStack)
	if(itemStack) then
		local local_filename = itemStack:GetDataField("tooltip");
		local_filename = commonlib.Encoding.Utf8ToDefault(local_filename)
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
		local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
		OpenAssetFileDialog.ShowPage(L"请输入bmax, x或fbx文件的相对路径, <br/>你也可以随时将外部文件拖入窗口中", function(result)
			if(result and result~="" and result~=local_filename) then
				result = commonlib.Encoding.DefaultToUtf8(result)
				self:SetModelFileName(itemStack, result);
			end
		end, local_filename, L"选择模型文件", "model", nil, function(filename)
			self:UnpackIntoWorld(itemStack, filename);
		end)
	end
end



-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
function ItemLiveModel:OnClickInHand(itemStack, entityPlayer)
	-- if there is selected blocks, we will replace selection with current block in hand. 
	if(GameLogic.GameMode:IsEditor() and entityPlayer == EntityManager.GetPlayer()) then
		self:SelectModelFile(itemStack);
	end
end

function ItemLiveModel:SelectModelFile(itemStack)
	local selected_blocks = Game.SelectionManager:GetSelectedBlocks();
	if(selected_blocks and itemStack) then
		-- Save template:
		local last_filename = itemStack:GetDataField("tooltip");
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
		OpenFileDialog.ShowPage(L"将当前选择的方块保存为bmax文件. 请输入文件名:<br/> 例如: test", function(result)
			if(result and result~="") then
				result = commonlib.Encoding.DefaultToUtf8(result)
				local filename = result;
				local bSucceed, filename = GameLogic.RunCommand("/savemodel "..filename);
				if(filename) then
					self:SetModelFileName(itemStack, filename);
				end
			end
		end, last_filename, L"选择模型文件", "model");
	else
		self:OpenChangeFileDialog(itemStack);
	end
end

-- virtual function: 
function ItemLiveModel:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
	local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
	EditModelTask:SetItemInHand(itemStack)
	return EditModelTask:new();
end

---------------------------------
-- Drag and drop EntityLiveModel implementations
-- following methods can also be used in a scene context to achive similar functions
-- just copy and paste following methods and modify as needed in a custom scene context. 
---------------------------------

-- only entity that has physics or stackable or has mount points can receive entity drop on to it. 
-- @param entity: the target EntityLiveModel instance. 
-- @param draggingEntity: the dragging entity that will be dropped to the target entity. 
function ItemLiveModel:CanEntityReceiveModelDrop(entity, draggingEntity)
	if(entity:HasRealPhysics() or entity:IsStackable() or (entity:GetMountPointsCount() > 0)) then
		return true;
	elseif(self:CanEntityReceiveCustomCharItem(entity, draggingEntity)) then
		return true
	end
end

-- is a character entity and dragging entity is a custom char item. 
function ItemLiveModel:CanEntityReceiveCustomCharItem(entity, draggingEntity)
	if(entity:HasCustomGeosets() and draggingEntity) then
		local category = draggingEntity:GetCategory()
		if(category == "customCharItem" or draggingEntity:GetCanDrag()) then
			return true
		end
	end
end

-- entity picking callback function
-- this fuction is only called when entity is dragging
function ItemLiveModel:OnFilterEntityPicking(entity)
	if(entity) then
		if(self.skipEntities and self.skipEntities[entity]) then
			return false;
		end
		if(entity:isa(EntityManager.EntityLiveModel) ) then
			if( (self.draggingEntity and not self:CanEntityReceiveModelDrop(entity, self.draggingEntity)) ) then
				-- we will filter out the given entity
				return false;
			end
		end
	end
	return true;
end

-- @return the global result. 
function ItemLiveModel:MousePickBlock()
	result = SelectionManager:MousePickBlock();
	return result;
end

--@return pickingResult, hoverEntity
function ItemLiveModel:CheckMousePick()
	local result
	-- we will try picking mounted objects first. 
	local function PickEntity_(parentEntity)
		result = self:MousePickBlock();

		if(result.entity and result.entity:isa(EntityManager.EntityLiveModel)) then
			local entity = result.entity;
			if(not parentEntity or parentEntity:HasLinkChild(entity)) then
				if(entity:GetLinkChildCount() > 0 and not entity:HasRealPhysics()) then
					
					self.skipEntities = self.skipEntities or {}
					self.skipEntities[entity] = true;

					local newEntity = PickEntity_(entity)
					if(not newEntity) then
						self.skipEntities[entity] = nil;
						result = self:MousePickBlock();
						-- double check, result.entity should always be EntityLiveModel. 
						if(result.entity and result.entity:isa(EntityManager.EntityLiveModel)) then
							entity = result.entity;
						end
					else
						return newEntity;
					end
				end
				return entity;
			end
		end
	end
	
	SelectionManager:SetEntityFilterFunction(ItemLiveModel.OnFilterEntityPicking, self)
	self.skipEntities =  nil;
	local entity = PickEntity_()
	self.skipEntities =  nil;

	local newHoverEntity
	if(entity) then
		if(not self.draggingEntity or self:CanEntityReceiveModelDrop(entity, self.draggingEntity)) then
			newHoverEntity = entity;
		end
	end

	if(self.last_hover_entity ~= newHoverEntity) then
		self.last_hover_entity = newHoverEntity;
	end
	if(newHoverEntity)  then
		local obj = newHoverEntity:GetInnerObject();
		if(obj) then	
			if(newHoverEntity:CanHighlight()) then
				ParaSelection.AddObject(obj, 1);
			else
				ParaSelection.ClearGroup(1);
			end
		end
	else
		ParaSelection.ClearGroup(1);
	end
	return result, self.last_hover_entity;
end

function ItemLiveModel:GetHoverEntity()
	return self.last_hover_entity
end


function ItemLiveModel:mousePressEvent(event)
	Game.SelectionManager:SetEntityFilterFunction(nil)
	local result, entity = self:CheckMousePick()

	self.mousePressEntity = nil;
	
	if(event.alt_pressed and event:button() == "left") then
		-- alt + click to pick both EntityBlockModel and EntityLiveModel
		if(not entity and result.blockX) then
			local entityBlock = EntityManager.GetBlockEntity(result.blockX, result.blockY, result.blockZ)
			if(entityBlock and entityBlock:isa(EntityManager.EntityBlockModel)) then
				entity = entityBlock;
			end
		end
		if(entity) then
			local itemStack = EntityManager.GetPlayer().inventory:GetItemInRightHand()
			if(itemStack and itemStack.id == block_types.names.LiveModel) then
				self:ConvertEntityToItem(entity, itemStack)
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
				local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
				local task = EditModelTask.GetInstance()
				if(task) then
					task:UpdateValueToPage();
				end
			else
				GameLogic.GetPlayerController():PickItemByEntity(entity);
			end
		elseif(result.block_id) then
			GameLogic.GetPlayerController():PickBlockAt(result.blockX, result.blockY, result.blockZ);
		end
		event:accept();
	elseif(self:CanDragDropEntity(entity) and (event:button() == "left")) then
		-- only left button to drag and drop 
		self.mousePressEntity = entity;
		-- mouse left dragging only enabled when we are not dragging or clicking live model. simply accept this event to do this trick.
		event:accept();
	end

	if(self.draggingEntity) then
		self:DropDraggingEntity()
	end
end

-- we will free fall into mountpoints if the horizontal distance is smaller than 0.5
-- we will also free fall into physical mesh without mount points. 
-- we will also free fall into bottom center of normal solid blocks
-- the highest point in above three conditions is used as the final drop location. 
-- @param dropLocation: {dropX, dropY, dropZ}, from which location to fall
-- @param maxFallDistance: default to 10 meters. 
function ItemLiveModel:CalculateFreeFallDropLocation(srcEntity, dropLocation, maxFallDistance)
	maxFallDistance = maxFallDistance or 10;
	local x, y, z = dropLocation.dropX, dropLocation.dropY, dropLocation.dropZ;
	-- TODO: if the current drop location is on a vertical physical mesh face, 
	-- we need to move the location a half block size towards to the eye location, before picking new physical mesh. 
	local entity, x1, y1, z1 = self:RayPickPhysicalLiveModel(x, y+0.1, z, 0, -1, 0, maxFallDistance)
	local lastEntity = dropLocation.target;
	local lastMountPointIndex = dropLocation.mountPointIndex;
	
	if(entity and entity:HasRealPhysics())then
		local canDropOnMountPoints;
		if(entity:GetMountPoints() and entity:GetMountPoints():GetCount() > 0) then
			-- check we will drop to the closest mount point that is lower than y
			local closestDist = 9999
			for i = 1, entity:GetMountPoints():GetCount() do
				local x2, y2, z2 = entity:GetMountPoints():GetMountPositionInWorldSpace(i)
				if(y >= y2) then
					local dist = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
					if(dist < closestDist and dist <= BlockEngine.blocksize * 0.5) then
						local totalStackHeight = self:GetStackHeightOnLocation(srcEntity, x2, y2, z2, true, entity)
						if(totalStackHeight) then
							x, y, z = x2, y2 + totalStackHeight, z2;
							dropLocation.target = entity;
							dropLocation.mountPointIndex = i;
							dropLocation.facing = entity:GetMountPoints():GetMountFacingInWorldSpace(i)
							canDropOnMountPoints = true;
						end
					end
				end
			end
		end
		if(not canDropOnMountPoints) then
			-- we will drop to physical mesh interaction point
			local totalStackHeight = self:GetStackHeightOnLocation(srcEntity, x1, y1, z1)
			if(totalStackHeight) then
				x, y, z = x1, y1+totalStackHeight, z1;
				dropLocation.target = entity;
				dropLocation.mountPointIndex = -1;
			end
		end
	end

	local block_id, solid_y, x1, y1, z1 = self:GetFirstObstructionBlockBelow(dropLocation.dropX, dropLocation.dropY+0.1, dropLocation.dropZ)
	if(block_id) then
		if((not dropLocation.mountPointIndex) or y1 > y) then
			-- we will drop to block's bottom center
			local totalStackHeight = self:GetStackHeightOnLocation(srcEntity, x1, y1, z1)
			if(totalStackHeight) then
				x, y, z = x1, y1+totalStackHeight, z1;
				dropLocation.target = block_id;
				dropLocation.mountPointIndex = nil;
			end
		end
	end
	dropLocation.dropX, dropLocation.dropY, dropLocation.dropZ = x, y, z;
end

-- we will see the target location's four directions, and if there is a nearby wall, we will return the walls facing. 
-- @param entity: this is usually the dragging entity.
-- @param x, y, z: usually the drop location of the entity. if nil, we will use the entity's current position. 
-- @param radius: default to half block size
function ItemLiveModel:GetNearbyWallFacing(entity, x, y, z, radius)
	if(not x) then
		x, y, z = entity:GetPosition()
	end
	if(not radius) then
		radius = BlockEngine.half_blocksize + 0.01;
	end
	local bx, by, bz = BlockEngine:block(x, y + 0.1, z)
	local bfx, bfy, bfz = BlockEngine:block_float(x, y+0.1, z)
	local distSqWall = 999;
	local wallSide;
	local wallFacing;
	for side = 0, 3 do
		local dx, dy, dz = Direction.GetOffsetBySide(side);
		local block = BlockEngine:GetBlock(bx + dx, by, bz + dz)
		if(block and block.obstruction) then
			local distSq = (dx~=0 and math.abs(bx + dx/2 + 0.5 - bfx) or math.abs(bz + dz/2 + 0.5 - bfz)) ^ 2
			if(distSq < distSqWall)  then
				distSqWall = distSq
				wallSide = side;
				wallFacing = Direction.directionTo3DFacing[wallSide]
			end
		end
		local entity, x1, y1, z1 = self:RayPickPhysicalLiveModel(x, y, z, dx, 0, dz, radius)
		if(entity and x1) then
			local distSq = (x1 - x) ^ 2 + (z1 - z) ^ 2
			if(distSq < distSqWall)  then
				distSqWall = distSq
				wallSide = side;
				wallFacing = Direction.directionTo3DFacing[wallSide]
			end
		end
	end
	return wallFacing;
end


-- @param x, y, z: real world position, where x, z is usually near block center. 
-- return block_id, blockY, realX, realY, realZ
function ItemLiveModel:GetFirstObstructionBlockBelow(x, y, z)
	local bx, by, bz = BlockEngine:block(x, y, z)
	-- if first block is obstruction, we will try at most two blocks above. 
	local b = BlockEngine:GetBlock(bx, by, bz)
	local offset = 1;
	if(b and b.obstruction) then
		local bSearchUpward = true;
		if(not self.solid) then
			local aabb = b:GetCollisionBoundingBoxFromPool(bx,by,bz)
			if(aabb and not aabb:ContainsPoint(x, y, z)) then
				bSearchUpward = false
				local _, minY, _ = aabb:GetMinValues()
				if(y < minY) then
					offset = 0
				else
					offset = 1
				end
			end
		end
		if(bSearchUpward) then
			b = BlockEngine:GetBlock(bx, by+1, bz)
			if(b and b.obstruction) then
				b = BlockEngine:GetBlock(bx, by+2, bz)
				if(b and b.obstruction) then
					-- no drop location can be found. 
				else
					offset = 2
				end
			else
				offset = 1
			end
		end
	else
		offset = 0
	end
	local block = commonlib.gettable("MyCompany.Aries.Game.block");
	local block_id, solid_y = BlockEngine:GetNextBlockOfTypeInColumn(bx,by+offset,bz, block.attributes.obstruction, maxFallDistance)
	if(block_id) then
		local x1, y1, z1 = BlockEngine:real_bottom(bx, solid_y + 1, bz)
		local blockTemplate = block_types.get(block_id);
		if(blockTemplate) then
			local aabb = blockTemplate:GetCollisionBoundingBoxFromPool(bx, solid_y, bz)
			if(aabb) then
				local _, topY, _ = aabb:GetMaxValues()
				y1 = topY;
			end
		end
		return block_id, solid_y, x1, y1, z1;
	end
end

-- return true if there is no solid blocks or physical meshes between the eye position and the given point
-- @param x,y,z: a point in 3d world space
-- @return boolean
function ItemLiveModel:CanSeePoint(x, y, z)
	local eyePos = Cameras:GetCurrent():GetEyePosition()
	local eyeX, eyeY, eyeZ = eyePos[1], eyePos[2], eyePos[3]
	
	local dir = mathlib.vector3d:new_from_pool(x - eyeX, y - eyeY, z - eyeZ)
	local length = dir:length();
	dir:normalize()
	local dirX, dirY, dirZ = dir[1], dir[2], dir[3];
	
	-- try picking physical mesh
	local pt = ParaScene.Pick(eyeX, eyeY, eyeZ, dirX, dirY, dirZ, length + 0.1, "point")
	if(pt:IsValid())then
		local x1, y1, z1 = pt:GetPosition()
		if((((x1-x)^2) + ((y1 - y)^2) + ((z1-z) ^2)) > 0.001) then
			return false;
		end
	end
	-- try to pick block 
	if(BlockEngine:RayPicking(eyeX, eyeY, eyeZ, dirX, dirY, dirZ, length - 0.1)) then
		return false;
	end
	return true
end


-- @param x,y,z: ray origin in world space
-- @param dirX, dirY, dirZ: ray direction, default to 0, -1, 0
-- @param maxDistance: default to 10
-- @return entityLiveModel, hitX, hitY, hitZ: return entity live model that is hit by the ray. 
function ItemLiveModel:RayPickPhysicalLiveModel(x, y, z, dirX, dirY, dirZ, maxDistance)
	local pt = ParaScene.Pick(x, y, z, dirX or 0, dirY or -1, dirZ or 0, maxDistance or 10, "point")
	if(pt:IsValid())then
		local entityName = pt:GetName();
		if(entityName and entityName~="") then
			local entity = EntityManager.GetEntity(entityName);
			if(entity and entity:isa(EntityManager.EntityLiveModel)) then
				local x1, y1, z1 = pt:GetPosition();
				return entity, x1, y1, z1;
			end
		end
	end
end

-- get top draggable entity in vertical range (0,1), whose x, z coordinates are almost the same. 
-- please note srcEntity may already be top entity and will be returned. 
-- @return topEntity: 
function ItemLiveModel:GetTopStackEntityFromEntity(srcEntity)
	if(srcEntity) then
		local topEntity = srcEntity;
		-- for object with mount points or physics or non-stackable, or object that has attached to some other object, it is always the top entity. 
		if(not srcEntity:HasMountPoints() and not srcEntity:HasRealPhysics() and srcEntity:IsStackable() and not srcEntity:GetLinkToTarget()) then
			local x, y, z = srcEntity:GetPosition()
			local MountedEntityCount = 0;
			local mountedEntities = EntityManager.GetEntitiesByAABBOfType(EntityManager.EntityLiveModel, ShapeAABB:new_from_pool(x, y+0.5, z, 0.1, 0.55, 0.1, true))
			if(mountedEntities) then
				table.sort(mountedEntities, function(left, right)
					local _, y1, _ = left:GetPosition()
					local _, y2, _ = right:GetPosition()
					return y1 < y2;
				end)
				-- stackable object are always picked first. 
				local bFoundEntity
				for _, entity in ipairs(mountedEntities) do
					if(entity ~= topEntity and entity:GetCanDrag()) then
						local x1, y1, z1 = entity:GetPosition()
						if(not entity:IsStackable()) then
							topEntity = entity;
							y = y1;
							bFoundEntity = true
							break;
						end
					end
				end
				if(not bFoundEntity) then
					-- now check for stackable entities on top
					for _, entity in ipairs(mountedEntities) do
						if(entity ~= topEntity and entity:GetCanDrag()) then
							local x1, y1, z1 = entity:GetPosition()
							if(entity:IsStackable()) then
								if(y1 > y) then
									local distSq = ((x1 - x)^2) + ((z1 - z)^2);
									if(distSq < 0.02) then
										-- vertically stacked and with correct stack height
										if(math.abs(topEntity:GetStackHeight() + y - y1) < 0.01) then
											topEntity = entity;
											y = y1;
											bFoundEntity = true
										else
											break;
										end
									end
								end
							end
						end
					end
				end
			end
		end
		return topEntity;
	end
end

-- @param draggingEntity: the entity that is dragging
-- @param x, y, z: mount point position. 
-- @param isMountPoint: if this is a mount point
-- @param targetEntity: if the x, y, z belongs to a point on targetEntity, this is provided. 
-- @return preferred stackHeight over x, y, z: if nil, it means that we can not stack on the location. 
function ItemLiveModel:GetStackHeightOnLocation(draggingEntity, x, y, z, isMountPoint, targetEntity)
	local totalStackHeight;

	if(isMountPoint) then
		local isMountedEntitiesStackable;
		local MountedEntityCount = 0;
		local mountedEntities = EntityManager.GetEntitiesByAABBOfType(EntityManager.EntityLiveModel, ShapeAABB:new_from_pool(x, y+0.5, z, 0.1, 0.55, 0.1, true))
		if(mountedEntities) then
			for _, entity in ipairs(mountedEntities) do
				if(not entity:HasLinkParent(draggingEntity) and entity~=targetEntity) then
					if(entity:GetLinkToTarget() == targetEntity) then
						local x1, y1, z1 = entity:GetPosition();
						if(math.abs(x1 - x) + math.abs(z1 - z) < 0.1) then
							MountedEntityCount = MountedEntityCount + 1
							if(entity:IsStackable()) then
								totalStackHeight = (totalStackHeight or 0) + entity:GetStackHeight();
								isMountedEntitiesStackable = true
							end
						end
					end
				end
			end
		end
		-- do not mount on point if they are non-stackable objects
		if(MountedEntityCount == 0 or (isMountedEntitiesStackable and draggingEntity:IsStackable())) then
			return totalStackHeight or 0
		end
	else
		totalStackHeight = 0
		local isMountedEntitiesStackable;
		local MountedEntityCount = 0;
		local mountedEntities = EntityManager.GetEntitiesByAABBOfType(EntityManager.EntityLiveModel, ShapeAABB:new_from_pool(x, y+0.5, z, 0.1, 0.55, 0.1, true))
		if(mountedEntities) then
			table.sort(mountedEntities, function(left, right)
				local _, y1, _ = left:GetPosition()
				local _, y2, _ = right:GetPosition()
				return y1 < y2;
			end)
			if(targetEntity) then
				-- remove all entities below the targetTarget. 
				local count = 0
				for i, entity in ipairs(mountedEntities) do
					if(entity==targetEntity) then
						count = i;
						break;
					end
				end
				while(count > 0) do
					count = count - 1;
					commonlib.removeArrayItem(mountedEntities, 1)
				end
			end
			for _, entity in ipairs(mountedEntities) do
				if(not entity:HasLinkParent(draggingEntity) and entity~=targetEntity) then
					local x1, y1, z1 = entity:GetPosition();
					if((math.abs(x1 - x) + math.abs(z1 - z)) < 0.1) then
						MountedEntityCount = MountedEntityCount + 1
						if(entity:IsStackable() and entity:GetCanDrag()) then
							local x1, y1, z1 = entity:GetPosition()
							local distSq = ((x1 - x)^2) + ((z1 - z)^2);
							if(distSq < 0.02 and (y1-y) > -0.001 and y1 <= (y + 1)) then
								-- vertically stacked
								totalStackHeight = (totalStackHeight or 0) + entity:GetStackHeight();
								isMountedEntitiesStackable = true
							end
						end
					end
				end
			end
		end
		-- do not mount on point if they are non-stackable objects
		if(MountedEntityCount == 0 or (isMountedEntitiesStackable and draggingEntity:IsStackable())) then
			return totalStackHeight or 0
		else
			return 0;
		end
	end
end

-- get nearby drop points, starting from the one that is closest to the eye position. 
-- @return array of {x,y,z}, candidates for nearby drop points close to x, y, z 
function ItemLiveModel:GetNearbyBlockDropPoints(x, y, z)
	local bx, by, bz = BlockEngine:block(x, y+0.1, z);
	local eyePos = Cameras:GetCurrent():GetEyePosition()
	local eyeX, eyeY, eyeZ = eyePos[1], eyePos[2], eyePos[3]
	
	local dir = mathlib.vector3d:new_from_pool(eyeX - x, 0, eyeZ - z)
	local length = dir:length() - 0.1;
	dir:normalize()
	local dx = (dir[1] > 0.7) and 1 or ((dir[1] < -0.7) and -1 or 0)
	local dz = (dir[3] > 0.7) and 1 or ((dir[3] < -0.7) and -1 or 0)
	local points = {}
	points[#points+1] = {BlockEngine:real_bottom(bx+dx, by, bz+dz)}
	if(math.abs(dx) == 1 and math.abs(dz) == 1) then
		points[#points+1] = {BlockEngine:real_bottom(bx+dx, by, bz)}	
		points[#points+1] = {BlockEngine:real_bottom(bx, by, bz+dz)}
	elseif(math.abs(dx) == 1) then
		points[#points+1] = {BlockEngine:real_bottom(bx+dx, by, bz+1)}	
		points[#points+1] = {BlockEngine:real_bottom(bx+dx, by, bz-1)}
	else
		points[#points+1] = {BlockEngine:real_bottom(bx+1, by, bz+dz)}	
		points[#points+1] = {BlockEngine:real_bottom(bx-1, by, bz+dz)}
	end
	return points;
end

-- get nearby drop points, starting from the one that is closest to the eye position. 
-- @param targetEntity: which physical model to drop upon. 
-- @param x, y, z: this is usually a hit point on targetEntity's physical mesh. 
-- @param objRadius: default to 0.  we have to ensure that the drop point is almost flat in the given radius for the drop to be valid. 
--  this is usually the aabb radius of the dropping object in xz plane. 
--  we will sort result, where the drop point that is big enough to contain the object is moved to the front.
-- @param gridSize: default to targetEntity:GetGridSize() or 0.25.
-- @return array of {x,y,z}, candidates for nearby drop points close to x, y, z 
function ItemLiveModel:GetNearbyPhysicalModelDropPoints(targetEntity, x, y, z, objRadius, gridSize)
	if(targetEntity and targetEntity:HasRealPhysics()) then
		if(not gridSize and targetEntity.GetGridSize) then
			gridSize = targetEntity:GetGridSize()
		end
		gridSize = gridSize or (0.25 * BlockEngine.blocksize);
		
		x, z = mathlib.SnapToGrid(x, gridSize), mathlib.SnapToGrid(z, gridSize)
		local eyePos = Cameras:GetCurrent():GetEyePosition()
		local eyeX, eyeY, eyeZ = eyePos[1], eyePos[2], eyePos[3]
	
		local dir = mathlib.vector3d:new_from_pool(eyeX - x, 0, eyeZ - z)
		local length = dir:length() - 0.1;
		dir:normalize()
		local dx = (dir[1] > 0.7) and 1 or ((dir[1] < -0.7) and -1 or 0)
		local dz = (dir[3] > 0.7) and 1 or ((dir[3] < -0.7) and -1 or 0)
		local points = {}

		local function addPoint_(x, y, z)
			local maxFallDistance = 10;
			local entity, x1, y1, z1 = self:RayPickPhysicalLiveModel(x, y+0.1, z, 0, -1, 0, maxFallDistance)
			if(entity == targetEntity) then
				points[#points+1] = {x1, y1, z1}
			end
		end
		addPoint_(x, y, z)
		addPoint_(x+dx*gridSize, y, z+dz*gridSize)
		if(math.abs(dx) == 1 and math.abs(dz) == 1) then
			addPoint_(x+dx*gridSize, y, z)	
			addPoint_(x, y, z+dz*gridSize)
		elseif(math.abs(dx) == 1) then
			addPoint_(x+dx*gridSize, y, z+1*gridSize)	
			addPoint_(x+dx*gridSize, y, z-1*gridSize)
		else
			addPoint_(x+1*gridSize, y, z+dz*gridSize)	
			addPoint_(x-1*gridSize, y, z+dz*gridSize)
		end
		if(objRadius and objRadius > 0.1) then
			-- sorting result, the drop point that is big enough to contain the object is moved to the front
			for index = 1, #points do
				local point = points[index];
				local x, y, z = point[1], point[2], point[3];
				local count = 6;
				local isBigEnough = true;
				-- try replacing with best height
				if(not points[1].isBigEnough or math.abs(points[1][2]-y) > math.abs(points[index][2]-y)) then
					for i = 1, count do
						local angle = math.pi * 2 / count * i;
						local x1 = x + math.cos(angle) * objRadius
						local z1 = z + math.sin(angle) * objRadius
						local maxFlatDiff = 0.2
						local entity, x1, y1, z1 = self:RayPickPhysicalLiveModel(x1, y+0.1, z1, 0, -1, 0, maxFlatDiff+0.1)
						if(entity ~= targetEntity or (y1 - y) >= maxFlatDiff) then
							isBigEnough = false
							break;
						end
					end
					if(isBigEnough) then
						points[index].isBigEnough = true;
						-- try replacing with best height
						points[1], points[index] = points[index], points[1]
					end
				end
			end
		end
		return points;
	end
end

function ItemLiveModel:UpdateDraggingEntity(draggingEntity, result, targetEntity)
	if(not result) then
		result, targetEntity = self:CheckMousePick()
	end
	if(draggingEntity) then
		local dragParams = draggingEntity.dragParams;
		local hasFound;
		-- finding a right location to put down.
		if(targetEntity) then
			if(targetEntity:GetMountPointsCount() > 0) then
				local bInside, mp, distance;
				if(targetEntity:HasRealPhysics() and result.x) then
					-- for physical model, we need to check if hit point is inside the AABB of mount points. 	
					bInside, mp = targetEntity:GetMountPoints():IsPointInMountPointAABB(result.x, result.y, result.z, 0, 0.1, 0)
				else
					mp, distance = targetEntity:GetMountPoints():GetMountPointByXY();
				end
				if(mp) then
					local x, y, z = targetEntity:GetMountPoints():GetMountPositionInWorldSpace(mp:GetIndex())
					local totalStackHeight = self:GetStackHeightOnLocation(draggingEntity, x, y, z, true, targetEntity)
					if(totalStackHeight) then
						local dropX, dropY, dropZ = x, y + totalStackHeight, z;
						local facing = targetEntity:GetMountPoints():GetMountFacingInWorldSpace(mp:GetIndex())
						if(targetEntity:HasRealPhysics()) then
							if(result.x) then
								x, y, z = result.x, result.y, result.z;
							end
						else
							local x1, y1, z1 = SelectionManager:GetMouseInteractionPointWithAABB(targetEntity:GetInnerObjectAABB());
							if(x1) then
								x, y, z = x1, y1, z1
							end
						end
						dragParams.dropLocation = {target = targetEntity, dropX = dropX, dropY = dropY, dropZ = dropZ, x = x, y = y, z = z, mountPointIndex = mp:GetIndex(), mountFacing = facing}
						hasFound = true	
					end
				end
			end
			if(not hasFound and targetEntity:HasRealPhysics() and result.x) then
				-- try nearby drop points. 
				local x, y, z = result.x, result.y, result.z
				local dropX, dropY, dropZ = x, y, z;
				local radius = draggingEntity.GetDropRadius and draggingEntity:GetDropRadius();
				local points = self:GetNearbyPhysicalModelDropPoints(targetEntity, dropX, dropY, dropZ, radius)
				if(points) then
					for _, point in ipairs(points) do
						if(self:CanSeePoint(point[1], point[2], point[3])) then
							dropX, dropY, dropZ = point[1], point[2], point[3];
							hasFound = true	
							local totalStackHeight = self:GetStackHeightOnLocation(draggingEntity, x, y, z, false, targetEntity)
							dropY = dropY + (totalStackHeight or 0);
							local facing = self:GetNearbyWallFacing(draggingEntity, (x + dropX) / 2, dropY, (z + dropZ) / 2)
							dragParams.dropLocation = {target = targetEntity, x=x, y=y, z=z, dropX = dropX, dropY = dropY, dropZ = dropZ, mountPointIndex = -1, facing = facing}
							break;
						end
					end
				end
			end

			-- is custom char item mounting character. 
			if(not hasFound and self:CanEntityReceiveCustomCharItem(targetEntity, self.draggingEntity)) then
				local x, y, z = result.x, result.y, result.z
				if(x) then
					local aabb = targetEntity:GetInnerObjectAABB()
					x, y, z = SelectionManager:GetMouseInteractionPointWithAABB(aabb);
					if(x) then
						dragParams.dropLocation = {target = targetEntity, x=x, y=y, z=z, dropX = x, dropY = y, dropZ = z, mountPointIndex = -1, isCustomCharItem = true}
						hasFound = true
					end
				end
			end

			if(not hasFound and targetEntity:GetLinkToTarget()) then
				local linkTarget = targetEntity:GetLinkToTarget()
				local x, y, z = targetEntity:GetPosition();
				if(linkTarget:GetMountPoints()) then
					local mp = linkTarget:GetMountPoints():GetMountPointByXYZ(x, y, z, true)
					if(mp) then
						local x, y, z = linkTarget:GetMountPoints():GetMountPositionInWorldSpace(mp:GetIndex())
						local totalStackHeight = self:GetStackHeightOnLocation(draggingEntity, x, y, z, true, linkTarget)
						if(totalStackHeight) then
							local dropX, dropY, dropZ = x, y + totalStackHeight, z;
							local facing = linkTarget:GetMountPoints():GetMountFacingInWorldSpace(mp:GetIndex())

							local bHasIntersectPoint;
							if(not targetEntity:HasRealPhysics()) then
								local x1, y1, z1 = SelectionManager:GetMouseInteractionPointWithAABB(targetEntity:GetInnerObjectAABB());
								if(x1) then
									x, y, z = x1, y1, z1
									bHasIntersectPoint = true
								end
							end
							if(not bHasIntersectPoint) then
								if(result.physicalX) then
									x, y, z = result.physicalX, result.physicalY, result.physicalZ
								elseif(result.x) then
									x, y, z = result.x, result.y, result.z;
								end
							end
							dragParams.dropLocation = {target = targetEntity, dropX = dropX, dropY = dropY, dropZ = dropZ, x = x, y = y, z = z, mountPointIndex = mp:GetIndex(), mountFacing = facing}
							hasFound = true	
						end	
					end
				end
				if(not hasFound) then
					-- most likely, linkTarget has real physics, we will stack on top of the linked entity. 
					local totalStackHeight = self:GetStackHeightOnLocation(draggingEntity, x, y, z)
					if(totalStackHeight) then
						local dropX, dropY, dropZ = x, y + totalStackHeight, z;

						local bHasIntersectPoint;
						if(not targetEntity:HasRealPhysics()) then
							local x1, y1, z1 = SelectionManager:GetMouseInteractionPointWithAABB(targetEntity:GetInnerObjectAABB());
							if(x1) then
								x, y, z = x1, y1, z1
								bHasIntersectPoint = true
							end
						end
						if(not bHasIntersectPoint) then
							if(result.physicalX) then
								x, y, z = result.physicalX, result.physicalY, result.physicalZ
							elseif(result.x) then
								x, y, z = result.x, result.y, result.z;
							end
						end
						local facing = self:GetNearbyWallFacing(draggingEntity, (x + dropX) / 2, dropY, (z + dropZ) / 2)
						dragParams.dropLocation = {target = linkTarget, dropX = dropX, dropY = dropY, dropZ = dropZ, x = x, y = y, z = z, mountPointIndex = -1, facing = facing}
						hasFound = true	
					end
				end
			end
		end
		if(not hasFound and result.blockX) then
			-- try free fall on to blocks, mount point or pure physical meshes. 
			-- we will only free fall on block centers even for physical meshes
			local x, y, z;
			local bx, by, bz = BlockEngine:GetBlockIndexBySide(result.blockX, result.blockY, result.blockZ, result.side);
			
			if(result.x) then
				x, y, z = result.x, result.y, result.z;
				if(targetEntity and not targetEntity:HasRealPhysics()) then
					local x1, y1, z1 = SelectionManager:GetMouseInteractionPointWithAABB(targetEntity:GetInnerObjectAABB());
					if(x1) then
						x, y, z = x1, y1, z1
					else
						x, y, z = result.physicalX or result.blockRealX or x, result.physicalY or result.blockRealY or y, result.physicalZ or result.blockRealZ or z;
					end
				end
			else
				x, y, z = BlockEngine:real_bottom(bx, by, bz)
			end
			local dropX, dropY, dropZ = BlockEngine:real_bottom(bx, by, bz)
			dropY = y;

			-- we have to ensure that we can see the drop point without any block of physical mesh blocking it from the current eye position. 
			if(not self:CanSeePoint(dropX, dropY, dropZ)) then
				-- try nearby drop points. 
				local points = self:GetNearbyBlockDropPoints(dropX, dropY, dropZ)
				if(points) then
					for _, point in ipairs(points) do
						if(self:CanSeePoint(point[1], dropY, point[3])) then
							dropX, dropY, dropZ = point[1], dropY, point[3];
							break;
						end
					end
				end
			end
			local facing = self:GetNearbyWallFacing(draggingEntity, (x + dropX) / 2, dropY, (z + dropZ) / 2)
			dragParams.dropLocation = {target = result.block_id, x=x, y=y, z=z, dropX = dropX, dropY = dropY, dropZ = dropZ, bx = bx, by = by, bz = bz, side = 5, facing = facing}
			self:CalculateFreeFallDropLocation(draggingEntity, dragParams.dropLocation);	
		end
		if(dragParams.dropLocation) then
			-- make the model a bit higher than the drop location. 
			local dragDisplayOffsetY = 0.3;
			local x, y, z = dragParams.dropLocation.x, dragParams.dropLocation.y + dragDisplayOffsetY, dragParams.dropLocation.z;
			local oldX, oldY, oldZ = draggingEntity:GetPosition()
			
			self:UpdateEntityDragAnim(draggingEntity, x, y, z, oldX, oldY, oldZ)
		end
	end
end

function ItemLiveModel:StopSmoothMoveTo(draggingEntity)
	self:SmoothMoveTo(draggingEntity)
end

-- @param facing: targetFacing
-- @param newX, newY, newZ: target location. 
function ItemLiveModel:SmoothMoveTo(draggingEntity, facing, newX, newY, newZ)
	local bReached = true;
	if(newX) then
		draggingEntity:SetPosition(newX, newY, newZ)
	end
	-- turning speed per tick
	local turningSpeed = 0.17
	if(facing) then
		draggingEntity.targetFacing = facing;
		local newFacing;
		newFacing, bReached = mathlib.SmoothMoveAngle(draggingEntity:GetFacing(), facing, turningSpeed)
		draggingEntity:SetFacing(newFacing)
	end
	if(facing or newX) then
		draggingEntity.smoothAnimTimer = draggingEntity.smoothAnimTimer or commonlib.Timer:new({callbackFunc = function(timer)
			local bReached = true
			if(draggingEntity.targetFacing) then
				local newFacing, bReached1 = mathlib.SmoothMoveAngle(draggingEntity:GetFacing(), draggingEntity.targetFacing, turningSpeed)
				draggingEntity:SetFacing(newFacing)
				if(bReached1) then
					draggingEntity.targetFacing = nil;
				end
				bReached = bReached and bReached1;
			end
			if(draggingEntity.motionSpeed) then
				draggingEntity.motionSpeed = math.max(0, draggingEntity.motionSpeed - math.max(draggingEntity.motionSpeed*0.2, 0.1));
				bReached = bReached and (draggingEntity.motionSpeed == 0);
				self:UpdateEntityAnimationByMotionSpeed(draggingEntity, draggingEntity.motionSpeed)
			end
			if(bReached) then
				draggingEntity:SetAnimation(draggingEntity:GetIdleAnim());
				timer:Change()
			end
		end})
		draggingEntity.smoothAnimTimer:Change(30, 30)
		self:UpdateEntityAnimationByMotionSpeed(draggingEntity, draggingEntity.motionSpeed)
	elseif(draggingEntity.smoothAnimTimer) then
		draggingEntity:SetAnimation(draggingEntity:GetIdleAnim());
		draggingEntity.smoothAnimTimer:Change()
	end
end

function ItemLiveModel:UpdateEntityAnimationByMotionSpeed(entity, motionSpeed)
	if(motionSpeed) then
		local animId = 0
		if(motionSpeed > 0.1) then
			animId = 5;
		end
		entity:SetAnimation(animId);
	end
end

function ItemLiveModel:UpdateEntityDragAnim(draggingEntity, newX, newY, newZ, oldX, oldY, oldZ)
	-- update motionSpeed;
	local dragParams = draggingEntity.dragParams;
	if(not dragParams) then
		return
	end
	draggingEntity.motionSpeed = (draggingEntity.motionSpeed or 0) + math.sqrt((newX - oldX) ^ 2) + ((newY - oldY) ^ 2) + ((newZ - oldZ) ^ 2)
	draggingEntity.motionSpeed = math.min(2, draggingEntity.motionSpeed);

	local targetFacing;
	if(draggingEntity:IsAutoTurningDuringDragging()) then
		if(dragParams.dropLocation and (dragParams.dropLocation.mountFacing or dragParams.dropLocation.facing)) then
			targetFacing = dragParams.dropLocation.mountFacing or dragParams.dropLocation.facing
		else
			-- the user will drag at least this distance before we will recalculate facing relative to last position. 
			local minTurningDragDistance = 0.2
			dragParams.lastFacingX = dragParams.lastFacingX or newX
			dragParams.lastFacingZ = dragParams.lastFacingZ or newZ

			local length = math.sqrt(((newX - dragParams.lastFacingX) ^ 2) + ((newZ - dragParams.lastFacingZ) ^ 2))
			if(length > minTurningDragDistance) then
				dragParams.lastFacingX, dragParams.lastFacingZ = newX, newZ;
				targetFacing = Direction.GetFacingFromOffset(newX - oldX, 0, newZ - oldZ)
			end	
		end
	end
	self:SmoothMoveTo(draggingEntity, targetFacing, newX, newY, newZ)
end

local hoverInterval = 1500; -- ms
local maxHoverMoveDistance = 10; -- pixels

-- return isHover, hoverOnEntity: the first return value is true, if it is already a hover event. 
-- the second parameter is the entity that is hovered on by the draggingEntity. 
function ItemLiveModel:UpdateOnHoverMousePointAABB(event, bReset)
	self.hoverTimer = self.hoverTimer or commonlib.Timer:new({callbackFunc = function(timer)
		if(not self.draggingEntity) then
			timer:Change();
		else
			self:UpdateOnHoverMousePointAABB()
		end
	end})
	self.hoverTimer:Change(200, 200);
	if(bReset) then 
		self.mousePointAABB = self.mousePointAABB or mathlib.ShapeAABB:new();
		if(event) then
			self.mousePointAABB:SetPointAABB(mathlib.vector3d:new({event.x, event.y, 0}))
		end
		self.hoverBeginTime = commonlib.TimerManager.GetCurrentTime();
		self.lastHoverDraggingEntity = self.draggingEntity
		if(self.draggingEntity and self.draggingEntity.dragParams and self.draggingEntity.dragParams.dropLocation) then
			self.lastHoverOnEntity = self.draggingEntity.dragParams.dropLocation.target;
		else
			self.lastHoverOnEntity = nil;
		end
		
	elseif(self.hoverBeginTime and self.mousePointAABB) then
		local curHoverOnEntity;
		if(self.draggingEntity and self.draggingEntity.dragParams and self.draggingEntity.dragParams.dropLocation) then
			curHoverOnEntity = self.draggingEntity.dragParams.dropLocation.target;
		end

		local curTime = commonlib.TimerManager.GetCurrentTime();
		if(event) then
			self.mousePointAABB:Extend(event.x, event.y, 0)
		end
		local maxDiff = self.mousePointAABB:GetMaxExtent()
		if(maxDiff > maxHoverMoveDistance or not curHoverOnEntity or (curHoverOnEntity~=self.lastHoverOnEntity or self.draggingEntity~=self.lastHoverDraggingEntity)) then
			self:UpdateOnHoverMousePointAABB(event, true)
		elseif( (curTime - self.hoverBeginTime) > hoverInterval and self.draggingEntity) then
			self:UpdateOnHoverMousePointAABB(event, true)

			local hoverOnEntity = self.lastHoverOnEntity;
			if(type(hoverOnEntity) == "table" and hoverOnEntity.OnHover) then
				hoverOnEntity:OnHover(self.draggingEntity)
			end
			return true, self.lastHoverOnEntity;
		end
	end
end

function ItemLiveModel:mouseMoveEvent(event)
	if(self.mousePressEntity) then
		event:accept();
	end

	if(self.mousePressEntity and event:GetDragDist() > 20) then
		if(not self.draggingEntity) then
			local topEntity = self:GetTopStackEntityFromEntity(self.mousePressEntity)
			if(topEntity and topEntity:GetCanDrag()) then
				self:StartDraggingEntity(topEntity)
				self:UpdateOnHoverMousePointAABB(event, true)
			end
		end
	end
	local result, targetEntity = self:CheckMousePick()
	if(self.draggingEntity) then
		self:UpdateDraggingEntity(self.draggingEntity, result, targetEntity)
		self:UpdateOnHoverMousePointAABB(event)
	end
end

-- drag and drop is disabled when the entity is being dragged or dropped. 
function ItemLiveModel:CanDragDropEntity(entity)
	return entity and entity.dropAnimTimer == nil and entity:GetCanDrag()
end

function ItemLiveModel:StartDraggingEntity(entity)
	if(self.draggingEntity) then
		self:DropDraggingEntity()
	end
	self.draggingEntity = entity;

	if(GameLogic.GameMode:IsEditor()) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
		local task = MyCompany.Aries.Game.Tasks.DragEntity:new({})
		task:StartDraggingEntity(entity);
		entity.dragTask = task;
	end
	
	local dragParams = {
		pos = {entity:GetPosition()},
		facing = entity:GetFacing(),
		hasRealPhysics = entity:HasRealPhysics(),
	};
	entity:BeginDrag();
	entity:UnLink();
			
	entity.dragParams = dragParams;
end

function ItemLiveModel:play_drop_sound(x,y,z)
	if(self.create_sound) then
		self.create_sound:play2d();
	end
end

function ItemLiveModel:MountEntityToTargetMountPoint(entity, mountTarget, mountPointIndex)
	if(entity and mountTarget) then
		entity:MountTo(mountTarget, mountPointIndex, true)
	end
end

-- drop entity to the 3d scene or on other entity
function ItemLiveModel:DropEntity(entity)
	if(entity and entity.dragParams and entity.dragParams.dropLocation.x) then
		self:StopSmoothMoveTo(entity);
		local dragParams = entity.dragParams;
		local destX, destY, destZ, facing = dragParams.dropLocation.dropX or dragParams.dropLocation.x, dragParams.dropLocation.dropY or dragParams.dropLocation.y, dragParams.dropLocation.dropZ or dragParams.dropLocation.z, dragParams.dropLocation.facing;
		-- drop animation
		local fromX, fromY, fromZ = entity:GetPosition()
		
		local t_xz = 0;
		local t_y = 0;
		local speedY = 0;
		entity.dropAnimTimer = commonlib.Timer:new({callbackFunc = function(timer)
			-- move with constant speed horizontally, and with some gravity accelerations vertically.  
			t_xz = math.min(1, t_xz + 0.2);
			t_y = math.min(1, t_y + speedY);
			speedY = speedY + 0.1;
			local x = fromX * (1 - t_xz) + destX * t_xz;
			local y = fromY * (1 - t_y) + destY * t_y;
			local z = fromZ * (1 - t_xz) + destZ * t_xz;
			entity:SetPosition(x, y, z)
			if(t_xz == 1 and t_y == 1) then
				if(dragParams.dropLocation.isCustomCharItem and dragParams.dropLocation.target) then
					-- only send mount event, without actually linking the dragging entity to target, the target will handle mount operation by itself. 
					dragParams.dropLocation.target:OnMount(nil, nil, entity)
				elseif(dragParams.dropLocation.mountPointIndex and dragParams.dropLocation.target) then
					self:MountEntityToTargetMountPoint(entity, dragParams.dropLocation.target, dragParams.dropLocation.mountPointIndex)
				end
				timer:Change();
				entity.dropAnimTimer = nil;
				self:play_drop_sound();
				if(entity.dragTask) then
					entity.dragTask:DropDraggingEntity()
					entity.dragTask = nil;
				end
				entity:EndDrag()
			end
		end})
		entity.dropAnimTimer:Change(30, 30)

		if(facing) then
			entity:SetFacing(facing);
		end
	elseif(entity) then
		-- restore to previous location or just leave as it is
		entity:EndDrag()
	end
end


function ItemLiveModel:DropDraggingEntity()
	local entity = self.draggingEntity;
	if(entity) then
		local dragParams = entity.dragParams
		if(dragParams) then
			self:DropEntity(entity)
			entity.dragParams = nil;
		end
		self.draggingEntity = nil

		if(not GameLogic.GameMode:IsEditor()) then
			GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.live_model.drag", { projectId = GameLogic.options:GetProjectId() or 0, filename = entity:GetModelFile(), name = entity:GetName()});
		end
	end
	Game.SelectionManager:SetEntityFilterFunction(nil)
end

-- only spawn entity if player is holding a LiveModel item in right hand. 
-- @param serverdata: default to item stack in player's hand item
function ItemLiveModel:SpawnNewEntityModel(bx, by, bz, facing, serverdata)
	local filename, xmlNode;
	if(not serverdata) then
		local itemStack = EntityManager.GetPlayer().inventory:GetItemInRightHand()
		if(itemStack and itemStack.id == block_types.names.LiveModel) then
			filename = itemStack:GetDataField("tooltip");
			xmlNode = itemStack:GetDataField("xmlNode");
			if(xmlNode and xmlNode.attr) then
				xmlNode.attr.x = nil;
				xmlNode.attr.y = nil;
				xmlNode.attr.z = nil;
				xmlNode.attr.bx = nil;
				xmlNode.attr.by = nil;
				xmlNode.attr.bz = nil;
				xmlNode.attr.name = nil;
				xmlNode.attr.linkTo = nil;
				xmlNode.class = nil;
				xmlNode.item_id = nil;
			end
		end
	end
	if(not filename or filename == "") then
		return;
	end
	if (not facing) then
		facing = Direction.GetFacingFromCamera()
		facing = Direction.NormalizeFacing(facing)
	end
	local entity = EntityManager.EntityLiveModel:Create({bx=bx,by=by,bz=bz, 
		item_id = block_types.names.LiveModel, facing=facing}, xmlNode);
	if(not xmlNode) then
		entity:SetModelFile(filename)
	end
	entity:Refresh();
	entity:Attach();
	return entity
end


function ItemLiveModel:mouseReleaseEvent(event)
	local result, targetEntity = self:CheckMousePick()
	
	if(self.draggingEntity) then
		self:DropDraggingEntity();
		event:accept();
	else
		local normalTargetEntity;
		if(GameLogic.GameMode:IsEditor() and event:button() == "right") then
			-- just in case, we are right click to edit a non-pickable live entity model
			Game.SelectionManager:SetEntityFilterFunction(nil)
			local result = self:MousePickBlock()
			if(result) then
				normalTargetEntity = result.entity
			end
		end			

		if(not event:IsCtrlKeysPressed() and event:isClick()) then
			if(normalTargetEntity) then
				normalTargetEntity:OnClick(result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side)
				event:accept();
			elseif(event:button() == "right") then
				if(result.block_id and result.block_id>0) then
					-- if it is a right click, first try the game logics if it is processed. such as an action neuron block.
					if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
						-- this fixed a bug where block entity is larger than the block like the physics block model.
						local bx, by, bz = result.entity:GetBlockPos();
						isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, EntityManager.GetPlayer(), result.side);
					else
						isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
					end
				end
				if(not isProcessed) then
					local bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
					local entity = self:SpawnNewEntityModel(bx, by, bz)
					if(entity) then
						-- let it fall down: simulate a drag and drop at click point
						self:StartDraggingEntity(entity)
						self:UpdateDraggingEntity(entity, result, targetEntity)
						self:DropDraggingEntity();
						if(entity.dragTask) then
							entity.dragTask:SetCreateMode()
						end
					end
				end
				event:accept();
			end
		end	
	end
	if(self.mousePressEntity) then
		event:accept();
		self.mousePressEntity = nil;
	end
	Game.SelectionManager:SetEntityFilterFunction(nil)
end
