--[[
Title: code behind page for LoadWorldPage.html
Author(s): LiXizhi
Date: 2008/4/28
Desc: pick an world from disk or download from web and load it. Loading world is usually for offline playing.
autolobby is enabled when user is Map3DSystem.User.IsAuthenticated

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/LoadWorldPage.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/OneTimeAsset.lua");

local LoadWorldPage = {};
commonlib.setfield("Map3DSystem.App.worlds.LoadWorldPage", LoadWorldPage)

---------------------------------
-- page event handlers
---------------------------------

-- first time init page
function LoadWorldPage.OnInit()
	local self = document:GetPageCtrl();

	local worlds = Map3DSystem.App.worlds.app:ReadConfig("RecentlyOpenedWorlds", {})
	local index, value
	for index, value in ipairs(worlds) do
		self:SetNodeValue("filepath", value);
	end
	self:SetNodeValue("filepath", "");
	self:SetNodeValue("WorldImage", "Texture/3DMapSystem/brand/noimageavailable.dds");
end

-- User clicks a file
function LoadWorldPage.OnSelectFile(name, filepath)
	local old_path = commonlib.Encoding.Utf8ToDefault(document:GetPageCtrl():GetUIValue("filepath"));
	if(old_path ~= filepath) then
		document:GetPageCtrl():SetUIValue("filepath", commonlib.Encoding.DefaultToUtf8(filepath));
		LoadWorldPage.OnClickRefreshPreview();
	end	
end

-- user double clicks a file, it will select it and add it to scene. 
function LoadWorldPage.OnDoubleClickFile(name, filepath)
	LoadWorldPage.OnClickLoadWorld();
end

-- user selects a new folder
function LoadWorldPage.OnSelectFolder(name, folderPath)
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
	if(filebrowserCtl and folderPath) then
		filebrowserCtl.rootfolder = folderPath;
		filebrowserCtl:ResetTreeView();
	end
end

-- user selects a new filter
function LoadWorldPage.OnSelectFilter(name, filter)
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
	if(filebrowserCtl and filter) then
		filebrowserCtl.filter = filter;
		filebrowserCtl:ResetTreeView();
	end
end

-- save open world record, so that next time the page is shown, users can open recent world files. 
-- @param worldpath: world path 
function LoadWorldPage.SaveOpenWorldRecord(worldpath)
	-- save to recently opened worlds
	local worlds = Map3DSystem.App.worlds.app:ReadConfig("RecentlyOpenedWorlds", {})
	local bNeedSave;
	-- sort by order
	local index, value, found
	for index, value in ipairs(worlds) do
		if(value == worldpath) then
			if(index>1) then
				commonlib.swapArrayItem(worlds, index, 1)
				bNeedSave = true;
			end	
			found = true;
		end
	end
	if(not found) then
		commonlib.insertArrayItem(worlds, 1, worldpath)
		bNeedSave = true;
	end
	if(bNeedSave) then
		if(#worlds>50) then
			commonlib.resize(worlds, 50)
		end
		Map3DSystem.App.worlds.app:WriteConfig("RecentlyOpenedWorlds", worlds)
		Map3DSystem.App.worlds.app:SaveConfig();
	end
	--commonlib.log(worlds);
end

-- delete the currently selected page. 
function LoadWorldPage.OnClickDeleteWorld()
	local filepath = document:GetPageCtrl():GetUIValue("filepath");
	if(filepath and filepath~="" and ParaIO.DoesFileExist(filepath)) then
		
		if(string.find(filepath, "^worlds/")) then
			local dirPath = string.gsub(filepath, "\\", "/");
			if(dirPath)then
				local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
				_guihelper.MessageBox(string.format("您确定要删除%s么?\n删除后的文件将被移动到%s", commonlib.Encoding.DefaultToUtf8(dirPath), commonlib.Encoding.DefaultToUtf8("temp/"..dirPath)), 
				function ()
					local targetDir = "temp/"..dirPath;
					if(ParaIO.CreateDirectory(targetDir) and ParaIO.MoveFile(dirPath, targetDir)) then  
						filebrowserCtl:ResetTreeView();
					else
						_guihelper.MessageBox("无法删除，可能您没有足够的权限."); 
					end
				end);
			end
		else
			_guihelper.MessageBox("您没有权限删除这个世界, 你可以用外部文件浏览器手工删除");
		end	
	else
		_guihelper.MessageBox("请选择一个世界文件路径");
	end	
end

-- refresh the current page. 
function LoadWorldPage.OnClickRefreshPreview()
	-- TODO: needs to get the image preview from world dir or zip and display it as below 
	local filepath = document:GetPageCtrl():GetUIValue("filepath");
	
	local _,_, ext = string.find(filepath, "%.(%w+)$");
	if(ext ~= nil) then
		ext = string.lower(ext);
	end
	
	local previewPath;
	if(ext == "txt") then
		-- user select a config file. 
		filepath = string.gsub(filepath, "[/\\][^/\\]+$", "")
		local search_result = ParaIO.SearchFiles(filepath.."/","*.jpg", "", 0, 10, 0);
		local nCount = search_result:GetNumOfResult();
		if(nCount>0) then
			previewPath = filepath.."/"..search_result:GetItem(0);
		end
	elseif(ext ~= "zip" and ext ~= "pkg") then	
		-- user select a folder. 
		local search_result = ParaIO.SearchFiles(filepath.."/","*.jpg", "", 0, 10, 0);
		local nCount = search_result:GetNumOfResult();
		if(nCount>0) then
			previewPath = filepath.."/"..search_result:GetItem(0);
		end
	else
		-- user select a zip file
		-- TODO: we will open the zip file to access the file, however shall we close the zip file when it is no longer needed. 
		
		if(LoadWorldPage.LastZipFile and LoadWorldPage.LastZipFile ~= filepath and LoadWorldPage.LastZipFile~=Map3DSystem.World.worldzipfile) then
			ParaAsset.CloseArchive(LoadWorldPage.LastZipFile);
		end
		LoadWorldPage.LastZipFile = filepath;
		ParaAsset.OpenArchive(filepath, true);
		
		local search_result = ParaIO.SearchFiles("","*/*.jpg", filepath, 0, 10, 0); -- this version uses wild cards
		--local search_result = ParaIO.SearchFiles("",":.*\\.jpg", filepath, 0, 10, 0); -- this version uses regular expression
		local nCount = search_result:GetNumOfResult();
		if(nCount>0) then
			-- just use the first directory in the world zip file as the world name.
			previewPath = string.gsub(filepath, "([^/\\]+)%.zip$", search_result:GetItem(0)); -- get rid of the zip file extension for display 
		end	
	end
	
	if(previewPath) then
		CommonCtrl.OneTimeAsset.Unload(document:GetPageCtrl():GetUIValue("WorldImage"))
		document:GetPageCtrl():SetUIValue("WorldImage", previewPath);
	else
		document:GetPageCtrl():SetUIValue("WorldImage", "Texture/3DMapSystem/brand/noimageavailable.dds");
	end	
end


-- Load the world. 
function LoadWorldPage.OnClickLoadWorld()
	local filepath = commonlib.Encoding.Utf8ToDefault(document:GetPageCtrl():GetUIValue("filepath") or "");
	if(filepath == nil or filepath == "") then
		_guihelper.MessageBox("请选择一个世界文件路径");
	elseif(not ParaIO.DoesFileExist(filepath)) then
		_guihelper.MessageBox(string.format("世界 %s 不存在", filepath));
	else
		--
		-- check for world file validity
		--
		-- filepath may be the world folder name or the world config file or a zip file. 
		local _,_, ext = string.find(filepath, "%.(%w+)$");
		if(ext ~= nil) then
			ext = string.lower(ext);
		end
		
		if(ext == "txt") then
			filepath = string.gsub(filepath, "[/\\][^/\\]+$", "")
		elseif(ext ~= "zip" and ext ~= "pkg") then	
			-- user select a folder. 
			local configpath = string.gsub(filepath, "([^/\\]+)$", "%1/%1.worldconfig.txt")
			local configpath1 = filepath.."/worldconfig.txt";

			if(not ParaIO.DoesFileExist(configpath1) and not ParaIO.DoesFileExist(configpath)) then
				_guihelper.MessageBox(string.format("世界 %s 不存在", filepath));
				return
			end
		end
	
		-- load the world here 
		-- disable network, so that it is local.
		LoadWorldPage.SaveOpenWorldRecord(filepath);
		
		-- autolobby is enabled when user is Map3DSystem.User.IsAuthenticated
		Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetLoadWorldCommand(), {worldpath = filepath, autolobby=Map3DSystem.User.IsAuthenticated});
	end
end
