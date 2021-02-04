--[[
Title: Custom Char Models and Skins
Author(s): chenjinxian
Date: 2020/12/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
CustomCharItems:Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")

CustomCharItems.defaultModelFile = "character/CC/02human/CustomGeoset/actor.x";

local models = {};
local items = {};
local category_items = {};

-- called only once
function CustomCharItems:Init()
	if(self.is_inited) then
		return;
	end
	self.is_inited = true;

	local root = ParaXML.LuaXML_ParseFile("config/Aries/creator/CustomCharItems.xml");
	if (root) then
		local id = 0;
		for itemNode in commonlib.XPath.eachNode(root, "/CustomCharItems/items/item") do
			local item = {};
			item.data = {};
			for _, node in ipairs(itemNode) do
				local attr = node.attr;
				local name = node.name;
				if (name == "geoset") then
					local slotId = attr.category or 0;
					local itemId = attr.id or 0;
					item.data.geoset = tonumber(slotId) * 100 + tonumber(itemId);
				elseif (name == "texture") then
					item.data.texture = string.format("%s:%s", attr.id or "0", attr.filename or "");
				elseif (name == "attachment") then
					item.data.attachment = string.format("%s:%s", attr.id or "11", attr.filename or "");
				end
				id = id + 1;
			end

			local modelPath = itemNode.attr.model;
			local itemId = itemNode.attr.id;
			if (modelPath and itemId) then
				item.id = itemId;
				item.model = {};
				for groupName in modelPath:gmatch("[^;]+") do
					item.model[#item.model+1] = groupName;
				end
			end
			items[#items+1] = item;
		end

		for modelGroup in commonlib.XPath.eachNode(root, "/CustomCharItems/models") do
			local type = modelGroup.attr.type;
			local groups = {};
			for _, node in ipairs(modelGroup) do
				groups[#groups+1] = node.attr.filename;
			end
			models[type] = groups;
		end

		LOG.std(nil, "info", "CustomCharItems", "%d skins loaded from %s", id, filename);

		root = ParaXML.LuaXML_ParseFile("config/Aries/creator/CustomCharList.xml");
		if (root) then
			for group in commonlib.XPath.eachNode(root, "/customcharlist/category") do
				local name = group.attr.name;
				local groups = {};
				for _, node in ipairs(group) do
					local item = {};
					item.id = node.attr.id;
					item.gsid = node.attr.gsid;
					item.icon = node.attr.icon;
					item.name = node.attr.name;
					groups[#groups+1] = item;
				end
				category_items[name] = groups;
			end
		end

	else
		LOG.std(nil, "error", "CustomCharItems", "can not find file at %s", filename);
	end
end

function CustomCharItems:GetModelItems(filename, category, skin)
	for type, names in pairs(models) do
		for _, name in ipairs(names) do
			if (name == filename) then
				return self:GetItemsByCategory(category, type, skin);
			end
		end
	end
end

function CustomCharItems:GetItemsByCategory(category, modelType, skin)
	local checkGeoset = 0;
	if (category == "shirt") then
		if (string.find(skin, "901#") ~= nil and string.find(skin, "Avatar_boy_leg_default") == nil) then
			checkGeoset = 801;
		end
	elseif (category == "pants") then
		if (string.find(skin, "801#") ~= nil and string.find(skin, "Avatar_boy_body_default") == nil) then
			checkGeoset = 901;
		end
	end

	local groups = category_items[category];
	if (groups) then
		local itemList = {};
		for _, item in ipairs(groups) do
			local data = self:GetItemById(item.id, modelType);
			if (data and (checkGeoset == 0 or checkGeoset == data.geoset)) then
				data.icon = item.icon;
				data.name = item.name;
				itemList[#itemList+1] = data;
			end
		end
		return itemList;
	end
end

function CustomCharItems:GetItemById(id, modelType)
	for _, item in ipairs(items) do
		if (item.id == id) then
			for _, model in ipairs(item.model) do
				if (model == modelType) then
					return item.data;
				end
			end
		end
	end
end

CustomCharItems.defaultSkinTable = {
	geosets = {1, 0, 1, 1, 1, 1, 0, 0, 1, 1},
	textures = {"Texture/blocks/CustomGeoset/hair/Avatar_boy_hair_01.png",
				"Texture/blocks/CustomGeoset/body/Avatar_boy_body_default.png",
				"Texture/blocks/Paperman/eye/eye1.png",
				"Texture/blocks/Paperman/mouth/mouth_01.png",
				"Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_default.png"},
	attachments = {}
}

CustomCharItems.defaultSkinString = "1#201#301#401#501#801#901#@1:Texture/blocks/CustomGeoset/hair/Avatar_boy_hair_01.png;2:Texture/blocks/CustomGeoset/body/Avatar_boy_body_default.png;3:Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_default.png";

function CustomCharItems:SkinTableToString(skin)
	local customGeosets = "";
	for id, geoset in pairs(skin.geosets) do
		customGeosets = customGeosets..format("%d#", (id-1) * 100 + geoset);
	end
	customGeosets = customGeosets.."@";
	for i = 1, #skin.textures do
		customGeosets = customGeosets..format("%d:%s;", i, skin.textures[i]);
	end
	customGeosets = customGeosets.."@";
	for id, filename in pairs(skin.attachments) do
		customGeosets = customGeosets..format("%d:%s;", id, filename);
	end

	return customGeosets;
end

function CustomCharItems:SkinStringToTable(skin)
	local skinTable = {};
	local geosets, textures, attachments =  string.match(skin, "([^@]+)@([^@]+)@?(.*)");
	if (geosets) then
		skinTable.geosets = {};
		for geoset in string.gfind(geosets, "([^#]+)") do
			local id = tonumber(geoset);
			skinTable.geosets[math.floor(id/100 + 1)] = id % 100;
		end
	end

	if (textures) then
		skinTable.textures = {};
		for id, filename in textures:gmatch("(%d+):([^;]+)") do
			id = tonumber(id)
			skinTable.textures[id] = filename;
		end
	end

	if (attachments) then
		skinTable.attachments = {};
		for id, filename in attachments:gmatch("(%d+):([^;]+)") do
			id = tonumber(id)
			skinTable.attachments[id] = filename;
		end
	end

	return skinTable;
end
