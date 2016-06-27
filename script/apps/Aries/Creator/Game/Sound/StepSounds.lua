--[[
Title: all step sounds
Author(s): LiXizhi
Date: 2013/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/StepSounds.lua");
local StepSounds = commonlib.gettable("MyCompany.Aries.Game.Sound.StepSounds");
StepSounds.get("grass")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BlockSound.lua");
local BlockSound = commonlib.gettable("MyCompany.Aries.Game.Sound.BlockSound");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local StepSounds = commonlib.gettable("MyCompany.Aries.Game.Sound.StepSounds");

local sounds;

function StepSounds.Init()
	if(not sounds) then
		sounds = {
			["sand"] = BlockSound:new():Init({"sand1", "sand2", "sand3", "sand4"}, 1, 1),
			["grass"] = BlockSound:new():Init({"grass1", "grass2", "grass3",}, 1, 1),
			["wood"] = BlockSound:new():Init({"wood1", "wood2", "wood3", "wood4"}, 1, 1),
			["glass"] = BlockSound:new():Init({"glass2","glass3",}, 0.1, 1),
			["gravel"] = BlockSound:new():Init({"gravel1", "gravel2", "gravel3", "gravel4"}, 0.5, 1),
			["stone"] = BlockSound:new():Init({"stone1", "stone2", "stone3", "stone4"}, 1, 1),
			["cloth"] = BlockSound:new():Init({"cloth1", "cloth2", "cloth3", "cloth4"}, 1, 1),
			["metal"] = BlockSound:new():Init({"stone1", "stone2", "stone3", "stone4"}, 1, 1.5),
		};
	end
end

function StepSounds.get(name)
	StepSounds.Init();
	return sounds[name or ""];
end
