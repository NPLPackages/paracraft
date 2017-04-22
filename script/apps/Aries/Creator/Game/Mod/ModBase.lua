--[[
Title: base class for mod (plugin)
Author(s): LiXizhi
Date: 2014/4/6
Desc: base class for mod. 
virtual functions:
  init(): 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModBase.lua");
local ModBase = commonlib.gettable("Mod.ModBase");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Plugins/PluginBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
NPL.load("(gl)script/ide/LuaXML.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/Files.lua");

local ModManager = commonlib.gettable("Mod.ModManager");
local ModBase    = commonlib.inherit(commonlib.gettable("System.Plugins.PluginBase"), commonlib.gettable("Mod.ModBase"));
local Encoding   = commonlib.gettable("commonlib.Encoding");

ModBase:Property({"Name", "unknown name"});
ModBase:Property({"Desc", "mod is a special kind of plugin in paracraft"});

function ModBase:ctor()
end

function ModBase:IsMod()
	return true;
end

-- get mod manager.
function ModBase:GetManager()
	return ModManager;
end

-- called once during initialization
function ModBase:init()
end

-- called when user logged in
function ModBase:OnLogin()
end

-- invoke method. if the plugin does not have the method, it does nothing. 
function ModBase:InvokeMethod(method_name, ...)
	local func = self[method_name];
	if(func and type(func) == "function") then
		return func(self, ...);
	end
end

-- called when a new world is loaded. 
function ModBase:OnWorldLoad()
end

-- called when a world is saved. 
function ModBase:OnWorldSave()
end

-- called when a world is unloaded. 
function ModBase:OnLeaveWorld()
end

function ModBase:OnDestroy()
end

-- @param event: see KeyEvent 
-- return true to prevent further processing.
function ModBase:handleKeyEvent(event)
end

-- @param event: see MouseEvent 
function ModBase:handleMouseEvent(event)
end

-- virtual: called when a desktop is inited such as displaying the initial user interface. 
-- return true to prevent further processing.
function ModBase:OnInitDesktop()
	-- return true;
end

-- virtual: called when a desktop mode is changed such as from game mode to edit mode. 
-- return true to prevent further processing.
function ModBase:OnActivateDesktop(mode)
	-- return true;
end

-- virtual: called when a user try to close the application window
-- return true to prevent further processing.
function ModBase:OnClickExitApp(bForceExit, bRestart)
	-- return true;
end

-- helper function to add a menu item in desktop menu. A more advanced way is to use filter directory
-- @param parent_name: name of the parent menu item. see DesktopMenu.lua. commonly used are "file", "online", "edit","window", "help"
-- @param menuItem: a table of menu item, e.g. {text=string, name = string, cmd=string, onclick=function}
-- @param previousItemName: The name of the menu item after which to insert the menu item. if nil, it will insert at the end.
-- e.g. self:RegisterMenuItem("file", {text="Demo Plugin Menu", name="file.demo", onclick=function() end}, "file.loadworld");
function ModBase:RegisterMenuItem(parent_name, menuItem, previousItemName)
	GameLogic.GetFilters():add_filter("desktop_menu", function(menuitems)
		for i, menu in ipairs(menuitems) do
			if(menu.name==parent_name) then
				local nInsertIndex;
				for index, item in ipairs(menu.children) do
					if(item.name == menuItem.name) then
						return menuitems;
					elseif(item.name == previousItemName) then
						nInsertIndex = index + 1;
					end
				end
				-- insert menu item
				table.insert(menu.children, nInsertIndex or (#(menu.children)+1), menuItem);
				break;
			end
		end
		return menuitems;
	end)
end

-- register a new command for this plugins
-- @param name: name of the command
-- @param cmd: a table containing command handler. 
-- e.g. self:RegisterCommand("hello", {name="hello", quick_ref="/hello", desc="", handler=function(cmd_name, cmd_text, cmd_params, fromEntity)	end})
function ModBase:RegisterCommand(name, cmd)
	local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
	Commands[name] = cmd;
end

-- set any kind of data
-- @param dataBundle: bundles of data
-- @param dataTable: table data type
-- e.g self:SetWorldData("mydata",{hello="world",thank="you"})
function ModBase:SetWorldData(dataBundle, dataTable, worldName)
	if(not worldName) then
		worldName = GameLogic.GetWorldDirectory();
	end

	local modName = self.Name;

	if(self.worldData == nil) then
		local filePath  = worldName .. "mod/" .. modName .. ".xml";
		self.worldData = ParaXML.LuaXML_ParseFile(filePath);
	end

	if(self.worldData) then
		--If exist the same dataBundle,delete it.
		for key,value in pairs(self.worldData[1]) do
			if(value.name == dataBundle) then
				self.worldData[1][key] = nil;
			end
		end
	else
		self.worldData = {{name=modName}};
		ParaIO.CreateDirectory(worldName .. "mod/");
	end

	local count = 0;
	local newWorldData = {{name=modName}};

	for key,value in pairs(self.worldData[1]) do
		if(type(key) == "number") then
			count = count + 1;
			newWorldData[1][count] = value;
		end
	end

	newWorldData[1][count+1] = {commonlib.serialize_compact(dataTable),name=dataBundle,attr={type=type(dataTable)}};
	self.worldData = newWorldData;
	return nil;
end

-- get any data
-- @param dataBundle: bundle name
-- e.g self:GetWorldData("myname")
-- return {hello="world",thank="you"}
function ModBase:GetWorldData(dataBundle, worldName)
	if(self.worldData == nil) then
		local modName   = self.Name;

		if(not worldName) then
			worldName = GameLogic.GetWorldDirectory();
		end

		local filePath  = worldName .. "mod/" .. modName .. ".xml";

		self.worldData = ParaXML.LuaXML_ParseFile(filePath);
	end

	if(self.worldData) then
		for key,value in pairs(self.worldData[1]) do
			if(value.name == dataBundle) then
				if(value.attr.type == "table") then
					return NPL.LoadTableFromString(value[1]);
				elseif(value.attr.type == "string") then
					return value[1];
				elseif(value.attr.type == "number") then
					return tonumber(value[1]);
				elseif(value.attr.type == "boolean") then
					return value[1] == "true";
				end
			end
		end

		return nil;
	else
		return nil;
	end
end

function ModBase:SaveWorldData(worldName)
	local modName   = self.Name;

	if(not worldName) then
		worldName = GameLogic.GetWorldDirectory();
	end

	local filePath  = worldName .. "mod/" .. modName .. ".xml";

	local saveXml = commonlib.Lua2XmlString(self.worldData);

	--LOG.std(nil,"debug","filePath",Encoding.DefaultToUtf8(filePath));
	local file = ParaIO.open(filePath, "w");

	file:write(saveXml,#saveXml);
	file:close();
end
	