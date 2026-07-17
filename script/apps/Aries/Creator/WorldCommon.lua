--[[
Title: common functions for world
Author(s): LiXizhi, big
CreateDate: 2010.02.05
ModifyDate: 2021.08.26
Desc: common world functions such as loading/saving tag/world. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
WorldCommon.OpenWorld(worldpath);
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/FastRandom.lua");
local FastRandom = commonlib.gettable("MyCompany.Aries.Game.Common.CustomGenerator.FastRandom");
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

-- create class
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Pet = commonlib.gettable("MyCompany.Aries.Pet");
local Player = commonlib.gettable("MyCompany.Aries.Player");

-- current world tag. 
WorldCommon.world_info = nil;

-- get whether the game world is modified or not
function WorldCommon.IsModified()
	return GameLogic.world_revision and GameLogic.world_revision:IsModified();
end

-- set world modified
function WorldCommon.SetModified()
	if(GameLogic.world_revision) then
		GameLogic.world_revision:SetModified()
	end
end

-- load world info from tag.xml under the world_path
-- @param world_path: if nil, ParaWorld.GetWorldDirectory() is used. 
-- @return nil or a table of {name, writedate, desc}
function WorldCommon.LoadWorldTag(world_path)
	WorldCommon.save_world_handler = SaveWorldHandler:new():Init(world_path);
	WorldCommon.world_info = WorldCommon.save_world_handler:LoadWorldInfo();
	WorldCommon.world_path = world_path or ParaWorld.GetWorldDirectory();

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


function WorldCommon.GeneratePrivateKey()
    local entityPlayer = EntityManager.GetFocus();
    local x, y, z;
    if entityPlayer then
        x, y, z = entityPlayer:GetBlockPos();
    else
        x, y, z = 0, 0, 0;
    end
    local random1 = math.random() * 100;
    local random2 = FastRandom.randomNoise(x, y, z, math.random());

    return commonlib.Encoding.base64(tostring(random1 + random2));
end

-- load world info from tag.xml under the world_path
-- @return true if succeeded. 
function WorldCommon.SaveWorldTag()
	if (WorldCommon.world_info and type(WorldCommon.world_info) == 'table') then
		if (WorldCommon.world_info.instituteVipSaveAsOnly == true or WorldCommon.world_info.instituteVipSaveAsOnly == "true"
			or WorldCommon.world_info.instituteVipChangeOnly == true or WorldCommon.world_info.instituteVipChangeOnly == "true") then
			if (not WorldCommon.world_info.privateKey or
				WorldCommon.world_info.privateKey == "") then
				WorldCommon.world_info.privateKey = WorldCommon.GeneratePrivateKey();
			end
		else
			WorldCommon.world_info.privateKey = nil;
		end
	end

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
		CommandManager:RunCommand("/history -init")
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
	WorldCommon.SetWorldTag("lastdaytime", GameLogic.RunCommand("/time now"))
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

			GameLogic.GetFilters():apply_filters('OnWorldTageChange', field_name)
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
				WorldCommon.SaveWorld();
			elseif(_guihelper.DialogResult.No == result) then
			else
			end
			
			Player.EnterEnvEditMode(false);
			if(type(callbackFunc) == "function") then
				callbackFunc(result);
			end
			WorldCommon.CloseWorldAssetUrl()
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
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
	local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")

	local lastWorldName = WorldCommon.GetWorldTag("name") or "no_name"

	if(GameLogic.IsRemoteWorld()) then
		-- always save before save as if world is a remote client world.
		GameLogic.RunCommand("/touchworld");
		GameLogic.SaveAll(true, true);
	end

	local baseFolder = GameLogic.GetFilters():apply_filters('service.local_service_world.get_user_folder_path') or
			LocalLoadWorld.GetDefaultSaveWorldPath();
	local defaultWorldName = lastWorldName;

	for i=1, 10 do
		local targetFolder = baseFolder .. "/".. commonlib.Encoding.Utf8ToDefault(defaultWorldName) .. "/";
		if(ParaIO.DoesFileExist(targetFolder.."tag.xml", false)) then
			defaultWorldName = lastWorldName..L"_副本"..tostring(i);
		else
			break;
		end	
	end
	local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld');
	local currentEnterWorldUserId = currentEnterWorld and currentEnterWorld.user and currentEnterWorld.user.id or 0;
	local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId');
	
	local isMyWorld = userId and userId > 0 and currentEnterWorldUserId and currentEnterWorldUserId == userId;
	if(GameLogic.options:HasCopyright()) and not isMyWorld then
		_guihelper.MessageBox(L"这个世界的作者申请了版权保护，无法复制世界。")
		return;
	end

	-- ban not institute student save as
	local instituteVipSaveAsOnly = WorldCommon.GetWorldTag('instituteVipSaveAsOnly');
	instituteVipSaveAsOnly = instituteVipSaveAsOnly == "true" or instituteVipSaveAsOnly == true
	local userType = Mod.WorldShare.Store:Get('user/userType') or {};
    local isStudent = userType.student;
    local isTeacher = userType.teacher;

	if instituteVipSaveAsOnly and not isMyWorld and not isStudent and not isTeacher then
		_guihelper.MessageBox(L"这个世界只有机构用户和老师才能另存为。");
		return;
	end

	local function IsValidDirectory(dir)
		if not dir or dir == "" then
			return false
		end
		  local invalidCharsPattern = "[<>:\"/\\|?*]" 
		  -- local invalidCharsPattern = "[/:*?\"<>|]"  -- Unix/Linux系统非法字符
		  if string.find(dir, invalidCharsPattern) then
			return false
		  end
		  return true
	end

	local function Handle()
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
		OpenFileDialog.ShowPage(L"输入新的世界名字".."<br/>"..L"如果你复制的是别人的世界, 请在世界中著名原作者, 并取得对方同意", function(result)
			if(result and result~="") then
				if not IsValidDirectory(result) then
					_guihelper.MessageBox(L"当前输入的世界名包含非法字符，请重新输入。",function()
						WorldCommon.SaveWorldAs()
					end)
					return
				end
				local function callback()
					local targetFolder = baseFolder .. "/".. result.. "/";
					local function StartSaveAs()
						if(GameLogic.world_revision:IsModified()) then
							_guihelper.MessageBox(format(L"世界《%s》刚刚被修改过。是否保留修改后的内容?",commonlib.Encoding.DefaultToUtf8(result)), function(res)
								if(res and res == _guihelper.DialogResult.Yes) then
									WorldCommon.SaveWorldAsImp(targetFolder, nil, true);
								else
									WorldCommon.SaveWorldAsImp(targetFolder);
								end
							end, _guihelper.MessageBoxButtons.YesNo);
						else
							WorldCommon.SaveWorldAsImp(targetFolder);
						end
					end

					local function SaveAsWorldCheckModified_(targetFolder)
						local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
						KeepworkServiceWorld:CheckWorldExists(result, function(bExists)
							if bExists then
								_guihelper.MessageBox(format(L"服务器中已经存在世界《%s》, 是否覆盖?",commonlib.Encoding.DefaultToUtf8(result)), function(res)
									if(res and res == _guihelper.DialogResult.Yes) then
										StartSaveAs()
									end
								end, _guihelper.MessageBoxButtons.YesNo);
								return
							end
							StartSaveAs()
						end)
					end
					if (ParaIO.DoesFileExist(targetFolder.."tag.xml", false)) then
						_guihelper.MessageBox(format(L"世界《%s》已经存在, 是否覆盖?",commonlib.Encoding.DefaultToUtf8(result)), function(res)
							if(res and res == _guihelper.DialogResult.Yes) then
								SaveAsWorldCheckModified_(targetFolder)
							end
						end, _guihelper.MessageBoxButtons.YesNo);
					else
						SaveAsWorldCheckModified_(targetFolder)
					end

					local worldname = GameLogic.GetWorldDirectory():match("([^/\\]+)$")
					GameLogic.GetFilters():apply_filters("user_event_stat", "world", "saveas:"..tostring(worldname), nil, nil);
				end
			
				if GameLogic.GetFilters():apply_filters("WorldCommon.SaveWorldAs", false, callback) then
					return false
				end

				callback()
			end
		end, commonlib.Encoding.Utf8ToDefault(defaultWorldName), L"世界另存为", "localworlds", true)
	end

	local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
	KeepworkServiceWorld:LimitFreeUser(false, function(result)
		if result then
			Handle()
		else
			GameLogic.ShowVipGuideTip("UnlimitWorldsNumber")
		end
	end)
end

function WorldCommon.SaveWorldAsImp(folderName, callbackFunc, bPreserveModified, bForceSave)
	local function Handle()
		if(WorldCommon.CopyWorldTo(folderName, bPreserveModified)) then
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
					local setAttrValueDefault = function (attrs)
						for key, value in pairs(attrs) do
							if node.attr[value] ~=nil then
								node.attr[value] = nil
							end
						end
					end
					setAttrValueDefault({"communityWorld","instituteVipChangeOnly","instituteVipEnabled","instituteVipSaveAsOnly","isVipWorld",
					"totalEditSeconds","totalClicks","totalKeyStrokes","totalSingleBlocks","totalWorkScore","editCodeLine","world_edit_code"})

					save_world_handler:SaveWorldXmlNode(xmlRoot);
					break;
				end
			end

			local deleteList = {
				"user_action_path.xml","block_hotVal_map.xml","user_code_data.xml","user_bones_data.xml","codeblock.txt",
				"stats/user_action_path.xml","stats/block_hotVal_map.xml","stats/user_code_data.xml","stats/user_bones_data.xml","stats/codeblock.txt",
			}
			for k,v in ipairs(deleteList) do
				local path = folderName.."/"..v 
				if ParaIO.DoesFileExist(path) then
					ParaIO.DeleteFile(path)
				end
			end

			if bForceSave then
				if (callbackFunc and type(callbackFunc) == "function") then
					callbackFunc(true);
				end
				return
			end
	
			if (callbackFunc and type(callbackFunc) == "function") then
				callbackFunc(true);
			else
				_guihelper.MessageBox(format(L"世界已经成功保存到: %s, 是否现在打开?", commonlib.Encoding.DefaultToUtf8(folderName)), function(res)
					if(res and res == _guihelper.DialogResult.Yes) then
						GameLogic.GetFilters():apply_filters("SaveWorldAsFinished",folderName)
						WorldCommon.OpenWorld(folderName, true)
					end
				end, _guihelper.MessageBoxButtons.YesNo);
			end
		end
	end

	if bForceSave then
		Handle()
		return
	end

	WorldCommon.CheckWorldAuth(function(result)
		if result then
			Handle()
		else
			_guihelper.MessageBox(L"你没有权限另存这个世界为自己的世界。")
		end
	end)
end

function WorldCommon.CheckWorldAuth(callbackFunc)
	if not GameLogic.IsReadOnly() then
		if (callbackFunc and type(callbackFunc) == "function") then
			callbackFunc(true);
		end
		return;
	end

	local is_signed_in = GameLogic.GetFilters():apply_filters('is_signed_in')
	if not is_signed_in then
		GameLogic.GetFilters():apply_filters('check_signed_in', '请先登录', function(result)
			if result == true then
				commonlib.TimerManager.SetTimeout(function()
					WorldCommon.CheckWorldAuth(callbackFunc)
				end, 200)
			end
		end)
		return;
	end

	local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
	local userId = Mod.WorldShare.Store:Get('user/userId')
	local isWorldAuthor = currentEnterWorld and currentEnterWorld.user and userId and currentEnterWorld.user.id == userId
	if isWorldAuthor then
		if (callbackFunc and type(callbackFunc) == "function") then
			callbackFunc(true);
		end
		return;
	end

	GameLogic.IsVip("WorldDataSaveAs", true, function(result)
		if (result) then
			if (callbackFunc and type(callbackFunc) == "function") then
				callbackFunc(true);
			end
		else
			if System.options.isHideVip then
				GameLogic.ShowVipGuideTip("WorldDataSaveAs")
			end
		end
	end)
end

-- @param bPreserveModified: true to preserve modified changes. 
-- @return true if succeed
function WorldCommon.CopyWorldTo(destinationFolder, bPreserveModified)
	ParaIO.CreateDirectory(destinationFolder);

	local bResult;
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

				-- ParaIO.CreateDirectory(dest_path);
				local re = ParaIO.CopyFile(source_path, dest_path, true);
				LOG.std(nil, "info", "CopyWorldFile", "copy(%s) %s -> %s",tostring(re),source_path,dest_path);
				fileCount = fileCount + 1

				if(dest_path:match("/script/")) then
					LOG.std(nil, "info", "CopyWorldFile", dest_path);
				end
			else
				-- this is a folder
				ParaIO.CreateDirectory(destinationFolder..filename.."/");
			end
		end
		LOG.std(nil, "info", "CopyWorldTo", "%s is unziped to %s ( %d files)", worldzipfile, destinationFolder, fileCount); 
		bResult = true;
	end
	if(not worldzipfile or bPreserveModified) then
		-- search just in disk file
		local filesOut = {};
		local parentDir = GameLogic.GetWorldDirectory();
		commonlib.Files.Find(filesOut, parentDir, 10, 10000, "*");

		local fileCount = 0;
		-- copy all files on disk
		for i = 1,#filesOut do
			local item = filesOut[i];
			local filename = item.filename
			if(item.filesize > 0) then
				local source_path = parentDir..filename;
				local dest_path = destinationFolder..filename;
				local re = ParaIO.CopyFile(source_path, dest_path, true);
				LOG.std(nil, "info", "CopyWorldFile", "copy(%s) %s -> %s",tostring(re),source_path,dest_path);
				fileCount = fileCount + 1
			else
				-- this is a folder
				ParaIO.CreateDirectory(destinationFolder..filename.."/");
			end
		end
		LOG.std(nil, "info", "CopyWorldTo", "%s is copied to %s ( %d files)", parentDir, destinationFolder, fileCount); 
		bResult = true;
	end
	if(bResult) then
		if(bPreserveModified and GameLogic.world_revision:IsModified()) then
			GameLogic.world_revision:StageChangesToFolder(destinationFolder, true);
		end
	end
	return bResult;
end

function WorldCommon.ReplaceWorld(targetProjectId)
	local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld');
	WorldCommon.sourceWorldFolderName = currentEnterWorld and currentEnterWorld.foldername or WorldCommon.GetWorldTag("name");
	WorldCommon.sourceWorldFolderName = commonlib.Encoding.Utf8ToDefault(WorldCommon.sourceWorldFolderName)
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

	GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在使用当前世界替换原有的并行世界...', nil, nil, 450)

	local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
	local username = LocalServiceWorld:GetLocalUsername()
	local targetFolder = LocalServiceWorld:GetDefaultSaveWorldPath() .. "/".. WorldCommon.sourceWorldFolderName.. "/"
	if username and username ~= "" then
		targetFolder = LocalServiceWorld:GetUserFolderPath() .. "/".. WorldCommon.sourceWorldFolderName.. "/"
	end
	if (ParaIO.DoesFileExist(targetFolder)) then
		ParaIO.DeleteFile(targetFolder);
	end

	WorldCommon.SaveWorldAsImp(targetFolder, function(result)
		local sourceWorldName = WorldCommon.sourceWorldName
		WorldCommon.sourceWorldName = nil

		GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close')
		WorldCommon.OpenWorld(targetFolder, true);
	end);
end

function WorldCommon.OnWorldLoaded()
	GameLogic:Disconnect("WorldLoaded", WorldCommon, WorldCommon.OnWorldLoaded, "UniqueConnection");
	local projectId = GameLogic.options:GetProjectId();
	if (projectId and tostring(projectId) == tostring(WorldCommon.destWorldId)) then
		commonlib.TimerManager.SetTimeout(function()
			GameLogic.GetFilters():apply_filters('cellar.common.msg_box.show', L'正在使用当前世界替换原有的并行世界...', nil, nil, 450)

			commonlib.TimerManager.SetTimeout(function()
				GameLogic.GetFilters():apply_filters('cellar.common.msg_box.close')
				WorldCommon.ReplaceWorldImp()
			end, 4000);
		end, 1000);
	end
end

-- return the private key or nil if not exist
function WorldCommon.GetPrivateKey()
	local privateKey = WorldCommon.GetWorldTag("privateKey");
	if(type(privateKey) == "string" and (#privateKey) > 10) then
		return privateKey
	end
end

-- Set up a mother world. Users can then explore and create new worlds, but after all worlds exit, need to return to the parent world
function WorldCommon.SetParentProjectId(parentProjectId)
	WorldCommon.parentProjectId = parentProjectId
end

function WorldCommon.GetParentProjectId()
	return WorldCommon.parentProjectId
end

function WorldCommon.PrepareDiskZipFile(localFile)
	WorldCommon.assetUrllocalFile = localFile;
	local worldpath =  WorldCommon.assetUrllocalFile
	ParaAsset.OpenArchive(worldpath, true)
	local search_result = ParaIO.SearchFiles("","*", worldpath, 0, 10, 0);
	local nCount = search_result:GetNumOfResult();
	if(nCount == 1) then
		-- just use the first directory in the world zip file as the world name.
		local WorldName = search_result:GetItem(0);
		WorldName = string.gsub(WorldName, "[/\\]$", "");
		worldpath = string.gsub(worldpath, "([^/\\]+)%.%w%w%w$", WorldName); -- get rid of the zip file extension for display 
	else
		worldpath = worldpath:gsub("[^/\\]+$", "");
	end
	Files.AddWorldSearchPath(worldpath);

	-- open zip and add to world search path
	LOG.std(nil, "info", "WorldCommon", "world asset url prepared at %s", WorldCommon.assetUrllocalFile)
end

-- download asset url and add to search path
-- @return true if already prepared. 
function WorldCommon.PrepareAssetUrl(assetUrl, callbackFunc)
	assetUrl = assetUrl or WorldCommon.GetWorldTag("assetUrl");
	if(assetUrl and assetUrl:match("^https?://")) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
		local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
		local downloader = FileDownloader:new();
		downloader:SetSilent(true)
		local filename = assetUrl:match("([^/]+)$");
		local diskFilePath = ParaIO.GetWritablePath() .. "temp/prepareAssetUrl/"..filename;

		if(ParaIO.DoesFileExist(diskFilePath, true)) then
			LOG.std(nil, "info", "WorldCommon", "asset url %s already exist", assetUrl)
			WorldCommon.PrepareDiskZipFile(diskFilePath)
			if(callbackFunc) then
				callbackFunc(true)
			end
			return true
		else
			ParaIO.CreateDirectory(prepareFolder);
			downloader:Init(L"下载美术资源", assetUrl, diskFilePath, function(bSucceed, localFile)
				if(bSucceed and localFile) then
					WorldCommon.PrepareDiskZipFile(localFile)
				else
					LOG.std(nil, "warn", "WorldCommon", "failed to prepare asset url %s, because %s", assetUrl, tostring(localFile))
				end
				if(callbackFunc) then
					callbackFunc(bSucceed)
				end
			end, "access plus 1 year");
		end
		return
	end
	if(callbackFunc) then
		callbackFunc()
	end
	return true
end

function WorldCommon.CloseWorldAssetUrl()
	if(WorldCommon.assetUrllocalFile) then
		ParaAsset.CloseArchive(WorldCommon.assetUrllocalFile)
		LOG.std(nil, "info", "WorldCommon", "asset url %s unloaded from zip", WorldCommon.assetUrllocalFile)
		WorldCommon.assetUrllocalFile = nil;
	end
end