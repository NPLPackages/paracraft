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
					item.avatarMode = node.attr.avatarMode;
					local data = self:GetItemById(item.id);
					if (data) then
						data.id = item.id;
						data.gsid = item.gsid;
						data.icon = item.icon;
						data.name = item.name;
						data.category = name;
						data.wing = node.attr.wing;
					end
					groups[#groups+1] = item;
				end
				category_items[name] = groups;
			end
		end

	else
		LOG.std(nil, "error", "CustomCharItems", "can not find file at %s", filename);
	end
end

function CustomCharItems:GetModelItems(filename, category, skin, avatar)
	if (not skin:match("^%d+#")) then
		skin = CustomCharItems:ItemIdsToSkinString(skin);
	end
	for type, names in pairs(models) do
		for _, name in ipairs(names) do
			if (name == filename) then
				return self:GetItemsByCategory(category, type, skin, avatar);
			end
		end
	end
end

function CustomCharItems:GetItemsByCategory(category, modelType, skin, avatar)
	local checkGeoset = {0, 0};
	if (category == "shirt") then
		if ((string.find(skin, "901#") ~= nil and string.find(skin, "Avatar_boy_leg_default") == nil) or string.find(skin, "903")) then
			checkGeoset[1] = 801;
			checkGeoset[2] = 801;
		end
	elseif (category == "pants") then
		if (string.find(skin, "801#") ~= nil and string.find(skin, "Avatar_boy_body_default") == nil) then
			checkGeoset[1] = 901;
			checkGeoset[2] = 903;
		end
	end

	local groups = category_items[category];
	if (groups) then
		local itemList = {};
		for _, item in ipairs(groups) do
			if ((avatar and item.avatarMode ~= "false") or (not avatar)) then
				local data = self:GetItemById(item.id, modelType);
				if (data and (checkGeoset[1] == 0 or checkGeoset[1] == data.geoset or checkGeoset[2] == data.geoset)) then
					data.id = item.id;
					data.icon = item.icon;
					data.name = item.name;
					itemList[#itemList+1] = data;
				end
			end
		end
		return itemList;
	end
end

function CustomCharItems:GetItemById(id, modelType)
	for _, item in ipairs(items) do
		if (item.id == id) then
			if (modelType) then
				for _, model in ipairs(item.model) do
					if (model == modelType) then
						return item.data;
					end
				end
			else
				return item.data;
			end
		end
	end
end

CustomCharItems.defaultSkinTable = {
	geosets = {1, 0, 1, 1, 1, 1, 0, 0, 1, 1},
	textures = {"Texture/blocks/CustomGeoset/hair/Avatar_boy_hair_01.png",
				"Texture/blocks/CustomGeoset/body/Avatar_boy_body_default.png",
				"Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png",
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

-- id:810001;82001;
function CustomCharItems:SkinStringToItemIds(skin)
	if (not skin) then return "" end;
	local idString = "80001;";
	local geosets, textures, attachments =  string.match(skin, "([^@]+)@([^@]+)@?(.*)");
	local use_hair = false;
	if (geosets) then
		for geoset in string.gfind(geosets, "([^#]+)") do
			local id = tonumber(geoset);
			if (id > 0 and id < 100) then
				use_hair = true;
			end
		end
	end
	if (textures) then
		for tex in textures:gmatch("([^;]+)") do
			for _, item in ipairs(items) do
				if (item.data.texture == tex) then
					idString = idString..item.data.id..";";
					break;
				end
			end
		end
	end

	if (attachments) then
		for att in attachments:gmatch("([^;]+)") do
			for _, item in ipairs(items) do
				if (item.data.attachment == att) then
					local id, filename = string.match(item.data.attachment, "(%d+):(.*)");
					id = tonumber(id);
					if (not use_hair or id ~= 11) then
						idString = idString..item.data.id..";";
					end
				end
			end
		end
	end
	return idString;
end

function CustomCharItems:ItemIdsToSkinString(idString)
	local skinTable = CustomCharItems:SkinStringToTable(CustomCharItems.defaultSkinString);
	local itemIds = commonlib.split(idString, ";");
	if (itemIds and #itemIds > 0) then
		for _, id in ipairs(itemIds) do
			local data = self:GetItemById(id);
			if (data) then
				CustomCharItems:AddItemToSkinTable(skinTable, data);
			end
		end
	end
	local skin = CustomCharItems:SkinTableToString(skinTable);
	return skin;
end

function CustomCharItems:ChangeSkinStringToItems(skin)
	if (skin:match("^%d+#")) then
		skin = CustomCharItems:SkinStringToItemIds(skin);
	end
	return skin;
end

function CustomCharItems:IsWing(attachment)
	for _, item in ipairs(items) do
		if (item.data and item.data.wing == "true" and string.find(item.data.attachment, attachment)) then
			return true;
		end
	end
	return false;
end

function CustomCharItems:GetUsedItemsBySkin(skin)
	local usedItems = {};
	if (not skin) then return usedItems end;
	if (skin:match("^%d+#")) then
		local geosets, textures, attachments =  string.match(skin, "([^@]+)@([^@]+)@?(.*)");
		if (textures) then
			for tex in textures:gmatch("([^;]+)") do
				if (string.find(CustomCharItems.defaultSkinString, tex) == nil) then
					for _, item in ipairs(items) do
						if (item.data.texture == tex) then
							usedItems[#usedItems+1] = {id = item.data.id, name = item.data.category, icon = item.data.icon};
							break;
						end
					end
				end
			end
		end

		if (attachments) then
			for att in attachments:gmatch("([^;]+)") do
				for _, item in ipairs(items) do
					if (item.data.attachment == att) then
						usedItems[#usedItems+1] = {id = item.data.id, name = item.data.category, icon = item.data.icon};
					end
				end
			end
		end
	else
		local itemIds = commonlib.split(skin, ";");
		if (itemIds and #itemIds > 0) then
			for _, id in ipairs(itemIds) do
				local data = self:GetItemById(id);
				if (data) then
					usedItems[#usedItems+1] = {id = id, name = data.category, icon = data.icon};
				end
			end
		end
	end
	return usedItems;
end

function CustomCharItems:AddItemToSkinTable(skinTable, item)
	if (not skinTable or not item) then
		return;
	end
	if (item.geoset) then
		skinTable.geosets[math.floor(item.geoset/100) + 1] = item.geoset % 100;
	end
	if (item.texture) then
		local id, filename = string.match(item.texture, "(%d+):(.*)");
		skinTable.textures[tonumber(id)] = filename;
	end
	if (item.attachment) then
		local id, filename = string.match(item.attachment, "(%d+):(.*)");
		skinTable.attachments[tonumber(id)] = filename;
	end
end

function CustomCharItems:AddItemToSkin(skin, item)
	local currentSkin = skin;
	if (not skin:match("^%d+#")) then
		currentSkin = CustomCharItems:ItemIdsToSkinString(skin);
	end
	local skinTable = CustomCharItems:SkinStringToTable(currentSkin);
	CustomCharItems:AddItemToSkinTable(skinTable, item);
	currentSkin = CustomCharItems:SkinTableToString(skinTable);
	if (not skin:match("^%d+#")) then
		currentSkin = CustomCharItems:SkinStringToItemIds(currentSkin);
	end
	return currentSkin;
end

function CustomCharItems:RemoveItemInSkin(skin, itemId)
	local currentSkin = skin;
	if (skin:match("^%d+#")) then
		local item = CustomCharItems:GetItemById(itemId);
		if (item) then
			if (item.geoset) then
				local str = tostring(item.geoset);
				if (item.geoset < 100) then
					currentSkin = string.gsub(currentSkin, str.."#", "1#");
				elseif (item.geoset < 200) then
				elseif (item.geoset < 300) then
					currentSkin = string.gsub(currentSkin, str, "201");
				elseif (item.geoset < 400) then
					currentSkin = string.gsub(currentSkin, str, "301");
				elseif (item.geoset < 500) then
					currentSkin = string.gsub(currentSkin, str, "401");
				elseif (item.geoset < 600) then
					currentSkin = string.gsub(currentSkin, str, "501");
				elseif (item.geoset < 700) then
				elseif (item.geoset < 800) then
				elseif (item.geoset < 900) then
					currentSkin = string.gsub(currentSkin, str, "801");
				elseif (item.geoset < 1000) then
					currentSkin = string.gsub(currentSkin, str, "901");
				else
				end
			end
			if (item.texture) then
				local id, tex = string.match(item.texture, "(%d+):([^;]+)");
				id = tonumber(id);
				currentSkin = string.gsub(currentSkin, tex, CustomCharItems.defaultSkinTable.textures[id]);
			end
			if (item.attachment) then
				local id, tex = string.match(item.attachment, "(%d+):([^;]+)");
				id = tonumber(id);
				if (id == 11) then
					currentSkin = string.gsub(currentSkin, "0#", "1#");
				end
				currentSkin = string.gsub(currentSkin, item.attachment..";", "");
			end
		end
	else
		if (itemId) then
			currentSkin = string.gsub(skin, itemId..";", "", 1);
		end
	end
	return currentSkin;
end

CustomCharItems.ExistAvatars = {
	"1#201#301#401#501#802#902#@1:Texture/blocks/CustomGeoset/hair/Avatar_boy_hair_01.png;2:Texture/blocks/CustomGeoset/body/Avatar_boy_body_graduation.png;3:Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_graduation.png",
	"1#201#301#401#501#802#902#@1:Texture/blocks/CustomGeoset/hair/Avatar_boy_hair_01.png;2:Texture/blocks/CustomGeoset/body/Avatar_boy_body_party.png;3:Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_party.png",
	"1#201#301#401#501#802#902#@1:Texture/blocks/CustomGeoset/hair/Avatar_boy_hair_01.png;2:Texture/blocks/CustomGeoset/body/Avatar_boy_body_activity.png;3:Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_activity.png",
	"2#201#301#401#501#803#902#@1:Texture/blocks/CustomGeoset/hair/Avatar_girl_hair_01.png;2:Texture/blocks/CustomGeoset/body/Avatar_girl_body_graduation.png;3:Texture/blocks/Paperman/eye/eye_girl_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_girl_01_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_girl_leg_default.png",
	"2#201#301#401#501#803#902#@1:Texture/blocks/CustomGeoset/hair/Avatar_girl_hair_01.png;2:Texture/blocks/CustomGeoset/body/Avatar_girl_body_party.png;3:Texture/blocks/Paperman/eye/eye_girl_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_girl_01_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_girl_leg_default.png",
	"2#201#301#401#501#803#902#@1:Texture/blocks/CustomGeoset/hair/Avatar_girl_hair_01.png;2:Texture/blocks/CustomGeoset/body/Avatar_girl_body_activity.png;3:Texture/blocks/Paperman/eye/eye_girl_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_girl_01_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_girl_leg_default.png",
}

function CustomCharItems:CheckAvatarExist(skin)
	for i = 1, #CustomCharItems.ExistAvatars do
		if (CustomCharItems.ExistAvatars[i] == skin) then
			return true;
		end
	end
	return false;
end
