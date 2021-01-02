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
	local is_modified = WorldCommon.is_modified;
	if(not is_modified) then
		return WorldCommon.CheckIfBlockWorldIsModified();
	end
	return is_modified;
end

-- return true if block world is modified since last load or save 
function WorldCommon.CheckIfBlockWorldIsModified()
	local blockWorld = GameLogic.GetBlockWorld()
	local worldAtt = ParaBlockWorld.GetBlockAttributeObject(blockWorld);
	local count = worldAtt:GetChildCount();

	local is_modified = false;
	for i = 0, count - 1 do
		local regionAtt = worldAtt:GetChildAt(i);
		is_modified = is_modified or regionAtt:GetField("IsModified", false);
		if(is_modified) then
			break
		end
	end
	return is_modified;
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
		LOG.std(nil, "info", "WorldCommon.OpenWorld", worldpath);
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

function WorldCommon.SavePreviewImageIfNot()
	local filepath = ParaWorld.GetWorldDirectory().."preview.jpg";

	if(not ParaIO.DoesFileExist(filepath, true)) then
		NPL.load("(gl)script/ide/System/Util/ScreenShot.lua");
		local ScreenShot = commonlib.gettable("System.Util.ScreenShot");
		if(ScreenShot.TakeSnapshot(filepath,300,200, false)) then
			LOG.std(nil, "info", "WorldCommon", "screen shot saved to %s", filepath);
			return true;
		end
	end
end

-- auto save the current world. It will save regardless of whether the world is modified or not.
function WorldCommon.SaveWorld()
	local worldname = GameLogic.GetWorldDirectory():match("([^/\\]+)$")
	GameLogic.GetFilters():apply_filters("user_event_stat", "world", "save:"..tostring(worldname), nil, nil);

	NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
	local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")
	LocalNPC:SaveToFile();
	WorldCommon.SavePreviewImageIfNot();
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
-- @param field_name: suppported tag names are "name", "nid", "desc", "size", "isVipWorld"
function WorldCommon.GetWorldTag(field_name)
	if(WorldCommon.world_info) then
		if(field_name == "size") then
			return tonumber(WorldCommon.GetWorldInfo().size);
		else
			return WorldCommon.world_info[field_name or "name"]
		end	
	end
end

function WorldCommon.SetWorldTag(field_name, value)
	if(WorldCommon.world_info) then
		if(field_name ~= "size") then
			WorldCommon.world_info[field_name or "name"] = value;
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

-- save the current world (could be a zip file) to another folder
function WorldCommon.SaveWorldAs()
	local status = GameLogic.GetFilters():apply_filters("save_world_as", false, worlds_template);

	if (status) then
		return
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
	local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
			
	local lastWorldName = WorldCommon.GetWorldTag("name") or "no_name"

	if(GameLogic.IsRemoteWorld()) then
		-- always save before save as if world is a remote client world.
		GameLogic.RunCommand("/touchworld");
		GameLogic.SaveAll(true, true);
	end

	local defaultWorldName = lastWorldName;
	for i=1, 10 do
		local targetFolder = LocalLoadWorld.GetDefaultSaveWorldPath() .. "/".. commonlib.Encoding.Utf8ToDefault(defaultWorldName) .. "/";
		if(ParaIO.DoesFileExist(targetFolder.."tag.xml", false)) then
			defaultWorldName = lastWorldName..L"_副本"..tostring(i);
		else
			break;
		end	
	end
	
	if(GameLogic.options:HasCopyright()) then
		_guihelper.MessageBox(L"这个世界的作者申请了版权保护，无法复制世界。")
		return
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
	local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
	OpenFileDialog.ShowPage(L"输入新的世界名字".."<br/>"..L"如果你复制的是别人的世界, 请在世界中著名原作者, 并取得对方同意", function(result)
		if(result and result~="") then
			local function callback()
				local targetFolder = LocalLoadWorld.GetDefaultSaveWorldPath() .. "/".. result.. "/";
				if (ParaIO.DoesFileExist(targetFolder.."tag.xml", false)) then
					_guihelper.MessageBox(format(L"世界%s已经存在, 是否覆盖?",commonlib.Encoding.DefaultToUtf8(result)), function(res)
						if(res and res == _guihelper.DialogResult.Yes) then
							WorldCommon.SaveWorldAsImp(targetFolder);
						end
					end, _guihelper.MessageBoxButtons.YesNo);
				else
					WorldCommon.SaveWorldAsImp(targetFolder);
				end

				local worldname = GameLogic.GetWorldDirectory():match("([^/\\]+)$")
				GameLogic.GetFilters():apply_filters("user_event_stat", "world", "saveas:"..tostring(worldname), nil, nil);
			end

			callback()
		end
	end, commonlib.Encoding.Utf8ToDefault(defaultWorldName), L"世界另存为", "localworlds", true)
end

function WorldCommon.SaveWorldAsImp(folderName, callbackFunc)
	local function Handle()
		if(WorldCommon.CopyWorldTo(folderName)) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandler.lua");
			local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
			local save_world_handler = SaveWorldHandler:new():Init(folderName);
			local xmlRoot = save_world_handler:LoadWorldXmlNode();
			if(xmlRoot) then
				for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
					-- change world name in tag. 
					local worldname = folderName:match("([^/]+)/?$")
					local name = commonlib.Encoding.DefaultToUtf8(worldname);
					node.attr.name = name;
					-- change Tag.xml to merge the original authors
					if(node.attr.kpProjectId) then
						node.attr.fromProjects =  node.attr.fromProjects and (node.attr.fromProjects..","..node.attr.kpProjectId)  or node.attr.kpProjectId;
						node.attr.kpProjectId = nil;
					end
					save_world_handler:SaveWorldXmlNode(xmlRoot);
					break;
				end
			end
	
			if (callbackFunc and type(callbackFunc) == "function") then
				callbackFunc(true);
			else
				_guihelper.MessageBox(format(L"世界已经成功保存到: %s, 是否现在打开?", commonlib.Encoding.DefaultToUtf8(folderName)), function(res)
					if(res and res == _guihelper.DialogResult.Yes) then
						WorldCommon.OpenWorld(folderName, true)
					end
				end, _guihelper.MessageBoxButtons.YesNo);
			end
		end
	end

	if(not GameLogic.IsVip("WorldDataSaveAs", true, function(result)
			if (result) then
				Handle()
			end
		end)) then
		return
	end

	Handle();
end

-- @return true if succeed
function WorldCommon.CopyWorldTo(destinationFolder)
	ParaIO.CreateDirectory(destinationFolder);

	local worldzipfile = System.World.worldzipfile;
	if(worldzipfile) then
		local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(worldzipfile);
		zipParentDir = zip_archive:GetField("RootDirectory", "");

		-- search just in a given zip archive file
		local filesOut = {};
		-- ":.", any regular expression after : is supported. `.` match to all strings. 
		commonlib.Files.Find(filesOut, "", 0, 10000, ":.", worldzipfile);

		local fileCount = 0;
		-- print all files in zip file
		for i = 1,#filesOut do
			local item = filesOut[i];
			local filename = item.filename
			filename = filename:gsub("^[^/]+/?", "");
			if(item.filesize > 0) then
				local source_path = zipParentDir..item.filename;
				
				-- tricky: we do not know which encoding the filename in the zip archive is,
				-- so we will assume it is utf8, we will convert it to default and then back to utf8.
				-- if the file does not change, it might be utf8. 
				local dest_path;
				local defaultEncodingFilename = commonlib.Encoding.Utf8ToDefault(filename)
				if(defaultEncodingFilename == filename) then
					dest_path = destinationFolder..filename;
				else
					if(commonlib.Encoding.DefaultToUtf8(defaultEncodingFilename) == filename) then
						dest_path = destinationFolder..defaultEncodingFilename;
					else
						dest_path = destinationFolder..filename;
					end
				end

				local re = ParaIO.CopyFile(source_path, dest_path, true);
				LOG.std(nil, "info", "CopyWorldFile", "copy(%s) %s -> %s",tostring(re),source_path,dest_path);
			else
				-- this is a folder
				ParaIO.CreateDirectory(destinationFolder..filename.."/");
			end
		end
		LOG.std(nil, "info", "CopyWorldTo", "%s is unziped to %s ( %d files)", worldzipfile, destinationFolder, fileCount); 
		return true;
	else
		-- search just in disk file
		local filesOut = {};
		local parentDir = GameLogic.GetWorldDirectory();
		commonlib.Files.Find(filesOut, parentDir, 10, 10000, "*");

		local fileCount = 0;
		-- print all files in zip file
		for i = 1,#filesOut do
			local item = filesOut[i];
			local filename = item.filename
			if(item.filesize > 0) then
				local source_path = parentDir..filename;
				local dest_path = destinationFolder..filename;
				local re = ParaIO.CopyFile(source_path, dest_path, true);
				LOG.std(nil, "info", "CopyWorldFile", "copy(%s) %s -> %s",tostring(re),source_path,dest_path);
			else
				-- this is a folder
				ParaIO.CreateDirectory(destinationFolder..filename.."/");
			end
		end
		LOG.std(nil, "info", "CopyWorldTo", "%s is copied to %s ( %d files)", parentDir, destinationFolder, fileCount); 
		return true;
	end
end

function WorldCommon.ReplaceWorld(targetProjectId)
	WorldCommon.sourceWorldName = WorldCommon.GetWorldTag("name");
	WorldCommon.destWorldId = targetProjectId;
	GameLogic:Connect("WorldLoaded", WorldCommon, WorldCommon.OnWorldLoaded, "UniqueConnection");
	CommandManager:RunCommand(format('/loadworld -s -force %d', targetProjectId))
end

function WorldCommon.ReplaceWorldImp()
	if(GameLogic.options:HasCopyright()) then
		_guihelper.MessageBox(L"这个世界的作者申请了版权保护，无法复制世界。")
		return false;
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
	local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
	local targetFolder = LocalLoadWorld.GetDefaultSaveWorldPath() .. "/".. commonlib.Encoding.Utf8ToDefault(WorldCommon.sourceWorldName).. "/";
	WorldCommon.SaveWorldAsImp(targetFolder, function(result)
		if (result) then
			_guihelper.MessageBox(string.format(L"替换成功，即将进入【%s】。", WorldCommon.sourceWorldName));
		end
		WorldCommon.sourceWorldName = nil
		commonlib.TimerManager.SetTimeout(function()
			WorldCommon.OpenWorld(targetFolder, true);
		end, 2000);
	end);
end

function WorldCommon.OnWorldLoaded()
	GameLogic:Disconnect("WorldLoaded", WorldCommon, WorldCommon.OnWorldLoaded, "UniqueConnection");
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tostring(projectId) == tostring(WorldCommon.destWorldId)) then
		commonlib.TimerManager.SetTimeout(function()
			_guihelper.MessageBox(L"正在使用当前世界替换原有的并行世界...");
		end, 3000);
		commonlib.TimerManager.SetTimeout(function()
			WorldCommon.ReplaceWorldImp()
		end, 4000);
	end
end
