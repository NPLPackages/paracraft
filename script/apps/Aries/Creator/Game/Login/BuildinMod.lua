--[[
Title: buildin paracraft mod
Author(s):  LiXizhi
Date: 2017.4.23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/BuildinMod.lua");
local BuildinMod = commonlib.gettable("MyCompany.Aries.Game.MainLogin.BuildinMod");
BuildinMod.AddBuildinMods();
------------------------------------------------------------
]]
-- create class
local BuildinMod = commonlib.gettable("MyCompany.Aries.Game.MainLogin.BuildinMod");

-- package_path can be the same, so the same package zip can contain multiple mods
BuildinMod.buildin_mods = {
	{
		name = "ParaXExporter", 
		package_path = "npl_packages/BMaxToParaXExporter/", 
		displayName = "ParaX 3D模型导出", 
		text="系统内置插件",
		version = "1.0",
		homepage = "https://github.com/tatfook/BMaxToParaXExporter",
	},
	{
		name = "NPLCAD", 
		package_path = "npl_packages/NPLCAD/", 
		displayName = "NPL CAD编程建模", 
		text="系统内置插件",
		version = "1.0",
		homepage = "https://github.com/tatfook/NPLCAD",
	},
	{
		name = "STLExporter", 
		package_path = "npl_packages/STLExporter/", 
		displayName = "STL 3D打印模型导出", 
		text="系统内置插件",
		version = "1.0",
		homepage = "https://github.com/LiXizhi/stlexporter",
	},
	-- TODO: add more preinstalled paracraft mod package here
};

-- called at the very beginning before plugins are loaded.
function BuildinMod.AddBuildinMods()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
	local ModManager = commonlib.gettable("Mod.ModManager");
	local pluginloader = ModManager:GetLoader();

	-- ensure that the same package_path are only loaded once.
	local loaded_packages = {};
	for _, mod in ipairs(BuildinMod.buildin_mods) do
		if(loaded_packages[mod.package_path]~=false) then
			if(loaded_packages[mod.package_path] == nil) then
				loaded_packages[mod.package_path] = NPL.load(mod.package_path)~=false;
			end
			if(loaded_packages[mod.package_path]) then
				pluginloader:AddSystemModule(mod.name or mod.package_path, mod);
			end
		end
	end
end