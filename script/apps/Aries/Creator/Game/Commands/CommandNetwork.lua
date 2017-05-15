--[[
Title: Command network
Author(s): LiXizhi
Date: 2014/6/25
Desc: network server related command
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandNetwork.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["tunnelserver"] = {
	name="tunnelserver", 
	quick_ref="/tunnelserver [-start|stop] [ip_host] [port]", 
	desc=[[start tunnel server on host port
]], 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local host, port;
		host, cmd_text = CmdParser.ParseString(cmd_text);
		port, cmd_text = CmdParser.ParseInt(cmd_text);
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Network/TunnelService/TunnelServer_main.lua");
		local TunnelServerMain = commonlib.gettable("MyCompany.Aries.Game.Network.TunnelServerMain");
		TunnelServerMain:Init({host=host, port=port});
		GameLogic.AddBBS(nil, "tunnel server is started");
	end,
};

Commands["startserver"] = {
	name="startserver", 
	quick_ref="/startserver [-tunnel room_key] [ip_host] [port]", 
	desc=[[start private server on host port
@param -tunnel: start server via tunnel server
]], 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local host, port, option, room_key, username;
		option, cmd_text = CmdParser.ParseOption(cmd_text);
		if(option == "tunnel") then
			room_key, cmd_text = CmdParser.ParseString(cmd_text);
		end

		host, cmd_text = CmdParser.ParseString(cmd_text);
		port, cmd_text = CmdParser.ParseInt(cmd_text);
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
		local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
		if(room_key) then
			NetworkMain:StartServerViaTunnel(host, port, room_key, username);
		else
			NetworkMain:StartServer(host, port);
		end

		-- turn off for debugging
		GameLogic.options:SetClickToContinue(false);
	end,
};

--[[ ]]
Commands["stopserver"] = {
	name="stopserver", 
	quick_ref="/stopserver", 
	desc="stop server" , 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
		local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
		NetworkMain:Stop();
	end,
};


Commands["webserver"] = {
	name="webserver", 
	quick_ref="/webserver [doc_root_dir] [ip_host] [port]", 
	desc=[[start web server at given directory:
@param ip_host: default to all ip addresses. 
@param port: default to 8099
@param doc_root_dir: www web root directory. it can be empty, "default", "test", "admin"
e.g.
	/webserver						start the default NPL/ParaEngine debug server (mostly for client debugging)
	/webserver script/apps/WebServer/test      start your own HTTP server.
	/webserver admin 127.0.0.1 8099   start admin server at given ip and port.
]], 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(not System.options.mc) then
			GameLogic.AddBBS(nil, L"此命令只有在Paracraft中可用");
			return 
		end
		local doc_root_dir, host, port;
		doc_root_dir, cmd_text = CmdParser.ParseString(cmd_text);
		host, cmd_text = CmdParser.ParseString(cmd_text);
		port, cmd_text = CmdParser.ParseInt(cmd_text) or 8099;
		
		doc_root_dir = doc_root_dir or "script/apps/WebServer/admin";
		if(doc_root_dir) then
			if(doc_root_dir == "test") then
				doc_root_dir = "script/apps/WebServer/test";
			elseif(doc_root_dir == "admin") then
				doc_root_dir = "script/apps/WebServer/admin";
			elseif(doc_root_dir == "www") then
				doc_root_dir = "www";
			end

			local att = NPL.GetAttributeObject();

			-- start server
			local function startserver_()
				if(WebServer:Start(doc_root_dir, host, port)) then
					CommandManager:RunCommand("/clicktocontinue off");
					local addr = WebServer:site_url();
					if(addr) then
						-- change windows title
						NPL.load("(gl)script/apps/WebServer/WebServer.lua");
						local wnd_title = ParaEngine.GetAttributeObject():GetField("WindowText", "")
						wnd_title = wnd_title:gsub("%sport:%d+", "");
						wnd_title = wnd_title .. format(" port:%d", port);
						ParaEngine.GetAttributeObject():SetField("WindowText", wnd_title);

						-- show tips
						GameLogic.SetStatus(format(L"Web Server启动成功: %s", addr));
						GameLogic.AddBBS(nil, format("www_root: %s", doc_root_dir));
					end
				else
					GameLogic.AddBBS(nil, L"只能同时启动一个Server");
				end
			end

			if(not att:GetField("IsServerStarted", false)) then
				local function TestOpenNPLPort_()
					System.os.GetUrl(format("http://127.0.0.1:%s/ajax/console?action=getpid", port), function(err, msg, data)
						if(data and data.pid) then
							if(System.os.GetCurrentProcessId() ~= data.pid) then
								-- already started by another application, 
								-- try 
								port = port + 1;
								TestOpenNPLPort_();
								return;
							else
								-- already opened by the same process
							end
						else
							startserver_();
						end
					end);
				end
				TestOpenNPLPort_();
			end
		end
	end,
};

--[[ connect to a given server
]]
Commands["connect"] = {
	name="connect", 
	quick_ref="/connect [-tunnel room_key] [ip] [port] [username] [password]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[connect to a given private server
@param -tunnel room_key: if specified, ip and port is the tunnel server's ip address and a room_key should be provided.
Example:
/connect     :connect to default ip:localhost and port:8099
/connect -tunnel room_test  :connect to default ip/port for the room_key: room_test
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local ip, port, username, password, option, room_key;
		option, cmd_text = CmdParser.ParseOption(cmd_text);
		if(option == "tunnel") then
			room_key, cmd_text = CmdParser.ParseString(cmd_text);
		end

		ip, cmd_text = CmdParser.ParseString(cmd_text);
		port, cmd_text = CmdParser.ParseInt(cmd_text);
		username, cmd_text = CmdParser.ParseString(cmd_text);
		password, cmd_text = CmdParser.ParseString(cmd_text);
		

		NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
		local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
		if(room_key) then
			NetworkMain:ConnectViaTunnel(ip, port, room_key, username, password);
		else
			NetworkMain:Connect(ip, port, username, password);
		end

		-- turn off for debugging
		GameLogic.options:SetClickToContinue(false);
	end,
};

--[[ disconnect from connect server
]]
Commands["disconnect"] = {
	name="disconnect", 
	quick_ref="/disconnect", 
	desc="disconnect a given private server" , 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
		local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
		NetworkMain:Disconnect();
	end,
};

--[[ send a chat message
]]
Commands["chat"] = {
	name="chat", 
	quick_ref="/chat any text", 
	desc="send a chat message" , 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local player = EntityManager.GetPlayer();
		if(player and cmd_text~="") then
			player:SendChatMsg(cmd_text);
		end
	end,
};

--[[ register a new user. 
]]
Commands["register"] = {
	name="register", 
	quick_ref="/register username password", 
	desc="register a new user or change password" , 
	mode_deny = "",
	mode_allow = "",
	isLocal = true,
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
		local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");

		if(NetworkMain:GetServerManager()) then
			local username, password;
			username, cmd_text = CmdParser.ParseString(cmd_text);
			password, cmd_text = CmdParser.ParseString(cmd_text);
			if(username and password) then
				NetworkMain:GetServerManager().passwordList:AddUser(username, password);
				local player = EntityManager.GetPlayer();
				if(player and cmd_text~="") then
					player:SendChatMsg(format("a new user:%s is registered", username));
				end
			end
		end
	end,
};

--[[ unregister a new user. 
]]
Commands["unregister"] = {
	name="unregister", 
	quick_ref="/unregister username", 
	desc="unregister a user" , 
	mode_deny = "",
	mode_allow = "",
	isLocal = true,
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
		local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");

		if(NetworkMain:GetServerManager()) then
			local username;
			username, cmd_text = CmdParser.ParseString(cmd_text);
			if(username) then
				NetworkMain:GetServerManager().passwordList:RemoveUser(username);
			end
		end
	end,
};

--[[ open the server configuration directory
]]
Commands["configserver"] = {
	name="configserver", 
	quick_ref="/configserver", 
	desc="config the server" , 
	mode_deny = "",
	mode_allow = "",
	isLocal = true,
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local config_dir = "config/ParaCraft/";
		ParaIO.CreateDirectory(config_dir);
		ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..config_dir, "", "", 1);
	end,
};


Commands["runat"] = {
	name="runat", 
	quick_ref="/runat @name /any_command", 
	desc=[[Run a local client side command at given player's console
@param @name: @all for all connected players. @p for last trigger entity. @name for given player name. `__MP__` can be ignored.
@param /any_command: if command is local, it can be sent to client for execution, otherwise it can only run on server.
Examples:
/runat @all /tip hello everyone    send message to every connected user
/runat @__MP__admin /tip hi, admin   send to admin host
/runat @admin /tip hi, admin         send to admin host
/runat @username /tip hi, username   send to a given user
/runat @p /tip hi, username			send to triggering user
]],
	mode_deny = "",
	mode_allow = "",
	isLocal = false,
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playername;
		playername, cmd_text = CmdParser.ParseFormated(cmd_text, "@%S+");
		
		if(playername) then
			playername = playername:gsub("^@", "");
		end
		cmd_text = cmd_text:gsub("^%s+", "");
		
		if(GameLogic.IsServerWorld()) then
			if(playername == "all") then
				local servermanager = GameLogic.GetWorld():GetServerManager();
				if(servermanager) then
					servermanager:SendPacketToAllPlayers(GameLogic.Packets.PacketClientCommand:new():Init(cmd_text));
				end
				-- also run on the server side 
				CommandManager:RunFromConsole(cmd_text, EntityManager.GetPlayer());
			elseif(playername) then
				local targetPlayer;
				if(playername == "p") then
					targetPlayer = EntityManager.GetLastTriggerEntity();
				else
					targetPlayer = EntityManager.GetEntity(playername);
					if(not targetPlayer) then
						if(not playername:match("^__MP__")) then
							playername = "__MP__"..playername;
							targetPlayer = EntityManager.GetEntity(playername);
						end
					end
				end
				if(targetPlayer) then
					if(targetPlayer == EntityManager.GetPlayer()) then
						CommandManager:RunFromConsole(cmd_text, targetPlayer);
					elseif(targetPlayer.SendPacketToPlayer) then
						targetPlayer:SendPacketToPlayer(GameLogic.Packets.PacketClientCommand:new():Init(cmd_text));
					end
				end
			end
		else
			CommandManager:RunFromConsole(cmd_text, EntityManager.GetPlayer());
		end
	end,
};