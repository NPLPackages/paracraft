--[[
Title: The map system Event handlers
Author(s): LiXizhi(code&logic)
Date: 2006/1/26
Desc: only included in event_handlers.lua
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_network.lua");
Map3DSystem.ReBindEventHandlers();
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/event_mapping.lua");

if(not Map3DSystem) then Map3DSystem={} end

function Map3DSystem.OnNetworkEvent()
	if(msg.code == NPLReturnCode.NPL_ConnectionEstablished) then
		LOG.std("", "system", "event", "Connection is established with %s", msg.nid);
		local OnConnectionEstablished = commonlib.getfield("Map3DSystem.App.AppManager.OnConnectionEstablished");
		if(OnConnectionEstablished) then
			OnConnectionEstablished(msg.nid);
		end
	elseif(msg.code == NPLReturnCode.NPL_ConnectionDisconnected) then
		LOG.std("", "system", "event", "Connection is disconnected with %s", msg.nid);
		local OnConnectionDisconnected = commonlib.getfield("Map3DSystem.App.AppManager.OnConnectionDisconnected");
		if(OnConnectionDisconnected) then
			OnConnectionDisconnected(msg.nid, msg.msg);
		end
	elseif(msg.code == NPLReturnCode.NPL_Command) then
		LOG.std("", "system", "event", "network cmd from %s", msg.nid);
		echo(msg);
	end	
end