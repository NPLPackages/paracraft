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
	type = "mcml_div", 
	message0 = "<div %1%2%3>",
	message1 = "%1",
	message2 = "</div>",
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
            self:getFieldAsString('code')
        );
	end,
	examples = {{desc = "", canRun = false, code = [[
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
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_button", 
	message0 = "<button  %1%2%3/>",
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
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_label", 
	message0 = "<label  %1%2%3/>",
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
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_text", 
	message0 = "<text  %1%2%3/>",
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
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_checkbox", 
	message0 = "<checkbox  %1%2%3/>",
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
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_progressbar", 
	message0 = "<progressbar %1%2%3/>",
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
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_sliderbar", 
	message0 = "<sliderbar %1%2%3/>",
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
	examples = {{desc = "", canRun = false, code = [[
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
	examples = {{desc = "", canRun = false, code = [[
]]}},
},


---------------------
})
