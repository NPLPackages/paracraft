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
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local NplMicrobit = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.NplMicrobit.NplMicrobit", NplMicrobit);

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Microbit.lua");

local s_env_methods = {
    
}

local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
NplMicrobit.categories = {
    {name = "NplMicrobit.Animation", text = L"动画", colour = "#717171", },
    {name = "NplMicrobit.Motion", text = L"运动", colour = "#0078d7", },
    {name = "NplMicrobit.Looks", text = L"显示", colour = "#7abb55", },
    {name = "NplMicrobit.Events", text = L"事件", colour="#764bcc", },
    {name = "NplMicrobit.Control", text = L"控制", colour = "#d83b01", },
    {name = "NplMicrobit.Sensing", text = L"感知", colour="#69b090", },
    {name = "NplMicrobit.Operators", text = L"运算", colour = "#569138", },
    {name = "NplMicrobit.Data", text = L"数据", colour="#459197", },
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

	local all_source_cmds = {
        NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Animation.lua");
        NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Motion.lua");
        NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Looks.lua");
        NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Events.lua");
        NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Control.lua");
        NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Sensing.lua");
        NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Operators.lua");
        NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitDef/NplMicrobitDef_Data.lua");
	}
	for k,v in ipairs(all_source_cmds) do
		NplMicrobit.AppendDefinitions(v);
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

-- custom toolbar UI's mcml on top of the code block window. return nil for default UI. 
-- return nil or a mcml string. 
function NplMicrobit.GetCustomToolbarMCML()
	NplMicrobit.toolBarMcmlText = NplMicrobit.toolBarMcmlText or string.format([[
    <div style="float:left;margin-left:5px;margin-top:7px;"
            tooltip='page://script/apps/Aries/Creator/Game/Code/NplMicrobit/NplMicrobitToolMenus.html' use_mouse_offset="false" is_lock_position="true" tooltip_offset_x="-5" tooltip_offset_y="22" show_duration="10" enable_tooltip_hover="true" tooltip_is_interactive="true" show_height="200" show_width="230">
        <div style="background-color:#808080;color:#ffffff;padding:3px;font-size:12px;height:25px;min-width:20px;">%s</div>
    </div>
]],
		L"导出");
	return NplMicrobit.toolBarMcmlText;
end
function NplMicrobit.GetCodesFromBlockWindow()
    local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock) then
        local entity = codeBlock:GetEntity();
        if(entity)then
            local codes;
            if(entity:IsBlocklyEditMode())then
                codes = entity:GetBlocklyNPLCode();
            else
                codes = entity:GetNPLCode();
            end
            return codes;
        end
	end
end
function NplMicrobit.OnClickExport(type)
    local codeBlock = CodeBlockWindow.GetCodeBlock();
    local block_name = codeBlock:GetBlockName();
    if(not block_name or block_name == "")then
        block_name = "default"
    end

	local relativePath = format("blocktemplates/nplrobot/%s",commonlib.Encoding.Utf8ToDefault(block_name));
    local filename = GameLogic.GetWorldDirectory()..relativePath;

    local codes = NplMicrobit.GetCodesFromBlockWindow()
    NplMicrobit.ExportToFile(filename,type,codes)
end
function NplMicrobit.ExportToFile(filename,type,codes)
    if(not type or not filename)then
        return
    end
    local NplRobotHelper = NPL.load("(gl)Mod/NplRobot/NplRobotHelper.lua");
    if(type == "hex")then
        -- save to hex
        local hex_text = NplRobotHelper.CombineHex(codes);
        filename = filename .. ".hex"
        NplRobotHelper.WriteFile(filename,hex_text);
        NplMicrobit.ShowMessageBox(filename)
    elseif(type == "full_python")then
        -- save to python 
        filename = filename .. ".py"
        local py_text = NplRobotHelper.CombineScripts(codes);
        NplRobotHelper.WriteFile(filename,py_text);
        NplMicrobit.ShowMessageBox(filename)
    end
end

function NplMicrobit.ShowMessageBox(filename)
    _guihelper.MessageBox(string.format(L"成功导出:%s, 是否打开所在目录", commonlib.Encoding.DefaultToUtf8(filename)), function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			local info = Files.ResolveFilePath(filename)
			if(info and info.relativeToRootPath) then
				local absPath = ParaIO.GetCurDirectory(0)..info.relativeToRootPath;
				local absPathFolder = absPath:gsub("[^/\\]+$", "")
				ParaGlobal.ShellExecute("open", absPathFolder, "", "", 1);
			end
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function NplMicrobit.CompileCode(code, filename, codeblock)
    local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
    local entity = codeblock:GetEntity();
    local compiler = CodeCompiler:new():SetFilename(filename)
	if(codeblock and entity and entity:IsAllowFastMode()) then
		compiler:SetAllowFastMode(true);
	end
    local codeLanguageType;
    if(entity.GetCodeLanguageType)then
        codeLanguageType = entity:GetCodeLanguageType();
    end
    if(codeLanguageType == "python")then
        local pyruntime = NPL.load("Mod/PyRuntime/Transpiler.lua")
		if(not ParacraftCodeBlockly.isPythonRuntimeLoaded) then
			ParacraftCodeBlockly.isPythonRuntimeLoaded = true;
			pyruntime:start()
		end
        local py_env, env_error_msg = NPL.load("Mod/PyRuntime/py2npl/polyfill.lua")
        pyruntime:installMethods(codeblock:GetCodeEnv(),py_env);
        -- this callback is synchronous 
        pyruntime:transpile(code, function(res)
            local lua_code = res.lua_code;
            if(not lua_code)then
                local error_msg = res.error_msg;
	            LOG.std(nil, "error", "CodePyToNplPage", error_msg);
                code = "";
                return
            end
            code = lua_code;
        end)
		codeblock:SetModified(true);
        return  compiler:Compile(code);
    else
	    return compiler:Compile(code);
    end
end