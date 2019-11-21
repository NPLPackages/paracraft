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
	type = "mcml_data_vlaue_px", 
	message0 = "%1%2",
	arg0 = {
        {
			name = "value",
			type = "input_value",
			shadow = { type = "math_number", value = 0,},
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
	category = "McmlData", 
	helpUrl = "", 
	canRun = true,
	func_description = '%s%s',
	ToNPL = function(self)
		return string.format('%s%s',self:getFieldValue('value'),self:getFieldValue('unit'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "mcml_data_vlaue_percent", 
	message0 = "%1%2",
	arg0 = {
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "%", "%"},
			},
		},
        {
			name = "value",
			type = "input_value",
			shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
        
	},
    output = {type = "null",},
	category = "McmlData", 
	helpUrl = "", 
	canRun = true,
	func_description = '%s%s',
	ToNPL = function(self)
		return string.format('%s%s',self:getFieldValue('value'),self:getFieldValue('unit'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "mcml_data_align", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ "left", "left" },
				{ "center", "center" },
				{ "right", "right" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "McmlData", 
	helpUrl = "", 
	canRun = true,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s',self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "mcml_data_label", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = "label",
		},
	},
	output = {type = "null",},
	category = "McmlData", 
	helpUrl = "", 
	canRun = true,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s',self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "mcml_data_string", 
	message0 = "\"%1\"",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = "string",
		},
	},
	output = {type = "null",},
	category = "McmlData", 
	helpUrl = "", 
	canRun = true,
	func_description = '"%s"',
	ToNPL = function(self)
		return string.format('"%s"',self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "mcml_data_number", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_number",
			text = "0",
		},
	},
	output = {type = "field_number",},
	category = "McmlData", 
	helpUrl = "", 
	canRun = true,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s',self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_data_boolean", 
	message0 = "%1",
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
	category = "McmlData", 
	helpUrl = "", 
	canRun = true,
	func_description = '%s',
	ToNPL = function(self)
		return string.format('%s',self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mcml_data_color", 
	message0 = "%1",
	arg0 = {
         {
			name = "value",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000", 
		},
	},
    output = {type = "null",},
	category = "McmlData", 
	helpUrl = "", 
	canRun = true,
	func_description_lua_provider = [[
        var text = Blockly.Lua.valueToCode(block, 'value');
        if (text) {
            var index = text.indexOf("\'");
            var last_index = text.lastIndexOf("\'");
            if (index > -1 && last_index > -1) {
                text = text.substr(index + 1, last_index - 1);
            }

        }
        return [text]
    ]],
	ToNPL = function(self)
		return string.format('%s',self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

---------------------
})
