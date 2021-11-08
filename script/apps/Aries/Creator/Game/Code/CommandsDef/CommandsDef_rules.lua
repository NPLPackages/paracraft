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
	type = "cmd_fps", 
	message0 = L"设置摄影机模式%1",
	arg0 = {
		{
			name = "input",
            type = "field_dropdown",
			options = {
				{ L"第一人称", "on" },{ L"第三人称", "off" },
			},
			text = "on"
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

{
	type = "cmd_addrule_player_canjump", 
	message0 = L"主角是否可以跳跃%1",
	arg0 = {
		{
			name = "input",
            type = "field_dropdown",
			options = {
				{ L"否", "false" }, { L"是", "true" },
			},
			text = "false"
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule Player CanJump %s',
	ToNPL = function(self)
		return string.format('/addrule Player CanJump %s\n', self:getFieldAsString('input'));
	end,
},


{
	type = "cmd_addrule_player_canfly", 
	message0 = L"主角是否可飞行%1",
	arg0 = {
		{
			name = "input",
            type = "field_dropdown",
			options = {
				{ L"否", "false" }, { L"是", "true" },
			},
			text = "false"
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule Player CanFly %s',
	ToNPL = function(self)
		return string.format('/addrule Player CanFly %s\n', self:getFieldAsString('input'));
	end,
},


{
	type = "cmd_addrule_player_canjumpinwater", 
	message0 = L"主角是否在水中可跳跃%1",
	arg0 = {
		{
			name = "input",
            type = "field_dropdown",
			options = {
				{ L"否", "false" }, { L"是", "true" },
			},
			text = "false"
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule Player CanJumpInWater %s',
	ToNPL = function(self)
		return string.format('/addrule Player CanJumpInWater %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_addrule_player_pickingdist", 
	message0 = L"主角鼠标点击范围%1",
	arg0 = {
		{
			name = "input",
			type = "field_number",
            text = 5
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule Player PickingDist %s',
	ToNPL = function(self)
		return string.format('/addrule Player PickingDist %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_addrule_player_autowalkupblock", 
	message0 = L"主角是否自动走上方块%1",
	arg0 = {
		{
			name = "input",
            type = "field_dropdown",
			options = {
				{ L"否", "false" }, { L"是", "true" },
			},
			text = "false"
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule Player AutoWalkupBlock %s',
	ToNPL = function(self)
		return string.format('/addrule Player AutoWalkupBlock %s\n', self:getFieldAsString('input'));
	end,
},


{
	type = "cmd_addrule_player_allowrunning", 
	message0 = L"主角是否可跑步%1",
	arg0 = {
		{
			name = "input",
            type = "field_dropdown",
			options = {
				{ L"否", "false" }, { L"是", "true" },
			},
			text = "false"
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule Player AllowRunning %s',
	ToNPL = function(self)
		return string.format('/addrule Player AllowRunning %s\n', self:getFieldAsString('input'));
	end,
},



{
	type = "cmd_addrule_player_jumpupspeed", 
	message0 = L"主角向上跳跃的速度%1",
	arg0 = {
		{
			name = "input",
			type = "field_number",
            text = 5
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule Player JumpUpSpeed %s',
	ToNPL = function(self)
		return string.format('/addrule Player JumpUpSpeed %s\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_addrule_block_candestroy", 
	message0 = L"设置方块%1可以被删除",
	arg0 = {
		{
			name = "input",
			type = "field_number",
            text = 62
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule Block CanDestroy %s',
	ToNPL = function(self)
		return string.format('/addrule Block CanDestroy %s true\n', self:getFieldAsString('input'));
	end,
},

{
	type = "cmd_addrule_block_canplace", 
	message0 = L"设置方块%1可以放到%2上",
	arg0 = {
		{
			name = "from",
			type = "field_number",
            text = 190
		},
		{
			name = "to",
			type = "field_number",
            text = 87
		},
	},
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule Block CanPlace %s %s',
	ToNPL = function(self)
		return string.format('/addrule Block CanPlace %s %s\n', self:getFieldAsString('from'), self:getFieldAsString('to'));
	end,
},

{
	type = "cmd_addrule_reset", 
	message0 = L"清空所有规则",
	category = "CommandRules", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = '/addrule reset',
	ToNPL = function(self)
		return '/addrule reset\n';
	end,
},
---------------------
})
