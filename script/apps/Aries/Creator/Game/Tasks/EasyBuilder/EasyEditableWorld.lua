--[[
Title: EasyBuilder Editable World Task
Author(s): LiXizhi
Date: 2025/09/26
Desc: Easy world editing and management tool that provides:
- World save/load functionality using EditableWorld
- Simple interface to manage saved world slots

GameLogic.GetFilters():apply_filters("EasyEditableWorldSlotFilenameChanged", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", status, EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
EasyEditableWorld:new({operation="Load", worldName = nil, onFinishCallback}):Run();
EasyEditableWorld:new({operation="Save", subTag="", worldName = nil, slotIndex = nil}):Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/EditableWorld.lua");
NPL.load("(gl)script/ide/System/Windows/Application.lua");
local Application = commonlib.gettable("System.Windows.Application");
local EasyMyCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMyCheckPoint.lua");
local EasyHomeBuilder = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyHomeBuilder.lua")
local EnterConfirm = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EnterConfirm.lua")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EditableWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.EditableWorld");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager")
local EasyEditableWorld = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld"));

local curInstance;
local page;

-- Always a top level task
EasyEditableWorld.is_top_level = true;
EasyEditableWorld.LocalWorlds_DS = {};
EasyEditableWorld.maxSlots = 20;
EasyEditableWorld.currentSlotFilename = nil; -- Current selected slot filename for highlighting
EasyEditableWorld.subTag = nil;
EasyEditableWorld.maxAllowedEntityCount = 300; -- nil to be unlimited
EasyEditableWorld.delayQuickSaveSeconds = 3; -- delay seconds for quick save after last edit
EasyEditableWorld.delayUploadSeconds = 30; -- delay seconds for uploading to server after last quick save
EasyEditableWorld.autoEnterWhenCollide = false;

-- Get locally saved world slots using EditableWorld
function EasyEditableWorld.GetLocalWorldsDS()
    local local_worlds = {};    
    
    -- Get saved world slots from EditableWorld
    local editableWorld = GameLogic.CreateGetEditableWorld();
    local savedSlots = {};
    
    if editableWorld then
        local slots = editableWorld:GetLocalWorldSlots();
        
        -- Create a lookup table for saved slots
        for i, slot in ipairs(slots) do
            savedSlots[i] = slot;
        end
    end
    local subTag = EasyEditableWorld.subTag
    if(subTag == "") then
        subTag = nil;
    end
    -- Create slots up to maxSlots, filling in saved data where available
    local usedSlotIndices = {}; -- Track used slot indices
    
    -- First pass: add all saved slots and track their indices
    for i = 1, #savedSlots do
        local slot = savedSlots[i];
        if((not subTag and slot.filesize > 0) or EasyEditableWorld.subTag == slot.subTag) then
            local index = #local_worlds + 1;
            local_worlds[index] = {
                slotIndex = slot.slotIndex,
                name = "slot_" .. slot.slotIndex,
                displayname = (L"存档 " .. slot.slotIndex),
                filename = slot.filename,
                filesize = slot.filesize,
                writedate = slot.writedate,
                writedateNumber = slot.writedate and commonlib.timehelp.GetNumberFromDateString(slot.writedate),
                subTag = slot.subTag or "",
            };
            if(slot.slotIndex == 0) then
                local_worlds[index].displayname = L"默认存档";
            end
            usedSlotIndices[slot.slotIndex] = true;
        end
    end
    -- Sort local_worlds by writedateNumber (newest first), then by slotIndex if dates are the same
    table.sort(local_worlds, function(a, b)
        if a.writedateNumber and b.writedateNumber then
            if a.writedateNumber ~= b.writedateNumber then
                return a.writedateNumber > b.writedateNumber
            else
                return a.slotIndex < b.slotIndex
            end
        elseif a.writedateNumber then
            return true
        elseif b.writedateNumber then
            return false
        else
            return a.slotIndex < b.slotIndex
        end
    end)
    
    -- Second pass: add empty slots with unique indices
    local curIndex = 1;
    local maxSlots = math.max(EasyEditableWorld.maxSlots, #local_worlds + 1);
    while #local_worlds < EasyEditableWorld.maxSlots do
        -- Find next unused slot index
        while usedSlotIndices[curIndex] do
            curIndex = curIndex + 1;
        end
        
        local index = #local_worlds + 1;
        local_worlds[index] = {
            index = index,
            name = "slot_" .. curIndex,
            slotIndex = curIndex,
            displayname = L"空存档 " .. curIndex,
            filename = nil,
            filesize = nil,
            writedate = nil,
            subTag = subTag or "",
        };
        
        usedSlotIndices[curIndex] = true;
        curIndex = curIndex + 1;
    end
    
    -- add index and Find the most recently updated slot
    local mostRecentTime;
    local mostRecentIndex = nil;
    for i, world in ipairs(local_worlds) do
        if world.writedateNumber and (not mostRecentTime or world.writedateNumber > mostRecentTime) then
            mostRecentTime = world.writedateNumber;
            mostRecentIndex = world.slotIndex;
        end
        world.index = i;
    end
    EasyEditableWorld.mostRecentUpdatedSlotIndex = mostRecentIndex or 1;
    return local_worlds;
end

function EasyEditableWorld:ctor()
end


function EasyEditableWorld.DS_SavedWorldItems(index)
    if(index == nil) then
        return #EasyEditableWorld.LocalWorlds_DS;
    else
        return EasyEditableWorld.LocalWorlds_DS[index];
    end
end

function EasyEditableWorld.DS_RestoreWorldItems(index)
    if(index == nil) then
        local worldName = curInstance and curInstance.worldName;
        EasyEditableWorld.RestoreWorlds_DS = GameLogic.CreateGetEditableWorld():GetRestoreWorldSlots(worldName);
        return #EasyEditableWorld.RestoreWorlds_DS;
    else
        return EasyEditableWorld.RestoreWorlds_DS[index];
    end
end

function EasyEditableWorld.GetInstance()
    return curInstance;
end

-- follow EditLightTask: keep a static InitPage(Page)
function EasyEditableWorld.InitPage(Page)
    page = Page;
end

function EasyEditableWorld:Redo()
end

function EasyEditableWorld:Undo()
end

-- follow EditLightTask lifecycle
function EasyEditableWorld:Run()
    curInstance = self;
    -- Refresh the data each time it's accessed
    if(self.subTag == "all") then
        self.subTag = nil;
    end
    EasyEditableWorld.subTag = self.subTag;
    EasyEditableWorld.LocalWorlds_DS = EasyEditableWorld.GetLocalWorldsDS();
    EasyEditableWorld.mode = self.operation or "Load"; -- "Load" or "Save"
    GameLogic.DisableSaveWorldTip()

    if(EasyEditableWorld.mode == "ForceLoadIfNot") then
        if(EasyEditableWorld.currentSlotFilename) then
            EasyEditableWorld.Cancel()
            return
        end
    end
    EasyEditableWorld.CheckQuickSave();
    self:ShowPage(true);
end

function EasyEditableWorld:OnExit()
    EasyEditableWorld.Cancel()
end
function EasyEditableWorld.Cancel()
    local self = curInstance;
    if(curInstance) then
        if(self.onFinishCallback) then
            self.onFinishCallback(EasyEditableWorld.currentSlotFilename);
        end
        self:ShowPage(false);
        self:SetFinished();
        self:CloseWindow();
        curInstance = nil;
    end
end


function EasyEditableWorld:ShowPage(bShow)
    if(not page) then
        local width, height = 720, 500;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.html", 
                name = "EasyEditableWorld.ShowPage", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide=false, 
                style = CommonCtrl.WindowFrame.ContainerStyle,
                enable_esc_key = false,
                isTopLevel = true,
                allowDrag = false,
                -- click_through = true, 
                bShow = (bShow ~= false),
                directPosition = true,
                    align = "_ct",
                    x = -width/2,
                    y = -height/2,
                    width = width,
                    height = height,
            };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
        curInstance = curInstance or self;
        GameLogic:Connect("WorldUnloaded", EasyEditableWorld, EasyEditableWorld.OnLeaveWorld, "UniqueConnection")
        if(params._page) then
            params._page.OnClose = function()
                page = nil;
            end
        end
    else
        if(bShow == false) then
            page:CloseWindow();
        else
            page:Refresh(0.1);
        end
    end
    if(bShow) then
        if(page) then
            if(EasyEditableWorld.currentSlotFilename) then
                -- Find the index for the current filename to scroll to
                for i, worldData in ipairs(EasyEditableWorld.LocalWorlds_DS) do
                    if worldData.filename == EasyEditableWorld.currentSlotFilename then
                        page:CallMethod("tvwSaveSlots", "ScrollToRow", i);
                        break;
                    end
                end
            elseif EasyEditableWorld.mostRecentUpdatedSlotIndex then
                page:CallMethod("tvwLoadSlots", "ScrollToRow", EasyEditableWorld.mostRecentUpdatedSlotIndex);
            end
		end
    end
end

function EasyEditableWorld.OnLeaveWorld()
    EasyEditableWorld.SetCurrentSlotFilename(nil);
    EasyEditableWorld.subTag = nil;
end

function EasyEditableWorld:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyEditableWorld:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

function EasyEditableWorld.RefreshWorldData()
    if(curInstance) then
        EasyEditableWorld.LocalWorlds_DS = EasyEditableWorld.GetLocalWorldsDS();
        if(page) then
            page:CallMethod("tvwLocalWorldsSlots", "DataBind");
        end
    end
end

function EasyEditableWorld.OnClickCancel()
    if(EasyEditableWorld.currentSlotFilename) then
        EasyEditableWorld.Cancel()
    else
        if curInstance and curInstance.operation == "ForceLoadIfNot" then
            EasyEditableWorld.OnClickRestartWorld()
        else
            EasyEditableWorld.Cancel()
        end
    end
end

-- @param name: if name=="forceRestart", then no confirmation dialog, it will clear all editable scenes and readonly templates.
function EasyEditableWorld.OnClickRestartWorld(name)
    local editableWorld = GameLogic.CreateGetEditableWorld();
    if editableWorld then
        editableWorld:SetMaxLiveEntities(EasyEditableWorld.maxAllowedEntityCount)
        local function ClearCurrentWorld()
            editableWorld:RestoreToEmpty();
            editableWorld:RemoveAllReadonlyBlockTemplates()
            EasyEditableWorld.OnBeforeLoadMyEditableWorld()
            EasyEditableWorld.OnLoadMyEditableWorld()
            EasyEditableWorld.Cancel()
        end
        if(EasyEditableWorld.currentSlotFilename or name=="forceRestart") then
            local confirmMessage = L"确定要清空场景，重新开始么？";
            if EasyEditableWorld.currentDisplayName and EasyEditableWorld.currentDisplayName ~= "" then
                confirmMessage = string.format(L"确定要清空场景 %s，重新开始么？", EasyEditableWorld.currentDisplayName);
            end
            _guihelper.MessageBox(confirmMessage, function(result)
                ClearCurrentWorld()
            end);
        else
            -- Check for slot 0 autosave before clearing
           EasyEditableWorld.OnClickLoadSlot(0)
           EasyEditableWorld.Cancel()
        end
    end
end

function EasyEditableWorld.HasLoadedAnyWorld()
    return EasyEditableWorld.currentSlotFilename ~= nil;
end

function EasyEditableWorld.SetCurrentSlotFilename(filename, worldData)
    EasyEditableWorld.currentSlotFilename = filename;
    EasyEditableWorld.currentDisplayName = nil;
    EasyEditableWorld.currentSubTag = nil;
    EasyEditableWorld.currentSlotIndex = nil;
    EasyEditableWorld.currentUserPointEntity = nil;
    EasyEditableWorld.currentCheckPointEntity = nil;
    EasyEditableWorld.currentWorldData = worldData;
    
    if filename and filename ~= "" then
        local basename = filename:match("([^/\\]+)$") or filename
        local clean = basename:gsub("%.autosave$", "")
        local slot, subtag = clean:match("^(%d+)%.([^.]+)%.blocks%.xml$")
        local slotIndex = clean:match("^(%d+)%.blocks%.xml$")
        slotIndex = slotIndex or slot
        local display = ""
        if(worldData and worldData.desc and worldData.desc ~= "") then
            display = string.format("%s", worldData.desc)
        else
            if slotIndex then
                if(slotIndex == "0") then
                    display = L"默认存档"
                else
                    display = string.format(L"存档%s", slotIndex)
                end
            else
                display = string.format(L"存档%s", clean)
            end
        end
        if slot and subtag then
            local actionName = GameLogic.EditableWorld:GetActionNameFromSubtag(subtag)
            display = string.format(L"%s@%s", display, actionName or subtag)
        end
        EasyEditableWorld.currentSubTag = subtag
        EasyEditableWorld.currentDisplayName = display
        EasyEditableWorld.currentSlotIndex = tonumber(slot or slotIndex)
    end
    GameLogic.GetFilters():apply_filters("EasyEditableWorldSlotFilenameChanged", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
    GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", EasyEditableWorld.currentSlotFilename and "loaded" or "", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
end

-- Get the checkpoint entity, with caching
-- @param bForceRefresh: if true, will force refresh the cached entity
function EasyEditableWorld.GetCheckPointEntity(bForceRefresh)
    if EasyEditableWorld.currentCheckPointEntity ~= nil and not bForceRefresh then
        if EasyEditableWorld.currentCheckPointEntity == false then
            return nil;
        elseif EasyEditableWorld.currentCheckPointEntity:IsValid() then
            return EasyEditableWorld.currentCheckPointEntity;
        else
            EasyEditableWorld.currentCheckPointEntity = nil;
        end
    end
    
    if EasyEditableWorld.currentSubTag then
        local checkpointEntity = EntityManager.FindFirstEntity(function(entity)
            if(entity.class_name == "LiveModel" and entity:GetStaticTag("subtag") == EasyEditableWorld.currentSubTag) then
                return true;
            end
        end)
        if checkpointEntity then
            EasyEditableWorld.currentCheckPointEntity = checkpointEntity;
        else
            EasyEditableWorld.currentCheckPointEntity = false;
        end
    else
        EasyEditableWorld.currentCheckPointEntity = false;
    end
    
    return EasyEditableWorld.currentCheckPointEntity == false and nil or EasyEditableWorld.currentCheckPointEntity;
end

-- make sure the user point exists in the world, if not we will create one at player's feet
-- @param bCreateIfNotExists: if true, we will create one if not exists. default is true.
function EasyEditableWorld.CreateGetUserPoint(bCreateIfNotExists)
    if(EasyEditableWorld.currentUserPointEntity) then
        if(EasyEditableWorld.currentUserPointEntity:IsValid()) then
            return EasyEditableWorld.currentUserPointEntity;
        else
            EasyEditableWorld.currentUserPointEntity = nil;
        end
    end

    local editableWorld = GameLogic.CreateGetEditableWorld();
    if editableWorld then
        editableWorld:ForEachLiveEntity(function(entity)
            if entity.class_name == "EntityUserPoint" then
                -- TODO: shall we also check for userid if there are multiple user points
                entity:SetCanDrag(false)
                EasyEditableWorld.currentUserPointEntity = entity;
                return true; -- Stop iteration
            end
        end)

        if(EasyEditableWorld.currentUserPointEntity == nil and bCreateIfNotExists ~= false) then
            local player = GameLogic.GetPlayer();
            if(player) then
                local x, y, z = player:GetPosition();
                NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityUserPoint.lua");
                local EntityUserPoint = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityUserPoint");
                local entity = EntityUserPoint:new():init();
                entity:SetPosition(x, y, z);
                entity:SetPersistent(true);
                entity:SetCanDrag(false)
                entity:Attach();
                if(editableWorld:AddLiveEntity(entity)) then
                    EasyEditableWorld.currentUserPointEntity = entity;
                end
            end
        end
        if(EasyEditableWorld.currentUserPointEntity and EasyEditableWorld.currentSubTag) then
            local checkpointEntity = EasyEditableWorld.GetCheckPointEntity();
            if(checkpointEntity) then
                local facing = checkpointEntity:GetStaticTag("spawnFacing")
                local pos = checkpointEntity:GetStaticTag("spawnRelativePos")
                if facing then
                    facing = tonumber(facing)
                    if facing then
                        EasyEditableWorld.currentUserPointEntity:SetFacing(facing)
                    end
                end
                if pos then
                    local x, y, z = pos:match("([^,]+),([^,]+),([^,]+)")
                    if x and y and z then
                        x, y, z = tonumber(x), tonumber(y), tonumber(z)
                        if x and y and z then
                            local cx, cy, cz = checkpointEntity:GetPosition()
                            EasyEditableWorld.currentUserPointEntity:SetPosition(cx + x, cy + y, cz + z)
                        end
                    end
                end
            end
        end
        return EasyEditableWorld.currentUserPointEntity;
    end
end

function EasyEditableWorld.UpdateUserPoint(entity)
    if(entity) then
        entity:SetUserName(System.User.username);
        entity:SetDisplayName(System.User.NickName or System.User.username);
        local text = entity:GetDisplayName();
        local name;
        if(EasyEditableWorld.currentWorldData and (EasyEditableWorld.currentWorldData.desc or "") ~= "") then
            name = EasyEditableWorld.currentWorldData.desc
        end
        if(name == nil or name == L"未命名") then
            local oldName = entity:GetCommand();
            if(oldName and oldName ~= "") then
                name = oldName:match("^(.-)\n") or oldName;
            else
                name = L"未命名"
            end
        end
        text = name.."\n"..text;
        local worldId = EasyEditableWorld.currentWorldData and EasyEditableWorld.currentWorldData.id;
        if(worldId) then
            text = string.format("%s\n#%d", text, worldId);
        else
            text = string.format("%s\n存档%s", text, EasyEditableWorld.currentSlotIndex);
        end
        if(entity:GetCommand() ~= text) then
            entity:SetCommand(text);
            entity:Refresh();
        end
    end
end

function EasyEditableWorld.TeleportToUserPoint(entity)
    if(entity) then
        local facing = entity:GetFacing() - math.pi / 2; 
        local x, y, z = entity:GetPosition()
        -- Calculate position 1.5 meter to the left of userPoint based on its facing
        local leftFacing = facing - math.pi / 2;
        local x1, z1;
        x1 = x + math.sin(leftFacing) * 1.5;
        z1 = z + math.cos(leftFacing) * 1.5;
        

        -- Teleport player 1 meter in front of userPoint based on its facing direction
        local offsetX = math.sin(facing) * (-1);
        local offsetZ = math.cos(facing) * (-1);
        local player = GameLogic.GetPlayer()
        player:SetPosition(x1 + offsetX, y, z1 + offsetZ);
        player:SetFacing(facing - math.pi / 2);
        -- Set camera to look at the userPoint
        System.Scene.Cameras:GetCurrent():SetFacingToPosition(x1, y, z1);

        -- show pet copilot near the user point on its right. 
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
        local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
        local copilot = CopilotDragonPet.GetInstance()

        local x2, z2;
        x2 = x - math.sin(leftFacing) * 1.5;
        z2 = z - math.cos(leftFacing) * 1.5;
        copilot:TeleportTo(x2 + offsetX, y, z2 + offsetZ)
        copilot:Show();
    end
end

function EasyEditableWorld.OnBeforeLoadMyEditableWorld()
    GameLogic.CreateGetEditableWorld():FreezeWorld(true, true);
end

function EasyEditableWorld:OnAppPause()
    if(EasyEditableWorld.HasLoadedAnyWorld()) then
        EasyEditableWorld.QuickSave()
    end
end

-- called after loading an editable world
function EasyEditableWorld.OnLoadMyEditableWorld()
    if(not EasyEditableWorld.currentSlotFilename) then
        return
    end
    Application:Connect("appPaused", EasyEditableWorld, EasyEditableWorld.OnAppPause, "UniqueConnection")

    if(EasyEditableWorld.CheckAndGotoUserPoint()) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
        local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
        local copilot = CopilotDragonPet.GetInstance()
        copilot:ClearAllTasks()
        copilot:OnLoadEditableWorld()

        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotLandKeeper.lua");
        local CopilotLandKeeper = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotLandKeeper");
        local copilotland = CopilotLandKeeper.GetInstance()
        copilotland:ClearAllTasks()
        copilotland:TurnTo()
        copilotland:OnLoadEditableWorld()
        
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
        local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
        CopilotManager.GetInstance():Register(copilot);
        CopilotManager.GetInstance():Register(copilotland);

        GameLogic.GetCodeGlobal():BroadcastTextEvent("EasyEditableWorld.OnLoadEditableWorld");
    end
    if(not GameLogic.IsReadOnly()) then
        GameLogic:Connect("beforeWorldSaved", EasyEditableWorld, EasyEditableWorld.OnBeforeWorldSave, "UniqueConnection");
    end
end

-- quick save and remove all loaded editable worlds and readonly block templates
function EasyEditableWorld.UnloadAllWorlds()
    EasyEditableWorld.Cancel()
    local editableWorld = GameLogic.CreateGetEditableWorld();
    if editableWorld then
        if(EasyEditableWorld.HasLoadedAnyWorld()) then
           EasyEditableWorld.QuickSave()
        end
        editableWorld:RestoreToEmpty();
        editableWorld:RemoveAllReadonlyBlockTemplates()
        EasyEditableWorld.SetCurrentSlotFilename(nil);
    end
    GameLogic.CreateGetEditableWorld():FreezeWorld(false, true);
end

function EasyEditableWorld.OnBeforeWorldSave()
    if(not EasyEditableWorld.currentSlotFilename) then
        return
    end
    local editableWorld = GameLogic.CreateGetEditableWorld();
    if editableWorld then
        EasyEditableWorld.UnloadAllWorlds()
    end
end

function EasyEditableWorld.CheckAndGotoUserPoint(bCreateIfNotExists)
    if(not EasyEditableWorld.currentSlotFilename) then
        return
    end
    local userPoint = EasyEditableWorld.CreateGetUserPoint(bCreateIfNotExists)
    if(userPoint) then
        EasyEditableWorld.UpdateUserPoint(userPoint)
        EasyEditableWorld.TeleportToUserPoint(userPoint)
        return true
    end
end

function EasyEditableWorld.LoadLocalSlot(worldData,loadFromAutoSave)
    local editableWorld = GameLogic.CreateGetEditableWorld()
    local worldName = curInstance and curInstance.worldName;
    local success
    -- make sure player is focused and not controlled externally
    local player = GameLogic.GetPlayer()
    if player then
        player:SetFocus();
        player:SetControlledExternally(false);
    end

    EasyEditableWorld.OnBeforeLoadMyEditableWorld()
    if loadFromAutoSave then
        success = editableWorld:LoadFromSlotAutoSave(worldData.slotIndex, worldName, worldData.subTag);
    else
        success = editableWorld:LoadFromWorldSlot(worldData.slotIndex, worldName, worldData.subTag);
    end
    if(success) then
        EasyEditableWorld.SetCurrentSlotFilename(worldData.filename, worldData);
        GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "loaded", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
        -- GameLogic.AddBBS(nil, string.format(L"成功加载 %s", EasyEditableWorld.currentDisplayName or ""), 2000, "0 255 0");
        EasyEditableWorld.OnLoadMyEditableWorld()
        EasyEditableWorld.editCount = 0;
    end
    return success
end

function EasyEditableWorld.LoadOrSaveSlot(index, mode, loadFromAutoSave)
    local editableWorld = GameLogic.CreateGetEditableWorld();
    local worldName = curInstance and curInstance.worldName;
    index = tonumber(index);
    mode = mode or EasyEditableWorld.mode or "Load"
    local worldData = EasyEditableWorld.LocalWorlds_DS[index or 0];
    if(not worldData) then
        worldData = {
            slotIndex = index or 0,
            subTag = "",
        };
    end
    if(index and worldData) then
        if(not worldData.filename) then
            worldData.filename = editableWorld:GetSlotFilename(worldData.slotIndex, worldName, worldData.subTag);
            -- user selected an empty slot, 
            if(not loadFromAutoSave and not ParaIO.DoesFileExist(worldData.filename)) then
                editableWorld:RestoreToEmpty();
                editableWorld:RemoveAllReadonlyBlockTemplates()
                local filename = editableWorld:SaveToWorldSlot(worldData.slotIndex, worldName, worldData.subTag);
                worldData.filename = filename;
                EasyEditableWorld.CheckAndGotoUserPoint()
                EasyEditableWorld.SetCurrentSlotFilename(worldData.filename, worldData);
                GameLogic.AddBBS(nil, L"已创建新存档", 3000, "0 255 0")
            end
        end
        
        if not loadFromAutoSave and worldData.subTag and worldData.subTag ~= "" and worldData.slotIndex then
            GameLogic.AddBBS("EasyEditableWorld", L"正在检查服务器存档，请稍候...", 5000, "0 255 255")
            EasyMyCheckPoint.CheckRemoteModelExist(worldData.slotIndex, worldData.subTag, function(exist)
                --GameLogic.AddBBS("EasyEditableWorld", exist and L"服务器存档存在" or L"服务器存档不存在", 2000, exist and "0 255 0" or "255 255 0")
                GameLogic.AddBBS("EasyEditableWorld", nil)
                LOG.std(nil, "info", "LoadOrSaveSlotWithSubTag", "slotIndex:%s, subTag:%s, exist:%s", worldData.slotIndex, worldData.subTag, exist)
                EasyEditableWorld.LoadOrSaveSlotWithSubTag(mode, worldData)
            end)
        else
            if mode == "Save" then
                -- In save mode, just select the slot
                EasyEditableWorld.editCount = 0;
                
                local success = editableWorld:SaveToWorldSlot(worldData.slotIndex, worldName, worldData.subTag);
            else
                -- In load mode, load the world
                editableWorld:SetMaxLiveEntities(EasyEditableWorld.maxAllowedEntityCount)
                local success = EasyEditableWorld.LoadLocalSlot(worldData,loadFromAutoSave)
            end
        end
        EasyEditableWorld.Cancel()
        EntityManager.GetFocus():SetControlledExternally(false);
        UndoManager.Clear();
        EasyEditableWorld.EnableAutoSave()
    end
end

function EasyEditableWorld.GetRemoteData(slotIndex, subTag)
    local remoteModel = EasyMyCheckPoint.GetRemoteModelBySlotIndex(slotIndex, subTag)
    if remoteModel and type(remoteModel) == "table" then
        return remoteModel
    end
    return nil
end

function EasyEditableWorld.LoadOrSaveSlotWithSubTag(mode, worldData)
    local editableWorld = GameLogic.CreateGetEditableWorld()
    local isEmpty = editableWorld and editableWorld:IsEmpty();
    if isEmpty and mode == "Save" then
        GameLogic.AddBBS(nil, L"当前存档未被编辑，无需保存", 2000, "255 0 0")
        return
    end
    if not worldData then
        worldData = {
            slotIndex = EasyEditableWorld.currentSlotIndex,
            subTag = EasyEditableWorld.currentSubTag,
        };
    end
    local currentSubTag = worldData.subTag
    local remoteModel = EasyEditableWorld.GetRemoteData(worldData.slotIndex, currentSubTag)
    if(remoteModel and worldData) then
        worldData.id = remoteModel.id
        worldData.desc = remoteModel.desc
    end
    if mode == "Save" then
        local worldName = curInstance and curInstance.worldName;
        local userPointEntity = EasyEditableWorld.CreateGetUserPoint(false)
        if(userPointEntity) then
            local text = userPointEntity:GetCommand()
            local desc = text:match("^(.-)\n")
            if(desc and desc ~= L"未命名") then
                worldData.desc = desc
                if(remoteModel and type(remoteModel) == "table") then
                    remoteModel.desc = desc
                end
            end
        end
        
        local filename = editableWorld:SaveToWorldSlot(worldData.slotIndex, worldName, currentSubTag); 
        local serverData = commonlib.deepcopy(worldData)
        if remoteModel and type(remoteModel) == "table" then
            commonlib.partialcopy(serverData,remoteModel)
        end
        GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "Syncing", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
        -- GameLogic.AddBBS("EasyEditableWorld", L"正在同步存档到服务器，请稍候...", 5000, "0 255 255")
        
        EasyMyCheckPoint.UploadToServer(filename, serverData, function(result)
            if result then
                EasyEditableWorld.editCount = 0;
                GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "Synced", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
                --GameLogic.AddBBS("EasyEditableWorld", L"同步服务器成功", 2000, "0 255 0")
            else
                GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "SyncFailed", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
                GameLogic.AddBBS("EasyEditableWorld", L"同步服务器失败", 2000, "255 0 0")
            end
        end)
    else
        editableWorld:RemoveReadonlyBlockTemplateBySubTag(currentSubTag)
        local serverSize = remoteModel and remoteModel.size
        local localSize = worldData and worldData.filesize
        if serverSize and localSize and serverSize == localSize then
            GameLogic.AddBBS("EasyEditableWorld", nil)
            -- load from auto save first, then from local slot
            if(EasyEditableWorld.LoadLocalSlot(worldData, true)) then
                EasyEditableWorld:TriggerAutoSave()
            else
                EasyEditableWorld.LoadLocalSlot(worldData, false)
            end
        else
            if not remoteModel or type(remoteModel) ~= "table" or not remoteModel.id then
                EasyEditableWorld.LoadLocalSlot(worldData)
                return
            end
            GameLogic.AddBBS("EasyEditableWorld", L"正在下载服务器存档，请稍候...", 5000, "0 255 255")
            GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "downloading", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
            EasyMyCheckPoint.LoadRemoteModel(remoteModel,function(result)
                if result then
                    GameLogic.AddBBS("EasyEditableWorld", nil)
                    GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "downloaded", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
                    EasyEditableWorld.LoadLocalSlot(worldData)
                else
                    --GameLogic.AddBBS("EasyEditableWorld", L"无法获取服务器存档，使用本地存档", 5000, "255 0 0")
                    GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "downloadNothing", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
                    EasyEditableWorld.LoadLocalSlot(worldData)
                end
            end)
        end
    end
end

function EasyEditableWorld.OnClickSlot(index)
    if EasyEditableWorld.mode == "Load" then
        EasyEditableWorld.OnClickLoadSlot(index);
    else
        EasyEditableWorld.LoadOrSaveSlot(index);
    end
end

function EasyEditableWorld.GetCurrentTag()
    local editableWorld = GameLogic.CreateGetEditableWorld();
    return editableWorld and editableWorld:GetDefaultWorldName()
end

function EasyEditableWorld.GetCurrentFileName()
    local editableWorld = GameLogic.CreateGetEditableWorld();
    local worldName = curInstance and curInstance.worldName;
    -- Find the world data by filename
    local worldData = nil;
    for i, data in ipairs(EasyEditableWorld.LocalWorlds_DS) do
        if data.filename == EasyEditableWorld.currentSlotFilename then
            worldData = data;
            break;
        end
    end
    local subTag = worldData and worldData.subTag;
    local slotIndex = worldData and worldData.slotIndex;
    return editableWorld and editableWorld:GetSlotFilename(slotIndex, worldName, subTag)
end

local maxWorldSize = 1
function EasyEditableWorld.UpLoadCurrentWorld(callback)
    local filename = EasyEditableWorld.GetCurrentFileName()
    if filename and filename ~= "" then
        NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
        local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
        MallManager.getInstance():UpLoadFile(filename,function(url,size)
            if callback and type(callback) == "function" then
                callback(url,size)
            end
        end,maxWorldSize,"easy_editable_world")
    else
        if callback and type(callback) == "function" then
            callback()
        end
    end
end

function EasyEditableWorld.loadWorldFromFile(filename, subtag)
    if filename and filename ~= "" then
        local editableWorld = GameLogic.CreateGetEditableWorld();
        editableWorld:LoadFromFile(filename);
    end
end 

function EasyEditableWorld.OnClickSaveSlot(index)
    local worldData = EasyEditableWorld.LocalWorlds_DS[index];
    if(EasyEditableWorld.currentSlotFilename == worldData.filename) or (not EasyEditableWorld.currentSlotFilename and (not worldData or not worldData.filename)) then
        EasyEditableWorld.LoadOrSaveSlot(index, "Save")
    else
        _guihelper.MessageBox(L"确定要覆盖此存档吗？", function(result)
            EasyEditableWorld.LoadOrSaveSlot(index, "Save")
        end);
    end
end

function EasyEditableWorld.OnClickLoadSlot(index)
    local editableWorld = GameLogic.CreateGetEditableWorld();
    local worldName = curInstance and curInstance.worldName;
    local worldData = EasyEditableWorld.LocalWorlds_DS[index];
    if(not worldData) then
        worldData = {
            slotIndex = index or 0,
            subTag = "",
        };
    end
    local subTag = worldData and worldData.subTag;
    local slotIndex = worldData and worldData.slotIndex or index or 0;
    local displayName = string.format(L"存档%d%s", slotIndex, (subTag and subTag~="") and (" - " .. subTag) or "");
    if(slotIndex == 0) then
        displayName = L"默认存档";
    end
    -- Check if there's an auto-save file for this slot
    local hasAutoSave, autosaveFilename = editableWorld:HasAutoSaveFileForSlot(slotIndex, worldName, subTag);
    
    if hasAutoSave then
        if(index == 0 or (not subTag or subTag=="")) then
            -- local slots should always load from auto-save
            EasyEditableWorld.LoadOrSaveSlot(index, "Load", true);
        else
            -- for subtag slots, we always load from the original or server version. 
            EasyEditableWorld.LoadOrSaveSlot(index, "Load", false);
        end
    else
        -- No auto-save file, check if there are unsaved edits
        local editCount = editableWorld:GetEditCount();
        if editCount > 0 then
            -- Has unsaved edits, show confirmation, this will NEVER run if auto-save is turned on
            _guihelper.MessageBox(string.format(L"确定要加载: %s 吗？未保存的内容将会丢失。", displayName), function(result)
                EasyEditableWorld.LoadOrSaveSlot(index, "Load", false);
            end);
        else
            -- No significant edits, load directly
            EasyEditableWorld.LoadOrSaveSlot(index, "Load", false);
        end
    end
end

function EasyEditableWorld.OnClickRestoreSlot(index)
    index = tonumber(index);
    if(EasyEditableWorld.currentDisplayName and index and EasyEditableWorld.RestoreWorlds_DS and EasyEditableWorld.RestoreWorlds_DS[index]) then
        local restoreData = EasyEditableWorld.RestoreWorlds_DS[index];
        local editableWorld = GameLogic.CreateGetEditableWorld();
        
        if editableWorld and restoreData.filename then
            _guihelper.MessageBox(string.format(L"恢复存档后，当前世界 %s的内容将被替换。是否继续?", EasyEditableWorld.currentDisplayName or ""), function(result)
                UndoManager.Clear();
                EasyEditableWorld.OnBeforeLoadMyEditableWorld()
                editableWorld:LoadFromFile(restoreData.filename);
                EasyEditableWorld.Cancel();
                EntityManager.GetFocus():SetControlledExternally(false);
                EasyEditableWorld.OnLoadMyEditableWorld()
            end);
        end
    end
end

function EasyEditableWorld.OnClickCloud()
    EasyEditableWorld.Cancel();
    local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
    MiniGameMainPage.OnClickCloud()
end

function EasyEditableWorld:OpenEditableWorld(subtag, entity)
    EnterConfirm.ShowPage(subtag,entity,true)
end

function EasyEditableWorld:OnEnterWorldPoint(subtag, entity)
    if(EasyEditableWorld.autoEnterWhenCollide) then
        EnterConfirm.ShowPage(subtag,entity)
    end
end

function EasyEditableWorld:OnLeaveWorldPoint(subtag, entity)
    if(EasyEditableWorld.autoEnterWhenCollide) then
        EnterConfirm.OnCancel()
    end
end

function EasyEditableWorld.OnClickOpenBackupFolder()
    local editableWorld = GameLogic.CreateGetEditableWorld();
    if editableWorld then
        local worldName = curInstance and curInstance.worldName;
        local backupPath = editableWorld:GetEditableFolder(worldName)
        if(backupPath and backupPath~="") then
            ParaGlobal.ShellExecute("open", backupPath, "", "", 1);
        end
    end
end

function EasyEditableWorld.OnClickShowAllArchives()
    EasyEditableWorld.OnClickSetSubTag("all");
end

function EasyEditableWorld.OnClickSetSubTag(subTag)
    if(subTag == "all") then
        subTag = nil;
    end
    if(subTag ~= EasyEditableWorld.subTag) then
        Mod.WorldShare.MsgBox:Wait(5000,L"存档数据加载中.....")
        EasyMyCheckPoint.RefreshEditableWorld(subTag,function()
            Mod.WorldShare.MsgBox:Close()
            EasyEditableWorld.subTag = subTag;
            if subTag and subTag ~= "" then
                EasyEditableWorld.mode = "Save"
            end
            EasyEditableWorld.LocalWorlds_DS = EasyEditableWorld.GetLocalWorldsDS();
            if(page) then
                page:Rebuild();
            end
        end)
    end
end

function EasyEditableWorld.EnableAutoSave()
    -- clear previous state
    EasyEditableWorld:ClearAutoSaveState()
    if(EasyEditableWorld.autoSaveEnabled) then
        return;
    end
    EasyEditableWorld.autoSaveEnabled = true;
    local editableWorld = GameLogic.CreateGetEditableWorld();
    if editableWorld then
        editableWorld:Connect("editableCountChanged", EasyEditableWorld, EasyEditableWorld.TriggerAutoSave, "UniqueConnection");
        GameLogic:Connect("WorldUnloaded", function()
            editableWorld:Disconnect("editableCountChanged", EasyEditableWorld, EasyEditableWorld.TriggerAutoSave);
            if EasyEditableWorld.autoSaveTimer then
                EasyEditableWorld.autoSaveTimer:Change();
                EasyEditableWorld.autoSaveTimer = nil;
            end
            EasyEditableWorld.autoSaveEnabled = nil;
        end);
    end
end

-- static function
function EasyEditableWorld:TriggerAutoSave()
    if(GameLogic.CreateGetEditableWorld():IsWorldFrozen()) then
        EasyEditableWorld.editCount = (EasyEditableWorld.editCount or 0) + 1;
        GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "unsaved", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName);
        EasyEditableWorld.autoSaveTimer = EasyEditableWorld.autoSaveTimer or commonlib.Timer:new({callbackFunc = function(timer)
            EasyEditableWorld.CheckQuickSave();
        end});
        EasyEditableWorld.autoSaveTimer:Change(EasyEditableWorld.delayQuickSaveSeconds * 1000, nil);
    end
end

function EasyEditableWorld:ClearAutoSaveState()
    if self.autoSaveTimer then
        self.autoSaveTimer:Change();
        self.autoSaveTimer = nil;
    end
end

function EasyEditableWorld.CheckQuickSave(bForceUpload)
    if((EasyEditableWorld.editCount or 0) > 0) then
        EasyEditableWorld.QuickSave(bForceUpload)
    end
end

-- Quick save to the current loaded slot locally
function EasyEditableWorld.QuickSave(bForceUpload)
    local editableWorld = GameLogic.CreateGetEditableWorld();
    if editableWorld and EasyEditableWorld.currentSlotFilename then
        local filename = EasyEditableWorld.currentSlotFilename or "";
        local suffix = "autosave";

        -- Check if filename contains subTag
        local worldData = nil;
        for i, data in ipairs(EasyEditableWorld.LocalWorlds_DS) do
            if data.filename == filename then
                worldData = data;
                break;
            end
        end
        local hasSubTag = worldData and worldData.subTag and worldData.subTag ~= "";

        local success, stats
        if hasSubTag then
            success, stats = editableWorld:DoAutoSave(true);
        elseif filename:sub(-#suffix) == suffix then
            success, stats = editableWorld:DoAutoSave(true);
        else
            local worldName = curInstance and curInstance.worldName;
            local filename = EasyEditableWorld.currentSlotFilename:match("([^/]+)$") or EasyEditableWorld.currentSlotFilename
            EasyEditableWorld.editCount = 0;
            success, stats = editableWorld:SaveToWorldSlot(filename, worldName);
        end
        if success then
            if hasSubTag then
                GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "savedButNotSynced", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName, stats);
                if(bForceUpload) then
                    if((EasyEditableWorld.editCount or 0) > 0 and EasyEditableWorld.currentSubTag) then
                        EasyEditableWorld.LoadOrSaveSlotWithSubTag("Save")
                    end
                else
                    EasyEditableWorld.uploadTimer = EasyEditableWorld.uploadTimer or commonlib.Timer:new({callbackFunc = function(timer)
                        if((EasyEditableWorld.editCount or 0) > 3 and EasyEditableWorld.currentSubTag) then
                            EasyEditableWorld.LoadOrSaveSlotWithSubTag("Save")
                        end
                    end});
                    if(not EasyEditableWorld.uploadTimer:IsEnabled()) then
                        EasyEditableWorld.uploadTimer:Change(EasyEditableWorld.delayUploadSeconds*1000, nil);
                    end
                end
            else
                GameLogic.GetFilters():apply_filters("EasyEditableWorldStatusChanged", "saved", EasyEditableWorld.currentSlotFilename, EasyEditableWorld.currentDisplayName, stats);
            end
        else
            GameLogic.AddBBS(nil, L"自动保存失败", 3000, "255 0 0");
        end
        EasyEditableWorld:ClearAutoSaveState()
    end
end

function EasyEditableWorld.OnClickSetHome()
    local worldData = EasyEditableWorld.currentWorldData
    if(worldData and worldData.slotIndex and worldData.subTag) then
         local remoteModel = EasyEditableWorld.GetRemoteData(worldData.slotIndex, worldData.subTag)
         if(remoteModel and remoteModel.id) then
            EasyHomeBuilder.CheckMyHomeExist(function(bExist, number)
                if(bExist) then
                    local homeModel = EasyHomeBuilder.homeBuilderData
                    if(homeModel and homeModel.id == remoteModel.id) then
                        return
                    end
                    _guihelper.MessageBox(L"您已设置过家园，是否需要搬家？", function(result)
                        if(result == _guihelper.DialogResult.Yes) then
                            local result = EasyHomeBuilder.ChangeHomeData(remoteModel)
                            if(result) then
                                GameLogic.AddBBS(nil, L"家园已搬家")
                                EasyMyCheckPoint.RefreshHomeData()
                                EasyEditableWorld.RefreshWorldData();
                            end
                        end
                    end,_guihelper.MessageBoxButtons.YesNo)
                end
            end)
         end
    end
end

function EasyEditableWorld.OnClickDeleteSlot(index)
    local editableWorld = GameLogic.CreateGetEditableWorld();
    local worldData = EasyEditableWorld.LocalWorlds_DS[index];
    if(worldData and worldData.filename) then
        local remoteModel = EasyEditableWorld.GetRemoteData(worldData.slotIndex, worldData.subTag)

        _guihelper.MessageBox(string.format(L"确定要删除存档 %d 吗？删除后仍可本地找回。", worldData.slotIndex or 0), function(result)
            EasyMyCheckPoint.DeleteModelBySubTag(worldData.slotIndex, worldData.subTag)
            if(worldData.slotIndex == EasyEditableWorld.currentSlotIndex or worldData.filename == EasyEditableWorld.currentSlotFilename) then
                editableWorld:BackupWorldSlot(worldData.slotIndex, worldName, worldData.subTag);
                EasyEditableWorld.OnClickRestartWorld();
            else
                local worldName = curInstance and curInstance.worldName;
                editableWorld:DeleteWorldSlot(worldData.slotIndex, worldName, worldData.subTag);
                EasyEditableWorld.RefreshWorldData();
            end
        end);
    end
end

-- this is called when loading an external file into the current world of a given subTag.
-- @param bDoNotTeleportPlayer: if true, we will not teleport the player to the user point in the loaded world.
function EasyEditableWorld.LoadExternalFile(filepath, subTag, isMine, bForceOverwrite, bDoNotTeleportPlayer)
    if(not filepath or filepath == "") then
        return;
    end
    GameLogic.EditableWorld:RemoveReadonlyBlockTemplateBySubTag(subTag)

    local function LoadExternalFileImp(filepath, subTag)
        local entities = GameLogic.EditableWorld:AddReadonlyBlockTemplate(filepath, subTag)
        if(type(entities) == "table" and not bDoNotTeleportPlayer) then
            for _, entity in ipairs(entities) do
                if(entity:isa(EntityManager.EntityUserPoint)) then
                    EasyEditableWorld.TeleportToUserPoint(entity)
                    break
                end
            end
        end
        if isMine then
            GameLogic.AddBBS(nil, L"这是你自己的存档， 将以只读模式加载")
        end
    end
    
    if(subTag == EasyEditableWorld.currentSubTag) then
        _guihelper.MessageBox(L"你正在编辑相同标签的存档，是否仍要加载？", function(result)
            if result == _guihelper.DialogResult.Yes then
                GameLogic.AddBBS("LoadExternalFile", L"已自动切换到默认存档", 3000, "255 0 0")
                EasyEditableWorld.OnClickLoadSlot(0);
                LoadExternalFileImp(filepath, subTag)
            end
        end, _guihelper.MessageBoxButtons.YesNo)
        return
    end
    
    -- add read only template imp 
    local hasConflict = false;
    local conflictBlocks
    if(not bForceOverwrite) then
        conflictBlocks = GameLogic.EditableWorld:GetConflictBlocksFromFile(filepath);
        if(conflictBlocks and #conflictBlocks > 0) then
            hasConflict = true;
        end
    end
    if hasConflict and conflictBlocks then
        -- TODO: show a draggable window to resolve conflicts
        GameLogic.EditableWorld:ShowConflictBlocks(conflictBlocks)
        _guihelper.MessageBox(string.format(L"存档中有%d个位置存在冲突，是否加载此存档?", #conflictBlocks), function(result)
            GameLogic.EditableWorld:ClearSelections()

            if result == _guihelper.DialogResult.Yes then
                LoadExternalFileImp(filepath, subTag)
            end
        end, _guihelper.MessageBoxButtons.YesNo)
    else
        LoadExternalFileImp(filepath, subTag)
    end
end

function EasyEditableWorld.GetCurrentSlotDSIndex()
    if not EasyEditableWorld.currentSlotFilename then
        return;
    end
    
    for i, worldData in ipairs(EasyEditableWorld.LocalWorlds_DS) do
        if worldData.filename == EasyEditableWorld.currentSlotFilename then
            return i;
        end
    end
end

function EasyEditableWorld.OnClickUploadCurrent()
    EasyEditableWorld.OnClickSaveSlot(EasyEditableWorld.GetCurrentSlotDSIndex())
end

function EasyEditableWorld.OnClickEditDescription(index)
    index = tonumber(index);
    local worldData = EasyEditableWorld.LocalWorlds_DS[index];
    if not worldData or not worldData.subTag or worldData.subTag == "" then
        GameLogic.AddBBS(nil, L"只有标签存档点才能编辑描述", 3000, "255 255 0");
        return;
    end
    
    -- Get current remote model data to get existing description
    local remoteModel = EasyEditableWorld.GetRemoteData(worldData.slotIndex, worldData.subTag)
    local currentDesc = (remoteModel and remoteModel.desc) or ""
    
    -- Show input dialog for description editing
    NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
    NPL.load("(gl)script/ide/System/Core/UniString.lua");
    NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
    local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
    local UniString = commonlib.gettable("System.Core.UniString");
    local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
    
    EnterTextDialog.ShowPage(L"编辑存档名", function(result)
        if result and result ~= "" then
            -- Trim spaces and validate using UniString
            result = string.gsub(result, "^%s*(.-)%s*$", "%1")
            if result ~= "" then
                -- Check for inappropriate content using BadWordFilter
                local filteredResult = BadWordFilter.FilterString(result);
                if filteredResult ~= result then
                    GameLogic.AddBBS(nil, L"输入内容包含不当词汇，请重新输入", 3000, "255 255 0");
                    return;
                end
                
                local uniStr = UniString:new(result);
                local charCount = uniStr:length();
                if charCount <= 10 then
                    EasyEditableWorld.UpdateArchiveDescription(worldData, result);
                else
                    GameLogic.AddBBS(nil, L"描述过长，最多10个字", 3000, "255 255 0");
                end
            end
        end
    end, currentDesc);
end

function EasyEditableWorld.UpdateArchiveDescription(worldData, newDesc)
    if not worldData or not worldData.subTag or worldData.subTag == "" then
        return;
    end
    -- Get the current remote model data
    local remoteModel = EasyEditableWorld.GetRemoteData(worldData.slotIndex, worldData.subTag)
    if(remoteModel and remoteModel.desc ~= newDesc) then
        worldData.desc = newDesc;
        remoteModel.desc = newDesc;
        EasyEditableWorld.OnClickUploadCurrent();
    end
end

function EasyEditableWorld.OnClickShowTutorialVideo()
    GameLogic.RunCommand("/open -webview https://keepwork.com/api/raw/maisi/maisi/webgames/data/msplanet_storymode_tips")
end