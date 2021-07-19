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



function CustomCharItems:AddItemToSkin(skin, item) 
调试信息：geosets index-1  = ccs index
 geosets={ 2, [3]=1, [4]=1, [5]=1, [6]=1, [9]=1, [10]=1 },
 2#201#301#401#501#801#901
-----------------------------------------------------------------
==================AddItemToSkin"
echo:"==================item"
echo:return {
  category="hair",
  geoset={ 2 },
  icon="Texture/Aries/Creator/keepwork/Avatar/icons/2_Avatar_girl_hair_02.png",
  id="82006",
  name="",
  texture="1:Texture/blocks/CustomGeoset/hair/2_Avatar_girl_hair_02.png" 
}
echo:"==================currentSkin"
echo:return "80001;82132;81004;88014;87003;"
echo:"==================currentSkin 1"
echo:return "9#201#301#401#501#801#901#@1:Texture/blocks/CustomGeoset/hair/710_girl_toufa06.png;2:Texture/blocks/CustomGeoset/body/Avatar_boy_body_default.png;3:Texture/blocks/Paperman/eye/eye_boy_02_01.png;4:Texture/blocks/Paperman/mouth/mouth_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_default.png;6:Texture/blocks/CustomGeoset/main/Avatar_tsj.png;@2:character/v3/Item/ObjectComponents/WEAPON/1156_YuanXiaoTorch.x;"
echo:"==================input skinTable"
echo:return {
  attachments={ [2]="character/v3/Item/ObjectComponents/WEAPON/1156_YuanXiaoTorch.x" },
  geosets={ 9, [3]=1, [4]=1, [5]=1, [6]=1, [9]=1, [10]=1 },
  textures={
    "Texture/blocks/CustomGeoset/hair/710_girl_toufa06.png",
    "Texture/blocks/CustomGeoset/body/Avatar_boy_body_default.png",
    "Texture/blocks/Paperman/eye/eye_boy_02_01.png",
    "Texture/blocks/Paperman/mouth/mouth_01.png",
    "Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_default.png",
    "Texture/blocks/CustomGeoset/main/Avatar_tsj.png" 
  } 
}
echo:"==================input skinTable 2"
echo:return {
  attachments={ [2]="character/v3/Item/ObjectComponents/WEAPON/1156_YuanXiaoTorch.x" },
  geosets={ 2, [3]=1, [4]=1, [5]=1, [6]=1, [9]=1, [10]=1 },
  textures={
    "Texture/blocks/CustomGeoset/hair/2_Avatar_girl_hair_02.png",
    "Texture/blocks/CustomGeoset/body/Avatar_boy_body_default.png",
    "Texture/blocks/Paperman/eye/eye_boy_02_01.png",
    "Texture/blocks/Paperman/mouth/mouth_01.png",
    "Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_default.png",
    "Texture/blocks/CustomGeoset/main/Avatar_tsj.png" 
  } 
}
echo:"==================currentSkin 2"
echo:return "2#201#301#401#501#801#901#@1:Texture/blocks/CustomGeoset/hair/2_Avatar_girl_hair_02.png;2:Texture/blocks/CustomGeoset/body/Avatar_boy_body_default.png;3:Texture/blocks/Paperman/eye/eye_boy_02_01.png;4:Texture/blocks/Paperman/mouth/mouth_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_default.png;6:Texture/blocks/CustomGeoset/main/Avatar_tsj.png;@2:character/v3/Item/ObjectComponents/WEAPON/1156_YuanXiaoTorch.x;"
echo:"==================currentSkin 3"
echo:return "80001;82006;81004;88014;87003;"
no such table: CreatureModelDBecho:"===================RefreshCustomGeosets input skin"
echo:"80001;82001;84020;81018;88002;85058"
echo:"===================RefreshCustomGeosets output skin"
echo:"1#201#301#401#501#802#904#@1:Texture/blocks/CustomGeoset/hair/1_Avatar_boy_hair_00.png;2:Texture/blocks/CustomGeoset/body/shirt_02_Avatar_boy_body_01.png;3:Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_boy_fps10_a001.png;5:Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_xiangyu00.png;6:Texture/blocks/CustomGeoset/main/Avatar_tsj.png;@"



更新skin位置：
PlayerAssetFile:RefreshCustomGeosets(player, skin)
pe_mc_player.SetAssetFile(mcmlNode, pageInst, filename)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")

CustomCharItems.defaultModelFile = "character/CC/02human/CustomGeoset/actor.x";
CustomCharItems.ReplaceableAvatars = {};

local models = {};
local items = {};
local category_items = {};

-- called only once
function CustomCharItems:Init()
	if(self.is_inited) then
		return;
	end
	self.is_inited = true;
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/Blue_Army_boss.x"] = "80001;84061;81018;88014;85080;83171";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/Red_Army_boss.x"] = "80001;82011;84060;81018;88014;85079";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/Blue_Army_xiaobing.x"] = "80001;84061;81018;88014;85080;83170";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/Red_Army_xiaobing.x"] = "80001;84060;81018;88014;85079;83172";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/Red_Army_nv1.x"] = "80001;84060;81018;88014;85079;83175";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/Red_Army_nv2.x"] = "80001;84060;81018;88014;85079;83174";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/tufei_movie.x"] = "80001;82065;84048;81018;88014;85070";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/Red_Army_master.x"] = "80001;84060;81018;88014;85079;83173";
	
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school0.x"] = "80001;82011;84003;81018;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school1.x"] = "80001;82028;84003;81018;88014;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school28.x"] = "80001;82148;84033;81058;88014;85049";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school34.x"] = "80001;82104;84012;81018;88014;85009";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school22.x"] = "80001;82126;84029;81018;88014;85050";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school43.x"] = "80001;82148;84012;81018;88014;85009";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school35.x"] = "80001;82004;84012;81018;88014;85009";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school10.x"] = "80001;82028;84052;81018;88002;85017";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school11.x"] = "80001;82029;84052;81018;88014;85002";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school14.x"] = "80001;82028;84010;81018;88014;85005";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school15.x"] = "80001;82011;84010;81018;88014;85005";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school17.x"] = "80001;82011;84017;81018;88014;85019";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school18.x"] = "80001;82029;84017;81018;88014;85019";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school2.x"] = "80001;82029;84003;81018;88014;85002";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school5.x"] = "80001;82029;84015;81018;88014;85017";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school6.x"] = "80001;82028;84013;81018;88014;85010";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school7.x"] = "80001;82047;84013;81018;88014;85010";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school16.x"] = "80001;82011;84010;81018;88014;85005";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school20.x"] = "80001;82001;84017;81018;88014;85019";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school21.x"] = "80001;82126;84016;81049;88020;85018";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school23.x"] = "80001;82148;84032;81049;88020;85027";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school24.x"] = "80001;82170;84032;81049;88020;85027";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school25.x"] = "80001;82104;84032;81049;88020;85027";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school26.x"] = "80001;82010;84032;81049;88020;85027";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school27.x"] = "80001;82126;84013;81049;88020;85010";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school29.x"] = "80001;82170;84013;81049;88020;85010";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school30.x"] = "80001;82104;84013;81049;88020;85010";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school31.x"] = "80001;82010;84013;81049;88020;85010";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school32.x"] = "80001;82126;84012;81049;88020;85009";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school33.x"] = "80001;82170;84012;81049;88020;85009";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school36.x"] = "80001;82170;84003;81049;88020;85018";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school37.x"] = "80001;82148;84003;81049;88020;85018";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school38.x"] = "80001;82170;84003;81049;88020;85018";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school39.x"] = "80001;82104;84003;81049;88020;85018";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school9.x"] =  "80001;82047;84013;81018;88002;85010";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school4.x"] =  "80001;82047;84003;81018;88002;85002";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school11.x"] = "80001;82047;84010;81018;88002;85005";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school12.x"] = "80001;82029;84010;81018;88002;85005";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school1.x"] =  "80001;82011;84003;81018;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school34.x"] = "80001;82104;84012;81049;88002;85009";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school35.x"] = "80001;82004;84012;81049;88002;85009";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school39.x"] = "80001;82104;84032;81049;88002;85028";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school40.x"] = "80001;82004;84032;81049;88002;85028";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/school3.x"] = "80001;82029;84003;81018;88002;85002";
	
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/boy_archaeologist.x"] = "80001;82064;84015;81018;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/girl_host.x"] = "80001;82126;84038;81049;88002;85028";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/boy_host.x"] = "80001;82011;84014;81005;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/movie/boy_staff_bank.x"] = "80001;82011;84014;81005;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/02human/paperman/principal.x"] = "80001;82011;84014;81005;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/02human/paperman/bay01.x"] = "80001;82011;84014;81005;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/02human/paperman/Female_teacher.x"] = "80001;82011;84014;81005;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/02human/paperman/bay07.x"] = "80001;82011;84014;81005;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/02human/blockman/cunzhang.x"] = "80001;82011;84014;81005;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/02human/paperman/boy01.x"] = "80001;82011;84014;81005;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/artwar/02human/blockman/cunming.x"] = "80001;82011;84014;81005;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/blockman/cunzhang.x"] = "80001;83158;84050;81018;88014;85067";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/blockman/cunming.x"] = "80001;82001;84046;81018;88014;85040";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/Female_teachers.x"] = "80001;82126;84032;81018;88014;85027";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/Male_teacher.x"] = "80001;82001;84003;81018;88014;85017";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/boy01.x"] = "80001;82001;84020;81018;88002;85058";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/boy02.x"] = "80001;82029;84015;81018;88002;85017";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/boy03.x"] = "80001;82065;84001;81018;88002;85011";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/boy04.x"] = "80001;82028;84010;81018;88002;85005"; -- 黑鬼，没有黑脸皮肤，默认为学生装
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/boy05.x"] = "80001;82047;84017;81018;88002;85019";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/boy06.x"] = "80001;82001;84027;81018;88002;85024";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/boy07.x"] = "80001;82001;84016;81018;88002;85017";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/girl01.x"] = "80001;82004;84028;81018;88002;85029";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/girl02.x"] = "80001;82085;84013;81018;88002;85010";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/girl03.x"] = "80001;82126;84032;81018;88002;85049";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/girl04.x"] = "80001;82109;84039;81018;88002;85029";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/girl05.x"] = "80001;82170;84012;81018;88002;85009"; --这套因为前段时间才一次给到手，没来得及上架，默认为学生装
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/zaizai.x"] = "80001;82001;84022;81018;88020;85004";
	CustomCharItems.ReplaceableAvatars["character/CC/02human/paperman/nuannuan.x"] = "80001;82010;84022;81049;88004;85004";
	CustomCharItems.ReplaceableAvatars["character/CC/codewar/sunbinjunshixingtai_movie.x"] = "80001;83150;84049;81018;88014;85067";

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
					if (item.data.geoset == nil) then
						item.data.geoset = {};
					end
					item.data.geoset[#(item.data.geoset) + 1] = tonumber(slotId) * 100 + tonumber(itemId);
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
					item.debug = node.attr.debug;
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
	--[[
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
	]]

	local groups = category_items[category];
	if (groups) then
		local itemList = {};
		for _, item in ipairs(groups) do
			if ((avatar and item.avatarMode ~= "false") or (not avatar)) then
				local debug = ParaEngine.GetAppCommandLineByParam("debug", false);
				if (item.debug ~= "true" or (debug == "true" and item.debug == "true" and not avatar)) then
					local data = self:GetItemById(item.id, modelType);
					if (data and (checkGeoset[1] == 0 or checkGeoset[1] == data.geoset[1] or checkGeoset[2] == data.geoset[1])) then
						data.id = item.id;
						data.icon = item.icon;
						data.name = item.name;
						itemList[#itemList+1] = data;
					end
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
				"Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_default.png",
				"Texture/blocks/CustomGeoset/main/Avatar_tsj.png"},
	attachments = {}
}

CustomCharItems.defaultSkinString = "1#201#301#401#501#801#901#@1:Texture/blocks/CustomGeoset/hair/Avatar_boy_hair_01.png;2:Texture/blocks/CustomGeoset/body/Avatar_boy_body_default.png;3:Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_01.png;5:Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_default.png;6:Texture/blocks/CustomGeoset/main/Avatar_tsj.png";

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
			if (id > 300 and id < 400) then
				for _, item in ipairs(items) do
					if (item.data.geoset[1] == id or item.data.geoset[2] == id) then
						idString = item.data.id..";";
						break;
					end
				end
			end
		end
	end
	if (textures) then
		function checkItem(item, geosets)
			for geoset in string.gfind(geosets, "([^#]+)") do
				local id = tonumber(geoset);
				if (item.data.geoset == nil or item.data.geoset[1] == id or item.data.geoset[2] == id or item.data.geoset[1] == nil) then
					return true;
				end
			end
			return false;
		end
		for tex in textures:gmatch("([^;]+)") do
			for _, item in ipairs(items) do
				if (item.data.texture == tex and checkItem(item, geosets) and item.data.id) then
					if (string.find(idString, item.data.id) == nil and string.find(tex, "6:") == nil) then
						idString = idString..item.data.id..";";
					end
					break;
				end
			end
		end
	end

	if (attachments) then
		for att in attachments:gmatch("([^;]+)") do
			for _, item in ipairs(items) do
				if (item.data.attachment == att and item.data.id) then
					local id, filename = string.match(item.data.attachment, "(%d+):(.*)");
					id = tonumber(id);
					if (not use_hair or id ~= 11) then
						if (string.find(idString, item.data.id) == nil) then
							idString = idString..item.data.id..";";
						end
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
		skinTable.geosets[4] = 1;
		for _, gs in ipairs(item.geoset) do
			skinTable.geosets[math.floor(gs/100) + 1] = gs % 100;
		end
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
				for _, gs in ipairs(item.geoset) do
					local str = tostring(gs);
					if (gs < 100) then
						currentSkin = string.gsub(currentSkin, str.."#", "1#");
					elseif (gs < 200) then
					elseif (gs < 300) then
						currentSkin = string.gsub(currentSkin, str, "201");
					elseif (gs < 400) then
						currentSkin = string.gsub(currentSkin, str, "301");
					elseif (gs < 500) then
						currentSkin = string.gsub(currentSkin, str, "401");
					elseif (gs < 600) then
						currentSkin = string.gsub(currentSkin, str, "501");
					elseif (gs < 700) then
					elseif (gs < 800) then
					elseif (gs < 900) then
						currentSkin = string.gsub(currentSkin, str, "801");
					elseif (gs < 1000) then
						currentSkin = string.gsub(currentSkin, str, "901");
					else
					end
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
					currentSkin = string.gsub(currentSkin, "300#", "301#");
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

function CustomCharItems:GetSkinByAsset(assetPath)
	return CustomCharItems.ReplaceableAvatars[assetPath];
end

function CustomCharItems:ReplaceSkinTexture(skin, texture)
	local currentSkin = skin;
	if (not skin or skin == "") then
		currentSkin = CustomCharItems.defaultSkinString;
	elseif (not skin:match("^%d+#")) then
		currentSkin = CustomCharItems:ItemIdsToSkinString(skin);
	end
	local skinTable = CustomCharItems:SkinStringToTable(currentSkin);
	for id, filename in texture:gmatch("(%d+):([^;]+)") do
		skinTable.textures[tonumber(id)] = filename;
	end
	currentSkin = CustomCharItems:SkinTableToString(skinTable);

	return currentSkin;
end

function CustomCharItems:GetItemByGsid(gsid)
	for k, v in pairs(category_items) do
		for k2, item in pairs(v) do
			if (item.gsid == gsid) then
				return item;
			end
		end
	end
end
