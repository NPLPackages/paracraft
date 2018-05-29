--[[
Title: base class for block template
Author(s): LiXizhi
Date: 2013/1/6
Desc: block side: 0 -x  1 +x  2 -z 3 z  4 -y 5 +y
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local block1 = block:new({id=1, texture="Texture/tileset/generic/c_bigroad_yellow1.dds", 
	obstruction=true, solid=true, cubeMode=true,})
block1:Register();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/block_material.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/ide/mathlib.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BlockSound.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/StepSounds.lua");
NPL.load("(gl)script/ide/math/AABBPool.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/BlockPieceEffect.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Color = commonlib.gettable("System.Core.Color");
local BlockPieceEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.BlockPieceEffect");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local AABBPool = commonlib.gettable("mathlib.AABBPool");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local StepSounds = commonlib.gettable("MyCompany.Aries.Game.Sound.StepSounds");
local BlockSound = commonlib.gettable("MyCompany.Aries.Game.Sound.BlockSound");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local NeuronBlock = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronBlock");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local blocks = commonlib.gettable("MyCompany.Aries.Game.blocks");

local block = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.block"));

local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

-- whether to auto generate block
block.auto_gen_terrain_block = false;

-- mapping from attribute name to value
local block_attribute_map = {
	obstruction		= 0x0000001,
	breakable		= 0x0000002,
	solid			= 0x0000004,
	liquid			= 0x0000008,
	blendedTexture	= 0x0000010,
	light			= 0x0000020,
	cubeMode		= 0x0000040,
	customModel		= 0x0000080,
	transparent		= 0x0000100,
	twoTexture		= 0x0000200,
	alphaTestTexture= 0x0000400,
	singleSideTex   = 0x0000800,
	threeSideTex	= 0x0001000,
	fourSideTex		= 0x0002000,
	sixSideTex		= 0x0004000,
	climbable		= 0x0008000,
	blockcamera		= 0x0010000,
	framemove		= 0x0020000, -- whether to tick randomly, framemove or tick_random are the same
	tick_random		= 0x0020000, -- whether to tick randomly, framemove or tick_random are the same
	onload			= 0x0040000, -- whether has onBlockLoaded
	color_data		= 0x0080000, -- whether the block contains color in its block data.
	invisible		= 0x0100000, -- whether the block is invisible.
	tiling			= 0x0200000, -- whether tiling is used
}

block.attributes = block_attribute_map;

-- Indicates how hard it takes to break a block. 
-- Tool's attack value will be devided by this hardness.
block.blockHardness = 1;

-- Indicates the blocks resistance to explosions. 
block.blockResistance = 0;

-- @param id: uint16 type. need to be larger than 1024 if not system type. 
function block:ctor()
	self.id = self.id or 0;
	self.attr = self.attr or 0;
	self.collisionAABB = ShapeAABB:new();
	self.collisionAABB:SetPointAABB(vector3d:new({0,0,0}));
	self.texture = self.texture or "";
	for i=2, 8 do
		local name = "texture"..tostring(i);
		if(self[name]) then
			self:SetTexture(self[name], i);
		end
	end

	if(self.break_sound) then
		self:LoadSound("break_sound");
	else
		self.break_sound = BlockSound:new():Init({"break3", "break2", });
	end

	if(self.create_sound) then
		self:LoadSound("create_sound");
	else
		self.create_sound = BlockSound:new():Init({"cloth1", "cloth2", "cloth3",});
	end

	if(self.step_sound) then
		self.step_sound = StepSounds.get(self.step_sound) or self:LoadSound("step_sound", nil);
	end

	if(self.click_sound) then
		self:LoadSound("click_sound", 2);
	end

	if(self.toggle_sound) then
		self:LoadSound("toggle_sound", 2);
	end
	
	if(type(self.material) ~= "table") then
		self.material = Materials[self.material or "default"];
	end

	self:UpdateBlockBounds();
end

-- Indicate if a material is a normal solid opaque cube. Normal cube block also provide weak power when activated by a wire. 
function block:isBlockNormalCube()
	return (self.cubeMode and self.solid and not self.ProvidePower);
end

-- not used. allowing to specify "glass4", and "glass[1-4]" is used. 
function block:LoadSound(name, max_count, volume, pitch)
	if(self[name]) then
		max_count = max_count or 5;
		local params = {self[name]};
		if(not self[name.."1"]) then
			local filename = self[name];
			if(name == "" and filename:match("^grass")) then
				volume = volume or 0.1;
			end
			local num = filename:match("%d$");
			if(num) then
				max_count = tonumber(num);
				self[name] = filename:gsub("%d$", "");

				for i=1, max_count do
					params[i] = self[name]..tostring(i);
				end
			end
		else
			for i=1, max_count do
				params[i+1] = self[name..tostring(i)];
			end	
		end
		self[name] = BlockSound:new():Init(params, volume, pitch);
	end
	return self[name];
end

function block:Init()
	return self;
end

function block:get_id()
	return self.id;
end

-- @param texture_index: nil to default to 1
function block:SetTexture(filename, texture_index)
	if(not texture_index or texture_index == 1) then
		self.texture = filename;
	else
		self.textures = self.textures or {};
		self.textures[texture_index] = filename;
	end
end

-- @param texture_index: nil to default to 1
function block:GetTexture(texture_index)
	if(not texture_index or texture_index == 1) then
		return self.texture;
	elseif(self.textures) then
		return self.textures[texture_index];
	end
end

-- get the current texture
function block:GetCurrentTexture()
	return self.new_texture or self:GetTexture();
end


-- @param texture_index: nil to default to 1
-- @return nil, false or the texture asset object. 
function block:GetTextureObj(texture_index)
	if(not texture_index or texture_index == 1) then
		if(self.texture_obj~=nil) then
			return self.texture_obj;
		else
			if(type(self.texture) == "string" and (self.texture:match("%.png$") or self.texture:match("%.dds$"))) then
				self.texture_obj = ParaAsset.LoadTexture("", self.texture, 1);
				return self.texture_obj;
			else
				self.texture_obj = false;
				return false;
			end
		end
	else
		local texture_objs = self.texture_objs;
		if(not texture_objs) then
			texture_objs = texture_objs or {};
			self.texture_objs = texture_objs;
		end
		if(texture_objs[texture_index]~=nil) then
			return texture_objs[texture_index];
		else
			local texture = self:GetTexture(texture_index);
			if(type(self.texture) == "string" and (self.texture:match("%.png$") or self.texture:match("%.dds$"))) then
				texture_objs[texture_index] = ParaAsset.LoadTexture("", texture, 1);
				return texture_objs[texture_index];
			else
				texture_objs[texture_index] = false;
				return false;
			end
		end
	end
end

-- if the texture of following block is replaced, it will only replace the block, rather than block sharing the same texture. 
local exclusive_block_tex = {
	-- glass and glass pane have same texture
	[102] = true,
};

function block:SetTileFromFilename(filename)
	local nTile = tonumber(filename:match("_x(%d)%.") or 1);
	if(self:GetTileSize() ~= nTile) then
		self.tile = nTile;
		self:UpdateAttribute("tile", nTile)
	end
end

-- default to 1
function block:GetTileSize()
	return self.tile or 1;
end

-- @param texture_index: nil to default to 1
-- @param bNoRestore: if true, we will not save the new texture to self.new_texture for automatic restore. 
function block:ReplaceTexture(filename, texture_index, bNoRestore)
	self:SetTileFromFilename(filename);

	if(texture_index and texture_index>1) then
		local texture = self:GetTexture(texture_index);
		if(texture and texture~="") then
			if(texture~=filename) then
				ParaIO.LoadReplaceFile(texture..","..filename, false);
			else
				ParaIO.LoadReplaceFile(texture..",", false);
			end
		end
	elseif(self.texture and self.texture~="") then
		if(self.texture~=filename) then
			if(filename and ((self.singleSideTex and filename:match("_three")) or filename:match("_a%d%d%d%.png$") or exclusive_block_tex[self.id]) ) then
				if(not bNoRestore) then
					self.new_texture = filename;
				end
				ParaTerrain.SetTemplateTexture(self.id, filename);
			-- @Note: following code is to replace one by one
			--elseif(filename:match("_a%d%d%d%.png$")) then
				--local new_name = filename:match("^(.*)_a%d%d%d%.png$");
				--local from_name, count = self.texture:match("^(.*)_a(%d%d%d)%.png$");
				--if(new_name and count) then
					--count = tonumber(count);
					--for i = 1, count do
						--echo(string.format("%s_a%03d.png,%s_a%03d.png", from_name,i, new_name, i))
						--ParaIO.LoadReplaceFile(string.format("%s_a%03d.png,%s_a%03d.png", from_name,i, new_name, i), false);
					--end
				--end
			else
				if(not bNoRestore) then
					self.new_texture = filename;
				end
				ParaIO.LoadReplaceFile(self.texture..","..filename, false);
			end
		else
			ParaIO.LoadReplaceFile(self.texture..",", false);
			if(self.new_texture) then
				ParaTerrain.SetTemplateTexture(self.id, self.texture);
				self.new_texture = nil;
			end
		end
	elseif(self.cubeMode) then
		if(not bNoRestore) then
			self.default_texture = self.default_texture or self.texture; -- just for restore
		end
		self.texture = filename;
		--self.icon = filename;
		ParaTerrain.SetTemplateTexture(self.id, filename);
		LOG.std(nil, "warn", "block_types", "texture replacement %d %s", self.id, filename);
	else
		-- TODO: 
		LOG.std(nil, "warn", "block_types", "only single side Tex support texture replacement %d %s", self.id, filename)
	end
end

function block:RestoreTexture()
	if(self.texture and self.texture~="") then
		-- @Note: following code is to replace one by one
		--local from_name, count = self.texture:match("^(.*)_a(%d%d%d)%.png$");
		--if(from_name and count) then
			--count = tonumber(count);
			--for i = 1, count do
				--ParaIO.LoadReplaceFile(string.format("%s_a%03d.png,", from_name,i), false);
			--end
		--end

		ParaIO.LoadReplaceFile(self.texture..",", false);
		if(self.new_texture) then
			ParaTerrain.SetTemplateTexture(self.id, self.texture);
			self.new_texture = nil;
		end
		self:SetTileFromFilename(self.texture);
	elseif(self.cubeMode and self.default_texture and self.default_texture~=self.texture) then
		self:ReplaceTexture(self.default_texture);
		self:SetTileFromFilename(self.default_texture);
	end
	if(self.textures) then
		for i, texture in pairs(self.textures) do
			if(texture and texture~="") then
				ParaIO.LoadReplaceFile(texture..",", false);
			end
		end
	end
end

function block:GetIcon()
	if(not self.icon) then
		if(self.texture) then
			if(self.singleSideTex) then
				self.icon = self.texture;
			elseif(self.threeSideTex) then
				self.icon = format("%s#0 128 128 128", self.texture);
			elseif(self.fourSideTex) then
				self.icon = format("%s#0 128 128 128", self.texture);
			elseif(self.sixSideTex) then
				self.icon = format("%s#0 0 128 128", self.texture);
			end
		end
	end
	return self.icon or "";
end

-- set per template attribute
function block:SetAttribute(name, value)
	if(name) then
		self[name] = value;
		if(block_attribute_map[name]) then
			if(value) then
				self.attr = mathlib.bit.bor(self.attr, block_attribute_map[name]);
			else
				self.attr = mathlib.bit.band(self.attr, mathlib.bit.bnot(block_attribute_map[name]));
			end
		end
	end
end

-- update attribute. 
function block:UpdateAttribute(name, value)
	if(not self.blockWorld) then
		ParaTerrain.RegisterBlockTemplate(self.id, {IsUpdating = true, [name] = value});
	else
		ParaBlockWorld.RegisterBlockTemplate(self.blockWorld, self.id, {IsUpdating = true, [name] = value});
	end	
end

-- set speed reduction percentage of current block type. 
-- @param value : [0,1]. by default water and web has 0.4, and 0.33 reduction. 
function block:SetSpeedReduction(value)
	self:UpdateAttribute("speedReduction", value)
end

-- make all blocks of this type visible or invisible. Please note, invisible block will maintain all of its functions. 
-- one may like to hide blocks like movie blocks in game mode. 
function block:SetVisible(bVisible)
	self:UpdateAttribute("isVisible", bVisible == true)
end

-- @param nValue: [0-15] a value of 0 means no light. 
function block:SetLightValue(nValue)
	self:UpdateAttribute("torchLightValue", tonumber(nValue) or 0);
end


function block:GetSpeedReduction()
	return self.speedReduction or 1;
end

function block:RecomputeAttribute()
	self.attr = 0;
	--if(self.solid and self.blockcamera==nil) then
		--self.blockcamera = true;
	--end

	if( self.onload==nil and ((self.models and self.customModel and not self.cubeMode) or self.entity_class)) then
		self.onload = true;
	end
	
	local name, value
	for name, value in pairs(block_attribute_map) do
		if(self[name]) then
			self.attr = mathlib.bit.bor(self.attr, value);
		end
	end
	self.attFlag = self.attr;
	return self.attr;
end

function block:GetAttribute(name)
	if(name) then
		return self[name];
	end
end

function block:Highlight()
end

-- register this block template
-- @param blockWorld: the ParaBlockWorld object. if nil, the default client block world is used. 
function block:Register(blockWorld)
	if(self.id and self.id>0) then
		local id = self.id;
		self:RecomputeAttribute();
		if(not blockWorld) then
			ParaTerrain.RegisterBlockTemplate(id, self);
		else
			self.blockWorld = blockWorld;
			ParaBlockWorld.RegisterBlockTemplate(blockWorld, id, self);
		end
		if(type(self.texture) == "string" and self.texture:match("%.png$")) then
			self.texture_obj = ParaAsset.LoadTexture("", self.texture, 1);
		end
	end
end

-- Returns the mobility information of the block, 0 = free, 1 = can't push but can move over, 2 = total immobility and stop pistons
function block:getMobilityFlag()
    return self.material:getMaterialMobility();
end

-- Sets how many hits it takes to break a block.
function block:setHardness(value)
    self.blockHardness = value;
    if (self.blockResistance < value * 5.0) then
        self.blockResistance = value * 5.0;
    end
end

-- This method will make the hardness of the block equals to -1, and the block is indestructible.
function block:setBlockUnbreakable()
    self:setHardness(-1.0);
end

-- Returns the block hardness at a location. Args: world, x, y, z
function block:getBlockHardness(x,y,z)
    return self.blockHardness;
end

-- get sub meta data according to current player or camera position. 
-- @param side: user clicked which side. this is *opposite* of the internal side.
-- @param side_region: the user clicked which side. can be "upper" or "lower"
-- @return metadata, force_condition:  metadata is nil, if no block meta data can be derived. some will only return force_condition table
function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z)
	-- TODO: here we will only deal with several shapes, it is better to 
	-- refactor to several inherited block classes in future. 
	local data;
	local force_condition;

	local shape = self.shape;
	if(shape == "vine" or shape == "halfvine") then
		return blocks.BlockVine:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx,camy,camz, lookat_x,lookat_y,lookat_z);
	end
	if(self.customBlockModel or (not self.cubeMode and self.customModel)) then
		local best_model = self:GetBestModel(blockX, blockY, blockZ, data, side, force_condition);
		if(best_model) then
			data = best_model.id_data or data;
		end
	end
	return data or 0;
end

-- Called when the block is placed in the world.
function block:OnBlockPlacedBy(x,y,z, entity)
	
end

-- virtual function: create a new block at the given position. 
-- TODO: move to game logic, and spawn other blocks if required
-- @param x, y, z: block position.
-- @param bCheckCanCreate: true to check if the player is inside the block and prevent creation. 
-- @param data: block data
-- @param side: usually a hint for on which block side this block is created on. 
-- @param condition: a condition table like in block_types.xml. 2,8 and 4,6 are horizontal neighbour. 0 is top, 5 is bottom.   
--		0(numerical): block must not be of the same type;  
--		1(numerical): block must be of the same type  -1(numerical): block should be empty  
--		'solid':block should be solid  'obstruction':block should be obstruction
-- @result: return the number of blocks created. if nil, no blocks are created
function block:Create(x, y, z, bCheckCanCreate, data, side, condition, serverdata)
	local num_block_created;
	if(bCheckCanCreate) then
		if(self:canPlaceBlockOnSide(x,y,z,side)) then
			num_block_created = self:Create(x,y,z, false, data, side, condition, serverdata);
		end
	else
		BlockEngine:SetBlock(x, y, z, self.id, data, 3, serverdata);
		num_block_created = 1;
	end
	return num_block_created;
end

-- whether the given real world point is near a terrain hole. 
-- @param cx,cz: center of the block in real coordinates
function block.NearTerrainHole(x, z)
	local blocksize = BlockEngine.blocksize;
	return ParaTerrain.IsHole(x+blocksize,z) or ParaTerrain.IsHole(x,z+blocksize) or ParaTerrain.IsHole(x-blocksize,z) or ParaTerrain.IsHole(x,z-blocksize)
end

local solid_column = {};

function block:GetTooltip()
	if(not self.tooltip) then
		self.tooltip = format("id: %d %s", self.id, self.name or "");
		if(self.text) then
			self.tooltip = format("%s %s", self.text, self.tooltip);
		end
	end
	return self.tooltip;
end

function block:GetDisplayName()
	return self.text or format("id: %d", self.id);
end

-- automatically generate blocks in column x,z. where the block at x,y,z must be a valid block either empty or solid. 
-- @return true, number_blocks_modifed. the first params is true if the current block is not destructible
function block.AutoFillUndergroundColumn(blockX, blockY, blockZ, bIgnoreThisBlock)
	local blocksize = BlockEngine.blocksize;
	local cx, cy, cz = BlockEngine:real(blockX, blockY, blockZ);
	local fElev = ParaTerrain.GetElevation(cx,cz);

	local k, top_solid, bottom_solid
	local _, terrain_block_y;
	local block_modified = 0;
	local top_undestructible_y;
	local is_terrain_hole = ParaTerrain.IsHole(cx, cz);
	local is_this_destructible = true;
	if(not is_terrain_hole) then
		if(fElev<(cy-blocksize)) then
			-- if the block well above the ground, exit without further processing. 
			return is_this_destructible;
		end

		if(block.NearTerrainHole(cx, cz)) then
			_, terrain_block_y, _ = BlockEngine:block(cx,fElev+0.1, cz);
			
			if(terrain_block_y == blockY or terrain_block_y == (blockY+1)) then
				top_undestructible_y = terrain_block_y-1;
			end
		else
			_, terrain_block_y, _ = BlockEngine:block(cx,fElev-blocksize-0.1, cz);
			if(terrain_block_y == blockY or terrain_block_y == (blockY+1)) then
				top_undestructible_y = terrain_block_y;
			end
		end

		top_solid, bottom_solid = blockY-1, blockY+1;
		for k = terrain_block_y, 0, -1 do
			if(ParaTerrain.GetBlockTemplateByIdx(blockX,k,blockZ) ~= 0) then
				top_solid = k;
				break;
			end
		end
	else
		top_solid, bottom_solid = blockY-1, blockY+1;
		for k = 0, BlockEngine.region_height*2-2 do
			if(ParaTerrain.GetBlockTemplateByIdx(blockX,k,blockZ) ~= 0) then
				bottom_solid = k;
				break;
			end
		end
		terrain_block_y = blockY;
	end
	
	if(top_solid<=1) then
		top_solid = blockY;
		bottom_solid = blockY;
	else
		if(not is_terrain_hole) then
			for k = 0, top_solid do
				if(ParaTerrain.GetBlockTemplateByIdx(blockX,k,blockZ) ~= 0) then
					bottom_solid = k;
					break;
				end
			end
		end
	end

	if(not is_terrain_hole) then
		
		local fill_to_block = math.min(terrain_block_y, blockY+1);

		if(top_undestructible_y) then
			for k = top_undestructible_y, fill_to_block do
				-- fill the undestructable block with a special stone type
				if(blockY == k) then
					is_this_destructible = false;
				end
				block.GenerateUndergroundBlock(blockX,k,blockZ, block_types.names.underground_shell);
				block_modified = block_modified + 1;
			end
			fill_to_block = top_undestructible_y - 1;
		end

		for k = top_solid, fill_to_block do
			if(not bIgnoreThisBlock or k~=blockY) then
				if(ParaTerrain.GetBlockTemplateByIdx(blockX,k,blockZ) == 0) then
					block.GenerateUndergroundBlock(blockX,k,blockZ);
					block_modified = block_modified + 1;
				end
			end
		end
	end

	for k = blockY-1, bottom_solid-1 do
		if(not bIgnoreThisBlock or k~=blockY) then
			if(ParaTerrain.GetBlockTemplateByIdx(blockX,k,blockZ) == 0) then
				block.GenerateUndergroundBlock(blockX,k,blockZ);
				block_modified = block_modified + 1;
			end
		end
	end
	return is_this_destructible, block_modified;
end

function block:GetModelByBlockData(blockData)
	if(self.models and blockData and self.models.id_model_map) then
		return self.models.id_model_map[blockData];
	end
end

-- get the best model object according to nearby blocks. 
-- @param side: usually a hint for on which block side this block is created on. 
function block:GetBestModel(blockX, blockY, blockZ, blockData, side, force_condition)
	if(self.models) then
		local best_model;
		if(blockData and self.models.id_model_map) then
			best_model = self.models.id_model_map[blockData];
			if(best_model) then
				return best_model;
			end
		end

		best_model = self.models[1];
		for _, model in ipairs(self.models) do
			-- match side first
			if(not side or not model.sides or model.sides[side]) then
				if(model.condition) then
					local is_match = true;
					-- TODO: check nearby blocks.
					local condition = model.condition;
					local direction, shouldBlockMatch;
					for direction, shouldBlockMatch in pairs(condition) do
						local bPassCheck;
						if(force_condition and force_condition[direction]) then
							if(shouldBlockMatch ~= force_condition[direction]) then
								is_match = false;
								break;
							else
								bPassCheck = true;
							end
						end
						if(not bPassCheck) then
							local block_id;
							if(direction < 10) then
								if(direction == 2) then
									block_id = ParaTerrain.GetBlockTemplateByIdx(blockX+1, blockY, blockZ);
								elseif(direction == 4) then
									block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY, blockZ+1);
								elseif(direction == 6) then
									block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY, blockZ-1);
								elseif(direction == 8) then
									block_id = ParaTerrain.GetBlockTemplateByIdx(blockX-1, blockY, blockZ);
								elseif(direction == 5) then
									if(blockY > 0) then
										block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY-1, blockZ);
									else
										block_id = 1;
									end
								elseif(direction == 0) then
									if(blockY < (BlockEngine.region_height*2-1)) then
										block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY+1, blockZ);
									else
										block_id = 1;
									end
								end
							else
								if(direction == 12) then
									block_id = ParaTerrain.GetBlockTemplateByIdx(blockX+1, blockY+1, blockZ);
								elseif(direction == 14) then
									block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY+1, blockZ+1);
								elseif(direction == 16) then
									block_id = ParaTerrain.GetBlockTemplateByIdx(blockX, blockY+1, blockZ-1);
								elseif(direction == 18) then
									block_id = ParaTerrain.GetBlockTemplateByIdx(blockX-1, blockY+1, blockZ);
								end
							end

							if(shouldBlockMatch == 0) then
								-- block must not be of the same type
								if(block_id == self.id) then
									is_match = false;
								end
							elseif(shouldBlockMatch == 1) then
								-- block must be of the same type
								if(block_id ~= self.id) then
									is_match = false;
								end
							elseif(shouldBlockMatch == -1) then
								-- block should be empty
								if(block_id~=0) then
									is_match = false;
								end
							elseif(shouldBlockMatch == 'solid') then
								-- block should be solid
								if(block_id ==0) then
									is_match = false;
								else
									local block = block_types.get(block_id)
									if( not (block and block.solid) ) then
										is_match = false;
									end
								end
							elseif(shouldBlockMatch == 'obstruction') then
								-- block should be obstruction
								if(block_id ==0) then
									is_match = false;
								else
									local block = block_types.get(block_id)
									if( not (block and block.obstruction) ) then
										is_match = false;
									end
								end
							elseif(shouldBlockMatch == '~obstruction') then
								-- block should be non-obstruction
								if(block_id ~=0) then
									local block = block_types.get(block_id)
									if( (block and block.obstruction) ) then
										is_match = false;
									end
								end
							elseif(shouldBlockMatch == '~solid') then
								-- block should be non-solid
								if(block_id ~=0) then
									local block = block_types.get(block_id)
									if( (block and block.solid) ) then
										is_match = false;
									end
								end
							end
							if(not is_match) then
								break;
							end
						end
					end

					if(is_match) then
						best_model = model;
						break;
					end
				else
					best_model = model;
					break;
				end
			end
			
		end
		return best_model;
	end
end

-- preload asset model. 
function block:PreloadAsset()
	if(self.is_asset_loaded_) then
		return
	else
		self.is_asset_loaded_ = true;
		local texture = self:GetTextureObj();
		if(texture) then
			texture:LoadAsset();
		end

		if(self.textures) then
			-- preload all asset
			for tex_index, filename in pairs(self.textures) do
				local texture = self:GetTextureObj(tex_index);
				if(texture) then
					texture:LoadAsset();
				end
			end
		end

		if((not self.cubeMode or self.customBlockModel) and self.customModel and self.models) then
			for _, model in ipairs(self.models) do
				local asset_obj = model:GetAssetObject();
				if(asset_obj) then
					asset_obj:LoadAsset();
				end
			end
		end
	end
end

-- virtual function
function block:OnBlockAdded(blockX, blockY, blockZ, block_data, serverdata)
	
end

-- when ever an event is received. 
function block:OnBlockEvent(x,y,z, event_id, event_param)
	
end

-- get the item stack when this block is broken & dropped. 
function block:GetDroppedItemStack(x,y,z, bForceDrop)
	if(bForceDrop or (not GameLogic.isRemote and GameLogic.GameMode:CanDropItem())) then
		return ItemStack:new():Init(self.id, 1);
	end
end

-- only called when user clicks to break an item 
function block:OnUserBreakItem(x,y,z, entityPlayer)
	GameLogic.GetWorld():CreateBlockPieces(self, x, y, z);
	local tx, ty, tz = BlockEngine:real(x,y,z);
	GameLogic.PlayAnimation({animationName = "Break",facingTarget = {x=tx, y=ty, z=tz},});
end

-- when ever this block is about to be destroyed and one may call this function to drop as an item first. 
-- @Note: this function should always be called before item is removed. 
-- @param bForceDrop: if true, we will drop regardless of game mode
function block:DropBlockAsItem(x,y,z, bForceDrop)
	local dropped_itemStack = self:GetDroppedItemStack(x,y,z, bForceDrop);
	if(dropped_itemStack) then
		local EntityItem = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityItem");
		local rx,ry,rz = BlockEngine:real(x,y,z);
		local entity = EntityItem:new():Init(rx, ry, rz, dropped_itemStack)
		entity:Attach();
	end
end

-- virtual function: Lets the block know when one of its neighbor changes. Doesn't know which neighbor changed (coordinates passed are their own) 
-- called when neighbour has changed. be careful of recursive calls. 
-- @param x, y, z:
-- @param neighbor_block_id:
function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(self.handleNeighborChange and self.customModel) then
		local data = self:GetMetaDataFromEnv(x,y,z);
		if(data ~= BlockEngine:GetBlockData(x,y,z)) then
			BlockEngine:SetBlockData(x,y,z, data, 3);
		end
	end
end

-- called on framemove.
function block:updateTick(x,y,z)
	
end

-- return true if the block_id is associated block, such as an open door and closed door. 
function block:IsAssociatedBlockID(block_id)
	return self.id == block_id or (self.associated_blockid == block_id and block_id);
end

-- default to return true, unless there is an can destroy rule. 
function block:CanDestroyBlockAt(x,y,z)
	local bCanDestroy;
	if(self.can_destroy_rule) then
		bCanDestroy = self.can_destroy_rule:CanDestroyBlockAt(x,y,z, entityPlayer)
	else
		bCanDestroy = GameLogic.GameMode:CanDestroyBlock();
	end
	return bCanDestroy;
end

-- set whether a given block can be placed onto another block. 
-- @param rule: rule or nil. nil to remove the rule. 
function block:SetRule_CanDestroy(rule)
	self.can_destroy_rule = rule;
end


-- virtual: Checks to see if its valid to put this block at the specified coordinates. Args: world, x, y, z
function block:canPlaceBlockAt(x,y,z)
	local entities = EntityManager.GetEntitiesInBlock(x,y,z);
	if(entities) then
		for entity, _ in pairs(entities) do
			if(not entity:canPlaceBlockAt(x,y,z, self)) then
				return false;
			end
		end
	end
	return true;
end

-- set whether a given block can be placed onto another block. 
-- @param rule: rule or nil. nil to remove the rule. 
function block:SetRule_CanPlace(rule)
	self.can_place_rule = rule;
end

-- checks to see if you can place this block can be placed on that side of a block: BlockLever overrides
-- @param x,y,z: this is the position where the block should be placed
-- @param side: this is the OPPOSITE of the side of contact.
function block:canPlaceBlockOnSide(x,y,z,side)
	if(self.can_place_rule and not self.can_place_rule:canPlaceBlockOnSide(x,y,z,side)) then
		return false;
	end
	return self:canPlaceBlockAt(x,y,z,side);
end

-- get the block entity at the given block position that matches the block's entity class
function block:GetBlockEntity(x,y,z)
	if(self.entity_class) then
		return EntityManager.GetEntityInBlock(x, y, z, self.entity_class);
	end
end

-- whether user data is auto computed. used when saving template. 
block.isAutoUserData = false;

-- update a block's custom model according to user data. this function is called whenever the block data changes or on load. 
function block:UpdateModel(blockX, blockY, blockZ, blockData)
	if(self.customModel and self.models) then
		-- create a model at block center with custom direction and model type according to nearby models. 
		local best_model = self:GetBestModel(blockX, blockY, blockZ, blockData);
		if(best_model) then
			if(best_model.assetfile) then
				self:PreloadAsset();

				local asset_obj = best_model:GetAssetObject();
				local hasPhysics = not self.obstruction;

				local x, y, z = BlockEngine:real(blockX, blockY, blockZ);
				local obj = ParaScene.GetObject(x, y, z, 0.01);
				if(obj:IsValid()) then
					ParaScene.Delete(obj);
				end
				
				local obj = ParaScene.CreateMeshPhysicsObject(format("%d,%d,%d", blockX, blockY, blockZ), asset_obj, BlockEngine.half_blocksize, BlockEngine.half_blocksize, BlockEngine.half_blocksize, best_model.hasPhysics=="true", best_model.transform or "1,0,0,0,1,0,0,0,1,0,0,0");
			
				obj:SetPosition(x,y,z);
				obj:SetField("progress", 1);
				-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
				obj:SetAttribute(128, true);
				-- OBJ_SKIP_PICKING = 0x1<<15:
				obj:SetAttribute(0x8000, true);
				-- making it non-persistent, since we will use the block onload callback to load any custom model. 
				obj:SetField("persistent", false); 
				obj:SetFacing(best_model.facing or 0);
				obj:SetScale(BlockEngine.blocksize);
				obj:SetField("RenderDistance", 160);
				local tex = self:GetTextureObj(best_model.texture_index);
				if(tex) then
					obj:SetReplaceableTexture(2, tex);
				end
				ParaScene.Attach(obj);
				if(best_model.id_data and blockData~=best_model.id_data) then
					ParaTerrain.SetBlockUserDataByIdx(blockX, blockY, blockZ, best_model.id_data);
				end
			end
		end
	end
end

-- Returns true if the block is emitting indirect/weak power on the specified side. If isBlockNormalCube
-- returns true, standard electric power propagation rules will apply instead and this will not be called. 
-- @param direction: Note that the side is reversed.  eg 4 (up) when checking the bottom of the block.
function block:isProvidingWeakPower(x, y, z, direction)
	return 0;
end

-- Returns true if the block is emitting direct/strong power on the specified side.
-- @param direction: Note that the side is reversed.  eg 4 (up) when checking the bottom of the block.
function block:isProvidingStrongPower(x, y, z, direction)
	return 0;
end

-- Can this block provide power. 
function block:canProvidePower()
    return false;
end

-- called when block is first loaded from disk file to memory
-- only customModel has this function called. 
function block:OnBlockLoaded(x,y,z, block_data)
	if(not self.cubeMode and self.customModel) then
		self:UpdateModel(x,y,z, block_data);
	end
end

-- get entity class if any. 
function block:GetEntityClass()
	if(self.entity_class_) then
		return self.entity_class_;
	elseif(self.entity_class) then
		self.entity_class_ = EntityManager.GetEntityClass(self.entity_class);
		return self.entity_class_;
	end
end

function block:DeleteModel(blockX, blockY, blockZ)
	if(not self.cubeMode and self.customModel and self.models) then
		-- remove the model as well. 
		local x, y, z = BlockEngine:real(blockX, blockY, blockZ);
		local obj = ParaScene.GetObject(x, y, z, 0.01);
		if(obj:IsValid()) then
			ParaScene.Delete(obj);
		end
	end
end

-- on block removed
function block:OnBlockRemoved(blockX, blockY, blockZ, last_id, last_data)
end


-- this decides the acceleration distance when entity is moving on the block. 
-- 0 means no acceleration distance and player stops immediately when it stops moving. 
-- bigger value means that the player will slide this certain distance before comming to a complete stop. 
function block:GetSlipperiness()
	return self.slipperiness or 0.25; 
end

-- virtual function: remove a block at the given position. 
-- it will automatically generate terrain blocks if necessary
-- @result: return the number of blocks modified. this number may be nil or 1 or larger than one. if some other blocks are auto generated. 
function block:Remove(blockX, blockY, blockZ)
	if(not block.auto_gen_terrain_block) then
		BlockEngine:SetBlockToAir(blockX, blockY, blockZ, 3);
		return 1;
	end

	-- if block is below terrain or is directly under a hole, we will auto generate underground blocks in 3*3 columns from terrain height to lowest height until a block is found
	local blocksize = BlockEngine.blocksize;
	local cx, cy, cz = BlockEngine:real(blockX, blockY, blockZ);
	
	local fElev = ParaTerrain.GetElevation(cx,cz);
	if(not ParaTerrain.IsHole(cx, cz)) then
		if(fElev<(cy-blocksize)) then
			-- if the block well above the ground, exit without further processing. 
			BlockEngine:SetBlockToAir(blockX, blockY, blockZ, 3);
			return 1;
		end
	end

	if(not block.NearTerrainHole(cx, cz)) then
		if(math.abs(fElev - cy)<(blocksize*0.5+0.1)) then
			-- we will simple delete a block that intersect with the terrain surface if it is not near a terrain hole. 
			BlockEngine:SetBlockToAir(blockX, blockY, blockZ, 3);
			return 1;
		end
	end
	
	if(block.AutoFillUndergroundColumn(blockX, blockY, blockZ, true)) then
		-- only remove if destructible
		BlockEngine:SetBlockToAir(blockX, blockY, blockZ, 3);
		local block_modified = 1; 
		local _, modified_num;
		_, modified_num = block.AutoFillUndergroundColumn(blockX+1, blockY, blockZ, false)
		block_modified = block_modified + (modified_num or 0);
		_, modified_num = block.AutoFillUndergroundColumn(blockX-1, blockY, blockZ, false)
		block_modified = block_modified + (modified_num or 0);
		_, modified_num = block.AutoFillUndergroundColumn(blockX, blockY, blockZ+1, false)
		block_modified = block_modified + (modified_num or 0);
		_, modified_num = block.AutoFillUndergroundColumn(blockX, blockY, blockZ-1, false)
		block_modified = block_modified + (modified_num or 0);
		return block_modified;
	end
end

-- static function: Fill blocks according to current terrain height and its surroundings.
-- @param block_id: if nil it defaults to block_types.names.underground_shell
function block.FillTerrainBlock(blockX, blockY, blockZ, block_id)
	local blocksize = BlockEngine.blocksize;
	local cx, cy, cz = BlockEngine:real(blockX, blockY, blockZ);
	local i, j, k;
	local x,y,z;

	-- get the min, max elevation that we need to fill in.
	
	-- get the min, max elevation that we need to fill in.
	local fMinElevation, fMaxElevation;

	-- checking for a small nearby terrain height
	local radius = 2;
	local step = 2*blocksize/(radius*2+1);
	for i = -radius, radius do 
		for j = -radius, radius do 
			x = cx + i * step;
			z = cz + j * step;
			if(not ParaTerrain.IsHole(x,z)) then
				local fElev = ParaTerrain.GetElevation(x,z);
				if(not fMinElevation or fElev<fMinElevation) then
					fMinElevation = fElev;
				end
				if(not fMaxElevation or fElev>fMaxElevation) then
					fMaxElevation = fElev;
				end
			end
		end
	end
	if(not fMaxElevation) then
		-- no need to remove terrain that is already hole.
		return;
	end
	local _, min_block_Y, _ = BlockEngine:block(cx, fMinElevation-0.1, cz);
	local _, max_block_Y, _ = BlockEngine:block(cx, fMaxElevation+0.1, cz);


	for i=min_block_Y, max_block_Y do
		block.GenerateUndergroundBlock(blockX, i, blockZ, block_id or block_types.names.underground_shell);
	end
end

-- static function: remove the terrain block, we will set holes
function block.RemoveTerrainBlock(blockX, blockY, blockZ)
	local blocksize = BlockEngine.blocksize;
	local cx, cy, cz = BlockEngine:real(blockX, blockY, blockZ);
	local i, j, k;
	local x,y,z;

	-- get the min, max elevation that we need to fill in.
	local fMinElevation, fMaxElevation;

	local radius = 7;
	for i = -radius, radius do 
		for j = -radius, radius do 
			x = cx + i * blocksize;
			z = cz + j * blocksize;
			if(not ParaTerrain.IsHole(x,z)) then
				local fElev = ParaTerrain.GetElevation(x,z);
				if(not fMinElevation or fElev<fMinElevation) then
					fMinElevation = fElev;
				end
				if(not fMaxElevation or fElev>fMaxElevation) then
					fMaxElevation = fElev;
				end
			end
		end
	end

	if(not fMaxElevation) then
		-- no need to remove terrain that is already hole.
		return;
	end

	local _, min_block_Y, _ = BlockEngine:block(cx, fMinElevation-0.1, cz);
	local _, max_block_Y, _ = BlockEngine:block(cx, fMaxElevation+0.1, cz);

	-- set hole on real terrain
	ParaTerrain.SetHole(cx, cz, true);
	ParaTerrain.UpdateHoles(cx, cz);

	
	for i = -radius, radius do 
		for j = -radius, radius do 
			x = cx + i * blocksize;
			z = cz + j * blocksize;
			if(ParaTerrain.IsHole(x,z)) then
				local k
				for k=max_block_Y, min_block_Y-2, -1 do
					block:Remove(blockX+i, k, blockZ+j);
				end

				--block.AutoFillUndergroundColumn(blockX+i, max_block_Y, blockZ+j);
				--if(min_block_Y~=max_block_Y) then
					--block.AutoFillUndergroundColumn(blockX+i, min_block_Y, blockZ+j);
				--end
			end
		end
	end
end

-- static function:
-- auto fill a random underground terrain block at given position. 
-- @param block_id: if nil it is a random block. 
function block.GenerateUndergroundBlock(blockX, blockY, blockZ, block_id)
	-- we will simply fill in the id=1,2,3 block. 
	block_id = block_id or block_types.names.underground_default;  --math.random(1,1);
	BlockEngine:SetBlock(blockX, blockY, blockZ, block_id);
end

function block:play_break_sound(x,y,z)
	if(self.break_sound) then
		self.break_sound:play2d();
	end
	SoundManager:Vibrate();
end

function block:play_create_sound(x,y,z)
	if(self.create_sound) then
		self.create_sound:play2d();
	end
end

function block:play_step_sound(volume)
	if(self.step_sound) then
		self.step_sound:play2d(volume);
	end
end

function block:play_click_sound(x,y,z)
	if(self.click_sound) then
		self.click_sound:play2d();
	end
end

function block:play_toggle_sound(x,y,z)
	if(self.toggle_sound) then
		self.toggle_sound:play2d();
	end
end

-- @param granularity: (0-1), 1 will generate 27 pieces, 0 will generate 0 pieces, default to 1. 
-- @param cx, cy, cz: center of break point. 
function block:CreateBlockPieces(blockX, blockY, blockZ, granularity, texture_filename, cx, cy, cz)
	granularity = granularity or 1;
	if(granularity < 0.05) then
		return;
	end
	if(granularity > 1) then
		granularity = 1;
	end
	if(granularity == 1)then
		self:play_break_sound();
	end

	if(not cx) then
		cx,cy,cz = BlockEngine:real(blockX, blockY, blockZ)
	end

	if(not texture_filename) then
		texture_filename = self.texture;
		if(self.customModel and not self.cubeMode) then
			local best_model = self:GetBestModel(blockX, blockY, blockZ);
			if(best_model) then
				texture_filename = best_model:GetMainTextureFileName() or texture_filename;
			end
			if(not texture_filename or texture_filename == "") then
				texture_filename = self.icon or "";
			end
		end
	end

	local half_blocksize = BlockEngine.half_blocksize;
	local width = 0.2;
	for i = -2, 2, 2 do 
		for j = -2, 2, 2 do 
			for k = -2, 2, 2 do 
				if(granularity == 1 or ParaGlobal.random()<granularity) then
					local speed_step = (0.5+0.5*ParaGlobal.random()); 
					local x, y, z = cx + i*width, cy + k*width, cz + j*width;
					BlockPieceEffect:CreateBlockPiece(
						x,y,z,
						width * 0.5 * (0.3+1.1*ParaGlobal.random()), --radius
						3*(0.5+0.5*ParaGlobal.random()), --lifetime
						(i)*speed_step*0.5, --speed_x
						(k)*speed_step*2,
						(j)*speed_step*0.5,
						texture_filename
					);
				end
			end
		end
	end
end

-- get the custom model at the given position. 
-- @return the paraobject or nil. 
function block:GetCustomModel(blockX, blockY, blockZ)
	if(self.customModel and self.models and not self.cubeMode) then
		-- remove the model as well. 
		local x, y, z = BlockEngine:real(blockX, blockY, blockZ);
		local obj = ParaScene.GetObject(x, y, z, 0.01);
		if(obj:IsValid()) then
			return obj;
		end
	end
end

-- add the custom model to selection. 
-- @param index: the selection group id, default to 2. 
-- @return true if selected
function block:AddToSelection(blockX, blockY, blockZ, index)
	local obj = self:GetCustomModel(blockX, blockY, blockZ);
	if(obj) then
		ParaSelection.AddObject(obj, index or 2);
		return true;
	end
end

-- some block like command blocks, may has an internal state number(like its last output result)
-- and some block may use its nearby blocks' state number to generate electric output or other behaviors.
-- @return nil or a number between [0-15]
function block:GetInternalStateNumber(x,y,z)
end


-- called when the user clicks on the block
-- @param side: on which side the block is clicked. 
-- @return: return true if it is an action block and processed . 
function block:OnClick(bx, by, bz, mouse_button, entity, side)
	if(self.hasAction) then
		if(GameLogic.isRemote) then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickBlock:new():Init(self.id, bx, by, bz, mouse_button, entity, side));
			return true;
		else
			return self:OnActivated(bx, by, bz, entity);
		end
	end
end

-- Triggered whenever an entity collides with this block (enters into the block). Args: world, x, y, z, entity
function block:OnEntityCollided(x,y,z, entity, deltaTime)
	
end

-- call when use press mouse down button over the block
function block:OnMouseDown(x,y,z, mouse_button)
	if(mouse_button == "left") then
		self:play_step_sound();
	end
end


-- virtual function: some signal is received, such as user click
-- the default behavior is to activate the neuron block.
function block:OnActivated(bx, by, bz, entity)
	local neuron = NeuronManager.GetNeuron(bx, by, bz, true);
	if(neuron) then
		-- TODO: play a different sound
		self:play_click_sound();
		neuron:Activate({type="click", action="user_toggle", entity=entity});
		return true;
	end
end

-- some blocks can be toggled to another block. and may event have a toggle function. 
function block:OnToggle(bx, by, bz)
	if(self.toggle_blockid) then
		-- TODO: play a different sound
		self:play_toggle_sound();
		-- we also send the block data
		BlockEngine:SetBlock(bx, by, bz, self.toggle_blockid, BlockEngine:GetBlockData(bx, by, bz), 3);
	end
end

-- when the player steps on the top surface of the block
-- some block may have an on step function. 
function block:OnStep(bx, by, bz, entity)

end

-- How many simulation steps 
function block:tickRate()
	return 10;
end

-- whether block is normal solid cube model that can not provide power. 
function block:isNormalCube()
	return (self.cubeMode and self.solid and not self.ProvidePower);
end

local offsets_map = {
	["model/blockworld/BlockModel/block_model_one.x"] = 0;
	["model/blockworld/BlockModel/block_model_four.x"] = 0;
	["model/blockworld/BlockModel/block_model_cross.x"] = 0;
	["model/blockworld/BlockModel/block_model_slab.x"] = 0;
	["model/blockworld/BlockModel/block_model_plate.x"] = 0;
	["model/blockworld/BlockModel/block_model_slope.x"] = 0;
	["model/blockworld/IconModel/IconModel_16x16.x"] = nil;
	[""] = 0;
}

local modelNameToModel = {
	["cross"] = "model/blockworld/BlockModel/block_model_cross.x",
	["grass"] = "model/blockworld/BlockModel/block_model_cross.x",
	["slab"] = "model/blockworld/BlockModel/block_model_slab.x",
	["plate"] = "model/blockworld/BlockModel/block_model_plate.x",
	["carpet"] = "model/blockworld/BlockModel/block_model_plate.x",
	["slope"] = "model/blockworld/BlockModel/block_model_slope.x",
}
-- get model file for item display
function block:GetItemModel()
	if(self.itemModel) then
		return self.itemModel;
	elseif(self.customModel) then
		if(self.modelName) then 
			local assetfile = modelNameToModel[self.modelName];
			if(assetfile) then
				return assetfile;
			end
		end
		if(self.models) then
			local model;
			if(self.models.id_model_map) then
				model = self.models.id_model_map[0] or self.models.id_model_map[1];
			end
			model = model or self.models[1];
			return model.assetfile;
		end
	elseif(self.cubeMode) then
		if(self.singleSideTex) then
			return "model/blockworld/BlockModel/block_model_one.x";
		elseif(self.threeSideTex) then
			return "model/blockworld/BlockModel/block_model_four.x";
		elseif(self.fourSideTex) then
			return "model/blockworld/BlockModel/block_model_four.x";
		elseif(not self.sixSideTex) then
			-- default to single side
			return "model/blockworld/BlockModel/block_model_one.x";
		end
	end
end

function block:GetOffsetY()
	if(self.offset_y) then
		return self.offset_y;
	else
		local modelfile = self:GetItemModel();
		self.offset_y = offsets_map[modelfile or ""] or 0.5;
		return self.offset_y;
	end
end

-- model scaling for GetItemModel() as handheld item. 
function block:GetItemModelScaling()
	return self.itemModelScaling or 1;
end

-- called when world is loaded
function block:OnWorldLoaded()
	self:UpdateBlockBounds();
end

-- set the block bounds and collision AABB. 
function block:UpdateBlockBounds()
	self:SetBlockBounds(0,0,0,1,1,1);
end

-- input is in local block pos which is scaled by block_size internally. 
function block:SetBlockBounds(minX, minY, minZ, maxX, maxY, maxZ)
	local block_size = BlockEngine.blocksize;
	self.collisionAABB:SetMinMaxValues(minX*block_size, minY*block_size, minZ*block_size, maxX*block_size, maxY*block_size, maxZ*block_size);
end

-- Returns a bounding box from the pool of bounding boxes.
-- this box can change after the pool has been cleared to be reused
function block:GetCollisionBoundingBoxFromPool(x,y,z)
	return self.collisionAABB:clone_from_pool():Offset(BlockEngine:real_min(x,y,z));
end

-- Adds all intersecting collision boxes representing this block to a list.
-- @param list: in|out array list to hold the output
-- @param aabb: only add if collide with this aabb. 
-- @param entity: 
function block:AddCollisionBoxesToList(x,y,z, aabb, list, entity)
	if(self.obstruction) then
		local my_aabb = self:GetCollisionBoundingBoxFromPool(x,y,z);

		if (my_aabb and my_aabb:Intersect(aabb)) then
			list[#list+1] = my_aabb;
		end
	end
end

-- rotate the block data by the given angle and axis. This is mosted reimplemented in blocks with orientations stored in block data, such as stairs, bones, etc. 
-- @param blockData: current block data
-- @param angle: usually 1.57, -1.57, 3.14, -3.14, 0.
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the rotated block data. 
function block:RotateBlockData(blockData, angle, axis)
	-- return self:RotateBlockDataUsingModelFacing(blockData, angle, axis);
	return blockData;
end


-- helper function: can be used by RotateBlockData() to automatically calculate rotated block facing. 
-- please note, it will cache last search result to accelerate subsequent calls.
function block:RotateBlockDataUsingModelFacing(blockData, angle, axis)
	if(not axis or axis == "y") then
		local lastModel = self:GetModelByBlockData(blockData)
		if(lastModel) then
			local lastFacing = lastModel.facing;
			if(lastFacing) then
				facing = lastFacing + angle;
				if(facing < 0) then
					facing = facing + 6.28;
				end
				facing = (math.floor(facing/1.57+0.5) % 4) * 1.57;

				if(not lastModel.facings) then
					lastModel.facings = {};
					for _, model in ipairs(self.models) do
						if(model.assetfile == lastModel.assetfile and model.facing and model.transform==lastModel.transform) then
							lastModel.facings[model.facing] = model.id_data;
						end
					end
					if(not lastModel.facings[3.14] and lastModel.facings[0]) then
						lastModel.facings[3.14] = lastModel.facings[0];
					end
					if(not lastModel.facings[4.71] and lastModel.facings[1.57]) then
						lastModel.facings[4.71] = lastModel.facings[1.57];
					end
				end
				blockData = lastModel.facings[facing] or blockData;
			end
		end
	else
		-- TODO: other axis
	end
	return blockData;
end

-- mirror the block data along the given axis. This is mosted reimplemented in blocks with orientations stored in block data, such as stairs, bones, etc. 
-- @param blockData: current block data
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the mirrored block data. 
function block:MirrorBlockData(blockData, axis)
	return blockData;
end

-- return color in RGB, without alpha
function block:GetBlockColor(x,y,z)
	local color; 
	if(self.color_data) then
		color = Color.convert16_32(BlockEngine:GetBlockData(x,y,z) or 0);
	elseif(self.mapcolor) then
		color = self.mapcolor;
	end
	color = Color.ToValue(color);
	return color;
end

-- return color in RGB, without alpha
function block:GetBlockColorByData(blockData)
	local color; 
	if(self.color_data) then
		color = Color.convert16_32(blockData or 0);
	elseif(self.mapcolor) then
		color = self.mapcolor;
	end
	color = Color.ToValue(color);
	return color;
end
