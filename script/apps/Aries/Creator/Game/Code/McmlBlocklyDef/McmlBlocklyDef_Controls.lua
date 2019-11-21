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
	type = "mcml_window", 
	message0 = "创建窗口",
	message1 = "%1",
	message2 = "%1,%2,%3,%4,%5",
	arg1 = {
		{
			name = "mcmlCode",
			type = "input_statement",
		},
	},
	arg2 = {
		{
			name = "alignment",
			type = "field_dropdown",
			options = {
				{ "左上", "_lt" },
				{ "左下", "_lb" },
				{ "居中", "_ct" },
				{ "居中上", "_ctt" },
				{ "居中下", "_ctb" },
				{ "居中左", "_ctl" },
				{ "居中右", "_ctr" },
				{ "右上", "_rt" },
				{ "右下", "_rb" },
				{ "中间上", "_mt" },
				{ "中间左", "_ml" },
				{ "中间右", "_mr" },
				{ "中间下", "_mb" },
				{ "全屏", "_fi" },
			},
			text = "_lt", 
		},
		{
			name = "left",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
		{
			name = "top",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0,
		},
		{
			name = "width",
			type = "input_value",
            shadow = { type = "math_number", value = 300,},
			text = 300,
		},
		{
			name = "height",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100,
		},
	},
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	funcName = 'McmlControls',
	func_description = 'window([[\\n%s\\n]], "%s", %s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('window([[%s]],"%s", %s, %s, %s, %s)\n', self:getFieldAsString('mcmlCode'), 
			self:getFieldAsString('alignment'), self:getFieldAsString('left'), self:getFieldAsString('top'), self:getFieldAsString('width'), self:getFieldAsString('height'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "mcml_div", 
	message0 = "<div %1%2%3>",
	message1 = "%1",
	message2 = "</div>",
	arg0 = {
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
        {
			name = "start_dummy",
			type = "input_dummy",
		},
        {
			name = "end_dummy",
			type = "input_dummy",
		},
	},
	arg1 = {
		{
			name = "code",
			type = "input_statement",
		},
	},
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_lua_provider = [[
        var attrs = Blockly.Extensions.readTextFromMcmlAttrs(block, "Lua");
        var code = Blockly.Lua.statementToCode(block, 'code') || '';
        if (attrs) {
            return "<div %s>\n%s</div>\n".format(attrs,code)
        }else{
            return "<div>\n%s</div>\n".format(code)
        }
    ]],
	ToNPL = function(self)
		return string.format('<div>\n%s\n</div>\n', 
        self:getFieldAsString('code'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_button", 
	message0 = "<button  %1%2%3/>",
	arg0 = {
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
        {
			name = "start_dummy",
			type = "input_dummy",
		},
        {
			name = "end_dummy",
			type = "input_dummy",
		},
	},
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_lua_provider = [[
        return Blockly.Extensions.getMcmlControlText(block, "button", "Lua");
    ]],
	ToNPL = function(self)
		return string.format('<input type="button"/>');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_label", 
	message0 = "<label  %1%2%3/>",
	arg0 = {
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
        {
			name = "start_dummy",
			type = "input_dummy",
		},
        {
			name = "end_dummy",
			type = "input_dummy",
		},
	},
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_lua_provider = [[
        return Blockly.Extensions.getMcmlControlText(block, "pe:label", "Lua");
    ]],
	ToNPL = function(self)
		return string.format('<pe:label />');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_text", 
	message0 = "<text  %1%2%3/>",
	arg0 = {
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
        {
			name = "start_dummy",
			type = "input_dummy",
		},
        {
			name = "end_dummy",
			type = "input_dummy",
		},
	},
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_lua_provider = [[
        return Blockly.Extensions.getMcmlControlText(block, "input type='text'", "Lua");
    ]],
	ToNPL = function(self)
		return string.format('<input type="text" />');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_checkbox", 
	message0 = "<checkbox  %1%2%3/>",
	arg0 = {
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
         {
			name = "start_dummy",
			type = "input_dummy",
		},
        {
			name = "end_dummy",
			type = "input_dummy",
		},
	},
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
    func_description_lua_provider = [[
        return Blockly.Extensions.getMcmlControlText(block, "input type='checkbox'", "Lua");
    ]],
	ToNPL = function(self)
		return string.format('<input type="checkbox" />');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_progressbar", 
	message0 = "<progressbar %1%2%3/>",
	arg0 = {
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
         {
			name = "start_dummy",
			type = "input_dummy",
		},
        {
			name = "end_dummy",
			type = "input_dummy",
		},
	},
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_lua_provider = [[
        return Blockly.Extensions.getMcmlControlText(block, "pe:progressbar", "Lua");
    ]],
	ToNPL = function(self)
		return string.format('<pe:progressbar />');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_sliderbar", 
	message0 = "<sliderbar %1%2%3/>",
	arg0 = {
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
         {
			name = "start_dummy",
			type = "input_dummy",
		},
        {
			name = "end_dummy",
			type = "input_dummy",
		},
	},
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description_lua_provider = [[
        return Blockly.Extensions.getMcmlControlText(block, "pe:sliderbar", "Lua");
    ]],
	ToNPL = function(self)
		return string.format('<pe:sliderbar />');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_pure_text", 
	message0 = "%1",
    arg0 = {
        {
			name = "value",
            type = "field_input",
			text = "",
		},
	},
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s',self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_br", 
	message0 = "<br/>",
	category = "McmlControls", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '<br/>',
	ToNPL = function(self)
		return '<br/>';
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


---------------------
})
