--[[
Title: user profile message processor
Author(s): LiXizhi
Date: 2007/10/19
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_obj.lua");
Map3DSystem.SendMessage_profile({type = Map3DSystem.msg.USER_AddPoint, value=10})
------------------------------------------------------------
]]

--[[
-------------------------------------------------
USER REWARD AND BONUS POINT SYSTEM
Draft by LiXizhi
-------------------------------------------------
For each user action, we will award the user some points. 
points can be converted to credits which may be used to purchase things on the server.
The server will keep track of the user points, yet point is a client based system, users can easily fake them. 
Therefore, points is only relavent to the subscription business model. It has nothing to do with virtual currency,which is a different business model.

Sometimes, we can use points to track user behaviors and award the user free things or unlock free levels, etc. 
Because of its client based nature, points can not be mixed with virtual currency. 
]]

-- scene:object window handler
function Map3DSystem.OnProfileMessage(window, msg)
	if(msg.type == Map3DSystem.msg.USER_AddPoint) then
		-----------------------------------------------
		-- user just earned some points. 
		-----------------------------------------------
		if(msg.value~=nil) then
			-- play sound
			ParaAudio.PlayUISound("Btn1");
			-- TODO: some UI animation to inform user that he or she earns some points
			-- TODO: award the user randomly based on the points gain before. Such as every 50 points, a big sound, every 100 points, a silver medal, every 300 points, ...
			-- TODO: write to local database
			-- TODO: if total points is larger than a certain value, update to the remove server. 
		end	
	elseif(msg.type == Map3DSystem.msg.USER_GetProfile) then
		-----------------------------------------------
		-- get profile
		-----------------------------------------------
		--TODO: 
	end
end
