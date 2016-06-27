--[[
Title: Texture atlas for block icons
Author(s): LiXizhi
Date: 2014/12/9
Desc: A texture atlas may contain one or more big render target textures in which many named regional textures are packed. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/TextureAtlas.lua");
local TextureAtlas = commonlib.gettable("MyCompany.Aries.Game.blocks.TextureAtlas")
local texture_atlas = TextureAtlas:new():init("block_icon_altas", 512, 512, 64);
texture_atlas:AddRegionByBlockId(62);
texture_atlas:AddRegionByBlockId(5);
texture_atlas:AddRegionByBlockId(26);

local region = texture_atlas:CreateGetRegion("block1", 32, 32); region:Print();
local region = texture_atlas:CreateGetRegion("block2", 32, 32); region:Print();
local region = texture_atlas:CreateGetRegion("block3", 32, 32); region:Print();
local region = texture_atlas:GetRegion("block3"); region:Print();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/mathlib.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

---------------------------
-- TextureRegion
---------------------------
local TextureRegion = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.TextureRegion"));
TextureRegion:Property("Name", "TextureRegion");
-- this string can be used directly in UI object's background property.  
TextureRegion:Property({"TexturePath", "", "GetTexturePath", "SetTexturePath", auto=true});

TextureRegion:Property({"BlockId", nil, "GetBlockId", "SetBlockId"});
-- when blockid is changed
TextureRegion:Signal("Changed");

function TextureRegion:ctor()
end

-- init a region
function TextureRegion:init(rectangle, texture_packer)
	self.rectangle = rectangle;
	self.texture_packer = texture_packer;
	self:ComputeTexturePath();
	self.Connect(self, "Changed", self.texture_packer, "MakeDirty");
	return self;
end

function TextureRegion:GetBlockId()
	return self.block_id;
end

function TextureRegion:SetBlockId(block_id)
	if(block_id~=self.block_id) then
		self.block_id = block_id; 
		self:RefreshBlock();
	end
end

function TextureRegion:RefreshBlock()
	self.tickCount = 0;
	self:ChangeTimer(10);
end

function TextureRegion:OnTick()
	if(not self.block_id) then
		return;
	end
	self.tickCount = self.tickCount + 1;
	local block_template = block_types.get(self.block_id);
	if(block_template) then
		local tex = block_template:GetTextureObj();
		if(tex) then
			local isAssetLoaded;
			tex:LoadAsset();
			if(tex:IsLoaded()) then
				local model_filename = block_template:GetItemModel();	
				if(model_filename and model_filename ~= "icon") then
					local asset = ParaAsset.LoadStaticMesh("", model_filename);
					if(asset) then
						asset:LoadAsset();
						if(asset:IsLoaded()) then
							self:MakeDirty();
							return;
						end
					end
				end
			end
			if(self.tickCount < 20) then
				self:ChangeTimer(self.tickCount*300);
			else
				LOG.std(nil, "error", "TextureRegion", "failed to load texture %d", self.block_id);
			end
		end
	end
end

function TextureRegion:MakeDirty()
	self.tickCount = 0;
	self:Changed();
end

function TextureRegion:GetWidth()
	if(self.rectangle) then
		return self.rectangle.width or 0;
	else
		return 0;
	end
end

function TextureRegion:GetHeight()
	if(self.rectangle) then
		return self.rectangle.height or 0;
	else
		return 0;
	end
end

function TextureRegion:GetLeft()
	if(self.rectangle) then
		return self.rectangle.x or 0;
	else
		return 0;
	end
end

function TextureRegion:GetTop()
	if(self.rectangle) then
		return self.rectangle.y or 0;
	else
		return 0;
	end
end

-- call this to release
function TextureRegion:AutoRelease()
	if(self.rectangle and self.texture_packer) then
		self.Disconnect(self, "Changed", self.texture_packer, "MakeDirty");
		self.rectangle = nil;
		self.texture_packer = nil;
	end
end

function TextureRegion:ComputeTexturePath()
	if(self.rectangle and self.texture_packer) then
		self:SetTexturePath(format("%s;%d %d %d %d", self.texture_packer:GetTextureFilename(), self.rectangle.x, self.rectangle.y, self.rectangle.width, self.rectangle.height));
	end
end

function TextureRegion:Print()
	LOG.std(nil, "info", "TextureRegion", "filename: %s", self:GetTexturePath());
end

---------------------------
-- TexturePacker
---------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/TextureAtlasRectPacker.lua");
local TexturePacker = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.blocks.TextureAtlasRectPacker"), commonlib.gettable("MyCompany.Aries.Game.Tools.TexturePacker"));
TexturePacker:Property("Name", "TexturePacker");
TexturePacker:Property("FileName", "");
TexturePacker:Property({"TextureFileName", nil, "TextureFileName"});
-- how many pixel is 1 meter in orthorgonal coordinates. 
TexturePacker:Property("UnitSize", 32);
-- called whenever the texture is updated. 
TexturePacker:Signal("TextureUpdated");

function TexturePacker:ctor()
	self.regions = commonlib.UnorderedArraySet:new();
end

-- @param filename: render target filename. 
-- @param texture_format: TODO. format is always default now
function TexturePacker:init(filename, width, height, texture_format)
	TexturePacker._super.init(self, width, height);

	self:SetFileName(filename);
	return self;
end

-- get the filename of the render target
function TexturePacker:GetTextureFilename()
	if(not self.textureFilename) then
		self.textureFilename = self:GetScene():GetAttributeObject():GetField("assetfile", self:GetFileName());
	end
	return self.textureFilename;
end

-- clear all 
function TexturePacker:Clear()
	local region = self.regions:first();
	while (region) do
		self:RemoveRegion(region);
		region = self.regions:first();
	end
end

function TexturePacker:AddRegion(region)
	if(region.texture_packer == self) then
		self.regions:add(region);
	end
end

function TexturePacker:RemoveRegion(region)
	if(region and region.texture_packer == self) then
		if(region.rectangle) then
			self:FreeRectangle(region.rectangle);
		end
		self.regions:removeByValue(region);
	end
end

function TexturePacker:GetScene()
	-- create the render target with the name
	return ParaScene.GetMiniSceneGraph(self:GetFileName());
end

-- prepare scene
function TexturePacker:PrepareSceneCamera(scene)
	if(not self.is_scene_prepared or not scene:IsCameraEnabled()) then
		self.is_scene_prepared = true;
		scene:SetRenderTargetSize(self:GetWidth(), self:GetHeight());
		-- enable camera and create render target
		scene:EnableCamera(true);
		-- render it each frame automatically. 
		scene:EnableActiveRendering(false);
		-- set the transparent background color
		local att = scene:GetAttributeObject();
		att:SetField("BackgroundColor", {1, 1, 1}); 
		att:SetField("ShowSky", false);
		att:SetField("IsPersistentRenderTarget", true);
		att:SetField("EnableFog", false)
		att:SetField("EnableLight", true)
		att:SetField("EnableSunLight", true)
		att:SetField("UsePointTexture", true)
		scene:SetBackGroundColor("255 255 255 0");
		att = scene:GetAttributeObjectCamera();
		att:SetField("IsPerspectiveView", false);
		local unit_width = self:GetWidth()/self:GetUnitSize();
		att:SetField("OrthoWidth", unit_width*0.5);
		att:SetField("OrthoHeight", unit_width*0.5);
		scene:CameraSetLookAtPos(unit_width*0.5,unit_width*0.5,0);
		scene:CameraSetEyePos(unit_width*0.5,unit_width*0.5, -10);
		-- set sun light
		local att = scene:GetAttributeObject("sun");
		att:SetField("TimeOfDaySTD", 0.5);
		-- att:SetField("Ambient", {0.6, 0.6, 0.6});
		att:SetField("Ambient", {0.7, 0.7, 0.7});
		att:SetField("Diffuse", {0.5, 0.5, 0.5});
	end
end


-- rebuild the scene. 
function TexturePacker:RebuildScene(bClearAll)
	self:SetDirty(false);
	local scene = self:GetScene();
	if(bClearAll) then
		scene:DestroyChildren();
		scene:Reset();
	end
	self:PrepareSceneCamera(scene);

	local unit_size_inverse = 1 / self:GetUnitSize();
	-- 45/180*3.1415926
	local facing = 0.78539815;
	-- unused: view_angle = acos((2/3)^0.5) = 0.615479709 (regular hexagon)
	local view_angle = 30/180*3.1415927; -- 30 degress
	local angleLength = 1/2^0.5;
	local max_height = math.sin(math.atan(angleLength)+view_angle)*(3^0.5);
	local scaling = 1/max_height;
	local offset_y = 1 - (max_height-math.cos(view_angle))*0.5/max_height;
	-- add one pixel margin on top and bottom. 
	offset_y = offset_y - unit_size_inverse;
	scaling = scaling*(self:GetUnitSize()-2)*unit_size_inverse;

	local height = self:GetHeight();
	local q = mathlib.QuatFromAxisAngle(angleLength, 0, angleLength, -view_angle);
	for i = 1, #(self.regions) do
		local region = self.regions[i];
		local block_id = region:GetBlockId();
		if(region.rectangle and block_id) then
			local block_template = block_types.get(block_id);
			if(block_template) then
				-- region:Print();
				
				local model_filename = block_template:GetItemModel();	
				if(model_filename and model_filename ~= "icon") then
					local model_offset_y = block_template:GetOffsetY();
					local obj_name = tostring(block_id);
					local obj = scene:GetObject(obj_name);
					if(not obj or not obj:IsValid()) then
						obj = ObjEditor.CreateObjectByParams({
							name = obj_name,
							IsCharacter = false,
							AssetFile = model_filename,
							x = (region.rectangle.x + region.rectangle.width*0.5)*unit_size_inverse,
							y = (height - region.rectangle.y - region.rectangle.height*offset_y)*unit_size_inverse + model_offset_y * scaling,
							z = 0,
							facing = facing,
							scaling = scaling,
						});
						obj:SetField("progress", 1);
						obj:SetRotation(q);
						scene:AddChild(obj);
					end
					
					local tex = block_template:GetTextureObj();
					if(tex) then
						tex:LoadAsset();
						obj:SetReplaceableTexture(2, tex);
					end
				end
			end
		end
	end
end

-- it only redraws the render target, but does not update the scene content. 
-- be sure to call the RebuildScene() before calling this function 
function TexturePacker:Draw()
	-- render into mini scenegraph. 
	local scene = self:GetScene();
	if(scene) then
		scene:Draw(0);
		-- signal
		self:TextureUpdated();
	end
end

-- @param filename: if nil, we will save to format("temp/%s.png", self:GetFileName())
function TexturePacker:SaveToFile(filename)
	local scene = self:GetScene();
	if(scene) then
		local disk_filename = filename or format("temp/%s.png", self:GetFileName());
		LOG.std(nil, "info", "TexturePacker", "saved to file: %s", disk_filename);
		scene:SaveToFile(disk_filename, self:GetWidth());
	end
end

-- save each region as a separate file. 
function TexturePacker:SaveAsIndividualFiles()
	local scene = self:GetScene();
	if(scene) then
		ParaIO.CreateDirectory("temp/blockitems/");
		for i = 1, #(self.regions) do
			local region = self.regions[i];
			local block_id = region:GetBlockId();
			if(block_id) then
				local block_template = block_types.get(block_id);
				if(block_template) then
					local filename = block_template:GetIcon():match("([^/\\]+)$");
					if(filename) then
						filename = format("temp/blockitems/%s", filename);
						scene:SaveToFileEx(filename, region:GetWidth(), region:GetHeight(), 3, 0, region:GetLeft(), region:GetTop(), region:GetWidth(), region:GetHeight());
					end
				end
			end
		end
	end
end

function TexturePacker:RefreshAllBlocks()
	for i = 1, #(self.regions) do
		local region = self.regions[i];
		local block_id = region:GetBlockId();
		if(block_id) then
			region:RefreshBlock();
		end
	end
end

---------------------------
-- TextureAtlas
---------------------------
local TextureAtlas = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.blocks.TextureAtlas"));
TextureAtlas:Property("Name", "TextureAtlas");
-- by default all regions are equally sized quad. 
TextureAtlas:Property("UnitSize", 32);
TextureAtlas:Property("Width", 512);
TextureAtlas:Property("Height", 512);
TextureAtlas:Property("MaxTextureCount", 8);
TextureAtlas:Property("FileName", "default_atlas_texture");
TextureAtlas:Property({"RenderToFile", false, "IsRenderToFile", "SetRenderToFile", auto=true});

TextureAtlas:Signal("RegionAdded", function(region) end);
TextureAtlas:Signal("RegionRemoved", function(region) end);

function TextureAtlas:ctor()
	self.textures = commonlib.UnorderedArray:new();
	self.regions = {};
end

function TextureAtlas:init(filename, width, height, unit_size)
	self:SetFileName(filename);
	self:SetWidth(width);
	self:SetHeight(height);
	if(unit_size) then
		self:SetUnitSize(unit_size);
	end
	return self;
end

function TextureAtlas:GetRegion(name)
	return self.regions[name];
end

function TextureAtlas:CreateGetRegion(name, width, height)
	width = width or self:GetUnitSize();
	height = height or self:GetUnitSize();

	local region = self:GetRegion(name);
	if(region) then
		if(region:GetWidth() == width and region:GetHeight() == height) then
			return region;
		else
			self:RemoveRegion(name);	
		end
	end
	if(self:GetWidth() >= width and self:GetHeight()>=height) then
		for i=1, #(self.textures) do
			local texture_packer = self.textures[i];
			local rectangle = texture_packer:quickInsert(width, height);
			if(rectangle) then
				local region = self:AddRegion(name, rectangle, texture_packer);
				if(region) then
					return region;
				end
			end
		end
		if(#(self.textures) < self:GetMaxTextureCount()) then
			local texture_packer = self:CreateNewTexturePacker();
			local rectangle = texture_packer:quickInsert(width, height);
			if(rectangle) then
				local region = self:AddRegion(name, rectangle, texture_packer);
				if(region) then
					return region;
				end
			else
				LOG.std(nil, "error", "TextureAtlas", "image is larger than the parent texture");
			end
		else
			LOG.std(nil, "error", "TextureAtlas", "max texture count reached");
		end
	end
end

-- create a new texture
function TextureAtlas:CreateNewTexturePacker()
	local size = self.textures:size();
	local filename = format("%s_%d", self:GetFileName(), size);
	local texture_packer = TexturePacker:new():init(filename, self:GetWidth(), self:GetHeight())	
	texture_packer:SetUnitSize(self:GetUnitSize());
	self.textures:add(texture_packer);
	self.Connect(texture_packer, texture_packer.Changed, self, self.OnChange);
	self.Connect(self, self.RegionAdded, texture_packer, texture_packer.AddRegion);
	self.Connect(self, self.RegionRemoved, texture_packer, texture_packer.RemoveRegion);
	return texture_packer;
end

-- private: 
function TextureAtlas:AddRegion(name, rectangle, texture_packer)
	if(rectangle) then
		local region = TextureRegion:new():init(rectangle, texture_packer);
		self.regions[name] = region;
		self:RegionAdded(region);
		return region;
	end
end

-- private: 
function TextureAtlas:RemoveRegion(name)
	local region = self.regions[name];
	if(region) then
		self:RegionRemoved(region);
		region:AutoRelease();
		self.regions[name] = nil;
	end
end

function TextureAtlas:Clear()
	local name = next(self.regions);
	while name do
		self:RemoveRegion(name);
		name = next(self.regions);
	end
end

-- block related, shall we move this to a new class? 
function TextureAtlas:AddRegionByBlockId(block_id)
	local region_name = format("block_%d", block_id);
	local region = self:GetRegion(region_name);
	if(not region) then
		local block_template = block_types.get(block_id);
		if(block_template) then
			local model_filename = block_template:GetItemModel();	
			local bUseIcon;
			if(model_filename and model_filename ~= "icon") then
				-- only add block with real models. 
				region = self:CreateGetRegion(region_name, nil, nil);
				if(region) then
					region:SetBlockId(block_id);
				end	
			end
		end
	end
	return region;
end

-- save each region as a separate file. 
function TextureAtlas:SaveAsIndividualFiles()
	for i=1, #(self.textures) do
		local texture_packer = self.textures[i];
		if(texture_packer) then
			texture_packer:SaveAsIndividualFiles();
		end
	end
end


function TextureAtlas:RefreshAllBlocks()
	for i=1, #(self.textures) do
		local texture_packer = self.textures[i];
		if(texture_packer) then
			texture_packer:RefreshAllBlocks();
		end
	end
end

function TextureAtlas:MakeDirty()
	for i=1, #(self.textures) do
		local texture_packer = self.textures[i];
		if(texture_packer) then
			texture_packer:MakeDirty();
		end
	end
end

-- public slot: call this to update any textures in the next cycle. 
function TextureAtlas:OnChange()
	self:ChangeTimer(100, nil);
end

function TextureAtlas:OnTick()
	-- LOG.std(nil, "debug", "TextureAtlas", "ontick refreshed");
	for i=1, #(self.textures) do
		local texture_packer = self.textures[i];
		if(texture_packer and texture_packer:IsDirty()) then
			texture_packer:RebuildScene();
			texture_packer:Draw();
			if(self:IsRenderToFile()) then
				-- for async loading reason, we will render it twice. 
				texture_packer:ScheduleFunctionCall(200, texture_packer, texture_packer.Draw);
				-- then save to file
				texture_packer:ScheduleFunctionCall(1000, texture_packer, texture_packer.SaveToFile);
			else
				LOG.std(nil, "debug", "TextureAtlas","%s redrawn", self:GetFileName())
			end
		end
	end
end