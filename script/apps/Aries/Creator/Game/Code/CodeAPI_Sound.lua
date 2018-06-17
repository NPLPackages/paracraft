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
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");

-- same as /midi [note]
-- @param beat: 
function env_imp:playNote(note, beat)
	GameLogic.RunCommand("/midi "..tostring(note));
	beat = math.max((beat or 1) * 1, env_imp.GetDefaultTick(self));
	env_imp.wait(self, beat);
end

-- same as /sound [filename]
function env_imp:playSound(filename)
	GameLogic.RunCommand("/sound "..(filename or ""));
	env_imp.wait(self, env_imp.GetDefaultTick(self));
end

-- same as /music [filename]
function env_imp:playMusic(filename)
	GameLogic.RunCommand("/music "..(filename or ""));
	env_imp.wait(self, env_imp.GetDefaultTick(self));
end