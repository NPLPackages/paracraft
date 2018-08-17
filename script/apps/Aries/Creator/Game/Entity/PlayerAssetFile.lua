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
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")

local last_index = 1;

-- all registered asset files: this will be loaded xml file, following is example format. 
local assetfiles = {
	-- {filename="character/CC/01char/char_male.x", name="default", displayname="通用人物"},
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