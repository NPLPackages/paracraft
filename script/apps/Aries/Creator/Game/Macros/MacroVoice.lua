--[[
Title: Macro Voice
Author(s): LiXizhi
Date: 2021/1/19
Desc: voices

Use Lib:
-------------------------------------------------------
GameLogic.Macros.voice("text to speech")
GameLogic.Macros.sound("1.mp3")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

local voices = {
["你需要同时按下2个按键"] = "Audio/Haqi/creator/MacroPlayer/macrotip_1.ogg",
["按住鼠标左键不要放手， 同时拖动鼠标到目标点"] = "Audio/Haqi/creator/MacroPlayer/macrotip_2.ogg",
["鼠标移动到这里，但不要点击"] = "Audio/Haqi/creator/MacroPlayer/macrotip_3.ogg",
["不要点击鼠标, 而是滚动鼠标中间的滚轮"] = "Audio/Haqi/creator/MacroPlayer/macrotip_4.ogg",
["请按照指示输入文字"] = "Audio/Haqi/creator/MacroPlayer/macrotip_5.ogg",
["请按住键盘的指定按钮不要松手，同时点击鼠标"] = "Audio/Haqi/creator/MacroPlayer/macrotip_6.ogg",
["请点击正确的鼠标按键"] = "Audio/Haqi/creator/MacroPlayer/macrotip_7.ogg",
["请将鼠标移动到目标点，再按键盘"] = "Audio/Haqi/creator/MacroPlayer/macrotip_8.ogg",
["拖动鼠标时需要按正确的按键"] = "Audio/Haqi/creator/MacroPlayer/macrotip_9.ogg",
["请拖动鼠标到目标点"] = "Audio/Haqi/creator/MacroPlayer/macrotip_10.ogg",
["请向另外一个方向滚动鼠标中间的滚轮"] = "Audio/Haqi/creator/MacroPlayer/macrotip_11.ogg",
["success"] = "Audio/Haqi/creator/ArtWar/success.mp3",
}

-- @param text: play text to speech
function Macros.voice(text)
	if(not text or text == "") then
		return
	end
	
	if(Macros.IsAutoPlay()) then
		return
	end

	local filename = voices[text]
	if(filename) then
		-- play macro voice and macro sound on two channels
		GameLogic.RunCommand("sound", format("macroplayerVoice %s", filename))
	else
		GameLogic.RunCommand("voice", text)
	end
end

-- @param filename play a mp3 or ogg file name
function Macros.sound(filename)
	if(Macros.IsAutoPlay()) then
		return
	end
	if(filename) then
		GameLogic.RunCommand("sound", format("macroplayer %s", filename))
	end
end



