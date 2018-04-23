--[[
Title: message processor
Author(s): LiXizhi
Date: 2007/11/6
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_game.lua");
Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_LOG, text="abc"})
------------------------------------------------------------
]]
if (not Map3DSystem) then  Map3DSystem = {} end
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/Cursor.lua");
local Cursor = commonlib.gettable("Map3DSystem.UI.Cursor");

-- scene:object window handler
function Map3DSystem.OnGameMessage(window, msg)
	if(msg.type == Map3DSystem.msg.GAME_LOG) then
		-----------------------------------------------
		-- display a global log message to the user. 
		-----------------------------------------------
		if(msg.text~=nil) then
			-- use in-game window to display all game logs. 
			autotips.AddMessageTips(msg.text)
			
			-- TODO: remove this debug text. 
			commonlib.log("game log: "..msg.text.."\n")
		end	
	elseif(msg.type == Map3DSystem.msg.GAME_CURSOR) then	
		-----------------------------------------------
		-- display a game cursor
		-- e.g.: Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_CURSOR, cursor="talk"})
		-----------------------------------------------
		Cursor.ApplyCursor(msg.cursor, msg.cursorfile, msg.hot_x, msg.hot_y);
		
	elseif(msg.type == Map3DSystem.msg.GAME_JOIN_JGSL) then
		-----------------------------------------------
		-- join a Jabber-GSL server with a given JID 
		-----------------------------------------------
		if(msg.jid~=nil) then
			NPL.load("(gl)script/kids/3DMapSystemNetwork/JGSL.lua");
			Map3DSystem.JGSL_client:LoginServer(msg.jid);
		end	
	elseif(msg.type == Map3DSystem.msg.GAME_JGSL_SIGNEDIN) then	
		-- called whenever this computer successfully signed in to a remote server
		
	elseif(msg.type == Map3DSystem.msg.GAME_JGSL_CONNECTION_TIMEOUT) then	
		-- called whenever connection to a remote server computer timed out. 
	elseif(msg.type == Map3DSystem.msg.GAME_JGSL_SIGNEDOUT) then	
		-- called whenever this computer signed out of a remote server or just can not connect to the server due to time out. 
	elseif(msg.type == Map3DSystem.msg.GAME_JGSL_USER_COME) then
		-- called whenever some user come in to this world
	elseif(msg.type == Map3DSystem.msg.GAME_JGSL_USER_LEAVE) then
		-- called whenever some user leaves this world
	elseif(msg.type == Map3DSystem.msg.GAME_TELEPORT_PLAYER) then	
		-- teleport the current character to a given location. User must have the right to do so. 
		-- msg = {x=number, y=number, z=number}, if x,y,z is not specified, it will pick a 3d position using the current mouse position. if only y is not specified, it will use the terrain height. 
		
		-- quick move the character to the location. 
		if(Map3DSystem.User.HasRight("Teleport")) then
			local x, y, z = msg.x, msg.y, msg.z;
			if(x==nil or z==nil) then
				local pt = ParaScene.MousePick(1000, "point");
				if(pt:IsValid())then
					x, y, z = pt:GetPosition();
				end
			end
			if(y==nil and x~=nil and z~=nil) then
				y = ParaTerrain.GetElevation(x,z);
			end
			
			if(x and y and z) then
				ParaScene.GetPlayer():SetPosition(x, y, z);
				-- this fix a bug when there is a target point during quick move. 
				ParaScene.GetPlayer():ToCharacter():Stop();
				-- this prevent an animation flaw when moving with character in fly mode
				ParaScene.GetPlayer():ToCharacter():FallDown();
			end	
		else
			autotips.AddMessageTips("在这个世界中, 你没有瞬移的权限");
		end	
	end
end
