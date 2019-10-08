--[[
Title: Craft2d
Author(s): leio
Date: 2019/10/4
Desc: Craft2d is a blockly program to control 2d game
use the lib:
-------------------------------------------------------
local Craft2d = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Craft2d/Craft2d.lua");
Craft2d.MakeBlocklyFiles();
-------------------------------------------------------
]]
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local Craft2d = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.Craft2d.Craft2d", Craft2d);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
Craft2d.categories = {
    {name = "Craft2d.Motion", text = L"运动", colour = "#0078d7", },
    {name = "Craft2d.Control", text = L"控制", colour = "#d83b01", },
};

-- make files for blockly 
function Craft2d.MakeBlocklyFiles()
    local categories = Craft2d.GetCategoryButtons();
    local all_cmds = Craft2d.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    CodeBlocklyHelper.SaveFiles("block_configs_nplmicrobit",categories,all_cmds);

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_nplmicrobit", "", "", 1); 
end
function Craft2d.GetCategoryButtons()
    return Craft2d.categories;
end
function Craft2d.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Craft2d/Craft2dDef/Craft2dDef_Motion.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Craft2d/Craft2dDef/Craft2dDef_Control.lua");

    local Craft2dDef_Motion = commonlib.gettable("MyCompany.Aries.Game.Code.Craft2d.Craft2dDef_Motion");
    local Craft2dDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.Craft2d.Craft2dDef_Control");
	

	local all_source_cmds = {
		Craft2dDef_Motion.GetCmds(),
		Craft2dDef_Control.GetCmds(),
	}
	for k,v in ipairs(all_source_cmds) do
		Craft2d.AppendDefinitions(v);
	end
end

function Craft2d.OnSelect()
    if(CodeBlockWindow.GetSceneContext and CodeBlockWindow:GetSceneContext())then
        CodeBlockWindow:GetSceneContext():SetShowBones(true);
    end
end

function Craft2d.OnDeselect()
    if(CodeBlockWindow.GetSceneContext and CodeBlockWindow:GetSceneContext())then
        CodeBlockWindow:GetSceneContext():SetShowBones(false);
    end
end

function Craft2d.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function Craft2d.GetAllCmds()
	Craft2d.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function Craft2d.CompileCode(code, filename, codeblock)
    local NplOceConnection = NPL.load("Mod/Craft2d2/NplOceConnection.lua");
    if(not NplOceConnection or not NplOceConnection.is_loaded)then
	    LOG.std(nil, "info", "Craft2d", "load nploce failed");
        return
    end

    local block_name = codeblock:GetBlockName();
    if(not block_name or block_name == "")then
        block_name = "default"
    end
	local worldpath = ParaWorld.GetWorldDirectory();
	
    local filepath = format("%sblocktemplates/nplmicrobit/%s.x",worldpath, commonlib.Encoding.Utf8ToDefault(block_name));
	code = Craft2d.GetCode(code, filepath);
	return CodeCompiler:new():SetFilename(filename):Compile(code);
end

-- create short cut in code API, so that we can write cube() instead of ShapeBuilder.cube()
function Craft2d.InstallMethods(codeAPI, shape)
	
	for func_name, func in pairs(shape) do
		if(type(func_name) == "string" and type(func) == "function") then
			codeAPI[func_name] = function(...)
				return func(...);
			end
		end
	end
end

function Craft2d.RefreshFile(filename)
	if(filename and ParaIO.DoesFileExist(filename)) then
		local function filterFunc(shouldRefresh, fullname)
			if(shouldRefresh and filename:match("[^\\/]+$")==fullname:match("[^\\/]+$")) then
				LOG.std(nil, "debug", "Craft2d", "skip refresh disk file %s", fullname);
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



function Craft2d.OpenDialog(filename)
    _guihelper.MessageBox(filename);
end
function Craft2d.GetCode(code, filename)
    return string.format([[

]], code, filename, filename, filename, filename)
end


