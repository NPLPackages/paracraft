--[[
Title: Providing asset data from file or remote server
Author(s): LiXizhi
Date: 2008/1/31
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetProvider.lua");
-- only included in asset manager
-------------------------------------------------------
]]

-- common control library
NPL.load("(gl)script/ide/common_control.lua");

-- create a new package. One can later call SelectPackage to select it by UI. 
-- @param package: partial class of Map3DSystem.App.Assets.Package. if package is nil, a default one at the current player position will be created. 
--  otherwise, the caller can specify where to create the package and how big is the construction site. 
-- @return return the package object created.
function Map3DSystem.App.Assets.CreatePackage(package)
	package = Map3DSystem.App.Assets.Package:new(package);
	return package;
end

-- load package from file. it returned the package object. it may return nil if failed. 
function Map3DSystem.App.Assets.LoadPackageFromFile(filename)
	local package = commonlib.LoadTableFromFile(filename)
	if(package~=nil) then
		package = Map3DSystem.App.Assets.Package:new(package);
	end
	return package;
end

-- local all local packages in the asset application directory to Map3DSystem.App.Assets.Packages array
function Map3DSystem.App.Assets.LoadAllLocalPackages()
	local files = {};
	local parentDir = Map3DSystem.App.Assets.app:GetAppDirectory();
	commonlib.SearchFiles(files, parentDir, "*.asset", 0, 50, true)
	local i, file
	for i, file in ipairs(files) do
		local package = Map3DSystem.App.Assets.LoadPackageFromFile(parentDir..file)
		if(package~=nil) then
			-- refill meta tables. 
			Map3DSystem.App.Assets.Package:new(package)
			local i,v;
			for i,v in ipairs(package.assets) do
				 Map3DSystem.App.Assets.asset:new(v)
			end
			for i,v in ipairs(package.folders) do
				 Map3DSystem.App.Assets.folder:new(v)
			end
			
			-- add to package
			Map3DSystem.App.Assets.AddPackage(package);
		end	
	end
end

-- save a local package in the asset application directory
-- @param filename: if nil, the package.Category + ".asset" is used as the file name
-- @return return the filename if succeed, otherwise return nil.
function Map3DSystem.App.Assets.SaveAsLocalPackage(package, filename)
	filename = filename or (tostring(package.Category)..".asset")
	log("Saving asset file: "..filename.."\n")
	local fileObj = Map3DSystem.App.Assets.app:openfile(filename, "w");
	if(fileObj:IsValid()) then
		fileObj:WriteString(commonlib.serialize(package));
		fileObj:close();
		log("package is successfully save to "..filename.."\n")
		return filename;
	end	
end
