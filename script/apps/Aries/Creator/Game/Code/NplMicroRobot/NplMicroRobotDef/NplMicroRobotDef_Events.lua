--[[
Title: NplMicroRobotDef_Events
Author(s): leio
Date: 2019/11/29
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotDef/NplMicroRobotDef_Events.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "registerKeyPressedEvent_NplMicroRobot", 
	message0 = L"当%1键按下时",
	message1 = L"%1",
	arg0 = {
		{
			name = "keyname",
			type = "field_dropdown",
			options = {
				{ L"A", "A" },
				{ L"B", "B" },
				{ L"AB", "AB" },
			},
			text = "A", 
		},
		
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "",
		},
    },
	category = "NplMicroRobot.Events", 
	helpUrl = "", 
	canRun = false,
	funcName = "registerKeyPressedEvent_NplMicroRobot",
	func_description = 'registerKeyPressedEvent_NplMicroRobot("%s", function(msg)\\n%send)',
	func_description_js = 'registerKeyPressedEvent_NplMicroRobot("%s", function(){\\n%s})',
	ToNPL = function(self)
		return string.format('registerKeyPressedEvent_NplMicroRobot("%s", function(msg)\n    %s\nend)\n', self:getFieldAsString('keyname'), self:getFieldAsString('input'));
	end,
	examples = {
{desc = L"", canRun = true, code = [[

]]},
},
},

{
	type = "registerGestureEvent_NplMicroRobot", 
	message0 = L"当%1",
	message1 = L"%1",
	arg0 = {
		{
			name = "keyname",
			type = "field_dropdown",
			options = {
				{ L"Shake", "Shake" },
				{ L"LogoUp", "LogoUp" },
				{ L"LogoDown", "LogoDown" },
				{ L"ScreenUp", "ScreenUp" },
				{ L"ScreenDown", "ScreenDown" },
				{ L"TiltLeft", "TiltLeft" },
				{ L"TiltRight", "TiltRight" },
				{ L"FreeFall", "FreeFall" },
				{ L"ThreeG", "ThreeG" },
				{ L"SixG", "SixG" },
				{ L"EightG", "EightG" },
			},
			text = L"Shake", 
		},
		
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "",
		},
    },
	category = "NplMicroRobot.Events", 
	helpUrl = "", 
	canRun = false,
	funcName = "registerGestureEvent_NplMicroRobot",
	func_description = 'registerGestureEvent_NplMicroRobot("%s", function(msg)\\n%send)',
	func_description_js = 'registerGestureEvent_NplMicroRobot("%s", function(){\\n%s})',
	ToNPL = function(self)
		return string.format('registerGestureEvent_NplMicroRobot("%s", function(msg)\n    %s\nend)\n', self:getFieldAsString('keyname'), self:getFieldAsString('input'));
	end,
	examples = {
{desc = L"", canRun = true, code = [[

]]},
},
},


})