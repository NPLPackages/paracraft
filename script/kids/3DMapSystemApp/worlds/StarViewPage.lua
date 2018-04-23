--[[
Title: code behind page for StarViewPage.html
Author(s): LiXizhi
Date: 2008/8/14
Desc: pick an world from disk or download from web and load it. Loading world is usually for offline playing.
autolobby is enabled when user is Map3DSystem.User.IsAuthenticated

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/StarViewPage.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/OneTimeAsset.lua");

local StarViewPage = {};
commonlib.setfield("Map3DSystem.App.worlds.StarViewPage", StarViewPage)

---------------------------------
-- page event handlers
---------------------------------

-- template db table
StarViewPage.dsOnlineTutorials = {
	{Title="新手村", SubTitle="教你基本人物操作, 使用工具, 创造3D家园, 探索3D社交网络", worldpath="worlds/Official/新手之路", preview="worlds/Official/新手之路/preview.jpg", },
	{Title="儿童村", SubTitle="如果你有7-12岁的孩子, 可以陪他们一起创作, 全面提高儿童的想像力, 创造力, 领导力(建设中...)", worldpath="worlds/Official/DisneyLand", preview="worlds/Official/DisneyLand/preview.jpg", },
	{Title="开发者村", SubTitle="介绍PEDN开发网, 应用程序架构, 创建属于你的3D互联网产业(建设中...)", worldpath="worlds/Official/NewUserVillage3", preview="worlds/Official/NewUserVillage3/preview.jpg", },
	
	{Title="新手镇", SubTitle="教你制作智能人物, 拍摄电影, 以及部分社交平台功能(建设中...)", worldpath="worlds/MyWorlds/新手镇", preview="worlds/MyWorlds/新手镇/preview.jpg", },
	{Title="PE颁奖岛", SubTitle="各种评选活动的颁奖地点(建设中...)", worldpath="worlds/MyWorlds/PE颁奖岛", preview="worlds/MyWorlds/PE颁奖岛/preview.jpg", },
	{Title="极地狂奔", SubTitle="滑雪游戏(建设中...)", worldpath="worlds/MyWorlds/极地狂奔", preview="worlds/MyWorlds/极地狂奔/preview.jpg", },
	
	{Title="群岛", SubTitle="许多岛屿, 约会的好去处(建设中...)", worldpath="worlds/MyWorlds/群岛", preview="worlds/MyWorlds/群岛/preview.jpg", },
	{Title="野人部落", SubTitle="野人部落(建设中...)", worldpath="worlds/MyWorlds/野人部落", preview="worlds/MyWorlds/野人部落/preview.jpg", },
	{Title="赛车场", SubTitle="赛车游戏(建设中...)", worldpath="worlds/MyWorlds/赛车场1", preview="worlds/MyWorlds/赛车场1/preview.jpg", },
	
	{Title="社区界面", SubTitle="社区登录界面(建设中...)", worldpath="worlds/MyWorlds/LoginWorld", preview="worlds/MyWorlds/LoginWorld/preview.jpg", },
	{Title="登录界面", SubTitle="一个简单的游戏登录界面(建设中...)", worldpath="worlds/MyWorlds/LoginWorld2", preview="worlds/MyWorlds/LoginWorld2/preview.jpg", },
	{Title="开发者村2", SubTitle="创建属于你的3D互联网产业(建设中...)", worldpath="worlds/Official/NewUserVillage2", preview="worlds/Official/NewUserVillage2/preview.jpg", },
};

local function DoEncoding()
	local _, t;
	for _,t in ipairs(StarViewPage.dsOnlineTutorials) do
		t.worldpath = commonlib.Encoding.Utf8ToDefault(t.worldpath)
		t.preview = commonlib.Encoding.Utf8ToDefault(t.preview)
	end
end
DoEncoding();

-- datasource function for pe:gridview
function StarViewPage.DS_OnlineTutorial_Func(index)
	if(index == nil) then
		return #(StarViewPage.dsOnlineTutorials);
	else
		return StarViewPage.dsOnlineTutorials[index];
	end
end

-- first time init page
function StarViewPage.OnInit()
	local self = document:GetPageCtrl();

	local worlds = Map3DSystem.App.worlds.app:ReadConfig("RecentlyOpenedWorlds", {})
	local index, value
	for index, value in ipairs(worlds) do
		self:SetNodeValue("filepath", commonlib.Encoding.DefaultToUtf8(value));
	end
	self:SetNodeValue("filepath", "");
	self:SetNodeValue("WorldImage", "Texture/3DMapSystem/brand/noimageavailable.dds");
end

-- User clicks to search a world by text
function StarViewPage.OnSearch(name, values)
	local searchText = values[SearchText];
	-- TODO: 
end

-- User clicks a file
function StarViewPage.OnSelectFile(name, filepath)
	local old_path = commonlib.Encoding.Utf8ToDefault(document:GetPageCtrl():GetUIValue("filepath"));
	if(old_path ~= filepath) then
		document:GetPageCtrl():SetUIValue("filepath", commonlib.Encoding.DefaultToUtf8(filepath));
		StarViewPage.OnClickRefreshPreview();
	end	
end

-- user double clicks a file, it will select it and add it to scene. 
function StarViewPage.OnDoubleClickFile(name, filepath)
	StarViewPage.OnClickLoadWorld();
end

-- user selects a new folder
function StarViewPage.OnSelectFolder(name, folderPath)
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
	if(filebrowserCtl and folderPath) then
		filebrowserCtl.rootfolder = folderPath;
		filebrowserCtl:ResetTreeView();
	end
end

-- user selects a new filter
function StarViewPage.OnSelectFilter(name, filter)
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
	if(filebrowserCtl and filter) then
		filebrowserCtl.filter = filter;
		filebrowserCtl:ResetTreeView();
	end
end

-- save open world record, so that next time the page is shown, users can open recent world files. 
-- @param worldpath: world path 
function StarViewPage.SaveOpenWorldRecord(worldpath)
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
function StarViewPage.OnClickDeleteWorld()
	local filepath = commonlib.Encoding.Utf8ToDefault(document:GetPageCtrl():GetUIValue("filepath"));
	if(filepath and filepath~="" and ParaIO.DoesFileExist(filepath)) then
		
		if(string.find(filepath, "^worlds/")) then
			local dirPath = string.gsub(filepath, "\\", "/");
			if(dirPath)then
				local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
				_guihelper.MessageBox(string.format("您确定要删除%s么?\n删除后的文件将被移动到%s", dirPath, "temp/"..dirPath), 
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
function StarViewPage.OnClickRefreshPreview()
	-- TODO: needs to get the image preview from world dir or zip and display it as below 
	local filepath = commonlib.Encoding.Utf8ToDefault(document:GetPageCtrl():GetUIValue("filepath"));
	
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
		
		if(StarViewPage.LastZipFile and StarViewPage.LastZipFile ~= filepath and StarViewPage.LastZipFile~=Map3DSystem.World.worldzipfile) then
			ParaAsset.CloseArchive(StarViewPage.LastZipFile);
		end
		StarViewPage.LastZipFile = filepath;
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
function StarViewPage.OnClickLoadWorld()
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
			if(not ParaIO.DoesFileExist(configpath)) then
				_guihelper.MessageBox(string.format("世界 %s 不存在", filepath));
				return
			end
		end
	
		-- load the world here 
		-- disable network, so that it is local.
		StarViewPage.SaveOpenWorldRecord(filepath);
		
		-- autolobby is enabled when user is Map3DSystem.User.IsAuthenticated
		Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetLoadWorldCommand(), {worldpath = filepath, autolobby=Map3DSystem.User.IsAuthenticated});
	end
end
