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
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModBase.lua");

local ModManager = commonlib.gettable("Mod.ModManager");

-- array of all mod
local mods = {};
-- mapping from name to mod
local mods_name_map = {};
-- mapping mod object to true
local mods_map = {};


function ModManager:Init()

end

-- clean up all mods
function ModManager:Cleanup()
	self:OnDestroy();
	mods = {};
	mods_name_map = {};
	mods_map = {};
end

function ModManager:GetMod(name)
	return mods_name_map[name or ""];
end

function ModManager:GetLoadedModCount()
	return #mods;
end

function ModManager:IsModLoaded(mod_)
	return mod_ and mods_map[mod_];
end

-- add mod to the mod plugin. 
function ModManager:AddMod(name, mod)
	if(not mod or not mod.InvokeMethod or self:IsModLoaded(mod)) then
		return;
	end
	name = name or mod:GetName() or "";
	mod:InvokeMethod("init");

	mods[#mods+1] = mod;
	mods_map[mod] = true;
	if(not mods_name_map[name]) then
		LOG.std(nil, "info", "ModManager", "mod: %s (%s) is added", name, mod:GetName() or "");
		mods_name_map[name] = mod;
	else
		LOG.std(nil, "info", "ModManager", "overriding mod with same name: %s", name);
	end
	return true;
end

-- private function: invoke method on all plugins. if the plugin does not have the method, it does nothing. 
-- it only calls method if the mod is enabled. 
-- @return the return value of the last non-nil plugin. 
function ModManager:InvokeMethod(method_name, ...)
	local result;
	for _, mod in ipairs(mods) do
		if(mod:IsEnabled()) then
			result = mod:InvokeMethod(method_name, ...) or result;
		end
	end
	return result;
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