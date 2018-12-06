--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/6/8
Desc: sandbox API environment
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Sound.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");

-- same as /midi [note]
-- @param beat: 
function env_imp:playNote(note, beat)
	GameLogic.RunCommand("/midi "..tostring(note));
	beat = math.max((beat or 1) * 1, env_imp.GetDefaultTick(self));
	env_imp.wait(self, beat);
end

-- play a sound 
-- @param channel_name: channelname or filename, where filename can be relative to current world or a predefined name
function env_imp:playSound(channel_name, filename, from_time, volume, pitch)
	filename = filename or channel_name;
	SoundManager:PlaySound(channel_name, filename, from_time or 0, volume, pitch);	
	env_imp.checkyield(self);
end

-- same as /sound [filename]
function env_imp:stopSound(filename)
	SoundManager:StopSound(filename)
	env_imp.checkyield(self);
end

-- same as /music [filename]
function env_imp:playMusic(filename)
	GameLogic.RunCommand("/music "..(filename or ""));
	env_imp.checkyield(self);
end