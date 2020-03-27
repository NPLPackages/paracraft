--[[
Title: LocalLoadWorld.html code-behind script
Author(s): LiPeng
Date: 2013/10/19
Desc: Create new world based on predefined template and open existing world. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
LocalLoadWorld.ShowOpenWorldPage()
LocalLoadWorld.ShowCreateWorldPage()

-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");

local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local worlds_template = {
	-- this is pure block world with "flat" generator
	{name = "积木世界", world_path = "worlds/Templates/Empty/flatsandland",icon = "", world_generator = "flat", seed = nil, },
};
-- the current index. 
LocalLoadWorld.SelectedWorldTemplate_Index = 1;

LocalLoadWorld.IsWorldListLoaded = nil;

-- default world folder path
LocalLoadWorld.OpenWorld_Folder = "worlds/DesignHouse";

-- whether to use the new version to open/create world
LocalLoadWorld.IsNewVersion = false;

local page;

function LocalLoadWorld.ShowPage()
	LocalLoadWorld.IsNewVersion = false;
	LocalLoadWorld.ShowPage_imp();
end

-- return a list of additional world directories, where load world is searched.
function LocalLoadWorld.GetAdditionWorldFolders()
	
end

function LocalLoadWorld.ShowPage_imp()
	-- force refreshing world dir
	LocalLoadWorld.IsWorldListLoaded = nil;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Login/LocalLoadWorld.html?folder=worlds/DesignHouse", 
			name = "LocalLoadWorld.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			isTopLevel = true,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		});
end

function LocalLoadWorld.ShowCreateWorldPage()
	LocalLoadWorld.IsNewVersion = true;
	LocalLoadWorld.tab_name = "newWorld";
	LocalLoadWorld.ShowPage_imp();
end

function LocalLoadWorld.ShowOpenWorldPage()
	LocalLoadWorld.IsNewVersion = true;
	LocalLoadWorld.tab_name = "openWorld";
	LocalLoadWorld.ShowPage_imp();
end

-- @Note: please use LocalLoadWorld.GetWorldFolderFullPath instead
-- return world folder such as "[writablepath]/worlds/MyWorlds"
function LocalLoadWorld.GetWorldFolder()
	return LocalLoadWorld.OpenWorld_Folder;
end

function LocalLoadWorld.GetWorldFolderFullPath()
	local myWorldFolder = GameLogic.GetFilters():apply_filters("LocalLoadWorld.GetWorldFolderFullPath", LocalLoadWorld.GetWorldFolder());

	if (LocalLoadWorld.OpenWorldFolderFullPath and LocalLoadWorld.OpenWorldFolderFullPath ~= myWorldFolder) then
		LocalLoadWorld.OpenWorldFolderFullPath = nil
	end

	if (not LocalLoadWorld.OpenWorldFolderFullPath) then
		LocalLoadWorld.OpenWorldFolderFullPath = myWorldFolder;
		
		if (not commonlib.Files.IsAbsolutePath(LocalLoadWorld.OpenWorldFolderFullPath)) then
			if (System.os.GetExternalStoragePath() ~= "") then
				LocalLoadWorld.OpenWorldFolderFullPath = System.os.GetExternalStoragePath() .. "paracraft/" .. myWorldFolder;
			else
				LocalLoadWorld.OpenWorldFolderFullPath = ParaIO.GetWritablePath() .. LocalLoadWorld.OpenWorldFolderFullPath;
			end
		end
	end
	return LocalLoadWorld.OpenWorldFolderFullPath;
end

-- local saveWorldPath;
-- same as LocalLoadWorld.GetWorldFolderFullPath() by default
function LocalLoadWorld.GetDefaultSaveWorldPath()
	local saveWorldPath = LocalLoadWorld.GetWorldFolderFullPath();
	LOG.std(nil, "info", "LocalLoadWorld", "default world path: %s", saveWorldPath);
	return saveWorldPath
end

-- refresh all causing world list to be refreshed. 
-- @param refresh_delay: usually nil or 0
function LocalLoadWorld.RefreshAll(refresh_delay)
	local node = page:GetNode("filepath");
	node.IsWorldListLoaded_ = nil
	page:Refresh(refresh_delay);
end


function LocalLoadWorld.BuildLocalWorldList(bForceRefresh, bSelectFirst)
	-- update the file path
	if(bForceRefresh or not LocalLoadWorld.IsWorldListLoaded) then
		LocalLoadWorld.IsWorldListLoaded = true;
		-- get all contents in folder. 
		-- clear ds
		LocalLoadWorld.dsWorlds = {};
		LocalLoadWorld.SelectedWorld_Index = nil;
		
		local folderPath = LocalLoadWorld.GetDefaultSaveWorldPath();

		-- add folders in myworlds/DesignHouse
		local output = LocalLoadWorld.SearchFiles(nil, folderPath, LocalLoadWorld.MaxItemPerFolder);
		if(output and #output>0) then
			
			local user_nid = tostring(System.User.nid);
			for _, item in ipairs(output) do
				local bLoadedWorld;
				local xmlRoot = ParaXML.LuaXML_ParseFile(folderPath.."/"..item.filename.."/tag.xml");
				if(xmlRoot) then
					for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
						if(node.attr) then
							local display_name = node.attr.name or item.filename;
							local filenameUTF8 = commonlib.Encoding.DefaultToUtf8(item.filename)
							if(filenameUTF8 ~= node.attr.name) then
								-- show dir name if differs from world name
								display_name = format("%s(%s)", node.attr.name or "", filenameUTF8);
							end
							-- only add world with the same nid
							LocalLoadWorld.AddWorldToDS({worldpath = folderPath.."/"..item.filename, 
								foldername = filenameUTF8,
								Title = display_name,
								writedate = item.writedate, filesize=item.filesize,
								nid = node.attr.nid,
								-- world's new property
								author = item.author or "None",
								mode = item.mode or "survival",
								-- the max value of the progress is 1
								progress = item.progress or "0",
								-- the format of costTime:  "day:hour:minute"
								costTime = item.progress or "0:0:0",
								-- maybe grade is "primary" or "middle" or "adventure" or "difficulty" or "ultimate"
								grade = item.grade or "primary",
								ip = item.ip or "127.0.0.1",
								order = item.order,
								IsFolder=true, time_text=item.time_text})	
							bLoadedWorld = true;
							break;	
						end
					end
				end
				if(not bLoadedWorld and ParaIO.DoesFileExist(folderPath.."/"..item.filename.."/worldconfig.txt")) then
					local filenameUTF8 = commonlib.Encoding.DefaultToUtf8(item.filename)
					LOG.std(nil, "info", "LocalWorld", "missing tag.xml in %s", filenameUTF8);
					LocalLoadWorld.AddWorldToDS({worldpath = folderPath.."/"..item.filename, 
							foldername = filenameUTF8,
							Title = filenameUTF8,
							writedate = item.writedate, filesize=item.filesize,
							order = item.order,
							IsFolder=true,})	
					bLoadedWorld = true;
				end	
			end
		end
		
		-- add *.zip world package file 
		local output = LocalLoadWorld.SearchFiles(nil, folderPath, LocalLoadWorld.MaxItemPerFolder, "*.zip");
		if(output and #output>0) then
			local _, item;
			for _, item in ipairs(output) do
				local zip_filename = folderPath.."/"..item.filename;
				local world_name = zip_filename:match("([^/\\]+)%.zip$");
				if(world_name) then
					world_name = commonlib.Encoding.DefaultToUtf8(world_name:gsub("^[%d_]*", ""));
				end
				LocalLoadWorld.AddWorldToDS({worldpath = zip_filename, 
						Title = world_name or "",
						writedate = item.writedate, filesize=item.filesize,
						costTime = item.progress or "0:0:0",
						nid = 0,
						order = item.order,
						IsFolder=false, time_text=item.time_text})	
			end
		end

		table.sort(LocalLoadWorld.dsWorlds, function(a, b)
			return (a.order or 0) > (b.order or 0);
		end)

		-- select the first world if any. 
		if(bSelectFirst and #LocalLoadWorld.dsWorlds > 0) then
			local world = LocalLoadWorld.dsWorlds[1];
			LocalLoadWorld.OnSelectWorld(world,false);
		end
		
		--if(not LocalLoadWorld.OnSelectWorld(1, true)) then
			---- if user has never created any world before we will show the new world tab, otherwise we will show the open world tab. 
			--page:SetNodeValue("OpenCreateWorldTabs", "newWorld");
		--end
	end
	return LocalLoadWorld.dsWorlds;	
end

-- init function. page script fresh is set to false.
function LocalLoadWorld.OnInit()
	-- start timer
	--page = document:GetPageCtrl();
	
	-- update the file path
	LocalLoadWorld.BuildLocalWorldList(false, true);
end

-- template db table
LocalLoadWorld.dsWorlds = {};
-- currently selected world index in above table
LocalLoadWorld.SelectedWorld_Index = nil;
LocalLoadWorld.SelectedWorld = {
	Title = "",
	writedate = "", filesize=0,
	nid = 0,
	-- world's new property
	author = "",
	mode = "survival",
	-- the max value of the progress is 1
	progress = "0",
	-- the format of costTime:  "day:hour:minute"
	costTime = "1:12:12",
	-- maybe grade is "primary" or "middle" or "adventure" or "difficulty" or "ultimate"
	grade = "primary",
	ip = "0.0.0.0",
	IsFolder=true, time_text="",
};


function LocalLoadWorld.DS_Func_Open(index)
	if(index == nil) then
		return #(LocalLoadWorld.dsWorlds);
	else
		return LocalLoadWorld.dsWorlds[index];
	end
end

function LocalLoadWorld.DS_Func_Create(index)
	if(not worlds_template)then return 0 end
	if(index == nil) then
		return #(worlds_template);
	else
		return worlds_template[index];
	end
end

-- user clicks to select a world. 
-- @param index: the world index in LocalLoadWorld.dsWorlds
-- @return true if successfully selected. 
function LocalLoadWorld.OnSelectWorld(world,bRefresh)
	local cur_world = LocalLoadWorld.SelectedWorld;
	if(cur_world) then
		cur_world.selected = nil;
	end
	world.selected = true;
	LocalLoadWorld.SelectedWorld = world;
	
	LocalLoadWorld.PreloadWorldHeaders(world);

	if(bRefresh) then
		LocalLoadWorld.page:Refresh(0.1);
	end
end

-- only return the sub folders of the current folder
-- @param rootfolder: the folder which will be searched.
-- @param nMaxFilesNum: one can limit the total number of files in the search result. Default value is 50. the search will stop at this value even there are more matching files.
-- @param filter: if nil, it defaults to "*."
-- @return a table array containing relative to rootfolder file name.
function LocalLoadWorld.SearchFiles(output, rootfolder,nMaxFilesNum, filter)
	if(rootfolder == nil) then return; end
	if(filter == nil) then filter = "*." end
	
	output = output or {};
	local sInitDir;
	if(commonlib.Files.IsAbsolutePath(rootfolder)) then
		sInitDir = rootfolder.."/";
	else
		sInitDir = ParaIO.GetCurDirectory(0)..rootfolder.."/";
	end

	local search_result = ParaIO.SearchFiles(sInitDir,filter, "", 0, nMaxFilesNum or 5000, 0);
	local nCount = search_result:GetNumOfResult();		
	local nextIndex = #output+1;
	local i;
	for i = 0, nCount-1 do 
		output[nextIndex] = search_result:GetItemData(i, {});
		local date = output[nextIndex].writedate;
		local year, month, day, hour, mins = string.match(date, "(%d+)%D+(%d+)%D+(%d+)%D+(%d+)%D+(%d+)")
		year, month, day,hour, mins = tonumber(year) or 0, tonumber(month) or 0, tonumber(day) or 0, tonumber(hour) or 0, tonumber(mins) or 0
		output[nextIndex].order = (year*380+(month-1)*31+day-1)*1440+(hour-1)*60+mins-1;
		output[nextIndex].time_text = string.format("%d年%d月%d日(%d点%d分)", year, month, day, hour, mins);
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
function LocalLoadWorld.AutoCompleteWorldInfo(worldInfo)
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
		worldInfo.preview = worldInfo.preview or "Texture/Aries/brand/noimageavailable.png";
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
function LocalLoadWorld.AddWorldToDS(worldInfo)
	if(LocalLoadWorld.AutoCompleteWorldInfo(worldInfo)) then
		table.insert(LocalLoadWorld.dsWorlds, worldInfo);
	end
end

-- user selected a world template. 
function LocalLoadWorld.OnSelectWorldTemplate(index)
	local i, world
	for i, world in ipairs(worlds_template)  do
		if(i == index) then
			world.selected = true;
			LocalLoadWorld.SelectedWorldTemplate_Index = index;
		else
			world.selected = nil;
		end
	end
	page:Refresh(0);
end

function LocalLoadWorld.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function LocalLoadWorld.OnClickDeleteWorld()
	local world = LocalLoadWorld.dsWorlds[LocalLoadWorld.SelectedWorld_Index];
	
	if(world) then
		local filepath = world.worldpath;
		if(string.find(filepath, "^worlds/")) then
			local dirPath = string.gsub(filepath, "\\", "/");
			if(dirPath)then
				_guihelper.MessageBox(string.format([[<div style="margin-top:32px">您确定要删除领地: [%s] 吗?</div>]], world.Title or ""), 
					function ()
						local targetDir = "temp/"..dirPath;
						if(ParaIO.CreateDirectory(targetDir) and ParaIO.MoveFile(dirPath, targetDir)) then  
							LocalLoadWorld.RefreshAll(0);
						else
							_guihelper.MessageBox([[<div style="margin-top:32px">无法删除，可能您没有足够的权限.</div>]]); 
						end
					end);
			end
		else
			_guihelper.MessageBox([[<div style="margin-top:32px">您没有权限删除这个世界, 你可以用外部文件浏览器手工删除</div>]]);
		end	
	else
		_guihelper.MessageBox([[<div style="margin-top:32px">请选择一个世界</div>]]);
	end	
end

function LocalLoadWorld.OnClickLoadWorld()
	local world = LocalLoadWorld.SelectedWorld;
	if(world and world.worldpath) then
		local worldpath = world.worldpath:gsub("%.zip$", "");
		if(System.world:DoesWorldExist(worldpath, true)) then
			LocalLoadWorld.page:CloseWindow();
			WorldCommon.OpenWorld(world.worldpath, true)
		else
			_guihelper.MessageBox(L"无效的世界文件");
		end
	end
end

function LocalLoadWorld.OnClickCreateWorld()
    MainLogin:next_step({IsCreateNewWorldRequested = true});
    LocalLoadWorld.page:CloseWindow();
end

-- private: create world according to attributes in values input  
-- @param values: it is a table of {worldname or name, parentworld, creationfolder, inherit_scene, inherit_char, author, level, desc,}
-- @return: return worldpath, message. If not succeeded, worldpath is nil. 
function LocalLoadWorld.CreateWorld(values)
	local worldname = values.worldname or values.name;
	local worldfolder = values.creationfolder or LocalLoadWorld.OpenWorld_Folder
	local parentworld = values.parentworld;
	if(parentworld==nil or parentworld=="") then parentworld=nil end 
	local inherit_scene = values.inherit_scene
	if(inherit_scene == nil) then inherit_scene=true end
	local inherit_char = values.inherit_char
	if(inherit_char == nil) then inherit_char=true end
	
	if(worldname == nil or worldname=="") then
		return nil, "领地名字不能为空"
	elseif(worldname == "_emptyworld") then
		return nil, "您不能使用这个名字, 请换个名字"
	else
		if(not string.match(worldfolder, "/$")) then
			worldfolder = worldfolder.."/"
		end
		local worldpath = (worldfolder..worldname);
		
		-- create a new world
		local res = System.CreateWorld(worldpath, parentworld, inherit_char, inherit_scene, true);
		if(res == true) then
			local file = ParaIO.open(worldpath.."/tag.xml", "w");
			if(file:IsValid()) then
				-- create the tag.xml file under the world root directory. 
				local attr = {};
				attr.name = values.title or worldname;
				attr.nid = System.User.nid or "";
				attr.create_date = ParaGlobal.GetDateFormat("yyyy-M-d");

				if(values.world_generator) then
					attr.world_generator = values.world_generator;
					if(values.seed) then
						attr.seed = values.seed;
					end
				end
				local node = {name="pe:mcml", [1] = {name="pe:world",attr = attr,},}
				NPL.load("(gl)script/ide/LuaXML.lua");
				file:WriteString(commonlib.Lua2XmlString(node, true, true));
				file:close();
				
				-- load success UI
				return worldpath, string.format([[<div style="margin-top:32px">领地[%s]创建成功! 开始你的创造吧</div>]], values.title or worldname);
			else
				_guihelper.MessageBox([[<div style="margin-top:32px">创建tag.xml出错了</div>]])	
			end
			
		elseif(type(res) == "string") then
			return nil, res
		end
	end
	return nil, "未知错误"
end


function LocalLoadWorld.CloseLastArchive()
	if(LocalLoadWorld.LastZipFile) then
		ParaAsset.CloseArchive(LocalLoadWorld.LastZipFile);
		LocalLoadWorld.LastZipFile = nil;
	end
end

function LocalLoadWorld.PreloadWorldHeaders(world)
	if(not world) then 
		return 
	end
	-- needs to get the image preview from world dir or zip and display it as below 
	local filepath = world.worldpath;
	
	local _,_, ext = string.find(filepath, "%.(%w+)$");
	if(ext ~= nil) then
		ext = string.lower(ext);
	end
	
	if(world.IsFolder) then	
		-- user select a folder. 
		local search_result = ParaIO.SearchFiles(filepath.."/","*.jpg", "", 0, 10, 0);
		local nCount = search_result:GetNumOfResult();
		if(nCount>0) then
			previewPath = filepath.."/"..search_result:GetItem(0);
		end
	else
		-- user select a zip file
		-- we will open the zip file to access the file, however shall we close the zip file when it is no longer needed. 
		
		if(LocalLoadWorld.LastZipFile and LocalLoadWorld.LastZipFile ~= filepath and LocalLoadWorld.LastZipFile~=Map3DSystem.World.worldzipfile) then
			LocalLoadWorld.CloseLastArchive();
		end
		LocalLoadWorld.LastZipFile = filepath;
		ParaAsset.OpenArchive(filepath, true);
		
		local search_result = ParaIO.SearchFiles("","*/*.jpg", filepath, 0, 10, 0); -- this version uses wild cards
		--local search_result = ParaIO.SearchFiles("",":.*\\.jpg", filepath, 0, 10, 0); -- this version uses regular expression
		local nCount = search_result:GetNumOfResult();
		if(nCount>0) then
			-- just use the first directory in the world zip file as the world name.
			world.preview = string.gsub(filepath, "([^/\\]+)$", search_result:GetItem(0)); -- get rid of the zip file extension for display 
		end	
	end
	--page:SetValue("WorldImage", world.preview or "");
end
