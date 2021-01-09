--[[
Title: Macro Tip
Author(s): LiXizhi
Date: 2021/1/7
Desc: tip macro

Use Lib:
-------------------------------------------------------
GameLogic.Macros.Tip("some mcml text here")
GameLogic.Macros.Broadcast("globalGameEvent")
-------------------------------------------------------
]]
-------------------------------------
-- single Macro base
-------------------------------------
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

-- @param text: mcml text, if nil, it will remove the tip. 
function Macros.Tip(text)
	-- TODO: show a tip 
	GameLogic.AddBBS("MacroTip", text, 10000, "0 255 0");
end


-- @param msg: global message name, same as /sendevent msg
function Macros.Broadcast(msg)
	GameLogic.RunCommand("sendevent", msg);
end





