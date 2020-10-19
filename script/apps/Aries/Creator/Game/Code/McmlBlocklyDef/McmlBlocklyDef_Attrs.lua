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
	type = "mcml_attrs_style_key_value", 
	message0 = "%1 = \"%2\"%3%4",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "style", "style"},
			},
		},
       
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
    output = {type = "null",},
	category = "McmlAttrs", 
	helpUrl = "", 
	canRun = false,
	func_description_lua_provider = [[
        var key_value = block.getFieldValue("key");
        var attrs_value = Blockly.Extensions.readTextFromMcmlAttrs(block,"Lua");
        var s = key_value + "='" + attrs_value + "'"
        return [s];
    ]],
	ToNPL = function(self)
		return string.format('%s="%s"',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

{
	type = "mcml_attrs_key_value_onclick", 
	message0 = "%1 = \"%2\"",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "onclick", "onclick"},
			},
		},
         {
			name = "value",
			type = "input_value",
			shadow = { type = "text"},
		},
      
	},
    output = {type = "null",},
	category = "McmlAttrs", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s=%s',
	ToNPL = function(self)
		return string.format('%s=%s',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
{
	type = "mcml_attrs_key_value", 
	message0 = "%1 = \"%2\"",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "value", "value"},
				{ "name", "name"},
				{ "class", "class"},
				{ "align", "align"},
				{ "checked", "checked"},
				{ "Minimum", "Minimum"},
				{ "Maximum", "Maximum"},
				{ "min", "min"},
				{ "max", "max"},
				{ "setter", "setter"},
				{ "getter", "getter"},
				{ "tooltip", "tooltip"},
			},
		},
         {
			name = "value",
			type = "input_value",
			shadow = { type = "text"},
		},
      
	},
    output = {type = "null",},
	category = "McmlAttrs", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s=%s',
	ToNPL = function(self)
		return string.format('%s=%s',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
{
	type = "mcml_attrs_align_key_value", 
	message0 = "%1 = \"%2\"",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "align", "align"},
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
	category = "McmlAttrs", 
	helpUrl = "", 
	canRun = false,
	func_description = '%s="%s"',
	ToNPL = function(self)
		return string.format('%s="%s"',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},

---------------------
})
