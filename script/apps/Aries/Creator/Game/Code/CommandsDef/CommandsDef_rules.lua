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
	type = "cmd_addrule", 
	message0 = L"添加规则%1",
	arg0 = {
		{
			name = "input",
            type = "field_input",
			text = ""
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "addrule",
	func_description = '/addrule %s',
	ToNPL = function(self)
		return string.format('/addrule %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_mode", 
	message0 = L"设置摄影机模式%1",
	arg0 = {
		{
			name = "input",
            type = "field_dropdown",
			options = {
				{ L"第一人称", "on" },{ L"第三人称", "off" },
			},
			text = "game"
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "fps",
	func_description = '/fps %s',
	ToNPL = function(self)
		return string.format('/fps %s\n', self:getFieldAsString('input'));
	end,
},
---------------------
})
