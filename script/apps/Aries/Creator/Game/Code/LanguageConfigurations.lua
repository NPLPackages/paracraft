--[[
Title: LanguageConfigurations
Author(s): LiXizhi
Date: 2019/1/14
Desc: 
see also: https://github.com/NPLPackages/paracraft/wiki/languageConfigFile
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/LanguageConfigurations.lua");
local LanguageConfigurations = commonlib.gettable("MyCompany.Aries.Game.Code.LanguageConfigurations");
-------------------------------------------------------
]]
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local LanguageConfigurations = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.LanguageConfigurations"));

function LanguageConfigurations:ctor()
	self.configs = {};
end

-- @return config object
function LanguageConfigurations:LoadConfigByFilename(filename)
	local langConfig;
	if(filename == "" or filename == "npl") then
		langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/ParacraftCodeBlockly.lua");
	elseif(filename == "npl_cad") then
		langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCad.lua");
    elseif(filename == "npl_microbit") then
		langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobit.lua");
	else
		filename = Files.GetWorldFilePath(filename)
		if(filename) then
			-- used forward slash for absolute file path, otherwise NPL.load will inteprete : wrongly.  
			filename = filename:gsub("^(%S):/", "%1:\\");
			langConfig = NPL.load(filename, true);
		end
	end
	if(type(langConfig) == "table") then
		self.configs[filename] = langConfig;
		return langConfig;
	end
end

function LanguageConfigurations:IsBuildinFilename(filename)
	return filename == "" or filename=="npl" or filename=="npl_cad" or filename=="npl_microbit"
end

-- enable caching
function LanguageConfigurations:GetConfig(filename)
	local config = self.configs[filename];
	if(config == nil) then
		config = self:LoadConfigByFilename(filename) or false;
		self.configs[filename] = config;
	end
	return config;
end

-- should be a function of CompileCode(code,filename, codeblock)
-- @param filename: configuration filename
function LanguageConfigurations:GetCompiler(filename)
	local config = self:GetConfig(filename)
	return config and config.CompileCode;
end

LanguageConfigurations:InitSingleton();