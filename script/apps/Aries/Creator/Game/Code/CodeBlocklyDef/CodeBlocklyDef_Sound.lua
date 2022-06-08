--[[
Title: CodeBlocklyDef_Sound
Author(s): LiXizhi
Date: 2018/7/5
Desc: define blocks in category of Sound
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Sound.lua");
local CodeBlocklyDef_Sound= commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Sound");
-------------------------------------------------------
]]
local CodeBlocklyDef_Sound = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyDef.CodeBlocklyDef_Sound");
local cmds = {
-- Sound

{
	type = "playNoteTypes", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ "1", "1" },{ "2", "2" },{ "3", "3" },{ "4", "4" },{ "5", "5" },{ "6", "6" },{ "7", "7" },
				{ "c", "c" },{ "d", "d" },{ "e", "e" },{ "f", "f" },{ "g", "g" },{ "a", "a" },{ "b", "b" },
				{ "c'", "c'" },{ "d'", "d'" },{ "e'", "e'" },{ "f'", "f'" },{ "g'", "g'" },{ "a'", "a'" },{ "b'", "b'" },
				{ "c''", "c''" },{ "d''", "d''" },{ "e''", "e''" },{ "f''", "f''" },{ "g''", "g''" },{ "a''", "a''" },{ "b''", "b''" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Sound", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "playNote", 
	message0 = L"播放音符%1持续%2节拍",
	arg0 = {
		{
			name = "note",
			type = "input_value",
			shadow = { type = "playNoteTypes", value = "1",},
			text = "1",
		},
		{
			name = "beat",
			type = "input_value",
            shadow = { type = "math_number", value = 0.25,},
			text = 0.25,
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "playNote",
	func_description = 'playNote(%s, %s)',
	ToNPL = function(self)
		return string.format('playNote("%s", %s)\n', self:getFieldAsString('note'), self:getFieldAsString('beat'));
	end,
	examples = {{desc = "", canRun = true, code = [[
while (true) do
    playNote("1", 0.5)
    playNote("2", 0.5)
    playNote("3", 0.5)
end
]]}},
},

{
	type = "playMusicFileTypes", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ "1", "1" },
				{ "2", "2" },
				{ "3", "3" },
				{ "4", "4" },
				{ "5", "5" },
				{ L"ogg文件", "filename.ogg" },
				{ L"wav文件", "filename.wav" },
				{ L"mp3文件", "filename.mp3" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Sound", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "playMusic", 
	message0 = L"播放背景音乐%1",
	arg0 = {
		{
			name = "filename",
			type = "input_value",
			shadow = { type = "playMusicFileTypes", value = "1",},
			text = "1",
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "playMusic",
	func_description = 'playMusic(%s)',
	ToNPL = function(self)
		return string.format('playMusic("%s")\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = L"播放音乐后停止", canRun = true, code = [[
playMusic("2")
wait(5)
playMusic()
]]}},
},


{
	type = "playSoundFileTypes", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"击碎", "break" },
				{ L"ogg文件", "filename.ogg" },
				{ L"wav文件", "filename.wav" },
				{ L"mp3文件", "filename.mp3" },
				{ L"开箱", "chestclosed" },
				{ L"关箱", "chestopen" },
				{ L"开门", "door_open" },
				{ L"关门", "door_close" },
				{ L"点击", "click" },
				{ L"激活", "trigger" },
				{ L"溅射", "splash" },
				{ L"水", "water" },
				{ L"吃", "eat1" },
				{ L"爆炸", "explode1" },
				{ L"升级", "levelup" },
				{ L"弹出", "pop" },
				{ L"掉下", "fallbig1" },
				{ L"火", "fire" },
				{ L"弓箭", "bow" },
				{ L"呼吸", "breath" },
			},
		},
	},
	hide_in_toolbox = true,
	category = "Sound", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "playSound", 
	message0 = L"播放声音%1",
	arg0 = {
		{
			name = "filename",
			type = "input_value",
			shadow = { type = "playSoundFileTypes", value = "break",},
			text = "break",
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "playSound",
	func_description = 'playSound(%s)',
	ToNPL = function(self)
		return string.format('playSound("%s")\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = L"播放音乐后停止", canRun = true, code = [[
playSound("levelup")
]]},
{desc = L"播放声道", canRun = true, code = [[
playSound("channel1", "levelup")
wait(0.5)
playSound("channel1", "breath")
]]},
{desc = L"一个声音同时播放多次", canRun = true, code = [[
for i=1, 80 do
    -- at most 5 at the same time
    playSound("breath"..(i % 5), "breath")
    wait(0.1)
end
]]},
{desc = L"音调和音量不同", canRun = true, code = [[
for pitch = 0, 1, 0.1 do
   playSound("click", "click", 0, 1, pitch)
   wait(0.5)
end
for volume = 0, 1, 0.1 do
   playSound("click", nil, 0, volume, 1)
   wait(0.5)
end
]]}
},
},

{
	type = "stopSound", 
	message0 = L"暂停播放声音%1",
	arg0 = {
		{
			name = "filename",
			type = "input_value",
			shadow = { type = "playSoundFileTypes", value = "break",},
			text = "break",
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "stopSound",
	func_description = 'stopSound(%s)',
	ToNPL = function(self)
		return string.format('stopSound("%s")\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = "", canRun = true, code = [[
playSound("levelup")
wait(0.4)
stopSound("levelup")
]]},
{desc = "", canRun = true, code = [[
playSound("levelup1", "levelup")
wait(0.5)
playSound("levelup2", "levelup")
wait(0.3)
stopSound("levelup2")
]]},
},
},

{
	type = "playText", 
	message0 = L"朗读文字%1",
	arg0 = {
		{
			name = "filename",
			type = "input_value",
			shadow = { type = "text", value = "你好",},
			text = "你好",
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	funcName = "playText",
	func_description = 'playText(%s)',
	ToNPL = function(self)
		return string.format('playText("%s")\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = "使用文本播放语音", canRun = true, code = [[
playText("欢迎来到我的世界")
]]},
{desc = "参数2可以延迟执行后面的代码", canRun = true, code = [[
playText("你好", 2)
tip("你好")
]]},
{desc = [[参数3可以选择不同的声音 0: 女声,1: 男声,3: 逍遥,4: 丫丫,        
-- 5003: 逍遥2,5118: 小鹿,106: 博文,110: 小童,111: 小萌,103: 米朵,5: 小娇,
-- 10001: 晓萱,10002: 云希,10003: 晓墨,10004: 晓涵,10005: 云哲,10006: 云野,
-- 10007: 晓颜,10008: 晓辰,10010: 晓曼,10011: 晓秋,10012: 晓悠,10013: 晓晓,
-- 10015: 云扬,20007: 晓睿,20008: 晓双,20015: 晓佳,20016: 云龍,20017: 晓臻,
-- 20018: 晓雨]], canRun = true, code = [[
playText("你好", 1, 1)
tip("你好")
]]},
},
},


};
function CodeBlocklyDef_Sound.GetCmds()
	return cmds;
end
