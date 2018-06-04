--[[
Title: CodeHelpWindow
Author(s): LiXizhi
Date: 2018/5/22
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
CodeHelpWindow.Show(true)
-------------------------------------------------------
]]
local CodeHelpWindow = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow"));

local page;
-- this is singleton class
local self = CodeHelpWindow;

local categories = {
{name = "Motion", displayName = L"运动"},
{name = "Events", displayName = L"事件"},
{name = "Looks", displayName = L"外观"},
{name = "Control", displayName = L"控制"},
{name = "Sound", displayName = L"声音"},
{name = "Sensing", displayName = L"感知"},
{name = "Operators", displayName = L"运算"},
{name = "Data", displayName = L"数据"},
};

local all_cmds = {
{
	type = "say", 
	message0 = L"say %1 for %2 secs",
	arg0 = {
		{
			name = "text",
			type = "field_input",
			text = L"hello!", 
		},
		{
			name = "duration",
			type = "field_number",
			text = 2, 
		},
	},
	category = "Motion", 
	tooltip = "", 
	helpUrl = "", 
	ToNPL = function(block)
		return string.format('say("%q");\n', block.getFieldValue('text'));
	end,
},

}

local all_examples = {
{name = "", desc = "", references = {"say", }, code = [[
say("Click Me!")
registerClickEvent(function()
   turn(15)
   play(0,1000)
   say("hi!")
end)
]]},
}

function CodeHelpWindow.InitCmds()
	
end

-- show code block window at the right side of the screen
-- @param bShow:
function CodeHelpWindow.Show(bShow)
end

CodeHelpWindow:InitSingleton();