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
	type = "cmd_shader", 
	message0 = L"显示画面效果%1",
	arg0 = {
		{
			name = "input",
			type = "field_dropdown",
            options = {
				{ L"低", "1" },{ L"中", "2" },{ L"高", "3" },
			},
			text = "2"
		},
	},
	category = "CommandGlobal", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "shader",
	func_description = '/shader %s',
	ToNPL = function(self)
		return string.format('/shader %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_tip", 
	message0 = L"提示%1",
	arg0 = {
		{
			name = "input",
            type = "field_input",
			text = ""
		},
	},
	category = "CommandGlobal", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "tip",
	func_description = '/tip %s',
	ToNPL = function(self)
		return string.format('/tip %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_clearbag", 
	message0 = L"清空背包",
	category = "CommandGlobal", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "clearbag",
	func_description = '/clearbag',
	ToNPL = function(self)
		return string.format('/clearbag\n');
	end,
},

{
	type = "cmd_time", 
	message0 = L"改变时间%1",
	arg0 = {
		{
			name = "input",
			type = "field_number",
            text = 0
		},
	},
	category = "CommandGlobal", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "time",
	func_description = '/time %s',
	ToNPL = function(self)
		return string.format('/time %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_light", 
	message0 = L"设置光源颜色%1",
	arg0 = {
		{
			name = "input",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000",
		},
	},
	category = "CommandGlobal", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "light",
	func_description = '/light %s',
	ToNPL = function(self)
		return string.format('/light %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_sun", 
	message0 = L"设置太阳颜色%1",
	arg0 = {
		{
			name = "input",
			type = "input_value",
            shadow = { type = "colour_picker", value = "#ff0000",},
			text = "#ff0000",
		},
	},
	category = "CommandGlobal", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "sun",
	func_description = '/sun %s',
	ToNPL = function(self)
		return string.format('/sun %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_lod", 
	message0 = L"多分辨率模型%1",
	arg0 = {
		{
			name = "input",
			type = "field_dropdown",
            options = {
				{ L"开启", "on" },{ L"关闭", "off" }
			},
			text = "off"
		},
	},
	category = "CommandGlobal", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "lod",
	func_description = '/lod %s',
	ToNPL = function(self)
		return string.format('/lod %s\n', self:getFieldAsString('input'));
	end,
},
---------------------
})
