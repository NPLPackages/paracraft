--[[
Title: ParacraftCodeBlockly
Author(s): LiXizhi
Date: 2018/6/7
Desc: language configuration file for ParacraftCodeBlockly
use the lib:
-------------------------------------------------------
local langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/ParacraftCodeBlockly.lua");
langConfig.MakeBlocklyFiles()
-------------------------------------------------------
]]
local ParacraftCodeBlockly = NPL.export();

local all_cmds = {}
local all_cmds_map = {}

local default_categories = {
{name = "Motion", text = L"运动", colour="#0078d7", },
{name = "Looks", text = L"外观" , colour="#7abb55", },
{name = "Events", text = L"事件", colour="#764bcc", },
{name = "Control", text = L"控制", colour="#d83b01", },
{name = "Sound", text = L"声音", colour="#8f6d40", },
{name = "Sensing", text = L"感知", colour="#69b090", },
{name = "Operators", text = L"运算", colour="#569138", },
{name = "Data", text = L"数据", colour="#459197", },
};

-- make files for blockly 
function ParacraftCodeBlockly.MakeBlocklyFiles()
    local categories = ParacraftCodeBlockly.GetCategoryButtons();
    local all_cmds = ParacraftCodeBlockly.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    CodeBlocklyHelper.SaveFiles("block_configs_paracraft",categories,all_cmds);

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_paracraft", "", "", 1); 
end

local is_installed = false;
function ParacraftCodeBlockly.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Control.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Data.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Events.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Looks.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Motion.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Operators.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Sensing.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Sound.lua");

	local CodeBlocklyDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Control");
	local CodeBlocklyDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Data");
	local CodeBlocklyDef_Events = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Events");
	local CodeBlocklyDef_Looks = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Looks");
	local CodeBlocklyDef_Motion = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Motion");
	local CodeBlocklyDef_Operators = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Operators");
	local CodeBlocklyDef_Sensing = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Sensing");
	local CodeBlocklyDef_Sound = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Sound");

	local all_source_cmds = {
		CodeBlocklyDef_Control.GetCmds(),
		CodeBlocklyDef_Data.GetCmds(),
		CodeBlocklyDef_Events.GetCmds(),
		CodeBlocklyDef_Looks.GetCmds(),
		CodeBlocklyDef_Motion.GetCmds(),
		CodeBlocklyDef_Operators.GetCmds(),
		CodeBlocklyDef_Sensing.GetCmds(),
		CodeBlocklyDef_Sound.GetCmds(),
	}
	for k,v in ipairs(all_source_cmds) do
		ParacraftCodeBlockly.AppendDefinitions(v);
	end
	GameLogic.GetFilters():apply_filters("ParacraftCodeBlocklyAppendDefinitions",ParacraftCodeBlockly);
end

-- all shared extended examples. 
local all_examples = {
{
	desc = L"点击我打招呼", 
	references = {"say", "sayAndWait", "turn", "play"}, 
	canRun = false,
	code = [[
say("Click Me!", 2)
registerClickEvent(function()
    turn(15)
    play(0,1000)
    say("hi!")
end)
]]},
{
	desc = L"显示/隐藏角色", 
	references = {"show", "hide",}, 
	canRun = true,
	code = [[
hide()
wait(1)
show()
]]},
}

function ParacraftCodeBlockly.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function ParacraftCodeBlockly.GetItemByType(typeName)
	return all_cmds_map[typeName];
end

-- public:
function ParacraftCodeBlockly.GetCategoryButtons()
	default_categories = GameLogic.GetFilters():apply_filters("ParacraftCodeBlocklyCategories",default_categories);
	return default_categories;
end

-- public:
function ParacraftCodeBlockly.GetAllCmds()
	ParacraftCodeBlockly.AppendAll();
	return all_cmds;
end

-- public: optional
function ParacraftCodeBlockly.GetCodeExamples()
	return all_examples;
end

function ParacraftCodeBlockly.CompileCode(code, filename, codeblock)
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
		local code_env = codeblock:GetCodeEnv()
		py_env['_set_codeblock_env'](code_env)
        pyruntime:installMethods(code_env, py_env);
        
		-- synchronous
        local error, luacode = pyruntime:transpile(code)

		if error then
			local error_msg = luacode
			return nil, luacode
		end

		codeblock:SetModified(true)
        return compiler:Compile(luacode);
    else
	    return compiler:Compile(code);
    end
end
