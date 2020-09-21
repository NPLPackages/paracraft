--[[
Title: EntityImage
Author(s): LiPeng, LiXizhi
Date: 2013/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityEntityImage.lua");
local EntityEntityImage = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityEntityImage")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Image3DDisplay.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local Image3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Image3DDisplay");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityImage"));

-- class name
Entity.class_name = "EntityImage";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
--Entity.is_root = false;
Entity.text_offset = {x=0,y=0.45,z=0.315};

Entity.load_image_times = 0;
Entity.modelFile = "model/blockworld/Painting/Painting.x";

local sys_images = {
	["logo"] = "Texture/3DMapSystem/brand/paraworld_text_256X128.png",
	["preview"] = "preview.jpg",
}

Entity.rows_to_top = 0;
Entity.rows_to_bottom = 0;
Entity.columns_to_left = 0;
Entity.columns_to_right = 0;

Entity.maxExpandLength = 200;
Entity.rows = 1;
Entity.columns = 1;
Entity.start_block_coord = nil;
Entity.imagefile_loaded_times = 0;
Entity.texture_for_imagefile = nil;

function Entity:ctor()
end

function Entity:Destroy()
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end


-- return empty collision AABB, since it does not have physics. 
function Entity:GetCollisionAABB()
	if(not self.aabb) then
		self.aabb = ShapeAABB:new();
	end
	return self.aabb;
end

--obsoleted
function Entity:UpdateBlockDataByFacing()
	local x,y,z = self:GetBlockPos();
	local dir_id = Direction.GetDirectionFromFacing(self.facing or 0);
	self.block_data = dir_id;
	BlockEngine:SetBlockData(x,y,z, dir_id);	
end

function Entity:OnBlockAdded(x,y,z, data)
	self.block_data = data or self.block_data or 0;
	self:ScheduleRefresh(x,y,z);
end

-- call init when block is first loaded. 
function Entity:OnBlockLoaded(x,y,z, data)
	self.block_data = data or self.block_data or 0;
	-- backward compatibility, since we used to store facing instead of data in very early version. 
	-- this should never happen in versions after late 2014
	if(self.block_data == 0 and (self.facing or 0) ~= 0) then
		LOG.std(nil, "warn", "info", "fix BlockSign entity facing and block data incompatibility in early version: %d %d %d", self.bx, self.by, self.bz);
		self:UpdateBlockDataByFacing();
	end
	if(not self:RefreshBakedImage()) then
		self:ScheduleRefresh(x,y,z);
	end
end


function Entity:ScheduleRefresh(x,y,z)
	if(not x) then
		x,y,z = self:GetBlockPos();
		self.bNeedUpdate = true;
	else
		local image_entity = EntityManager.GetEntityInBlock(x,y,z,self.class_name);
		if(image_entity) then
			image_entity.bNeedUpdate = true;
		else
			return;
		end
	end
	GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self:GetBlockId(), 1);
end

function Entity:GetImageFilePath()
	local cmd = self.cmd or "";
	cmd = cmd:gsub("^$%(.*%)", "")
	return sys_images[cmd] or cmd;
end

-- self.cmd like $(/loadworld 503)preview.jpg
-- return nil, if inline command does not exist
function Entity:GetInlineCommand()
	if(self.cmd) then
		local cmd = self.cmd:match("^$%((.*)%)")
		if(cmd and cmd~="") then
			return cmd
		end
	end
end

-- return full file name and whether file exist. 
--@return fullname, bExist:  
function Entity:GetFullFilePath(filename)
	local bExist
	local old_filename = filename;
	if(filename and filename~="") then
		if(filename:match("^https?://")) then
			bExist = true;
		else
			filename = filename:gsub("[;:].*$", "")
			if(not ParaIO.DoesAssetFileExist(filename, true)) then
				local filename = Files.GetWorldFilePath(filename);
				if(filename) then
					return ParaWorld.GetWorldDirectory()..old_filename, true;
				end
			else
				bExist = true;
			end
		end
	end
	return old_filename, bExist;
end

function Entity:GetImageFacing()
	return (self.block_data or 0) % 4;
end

-- clean up all nearby paintings which are derived from this one. 
function Entity:ResetDerivedPaintings()
	if(self.start_block_coord and self.rows) then
		local rows = self.rows;
		local columns = self.columns;
		local facing = self:GetImageFacing();

		local start_block_x = self.start_block_coord.x;
		local start_block_y = self.start_block_coord.y;
		local start_block_z = self.start_block_coord.z;

		local block_x = start_block_x;
		local block_y = start_block_y;
		local block_z = start_block_z;

		local get_new_root_entity = false;
		local new_root_entity_coord;
	
		local row_index,column_index;
		for row_index = 1,rows do
			for column_index = 1,columns do
				local image_entity = EntityManager.GetEntityInBlock(block_x,block_y,block_z,self.class_name);
				if(image_entity) then
					image_entity.root_entity_coord = nil; 
					image_entity:SetDerivedImageFilename(nil);
				end

				if(facing == 0) then
					block_z = block_z + 1;
				elseif(facing == 3) then
					block_x = block_x + 1;
				elseif(facing == 1) then
					block_z = block_z - 1;
				elseif(facing == 2) then
					block_x = block_x - 1;
				end
			end

			block_x = start_block_x;
			block_y = block_y - 1;
			block_z = start_block_z;
		end
	else
		self.root_entity_coord = nil; 
		self:SetDerivedImageFilename(nil);
	end
	self:Refresh()
end

local data_expand_dir = {
	zero = {0, 0, 0},
	[0] = {0, 1, -1},
	[1] = {0, 1, 1},
	[2] = {1, 1, 0},
	[3] = {-1, 1, 0},
};

-- return a vector relative to current block. 
function Entity:GetExpandDirectionByData(data)
	return data_expand_dir[data or 0] or data_expand_dir.zero;
end

-- LiXizhi: half-done work: for images on the ground. 
-- @return length_x, length_y, length_z;
function Entity:CalculateLengths()
	-- if any neighbour has EntityImage's block_id but the entity is not ready yet. 
	local bHasInvalidImageEntity;

	-- the root entity information;
	local root_x = self.bx;
	local root_y = self.by;
	local root_z = self.bz;
	local root_block_id = self:GetBlockId();
	local root_block_facing = self:GetImageFacing();

	-- calculate length_x, length_y, length_z;
	local length_x, length_y, length_z;
	local x,y,z = root_x,root_y,root_z;
	local dir = self:GetExpandDirectionByData(self.block_data);
	local bFirstBoundary = true;
	for dx = 0, Entity.maxExpandLength do
		for dy = 0, Entity.maxExpandLength do	
			for dz = 0, Entity.maxExpandLength do
				local lx, ly, lz = dx*dir[1], dy*dir[2], dz*dir[3];
				local x, y, z = root_x+lx, root_y+ly, root_z+lz;
				local neighbor_id = BlockEngine:GetBlockId(x,y,z);
				local bIsBoundary;
				if(root_block_id ~= neighbor_id) then
					bIsBoundary = true;
				else
					local neighbor_entity = EntityManager.GetEntityInBlock(x,y,z,self.class_name);
					if(neighbor_entity) then
						neighbor_facing = neighbor_entity:GetImageFacing();
						if(neighbor_facing ~= root_block_facing or neighbor_entity:HasImage()) then
							bIsBoundary = true;
						end
					else
						bHasInvalidImageEntity = true;
						bIsBoundary = true;
					end
				end
				
				if(bIsBoundary) then
					if(bFirstBoundary) then
						bFirstBoundary = false;
						length_x = (dx > 0) and dx or length_x;
						length_y = (dy > 0) and dy or length_y;
						length_z = (dz > 0) and dz or length_z;
					else
						length_x = (not length_x and dx > 0) and dx or length_x;
						length_y = (not length_y and dy > 0) and dy or length_y;
						length_z = (not length_z and dz > 0) and dz or length_z;
					end
					break;
				end
				if(dir.z == 0 or (length_z and dz >= length_z)) then
					break
				end
			end
			if(dir.y == 0 or (length_y and dy >= length_y)) then
				break
			end
		end
		if(dir.x == 0 or (length_x and dx >= length_x)) then
			break
		end
	end
	self.length_x =	 length_x or 1;
	self.length_y =	 length_y or 1;
	self.length_z =	 length_z or 1;
end

-- only called for the block containing the actual image to calculate the total block 
-- size(self.rows, self.columns) and position(self.start_block_coord) that this block image should be expanded to. 
-- expansion data is written to self.start_block_coord, self.rows,self.columns,
-- @return true if succeed, or false if not ImageEntity has not been properly loaded, such as during RegionLoad time
function Entity:CaculateImageExpansionData()
	-- if any neighbour has EntityImage's block_id but the entity is not ready yet. 
	local bHasInvalidImageEntity;

	-- the root entity information;
	local root_x = self.bx;
	local root_y = self.by;
	local root_z = self.bz;
	local root_block_id = self:GetBlockId();
	local root_block_facing = self:GetImageFacing();

	local top_blocks_number = 0;
	local bottom_blocks_number = 0;
	local left_blocks_number = 0;
	local right_blocks_number = 0;
	

	local x = root_x;
	local y = root_y;
	local z = root_z;

	local neighbor_id,neighbor_facing;
	
	while(true) do
		y = y + 1;
		neighbor_id = BlockEngine:GetBlockId(x,y,z)
		if(root_block_id ~= neighbor_id) then
			break;
		end
		local neighbor_entity = EntityManager.GetEntityInBlock(x,y,z,self.class_name);
		if(neighbor_entity) then
			neighbor_facing = neighbor_entity:GetImageFacing();
			if(neighbor_facing ~= root_block_facing or neighbor_entity:HasImage()) then
				break;
			end
			top_blocks_number = top_blocks_number + 1;
		else
			bHasInvalidImageEntity = true;
		end
	end
		
	y = root_y;
	while(true) do
		y = y - 1;
		neighbor_id = BlockEngine:GetBlockId(x,y,z)
		if(root_block_id ~= neighbor_id) then
			break;
		end
		local neighbor_entity = EntityManager.GetEntityInBlock(x,y,z,self.class_name);
		if(neighbor_entity) then
			neighbor_facing = neighbor_entity:GetImageFacing();
			if(neighbor_facing ~= root_block_facing or neighbor_entity:HasImage()) then
				break;
			end
			bottom_blocks_number = bottom_blocks_number + 1;
		else
			bHasInvalidImageEntity = true;
		end
	end		
		
	local rows = top_blocks_number + 1 + bottom_blocks_number;

	local start_block_x,start_block_y,start_block_z;

	start_block_y = root_y + top_blocks_number;
	y = start_block_y;
	
	for i = 1,rows do
		local left_number = 0;
		local right_number = 0;


		x = root_x;
		z = root_z;
		while(true) do
			if(root_block_facing == 0) then
				z = z - 1;
			elseif(root_block_facing == 3) then
				x = x - 1;
			elseif(root_block_facing == 1) then
				z = z + 1;
			elseif(root_block_facing == 2) then
				x = x + 1;
			end
			neighbor_id = BlockEngine:GetBlockId(x,y,z)
			if(root_block_id ~= neighbor_id) then
				break;
			end
			local neighbor_entity = EntityManager.GetEntityInBlock(x,y,z,self.class_name);
			if(neighbor_entity) then
				neighbor_facing = neighbor_entity:GetImageFacing();
				if(neighbor_facing ~= root_block_facing or neighbor_entity:HasImage()) then
					break;
				end
				left_number = left_number + 1;
				if(i ~= 1 and left_number == left_blocks_number) then
					break;
				end
			else
				bHasInvalidImageEntity = true;
			end
		end

		x = root_x;
		z = root_z;
		while(true) do
			if(root_block_facing == 0) then
				z = z + 1;
			elseif(root_block_facing == 3) then
				x = x + 1;
			elseif(root_block_facing == 1) then
				z = z - 1;
			elseif(root_block_facing == 2) then
				x = x - 1;
			end
			neighbor_id = BlockEngine:GetBlockId(x,y,z)
			if(root_block_id ~= neighbor_id) then
				break;
			end
			local neighbor_entity = EntityManager.GetEntityInBlock(x,y,z,self.class_name);
			if(neighbor_entity) then
				neighbor_facing = neighbor_entity:GetImageFacing();
				if(neighbor_facing ~= root_block_facing or neighbor_entity:HasImage()) then
					break;
				end
				right_number = right_number + 1;
				if(i ~= 1 and right_number == right_blocks_number) then
					break;
				end
			else
				bHasInvalidImageEntity = true;
			end
		end

		if(i == 1) then
			left_blocks_number = left_number;
			right_blocks_number = right_number;
		else
			if(left_number < left_blocks_number) then
				left_blocks_number = left_number;
			end
			if(right_number < right_blocks_number) then
				right_blocks_number = right_number;
			end
		end

		y = y - 1;
	end
		
	local columns = left_blocks_number + 1 + right_blocks_number;

	
	--start_block_y = origin_block.y + top_image_blocks_number;
	if(root_block_facing == 0) then
		start_block_z = root_z - left_blocks_number;
	elseif(root_block_facing == 3) then
		start_block_x = root_x - left_blocks_number;
	elseif(root_block_facing == 1) then
		start_block_z = root_z + left_blocks_number;
	elseif(root_block_facing == 2) then
		start_block_x = root_x + left_blocks_number;
	end
	if(start_block_x == nil) then
		start_block_x = root_x;
	elseif(start_block_z == nil) then
		start_block_z = root_z;
	end
	self.rows = rows;
	self.columns = columns;
	self.start_block_coord = {x = start_block_x, y = start_block_y, z = start_block_z};
	return not bHasInvalidImageEntity;
end

-- only called on the root entity to set/expand the image on this block to all nearby blocks
-- i.e. setting the other_image_entity.derived_image_filename and call their refresh. 
-- expansion data is from self.start_block_coord, self.rows,self.columns, etc. 
function Entity:ApplyExpansionData()
	if(not self.image_filename) then
		return;
	end
	local rows = self.rows;
	local columns = self.columns;
		
	local start_block_x = self.start_block_coord.x;
	local start_block_y = self.start_block_coord.y;
	local start_block_z = self.start_block_coord.z;
	local root_entity_coord = {x = self.bx, y = self.by, z = self.bz};
	
	local x = start_block_x;
	local y = start_block_y;
	local z = start_block_z;

	local facing = self:GetImageFacing();

	if(rows ~= 1 or columns ~= 1) then
		for row_index = 1,rows do
			for column_index = 1,columns do
				local image_entity = EntityManager.GetEntityInBlock(x,y,z,self.class_name);
				if(image_entity) then
					-- set target image, and save a reference to the root block's coordinate.  
					image_entity.root_entity_coord = root_entity_coord; 
					image_entity:SetDerivedImageFilename(self.image_filename);
				end
				
				if(facing == 0) then
					z = z + 1;
				elseif(facing == 3) then
					x = x + 1;
				elseif(facing == 1) then
					z = z - 1;
				elseif(facing == 2) then
					x = x - 1;
				end
			end
			x = start_block_x;
			z = start_block_z;
			y = y - 1;
		end
	else
		self.root_entity_coord = nil; 
		self:SetDerivedImageFilename(nil);
	end
end

function Entity:SetImageFileName(filename)
	if(self.image_filename ~= filename) then
		self.image_filename = filename;
	end
end

function Entity:HasImage()
	if(self.image_filename or (self.cmd and self.cmd~="")) then
		return true;
	end
end

function Entity:Refresh(bForceRefresh)
	self.bNeedUpdate = nil;

	local filename = self:GetImageFilePath(); 
	if(filename) then
		filename = self:GetFullFilePath(filename);
	end
	
	if(filename and bForceRefresh)then
		if(filename == "") then
			if(self.image_filename) then
				self:ResetDerivedPaintings();
			end
			self:SetImageFileName(nil);
			self:UpdateImageModel(nil, true)
		else
			self:SetImageFileName(filename);
			
			if(self:CaculateImageExpansionData()) then
				self:ApplyExpansionData();
				self:UpdateImageModel(filename, self:GetDerivedImageFilename()==nil)
			else
				if(not self.bHasWaitedOneTickOnLoad) then
					self.bHasWaitedOneTickOnLoad = true;
					self:ScheduleRefresh();
				else
					local x, y, z = self:GetBlockPos();
					LOG.std(nil, "warn", self.class_name, "invalid block entity at pos: %d %d %d", x, y, z);
				end
			end
		end		
	end	
end


function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	local filename = self:GetImageFilePath();
	if(filename) then
		-- relative to world directory path
		local isSingle = self:IsSingleImage();
		node.attr.isSingle = isSingle
		if(not isSingle) then
			node.attr.rows = self.rows;
			node.attr.columns = self.columns;

			if(self.start_block_coord) then
				local x, y, z = self:GetBlockPos();
				local rx = self.start_block_coord.x - x;
				local ry = self.start_block_coord.y - y;
				local rz = self.start_block_coord.z - z;
				if(rx~=0 or ry~=0 or rz ~=0) then
					node.attr.rx = rx;
					node.attr.ry = ry;
					node.attr.rz = rz;
				end
			end
		end
	end
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	if(attr and attr.isSingle~=nil) then
		self.isSingle = attr.isSingle == "true" or attr.isSingle == true;
		if(not self.isSingle) then
			self.hasBakedImage = true;
			self.rows = tonumber(attr.rows)
			self.columns = tonumber(attr.columns)
			local x, y, z = self:GetBlockPos();
			self.start_block_coord = {x=x+tonumber(attr.rx or 0), y=y+tonumber(attr.ry or 0), z=z+tonumber(attr.rz or 0)};
		end
	end
end

function Entity:RefreshBakedImage()
	if(self.hasBakedImage and self.rawPath) then
		self.hasBakedImage = false;
		local filename = self:GetImageFilePath(); 
		if(filename) then
			filename, bFileExist = self:GetFullFilePath(filename);
			self:SetImageFileName(filename);
			self:ApplyExpansionData();
			self:UpdateImageModel(filename, self.isSingle)
		end
		return true;
	end
end

function Entity:IsSingleImage()
	return (self.rows == 1 and self.columns==1);
end

function Entity:UpdateImageModel(filename, isSingle)
	local imageSizeChanged = (self.last_columns~=self.columns or self.last_rows~=self.rows)
	if(self.last_filename ~= (filename or "") or imageSizeChanged) then
		self.last_filename = filename or "";
		self.last_columns = self.columns;
		self.last_rows = self.rows;

		if(filename and filename ~="") then
			-- only create C++ object when image is not empty
			if(not self.obj) then
				local obj = self:CreateInnerObject("model/blockworld/BlockModel/block_model_one.x", nil, BlockEngine.half_blocksize, BlockEngine.blocksize);
				if(obj) then
					-- making it using custom renderer since we are using chunk buffer to render. 
					obj:SetAttribute(0x20000, true);
				end
			end
		end
		local obj = self:GetInnerObject();
		if(obj) then
			local mat = mathlib.Matrix4:new():identity();
			local imageRadius = 1;
			local gridWidth, gridHeight = self.columns, self.rows;
			if(not isSingle or imageSizeChanged) then
				imageRadius = math.max(gridWidth, gridHeight);
				if(isSingle or self.last_filename == "") then
					mat:setScale(BlockEngine.blocksize, BlockEngine.blocksize, BlockEngine.blocksize)
					obj:SetField("LocalTransform", mat)	
				else
					local matScale = mathlib.Matrix4:new():identity();
					matScale:setScale(imageRadius*2*BlockEngine.blocksize, imageRadius*2*BlockEngine.blocksize, imageRadius*2*BlockEngine.blocksize);
					mat:offsetTrans(0, -0.5, 0);

					local data = self.block_data or 0;
					if(data>=4 and data<12) then
						local quat = Direction.GetQuaternionByData(data);
						mat = mat:multiply(mathlib.Quaternion:new({quat.x, quat.y, quat.z, quat.w}):ToRotationMatrix());
					end
					mat = mat:multiply(matScale);

					if(self.start_block_coord and (self.start_block_coord.x ~= self.bx or self.start_block_coord.y ~= self.by or self.start_block_coord.z ~= self.bz)) then
						local dx = (self.start_block_coord.x - self.bx) * BlockEngine.blocksize;
						local dy = (self.start_block_coord.y - self.by) * BlockEngine.blocksize;
						local dz = (self.start_block_coord.z - self.bz) * BlockEngine.blocksize;
						mat:offsetTrans(dx, dy, dz);
					end
					obj:SetField("LocalTransform", mat)	
				end
			end

			if(self.last_filename ~= "") then
				-- update rotation based on block data
				local data = self.block_data or 0;
				if(data < 4) then
					obj:SetFacing(Direction.directionTo3DFacing[data]);
				elseif(data < 12) then
					obj:SetFacing(0);
					if(isSingle)  then
						obj:SetRotation(Direction.GetQuaternionByData(data));
					end
				end
			end

			if(isSingle) then
				self.text_offset.y = 0.45;
				Image3DDisplay.ShowHeadonDisplay(true, obj, filename or "", 90, 90, nil, self.text_offset, -1.57);
			else
				local imageScale = imageRadius*2;
				local text_offset = {x = (self.text_offset.x + gridWidth*0.5-0.5)  / imageScale, y = (0.5+imageRadius) / imageScale, z = self.text_offset.z / imageScale}
				Image3DDisplay.ShowHeadonDisplay(true, obj, filename or "", 100/imageScale * gridWidth, 100/imageScale*gridHeight, nil, text_offset, -1.57);
			end
		end
	end
end


-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	return L"输入图片的名字或路径<div>格式: 相对路径[;l t w h][:l t r b]</div><div>例如: preview.jpg;0 0 100 64</div>".."<div>$(tip hello)preview.jpg</div>"
end

function Entity:RunCommand()
	if(self.root_entity_coord) then
		local x = self.root_entity_coord.x;
		local y = self.root_entity_coord.y;
		local z = self.root_entity_coord.z;
		if(x~=self.bx or y~=self.by or z~=self.bz) then
			local entity = EntityManager.GetBlockEntity(x, y, z);
			if(entity and entity.RunCommand) then
				entity:RunCommand();
			end
			return
		end
	end
	local cmd = self:GetInlineCommand()
	if(cmd) then
		-- TODO: isRemote() to run on server?
		GameLogic.RunCommand(cmd);
	end
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
		local old_value = self:GetCommand();
		self:BeginEdit();
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
		OpenFileDialog.ShowPage(self:GetCommandTitle(), function(result)
			if(result) then
				result = result:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\r\n]+$", "");
				self:SetCommand(result);
				self:Refresh(true);
			end
			self:EndEdit();
		end, old_value, L"贴图文件", "texture");
	else
		self:RunCommand()
	end
	return true;
end

-- virtual
function Entity:OnNeighborChanged(x,y,z, from_block_id)
	if(self.image_filename) then
		self:ScheduleRefresh();
	elseif(self.root_entity_coord) then
		local root_x = self.root_entity_coord.x;
		local root_y = self.root_entity_coord.y;
		local root_z = self.root_entity_coord.z;
		self:ScheduleRefresh(root_x, root_y, root_z);
	end
end

function Entity:EndEdit()
	Entity._super.EndEdit(self);
	-- just in case the image is changed. 
	self:Refresh(true);
	self:MarkForUpdate();
end

function Entity:GetDerivedImageFilename()
	return self.derived_image_filename;
end

function Entity:SetDerivedImageFilename(filename)
	if(self.derived_image_filename~=filename) then
		self.derived_image_filename = filename;
	end
end

-- Overriden in a sign to provide the text.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	return Packets.PacketUpdateEntitySign:new():Init(x,y,z, self.cmd, self.block_data);
end

-- update from packet. 
function Entity:OnUpdateFromPacket(packet_UpdateEntitySign)
	if(packet_UpdateEntitySign:isa(Packets.PacketUpdateEntitySign)) then
		self.block_data = packet_UpdateEntitySign.data;
		if((self.cmd or "") ~= (packet_UpdateEntitySign.text or "")) then
			self:SetCommand(packet_UpdateEntitySign.text);
			self:ScheduleRefresh()
		end
	end
end

-- Ticks the block if it's been scheduled
function Entity:updateTick(x,y,z)
	if(self.bNeedUpdate) then
		self:Refresh(true);
	end
end

function Entity:GetText()
	return self:GetImageFilePath()
end

-- @param text: string to match
-- @param bExactMatch: if for exact match
-- return true, filename: if the file text is found. filename contains the full filename
function Entity:FindFile(text, bExactMatch)
	local filename = self:GetText();
	if( (bExactMatch and filename == text) or (not bExactMatch and filename and filename:find(text))) then
		return true, filename
	end
end

