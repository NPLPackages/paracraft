--[[
Title: 
Author(s): chenjinxian
Date: 
Desc: 
use the lib:
------------------------------------------------------------
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
World2In1.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingUpload.lua");
local VideoSharingUpload = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingUpload");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CreateRewardManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/CreateRewardManager.lua") 
local World2In1UserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1UserInfo.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local ParaWorldMiniChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");
local CreateModulPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CreateModulPage.lua")
local World2In1 = NPL.export();

local page;
local mapTypeIndex = {grade = 1, school = 2, all = 3, course = 4, creator = 5};
local regions = {{37, 36}, {38, 37}, {37, 38}, {36, 37}, {37, 37}};
local centerPos = {19200, 12, 19200};
local creatorWorldName = "chenjinxian_ceshi123_study";

local allMiniWorlds = {{}, {}, {}};
local currentWorlds = {};
local worldIndex = 1;
local serverDataIndex = 1;

local parentWorldId = 59045;
local currentType = "course";
local last_region_type = "course"
local currentGridX = 0;
local currentGridY = 0;
local lock_timer;
local load_timer;
local courcePosition = {18542,43,19197}

local hidePage = false;
local page_root = nil
local last_audio_src
local music_path = "Audio/Haqi/keepwork/common/"

World2In1.ServerWorldData = {}
function World2In1.OnInit()
	page = document:GetPageCtrl();
	page_root = page:GetParentUIObject()
end

function World2In1.Init()
	World2In1.SetIsWorld2In1(true)

	-- 绑定上传世界完成事件
	GameLogic.GetFilters():add_filter("SyncWorldFinish", World2In1.OnSyncWorldFinish);
end

function World2In1.ShowPage(offset, reload)
	offset = offset or 0;

	World2In1.Init()
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.html",
		name = "World2In1.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		enable_esc_key = false,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_rt",
		x = -370 - offset,
		y = 0,
		width = 370,
		zorder = -13,
		height = 260,		
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", World2In1.MoveLeft, World2In1, "World2In1");
	GameLogic:Connect("WorldUnloaded", World2In1, World2In1.OnWorldUnload, "UniqueConnection");
	--echo({hidePage,reload})
	if (not hidePage and not reload) then
		allMiniWorlds = {{}, {}, {}};
		--World2In1.OnEnterCourseRegion();
		
	end
	hidePage = false;
	World2In1.OnMouseChangeEx()
	-- commonlib.TimerManager.SetTimeout(function()  
	-- 	World2In1.OnMouseChangeEx()
	-- end, 500);
end

function World2In1.OnMouseChangeEx()
	if page then
		local name_list = {
			"mapBg",
			"school_title_bg",
			"all_title_bg",
			"grade_title_bg",
			"cource_title_bg",
			"creator_title_bg",
		}
		for i = 1,#name_list do
			local name = name_list[i]
			local img_Bg = page:GetNode(name);  
			local img_BgObj = ParaUI.GetUIObject(img_Bg.uiobject_id)
			
			img_BgObj:SetScript("onmouseenter",function()
				World2In1.ShowImageSel(true)
				if name == "mapBg" then
					_guihelper.SetUIColor(img_BgObj, "#ffffff")
				end				
			end)  
			img_BgObj:SetScript("onmouseleave",function()
				World2In1.ShowImageSel(false)
				if name == "mapBg" then
					_guihelper.SetUIColor(img_BgObj, "#ffffff")
				end
			end)
		end
		local img_SelBg = page:GetNode("mapSelectBg");  
		local img_SelObg = ParaUI.GetUIObject(img_SelBg.uiobject_id)
		img_SelObg.visible = false
		for i = 1,#name_list do
			local name = name_list[i]
			if name ~= "mapBg" then
				local img_Bg = page:GetNode(name);  
				local img_BgObj = ParaUI.GetUIObject(img_Bg.uiobject_id)
				img_BgObj.visible = false

				local lblname = string.sub(name_list[i],1,-4)
				local lbl_text = page:GetNode(lblname);  
				local lbl_textObj = ParaUI.GetUIObject(lbl_text.uiobject_id)
				lbl_textObj.visible = false
			end
		end
	end
end

function World2In1.ShowImageSel(bShow)
	local bShow = bShow or false
	local name_list = {
		"school_title",
		"all_title",
		"grade_title",
		"cource_title",
		"creator_title",
	}
	local img_SelBg = page:GetNode("mapSelectBg");  
	local img_SelObg = ParaUI.GetUIObject(img_SelBg.uiobject_id)
	img_SelObg.visible = bShow
	for i = 1,#name_list do
		local name = name_list[i]
		local lbl_text = page:GetNode(name);  
		local lbl_textObj = ParaUI.GetUIObject(lbl_text.uiobject_id)
		lbl_textObj.visible = bShow

		local nameBg = name_list[i].."_bg"
		local bg_node = page:GetNode(nameBg)
		local bg_nodeObj = ParaUI.GetUIObject(bg_node.uiobject_id) 
		bg_nodeObj.visible = bShow
	end	
end

function World2In1:MoveLeft(event)
	if (hidePage) then return end
	if (page) then
		page:CloseWindow();
	end
	if (event.bShow) then
		World2In1.ShowPage(event.width, true);
	else
		World2In1.ShowPage(0, true);
	end
end

function World2In1.OnWorldUnload()
	World2In1.EndLoadTimer();
	World2In1.EndLockTimer();
	World2In1.HideCreateReward()
	World2In1UserInfo.ShowPage(nil);
	allMiniWorlds = {{}, {}, {}};
	currentWorlds = {};
	World2In1.ServerWorldData = {}
	worldIndex = 1;
	serverDataIndex = 1
	parentWorldId = 59045;
	World2In1.SetCurrentType("course")
	currentGridX = 0;
	currentGridY = 0;
	lock_timer = nil
	load_timer = nil
	courcePosition = {18542,43,19197}
	hidePage = false;
	page_root = nil
	VideoSharingUpload.ChangeRegionType(nil)
	World2In1.SetIsWorld2In1(false)
	World2In1.CelarToolData()
	World2In1.SetIsLessonBox(false)
	World2In1.StopMusic()
end

function World2In1.CelarToolData()
	World2In1.ItemsDataSource = nil

	if World2In1.CodeEditor then
		World2In1.CodeEditor:clear()
		World2In1.CodeEditor = nil
	end
end

function World2In1.OnClose()
	GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", World2In1.MoveLeft, World2In1);
	if (page) then
		page:CloseWindow();
	end
	World2In1.OnWorldUnload();
end

function World2In1.HidePage()
	GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", World2In1.MoveLeft, World2In1);
	if (page) then
		page:CloseWindow();
	end
	hidePage = true;
end

function World2In1.GetRegionType()
	return currentType
end

function World2In1.BroadcastTypeChanged()
	if(currentType == "creator")then
		GameLogic.RunCommand("/ggs user hidden ");	
	else
		GameLogic.RunCommand("/ggs user visible");
		World2In1.HideCreateReward()	
	end
	VideoSharingUpload.ChangeRegionType(currentType)
	-- World2In1.UnLoadcurrentWorldList()
	GameLogic.GetCodeGlobal():BroadcastTextEvent("changeRegionType")

	if last_region_type == "creator" then
		World2In1.ChangeSkyBox("")
		World2In1.CelarToolData()
	end

	GameLogic.RunCommand("/unmount")
	local project_id = WorldCommon.GetWorldTag("kpProjectId");
	if project_id == 79969 then
		World2In1.StopWorldMusic()
		if currentType == "creator" then
			World2In1.PlayCreatorMusic()
		elseif currentType == "all" or currentType == "school" or currentType == "grade" then
			World2In1.PlayOtherMusic()
		elseif currentType == "course" then
			World2In1.PlayWorldMusic()
		end
	end
end

function World2In1.PlayWorldMusic()
	local filename = music_path.."bigworld_bgm.ogg"
	-- GameLogic.RunCommand("/music "..(filename or ""));
	World2In1.PlayMusic(filename,0.1)
end

function World2In1.PlayLessonMusic()
	local filename = music_path.."offline_bgm.ogg"
	-- GameLogic.RunCommand("/music "..(filename or ""));
	World2In1.PlayMusic(filename,0.1)
end

function World2In1.PlayOperateMusic()
	local filename = music_path.."guide_bgm.ogg"
	-- GameLogic.RunCommand("/music "..(filename or ""));
	World2In1.PlayMusic(filename,0.05)
end

function World2In1.PlayCreatorMusic()
	local filename = music_path.."planet_bgm.ogg"
	-- GameLogic.RunCommand("/music "..(filename or ""));
	World2In1.PlayMusic(filename,0.1)
end

function World2In1.PlayOtherMusic()
	local filename = music_path.."minigame_bgm.ogg"
	-- GameLogic.RunCommand("/music "..(filename or ""));
	World2In1.PlayMusic(filename,0.1)
end

function World2In1.PlayLogoMusic()
	local filename = music_path.."login_bgm.ogg"
	-- GameLogic.RunCommand("/music "..(filename or ""));
	World2In1.PlayMusic(filename,0.1)
end

--local filename = "Audio/Haqi/keepwork/common/offline_bgm.ogg"
function World2In1.PlayMusic(filename,volume,pitch)
    local volume = volume or 1
    local music_audio = World2In1.GetMusic(filename)
    if last_audio_src ~= music_audio then
        if(last_audio_src) then
            last_audio_src:stop();
        end
        last_audio_src = music_audio
    end
    if music_audio then
        music_audio:play2d(volume,pitch);
    end
end

function World2In1.GetMusic(filename)
	if(not filename or filename=="") then
		return;
	end
	filename = commonlib.Encoding.Utf8ToDefault(filename)

	local audio_src = AudioEngine.Get(filename);
	if(not audio_src) then
		if(not ParaIO.DoesAssetFileExist(filename, true)) then
			filename = ParaWorld.GetWorldDirectory()..filename;
			if(not ParaIO.DoesAssetFileExist(filename, true)) then
				return;
			end
		end		
		audio_src = AudioEngine.CreateGet(filename);
		audio_src.loop = true;
		audio_src.file = filename;
		audio_src.isBackgroundMusic = true;
	end
	
	return audio_src;
end

function World2In1.StopMusic()
	if last_audio_src then
		last_audio_src:stop();
		last_audio_src = nil;
	end
end

function World2In1.StopWorldMusic()
	BackgroundMusic:Stop();
end

function World2In1.SaveCreateTips(callback)
	if currentType == "creator" then
		_guihelper.MessageBox(
            L"是否需要保存你已经创造的作品?",
            function(res)
                if res and res == _guihelper.DialogResult.OK then
                    World2In1.OnSaveWorld()
					if(callback)then
						callback()
					end
                end
                if res and res == _guihelper.DialogResult.Cancel then
                    if(callback)then
						callback()
					end
                end
            end,
            _guihelper.MessageBoxButtons.OKCancel_CustomLabel
        )
	else
		if(callback)then
			callback()
		end
	end
	
end

function World2In1.SetParentWorldId(parentId)
	CreateRewardManager.InitCreateManager()
	parentWorldId = parentId;
end

function World2In1.SetCreatorWorldName(worldName)
	creatorWorldName = worldName;
end

function World2In1.GetCreatorWorldName()
	return creatorWorldName or "";
end

function World2In1.SetCourcePosition(pos)
	courcePosition = pos
end

function World2In1.SetRegionPositions(type, x, y)
	local index = mapTypeIndex[type];
	if (index) then
		regions[index][1] = x;
		regions[index][2] = y;
	end
end

function World2In1.GetRegionCenterPos(typeIndex)
	local centerR = regions[5];
	local region = regions[typeIndex];
	local x = centerPos[1] + (region[1] - centerR[1]) * 512;
	local y = centerPos[2];
	local z = centerPos[3] + (region[2] - centerR[2]) * 512;
	return x, y, z
end

function World2In1.FromWorldPosToGridXY(worldX, worldY, typeIndex)
	local x, y, z = World2In1.GetRegionCenterPos(typeIndex);
	return math.floor((worldX - x)/128), math.floor((worldY - z)/128)
end

function World2In1.isValidGridXY(typeIndex, gridX, gridY)
	if (typeIndex == 1) then
		return gridX == 0 and gridY <= 0;
	elseif (typeIndex == 2) then
		return gridX >= 0 and gridY == 0;
	elseif (typeIndex == 3) then
		return gridX == 0 and gridY >= 0;
	else
		return false;
	end
end

function World2In1.updateWorldIndex(typeIndex, gridX, gridY)
	local lastWorldIndex = worldIndex
	if (typeIndex == 1) then
		worldIndex = 1 - gridY;
	elseif (typeIndex == 2) then
		worldIndex = gridX + 1;
	elseif (typeIndex == 3) then
		worldIndex = gridY + 1;
	end

	local offset = worldIndex - lastWorldIndex
	local move_dir = 1
	move_dir = offset >= 0 and 1 or -1
	
	serverDataIndex = serverDataIndex + offset

	
	-- -- 判断下该地块是否加载
	local gridX, gridY = 0, 0
	if currentType == "all" then
		gridX, gridY = 0, worldIndex - 1
	elseif currentType == "school" then 
		gridX, gridY = worldIndex - 1, 0
	elseif currentType == "grade" then 
		gridX, gridY = 0, 1 - worldIndex
	end
	
	-- local typeIndex = mapTypeIndex[type];
	local currentWorldList = allMiniWorlds[typeIndex];
	local key = string.format("%d_%d", gridX, gridY);
	if currentWorldList[key] == nil or not currentWorldList[key].loaded then
		local world = currentWorlds[serverDataIndex]
		if world and world.is_load then
			local index = serverDataIndex
			-- body
			
			while index > 1 and index < #currentWorlds do
				index = index + move_dir
				world = currentWorlds[index]
				if world == nil then
					break
				end
	
				if not world.is_load then
					serverDataIndex = index
					break
				end
			end
		end
	end
end

function World2In1.OnEnterGradeRegion()
	World2In1.SaveCreateTips(function()
		World2In1.ShowCreateReward()
		World2In1.SetGameMode();
		World2In1.SetCurrentType("grade")
		World2In1.BroadcastTypeChanged()
		local x, y,  z = World2In1.GetRegionCenterPos(1);
		GameLogic.RunCommand(string.format("/goto %d %d %d", x + 64, y, z + 64));	
		World2In1.StartLoadTimer();
		World2In1.LoadAllWorlds(currentType, function()
			World2In1.LoadMiniWorld(currentType, 0, 0);
		end);		
	end)
	
end

function World2In1.OnEnterSchoolRegion()
	World2In1.SaveCreateTips(function()
		World2In1.ShowCreateReward()
		World2In1.SetGameMode();
		World2In1.SetCurrentType("school")
		World2In1.BroadcastTypeChanged()
		local x, y,  z = World2In1.GetRegionCenterPos(2);
		GameLogic.RunCommand(string.format("/goto %d %d %d", x + 64, y, z + 64));	
		World2In1.StartLoadTimer();
		World2In1.LoadAllWorlds(currentType, function()
			World2In1.LoadMiniWorld(currentType, 0, 0);
		end);	
	end)	
end

function World2In1.OnEnterAllRegion()
	World2In1.SaveCreateTips(function()
		World2In1.SetGameMode();
		World2In1.ShowCreateReward()
		World2In1.SetCurrentType("all")
		World2In1.BroadcastTypeChanged()
		local x, y,  z = World2In1.GetRegionCenterPos(3);
		GameLogic.RunCommand(string.format("/goto %d %d %d", x + 64, y, z + 64));	
		World2In1.StartLoadTimer();
		World2In1.LoadAllWorlds(currentType, function()
			World2In1.LoadMiniWorld(currentType, 0, 0);
		end);	
	end)	
end

function World2In1.GetEmptyGridIndex(default_index, type)
	-- 判断下该地块是否加载
	local gridX, gridY = 0, 0
	if type == "all" then
		gridX, gridY = 0, default_index - 1
	elseif type == "school" then 
		gridX, gridY = default_index - 1, 0
	elseif type == "grade" then 
		gridX, gridY = 0, 1 - default_index
	end
	
	local typeIndex = mapTypeIndex[type];
	local currentWorldList = allMiniWorlds[typeIndex];
	local key = string.format("%d_%d", gridX, gridY);
	if currentWorldList[key] == nil or not currentWorldList[key].loaded then
		return default_index
	end

	local index = default_index
	while index < 85 do
		index = index + 1
		if type == "all" then
			gridX, gridY = 0, index - 1
		elseif type == "school" then 
			gridX, gridY = index - 1, 0
		elseif type == "grade" then 
			gridX, gridY = 0, 1 - index
		end

		key = string.format("%d_%d", gridX, gridY);
		if not currentWorldList[key] or not currentWorldList[key].loaded then
			return index
		end
	end
end

function World2In1.OnEnterRegionByProjectName(type, project_name)
	World2In1.SetGameMode();
	World2In1.SetCurrentType(type)
	World2In1.BroadcastTypeChanged()
	World2In1.StartLoadTimer();

	worldIndex = 1
	serverDataIndex = 1
	local is_world_load = false
	World2In1.LoadAllWorlds(currentType, function(worlds_data)
		for i, v in ipairs(worlds_data) do
			if v.name == project_name then
				worldIndex = i
				serverDataIndex = i
				is_world_load = v.is_load
				break
			end
		end

		if worlds_data[serverDataIndex] and worlds_data[serverDataIndex].is_load then
			worldIndex = worlds_data[serverDataIndex].worldIndex or 1
		else
			if serverDataIndex > 43 then
				worldIndex = 43
			end
			
			worldIndex = World2In1.GetEmptyGridIndex(worldIndex, type)
		end

		local pox_index = worldIndex - 1
		if type == "all" then
			local x, y,  z = World2In1.GetRegionCenterPos(3);
			z = z + pox_index * 128;
			GameLogic.RunCommand(string.format("/goto %d %d %d", x+64, y, z+64));
			-- worldIndex = worldIndex + 1;
			World2In1.LoadMiniWorld(currentType, 0, worldIndex - 1);
		elseif type == "school" then 
			local x, y,  z = World2In1.GetRegionCenterPos(2);
			x = x + pox_index * 128;
			GameLogic.RunCommand(string.format("/goto %d %d %d", x+64, y, z+64));
			-- worldIndex = worldIndex + 1;
			World2In1.LoadMiniWorld(currentType, worldIndex - 1, 0);
		elseif type == "grade" then 
			local x, y,  z = World2In1.GetRegionCenterPos(1);
			z = z - pox_index * 128;
			GameLogic.RunCommand(string.format("/goto %d %d %d", x+64, y, z+64));
			-- worldIndex = worldIndex + 1;
			World2In1.LoadMiniWorld(currentType, 0, 1 - worldIndex);
		end

	end);
end

function World2In1.StartLoadTimer()
	load_timer = load_timer or commonlib.Timer:new({callbackFunc = function(timer)
		local player = EntityManager.GetPlayer()
		local x, y, z = player:GetBlockPos();
		local typeIndex = mapTypeIndex[currentType];
		local gridX, gridY = World2In1.FromWorldPosToGridXY(x, z, typeIndex);
		if ((currentGridX ~= gridX or currentGridY ~= gridY) and World2In1.isValidGridXY(typeIndex, gridX, gridY)) then
			currentGridX = gridX;
			currentGridY = gridY;
			World2In1.updateWorldIndex(typeIndex, gridX, gridY);
			World2In1.LoadMiniWorld(currentType, gridX, gridY);
		end
	end});
	load_timer:Change(1000, 1000);
end

function World2In1.EndLoadTimer()
	if (load_timer) then
		load_timer:Change();
	end
end

function World2In1.OnEnterCourseRegion()
	World2In1.SaveCreateTips(function()
		World2In1.EndLoadTimer();
		World2In1UserInfo.ShowPage(nil);
		World2In1.SetGameMode();
		World2In1.ShowCreateReward()
		World2In1.SetCurrentType("course")
		World2In1.BroadcastTypeChanged()
		if courcePosition then
			GameLogic.RunCommand(string.format("/goto %d %d %d", courcePosition[1],courcePosition[2],courcePosition[3]));
		else
			local x, y,  z = World2In1.GetRegionCenterPos(4);
			GameLogic.RunCommand(string.format("/goto %d %d %d", x + 64, y + 40,  z + 64));
		end		
	end)
	
end

function World2In1.SetEnterCreateRegionCb(cb)
	World2In1.enter_create_region_cb = cb
end

function World2In1.GetEnterCreateRegionCb()
	return World2In1.enter_create_region_cb
end

function World2In1.ChangeSkyBox(file)
	local entity_sky = GameLogic.GetSkyEntity()
	if file and (file ~= entity_sky.filename or entity_sky.IsSimulatedSky) then
		if file == "" then
			if not entity_sky.IsSimulatedSky then
				NPL.load("(gl)script/apps/Aries/Creator/Env/SkyPage.lua");
				local SkyPage = commonlib.gettable("MyCompany.Aries.Creator.SkyPage");
				SkyPage.OnChangeSkybox(1);
			end
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
			local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
			CommandManager:RunCommand("/sky "..file);
		end
	end
end

function World2In1.GotoCreateRegion(pos)
	World2In1.EndLoadTimer();
	World2In1UserInfo.ShowPage(nil);
	GameLogic.RunCommand("/mode edit");
	World2In1.SetCurrentType("creator")
	World2In1.BroadcastTypeChanged()
	World2In1.ShowCreateReward(true)	

	World2In1.GetCreateWorldServerData(function()
		local extra = World2In1.create_world_server_data.extra or {}
		World2In1.ChangeSkyBox(extra.sky_file)
	end)

	if World2In1.enter_create_region_cb then
		World2In1.enter_create_region_cb()
		World2In1.enter_create_region_cb = nil
	end	

	local path = World2In1.GetWritablePath().."worlds/DesignHouse/"..commonlib.Encoding.Utf8ToDefault(creatorWorldName)
	local tag_xml_data = World2In1.LoadWorldTageXml(path)      
	if tag_xml_data and tag_xml_data.attr and tag_xml_data.attr.fromProjects then
		local form_project_list = commonlib.split(tag_xml_data.attr.fromProjects,",") or {};
		local form_project_id = form_project_list[#form_project_list]
		
		if form_project_id and tonumber(form_project_id) then
			local module_data = CreateModulPage.GetOneProjectData(tonumber(form_project_id))
			if module_data and module_data.pos then
				local default_pos = module_data.pos
				GameLogic.RunCommand(format("/goto %d %d %d", default_pos[1], default_pos[2], default_pos[3]))
			elseif pos then
				GameLogic.RunCommand(format("/goto %d %d %d", pos[1], pos[2], pos[3]))
			end
		elseif pos then
			GameLogic.RunCommand(format("/goto %d %d %d", pos[1], pos[2], pos[3]))
		end
		-- body
	elseif pos then
		GameLogic.RunCommand(format("/goto %d %d %d", pos[1], pos[2], pos[3]))
	end

	World2In1.InitToolItems()

	lock_timer = lock_timer or commonlib.Timer:new({callbackFunc = function(timer)
		local player = EntityManager.GetPlayer()
		local x, y, z = player:GetBlockPos();
		local dis = 50
		local minX, minY, minZ = 19136, 12, 19136;
		local maxX = minX+128 + dis;
		local maxZ = minZ+128 + dis;
		local newX = math.min(maxX-5, math.max(minX-dis + 4, x));
		local newZ = math.min(maxZ-5, math.max(minZ-dis + 4, z));
		local newY = math.max(minY-1, y);
		if(x~=newX or y~=newY or z~=newZ) then
			player:SetBlockPos(newX, newY, newZ)
			if(y~=newY and not GameLogic.IsReadOnly()) then
				local blockTemplate = BlockEngine:GetBlock(newX, minY-2, newZ)	
				if(not blockTemplate) then
					BlockEngine:SetBlock(newX, minY-2, newZ, names.Bedrock);
				end
			end
		end
	end})
	lock_timer:Change(1000, 1000);
end

function World2In1.OnEnterCreatorRegion()	
	if (currentType == "creator") then
		return;
	end	
	local project_id = WorldCommon.GetWorldTag("kpProjectId");
	local id_list = {
		[79969] = 1,
		[76739] = 1,
		[83044] = 1,
		[128252] = 1,
		[132939] = 1,
		
	}
	if id_list[project_id] then
		GameLogic.RunCommand("/sendevent gotoCreate")
		return 
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/WorldCreatePage.lua").Show();
end

function World2In1.ShowCreateReward(isCreateRegion)
	if not page_root then
		return 
	end	
	CreateRewardManager.ShowGiftBtn(page_root,isCreateRegion)
end

function World2In1.HideCreateReward()
	CreateRewardManager.HideGiftBtn()
end

function World2In1.EndLockTimer()
	if (lock_timer) then
		lock_timer:Change();
	end
end

function World2In1.SetGameMode()
	World2In1.EndLockTimer();
	GameLogic.RunCommand("/mode strictgame");
end

function World2In1.GoToNextGradeMiniWorld()
	local x, y,  z = World2In1.GetRegionCenterPos(1);
	z = z - worldIndex * 128;
	GameLogic.RunCommand(string.format("/goto %d %d %d", x+64, y, z+64));
	worldIndex = worldIndex + 1;
	serverDataIndex = serverDataIndex + 1
	World2In1.LoadMiniWorld(currentType, 0, 1 - worldIndex);
end

function World2In1.GoToNextSchoolMiniWorld()
	local x, y,  z = World2In1.GetRegionCenterPos(2);
	x = x + worldIndex * 128;
	GameLogic.RunCommand(string.format("/goto %d %d %d", x+64, y, z+64));
	worldIndex = worldIndex + 1;
	serverDataIndex = serverDataIndex + 1
	World2In1.LoadMiniWorld(currentType, worldIndex - 1, 0);
end

function World2In1.GoToNextAllMiniWorld()
	local x, y,  z = World2In1.GetRegionCenterPos(3);
	z = z + worldIndex * 128;
	GameLogic.RunCommand(string.format("/goto %d %d %d", x+64, y, z+64));
	worldIndex = worldIndex + 1;
	serverDataIndex = serverDataIndex + 1
	World2In1.LoadMiniWorld(currentType, 0, worldIndex - 1);
end

function World2In1.ShowHelpPage()
	GameLogic.AddBBS(nil,"敬请期待~")
end

function World2In1.ShowRankPage()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/World2In1Rank.lua").Show();
	--GameLogic.AddBBS(nil,"功能未上线~")
end

function World2In1.OnSaveWorld()
	if currentType ~= "creator" then
		_guihelper.MessageBox("创造区才可以保存你的作品哟，是否去创造区创造你的作品",function()
			World2In1.OnEnterCreatorRegion()
		end)
		return 
	end
	if (creatorWorldName and creatorWorldName ~= "") then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.macro.task", { from = "macrosave",  name = "clicksave",});
		GameLogic.RunCommand(string.format("/saveregionex %s 37 37",creatorWorldName))   

		if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
			--GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.macro.task", { from = "macrosave",  name = "clicksave",});
			local RealNameTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RealNameTip/RealNameTip.lua")
			RealNameTip.ShowView()
			return 
		end
	
		local blocks = ParaWorldMiniChunkGenerator:GetAllBlocks();
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		local filename = World2In1.GetWritablePath().."worlds/DesignHouse/"..commonlib.Encoding.Utf8ToDefault(creatorWorldName).."/miniworld.template.xml";
		
		local x, y, z = ParaWorldMiniChunkGenerator:GetPivot();
		local params = {};
		params.pivot = string.format("%d,%d,%d", x, y, z)
		params.relative_motion = true;

		local World2In1FramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.World2In1FramePage");
		if World2In1FramePage.has_bind then
			World2In1FramePage.SaveToXml()
		end
		
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, 
			params = params,
			exportReferencedFiles = true,
			blocks = blocks})
		task:Run();
		
		
		World2In1.UpLoadWorld()
		-- GameLogic.GetFilters():apply_filters("cellar.sync.sync_main.sync_to_data_source_by_world_name", creatorWorldName, function(res)
		-- 	if (res) then
		-- 	end
		-- end);	
	end
end

function World2In1.UpLoadWorld()
	local curProjectId = World2In1.GetProjectIdByWorldName(creatorWorldName)
	if curProjectId <= 0 then
		GameLogic.GetFilters():apply_filters("service.local_service_world.set_world_instance_by_foldername", creatorWorldName);	
		local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
		if world_data and world_data.kpProjectId then
			-- curProjectId = world_data.kpProjectId
			GameLogic.GetFilters():apply_filters(
			'service.sync_to_data_source.init',
			function(result, option)
				if option.method == 'UPDATE-PROGRESS-FINISH' then
					GameLogic.AddBBS(nil,"上传创作区成功")
				end
			end)
			return
		end
	end
	GameLogic.GetFilters():apply_filters(
		'service.keepwork_service_world.set_world_instance_by_pid',
		tonumber(curProjectId),
		function()
			GameLogic.GetFilters():apply_filters(
				'service.sync_to_data_source.init',
				function(result, option)
					if option.method == 'UPDATE-PROGRESS-FINISH' then
						GameLogic.AddBBS(nil,"上传创作区成功")
					end
				end)
		end
	)
end

function World2In1.GetProjectIdByWorldName(worldName)
	local worldName = worldName or creatorWorldName	
	local targetFolder = World2In1.GetWritablePath().."worlds/DesignHouse/"..commonlib.Encoding.Utf8ToDefault(worldName).."/"
	if(ParaIO.DoesFileExist(targetFolder.."tag.xml", false)) then
		local tag_xml_data = World2In1.LoadWorldTageXml(targetFolder) 
		echo(tag_xml_data)
		if tag_xml_data and tag_xml_data.attr and tag_xml_data.attr.kpProjectId then
			return tonumber(tag_xml_data.attr.kpProjectId)
		end 
	end
	return -1
end

function World2In1.UnLoadcurrentWorldListByName(name)
	if allMiniWorlds == nil then
		return
	end

	for k, v in pairs(allMiniWorlds) do
		for k2, v2 in pairs(v) do
			if v2.projectName == name then
				v[k2].need_clean = true
			end
		end

	end
end

function World2In1.UnLoadcurrentWorldList(name)
	if allMiniWorlds == nil then
		return
	end

	for k, v in pairs(allMiniWorlds) do
		for k2, v2 in pairs(v) do
			v[k2].need_clean = true
		end
	end

end

function World2In1.LoadMiniWorld(type, gridX, gridY)
	function localGridXYToGlobal(gridX, gridY, typeIndex)
		if (typeIndex == 1) then
			gridX = gridX
			gridY = gridY - 4;
		elseif (typeIndex == 2) then
			gridX = gridX + 4;
			gridY = gridY;
		elseif (typeIndex == 3) then
			gridX = gridX
			gridY = gridY + 4;
		end
		return gridX, gridY;
	end

	local typeIndex = mapTypeIndex[type];
	local currentWorldList = allMiniWorlds[typeIndex];
	local key = string.format("%d_%d", gridX, gridY);
	if (currentWorldList[key] and currentWorldList[key].loaded) then
		if currentWorldList[key].need_clean then
			local gen = GameLogic.GetBlockGenerator();
			local x, y = localGridXYToGlobal(gridX, gridY, typeIndex);
			gen:ResetGridXY(x, y);

			-- currentWorldList[key].need_clean = false
			-- currentWorldList[key].loaded = false
			currentWorldList[key] = nil
		else
			if (currentWorldList[key].projectName and currentWorldList[key].projectName ~= "") then
				GameLogic.AddBBS(nil, string.format(L"进入【%s】", currentWorldList[key].projectName), 3000, "0 255 0");
				local params = currentWorldList[key]
				World2In1UserInfo.ShowPage(params);
				if currentWorldList[key].sky_file then
					World2In1.ChangeSkyBox(currentWorldList[key].sky_file)
				else
					World2In1.ChangeSkyBox("")
				end
			else
				World2In1UserInfo.ShowPage(nil);
				World2In1.ChangeSkyBox("")
			end
			return;
		end
	end

	function downloadFile(world, commitId)
		local path = ParaWorldMiniChunkGenerator:GetTemplateFilepath();
		local filename = ParaIO.GetFileName(path);
		GameLogic.GetFilters():apply_filters('get_single_file_by_commit_id',world.id, commitId, filename, function(content)
			if (not content) then
				currentWorldList[key].loaded = false;
				return;
			end

			local miniTemplateDir = World2In1.GetWritablePath().."temp/miniworlds/";
			ParaIO.CreateDirectory(miniTemplateDir);
			local template_file = miniTemplateDir..world.id..".xml";
			local file = ParaIO.open(template_file, "w");

			if (file:IsValid()) then
				file:write(content, #content);
				file:close();
				local gen = GameLogic.GetBlockGenerator();
				local x, y = localGridXYToGlobal(gridX, gridY, typeIndex);
				gen:LoadTemplateAtGridXY(x, y, template_file);
				currentWorldList[key].loaded = true;
				currentWorldList[key].projectName = world.name;
				currentWorldList[key].projectId = world.id;
				currentWorldList[key].userId = world.userId;
				currentWorldList[key].gridX = gridX;
				currentWorldList[key].gridY = gridY;
				currentWorldList[key].typeIndex = typeIndex;

				if world.extra and world.extra.sky_file then
					currentWorldList[key].sky_file = world.extra.sky_file
					World2In1.ChangeSkyBox(world.extra.sky_file)
				else
					World2In1.ChangeSkyBox("")
				end
				world.is_load = true
				world.worldIndex = worldIndex
				GameLogic.AddBBS(nil, string.format(L"欢迎来到【%s】", world.name), 3000, "0 255 0");				
				local params = currentWorldList[key]
				World2In1UserInfo.ShowPage(params);
			else
				currentWorldList[key].loaded = false;
			end
		end, true);
	end

	function checkWorldLoaded(id)
		for _, value in pairs(currentWorldList) do
			if (value.projectId == id) then
				return true;
			end
		end
		return false;
	end

	currentWorldList[key] = currentWorldList[key] or {loaded = true};
	
	local world = currentWorlds[serverDataIndex];
	if (world) then
		keepwork.world.detail({router_params = {id = world.id}}, function(err, msg, data)
			if (data and data.world and data.world.commitId) then
				downloadFile(world, data.world.commitId);
			else
				currentWorldList[key].loaded = false;
			end
		end);
	else
		currentWorldList[key].loaded = false;
	end
	--[[
	keepwork.world.by_parent_id({headers = {["x-per-page"] = 1, ["x-page"] = orldIndex}, type = type, parentId = parentWorldId}, function(err, msg, data)
		if (data and data.count and data.rows and data.rows[1]) then
			echo(data.rows);
			local world = {projectId = data.rows[1].id, projectName = data.rows[1].name, userId = data.rows[1].userId};
			echo(world);
			keepwork.world.detail({router_params = {id = world.projectId}}, function(err, msg, data)
				if (data and data.world and data.world.commitId) then
					downloadFile(world, data.world.commitId);
				else
					currentWorldList[key].loaded = false;
				end
			end);
		end
	end);
	]]
end

function World2In1.LoadAllWorlds(type, callback)
	worldIndex = 1
	serverDataIndex = 1
	if World2In1.ServerWorldData[type] == nil then
		World2In1.ServerWorldData[type] = {}
	end
	currentWorlds = World2In1.ServerWorldData[type]
	if #currentWorlds > 0 then
		if (page) then
			page:Refresh(0);
			World2In1.OnMouseChangeEx()
		end
		if (callback) then
			callback(currentWorlds);
		end
	else
		keepwork.world.by_parent_id({
			type = type, 
			parentId = parentWorldId,
			["x-per-page"] = 400,
			["x-page"] = 1,
		}, function(err, msg, data)
			if (data and data.count and data.rows) then
				for i = 1, #data.rows do
					currentWorlds[i] = data.rows[i];
				end
				if (page) then
					page:Refresh(0);
					World2In1.OnMouseChangeEx()
					-- commonlib.TimerManager.SetTimeout(function()  
					-- 	World2In1.OnMouseChangeEx()
					-- end, 500);
				end
				if (callback) then
					callback(currentWorlds);
				end
			end
		end);
	end
end

function World2In1.GetTypeIndex()
	return mapTypeIndex[currentType];
end

function World2In1.ShowToolBox()
	GameLogic.AddBBS(nil,"暂无可用的工具")
	-- GameLogic.GetCodeGlobal():BroadcastTextEvent("showToolBox", {}, function()
		
	-- end);
end

function World2In1.IsInSummerCampWorld()
    local id_list = {
        ONLINE = 70351,
        RELEASE = 20669,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local world_id = id_list[httpwrapper_version]
	local project_id = WorldCommon.GetWorldTag("kpProjectId");
	if project_id == world_id then
		return true
	end

	return false
end

function World2In1.SetCurrentType(type)
	last_region_type = currentType
	currentType = type;
end

function World2In1.GetCurrentType()
	return currentType
end

function World2In1.LoadWorldTageXml(world_path)
	world_path = string.gsub(world_path, "[/\\]$", "");

	local xmlRoot = ParaXML.LuaXML_ParseFile(world_path.."/tag.xml");
	if(xmlRoot) then
        -- local world_info = WorldInfo:new();
        if(xmlRoot) then
            local node;
            for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
                return node;
            end
        end 
	end
end

function World2In1.GetWritablePath()
	if World2In1.write_table_path == nil then
		World2In1.write_table_path = ParaIO.GetWritablePath()
	end
	
	return World2In1.write_table_path
end

function World2In1.IsInVisitPorject()
	if page == nil then
		return false
	end

	if currentType == "all" or currentType == "school" or currentType == "grade" then
		return true
	end

	return false
end

function World2In1.GetCurProjectServerData()
	if #currentWorlds == 0 then
		return
	end
	serverDataIndex = serverDataIndex or 1
	return currentWorlds[serverDataIndex]
end
-- 将原本的世界坐标 转换为迷你作品里的坐标
function World2In1.TurnWorldPosToMiniPos(pos)
	local pox_index = worldIndex - 1
	local x, y, z
	if currentType == "all" then
		x, y,  z = World2In1.GetRegionCenterPos(3);
		z = z + pox_index * 128;
		-- GameLogic.RunCommand(string.format("/goto %d %d %d", 19231, 14, 18524));
	elseif currentType == "school" then 
		x, y,  z = World2In1.GetRegionCenterPos(2);
		x = x + pox_index * 128;
		-- GameLogic.RunCommand(string.format("/goto %d %d %d", x, y, z));
	elseif currentType == "grade" then 
		x, y,  z = World2In1.GetRegionCenterPos(1);
		
		z = z - pox_index * 128;
		-- GameLogic.RunCommand(string.format("/goto %d %d %d", x, y, z));
	end
	if x then
		local begain_pos = {19136,12,19136}
		local targer_pos = {}
		targer_pos[1] = pos[1] - begain_pos[1] + x
		targer_pos[2] = pos[2] - begain_pos[2] + y
		targer_pos[3] = z - (begain_pos[3] - pos[3])
		
		return targer_pos
	end
end

function World2In1.SetIsWorld2In1(flag)
	World2In1.is_world2in1 = flag
end

function World2In1.GetIsWorld2In1()
	return World2In1.is_world2in1
end

function World2In1.SetIsLessonBox(flag)
	World2In1.is_lessonbox = flag
end

function World2In1.GetIsLessonBox()
	return World2In1.is_lessonbox
end

-- 初始化二合一世界工具栏物品数据
function World2In1.InitToolItems()
	if World2In1.ItemsDataSource then
		return
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
	local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	
	local filename = "items/customlist.xml"
	local file_path = Files.GetWorldFilePath(filename)
	if not file_path then
		return
	end

	World2In1.ItemsDataSource = {}
	local xmlRoot = ParaXML.LuaXML_ParseFile(file_path);
	local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
	local item_class = block_types.GetItemClass("ItemWorld2In1")
	if(xmlRoot) then
		local default_icon = {
			["model"] = "Texture/blocks/items/ts_char_off.png",
			["templates"] = "Texture/blocks/items/book_writable.png",
			["movie"] = "Texture/blocks/items/movie.png",
			["agent"] = "Texture/blocks/items/Command_Block.png",
			["skybox"] = "Texture/blocks/items/metal_block.png",
		}

		local code_item_list = {}
		for itemNode in commonlib.XPath.eachNode(xmlRoot, "/blocklist/category") do
			local data = {}
			data.text = itemNode.attr.text
			data.type = itemNode.attr.name
			
			data.item_list = {}
			if data.type == "skybox" then
				local item_data = {}
				item_data.name = "清空天空盒"
				item_data.type = data.type
				item_data.icon = default_icon[data.type]
				item_data.price = 0
				data.item_list[#data.item_list + 1] = item_data
			end

			for i, v in ipairs(itemNode) do
				local item_data = {}
				item_data.name = v.attr.name
				item_data.item_name = v.attr.name
				item_data.isvip = v.attr.isvip == "true"
				
				item_data.type = data.type
				item_data.obstruction = v.attr.obstruction == "true"
				item_data.filename = v.attr.filename
				item_data.price = tonumber(v.attr.price) or 0
				item_data.tips = v.attr.tips
				
				local icon_path = Files.GetWorldFilePath(string.format("items/%s/icon/%s.png", data.type, item_data.filename))
				if icon_path then
					item_data.icon = icon_path
				else
					item_data.icon = default_icon[data.type] or "Texture/blocks/items/ts_char_off.png"
				end
				if v.attr.id then
					item_data.id = tonumber(v.attr.id)
					item_data.block_id = item_data.id;
					local item = item_class:new(item_data);
					ItemClient.AddItem(item_data.block_id, item);
				end

				if data.type == "agent" and v.attr.isrun == "true" then
					--World2In1.RunCode(item_data)
					code_item_list[#code_item_list + 1] = item_data
				else
					data.item_list[#data.item_list + 1] = item_data
				end
			end

			World2In1.ItemsDataSource[#World2In1.ItemsDataSource + 1] = data
		end
		if #code_item_list > 0 then
			for index, item_data in ipairs(code_item_list) do
				World2In1.RunCode(item_data)
			end
		end
	end

	-- 加入resource目录
	local result = commonlib.Files.Find({}, GameLogic.current_worlddir.."items/resource/", 2, 500, function(item)
		if(item.filename:match("%.bmax$") or item.filename:match("%.x$")) then
			return true;
		end
	end)

	if result and #result > 0 then
		local start_id = 3900
		local data = {}
		data.text = "资源"
		data.type = "resource"
		data.item_list = {}
		for i, file in ipairs(result) do
			local item_data = {}
			item_data.name = file.filename:match("([^/\\]+%.bmax)$")
			if(not item_data.name) then
				item_data.name = file.filename:match("([^/\\]+%.x)$")
			end
			item_data.item_name = item_data.name
			item_data.isvip = false
			
			item_data.type = data.type
			item_data.obstruction = false
			item_data.filename = item_data.name
			item_data.price = 0
			item_data.icon = "Texture/blocks/items/ts_char_off.png"

			item_data.id = start_id + i
			item_data.block_id = item_data.id;
			local item = item_class:new(item_data);
			ItemClient.AddItem(item_data.block_id, item);

			data.item_list[#data.item_list + 1] = item_data
			--item_data.tips = item_data.name
		end

		World2In1.ItemsDataSource[#World2In1.ItemsDataSource + 1] = data
	end
end

function World2In1.AddAgentItem(blcok_item_data)
	if not World2In1.ItemsDataSource or #World2In1.ItemsDataSource == 0 then
		return
	end

	local agetn_item_list
	for i, v in ipairs(World2In1.ItemsDataSource) do
		if v.type == "agent" then
			agetn_item_list = v.item_list
			break
		end
	end
	if not agetn_item_list then
		return
	end

	local item_data = {}
	item_data.is_agent_item = true
	item_data.icon = blcok_item_data.icon
	item_data.tips = blcok_item_data.tooltip
	item_data.price = 0
	item_data.blcok_item_data = blcok_item_data
	agetn_item_list[#agetn_item_list + 1] = item_data
end

function World2In1.GetToolItems()
	return World2In1.ItemsDataSource or {}
end

function World2In1.GetCreateWorldServerData(cb)
    local world_data = Mod.WorldShare.Store:Get('world/currentWorld')
	if world_data == nil or world_data.kpProjectId == nil then
		World2In1.create_world_server_data = nil
		return
	end

	local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
	KeepworkServiceProject:GetProject(world_data.kpProjectId, function(data, err)
        if type(data) == 'table' then
			World2In1.create_world_server_data = data
			if cb then
				cb()
			end
        end
    end)
end

function World2In1.OnSyncWorldFinish()
    local world_data = Mod.WorldShare.Store:Get('world/currentWorld')
	if world_data == nil then
		return
	end

	local sync_sky_func = function()
		local extra = World2In1.create_world_server_data.extra or {}
		local entity_sky = GameLogic.GetSkyEntity()
		local server_sky_file = extra.sky_file
		-- 等于nil 说明是第一次保存
		local is_first_save = server_sky_file == nil
		local sky_file = entity_sky.filename;
		if entity_sky.IsSimulatedSky then
			sky_file = ""
		end

		-- 第一次保存 且最后没选择天空盒
		if is_first_save and entity_sky.filename == "" then
			sky_file = nil
		end
		
		if sky_file and sky_file ~= extra.sky_file then
			keepwork.project.update({
				router_params = {
					id = world_data.kpProjectId,
				},
				extra={
					sky_file=sky_file
				}
			},function(err,msg,data)
				if err == 200 then
					extra.sky_file = sky_file
				end
			end)			
		end
	end

	if World2In1.create_world_server_data then
		sync_sky_func()
	else
		World2In1.GetCreateWorldServerData(sync_sky_func)
	end
end

function World2In1.RunCode(item_data)
	local template_path = Files.GetWorldFilePath(string.format("items/%s/%s.xml", item_data.type, item_data.name))
	local xmlRoot = ParaXML.LuaXML_ParseFile(template_path or "");
	if not xmlRoot then
		return
	end
	
	local Editor = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/Editor.lua");
	local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");

	if not node[1] then
		return
	end

	local block_list = NPL.LoadTableFromString(node[1])
	local code_list = {}
	
	local begain_pos
	for index, v in ipairs(block_list) do
		if v[4] == 219 then
			code_list[#code_list + 1] = v
		elseif v[4] == 190 then
			begain_pos = {v[1], v[2], v[3]}
		end
	end

	if #code_list == 0 then
		return
	end

	local function get_distance(pos_list1, pos_list2)
		return (pos_list1[1] - pos_list2[1])^2 + (pos_list1[2] - pos_list2[2])^2 + (pos_list1[3] - pos_list2[3])^2
	end

	local function sort_list(list)
	-- 排序
		table.sort(list, function(a, b) 
			if a == b then
				return false
			end

			local sort_num_a = 0
			local sort_num_b = 0

			local dis_to_begain_a = get_distance(a, begain_pos)
			local dis_to_begain_b = get_distance(b, begain_pos)

			--return dis_to_begain_b > dis_to_begain_a
			-- 距离优先
			if dis_to_begain_a > dis_to_begain_b then
				sort_num_a = sort_num_a + 1000
			end

			if dis_to_begain_a < dis_to_begain_b then
				sort_num_b = sort_num_b + 1000
			end

			if dis_to_begain_a == dis_to_begain_b then
				-- 距离相等的情况下
				-- 忽略y轴
				-- x轴优先 小的优先
				if a[1] < b[1] then
					sort_num_a = sort_num_a + 100
				end

				if a[1] > b[1] then
					sort_num_b = sort_num_b + 100
				end

				if a[1] == b[1] then
					if a[3] < b[3] then
						sort_num_a = sort_num_a + 10
					else
						sort_num_b = sort_num_b + 10
					end
				end
			end

			-- -- 降序
			return sort_num_b > sort_num_a; 
		end);	
	end

	if begain_pos then
		-- 有开关的话 要找出里开关最近的那个方块
		local begain_code_list = {}
		local min_dis = 99999
		for i, v in ipairs(code_list) do
			local dis = get_distance(v, begain_pos)
			if dis < min_dis then
				min_dis = dis
				begain_code_list = {}
			end

			if dis == min_dis then
				begain_code_list[#begain_code_list + 1] = v
			end
		end

		sort_list(begain_code_list)
		local last_code = begain_code_list[1]
		begain_pos = {last_code[1], last_code[2], last_code[3]}
	else
		begain_pos = {code_list[1][1], code_list[1][2], code_list[1][3]}
	end
	sort_list(code_list)

	
	if World2In1.CodeEditor == nil then
		local SkySpacePairBlock = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BlockPositionAllocations/SkySpacePairBlock.lua");
		local block_pos = SkySpacePairBlock:new()
		block_pos.start_x = 19136
		block_pos.start_y = 250
		block_pos.start_z = 19263
		
		World2In1.CodeEditor = Editor:new():onInit(block_pos);
	end
	local editor = World2In1.CodeEditor

	local editor_list = {}
	for index, v in ipairs(code_list) do
		local code = v[6] or {}
		for i2, v2 in ipairs(code) do
			if v2.name == "cmd" then
				local cmd_data = v2[1]
				if(cmd_data) then
					local cmd
					if(type(cmd_data) == "string") then
						cmd = cmd_data
					elseif(type(cmd_data) == "table" and type(cmd_data[1]) == "string") then
						cmd = cmd_data[1]
					end

					if cmd then
						local node, code_component, movieclip_component = editor:createBlockCodeNode();
						if code.attr and code.attr.displayName then
							if code_component then
								code_component.Name = code.attr.displayName;
								local entity = code_component:getEntity()
								if entity then
									entity:SetDisplayName(code_component.Name)
								end
							end

							if movieclip_component then
								movieclip_component.Name = code.attr.displayName;
							end

							
						end
						if code_component then
							code_component:setCode(cmd)
							code_component:run()
						end
						editor_list[#editor_list + 1] = editor						
					end
				end
			end
		end
	end

	-- local editor = Editor:new():onInit();
	-- local node, code_component, movieclip_component = editor:createBlockCodeNode();
	-- if code_component then
	-- 	code_component:setCode("")
	-- 	code_component:run()
	-- end

	-- BlockEngine:SetBlock(19200,250,19200, 0);
	-- BlockEngine:SetBlock(19200,250,19201, 0);
end