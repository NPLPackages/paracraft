--[[
Title: CodeBlocklyHelper
Author(s): leio
Date: 2019/7/15
Desc: the help functions for reading/writing blockly information 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyGenerator.lua");
local CodeBlocklyGenerator = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyGenerator");

local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");

function CodeBlocklyHelper.SaveFiles(folder_name,categories,all_cmds)
    local code_generator = CodeBlocklyGenerator:new():OnInit(categories,all_cmds);
    folder_name = folder_name or "block_configs"
    NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Translation.lua");
    local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")
    local lang = Translation.GetCurrentLanguage();
    if(lang == "enUS")then
        -- menu xml
        CodeBlocklyHelper.WriteToFile(folder_name .. "/BlocklyMenu.xml",code_generator:GetBlocklyMenuXml());
        -- config
        CodeBlocklyHelper.WriteToFile(folder_name .. "/BlocklyConfigSource.json",code_generator:GetBlocklyConfig());
    else
        -- menu xml
        CodeBlocklyHelper.WriteToFile(folder_name .. "/BlocklyMenu-zh-cn.xml",code_generator:GetBlocklyMenuXml());
        -- config
        CodeBlocklyHelper.WriteToFile(folder_name .. "/BlocklyConfigSource-zh-cn.json",code_generator:GetBlocklyConfig());
        
    end
    CodeBlocklyHelper.WriteToFile(folder_name .. "/BlocklyExecution.js",code_generator:GetBlocklyCode());
    CodeBlocklyHelper.WriteToFile(folder_name .. "/LanguageKeywords.json.js",code_generator:GetKeywords());
end

function CodeBlocklyHelper.WriteToFile(filename,content)
    ParaIO.CreateDirectory(filename);
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(content);
		file:close();
	end
end