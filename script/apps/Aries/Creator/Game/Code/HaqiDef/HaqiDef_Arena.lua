--[[
Title: Block Pen
Author(s): LiXizhi
Date: 2020/2/16
Desc: 
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.export({
-----------------------
{
	type = "createArena", 
	message0 = "创建法阵 %1",
	arg0 = {
		{
			name = "speed",
			type = "input_value",
			shadow = { type = "math_number", value = 2,},
			text = 2, 
		},
	},
	category = "arena", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'createArena(%s)',
	ToNPL = function(self)
		return string.format('createArena(%s)\n', self:getFieldValue('speed'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},
-----------------------

});