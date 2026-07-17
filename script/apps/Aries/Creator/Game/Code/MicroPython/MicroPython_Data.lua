--[[
Title: MicroPython_Data
Author(s): LiXizhi
Date: 2018/7/5
Desc: define blocks in category of Data
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/MicroPython/MicroPython_Data.lua");
-------------------------------------------------------
]]
MicroPython = NPL.load("./MicroPython.lua");

NPL.export({
-- Data
{
	type = "getLocalVariable1", 
	message0 = L"%1",
	arg0 = {
		{
			name = "var",
			type = "field_variable",
			variable = L"变量名",
			variableTypes = {""},
			text = L"变量名",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	hide_in_codewindow = true,
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	ToMicroPython = function(self)
		local var = self:getFieldAsString('var')
		return commonlib.Encoding.toValidParamName(var);
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "assign1", 
	message0 = L"%1赋值为%2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
			shadow = { type = "getLocalVariable1", value = L"变量名",},
			text = L"变量名",
		},
		{
			name = "right",
			type = "input_value",
			shadow = { type = "functionParams", value = "1",},
			text = "1",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	hide_in_codewindow = true,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s = %s',
	ToNPL = function(self)
		return string.format('%s = %s\n', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUniqueHeader(string.format('%s = None\n', self:getFieldAsString('left')))
		return string.format('%s = %s\n', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "increase1", 
	message0 = L"%1值加%2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
			shadow = { type = "getLocalVariable1", value = L"变量名",},
			text = L"变量名",
		},
		{
			name = "right",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	hide_in_codewindow = true,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s += %s',
	ToNPL = function(self)
		return string.format('%s = %s + %s\n', self:getFieldAsString('left'), self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	ToMicroPython = function(self)
		return string.format('%s = %s + %s\n', self:getFieldAsString('left'), self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "tostring", 
	message0 = "转为文本%1",
	arg0 = {
		{
			name = "left",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = '',
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = 'str(%s)',
	ToNPL = function(self)
		return string.format('str(%s)', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
def on_button_a_pressed(_):
    oled.fill(0)
    oled.DispChar(str(button_a.get_presses()), 0, 0, 1)
    oled.show()

button_a.event_pressed = on_button_a_pressed
]]}},
},

{
	type = "getCode", 
	message0 = "%1",
	arg0 = {
		{
			name = "left",
			type = "field_input",
			text = L"['任意代码']",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return self:getFieldAsString('left');
	end,
	ToMicroPython = function(self)
		return self:getFieldAsString('left');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "getString", 
	message0 = "\"%1\"",
	arg0 = {
		{
			name = "left",
			type = "field_input",
			text = "string",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return string.format('"%s"', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "getBoolean", 
	message0 = L"%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"真", "True" },
				{ L"假", "False" },
				{ L"无效", "None" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		local value = self:getFieldAsString("value")
		if value == 'true' then
			value = 'True'
		elseif value == 'false' then
			value = 'False'
		elseif value == 'nil' then
			value = 'None'
		end
		return value;
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "getNumber", 
	message0 = L"%1",
	arg0 = {
		{
			name = "left",
			type = "field_number",
			text = "0",
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "getColor", 
	message0 = "%1",
	arg0 = {
		{
			name = "color",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('"%s"', self:getFieldAsString('color'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "defineHeaderFunction", 
	message0 = L"定义函数%1(%2)",
	message1 = L"%1",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "", 
		},
		{
			name = "param",
			type = "field_input",
			text = "", 
		},
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "pass",
		},
    },
	--previousStatement = true,
	nextStatement = true,
	hide_in_codewindow = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = 'def %s(%s):\\n    %s',
    ToNPL = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def %s(%s):\n    %s\n', self:getFieldAsString('name'), self:getFieldAsString('param'), input);
	end,
	ToMicroPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end

		local params = self:getFieldAsString('param') or ""
		local paramsMap;
		for paramName in params:gmatch("[^%s,]+") do
			paramsMap = paramsMap or {}
			paramsMap[paramName] = true
		end
		local global_vars = MicroPython:GetGlobalVarsDefString(self, paramsMap)
		local code = string.format('\ndef %s(%s):\n%s%s\n', commonlib.Encoding.toValidParamName(self:getFieldAsString('name')), params, global_vars, input);
		self:GetBlockly():AddUniqueHeader(code, 10) -- order is 10, so that it is added after import code.
		return "\n";
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "defineFunction", 
	message0 = L"定义函数%1(%2)",
	message1 = L"%1",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "", 
		},
		{
			name = "param",
			type = "field_input",
			text = "", 
		},
	},
    arg1 = {
        {
			name = "input",
			type = "input_statement",
			text = "pass",
		},
    },
	previousStatement = true,
	nextStatement = true,
	hide_in_codewindow = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = 'def %s(%s):\\n    %s',
    ToNPL = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def %s(%s):\n    %s\n', self:getFieldAsString('name'), self:getFieldAsString('param'), input);
	end,
	ToMicroPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end

		local params = self:getFieldAsString('param') or ""
		local paramsMap;
		for paramName in params:gmatch("[^%s,]+") do
			paramsMap = paramsMap or {}
			paramsMap[paramName] = true
		end
		local global_vars = MicroPython:GetGlobalVarsDefString(self, paramsMap)

		return string.format('def %s(%s):\n%s%s\n', commonlib.Encoding.toValidParamName(self:getFieldAsString('name')), params, global_vars, input);
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "functionParams", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = ""
		},
	},
	hide_in_toolbox = true,
	category = "Data", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
    colourSecondary = "#ffffff",
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "callFunction", 
	message0 = L"调用函数%1(%2)",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "log",
		},
		{
			name = "param",
			type = "input_value",
			shadow = { type = "functionParams", value = "param",},
			text = "",
		},
	},
	previousStatement = true,
	nextStatement = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s(%s)',
	ToNPL = function(self)
		return string.format('%s(%s)\n', self:getFieldAsString('name'), self:getFieldAsString('param'));
	end,
	ToMicroPython = function(self)
		return string.format('%s(%s)\n', commonlib.Encoding.toValidParamName(self:getFieldAsString('name')), self:getFieldAsString('param'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "callFunctionWithReturn", 
	message0 = L"调用函数并返回%1(%2)",
	arg0 = {
		{
			name = "name",
			type = "field_input",
			text = "log",
		},
		{
			name = "param",
			type = "input_value",
			shadow = { type = "functionParams", value = "param",},
			text = "",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s(%s)',
	ToNPL = function(self)
		return string.format('%s(%s)', self:getFieldAsString('name'), self:getFieldAsString('param'));
	end,
	ToMicroPython = function(self)
		return string.format('%s(%s)', commonlib.Encoding.toValidParamName(self:getFieldAsString('name')), self:getFieldAsString('param'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "print", 
	message0 = L"打印%1",
	arg0 = {
		{
			name = "obj",
			type = "input_value",
            shadow = { type = "text", value = "hello",},
			text = "hello", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "print",
	func_description = 'print(%s)',
	ToNPL = function(self)
		return string.format('print("%s")\n', self:getFieldAsString('obj'));
	end,
	examples = {{desc = L"查看log.txt或F11看日志", canRun = true, code = [[
]]}},
},


{
	type = "import", 
	message0 = L"引入类库%1", color="#cc0000",
	arg0 = {
		{
			name = "filename",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	hide_in_codewindow = true,
	hide_in_toolbox = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "import",
	func_description = 'import %s',
	ToNPL = function(self)
		return string.format('import %s\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "code_comment", 
	message0 = L"注释 %1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = "",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '# %s',
    ToNPL = function(self)
		return string.format('# %s\n', self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

})
