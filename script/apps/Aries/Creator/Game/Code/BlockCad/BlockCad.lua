--[[
Title: BlockCad
Author(s): leio
Date: 2018/12/12
Desc: BlockCad is a blockly program to create shapes with nploce on web browser
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockCad/BlockCad.lua");
local BlockCad = commonlib.gettable("MyCompany.Aries.Game.Code.BlockCad.BlockCad");
local categories = BlockCad.GetCategoryButtons();
local all_cmds = BlockCad.GetAllCmds()

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklySerializer.lua");
local CodeBlocklySerializer = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklySerializer");
CodeBlocklySerializer.OnInit(categories,all_cmds)
CodeBlocklySerializer.SaveFilesToDebug("block_configs_blockcad");

-------------------------------------------------------
]]
local BlockCad = commonlib.gettable("MyCompany.Aries.Game.Code.BlockCad.BlockCad");

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
BlockCad.categories = {
    {name = "Shapes", text = L"图形", colour = "#0078d7", },
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
	
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockCad/BlockCadDef/BlockCadDef_Shapes.lua");
    local BlockCadDef_Shapes = commonlib.gettable("MyCompany.Aries.Game.Code.BlockCad.BlockCadDef_Shapes");

    -- Using CodeCad definitions temporarily
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Control.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Data.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCad/CodeCadDef/CodeCadDef_Math.lua");

    local CodeCadDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Control");
    local CodeCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Data");
    local CodeCadDef_Math = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCad.CodeCadDef_Math");
	

	local all_source_cmds = {
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

