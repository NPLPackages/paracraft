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
	canRun = true,
	func_description = '%s:%s;',
	ToNPL = function(self)
		return string.format('%s:%s;',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "mcml_styles_key_value", 
	message0 = "%1:%2;",
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
                { "padding", "padding"},
				{ "paddingn-left", "padding-left"},
				{ "padding-top", "padding-top"},
				{ "padding-right", "padding-right"},
				{ "padding-bottom", "padding-bottom"},
                { "width", "width"},
                { "height", "height"},
                { "background", "background"},
                { "background-color", "background-color"},
                { "font-size", "font-size"},
                { "bold", "bold"},
			},
		},
         {
			name = "value",
            type = "input_value",
			shadow = { type = "text"},
		},
	},
    output = {type = "null",},
	category = "McmlStyles", 
	helpUrl = "", 
	canRun = true,
	func_description = '%s:%s;',
	ToNPL = function(self)
		return string.format('%s:%s;',self:getFieldValue('key'),self:getFieldValue('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},



---------------------
})
