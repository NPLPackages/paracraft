--[[
Title: language configuration plugin
Author(s): LiXizhi
Date: 2019/10/28
Desc: 
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.export({
-----------------------
{
	type = "cmd_t", 
	message0 = L"%1秒后执行",
	message1 = L"%1",
	arg0 = {
		{
			name = "expression",
			type = "field_input",
			text = "1"
		},
    },
    arg1 = {
		{
			name = "input_true",
			type = "input_statement",
			text = "", 
		},
	},
	category = "CommandControl", 
	helpUrl = "", 
	canRun = false,
	funcName = "t",
	previousStatement = true,
	nextStatement = true,
	func_description = '/t %s %s',
	ToNPL = function(self)
		return string.format('/t %s %s\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'));
	end,
},

{
	type = "cmd_if", 
	message0 = L"如果%1那么",
	message1 = L"%1",
	arg0 = {
		{
			name = "expression",
			type = "field_input",
			text = ""
		},
    },
    arg1 = {
		{
			name = "input_true",
			type = "input_statement",
			text = "", 
		},
	},
	category = "CommandControl", 
	helpUrl = "", 
	canRun = false,
	funcName = "if",
	previousStatement = true,
	nextStatement = true,
	func_description = 'if %s then\\n%s\\nfi',
	ToNPL = function(self)
		return string.format('if %s then\n %s\nfi\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'));
	end,
},

{
	type = "cmd_fi", 
	message0 = "fi",
	category = "CommandControl", 
	helpUrl = "", 
	canRun = false,
	hide_in_toolbox = true,
	funcName = "fi",
	previousStatement = true,
	nextStatement = true,
	func_description = 'fi',
	ToNPL = function(self)
		return "fi\n";
	end,
},

{
	type = "cmd_jumpto", 
	message0 = L"跳转到%1行",
	arg0 = {
		{
			name = "input",
            type = "field_input",
			text = "1"
		},
	},
	category = "CommandControl", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "jumpto",
	func_description = '/jumpto %s',
	ToNPL = function(self)
		return string.format('/jumpto %s\n', self:getFieldAsString('input'));
	end,
},


{
	type = "cmd_function", 
	message0 = L"创建函数%1",
	message1 = L"%1",
	arg0 = {
		{
			name = "expression",
			type = "field_input",
			text = ""
		},
    },
    arg1 = {
		{
			name = "input_true",
			type = "input_statement",
			text = "", 
		},
	},
	category = "CommandControl", 
	helpUrl = "", 
	canRun = false,
	funcName = "function",
	previousStatement = true,
	nextStatement = true,
	func_description = 'function %s\\n%s\\nfunctionend',
	ToNPL = function(self)
		return string.format('function %s\n%s\nfunctionend\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'));
	end,
},

{
	type = "cmd_functionend", 
	message0 = "functionend",
	category = "CommandControl", 
	helpUrl = "", 
	canRun = false,
	hide_in_toolbox = true,
	funcName = "functionend",
	previousStatement = true,
	nextStatement = true,
	func_description = 'functionend',
	ToNPL = function(self)
		return "functionend\n";
	end,
},

{
	type = "cmd_callfunction", 
	message0 = L"调用函数%1",
	arg0 = {
		{
			name = "input",
            type = "field_input",
			text = ""
		},
	},
	category = "CommandControl", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "callfunction",
	func_description = '/callfunction %s',
	ToNPL = function(self)
		return string.format('/callfunction %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_sendevent", 
	message0 = L"发送事件%1",
	arg0 = {
		{
			name = "input",
            type = "field_input",
			text = ""
		},
	},
	category = "CommandControl", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "sendevent",
	func_description = '/sendevent %s',
	ToNPL = function(self)
		return string.format('/sendevent %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_return", 
	message0 = L"返回%1",
	arg0 = {
		{
			name = "input",
            type = "field_input",
			text = ""
		},
	},
	category = "CommandControl", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "return",
	func_description = '/return %s',
	ToNPL = function(self)
		return string.format('/return %s\n', self:getFieldAsString('input'));
	end,
},
---------------------
})
