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
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
if(not paraworld) then paraworld = {} end

-- 2009.7.23: if this is true, most paraworld API will be sent via the game server interface(using current persistent NPL connection). otherwise, they are sent via HTTP interface (stateless TCP connection)
-- use_game_server requires NPL network architecture running on the server side (consisting game servers, NPLRouters and DBServers). 
-- @note: even the paraworld.use_game_server is true, some API only has HTTP interface. So they can be used hand-in-hand, without the caller really noticing which kind of server is servicing. 
paraworld.use_game_server = true;

-- this loads the game server client interface
NPL.load("(gl)script/apps/GameServer/rest_client.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/API/webservice_wrapper.lua");

-- this is paraworld.create_wrapper has different meanings according to paraworld.use_game_server
if (paraworld.use_game_server and GameServer and GameServer.rest) then
	paraworld.create_wrapper = GameServer.rest.client.CreateRESTJsonWrapper;
else
	paraworld.create_wrapper = paraworld.CreateRESTJsonWrapper;		
end

-- whether this is an offline mode
paraworld.OfflineMode = nil;

-- when offline mode is enabled, the local server result will be returned regardless of whether they are expired. 
-- in other word, the cache policy is always replaced by a always from cache policy. 
function paraworld.EnableOfflineMode(bEnable)
	if(bEnable) then
		LOG.std("", "system","API", "offline mode is started");
	end	
	paraworld.OfflineMode = bEnable;
end

NPL.load("(gl)script/ide/System/localserver/factory.lua");
NPL.load("(gl)script/ide/NPLExtension.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/API/epoll_serverproxy.lua");

---------------------------------------------------------
-- central server API
---------------------------------------------------------
-- It is for client and application to authenticate a user and return or verify a session key. 
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.auth.lua");
-- Get profile of a given user; set profile of a given user for a given application
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.profile.lua");
-- get or set social graphs. 
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.friends.lua");
-- get or set user information.
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.users.lua");
-- MQL: microcosmos query language
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.MQL.lua");

---------------------------------------------------------
-- official application server API
---------------------------------------------------------
-- application directory service, add or remove applications of a given user, setting privacy info of a given user, sending or receiving emails for a given application. 
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.apps.lua");
-- anything about feed
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.actionfeed.lua");
-- map browsing, land selling or purchasing
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.map.lua");
-- user's bag management, tradable items are in the bag which can be exchanged among users or sold from a shop or person. 
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.inventory.lua");
-- a central place per application for selling and buying tradable items. 
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.marketplace.lua");
-- a central place per application for creating and joining each other's world (room).
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.lobby.lua");
-- game email system
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.email.lua");
-- item global store
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.globalstore.lua");
-- worlds related. 
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.worlds.lua");
-- family related. 
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.family.lua");
-- file related
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.file.lua");
-- plant related
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.plant.lua");
-- magiccard related
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.magiccard.lua");
-- pet related
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.pet.lua");
-- VIP related
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.VIP.lua");
-- auction related
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.auction.lua");