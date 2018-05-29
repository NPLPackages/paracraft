--[[
Title: all block types
Author(s): LiXizhi
Date: 2012/10/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")

block_types.init();
block_types.register_new_type();

local block_template = block_types.get(block_id);
if(block_template) then
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/LocalTextures.lua");
local LocalTextures = commonlib.gettable("MyCompany.Aries.Game.Materials.LocalTextures");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

-- TODO: testing only, replace this with 
-- local BlockTerrain = ParaTerrain;
local BlockTerrain = commonlib.gettable("MyCompany.Aries.Game.Fake_ParaTerrain")

local names = commonlib.createtable("MyCompany.Aries.Game.block_types.names", {
	Air = 0,
	underground_shell = 62,
	underground_default = 55,
	water = 75,
	Water = 75,
	Still_Water = 76,  -- this is used by terrain generator
	Bedrock = 123,
	Diamond_Ore = 96,
	Rose = 115,
	Cactus = 26,
	Wood = 98,
	Leaves = 86,

	-- star to pick on ground
	blue_star = 10001,
	-- gold coin
	gold_coin = 10011,
	-- silver coin
	silver_coin = 10012,
	-- flying heart to pick
	heart_blue = 10021,
	-- a gun that fire
	gun_snipper = 10030,
	-- first aid box
	rocket = 10032,
	-- rocket ammo
	rocket_ammo = 10042,
	-- first aid box
	first_aid = 10051,

	-- a simple standard mob
	simple_mob = 20001,
	-- player spawn point
	player_spawn_point = 20002,

	-- main player
	player = 30002,
});

-- mapping from mc_id to our id
block_types.mc_id_map = {
	-- water blocks
	[8] = 75, 
	[9] = 75,
};

-- all block class definitions here
block_types.block_classes = {
	["block"] = block,
}

--mapping from type id (uint16) to type attribute table
-- please note that id [0-4096] is reserved for system block types
-- id larger than 4096 can be used for per world custom model.
local all_types = {
};

local blocks = commonlib.gettable("MyCompany.Aries.Game.block_types.blocks");

-- load known block type
function block_types.PreloadBlockClass()
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockEntityBase.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSlab.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLiquidStill.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLiquidFlow.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockGrass.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLever.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockWire.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockRepeater.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLogic.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockElectricLight.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockElectricTorch.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockButton.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockTrapDoor.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockTNT.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSapling.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPressurePlate.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPiston.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPistonExtension.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPistonMoving.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPowered.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockTeleportStone.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockPlant.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockFence.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockStair.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSign.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockItemFrame.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockChest.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSponge.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockNote.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockMusicBox.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockCollisionSensor.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockConductor.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockDynamic.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockCommandBlock.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockBlockUpdateDetector.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockImage.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockCarpet.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockRailBase.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockRailPowered.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockRailDetector.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockBone.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockModel.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLilypad.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockVine.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockTorch.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockArrow.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSlope.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockLight.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockMemory.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockCode.lua");
end

-- block_types.register_basics
function block_types.init()
	-- register all types.
	block_types.register_basics();
end

-- called when world is just loaded
function block_types:OnWorldLoaded()
	for id, block_template in pairs(all_types) do
		if(block_template.OnWorldLoaded) then
			block_template:OnWorldLoaded();
		end
	end
end

-- register a new block class
function block_types.RegisterBlockClass(name, class)
	block_types.block_classes[name] = class;
end

function block_types.RegisterItemClass(name, class)
	return block_types.RegisterBlockClass(name, class);
end

-- get block class
function block_types.GetBlockClass(block_)
	local class_name = block_.class;
	if(class_name) then
		return block_types.block_classes[class_name] or block;
	else
		return block;
	end
end

-- get item class by name
function block_types.GetItemClass(class_name)
	return block_types.block_classes[class_name] or MyCompany.Aries.Game.Items.Item;
end

-- such as the open door block and closed door block are associated. 
function block_types.IsAssociatedBlockID(block_id1, block_id2)
	if(block_id1 ==  block_id2) then
		return true;
	elseif(block_id1~=0 and block_id2~=0) then
		local block = block_types.get(block_id1);
		if(block and block:IsAssociatedBlockID(block_id2)) then
			return true;
		end
	end
end

-- register a new block type. It will overwrite whatever is registered before. 
-- @param block_: the block template object or a pure table of {id, ...} which will be used to construct a block template object. 
-- @param bCallRegister: true to invoke the low level block registration with the game engine. 
function block_types.register_new_type(block_, bCallRegister)
	if(block_ and block_.id) then
		if(not block_.Register) then
			local block_class = block_types.GetBlockClass(block_);	
			block_ = block_class:new(block_);
			block_:Init();
		end
		all_types[block_.id] = block_;
		if(block_.name) then
			blocks[block_.name] = block_;
		end
		if(bCallRegister) then
			block_:Register();
		end
	end
	return block_;
end

-- create get the template params by template id.
function block_types.create_get_type(id, params_default)
	local params = all_types[id];
	if (not params) then
		params = params_default or {id=id};
		all_types[id] = params;
	end
	return params;
end

function block_types.GetAllBlocksWithTexture(filename)
	local blocks;
	for id,block in pairs(all_types) do
		if(block.texture == filename) then
			blocks = blocks or {};
			blocks[#blocks+1] = block;
		end
	end
	return blocks;
end

-- replace texture at runtime
-- @param bReplaceAllBlocks: true to replace all blocks with the given texture filename.
function block_types.replace_texture(id, filename, texture_index, bReplaceAllBlocks)
	local block = block_types.get(id)
	if(block) then
		if(not bReplaceAllBlocks) then
			block:ReplaceTexture(filename, texture_index);
		else
			local blocks = block_types.GetAllBlocksWithTexture(block.texture);
			if(blocks) then
				for id, block in ipairs(blocks) do
					block:ReplaceTexture(filename, texture_index);
				end
			end
		end
	end
end

-- restore all textures to its default value. 
function block_types.restore_texture_pack()
	for id,block in pairs(all_types) do
		block:RestoreTexture();
	end
end

-- return a given block template
function block_types.get(id)
	return all_types[id];
end

-- @param id: string or number. it can also be number string, such as "Water", "63", 63 are all valid. 
function block_types.GetByNameOrID(id)
	if(type(id) == "number") then
		return block_types.get(id);
	else
		local block_template = block_types.get(block_types.names[id]);
		if(not block_template) then
			id = tonumber(id);
			if(id) then
				block_template = block_types.get(id);
			end
		end
		return block_template;
	end
end

-- return tooltip
function block_types.GetTooltip(id)
	local block = block_types.get(id);
	if(block) then
		return block:GetTooltip();
	end
end

--------------------------
-- block_model class
--------------------------
local block_model = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.block_model"));
function block_model:ctor()
	self.facing = tonumber(self.facing or 0);
	self.is_update_nearby = self.is_update_nearby == "true";
	if(self.id_data) then
		self.id_data = tonumber(self.id_data);
	end
	if(self.scaling) then
		self.scaling = tonumber(self.scaling);
	end
	if(self.offset_y) then
		self.offset_y = tonumber(self.offset_y);
	end
	if(self.texture_index) then
		self.texture_index = tonumber(self.texture_index);
	end
	if(type(self.sides) == "string") then
		local sides = {};
		local side
		for side in self.sides:gmatch("%d+") do
			sides[tonumber(side)] = true;
		end
		self.sides = sides;
	end
	if(type(self.condition) == "string") then
		local condition = NPL.LoadTableFromString(self.condition);
		if(condition) then
			self.condition = condition;
			local direction, _
			for direction, _ in pairs(self.condition) do
				if(direction >=0 and direction<10) then
					self.need_update_layer_current = true;
				elseif(direction>10) then
					self.need_update_layer_lower = true;
				elseif(direction<0) then
					self.need_update_layer_upper = true;
				end
			end
		else
			LOG.std(nil, "error", "block_types", "condition format wrong for %s", self.condition);
		end
	end
end

-- get the default asset object. 
function block_model:GetAssetObject()
	self.default_asset = self.default_asset or ParaAsset.LoadStaticMesh("", self.assetfile);
	return self.default_asset;
end

-- whether the model need to update layer one
-- whether the model need to update layer 1
function block_model:NeedUpdateLayer(layer)
	if(layer == 0) then
		return self.need_update_layer_current;
	elseif(layer == -1) then
		return self.need_update_layer_lower;
	elseif(layer == 1) then
		return self.need_update_layer_upperr;
	end
end

-- for breaking into pieces animation. 
function block_model:GetMainTextureFileName()
	if(not self.main_texture_filename) then
		local asset = self:GetAssetObject();
		local tex = asset:GetAttributeObject():GetField("TextureUsage", "")
		if(tex and tex~="") then
			local filename = tex:match("%d+%*%d+%(%d+%)([^;]+)");
			if(filename) then
				self.main_texture_filename = filename
			end
		end
		self.main_texture_filename = self.main_texture_filename or "";
	end
	return self.main_texture_filename;
end

function block_types.add_mc_id(mc_id, block_id)
	if(type(mc_id) == "string") then
		local id, data = mc_id:match("(%d+):(%d+)");
		if(data) then
			data = tonumber(data);
			if(data ~= 0) then
				mc_id = tonumber(id)*100+data;
			else
				mc_id = tonumber(id);
			end
		else
			mc_id = tonumber(mc_id);
		end
		if(mc_id) then
			block_types.mc_id_map[mc_id] = block_id;
		end
	elseif(type(mc_id) == "number") then
		block_types.mc_id_map[mc_id] = block_id;
	end
end

function block_types.LoadBlockTemplates(filename)
	if(block_types.templates and not filename) then
		return;
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/block_material.lua");
	local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");
	Materials.RegisterAllMaterials();

	filename = filename or "config/Aries/creator/block_types_template.xml";
	block_types.templates = block_types.templates or {};

	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local templates = block_types.templates;
		local count = 0;
		xmlRoot = GameLogic.GetFilters():apply_filters("block_types_template", xmlRoot);
		for node in commonlib.XPath.eachNode(xmlRoot, "/block_templates/block") do
			local attr = node.attr;
			if(attr.name) then
				templates[attr.name] = node;
			end
			count = count + 1;
		end
		LOG.std(nil, "debug", "block_template", "%d templates loaded", count)
	end
end

-- apply a given block template by name to the given xml node. 
function block_types.ApplyTemplate(name, dest_node, filename)
	if(block_types.templates and block_types.templates[name or ""]) then
		
		local src_node = block_types.templates[name];
		if(src_node) then
			local function ApplyProperty(property_name)
				if(src_node.attr and src_node.attr[property_name] ~= nil and dest_node.attr and dest_node.attr[property_name] == nil) then
					dest_node.attr[property_name] = src_node.attr[property_name];
				end
			end

			local function ApplyModels(filename)
				local model;
				for model in commonlib.XPath.eachNode(src_node, "/model") do
					local model_ = commonlib.deepcopy(model);
					local attr = model_.attr;
					if(attr.assetfile and filename) then
						attr.assetfile = attr.assetfile:gsub("%[filename%]", filename or "");
					end
					dest_node[#dest_node+1] = model_;
				end
			end
			ApplyProperty("texture");ApplyProperty("texture2");ApplyProperty("texture3");ApplyProperty("light");ApplyProperty("solid");ApplyProperty("cubeMode");ApplyProperty("customModel");ApplyProperty("click_sound");ApplyProperty("toggle_sound");
			ApplyProperty("selection_effect");ApplyProperty("shape");ApplyProperty("obstruction");ApplyProperty("blockcamera");ApplyProperty("climbable");ApplyProperty("break_sound");ApplyProperty("customBlockModel");ApplyProperty("material");
			ApplyProperty("break_sound1");ApplyProperty("break_sound2");ApplyProperty("modelName");ApplyProperty("hasAction");ApplyProperty("on_click");ApplyProperty("on_toggle");ApplyProperty("item_class");
			ApplyProperty("handleNeighborChange");ApplyProperty("framemove");ApplyProperty("ProvidePower");ApplyProperty("class");ApplyProperty("entity");ApplyProperty("itemModel");
			ApplyProperty("itemModelScaling");ApplyProperty("inhandOffset");ApplyProperty("speedReduction");ApplyProperty("slipperiness");
			ApplyModels(filename);
		end
	end
end

-- loading all block definition from file
function block_types.LoadFromFile(filename)
	block_types.PreloadBlockClass();
	ItemClient.PreloadItemClass();
	block_types.LoadBlockTemplates();
	

	filename = filename or "config/Aries/creator/block_types.xml";
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		xmlRoot = GameLogic.GetFilters():apply_filters("block_types", xmlRoot);
		
		for node in commonlib.XPath.eachNode(xmlRoot, "/blocks/block") do
			local attr = node.attr;
			local block_id = tonumber(attr.id);
			if(block_id and block_id>=0 and block_id<65535) then
				if(attr.template) then
					local name, params = attr.template:match("^([%w_]+)%??(.*)");
					if(name) then
						local filename
						if(params) then
							filename = params:match("^filename=(.*)");
						end
						block_types.ApplyTemplate(name, node, filename);
					end
				end

				attr.id = block_id;
				attr.text = L(attr.text);
				attr.searchkey = L(attr.searchkey);
				if(attr.searchkey) then
					attr.searchkey = string.lower(attr.searchkey);
				end
				attr.tooltip = L(attr.tooltip);
				attr.obstruction = attr.obstruction == "true";
				attr.solid = attr.solid == "true";
				attr.cubeMode = attr.cubeMode == "true";
				attr.light = attr.light == "true";
				attr.threeSideTex = attr.threeSideTex == "true";
				attr.singleSideTex = attr.singleSideTex == "true";
				attr.fourSideTex = attr.fourSideTex == "true";
				attr.sixSideTex = attr.sixSideTex == "true";
				attr.customModel = attr.customModel == "true";
				-- custom block model is read from x file, but cached in chunk render buffer like ordinary cubeModel. 
				attr.customBlockModel = attr.customBlockModel == "true";
				if(attr.customBlockModel) then
					attr.cubeMode = true;
				end
				if(attr.categoryID) then
					attr.categoryID = tonumber(attr.categoryID);
				else
					if((attr.customModel or attr.customBlockModel) and not attr.light) then
						-- automatically set custom model to 255, so that we will give it some fake torch shading at night.
						attr.categoryID = 255;
					end
				end
				if(attr.opacity) then
					attr.opacity = tonumber(attr.opacity);
				end

				attr.climbable = attr.climbable == "true";
				attr.blockcamera = attr.blockcamera == "true";
				attr.handleNeighborChange = attr.handleNeighborChange == "true";
				attr.framemove = attr.framemove == "true" or attr.tick_random == "true";
				if(attr.itemModelScaling) then
					attr.itemModelScaling = tonumber(attr.itemModelScaling);
				end
				if(attr.inhandOffset) then
					attr.inhandOffset = NPL.LoadTableFromString(attr.inhandOffset);
				end
				
				if(attr.onload) then
					attr.onload = attr.onload == "true";
				end
				attr.ProvidePower = attr.ProvidePower == "true";
				-- attr.shape = "stair";
				if(attr.toggle_blockid) then
					attr.toggle_blockid = tonumber(attr.toggle_blockid);
					attr.associated_blockid = attr.toggle_blockid;
				end
				if(attr.associated_blockid) then
					attr.associated_blockid = tonumber(attr.associated_blockid) or attr.associated_blockid;
				end
				if(attr.torchLightValue) then
					attr.torchLightValue = tonumber(attr.torchLightValue);
				end
				if(attr.speedReduction) then
					attr.speedReduction = tonumber(attr.speedReduction);
				end
				if(attr.slipperiness) then
					attr.slipperiness = tonumber(attr.slipperiness);
				end

				if(attr.mc_id) then
					block_types.add_mc_id(attr.mc_id, block_id);
				end

				attr.texture = LocalTextures:GetBlockTexture(attr.texture);

				if (attr.src) then
					NPL.load("(gl)"..attr.src);
				end
				if (attr.name) then
					names[attr.name] = block_id;
				end
				if (attr.disable_gen_icon) then
					attr.disable_gen_icon = (attr.disable_gen_icon == "true");
				end

				if(block_id < 4096) then
					-- raw block types for id <4096
					local block = block_types.register_new_type(attr);
				
					if(attr.customModel or attr.customBlockModel) then
						local model;
						for model in commonlib.XPath.eachNode(node, "/model") do
							local attr = block_model:new(model.attr);
							block.models = block.models or {};
							block.models[#(block.models)+1] = attr;

							if(attr.id_data) then
								block.models.id_model_map = block.models.id_model_map or {};
								block.models.id_model_map[attr.id_data] = attr;
							end

							block.need_update_layer_current = block.need_update_layer_current or attr.need_update_layer_current;
							block.need_update_layer_upper = block.need_update_layer_upper or attr.need_update_layer_upper;
							block.need_update_layer_lower = block.need_update_layer_lower or attr.need_update_layer_lower;
						end
					end

					-- ensure the block item is also created
					local item = ItemClient.CreateGetByBlockID(block_id, attr.item_class);
					item.itemModelScaling = attr.itemModelScaling;
					item.inhandOffset = attr.inhandOffset;

				elseif(attr.item_class) then
					local item_class = block_types.GetItemClass(attr.item_class);
					if(item_class and item_class.new) then
						local item = ItemClient.GetItem(block_id);
						if(not item) then
							local models;
							local model;
							for model in commonlib.XPath.eachNode(node, "/model") do
								local attr = block_model:new(model.attr);
								models = models or {};
								models[#(models)+1] = attr;
								if(attr.id_data) then
									models.id_model_map = block.models.id_model_map or {};
									models.id_model_map[attr.id_data] = attr;
								end
							end
							attr.models = models;
							attr.block_id = attr.id;
							item = item_class:new(attr);
							ItemClient.AddItem(block_id, item);
						end
					else
						LOG.std(nil, "error", "block_types", "unknown class name %s", attr.class);
					end
				end
			end
		end
		LOG.std(nil, "info", "block_types", "loaded file from %s", filename);
	end
end

-- basic types
function block_types.register_basics()
	if(not block_types.is_basic_loaded) then
		block_types.is_basic_loaded = true;
		block_types.LoadFromFile();

		-- for debugging only, in case block_types.xml does not exist. 
		block_types.register_new_type({id=1, texture="Texture/blocks/grass_top.png", 
			obstruction=true, solid=true, cubeMode=true, threeSideTex=true, });
	end
end

-- dev only function:
-- @filename: type in cmd.exe "dir >filename.txt" and then use this function. 
function block_types.GenerateFromDirFile(filename)
	local filename = filename or "Texture/tileset/blocks/filename.txt"
	local file = ParaIO.open(filename or "Texture/tileset/blocks/filename.txt" , "r");
	local line = file:readline();
	local output = {name="blocks"};
	local id = 1;
	while (line) do
		local name = line:match("([%w_]+%.dds)");
		if(name) then
			local singleSideTex = name:match("_single");
			local sixSideTex = name:match("_six");
			local threeSideTex = name:match("_three");
			local fourSideTex = name:match("_four");
			id = id + 1;
			output[#output+1] = {name="block", attr={id=id, texture="Texture/tileset/blocks/"..name, 
				singleSideTex = if_else(singleSideTex, "true", nil),
				sixSideTex = if_else(sixSideTex, "true", nil),
				threeSideTex = if_else(threeSideTex, "true", nil),
				fourSideTex = if_else(fourSideTex, "true", nil),
			 }}
		end
		line = file:readline()
	end
	file:close();

	local code = commonlib.Lua2XmlString(output, true, true);
	local file = ParaIO.open(filename..".result", "w");
	file:WriteString(code);
	file:close();
end

-- update the re-register all templates with the low level game engine. 
-- @param blockWorld: the ParaBlockWorld object. if nil, the default client block world is used. 
function block_types.update_registered_templates(blockWorld)
	if(all_types) then
		local id, block;
		local count = 0;
		for id, block in pairs(all_types) do
			if(block.Register) then
				count = count + 1;
				block:Register(blockWorld);
			end
		end
		LOG.std(nil, "info", "block_types", "registering %d block templates", count);
	end
end
