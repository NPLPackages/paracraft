--[[
Title: JiHRobot
Author(s): leio
Date: 2022/8/23
Desc: blockly program to JiHRobot
use the lib:
-------------------------------------------------------
local JiHRobot = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/JiHRobot/JiHRobot.lua");
JiHRobot.MakeBlocklyFiles();
-------------------------------------------------------
]]

local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local JiHRobot = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.JiHRobot.JiHRobot", JiHRobot);

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};

JiHRobot.categories = {
    {name = "Motion", text = L"运动", colour = "#0078d7", },
    {name = "ObjectName", text = L"名称", colour = "#ff8c1a", custom="VARIABLE", },
    {name = "Event", text = L"事件", colour = "#ffbf00", },
    {name = "Control", text = L"控制", colour = "#d83b01", },
    {name = "Math", text = L"运算", colour = "#569138", },
    {name = "Data", text = L"数据", colour = "#459197", },
    
};

-- make files for blockly 
function JiHRobot.MakeBlocklyFiles()
    local categories = JiHRobot.GetCategoryButtons();
    local all_cmds = JiHRobot.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    CodeBlocklyHelper.SaveFiles("block_configs_jihrobot",categories,all_cmds);

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_jihrobot", "", "", 1); 
end
function JiHRobot.GetCategoryButtons()
	return JiHRobot.categories;
end
function JiHRobot.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/JiHRobot/JiHRobotDef/JiHRobotDef_Motion.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/JiHRobot/JiHRobotDef/JiHRobotDef_Event.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/JiHRobot/JiHRobotDef/JiHRobotDef_Control.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/JiHRobot/JiHRobotDef/JiHRobotDef_Data.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/JiHRobot/JiHRobotDef/JiHRobotDef_Math.lua");

    local JiHRobotDef_Motion = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Motion");
    local JiHRobotDef_Event = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Event");
    local JiHRobotDef_Control = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Control");
    local JiHRobotDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Data");
    local JiHRobotDef_Math = commonlib.gettable("MyCompany.Aries.Game.Code.JiHRobot.JiHRobotDef_Math");
	

	local all_source_cmds = {
		JiHRobotDef_Motion.GetCmds(),
		JiHRobotDef_Event.GetCmds(),
		JiHRobotDef_Control.GetCmds(),
		JiHRobotDef_Data.GetCmds(),
		JiHRobotDef_Math.GetCmds(),
	}
	for k,v in ipairs(all_source_cmds) do
		JiHRobot.AppendDefinitions(v);
	end
end

function JiHRobot.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function JiHRobot.GetAllCmds()
	JiHRobot.AppendAll();
	return all_cmds;
end