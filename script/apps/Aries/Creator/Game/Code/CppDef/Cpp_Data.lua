--[[
Title: Cpp_Data
Author(s): LiXizhi
Date: 2023/12/28
Desc: define blocks in category of Data
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Cpp/Cpp_Data.lua");
-------------------------------------------------------
]]

NPL.export({
-- Data
{
	type = "include", 
	message0 = L"include%1", color="#cc0000",
	arg0 = {
		{
			name = "filename",
			type = "input_value",
            shadow = { type = "text", value = "stdio.h",},
			text = "stdio.h", 
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "include",
	func_description = '#include <%s>',
	ToNPL = function(self)
		return string.format('#include <%s>\n', self:getFieldAsString('filename'));
	end,
	ToCpp = function(self)
		self:GetBlockly():AddUnqiueHeader(string.format('#include <%s>\n', self:getFieldAsString('filename')));
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

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
	ToCpp = function(self)
		local var = self:getFieldAsString('var')
		return commonlib.Encoding.toValidParamName(var);
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "cpp_value_types", 
	message0 = "%1",
	arg0 = {
		{
			name = "to",
			type = "field_dropdown",
			options = {
				{ L"浮点数", "float" },
				{ L"double", "double" },
				{ L"整数", "int" },
				{ L"const char*", "const char*" },
			},
		},
	},
    hide_in_toolbox = true,
    output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "defineVariable", 
	message0 = L"定义全局变量 %1 %2",
	arg0 = {
		{
			name = "value_type",
			type = "input_value",
            shadow = { type = "cpp_value_types" },
			text = "float",
		},
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
	previousStatement = true,
	nextStatement = true,
	func_description = '%s',
	hide_in_codewindow = true,
	ToNPL = function(self)
		return string.format('%s %s;\n', self:getFieldAsString('value_type'), self:getFieldAsString('var'));
	end,
	ToCpp = function(self)
		local var = commonlib.Encoding.toValidParamName(self:getFieldAsString('var'))
		local varType = self:getFieldAsString('value_type')
		self:GetBlockly():AddUnqiueHeader(string.format('// global %s', var));
		if(varType == "float" or varType == "double" or varType == "int") then
			self:GetBlockly():AddUnqiueHeader(string.format('%s %s = 0;', varType, var));
		else
			self:GetBlockly():AddUnqiueHeader(string.format('%s %s;', varType, var));
		end
		return "";
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
	func_description = '%s = %s;',
	ToNPL = function(self)
		return string.format('%s = %s;\n', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	ToCpp = function(self)
		local left = self:getFieldAsString('left')
		if(not self:GetBlockly():HasUniqueHeader(string.format('// global %s', left))) then
			self:GetBlockly():AddUniqueHeader(string.format('double %s = 0;', left));	
		end
		return string.format('%s = %s;\n', left, self:getFieldAsString('right'));
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
	func_description = '%s += %s;',
	ToNPL = function(self)
		return string.format('%s += %s;\n', self:getFieldAsString('left'), self:getFieldAsString('right'));
	end,
	ToCpp = function(self)
		local left = self:getFieldAsString('left')
		if(not self:GetBlockly():HasUniqueHeader(string.format('// global %s', left))) then
			self:GetBlockly():AddUniqueHeader(string.format('double %s = 0;', left));	
		end
		return string.format('%s += %s;\n', left, self:getFieldAsString('right'));
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
	func_description = 'String(%s)',
	ToNPL = function(self)
		return string.format('String(%s)', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
				{ L"真", "true" },
				{ L"假", "false" },
				{ L"无效", "0" },
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
			text = "",
		},
    },
	-- previousStatement = true,
	nextStatement = true,
	hide_in_codewindow = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = 'void %s(%s){\n%s\n}\n',
    ToNPL = function(self)
		local input = self:getFieldAsString('input')
		return string.format('void %s(%s){\n%s\n}\n', self:getFieldAsString('name'), self:getFieldAsString('param'), input);
	end,
	ToCpp = function(self)
		local input = self:getFieldAsString('input')
		local originalName = self:getFieldAsString('name')
		local name = commonlib.Encoding.toValidParamName(originalName)
		local funcComment = ""
		if(name ~= originalName) then
			funcComment = string.format("// %s \n", originalName)
		end
		self:GetBlockly():AddUniqueHeader(funcComment..string.format('void %s(%s);\n', name, self:getFieldAsString('param')));
		local block_indent = self:GetIndent();
		return funcComment..string.format('void %s(%s){\n%s\n%s}\n', name, self:getFieldAsString('param'), input, block_indent);
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
			text = "",
		},
    },
	previousStatement = true,
	nextStatement = true,
	hide_in_codewindow = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = 'void %s(%s){\n%s\n}\n',
    ToNPL = function(self)
		local input = self:getFieldAsString('input')
		return string.format('void %s(%s){\n%s\n}\n', self:getFieldAsString('name'), self:getFieldAsString('param'), input);
	end,
	ToCpp = function(self)
		local input = self:getFieldAsString('input')
		local originalName = self:getFieldAsString('name')
		local name = commonlib.Encoding.toValidParamName(originalName)
		local funcComment = ""
		if(name ~= originalName) then
			funcComment = string.format("// %s \n", originalName)
		end
		self:GetBlockly():AddUniqueHeader(funcComment..string.format('void %s(%s);\n', name, self:getFieldAsString('param')));
		local block_indent = self:GetIndent();
		return funcComment..string.format('void %s(%s){\n%s\n%s}\n', name, self:getFieldAsString('param'), input, block_indent);
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
	func_description = '%s(%s);',
	ToNPL = function(self)
		return string.format('%s(%s);\n', self:getFieldAsString('name'), self:getFieldAsString('param'));
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
			text = "print",
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
	headerText = "#include <iostream>",
	func_description = 'print(%s);',
	ToNPL = function(self)
		return string.format('print("%s");\n', self:getFieldAsString('obj'));
	end,
	ToCpp = function(self)
		local text = self:GetValueAsString('obj')
		return string.format('print(%s);\n', text);
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
	func_description = '// %s',
    ToNPL = function(self)
		return string.format('// %s\n', self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

})
