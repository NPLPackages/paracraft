--[[
Title: BlockCad
Author(s): leio
Date: 2018/12/12
Desc: BlockCad is a blockly program to create shapes with nploce on web browser
use the lib:
-------------------------------------------------------
local BlockCad = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockCad/BlockCad.lua");
local categories = BlockCad.GetCategoryButtons();
local all_cmds = BlockCad.GetAllCmds()

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklySerializer.lua");
local CodeBlocklySerializer = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklySerializer");
CodeBlocklySerializer.OnInit(categories,all_cmds)
CodeBlocklySerializer.SaveFilesToDebug("block_configs_blockcad");
-------------------------------------------------------
]]
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local BlockCad = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.BlockCad.BlockCad", BlockCad);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
BlockCad.categories = {
    {name = "ShapeOperators", text = L"操作", colour = "#0078d7", },
    {name = "Shapes", text = L"图形", colour = "#764bcc", },
    {name = "Control", text = L"控制", colour = "#d83b01", },
    {name = "Math", text = L"运算", colour = "#569138", },
    {name = "Data", text = L"数据", colour = "#459197", },
};

function BlockCad.GetCategoryButtons()
    return BlockCad.categories;
end
function BlockCad.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockCad/BlockCadDef/BlockCadDef_ShapeOperators.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockCad/BlockCadDef/BlockCadDef_Shapes.lua");
    local BlockCadDef_ShapeOperators = commonlib.gettable("MyCompany.Aries.Game.Code.BlockCad.BlockCadDef_ShapeOperators");
    local BlockCadDef_Shapes = commonlib.gettable("MyCompany.Aries.Game.Code.BlockCad.BlockCadDef_Shapes");

    -- Using CodeCad definitions temporarily
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Control.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Data.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Math.lua");

    local CodeCadDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Control");
    local CodeCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Data");
    local CodeCadDef_Math = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Math");
	

	local all_source_cmds = {
		BlockCadDef_ShapeOperators.GetCmds(),
		BlockCadDef_Shapes.GetCmds(),
		CodeCadDef_Control.GetCmds(),
		CodeCadDef_Data.GetCmds(),
		CodeCadDef_Math.GetCmds(),
	}
	for k,v in ipairs(all_source_cmds) do
		BlockCad.AppendDefinitions(v);
	end
end

function BlockCad.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function BlockCad.GetAllCmds()
	BlockCad.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function BlockCad.CompileCode(code, filename, codeblock)
    local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
    if(not NplOceConnection or not NplOceConnection.is_loaded)then
        return
    end

    local block_name = codeblock:GetBlockName();
    if(not block_name or block_name == "")then
        block_name = "default"
    end
	local worldpath = ParaWorld.GetWorldDirectory();
    local name = format("%sblocktemplates/blockcad/%s.x",worldpath,block_name);
    code = BlockCad.GetCode(code, name);
	return CodeCompiler:new():SetFilename(filename):Compile(code);
end

-- create short cut in code API, so that we can write cube() instead of ShapeBuilder.cube()
function BlockCad.InstallMethods(codeAPI, shape)
	codeAPI.cube = function(...)
		shape.cube(...) 
	end
	-- Remove this: extract all methods like below
	for func_name, func in pairs(shape) do
		if(type(func_name) == "string" and type(func) == "function") then
			codeAPI[func_name] = function(...)
				return func(...);
			end
		end
	end
end

function BlockCad.GetCode(code, filename)
    return format([[
        local NplOceScene = NPL.load("Mod/NplCad2/NplOceScene.lua");
        local ShapeBuilder = NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.lua");
        ShapeBuilder.create();
		local BlockCad = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockCad/BlockCad.lua");
		BlockCad.InstallMethods(codeblock:GetCodeEnv(), ShapeBuilder)
        %s
        NplOceScene.saveSceneToParaX("%s",ShapeBuilder.getScene());
    ]],code, filename)
end


