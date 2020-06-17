--[[
Title: Teacher Block 
Author(s): chenjinxian
Date: 2020/6/1
Desc: 
use the lib:
-------------------------------------------------------
local TeacherBlockly = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TeacherBlocklyDef/TeacherBlockly.lua");
-------------------------------------------------------
]]
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local TeacherBlockly = NPL.export();

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
TeacherBlockly.categories = {
	{name = "npc", text = "NPC", colour = "#0078d7", },
};

function TeacherBlockly.GetCategoryButtons()
	return TeacherBlockly.categories;
end

function TeacherBlockly.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

	local all_source_cmds = {
		NPL.load("./TeacherBlocklyDef.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		TeacherBlockly.AppendDefinitions(v);
	end
end

function TeacherBlockly.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function TeacherBlockly.GetAllCmds()
	TeacherBlockly.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function TeacherBlockly.CompileCode(code, filename, codeblock)
	code = TeacherBlockly.GetCode(code);

	local compiler = CodeCompiler:new():SetFilename(filename)
	if(codeblock and codeblock:GetEntity() and codeblock:GetEntity():IsAllowFastMode()) then
		compiler:SetAllowFastMode(true);
	end
	return compiler:Compile(code);
end

-- @param relativePath: can be nil, in which case filepath will be used. 
function TeacherBlockly.GetCode(code)
	if(not TeacherBlockly.templateCode) then
		TeacherBlockly.templateCode = [[
local TeacherBlockly = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TeacherBlocklyDef/TeacherBlockly.lua");
local TeacherBlocklyAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TeacherBlocklyDef/TeacherBlocklyAPI.lua");
local api = TeacherBlocklyAPI:new():Init(codeblock:GetCodeEnv())
<code>
]]
		TeacherBlockly.templateCode = TeacherBlockly.templateCode:gsub("(\r?\n)", ""):gsub("<code>", "%%s")
	end
	local s = string.format(TeacherBlockly.templateCode, code or "");
	return s
end

function TeacherBlockly.OnClickLearn()
	--ParaGlobal.ShellExecute("open", L"https://keepwork.com/pbl/project/852/", "", "", 1);
end