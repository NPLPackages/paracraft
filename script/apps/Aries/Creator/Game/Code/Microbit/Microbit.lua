--[[
Title: Microbit
Author(s): leio
Date: 2021/4/28
Desc: blockly program for microbit, based on pxt-microbit api
use the lib:
-------------------------------------------------------
local Microbit = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Microbit/Microbit.lua");
Microbit.MakeBlocklyFiles();
-------------------------------------------------------
]]
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local Microbit = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.Microbit.Microbit", Microbit);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
Microbit.type =  "microbit";
Microbit.categories = {
    {name = "Basic", text = L"基础", colour = "#1e90ff", },
    {name = "Input", text = L"输入", colour = "#d400d4", },
    {name = "Music", text = L"音乐", colour = "#e63022", },
    {name = "Led", text = L"发光管", colour = "#5c2d91", },
    {name = "Radio", text = L"无线", colour = "#e3008c", },
    {name = "Loops", text = L"循环", colour = "#00aa00", },
    {name = "Logic", text = L"逻辑", colour = "#00aa00", },
    {name = "Variables", text = L"变量", colour = "#dc143c", custom="VARIABLE", },
    {name = "Math", text = L"数学", colour = "#9400d3", },
    
};

-- make files for blockly 
function Microbit.MakeBlocklyFiles()
    local categories = Microbit.GetCategoryButtons();
    local all_cmds = Microbit.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    CodeBlocklyHelper.SaveFiles("block_configs_microbit",categories,all_cmds);

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_microbit", "", "", 1); 
end
function Microbit.GetCategoryButtons()
    return Microbit.categories;
end
function Microbit.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

	local all_source_cmds = {
	NPL.load("(gl)./MicrobitDef/MicrobitDef_Basic.lua");
    NPL.load("(gl)./MicrobitDef/MicrobitDef_Input.lua");
    NPL.load("(gl)./MicrobitDef/MicrobitDef_Music.lua");
    NPL.load("(gl)./MicrobitDef/MicrobitDef_Led.lua");
    NPL.load("(gl)./MicrobitDef/MicrobitDef_Radio.lua");
    NPL.load("(gl)./MicrobitDef/MicrobitDef_Loops.lua");
    NPL.load("(gl)./MicrobitDef/MicrobitDef_Logic.lua");
    NPL.load("(gl)./MicrobitDef/MicrobitDef_Variables.lua");
    NPL.load("(gl)./MicrobitDef/MicrobitDef_Math.lua");
	}
	for k,v in ipairs(all_source_cmds) do
		Microbit.AppendDefinitions(v);
	end
end

function Microbit.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function Microbit.GetAllCmds()
	Microbit.AppendAll();
	return all_cmds;
end

function Microbit.InstallMethods(codeAPI, shape)
	
	for func_name, func in pairs(shape) do
		if(type(func_name) == "string" and type(func) == "function") then
			codeAPI[func_name] = function(...)
				return func(...);
			end
		end
	end
end
function Microbit.GetWebEditorUrl()
	local url = "https://makecode.microbit.org/#editor";
	return url;
end