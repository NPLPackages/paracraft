--[[
Title: micro python 
Author(s): LiXizhi
Date: 2023/8/2
Desc: Display and more
use the lib:
-------------------------------------------------------
from mpython import *
oled.fill(0)
oled.show()
oled.DispChar(str('Hello, world!'), 0, 48, 1)
oled.fill_rect(0, 0, 128, 16, 0)
oled.DispChar(str('Hello, world!'), 10, 10, 1, True)
oled.pixel(0, 0, 1)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");

NPL.export({

{
	type = "oled.importmpython", 
	message0 = L"引入mpython",
	arg0 = {
	},
	category = "display", 
	helpUrl = "", 
	canRun = false,
	funcName = "oled.importmpython",
	hide_in_blockly = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'from mpython import *',
	ToNPL = function(self)
		return "from mpython import *";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "oled.fill", 
	message0 = L"OLED显示%1",
	arg0 = {
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"清空", "fill(0)" },
				{ L"全亮", "fill(1)" },
				{ L"黑底", "invert(0)" },
				{ L"白底", "invert(1)" },
			  }
		},
	},
	category = "display", 
	helpUrl = "", 
	canRun = false,
	funcName = "oled.fill",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'oled.%s',
	ToNPL = function(self)
		return string.format('oled.%s\n', self:getFieldAsString('mode'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
oled.fill(0)
oled.DispChar("Hello, world!", 0, 0, 1)
oled.show()
]]}},
},

{
	type = "oled.show", 
	message0 = L"OLED显示生效",
	arg0 = {
	},
	category = "display", 
	helpUrl = "", 
	canRun = false,
	funcName = "oled.show",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'oled.show()',
	ToNPL = function(self)
		return "oled.show()";
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
oled.fill(0)
oled.DispChar("Hello, world!", 0, 0, 1)
oled.show()
]]}},
},

{
	type = "oled.DispChar", 
	message0 = L"OLED显示%1在第%2行 模式%3 %4",
	arg0 = {
		{
			name = "content",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello", 
		},
		{
			name = "y",
			type = "field_dropdown",
			options = {
				{ "1", 0 },
				{ "2", 16 },
				{ "3", 32 },
				{ "4", 48 },
			  }
		},
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"普通", 1 },
				{ L"反转", 2 },
				{ L"透明", 3 },
				{ L"XOR", 4 },
			  }
		},
		{
			name = "lineWrap",
			type = "field_dropdown",
			options = {
				{ L"不换行",  ""},
				{ L"自动换行", ", True" },
			  }
		},
	},
	category = "display", 
	helpUrl = "", 
	canRun = false,
	funcName = "oled.DispChar",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'oled.DispChar(str(%s), 0, %s, %s%s)',
	ToNPL = function(self)
		return string.format('oled.DispChar("%s", 0, %s, %s%s)\n', self:getFieldAsString('content'), self:getFieldAsString('y'), self:getFieldAsString('mode'), self:getFieldAsString('lineWrap'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
oled.fill(0)
oled.DispChar("Hello, world!", 0, 0, 1)
oled.show()
]]}},
},

{
	type = "oled.DispChar2", 
	message0 = L"OLED显示%1在x%2 y%3 模式%4 %5",
	arg0 = {
		{
			name = "content",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello", 
		},
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"普通", 1 },
				{ L"反转", 2 },
				{ L"透明", 3 },
				{ L"XOR", 4 },
			  }
		},
		{
			name = "lineWrap",
			type = "field_dropdown",
			options = {
				{ L"不换行",  ""},
				{ L"自动换行", ", True" },
			  }
		},
	},
	category = "display", 
	helpUrl = "", 
	canRun = false,
	funcName = "oled.DispChar2",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'oled.DispChar(str(%s), %s, %s, %s%s)',
	ToNPL = function(self)
		return string.format('oled.DispChar("%s", %s, %s, %s%s)\n', self:getFieldAsString('content'), self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('mode'), self:getFieldAsString('lineWrap'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
oled.fill(0)
oled.DispChar("Hello, world!", 10, 10, 1)
oled.show()
]]}},
},

{
	type = "oled.clearLine", 
	message0 = L"OLED清除第%1行",
	arg0 = {
		{
			name = "y",
			type = "field_dropdown",
			options = {
				{ "1", 0 },
				{ "2", 16 },
				{ "3", 32 },
				{ "4", 48 },
			  }
		},
	},
	category = "display", 
	helpUrl = "", 
	canRun = false,
	funcName = "oled.clearLine",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'oled.fill_rect(0, %s, 128, 16, 0)',
	ToNPL = function(self)
		return string.format('oled.fill_rect(0, %s, 128, 16, 0)\n', self:getFieldAsString('y'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "oled.pixel", 
	message0 = L"OLED描点 x%1 y%2 %3",
	arg0 = {
		{
			name = "x",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "y",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"亮", 1 },
				{ L"暗", 0 },
			  }
		},
	},
	category = "display", 
	helpUrl = "", 
	canRun = false,
	funcName = "oled.pixel",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *",
	func_description = 'oled.pixel(int(%s), int(%s), %s)',
	ToNPL = function(self)
		return string.format('oled.pixel(int(%s), int(%s), %s)\n', self:getFieldAsString('x'), self:getFieldAsString('y'), self:getFieldAsString('mode'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
oled.fill(0)
for i in range(1, 40):
    oled.pixel(10, i, 1)
oled.show()
]]}},
},

});