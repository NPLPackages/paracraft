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
local CCS = commonlib.gettable("Map3DSystem.UI.CCS");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")

local last_index = 1;

-- all registered asset files: this will be loaded xml file, following is example format. 
local assetfiles = {
	-- {filename="character/CC/01char/char_male.x", name="default", displayname="通用人物"},
}

-- default scale 
local default_scales = {
	["character/v3/Elf/Female/ElfFemale.xml"] = 1.4,
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

function PlayerAssetFile:GetFilenameByName(name)
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


function PlayerAssetFile:IsCustomModel(filename)
	return "character/v3/Elf/Female/ElfFemale.xml" == filename;
end

function PlayerAssetFile:HasCustomGeosets(filename)
	return filename ~= nil and string.find(filename, "CustomGeoset") ~= nil;
end

-- mostly for haqi character
function PlayerAssetFile:GetDefaultCCSString()
	return "0#1#0#2#1#@0#F#0#0#0#0#0#F#0#0#0#0#9#F#0#0#0#0#9#F#0#0#0#0#10#F#0#0#0#0#8#F#0#0#0#0#0#F#0#0#0#0#@1#10001#0#3#11009#0#0#0#0#0#0#0#0#1072#1073#1074#0#0#0#0#0#0#0#0#";
end

-- @param skin: this is actually CCS string 
function PlayerAssetFile:RefreshCustomModel(player, skin)
	if(skin and skin:match("^%d+#")) then
		CCS.ApplyCCSInfoString_MC(player, skin);
	else
		CCS.ApplyCCSInfoString_MC(player, self:GetDefaultCCSString());
	end
end

-- get default player scale for the given file. default to 1
function PlayerAssetFile:GetDefaultScale(filename)
	return default_scales[filename] or 1;
end

function PlayerAssetFile:GetDefaultCustomGeosets()
	return CustomCharItems.defaultSkinString;
end

function PlayerAssetFile:RefreshCustomGeosets(player, skin)
	if (not skin or skin == "") then
		skin = self:GetDefaultCustomGeosets();
	elseif (not skin:match("^%d+#")) then
		skin = CustomCharItems:ItemIdsToSkinString(skin);
	end

	local geosets, textures, attachments =  string.match(skin, "([^@]+)@([^@]+)@?(.*)");
	if (not geosets) then
		geosets = skin;
	end

	local use_hair = false;
	local charater = player:ToCharacter();
	if (geosets) then
		for geoset in string.gfind(geosets, "([^#]+)") do
			local id = tonumber(geoset);
			if (id > 0 and id < 100) then
				use_hair = true;
			end
			charater:SetCharacterSlot(math.floor(id / 100), id % 100);
		end
	end

	if (textures) then
		for id, filename in textures:gmatch("(%d+):([^;]+)") do
			id = tonumber(id)
			player:SetReplaceableTexture(id, ParaAsset.LoadTexture("", filename, 1));
		end
	end

	charater:RemoveAttachment(2, 2);
	charater:RemoveAttachment(11, 11);
	charater:RemoveAttachment(15, 15);
	if (attachments) then
		for id, filename in attachments:gmatch("(%d+):([^;]+)") do
			id = tonumber(id);
			if (use_hair and id == 11) then
				charater:RemoveAttachment(11, 11);
			else
				local meshModel;
				if (string.find(filename, "anim.x")) then
					meshModel = ParaAsset.LoadParaX("", filename);
				else
					meshModel = ParaAsset.LoadStaticMesh("", filename);
				end
				if (meshModel) then
					charater:AddAttachment(meshModel, id, id);
				end
			end
		end
	end
end

function PlayerAssetFile:ShowWingAttachment(player, skin, show)
	local generatorName = WorldCommon.GetWorldTag("world_generator");
	if (generatorName ~= "paraworld") then
		return;
	end

	if (not skin or skin == "") then
		return;
	end

	skin = CustomCharItems:ChangeSkinStringToItems(skin);
	local charater = player:ToCharacter();
	local itemIds = commonlib.split(skin, ";");
	if (itemIds and #itemIds > 0) then
		for i = 1, #itemIds do
			local item = CustomCharItems:GetItemById(itemIds[i]);
			if (item.wing == "true") then
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
							charater:AddAttachment(meshModel, id, id);
						end
					end
				else
					charater:RemoveAttachment(15, 15);
				end

				break;
			end
		end
	end
end