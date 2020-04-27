--[[
Title: NplCadDef_Data
Author(s): leio
Date: 2018/9/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCadDef/NplCadDef_Data.lua");
local NplCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Data");
-------------------------------------------------------
]]
local NplCadDef_Data = commonlib.gettable("MyCompany.Aries.Game.Code.NplCad.NplCadDef_Data");
local cmds = {

{
	type = "getLocalVariable", 
	message0 = L"%1",
	arg0 = {
		{
			name = "var",
			type = "field_input",
			text = L"变量名",
		},
	},
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
    colourSecondary = "#ffffff",
	func_description = '%s',
	func_description_js = '%s',
	ToNPL = function(self)
		return self:getFieldAsString('var');
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},

{
	type = "createLocalVariable", 
	message0 = L"新建本地%1为%2",
	arg0 = {
		{
			name = "var",
			type = "field_input",
			text = L"变量名",
		},
		{
			name = "value",
			type = "input_value",
			shadow = { type = "functionParams", value = "0",},
			text = "0",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'local %s = %s',
	func_description_js = 'var %s = %s',
	ToNPL = function(self)
		return 'local key = "value"\n';
	end,
	examples = {{desc = "", canRun = true, code = [[
local key = "value"
say(key, 1)
]]}},
},

{
	type = "assign", 
	message0 = L"%1赋值为%2",
	arg0 = {
		{
			name = "left",
			type = "input_value",
			shadow = { type = "getLocalVariable", value = L"变量名",},
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
	previousStatement = true,
	nextStatement = true,
	func_description = '%s = %s',
	func_description_js = '%s = %s',
	ToNPL = function(self)
		return 'key = "value"\n';
	end,
	examples = {{desc = "", canRun = true, code = [[
text = "hello"
say(text, 1)
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
	func_description_js = '"%s"',
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
				{ "true", "true" },
				{ "false", "false" },
				{ "nil", "nil" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
	func_description_js = '%s',
	ToNPL = function(self)
		return self:getFieldAsString("value");
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
	func_description_js = '%s',
	ToNPL = function(self)
		return string.format('%s', self:getFieldAsString('left'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "newEmptyTable", 
	message0 = L"{%1%2%3}",
	arg0 = {
        {
			name = "start_dummy",
			type = "input_dummy",
		},
        {
			name = "end_dummy",
			type = "input_dummy",
		},
        {
            name = "btn",
            type = "field_button",
            content = {
                src = "png/plus-2x.png"
            },
            width = 16,
            height = 16,
            callback = "FIELD_BUTTON_CALLBACK_append_mcml_attr"
        },
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description_lua_provider = [[
        var attrs = Blockly.Extensions.readTextFromMcmlAttrs(block, "Lua", ",");
        if (attrs) {
            return ["{%s}".format(attrs), Blockly.Lua.ORDER_ATOMIC];
        }else{
            return ["{}", Blockly.Lua.ORDER_ATOMIC];
        }
    ]],
	ToNPL = function(self)
		return "{}";
	end,
	examples = {{desc = "", canRun = true, code = [[
local t = {}
t[1] = "hello"
t["age"] = 10;
log(t)
]]}},
},

{
	type = "getTableValue", 
	message0 = L"%1中的%2",
	arg0 = {
		{
			name = "table",
			type = "input_value",
			shadow = { type = "functionParams", value = "_G",},
			text = "_G", 
		},
		{
			name = "key",
			type = "input_value",
			shadow = { type = "text", value = "key",},
			text = "key", 
		},
	},
	output = {type = "field_number",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s[%s]',
	ToNPL = function(self)
		return string.format('%s["%s"]', self:getFieldAsString('table'), self:getFieldAsString('key'));
	end,
	examples = {{desc = "", canRun = true, code = [[
local t = {}
t[1] = "hello"
t["age"] = 10;
log(t)
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
	func_description = 'function %s(%s)\\n%send',
    ToPython = function(self)
		local input = self:getFieldAsString('input')
		if input == '' then
			input = 'pass'
		end
		return string.format('def %s(%s):\n    %s\n', self:getFieldAsString('name'), self:getFieldAsString('param'), input);
	end,
	ToNPL = function(self)
		return string.format('function %s(%s)\n    %s\nend\n', self:getFieldAsString('name'), self:getFieldAsString('param'), self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
function intersected()
  pushNode("union","intersected",'#ffc658',true)
    sphere("union",1,'#ffc658')
    cube("intersection",1.5,'#ffc658')
  popNode()
end
function holes()
  pushNode("difference","holes",'#ffc658',true)
    cylinder("union",0.5,2,'#ffc658')
    cylinder("union",0.5,2,'#ffc658')
    rotate('x',90)
    cylinder("union",0.5,2,'#ffc658')
    rotate('z',90)
  popNode()
end
pushNode("union","object0",'#ffc658',true)
  intersected("")
  holes("")
popNode()
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
	examples = {{desc = "", canRun = true, code = [[
function f(x)
    return 0.5 * x
end

function g(x)
    return {x, f(x) * f(x), 0}
end

for a = -10, 10, 2 do
    cube("union",1,"#ffc658")
    move(a,f(a),0)
end

for a = -10, 10, 1 do
    sphere("union",0.5,"#ffc658")
    local t = g(a)
    move(t[1], t[2], t[3])
end
	]]}},
},

{
	type = "code_block", 
	message0 = L"代码%1",
	message1 = L"%1",
    arg0 = {
		{
			name = "label_dummy",
			type = "input_dummy",
			text = "",
		},
	},
	arg1 = {
		{
			name = "codes",
			type = "field_input",
			text = "",
		},
	},
	hide_in_toolbox = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s',
	func_description_js = '%s',
	ToNPL = function(self)
		return string.format('%s\n', self:getFieldAsString('codes'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},

{
	type = "code_comment", 
	message0 = L"-- %1",
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
	func_description = '-- %s',
	func_description_js = '// %s',
	ToNPL = function(self)
		return string.format('-- %s', self:getFieldAsString('value'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},

{
	type = "code_comment_full", 
	message0 = L"注释全部 %1",
	message1 = "%1",
	message2 = "%1",
    arg0 = {
		{
			name = "label_dummy",
			type = "input_dummy",
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
    arg2 = {
		{
			name = "label_dummy",
			type = "input_dummy",
			text = "",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '--[[\\n%s\\n]]',
	func_description_js = '/**\\n%s\\n*/',
    ToPython = function(self)
		return string.format('"""\n%s\n"""', self:getFieldAsString('input'));
	end,
	ToNPL = function(self)
		return string.format('--[[\n%s\n]]', self:getFieldAsString('input'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},

{
	type = "data_variable", 
	message0 = L"%1",
    lastDummyAlign0 = "CENTRE",
	arg0 = {
		{
			name = "VARIABLE",
			type = "field_variable_getter",
			text = "i",
            variableType = "",
		},
	},
    colour = "#ff8c1a",
	hide_in_toolbox = true,
    checkboxInFlyout = false,
	output = {type = "null",},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	func_description_js = '"%s"',
	ToNPL = function(self)
		return string.format('"%s"', self:getFieldAsString('VARIABLE'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
]]}},
},

{
	type = "print3d", 
	message0 = L"打印 %1",
    arg0 = {
        
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"需要", "true" },
				{ L"不需要", "false" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'print3d(%s)',
	func_description_js = 'print3d(%s)',
	ToNPL = function(self)
        return string.format('print3d(%s)', 
            self:getFieldValue('value')
            );
	end,
	examples = {{desc = "", canRun = true, code = [[
    ]]}},
},

{
	type = "setMaxTrianglesCnt", 
	message0 = L"模型三角形最大数量: %1",
	arg0 = {
		{
			name = "value",
			type = "field_number",
			text = "-1",
		},
	},
	category = "Data", 
	helpUrl = "", 
	canRun = false,
	nextStatement = true,
	func_description = 'setMaxTrianglesCnt(%s)',
	ToNPL = function(self)
		return string.format('setMaxTrianglesCnt(%s)', self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
};
function NplCadDef_Data.GetCmds()
	return cmds;
end
