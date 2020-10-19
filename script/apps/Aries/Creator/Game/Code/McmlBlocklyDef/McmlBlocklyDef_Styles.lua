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
	type = "mcml_styles_float_key_value", 
	message0 = "%1:%2;",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "float", "float"},
                { "text-align", "text-align"},
			},
		},
         {
			name = "value",
			type = "field_dropdown",
            options = {
				{ "left", "left"},
				{ "center", "center"},
				{ "right", "right"},
			},
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s:%s;',
	ToNPL = function(self)
		return string.format('%s:%s;',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_styles_key_value_margin_pixel", 
	message0 = "%1:%2%3;",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "margin", "margin"},
				{ "margin-left", "margin-left"},
				{ "margin-top", "margin-top"},
				{ "margin-right", "margin-right"},
				{ "margin-bottom", "margin-bottom"},
			},
		},
         {
			name = "value",
            type = "input_value",
			shadow = { type = "math_number", value = 0, },
            text = 0,
		},
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "px", "px"},
			},
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s:%s%s;',
	ToNPL = function(self)
		return string.format('%s:%s%s;',self:getFieldValue('key'),self:getFieldValue('value'),self:getFieldValue('unit'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_styles_key_value_padding_pixel", 
	message0 = "%1:%2%3;",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "padding", "padding"},
				{ "paddingn-left", "padding-left"},
				{ "padding-top", "padding-top"},
				{ "padding-right", "padding-right"},
				{ "padding-bottom", "padding-bottom"},
			},
		},
         {
			name = "value",
            type = "input_value",
			shadow = { type = "math_number", value = 0, },
            text = 0,
		},
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "px", "px"},
			},
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s:%s%s;',
	ToNPL = function(self)
		return string.format('%s:%s%s;',self:getFieldValue('key'),self:getFieldValue('value'),self:getFieldValue('unit'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_styles_key_value_width_pixel", 
	message0 = "%1:%2%3;",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "width", "width"},
                { "height", "height"},
			},
		},
         {
			name = "value",
            type = "input_value",
			shadow = { type = "math_number", value = 100, },
            text = 100,
		},
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "px", "px"},
			},
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s:%s%s;',
	ToNPL = function(self)
		return string.format('%s:%s%s;',self:getFieldValue('key'),self:getFieldValue('value'),self:getFieldValue('unit'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_styles_key_value_font_size_pixel", 
	message0 = "%1:%2%3;",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "font-size", "font-size"},
			},
		},
         {
			name = "value",
            type = "input_value",
			shadow = { type = "math_number", value = 14, },
            text = 14,
		},
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "px", "px"},
			},
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s:%s%s;',
	ToNPL = function(self)
		return string.format('%s:%s%s;',self:getFieldValue('key'),self:getFieldValue('value'),self:getFieldValue('unit'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},


{
	type = "mcml_styles_font_weight", 
	message0 = "font-weight:%1;",
	arg0 = {
        {
			name = "value",
			type = "field_dropdown",
			options = {
                { "bold", "bold"},
			},
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = false,
	func_description = 'font-weight:%s;',
	ToNPL = function(self)
		return string.format('font-weight:%s;',self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_styles_key_value_color", 
	message0 = "%1:%2;",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "color", "color"},
                { "background-color", "background-color"},
			},
		},
         {
			name = "value",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = false,
    func_description_lua_provider = [[
        var key_value = block.getFieldValue("key");
        var text = Blockly.Lua.valueToCode(block, 'value');
        if (text) {
            var index = text.indexOf("\'");
            var last_index = text.lastIndexOf("\'");
            if (index > -1 && last_index > -1) {
                text = text.substr(index + 1, last_index - 1);
            }

        }
        return [key_value + ":" + text+";"]
    ]],
	ToNPL = function(self)
		return string.format('%s:%s;',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_styles_background", 
	message0 = "%1:url(%2);",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "background", "background"},
			},
		},
        {
			name = "value",
            type = "field_input",
			text = "",
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s:url(%s);',
	ToNPL = function(self)
		return string.format('%s:url(%s);',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},


{
	type = "mcml_styles_position", 
	message0 = "position:%1;",
	arg0 = {
        {
			name = "value",
			type = "field_dropdown",
            options = {
				{ "relative", "relative"},
				{ "static", "static"},
				{ "absolute", "absolute"},
			},
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = false,
	func_description = 'position:%s;',
	ToNPL = function(self)
		return string.format('position:%s;',self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

---------------------
})
