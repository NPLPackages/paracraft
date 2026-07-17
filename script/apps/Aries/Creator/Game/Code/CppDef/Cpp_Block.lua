NPL.export({
-----------------------------------------------------------common--------------------------------------------------------------
{
		type = "IncludeBasic", 
		message0 = L"导入头文件",
		category = "basic", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = '#include <bits/stdc++.h>\n',
		ToNPL = function(self)
			return string.format('#include <bits/stdc++.h>\n');
		end,
		ToCpp = function(self)
			return string.format('#include <bits/stdc++.h>\n');
		end,
		examples = {{desc = "", canRun = false, code = [[
	]]}},
	},

	{
		type = "UsingBasic", 
		message0 = L"引用命名空间",
		category = "basic", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'using namespace std;\n',
		ToNPL = function(self)
			return string.format('using namespace std;\n');
		end,
		ToCpp = function(self)
			return string.format('using namespace std;\n');
		end,
		examples = {{desc = "", canRun = false, code = [[
	]]}},
	},

	{
		type = "MainBasic", 
		message0 = L"main函数",
		message1 = L"%1",
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "",
			},
		},
		category = "basic", 
		helpUrl = "", 
		canRun = false,
		funcName = "cpp.main",
		previousStatement = true,
		nextStatement = true,
		func_description = 'int main(){\n%s}',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			return string.format('int main()\n{\n    %s\n    return 0;\n}\n', input);
		end,
		ToCpp = function(self)
			local input = self:getFieldAsString('input')
			return string.format('int main()\n{\n    %s\n    return 0;\n}\n', input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

	{
		type = "CinBasic", 
		message0 = L"输入",
		message1 = L"%1",
		arg1 = {
			{
				name = "input",
				type = "input_value",
				text = "a",
			},
		},
		category = "basic", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'cin >> %s;',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			return string.format('cin >> %s;\n', input);
		end,
		ToCpp = function(self)
			local input = self:getFieldAsString('input')
			return string.format('cin >> %s;\n', input);
		end,
		examples = {{desc = "", canRun = true, code = [[
		cin>>a;
	]]}},
	},

	{
		type = "CoutBasic", 
		message0 = L"输出",
		message1 = L"%1",
		arg1 = {
			{
				name = "input",
				type = "input_value",
				text = "hello world",
			},
		},
		category = "basic", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'cout << %s;',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			return string.format('cout << "%s";\n', input);
		end,
		ToCpp = function(self)
			local input = self:GetValueAsString('input')
			return string.format('cout << %s;\n', input);
		end,
		examples = {{desc = "", canRun = true, code = [[
		cout<<"hello world";
	]]}},
	},

	{
		type = "CoutEndlBasic", 
		message0 = L"换行输出",
		message1 = L"%1",
		arg1 = {
			{
				name = "input",
				type = "input_value",
				text = "hello world",
			},
		},
		category = "basic", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'cout << %s << endl;',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			return string.format('cout << "%s" << endl;\n', input);
		end,
		ToCpp = function(self)
			local input = self:GetValueAsString('input')
			return string.format('cout << %s << endl;\n', input);
		end,
		examples = {{desc = "", canRun = true, code = [[
		cout<<"hello world" << endl;
	]]}},
	},

	{
		type = "CharBasic", 
		message0 = L"输入符",
		message1 = L"%1",
		arg1 = {
			{
				name = "input",
                type = "field_dropdown",
                options = {
                    { "()", "()" },{ "{}", "{}" },{ "<<", "<<" },{ ">>", ">>" },{ "''", "''" },{ '""', '""' },
                },
			},
		},
		category = "basic", 
		helpUrl = "", 
		canRun = false,
	    output = {type = "null",},
        previousStatement = false,
		nextStatement = false,
        -- hide_in_toolbox = true,
		func_description = '%s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			return string.format('%s', input);
		end,
		ToCpp = function(self)
			local input = self:GetValueAsString('input')
			return string.format('%s', input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

	{
		type = "CommentBasic", 
		message0 = L"注释",
		message1 = L"%1",
		arg1 = {
			{
				name = "input",
				type = "input_value",
				text = "",
			},
		},
		category = "basic", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = '// %s',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			return string.format('// %s\n', input);
		end,
		ToCpp = function(self)
			local input = self:getFieldAsString('input')
			return string.format('// %s\n', input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

	{
		type = "CommentsBasic", 
		message0 = L"注释全部",
		message1 = L"%1",
		arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "",
			},
		},
		category = "basic", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = '/*\n%s\n*/',
		ToNPL = function(self)
			local input = self:getFieldAsString('input')
			return string.format('/*\n%s\n*/\n', input);
		end,
		ToCpp = function(self)
			local input = self:getFieldAsString('input')
			return string.format('/*\n%s\n*/\n', input);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

-----------------------------------------------------------control--------------------------------------------------------------
    {
        type = "WhileControl", 
        message0 = L"当 %1 时重复执行",
        message1 = L"%1",
        arg0 = {
            {
                name = "expression",
                type = "input_value",
                text = ""
            },
        },
        arg1 = {
            {
                name = "input",
                type = "input_statement",
                text = "",
            },
        },
        category = "control", 
        helpUrl = "", 
        canRun = false,
        previousStatement = true,
        funcName = "while",
        nextStatement = true,
        func_description = 'while(%s){\\n%s\\n}',
        ToNPL = function(self)
            local input = self:getFieldAsString('input')
            return string.format('while(%s)\n{\n    %s\n}\n', self:getFieldAsString('expression'), input);
        end,
        ToCpp = function(self)
            local input = self:getFieldAsString('input')
            local block_indent = self:GetIndent();
            return string.format('while(%s){\n%s\n%s}\n', self:getFieldAsString('expression'), input, block_indent);
        end,
        examples = {{desc = "", canRun = true, code = [[
    ]]}},
    },

    {
        type = "ForControl", 
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
        category = "control", 
        helpUrl = "", 
        canRun = false,
        previousStatement = true,
        nextStatement = true,
        funcName = "for",
        func_description = 'for(int %s = %s; i <= %s; i++) {\\n%s\\n}',
        ToNPL = function(self)
            local input = self:getFieldAsString('input')
            local var = self:getFieldValue('var');
            return string.format('for(int %s = %s; %s <= %s; %s++)\n{\n    %s\n}\n', 
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
        type = "DoWhileControl", 
        message0 = L"重复执行%1",
        message1 = L"只要%1",
        arg0 = {
            {
                name = "input",
                type = "input_statement",
                text = "",
            },

        },
        arg1 = {
            {
                name = "expression",
                type = "input_value",
                text = "", 
            },
        },
        category = "control", 
        helpUrl = "", 
        canRun = false,
        previousStatement = true,
        nextStatement = true,
        func_description = 'do{\n%s}while(%s);',
        ToNPL = function(self)
            local input = self:getFieldAsString('input')
            local expression = self:getFieldAsString('expression')
            return string.format('do\n{\n    %s\n}while(%s);\n', input, expression);
        end,
        ToCpp = function(self)
            local input = self:getFieldAsString('input');
            local expression = self:getFieldAsString('expression')
            local block_indent = self:GetIndent();
            return string.format('do{\n%s\n%s}while(%s);\n', input, block_indent, expression);
        end,
        examples = {{desc = "", canRun = true, code = [[
    ]]}},
    },

    {
        type = "IfControl", 
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
        category = "control", 
        helpUrl = "", 
        canRun = false,
        funcName = "if",
        previousStatement = true,
        nextStatement = true,
        func_description = 'if(%s){\n%s}',
        ToNPL = function(self)
            local input = self:getFieldAsString('input_true')
            return string.format('if(%s)\n{\n    %s\n}\n', self:getFieldAsString('expression'), input);
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
        type = "IfElseControl", 
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
        category = "control", 
        helpUrl = "", 
        canRun = false,
        previousStatement = true,
        nextStatement = true,
        func_description = 'if (%s){\\n%s}\\nelse{\\n%s}',
        ToNPL = function(self)
            local input_true = self:getFieldAsString('input_true')
            local input_else = self:getFieldAsString('input_else')
            return string.format('if (%s)\n{\n    %s\n}\nelse\n{\n    %s\n}\n', self:getFieldAsString('expression'), input_true, input_else);
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

    {
        type = "BreakControl", 
        message0 = L"跳出循环",
        arg0 = {
        },
        category = "control", 
        helpUrl = "", 
        canRun = false,
        previousStatement = true,
        nextStatement = true,
        func_description = 'break;',
        ToNPL = function(self)
            return string.format('break;\n');
        end,
        ToCpp = function(self)
            return string.format('break;\n');
        end,
        examples = {{desc = "", canRun = true, code = [[
    ]]}},
    },

-----------------------------------------------------------operator--------------------------------------------------------------
    {
        type = "BaseOperator", 
        message0 = L"%1 %2 %3",
        arg0 = {
            {
                name = "left",
                type = "input_value",
                shadow = { type = "math_number", },
            },
            {
                name = "op",
                type = "field_dropdown",
                options = {
                    { "加", "+" },{ "减", "-" },{ "乘", "*" },{ "除", "/" },
                },
            },
            {
                name = "right",
                type = "input_value",
                shadow = { type = "math_number", },
            },
        },
        output = {type = "field_number",},
        category = "operator", 
        helpUrl = "", 
        canRun = false,
        func_description = '((%s) %s (%s))',
        ToNPL = function(self)
            return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'), self:getFieldAsString('right'));
        end,
        ToCpp = function(self)
            return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'), self:getFieldAsString('right'));
        end,
        examples = {{desc = L"数字的加减乘除", canRun = true, code = [[
    ]]}},
    },

    {
        type = "CompareOperator", 
        message0 = L"%1 %2 %3",
        arg0 = {
            {
                name = "left",
                type = "input_value",
                shadow = { type = "math_number", },
            },
            {
                name = "op",
                type = "field_dropdown",
                options = {
                    { "小于", "<" },
                    { "大于", ">" },
                    { "等于", "==" },
                    { "不等于", "!=" },
                    { "大于等于", ">=" },
                    { "小于等于", "<=" },
                },
            },
            {
                name = "right",
                type = "input_value",
                shadow = { type = "math_number", },
            },
        },
        output = {type = "field_number",},
        category = "operator", 
        helpUrl = "", 
        canRun = false,
        func_description = '((%s) %s (%s))',
        ToNPL = function(self)
            local op = self:getFieldAsString('op')
            if op == '~=' then
                op = '!='
            end
            return string.format('(%s) %s (%s)', self:getFieldAsString('left'), op, self:getFieldAsString('right'));
        end,
        examples = {{desc = "", canRun = true, code = [[

    ]]}},
    },

    {
        type = "LogicalOperator", 
        message0 = L"%1 %2 %3",
        arg0 = {
            {
                name = "left",
                type = "input_value",
            },
            {
                name = "op",
                type = "field_dropdown",
                options = {
                    { L"并且", "&&" },{ L"或", "||" },
                },
            },
            {
                name = "right",
                type = "input_value",
            },
        },
        output = {type = "field_number",},
        category = "operator", 
        helpUrl = "", 
        canRun = false,
        func_description = '((%s) %s (%s))',
        ToNPL = function(self)
            return string.format('(%s) %s (%s)', self:getFieldAsString('left'), self:getFieldAsString('op'),self:getFieldAsString('right'));
        end,
        examples = {{desc = L"同时满足条件", canRun = true, code = [[
    ]]}},
    },

    {
        type = "NotOperator", 
        message0 = L"不满足%1",
        arg0 = {
            {
                name = "left",
                type = "input_value",
            },
        },
        output = {type = "field_number",},
        category = "operator", 
        helpUrl = "", 
        canRun = false,
        funcName = "not",
        func_description = '(! (%s))',
        ToNPL = function(self)
            return string.format('(! (%s))', self:getFieldAsString('left'));
        end,
        examples = {{desc = L"是否不为真", canRun = true, code = [[
    ]]}},
    },

-----------------------------------------------------------variable--------------------------------------------------------------
    {
        type = "InitVariable", 
        message0 = L"%1 %2 初始化为 %3",
        arg0 = {
            {
                name = "value_type",
                type = "field_dropdown",
                options = {
                    { L"整数", "int" },
                    { L"浮点数", "float" },
                    { L"字符", "char" },
                    { L"字符串", "string" },
                },
                text = "int"
            },
            {
                name = "var",
                type = "field_variable",
                variable = L"变量名",
                text = L"变量名",
            },
            {
                name = "value",
                type = "input_value",
                text = L"",
            },
        },
        output = {type = "null",},
        category = "variable", 
        helpUrl = "", 
        canRun = false,
        previousStatement = true,
        nextStatement = true,
        func_description = '%s %s = %s;',
        ToNPL = function(self)
            return string.format('%s %s = %s;\n', self:getFieldAsString('value_type'), self:getFieldAsString('var'), self:getFieldAsString('value'));
        end,
        ToCpp = function(self)
            local var = commonlib.Encoding.toValidParamName(self:getFieldAsString('var'))
            local varType = self:getFieldAsString('value_type')
            local value = self:getFieldAsString('value')
            -- if(varType == "float" or varType == "double" or varType == "int") then
            -- 	return string.format('%s %s = %s;', varType, var, value);
            -- elseif (varType == "char") then
            -- 	return string.format("%s %s = '%s';", varType, var, value);
            -- else
            -- 	return string.format('%s %s = %s;', varType, var, self:GetValueAsString("value"));
            -- end
            return string.format('%s %s = %s;', varType, var, value);
        end,
        examples = {{desc = "", canRun = true, code = [[
    ]]}},
    },

    {
        type = "AssignVariable", 
        message0 = L"%1 赋值为 %2",
        arg0 = {
            {
                name = "var",
                type = "field_variable",
                variable = L"变量名",
                text = L"变量名",
            },
            {
                name = "value",
                type = "input_value",
                text = L"",
            },
        },
        output = {type = "null",},
        category = "variable", 
        helpUrl = "", 
        canRun = false,
        previousStatement = true,
        nextStatement = true,
        func_description = '%s = %s;',
        ToNPL = function(self)
            return string.format('%s = %s;\n', self:getFieldAsString('var'), self:getFieldAsString('value'));
        end,
        ToCpp = function(self)
            local var = commonlib.Encoding.toValidParamName(self:getFieldAsString('var'))
            local value = self:getFieldAsString('value')
            return string.format('%s = %s;', var, value);
        end,
        examples = {{desc = "", canRun = true, code = [[
    ]]}},
    },

    {
        type = "GetVariable", 
        message0 = L"%1",
        arg0 = {
            {
                name = "var",
                type = "field_variable",
                text = L"变量名",
            },
        },
        output = {type = "null",},
        category = "variable", 
        helpUrl = "", 
        canRun = false,
        func_description = '%s',
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

-----------------------------------------------------------array--------------------------------------------------------------
    {
        type = "InitArray", 
        message0 = L"%1 %2 初始化为 %3",
        arg0 = {
            {
                name = "value_type",
                type = "field_dropdown",
                options = {
                    { L"整数", "int" },
                    { L"浮点数", "float" },
                    { L"字符串", "string" },
                },
                text = "int"
            },
            {
                name = "var",
                type = "field_variable",
                vartype = "array",
                text = L"数组名",
            },
            {
                name = "value",
                type = "input_value",
                text = L"",
            },
        },
        output = {type = "null",},
        category = "array", 
        helpUrl = "", 
        canRun = false,
        previousStatement = true,
        nextStatement = true,
        func_description = '%s %s[] = {%s};',
        ToNPL = function(self)
            return string.format('%s %s[] = {%s};\n', self:getFieldAsString('value_type'), self:getFieldAsString('var'), self:getFieldAsString('value'));
        end,
        ToCpp = function(self)
            local var = commonlib.Encoding.toValidParamName(self:getFieldAsString('var'))
            local varType = self:getFieldAsString('value_type')
            local value = self:getFieldAsString('value')
            -- if(varType == "float" or varType == "double" or varType == "int") then
            -- 	return string.format('%s %s = %s;', varType, var, value);
            -- elseif (varType == "char") then
            -- 	return string.format("%s %s = '%s';", varType, var, value);
            -- else
            -- 	return string.format('%s %s = %s;', varType, var, self:GetValueAsString("value"));
            -- end
            return string.format('%s %s[] = {%s};', varType, var, value);
        end,
        examples = {{desc = "", canRun = true, code = [[
    ]]}},
    },

	{
		type = "AccessArray", 
		message0 = L"访问 %1 %2",
		arg0 = {
			{
				name = "var",
				type = "field_variable",
				vartype = "array",
				text = L"数组名",
			},
			{
				name = "index",
				type = "input_value",
				text = "0",
			}
		},
		output = {type = "null",},
		category = "array", 
		helpUrl = "", 
		canRun = false,
		func_description = '%s[%s]',
		ToNPL = function(self)
			return string.format('%s[%s]', self:getFieldAsString('var'), self:getFieldAsString("index"));
		end,
		ToCpp = function(self)
			local var = self:getFieldAsString('var')
			return string.format('%s[%s]', commonlib.Encoding.toValidParamName(var), self:getFieldAsString("index"));
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

	{
		type = "AssignArray", 
		message0 = L"%1 %2 赋值为 %3",
		arg0 = {
			{
				name = "var",
				type = "field_variable",
				vartype = "array",
				text = L"数组名",
			},
			{
				name = "index",
				type = "input_value",
				text = "0",
			},
			{
				name = "value",
				type = "input_value",
				text = "",
			}
		},
		previousStatement = true,
		nextStatement = true,
		category = "array", 
		helpUrl = "", 
		canRun = false,
		func_description = '%s[%s] = %s;',
		ToNPL = function(self)
			return string.format('%s[%s] = %s;', self:getFieldAsString('var'), self:getFieldAsString("index"), self:getFieldAsString("value"));
		end,
		ToCpp = function(self)
			local var = self:getFieldAsString('var')
			return string.format('%s[%s] = %s;', commonlib.Encoding.toValidParamName(var), self:getFieldAsString("index"), self:getFieldAsString("value"));
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},
-----------------------------------------------------------function-----------------------------------------------------------
	{
		type = "DefineFunction", 
		message0 = L"函数 %1",
		message1 = L"%1",
		arg0 = {
			{
				name = "func_name",
				type = "input_value",
				text = "name"
			},
		},
		arg1 = {
			{
				name = "func_body",
				type = "input_statement",
				text = "",
			},
		},
		category = "function", 
		helpUrl = "", 
		canRun = false,
		previousStatement = true,
		nextStatement = true,
		func_description = 'void %s(){\\n%s\\n}',
		ToNPL = function(self)
			return string.format('void %s()\n{\n    %s\n}\n', self:getFieldAsString('func_name'), self:getFieldAsString('func_body'));
		end,
		ToCpp = function(self)
			local block_indent = self:GetIndent();
			return string.format('void %s(){\n%s\n%s}\n',  commonlib.Encoding.toValidParamName(self:getFieldAsString('func_name')), block_indent, func_body);
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

    {
		type = "CallFunction", 
		message0 = L"调用函数 %1",
		arg0 = {
			{
				name = "func_name",
				type = "input_value",
				text = L"name",
			},
		},
		output = {type = "null",},
		category = "function", 
		helpUrl = "", 
		canRun = false,
		func_description = '%s[%s]',
		ToNPL = function(self)
			return string.format('%s()', self:getFieldAsString('func_name'));
		end,
		ToCpp = function(self)
			return string.format('%s()',  commonlib.Encoding.toValidParamName(self:getFieldAsString('func_name')));
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

    {
		type = "ReturnFunction", 
		message0 = L"返回",
		arg0 = {
		},
		output = {type = "null",},
		category = "function", 
		helpUrl = "", 
		canRun = false,
		func_description = 'return',
		ToNPL = function(self)
			return string.format('return;\n');
		end,
		ToCpp = function(self)
			return string.format('return;\n');
		end,
		examples = {{desc = "", canRun = true, code = [[
	]]}},
	},

-----------------------------------------------------------function-----------------------------------------------------------
    {
        type = "SleepApi", 
        message0 = L"等待 %1毫秒",
        arg0 = {
            {
                name = "times",
                type = "input_value",
                shadow = { type = "math_number", value = 10,},
                text = 10, 
            },
        },
        category = "api", 
        helpUrl = "", 
        canRun = false,
        previousStatement = true,
        nextStatement = true,
        func_description = 'sleep(%s);',
        ToNPL = function(self)
            return string.format('sleep(%s);\n', self:getFieldAsString('time'));
        end,
        ToCpp = function(self)
            return string.format('sleep(%s);\n', self:getFieldAsString('time'));
        end,
        examples = {{desc = "", canRun = true, code = [[
    ]]}},
    },

    {
        type = "RandApi", 
        message0 = L"随机数",
        arg0 = {
        },
        category = "api", 
		output = {type = "math_number",},
        helpUrl = "", 
        previousStatement = true,
        nextStatement = true,
        func_description = 'rand()',
        ToNPL = function(self)
            return string.format('rand()');
        end,
        ToCpp = function(self)
            return string.format('rand()');
        end,
        examples = {{desc = "", canRun = true, code = [[
    ]]}},
    },

    {
        type = "SrandApi", 
        message0 = L"随机种子",
        arg0 = {
            {
                name = "value",
                type = "input_value",
                shadow = { type = "math_number", value = 10,},
                text = 10, 
            },
        },
        category = "api", 
        previousStatement = true,
        nextStatement = true,
        helpUrl = "", 
        canRun = false,
        funcName = "sleep",
        func_description = 'srand(%s)',
        ToNPL = function(self)
            return string.format('srand(%s)', self:getFieldAsString('value'));
        end,
        ToCpp = function(self)
            return string.format('srand(%s)', self:getFieldAsString('value'));
        end,
        examples = {{desc = "", canRun = true, code = [[
    ]]}},
    },

});