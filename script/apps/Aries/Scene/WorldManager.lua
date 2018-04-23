--[[
Title: World Manager
Author(s): LiXizhi
Date: 2010/9/11
Desc: design related configurations to all public worlds in the game. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
MyCompany.Aries.WorldManager:Init("script/apps/Aries/Scene/AriesGameWorlds.config.xml");
local world = WorldManager:GetWorldInfo("main_town");
LOG.debug({world, world.worldpath, world.name, })
local world_info = WorldManager:GetCurrentWorld()
local world_info = WorldManager:GetWorldInfo(nil); -- the default world
local world_info = WorldManager:GetReturnWorld()

world_info:SetTeleportBackPosition(x,y,z);
world_info:SetTeleportBackCamera(CameraObjectDistance, CameraLiftupAngle, CameraRotY);
WorldManager:TeleportBack()

WorldManager:SaveSessionCheckPoint()
------------------------------------------------------------
]]
local AutoCameraController = commonlib.gettable("MyCompany.Aries.AutoCameraController");
local CommonClientService = commonlib.gettable("MyCompany.Aries.Service.CommonClientService");
local HomeLandGateway = commonlib.gettable("Map3DSystem.App.HomeLand.HomeLandGateway");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local NPCList = commonlib.gettable("MyCompany.Aries.Quest.NPCList");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local ItemManager = commonlib.gettable("System.Item.ItemManager");


-- teleport cool down in seconds. setting to nil to disable using CD
WorldManager.teleport_stone_cool_down_seconds = nil;
WorldManager.last_teleport_time = nil;
-------------------------------------------
-- a class of world_info
-------------------------------------------
local world_info_class = commonlib.inherit();

-- set the world portal position in the world. 
-- @param x,y,z: if all are nil, the current player position is used. 
function world_info_class:SetTeleportBackPosition(x,y,z)
	if(not x) then
		x, y, z = Player.GetPlayer():GetPosition();
	end
	if(x) then
		self.LastWorldPosX = x;
		self.LastWorldPosY = y;
		self.LastWorldPosZ = z;
		LOG.std("", "debug", "WorldManager", {"SetTeleportBackPosition", self.name, x,y,z})
	end
end

-- set the world portal position in the world. 
-- @param x,y,z: if all are nil, the current player position is used. 
function world_info_class:SetTeleportBackCamera(CameraObjectDistance, CameraLiftupAngle, CameraRotY)
	if(CameraObjectDistance) then
		self.LastWorldCameraObjectDistance = CameraObjectDistance;
		self.LastWorldCameraLiftupAngle = CameraLiftupAngle;
		self.LastWorldCameraRotY = CameraRotY;
	end
end

--------------------------------
-- the default world info
--------------------------------
local default_world_info = world_info_class:new({
	worldpath = "worlds/MyWorlds/61HaqiTown",
	free_to_enter = "true",
	min_level="10",
	can_fly = "true",
    can_reverse_time = "true",
    can_teleport = false,
});

----------------------------------------
-- class world manager
----------------------------------------
-- load from configuration files. 
-- this function can be called multiple times, where the the lastest call may overwrite the old setting. 
-- @param filename: the worlds config file
function WorldManager:Init(filename)
	if(not System.options.mc) then
		NPL.load("(gl)script/apps/Aries/Service/CommonClientService.lua");
		NPL.load("(gl)script/apps/Aries/Scene/AutoCameraController.lua");
		NPL.load("(gl)script/apps/Aries/Quest/NPCList.lua");
	end

	-- read all worlds configuration file. 
	filename = filename or "script/apps/Aries/Scene/AriesGameWorlds.config.xml"
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(not xmlRoot) then
		LOG.std(nil, "error", "WorldManager", "failed loading world config file %s", filename);
		return;
	end	
	LOG.std(nil, "system", "WorldManager", "world config file %s", filename);

	self.worlds = self.worlds or {};
	self.worlds_by_path = self.worlds_by_path or {};
	self.world_filters = self.world_filters or {};

	local node;
	for node in commonlib.XPath.eachNode(xmlRoot, "/Worlds/World") do
		-- only load if version matched. 
		if(node.attr and node.attr.name and 
			(not node.attr.version or node.attr.version=="" or System.options.version == node.attr.version) ) then
			
			local world_info = world_info_class:new();
			commonlib.partialcopy(world_info, node.attr);
			
			world_info.gridnoderule_id = tonumber(world_info.gridnoderule_id);
			world_info.free_to_enter = world_info.free_to_enter ~= "false";
			world_info.min_level = tonumber(world_info.min_level) or 0;
			world_info.can_fly = world_info.can_fly ~= "false";
			world_info.can_reverse_time = world_info.can_reverse_time == "true";
			world_info.can_teleport = world_info.can_teleport == "true";
			if(world_info.can_teleport) then
				world_info.can_follow = world_info.can_follow ~= "false";
			else
				world_info.can_follow = world_info.can_follow == "true";
			end
			world_info.apply_env_effect = world_info.apply_env_effect ~= "false";
			world_info.can_save_location = world_info.can_save_location ~= "false";
			world_info.disable_desktop_ui = world_info.disable_desktop_ui == "true";
			world_info.is_default = world_info.is_default == "true";
			world_info.is_standalone = world_info.is_standalone == "true";
			world_info.is_local_instance = world_info.is_local_instance == "true";
			world_info.share_global_weather = world_info.share_global_weather == "true";
			world_info.wait_for_start = world_info.wait_for_start == "true";
			world_info.MinPopUpDistance = tonumber(world_info.MinPopUpDistance);
			world_info.create_join = world_info.create_join == "true";
			world_info.ignore_quest = world_info.ignore_quest == "true";
			world_info.locked_world_size = tonumber(world_info.locked_world_size);
			world_info.world_center_x = tonumber(world_info.world_center_x);
			world_info.world_center_z = tonumber(world_info.world_center_z);
			world_info.can_jump = world_info.can_jump ~= "false";
			world_info.team_waiting_secs = tonumber(world_info.team_waiting_secs);
			world_info.RealtimePositionUpdateInterval = tonumber(world_info.RealtimePositionUpdateInterval);
			world_info.captain_id = tonumber(world_info.captainID) or 0;
			world_info.arena_teleport_facing = tonumber(world_info.arena_teleport_facing);
			world_info.enter_combat_range = tonumber(world_info.enter_combat_range);
			world_info.min_fly_height = tonumber(world_info.min_fly_height);
			world_info.lowest_land_height = tonumber(world_info.lowest_land_height);
			world_info.ticket_gsid = tonumber(world_info.ticket_gsid);
			world_info.enter_require_gsid = tonumber(world_info.enter_require_gsid);

			if(world_info.enter_combat_range) then
				world_info.enter_combat_range_sq = world_info.enter_combat_range * world_info.enter_combat_range;
				local alert_combat_range = world_info.enter_combat_range + 5;
				world_info.alert_combat_range_sq = alert_combat_range * alert_combat_range;
			end
			world_info.disable_arena_talk = (world_info.disable_arena_talk == "true");
			world_info.island_name = world_info.island_name; -- 副本所在岛屿名，如果不是副本为 nil
			if(world_info.entry_pos) then	-- 副本入口，如果不是副本为nil
				world_info.entry_pos = NPL.LoadTableFromString(world_info.entry_pos);
			end
			if(world_info.local_map_settings) then	-- 副本入口，如果不是副本为nil
				world_info.local_map_settings = NPL.LoadTableFromString(world_info.local_map_settings);
				local settings = world_info.local_map_settings;
				if(settings and settings.center_x and settings.radius) then
					settings.left,  settings.top, settings.right,  settings.bottom = 
						settings.center_x - settings.radius, settings.center_y - settings.radius, 
						settings.center_x + settings.radius, settings.center_y + settings.radius;
					-- settings.center_x, settings.center_y, settings.radius = nil, nil, nil;
				end
			end

			-- world_info.allow_recover_connection = world_info.allow_recover_connection == "true";
			world_info.allow_recover_connection = world_info.allow_recover_connection ~= "false"; -- make it true by default
			world_info.loader_movie_file = if_else(world_info.loader_movie_file == "", nil, world_info.loader_movie_file);
			world_info.loader_asset_list = if_else(world_info.loader_asset_list == "", nil, world_info.loader_asset_list);
			world_info.asset_replace_file = if_else(world_info.asset_replace_file == "", nil, world_info.asset_replace_file);
			world_info.wisp_scene = if_else(world_info.wisp_scene == "", nil, world_info.wisp_scene);
			world_info.allow_hp_recovery = world_info.allow_hp_recovery ~= "false"; -- make it true by default
			if(world_info.immortal_after_combat) then
				world_info.immortal_after_combat = world_info.immortal_after_combat == "true"
			end
			
			if(world_info.born_pos) then
				world_info.born_pos = NPL.LoadTableFromString(world_info.born_pos);
			end
			if(world_info.born_pos0) then
				world_info.born_pos0 = NPL.LoadTableFromString(world_info.born_pos0);
			end
			if(world_info.born_pos1) then
				world_info.born_pos1 = NPL.LoadTableFromString(world_info.born_pos1);
			end
			
			if(world_info.login_pos) then
				world_info.login_pos = NPL.LoadTableFromString(world_info.login_pos);
			end

			if(world_info.worldpath) then
				if(world_info.is_default) then
					self.default_world = world_info;
					self.worlds["default"] = world_info;
				end
				
				self.worlds[world_info.name] = world_info;
				self.worlds_by_path[world_info.worldpath] = world_info;
			elseif(world_info.worldfilter_lowercase) then
				self.worlds[world_info.name] = world_info;
				self.world_filters[world_info.worldfilter_lowercase] = world_info;
			end

			world_info.allow_terrain_slope_collision = world_info.allow_terrain_slope_collision == "true";
			world_info.is_anonymous = world_info.is_anonymous == "true";
		end	
	end
end

-- get captainID on the world. 
-- If still not found, it will return 0.
-- @param worldname: the short world name like "61HaqiTown", or it can be the full worldpath. If nil, it means the default world. 
function WorldManager:GetWorldCaptainID(worldname)
	local captainID = self.worlds[worldname or "default"].captain_id;
	if (captainID) then
		return captainID;
	else
		return 0;
	end
end

-- get worldInstance entry. 
-- If still not found, it will return nil.
-- @param worldname: the short world name like "61HaqiTown", or it can be the full worldpath. If nil, it means the default world. 
function WorldManager:GetWorldInstanceEntry(worldname)
	local result={island_name="",entry_pos={},};
	local worldnm_lower = string.lower(worldname);
	local world_info ={};
	local worldsnm, world;
		
	for worldnm, world in pairs(self.worlds) do
		local lower_worldname = string.lower(worldnm);
		if(worldnm_lower == lower_worldname) then
			world_info = world;
			break;
		end
	end
	if (next(world_info)~=nil) then
		result.island_name = world_info.island_name;
		if (result.island_name) then
			result.entry_pos =  world_info.entry_pos;
		end
	end
	return result;
end


-- get world info by world name or world path. 
-- it will first search for an exact match, if not found, it will search in world filter. 
-- If still not found, it will return the default world info.
-- @param worldname: the short world name like "MainTown", or it can be the full worldpath. If nil, it means the default world. 
-- @param bSetCurrentWorld: true to set as current world. 
function WorldManager:GetWorldInfo(worldname, bSetCurrentWorld)
	local world_info;
	if(self.worlds) then
		world_info = self.worlds[worldname or "default"] or self.worlds_by_path[worldname or "default"];
		if(not world_info and worldname) then
			local worldpath_lower = string.lower(worldname);
			local filter, world
			for filter, world in pairs(self.world_filters) do
				if(worldpath_lower:match(filter)) then
					world_info = world;
					break;
				end
			end
		end
	end
	
	world_info = world_info or default_world_info;
	if(bSetCurrentWorld) then
		self:SetCurrentWorld(world_info);
	end
	return world_info;
end

-- set the current world by world name
-- @param worldname: this is either worldname or worldpath, or world_info table. 
function WorldManager:SetCurrentWorld(worldname)
	if(type(worldname) ~= "table") then
		self.current_world = self:GetWorldInfo(worldname);
	else
		self.current_world = worldname;
	end
	if(self.current_world and (self.current_world.can_save_location or self.current_world.local_map_url)) then
		-- if the world can save location or has a local map, we will enable returning. 
		self.last_return_world = self.current_world;
	end
end

-- get current world info. 
function WorldManager:GetCurrentWorld()
	return self.current_world or self:GetWorldInfo()
end

-- get the return world info. Return world is the world that user should return to when getting out of homeland or some other standalone worlds. 
function WorldManager:GetReturnWorld()
	return self.last_return_world or self:GetWorldInfo()
end

-- set the world portal position in the current world. 
-- @param x,y,z: if all are nil, the current player position is used. 
function WorldManager:SetTeleportBackPosition(x,y,z)
	local world_info = self:GetCurrentWorld();
	if(world_info) then
		world_info:SetTeleportBackPosition(x,y,z);
	end
end

-- set the world portal position in the current world. 
-- @param x,y,z: if all are nil, the current player position is used. 
function WorldManager:SetTeleportBackCamera(CameraObjectDistance, CameraLiftupAngle, CameraRotY)
	local world_info = self:GetCurrentWorld();
	if(world_info) then
		world_info:SetTeleportBackCamera(CameraObjectDistance, CameraLiftupAngle, CameraRotY);
	end
end

-- teleport back to the previously visited public world. This function is only effective if current world is homeland or a standalone world. 
function WorldManager:TeleportBack()
	local world_info = self:GetReturnWorld();
	if(world_info and world_info~=self:GetCurrentWorld()) then
		LOG.std("", "info", "WorldManager", "teleport back to previous world: %s", world_info.name);
		System.App.Commands.Call(System.App.Commands.GetDefaultCommand("LoadWorld"), {
			worldpath = world_info.worldpath,
			PosX = world_info.LastWorldPosX,
			PosY = world_info.LastWorldPosY,
			PosZ = world_info.LastWorldPosZ,
			CameraObjectDistance = world_info.LastWorldCameraObjectDistance,
			CameraLiftupAngle = world_info.LastWorldCameraLiftupAngle,
			CameraRotY = world_info.LastWorldCameraRotY,
		});
		return true;
	end
end

-- similar to TeleportBack except that it will check whether to save. 
function WorldManager:TeleportBackCheckSave()
	WorldCommon.LeaveWorld(function(result)
		if(_guihelper.DialogResult.Yes == result or _guihelper.DialogResult.No == result) then
			HomeLandGateway.ReturnToPublicWorld();
		end
	end);
end

-- goto the home world of the given nid
-- @param nid: nid number. if nil, it means the current user. 
function WorldManager:GotoHomeWorld(nid)
	Map3DSystem.App.HomeLand.HomeLandGateway.Gohome(nid)
end

-- record the last player position so that when the user logins again, it will born at that position. 
-- this function is called after people leaves a given world. 
function WorldManager:RecordLastPosition(bForceFlush)
	local world_info = self:GetCurrentWorld();

	local function save_last_world_pos(x,y,z)
		local server_info = GameServer.rest.client.cur_world_server or {};
		if(x == 0 and y==0 and z==0) then
			if(System.options.isAB_SDK) then
				_guihelper.MessageBox("SDK: Error: 0,0,0 found when WorldManager:RecordLastPosition is called")
			end
			LOG.std(nil, "error", "WorldManager", "saving world pos with 0,0,0")
		else
			Player.SaveLocalData("LastPosition", {pos={x=x, y=y, z=z}, worldname=world_info.name,
				}, nil, not bForceFlush);
		end
		Player.SaveLocalData("LastPort", server_info.port, true, not bForceFlush);
		Player.SaveLocalData("LastWorldServer", server_info, true, not bForceFlush);
	end
	if(world_info and world_info.can_save_location) then
		-- only record the position in official world
		local x, y, z = Player.GetPlayer():GetPosition();
		save_last_world_pos(x,y,z)
	else
		world_info = self:GetReturnWorld();
		if(world_info and world_info.can_save_location) then
			local x, y, z = world_info.LastWorldPosX, world_info.LastWorldPosY, world_info.LastWorldPosZ;
			save_last_world_pos(x,y,z)
		end
	end
end

-- return an address table containing the world address. 
-- The returned address table can be sent to other players so that they use TeleportByWorldAddress method to teleport to this player.
-- @return nil if teleporting is forbidden in the current world.
function WorldManager:GetWorldAddress()
	local world_info = self:GetCurrentWorld();
	if(world_info.can_teleport) then
		local address = {};
		address.x, address.y, address.z = Player.GetPlayer():GetPosition();
		address.game_nid = Map3DSystem.GSL_client.gameserver_nid;
		address.world_id = Map3DSystem.GSL_client.worldserver_id;
		address.name = world_info.name;
		address.ws_seqid = MyCompany.Aries.WorldServerSeqId;
		address.ws_text = MyCompany.Aries.WorldServerName;
		
		if(world_info.teleport_match_worldpath) then
			address.worldpath = System.options.worldpath;
		end

		local cur_params = self:GetCurrentWorldSession();
		if(cur_params) then
			address.room_key = cur_params.room_key;
			address.force_nid = cur_params.force_nid;
			if(cur_params.match_info) then
				-- we prohibit any world with match_info to be teleported
				return nil;
			end
		end

		return address;
	end
end

local last_world_session;
local cur_world_session;

-- save world session so that we can recover from it. 
-- @param params: this should be the params passed to "File.EnterAriesWorld" command. 
-- @param bAllowRecoverSession: if true we will allow recover session if user connection is broken during game play. 
function WorldManager:SaveWorldSession(params, bAllowRecoverSession)
	cur_world_session = commonlib.deepcopy(params);
	
	if(cur_world_session and cur_world_session.match_info and cur_world_session.match_info.teams) then
		-- clean up match_info struct to make it more compact. 
		local _, team
		for _, team in ipairs(cur_world_session.match_info.teams) do
			team.match_info = nil;
		end
	end

	if (cur_world_session) then
		cur_world_session.last_user_nid = System.User.nid;
		-- remember the connection info.
		cur_world_session.gs_nid = cur_world_session.gs_nid or Map3DSystem.User.gs_nid;
		cur_world_session.ws_id = cur_world_session.ws_id or Map3DSystem.User.ws_id;
	end

	if(not bAllowRecoverSession) then
		last_world_session = nil
	else
		last_world_session = cur_world_session;
	end
end

-- get the last session params that is passed to "File.EnterAriesWorld" command. 
function WorldManager:GetCurrentWorldSession()
	return cur_world_session;
end

-- save the current session to disk so that we can recover it within 2 mins. 
-- @return the last world session table that is saved. or nil, it nothing is saved. 
function WorldManager:SaveSessionCheckPoint()
	if(last_world_session) then
		last_world_session.last_date = ParaGlobal.GetDateFormat("yyyy-M-d"); 
		last_world_session.last_time = ParaGlobal.timeGetTime();
		last_world_session.PosX, last_world_session.PosY, last_world_session.PosZ = Player.GetPlayer():GetPosition();
		LOG.std(nil, "system", "WorldManager", "world session checkpoint saved: %s", commonlib.serialize_compact(last_world_session));
		Player.SaveLocalData("last_login", last_world_session, true);
		return last_world_session;
	end
end

-- we only allow recovering if user reconnect within this amount of time in milliseconds. 
local max_recover_time = 120000;

-- recover the last world session. 
-- @param params: the original local world params. we will only recover if the params is on the same world
-- @return true if session should be recovered
function WorldManager:RecoverWorldSession(params)
	local world_session = Player.LoadLocalData("last_login", nil, true);
	
	if( world_session and world_session.name and world_session.last_user_nid == System.User.nid) then
		local cur_time = ParaGlobal.timeGetTime();
		local force_recover_last_position;
		--if(System.options.version == "teen") then
			---- always login to last public world unless we have a broken connection last time. 
			--local world_info = self:GetWorldInfo(world_session.name)
			--if(world_info and world_info.can_save_location) then
				---- for teen version, the user is always spawned at the last logout position. 
				--force_recover_last_position = true;
			--end
		--end
		if( force_recover_last_position or 
			(world_session.last_date == ParaGlobal.GetDateFormat("yyyy-M-d") and 
			((cur_time-(world_session.last_time or 0)) < max_recover_time) and 
			(world_session.gs_nid == params.gs_nid) and (world_session.ws_id == params.ws_id))) then

			if( not world_session.room_key ) then
				local world_info = self:GetWorldInfo(world_session.name);
				if(not world_info.can_save_location or world_session.force_nid == 1) then
					-- For instance world without room_key or with a random nid(1), like PvP trial worlds or auto created worlds, we will disable recovering. 
					-- TODO: we may support in-place recovering session in future. 
					return;
				end
			end

			--NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClientServicePage.lua");
			-- local LobbyClientServicePage = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClientServicePage");
			--if(not LobbyClientServicePage.CheckTicket_CanPass(world_session.name, false)) then
				--LOG.std(nil, "system", "WorldManager", "not enough tickets to enter the world during recovering. %d: %s", cur_time, commonlib.serialize_compact(world_session));
				--return;
			--end

			LOG.std(nil, "system", "WorldManager", "world session recovered at time%d: %s", cur_time, commonlib.serialize_compact(world_session));
			-- now login
			world_session.ws_text = world_session.ws_text or params.ws_text;
			world_session.ws_seqid = world_session.ws_seqid or params.ws_seqid;
			
			-- just in case input is blocked since we did not select world server. 
			ParaScene.GetAttributeObject():SetField("BlockInput", false);
			ParaCamera.GetAttributeObject():SetField("BlockInput", false);

			Player.SaveLocalData("last_login", nil, true);
			System.App.Commands.Call(System.App.Commands.GetLoadWorldCommand(), world_session); 
			return true;
		end
	end
end

-- get the born address of the main town. everytime it will use a random position around the born position. 
function WorldManager:GetMainTownBornAddress(name)
	local worldinfo = self:GetWorldInfo(name or "default");
	if(worldinfo) then
		if(worldinfo.born_pos) then
			local x,y,z = worldinfo.born_pos.x, worldinfo.born_pos.y, worldinfo.born_pos.z;
			local radius = worldinfo.born_pos.radius;
			if(radius) then
				x = x + (math.random()*2-1)*radius;
				z = z + (math.random()*2-1)*radius;
			end
			local address = {x=x, y=y, z=z, name = worldinfo.name};
			return address;
		else
			_guihelper.MessageBox(format("warn: %s 没有出生点", worldinfo.name))
			LOG.std(nil, "error", "worldmanager", "%s does not have a born_pos", worldinfo.name);
		end
	end
end

-- teleport the current user to a new world address (may not necessarily be on the same computer). 
-- this function has a cool down of 60 seconds (reducing server load). 
-- @param address: a table of {game_nid, world_id, name, x, y, z, facing}
-- @param bIgnoreConstraint: if true, we will ignore bag weight and player level. 
--  Otherwise if the player is not qualified to teleport to the address, we will display an error message.
-- @return false: return false if we need to cool down.
function WorldManager:TeleportByWorldAddress(address, bIgnoreConstraint)
	if(not address) then return end
	local world_info = self:GetCurrentWorld();
	local Player = commonlib.gettable("MyCompany.Aries.Player");
	local Scene = commonlib.gettable("MyCompany.Aries.Scene");

	local dest_world_info = WorldManager:GetWorldInfo(address.name);
	if(not dest_world_info) then return end

	if(address.name=="designhouse" or address.name=="mcworld") then
		if(address.worldpath and address.worldpath:match("^worlds/DesignHouse/")) then
			if(address.worldpath:match("^worlds/DesignHouse/[^/]*%.zip$")) then
				if(ParaIO.DoesAssetFileExist(address.worldpath, true)) then
					ParaAsset.OpenArchive(filepath, true);
				end
			end

			if(System.world:DoesWorldExist(address.worldpath, true)) then
				NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
				local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
				WorldCommon.OpenWorld(address.worldpath, true);
			else
				LOG.std(nil, "warn", "TeleportByWorldAddress", "%s does not exist", address.worldpath);
				_guihelper.MessageBox(format("您没有安装创意空间世界%s, 不能传送", address.worldpath))
			end
		else
			LOG.std(nil, "warn", "TeleportByWorldAddress", "%s not trusted", address.worldpath or "");
		end
		return;
	end

	if(not bIgnoreConstraint) then
		if(Player.IsBagTooHeavy() and System.options.version ~= "teen") then
			_guihelper.MessageBox("你背包中的物品太多了. 快去打开背包，出售一些装备或收集品吧！");
			return;
		elseif(Player.IsInCombat()) then
			_guihelper.MessageBox("战斗中无法传送");
			return;
		elseif(Player.GetLevel() < dest_world_info.min_level) then
			_guihelper.MessageBox("你的战斗等级不够，无法传送到"..(dest_world_info.world_title or "目标地点"));
			return;
		end
	end

	local LobbyClientServicePage = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClientServicePage");
	if(not LobbyClientServicePage.CheckTicket_CanPass(address.name)) then
		if(dest_world_info.name == "DarkForestIsland") then
			_guihelper.MessageBox("你没有【幽暗岛】地图, 不能前往【幽暗岛】。至少拥有1件S4装备后前往【沙漠岛】找法斯特船长获得【幽暗岛】地图");
		else
			_guihelper.MessageBox(format("没有门票, 无法进入目标副本:%s",dest_world_info.world_title or ""));	
		end
		
		return;
	end

	-- teleporting by address.
	LOG.std(nil, "info", "WorldManager", "teleporting by address"..commonlib.serialize_compact(address).."from current world:"..tostring(world_info.name));

	local function LoadWorld_(bLogoutFirst)
		AutoCameraController:SaveCamera();
		if(self:IsPublicWorld(address.name) or address.room_key) then
			System.App.Commands.Call(System.App.Commands.GetDefaultCommand("LoadWorld"), {
					gs_nid = address.game_nid,-- force using the game server nid
					ws_id = address.world_id, -- force using the world server id
					name = address.name,
					PosX = address.x,
					PosY = address.y,
					PosZ = address.z,
					PosFacing = address.facing,
					ws_seqid = address.ws_seqid,
					ws_text = address.ws_text,
					room_key = address.room_key,
					force_nid = address.force_nid,
				});
		else
			NPL.load("(gl)script/apps/Aries/CrazyTower/CrazyTowerProvider.lua");
			local CrazyTowerProvider = commonlib.gettable("MyCompany.Aries.CrazyTower.CrazyTowerProvider")
			local game = CrazyTowerProvider.GetGameTemplate(address.name);
			if(game)then
				MyCompany.Aries.Quest.QuestHelp.DoOpenCrazyTower(address.name);
			else
				-- enter instance world
				MyCompany.Aries.Quest.QuestHelp.DoAutoJoinRoom_PvE(address.name);
			end
		end
	end

	if(not self:IsPublicWorld(address.name) and address.room_key) then
		-- just connect locally
		address.game_nid = nil;
		address.world_id = nil;
		address.ws_text = nil;
		address.ws_seqid = nil;
	end

	if( (not address.game_nid or address.game_nid == Map3DSystem.GSL_client.gameserver_nid) and 
		(not address.world_id or address.world_id == Map3DSystem.GSL_client.worldserver_id) ) then

		if((not address.name or address.name == world_info.name)) then
			-- both game and world server are not changed, simply change player position. 
			LOG.std(nil, "info", "WorldManager", "teleporting locally");
			if(address.x and address.y and address.z) then
				Scene.OnMapTeleport({position={address.x, address.y, address.z, address.facing}, camera = {ParaCamera.GetEyePos()},bForceSkipTeleportCheck=true});
			end
		else
			-- the server is not changed, simple switch the worldpath by loading world again. 
			LOG.std(nil, "info", "WorldManager", "teleporting locally with different world path");
			LoadWorld_();
		end
	elseif(address.game_nid) then --  and address.game_nid ~= Map3DSystem.GSL_client.gameserver_nid
		LOG.std(nil, "info", "WorldManager", "teleporting across servers. break connection and connect again");
		-- if the game server is on a different server, we need to break the previous connection and login again. 
		local function ConnectFail(reasonText)
			_guihelper.CloseMessageBox();
			_guihelper.MessageBox(reasonText or "无法连接这台服务器, 请重新登录并试试其他服务器", function()
					Map3DSystem.App.Commands.Call("Profile.Aries.Restart", {method="soft"});
				end)
		end
		
		paraworld.ShowMessage("正在切换服务器...", nil, _guihelper.MessageBoxButtons.Nothing);
		----------------------------
		-- switch game server and authenticate using old account
		----------------------------
		local rest_client = GameServer.rest.client;
		Map3DSystem.GSL_client:LogoutServer();
		-- disconnect first
		Map3DSystem.GSL_client:Disconnect();
		GameServer.rest.client:disconnect();

		-- here we will wait 5 seconds before proceeding. 
		-- if target is on a different game server, diconnect old and connect to the new one and sign in using the same account. 
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			GameServer.rest.client:connect({nid=address.game_nid, world_id=address.world_id,}, nil, function(msg) 
				if(msg.connected) then
					LOG.std(nil, "system", "worldmanager", "connection with game server %s is established", address.game_nid)
					
					-- authenticate again with the new game server using existing account. 
					paraworld.auth.AuthUser(Map3DSystem.User.last_login_msg or {username = tostring(System.User.username), password = System.User.Password,}, "login", function (msg)
						if(msg==nil) then
							ConnectFail("这台服务器无法认证, 请试试其他服务器");
						elseif(msg.issuccess) then	
							LoadWorld_();
						else
							ConnectFail("服务器认证失败了, 请重新登录");
						end
					end, nil, 20000, function(msg)
						-- timeout request
						commonlib.applog("Proc_Authentication timed out")
						ConnectFail("用户验证超时了, 可能服务器太忙了, 或者您的网络质量不好.");
					end);
				else
					ConnectFail("无法连接这台服务器, 请试试其他服务器");
				end
			end)
		end})
		mytimer:Change(5000,nil);
	end
end
--当前世界是否可以跳转
function WorldManager:CanTeleport_CurrentWorld()
	local world_info = self:GetCurrentWorld();
	if(world_info)then
		return world_info.can_teleport;
	end
end

function WorldManager:CanTeleport(worldname)
	local world_info = if_else(worldname~=nil, self:GetCurrentWorld(), self:GetWorldInfo(worldname));
	if(world_info)then
		return world_info.can_teleport;
	end
end

--跳转到当前世界船长面前 并且带对话框提示
--@param worldname:目的地
--@param callbackFunc:call back function
function WorldManager:TeleportTo_CurrentWorld_Captain_PreDialog(worldname,callbackFunc)
	if(not worldname)then return end
	if( not self:HasCaptainInCurrentWorld()) then
		_guihelper.MessageBox("当前岛屿无法传送, 请先返回主城")
		return;
	end
	local goal_world =  WorldManager:GetWorldInfo(worldname);
	local s = string.format("该目标在%s，可以先去问问法斯特船长.",goal_world.world_title or "");
	NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
	_guihelper.Custom_MessageBox(s,function(result)
		if(result == _guihelper.DialogResult.Yes)then
			WorldManager:TeleportTo_CurrentWorld_Captain();
			if(callbackFunc)then
				callbackFunc();
			end
		end
	end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/OK_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/Cancel_32bits.png; 0 0 153 49"});
end

-- return true if there is captain in the current world. 
function WorldManager:HasCaptainInCurrentWorld()
	local world_info = self:GetCurrentWorld();
	if(world_info)then
		local worldname = world_info.name;
		local thisCaptainID = WorldManager:GetWorldCaptainID(worldname);
		local npc, __, npc_data = NPCList.GetNPCByIDAllWorlds(thisCaptainID);
		if(npc)then
			return true;
		end
	end
end
--跳转到当前世界船长面前
function WorldManager:TeleportTo_CurrentWorld_Captain()
	local world_info = self:GetCurrentWorld();
	if(world_info)then
		local worldname = world_info.name;
		local thisCaptainID = WorldManager:GetWorldCaptainID(worldname);
		local npc, __, npc_data = NPCList.GetNPCByIDAllWorlds(thisCaptainID);
		if(npc)then
			local facing = npc.facing or 0;
			facing = facing + 1.57
			local radius = 5;
			local end_pos = npc.position;
			if(end_pos)then
				local  x,y,z = end_pos[1],end_pos[2],end_pos[3];
				x = x + radius * math.sin(facing);
				z = z + radius * math.cos(facing);
				if(x and y and z)then
					local Position = {x,y,z, facing+1.57};
					local CameraPosition = { 15, 0.27, facing + 1.57 - 1};
					local msg = { aries_type = "OnMapTeleport", 
								position = Position, 
								camera = CameraPosition, 
								bCheckBagWeight = true,
								wndName = "map", 
								end_callback = function()
									-- automatically open dialog when talking to npc. added by Xizhi to simplify user actions.
									local npc_id = tonumber(npc.npc_id);
									if(npc_id) then
										local TargetArea = commonlib.gettable("MyCompany.Aries.Desktop.TargetArea");
										TargetArea.TalkToNPC(npc_id, nil, false);
									end	
								end
							};
					CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
				end
			end
		end
	end
end

local world_effect_state = nil;
local last_effect_state = nil;
-- we can use this function to temperarily enable certain effect of a given world, such as shadow or glow effect. 
-- one need to make sure the user does not have the option to alter the world settings before PopWorldEffectStates() is called.
-- the PopWorldEffectStates() is always called when loading a new world. 
-- @param states: such as { bUseShadow = bool, bFullScreenGlow=bool}
function WorldManager:PushWorldEffectStates(states)
	if(not world_effect_state) then
		self:PopWorldEffectStates();
	end
	if(not states) then
		return;
	end
	world_effect_state = states;
	last_effect_state = {};

	if(states.bFullScreenGlow or states.bUseShadow) then
		states.EffectLevel = states.EffectLevel or 1;
	end

	local att = ParaEngine.GetAttributeObject();
	if(states.bUseShadow~=nil) then
		last_effect_state.bUseShadow = att:GetField("SetShadow", false);
		att:SetField("SetShadow", states.bUseShadow);
		att:SetField("UseDropShadow", not states.bUseShadow);
	end

	if(states.EffectLevel~=nil) then
		last_effect_state.EffectLevel = att:GetField("Effect Level", 0);
		att:SetField("Effect Level", states.EffectLevel);
	end

	if(states.bFullScreenGlow~=nil) then
		last_effect_state.bFullScreenGlow = ParaScene.GetAttributeObject():GetField("FullScreenGlow", false);
		ParaScene.GetAttributeObject():SetField("FullScreenGlow", states.bFullScreenGlow);
	end
end

-- pop world state
function WorldManager:PopWorldEffectStates()
	if(last_effect_state) then
		local states = last_effect_state;
		local att = ParaEngine.GetAttributeObject();
		if(states.bUseShadow~=nil) then
			att:SetField("SetShadow", states.bUseShadow);
			att:SetField("UseDropShadow", not states.bUseShadow);
		end

		if(states.EffectLevel~=nil) then
			att:SetField("Effect Level", states.EffectLevel);
		end

		if(states.bFullScreenGlow~=nil) then
			ParaScene.GetAttributeObject():SetField("FullScreenGlow", states.bFullScreenGlow);
		end	
		
	end
	world_effect_state = nil;
	last_effect_state = nil;
end

-- 跳转到指定世界的指定坐标，如果不在同一个世界，会提示跳转到船长附近
-- 跳转成功将消耗一颗传送石
-- @param worldname:世界名称
-- @param position:位置坐标 {x,y,z,facing(optional)}
-- @param camera(optional):摄影机坐标 {CameraObjectDistance,CameraLiftupAngle,CameraRotY}
-- @param before_jump_func: dispatch before jump
-- @param after_jump_func: dispatch after jump
-- @param ignore_jump_stone:true 忽略传送石的判断 ,default value is nil
-- @param ignore_instance_world: ignore instance world can not jump. most likely happen in LocalMapTeen. 
-- @param bForceJumpStone: free jump is disabled, and jump stone must be used. 
-- @return true if we found the position and can jump. 
function WorldManager:GotoWorldPosition(worldname,position,camera,before_jump_func,after_jump_func,ignore_jump_stone, ignore_instance_world, bIgnoreConstraint, bForceJumpStone)
	if(not position)then
		return
	end

	if(not ignore_instance_world and (WorldManager:IsInstanceWorld(worldname) and not WorldManager:CanTeleport(worldname)))then
        _guihelper.MessageBox(format("目标在副本[%s]中<br/>副本不能跳转！", WorldManager:GetWorldInfo(worldname).world_title or "" ));
		return;
	end
	local __,guid,__,copies = ItemManager.IfOwnGSItem(12016);
    copies = copies or 0;
	
	if(not bIgnoreConstraint) then
		local dest_world_info = WorldManager:GetWorldInfo(worldname);
		if(Player.IsBagTooHeavy() and System.options.version ~= "teen") then
			_guihelper.MessageBox("你背包中的物品太多了. 快去打开背包，出售一些装备或收集品吧！");
			return;
		elseif(Player.IsInCombat()) then
			_guihelper.MessageBox("战斗中无法传送");
			return;
		elseif(Player.GetLevel() < (dest_world_info.min_level or 0)) then
			_guihelper.MessageBox("你的战斗等级不够，无法传送到"..(dest_world_info.world_title or "目标地点"));
			return;
		end
	end

	-- this will ignore teleport freely. 
	ignore_jump_stone = ignore_jump_stone or MyCompany.Aries.VIP.CanTeleportFree()
	local jump_stone_cooldown = 0;
    if(not ignore_jump_stone)then
		if(WorldManager.teleport_stone_cool_down_seconds) then
			jump_stone_cooldown = WorldManager.teleport_stone_cool_down_seconds - math.floor((commonlib.TimerManager.GetCurrentTime() - (WorldManager.last_teleport_time or 0))/1000);
		else
			jump_stone_cooldown = 1;
		end
		
		if(not bForceJumpStone and jump_stone_cooldown <=0 ) then
			WorldManager.last_teleport_time = commonlib.TimerManager.GetCurrentTime();
			ignore_jump_stone = true;
		else
			if(copies <= 0)then
				NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
				local s;
				if(bForceJumpStone) then
					s = "地图跳转需要传送石！你没有<pe:item gsid='12016' isclickable='false' style='float:left;width:28px;height:28px;'/><span class='guide'>传送石</span> 不能立即传送. ";
				else
					if(WorldManager.teleport_stone_cool_down_seconds) then
						s = format("你没有<pe:item gsid='12016' isclickable='false' style='float:left;width:28px;height:28px;'/><span class='guide'>传送石</span>不能立即传送.<br/>免费传送还需%d秒才能再次使用！<br/>充值<span class='guide'>魔法星VIP2级</span>,可永久免费传送！", jump_stone_cooldown)
					else
						bForceJumpStone = true;
						s = format("你没有<pe:item gsid='12016' isclickable='false' style='float:left;width:28px;height:28px;'/><span class='guide'>传送石</span>不能立即传送.<br/>充值<span class='guide'>魔法星VIP2级</span>,可永久免费传送！")
					end
				end
				_guihelper.Custom_MessageBox(s,function(result)
					if(result == _guihelper.DialogResult.Yes)then
						--local command = System.App.Commands.GetCommand("Profile.Aries.PurchaseItemWnd");
						--if(command) then
							---- command:Call({gsid = 12016}); -- modou
							--command:Call({gsid = 12016, exid = 1313, npc_shop = true}); -- qidou
						--end
						MyCompany.Aries.Desktop.Dock.FireCmd("MagicStarPage.ShowPage");
					end
				end,_guihelper.MessageBoxButtons.YesNo,{show_label = true, yes = "查看魔法星", no = if_else(bForceJumpStone, "取消", "我再等等")});
				return
			end
		end
	end
	local function do_jump()
		if(before_jump_func)then
			before_jump_func();
		end
		local cur_world = WorldManager:GetCurrentWorld();
		if(not worldname)then
			worldname = cur_world.name;			
		end
		if(not camera)then
			camera = { 15, 0.27, 0};
		end
		if(cur_world.name ~= worldname)then
			local goal_world = WorldManager:GetWorldInfo(worldname);
			if(goal_world)then
				local allow_teleport_direct = true;
				if(allow_teleport_direct) then
					local address = WorldManager:GetMainTownBornAddress(goal_world.name);
					address = commonlib.copy(address);
					if(position and position[1]) then
						address.x = position[1];
						address.y = position[2];
						address.z = position[3];
						address.facing = position[4];
					end
					WorldManager:TeleportByWorldAddress(address, true);
							
					----如果需要传送石
					--if(not ignore_jump_stone)then
						--ItemManager.DestroyItem(guid, 1, function(msg) end);
					--end
					--if(after_jump_func)then
						--after_jump_func();
					--end
					--local s;
					--if(ignore_jump_stone)then
						--s = string.format("该目标在%s，是否直接传送?",goal_world.world_title or "");
					--else
						--s = string.format("该目标在%s，是否使用传送石直接传送?",goal_world.world_title or "");
					--end
					--_guihelper.MessageBox(s,function(result)
						--if(result == _guihelper.DialogResult.Yes)then
							----code here		
						--end
					--end,_guihelper.MessageBoxButtons.YesNo);
				else
					local s;
					if(ignore_jump_stone)then
						s = string.format("该目标在%s，可以先去问问法斯特船长.",goal_world.world_title or "");
					else
						s = string.format("该目标在%s，可以先去问问法斯特船长.<br/>是否使用传送石直接传送?",goal_world.world_title or "");
					end
					NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
					_guihelper.Custom_MessageBox(s,function(result)
						if(result == _guihelper.DialogResult.Yes)then
							WorldManager:TeleportTo_CurrentWorld_Captain();
							--如果需要传送石
							if(not ignore_jump_stone)then
								ItemManager.DestroyItem(guid, 1, function(msg) end);
							end
							if(after_jump_func)then
								after_jump_func();
							end
						end
					end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/OK_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/Cancel_32bits.png; 0 0 153 49"});
				end
			end
			return;
		end
		local msg = { aries_type = "OnMapTeleport", 
					position = position, 
					camera = camera, 
					bCheckBagWeight = true,
					wndName = "map", 
					-- this will ignore instance_world, and always to a location teleport. 
					bForceSkipTeleportCheck = ignore_instance_world or WorldManager:CanTeleport(worldname),
					end_callback = function()
						if(not ignore_jump_stone)then
							ItemManager.DestroyItem(guid, 1, function(msg) end);
						end
						if(after_jump_func)then
							after_jump_func();
							NPL.load("(gl)script/apps/Aries/Quest/QuestTrackerPane.lua");	
							local QuestTrackerPane = commonlib.gettable("MyCompany.Aries.Quest.QuestTrackerPane");
							if(not QuestTrackerPane.IsNearPosition(position[1], position[2], position[3])) then
								QuestTrackerPane.FindPath_ReActive();
							end
						end
					end
				};
		CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
	end
    if(ignore_jump_stone)then
		do_jump();
	else	
		NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
		local s;
		if(bForceJumpStone) then
			s = format("地图跳转需要传送石！<br/>是否使用一颗<span class='guide'>传送石</span>？你现在有%d颗传送石。<br/>充值<span class='guide'>魔法星VIP2级</span>,可以免费传送！<br/>", copies);
		else
			if(not WorldManager.teleport_stone_cool_down_seconds) then
				bForceJumpStone = true;
			end
			s = format("是否使用一颗<span class='guide'>传送石</span>跳转？你现在有%d颗传送石。<br/>充值<span class='guide'>魔法星VIP2级</span>,可以免费传送！", copies);
		end
		_guihelper.Custom_MessageBox(s,function(result)
			if(result == _guihelper.DialogResult.Yes)then
				do_jump();
			end
		end,_guihelper.MessageBoxButtons.YesNo,{show_label = true, yes = "使用传送石", no = if_else(bForceJumpStone, "取消", "我再等等")});
	end
	return true;
end

-- return true if npc is found. but may not mean that it can jump now. 
function WorldManager:GotoNPC(npcid,callbackFunc)
	if(not npcid)then return end
    local worldname,position,camera = WorldManager:GetWorldPositionByNPC(npcid);

	if(worldname and position) then
		WorldManager:GotoWorldPosition(worldname,position,camera,function()
			if(callbackFunc)then
				callbackFunc();
			end
		end,nil,true);   
		return true;
	end
end

function WorldManager:TrackAndGotoNPC(npcid,callbackFunc)
	local NPCList = commonlib.gettable("MyCompany.Aries.Quest.NPCList");
	local npc, worldname = NPCList.GetNPCByIDAllWorlds(npcid);
    if(npc and npc.position) then
        local worldname,position,camera = WorldManager:GetWorldPositionByNPC(npcid);
        local params = {
				x = npc.position[1],
				y = npc.position[2],
				z = npc.position[3],
				jump_pos = position,
				camPos = camera,
				worldInfo = WorldManager:GetWorldInfo(worldname),
				radius = 4,
				targetName = npc.name,
		}
        local QuestPathfinderNavUI = commonlib.gettable("MyCompany.Aries.Quest.QuestPathfinderNavUI");
		QuestPathfinderNavUI.RefreshPage(true);
		QuestPathfinderNavUI.SetTargetQuest(params)

        WorldManager:GotoWorldPosition(worldname,position,camera,callbackFunc);
        return true;
    end
end

--return worldname,Position {x,y,z, facing},CameraPosition
function WorldManager:GetWorldPositionByNPC(npcid)
	if(not npcid)then return end
	local npc, worldname, npc_data = NPCList.GetNPCByIDAllWorlds(npcid);
	if(npc)then
		local facing = npc.facing or 0;
		facing = facing + 1.57
		local radius = 5;
		local end_pos = npc.position;
		if(end_pos)then
			local  x,y,z = end_pos[1],end_pos[2],end_pos[3];
			x = x + radius * math.sin(facing);
			z = z + radius * math.cos(facing);
			if(x and y and z)then
				local Position = {x,y,z, facing+1.57};
				local CameraPosition = { 15, 0.27, facing + 1.57 - 1};
				return worldname,Position,CameraPosition;
			end
		end
	end
end

-- whether we have ticket for a given world. For free world, this function always returns true. 
function WorldManager:HasTicket(name)
	local world_info = if_else(name~=nil, self:GetWorldInfo(name), self:GetCurrentWorld());
	if(world_info and world_info.enter_require_gsid) then
		local has_ticket, guid = ItemManager.IfOwnGSItem(world_info.enter_require_gsid);
		if(not has_ticket) then
			return false;
		end
	end
	if(world_info and world_info.ticket_gsid) then
		local has_ticket, guid = ItemManager.IfOwnGSItem(world_info.ticket_gsid);
		if(not has_ticket) then
			return false;
		end
	end
	return true;
end


--当前是否在副本当中
--除了公共世界，都认为是在副本当中
function WorldManager:IsInInstanceWorld()
	local world_info = self:GetCurrentWorld();
	if(world_info)then
		local worldname = world_info.name;
		return self:IsInstanceWorld(worldname);
	end
	return false;
end

function WorldManager:IsInPublicWorld()
	local world_info = self:GetCurrentWorld();
	if(world_info)then
		local worldname = world_info.name;
		return self:IsPublicWorld(worldname);
	end
	return false;
end

-- whether we are in public world. 
function WorldManager:IsPublicWorld(worldname)
	if(not worldname)then return end
	if(CommonClientService.IsKidsVersion())then
		if(not self.public_world_map)then
			self.public_world_map = {
				["NewUserIsland"] = true,-- 新手岛
				["61HaqiTown"] = true,-- 哈奇岛
				["FlamingPhoenixIsland"] = true,--火鸟岛
				["FrostRoarIsland"] = true,--寒冰岛
				["AncientEgyptIsland"] = true,--沙漠岛
				["DarkForestIsland"] = true,--死亡岛
			}
		end
	else
		if(not self.public_world_map)then
			self.public_world_map = {
				["61HaqiTown_teen"] = true,-- 彩虹岛
				["FlamingPhoenixIsland"] = true,--火鸟岛
				["FrostRoarIsland"] = true,--寒冰岛
				["AncientEgyptIsland"] = true,--沙漠岛
				["DarkForestIsland"] = true,--死亡岛
				["CloudFortressIsland"] = true,--云海秘境
			}
		end
	end
	if(self.public_world_map[worldname])then
		return true;
	end
	return false;
end

-- whether we are in instanced world
function WorldManager:IsInstanceWorld(worldname)
	return not WorldManager:IsPublicWorld(worldname);
end

function WorldManager:GotoNPCAndDialog(npcid)
    if (npcid) then
		npcid = tonumber(npcid);
	    local worldname,position,camera = WorldManager:GetWorldPositionByNPC(npcid);
--		local cur_world = WorldManager:GetCurrentWorld();
		WorldManager:GotoWorldPosition(worldname,position,camera,nil,
			function() 
				System.App.Commands.Call("Profile.Aries.ShowNPCDialog_Menu",{npc_id = npcid});	
			end
		,true);
    end
end

-- @position = {x,y,z} target position
-- @facing: target facing
-- @camera = {x,y,z}
-- @worldname: target world
-- @tragetName: given name for this track
function WorldManager:TrackAndGotoPos(position,facing,camera,worldname,targetName,callbackFunc)
	local function CalcDistance(v0,v1)
		local dx = v0.x - v1.x;
		local dz = v0.z - v1.z;
		return math.sqrt(dx*dx + dz*dz);
	end

	local curLocation = WorldManager:GetWorldAddress()
	if (position and worldname) then
		local target = {
			x = position[1],
			y = position[2],
			z = position[3],
			facing = facing, 
			camPos = camera or { 15, 0.27, 0},
			worldInfo =	WorldManager:GetWorldInfo(worldname),
			radius = 15,
			targetName = targetName};

		local QuestPathfinderNavUI = commonlib.gettable("MyCompany.Aries.Quest.QuestPathfinderNavUI");
		QuestPathfinderNavUI.pathfinder:SetTarget(target);
		local dist = CalcDistance(curLocation, target);

		-- if distance is bigger than 100, do teleport to save player time. 
		if(dist > QuestPathfinderNavUI.max_walk_dist_during_pathfinding) then
			QuestPathfinderNavUI.LeaveAutoNavigationMode();
			QuestPathfinderNavUI.TransportToCurrentTarget();
			if (callbackFunc) then
				callbackFunc();
			end
			return;
		end		

		-- tricky: force waypoint to be calculated at least once before nav timer callback is called. 
		QuestPathfinderNavUI.OnTimer();

		QuestPathfinderNavUI.nav_timer = QuestPathfinderNavUI.nav_timer or commonlib.Timer:new({callbackFunc = function(timer)
			QuestPathfinderNavUI.AutoNavigationFrameMove();
		end})
		QuestPathfinderNavUI.nav_timer:Change(200,200);
		QuestPathfinderNavUI.last_move_count = Map3DSystem.HandleMouse.GetMovementCount();
		QuestPathfinderNavUI.reached_last_waypoint = false;
		if (callbackFunc) then
			callbackFunc();
		end
	end
end
