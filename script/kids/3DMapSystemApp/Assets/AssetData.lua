--[[
Title: asset definition for asset, folder, package
Author(s): LiXizhi
Date: 2008/1/31
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetData.lua");
-- only included in asset manager
-------------------------------------------------------
]]

-- common control library
NPL.load("(gl)script/ide/common_control.lua");
---- requires its Map3DSystem.UI.Creation.GetObjParamsFromAsset
--NPL.load("(gl)script/kids/3DMapSystemUI/InGame/Creation.lua");

-- requires its Map3DSystem.UI.Creator.GetObjParamsFromAsset
NPL.load("(gl)script/kids/3DMapSystemUI/Creator/Main.lua");

Map3DSystem.App.Assets.AssetStatus = {
	-- only a local copy of the asset
	Local = nil,
	-- a remote reference of the asset. The asset is not found in local disk
	Remote = 1,
	-- local and remote copy are identical
	Sync = 2,
	-- there is a difference between local copy and remote copy. Either overwrite from remote or update to remote. 
	Diff = 3,
};

-- a mapping from predefined category prefix to category text. 
Map3DSystem.App.Assets.CategoryMap = {
	["Creations.BCS.doors"] = "创建.建筑部件.门",
	["Creations.NormalModels.trees"] = "创建.模型.树",
	-- TODO: add more here: this should be the same as in the main bar
}

--------------------------------------
-- an asset template
--------------------------------------
Map3DSystem.App.Assets.asset = {
	-- model or texture relative-to-root file path, this is the only required field. 
	filename = nil, 
	-- text to be displayed. if nil, default to ParaIO.GetFileName(filename)
	text = nil, 
	-- default to "<filepath>.png", if filepath is not an image file.
	icon = nil,
	Price = nil,
	Reserved1 = nil,
	Reserved2 = nil,
	Reserved3 = nil,
	Reserved4 = nil,
};

-- create a new asset. the asset's filename must not be nil. 
function Map3DSystem.App.Assets.asset:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o	
end

function Map3DSystem.App.Assets.asset:getIcon()
	return self.icon or (self.filename..".png")
end

function Map3DSystem.App.Assets.asset:getText()
	return self.text or ParaIO.GetFileName(self.filename)
end

-- convert this asset to the item format. item format is the internal format used by the Creator integration point. 
function Map3DSystem.App.Assets.asset:ToItem()	
	return {
	  ["Price"] = self.price,
	  ["IconAssetName"] = self:getText(),
	  ["ModelFilePath"] = self.filename,
	  ["IconFilePath"] = self:getIcon(),
	  ["Reserved1"] = self.Reserved1,
	  ["Reserved2"] = self.Reserved2,
	  ["Reserved3"] = self.Reserved3,
	  ["Reserved4"] = self.Reserved4,
	  ["Reserved5"] = self.Reserved5,
	}
end

-- it will return the objParams if it is a model or character asset, otherwise it will return nil. 
function Map3DSystem.App.Assets.asset:getModelParams()	
	local ext = string.lower(ParaIO.GetFileExtension(self.filename));
	if(ext == "x" or ext == "xml") then
		local category;
		if(Map3DSystem.App.Assets.AssetManager and Map3DSystem.App.Assets.AssetManager.CurPak) then
			category = Map3DSystem.App.Assets.AssetManager.CurPak.Category; 
		end
		if(category~=nil) then
			category = string.gsub(category, ".*%.([^%.]*)$", "%1");
		end
		local obj_params = Map3DSystem.UI.Creator.GetObjParamsFromAsset(category, self:ToItem());
		return obj_params;
	end
end

-- it will return the image file name if it is a texture asset, otherwise it will return nil. 
function Map3DSystem.App.Assets.asset:getImageFile()	
	local ext = string.lower(ParaIO.GetFileExtension(self.filename));
	if(ext == "dds" or ext == "jpg" or ext == "png" or ext == "swf" or ext == "flv" or ext == "avi") then
		return self.filename;
	end
end

--------------------------------------
-- a folder template
--------------------------------------
Map3DSystem.App.Assets.folder = {
	-- working directory of the folder. this is the only required field. it should ends with /
	filename = nil, 
	-- a string or an array of strings. each one is a file extension. 
	fileExt = {"*.x", "*.xml", "*.png", "*.jpg",},
};

-- create a new asset. the asset's filename must not be nil. 
function Map3DSystem.App.Assets.folder:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end
--------------------------------------
-- a package temple: contains a collection of assets and a collection of folders
--------------------------------------
Map3DSystem.App.Assets.Package = {
	-- Package GUID string. if this is nil, the item is never uploaded before. 
	id = nil,
	-- type of Map3DSystem.App.Assets.AssetStatus 
	AssetStatus = nil, 
	-- user who owns it. if nil, it means the current user. 
	userid = nil,
	-- creation category string.(always betweens with "creator") The string should match the command name prefix when added to mainbar:creation, such as "creator.Normal Model.NM_trees". 
	-- It usually contains two levels, and items in the package are in the third level. please see Map3DSystem.App.Assets.CategoryMap for predefined categories. 
	-- If either the first or second category level is not defined, it will be created in the mainbar, using the default icon. 
	Category = nil, 
	-- the level 1 UI text to display if it is not already defined in the mainbar. 
	Level1Text = nil,
	-- the level 2 UI text to display if it is not already defined in the mainbar. 
	text = "未命名",
	-- The icon path to display if it is
	icon = nil,
	-- tooltip to display.
	tooltip = nil,
	
	-- whether to display the package inside the mainbar. 
	bDisplayInMainBar = nil,
	-- if nil, it means free. 
	priceE = nil,
	priceP = nil,

	-- array of assets. The order in this array depends the show sequence. Each asset is a table of 
	-- type of Map3DSystem.App.Assets.asset
	assets = {},
	
	--folders are only used for synchronization and editing purposes. It maps a sub group of asset files to a working directory on the user's local disk. 
	-- type of Map3DSystem.App.Assets.folder 
	folders = {},
};

-- create a new Package
function Map3DSystem.App.Assets.Package:new(o)
	o = o or {}   -- create object if user does not provide one
	o.assets = o.assets or {};
	o.folders = o.folders or {};
	
	setmetatable(o, self)
	self.__index = self
	return o	
end

-- clear all objects
function Map3DSystem.App.Assets.Package:ClearAll()
	self.assets = {};
end

-- add a new asset to the asset list. if the asset.filename already exist, it will update the existing one. 
-- return the asset and its index in the package
function Map3DSystem.App.Assets.Package:AddAsset(asset)
	local i, v;
	for i,v in ipairs(self.assets) do
		if(v.filename == asset.filename) then
			commonlib.partialcopy(v, asset);
			return v, i;
		end
	end
	-- insert to back
	commonlib.insertArrayItem(self.assets, nil, asset);
	return asset, table.getn(self.assets);
end

-- remove an asset from the package by a given asset filename 
function Map3DSystem.App.Assets.Package:RemoveAsset(filename)
	local i, v;
	for i,v in ipairs(self.assets) do
		if(v.filename == filename) then
			commonlib.removeArrayItem(self.assets, i);
			return;
		end
	end
end

-- get an asset from the package by a given asset filename 
-- return the asset and its index in the package. return nil,nil if not found. 
function Map3DSystem.App.Assets.Package:GetAsset(filename)
	local i, v;
	for i,v in ipairs(self.assets) do
		if(v.filename == filename) then
			return v,i;
		end
	end
end

-- add a new folder to the folder list. if the folder.filename already exist, it will update the existing one. 
-- return the folder and its index in the package
function Map3DSystem.App.Assets.Package:AddFolder(folder)
	local i, v;
	for i,v in ipairs(self.folders) do
		if(v.filename == folder.filename) then
			commonlib.partialcopy(v, folder);
			return v, i;
		end
	end
	-- insert to back
	commonlib.insertArrayItem(self.folders, nil, folder);
	return folder, table.getn(self.folders);
end

-- remove an folder from the package by a given folder filename 
function Map3DSystem.App.Assets.Package:RemoveFolder(filename)
	local i, v;
	for i,v in ipairs(self.folders) do
		if(v.filename == filename) then
			commonlib.removeArrayItem(self.folders, i);
			return;
		end
	end
end

-- get an folder from the package by a given folder filename 
-- return the folder and its index in the package. return nil,nil if not found. 
function Map3DSystem.App.Assets.Package:GetFolder(filename)
	local i, v;
	for i,v in ipairs(self.folders) do
		if(v.filename == filename) then
			return i,v;
		end
	end
end
