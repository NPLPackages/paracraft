--[[
Title: EasyHomeBuilder
Author: pbb
Date: 2025-11-13
Desc: 简化家园创建系统
Use Lib:
    local EasyHomeBuilder = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyHomeBuilder.lua")
    EasyHomeBuilder.CheckMyHomeExist()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
local EasyMyCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMyCheckPoint.lua");
local EasyHomeBuilder = NPL.export()
local page
local pageName = "@world"
local pageKey = "homeBuilder"

EasyHomeBuilder.selectSlotIndex = -1
-- 初始化
function EasyHomeBuilder.OnInit()
    page = document:GetPageCtrl()
    page.OnClose = EasyHomeBuilder.OnClose
end

function EasyHomeBuilder.OnClose()
    EasyHomeBuilder.SetUserExternalyControl(false)
    GameLogic.GetFilters():apply_filters('requestHideUI',false)
    GameLogic.RunCommand("/show player")
end

function EasyHomeBuilder.LoadHomeCheckPoints()
    EasyHomeBuilder.checkPointDatas = EasyHomeBuilder.checkPointDatas or {}
    EasyHomeBuilder.checkPointDatasBySubTag = EasyHomeBuilder.checkPointDatasBySubTag or {}
    local allEntities = GameLogic.EntityManager.FindEntitiesByClassName("LiveModel");
    local checkAsset = "character/CC/05effect/fireglowingcircle.x"
    for _, entity in ipairs(allEntities) do
        local modelUrl = entity:GetModelFile()
        if modelUrl and modelUrl == checkAsset then
            local actionname = entity:GetStaticTag("actionname")
            local subTag = entity:GetStaticTag("subtag")
            local isAllowSetAsHome = entity:GetStaticTag("isAllowSetAsHome") == "true"
            local spawnRelativePosStr = entity:GetStaticTag("spawnRelativePos") or "0,0,0"
            local spawnFacingStr = entity:GetStaticTag("spawnFacing") or "0"
            local editableRegionStr = entity:GetStaticTag("editableRegion") or ""
            local bx,by,bz = entity:GetBlockPos()
            if actionname and subTag and isAllowSetAsHome and not EasyHomeBuilder.checkPointDatasBySubTag[subTag]  then
                local tempData = {
                    displayName = actionname,
                    name = subTag,
                    subTag = subTag,
                    isAllowSetAsHome = isAllowSetAsHome,
                    spawnRelativePos = spawnRelativePosStr,
                    spawnFacing = spawnFacingStr,
                    editableRegion = editableRegionStr,
                    pos = {bx,by,bz},
                    filename = "blocktemplates/"..subTag..".blocks.xml"
                }
                EasyHomeBuilder.checkPointDatasBySubTag[subTag] = tempData
                EasyHomeBuilder.checkPointDatas[#EasyHomeBuilder.checkPointDatas + 1] = tempData
            end
        end
    end
end

function EasyHomeBuilder.GetHomeIndexBySubTag(subTag)
    if EasyHomeBuilder.checkPointDatas then
        for index, data in ipairs(EasyHomeBuilder.checkPointDatas) do
            if data.subTag == subTag then
                return index
            end
        end
    end
    return -1
end

function EasyHomeBuilder.Show(bShowUI)
    if not bShowUI then
        return
    end
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyHomeBuilder.html",
        name = "EasyHomeBuilder.Show",
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = true,
        enable_esc_key = false,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 0,
        directPosition = true,
        click_through = true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
    }
    EasyHomeBuilder.SetUserExternalyControl(true)
    local currentHomeIndex = EasyHomeBuilder.selectSlotIndex > 0 and EasyHomeBuilder.selectSlotIndex or 1
    EasyHomeBuilder.SetCurrentHomeIndex(currentHomeIndex)
    GameLogic.GetFilters():apply_filters('requestHideUI',true)
    System.App.Commands.Call("File.MCMLWindowFrame", params)
    GameLogic:Disconnect("WorldUnloaded", EasyHomeBuilder, EasyHomeBuilder.OnWorldUnload, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", EasyHomeBuilder, EasyHomeBuilder.OnWorldUnload, "UniqueConnection");
end

function EasyHomeBuilder.OnWorldUnload()
    EasyHomeBuilder.selectSlotIndex = -1
    EasyHomeBuilder.checkPointDatas = nil
    EasyHomeBuilder.checkPointDatasBySubTag = nil
end

function EasyHomeBuilder.GetStoreUtil()
    if not EasyHomeBuilder.storeUtil then
        EasyHomeBuilder.storeUtil = GameLogic.PersonalPageStore
    end
    return EasyHomeBuilder.storeUtil
end

-- @param callback: function(isExist, numberOfHomes)
-- @return: number of home points
function EasyHomeBuilder.CheckMyHomeExist(callback, bShowUI)
    EasyHomeBuilder.LoadHomeCheckPoints()
    local numberOfHomes = EasyHomeBuilder.checkPointDatas and #EasyHomeBuilder.checkPointDatas or 0
    if numberOfHomes == 0 then
        if callback then
            callback(false, numberOfHomes)
        end
        return false
    end
    
    local storeUtil = EasyHomeBuilder.GetStoreUtil()
    storeUtil:RefreshPageData(pageName)
    storeUtil:LoadPageData(pageName, pageKey,function(data)
        if data and type(data) == "table" then
            EasyHomeBuilder.homeBuilderData = data
            local subTag = EasyHomeBuilder.homeBuilderData.subtag
            if subTag and subTag ~= "" and EasyHomeBuilder.CheckSubtagIsHome(subTag) then
                if callback then
                    callback(true, numberOfHomes)
                end
                LOG.std(nil,"info","EasyHomeBuilder","CheckMyHomeExist is exist %s", commonlib.serialize(EasyHomeBuilder.homeBuilderData))
                if bShowUI then
                    EasyHomeBuilder.LoadMyHomeCheckpoint()
                end
            else
                if callback then
                    callback(false, numberOfHomes)
                end
                EasyHomeBuilder.Show(bShowUI)
                LOG.std(nil,"info","EasyHomeBuilder","CheckMyHomeExist home data is not exist %s", commonlib.serialize(EasyHomeBuilder.homeBuilderData))
            end
        else
            if callback then
                callback(false, numberOfHomes)
            end
            EasyHomeBuilder.Show(bShowUI)
            LOG.std(nil,"info","EasyHomeBuilder","CheckMyHomeExist home checkpoint is not created")
        end
    end)
    return numberOfHomes;
end

function EasyHomeBuilder.CheckServerHomeExist(modelId)
    if not EasyHomeBuilder.homeBuilderData or not EasyHomeBuilder.homeBuilderData.id or EasyHomeBuilder.homeBuilderData.id ~= modelId then
        return false
    end
    return true
end

function EasyHomeBuilder.DeleteMyHome(modelId)
    EasyHomeBuilder.CheckMyHomeExist(function(bExist, numberOfHomes)
        if not bExist or numberOfHomes == 0 then
            return
        end
        local homeBuilderData = EasyHomeBuilder.homeBuilderData
        if not homeBuilderData or not homeBuilderData.id or homeBuilderData.id ~= modelId then
            return
        end
        local storeUtil = EasyHomeBuilder.GetStoreUtil()
        storeUtil:DeletePageData(pageName, pageKey,true)
        EasyHomeBuilder.homeBuilderData = nil
        LOG.std(nil,"info","EasyHomeBuilder","DeleteMyHome %d", homeBuilderData.id)
    end)
end

function EasyHomeBuilder.LoadMyHomeCheckpoint()
    local homeBuilderData = EasyHomeBuilder.homeBuilderData
    if not homeBuilderData or not homeBuilderData.id then
        return
    end
    local subTag = homeBuilderData.subtag
    local slotIndex =  homeBuilderData.slotIndex
    if not slotIndex or not subTag then
        return
    end
    EasyHomeBuilder.LoadWorldSlot(slotIndex, subTag)
end

function EasyHomeBuilder.LoadWorldSlot(slotIndex, subTag)
    if not slotIndex or not subTag then
        return
    end
    EasyEditableWorld:new({operation="Load", subTag=subTag, worldName = nil, slotIndex = slotIndex}):Run()
    local instance = EasyEditableWorld.GetInstance()
    if instance then
        instance:ShowPage(false);
        local loadIndex = nil
        for index, slot in ipairs(EasyEditableWorld.LocalWorlds_DS) do
            if slot.slotIndex == slotIndex then
                loadIndex = index
                break
            end
        end
        if loadIndex then
            EasyEditableWorld.LoadOrSaveSlot(loadIndex, "Load", false);
            return true
        end
    end
end

function EasyHomeBuilder.CheckSubtagIsHome(subTag)
    EasyHomeBuilder.LoadHomeCheckPoints()
    for _, data in ipairs(EasyHomeBuilder.checkPointDatas) do
        if data.subTag == subTag then
            return true
        end
    end
    return false
end

function EasyHomeBuilder.SetUserExternalyControl(isExternal)
    local player = GameLogic.GetPlayer()
    if player then
        local isExternalControl = player:IsControlledExternally()
        if isExternalControl ~= isExternal then
            player:SetControlledExternally(isExternal)
        end
    end
end

function EasyHomeBuilder.SetCurrentHomeIndex(index)
    if not index or index < 1 or index > #EasyHomeBuilder.checkPointDatas then
        return
    end
    local preIndex = EasyHomeBuilder.selectSlotIndex
    EasyHomeBuilder.selectSlotIndex = index
    EasyHomeBuilder.RefreshPage()
    EasyHomeBuilder.LoadHomeData(preIndex)
end

function EasyHomeBuilder.LoadHomeData(preIndex)
    if preIndex then
        EasyHomeBuilder.UnloadReadonlyTemplate(preIndex)
    end
    local index = EasyHomeBuilder.selectSlotIndex
    EasyHomeBuilder.LoadReadonlyTemplate(index)
end

function EasyHomeBuilder.AddReadonlyBlockTemplate(filename, pos, subtag)
	EasyHomeBuilder.readonlyBlockTemplates = EasyHomeBuilder.readonlyBlockTemplates or {}
	EasyHomeBuilder.subtagToFilename = EasyHomeBuilder.subtagToFilename or {}
	if subtag then
		local existingFilename = EasyHomeBuilder.subtagToFilename[subtag]
		if existingFilename and existingFilename ~= filename then
			EasyHomeBuilder.RemoveReadonlyBlockTemplate(existingFilename)
		end
		EasyHomeBuilder.subtagToFilename[subtag] = filename
	end
	
	if(not EasyHomeBuilder.readonlyBlockTemplates[filename]) then
		EasyHomeBuilder.readonlyBlockTemplates[filename] = true;

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
        local params = {operation = BlockTemplate.Operations.Load, 
            filename = filename, 
			blockX = (pos and pos[1]) or 0, 
            blockY = (pos and pos[2]) or 0, 
            blockZ = (pos and pos[3]) or 0, 
            UseAbsolutePos = false, 
            nohistory = true, 
			TeleportPlayer = false, 
			keepEntityReferences = true,
		}
		local task = BlockTemplate:new(params)
		if(task:Run()) then	
			
			EasyHomeBuilder.readonlyBlockTemplates[filename] = task.entity_references or true;
		end
	end

	return EasyHomeBuilder.readonlyBlockTemplates[filename];
end

function EasyHomeBuilder.RemoveReadonlyBlockTemplate(filename, pos, subtag)
	EasyHomeBuilder.readonlyBlockTemplates = EasyHomeBuilder.readonlyBlockTemplates or {}
	if(EasyHomeBuilder.readonlyBlockTemplates[filename]) then
		local entity_references = EasyHomeBuilder.readonlyBlockTemplates[filename]
		EasyHomeBuilder.readonlyBlockTemplates[filename] = nil;
		
		if EasyHomeBuilder.subtagToFilename then
			for subtag, mappedFilename in pairs(EasyHomeBuilder.subtagToFilename) do
				if mappedFilename == filename then
					EasyHomeBuilder.subtagToFilename[subtag] = nil
					break
				end
			end
		end
		local cx,cy,cz = (pos and pos[1]) or 0, (pos and pos[2]) or 0, (pos and pos[3]) or 0
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.LoadToMemory, filename = filename, 
				blockX = cx, blockY = cy, blockZ = cz, })
		if(task:Run()) then
			local loadedBlocks = task.blocks or {}
			for _, b in ipairs(loadedBlocks) do
				local bx, by, bz = b[1] + cx, b[2] + cy, b[3] + cz
                GameLogic.BlockEngine:SetBlockToAir(bx, by, bz);
			end
			if(type(entity_references) == "table" and #entity_references > 0) then
				for _, entity in ipairs(entity_references) do
					if entity then
						entity:Destroy();
					end
				end
			end
		end
	end
end

function EasyHomeBuilder.ChangeHomeData(newData)
    if not newData or not newData.id then
        return false
    end
    local buiderData
    if not EasyHomeBuilder.homeBuilderData then
        buiderData = newData
    elseif newData.id ~= EasyHomeBuilder.homeBuilderData.id then
        buiderData = newData
    else
        GameLogic.AddBBS(nil, "家园已存在")
        return false
    end
    newData.isMineHome = true
    EasyHomeBuilder.homeBuilderData = {
        id = buiderData.id,
        size = buiderData.size,
        subtag = buiderData.subtag,
        slotIndex = buiderData.slotIndex,
        modelUrl = buiderData.modelUrl,
        tag = buiderData.tag,
        filename = string.format("%s.%s.blocks.xml", buiderData.slotIndex, buiderData.subtag),
        userId = buiderData.userId,
        updateAt = buiderData.updateAt,
    }
    local storeUtil = EasyHomeBuilder.GetStoreUtil()
    storeUtil:SavePageData(pageName, pageKey, EasyHomeBuilder.homeBuilderData,true)
    return true
end

function EasyHomeBuilder.IsVisible()
    return page and page:IsVisible()
end

function EasyHomeBuilder.RefreshPage()
    if page then
        page:Refresh(0.01)
    end
end

function EasyHomeBuilder.Close()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function EasyHomeBuilder.OnClickBuild()
    local home = EasyHomeBuilder.GetHomeByIndex(EasyHomeBuilder.selectSlotIndex)
    if home then
        local subTag = home.subTag
        EasyHomeBuilder.GetUsedSlotIndex(subTag,function(slotIndex)
            if slotIndex and slotIndex > 0 then
                _guihelper.MessageBox(L'你确定要选择这里作为你的家园么？ 抱抱龙会帮你在当前位置创建一个基础家园，是否继续？',
                    function(res)
                        if res and res == _guihelper.DialogResult.Yes then
                            EasyHomeBuilder.UnloadReadonlyTemplate(EasyHomeBuilder.selectSlotIndex)
                            local result = EasyHomeBuilder.LoadWorldSlot(slotIndex, subTag)
                            if result then
                                EasyHomeBuilder.lastLoadedSlotIndex = slotIndex
                                GameLogic.GetFilters():add_filter("EasyEditableWorldStatusChanged", EasyHomeBuilder.WorldStatusChanged);
                            end
                            EasyHomeBuilder.Close()
                        end
                    end,
                    _guihelper.MessageBoxButtons.YesNo,nil,nil,nil,nil,{is_hide_close=true})
            end
        end)
    end
end

function EasyHomeBuilder.WorldStatusChanged(status, filename, displayName, stats)
    if status == "Synced" then
        local home = EasyHomeBuilder.GetHomeByIndex(EasyHomeBuilder.selectSlotIndex)
        if home and EasyHomeBuilder.lastLoadedSlotIndex then
            local remoteData = EasyMyCheckPoint.GetRemoteModelBySlotIndex(EasyHomeBuilder.lastLoadedSlotIndex, home.subTag)
            if remoteData then
                remoteData.slotIndex = EasyHomeBuilder.lastLoadedSlotIndex
                EasyHomeBuilder.ChangeHomeData(remoteData)
            end
            EasyHomeBuilder.lastLoadedSlotIndex = nil
        end
        GameLogic.GetFilters():remove_filter("EasyEditableWorldStatusChanged", EasyHomeBuilder.WorldStatusChanged);
    end
    return status, filename, displayName, stats
end

function EasyHomeBuilder.OnClickNext()
    local index = EasyHomeBuilder.selectSlotIndex
    index = index + 1
    if index > #EasyHomeBuilder.checkPointDatas then
        index = 1
    end
    EasyHomeBuilder.SetCurrentHomeIndex(index)
end

function EasyHomeBuilder.OnClickPrev()
    local index = EasyHomeBuilder.selectSlotIndex
    index = index - 1
    if index < 1 then
        index = #EasyHomeBuilder.checkPointDatas
    end
    EasyHomeBuilder.SetCurrentHomeIndex(index)
end

function EasyHomeBuilder.GetHomeByIndex(index)
    if not EasyHomeBuilder.checkPointDatas then return nil end
    return EasyHomeBuilder.checkPointDatas[index]
end

function EasyHomeBuilder.ComputeTemplatePosByHome(home)
    if not home or not home.pos then return nil end
    local bx,by,bz = unpack(home.pos)
    local nums = {}
    for n in (home.editableRegion or ""):gmatch("%-?%d+") do
        nums[#nums+1] = tonumber(n)
    end
    if #nums >= 6 then
        local rx, ry, rz = nums[1], nums[2], nums[3]
        local dx, dy, dz = nums[4], nums[5], nums[6]
        local min_x = bx + rx
        local min_y = by + ry
        local min_z = bz + rz
        local cx = math.floor(min_x + dx / 2)
        local cy = math.floor(min_y + dy / 2)
        local cz = math.floor(min_z + dz / 2)
        return {cx, cy + 1, cz}
    else
        return {bx + (nums[1] or 0), by + (nums[2] or 0) + 1, bz + (nums[3] or 0)}
    end
end

function EasyHomeBuilder.ComputePlayerPosByHome(home)
    if not home or not home.pos then return nil end
    local bx,by,bz = unpack(home.pos)
    local parts = {}
    for part in string.gmatch((home.spawnRelativePos or ""), "[^,]+") do
        part = math.floor(tonumber(part) or 0)
        table.insert(parts, part)
    end
    if #parts < 3 then
        return {bx, by + 1, bz}
    end
    local dx = parts[1]
    local dy = parts[2]
    local dz = parts[3]
    local px = bx + dx
    local py = by + dy
    local pz = bz + dz
    return {px, py + 1, pz}
end

function EasyHomeBuilder.LoadReadonlyTemplate(index)
    local home = EasyHomeBuilder.GetHomeByIndex(index)
    if not home then return end
    local templatePos = EasyHomeBuilder.ComputeTemplatePosByHome(home)
    local playerPos = EasyHomeBuilder.ComputePlayerPosByHome(home)
    local newFilename = home.filename
    local prevFilename = EasyHomeBuilder.loadedTemplateFilename
    local prevPos = EasyHomeBuilder.currentTemplatePos
    local samePos = prevPos and templatePos and prevPos[1] == templatePos[1] and prevPos[2] == templatePos[2] and prevPos[3] == templatePos[3]
    if prevFilename and (prevFilename ~= newFilename or not samePos) then
        EasyHomeBuilder.RemoveReadonlyBlockTemplate(prevFilename, prevPos)
    end
    if playerPos then
        GameLogic.RunCommand(string.format("/goto %d %d %d", unpack(playerPos)))
        GameLogic.RunCommand(string.format("/lookat %d %d %d", unpack(templatePos)))
    else
        GameLogic.RunCommand(string.format("/goto %d %d %d", unpack(templatePos)))
    end
    GameLogic.RunCommand("/hide player")
    commonlib.TimerManager.SetTimeout(function()
        EasyHomeBuilder.AddReadonlyBlockTemplate(newFilename, templatePos, home.name)
        EasyHomeBuilder.loadedTemplateFilename = newFilename
        EasyHomeBuilder.currentTemplatePos = templatePos
        EasyHomeBuilder.loadedTemplateIndex = index
    end, 1000)
end

function EasyHomeBuilder.UnloadReadonlyTemplate(index)
    local home = EasyHomeBuilder.GetHomeByIndex(index)
    local filename = home and home.filename or EasyHomeBuilder.loadedTemplateFilename
    if filename then
        local pos = EasyHomeBuilder.ComputeTemplatePosByHome(home)
        EasyHomeBuilder.RemoveReadonlyBlockTemplate(filename, pos)
        if EasyHomeBuilder.loadedTemplateFilename == filename then
            EasyHomeBuilder.loadedTemplateFilename = nil
            EasyHomeBuilder.currentTemplatePos = nil
            EasyHomeBuilder.loadedTemplateIndex = nil
        end
    end
end

function EasyHomeBuilder.GetServerDataBySubtag(subTag,callback)
    if not subTag or subTag == "" then 
        return nil 
    end
    EasyMyCheckPoint.LoadRemoteData(subTag,function(success)
        if success then
            remoteDatas = EasyMyCheckPoint.remoteModels or {}
            if callback then
                callback(remoteDatas)
            end
        end
    end)
end

function EasyHomeBuilder.GetLocalDataBySubtag(subTag)
    if not subTag or subTag == "" then 
        return nil 
    end
     local editableWorld = GameLogic.CreateGetEditableWorld();
     if editableWorld then
         local slots = editableWorld:GetLocalWorldSlots(nil,subTag);
         return slots
     end
end

function EasyHomeBuilder.GetUsedSlotIndex(subTag,callback)
    local localSlots = EasyHomeBuilder.GetLocalDataBySubtag(subTag)
    EasyHomeBuilder.GetServerDataBySubtag(subTag,function(remoteDatas)
        local allModels = {}
        for _,v in pairs(remoteDatas) do
            if v.serverSlotIndex then
                allModels[v.serverSlotIndex] = v
            end
        end
        for _,v in pairs(localSlots) do
            if v.slotIndex then
                if not allModels[v.slotIndex] then
                    allModels[v.slotIndex] = v
                end
            end
        end
        local usedSlotIndex = -1
        for i =1,EasyEditableWorld.maxSlots do
            if not allModels[i] then
                usedSlotIndex = i
                break
            end
        end
        if callback then
            callback(usedSlotIndex)
        end
    end)
end

function EasyHomeBuilder.TeleportToHome()
    local homeData = EasyHomeBuilder.homeBuilderData
    if not homeData or not homeData.id or not homeData.subtag then return end
    local home = EasyHomeBuilder.checkPointDatasBySubTag[homeData.subtag]
    local templatePos = EasyHomeBuilder.ComputeTemplatePosByHome(home)
    local playerPos = EasyHomeBuilder.ComputePlayerPosByHome(home)
    if playerPos then
        GameLogic.RunCommand(string.format("/goto %d %d %d", unpack(playerPos)))
        GameLogic.RunCommand(string.format("/lookat %d %d %d", unpack(templatePos)))
    else
        GameLogic.RunCommand(string.format("/goto %d %d %d", unpack(templatePos)))
    end
    return true
end