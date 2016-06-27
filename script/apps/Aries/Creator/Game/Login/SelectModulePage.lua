--[[
Title: SelectModulePage.html code-behind script
Author(s): LiPeng, LiXizhi
Date: 2014/4/1
Desc: select the default global modules for the game, and the modules for every world.
Simply put plugin zip file or mod folder to ./Mod folder. 
The plugin zip file must contain a file called "Mod/[plugin_name]/main.lua" 
in order to be considered as a valid plugin zip file. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/SelectModulePage.lua");
local SelectModulePage = commonlib.gettable("MyCompany.Aries.Game.MainLogin.SelectModulePage")
local modules = SelectModulePage.SearchAllModules();
echo(modules)
SelectModulePage.AddModule("STLExporter.zip")
SelectModulePage.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
local ModManager = commonlib.gettable("Mod.ModManager");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local SelectModulePage = commonlib.gettable("MyCompany.Aries.Game.MainLogin.SelectModulePage")

-- the rage value can be 0(for global game) or 1(for one world).
SelectModulePage.range = 0;
-- the module files' directory
SelectModulePage.dir = "Mod/";
SelectModulePage.page = nil;

--local isDevEnv = false;
local isDevEnv = System.options.isDevEnv;
SelectModulePage.mod_info= {
	--scriptList = {},
	--cur_script_name = nil;
	-- saved the gridview datasource which named "gvwModTable"
	modList = {},
	-- the table loaded from the local config file,decided the module whether be used;
	modTable = {},
	-- the world which the modules are used in. if "nil" ,the modules are used in global range;
	curWorld = nil,
	---- the selected mod list
	--selectedModList = {},
}

-- init function. page script fresh is set to false.
function SelectModulePage.OnInit()
	
	if(not SelectModulePage.inited) then
		SelectModulePage.inited = true;
		ParaIO.CreateDirectory(SelectModulePage.dir);
		SelectModulePage.GetModTableFromFile();
		--SelectModulePage.page = document:GetPageCtrl();
	end	
end

function SelectModulePage.GetCurrentWorld()
	return SelectModulePage.curWorld or "global";
end

function SelectModulePage.GetModTableFromFile()
	local curModTable = {};

	local filename = SelectModulePage.dir.."ModsConfig.xml";
	if(not ParaIO.DoesAssetFileExist(filename, true))then
		return;
	end
	local modXML = ParaXML.LuaXML_ParseFile(filename);

	local modnode;
	for modnode in commonlib.XPath.eachNode(modXML,"/mods/mod") do
		local modname = modnode.attr.name;
		curModTable[modname] = {};
		local worldnode;
		for worldnode in commonlib.XPath.eachNode(modnode,"/world") do
			local worldname = worldnode.attr.name;
			curModTable[modname][worldname] = {};
			local checked = worldnode.attr.checked;
			if(checked and checked == "true") then
				curModTable[modname][worldname]["checked"] = true;
			else
				curModTable[modname][worldname]["checked"] = false;
			end
		end
	end
	SelectModulePage.mod_info.modTable = curModTable;
end

function SelectModulePage.SaveModTableToFile()
	local curModTable = SelectModulePage.mod_info.modTable;
	local filename = SelectModulePage.dir.."ModsConfig.xml";
	local file = ParaIO.open(filename, "w");

	if(file:IsValid()) then
		local root = {name='mods',}
		for modname,mod in pairs(curModTable) do 
			local modnode = {name='mod', attr={name = modname}};
			
			for worldname,world in pairs(mod) do 
				local worldnode = {name='world', attr={name = worldname}};
				if(world["checked"]) then
					worldnode.attr.checked = world["checked"];
				else
					worldnode.attr.checked = false;
				end
				if(worldnode) then
					modnode[#modnode+1] = worldnode;
				end
			end
			if(modnode) then
				root[#root+1] = modnode;
			end
		end
		if(root) then
			file:WriteString(commonlib.Lua2XmlString(root,true) or "");
		end
		file:close();
	end
end

function SelectModulePage.AddModuleToDS(modname, modList)
	local curModTable = SelectModulePage.mod_info.modTable;
	local curWorld = SelectModulePage.GetCurrentWorld();
	local checked = false;
	
	local mod = curModTable[modname];
	if(mod) then
		if(mod[curWorld] and mod[curWorld]["checked"] == true) then
			checked = true;
		end
	else
		mod = {};
		curModTable[modname] = mod;
		if(not mod[curWorld]) then
			if(curWorld ~= "global") then
				if(mod["global"]) then
					mod[curWorld] = mod["global"];
				else
					mod[curWorld] = {};
				end
			else
				mod[curWorld] = {};
			end
		end
	end
	local isZip = modname:match("%.(zip)$") == "zip";
	local item = {text = modname, name = modname, checked = checked, isZip=isZip};
	modList[#modList+1] = item;
end

function SelectModulePage.SearchAllModules()
	local modList = {};
	-- add all explicit plugins in "Mod" folder. 
	local folderPath = SelectModulePage.dir;
	local output = commonlib.Files.Find(nil, folderPath, 0, 50000, "*.");
	if(output and #output>0) then
		for _, item in ipairs(output) do
			local filename = format("%s%s/main.lua", folderPath, item.filename);
			if(ParaIO.DoesFileExist(filename, false)) then
				SelectModulePage.AddModuleToDS(item.filename, modList);
			end
		end
	end
	-- add *.zip plugins in "Mod" folder. 
	if(not isDevEnv) then
		local output = commonlib.Files.Find(nil, folderPath, 0, 50000, "*.zip");
		if(output and #output>0) then
			for _, item in ipairs(output) do
				SelectModulePage.AddModuleToDS(item.filename, modList);
			end
		end
	end
	return modList;
end

-- get the modlist from the directory "Mod/"
function SelectModulePage.GetModuleList()
	SelectModulePage.mod_info.modList = SelectModulePage.SearchAllModules();
end

-- get the datasource of the module;
function SelectModulePage.DS_Items(index)
	local ds = SelectModulePage.mod_info.modList;
	if(ds) then
		if(index == nil) then
			return #ds;
		else
			return ds[index];
		end
	end
end

local temporary_modtable = {};

-- select the module to decide the module whether loaded
function SelectModulePage.OnSwitchModStatus(bChecked,modName,index)
	local curWorld = SelectModulePage.GetCurrentWorld();
	local mod = temporary_modtable[modName];
	if(not mod) then
		temporary_modtable[modName] = {};
		mod = temporary_modtable[modName];
	end

	if(not mod[curWorld]) then
		if(curWorld ~= "global") then
			if(mod["global"]) then
				mod[curWorld] = mod["global"];
			else
				mod[curWorld] = {};
			end
		else
			mod[curWorld] = {};
		end
	end
	mod[curWorld]["checked"] = bChecked;
	if(index) then
		local item = SelectModulePage.mod_info.modList[index];
		item.checked = bChecked;
	end
end

-- reset the "SelectModulePage.mod_info.modTable"
function SelectModulePage.ResetLoadedMods()
	SelectModulePage.mod_info.modTable = nil;
	SelectModulePage.mod_info.modTable = temporary_modtable;
	SelectModulePage.SaveModTableToFile();
end

-- show page
function SelectModulePage.ShowPage()
	SelectModulePage.OnInit();
	SelectModulePage.GetModuleList();

	if(System.options.IsMobilePlatform) then
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Login/SelectModulePage.mobile.html", 
			name = "SelectModulePage.ShowMobilePage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow,
			zorder = 5,
			click_through = true, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		});
	else
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Login/SelectModulePage.html", 
			name = "SelectModulePage", 
			isShowTitleBar = false,
			enable_esc_key = true,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 0,
			allowDrag = false,
			directPosition = true,
				align = "_ct",
				x = -300,
				y = -250,
				width = 600,
				height = 500,
			cancelShowAnimation = true,
		});
	end
	
	commonlib.mincopy(temporary_modtable,SelectModulePage.mod_info.modTable);
end


-- load selected modules file
function SelectModulePage.LoadMods()
	if(SelectModulePage.isLoaded or not System.options.mc) then
		return;
	end
	SelectModulePage.isLoaded = true;

	local skip_modname;
	if(isDevEnv) then
		local modname = ParaEngine.GetAppCommandLineByParam("mod","");
		if(modname and modname ~= "") then
			local filepath = "(gl)"..SelectModulePage.dir..modname.."/main.lua";
			NPL.load(filepath);
			local module_class = SelectModulePage.FindModuleClass(modname);
			if(module_class) then
				ModManager:AddMod(modname, module_class);
			end
			skip_modname = modname;
		end
	end

	SelectModulePage.OnInit();

	local modTable = SelectModulePage.mod_info.modTable;
	local curWorld = SelectModulePage.GetCurrentWorld();		
	local failedMods;
	for modname, modinfo in pairs(modTable) do
		if(modinfo[curWorld] and modinfo[curWorld]["checked"]) then
			if(skip_modname ~= modname) then
				if(not SelectModulePage.AddModule(modname)) then
					LOG.std(nil, "warn", "SelectModulePage", "failed to load module %s", modname);
					failedMods = failedMods or {};
					failedMods[#failedMods+1] = modname;
				end
			end
		end
	end
	if(failedMods) then
		for _, modname in ipairs(failedMods) do
			modTable[modname] = nil;
		end
		SelectModulePage.SaveModTableToFile();
	end
end

-- @param module_classname: case insensitive module name
function SelectModulePage.FindModuleClass(module_classname)
	if(module_classname) then
		module_classname = string.lower(module_classname);
		for name, value in pairs(Mod) do
			if(string.lower(name) == module_classname) then
				if(type(value) == "table") then
					return value;
				end
			end
		end
	end
end

function SelectModulePage.AddModuleImp(modname, main_filename)
	local module_classname = main_filename:match("^%w+/([^/]+)");
	local module_class = SelectModulePage.FindModuleClass(module_classname);
	if(not module_class) then
		NPL.load(main_filename);
		module_class = SelectModulePage.FindModuleClass(module_classname);
		if(module_class) then
			ModManager:AddMod(modname, module_class);
			return true;
		end
	else
		LOG.std(nil, "warn", "Modules", "mod: %s ignored, because another module_class %s already exist", modname, module_classname); 
	end
end

-- @param modname: it is either the folder name or zip file name. such as "STLExporter.zip"
function SelectModulePage.AddModule(modname)
	local filename = SelectModulePage.dir..modname;
	if( modname:match("%.(zip)$") == "zip") then
		if(ParaIO.DoesAssetFileExist(filename, true))then
			ParaAsset.OpenArchive(filename,false);	
			-- try find main file in "Mod/*/main.lua"
			local output = commonlib.Files.Find(nil, "", 0, 10000, "Mod/*/main.lua", filename)
			if(output and #output>0) then
				local main_filename = output[1].filename;
				return SelectModulePage.AddModuleImp(modname, main_filename);
			end
			-- try find main file in "*/Mod/*/main.lua"
			local output = commonlib.Files.Find(nil, "", 0, 10000, "*/Mod/*/main.lua", filename)
			if(output and #output>0) then
				-- just in case, the user has zipped everything in a folder, such as downloading from github as a zip file. 
				local base_folder_name, main_filename = output[1].filename:match("^([^/]+)/(%w+/[^/]+/main.lua)");
				if(main_filename) then
					local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(filename);
					zip_archive:SetField("SetBaseDirectory", base_folder_name);
					return SelectModulePage.AddModuleImp(modname, main_filename);
				end
			end
		end
	else
		local main_filename = filename.."/main.lua";
		return SelectModulePage.AddModuleImp(modname, main_filename);
	end
end