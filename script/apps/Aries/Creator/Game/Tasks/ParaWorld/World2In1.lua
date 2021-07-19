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
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
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

World2In1.ServerWorldData = {}
function World2In1.OnInit()
	page = document:GetPageCtrl();
	page_root = page:GetParentUIObject()
end

function World2In1.ShowPage(offset, reload)
	offset = offset or 0;
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
		World2In1.OnEnterCourseRegion();
		
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

	-- World2In1.UnLoadcurrentWorldList()
	GameLogic.GetCodeGlobal():BroadcastTextEvent("changeRegionType")
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

function World2In1.GotoCreateRegion(pos)
	World2In1.EndLoadTimer();
	World2In1UserInfo.ShowPage(nil);
	GameLogic.RunCommand("/mode edit");
	World2In1.SetCurrentType("creator")
	World2In1.BroadcastTypeChanged()
	World2In1.ShowCreateReward(true)	
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

	lock_timer = lock_timer or commonlib.Timer:new({callbackFunc = function(timer)
		local player = EntityManager.GetPlayer()
		local x, y, z = player:GetBlockPos();
		local minX, minY, minZ = 19136, 12, 19136;
		local maxX = minX+128;
		local maxZ = minZ+128;
		local newX = math.min(maxX-5, math.max(minX+4, x));
		local newZ = math.min(maxZ-5, math.max(minZ+4, z));
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
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/WorldCreatePage.lua").Show();
	--GameLogic.GetCodeGlobal():BroadcastTextEvent("gotoCreate");	
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
			GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.macro.task", { from = "macrosave",  name = "clicksave",});
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
		
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, 
			params = params,
			exportReferencedFiles = true,
			blocks = blocks})
		task:Run();
	
		GameLogic.GetFilters():apply_filters("cellar.sync.sync_main.sync_to_data_source_by_world_name", creatorWorldName, function(res)
			if (res) then
			end
		end);	
	end
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
			else
				World2In1UserInfo.ShowPage(nil);
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