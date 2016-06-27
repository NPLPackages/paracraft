--[[
Title: HeadonSpeech Display
Author(s): LiXizhi
Date: 2013/12/23
Desc: Headon 3d image for static models. Characters currently does not support real 3d text. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/HeadonSpeechDisplay.lua");
local HeadonSpeechDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.HeadonSpeechDisplay");
HeadonSpeechDisplay.ShowHeadonDisplay(bShow, obj, image_path, width, height, color, offset, facing)
HeadonSpeechDisplay.InitHeadOnTemplates(true)
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local HeadonSpeechDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.HeadonSpeechDisplay");

-- head on display UI style, edit it here or change via HeadonSpeechDisplay.headon_style
local headon_style = {
	-- some background
	default_bg = "Texture/blocks/cake_top.png",
	-- text color
	text_color = "0 160 0",
	-- whether there is text shadow
	-- use_shadow = true,
	-- any text scaling
	-- scaling = 1.2,
	spacing = 2,
	width = 64,
	height = 64,
}

HeadonSpeechDisplay.headon_style = HeadonSpeechDisplay.headon_style or headon_style;

