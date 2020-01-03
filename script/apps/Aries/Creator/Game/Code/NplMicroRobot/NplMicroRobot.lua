--[[
Title: NplMicroRobot
Author(s): leio
Date: 2018/12/12
Desc: NplMicroRobot is a blockly program to control animation on microbit
use the lib:
-------------------------------------------------------
local NplMicroRobot = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobot.lua");
NplMicroRobot.MakeBlocklyFiles();
-------------------------------------------------------
]]
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local NplMicroRobot = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.NplMicroRobot.NplMicroRobot", NplMicroRobot);

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Microbit.lua");


local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
NplMicroRobot.categories = {
    {name = "NplMicroRobot.Motion", text = L"运动", colour="#42ccff", },
};

-- make files for blockly 
function NplMicroRobot.MakeBlocklyFiles()
    local categories = NplMicroRobot.GetCategoryButtons();
    local all_cmds = NplMicroRobot.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    CodeBlocklyHelper.SaveFiles("block_configs_nplmicrorobot",categories,all_cmds);

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_nplmicrorobot", "", "", 1); 
end
function NplMicroRobot.GetCategoryButtons()
    return NplMicroRobot.categories;
end
function NplMicroRobot.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

	local all_source_cmds = {
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_Motion.lua");
	}
	for k,v in ipairs(all_source_cmds) do
		NplMicroRobot.AppendDefinitions(v);
	end
end


function NplMicroRobot.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
			all_cmds_map[v.type] = v;
		end
	end
end

function NplMicroRobot.GetAllCmds()
	NplMicroRobot.AppendAll();
	return all_cmds;
end
