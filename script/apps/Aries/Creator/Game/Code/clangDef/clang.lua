--[[
Title: clang
Author(s): LiXizhi
Date: 2023/6/9
Desc: language configuration file for clang(c/c++) llvm (runtime in webview web assembly)
use the lib:
-------------------------------------------------------
local langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/clangDef/clang.lua");
-------------------------------------------------------
]]
local WasmClang = NPL.load("(gl)script/apps/Aries/Creator/Game/WasmClang/WasmClang.lua");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local clang = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.clang", clang);

local all_cmds = {}
local cmdsMap = {};
local default_categories = {
{name = "CommandIncludes", text = L"头文件", colour="#764bcc", },
};

local is_installed = false;
function clang.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;
	
	local all_source_cmds = {
		NPL.load("./clangDef_Includes.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		clang.AppendDefinitions(v);
	end
end

function clang.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			cmdsMap[v.type] = v;
			table.insert(all_cmds,v);
		end
	end
end
-- public:
function clang.GetCategoryButtons()
	return default_categories;
end

-- custom toolbar UI's mcml on top of the code block window. return nil for default UI. 
-- return nil or a mcml string. 
function clang.GetCustomToolbarMCML()
	clang.toolBarMcmlText = clang.toolBarMcmlText or string.format([[
    <div style="float:left;margin-left:5px;margin-top:7px;">
		<input type="button" value='<%%="%s"%%>' onclick="MyCompany.Aries.Game.Code.clang.OnClickLearn" style="min-width:80px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
    </div>
]], L"学习");
	return clang.toolBarMcmlText;
end

function clang.OnClickLearn()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/docs/tutorials/codelab", "", "", 1);
end

-- public:
function clang.GetAllCmds()
	clang.AppendAll();
	return all_cmds;
end

-- custom compiler here: 
-- @param codeblock: code block object here
function clang.CompileCode(code, filename, codeblock)
    local block_name = codeblock:GetBlockName();
    clang.OneTimeInit();
	code = clang.GetCode(code, filename);
	local compiler = CodeCompiler:new():SetFilename(filename)
	compiler:SetAllowFastMode(true);
	return compiler:Compile(code);
end

function clang.OneTimeInit()
	if(clang.inited) then
		return
	end
	clang.inited = true;
	WasmClang:Connect("LogReceived", clang, clang.OnReceiveLog, "UniqueConnection")
end

function clang:OnReceiveLog(text)
	log(text);
	GameLogic.GetCodeGlobal():logAdded(text);
	GameLogic.AppendChat(text);
end

-- @param code: text of code string
function clang.GetCode(code, filename)
	local text = string.format('local WasmClang = NPL.load("(gl)script/apps/Aries/Creator/Game/WasmClang/WasmClang.lua");WasmClang:Start(function() WasmClang:CompileLinkRun([[%s]]); end);', code)
	return text;
end