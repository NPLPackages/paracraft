--[[
Title: Macro Button Click Trigger
Author(s): LiXizhi
Date: 2021/1/4
Desc: a trigger for key(s) press. 

Use Lib:
-------------------------------------------------------

-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

--@param button: string like "C" or "ctrl+C"
function Macros.KeyPressTrigger(button)
	local callback = {};
	MacroPlayer.SetKeyPressTrigger(button, function()
		if(callback.OnFinish) then
			callback.OnFinish();
		end
	end);
	return callback;
end





