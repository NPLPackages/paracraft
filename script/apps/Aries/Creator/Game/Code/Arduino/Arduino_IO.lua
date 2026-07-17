--[[
Title: Arduino IO functions
Author(s): LiXizhi
Date: 2023/12/28
Desc:
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]

NPL.export({

{
	type = "arduino.digitalWrite", 
	message0 = L"写数字端口%1 %2",
	arg0 = {
		{
			name = "port",
			type = "field_dropdown",
			options = {
				{ "0", "0" },
				{ "1", "1" },
				{ "2", "2" },
				{ "3", "3" },
				{ "4", "4" },
				{ "5", "5" },
				{ "6", "6" },
				{ "7", "7" },
				{ "8", "8" },
				{ "9", "9" },
				{ "10", "10" },
				{ "11", "11" },
				{ "12", "12" },
				{ "13", "13" },
				{ "A0", "A0" },
				{ "A1", "A1" },
				{ "A2", "A2" },
				{ "A3", "A3" },
				{ "A4", "A4" },
				{ "A5", "A5" },
			  }
		},
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ "高电平", "HIGH" },
				{ "低电平", "LOW" },
			}
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "digitalWrite",
	func_description = 'digitalWrite(%s, %s);',
	ToNPL = function(self)
		local port = self:getFieldAsString('port')
		return string.format('digitalWrite(%s, %s);\n', port, self:getFieldAsString('value'));
	end,
	ToArduino = function(self)
		local port = self:getFieldAsString('port')
		self:GetBlockly():AddUniqueHeader(string.format("//setup pinMode(%s, OUTPUT);", port));
		return string.format('digitalWrite(%s, %s);\n', port, self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.analogWrite", 
	message0 = L"写模拟端口%1 %2",
	arg0 = {
		{
			name = "port",
			type = "field_dropdown",
			options = {
				{ "3", "3" },
				{ "4", "4" },
				{ "5", "5" },
				{ "6", "6" },
				{ "7", "7" },
				{ "8", "8" },
				{ "9", "9" },
				{ "10", "10" },
				{ "11", "11" },
			  }
		},
		{
			name = "value",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "analogWrite",
	func_description = 'analogWrite(%s, %s);',
	ToNPL = function(self)
		local port = self:getFieldAsString('port')
		return string.format('analogWrite(%s, %s);\n', port, self:getFieldAsString('value'));
	end,
	ToArduino = function(self)
		local port = self:getFieldAsString('port')
		self:GetBlockly():AddUniqueHeader(string.format("//setup pinMode(%s, OUTPUT);", port));
		return string.format('analogWrite(%s, %s);\n', port, self:getFieldAsString('value'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.digitalRead", 
	message0 = L"读数字端口%1",
	arg0 = {
		{
			name = "port",
			type = "field_dropdown",
			options = {
				{ "0", "0" },
				{ "1", "1" },
				{ "2", "2" },
				{ "3", "3" },
				{ "4", "4" },
				{ "5", "5" },
				{ "6", "6" },
				{ "7", "7" },
				{ "8", "8" },
				{ "9", "9" },
				{ "10", "10" },
				{ "11", "11" },
				{ "12", "12" },
				{ "13", "13" },
				{ "A0", "A0" },
				{ "A1", "A1" },
				{ "A2", "A2" },
				{ "A3", "A3" },
				{ "A4", "A4" },
				{ "A5", "A5" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	funcName = "digitalRead",
	func_description = 'digitalRead(%s)',
	ToNPL = function(self)
		local port = self:getFieldAsString('port')
		return string.format('digitalRead(%s)', self:getFieldAsString('value'));
	end,
	ToArduino = function(self)
		local port = self:getFieldAsString('port')
		self:GetBlockly():AddUniqueHeader(string.format("//setup pinMode(%s, INPUT);", port));
		return string.format('digitalRead(%s)', port);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.analogRead", 
	message0 = L"读模拟端口%1",
	arg0 = {
		{
			name = "port",
			type = "field_dropdown",
			options = {
				{ "A0", "A0" },
				{ "A1", "A1" },
				{ "A2", "A2" },
				{ "A3", "A3" },
				{ "A4", "A4" },
				{ "A5", "A5" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	funcName = "analogRead",
	func_description = 'analogRead(%s)',
	ToNPL = function(self)
		local port = self:getFieldAsString('port')
		return string.format('analogRead(%s)', self:getFieldAsString('value'));
	end,
	ToArduino = function(self)
		local port = self:getFieldAsString('port')
		self:GetBlockly():AddUniqueHeader(string.format("//setup pinMode(%s, INPUT);", port));
		return string.format('analogRead(%s)', port);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.WeServo.write", 
	message0 = L"舵机%1 角度%2",
	arg0 = {
		{
			name = "port",
			type = "field_dropdown",
			options = {
				{ "端口A", "A" },
				{ "端口B", "B" },
				{ "端口C", "C" },
				{ "端口D", "D" },
			  }
		},
		{
			name = "angle",
			type = "input_value",
            shadow = { type = "math_number", value = 90,},
			text = 90, 
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "WeServo.write",
	func_description = 'servo_%s.write(%s)',
	ToNPL = function(self)
		local port = self:getFieldAsString('port')
		return string.format('servo_%s.write(%s);\n', port, self:getFieldAsString('angle'));
	end,
	headerText = "#include<WeELFMini.h>",
	ToArduino = function(self)
		local port = self:getFieldAsString('port')
		self:GetBlockly():AddUniqueHeader(string.format('WeServo servo_%s(PORT_%s);', port, port));
		return string.format('servo_%s.write(%s);\n', port, self:getFieldAsString('angle'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.We130DCMotor.dc130_A", 
	message0 = L"直流电机%1 速度%2",
	arg0 = {
		{
			name = "port",
			type = "field_dropdown",
			options = {
				{ "端口A", "A" },
				{ "端口B", "B" },
				{ "端口C", "C" },
				{ "端口D", "D" },
			  }
		},
		{
			name = "velocity",
			type = "input_value",
            shadow = { type = "math_number", value = 50,},
			text = 50, 
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "We130DCMotor.dc130_A",
	func_description = 'dc130_%s.run(%s)',
	ToNPL = function(self)
		local port = self:getFieldAsString('port')
		return string.format('dc130_%s.run(%s);\n', port, self:getFieldAsString('velocity'));
	end,
	headerText = "#include<WeELFMini.h>",
	ToArduino = function(self)
		local port = self:getFieldAsString('port')
		self:GetBlockly():AddUniqueHeader(string.format('We130DCMotor dc130_%s(PORT_%s);', port, port));
		return string.format('dc130_%s.run(%s);\n', port,  self:getFieldAsString('velocity'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.WeDCMotor.runSingle", 
	message0 = L"直流电机%1 速度%2",
	arg0 = {
		{
			name = "port",
			type = "field_dropdown",
			options = {
				{ "M1", "1" },
				{ "M2", "2" },
				{ "M3", "3" },
				{ "M4", "4" },
			  }
		},
		{
			name = "velocity",
			type = "input_value",
            shadow = { type = "math_number", value = 100,},
			text = 100, 
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "WeDCMotor.runSingle",
	func_description = 'dc_%s.run(%s)',
	ToNPL = function(self)
		local port = self:getFieldAsString('port')
		return string.format('dc_%s.run(%s);\n', port, self:getFieldAsString('velocity'));
	end,
	headerText = "#include<WeELFMini.h>",
	ToArduino = function(self)
		local port = self:getFieldAsString('port')
		self:GetBlockly():AddUniqueHeader(string.format('WeDCMotor dc_%s(M%s);', port, port));
		return string.format('dc_%s.run(%s);\n', port, self:getFieldAsString('velocity'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.WeDCMotor.run2", 
	message0 = L"左轮速度%1 右轮速度%2",
	arg0 = {
		{
			name = "velocityLeft",
			type = "input_value",
            shadow = { type = "math_number", value = 50,},
			text = 50, 
		},
		{
			name = "velocityRight",
			type = "input_value",
            shadow = { type = "math_number", value = -50,},
			text = -50, 
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "WeDCMotor.run2",
	func_description = 'dc_1.run(%s);dc_2.run(%s);',
	ToNPL = function(self)
		local v1 = self:getFieldAsString('velocityRight')
		local v2 = "-("..self:getFieldAsString('velocityLeft')..")"
		return string.format('dc_1.run(%s);\ndc_2.run(%s);\n', v1, v2);
	end,
	headerText = "#include<WeELFMini.h>",
	ToArduino = function(self)
		local v1 = self:getFieldAsString('velocityRight')
		local v2 = "-("..self:getFieldAsString('velocityLeft')..")"
		self:GetBlockly():AddUniqueHeader("WeDCMotor dc_1(M1);");
		self:GetBlockly():AddUniqueHeader("WeDCMotor dc_2(M2);");
		local block_indent = self:GetIndent();
		return string.format('dc_1.run(%s);\n%sdc_2.run(%s);\n', v1, block_indent, v2);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.WeDCMotor.run", 
	message0 = L"电机移动%1 速度%2",
	arg0 = {
		{
			name = "dir",
			type = "field_dropdown",
			options = {
				{ "前", "+-" },
				{ "后", "-+" },
				{ "左", "--" },
				{ "右", "++" },
			  }
		},
		{
			name = "velocity",
			type = "input_value",
            shadow = { type = "math_number", value = 120,},
			text = 120, 
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "WeDCMotor.run",
	func_description = 'dc_1.run(%s);',
	ToNPL = function(self)
		local dir = self:getFieldAsString('dir')
		return string.format('dc_1.run(%s);\n', self:getFieldAsString('velocity'));
	end,
	headerText = "#include<WeELFMini.h>",
	ToArduino = function(self)
		local dir = self:getFieldAsString('dir')
		self:GetBlockly():AddUniqueHeader("WeDCMotor dc_1(M1);");
		self:GetBlockly():AddUniqueHeader("WeDCMotor dc_2(M2);");
		local block_indent = self:GetIndent();
		local v1 = self:getFieldAsString('velocity')
		local v2 = v1;
		if(dir == "+-") then
			v2 = "-("..v2..")";
		elseif(dir == "--") then
			v1 = "-("..v1..")";
			v2 = "-("..v2..")";
		elseif(dir == "-+") then
			v1 = "-("..v1..")";
		end
		return string.format('dc_1.run(%s);\n%sdc_2.run(%s);\n', v1, block_indent, v2);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.WeDCMotor.stop", 
	message0 = L"停止所有直流电机",
	arg0 = {
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	funcName = "WeDCMotor.run",
	func_description = 'dc_1.stop();dc_2.stop();',
	ToNPL = function(self)
		return string.format('dc_1.stop();\ndc_2.stop();\n');
	end,
	headerText = "#include<WeELFMini.h>",
	ToArduino = function(self)
		self:GetBlockly():AddUniqueHeader("WeDCMotor dc_1(M1);");
		self:GetBlockly():AddUniqueHeader("WeDCMotor dc_2(M2);");
		local block_indent = self:GetIndent();
		return string.format('dc_1.stop();\n%sdc_2.stop();\n', block_indent);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.WeLineFollower.startRead", 
	message0 = L"巡线传感器%1 %2",
	arg0 = {
		{
			name = "port",
			type = "field_dropdown",
			options = {
				{ "端口A", "A" },
				{ "端口B", "B" },
				{ "端口C", "C" },
				{ "端口D", "D" },
			  }
		},
		{
			name = "sensor",
			type = "field_dropdown",
			options = {
				{ "S1", "1" },
				{ "S2", "2" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	funcName = "WeLineFollower.startRead",
	func_description = 'linefollower_%s.startRead(%s)',
	ToNPL = function(self)
		local port = self:getFieldAsString('port')
		local sensor = self:getFieldAsString('sensor')
		return string.format('linefollower_%s.startRead(%s)', port, sensor);
	end,
	headerText = "#include<WeELFMini.h>",
	ToArduino = function(self)
		local port = self:getFieldAsString('port')
		local sensor = self:getFieldAsString('sensor')
		self:GetBlockly():AddUniqueHeader(string.format("WeLineFollower linefollower_%s(PORT_%s);", port, port))
		return string.format('linefollower_%s.startRead(%s)', port, sensor);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.WeBluetooth.buttonPressed", 
	message0 = L"蓝牙手柄按钮%1按下?",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ "ZR", "ZR" },
				{ "R", "R" },
				{ "ZL", "ZL" },
				{ "L", "L" },
				{ "HOME", "HOME" },
				{ "BL", "BL" },
				{ "Y", "Y" },
				{ "B", "B" },
				{ "A", "A" },
				{ "X", "X" },
				{ "PLUS", "PLUS" },
				{ "MODE", "MODE" },
				{ "UP", "UP" },
				{ "DOWN", "DOWN" },
				{ "LEFT", "LEFT" },
				{ "RIGHT", "RIGHT" },
				{ "MINUS", "MINUS" },
				{ "BR", "BR" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	funcName = "WeBluetooth.buttonPressed",
	func_description = 'bluetooth_controller.buttonPressed(WeBUTTON_%s)',
	ToNPL = function(self)
		local value = self:getFieldAsString('value')
		return string.format('bluetooth_controller.buttonPressed(WeBUTTON_%s)', value);
	end,
	headerText = "#include<WeELFMini.h>",
	ToArduino = function(self)
		local value = self:getFieldAsString('value')
		self:GetBlockly():AddUniqueHeader([[
WeBluetoothController bluetooth_controller;
void sleep(unsigned long duration){
	unsigned long endTime = millis() + duration;
	while(millis() < endTime)update();
}
void update(){
	bluetooth_controller.loop();
}
]])
		self:GetBlockly():AddUniqueHeader("//replace delay sleep");
		self:GetBlockly():AddUniqueHeader("//loop update();\n");
		return string.format('bluetooth_controller.buttonPressed(WeBUTTON_%s)', value);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "arduino.WeBluetooth.readAnalog", 
	message0 = L"蓝牙手柄%1值",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ "左摇杆X轴", "LX" },
				{ "左摇杆Y轴", "LY" },
				{ "右摇杆X轴", "RX" },
				{ "右摇杆Y轴", "RY" },
			  }
		},
	},
	output = {type = "field_number",},
	category = "IO", 
	helpUrl = "", 
	canRun = false,
	funcName = "WeBluetooth.readAnalog",
	func_description = 'bluetooth_controller.readAnalog(WeJOYSTICK_%s)',
	ToNPL = function(self)
		local value = self:getFieldAsString('value')
		return string.format('bluetooth_controller.readAnalog(WeJOYSTICK_%s)', value);
	end,
	headerText = "#include<WeELFMini.h>",
	ToArduino = function(self)
		local value = self:getFieldAsString('value')
		self:GetBlockly():AddUniqueHeader([[
WeBluetoothController bluetooth_controller;
void sleep(unsigned long duration){
	unsigned long endTime = millis() + duration;
	while(millis() < endTime)update();
}
void update(){
	bluetooth_controller.loop();
}
]])
		self:GetBlockly():AddUniqueHeader("//replace delay sleep");
		self:GetBlockly():AddUniqueHeader("//loop update();\n");
		return string.format('bluetooth_controller.readAnalog(WeJOYSTICK_%s)', value);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

});