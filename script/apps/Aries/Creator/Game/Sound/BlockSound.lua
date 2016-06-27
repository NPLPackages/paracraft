--[[
Title: Block Sound
Author(s): LiXizhi
Date: 2013/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BlockSound.lua");
local BlockSound = commonlib.gettable("MyCompany.Aries.Game.Sound.BlockSound");
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local BlockSound = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Sound.BlockSound"));

function BlockSound:ctor()
end

-- @param filename: sound name or a table array of sound names. 
function BlockSound:Init(filename, volume, pitch)
	if(type(filename) == "table") then
		for i, name in ipairs(filename) do
			self[i] = name;
		end
	elseif(type(filename) == "string") then
		self[1] = filename;
	end

	local count = #self;
	local i;
	for i=1, count do 
		if(type(self[i]) == "string") then
			self[i] = AudioEngine.CreateGet(self[i]);
		end
	end
	self.index = 1;
	self.count = count;
	self.volume = self.volume or volume or 1;
	self.pitch = self.pitch or pitch or 1;
	return self;
end

function BlockSound:play2d(volume, pitch)
	if(self.count >= 1) then
		self.index = self.index % self.count + 1;
		local audio = self[self.index];
		if(audio) then
			if(volume) then
				volume = volume * self.volume;
			end
			audio:play2d(volume or self.volume, self.pitch or pitch);
		end
	end
end

function BlockSound:play3d(...)
	if(self.count >= 1) then
		self.index = self.index % self.count + 1;
		local audio = self[self.index];
		if(audio) then
			audio:play3d(...);
		end
	end
end
