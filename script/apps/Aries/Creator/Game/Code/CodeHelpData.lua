--[[
Title: CodeHelpData
Author(s): LiXizhi
Date: 2018/6/7
Desc: add help data here
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpData.lua");
local CodeHelpData = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpData");
CodeHelpData.LoadParacraftCodeFunctions()
-------------------------------------------------------
]]
local CodeHelpData = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpData");

local all_cmds = {}

function CodeHelpData.AppendAll()
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
		CodeHelpData.AppendDefinitions(v);
	end
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

local is_installed = false;
function CodeHelpData.AppendDefinitions(source)
	if(source)then
		local k,v;
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
		end
	end
end

function CodeHelpData.LoadParacraftCodeFunctions()
	CodeHelpData.AppendAll();
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
	local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
	CodeHelpWindow.AddCodeHelpItems(all_cmds);
	CodeHelpWindow.AddCodeExamples(all_examples);
end

function CodeHelpData.GetAllCmds()
	CodeHelpData.AppendAll();
	return all_cmds;
end
