--[[
Title: CreateOpenWorld.html code-behind script
Author(s): LiXizhi
Date: 2010/1/22
Desc: Create new world based on predefined template and open existing world. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/CreateOpenWorld.lua");
local CreateOpenWorld = commonlib.gettable("MyCompany.Aries.Creator.CreateOpenWorld")
CreateOpenWorld.ShowPage();
CreateOpenWorld.ShowCreateWorldPage();
CreateOpenWorld.ShowOpenWorldPage();

script/apps/Aries/Creator/CreateOpenWorld.html
-- to new/open worlds in a given folder, use following request params. 
script/apps/Aries/Creator/CreateOpenWorld.html?folder=worlds/DesignHouse
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");

local CreateOpenWorld = commonlib.gettable("MyCompany.Aries.Creator.CreateOpenWorld")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local worlds_template = {
	-- this is pure block world with "flat" generator
	{name = "积木世界", selected=true, world_path = "worlds/Templates/Empty/flatsandland",icon = "", world_generator = "flat64", seed = nil, },
	{name = "青青草原", world_path = "worlds/Templates/Empty/flatgrassland",icon = "", },
	{name = "冰雪世界", world_path = "worlds/Templates/Empty/flatsnowland",icon = "",},
	{name = "沙漠世界", world_path = "worlds/Templates/Empty/flatsandland",icon = "",},
	{name = "月夜星空", world_path = "worlds/Templates/Empty/neverland",icon = "", },
};
-- the current index. 
CreateOpenWorld.SelectedWorldTemplate_Index = 1;

-- default world folder path
CreateOpenWorld.OpenWorld_Folder = "worlds/MyWorlds";

-- whether to use the new version to open/create world
-- old version is completed deprecated. 
CreateOpenWorld.IsNewVersion = true;

local page;

function CreateOpenWorld.ShowPage()
	-- CreateOpenWorld.IsNewVersion = false;
	CreateOpenWorld.ShowPage_imp();
end

function CreateOpenWorld.ShowPage_imp()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/CreateOpenWorld.html?folder=worlds/DesignHouse", 
			name = "CreateOpenWorld.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -310,
				y = -245,
				width = 620,
				height = 490,
		});
end

function CreateOpenWorld.ShowCreateWorldPage()
	CreateOpenWorld.IsNewVersion = true;
	CreateOpenWorld.tab_name = "newWorld";
	CreateOpenWorld.ShowPage_imp();
end

function CreateOpenWorld.ShowOpenWorldPage()
	CreateOpenWorld.IsNewVersion = true;
	CreateOpenWorld.tab_name = "openWorld";
	CreateOpenWorld.ShowPage_imp();
end

-- return world folder such as "worlds/MyWorlds"
function CreateOpenWorld.GetWorldFolder()
	return page:GetRequestParam("folder") or CreateOpenWorld.OpenWorld_Folder;
end

-- refresh all causing world list to be refreshed. 
-- @param refresh_delay: usually nil or 0
function CreateOpenWorld.RefreshAll(refresh_delay)
	local node = page:GetNode("filepath");
	node.IsWorldListLoaded_ = nil
	page:Refresh(refresh_delay);
end

-- init function. page script fresh is set to false.
function CreateOpenWorld.OnInit()
	-- start timer
	page = document:GetPageCtrl();
	
	-- update the file path
	local node = page:GetNode("filepath");
	if(not node.IsWorldListLoaded_) then
		node.IsWorldListLoaded_ = true;
		-- get all contents in folder. 
		-- clear ds
		CreateOpenWorld.dsWorlds = {};
		CreateOpenWorld.SelectedWorld_Index = nil;
		
		-- add folders in myworlds/DesignHouse
		local folderPath = CreateOpenWorld.GetWorldFolder();
		
		local output = CreateOpenWorld.SearchFiles(nil, folderPath, CreateOpenWorld.MaxItemPerFolder);
		if(output and #output>0) then
			local user_nid = tostring(System.User.nid);
			local _, item;
			for _, item in ipairs(output) do
				local xmlRoot = ParaXML.LuaXML_ParseFile(folderPath.."/"..item.filename.."/tag.xml");
				if(xmlRoot) then
					local node;
					for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
						if(node.attr) then
							-- only add world with the same nid
							--if(node.attr.nid == user_nid) then
								CreateOpenWorld.AddWorldToDS({worldpath = folderPath.."/"..item.filename, 
									Title = node.attr.name,
									writedate = item.writedate, filesize=item.filesize,
									nid = node.attr.nid,
									IsFolder=true, time_text=item.time_text})	
								break;	
							--end	
						end
					end
				end	
			end
		end
		
		-- add *.zip world package file 
		local output = CreateOpenWorld.SearchFiles(nil, folderPath, CreateOpenWorld.MaxItemPerFolder, "*.zip");
		if(output and #output>0) then
			local _, item;
			for _, item in ipairs(output) do
				local zip_filename = folderPath.."/"..item.filename;
				local world_name = zip_filename:match("([^/\\]+)%.zip$");
				if(world_name) then
					world_name = world_name:gsub("^[%d_]*", "");
				end
				CreateOpenWorld.AddWorldToDS({worldpath = zip_filename, 
						Title = world_name or "",
						writedate = item.writedate, filesize=item.filesize,
						nid = 0,
						IsFolder=false, time_text=item.time_text})	
			end
		end

		-- select the first world if any. 
		if(not CreateOpenWorld.OnSelectWorld(1, true)) then
			-- if user has never created any world before we will show the new world tab, otherwise we will show the open world tab. 
			page:SetNodeValue("OpenCreateWorldTabs", "newWorld");
		end
	end	
end

-- template db table
CreateOpenWorld.dsWorlds = {};
-- currently selected world index in above table
CreateOpenWorld.SelectedWorld_Index = nil;

function CreateOpenWorld.DS_Func_Open(index)
	if(index == nil) then
		return #(CreateOpenWorld.dsWorlds);
	else
		return CreateOpenWorld.dsWorlds[index];
	end
end

function CreateOpenWorld.DS_Func_Create(index)
	if(not worlds_template)then return 0 end
	if(index == nil) then
		return #(worlds_template);
	else
		return worlds_template[index];
	end
end

-- user clicks to select a world. 
-- @param index: the world index in CreateOpenWorld.dsWorlds
-- @param no_refresh: true to disable page refresh. 
-- @return true if successfully selected. 
function CreateOpenWorld.OnSelectWorld(index, no_refresh)
	local i, world
	for i, world in ipairs(CreateOpenWorld.dsWorlds)  do
		if(i == index) then
			world.selected = true;
			CreateOpenWorld.OnSelectWorld_imp(world);
			CreateOpenWorld.SelectedWorld_Index = index;
		else
			world.selected = nil;
		end
	end
	if(not CreateOpenWorld.SelectedWorld_Index) then
		page:SetValue("WorldImage", ""); -- Texture/Aries/brand/noimageavailable.png
	end
	if(not no_refresh) then
		page:Refresh(0);
	end
	if(CreateOpenWorld.SelectedWorld_Index) then
		return true;
	end
end

-- only return the sub folders of the current folder
-- @param rootfolder: the folder which will be searched.
-- @param nMaxFilesNum: one can limit the total number of files in the search result. Default value is 50. the search will stop at this value even there are more matching files.
-- @param filter: if nil, it defaults to "*."
-- @return a table array containing relative to rootfolder file name.
function CreateOpenWorld.SearchFiles(output, rootfolder,nMaxFilesNum, filter)
	if(rootfolder == nil) then return; end
	if(filter == nil) then filter = "*." end
	
	output = output or {};
	local sInitDir = ParaIO.GetCurDirectory(0)..rootfolder.."/";
	local search_result = ParaIO.SearchFiles(sInitDir,filter, "", 0, nMaxFilesNum or 5000, 0);
	local nCount = search_result:GetNumOfResult();		
	local nextIndex = #output+1;
	local i;
	for i = 0, nCount-1 do 
		output[nextIndex] = search_result:GetItemData(i, {});
		local date = output[nextIndex].writedate;
		local year, month, day, hour, mins = string.match(date, "(%d+)%D+(%d+)%D+(%d+)%D+(%d+)%D+(%d+)")
		year, month, day,hour, mins = tonumber(year) or 0, tonumber(month) or 0, tonumber(day) or 0, tonumber(hour) or 0, tonumber(mins) or 0
		output[nextIndex].order = (year*365+month*31+day)*1440+hour*60+mins;
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
function CreateOpenWorld.AutoCompleteWorldInfo(worldInfo)
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
function CreateOpenWorld.AddWorldToDS(worldInfo)
	if(CreateOpenWorld.AutoCompleteWorldInfo(worldInfo)) then
		table.insert(CreateOpenWorld.dsWorlds, worldInfo);
	end
end

-- user selected a world template. 
function CreateOpenWorld.OnSelectWorldTemplate(index)
	local i, world
	for i, world in ipairs(worlds_template)  do
		if(i == index) then
			world.selected = true;
			CreateOpenWorld.SelectedWorldTemplate_Index = index;
		else
			world.selected = nil;
		end
	end
	page:Refresh(0);
end

function CreateOpenWorld.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function CreateOpenWorld.OnClickDeleteWorld()
	local world = CreateOpenWorld.dsWorlds[CreateOpenWorld.SelectedWorld_Index];
	
	if(world) then
		local filepath = world.worldpath;
		if(string.find(filepath, "^worlds/")) then
			local dirPath = string.gsub(filepath, "\\", "/");
			if(dirPath)then
				_guihelper.MessageBox(string.format([[<div style="margin-top:32px">您确定要删除领地: [%s] 吗?</div>]], world.Title or ""), 
					function ()
						local targetDir = "temp/"..dirPath;
						if(ParaIO.CreateDirectory(targetDir) and ParaIO.MoveFile(dirPath, targetDir)) then  
							CreateOpenWorld.RefreshAll(0);
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

function CreateOpenWorld.OnClickLoadWorld()
	local world = CreateOpenWorld.dsWorlds[CreateOpenWorld.SelectedWorld_Index];
	if(world and world.worldpath) then
		local worldpath = world.worldpath:gsub("%.zip$", "");
		if(System.world:DoesWorldExist(worldpath, true)) then
			CreateOpenWorld.ClosePage();
			WorldCommon.OpenWorld(world.worldpath, CreateOpenWorld.IsNewVersion)
		else
			_guihelper.MessageBox("无效的世界文件");
		end
	end
end

function CreateOpenWorld.OnClickCreateWorld()
	-- _guihelper.MessageBox("OnClickCreateWorld"..CreateOpenWorld.SelectedWorldTemplate_Index)	
	local templ_world = worlds_template[CreateOpenWorld.SelectedWorldTemplate_Index];
	if(not templ_world) then return end
	
	local world_name = page:GetValue("NewWorldName");
	if(world_name == "") then
		_guihelper.MessageBox([[<div style="margin-top:32px">领地名字不能为空, 请输入领地名称</div>]]);
		return
	elseif(string.len(world_name) > 20) then	
		_guihelper.MessageBox([[<div style="margin-top:32px">领地名字太长了, 请重新输入</div>]]);
		return
	end
	
	local params = {
		-- since world name is used as the world path name, we will only use letters as filename. 
		worldname = ParaGlobal.GetDateFormat("yyMMdd").."_"..ParaGlobal.GetTimeFormat("Hmmss").."_"..string.gsub(world_name, "%W", ""),
		title = world_name,
		creationfolder = CreateOpenWorld.GetWorldFolder(),
		parentworld = templ_world.world_path,
		world_generator = templ_world.world_generator,
		seed = templ_world.seed,
		inherit_scene = true,
		inherit_char = true,
	}
	-- _guihelper.MessageBox(params);
	local worldpath, msg = CreateOpenWorld.CreateWorld(params);
	if(worldpath) then
		CreateOpenWorld.ClosePage();
		_guihelper.MessageBox(msg, function()
			-- open the world. 
			WorldCommon.OpenWorld(worldpath, CreateOpenWorld.IsNewVersion);
		end, _guihelper.MessageBoxButtons.YesNo);
	end
end

-- private: create world according to attributes in values input  
-- @param values: it is a table of {worldname or name, parentworld, creationfolder, inherit_scene, inherit_char, author, level, desc,}
-- @return: return worldpath, message. If not succeeded, worldpath is nil. 
function CreateOpenWorld.CreateWorld(values)
	local worldname = values.worldname or values.name
	local worldfolder = values.creationfolder or CreateOpenWorld.OpenWorld_Folder
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
				local world_generator = "";
				if(values.world_generator) then
					world_generator = format("world_generator='%s' ", values.world_generator);
					if(values.seed) then
						world_generator = format("%s seed='%s' ", values.world_generator, values.seed);	
					end
				end
				local text = [[<pe:mcml>
<pe:world name="%s" nid="%s" create_date="%s" %s/>
</pe:mcml>]];
				file:WriteString(string.format(text, values.title or worldname, System.User.nid or "", ParaGlobal.GetDateFormat("yyyy-M-d"), world_generator));
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


-- load world. 
function CreateOpenWorld.OnSelectWorld_imp(world)
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
		
		if(CreateOpenWorld.LastZipFile and CreateOpenWorld.LastZipFile ~= filepath and CreateOpenWorld.LastZipFile~=Map3DSystem.World.worldzipfile) then
			ParaAsset.CloseArchive(CreateOpenWorld.LastZipFile);
		end
		CreateOpenWorld.LastZipFile = filepath;
		ParaAsset.OpenArchive(filepath, true);
		
		local search_result = ParaIO.SearchFiles("","*/*.jpg", filepath, 0, 10, 0); -- this version uses wild cards
		--local search_result = ParaIO.SearchFiles("",":.*\\.jpg", filepath, 0, 10, 0); -- this version uses regular expression
		local nCount = search_result:GetNumOfResult();
		if(nCount>0) then
			-- just use the first directory in the world zip file as the world name.
			world.preview = string.gsub(filepath, "([^/\\]+)$", search_result:GetItem(0)); -- get rid of the zip file extension for display 
		end	
	end
	page:SetValue("WorldImage", world.preview or "");
end
