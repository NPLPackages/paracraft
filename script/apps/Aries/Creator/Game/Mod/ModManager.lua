--[[
Title: plugin manager
Author(s): LiXizhi
Date: 2015/4/9
Desc: mod is a special type of plugin that can be dynamically loaded. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
local ModManager = commonlib.gettable("Mod.ModManager");
ModManager:OnLoadWorld();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Plugins/PluginManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModBase.lua");
local PluginManager = commonlib.gettable("System.Plugins.PluginManager");

local ModManager = commonlib.inherit(PluginManager, {});
ModManager:Property({"Name", "Paracraft"});

function ModManager:ctor()
end

function ModManager:Init()
end

function ModManager:handleKeyEvent(event)
	return self:InvokeMethod("handleKeyEvent", event);
end

function ModManager:handleMouseEvent(event)
	return self:InvokeMethod("handleMouseEvent", event);
end

-- signal
function ModManager:OnWorldLoad()
	self:InvokeMethod("OnWorldLoad");
	LOG.std(nil, "info", "ModManager", "plugins (mods) loaded in world");
end

-- signal
function ModManager:OnWorldSave()
	self:InvokeMethod("OnWorldSave");
	LOG.std(nil, "info", "ModManager", "plugins (mods) saved in world");
end

-- signal
function ModManager:OnLeaveWorld()
	self:InvokeMethod("OnLeaveWorld");
end

-- signal
function ModManager:OnDestroy()
	self:InvokeMethod("OnDestroy");
end

-- signal
function ModManager:OnLogin()
	self:InvokeMethod("OnLogin");
end

-- virtual: called when a desktop is inited such as displaying the initial user interface. 
-- return true to prevent further processing.
function ModManager:OnInitDesktop()
	return self:InvokeMethod("OnInitDesktop");
end

-- virtual: called when a desktop mode is changed such as from game mode to edit mode. 
-- return true to prevent further processing.
function ModManager:OnActivateDesktop(mode)
	return self:InvokeMethod("OnActivateDesktop", mode);
end

-- virtual: called when a user try to close the application window
-- return true to prevent further processing.
function ModManager:OnClickExitApp(bForceExit, bRestart)
	return self:InvokeMethod("OnClickExitApp",bForceExit, bRestart);
end

-- create singleton and assign it to Mod.ModManager
local g_Instance = ModManager:new(commonlib.gettable("Mod.ModManager"));
PluginManager.AddInstance(g_Instance);