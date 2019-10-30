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
	type = "attribute", 
	message0 = "向上移动",
	arg0 = {
	},
	category = "attribute", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'attribute()',
	ToNPL = function(self)
		return string.format('attribute()\n');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

---------------------
})
