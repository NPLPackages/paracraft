--[[
Title: teleport helper from world objects
Author(s): WangTian
Date: 2009/8/6
Desc: 
teleport portal and dest is a pair of characters that will handle the world teleport:
	teleport-portal:[ID] character on_framemove ai script will track the player position if in teleport active range, then teleport to the destination
	teleport-dest:[ID] character
Characters are saved with on_load script. Character rendering is dynamicaly loaded that character objects are not actually valid in OnWorldLoad
app message. The character must be at least rendered once according to player position in quad-tree structure.

In-game editing process:
	1. create a teleport pair using TeleportPortal.CreatePortalPair, portal will be created in the position, destination will be create 10000 meters above
	2. player will be teleport immediately to the sky
	3. create a in-door object for teleport and player to stand
	4. walk some meters away, (in case of loop teleport)
	5. create another teleport pair using TeleportPortal.CreatePortalPair, destination will be created 10000 meter below and snap to terrain surface
	6. player will be teleport immediately to the ground
	7. 2 teleport pairs(4 characters) are all editable to change position
		
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/TeleportPortal.lua");
Map3DSystem.App.worlds.TeleportPortal.CreatePortalPair();
------------------------------------------------------------
]]

local TeleportPortal = commonlib.gettable("Map3DSystem.App.worlds.TeleportPortal");
local TimerManager = commonlib.gettable("commonlib.TimerManager")

-- init the world manager at startup
-- @param id: id of the teleport pair
-- @param position: {x, y, z}
-- @param portal_assetfile: portal character asset file
-- @param dest_assetfile: dest character asset file
function TeleportPortal.CreatePortalPair(id, position, portal_assetfile, dest_assetfile)
	id = id or 1;
	local portal = ParaScene.GetCharacter("teleport-portal:"..id);
	local dest = ParaScene.GetCharacter("teleport-dest:"..id);
	if(portal:IsValid() or dest:IsValid()) then
		log("portal pair already created with id:"..id..". change a different id\n");
		--TeleportPortal.CreatePortalPair(id + 1, position, portal_assetfile, dest_assetfile);
		return;
	end
	if(position == nil) then
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		position = {x, y, z};
	end
	if(portal_assetfile == nil) then
		portal_assetfile = "character/common/portal/chuansongmen.x";
	end
	if(dest_assetfile == nil) then
		dest_assetfile = "character/common/headarrow/headarrow.x";
	end
	-- create the portal
	local obj_params = {};
	obj_params.name = "teleport-portal:"..id;
	obj_params.x = position[1];
	obj_params.y = position[2];
	obj_params.z = position[3];
	obj_params.AssetFile = portal_assetfile;
	obj_params.IsCharacter = true;
	-- skip saving to history for recording or undo.
	System.SendMessage_obj({
		type = System.msg.OBJ_CreateObject, 
		obj_params = obj_params, 
		SkipHistory = true,
	});
	portal = ParaScene.GetCharacter("teleport-portal:"..id);
	-- set onload and onframemove scripts
	local att = portal:GetAttributeObject();
	-- att:SetField("OnLoadScript", [[;Map3DSystem.App.worlds.TeleportPortal.On_Load();]]);
	att:SetField("On_FrameMove", [[;Map3DSystem.App.worlds.TeleportPortal.On_Framemove();]]);
	att:SetField("FrameMoveInterval", 450);
	att:SetField("PerceptiveRadius", 0);
	att:SetField("Sentient Radius", 3);
	portal:SetDynamicField("name", "");
	local SentientGroupIDs = commonlib.getfield("MyCompany.Aries.SentientGroupIDs");
	if(SentientGroupIDs) then
		portal:SetSentientField(SentientGroupIDs["Player"], true);
	else
		att:SetField("SentientField", 65535);
	end

	-- create the dest
	local obj_params = {};
	obj_params.name = "teleport-dest:"..id;
	obj_params.x = position[1];
	obj_params.y = position[2] + 10000;
	obj_params.z = position[3];
	obj_params.AssetFile = dest_assetfile;
	obj_params.IsCharacter = true;
	-- skip saving to history for recording or undo.
	System.SendMessage_obj({
		type = System.msg.OBJ_CreateObject, 
		obj_params = obj_params, 
		SkipHistory = true,
	});
	dest = ParaScene.GetCharacter("teleport-dest:"..id);
	if(position[2] > 9000) then
		dest:SnapToTerrainSurface(0);
	end
end

function TeleportPortal.DeletePortalPair(id)
	local portal = ParaScene.GetCharacter("teleport-portal:"..id);
	local dest = ParaScene.GetCharacter("teleport-dest:"..id);
	if(portal:IsValid()) then
		ParaScene.Delete(portal);
	end
	if(dest:IsValid()) then
		ParaScene.Delete(dest);
	end
end

function TeleportPortal.On_Load()
	local portal = ParaScene.GetObject(sensor_name);
	if(portal:IsValid() == true) then
		local att = portal:GetAttributeObject();
		local SentientGroupIDs = commonlib.getfield("MyCompany.Aries.SentientGroupIDs");
		if(SentientGroupIDs) then
			portal:SetSentientField(SentientGroupIDs["Player"], true);
		else
			att:SetField("SentientField", 65535);
		end
		att:SetField("OnLoadScript", [[;Map3DSystem.App.worlds.TeleportPortal.On_Load();]]);
		att:SetField("On_FrameMove", [[;Map3DSystem.App.worlds.TeleportPortal.On_Framemove();]]);
		att:SetField("FrameMoveInterval", 450);
		att:SetField("PerceptiveRadius", 0);
		att:SetField("Sentient Radius", 3);
		portal:SetDynamicField("name", "");
	end
end

local memorys = {};

-- every 0.45 seconds
function TeleportPortal.On_Framemove()
	local memory = memorys[sensor_name];
	if(not memory) then
		memory = {};
		memorys[sensor_name] = memory;
	end
	
	local portal = ParaScene.GetObject(sensor_name);
	
	if(portal:IsValid() == true) then
		if(TeleportPortal.DestHelpersHidden == true) then
			local destname = string.gsub(sensor_name, "portal", "dest");
			if(destname) then
				local dest = ParaScene.GetObject(destname);
				if(dest:IsValid() == true) then
					dest:SetVisible(false);
				end
			end
			--portal:SetVisible(false);
		end
		local destname = string.gsub(portal.name, "portal", "dest");
		local dest = ParaScene.GetObject(destname);
		local player = ParaScene.GetPlayer();
		if(string.find(player.name, "teleport-")) then
			return;
		end
		if(player and player:IsValid() == true and dest and dest:IsValid() == true) then
			local dist = portal:DistanceTo(player);
			if(dist < 5) then
				-- call hook for Aries OnTeleportPortal
				if(System.SystemInfo.GetField("name") == "Aries") then
					local curTime = ParaGlobal.timeGetTime();
					if(not memory.due_time or curTime > memory.due_time) then
						local msg = { aries_type = "OnTeleportPortal", dest = {dest:GetPosition()}, portal = portal, wndName = "map"};
						CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
						-- only to allow call again after 3 seconds. 
						memory.due_time = curTime + 3000;
					end
				else
					player:SetPosition(dest:GetPosition());
					player:ToCharacter():Stop();
				end
			end
		end
	end
end

function TeleportPortal.ShowAllTeleportDestHelpers()
	TeleportPortal.DestHelpersHidden = nil;
	local player = ParaScene.GetObject("<player>");
	local playerCur = player;
	while(playerCur:IsValid() == true) do
		-- get next object
		playerCur = ParaScene.GetNextObject(playerCur);
		if(playerCur:IsValid() and playerCur:IsCharacter()) then
			--if(string.find(playerCur.name, "teleport%-portal:") or string.find(playerCur.name, "teleport%-dest:")) then
			if(string.find(playerCur.name, "teleport%-dest:")) then
				playerCur:SetVisible(true);
			end
		end
		-- if cycled to the player character
		if(playerCur:equals(player) == true) then
			break;
		end
	end
end

function TeleportPortal.HideAllTeleportDestHelpers()
	TeleportPortal.DestHelpersHidden = true;
	local player = ParaScene.GetObject("<player>");
	local playerCur = player;
	while(playerCur:IsValid() == true) do
		-- get next object
		playerCur = ParaScene.GetNextObject(playerCur);
		if(playerCur:IsValid() and playerCur:IsCharacter()) then
			--if(string.find(playerCur.name, "teleport%-portal:") or string.find(playerCur.name, "teleport%-dest:")) then
			if(string.find(playerCur.name, "teleport%-dest:")) then
				playerCur:SetVisible(false);
			end
		end
		-- if cycled to the player character
		if(playerCur:equals(player) == true) then
			break;
		end
	end
end