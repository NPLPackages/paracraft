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
	type = "window", 
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
	category = "window", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = 'window',
	func_description = 'window([[\\n%s\\n]], "%s", %s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('window([[%s]],"%s", %s, %s, %s, %s)\n', self:getFieldAsString('mcmlCode'), 
			self:getFieldAsString('alignment'), self:getFieldAsString('left'), self:getFieldAsString('top'), self:getFieldAsString('width'), self:getFieldAsString('height'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "tag_div", 
	message0 = "<div ",
	message1 = " style='%1' %2/>",
	message2 = "%1",
	message3 = "</div>",
	arg1 = {
		{
			name = "style",
			type = "input_value",
			shadow = { type = "text"},
			text = "", 
		},
		{
			name = "attrs",
			type = "input_value",
			shadow = { type = "text"},
		},
	},
	arg2 = {
		{
			name = "code",
			type = "input_statement",
		},
	},
	category = "window", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '<div style=%s %s/>%s</div>',
	ToNPL = function(self)
		return string.format('<div style="%s" %s/>%s</div>\n', self:getFieldAsString('style'), self:getFieldAsString('attrs'), 
			self:getFieldAsString('code')
			);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

---------------------
})
