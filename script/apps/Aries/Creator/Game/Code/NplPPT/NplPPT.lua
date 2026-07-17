--[[
Title: NplPPT
Author(s): LiXizhi
Date: 2018/6/7
Desc: language configuration file for NplPPT
use the lib:
-------------------------------------------------------
local langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/NplPPT.lua");
langConfig.MakeBlocklyFiles()
-------------------------------------------------------
]]
local NplPPT = NPL.export();

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
function NplPPT.MakeBlocklyFiles()
    -- local categories = NplPPT.GetCategoryButtons();
    -- local all_cmds = NplPPT.GetAllCmds()

    -- NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    -- local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    -- CodeBlocklyHelper.SaveFiles("block_configs_paracraft",categories,all_cmds);

    -- _guihelper.MessageBox("making blockly files finished");
	-- ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_paracraft", "", "", 1); 
end

local is_installed = false;
function NplPPT.AppendAll()
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
		NplPPT.AppendDefinitions(v);
	end
	GameLogic.GetFilters():apply_filters("NplPPTAppendDefinitions",NplPPT);
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

function NplPPT.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function NplPPT.GetItemByType(typeName)
	return all_cmds_map[typeName];
end

-- public:
function NplPPT.GetCategoryButtons()
	default_categories = GameLogic.GetFilters():apply_filters("NplPPTCategories",default_categories);
	return default_categories;
end

-- public:
function NplPPT.GetAllCmds()
	NplPPT.AppendAll();
	return all_cmds;
end

-- public: optional
function NplPPT.GetCodeExamples()
	return all_examples;
end

function NplPPT.OpenPPTPage()
	local code = NplPPT.code or ""
	local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
	local course_name = "ppt_test"
	local disk_folder = RedSummerCampPPtPage.GetPPTConfigDiskFolder()
	local filename =  "ppt_test.xml"
	local file_path = string.format("%s/%s/%s", disk_folder, course_name, filename)
	if not ParaIO.DoesFileExist(file_path, true) then
		ParaIO.CreateDirectory(file_path)
	end

	local file = ParaIO.open(file_path, "w");
	if(file) then
		file:write(code, #code);
		file:close();
	end
	
	local data = {
		auth = true,
		code=course_name,
		id=26,
		md5=course_name,
		name="初中校园课(HX1)",
		url="" 
	}

	if RedSummerCampPPtPage.PPtCacheData and RedSummerCampPPtPage.PPtCacheData[course_name] then
		RedSummerCampPPtPage.PPtCacheData[course_name] = nil
	end
	RedSummerCampPPtPage.SetIsInDebug(true)
	RedSummerCampPPtPage.Show(data);
end

function NplPPT.CompileCode(code, filename, codeblock)
	NplPPT.code = code
	return NplPPT.OpenPPTPage
end

function NplPPT.GetCustomCodeUIUrl()
	return "script/apps/Aries/Creator/Game/Code/NplPPT/CodeBlockWindowPPT.html"
end

function NplPPT.OnCloseCodeEditor()
	local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
	RedSummerCampPPtPage.CloseInDebug()
	RedSummerCampPPtPage.SetDefaulIndex(nil)
end