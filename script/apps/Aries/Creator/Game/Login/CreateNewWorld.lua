--[[
Title: CreateNewWorld.html code-behind script
Author(s): LiPeng
Date: 2013/10/19
Desc: Create new world based on predefined template and open existing world. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
CreateNewWorld.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")

local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local worlds_template = {
	-- this is pure block world with "flat" generator
	{name = "积木世界", icon = "", world_generator = "flat", seed = nil, },
};

CreateNewWorld.SelectedWorldTemplate_Index = nil;

CreateNewWorld.inited = false;
CreateNewWorld.default_worldname= "积木世界";

CreateNewWorld.style_info = {
	{index = 1,style = "survival", show_value = "生存模式", description = "探索、冒险<br/>收集、合成"},
	{index = 2,style = "create",   show_value = "创造模式", description = "无限资源<br/>随意建造、瞬间破坏"},
	}
CreateNewWorld.difficulty_info = {
	{index = 1,grade = "primary", show_value = "初级", description = "怪物数量：很少<br/>怪物血量：低血量"},
	{index = 2,grade = "middle",  show_value = "中级", description = "怪物数量：中等<br/>怪物血量：中等血量"},
	}
-- initial world settings
CreateNewWorld.terrain_info = {
	{index = 1,terrain = "superflat",  show_value = "超级平坦", description = "海拔0米,无地下"},
	{index = 2,terrain = "custom", show_value = "随机地形", description = "森林，沙漠，雪地，山洞"},
	{index = 3,terrain = "empty", show_value = "空", description = "SDK用户可用命令行创建地基"},
	--{index = 4,terrain = "flat",  show_value = "高原", description = "海拔128米"},
}
CreateNewWorld.oneday_time_info = {
	{index = 1,realtime = "short", show_value = "10min/day", description = "10分钟"},
	{index = 2,realtime = "long",  show_value = "20min/day",description = "20分钟"},
}

CreateNewWorld.world_info = {
	worldname = nil;
	
}


-- default world folder path
CreateNewWorld.OpenWorld_Folder = "worlds/DesignHouse";

-- whether to use the new version to open/create world
CreateNewWorld.IsNewVersion = false;

-- init function. page script fresh is set to false.
function CreateNewWorld.OnInit()
	-- start timer
	--page = document:GetPageCtrl();
	
	-- update the file path
	if(not CreateNewWorld.inited) then
		CreateNewWorld.inited = true;
		CreateNewWorld.cur_style = CreateNewWorld.style_info[2];
		CreateNewWorld.cur_difficulty = CreateNewWorld.difficulty_info[1];
		CreateNewWorld.cur_terrain = CreateNewWorld.terrain_info[1];
		CreateNewWorld.cur_oneday_time = CreateNewWorld.oneday_time_info[1];
		
		
		--if(not CreateNewWorld.OnSelectWorld(1, true)) then
			---- if user has never created any world before we will show the new world tab, otherwise we will show the open world tab. 
			--page:SetNodeValue("OpenCreateWorldTabs", "newWorld");
		--end
	end	
end

-- show page
function CreateNewWorld.ShowPage()
	local isCustomShow = GameLogic.GetFilters():apply_filters("show_custom_create_new_world", "show");
	if(isCustomShow == "show") then
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Login/CreateNewWorld.html", 
			name = "CreateMCNewWorld", 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 0,
			allowDrag = false,
			directPosition = true,
				align = "_ct",
				x = -700/2,
				y = -450/2,
				width = 700,
				height = 450,
			cancelShowAnimation = true,
		});
	end
end

-- template db table
CreateNewWorld.dsWorlds = {};
-- currently selected world index in above table
CreateNewWorld.SelectedWorld_Index = nil;
CreateNewWorld.SelectedWorld = nil;


function CreateNewWorld.DS_Func_Open(index)
	if(index == nil) then
		return #(CreateNewWorld.dsWorlds);
	else
		return CreateNewWorld.dsWorlds[index];
	end
end

function CreateNewWorld.DS_Func_Create(index)
	if(not worlds_template)then return 0 end
	if(index == nil) then
		return #(worlds_template);
	else
		return worlds_template[index];
	end
end

-- user clicks to select a world. 
-- @param index: the world index in CreateNewWorld.dsWorlds
-- @return true if successfully selected. 
function CreateNewWorld.OnSelectWorld(world,bRefresh)
	--local i, world
	--for i, world in ipairs(CreateNewWorld.dsWorlds)  do
		--if(i == index) then
			--world.selected = true;
			--CreateNewWorld.OnSelectWorld_imp(world);
			--CreateNewWorld.SelectedWorld_Index = index;
			--world.background = "Texture/Aries/Creator/Theme/CommonControl_32bits.png;52 202 16 16:6 6 6 6"
		--else
			--world.selected = nil;
			--world.background = "Texture/Aries/Creator/Theme/CommonControl_32bits.png;32 202 16 16:6 6 6 6";
		--end
	--end


	local cur_world = CreateNewWorld.SelectedWorld;
	if(cur_world) then
		cur_world.selected = nil;
	end
	world.selected = true;
	CreateNewWorld.SelectedWorld = world;
	
	if(bRefresh) then
		CreateNewWorld.page:Refresh(0.1);
	end
		
    
end

-- only return the sub folders of the current folder
-- @param rootfolder: the folder which will be searched.
-- @param nMaxFilesNum: one can limit the total number of files in the search result. Default value is 50. the search will stop at this value even there are more matching files.
-- @param filter: if nil, it defaults to "*."
-- @return a table array containing relative to rootfolder file name.
function CreateNewWorld.SearchFiles(output, rootfolder,nMaxFilesNum, filter)
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
function CreateNewWorld.AutoCompleteWorldInfo(worldInfo)
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
function CreateNewWorld.AddWorldToDS(worldInfo)
	if(CreateNewWorld.AutoCompleteWorldInfo(worldInfo)) then
		table.insert(CreateNewWorld.dsWorlds, worldInfo);
	end
end

-- user selected a world template. 
function CreateNewWorld.OnSelectWorldTemplate(index)
	local i, world
	for i, world in ipairs(worlds_template)  do
		if(i == index) then
			world.selected = true;
			CreateNewWorld.SelectedWorldTemplate_Index = index;
		else
			world.selected = nil;
		end
	end
	page:Refresh(0);
end

function CreateNewWorld.ClosePage()
	local isCustomShow = GameLogic.GetFilters():apply_filters("show_custom_create_new_world", "close");
	if(not isCustomShow) then
		page:CloseWindow();
	end
end


function CreateNewWorld.OnClickLoadWorld()
	local world = CreateNewWorld.SelectedWorld;
	if(world and world.worldpath) then
		local worldpath = world.worldpath:gsub("%.zip$", "");
		if(System.world:DoesWorldExist(worldpath, true)) then
			CreateNewWorld.ClosePage();
			WorldCommon.OpenWorld(world.worldpath, true)
		else
			_guihelper.MessageBox(L"无效的世界文件");
		end
	end
end

function CreateNewWorld.GetWorldFolder()
	return LocalLoadWorld.GetDefaultSaveWorldPath();
end

function CreateNewWorld.OnClickCreateWorld()
	-- _guihelper.MessageBox("OnClickCreateWorld"..CreateNewWorld.SelectedWorldTemplate_Index)	
	--local templ_world = worlds_template[CreateNewWorld.SelectedWorldTemplate_Index];
	local templ_world = worlds_template[CreateNewWorld.SelectedWorldTemplate_Index or 1];
	if(not templ_world) then return end
	
	--local world_name = page:GetValue("NewWorldName") or "积木世界";
	
	--echo("22222222222");
	--echo(CreateNewWorld.page:GetValue("new_world_name"));
	local world_name = CreateNewWorld.page:GetValue("new_world_name") or CreateNewWorld.default_worldname;
	world_name = world_name:gsub("[%s/\\]", "");

	local world_name_locale = commonlib.Encoding.Utf8ToDefault(world_name);
	if(world_name == "") then
		_guihelper.MessageBox(L"世界名字不能为空, 请输入世界名称");
		return
	elseif(string.len(world_name) > 20) then	
		_guihelper.MessageBox(L"世界名字太长了, 请重新输入");
		return
	end
	
	local params = {
		-- since world name is used as the world path name, we will only use letters as filename. 
		--worldname = ParaGlobal.GetDateFormat("yyMMdd").."_"..ParaGlobal.GetTimeFormat("Hmmss").."_"..string.gsub(world_name, "%W", ""),
		worldname = world_name_locale,
		title = world_name,
		creationfolder = CreateNewWorld.GetWorldFolder(),
		parentworld = templ_world.parent_world_path,
		world_generator = CreateNewWorld.cur_terrain.terrain or templ_world.world_generator,
		seed = templ_world.seed or world_name,
		inherit_scene = true,
		inherit_char = true,
	}
	LOG.std(nil, "info", "CreateNewWorld", params);

	local worldpath, error_msg = CreateNewWorld.CreateWorld(params);
	if(not worldpath) then
		if(error_msg) then
			_guihelper.MessageBox(error_msg);
		end
	else
		LOG.std(nil, "info", "CreateNewWorld", "new world created at %s", worldpath);
		CreateNewWorld.ClosePage();
		WorldCommon.OpenWorld(worldpath, true);
		GameLogic:UserAction("introduction");
		-- this is annoying, we will not show tutorial in this intrusive way. we will use external lesson mod to do this job in near future.
		-- GameLogic.options:SetShowTutorial(true);
	end
end

-- private: create world according to attributes in values input  
-- @param values: it is a table of {worldname or name, parentworld, creationfolder, inherit_scene, inherit_char, author, level, desc,}
-- @return: return worldpath, message. If not succeeded, worldpath is nil. 
function CreateNewWorld.CreateWorld(values)
	local worldname = values.worldname or values.name;
	local worldfolder = values.creationfolder or CreateNewWorld.OpenWorld_Folder
	local parentworld = values.parentworld;
	if(parentworld==nil or parentworld=="") then parentworld=nil end 
	local inherit_scene = values.inherit_scene
	if(inherit_scene == nil) then inherit_scene=true end
	local inherit_char = values.inherit_char
	if(inherit_char == nil) then inherit_char=true end
	
	if(worldname == nil or worldname=="") then
		return nil, L"世界名字不能为空"
	elseif(worldname == "_emptyworld") then
		return nil, L"您不能使用这个名字, 请换个名字"
	else
		if(not string.match(worldfolder, "/$")) then
			worldfolder = worldfolder.."/"
		end

		if(not commonlib.Files.IsAbsolutePath(worldfolder)) then
			worldfolder = ParaIO.GetWritablePath()..worldfolder;
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
				NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackage.lua");
				local TexturePackage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackage");
				attr.texture_pack_path = TexturePackage.default_texture_path;
				attr.texture_pack_type = TexturePackage.default_texture_type;
				attr.texture_pack_url  = TexturePackage.default_texture_url;

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
				return worldpath, string.format(L"世界[%s]创建成功! 开始你的创造吧", values.title or worldname);
			else
				_guihelper.MessageBox(L"创建tag.xml出错了")	
			end
			
		elseif(type(res) == "string") then
			return nil, res
		end
	end
	return nil, L"未知错误"
end


-- load world. 
function CreateNewWorld.OnSelectWorld_imp(world)
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
		
		if(CreateNewWorld.LastZipFile and CreateNewWorld.LastZipFile ~= filepath and CreateNewWorld.LastZipFile~=Map3DSystem.World.worldzipfile) then
			ParaAsset.CloseArchive(CreateNewWorld.LastZipFile);
		end
		CreateNewWorld.LastZipFile = filepath;
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
