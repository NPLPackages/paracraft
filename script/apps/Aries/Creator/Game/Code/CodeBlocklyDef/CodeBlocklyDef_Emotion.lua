--[[
Title: CodeBlocklyDef_Emotion
Author(s): leio
Date: 2019/12/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/CodeBlocklyDef_Emotion.lua");
-------------------------------------------------------
]]
local list = {
    { label = L"向上看", func = "lookup", },
    { label = L"向下看", func = "lookdown", },
    { label = L"向左看", func = "lookleft", },
    { label = L"向右看", func = "lookright", },
    { label = L"东张西望", func = "lookaround", },
    { label = L"眨眼", func = "blink", },
    { label = L"笑", func = "smile", },
    { label = L"耶", func = "yeah", },
    { label = L"调皮", func = "naughty", },
    { label = L"得意", func = "proud", },
    { label = L"撒娇", func = "yummy", },
    { label = L"尴尬", func = "uh_oh", },
    { label = L"惊叹", func = "wow", },
    { label = L"委屈", func = "hurt", },
    { label = L"难过", func = "sad", },
    { label = L"生气", func = "angry", },
    { label = L"打招呼", func = "hello", },
    { label = L"冲刺", func = "sprint", },
    { label = L"吓一跳", func = "scared", },
    { label = L"发抖", func = "shiver", },
    { label = L"头晕", func = "dizzy", },
    { label = L"瞌睡", func = "yawn", },
    { label = L"熟睡", func = "sleep", },
    { label = L"苏醒", func = "wake", },
    { label = L"肯定", func = "yes", },
    { label = L"否定", func = "no", },
    { label = L"开门", func = "opendoor", },
    { label = L"关门", func = "closedoor", },
}
local result = {};
for k,v in ipairs(list) do
    local cmd = {
	type = "ai" .. v.func,
	message0 = v.label,
	category = "Emotion", 
	helpUrl = "", 
	canRun = true,
	previousStatement = true,
	nextStatement = true,
	func_description = 'ai_' .. v.func .. '()',
	ToNPL = function(self)
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},

}
    table.insert(result,cmd);
end
NPL.export(result)