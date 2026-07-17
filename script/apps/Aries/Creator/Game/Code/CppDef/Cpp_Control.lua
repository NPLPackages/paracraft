--[[
Title: Cpp_Control
Author(s): LiXizhi
Date: 2023/12/28
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Cpp/Cpp_Control.lua");
-------------------------------------------------------
]]

NPL.export({

	-- Control
	{
	type = "sleep", 
	message0 = L"等待 %1毫秒",
	arg0 = {
		{
			name = "times",
			type = "input_value",
            shadow = { type = "math_number", value = 10,},
			text = 10, 
		},
	},
	category = "Control", 
	helpUrl = "", 
	canRun = false,
	funcName = "sleep",
	previousStatement = true,
	nextStatement = true,
	func_description = 'sleep(%s);',
	ToNPL = function(self)
		return string.format('sleep(%s);\n', self:getFieldAsString('time'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
				text = "",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'for(int i = 0; i < %s; i++) {\\n%s\\n}',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			return string.format('for(int i = 0; i < %s; i++) {\n%s}\n', self:getFieldAsString('times'), input);
		end,
		ToCpp = function(self)
			local input = self:getFieldAsString('input')
			local block_indent = self:GetIndent();
			return string.format('for(int i = 0; i < %s; i++) {\n%s\n%s}\n', self:getFieldAsString('times'), input, block_indent);
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
				text = "",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		funcName = "for",
		func_description = 'for(int %s = %s; i <= %s; i++) {\\n%s\\n}',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			local var = self:getFieldValue('var');
			return string.format('for(int %s = %s; %s <= %s; %s++) {\n%s}\n', 
				var,self:getFieldAsString('start_index'), var, self:getFieldAsString('end_index'), var, input);
		end,
		ToCpp = function(self)
			local input = self:getFieldAsString('input')
			local var = self:getFieldValue('var');
			local block_indent = self:GetIndent();
			return string.format('for(int %s = %s; %s <= %s; %s++) {\n%s\n%s}\n', 
				var,self:getFieldAsString('start_index'), var, self:getFieldAsString('end_index'), var, input, block_indent);
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
				text = "",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'for(int %s = %s; i <= %s; i+=%s) {\\n%s\\n}',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			local var = self:getFieldValue('var');
			return string.format('for(int %s = %s; %s <= %s; %s+=%s) {\n%s}\n', 
				var,self:getFieldAsString('start_index'), var, self:getFieldAsString('end_index'), var, self:getFieldAsString('step'), input);
		end,
		ToCpp = function(self)
			local input = self:getFieldAsString('input')
			local var = self:getFieldValue('var');
			local block_indent = self:GetIndent();
			return string.format('for(int %s = %s; %s <= %s; %s+=%s) {\n%s\n%s}\n', 
				var,self:getFieldAsString('start_index'), var, self:getFieldAsString('end_index'), var, self:getFieldAsString('step'), input, block_indent);
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
		ToCpp = function(self)
			return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'), self:getFieldAsString('right'));
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
				text = "",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		funcName = "while",
		nextStatement = true,
		func_description = 'while(%s){\\n%s\\n}',
		ToNPL = function(self)
			local input = self:getFieldAsString('input_true')
			return string.format('while(%s){\n%s}\n', self:getFieldAsString('expression'), input);
		end,
		ToCpp = function(self)
			local input = self:getFieldAsString('input_true')
			local block_indent = self:GetIndent();
			return string.format('while(%s){\n%s\n%s}\n', self:getFieldAsString('expression'), input, block_indent);
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
				text = "",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		funcName = "if",
		previousStatement = true,
		nextStatement = true,
		func_description = 'if(%s){\\n%s}',
		ToNPL = function(self)
			local input = self:getFieldAsString('input_true')
			return string.format('if(%s){\n%s}\n', self:getFieldAsString('expression'), input);
		end,
		ToCpp = function(self)
			local input = self:getFieldAsString('input_true')
			local block_indent = self:GetIndent();
			return string.format('if(%s){\n%s\n%s}\n', self:getFieldAsString('expression'), input, block_indent);
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
				text = "",
			},
		},
		arg3 = {
			{
				name = "input_else",
				type = "input_statement",
				text = "",
			},
		},
		category = "Control", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'if (%s){\\n%s}\\nelse{\\n%s}',
		ToNPL = function(self)
			local input_true = self:getFieldAsString('input_true')
			local input_else = self:getFieldAsString('input_else')
			return string.format('if (%s){\n%s}\nelse{\n%s}\n', self:getFieldAsString('expression'), input_true, input_else);
		end,
		ToCpp = function(self)
			local input_true = self:getFieldAsString('input_true')
			local input_else = self:getFieldAsString('input_else')
			local block_indent = self:GetIndent();
			return string.format('if (%s){\n%s\n%s}\n%selse{\n%s\n%s}\n', self:getFieldAsString('expression'), input_true, block_indent, block_indent, input_else, block_indent);
		end,
		examples = {{desc = "", canRun = true, code = [[
	
	]]}},
	},

})
	