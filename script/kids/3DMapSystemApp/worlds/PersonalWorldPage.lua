--[[
Title: code behind page for PersonalWorldPage.html
Author(s): LiXizhi
Date: 2008/8/14
Desc: pick an world from disk or download from web and load it. Loading world is usually for offline playing.
autolobby is enabled when user is Map3DSystem.User.IsAuthenticated

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/PersonalWorldPage.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/OneTimeAsset.lua");

local PersonalWorldPage = {};
commonlib.setfield("Map3DSystem.App.worlds.PersonalWorldPage", PersonalWorldPage)

---------------------------------
-- page event handlers
---------------------------------
-- singleton page object
local page;
PersonalWorldPage.MaxItemPerFolder = 100;

-- template db table
PersonalWorldPage.dsWorlds = {};

-- datasource function for pe:gridview
function PersonalWorldPage.DS_Func(index)
	if(index == nil) then
		return #(PersonalWorldPage.dsWorlds);
	else
		return PersonalWorldPage.dsWorlds[index];
	end
end

-- only return the sub folders of the current folder
-- @param rootfolder: the folder which will be searched.
-- @param nMaxFilesNum: one can limit the total number of files in the search result. Default value is 50. the search will stop at this value even there are more matching files.
-- @param filter: if nil, it defaults to "*."
-- @return a table array containing relative to rootfolder file name.
function PersonalWorldPage.SearchFiles(output, rootfolder,nMaxFilesNum, filter)
	if(rootfolder == nil) then return; end
	if(filter == nil) then filter = "*." end
	
	output = output or {};
	local sInitDir = ParaIO.GetCurDirectory(0)..rootfolder.."/";
	local search_result = ParaIO.SearchFiles(sInitDir,filter, "", 0, nMaxFilesNum or 50, 0);
	local nCount = search_result:GetNumOfResult();		
	local nextIndex = #output+1;
	local i;
	for i = 0, nCount-1 do 
		output[nextIndex] = search_result:GetItemData(i, {});
		local date = output[nextIndex].writedate;
		local year, month, day = string.match(date, "(%d+)%D+(%d+)%D+(%d+)")
		year, month, day = tonumber(year) or 0, tonumber(month) or 0, tonumber(day) or 0
		output[nextIndex].order = year*365+month*31+day
		nextIndex = nextIndex + 1;
	end
	-- sort output by file.writedate
	table.sort(output, function(a, b)
		return (a.order > b.order )
	end)
	search_result:Release();
	return output;	
end

-- auto complete world info from just the input. 
-- @param worldInfo: {worldpath = "", Title="", preview="", icon="", IsFolder=false, writedate, }, where only worldpath is mendatory
function PersonalWorldPage.AutoCompleteWorldInfo(worldInfo)
	if(not worldInfo.worldpath) then
		return 
	end
	
	if(not worldInfo.Title) then
		worldInfo.Title = string.match(worldInfo.worldpath, "[^/\\]+$") or worldInfo.worldpath
		worldInfo.Title = string.gsub(worldInfo.Title, "%.%w+$", "") or worldInfo.worldpath
		-- needs encoding convert
		worldInfo.Title = commonlib.Encoding.DefaultToUtf8(worldInfo.Title)
	end
	if(not worldInfo.preview) then
		if(worldInfo.IsFolder) then
			if(ParaIO.DoesFileExist(worldInfo.worldpath.."/preview.jpg")) then
				worldInfo.preview = worldInfo.worldpath.."/preview.jpg"
			end
		end
		worldInfo.preview = worldInfo.preview or "Texture/3DMapSystem/brand/noimageavailable.dds";
	end
	if(not worldInfo.icon) then
		if(worldInfo.IsFolder) then
			worldInfo.icon = "Texture/3DMapSystem/common/page_world.png"
		else
			worldInfo.icon = "Texture/3DMapSystem/common/page_white_zip.png"
		end
	end
	return worldInfo;
end
-- add a given world to datasource
function PersonalWorldPage.AddWorldToDS(worldInfo)
	if(PersonalWorldPage.AutoCompleteWorldInfo(worldInfo)) then
		table.insert(PersonalWorldPage.dsWorlds, worldInfo);
	end
end

-- first time init page
function PersonalWorldPage.OnInit()
	local node;
	page = document:GetPageCtrl();

	-- update the file path
	node = page:GetNode("filepath");
	if(not node.IsWorldListLoaded_) then
		node.IsWorldListLoaded_ = true;
		
		local worlds = Map3DSystem.App.worlds.app:ReadConfig("RecentlyOpenedWorlds", {})
		local index, value
		for index, value in ipairs(worlds) do
			page:SetNodeValue("filepath", commonlib.Encoding.DefaultToUtf8(value) );
		end
		page:SetNodeValue("filepath", "");
		page:SetNodeValue("WorldImage", "Texture/3DMapSystem/brand/noimageavailable.dds");
	end	
		
	-- load data source with local data. 
	node = page:GetNode("CurFolder");
	local curFolder = page:GetNodeValue("CurFolder");
	if(curFolder ~= node.lastFolder_) then
		node.lastFolder_ = curFolder;
		
		-- get all contents in folder. 
		
		-- clear ds
		PersonalWorldPage.dsWorlds = {};
		
		-- add folders
		local folderPath = curFolder;
		
		local output = PersonalWorldPage.SearchFiles(nil, folderPath, PersonalWorldPage.MaxItemPerFolder);
		if(output and #output>0) then
			local _, item;
			for _, item in ipairs(output) do
				PersonalWorldPage.AddWorldToDS({worldpath = folderPath.."/"..item.filename, 
					writedate = item.writedate, filesize=item.filesize,
					IsFolder=true})
			end
		end
		
		-- add files
		PersonalWorldPage.filter = "*.zip;*.pkg;";
		if(PersonalWorldPage.filter~=nil and PersonalWorldPage.filter~="")then
			-- add files, but exclude folders. 
			local filter;
			local output = {};
			for filter in string.gfind(PersonalWorldPage.filter, "([^%s;]+)") do
				PersonalWorldPage.SearchFiles(output, folderPath,PersonalWorldPage.MaxItemPerFolder, filter);
			end
			if(#output>0) then
				local _, item;
				for _, item in ipairs(output) do
					if(string.find(item.filename,"%.")) then
						-- we will skip folders since they are already added.
						PersonalWorldPage.AddWorldToDS({worldpath = folderPath.."/"..item.filename, 
							writedate = item.writedate, filesize=item.filesize})
					end	
				end
			end
		end
	end
end

-- User selects a use world from the file name list. 
function PersonalWorldPage.OnSelectWorldPath(name, filepath)
	PersonalWorldPage.OnSelectWorld_imp(commonlib.Encoding.Utf8ToDefault(filepath));
end

-- User clicks a file
function PersonalWorldPage.OnSelectWorld(filepath, lastUpdateTime)
	local old_path = commonlib.Encoding.Utf8ToDefault(page:GetUIValue("filepath"));
	if(old_path ~= filepath) then
		PersonalWorldPage.OnSelectWorld_imp(filepath, lastUpdateTime)
	end	
end

function PersonalWorldPage.OnSelectWorld_imp(filepath, lastUpdateTime)
	local worldInfo = PersonalWorldPage.AutoCompleteWorldInfo({worldpath = filepath, writedate = lastUpdateTime})
	if(worldInfo) then
		page:SetUIValue("filepath", commonlib.Encoding.DefaultToUtf8(worldInfo.worldpath));
		page:SetUIValue("updatetime", worldInfo.writedate or "");
		page:SetUIValue("worldname", worldInfo.Title or "");
		PersonalWorldPage.OnClickRefreshPreview();
	end	
end

-- user selects a new folder
function PersonalWorldPage.OnSelectFolder(name, folderPath)
	page:SetNodeValue("CurFolder", folderPath);
	page:CallMethod("gvwWorlds", "Reset") 
	page:CallMethod("gvwWorlds2", "Reset") 
	page:Refresh(0);
end

-- user clicks to toggle the display of preview images. 
function PersonalWorldPage.OnCheckShowPreview(checked)
	page:SetNodeValue("ShowPreviewImage", checked);
	page:CallMethod("gvwWorlds", "Reset") 
	page:CallMethod("gvwWorlds2", "Reset") 
	page:Refresh(0);
end

-- save open world record, so that next time the page is shown, users can open recent world files. 
-- @param worldpath: world path 
function PersonalWorldPage.SaveOpenWorldRecord(worldpath)
	-- save to recently opened worlds
	local worlds = Map3DSystem.App.worlds.app:ReadConfig("RecentlyOpenedWorlds", {})
	local bNeedSave;
	-- sort by order
	local index, value, found
	for index, value in ipairs(worlds) do
		if(value == worldpath) then
			if(index>1) then
				commonlib.moveArrayItem(worlds, index, 1)
				bNeedSave = true;
			end	
			found = true;
			break;
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
function PersonalWorldPage.OnClickDeleteWorld()
	local filepath = page:GetUIValue("filepath");
	if(filepath and filepath~="" and ParaIO.DoesFileExist(filepath)) then
		
		if(string.find(filepath, "^worlds/")) then
			local dirPath = string.gsub(filepath, "\\", "/");
			if(dirPath)then
				local filebrowserCtl = page:FindControl("FileBrowser");
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
function PersonalWorldPage.OnClickRefreshPreview()
	-- TODO: needs to get the image preview from world dir or zip and display it as below 
	local filepath = page:GetUIValue("filepath");
	
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
		
		if(PersonalWorldPage.LastZipFile and PersonalWorldPage.LastZipFile ~= filepath and PersonalWorldPage.LastZipFile~=Map3DSystem.World.worldzipfile) then
			ParaAsset.CloseArchive(PersonalWorldPage.LastZipFile);
		end
		PersonalWorldPage.LastZipFile = filepath;
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
		CommonCtrl.OneTimeAsset.Unload(page:GetUIValue("WorldImage"))
		page:SetUIValue("WorldImage", previewPath);
	else
		page:SetUIValue("WorldImage", "Texture/3DMapSystem/brand/noimageavailable.dds");
	end	
end


-- Load the world. 
function PersonalWorldPage.OnClickLoadWorld()
	local filepath = commonlib.Encoding.Utf8ToDefault(page:GetUIValue("filepath") or "");
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
		PersonalWorldPage.SaveOpenWorldRecord(filepath);
		
		-- autolobby is enabled when user is Map3DSystem.User.IsAuthenticated
		Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetLoadWorldCommand(), {worldpath = filepath, autolobby=Map3DSystem.User.IsAuthenticated});
	end
end
