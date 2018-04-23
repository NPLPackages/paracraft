--[[
Title: header file for all server side paraworld application programming interface. 
Author(s): LiXizhi
Date: 2008/1/21
Desc: 

Each server side api function is an asynchronous RPC (remote procedure call) wrapper. 
Take the AuthUser RPC for instance (one can open "paraworld.auth.lua" for reference), a paraworld RPC wrapper is in the following declaration format:

function paraworld.auth.AuthUser(msg, id, callbackFunc, callbackParams) 
	-- asynchronous call which returns immediately. 
end

@param msg: msg is always the input xml table of the RPC, which is documented above the function declaration. 
	NOTES: cookie data are automatically appended for RPCs that require them. Commmon cookie variables are sessionkey, userid, app_key, etc. 
	However, if you include any of these variables explicitly in your message, it will override default corresponding cookie variables. 
@param id: id is a string indicating a given caller. Please note that if one tries to call the same function twice with the same id, the function will fail if first call does not return. 
	however, one can specify nil to id, to force calling multiple times even the previous call does not response. 
	Usually, the application name or application key is used as id, when the application is trying to make a call to a server side API. 
@param callbackFunc: a function pointer of type function (msg, params) end. when the RPC returns, the callbackFunc will be called. The params is optional. see below. 
	NOTES: in the callbackFunc, one should always check for the error code and handle it gracefully. 
@param callbackParams: [optional] this is an optional table or value that will be passed to the second params of the callbackFunc when calling back. 
@return: it will return true if succeed. or it will return nil or a error code (paraworld.errorcode.RepeatCall) or error message. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/AriesServerPowerAPI.lua");
-------------------------------------------------------
]]

-- create class
if(not paraworld) then paraworld = {} end
if(not paraworld.PowerAPI) then paraworld.PowerAPI = {} end

-- 2009.7.23: if this is true, most paraworld API will be sent via the game server interface(using current persistent NPL connection). otherwise, they are sent via HTTP interface (stateless TCP connection)
-- use_game_server requires NPL network architecture running on the server side (consisting game servers, NPLRouters and DBServers). 
-- @note: even the paraworld.use_game_server is true, some API only has HTTP interface. So they can be used hand-in-hand, without the caller really noticing which kind of server is servicing. 
paraworld.use_game_server = true;

-- this loads the game server client interface
NPL.load("(gl)script/apps/GameServer/rest_client.lua");
NPL.load("(gl)script/apps/GameServer/rest_local.lua");
NPL.load("(gl)script/apps/GameServer/rest_webservice_wrapper.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/API/webservice_wrapper.lua");

-- this is paraworld.create_wrapper has different meanings according to paraworld.use_game_server
if(not paraworld.create_wrapper) then
	if (paraworld.use_game_server) then
		paraworld.create_wrapper = GameServer.rest.client.CreateRESTJsonWrapper;
	else
		paraworld.create_wrapper = paraworld.CreateRESTJsonWrapper;		
	end
end

-- the power API wrapper
paraworld.createPowerAPI = GameServer.rest_local.CreateRESTLocalJsonWrapper;

NPL.load("(gl)script/ide/System/localserver/factory.lua");
NPL.load("(gl)script/ide/NPLExtension.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/API/epoll_serverproxy.lua");

---------------------------------------------------------
-- central server API
---------------------------------------------------------
-- common functions
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.common.lua");
-- inventory related
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.inventory.lua");
-- user info related
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.users.lua");
-- pet related
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.pet.lua");
-- payment related
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.payment.lua");
-- svr email
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/paraworld.PowerAPI.email.lua");

LOG.std(nil,"system", "PowerAPI", "power api loaded in this thread.")