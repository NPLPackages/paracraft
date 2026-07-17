--[[
Title: EasyBuilder LiveModel Task
Author(s): GitHub Copilot
Date: 2025/10/27
Desc: Super easy interface to create live models and characters to the current scene.
Similar to OpenAssetFileDialog but simplified for easy model placement.

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyLiveModel.lua");
local EasyLiveModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyLiveModel");
local task = EasyLiveModel:new();
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/ModelTemplatesFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLiveModel.lua");
NPL.load("(gl)script/ide/System/Windows/MouseEvent.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.lua");
NPL.load("(gl)script/ide/ContextMenu.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
local EasyModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyModel");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ItemLiveModel = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");
local ModelTemplatesFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.ModelTemplatesFile");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");

local EasyLiveModel = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyLiveModel"));
EasyLiveModel:Signal("taskFinished");
local curInstance;
local page;
local previewEntity; -- Temporary entity for model preview
local lastPlayerPos; -- Track last player position to detect movement

-- Always a top level task
EasyLiveModel.is_top_level = true;
EasyLiveModel.previewEntityHeadonYOffset = 2.1; -- Y offset above player's head for preview
EasyLiveModel.playerMovementThreshold = 0.1; -- Distance threshold to trigger preview destruction
-- show only custom characters in the people category
EasyLiveModel.showOnlyCustomChar = true;
EasyLiveModel.autoRotatePreviewEntity = false; -- whether to auto rotate the preview entity
EasyLiveModel.destroyPreviewEntityWhenDragEnd = true; -- whether to destroy the preview entity when drag ends

-- Display name mapping file
EasyLiveModel.displayNameFileName = "localFileDisplayName.txt";

-- Category settings
EasyLiveModel.categories = {
	{name = "all", text = L"全部", color="#ffffff", },
	{name = "local", text = L"本地", color="#0078d7", },
	-- {name = "common", text = L"常用" , color="#7abb55", },
	{name = "people", text = L"人类", color="#764bcc", },
	{name = "animals", text = L"动物", color="#d83b01", },
	{name = "furnitures", text = L"装饰", color="#69b090", },
	{name = "fantasy", text = L"科幻", color="#8f6d40", },
	{name = "vehicles", text = L"交通", color="#69b090", },
	{name = "props", text = L"物品", color="#69b090", },
	{name = "equipment", text = L"装备", color="#69b090", },
	{name = "effects", text = L"特效", color="#69b090", },
};
EasyLiveModel.default_category_index = 3; -- Default to "people" category
EasyLiveModel.category_index = nil

EasyLiveModel.IndexLocal = 1;
EasyLiveModel.IndexCommon = 2;

-- Selected model info
EasyLiveModel.modelFilename = nil;

-- File filters
EasyLiveModel.filters = {
	{L"全部文件(*.fbx,*.FBX,*.x,*.bmax,*.glb,*.gltf,*.ply)",  "*.fbx;*.FBX;*.x;*.bmax;*.glb;*.gltf;*.ply", exclude="*.blocks.xml"},
	{L"FBX模型(*.fbx)",  "*.fbx"},
	{L"bmax模型(*.bmax)",  "*.bmax"},
	{L"ParaX模型(*.x,*.xml)",  "*.x;*.xml", exclude="*.blocks.xml"},
	{L"GLTF模型(*.glb,*.gltf)",  "*.glb;*.gltf"},
};

-- Display name mapping system
EasyLiveModel.localFileDisplayNameCache = nil;
EasyLiveModel.displayNameMapping = nil;

function EasyLiveModel:ctor()
end

function EasyLiveModel.GetInstance()
    return curInstance;
end

-- Register world unload event to invalidate display name cache
function EasyLiveModel.RegisterWorldEvents()
    GameLogic:Connect("WorldUnloaded", EasyLiveModel, EasyLiveModel.OnWorldUnload, "UniqueConnection");
end

-- Called when world is unloaded
function EasyLiveModel.OnWorldUnload()
    EasyLiveModel.InvalidateDisplayNameCache();
end

function EasyLiveModel.OnInit()
    page = document:GetPageCtrl();
    EasyLiveModel.UpdateExistingFiles();
end

-- Get category buttons for display
function EasyLiveModel.GetCategoryButtons()
	return EasyLiveModel.categories;
end

function EasyLiveModel:Redo()
end

function EasyLiveModel:Undo()
end

-- Follow EasyModel lifecycle
function EasyLiveModel:Run()
    curInstance = self;
    self:ShowPage(true);
    self:LoadSceneContext();
end

function EasyLiveModel:OnExit()
    EasyLiveModel.Cancel()
end

function EasyLiveModel.Cancel()
    local self = curInstance;
    if(self) then 
        curInstance = nil;
        self:SetFinished();
        self:CloseWindow();
        self:UnloadSceneContext();
        EasyLiveModel.DestroyPreviewEntity();
        EasyLiveModel.CloseFindEntityWindow();
        EasyModel:ShowEditActionsForEntity(nil);
        EasyModel.CloseEditModelWindow()
        self:taskFinished();
    end
    EasyLiveModel.category_index = nil
end

function EasyLiveModel:ShowPage(bShow)
    if(not page) then
        local width, height = 360, 620;
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyLiveModel.html", 
            name = "EasyLiveModel.ShowPage", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            bToggleShowHide = false, 
            style = CommonCtrl.WindowFrame.ContainerStyle,
            enable_esc_key = false,
            allowDrag = false,
            click_through = true, 
            bShow = (bShow ~= false),
            directPosition = true,
            align = "_rt",
            x = -20 - width,
            y = 64,
            width = width,
            height = height,
        };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
        curInstance = curInstance or self;
        if(params._page) then
            params._page.OnClose = function()
                page = nil;
                EasyLiveModel.DestroyPreviewEntity();
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
        EasyLiveModel.OnChangeCategory(EasyLiveModel.default_category_index);
    end
end

function EasyLiveModel:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
    EasyLiveModel.DestroyPreviewEntity();
    EasyLiveModel.CloseFindEntityWindow();
    EasyModel:ShowEditActionsForEntity(nil);
end

function EasyLiveModel:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

-- Create or update preview entity above player's head
function EasyLiveModel.CreateOrUpdatePreviewEntity(modelFilename, displayname)
    if(not modelFilename or modelFilename == "") then
        EasyLiveModel.DestroyPreviewEntity();
        return;
    end
    
    local player = EntityManager.GetFocus();
    if(not player) then
        return;
    end
    
    -- Get player position
    local px, py, pz = player:GetPosition();
    lastPlayerPos = {x = px, y = py, z = pz};
    py = py + EasyLiveModel.previewEntityHeadonYOffset;
    
    -- Validate model filename
    local filepath = PlayerAssetFile:GetValidAssetByString(modelFilename);
    if(not filepath) then
        filepath = modelFilename;
    end
    filepath = Files.GetRelativePath(filepath);
    
    if(not previewEntity) then
        -- Create new preview entity
        previewEntity = EntityManager.EntityLiveModel:Create({
            x = px, y = py, z = pz,
            item_id = block_types.names.LiveModel, 
        });
        previewEntity:SetPersistent(false); -- Don't save this entity
        previewEntity:SetDummy(false); -- Enable frame move to follow player
        previewEntity:Attach();
        previewEntity:SetCanDrag(true);
        previewEntity:SetDisplayName(displayname);
        previewEntity.nohistory = true;
        previewEntity:Connect("dragBegun", EasyLiveModel, EasyLiveModel.DragBegunPreviewEntity, "UniqueConnection");
        previewEntity:Connect("dragEnded", EasyLiveModel, EasyLiveModel.DragEndedPreviewEntity, "UniqueConnection");
        
        -- Make it slightly transparent to indicate it's a preview
        -- previewEntity:SetOpacity(0.7);
    end
    -- Update existing preview entity
    if(previewEntity:GetModelFile() ~= filepath) then
        -- GameLogic.SetStatus(L"拖动放置模型");
        previewEntity:SetModelFile(filepath);
        previewEntity:Refresh();
    end
    previewEntity:SetScaling(1.0); -- Reset scaling
    -- check if the entity has animation id 4, if so, we will set its category to character
    if previewEntity:HasAnimation(4) then
        previewEntity:SetCategory("character")
    else
        previewEntity:SetCategory(nil)
    end
    -- Set facing to face the camera
    previewEntity:SetFacing(Direction.GetFacingFromCamera() + math.pi);
    -- Update position to follow player
    previewEntity:SetPosition(px, py, pz);

    -- Start animation for new entity or model change
    EasyLiveModel.StartPreviewEntityAnimation();
    
    -- Start a timer to update position following player
    EasyLiveModel.StartPreviewPositionUpdater();
end

-- Clone the preview entity to create a permanent model in the scene
-- @param callback function to call when new model is created, we can change some param in it before we save to undo history
-- @return newly created entity
function EasyLiveModel.ClonePreviewEntity(callback)
    if(previewEntity and not previewEntity.isDead) then
        local newModel = previewEntity:CloneMe()
        newModel:SetPersistent(true);
        newModel:Attach()
        if(newModel.category == "character") then
            newModel:SetStaticTag("actionname", L"互动");
            newModel:SetOnClickEvent("API.CharInteract");
            newModel:SetActionRadius(1.5);
            newModel:SetCanDrag(true)
        else
            newModel:SetCanDrag(false)
        end
        if(callback) then
            callback(newModel)
        end

        newModel.nohistory = nil;
        
        if(GameLogic.CreateGetEditableWorld():AddLiveEntity(newModel, true)) then
            -- add to history command
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
            local task = MyCompany.Aries.Game.Tasks.DragEntity:new({addToHistory=true});
            task:CreateEntity(newModel);
            
            local filename = newModel:GetModelFile() or "";
            local cleanFilename = filename:match("([^/\\]+)$") or filename
            GameLogic.AddBBS(nil, format(L"成功创建活动模型:%s", cleanFilename), 3000, "0 255 0");
            return newModel
        end
    end
end

function EasyLiveModel:DragBegunPreviewEntity()
    if(curInstance) then
        curInstance:DeleteManipulators();
    end
    -- Cancel any pending delayed manipulator update when dragging starts
    EasyLiveModel.CancelDelayedManipulatorUpdate();
end

function EasyLiveModel:DragEndedPreviewEntity(dragLocation)
    if(previewEntity and not previewEntity.isDead) then
        EasyLiveModel.ClonePreviewEntity()
        
        if(EasyLiveModel.destroyPreviewEntityWhenDragEnd) then
            EasyLiveModel.DestroyPreviewEntity();
        else
            previewEntity:RestoreDragLocation();
        end

        if(curInstance) then
            curInstance:UpdateManipulators();
        end
        
        -- Update player position after drag to prevent immediate destruction
        local player = EntityManager.GetFocus();
        if(player) then
            local px, py, pz = player:GetPosition();
            lastPlayerPos = {x = px, y = py, z = pz};
        end
        return true;
    end
end

-- Create a falling clone of the preview entity
function EasyLiveModel.CreateFallingClone()
    local entity = EasyLiveModel.ClonePreviewEntity(function(entity)
        if(entity) then
            entity:FallDown()
        end
    end)
end

-- Destroy preview entity
function EasyLiveModel.DestroyPreviewEntity()
    if(previewEntity) then
        previewEntity:SetDead();
        previewEntity:Destroy();
        previewEntity = nil;

        if(curInstance) then
            curInstance:UpdateManipulators();
        end
    end
    lastPlayerPos = nil;
    EasyLiveModel.StopPreviewPositionUpdater();
    EasyLiveModel.StopPreviewEntityAnimation();
    EasyLiveModel.CancelDelayedManipulatorUpdate();
    EasyLiveModel.SetModelFilename(nil);
    GameLogic.SetStatus(nil);
end

-- Start preview entity animation (scale and rotation)
function EasyLiveModel.StartPreviewEntityAnimation(entity)
    EasyLiveModel.animatingEntity = entity or previewEntity
    local targetEntity = EasyLiveModel.animatingEntity
    if(not targetEntity or targetEntity.isDead) then
        return;
    end
    
    -- Stop any existing animation
    EasyLiveModel.StopPreviewEntityAnimation();
    
    -- Cancel any pending manipulator update
    EasyLiveModel.CancelDelayedManipulatorUpdate();
    
    -- Delete manipulators when animation starts
    if(curInstance) then
        curInstance:DeleteManipulators();
    end
    
    -- Disable dragging during animation
    targetEntity:SetCanDrag(false);
    
    -- Animation parameters
    EasyLiveModel.animationDuration = 1000; -- 1 second in milliseconds
    EasyLiveModel.animationStartScale = 0.1; -- Initial scale when animation starts
    EasyLiveModel.animationPeakScale = 1.2; -- Peak scale during animation (bounce effect)

    local startTime = ParaGlobal.timeGetTime();
    local initialFacing = Direction.GetFacingFromCamera() - math.pi/2; -- Start rotated 90 degrees
    local targetFacing = Direction.GetFacingFromCamera() - math.pi; -- End facing camera
    
    -- Set initial state
    targetEntity:SetFacing(initialFacing);
    targetEntity:SetScaling(EasyLiveModel.animationStartScale); -- Start at configurable small scale

    local player = EntityManager.GetFocus()
    if(player) then
        -- hold out arms and back to idle
        player:SetAnimation(152)
        player:PlaySound("click");
        -- player:SetFacing(targetFacing)
    end
    
    EasyLiveModel.previewAnimationTimer = commonlib.Timer:new({callbackFunc = function(timer)
        local targetEntity = EasyLiveModel.animatingEntity
        if(not targetEntity or targetEntity.isDead) then
            EasyLiveModel.StopPreviewEntityAnimation();
            return;
        end
        
        local currentTime = ParaGlobal.timeGetTime();
        local elapsed = currentTime - startTime;
        local progress = math.min(elapsed / EasyLiveModel.animationDuration, 1.0);
        
        if(progress >= 1.0) then
            -- Animation complete
            targetEntity:SetScaling(1.0);
            targetEntity:SetFacing(targetFacing);
            EasyLiveModel.StopPreviewEntityAnimation();
            -- Re-enable dragging when animation stops
            targetEntity:SetCanDrag(true);
            -- Schedule delayed manipulator update (1 second after animation stops)
            EasyLiveModel.ScheduleDelayedManipulatorUpdate();
        else
            -- Animate scale using tunable parameters
            local startScale = EasyLiveModel.animationStartScale;
            local peakScale = EasyLiveModel.animationPeakScale;
            local scale;
            if(progress < 0.5) then
                -- First half: scale from startScale to peakScale
                scale = startScale + (progress * 2) * (peakScale - startScale);
            else
                -- Second half: scale from peakScale to 1.0
                scale = peakScale - ((progress - 0.5) * 2) * (peakScale - 1.0);
            end
            targetEntity:SetScaling(scale);
            
            -- Animate rotation: smooth interpolation from initial to target
            local currentFacing = initialFacing + (targetFacing - initialFacing) * progress;
            targetEntity:SetFacing(currentFacing);
        end
    end});
    
    EasyLiveModel.previewAnimationTimer:Change(30, 30); -- Update every 30ms for smooth animation
end

-- Stop preview entity animation
function EasyLiveModel.StopPreviewEntityAnimation()
    if(EasyLiveModel.previewAnimationTimer) then
        EasyLiveModel.previewAnimationTimer:Change();
        EasyLiveModel.previewAnimationTimer = nil;
        -- Re-enable dragging when animation is manually stopped
        local targetEntity = EasyLiveModel.animatingEntity or previewEntity
        if(targetEntity and not targetEntity.isDead) then
            targetEntity:SetCanDrag(true);
        end
        EasyLiveModel.animatingEntity = nil
        local player = EntityManager.GetFocus()
        if(player) then
            player:SetAnimation(0)
        end
    end
end

-- Schedule delayed manipulator update (1 second after animation stops)
function EasyLiveModel.ScheduleDelayedManipulatorUpdate()
    -- Cancel any existing delayed update
    EasyLiveModel.CancelDelayedManipulatorUpdate();
    
    EasyLiveModel.delayedManipulatorTimer = commonlib.Timer:new({callbackFunc = function(timer)
        if(curInstance and previewEntity and not previewEntity.isDead) then
            curInstance:UpdateManipulators();
        end
        EasyLiveModel.delayedManipulatorTimer = nil;
    end});
    
    -- Set timer to fire once after 1000ms (1 second)
    EasyLiveModel.delayedManipulatorTimer:Change(1000, nil);
end

-- Cancel any pending delayed manipulator update
function EasyLiveModel.CancelDelayedManipulatorUpdate()
    if(EasyLiveModel.delayedManipulatorTimer) then
        EasyLiveModel.delayedManipulatorTimer:Change();
        EasyLiveModel.delayedManipulatorTimer = nil;
    end
end

-- Start timer to update preview entity position
function EasyLiveModel.StartPreviewPositionUpdater(entity, options)
    EasyLiveModel.updatingEntity = entity or previewEntity
    EasyLiveModel.updateOptions = options
    
    -- initialize lastPlayerPos
    local player = EntityManager.GetFocus();
    if(player) then
        local px, py, pz = player:GetPosition();
        lastPlayerPos = {x = px, y = py, z = pz};
    end

    if(not EasyLiveModel.previewUpdateTimer) then
        EasyLiveModel.previewUpdateTimer = commonlib.Timer:new({callbackFunc = function(timer)
            local targetEntity = EasyLiveModel.updatingEntity
            local options = EasyLiveModel.updateOptions or {}
            
            if(targetEntity and not targetEntity.isDead) then
                local player = EntityManager.GetFocus();
                if(player) then
                    local px, py, pz = player:GetPosition();
                    
                    -- Don't update position if entity is being dragged
                    if(not targetEntity:IsDragging()) then
                        -- Check if player has moved beyond threshold
                        if(lastPlayerPos) then
                            local dx = px - lastPlayerPos.x;
                            local dy = py - lastPlayerPos.y;
                            local dz = pz - lastPlayerPos.z;
                            local xzDistance = math.sqrt(dx * dx + dz * dz);
                            
                            -- If player moved in XZ plane
                            if(xzDistance > EasyLiveModel.playerMovementThreshold) then
                                if options.onMove then
                                    options.onMove(targetEntity)
                                    EasyLiveModel.StopPreviewPositionUpdater()
                                    return
                                else
                                    EasyLiveModel.DestroyPreviewEntity();
                                    return;
                                end
                            end
                            
                            -- If player jumped (significant Y movement upward)
                            if(dy > EasyLiveModel.playerMovementThreshold) then
                                if options.onMove then
                                    options.onMove(targetEntity)
                                    EasyLiveModel.StopPreviewPositionUpdater()
                                    return
                                else
                                    EasyLiveModel.CreateFallingClone();
                                    EasyLiveModel.DestroyPreviewEntity();
                                    return;
                                end
                            end
                        end
                        
                        -- Update position to follow player's head
                        py = py + EasyLiveModel.previewEntityHeadonYOffset;
                        targetEntity:SetPosition(px, py, pz);
                    end

                    -- Auto rotation disabled per user request
                    if(EasyLiveModel.autoRotatePreviewEntity) then
                        local facing = targetEntity:GetFacing();
                        targetEntity:SetFacing(facing + 0.02);
                    end
                end
            else
                EasyLiveModel.StopPreviewPositionUpdater();
            end
        end})
    end
    EasyLiveModel.previewUpdateTimer:Change(30, 100); -- Update every 100ms
end

-- Stop preview position updater timer
function EasyLiveModel.StopPreviewPositionUpdater()
    if(EasyLiveModel.previewUpdateTimer) then
        EasyLiveModel.previewUpdateTimer:Change();
        EasyLiveModel.previewUpdateTimer = nil;
    end
end

-- Key press event handler
function EasyLiveModel:keyPressEvent(event)
    if(event:isAccepted()) then
        return
    end
    local dik_key = event.keyname;
    if(dik_key == "DIK_ESCAPE")then
        EasyLiveModel.OnClickClose()
        event:accept()
    elseif(dik_key == "DIK_E")then
        EasyLiveModel.OnClickClose()
        event:accept()
    elseif(event.ctrl_pressed and dik_key == "DIK_Z")then
        UndoManager.Undo();
        event:accept();
    elseif(event.ctrl_pressed and dik_key == "DIK_Y")then
        UndoManager.Redo();
        event:accept();
    else
        self:GetSceneContext():keyPressEvent(event);
    end
end

-- Mouse press event handler
function EasyLiveModel:mousePressEvent(event)
    local context = self:GetSceneContext();
    if(event.mouse_button == "left") then
        context._super.mousePressEvent(context, event);
    end
end

-- Mouse move event handler
function EasyLiveModel:mouseMoveEvent(event)
    local context = self:GetSceneContext();
    if(event.mouse_button == "left") then
        context._super.mouseMoveEvent(context, event);
    end
end

-- Mouse release event handler
function EasyLiveModel:mouseReleaseEvent(event)
    local context = self:GetSceneContext();
    
    if(event.mouse_button == "left") then
        context._super.mouseReleaseEvent(context, event);
    end

    context.is_click = event:isClick()
    
    if(context.is_click) then
        local result = context:CheckMousePick();
        if(event.mouse_button == "left") then
            self:handleLeftClickScene(event, result)
        elseif(event.mouse_button == "right") then
            self:handleRightClickScene(event, result);
        elseif(event.mouse_button == "middle") then
            self:handleMiddleClickScene(event, result);
        end
    end
end

-- Handle middle click to teleport player
function EasyLiveModel:handleMiddleClickScene(event, result)
    if(result and result.blockX) then
        local x, y, z = result.blockX, result.blockY, result.blockZ;
        local block_template = BlockEngine:GetBlock(x, y, z);
        if(block_template and not block_template.obstruction) then
            local block_template = BlockEngine:GetBlock(x, y-1, z);
            if(block_template and block_template.obstruction) then
                y = y - 1;
            end
        end
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
        local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX = x, blockY = y, blockZ = z})
        task:Run();	
    end
end

-- Handle left click scene
function EasyLiveModel:handleLeftClickScene(event, result)
    self:handleSceneClick(event, result)
end

-- Handle right click scene
function EasyLiveModel:handleRightClickScene(event, result)
    self:handleSceneClick(event, result)
end

-- Try to edit an entity (similar to EasyModel:TryEditEntity)
function EasyLiveModel:TryEditEntity(entity)
    if(entity) then
        if(entity:isa(EntityManager.EntityLiveModel) and entity.isFromEditableWorld) then
            EasyModel:ShowEditActionsForEntity(entity, function()
                if(curInstance) then
                    curInstance:CheckRestoreSceneContext();
                end
            end)
            return true;
        end
    else
        EasyModel:ShowEditActionsForEntity(nil)
    end
end

-- Handle scene click
function EasyLiveModel:handleSceneClick(event, result)
    if not event:isClick() or not curInstance or not result or not result.blockX then return end
    
    -- Check if clicked on a live model entity
    if(result.entity and result.entity:isa(EntityManager.EntityLiveModel) and result.entity.isFromEditableWorld) then
        self:TryEditEntity(result.entity)
        event:accept()
        return
    end
end

function EasyLiveModel:IsVisible()
    return page and page:IsVisible();
end


function EasyLiveModel.OnClickClose()
    local isFromItemEasyBuilder;
    if(curInstance) then
        isFromItemEasyBuilder = curInstance.isFromItemEasyBuilder;
        curInstance:OnExit();
    end
    if(isFromItemEasyBuilder) then
        -- take back the easy builder item
        GameLogic.RunCommand("/take -select -bag 3");
    end
end

-- Change category
function EasyLiveModel.OnChangeCategory(index)
	EasyLiveModel.category_index = tonumber(index);
	local category = EasyLiveModel.GetCategoryButtons()[EasyLiveModel.category_index];
	if(category and category.name == "all") then
		-- Show all categories
		filteredFiles = nil;
		for _, cat in ipairs(EasyLiveModel.GetAllFiles()) do
			cat.attr.expanded = false;
		end
	else
		-- Show only selected category
		local idx = EasyLiveModel.category_index - 1;
		filteredFiles = {};
		for i, cat in ipairs(EasyLiveModel.GetAllFiles()) do
			cat.attr.expanded = (i == idx);
			if(i == idx) then
				filteredFiles[#filteredFiles + 1] = cat;
			end
		end
	end
	if(page) then
		EasyLiveModel.SetSearchText();
		page:Refresh(0.01);
	end
end

-- Set model filename and update preview
function EasyLiveModel.SetModelFilename(filename, displayname)
	if(EasyLiveModel.modelFilename ~= filename) then
		EasyLiveModel.modelFilename = filename;
		if(filename) then
			EasyLiveModel.CreateOrUpdatePreviewEntity(filename, displayname);
		end
	end
end

function EasyLiveModel.GetModelFilename()
	return EasyLiveModel.modelFilename;
end

-- Get all existing files
EasyLiveModel.dsExistingFiles = {};

function EasyLiveModel.GetExistingFiles()
	return EasyLiveModel.dsExistingFiles;
end

-- Update existing files from world directory
function EasyLiveModel.UpdateExistingFiles()
	NPL.load("(gl)script/ide/Files.lua");
	local rootPath = ParaWorld.GetWorldDirectory();

	local filter, filterFunc;
	local searchLevel = 2;
	if(EasyLiveModel.filters) then
		filter = EasyLiveModel.filters[EasyLiveModel.curFilterIndex or 1];
		if(filter) then
			if(filter[2]) then
				local exts = {};
				local excludes;
				for ext in filter[2]:gmatch("%*%.([^;]+)") do
					exts[#exts + 1] = "%."..ext.."$";
				end
				if(filter.exclude) then
					excludes = excludes or {};
					for ext in filter.exclude:gmatch("%*%.([^;]+)") do
						excludes[#excludes + 1] = "%."..ext.."$";
					end
				end
				
				local skippedFiles = {
					["LocalNPC.xml"] = true,
					["entity.xml"] = true,
					["players/0.entity.xml"] = true,
					["revision.xml"] = true,
					["tag.xml"] = true,
				}

				filterFunc = function(item)
					if(not skippedFiles[item.filename] and not item.filename:match("^blockWorld")) then
						if(excludes) then
							for i=1, #excludes do
								if(item.filename:match(excludes[i])) then
									return;
								end
							end
						end
						for i=1, #exts do
							if(item.filename:match(exts[i])) then
								return true;
							end
						end
					end
				end
			end
		end
	end
	
	local files = EasyLiveModel.dsExistingFiles;
	table.resize(EasyLiveModel.dsExistingFiles, 0);
	local result = commonlib.Files.Find({}, rootPath, searchLevel, 500, filterFunc);

	if(System.World.worldzipfile) then
		local localFiles = {};
		for i = 1, #result do
			local fileAttr = result[i];
			-- Apply custom display name if available
			local displayName = EasyLiveModel.GetDisplayName(fileAttr.filename);
			if(displayName and displayName ~= fileAttr.filename) then
				fileAttr.text = displayName;
			end
			localFiles[#localFiles+1] = {name="file", attr=fileAttr};
		end

		if (localFiles and #localFiles > 0) then
			for _, item in ipairs(localFiles) do
				files[#files + 1] = item;
			end
		end

		local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(System.World.worldzipfile);
		local zipParentDir = zip_archive:GetField("RootDirectory", "");
		if(zipParentDir~="") then
			if(rootPath:sub(1, #zipParentDir) == zipParentDir) then
				rootPath = rootPath:sub(#zipParentDir+1, -1)
				local result = commonlib.Files.Find({}, rootPath, searchLevel, 500, ":.", System.World.worldzipfile);
				for i = 1, #result do
					if(type(filterFunc) == "function" and filterFunc(result[i])) then
						local beExist = false;
						result[i].filename = commonlib.Encoding.Utf8ToDefault(result[i].filename)
						if (localFiles and #localFiles > 0) then
							for _, item in ipairs(localFiles) do
								if item and item.attr and item.attr.filename and
								   result[i] and result[i].filename and
								   item.attr.filename == result[i].filename then
									beExist = true;
									break;
								end
							end
						end

						if (not beExist) then
							local fileAttr = result[i];
							-- Apply custom display name if available
							local displayName = EasyLiveModel.GetDisplayName(fileAttr.filename);
							if(displayName and displayName ~= fileAttr.filename) then
								fileAttr.text = displayName;
							end
							files[#files+1] = {name="file", attr=fileAttr};
						end
					end
				end
			end
		end
	else
		for i = 1, #result do
			local fileAttr = result[i];
			-- Apply custom display name if available
			local displayName = EasyLiveModel.GetDisplayName(fileAttr.filename);
			if(displayName and displayName ~= fileAttr.filename) then
				fileAttr.text = displayName;
			end
			files[#files + 1] = {name="file", attr=fileAttr};
		end
	end
	
	if not GameLogic.IsReadOnly() then
		table.sort(files, function(a, b)
			return a.attr and b.attr and a.attr.writedate and b.attr.writedate and a.attr.writedate > b.attr.writedate;
		end)
	end
	EasyLiveModel.GetAllFiles()[EasyLiveModel.IndexLocal].attr.count = #files;
	return files;
end

local allFiles;
local filteredFiles;

function EasyLiveModel.GetAllFiles()
	if(not allFiles) then
		allFiles = {};

		-- Fill local files
		allFiles[EasyLiveModel.IndexLocal] = EasyLiveModel.GetExistingFiles();
		
		-- Fill all categories from PlayerAsset files
		for i=1, #EasyLiveModel.categories do
			local category = EasyLiveModel.categories[i];
			local idx = i-1;
			allFiles[idx] = allFiles[idx] or {};
			local commonFiles = allFiles[idx];
			commonFiles.name = "category";
			commonFiles.attr = {text=category.text, expanded=false, count=0};

			if(PlayerAssetFile:HasCategory(category.name)) then
				local items = PlayerAssetFile:GetCategoryItems(category.name);
				for i, item in ipairs(items) do
					local assetfile = item.filename;
					if(assetfile and assetfile~="") then
						-- Filter for "people" category: only show models with HasCustomGeosets if showOnlyCustomChar is true
						local shouldAdd = true;
						if(category.name == "people" and EasyLiveModel.showOnlyCustomChar) then
                            local filename = PlayerAssetFile:GetValidAssetByString(assetfile)
							shouldAdd = CustomCharItems:GetSkinByAsset(filename)~=nil or PlayerAssetFile:HasCustomGeosets(filename);
						end
						
						if(shouldAdd) then
							commonFiles[#commonFiles+1] = {name="commonfile", attr={text=item.displayname or item.filename, filename=item.name or item.filename}};
						end
					end
				end
			end
			commonFiles.attr.count = #commonFiles;
		end
		allFiles[EasyLiveModel.IndexLocal].attr.expanded = true;
	end
	return allFiles;
end

function EasyLiveModel.GetAllFilesWithFilters()
	return filteredFiles and filteredFiles or EasyLiveModel.GetAllFiles()
end

-- Search/filter functionality
function EasyLiveModel.SetSearchText(searchText)
	if(not searchText or searchText == "") then
		-- Check if we need to restore category filtering
		local category = EasyLiveModel.GetCategoryButtons()[EasyLiveModel.category_index];
		if(category and category.name ~= "all") then
			-- Restore single category view
			local idx = EasyLiveModel.category_index - 1;
			filteredFiles = {};
			for i, cat in ipairs(EasyLiveModel.GetAllFiles()) do
				if(i == idx) then
					filteredFiles[#filteredFiles + 1] = cat;
				end
			end
		else
			-- Show all categories
			filteredFiles = nil;
		end
		if(EasyLiveModel.searchText) then
			EasyLiveModel.searchText = nil
			return true;
		end
	else
		if(EasyLiveModel.searchText ~= searchText) then
			EasyLiveModel.searchText = searchText
			filteredFiles = {};
			
			-- Determine which categories to search
			local categoriesToSearch = {};
			local category = EasyLiveModel.GetCategoryButtons()[EasyLiveModel.category_index];
			if(category and category.name == "all") then
				-- Search all expanded categories
				for i, cat in ipairs(EasyLiveModel.GetAllFiles()) do
					if(cat.attr.expanded) then
						categoriesToSearch[#categoriesToSearch + 1] = cat;
					end
				end
			else
				-- Search only the selected category
				local idx = EasyLiveModel.category_index - 1;
				if(EasyLiveModel.GetAllFiles()[idx]) then
					categoriesToSearch[#categoriesToSearch + 1] = EasyLiveModel.GetAllFiles()[idx];
				end
			end
			
			for _, category in ipairs(categoriesToSearch) do
				local files = {name="category", attr = category.attr};
				for _, file in ipairs(category) do
					if(file.attr.filename:find(searchText, 1, true) or (file.attr.text and file.attr.text:find(searchText, 1, true))) then
						files[#files+1] = file;
					end
				end
				filteredFiles[#filteredFiles+1] = files
			end
			return true
		end
	end
end

function EasyLiveModel.RefreshFileTreeView() 
	if(page) then
		page:CallMethod("tvwFiles","SetDataSource", EasyLiveModel.GetAllFilesWithFilters());
		page:CallMethod("tvwFiles","DataBind", true);
	end
end

-- TODO: handle text search
function EasyLiveModel.OnTextChange(name, mcmlNode)
	local text = mcmlNode:GetUIValue()
	if(text and text:match("^[/?]")) then
		EasyLiveModel.searchTimer = EasyLiveModel.searchTimer or commonlib.Timer:new({callbackFunc = function(timer)
			if(page) then
				local text = page:GetUIValue("text") or ""
				local searchText = text:match("^[/?](.+)")
				if(EasyLiveModel.SetSearchText(searchText)) then
					EasyLiveModel.RefreshFileTreeView()
				end
			end
		end})
		EasyLiveModel.searchTimer:Change(500);
	else
		if(EasyLiveModel.SetSearchText()) then
			EasyLiveModel.RefreshFileTreeView()
		end
		local filepath = PlayerAssetFile:GetValidAssetByString(text);
		if(filepath) then
			EasyLiveModel.SetModelFilename(filepath);
		end
	end
end

function EasyLiveModel:IsVisible()
    return page and page:IsVisible();
end


function EasyLiveModel:UpdateManipulators()
	self:DeleteManipulators();
    if(previewEntity) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelManipContainer.lua");
        local EditModelManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditModelManipContainer");
        local manipCont = EditModelManipContainer:new();
        manipCont:ShowPosition(false)
        manipCont:SetShowDragMoveIcon(true)
        manipCont:init();
        manipCont.scaleManip:SetShowXAxis(false);
        manipCont.scaleManip:SetShowZAxis(false);
        -- manipCont.scaleManip:SetInvertYAxis(true);
        manipCont.scaleManip:SetCanPickAxisLine(false);
        manipCont.scaleManip:SetShowAxisLine(false);
        manipCont.scaleManip.radius = math.min(5, math.max(previewEntity:GetHeight() + 0.2, 2))
        -- manipCont.scaleManip.yColor = "#00FF00"; -- green color for Y axis
        self:AddManipulator(manipCont);
        self.modelManip = manipCont;
        manipCont:connectToDependNode(previewEntity);
    end
end

-- Display name mapping functions

-- Extract base filename from path (remove directory path)
-- @param filename: full path filename
-- @return: base filename without path
function EasyLiveModel.GetBaseFilename(filename)
    if(not filename or filename == "") then
        return filename;
    end
    -- Remove everything before and including the last / or \
    return filename:match("([^/\\]+)$") or filename;
end

-- Get the full path to the display name mapping file
function EasyLiveModel.GetDisplayNameFilePath()
    return ParaWorld.GetWorldDirectory() .. EasyLiveModel.displayNameFileName;
end

-- Invalidate display name cache - call when switching worlds
function EasyLiveModel.InvalidateDisplayNameCache()
    EasyLiveModel.displayNameMapping = nil;
    EasyLiveModel.localFileDisplayNameCache = nil;
end

-- Load display name mapping from file
function EasyLiveModel.LoadDisplayNameMapping()
    if(EasyLiveModel.displayNameMapping) then
        return EasyLiveModel.displayNameMapping;
    end
    
    local filepath = EasyLiveModel.GetDisplayNameFilePath();
    EasyLiveModel.displayNameMapping = {};
    
    -- Load CSV file (name,value format)
    local file = ParaIO.open(filepath, "r");
    if(file:IsValid()) then
        local content = file:GetText(0, -1);
        file:close();
        
        if(content and content ~= "") then
            -- Parse CSV lines
            for line in content:gmatch("[^\r\n]+") do
                if(line ~= "" and not line:match("^#")) then -- Skip empty lines and comments
                    -- Split by comma, handle quoted values
                    local name, value = line:match("^([^,]+),(.*)$");
                    if(name and value) then
                        -- Remove quotes if present
                        if(value:match("^\".*\"$")) then
                            value = value:sub(2, -2);
                        end
                        EasyLiveModel.displayNameMapping[name] = value;
                    end
                end
            end
        end
    end
    EasyLiveModel.RegisterWorldEvents()
    
    return EasyLiveModel.displayNameMapping;
end

-- Save display name mapping to file
function EasyLiveModel.SaveDisplayNameMapping()
    if(not EasyLiveModel.displayNameMapping) then
        return;
    end
    
    local filepath = EasyLiveModel.GetDisplayNameFilePath();
    
    -- Save as CSV file (name,value format)
    local csvLines = {};
    csvLines[#csvLines + 1] = "# Display name mapping for local files (name,displayName)";
    
    -- Sort keys for consistent output
    local keys = {};
    for k in pairs(EasyLiveModel.displayNameMapping) do
        keys[#keys + 1] = k;
    end
    table.sort(keys);
    
    for _, name in ipairs(keys) do
        local displayName = EasyLiveModel.displayNameMapping[name];
        if(displayName and displayName ~= "") then
            -- Escape quotes in display name if needed
            if(displayName:find(",") or displayName:find("\"")) then
                displayName = "\"" .. displayName:gsub("\"", "\"\"") .. "\"";
            end
            csvLines[#csvLines + 1] = name .. "," .. displayName;
        end
    end
    
    local content = table.concat(csvLines, "\n");
    local file = ParaIO.open(filepath, "w");
    if(file:IsValid()) then
        file:WriteString(content);
        file:close();
    end
end

-- Set display name for a filename
-- @param filename: the filename to set display name for
-- @param displayName: the custom display name, if nil or empty, removes the mapping
function EasyLiveModel.SetDisplayName(filename, displayName)
    if(not filename or filename == "") then
        return;
    end
    
    local baseFilename = EasyLiveModel.GetBaseFilename(filename);
    EasyLiveModel.LoadDisplayNameMapping();
    
    if(displayName and displayName ~= "") then
        EasyLiveModel.displayNameMapping[baseFilename] = displayName;
        GameLogic.AddBBS(nil, format(L"已设置文件 %s 的显示名称为: %s", baseFilename, displayName), 3000, "0 255 0");
    else
        EasyLiveModel.displayNameMapping[baseFilename] = nil;
        GameLogic.AddBBS(nil, format(L"已清除文件 %s 的显示名称", baseFilename), 3000, "0 255 0");
    end
    
    EasyLiveModel.SaveDisplayNameMapping();
    
    -- Refresh the file tree view to show new display names
    if(page) then
        EasyLiveModel.RefreshFileTreeView();
    end
end

-- Get display name for a filename, returns original filename if no custom name is set
-- @param filename: the filename to get display name for
-- @return: display name or original filename
function EasyLiveModel.GetDisplayName(filename)
    if(not filename or filename == "") then
        return filename;
    end
    
    local baseFilename = EasyLiveModel.GetBaseFilename(filename);
    EasyLiveModel.LoadDisplayNameMapping();
    return EasyLiveModel.displayNameMapping[baseFilename] or filename;
end

-- Show dialog to set display name for a file
function EasyLiveModel.ShowSetDisplayNameDialog(filename)
    if(not filename or filename == "") then
        return;
    end
    
    local currentDisplayName = EasyLiveModel.GetDisplayName(filename);
    -- If current display name is same as filename, show empty as default
    local defaultText = (currentDisplayName == filename) and "" or currentDisplayName;
    
    EnterTextDialog.ShowPage(format(L"请输入文件的显示名称:\n%s", filename), function(result)
        if(result) then
            EasyLiveModel.SetDisplayName(filename, result);
        end
    end, defaultText);
end

-- Quick method to get display name from filename - can be called from external code
-- @param filename: the filename to get display name for
-- @return: display name if custom name is set, otherwise original filename
function EasyLiveModel.GetDisplayNameForFile(filename)
    return EasyLiveModel.GetDisplayName(filename);
end

-- Quick method to set display name from external code
-- @param filename: the filename to set display name for
-- @param displayName: the custom display name
function EasyLiveModel.SetDisplayNameForFile(filename, displayName)
	EasyLiveModel.SetDisplayName(filename, displayName);
end

-- Close FindBlockTask window
function EasyLiveModel.CloseFindEntityWindow()
    if(EasyLiveModel.findEntityTask and not EasyLiveModel.findEntityTask.finished) then
        EasyLiveModel.findEntityTask.OnClose()
        EasyLiveModel.findEntityTask = nil;
    end
end

-- Open object list (similar to EasyModel:OnOpenObjectList)
function EasyLiveModel.OnOpenObjectList()
    if(EasyLiveModel.findEntityTask and not EasyLiveModel.findEntityTask.finished) then
        -- already open
        return;
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FindBlockTask.lua");
    local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
    local task = MyCompany.Aries.Game.Tasks.FindBlockTask:new()
    EasyLiveModel.findEntityTask = task;
    local editableWorld = GameLogic.CreateGetEditableWorld();
    task:ShowPage(true, nil, function()
        EasyLiveModel.findEntityTask = nil;
    end, function(entity)
        if(entity:IsBlockEntity() and editableWorld:IsEditableBlock(entity:GetBlockPos())) then
            entity.isFromEditableWorld = true;
            -- this will include all editable block entities
            return true;
        end
        return entity.isFromEditableWorld == true;
    end, L"物品列表", function(index)
        local entity = FindBlockTask.GetResultAt(index);
	    if(entity) then
            EasyLiveModel.DestroyPreviewEntity();
            FindBlockTask.SetSelectedIndexByResultIndex(index)
            FindBlockTask.GotoItemAtIndex(index);
            -- FindBlockTask.OnClose()
        end
        return true
    end, "easy")
end

-- Teleport to instance of live model with matching filename using FindBlockTask
-- @param filename: the filename to search for
function EasyLiveModel.TeleportToModelInstance(filename)
	if(not filename or filename == "") then
		return;
	end
    EasyLiveModel.DestroyPreviewEntity()
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FindBlockTask.lua");
	local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
	
	-- Get base filename for comparison
	local baseFilename = EasyLiveModel.GetBaseFilename(filename);
	
	-- Create a filter function to find live models with matching filename
	local function filterLiveModels(entity)
		if(entity and entity.class_name == "LiveModel" and entity.GetModelFile) then
			local modelFile = entity:GetModelFile();
			if(modelFile) then
				return filename == modelFile;
			end
		end
		return false;
	end
	
	-- Create click callback to teleport and close
	local function onClickCallback(index)
		FindBlockTask.SetSelectedIndexByResultIndex(index);
		FindBlockTask.GotoItemAtIndex(index);
		-- FindBlockTask.OnClose();
		return true; -- Prevent default click behavior
	end
	
	-- Show FindBlockTask with filtered results
	local task = FindBlockTask:new();
	task:ShowPage(true, nil, nil, filterLiveModels, L"传送到实例: " .. baseFilename, onClickCallback);
end

-- Context menu for file operations
function EasyLiveModel.OnClickFileContextMenuItem(node)
	local filename = EasyLiveModel.rightCtxValue
	if(node.Name == "setDisplayName") then
		EasyLiveModel.ShowSetDisplayNameDialog(filename);
	elseif(node.Name == "teleportToInstance") then
		EasyLiveModel.TeleportToModelInstance(filename);
	elseif(node.Name == "loadtemplate") then
		BlockTemplatePage.CreateFromTemplate(filename);
	elseif(node.Name == "delete") then
		local path = GameLogic.RunCommand(string.format("/deletefile %s -backup", filename))
		if path then
			path = string.gsub(path, ParaIO.GetWritablePath(), "")
			GameLogic.AddBBS(nil, L"成功删除文件并备份为："..commonlib.Encoding.DefaultToUtf8(path))
		end
		EasyLiveModel.UpdateExistingFiles()
		if page then
			page:Refresh(0)
		end
	elseif(node.Name == "copypath") then
		ParaMisc.CopyTextToClipboard(filename or "");
		GameLogic.AddBBS(nil, L"文件路径已复制到剪贴板", 3000, "0 255 0");
	end
end

function EasyLiveModel.OnShowFileContextMenu(x, y, width, height)
	if(EasyLiveModel.contextMenuFile == nil) then
		EasyLiveModel.contextMenuFile = CommonCtrl.ContextMenu:new{
			name = "EasyLiveModel.contextMenuFile",
			width = 180,
			height = 30,
			DefaultNodeHeight = 32,
			onclick = EasyLiveModel.OnClickFileContextMenuItem,
		};
		local node = EasyLiveModel.contextMenuFile.RootNode;
		node:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
		local node = node:GetChild(1);
	end
	local ctl = EasyLiveModel.contextMenuFile
	local node = ctl.RootNode:GetChild(1);
	if(node) then
		node:ClearAllChildren();
		local filename = EasyLiveModel.rightCtxValue

		local _ctxMenuItems
		local isModel = filename:match("%.x$") or filename:match("%.fbx$") or 
						filename:match("%.FBX$") or filename:match("%.bmax$") or 
						filename:match("%.glb$") or filename:match("%.gltf$") or 
						filename:match("%.ply$")
		local isBmax = filename:match("%.bmax$")
		local isX = filename:match("%.x$")
		
		if isBmax then
			_ctxMenuItems = {
				{name="setDisplayName", text=L"设置显示名称"}, 
				{name="teleportToInstance", text=L"传送到实例"},
				{name="loadtemplate", text=L"展示bmax原型"},
				{name="copypath", text=L"复制路径"},
				{name="delete", text=L"删除文件"},
			};
		elseif isModel then
			_ctxMenuItems = {
				{name="setDisplayName", text=L"设置显示名称"}, 
				{name="teleportToInstance", text=L"传送到实例"},
				{name="copypath", text=L"复制路径"},
				{name="delete", text=L"删除文件"},
			};
		else
			_ctxMenuItems = {
				{name="copypath", text=L"复制路径"},
				{name="delete", text=L"删除文件"},
			};
		end
		
		for index, item in ipairs(_ctxMenuItems) do
			local text = item.text or item.name;
			if(text) then
				local uiname;
				if(item.name~="") then
					uiname = "EasyLiveModel.contextMenuFile."..item.name
				end
				node:AddChild(CommonCtrl.TreeNode:new({Text = text, uiname=uiname, Name = item.name, Type = "Menuitem", onclick = nil, }))
			end
		end
		ctl.height = (#_ctxMenuItems) * 32 + 4;
	end
	if(not x or not width) then
		x, y, width, height = _guihelper.GetLastUIObjectPos();
        x = x or mouse_x or 0;
        y = y or mouse_y or 0;
        width = width or  0;
        height = height or 0;
	end
	if(x and width) then
		EasyLiveModel.contextMenuFile:Show(x, y+height);
	end
end

function EasyLiveModel.ShowFileContextMenu(filename, filesize)
	EasyLiveModel.rightCtxValue = filename
    EasyLiveModel.rightCtxFileSize = filesize
    if(GameLogic.IsReadOnly()) or (filesize or 0) <= 0 then
        return
    end
	EasyLiveModel.OnShowFileContextMenu()
end