--[[
Title: Player AssetFukes
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
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")

local last_index = 1;

-- all registered asset files: this will be loaded xml file, following is example format. 
local assetfiles = {
	-- {filename="character/CC/01char/char_male.x", name="default", displayname="通用人物"},
}

local filename_to_name_map = {}
local name_to_filename_map = {}

function PlayerAssetFile:Init()
	if(self.isInited) then
		return 
	end
	self.isInited = true;
	self:LoadFromXMLFile();
	for _, asset in ipairs(assetfiles) do
		filename_to_name_map[asset.filename] = asset.name;
		name_to_filename_map[asset.name] = asset.filename;
	end
end

function PlayerAssetFile:LoadFromXMLFile()
	local filename = "config/Aries/creator/PlayerAssetFile.xml";
	local root = ParaXML.LuaXML_ParseFile(filename);
	if(root) then
		-- clear asset files: 
		assetfiles = {};
		for node in commonlib.XPath.eachNode(root, "/PlayerAssets/asset") do
			local attr = node.attr;
			if(attr and attr.filename) then
				attr.displayname = L(attr.displayname);
				assetfiles[#assetfiles+1] = attr;
			end
		end
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