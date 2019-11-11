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
	type = "mcml_attrs_key_value", 
	message0 = "%1 = \"%2\"",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "name", "name"},
				{ "class", "class"},
				{ "align", "align"},
				{ "value", "value"},
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
	canRun = true,
	func_description = '%s=%s',
	ToNPL = function(self)
		return string.format('%s=%s',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
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
	canRun = true,
	func_description = '%s="%s"',
	ToNPL = function(self)
		return string.format('%s="%s"',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},
{
	type = "mcml_attrs_style_key_value", 
	message0 = "%1 = \"%2\"",
	arg0 = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "style", "style"},
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
	canRun = true,
	func_description = '%s="%s"',
	ToNPL = function(self)
		return string.format('%s="%s"',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},



---------------------
})
