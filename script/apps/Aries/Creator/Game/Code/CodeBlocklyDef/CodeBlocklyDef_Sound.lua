--[[
Title: CodeBlocklyDef_Sound
Author(s): leio
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
	type = "playNote", 
	message0 = L"播放音符%1持续%2节拍",
	arg0 = {
		{
			name = "note",
			type = "field_input",
			text = "7",
		},
		{
			name = "beat",
			type = "field_number",
			text = 0.25,
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'playNote("%s", %s)',
	ToNPL = function(self)
		return string.format('playNote("%s", %s)\n', self:getFieldAsString('note'), self:getFieldAsString('beat'));
	end,
	examples = {{desc = L"", canRun = true, code = [[
while (true) do
    playNote("1", 0.5)
    playNote("2", 0.5)
    playNote("3", 0.5)
end
]]}},
},

{
	type = "playMusic", 
	message0 = L"播放背景音乐%1",
	arg0 = {
		{
			name = "filename",
			type = "field_input",
			text = "1",
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'playMusic("%s")',
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
	type = "playSound", 
	message0 = L"播放MP3音乐%1",
	arg0 = {
		{
			name = "filename",
			type = "field_input",
			text = "break",
		},
	},
	category = "Sound", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'playSound("%s")',
	ToNPL = function(self)
		return string.format('playSound("%s")\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = L"播放音乐后停止", canRun = true, code = [[
playSound("break")
wait(1)
playSound("click")
]]}},
},
};
function CodeBlocklyDef_Sound.GetCmds()
	return cmds;
end
