--[[
Title: Player Asset files
Author(s): LiXizhi
Date: 2014/4/23
Desc: buildin asset file and their short names. Only short names is used in movie clip serialization. 
so that you can change the filename without breaking the movie file in future. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
PlayerAssetFile:Init();
PlayerAssetFile:GetNameByFilename(filename)
PlayerAssetFile:GetFilenameByName(name)
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/ccs.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CCS = commonlib.gettable("Map3DSystem.UI.CCS");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")

-- local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local last_index = 1;

-- all registered asset files: this will be loaded xml file, following is example format. 
local assetfiles = {
	-- {filename="character/CC/01char/char_male.x", name="default", displayname="通用人物"},
}

-- default scale 
local default_scales = {
	["character/v3/Elf/Female/ElfFemale.xml"] = 1.4,
	["character/v3/TeenElf/Male/TeenElfMale.xml"] = 0.65,
	["character/v3/TeenElf/Female/TeenElfFemale.xml"] = 0.67,
}
local isCustomModels = {
	["character/v3/Elf/Female/ElfFemale.xml"] = true,
	["character/v3/TeenElf/Female/TeenElfFemale.xml"] = true,
	["character/v3/TeenElf/Male/TeenElfMale.xml"] = true,
}
-- default CCS string
local defaultCCS_strings = {
	-- haqi1
	["character/v3/Elf/Female/ElfFemale.xml"] = "0#1#0#2#1#@0#F#0#0#0#0#0#F#0#0#0#0#9#F#0#0#0#0#9#F#0#0#0#0#10#F#0#0#0#0#8#F#0#0#0#0#0#F#0#0#0#0#@1#10001#0#3#11009#0#0#0#0#0#0#0#0#1072#1073#1074#0#0#0#0#0#0#0#0#",
	-- haqi2 female
	["character/v3/TeenElf/Female/TeenElfFemale.xml"] = "4#1#0#0#1#@204#F#0#0#0#0#65535#F#0#0#0#0#65535#F#0#0#0#0#65535#F#0#0#0#0#65535#F#0#0#0#0#65535#F#0#0#0#0#102#F#0#0#0#0#@35033#10001#0#3#11009#0#0#0#0#0#0#0#0#1072#0#1074#0#0#0#41366#0#0#0#0#0#0#0#0#41321#0#@F",
	-- haqi2 male
	["character/v3/TeenElf/Male/TeenElfMale.xml"] = "1#1#0#0#1#@101#F#0#0#0#0#65535#F#0#0#0#0#65535#F#0#0#0#0#65535#F#0#0#0#0#65535#F#0#0#0#0#65535#F#0#0#0#0#200#F#0#0#0#0#@35008#10001#0#3#11009#0#0#0#0#0#0#0#0#1072#0#1074#0#0#0#35003#0#0#0#0#0#0#0#0#35001#0#@F",
	-- paracraft paper char 
	["character/CC/02human/CustomGeoset/actor.x"] = "80001;84010;81018;85005;",
	["customchar"] = "80001;84010;81018;85005;",
}

local categories = {};
local filename_to_name_map = {}
local name_to_filename_map = {}

function PlayerAssetFile:Init()
	if(self.isInited) then
		return 
	end
	self.isInited = true;
	self:LoadFromXMLFile();
	self:LoadAnimationFromXMLFile();
end

function PlayerAssetFile:HasCategory(name)
	return categories[name]~=nil;
end

function PlayerAssetFile:GetCategoryItems(name)
	local category = categories[name]
	if(not category) then
		category = {};
		categories[name] = category;
	end
	return category;
end

-- @param filename: default to "config/Aries/creator/PlayerAssetFile.xml"
function PlayerAssetFile:LoadFromXMLFile(filename)
	filename = filename or "config/Aries/creator/PlayerAssetFile.xml";
	local root = ParaXML.LuaXML_ParseFile(filename);
	if(root) then
		-- clear asset files: 
		assetfiles = {};
		
		local function ProcessNode(parentNode, category)
			for _, node in ipairs(parentNode) do
				if(node.name == "asset") then
					local attr = node.attr;
					if(attr and attr.filename) then
						attr.displayname = attr.displayname and L(attr.displayname) or attr.name;
						if(not filename_to_name_map[attr.filename]) then
							assetfiles[#assetfiles+1] = attr;
						end
						
						if(attr.name) then
							filename_to_name_map[attr.filename] = attr.name;
							name_to_filename_map[attr.name] = attr.filename;
						end
						
						if(category and not attr.hidden) then
							category[#category+1] = attr;
						end

						local debug = ParaEngine.GetAppCommandLineByParam("debug", false);
						if(debug =="true" and attr.isTest)then
							category[#category+1] = attr;
						end

						if(attr.category) then
							local category_ = self:GetCategoryItems(attr.category);
							category_[#category_+1] = attr;
						end
					end
				elseif(node.name == "category") then
					ProcessNode(node, self:GetCategoryItems(node.attr.name or ""))
				else
					ProcessNode(node, category)
				end
			end
		end
		ProcessNode(root, self:GetCategoryItems("common"));
		
		LOG.std(nil, "info", "PlayerAssetFile", "%d assets loaded from %s", #assetfiles, filename);
	else
		LOG.std(nil, "error", "PlayerAssetFile", "can not find file at %s", filename);
	end
	self:FilterCharItems()
end

function PlayerAssetFile:FilterCharItems() 
	if not System.options.isEducatePlatform then
		return 
	end
	--原有的school == "false" 判断由于影响智慧教育上课，去掉了
	assetfiles = commonlib.filter(assetfiles,function (item)
		return (item.name and not item.name:find("haqi"))
	end)

	local keys = {"common","people","effects","furnitures","props","equipment","vehicles","fantasy","animals"}
	for k,v in pairs(keys) do
		categories[v] = commonlib.filter(categories[v],function (item)
			return (item.name and not item.name:find("haqi"))
		end)
	end
end

function PlayerAssetFile:GetAllAssetFiles()
	return assetfiles;
end

-- never used: should only be used when interating all assets. 
-- @param id: integer
function PlayerAssetFile:GetAssetByID(id)
	id = (id) % (#assets);
	local asset = assetfiles[id+1];
	if(asset) then
		return asset.filename;
	end
end

function PlayerAssetFile:GetDefaultAsset(name)
	if name == "default" then
		if System.options.isEducatePlatform then
			return "character/CC/02human/CustomGeoset/actor_kaka.x"
		end
		return "character/CC/02human/CustomGeoset/actor.x";
	end
end

function PlayerAssetFile:GetBuildInFilenameByName(name)
	if name == "default" then
		return self:GetDefaultAsset(name)
	end
	return name_to_filename_map[name] or name
end

function PlayerAssetFile:GetFilenameByName(name)
	if name == "default" then
		return self:GetDefaultAsset(name)
	end
	return name_to_filename_map[name] or Files.GetFilePath(name) or name;
end

function PlayerAssetFile:GetNameByFilename(filename)
	return filename_to_name_map[filename] or Files:GetShortFileFromLongFile(filename) or filename;
end

function PlayerAssetFile:GetValidAssetByString(str)
	local asset_filename = self:GetFilenameByName(str);
	asset_filename = Files.GetWorldFilePath(asset_filename);
	return asset_filename;
end

function PlayerAssetFile:IsCustomModelOrGeosets(filename)
	return self:IsCustomModel(filename) or self:HasCustomGeosets(filename);
end

function PlayerAssetFile:IsCustomModel(filename)
	return filename and isCustomModels[filename];
end

--- @param assetModelPath string: e.g. character/CC/02human/CustomGeoset/actor.x
function PlayerAssetFile:HasCustomGeosets(assetModelPath)
	return assetModelPath ~= nil and string.find(assetModelPath, "CustomGeoset") ~= nil;
end

-- mostly for haqi character
function PlayerAssetFile:GetDefaultCCSString(assetFile)
	return defaultCCS_strings[assetFile or ""] or "0#1#0#2#1#@0#F#0#0#0#0#0#F#0#0#0#0#9#F#0#0#0#0#9#F#0#0#0#0#10#F#0#0#0#0#8#F#0#0#0#0#0#F#0#0#0#0#@1#10001#0#3#11009#0#0#0#0#0#0#0#0#1072#1073#1074#0#0#0#0#0#0#0#0#";
end

-- @param skin: this is actually CCS string 
function PlayerAssetFile:RefreshCustomModel(player, skin, assetFile)
	if(skin and skin:match("^%d+#")) then
		CCS.ApplyCCSInfoString_MC(player, skin);
	else
		CCS.ApplyCCSInfoString_MC(player, self:GetDefaultCCSString(assetFile));
	end
end

-- get default player scale for the given file. default to 1
function PlayerAssetFile:GetDefaultScale(filename)
	return default_scales[filename] or 1;
end

function PlayerAssetFile:GetDefaultCustomGeosets(assetfile)
	return CustomCharItems:GetDefaultSkinString(assetfile)
end

function PlayerAssetFile:CreateMountPet(petId, modelUrl, x, y, z, skin)

	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/Entity.lua");
	local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
	local entity = MyCompany.Aries.Game.EntityManager.EntityPlayer:new({
		x, y, z
	});

	entity:CreateInnerObject(modelUrl, true, nil, 1, skin, petId)

	return entity;
end

--- @param player ParaObject: All player obj in the scene
--- @param skin string: 80001;21122;
--- @param playerUserName string: userAccount, self.username, make sure to get the right player that the user is controlling
function PlayerAssetFile:RefreshCustomGeosets(player, skin, playerEntity)
	if(not player) then
		return;
	end

	local skinIds = skin;
	local playerUserName;

	if playerEntity then
		playerUserName = playerEntity.username
	end

	local assetfile = player:GetField("assetfile", "")
	if (not skin or skin == "") then
		skin = self:GetDefaultCustomGeosets(assetfile);
	elseif (not skin:match("^%d+#")) then
		skin = CustomCharItems:ItemIdsToSkinString(skin, assetfile);
	end
	-- commonlib.echo("PlayerAssetFile:RefreshCustomGeosets:skin"); commonlib.echo(skin);
	-- echo:"skin ds"
	-- echo:return "6#201#301#401#501#801#901#
	-- @1:Texture/blocks/CustomGeoset/hair/36_Avatar_boy_hair_02.png;
	-- 2:Texture/blocks/CustomGeoset/body/84064_Avatar_boy_body_54.png;
	-- 3:Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png;4:Texture/blocks/Paperman/mouth/mouth_boy_fps10_a001.png;
	-- 5:Texture/blocks/CustomGeoset/leg/85082_Avatar_boy_leg_72.png;6:Texture/blocks/CustomGeoset/main/Avatar_tsj.png;
	-- @2:character/v3/Item/ObjectComponents/WEAPON/1022_LargeLollipop.x;
	-- 15:character/v3/Item/ObjectComponents/Back/1735_ColiseumFireBackS1.anim.x;
	-- 20:character/CC/ObjectComponents/ride/tank.anim.x;"
	local geosets, textures, attachments =  string.match(skin, "([^@]+)@([^@]+)@?(.*)");

	if (not geosets) then
		geosets = skin;
	end

	local use_hair = false;
	local character = player:ToCharacter();

	-- echo:"geosets"
    -- echo:return "6#201#301#401#501#801#901#"
	if (geosets) then
		for geoset in string.gfind(geosets, "([^#]+)") do
			local id = tonumber(geoset);
			if (id > 0 and id < 100) then
				use_hair = true;
			end
			character:SetCharacterSlot(math.floor(id / 100), id % 100);
		end
	end

	-- textures data structure
	-- 1:Texture/blocks/CustomGeoset/hair/36_Avatar_boy_hair_02.png;2:Texture/blocks/CustomGeoset/body/84064_Avatar_boy_body_54.png;
	if (textures) then
		local replace_hand = false;
		for id, filename in textures:gmatch("(%d+):([^;]+)") do
			id = tonumber(id)
			if (id == 6) then
				replace_hand = true;
			end
			player:SetReplaceableTexture(id, ParaAsset.LoadTexture("", filename, 1));
		end
		if (not replace_hand) then
			player:SetReplaceableTexture(6, ParaAsset.LoadTexture("", CustomCharItems.defaultSkinTable.textures[6], 1));
		end
	end

	character:RemoveAttachment(2, 2);
	character:RemoveAttachment(11, 11);
	character:RemoveAttachment(15, 15);

	local isAttachmentStringExist = attachments and string.len(attachments) > 0;
	if (isAttachmentStringExist) then
		for id, filename in attachments:gmatch("(%d+):([^;]+)") do
			id = tonumber(id);
			if (use_hair and id == 11) then
				character:RemoveAttachment(11, 11);
			else
				local meshModel;
				if (string.find(filename, "anim.x")) then
					meshModel = ParaAsset.LoadParaX("", filename);
				else
					meshModel = ParaAsset.LoadStaticMesh("", filename);
				end
				if (meshModel and (id ~= ATTACHMENT_ID_PET)) then
					character:AddAttachment(meshModel, id, id);
				end
			end
		end
	end

	if(playerEntity) then
		PlayerAssetFile.ShowMountOrNot(player, attachments, playerEntity, isAttachmentStringExist, skinIds);
	end
end


function PlayerAssetFile.ShowMountOrNot(player, attachments, playerEntity, isAttachmentStringExist, skinIds)
	local isPetSkinIdExist = attachments and attachments ~="" and string.find(attachments, "20:");
	if(not isPetSkinIdExist) then
		if(playerEntity.petObj) then
			playerEntity:UnloadPet();
		end
		return
	end
	player = player or playerEntity:GetInnerObject();
	local isMcPlayer = player.name == "mc_player"
	if(isMcPlayer) then
		return;
	end

	local character = player:ToCharacter();
	local ATTACHMENT_ID_PET = 20;
	local playerId = player.id or "";
	local petId = playerId.."@pet";

	local modelUrl = PlayerAssetFile:GetAttachmentModelUrlByID(ATTACHMENT_ID_PET, attachments)
	local filename = CustomCharItems:GetModelBySkinDDS(modelUrl)
	local skinTexture,skinIndex
	if filename and filename ~= "" and filename ~= modelUrl then --抱抱龙
		skinTexture = modelUrl
		modelUrl = filename
		skinIndex = CustomCharItems:GetDDSSkinColorIndex(skinTexture)
	end

	local function updatePet()
		local petModel = ParaAsset.LoadParaX("", modelUrl);
		character:ResetBaseModel(petModel);
		if skinTexture and skinTexture ~= "" then
			if skinIndex and skinIndex > 0 then
				character:SetBodyParams(skinIndex,-1,-1,-1,-1)
			else
				player:SetReplaceableTexture(1, ParaAsset.LoadTexture("", skinTexture, 1));
			end
		end
	end

	if(not playerEntity.petObj) then
		updatePet()
		local x, y, z = player:GetPosition();
		local newSkin = PlayerAssetFile.RemovePetIdFromSkinIds(skinIds);
		local dummmyPlayerEntity = PlayerAssetFile:CreateMountPet(
			petId, CustomCharItems.defaultModelFile, 
			x, y, z, 
			newSkin);

		local dummmyPlayerObj = dummmyPlayerEntity:GetInnerObject();
		dummmyPlayerObj:ToCharacter():MountOn(player)
		dummmyPlayerObj:SetAnimation(187);
		if(not playerEntity:IsVisible()) then
			dummmyPlayerObj:SetVisible(false)
		end

		playerEntity.petObj = dummmyPlayerObj;
		playerEntity.petEntity = dummmyPlayerEntity
		commonlib.TimerManager.SetTimeout(function()
			dummmyPlayerEntity:SetHeadOnDisplay(playerEntity.headUI_Params)
			playerEntity:SetHeadOnDisplay(nil);
		end, 3000);
	end
	if(playerEntity.petObj) then
		updatePet()
		playerEntity.petObj:ToCharacter():MountOn(player)
		playerEntity.petObj:SetAnimation(187);
		PlayerAssetFile:RefreshCustomGeosets(playerEntity.petObj, PlayerAssetFile.RemovePetIdFromSkinIds(skinIds));
	end
end 



-- remove the PetSkin
function PlayerAssetFile.RemovePetIdFromSkinIds(skin)
	local newSkin = "";
	local itemIds = commonlib.split(skin, ";");

	for _, idString in ipairs(itemIds) do
		if(not CustomCharItems.PetIds[idString]) then
			newSkin = newSkin..idString..";";
		end
	end
	return newSkin;
end

function PlayerAssetFile.AddPetIdToSkinIds(skin, petId)
	if not petId or petId == "" then
		return skin;
	end
	local noPetSkin = PlayerAssetFile.RemovePetIdFromSkinIds(skin);
	return noPetSkin..petId..";";
end

function PlayerAssetFile.IsPetSkinIdExist(skin)
	local skinStr = CustomCharItems:ItemIdsToSkinString(skin);
	local geosets, textures, attachments =  string.match(skinStr, "([^@]+)@([^@]+)@?(.*)");
	local isPetSkinIdExist = attachments and string.find(attachments, "20:");
	return isPetSkinIdExist;
end

--- @param id number
--- @param attachments string: e.g. 2:character/v3/Item/ObjectComponents/WEAPON/1022_LargeLollipop.x;15:character/v3/Item/ObjectComponents/Back/1735_ColiseumFireBackS1.anim.x;
function PlayerAssetFile:GetAttachmentModelUrlByID(id, attachments)
	for _id, modelUrl in attachments:gmatch("(%d+):([^;]+)") do
		if(tonumber(_id) == id) then
			return modelUrl
		end
	end

	return nil;
end 

function PlayerAssetFile:ShowWingAttachment(player, skin, show)
	if (not skin or skin == "") then
		return;
	end
	skin = CustomCharItems:ChangeSkinStringToItems(skin);
	local character = player:ToCharacter();
	local itemIds = commonlib.split(skin, ";");
	if (itemIds and #itemIds > 0) then
		for i = 1, #itemIds do
			local item = CustomCharItems:GetItemById(itemIds[i]);
			if (item and item.wing == "true") then
				if (show) then
					if (item.attachment) then
						local id, filename = string.match(item.attachment, "(%d+):(.*)");
						id = tonumber(id);
						local meshModel;
						if (string.find(filename, "anim.x")) then
							meshModel = ParaAsset.LoadParaX("", filename);
						else
							meshModel = ParaAsset.LoadStaticMesh("", filename);
						end
						if (meshModel) then
							character:AddAttachment(meshModel, id, id);
						end
					end
				else
					character:RemoveAttachment(15, 15);
				end

				break;
			end
		end
	end
end

function PlayerAssetFile:GetDefaultAssetFileBySkin(skin)
	return CustomCharItems:GetDefaultAssetBySkin(skin)
end

function PlayerAssetFile:CheckDefaultSkinValid(skin)
	local asset = self:GetDefaultAssetFileBySkin(skin);
	if asset and asset ~= "" then
		local defaultSkin = "character/CC/02human/CustomGeoset/actor_kaka.x"
		local defaultSkin1 = "character/CC/02human/CustomGeoset/actor.x"
		if System.options.isEducatePlatform then
			return asset == defaultSkin;
		end
		return asset == defaultSkin1;
	end
	return true
end

PlayerAssetFile.Store = {
	-- current user skin
	skin = nil,
	assetfiles = nil
}

local animations = {};
local animation_name_map = {};
local animation_id_map = {};
local animation_categories = {};
-- player animation
function PlayerAssetFile:LoadAnimationFromXMLFile(filename)
	filename = filename or "config/Aries/creator/PlayerAnimAssetFile.xml";
	local root = ParaXML.LuaXML_ParseFile(filename);
	if(root) then
		-- clear asset files: 
		animations = {};
		for itemNode in commonlib.XPath.eachNode(root, "/PlayerAnimAssets") do
			for _, node in ipairs(itemNode) do
				if node and node.name == "category" and node.attr and node.attr.name then
					animation_categories[node.attr.name] = node
				end
				for _,item in ipairs(node) do
					if item and item.name == "asset" then
						local data = item.attr
						data.category = "action"
						animation_name_map[data.name] = data
						animation_id_map[data.id] = data
						animations[#animations+1] = data
					end
				end
			end
		end
		LOG.std(nil, "info", "PlayerAssetFile", "%d animation assets loaded from %s", #animations, filename);
	else
		LOG.std(nil, "error", "PlayerAssetFile", "can not find file at %s", filename);
	end
end

function PlayerAssetFile:GetAnimationItem(name)
	if animation_name_map[name] then
		return animation_name_map[name]
	end
	if animation_id_map[name] then
		return animation_id_map[name]
	end
	return nil
end

function PlayerAssetFile:GetAnimationCategory(name)
	if animation_categories[name] then
		return animation_categories[name]
	end
	return nil
end

function PlayerAssetFile:GetAllAnimations()
	return animations
end
