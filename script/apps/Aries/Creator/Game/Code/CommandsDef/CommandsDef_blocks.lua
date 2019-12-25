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
	type = "cmd_mode", 
	message0 = L"设置编辑模式%1",
	arg0 = {
		{
			name = "input",
            type = "field_dropdown",
			options = {
				{ L"游戏模式", "game" },{ L"编辑模式", "edit" },
			},
			text = "game"
		},
	},
	category = "CommandBlocks", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "mode",
	func_description = '/mode %s',
	ToNPL = function(self)
		return string.format('/mode %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "functionParams", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_input",
			text = ""
		},
	},
	hide_in_toolbox = true,
	category = "CommandBlocks", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '%s',
    colourSecondary = "#ffffff",
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "cmd_setblock", 
	message0 = L"创建方块在%1, ID%2",
	arg0 = {
		{
			name = "input",
            type = "field_input",
			text = ""
		},
		{
			name = "input2",
            type = "field_input",
			text = ""
		},
	},
	category = "CommandBlocks", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "setblock",
	func_description = '/setblock %s %s',
	ToNPL = function(self)
		return string.format('/setblock %s %s\n', self:getFieldAsString('input'), self:getFieldAsString('input2'));
	end,
},
-------------------
})
