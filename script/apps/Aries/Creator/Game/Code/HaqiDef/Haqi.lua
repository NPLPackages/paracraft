--[[
Title: Haqi
Author(s): LiXizhi
Date: 2020/4/7
Desc: Haqi Code block
use the lib:
-------------------------------------------------------
local Haqi = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/HaqiDef/Haqi.lua");
-------------------------------------------------------
]]
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local Haqi = NPL.export();

commonlib.setfield("MyCompany.Aries.Game.Code.Haqi.Haqi", Haqi);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
Haqi.categories = {
    {name = "arena", text = "法阵", colour = "#0078d7", },
	{name = "Control", text = L"控制", colour="#d83b01", },
	{name = "Data", text = L"数据", colour="#459197", },
};

function Haqi.GetCategoryButtons()
    return Haqi.categories;
end

function Haqi.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

	local all_source_cmds = {
		NPL.load("./HaqiDef_Arena.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		Haqi.AppendDefinitions(v);
	end
end

function Haqi.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function Haqi.GetAllCmds()
	Haqi.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function Haqi.CompileCode(code, filename, codeblock)
    code = Haqi.GetCode(code);

	local compiler = CodeCompiler:new():SetFilename(filename)
	if(codeblock and codeblock:GetEntity() and codeblock:GetEntity():IsAllowFastMode()) then
		compiler:SetAllowFastMode(true);
	end
	return compiler:Compile(code);
end

-- @param relativePath: can be nil, in which case filepath will be used. 
function Haqi.GetCode(code)
	if(not Haqi.templateCode) then
		Haqi.templateCode = [[
local Haqi = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/HaqiDef/Haqi.lua")
local HaqiAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/HaqiDef/HaqiAPI.lua")
local api = HaqiAPI:new():Init(codeblock:GetCodeEnv())
hide()

<code>
if(isArenaModified()) then
	wait(1)
	restart()
	api:addIncludeFiles();
end
]]
		Haqi.templateCode = Haqi.templateCode:gsub("(\r?\n)", ""):gsub("<code>", "%%s")
	end
    local s = string.format(Haqi.templateCode, code or "");
    return s
end

function Haqi.OnClickLearn()
	-- ParaGlobal.ShellExecute("open", L"https://keepwork.com/pbl/project/852/", "", "", 1);
end

function Haqi.OnClickRestartServer()
	local HaqiAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/HaqiDef/HaqiAPI.lua");
	HaqiAPI.restart();
end

-- custom toolbar UI's mcml on top of the code block window. return nil for default UI. 
-- return nil or a mcml string. 
function Haqi.GetCustomToolbarMCML()
	Haqi.toolBarMcmlText = Haqi.toolBarMcmlText or string.format([[
<div style="float:left;margin-left:5px;margin-top:7px;">
	<input type="button" value='%s'  tooltip='%s' name='restart' onclick="MyCompany.Aries.Game.Code.CodeBlockWindow.OnChangeModel" style="margin-top:0px;background:url(Texture/whitedot.png);background-color:#808080;color:#ffffff;height:25px;min-width:20px;" />
</div>
]], L"角色模型", L"也可以通过电影方块编辑");
	return Haqi.toolBarMcmlText;
end