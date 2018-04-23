--[[
Title: auto lobby page
Author(s): LiXizhi
Date: 2008/6/22
Desc: lobby server logic and display information about the current world.

---+++ auto create/join lobby
Simply call following when connection to server is lost, or when world is just loaded or on user request. 
It will automatically join a world that has not reached max clients. Or it will create one if not found a free server
<verbatim>
	NPL.load("(gl)script/kids/3DMapSystemApp/worlds/AutoLobbyPage.lua");
	Map3DSystem.App.worlds.AutoLobbyPage.AutoJoinRoom()
</verbatim>

To manually join a given user's world call below. 
<verbatim>
	NPL.load("(gl)script/kids/3DMapSystemApp/worlds/AutoLobbyPage.lua");
	Map3DSystem.App.worlds.AutoLobbyPage.Reset()
	Map3DSystem.App.worlds.AutoLobbyPage.JoinRoom(uid, "jgsl://lixizhi@pala5.cn")
</verbatim>

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/AutoLobbyPage.lua");
Map3DSystem.App.worlds.AutoLobbyPage.AutoJoinRoom()
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemNetwork/JGSL.lua");

-- create class
local AutoLobbyPage = {};
commonlib.setfield("Map3DSystem.App.worlds.AutoLobbyPage", AutoLobbyPage)

-- status: nil not available, 1 fetching, 2 fetched. 
local dsRooms = {status=nil, };
local sWorldPath = nil;
-- singleton page instance
local page;
-- current server status text to display
local currentStatusText = "离线状态";

function AutoLobbyPage.DS_Func_Rooms(index)
    return AutoLobbyPage.DS_Func(dsRooms, index, sWorldPath, page)
end

function AutoLobbyPage.OnInit()
	page = document:GetPageCtrl(); -- singleton
	
	local node = page:GetNode("worldpath");
	if(node) then
		node:SetAttribute("tooltip", Map3DSystem.World.worldzipfile or Map3DSystem.World.name);
		node:SetInnerText(string.match(Map3DSystem.World.name, "[^/\\]+$"))
	end
	page:SetNodeValue("owner", Map3DSystem.world.author);
	
	-- access right
	page:SetNodeValue("role", Map3DSystem.User.Role); -- TODO: translate to localized string
	
	page:SetNodeValue("CanSave", Map3DSystem.User.HasRight("Save"));
	page:SetNodeValue("CanChat", Map3DSystem.User.HasRight("Chat"));
	page:SetNodeValue("CanScreenShot", Map3DSystem.User.HasRight("ScreenShot"));
	page:SetNodeValue("CanCreate", Map3DSystem.User.HasRight("Create"));
	page:SetNodeValue("CanEdit", Map3DSystem.User.HasRight("Edit"));
	page:SetNodeValue("CanDelete", Map3DSystem.User.HasRight("Delete"));
	page:SetNodeValue("CanSky", Map3DSystem.User.HasRight("Sky"));
	page:SetNodeValue("CanOcean", Map3DSystem.User.HasRight("Ocean"));
	page:SetNodeValue("CanTerrainTexture", Map3DSystem.User.HasRight("TerrainTexture"));
	page:SetNodeValue("CanTerrainHeightmap", Map3DSystem.User.HasRight("TerrainHeightmap"));
	page:SetNodeValue("CanTimeOfDay", Map3DSystem.User.HasRight("TimeOfDay"));
	page:SetNodeValue("CanShiftCharacter", Map3DSystem.User.HasRight("ShiftCharacter"));
	
	-- server info
	local serverInfo = Map3DSystem.JGSL_client:GetServerInfo();
	if(serverInfo) then
		page:SetNodeValue("ServerJID", serverInfo.jid);
		page:SetNodeValue("ServerOwner", serverInfo.uid);
		page:SetNodeValue("StartTime", serverInfo.StartTime);
		page:SetNodeValue("ServerVersion", serverInfo.ServerVersion);
		page:SetNodeValue("OnlineUserNum", serverInfo.OnlineUserNum);
		page:SetNodeValue("VisitsSinceStart", serverInfo.VisitsSinceStart);
		page:SetNodeValue("ClientVersion", serverInfo.ClientVersion);
		
		page:SetNodeValue("result", "连接到: "..serverInfo.jid);
	else
		page:SetNodeValue("ServerJID", "没有连接服务器");
		page:SetNodeValue("result", currentStatusText);
	end	
	
	-- my host
	page:SetNodeValue("ClientJID", Map3DSystem.JGSL.GetJID());
	
	if(sWorldPath~=(Map3DSystem.World.worldzipfile or Map3DSystem.World.name)) then
		sWorldPath = Map3DSystem.World.worldzipfile or Map3DSystem.World.name;
		dsRooms.status = nil;
	end
end

function AutoLobbyPage.OnClose()
	-- toggle, show hide. 
	page:CloseWindow();
end

function AutoLobbyPage.OnClickRefreshRooms()
    dsRooms.status = nil;
    if(page) then
		page:Refresh();
	end	
end

-- The data source function. 
function AutoLobbyPage.DS_Func(dsTable, index, worldpath, pageCtrl)
    if(not dsTable.status) then
        -- use a default cache
        AutoLobbyPage.GetRoomList(pageCtrl, "access plus 10 seconds", dsTable, worldpath)
    elseif(dsTable.status==2) then    
        if(index==nil) then
            return dsTable.Count;
        else
            return dsTable[index];
        end
    end 
end

-- get friends web service call. it will refresh page once finished. 
function AutoLobbyPage.GetRoomList(pageCtrl, cachepolicy, output, worldpath)
	local msg = {
		pageindex = 0,
		pagesize = 20,
		worldid = nil,
		worldpath = worldpath,
		-- orderfield = 2,
		-- orderdirection = 2,
	};
	output.status = 1;
	local bFetching = paraworld.lobby.GetRoomList(msg, "paraworld", function(msg)
		if(msg and (msg.errorcode==0 or errorcode==nil)) then
		    if(msg.rooms) then
		        local i;
		        for i, room in ipairs(msg.rooms) do 
		            output[i] = room;
		        end
		        output.Count = #(msg.rooms);
		    else
		        output.Count = 0;
		    end
		else
		    log("warning: error fetching lobby rooms\n")    
		    output.Count = 0;
		end
		commonlib.resize(output, output.Count or 0)
		output.status = 2;
		if(pageCtrl) then
			pageCtrl:Refresh();
		end	
	end);
	
	if(bFetching ~= true) then
		output.status = 2;
		output.Count = 0;
		commonlib.resize(output, output.Count or 0)
		if(pageCtrl) then
			pageCtrl:Refresh();
		end	
	end
end

-- create a new room of this world. 
function AutoLobbyPage.CreateRoom()
	local msg = {
		worldpath = Map3DSystem.World.worldzipfile or Map3DSystem.World.name,
		joinpassword = nil,
		description = string.format("jgsl://%s", Map3DSystem.JGSL.GetJID()),
		maxclients = 20,
	};
	commonlib.log("AutoLobbyPage.CreateRoom ... \n")
	Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_LOG, text="正在申请主机..."})
	local bFetching = paraworld.lobby.CreateRoom(msg, "paraworld", function(msg)
		if(msg and msg.newroomid) then
			if(page) then
				currentStatusText = "你正在做主机"
				page:SetUIValue("result", currentStatusText);
				AutoLobbyPage.OnClickRefreshRooms()
			end
			Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_LOG, text="你正在做主机"})
			
			commonlib.log("AutoLobbyPage.CreateRoom Succeed. roomid is %s\n", tostring(msg.newroomid))
		else
			if(page) then
				page:SetUIValue("result", "你目前无法做主机");
			end	
			Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_LOG, text="你目前无法做主机"})
			commonlib.log("warning: AutoLobbyPage.CreateRoom Failed.")
		end
	end);
end

-- join a world that has not reached max clients. 
function AutoLobbyPage.JoinRoom(uid, serverDesc)
	local jid = string.match(serverDesc, "^jgsl://(.*)");
	if(jid) then
		Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_JOIN_JGSL, jid=jid, uid=uid})
		
		if(page) then
			-- find a better way to show connection status. 
			page:SetUIValue("result", currentStatusText);
		end	
	end	
end

-- reset the lobby data, so that it will connection as if no failed attempts are made. 
function AutoLobbyPage.Reset()
	local index, server
	for index, server in ipairs(AutoLobbyPage.public_servers) do
		if(server.worldpath ~= nil) then
			server.worldpath = nil;
			server.uid = nil;
			server.connected = nil;
			return true;
		end
	end
	
	AutoLobbyPage.last_candidate_room.serverDesc = nil;
	AutoLobbyPage.last_candidate_room.worldpath = nil;
	AutoLobbyPage.last_candidate_room.connected = nil;
	AutoLobbyPage.last_candidate_room.nIteration = nil;
	AutoLobbyPage.last_candidate_room.result_time = nil;
	
	AutoLobbyPage.this_candidate_room.serverDesc = nil;
	AutoLobbyPage.this_candidate_room.worldpath = nil;
	AutoLobbyPage.this_candidate_room.connected = nil;
	AutoLobbyPage.this_candidate_room.nIteration = nil;
	AutoLobbyPage.this_candidate_room.result_time = nil;
end

-- a list of public servers to try before using the private servers. 
AutoLobbyPage.public_servers = {
	{
		-- such as string "jgsl://name@domain"
		serverDesc = "jgsl://server.1@pala5.cn", 
		uid = nil, 
		-- when we have its server connection result, either fail or succeed. 
		result_time = 0, 
		connected = nil,
		worldpath = nil,
	},
};

AutoLobbyPage.last_candidate_room = {
	-- such as string "jgsl://name@domain"
	serverDesc = nil, 
	uid = nil, 
	-- when room is retrieved from lobby server
	update_time = 0, 
	-- when we have its server connection result, either fail or succeed. 
	result_time = 0, 
	connected = nil,
	worldpath = nil,
	-- at which iteration this candidate is selected. 
	nIteration = 0,
}
AutoLobbyPage.this_candidate_room = {
	-- such as string "jgsl://name@domain"
	serverDesc = nil, 
	uid = nil, 
	update_time = 0, 
	result_time = 0, 
	connected = nil,
	worldpath = nil,
	-- at which iteration this candidate is selected. 
	nIteration = 0,
}
-- how many times we try to join a room before we give up. 
AutoLobbyPage.MaxTryIterations = 2;
-- how many milliseconds, we wait before a connection result is given. 
AutoLobbyPage.MaxConnectionTime = 25000;

-- join public servers
-- It will return true if it is joining the server. or nil if all server have failed. 
function AutoLobbyPage.JoinPublicServer()
	local worldpath = Map3DSystem.World.worldzipfile or Map3DSystem.World.name;
	local index, server
	for index, server in ipairs(AutoLobbyPage.public_servers) do
		if(server.worldpath ~= worldpath) then
			server.worldpath = worldpath;
			AutoLobbyPage.JoinRoom(server.uid, server.serverDesc);
			return true;
		end
	end
end

-- user clicks to auto join a room.
function AutoLobbyPage.OnClickAutoJoinRoom()
	AutoLobbyPage.Reset();
	AutoLobbyPage.AutoJoinRoom();
end

-- Public function:
-- It will automatically join a world that has not reached max clients. Or it will create one if not found a free server. This function can be called repeatedly. 
-- the logic is this:
-- internally it keeps a last tried candidate table = {jid, uid, connect_time, connected, worldpath}, which is initial nil.
-- every time the AutoJoinRoom() function is called, it will connect to lobby server and retrieve a fresh new copy of 
-- available rooms and choose from them a candidate room. It then tries to connect to the new candidate, if connection is successful, we found the server.
-- if the connection failed. we will check if the newly failed candidate room is the same as the last candidate room, 
-- if they are the same and the connection_time difference is small, we will assume that there is no available server, 
-- and go on to create our own server, otherwise, we will interate the above process for new candidate from the server until 
-- we are either able to join or create our own server or exceed AutoLobbyPage.MaxTryIterations times. 
function AutoLobbyPage.AutoJoinRoom()
	-- try public server first. 
	if(AutoLobbyPage.JoinPublicServer()) then
		return 
	end
	
	local this_candidate_room = AutoLobbyPage.this_candidate_room
	local last_candidate_room = AutoLobbyPage.last_candidate_room
	local worldpath = Map3DSystem.World.worldzipfile or Map3DSystem.World.name;
	local sysTime = ParaGlobal.timeGetTime();
	
	if(this_candidate_room.worldpath~=worldpath or (sysTime-this_candidate_room.update_time) > AutoLobbyPage.MaxConnectionTime) then
		-- this is the beginning of a new AutoJoinRoom request. 
		this_candidate_room.nIteration = 0;
		Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_LOG, text="正在自动寻找可用主机服务器..."})
	end
	if(this_candidate_room.nIteration >= AutoLobbyPage.MaxTryIterations) then
		-- already reached max iterations, we will give up joining, but hosting by ourselves. 
		commonlib.log("already reached max iterations, we will give up joining, but hosting by ourselves. \n")
		AutoLobbyPage.CreateRoom();
		return;
	end
	--if( this_candidate_room.nIteration==(last_candidate_room.nIteration+1) and 
		--last_candidate_room.worldpath == worldpath and last_candidate_room.serverDesc == this_candidate_room.serverDesc and last_candidate_room.serverDesc ~= nil and
		--(this_candidate_room.update_time-last_candidate_room.update_time) < AutoLobbyPage.MaxConnectionTime) then
		---- if the current candidate room is the same as the last candidate room, 
		---- and the update_time difference is small, we will assume that there is no available server, 
		---- and go on to create our own server
		--commonlib.log("the current candidate room is the same as the last candidate room. we will create our own server \n")
		--AutoLobbyPage.CreateRoom();
		--return;
	--end	
	
	-- call the web service to locate a new candidate
	local msg = {
		pageindex = 0,
		pagesize = 20,
		worldid = nil,
		worldpath = worldpath,
	};
	local bFetching = paraworld.lobby.GetRoomList(msg, "paraworld", function(msg)
		local candidate_room;
		if(msg and (msg.errorcode==0 or errorcode==nil)) then
		    if(msg.rooms) then
		        local i;
		        for i, room in ipairs(msg.rooms) do 
		            dsRooms[i] = room;
		            if(candidate_room == nil) then
						if(room.hostuid ~= Map3DSystem.User.userid) then
							candidate_room = room;
						end
		            end
		        end
		        dsRooms.Count = #(msg.rooms);
		        
		        -- if there is a candidte in the room list. 
		        if(candidate_room) then
					if( this_candidate_room.worldpath == candidate_room.worldpath and this_candidate_room.serverDesc == candidate_room.description and this_candidate_room.serverDesc ~= nil and
						(ParaGlobal.timeGetTime()-this_candidate_room.update_time) < AutoLobbyPage.MaxConnectionTime) then
						-- if the current candidate room is the same as the last candidate room, 
						-- and the update_time difference is small, we will assume that there is no available server, 
						-- and go on to create our own server
						commonlib.log("the current candidate room is the same as the last candidate room. we will create our own server \n")
						candidate_room = nil;
					else
						-- copy current candidate to last candidate
						commonlib.partialcopy(last_candidate_room, this_candidate_room);
						
						-- assign new candidate to current candidate
						this_candidate_room.nIteration = this_candidate_room.nIteration + 1;
						this_candidate_room.serverDesc = candidate_room.description;
						this_candidate_room.uid = candidate_room.hostuid;
						this_candidate_room.update_time = ParaGlobal.timeGetTime();
						this_candidate_room.worldpath = candidate_room.worldpath;
						
						-- join the new candidate room. 
						AutoLobbyPage.JoinRoom(this_candidate_room.uid, this_candidate_room.serverDesc)
						commonlib.log("Searching auto Lobby iteration: %d for %s \n", this_candidate_room.nIteration, tostring(candidate_room.worldpath))
					end	
		        end
		    else
		        dsRooms.Count = 0;
		    end
		end
		commonlib.resize(dsRooms, dsRooms.Count or 0)
		dsRooms.status = 2
		if(not candidate_room) then
			-- if there is no candiate, we will create our own. 
			AutoLobbyPage.CreateRoom();
			return;
		end
	end);
end

function AutoLobbyPage.OnClickRefreshServerInfo()
	if(page) then
		page:Refresh();
	end	
end

-- logout server
function AutoLobbyPage.OnClickLogOutServer()
	Map3DSystem.JGSL_client:LogoutServer();
	page:SetUIValue("result", "已经注销服务器");
end

-- save my server settings. 
function AutoLobbyPage.OnClickSaveMyServerSetting(btnName, values)
	-- TODO: 
end