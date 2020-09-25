--[[
Title: Item Client
Author(s): LiXizhi
Date: 2013/7/14
Desc: all block template.
User defined custom blocks in the current world directory is saved in `blockWorld.lastsave/customblocks.xml`

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
ItemClient.OnInit();

local item = ItemClient.CreateGetByBlockID(block_id);

local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");
local item = ItemClient.GetItem(names.gold_coin);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/Item.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Item = commonlib.gettable("MyCompany.Aries.Game.Items.Item");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local items = {};

local items_count = {};

local ds_category_blocks = {};

local custom_block_ids = {};

-- the first custom block id
local custom_block_id_begin = 2000;
local custom_block_id_max_count = 3000;

-- add new preloaded item class here. 
function ItemClient.PreloadItemClass()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/Item.lua");	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCollectable.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemMob.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemNPC.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemSnipper.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemBook.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTool.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemSlab.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCode.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemBlockTemplate.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemMovieClip.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemRule.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemDialog.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCommandLine.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCmdUrl.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeries.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesCamera.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesNPC.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesCommands.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesOverlay.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesLight.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemImage.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemDoor.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemRailcar.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemMinimap.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemBlockModel.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemColorBlock.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemEmpty.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemSign.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemBlockBone.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCarpet.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTerrainBrush.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemPaintBrush.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLight.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCodeBlock.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCodeActor.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCodeActorInstance.lua");

	GameLogic.GetFilters():apply_filters("register_item");
end

function ItemClient.OnInit()
	ItemClient.LoadFromCurrentWorld();

	GameLogic.GetPlayerController():LoadFromCurrentWorld();

	-- clear all item count to zero
	items_count = {};

	-- init stats
	NPL.load("(gl)script/apps/Aries/Creator/Game/API/StatList.lua");
	local StatList = commonlib.gettable("MyCompany.Aries.Creator.Game.API.StatList");
	StatList.Init();
end

-- register a new class
function ItemClient.RegisterItemClass(name, class)
	return block_types.RegisterBlockClass(name, class);
end

-- load both official block list as well as custom user defined block list. 
function ItemClient.LoadFromCurrentWorld()
	ItemClient.LoadGlobalBlockList();
	ItemClient.LoadCustomBlocks();
end

-- private: only load once the official block list. 
function ItemClient.LoadGlobalBlockList()
	if(ItemClient.is_global_block_list_loaded) then
		return true;
	end
	ItemClient.is_global_block_list_loaded = true;

	local filename = "config/Aries/creator/block_list.xml";
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		LOG.std(nil, "info", "ItemClient", "loaded block list category from file %s", filename);
		xmlRoot = GameLogic.GetFilters():apply_filters("block_list", xmlRoot);

		local version = if_else(System.options.mc, "mc", "haqi");
		local is_sdk = System.options.isAB_SDK;

		local node, category_node;
		for node in commonlib.XPath.eachNode(xmlRoot, "/blocklist/category") do
			local category_name = node.attr.name;
			category_node = node;
			-- add blocks
			for node in commonlib.XPath.eachNode(category_node, "/block") do
				local attr = node.attr;
				if((not attr.version or attr.version == version) and (not attr.test_sdk or is_sdk) ) then
					local from_id = tonumber(attr.id);
					if(not from_id) then
						if(attr.name) then
							from_id = block_types.names[attr.name];
						end
					end
					if(from_id) then
						local itemDS = ItemClient.AddBlock(from_id, nil, category_name);
						if(attr.block_data) then
							itemDS.block_data = tonumber(attr.block_data);
						end
						if(attr.server_data) then
							itemDS.server_data = NPL.LoadTableFromString(attr.server_data);
						end
						if(attr.icon) then
							itemDS.icon = attr.icon;
						end
						if(attr.to_id) then
							local to_id = tonumber(attr.to_id);
							local id;
							for id = from_id+1, to_id do
								ItemClient.AddBlock(id, nil, category_name);
							end
						end
					end
				end
			end
		end
	end
end

function ItemClient.SaveToCurrentWorld()
	ItemClient.SaveCustomBlocks();
end

-- add a block at the given index. 
-- @param index: if nil, it will be added to last block. 
-- @param category_name: default to "static"
-- @return blockDsItem
function ItemClient.AddBlock(block_id, index, category_name)
	local item = ItemClient.CreateGetByBlockID(block_id);

	local blockDSItem = { __index = item, block_id = block_id };
	setmetatable(blockDSItem, blockDSItem);

	local ds_blocks = ItemClient.GetBlockDS(category_name);
	index = index or (#ds_blocks+1);
	ds_blocks[index] = blockDSItem;	
	return blockDSItem
end

-- search a given block
-- @return a table containing all matching blocks
function ItemClient.SearchBlocks(block_id_or_name, category_name, ds)
	if(category_name and category_name == "all") then
		if(type(block_id_or_name) == "string") then
			--local pattern_search = "*("..block_id_or_name..")*";
			local ds_src = ItemClient.GetBlockDS(category_name);
			local category_ds,index,item;
			ds = ds or {};
			local idMap = {};
			for _,category_ds in pairs(ds_src) do
				for index, item in ipairs(category_ds) do 
					--if(item.block_id == block_id) then
					local id = tostring(item.id);
					local bMatch;
					if(id and string.match(id,block_id_or_name)) then
						bMatch = true;
					else
						local searchkey = item:GetSearchKey();
						if(searchkey and string.match(searchkey,block_id_or_name)) then
							bMatch = true;
						end
					end
					if(bMatch and not idMap[item.id]) then
						idMap[item.id] = true;
						ds[#ds+1] = item;
					end
				end	
			end
			return ds;
		end
	else
		local block_id = tonumber(block_id_or_name);
		if(block_id) then
			if(category_name) then
				local ds_src = ItemClient.GetBlockDS(category_name);
				local index, item;
				for index, item in ipairs(ds_src) do 
					if(item.block_id == block_id) then
						ds = ds or {};
						ds[#ds+1] = item;
						return ds;
					end
				end
			end
		end
	end
end

-- get data source by category name
function ItemClient.GetBlockDS(category_name)
	category_name = category_name or "static";
	if(category_name == "all") then
		return ds_category_blocks;
	end
	local ds_blocks = ds_category_blocks[category_name];
	if(not ds_blocks) then
		ds_blocks = {};
		ds_category_blocks[category_name] = ds_blocks;
	end
	return ds_blocks;
end

function ItemClient.MergeCustomBlockToDS(bImmediate)
	if(not bImmediate) then
		ItemClient.merge_timer = ItemClient.merge_timer or commonlib.Timer:new({callbackFunc = function(timer)
			ItemClient.MergeCustomBlockToDS(true)
		end})
		ItemClient.merge_timer:Change(1);
	else
		local ds = ItemClient.GetBlockDS("tool")
		-- all custom blocks are in tool category by default
		if(ds) then
			-- first remove all custom blocks, and then add again
			local maxid = custom_block_id_begin+custom_block_id_max_count
			for i=#ds, 1, -1  do
				local item = ds[i];
				if(item.block_id and item.block_id>=custom_block_id_begin and item.block_id<=maxid) then
					commonlib.removeArrayItem(ds, i);
				end
			end
			local items = {}
			for _, item in pairs(custom_block_ids) do
				items[#items+1] = item;
			end
			table.sort(items, function(a, b) 
				return a.block_id < b.block_id
			end)
			for _, item in ipairs(items) do
				ItemClient.AddBlock(item.block_id, nil, "tool")
			end
		end
	end
end


function ItemClient.GetItemCount(block_id)
	return items_count[block_id] or 0
end

function ItemClient.SetItemCount(block_id, count, diff_count)
	if(count) then
		items_count[block_id] = count;
	elseif(diff_count) then
		items_count[block_id] = (items_count[block_id] or 0) + diff_count;
	end
	return items_count[block_id] or 0;
end

-- add item
function ItemClient.AddItem(block_id, item)
	if(item) then
		if(not item.tooltip or item.tooltip == "") then
			local tooltip = item:GetDisplayName() or "";
			
			if(item.gold_count) then
				tooltip = tooltip..format(L"\n金币:%d ", item.gold_count);
			end
			if(item.max_count) then
				tooltip = tooltip..format(L"\n上限:%d ", item.max_count);
			end
			-- append id for ease of plugin
			tooltip = tooltip..format(" id: %d", item.block_id);
			item.tooltip = tooltip;
		end
		GameLogic.GetFilters():apply_filters("item_client_new_item_type_added", block_id, item);
	end
	items[block_id] = item;
end

-- get item by id
function ItemClient.GetItem(block_id)
	return items[block_id];
end

function ItemClient.GetItemByName(name)
	if(name) then
		local id = block_types.names[name];
		if(id) then
			return items[id];
		end
	end
end

-- create get an item by block id. 
function ItemClient.CreateGetByBlockID(block_id, item_class)
	local item = items[block_id];
	if(not item) then
		item = ItemClient.CreateByBlockID(block_id, item_class)
	end
	return item;
end

-- create and overwrite 
function ItemClient.CreateByBlockID(block_id, item_class)
	local item = items[block_id];
	local item_class = block_types.GetItemClass(item_class or "");
	item = item_class:new({
		block_id = block_id,
	});
	local block_template = block_types.get(block_id);
	if(block_template) then
		item.icon = block_template:GetIcon();
		item.name = block_template.name;
		item.disable_gen_icon = block_template.disable_gen_icon;
		item.displayname = block_template:GetDisplayName();
	end
	item.icon = item.icon or "";
	items[block_id] = item;
	
	return item;
end

function ItemClient.OnLeaveWorld()
	-- custom_block_ids
	local block_ids;
	for id, item in pairs(custom_block_ids) do
		block_ids = block_ids or {};
		block_ids[#block_ids+1] = id;
	end
	if(block_ids) then
		for _, id in ipairs(block_ids) do
			ItemClient.UnRegisterCustomItem(id);
		end
		custom_block_ids = {};
	end
	-- call on leave for every item types. 
	for key, item in pairs(items) do
		if(item and item.OnLeaveWorld) then
			item:OnLeaveWorld();
		end
	end
end

function ItemClient.GetCustomBlocksXMLRoot()
	local filename = format("%sblockWorld.lastsave/customblocks.xml", ParaWorld.GetWorldDirectory())
	if(not ParaIO.DoesAssetFileExist(filename, true)) then
		filename = format("%sblockWorld/customblocks.xml", ParaWorld.GetWorldDirectory())
		if(not ParaIO.DoesAssetFileExist(filename, true)) then
			filename = nil;
		end
	end
	if(filename) then
		local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
		return xmlRoot;
	end
end

-- custom block is used defined blocks in the current world directory. 
-- @param xmlRoot: if nil, we will use ItemClient.GetCustomBlocksXMLRoot from working directory
function ItemClient.LoadCustomBlocks(xmlRoot)
	custom_block_ids = {};
	xmlRoot = xmlRoot or ItemClient.GetCustomBlocksXMLRoot();
	if(xmlRoot) then
		for node in commonlib.XPath.eachNode(xmlRoot, "/customblocks/block") do
			local attr = node.attr;
			if(attr) then
				attr.id = tonumber(attr.id);
				attr.base_block_id = tonumber(attr.base_block_id);
				if(attr.id and attr.base_block_id) then
					ItemClient.RegisterCustomItem(attr);
				end
			end
		end
	end
	ItemClient.MergeCustomBlockToDS();
end

-- custom block is user defined blocks in the current world directory. 
function ItemClient.SaveCustomBlocks()
	local from_id, to_id = custom_block_id_begin, custom_block_id_begin+custom_block_id_max_count;
	local root = {name="customblocks", attr={desc=string.format("ID must be in range:%d-%d", from_id, to_id)}}
	for id, item in pairs(custom_block_ids) do
		if(item.id>=from_id and item.id<=to_id and item.custom_params) then
			local params = item.custom_params;
			local node = {name="block", attr = params,}
			root[#root+1] = node;
		end
	end
	table.sort(root, function(a, b)
		return (a.attr.id or 0) < (b.attr.id or 0);
	end)
	local filename = format("%sblockWorld.lastsave/customblocks.xml", ParaWorld.GetWorldDirectory())
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(commonlib.Lua2XmlString(root,true,true) or "");
		file:close();
	end
end

-- next custom block id
function ItemClient.GetNextCustomBlockId()
	local next_id = custom_block_id_begin;
	for id, item in pairs(custom_block_ids) do
		if(id>=next_id) then
			next_id = id + 1;
		end
	end
	return next_id;
end

-- return item or nil by texture filename. 
function ItemClient.GetCustomBlockByTexture(filename)
	for id, item in pairs(custom_block_ids) do
		if(item.real_filename==filename) then
			return item;
		end
	end
end

function ItemClient.UnRegisterCustomItem(block_id)
end

-- @param params: a table of {base_block_id, texture, [id], [icon], alphaTestTexture=false, blendedTexture=false, transparent=false}
-- if params.id is not specified, we will generate an unused id instead.
--  please note the same texture filename will always generate the same id. 
function ItemClient.RegisterCustomItem(params)
	local icon = params.icon;
	local base_block_id = params.base_block_id;
	
	local base_block = block_types.get(base_block_id);
	local new_block = {};
	if(base_block) then
		local filename = params.texture or base_block.texture;
		local real_filename = Files.GetWorldFilePath(filename);
		if(not real_filename) then
			LOG.std(nil, "warn", "ItemClient", "RegisterCustomItem id %d with texture %s does not exist ", params.id or 0, filename);
			return;
		end

		local block_id = params.id;
		if(not block_id) then
			-- if id is not specified, the same texture path always maps to the same block id. 
			local item = ItemClient.GetCustomBlockByTexture(real_filename);
			if(item) then
				block_id = item.id
			else
				block_id = ItemClient.GetNextCustomBlockId();
			end
		end
		
		if(block_id and block_id>=custom_block_id_begin and block_id<=(custom_block_id_begin+custom_block_id_max_count)) then
			LOG.std(nil, "info", "ItemClient", "RegisterCustomItem with id %d", block_id);
		else
			LOG.std(nil, "warn", "ItemClient", "RegisterCustomItem id must be in range %d,%d", custom_block_id_begin, custom_block_id_begin+custom_block_id_max_count);
			return;
		end
		new_block.custom_params = params;
		new_block.id = block_id;
		new_block.categoryID = base_block.categoryID;
		new_block.obstruction = base_block.obstruction;
		new_block.solid = base_block.solid;
		new_block.slipperiness = base_block.slipperiness;
		new_block.liquid = base_block.liquid;
		new_block.cubeMode = base_block.cubeMode;
		new_block.light = params.light or base_block.light;
		new_block.threeSideTex = base_block.threeSideTex;
		new_block.fourSideTex = base_block.fourSideTex;
		new_block.singleSideTex = base_block.singleSideTex;
		new_block.sixSideTex = base_block.sixSideTex;
		new_block.customModel = base_block.customModel;
		new_block.customBlockModel = base_block.customBlockModel;
		new_block.climbable = base_block.climbable;
		new_block.blockcamera = base_block.blockcamera;
		new_block.template = base_block.template;
		new_block.transparent = params.transparent or base_block.transparent;
		new_block.alphaTestTexture = params.alphaTestTexture or base_block.alphaTestTexture;
		new_block.blendedTexture = params.blendedTexture or base_block.blendedTexture;
		new_block.ProvidePower = base_block.ProvidePower;
		new_block.shape = base_block.shape;
		new_block.modelName = base_block.modelName;
		new_block.hasAction = base_block.hasAction;
		new_block.color_data = base_block.color_data;
		new_block.color8_data = base_block.color8_data;
		new_block.texture = real_filename;
		new_block.icon = params.icon or new_block.texture or base_block.icon;
		new_block.opacity = base_block.opacity;
		new_block.handleNeighborChange = base_block.handleNeighborChange;

		new_block.name = "customblock"..tostring(new_block.id);
		new_block.class = base_block.class;
		new_block.item_class = base_block.item_class;
		new_block.entity_class = base_block.entity_class;

		if(new_block.customModel) then
			new_block.models = base_block.models;
			new_block.need_update_layer_current = base_block.need_update_layer_current;
			new_block.need_update_layer_upper = base_block.need_update_layer_upper;
			new_block.need_update_layer_lower = base_block.need_update_layer_lower;
		end

		block_types.register_new_type(new_block, true);

		-- ensure the block item is also created
		local item = ItemClient.CreateByBlockID(block_id, new_block.item_class);
		if(item) then
			-- must store block id. 
			params.id = block_id;
			item.custom_params = params;
			item.real_filename = real_filename;
		end
		-- add to custom block 
		custom_block_ids[block_id] = item;

		ItemClient.MergeCustomBlockToDS();
		return item;
	end
end


