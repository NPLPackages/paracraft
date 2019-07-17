--[[
Title: NplMicrobit
Author(s): leio
Date: 2018/12/12
Desc: NplMicrobit is a blockly program to control microbit
use the lib:
-------------------------------------------------------
local NplMicrobit = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobit.lua");
NplMicrobit.MakeBlocklyFiles();
-------------------------------------------------------
]]
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local NplMicrobit = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobit", NplMicrobit);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
NplMicrobit.categories = {
    {name = "Body", text = L"躯干", colour = "#764bcc", },
    {name = "Control", text = L"控制", colour = "#d83b01", },
};

-- make files for blockly 
function NplMicrobit.MakeBlocklyFiles()
    local categories = NplMicrobit.GetCategoryButtons();
    local all_cmds = NplMicrobit.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    CodeBlocklyHelper.SaveFiles("block_configs_nplmicrobit",categories,all_cmds);

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_nplmicrobit", "", "", 1); 
end
function NplMicrobit.GetCategoryButtons()
    return NplMicrobit.categories;
end
function NplMicrobit.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Body.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Control.lua");

    local NplMicrobitDef_Body = commonlib.gettable("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobitDef_Body");
    local NplMicrobitDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobitDef_Control");
	

	local all_source_cmds = {
		NplMicrobitDef_Body.GetCmds(),
		NplMicrobitDef_Control.GetCmds(),
	}
	for k,v in ipairs(all_source_cmds) do
		NplMicrobit.AppendDefinitions(v);
	end
end

function NplMicrobit.OnSelect()
    if(CodeBlockWindow.GetSceneContext and CodeBlockWindow:GetSceneContext())then
        CodeBlockWindow:GetSceneContext():SetShowBones(true);
    end
end

function NplMicrobit.OnDeselect()
    if(CodeBlockWindow.GetSceneContext and CodeBlockWindow:GetSceneContext())then
        CodeBlockWindow:GetSceneContext():SetShowBones(false);
    end
end

function NplMicrobit.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function NplMicrobit.GetAllCmds()
	NplMicrobit.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function NplMicrobit.CompileCode(code, filename, codeblock)
    local NplOceConnection = NPL.load("Mod/NplMicrobit2/NplOceConnection.lua");
    if(not NplOceConnection or not NplOceConnection.is_loaded)then
	    LOG.std(nil, "info", "NplMicrobit", "load nploce failed");
        return
    end

    local block_name = codeblock:GetBlockName();
    if(not block_name or block_name == "")then
        block_name = "default"
    end
	local worldpath = ParaWorld.GetWorldDirectory();
	
    local filepath = format("%sblocktemplates/nplmicrobit/%s.x",worldpath, commonlib.Encoding.Utf8ToDefault(block_name));
	code = NplMicrobit.GetCode(code, filepath);
	return CodeCompiler:new():SetFilename(filename):Compile(code);
end

-- create short cut in code API, so that we can write cube() instead of ShapeBuilder.cube()
function NplMicrobit.InstallMethods(codeAPI, shape)
	
	for func_name, func in pairs(shape) do
		if(type(func_name) == "string" and type(func) == "function") then
			codeAPI[func_name] = function(...)
				return func(...);
			end
		end
	end
end

function NplMicrobit.RefreshFile(filename)
	if(filename and ParaIO.DoesFileExist(filename)) then
		local function filterFunc(shouldRefresh, fullname)
			if(shouldRefresh and filename:match("[^\\/]+$")==fullname:match("[^\\/]+$")) then
				LOG.std(nil, "debug", "NplMicrobit", "skip refresh disk file %s", fullname);
				return false
			else
				return shouldRefresh;
			end
		end
		GameLogic.GetFilters():add_filter("shouldRefreshWorldFile", filterFunc);
		ParaAsset.LoadParaX("", filename):UnloadAsset()
		commonlib.TimerManager.SetTimeout(function()  
			GameLogic.GetFilters():remove_filter("shouldRefreshWorldFile", filterFunc);	
		end, 5000)
	end
end



function NplMicrobit.OpenDialog(filename)
    _guihelper.MessageBox(filename);
end
function NplMicrobit.GetCode(code, filename)
    return string.format([[

]], code, filename, filename, filename, filename)
end


