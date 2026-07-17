--[[
Title: MicroPython_Control
Author(s): LiXizhi
Date: 2018/7/5
Desc: define blocks in category of Control
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/MicroPython/MicroPython_Control.lua");
-------------------------------------------------------
]]
local function trimString(strText)
	if not strText or strText == "" then
		return ""
	end
	return strText:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\r\n]+", "")
end
NPL.export({

	-- Control
	{
	type = "time.sleep", 
	message0 = L"等待 %1 %2",
	arg0 = {
		{
			name = "time",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"秒", ""},
				{ L"毫秒", "_ms" },
				{ L"微秒", "_us" },
			  }
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	funcName = "time.sleep",
	previousStatement = true,
	nextStatement = true,
	headerText = "import time",
	func_description = 'time.sleep(%s)',
	ToNPL = function(self)
		return string.format('time.sleep%s(%s)\n', self:getFieldAsString('mode'), self:getFieldAsString('time'));
	end,
	ToMicroPython = function(self)
		return string.format('time.sleep%s(%s)\n', self:getFieldAsString('mode'), self:getFieldAsString('time'));
	end,
	examples = {{desc = "", canRun = true, code = [[
import time
time.sleep(1)
time.sleep_ms(1)
time.sleep_us(1)
]]}},
},

	{
		type = "repeat", 
		message0 = L"重复%1次",
		message1 = L"%1",
		arg0 = {
			{
				name = "times",
				type = "input_value",
				shadow = { type = "math_number", value = 10,},
				text = 10, 
			},
		},
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'for i_ in range(%s):\\n    %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for i_ in range(%s):\n    %s\n', self:getFieldAsString('times'), input);
		end,
		ToMicroPython = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for i_ in range(%s):\n%s\n', self:getFieldAsString('times'), input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},
	
	{
		type = "forever", 
		message0 = L"永远重复%1",
		message1 = L"%1",
		arg0 = {
			{
				name = "label_dummy",
				type = "input_dummy",
			},
		},
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		funcName = "while",
		previousStatement = true,
		nextStatement = true,
		func_description = 'while True:\\n    %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('while True:\n    %s\n', input);
		end,
		ToMicroPython = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('while True:\n%s\n', input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},
	{
		type = "repeat_count", 
		message0 = L"循环:变量%1从%2到%3",
		message1 = L"%1",
		arg0 = {
			{
				name = "var",
				type = "field_input",
				text = "i",
			},
			{
				name = "start_index",
				type = "input_value",
				shadow = { type = "math_number", value = 1,},
				text = 1, 
			},
			{
				name = "end_index",
				type = "input_value",
				shadow = { type = "math_number", value = 10,},
				text = 10, 
			},
			
		},
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		funcName = "for",
		func_description = 'for %s in range(%d, %d):\\n    %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for %s in range(%s, %s+1):\n    %s\n', self:getFieldValue('var'),self:getFieldAsString('start_index'),self:getFieldAsString('end_index'), input);
		end,
		ToMicroPython = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for %s in range(%s, %s+1):\n%s\n', self:getFieldValue('var'),self:getFieldAsString('start_index'),self:getFieldAsString('end_index'), input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},
	{
		type = "repeat_count_step", 
		message0 = L"循环:变量%1从%2到%3递增%4",
		message1 = L"%1",
		arg0 = {
			{
				name = "var",
				type = "field_input",
				text = "i",
			},
			{
				name = "start_index",
				type = "input_value",
				shadow = { type = "math_number", value = 1,},
				text = 1, 
			},
			{
				name = "end_index",
				type = "input_value",
				shadow = { type = "math_number", value = 10,},
				text = 10, 
			},
			{
				name = "step",
				type = "input_value",
				shadow = { type = "math_number", value = 1,},
				text = 1, 
			},
		},
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'for %s in range(%s, %s, %s):\\n    %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for %s in range(%s, %s+1, %s):\n    %s\n', self:getFieldValue('var'),self:getFieldAsString('start_index'),self:getFieldAsString('end_index'), self:getFieldAsString('step'), input);
		end,
		ToMicroPython = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for %s in range(%s, %s+1, %s):\n%s\n', self:getFieldValue('var'),self:getFieldAsString('start_index'),self:getFieldAsString('end_index'), self:getFieldAsString('step'), input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	
	]]}},
	},
	
	
	{
		type = "expression_compare", 
		message0 = L"%1 %2 %3",
		arg0 = {
			{
				name = "left",
				type = "field_input",
				text = "status",
			},
			{
				name = "op",
				type = "field_dropdown",
				options = {
					{ "==", "==" },{ "!=", "!=" },
				},
			},
			{
				name = "right",
				type = "field_input",
				text = "\"start\"",
			},
		},
		hide_in_toolbox = true,
		output = {type = "field_number",},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		func_description = '((%s) %s (%s))',
		ToNPL = function(self)
			return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'), self:getFieldAsString('right'));
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},
	
	{
		type = "repeat_until", 
		message0 = L"重复执行",
		message1 = L"%1",
		message2 = L"一直到%1",
		arg0 = {
		},
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
		arg2 = {
			{
				name = "expression",
				type = "input_value",
				shadow = { type = "expression_compare", },
				text = "status == \"start\""
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		hide_in_codewindow = false,
		previousStatement = true,
		nextStatement = true,
		funcName = "repeat", 
		func_description = "while True:\\n    %s\\n    if %s:\\n        break",
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('while True:\n    %s\n    if %s:\n        break\n', input, self:getFieldAsString('expression'));
		end,
		ToMicroPython = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			local block_indent = self:GetIndent();
			return string.format('while True:\n%s\n%s    if %s:\n%s        break\n', input, block_indent, self:getFieldAsString('expression'), block_indent);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},
	
	
	{
		type = "while_if", 
		message0 = L"重复执行只要%1",
		message1 = L"%1",
		arg0 = {
			{
				name = "expression",
				type = "input_value",
				shadow = { type = "expression_compare", },
				text = "status == \"start\""
			},
		},
		arg1 = {
			{
				name = "input_true",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		funcName = "while",
		nextStatement = true,
		func_description = 'while %s:\\n    %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input_true')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('while %s:\n    %s\n', self:getFieldAsString('expression'), input);
		end,
		ToMicroPython = function(self)
			local input = self:getFieldAsString('input_true')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('while %s:\n%s\n', self:getFieldAsString('expression'), input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},
	
	
	{
		type = "control_if", 
		message0 = L"如果%1那么",
		message1 = L"%1",
		arg0 = {
			{
				name = "expression",
				type = "input_value",
			},
		},
		arg1 = {
			{
				name = "input_true",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		funcName = "if",
		previousStatement = true,
		nextStatement = true,
		func_description = 'if %s:\\n    %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input_true')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('if %s:\n    %s\n', self:getFieldAsString('expression'), input);
		end,
		ToMicroPython = function(self)
			local input = self:getFieldAsString('input_true')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('if %s:\n%s\n', self:getFieldAsString('expression'), input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},
	
	{
		type = "if_else", 
		message0 = L"如果%1那么",
		message1 = L"%1",
		message2 = L"否则",
		message3 = L"%1",
		arg0 = {
			{
				name = "expression",
				type = "input_value",
			},
		},
		arg1 = {
			{
				name = "input_true",
				type = "input_statement",
				text = "pass",
			},
		},
		arg3 = {
			{
				name = "input_else",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'if %s:\\n    %s\\nelse:\\n    %s',
		ToNPL = function(self)
			local input_true = self:getFieldAsString('input_true')
			local input_else = self:getFieldAsString('input_else')
			if input_true == '' then
				input_true = 'pass'
			end
			if input_else == '' then
				input_else = 'pass'
			end
			return string.format('if %s:\n    %s\nelse:\n    %s\n', self:getFieldAsString('expression'), input_true, input_else);
		end,
		ToMicroPython = function(self)
			local input_true = self:getFieldAsString('input_true')
			local input_else = self:getFieldAsString('input_else')
			local block_indent = self:GetIndent();
			if input_true == '' then
				input_true = 'pass'
			end
			if input_else == '' then
				input_else = 'pass'
			end
			return string.format('if %s:\n%s\n%selse:\n%s\n', self:getFieldAsString('expression'), input_true, block_indent, input_else);
		end,
		examples = {{desc = "", canRun = true, code = [[
	
	]]}},
	},
	
	
	{
		type = "forKeyValue", 
		message0 = L"每个%1,%2在%3",
		message1 = L"%1",
		arg0 = {
			{
				name = "key",
				type = "field_input",
				text = "key", 
			},
			{
				name = "value",
				type = "field_input",
				text = "value", 
			},
			{
				name = "data",
				type = "input_value",
				shadow = { type = "functionParams", value = "data",},
				text = "data", 
			},
			
		},
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		funcName = "pairs",
		nextStatement = true,
		func_description = 'for %s, %s in %s.items():\\n    %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for %s, %s in %s.items():\n    %s\n', self:getFieldAsString('key'), self:getFieldAsString('value'), self:getFieldAsString('data'), input);
		end,
		ToMicroPython = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for %s, %s in %s.items():\n%s\n', self:getFieldAsString('key'), self:getFieldAsString('value'), self:getFieldAsString('data'), input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	
	]]}},
	},
	
	{
		type = "forIndexValue", 
		message0 = L"每个%1,%2在数组%3",
		message1 = L"%1",
		arg0 = {
			{
				name = "i",
				type = "field_input",
				text = "index", 
			},
			{
				name = "item",
				type = "field_input",
				text = "item", 
			},
			{
				name = "data",
				type = "input_value",
				shadow = { type = "functionParams", value = "data",},
				text = "data", 
			},
			
		},
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		funcName = "ipairs",
		func_description = 'for %s, %s in enumerate(%s):\\n    %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for %s, %s in enumerate(%s):\n    %s\n', self:getFieldAsString('i'), self:getFieldAsString('item'), self:getFieldAsString('data'), input);
		end,
		ToMicroPython = function(self)
			local input = self:getFieldAsString('input')
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('for %s, %s in enumerate(%s):\n%s\n', self:getFieldAsString('i'), self:getFieldAsString('item'), self:getFieldAsString('data'), input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	
	]]}},
	},
	

	{
		type = "userTimer", 
		message0 = L"定义定时器 %1",
		message1 = L"%1",
		arg0 = {
			{
			name = "timerId",
			type = "field_dropdown",
			options = {
				{ L"1", "1" },
				{ L"2", "2" },
				{ L"3", "3" },
				{ L"4", "4" },
				{ L"5", "5" },
				{ L"6", "6" },
				{ L"7", "7" },
				{ L"8", "8" },
				{ L"9", "9" },
				{ L"10", "10" },
			  }
			}
		},
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		funcName = "if",
		previousStatement = true,
		nextStatement = true,
		headerText = "from machine import Timer",
		func_description = 'def userTimer%s_tick(_):\\n    %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			return string.format('def userTimer%s_tick(_):\n    %s\nuserTimer%s = Timer(%s)\n', self:getFieldAsString('timerId'), 
				input, self:getFieldAsString('timerId'), self:getFieldAsString('timerId'));
		end,
		ToMicroPython = function(self)
			local global_vars = MicroPython:GetGlobalVarsDefString(self)
			local input = self:getFieldAsString('input')
			local block_indent = self:GetIndent();
			if trimString(input) == '' then
				input = input .. 'pass'
			end
			return string.format('def userTimer%s_tick(_):\n%s%s\n%suserTimer%s = Timer(%s)\n', self:getFieldAsString('timerId'), 
				global_vars, input, block_indent, self:getFieldAsString('timerId'), self:getFieldAsString('timerId'));
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

	{
	type = "userTimer.Init", 
	message0 = L"启动定时器%1 周期%2毫秒 %3 ",
	arg0 = {
		{
			name = "timerId",
			type = "field_dropdown",
			options = {
				{ L"1", "1" },
				{ L"2", "2" },
				{ L"3", "3" },
				{ L"4", "4" },
				{ L"5", "5" },
				{ L"6", "6" },
				{ L"7", "7" },
				{ L"8", "8" },
				{ L"9", "9" },
				{ L"10", "10" },
			  }
		},
		{
			name = "period",
			type = "input_value",
            shadow = { type = "math_number", value = 2000,},
			text = 2000, 
		},
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"重复执行", "PERIODIC"},
				{ L"延时执行", "ONE_SHOT" },
			  }
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	funcName = "time.sleep",
	previousStatement = true,
	nextStatement = true,
	headerText = "from machine import Timer",
	func_description = 'userTimer%s.init(period=%s, mode=Timer.%s, callback=timer1_tick)',
	ToNPL = function(self)
		return string.format('userTimer%s.init(period=%s, mode=Timer.%s, callback=userTimer%s_tick)\n', 
			self:getFieldAsString('timerId'), self:getFieldAsString('period'), self:getFieldAsString('mode'), self:getFieldAsString('timerId'));
	end,
	ToMicroPython = function(self)
		return string.format('userTimer%s.init(period=%s, mode=Timer.%s, callback=userTimer%s_tick)\n', 
			self:getFieldAsString('timerId'), self:getFieldAsString('period'), self:getFieldAsString('mode'), self:getFieldAsString('timerId'));
	end,
	examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

})
	