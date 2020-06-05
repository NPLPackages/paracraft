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
	elseif(filename == "mcml" or filename == "html") then
		langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/McmlBlocklyDef/McmlBlockly.lua");
    elseif(filename == "npl_micro_robot") then
		langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobot.lua");
	elseif(filename == "npl_blockpen") then
		langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockPenDef/BlockPen.lua");
	elseif(filename == "haqi") then
		langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/HaqiDef/Haqi.lua");
	elseif(filename == "commands") then
		langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CommandsDef/CommandsBlockly.lua");
	elseif(filename == "npl_teacher") then
		langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TeacherBlocklyDef/TeacherBlockly.lua");
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
	return filename == "" or filename=="npl" or filename=="npl_cad" or filename=="npl_micro_robot"  or filename=="npl_blockpen" or filename=="npl_teacher"
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

-- custom toolbar UI's mcml on top of the code block window. return nil for default UI. 
-- return nil or a mcml string. 
function LanguageConfigurations:GetCustomToolbarMCML(filename)
	local config = self:GetConfig(filename)
	if(config and config.GetCustomToolbarMCML) then
		return config:GetCustomToolbarMCML();
	end
end

LanguageConfigurations:InitSingleton();