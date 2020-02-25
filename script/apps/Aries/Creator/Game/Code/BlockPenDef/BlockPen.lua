--[[
Title: Block Pen
Author(s): LiXizhi
Date: 2020/2/16
Desc: This is from the ArtWork project (id: 852). I have turned that project into a built-in module
use the lib:
-------------------------------------------------------
local BlockPen = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockPenDef/BlockPen.lua");
-------------------------------------------------------
]]
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local BlockPen = NPL.export();

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
BlockPen.categories = {
    {name = "painter", text = "绘图", colour = "#0078d7", },
	{name = "canvas", text = "画板", colour = "#ff0000", },
	{name = "Control", text = L"控制", colour="#d83b01", },
	{name = "Operators", text = L"运算", colour="#569138", },
    {name = "Data", text = L"数据", colour="#459197", },
};

function BlockPen.GetCategoryButtons()
    return BlockPen.categories;
end

function BlockPen.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

	local all_source_cmds = {
		NPL.load("./BlockPenDef_Painter.lua"),
		NPL.load("./BlockPenDef_Common.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		BlockPen.AppendDefinitions(v);
	end
end

function BlockPen.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function BlockPen.GetAllCmds()
	BlockPen.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function BlockPen.CompileCode(code, filename, codeblock)
    code = BlockPen.GetCode(code);

	local compiler = CodeCompiler:new():SetFilename(filename)
	if(codeblock and codeblock:GetEntity() and codeblock:GetEntity():IsAllowFastMode()) then
		compiler:SetAllowFastMode(true);
	end
	return compiler:Compile(code);
end

-- @param relativePath: can be nil, in which case filepath will be used. 
function BlockPen.GetCode(code)
	if(not BlockPen.templateCode) then
		BlockPen.templateCode = [[
local BlockPen = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockPenDef/BlockPen.lua");
local BlockPenAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockPenDef/BlockPenAPI.lua");
local api = BlockPenAPI:new():Init(codeblock:GetCodeEnv())
<code>
]]
		BlockPen.templateCode = BlockPen.templateCode:gsub("(\r?\n)", ""):gsub("<code>", "%%s")
	end
    local s = string.format(BlockPen.templateCode, code or "");
    return s
end

function BlockPen.OnClickLearn()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/pbl/project/852/", "", "", 1);
end