--[[
Title: CodeCad
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCad.lua");
local CodeCad = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCad");
local categories = CodeCad.GetCategoryButtons();
local all_cmds = CodeCad.GetAllCmds()

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklySerializer.lua");
local CodeBlocklySerializer = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklySerializer");
CodeBlocklySerializer.OnInit(categories,all_cmds)
CodeBlocklySerializer.SaveFilesToDebug("block_configs_cad");

-------------------------------------------------------
]]
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local CodeCad = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.CodeCad.CodeCad", CodeCad);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
CodeCad.categories = {
    {name = "3DShapes", text = L"3D 图形", colour = "#0078d7", },
    {name = "2DShapes", text = L"2D 图形" , colour = "#7abb55", },
    {name = "Transforms", text = L"变形", colour = "#764bcc", },
    {name = "Ops", text = L"Set Ops", colour = "#69b090", },
    {name = "Control", text = L"控制", colour = "#d83b01", },
    {name = "Math", text = L"运算", colour = "#569138", },
    {name = "Data", text = L"数据", colour = "#459197", },
};
function CodeCad.GetCategoryButtons()
    return CodeCad.categories;
end
function CodeCad.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;
	
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_2DShapes.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_3DShapes.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Control.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Data.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Math.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Ops.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Transforms.lua");

    local CodeCadDef_2DShapes = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_2DShapes");
    local CodeCadDef_3DShapes = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_3DShapes");
    local CodeCadDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Control");
    local CodeCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Data");
    local CodeCadDef_Math = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Math");
    local CodeCadDef_Ops = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Ops");
    local CodeCadDef_Transforms = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Transforms");
	

	local all_source_cmds = {
		CodeCadDef_2DShapes.GetCmds(),
		CodeCadDef_3DShapes.GetCmds(),
		CodeCadDef_Control.GetCmds(),
		CodeCadDef_Data.GetCmds(),
		CodeCadDef_Math.GetCmds(),
		CodeCadDef_Ops.GetCmds(),
		CodeCadDef_Transforms.GetCmds(),
	}
	for k,v in ipairs(all_source_cmds) do
		CodeCad.AppendDefinitions(v);
	end
end

function CodeCad.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end
function CodeCad.GetAllCmds()
	CodeCad.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
function CodeCad.CompileCode(code, filename)
	local precode = format("log('NPL CAD begin code:%s')\n", filename or "unnamed")
	local endcode = "log('NPL CAD end code')\n"
	code = precode..(code or "")..endcode;
	return CodeCompiler:new():SetFilename(filename):Compile(code);
end

