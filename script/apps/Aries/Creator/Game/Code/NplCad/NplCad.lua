--[[
Title: NplCad
Author(s): leio
Date: 2018/12/12
Desc: NplCad is a blockly program to create shapes with nploce on web browser
use the lib:
-------------------------------------------------------
local NplCad = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCad.lua");
NplCad.MakeBlocklyFiles();
-------------------------------------------------------
]]
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local NplCad = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.NplCad.NplCad", NplCad);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
NplCad.categories = {
    {name = "Shapes", text = L"图形", colour = "#764bcc", },
    {name = "ShapeOperators", text = L"修改", colour = "#0078d7", },
    {name = "ObjectName", text = L"名称", colour = "#ff8c1a", custom="VARIABLE", },
    {name = "Control", text = L"控制", colour = "#d83b01", },
    {name = "Math", text = L"运算", colour = "#569138", },
    {name = "Data", text = L"数据", colour = "#459197", },
};

-- make files for blockly 
function NplCad.MakeBlocklyFiles()
    local categories = NplCad.GetCategoryButtons();
    local all_cmds = NplCad.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklySerializer.lua");
    local CodeBlocklySerializer = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklySerializer");
    CodeBlocklySerializer.OnInit(categories,all_cmds)
    CodeBlocklySerializer.SaveFilesToDebug("block_configs_nplcad");

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_nplcad", "", "", 1); 
end
function NplCad.GetCategoryButtons()
    return NplCad.categories;
end
function NplCad.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_ShapeOperators.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Shapes.lua");
    local NplCadDef_ShapeOperators = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_ShapeOperators");
    local NplCadDef_Shapes = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Shapes");

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Control.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Data.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Math.lua");

    local NplCadDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Control");
    local NplCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Data");
    local NplCadDef_Math = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Math");
	

	local all_source_cmds = {
		NplCadDef_ShapeOperators.GetCmds(),
		NplCadDef_Shapes.GetCmds(),
		NplCadDef_Control.GetCmds(),
		NplCadDef_Data.GetCmds(),
		NplCadDef_Math.GetCmds(),
	}
	for k,v in ipairs(all_source_cmds) do
		NplCad.AppendDefinitions(v);
	end
end

function NplCad.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function NplCad.GetAllCmds()
	NplCad.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function NplCad.CompileCode(code, filename, codeblock)
    local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
    if(not NplOceConnection or not NplOceConnection.is_loaded)then
	    LOG.std(nil, "info", "NplCad", "load nploce failed");
        return
    end

    local block_name = codeblock:GetBlockName();
    if(not block_name or block_name == "")then
        block_name = "default"
    end
	local worldpath = ParaWorld.GetWorldDirectory();
	
    local filepath = format("%sblocktemplates/nplcad/%s.x",worldpath, commonlib.Encoding.Utf8ToDefault(block_name));
	code = NplCad.GetCode(code, filepath);
	return CodeCompiler:new():SetFilename(filename):Compile(code);
end

-- create short cut in code API, so that we can write cube() instead of ShapeBuilder.cube()
function NplCad.InstallMethods(codeAPI, shape)
	
	for func_name, func in pairs(shape) do
		if(type(func_name) == "string" and type(func) == "function") then
			codeAPI[func_name] = function(...)
				return func(...);
			end
		end
	end
end

function NplCad.RefreshFile(filename)
	if(filename and ParaIO.DoesFileExist(filename)) then
		local function filterFunc(shouldRefresh, fullname)
			if(shouldRefresh and filename:match("[^\\/]+$")==fullname:match("[^\\/]+$")) then
				LOG.std(nil, "debug", "NplCAD", "skip refresh disk file %s", fullname);
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



function NplCad.OpenDialog(filename)
    _guihelper.MessageBox(filename);
end
function NplCad.GetCode(code, filename)
    return string.format([[
local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");
local ShapeBuilder = NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.lua");
ShapeBuilder.create();
local NplCad = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCad.lua");
NplCad.InstallMethods(codeblock:GetCodeEnv(), ShapeBuilder)
%s
local result = SceneHelper.saveSceneToParaX(%q,ShapeBuilder.getScene());
if(result)then
	setActorValue("assetfile", %q)
    NplCad.RefreshFile(%q)
end
]], code, filename, filename, filename, filename)
end


