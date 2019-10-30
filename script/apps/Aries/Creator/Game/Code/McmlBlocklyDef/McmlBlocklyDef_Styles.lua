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
	type = "style_width", 
	message0 = "向上移动",
	arg0 = {
	},
	category = "style", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'width;',
	ToNPL = function(self)
		return string.format('width\n');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

---------------------
})
