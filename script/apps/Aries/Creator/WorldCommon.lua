--[[
Title: common functions for world
Author(s): LiXizhi
Date: 2010/2/5
Desc: common world functions such as loading/saving tag/world. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
WorldCommon.OpenWorld(worldpath);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandler.lua");
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
		
-- create class
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Pet = commonlib.gettable("MyCompany.Aries.Pet");
local Player = commonlib.gettable("MyCompany.Aries.Player");

-- current world tag. 
WorldCommon.world_info = nil;

-- get whether the game world is modified or not
function WorldCommon.IsModified()
	return WorldCommon.is_modified;
end

-- set whether the game world is modified or not
function WorldCommon.SetModified(bModified)
	WorldCommon.is_modified = bModified;
end

-- load world info from tag.xml under the world_path
-- @param world_path: if nil, ParaWorld.GetWorldDirectory() is used. 
-- @return nil or a table of {name, writedate, desc}
function WorldCommon.LoadWorldTag(world_path)
	NPL.load("(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandler.lua");
	local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
	WorldCommon.save_world_handler = SaveWorldHandler:new():Init(world_path);
	WorldCommon.world_info = WorldCommon.save_world_handler:LoadWorldInfo();
	return WorldCommon.world_info;
end

function WorldCommon.GetSaveWorldHandler()
	return WorldCommon.save_world_handler;
end

function WorldCommon.SetTexturePackageInfo(package)
	local info = WorldCommon.GetWorldInfo();
	info.texture_pack_type = package.type;
	info.texture_pack_path = commonlib.Encoding.DefaultToUtf8(package.packagepath);
	info.texture_pack_url  = package.url;
	info.texture_pack_text = package.text;
end

-- load world info from tag.xml under the world_path
-- @return true if succeeded. 
function WorldCommon.SaveWorldTag()
	return WorldCommon.save_world_handler:SaveWorldInfo(WorldCommon.world_info);
end

WorldCommon.initial_player_pos = {x=19959, y=0, z=20273}

-- Open a given local personal world
function WorldCommon.OpenWorld(worldpath, isNewVersion, force_nid)
	NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
	local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");

	if(isNewVersion == nil) then
		if(System.options.version == "teen") then
			isNewVersion = true;
		else
			isNewVersion = EnterGamePage.HaveRight("entergame")
		end
	end
	
	-- this is for offline mode just in case it happens.
	Map3DSystem.User.nid = Map3DSystem.User.nid or 0;

	if(isNewVersion) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
		local Game = commonlib.gettable("MyCompany.Aries.Game")
		Game.Start(worldpath, nil, force_nid);
	else
		-- load scene
		local commandName = System.App.Commands.GetDefaultCommand("LoadWorld");
	
		local world_tag = WorldCommon.LoadWorldTag(worldpath);
		local world_size = 1000; -- default world size if no tag is available. 
		if(world_tag) then
			world_size = tonumber(world_tag.size);
		end
	
		Player.EnterEnvEditMode(true);
	
		System.App.Commands.Call(commandName, {worldpath = worldpath, tag="MyLocalWorld", 
			world_size = world_size,
			PosX = WorldCommon.initial_player_pos.x, PosZ = WorldCommon.initial_player_pos.z,
		});
		WorldCommon.worldpath = ParaWorld.GetWorldDirectory();

		CommandManager:Init();
		--local pos = Map3DSystem.App.HomeLand.HomeLandConfig.DefaultBornPlace;
		--local x,y,z = pos.x,pos.y,pos.z;
		--Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_TELEPORT_PLAYER, x= tonumber(x) or 20000, z=tonumber(z) or 20000});
	end
end

function WorldCommon.SetPlayerMovableRegion(world_radius)
	if(world_radius) then
		commonlib.log("player MovableRegion is changed to radius: %d\n", world_radius)
		ParaScene.GetPlayer():SetMovableRegion(WorldCommon.initial_player_pos.x, 0, WorldCommon.initial_player_pos.z, world_radius,world_radius,world_radius);
	end	
end

-- auto save the current world. It will save regardless of whether the world is modified or not.
function WorldCommon.SaveWorld()
	NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
	local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")
	LocalNPC:SaveToFile();
	WorldCommon.SaveWorldTag();
	
	if(System.options.mc) then
		-- this ensures that folder modification time is changed
		commonlib.Files.TouchFolder(GameLogic.GetWorldDirectory());
	else
		-- since sqlite will delete journal file anyway, the folder modification time is changed anyway. 
		-- so no need to touch directory explicitly here
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.SCENE_SAVE})
	end
end


-- get the current tag field value in the current world. see "[worldpath]/tag.xml" for the tag name, value pairs. 
-- @param field_name: suppported tag names are "name", "nid", "desc", "size"
function WorldCommon.GetWorldTag(field_name)
	if(WorldCommon.world_info) then
		if(field_name == "size") then
			return tonumber(WorldCommon.GetWorldInfo().size);
		else
			return WorldCommon.world_info[field_name or "name"]
		end	
	end
end

function WorldCommon.GetWorldInfo()
	return WorldCommon.world_info;
end


-- leave the world. this function is called automatically by the HomeLandGateway whenever user leaves the world for the public world. 
-- it is safe to call this function many times. 
-- @param callbackFunc: nil or a call back function(result)  end, where result is same as MessageBox result. 
-- @return true, if a message box is displayed otherwise false. 
function WorldCommon.LeaveWorld(callbackFunc)
	if(WorldCommon.IsModified() and WorldCommon.worldpath == ParaWorld.GetWorldDirectory()) then
		-- pop up a message box to ask whether to save the game world. 	
		_guihelper.MessageBox(string.format([[<div style="margin-top:28px">你即将离开领地[%s]<br/>是否在离开前保存领地?</div>]], WorldCommon.GetWorldTag("name")), function(result)
			if(_guihelper.DialogResult.Yes == result) then
				WorldCommon.SetModified(false);
				WorldCommon.SaveWorld();
			elseif(_guihelper.DialogResult.No == result) then
				WorldCommon.SetModified(false);
			else
			end
			
			Player.EnterEnvEditMode(false);
			if(type(callbackFunc) == "function") then
				callbackFunc(result);
			end
			
		end, _guihelper.MessageBoxButtons.YesNoCancel)
		
		return true;
	end
	
	Player.EnterEnvEditMode(false);
	if(type(callbackFunc) == "function") then
		callbackFunc(_guihelper.DialogResult.No);
	end
end
