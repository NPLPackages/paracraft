--[[
Title: multi-touch event handler
Author(s): LiXizhi
Date: 2022/1/30.  
Desc: only included in event_handlers.lua
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_touch.lua");
Map3DSystem.ReBindEventHandlers();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")

-- input: msg.type, msg.x, msg.y, msg.id, 
function Map3DSystem.OnTouchEvent()
	local touch = msg;
	
	local session = TouchSession.GetExistingTouchSession(touch)
	if(session) then
		session:Tick()
		if(touch.type == "WM_POINTERUP") then
			session:SetClosed();
		end
	end
	if(touch.type == "WM_POINTERDOWN") then
		TouchSession.RemoveClosedSessions(1000)
	end
end	