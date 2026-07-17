--[[
Title: EasyBuilder Model Task
Author(s): LiXizhi
Date: 2025/09/21
Desc: 

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.lua");
local EasyModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyModel");
EasyModel:ShowPage(true)
EasyModel.TakeItem(279)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockInEntityHand.lua");
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
local EntityLiveModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel")
local Color = commonlib.gettable("System.Core.Color");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local MobileUIRegister = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileUIRegister");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");
local EasyModel = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyModel"));

local curInstance;
local page;
local quickSelectBarPage;

local selected_itemStack;
-- Always a top level task
EasyModel.is_top_level = true;
EasyModel.SlotsNames = {
    Pick = 0,
    Delete = -1,
    Select = -2,
    ColorBlock = 8, -- default slot 8 (can be replaced)
    ColorStair = 9, -- default slot 9 (can be replaced)
}
EasyModel.selectedSlot = nil;

EasyModel.lastSelectedSlot = 8 -- default to ColorBlock

-- Brush modes: add, replace, fill, delete
EasyModel.currentBrushMode = "add" -- default to "add"

-- Quick Select Bar
EasyModel.quickSelectBarSlots = {}
EasyModel.quickSelectBarSelectedSlot = 8
EasyModel.leftClickToCreate = true; -- left click to create blocks by default. this is true for touch devices.

function EasyModel:ctor()
    -- Initialize default blocks for quick select bar slots (can be replaced by user)
    EasyModel.quickSelectBarSlots[8] = EasyModel.quickSelectBarSlots[8] or ItemStack:new():Init(10, 99999) -- Slot 8: ColorBlock (default)
    EasyModel.quickSelectBarSlots[9] = EasyModel.quickSelectBarSlots[9] or ItemStack:new():Init(280, 99999) -- Slot 9: ColorStair (default)
    EasyModel.leftClickToCreate = System.options.IsTouchDevice or System.options.IsMobilePlatform;
end

function EasyModel.GetInstance()
    return curInstance;
end

-- follow EditLightTask: keep a static InitPage(Page)
function EasyModel.InitPage(Page)
    page = Page;
end

-- Initialize QuickSelectBar page
function EasyModel.InitQuickSelectBarPage(Page)
    quickSelectBarPage = Page;
    EasyModel.CheckShowColorsPage()
end

function EasyModel:Redo()
end

function EasyModel:Undo()
end

-- follow EditLightTask lifecycle
function EasyModel:Run()
    curInstance = self;
    self:ShowPage(true);
    self:ShowQuickSelectBarPage(true);
    self:LoadSceneContext();
    MobileUIRegister.SetForceUseMobileUI("SelectBlocksTask", true);
    MobileUIRegister.SetForceUseMobileUI("ExportTask", true);
    MobileUIRegister.SetForceUseMobileUI("MirrorWnd", true);
    MobileUIRegister.SetForceUseMobileUI("TransformWnd", true);

    -- force using the main player 
    if(EntityManager:GetFocus()~= EntityManager.GetPlayer()) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMap.lua");
        local EasyMap = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyMap");
        EasyMap.PossessChar(EntityManager.GetPlayer())
    end
    
    -- Initialize player's hand-in item with the selected item
    if EasyModel.selectedSlot and EasyModel.selectedSlot > 0 then
        EasyModel.SetSelectedItemStack(EasyModel.quickSelectBarSlots[EasyModel.selectedSlot])
    end
end

function EasyModel:OnExit()
    EasyModel.Cancel()
end

function EasyModel.Cancel()
    local self = curInstance;
    if(self) then 
        curInstance = nil;
        self:SetFinished();
        self:CloseWindow();
        self:CloseQuickSelectBarWindow();
        self:UnloadSceneContext();
        self:ClearQuickSelectBarSlots()

        MobileUIRegister.SetForceUseMobileUI("SelectBlocksTask", false);
        MobileUIRegister.SetForceUseMobileUI("ExportTask", false);
        MobileUIRegister.SetForceUseMobileUI("MirrorWnd", false);
        MobileUIRegister.SetForceUseMobileUI("TransformWnd", false);
    end
end

function EasyModel:ShowPage(bShow)
    if(not page) then
        if(not EasyModel.selectedSlot) then
            EasyModel.OnSelectSlot("ColorBlock")
        end
        
        local width, height = 235, 400;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.html", 
                name = "EasyModel.ShowPage", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide=false, 
                style = CommonCtrl.WindowFrame.ContainerStyle,
                enable_esc_key = false,
                allowDrag = false,
                click_through = true, 
                bShow = (bShow ~= false),
                directPosition = true,
                    align = "_rt",
                    x = -width-20,
                    y = 64,
                    width = width,
                    height = height,
            };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
        curInstance = curInstance or self;
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
end

function EasyModel:ShowQuickSelectBarPage(bShow)
    local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
    if(not quickSelectBarPage) then
        if(not EasyModel.quickSelectBarSelectedSlot) then
            -- Default to slot 8 (ColorBlock)
            EasyModel.quickSelectBarSelectedSlot = 8
        end
        
        local width, height = 800, 72;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.QuickSelectBar.html", 
                name = "EasyModel.QuickSelectBar", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide=false, 
                style = CommonCtrl.WindowFrame.ContainerStyle,
                enable_esc_key = false,
                allowDrag = false,
                click_through = false, 
                bShow = (bShow ~= false),
                directPosition = true,
                    align = "_ctb",
                    x = 0,
                    y = - 20,
                    width = width,
                    height = height,
            };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
        curInstance = curInstance or self;
        if(params._page) then
            quickSelectBarPage = params._page;
            params._page.OnClose = function()
                quickSelectBarPage = nil;
                QuickSelectBar.ShowPage(true)
            end
        end
    else
        if(bShow == false) then
            quickSelectBarPage:CloseWindow();
            quickSelectBarPage = nil;
        else
            quickSelectBarPage:Refresh(0.1);
        end
    end
    if(bShow ~= false) then
        QuickSelectBar.ShowPage(false)
    else
        QuickSelectBar.ShowPage(true)
    end
end

function EasyModel.CloseSelectionWindow()
    if(EasyModel.selectTask and not EasyModel.selectTask.finished) then
        EasyModel.selectTask.CancelSelection()
        EasyModel.selectTask = nil;
    end
end

-- static function
function EasyModel.CloseEditModelWindow()
    if(EasyModel.editModelTask and not EasyModel.editModelTask.finished) then
        EasyModel.editModelTask:OnExit()
        EasyModel.editModelTask = nil;
    end
end

-- static function
function EasyModel.CloseAddLiveModelWindow()
    if(EasyModel.addLiveModelTask and not EasyModel.addLiveModelTask.finished) then
        EasyModel.addLiveModelTask:OnExit()
        EasyModel.addLiveModelTask = nil;
    end
end

function EasyModel.CloseCloneBagWindow()
    if( EasyModel.cloneBagTask and not EasyModel.cloneBagTask.finished) then
        EasyModel.cloneBagTask:OnExit()
        EasyModel.cloneBagTask = nil;
    end
end

function EasyModel.CloseAllSubToolWindows()
    EasyModel.ShowColorsPage(false)
    EasyModel.ShowAllBlocksPage(false)
    EasyModel.CloseSelectionWindow()
    EasyModel.CloseEditModelWindow()
    EasyModel.CloseAddLiveModelWindow()
    EasyModel.CloseCloneBagWindow()
end

function EasyModel:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
    EasyModel.CloseAllSubToolWindows()
    EasyModel.currentBrushMode = "add" -- reset to "add" mode
    EasyModel:ShowEditActionsForEntity(nil)
end

function EasyModel:CloseQuickSelectBarWindow()
    if(quickSelectBarPage) then
        quickSelectBarPage:CloseWindow();
        quickSelectBarPage = nil;
    end
end

function EasyModel:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

function EasyModel:keyPressEvent(event)
    local ItemEasyBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Items.ItemEasyBuilder");
    ItemEasyBuilder:keyPressEvent(event)
    if(event:isAccepted()) then
        return
    end
	local dik_key = event.keyname;
    if(dik_key == "DIK_ESCAPE")then
        EasyModel.OnClickClose()
        event:accept()
    elseif(dik_key == "DIK_E")then
        -- EasyModel.OnSelectSlot("More")
        EasyModel.OnClickClose()
        event:accept()
    elseif(event.ctrl_pressed and dik_key == "DIK_S") then
        EasyModel.OnClickSave()
        event:accept()
    elseif(dik_key == "DIK_P")then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyPlay.lua");
        local EasyPlay = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyPlay");
        EasyPlay.OnClickPossession()
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

function EasyModel:CanReachBlockAt(x,y,z)
    return GameLogic.CreateGetEditableWorld():IsEditableBlock(x, y, z)
end

function EasyModel:CanDestroyBlockAt(x,y,z)
    return GameLogic.CreateGetEditableWorld():IsEditableBlock(x, y, z)
end

function EasyModel:mousePressEvent(event)
    local context = self:GetSceneContext();

    if(event.mouse_button == "left" and ((EasyModel.selectedSlot ~= EasyModel.SlotsNames.Select and EasyModel.selectedSlot ~= EasyModel.SlotsNames.Delete))) then
        context._super.mousePressEvent(context, event);
    end

    if(event.mouse_button == "left") then
        EasyModel.isLongHoldDeleted = false;
        if(not event:isAccepted()) then
            -- only enable long hold to delete block timer, when event is not accepted(not dragging some live entity)
            context:EnableMouseDownTimer(true);    
        end
    end
end

function EasyModel:mouseMoveEvent(event)
    local context = self:GetSceneContext();
    if(event.mouse_button == "left" and ((EasyModel.selectedSlot ~= EasyModel.SlotsNames.Select and EasyModel.selectedSlot ~= EasyModel.SlotsNames.Delete))) then
        context._super.mouseMoveEvent(context, event);
    end
    if(event:GetDragDist() > 10) then
        -- disable long hold to delete block timer when dragging
        context:EnableMouseDownTimer(false);
        context:UpdateClickStrength(-1);
    end
end

function EasyModel:mouseReleaseEvent(event)
    local context = self:GetSceneContext();

    if(event.mouse_button == "left" and ((EasyModel.selectedSlot ~= EasyModel.SlotsNames.Select and EasyModel.selectedSlot ~= EasyModel.SlotsNames.Delete))) then
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

function EasyModel:handleMiddleClickScene(event, result)
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

function EasyModel:OnLeftLongHoldBreakBlock(fDelta, result)
    if not curInstance or not result or not result.blockX then return end
    if EasyModel.selectedSlot and EasyModel.selectedSlot >= 1 then
        EasyModel:OnDeleteBlock(result)
        EasyModel.isLongHoldDeleted = true;
    end
end

function EasyModel:handleRightClickScene(event, result)
    self:handleSceneClick(event, result)
end

function EasyModel:handleLeftClickScene(event, result)
    self:handleSceneClick(event, result)
    EasyModel.isLongHoldDeleted = false;
end

-- static function: edit a live entity
function EasyModel:EditLiveEntity(entity, onFinishCallback)
    if(entity and entity:isa(EntityManager.EntityLiveModel) and entity.isFromEditableWorld) then
        EasyModel.ShowColorsPage(false)
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
        local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
        local task = EditModelTask:new({theme = "easy", add_to_history = true});
        task:Run()
        EasyModel.editModelTask = task;
        
        task:SelectModel(entity);
        task:SetTransformMode(true);
        
        task:Connect("taskFinished", function() 
            if(curInstance) then
                curInstance:CheckRestoreSceneContext()
            end
            EasyModel.editModelTask = nil;
            GameLogic.CreateGetEditableWorld():AddEditCount();
            if(onFinishCallback) then
                onFinishCallback();
            end
        end)
        task:Connect("modelChanged", function() 
            GameLogic.CreateGetEditableWorld():AddEditCount();
            local entity = task:GetSelectedModel()
            if(entity) then
                -- in case of duplicated models
                if(not GameLogic.CreateGetEditableWorld():AddLiveEntity(entity, true)) then
                    EasyModel.CloseEditModelWindow()
                end
            else
                task:OnExit()
            end
        end)
        return true;
    elseif(not entity) then
        EasyModel.CloseEditModelWindow()
    end
end

function EasyModel:OnSelectSceneBlock(result, event)
    if(result.entity and result.entity.isFromEditableWorld and result.entity.class_name == "LiveModel") then
        self:EditLiveEntity(result.entity)
        return
    end
    if(GameLogic.CreateGetEditableWorld():IsEditableBlock(result.blockX, result.blockY, result.blockZ)) then
        local block = BlockEngine:GetBlock(result.blockX, result.blockY, result.blockZ)
        if block then
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
            local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
            local task = SelectBlocks:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ,
                    clickToSelect=true, onlySelectEditable = true, autoSaveBMaxToTemp = true,
                    add_to_history = true,
                })
            task:Connect("selectionCanceled", function()
                if(curInstance) then
                    curInstance:CheckRestoreSceneContext()
                    EasyModel.OnSelectSlot(EasyModel.quickSelectBarSelectedSlot or 8)
                    
                    if(task.saveAsBmaxPath) then
                        local filename = commonlib.Files.GetRelativePath(task.saveAsBmaxPath)
                        EasyModel.AddLiveModelFromFile(filename)
                    end
                end
                EasyModel.selectTask = nil;
            end)
            task:Run();
            EasyModel.selectTask = task;
        end
    else
        GameLogic.AddBBS(nil, L"此方块不可选择", 3000, "255 0 0");
    end
end

function EasyModel.OnOpenCloneBag()
    EasyModel.CloseSelectionWindow()
    EasyModel.CloseEditModelWindow()
    EasyModel.CloseAddLiveModelWindow()
    EasyModel.CloseCloneBagWindow()
    EasyModel.ShowColorsPage(false)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCloneBag.lua");
    local EasyCloneBag = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyCloneBag");
    local task = EasyCloneBag:new({})
    task:Connect("bagClosed", function()
        if(curInstance) then
            curInstance:CheckRestoreSceneContext()
        end
        EasyModel.cloneBagTask = nil;
    end)
    task:Connect("beforeItemClicked", function(itemstack)
        
    end)
    task:Connect("afterEntityCreated", function(entity)
        if(GameLogic.CreateGetEditableWorld():AddLiveEntity(entity, true)) then
            -- add to history command
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
            local task = MyCompany.Aries.Game.Tasks.DragEntity:new({addToHistory=true})
            task:CreateEntity(entity);
        end
    end)
    task:Run()
    EasyModel.cloneBagTask = task;
end

function EasyModel:OnPickSceneBlock(result, event)
    if not curInstance or not result or not result.blockX then return end
    local x, y, z = result.blockX, result.blockY, result.blockZ
    local side = result.side
    local block_template = BlockEngine:GetBlock(x, y, z)
    if block_template then
        local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient")
        local item = ItemClient.GetItem(block_template.id)
        if item and block_template.id < 2000 then
            -- only pick normal blocks id < 2000
            local item_stack = item:PickItemFromPosition(x, y, z, side)
            EasyModel.TakeItemStack(item_stack:Copy())
            
            local brushModeText = EasyModel.GetBrushModeText()
            EasyModel.UpdateStatus(format(L"已吸取:%s，点击场景%s", item:GetDisplayName(), brushModeText))
            self:RefreshPage()
        end
    end
end

function EasyModel.SelectMeInHand(delayTime)
    local function SelectMe_()
        if curInstance then
            curInstance:CheckRestoreSceneContext()
        else
            GameLogic.RunCommand("/take -select -bag 5")
        end
    end
    if(delayTime ==  0) then
        SelectMe_()
    else
        commonlib.TimerManager.SetTimeout(SelectMe_, delayTime or 10)
    end
end

function EasyModel:ShowCodeBlockWindow(event)
	if event and not event.bShow then
        GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow",EasyModel.ShowCodeBlockWindow,EasyModel)
        EasyModel.SelectMeInHand()
	end
end

function EasyModel.OnCloseMovieController()
    AllContext:GetContext("movie"):SetForceEditorMode(false);
    GameLogic.GetFilters():remove_filter("OnCloseMovieController",EasyModel.OnCloseMovieController)
    GameLogic.RunCommand("/show quickselectbar");
    EasyModel.SelectMeInHand()
end

function EasyModel.OnEntityDestroyed()
    EasyModel:ShowEditActionsForEntity(nil)
end

-- static function: there can only be one entity to show edit buttons
-- this function can be called outside EasyModel class, like in EntityLiveModel
function EasyModel:ShowEditActionsForEntity(entity, onFinishCallback)
    local self = EasyModel;
    if not entity then
        -- Restore drag state for previous entity
        if self.currentEditEntity then
            if self.currentEditEntity.SetTempCanDrag then
                self.currentEditEntity:SetTempCanDrag(nil)
            end
            self.currentEditEntity:Disconnect("beforeDestroyed", EasyModel, EasyModel.OnEntityDestroyed);
        end
        self.currentEditEntity = nil
        -- Hide the marker if it exists
        if self.editActionMarker then
            self.editActionMarker.visible = false
        end
        -- Stop position updates
        if self.editActionPositionTimer then
            self.editActionPositionTimer:Change()
        end
        return
    end
    self.onFinishEditActionCallback = onFinishCallback

    -- Check if entity has changed
    if entity ~= self.currentEditEntity then
        -- Restore drag state for previous entity
        if self.currentEditEntity then
            if self.currentEditEntity.SetTempCanDrag then
                self.currentEditEntity:SetTempCanDrag(nil)
            end
            self.currentEditEntity:Disconnect("beforeDestroyed", EasyModel, EasyModel.OnEntityDestroyed);
        end
        self.currentEditEntity = entity
        self.currentEditEntity:Connect("beforeDestroyed", EasyModel, EasyModel.OnEntityDestroyed);
        -- Enable drag for new entity
        if self.currentEditEntity and self.currentEditEntity.SetTempCanDrag then
            self.currentEditEntity:SetTempCanDrag(true)
        end
        
        -- Create marker if it doesn't exist
        if not self.editActionMarker or not self.editActionMarker:IsValid() then
            -- Create container for the edit action UI
            self.editActionMarker = ParaUI.CreateUIObject("container", "edit_action_container", "_lt", 0, 0, 100, 48)
            self.editActionMarker.background = ""
            self.editActionMarker.zorder = -100
            self.editActionMarker.click_through = true
            
            -- Create edit button
            local editBtn = ParaUI.CreateUIObject("button", "edit_btn", "_lt", 0, 0, 72, 36)
            editBtn.font = "System;14;bold"
            editBtn.text = L"编辑"
            editBtn.background = "Texture/Aries/Creator/keepwork/Mobile/icon/caozuoqiu_56x56_32bits.png#0 0 56 56:18 18 18 18"
            _guihelper.SetFontColor(editBtn, "#464646")
            
            editBtn:SetScript("onclick", function()
                local entity = self.currentEditEntity
                EasyModel:ShowEditActionsForEntity(nil)
                if entity then
                    EasyModel:EditLiveEntity(entity, function()
                        if(EasyModel.onFinishEditActionCallback) then
                            EasyModel.onFinishEditActionCallback()
                            EasyModel.onFinishEditActionCallback = nil
                        end
                    end)
                end
            end)
            
            self.editActionMarker:AddChild(editBtn)
            
            -- Create background arrow (down arrow, positioned below the button)
            local bg = ParaUI.CreateUIObject("button", "edit_action_bg", "_ctb", 0, 0, 12, 8)
            bg.background = "Texture/blocks/icons/arrow_down.png;12 28 40 31"
            bg.enabled = false
            _guihelper.SetUIColor(bg, "#26f749ff")
            self.editActionMarker:AddChild(bg)
            
            self.editActionMarker:AttachToRoot()
            
            -- Initialize position tracking
            self.editActionLastPos = {x = 0, y = 0, initialized = false}
            self.editActionTargetPos = {x = 0, y = 0}
        end
        
        -- Update marker width
        self.editActionMarker.width = 72
        self.editActionMarker.visible = true
        
        -- Start position update timer
        if not self.editActionPositionTimer then
            self.editActionPositionTimer = commonlib.Timer:new({
                callbackFunc = function(timer)
                    EasyModel:UpdateEditActionMarkerPosition()
                end
            })
        end
        self.editActionPositionTimer:Change(0, 30) -- Update every 30ms
        
        -- Reset position initialization
        self.editActionLastPos.initialized = false
    end
end

-- static function: Update the position of the edit action marker
function EasyModel:UpdateEditActionMarkerPosition()
    local self = EasyModel
    local entity = self.currentEditEntity
    
    if not entity then
        return
    end
    
    -- Hide marker when entity is being dragged
    if entity.IsDragging and entity:IsDragging() then
        self.editActionMarker.visible = false
        return
    else
        self.editActionMarker.visible = true
    end
    
    -- Get entity position
    local x, y, z = entity:GetPosition()
    if not x or not y or not z then
        self:ShowEditActionsForEntity(nil)
        return
    end
    
    -- Add offset to show marker above entity
    local height = math.min(5, math.max(entity:GetHeight(), 1))
    y = y + height
    
    -- Convert 3D position to screen coordinates
    self.editActionScreenPos = self.editActionScreenPos or {x=0, y=0}
    ParaScene.GetScreenPosFrom3DPoint(x, y, z, self.editActionScreenPos)
    
    -- Update target position
    self.editActionTargetPos.x = math.floor(self.editActionScreenPos.x - (self.editActionMarker.width / 2))
    self.editActionTargetPos.y = self.editActionScreenPos.y - self.editActionMarker.height
    
    -- Initialize last position if this is the first update
    if not self.editActionLastPos.initialized then
        self.editActionLastPos.x = self.editActionTargetPos.x
        self.editActionLastPos.y = self.editActionTargetPos.y
        self.editActionLastPos.initialized = true
    end
    
    -- Smoothly interpolate towards target position
    local smoothingFactor = 1 -- Instant positioning, can be reduced for smoothing
    self.editActionLastPos.x = self.editActionLastPos.x * (1.0 - smoothingFactor) + self.editActionTargetPos.x * smoothingFactor
    self.editActionLastPos.y = self.editActionLastPos.y * (1.0 - smoothingFactor) + self.editActionTargetPos.y * smoothingFactor
    
    -- Apply the smoothed position to the marker
    self.editActionMarker.x = self.editActionLastPos.x
    self.editActionMarker.y = self.editActionLastPos.y
end

function EasyModel:TryEditEntity(entity)
    if(entity) then
        if(entity:isa(EntityManager.EntityNPC)) then
            if(entity:OpenEditor("SelectModel")) then
                return true;
            end
        elseif(entity:isa(EntityManager.EntityMovieClip)) then
            EasyModel.OnClickClose();
            -- force editor mode regardless of if last mode is editor or not
            AllContext:GetContext("movie"):SetForceEditorMode(true);
            entity:OpenEditor("entity");
            GameLogic.RunCommand("/hide quickselectbar");
            GameLogic.GetFilters():add_filter("OnCloseMovieController",EasyModel.OnCloseMovieController)
           
            return true;
        elseif(entity:isa(EntityManager.EntityBlockCodeBase) or entity:isa(EntityManager.EntityImage)) then
            entity:OpenEditor("entity");
            if(entity:isa(EntityManager.EntityCode)) then
                EasyModel.OnClickClose()
                GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow",EasyModel.ShowCodeBlockWindow,EasyModel,"EasyModel");
            end
            return true;
        elseif(entity:isa(EntityManager.EntityLiveModel) and entity.isFromEditableWorld) then
            EasyModel:ShowEditActionsForEntity(entity)
            -- self:EditLiveEntity(entity)
            return true;
        end
    end
end

function EasyModel:handleSceneClick(event, result)
    if not event:isClick() or EasyModel.isLongHoldDeleted or not curInstance or not result or not result.blockX then return end
    local isProcessed = false;
    if event.alt_pressed or EasyModel.selectedSlot == EasyModel.SlotsNames.Pick then
        EasyModel:OnPickSceneBlock(result, event)
        event:accept()
        return
    elseif event.shift_pressed then
        local isCreate = (event.mouse_button == "left" and EasyModel.leftClickToCreate) or 
                        (event.mouse_button == "right" and not EasyModel.leftClickToCreate)
        if isCreate then
            if(result.blockX) then
                NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FillLineTask.lua");
                local task = MyCompany.Aries.Game.Tasks.FillLine:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_data = block_data, side = result.side, add_to_history = true,})
                task:Run();
            end
        else
            if(result.blockX) then
                NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
                local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({blockX=result.blockX, blockY=result.blockY, blockZ=result.blockZ, block_id = result.block_id, explode_time=200, add_to_history = true, })
                task:Run();
            else
                EasyModel:OnDeleteBlock(result, event)
            end
        end
        event:accept()
        return
    elseif event.ctrl_pressed then
        EasyModel.OnSelectSlot("Select")
        EasyModel:OnSelectSceneBlock(result, event)
        event:accept()
        return
    elseif((EasyModel.selectedSlot or 0)>=1 and not event.shift_pressed and not event.alt_pressed) then
        -- if the block is editable, then try to edit it first.
        if(event.mouse_button == "left") then
            local entity = result.entity or EntityManager.GetBlockEntity(result.blockX, result.blockY, result.blockZ)
            if(entity and EasyModel:TryEditEntity(entity)) then
                isProcessed = true;
            else
                EasyModel:ShowEditActionsForEntity(nil)
            end
            if not isProcessed and result.block_id and result.block_id>0 then
                if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
                    -- this fixed a bug where block entity is larger than the block like the physics block model.
                    local bx, by, bz = result.entity:GetBlockPos();
                    isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, EntityManager.GetPlayer(), result.side);
                else
                    isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
                end
            end
            if(not isProcessed and result.entity) then
                isProcessed = GameLogic.GetPlayerController():OnClickEntity(result.entity, result.blockX, result.blockY, result.blockZ, event.mouse_button);
            end
        else
            EasyModel:ShowEditActionsForEntity(nil)
        end
    end
    
    if(isProcessed) then
        event:accept()
        return
    end
    
    if EasyModel.selectedSlot == EasyModel.SlotsNames.Select then
        EasyModel:OnSelectSceneBlock(result, event)
        event:accept()
    elseif EasyModel.selectedSlot == EasyModel.SlotsNames.Delete then
        EasyModel:OnDeleteBlock(result, event)
        event:accept()
    elseif EasyModel.selectedSlot and EasyModel.selectedSlot >= 1 then
        local isCreate = (event.mouse_button == "left" and EasyModel.leftClickToCreate) or 
                        (event.mouse_button == "right" and not EasyModel.leftClickToCreate)
        if isCreate then
            EasyModel:OnCreateBlock(result, event)
        else
            EasyModel:OnDeleteBlock(result, event)
        end
        event:accept()
    end
end

function EasyModel:OnDeleteBlock(result, event)
    if(result.entity and result.entity.isFromEditableWorld and result.entity.class_name == "LiveModel") then
        EasyModel.OnSelectSlot("Select")
        EasyModel:OnSelectSceneBlock(result, event)
        return
    end
    if(GameLogic.CreateGetEditableWorld():IsEditableBlock(result.blockX, result.blockY, result.blockZ)) then
        local block = BlockEngine:GetBlock(result.blockX, result.blockY, result.blockZ)
        if block then
            local task = MyCompany.Aries.Game.Tasks.DestroyBlock:new({
                blockX = result.blockX,
                blockY = result.blockY,
                blockZ = result.blockZ,
                add_to_history = true,
                donot_drop_item = true, -- do not drop item in game mode. 
            })
            task:Run()
        end
    else
        GameLogic.AddBBS(nil, L"此方块不可删除", 3000, "255 0 0");
    end
end

-- based on BaseContext:OnCreateBlock(result, event)
function EasyModel:OnCreateBlock(result, event)
    if not selected_itemStack then
        return
    end
    local x, y, z = BlockEngine:GetBlockIndexBySide(result.blockX, result.blockY, result.blockZ, result.side);
    local itemStack = selected_itemStack:Copy()
    itemStack.color32 = selected_itemStack.color32;
    local block_id = itemStack.id;
    local block_data = nil;
    local item = itemStack:GetItem();
    if(not item) then
        LOG.std(nil, "debug", "EasyModel", "no block definition for %d", block_id or 0);
        return;
    end

    local side_region;
    if(result.y) then
        if(result.side == 4) then
            side_region = "upper";
        elseif(result.side == 5) then
            side_region = "lower";
        else
            local _, center_y, _ = BlockEngine:real(0,result.blockY,0);
            if(result.y > center_y) then
                side_region = "upper";
            elseif(result.y < center_y) then
                side_region = "lower";
            end
        end
    end

    local brushMode = EasyModel.GetCurrentBrushMode()
    if(brushMode == "add") then
        local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({
            blockX = x,
            blockY = y,
            blockZ = z,
            itemStack = itemStack,
            block_id = block_id,
            data = block_data,
            side = result.side,
            from_block_id = result.block_id,
            side_region = side_region,
            add_to_history = true,
        })
        task:Run();
    elseif(brushMode == "replace" or brushMode == "fill") then
        if(result.block_id and result.block_id < 4096 and block_id < 4096 and result.block_id ~= block_types.names.water and block_id ~= block_types.names.PhysicsModel and block_id ~= block_types.names.BlockModel) then
            block_data = item:GetBlockData(itemStack);
            -- Replace block at the cursor with the current block
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
            local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({
                blockX = result.blockX,
                blockY = result.blockY,
                blockZ = result.blockZ,
                to_id = block_id,
                to_data = block_data,
                max_radius = brushMode == "replace" and 0 or 30,
                preserveRotation = true,
                add_to_history = true,
            })
            local count = task:Run();
            if(count and count > 0) then
                GameLogic.GetFilters():apply_filters("create_block_event", "ReplaceBlocks", task);
            else
                -- Switch back to add mode when replace/fill fails
                if(not count) then
                    EasyModel.OnSelectBrushMode("add")
                    GameLogic.AddBBS("replaceBlocks", L"已自动为您切换到添加模式", 3000, "255 255 0");
                else
                    GameLogic.AddBBS("replaceBlocks", L"替换操作未改变任何方块, 可切换到添加模式", 5000, "255 255 0");
                end
            end
        end
    elseif(brushMode == "delete") then
        -- In delete brush mode, perform deletion on the target block
        EasyModel:OnDeleteBlock(result, event)
        event:accept()
        return
    elseif(brushMode == "select") then
        EasyModel:OnSelectSceneBlock(result, event)
        event:accept()
        return
    end
end

function EasyModel.CheckShowColorsPage()
    EasyModel.ShowColorsPage(EasyModel.IsPickedColorBlock())
end

-- Set the selected item stack and update player's hand-in item
function EasyModel.SetSelectedItemStack(itemStack)
    selected_itemStack = itemStack
    EasyModel.currentBrushMode = "add"

    -- Update player's hand-in item
    local player = EntityManager.GetPlayer()
    if player then
        BlockInEntityHand.RefreshRightHand(player, selected_itemStack)
        local obj = player:GetInnerObject();
		if(obj) then
			obj:ToCharacter():PlayAnimation(71); -- play hold item animation
		end
    end
end

function EasyModel.GetHandIndexByBlockId(blockId)
    local nHandIndex = nil
    for i = 1, 9 do
        local slotItem = EasyModel.quickSelectBarSlots[i]
        if slotItem and slotItem.id == blockId then
            nHandIndex = i
            break
        end
    end
    return nHandIndex
end

function EasyModel.TakeItemStack(itemStack, nHandIndex)
    if not itemStack then return end
    
    -- Determine which slot to use
    if not nHandIndex then
        local targetItemId = itemStack.id
        
        -- Step 1: Search for existing slot with the same item ID
        for i = 1, 9 do
            local slotItem = EasyModel.quickSelectBarSlots[i]
            if slotItem and slotItem.id == targetItemId then
                nHandIndex = i
                break
            end
        end
        
        -- Step 2: If not found, look for an empty slot
        if not nHandIndex then
            for i = 1, 9 do
                if not EasyModel.quickSelectBarSlots[i] then
                    nHandIndex = i
                    break
                end
            end
        end
        
        -- Step 3: If no empty slot, use current selected slot or default to slot 1
        if not nHandIndex then
            if (EasyModel.selectedSlot or 0) >= 1 and (EasyModel.selectedSlot or 0) <= 9 then
                nHandIndex = EasyModel.selectedSlot
            else
                nHandIndex = 1
            end
        end
    end
    
    EasyModel.SetSelectedItemStack(itemStack)
    if nHandIndex and nHandIndex >=1 and nHandIndex <=9 then
        EasyModel.quickSelectBarSlots[nHandIndex] = itemStack:Copy()
        EasyModel.quickSelectBarSelectedSlot = nHandIndex
        EasyModel.selectedSlot = nHandIndex
        EasyModel:RefreshQuickSelectBarPage()
    end
end

-- @param itemStackOrId: the item stack to take, if it is number, we will create a new item stack with that id
-- @param nHandIndex: if nil, it will search for existing slot, empty slot, or replace current/slot 1
function EasyModel.TakeItem(itemStackOrId, nHandIndex)
    EasyModel.SelectMeInHand(0)

    local itemStack;
    if type(itemStackOrId) == "number" then
        local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient")
        local item = ItemClient.GetItem(itemStackOrId)
        if item then
            itemStack = ItemStack:new():Init(itemStackOrId, 99999)
        end
    else
        itemStack = itemStackOrId
    end
    EasyModel.TakeItemStack(itemStack, nHandIndex)
end

function EasyModel.OnSelectSlot(name)
    -- for buttons
    if(name == "More") then
        EasyModel.selectedSlot = nil;
        return
    elseif(name == "Undo") then
        UndoManager.Undo()
        return
    elseif(name == "Redo") then
        UndoManager.Redo()
        return
    end

    -- for slots (only one is selected at one time)
    local slot = type(name) == "number" and name or EasyModel.SlotsNames[name] 

    if(EasyModel.selectedSlot == slot) then
        if(name == "Delete") then
            EasyModel.OnSelectSlot(EasyModel.quickSelectBarSelectedSlot or 8)
        end
        return
    end
    if slot then
        local self = curInstance;
        if(not self) then
            return
        end
        EasyModel:ShowEditActionsForEntity(nil)
        EasyModel.selectedSlot = slot
        if EasyModel.selectedSlot > 0 then
            -- Selected a slot from quick select bar
            EasyModel.SetSelectedItemStack(EasyModel.quickSelectBarSlots[EasyModel.selectedSlot])
        else
            EasyModel.SetSelectedItemStack(nil)
            EasyModel.ShowColorsPage(false);
        end
        if(name == "Pick") then
            EasyModel.UpdateStatus(L"点击场景中任意方块，可吸取到手中用于创作")
        elseif(name == "Delete") then
            EasyModel.UpdateStatus(L"点击场景中方块可删除")
            EasyModel.CloseSelectionWindow()
            EasyModel.CloseEditModelWindow()
            EasyModel.CloseAddLiveModelWindow()
            EasyModel.CloseCloneBagWindow()
            EasyModel.currentBrushMode = "delete"
        elseif(name == "Select") then
            EasyModel.UpdateStatus(L"点击场景中方块可选择并编辑")
            EasyModel.currentBrushMode = "select"
        else
            if selected_itemStack then
                local item = selected_itemStack:GetItem()
                local displayName = item and item:GetDisplayName() or L"未知方块"
                local brushModeText = EasyModel.GetBrushModeText()
                EasyModel.UpdateStatus(format(L"已选:%s，点击场景%s，长按删除", displayName, brushModeText))
            else
                EasyModel.UpdateStatus(L"点击场景可放置方块")
            end
        end
        if(EasyModel.selectedSlot > 0) then
            EasyModel.lastSelectedSlot = EasyModel.selectedSlot
        end
        EasyModel:RefreshPage()
    end
end

function EasyModel.OnOpenObjectList()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FindBlockTask.lua");
    local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
    local task = MyCompany.Aries.Game.Tasks.FindBlockTask:new()
    local editableWorld = GameLogic.CreateGetEditableWorld();
    task:ShowPage(true, nil, nil, function(entity)
        if(entity:IsBlockEntity() and editableWorld:IsEditableBlock(entity:GetBlockPos())) then
            entity.isFromEditableWorld = true;
            -- this will include all editable block entities
            return true;
        end
        return entity.isFromEditableWorld == true;
    end, L"物品列表", function(index)
        local entity = FindBlockTask.GetResultAt(index);
	    if(entity) then
            if(EasyModel:TryEditEntity(entity)) then
            end
            FindBlockTask.SetSelectedIndexByResultIndex(index)
            FindBlockTask.GotoItemAtIndex(index);
            FindBlockTask.OnClose()
        end
        return true
    end, "easy")
end

function EasyModel.OnClickClose()
    GameLogic.RunCommand("/take -select -bag 3");
end

function EasyModel.UpdateStatus(text)
    EasyModel.status = text;
    EasyModel:RefreshPage() 
end

function EasyModel.GetBrushModeText()
    local mode = EasyModel.currentBrushMode or "add"
    if mode == "add" then
        return L"添加"
    elseif mode == "replace" then
        return L"替换"
    elseif mode == "fill" then
        return L"填充"
    elseif mode == "delete" then
        return L"删除"
    elseif mode == "select" then
        return L"选择"
    end
    return L"添加"
end

function EasyModel.OnSelectBrushMode(mode)
    -- Set the brush mode directly
    if mode == "add" or mode == "replace" or mode == "fill" or mode == "delete" or mode == "select" then
        if(mode ~= "delete" and mode ~= "select" and EasyModel.selectedSlot and EasyModel.selectedSlot <=0) then
             EasyModel.selectedSlot = EasyModel.quickSelectBarSelectedSlot or 8;
             EasyModel.SetSelectedItemStack(EasyModel.quickSelectBarSlots[EasyModel.selectedSlot])
        end
        EasyModel.currentBrushMode = mode
        local modeText = EasyModel.GetBrushModeText()
        local statusText = ""
        if mode == "add" then
            statusText = format(L"模式: %s - 在空白处添加方块", modeText)
        elseif mode == "replace" then
            statusText = format(L"模式: %s - 替换单个方块", modeText)
        elseif mode == "fill" then
            statusText = format(L"模式: %s - 填充相同颜色的连续方块", modeText)
        elseif mode == "delete" then
            statusText = format(L"模式: %s - 点击删除方块", modeText)
        elseif mode == "select" then
            statusText = format(L"模式: %s - 点击选择方块", modeText)
        end
        EasyModel.UpdateStatus(statusText)
        if curInstance then
            curInstance:RefreshPage()
        end
    end
end

function EasyModel.GetCurrentBrushMode()
    return EasyModel.currentBrushMode or "add"
end

function EasyModel.GetBrushModeColor()
    local mode = EasyModel.GetCurrentBrushMode()
    if mode == "add" then
        return "#808080"  -- white (default)
    elseif mode == "replace" then
        return "#ffaa00"  -- orange
    elseif mode == "fill" then
        return "#00aaff"  -- cyan/blue
    elseif mode == "delete" then
        return "#ff4444" -- red for delete
    elseif mode == "select" then
        return "#00ff00" -- green for select
    end
    return "#808080"
end

---------------------------
-- color page
---------------------------

-- the following is default 20 colors in Windows's painter app.
-- this make sure 8 bits are 16 bits colors are identical.
local colors = {
	-- row1
	{color="#000000"},
	{color="#555555"},
	{color="#aa0000"},
	{color="#ff0000"},
	{color="#ff5500"},
	{color="#ffff00"},
	{color="#00aa55"},
	{color="#00aaff"},
	{color="#0055ff"},
	{color="#aa55aa"},
	-- row2
	{color="#ffffff"},
	{color="#aaaaaa"},
	{color="#aa5555"},
	{color="#ffaaff"},
	{color="#ffaa00"},
	{color="#ffffaa"},
	{color="#aaff00"},
	{color="#aaffff"},
	{color="#55aaaa"},
	{color="#ffaaaa"},
}

function EasyModel.GetColorListDS(index)
	if(not index) then
		return #colors;
	else
		return colors[index];
	end
end

function EasyModel.OnClickColor(index)
    local color = colors[index].color;
    EasyModel.SetColor(color);
end

function EasyModel.OnCloseColors()
    EasyModel.ShowColorsPage(false)
end

function EasyModel.OnCloseAllBlocks()
    EasyModel.ShowAllBlocksPage(false)
end

function EasyModel.ShowColorsPage(bShow)
    if(bShow) then
        EasyModel.CloseSelectionWindow()
        EasyModel.CloseEditModelWindow()
        EasyModel.CloseAddLiveModelWindow()
        EasyModel.CloseCloneBagWindow()
    end
    if(not EasyModel.colorPage and not bShow) then
        return
    end
    local width, height = 512, 128;
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.Colors.html", 
        name = "EasyModel.Colors.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        enable_esc_key = false,
        allowDrag = false,
        click_through = true, 
        bShow = (bShow ~= false),
        SelfPaint = true,
        directPosition = true,
            align = "_ctt",
            x = 0,
            y = 0,
            width = width,
            height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if(bShow) then
        if(params._page) then
            EasyModel.colorPage = params._page;
            params._page.OnClose = function()
                EasyModel.colorPage = nil;
            end
        end
        if(EasyModel.colorPage) then
            EasyModel.colorPage:Refresh(0.01);
        end
        if(params.SelfPaint) then
            local Item = commonlib.gettable("MyCompany.Aries.Game.Items.Item");
            local textureAtlas = Item:GetIconAtlas();
            if(textureAtlas) then
                textureAtlas:Connect("TextureUpdated", EasyModel, EasyModel.RefreshQuickSelectBarPage, "UniqueConnection");
            end
        end
    end
end

function EasyModel.RefreshColorsPage()
    if(EasyModel.colorPage) then
        EasyModel.colorPage:Refresh(0.01);
    end
end

function EasyModel.ShowAllBlocksPage(bShow)
    if(bShow) then
        EasyModel.CloseSelectionWindow()
        EasyModel.CloseEditModelWindow()
        EasyModel.CloseAddLiveModelWindow()
        EasyModel.CloseCloneBagWindow()
    end
    if(not EasyModel.allBlocksPage and not bShow) then
        return
    end
    local width, height = 600, 512;
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.AllBlocks.html", 
        name = "EasyModel.AllBlocks.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        enable_esc_key = false,
        allowDrag = false,
        click_through = true, 
        -- isTopLevel = true,
        bShow = (bShow ~= false),
        directPosition = true,
            align = "_ctt",
            x = 0,
            y = 90,
            width = width,
            height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if(bShow) then
        if(params._page) then
            EasyModel.allBlocksPage = params._page;
            params._page.OnClose = function()
                EasyModel.allBlocksPage = nil;
            end
        end
    end
end


function EasyModel.SetColor(color)
    -- for all color blocks and quick select bar slots (including slots 8-9)
    if EasyModel.selectedSlot and EasyModel.selectedSlot >= 1 and EasyModel.selectedSlot <= 9 then
        -- All quick select bar slots can have color applied
        if selected_itemStack then
            selected_itemStack.colorName = color;
            selected_itemStack.color32 = Color.ToValue(color)
            EasyModel.RefreshColorsPage()
        end
    end
end

function EasyModel.GetColor()
    if selected_itemStack and selected_itemStack.colorName then
        return selected_itemStack.colorName
    end
    return "#ffffff"
end

EasyModel.block_category_ds = {
    {text=L"建造", name="static", enabled=true},
    {text=L"机关", name="gear",	enabled=true},
    {text=L"装饰", name="deco", enabled=true},
    {text=L"代码", name="code", enabled=true},
    {text=L"彩色", name="color", enabled=true},
}
EasyModel.block_category_index = 1;

-- add all block ids here for easy builder
-- generated from config/Aries/creator/block_list.xml
local all_blocks = {
    -- static (方块)
    {52, 17, 5, 51, 4, 171, 26, 62, 55, 13, "SoilCarpet", 174, 28, 159, 155, 56, 123, 124, 18, 87, 16, 2, 145, 130, 147, 131, 151, 150, 146, 125, 158, 12, 53, 85, 86, 91, 129, 92, 82, 126, 128, 98, 99, 149, 152, 139, 81, 140, 138, 59, 58, 68, 66, 70, 69, 154, 111, 206, 8, 170, 89, 110, 144, 80, 133, 135, 23, 96, 94, 27, 93, 137, 20, 21, 19, 25, 24, 136, 134, 71, 142, 143, 148, 156, 97, 157, 186, 90, 6, 220, 153, },
    
    -- gear (机关)
    {"Command_Block", "Wire", "Lever", "Stone_Button", "Electric_Torch_On", "Trapdoor", "Wooden_Door", "IronTrapdoor", "Iron_Door", "Conductor", "ConductorOmini", "Repeater", "Lamp", "Wooden_Pressure_Plate", "Stone_Pressure_Plate", "CornerGrass", "StickyPiston", "Piston", "TNT", "PowerBlock", "BlockUpdateDetector", "Chest", "MusicBox", "Note_Block", "TeleportStone", "PhysicalBox", "Rails", "railcar", "RailPowered", "RailDetector", "Sign_Post", "Wall_Sign", "Painting", "Bone", "BlockArrow", "EditableWorld"},
    
    -- deco (装饰)
    {"Fence", "Torch", 222, 117, 153, 90, 220, 162, 113, 116, "CornerGrass", 115, 165, 92, 114, 132, 141, 161, 164, 208, "Apple", 149, 152, 188, 185, 122, 112, 160, 119, 172, 183, 120, 173, 184, 121, 87, 82, 118, 163, 100, 6, 90, 95, 221, 218, 224, 144, 80, "Chest", 186, 84, 101, 214, 209, "Trapdoor", "Wooden_Door", "IronTrapdoor", "Iron_Door", 166, 103, 104, 177, 167, 179, 169, 181, 168, 180, 176, 111, 175, 178, 206, 187, 182, 23, 102, 211, 186, 188, 185, 112, 160, 172, 183, 104},
    
    -- character/code (代码)
    {"CodeBlock", "Wire", "Lever", "Repeater", "MovieClip", "Bone", "Fence", "Sign_Post"},

    -- color (彩色方块)
    {10, 280, 281, 282, 50, 286, 287, 288, 73,283, 284, 285, 267, 268, 234, 74, 276, 171, 133, 102},
}

local all_blocks_ds = {}

function EasyModel.GetBlockCategoryButtons()
    return EasyModel.block_category_ds
end

function EasyModel.GetBlockCategory(blockId)
    for index, blocks in ipairs(all_blocks) do
        for blockIndex, id in ipairs(blocks) do
            if id == blockId then
                return index,blockIndex
            end
        end
    end
    return 0
end

function EasyModel.OnChangeBlockCategory(name)
    EasyModel.block_category_index = tonumber(name) or 1;
    -- Refresh the AllBlocks page to show the new category
    if(EasyModel.allBlocksPage) then
        EasyModel.allBlocksPage:Refresh(0.01)
    end
end

function EasyModel.OnClickSelectBlock(block_id, mcmlNode)
    local item_stack = ItemStack:new():Init(block_id, 99999);
    
    EasyModel.TakeItemStack(item_stack, nil)

    if(EasyModel.allBlocksPage) then
        EasyModel.allBlocksPage:Refresh(0.01)
    end
    EasyModel.OnCloseAllBlocks()
end

function EasyModel.IsPickedColorBlock()
    if selected_itemStack then
        local block_id = selected_itemStack.id
        -- Check if the block_id exists in the color category blocks
        local color_blocks = all_blocks[5] -- color category is index 5
        if color_blocks then
            for _, id in ipairs(color_blocks) do
                if id == block_id then
                    return true
                end
            end
        end
    end
    return false
end

function EasyModel.GetPickedBlockId()
    if selected_itemStack then
        return selected_itemStack.id or 0
    end
    return 0;
end

function EasyModel.GetAllBlocksDS(index)
    local ds = all_blocks_ds[EasyModel.block_category_index]
    if(not ds) then
        -- fill in data source
        ds = {}
        local blocks = all_blocks[EasyModel.block_category_index or 1]
        if(blocks) then
            for index, block_id_or_name in ipairs(blocks) do
                if(type(block_id_or_name) == "string") then
                    block_id_or_name = block_types.names[block_id_or_name];
                end
                if(block_id_or_name) then
                    ds[#ds+1] = {block_id = block_id_or_name}
                end
            end
        end
        all_blocks_ds[EasyModel.block_category_index] = ds;
    end
    if(not index) then
        return #(ds)
    else
        return ds[index]
    end
end

function EasyModel.AddLiveModelFromFile(filename, displayName)
    filename = commonlib.Encoding.DefaultToUtf8(filename)
    local player = EntityManager.GetFocus()
    if player then
        local x, y, z = player:GetPosition()
        
        local y_offset = math.max(2, math.min(4, player:GetHeight()+0.2))
        local bx, by, bz = BlockEngine:block(x, y + y_offset, z)
        local entity = EntityLiveModel:new():init()
        entity:SetBlockPos(bx, by, bz)
        entity:SetModelFile(filename)
        if(displayName) then
            entity:SetDisplayName(displayName)
        end
        
        local finalCanDrag = false
        -- check if the entity has animation id 4, if so, we will set its category to character
        if entity:HasAnimation(4) then
            entity:SetCategory("character")
            entity:SetStaticTag("actionname", L"互动");
            entity:SetOnClickEvent("API.CharInteract");
            entity:SetActionRadius(1.5);
            finalCanDrag = true
        end
        entity:SetCanDrag(true) -- Always allow drag initially for placement
        
        entity:Attach()
        if(GameLogic.CreateGetEditableWorld():AddLiveEntity(entity, true)) then
            -- add to history command
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
            local task = MyCompany.Aries.Game.Tasks.DragEntity:new({addToHistory=true})
            task:CreateEntity(entity);

            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyLiveModel.lua");
            local EasyLiveModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyLiveModel");
            
            EasyLiveModel.StartPreviewEntityAnimation(entity)
            
            local function onEntityPlaced(targetEntity)
                if(targetEntity) then
                    targetEntity:FallDown()
                    if(finalCanDrag == false) then
                        targetEntity:SetCanDrag(false)
                    end
                    EasyModel:ShowEditActionsForEntity(targetEntity)
                end
                EasyLiveModel.StopPreviewPositionUpdater()
            end
            EasyLiveModel.StartPreviewPositionUpdater(entity, {
                onMove = function(targetEntity)
                    onEntityPlaced(targetEntity)
                end
            })
            entity:Connect("dragEnded", function()
                onEntityPlaced(entity)
            end)
        else
            EasyModel:EditLiveEntity(nil)
        end
    end
end

function EasyModel.OnAddLiveModel()
    if(EasyModel.useEasyLiveModel~=false) then
        EasyModel.CloseAllSubToolWindows()

        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyLiveModel.lua");
        local EasyLiveModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyLiveModel");
        local task = EasyLiveModel:new();
        EasyModel.addLiveModelTask = task;
        
        task:Connect("taskFinished", function() 
            if(curInstance) then
                curInstance:CheckRestoreSceneContext();
            end
            EasyModel.addLiveModelTask = nil;
        end);
        task:Run();
    else
        NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
        local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
        OpenAssetFileDialog.ShowPage(L"请输入bmax, x或fbx文件的相对路径, <br/>你也可以随时将外部文件拖入窗口中", function(result)
            if(result and result~="") then
                EasyModel.AddLiveModelFromFile(result)
            end
        end, nil, L"选择模型文件", "model", nil, function(filename)
            -- edit button callback
        end)
    end
end

function EasyModel.OnClickSave()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
    local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
    EasyEditableWorld.CheckQuickSave(true);
end

---------------------------
-- Quick Select Bar
---------------------------

function EasyModel.OnClickQuickSelectBarSlot(slotIndex)
    slotIndex = tonumber(slotIndex)
    if not slotIndex then return end
    
    EasyModel.quickSelectBarSelectedSlot = slotIndex
    EasyModel.currentBrushMode = "add" -- reset to add mode
    
    local itemStack = EasyModel.quickSelectBarSlots[slotIndex]
    if itemStack then
        EasyModel.selectedSlot = slotIndex
        EasyModel.SetSelectedItemStack(itemStack)
        local item = itemStack:GetItem()
        local displayName = item and item:GetDisplayName() or L"未知方块"
        local brushModeText = EasyModel.GetBrushModeText()
        EasyModel.UpdateStatus(format(L"已选:%s，点击场景%s，长按删除", displayName, brushModeText))
        
        EasyModel.lastSelectedSlot = EasyModel.selectedSlot
    else
        -- Empty slot - show block picker and wait for user to pick
        EasyModel.selectedSlot = slotIndex
        EasyModel.SetSelectedItemStack(nil)
        EasyModel.UpdateStatus(format(L"请选择或拾取方块", slotIndex))
    end
    
    if(quickSelectBarPage) then
        quickSelectBarPage:Refresh(0.01)
    end
    if(page) then
        page:Refresh(0.01)
    end
end

function EasyModel.OnClickShowAllBlocks()
    EasyModel.ShowAllBlocksPage(true)
end

function EasyModel.OnDragEndQuickSlot(name, mcmlNode)
    local slotIndex = tonumber(name)
    
    if not slotIndex then return end
    local m_x, m_y = ParaUI.GetMousePosition();
    local temp = ParaUI.GetUIObjectAtPoint(m_x, m_y);
	if(not temp:IsValid()) then
		-- delete (drop to 3d scene. maybe in future?)
        
        -- Remove the item from the slot
        EasyModel.quickSelectBarSlots[slotIndex] = nil
        
        -- If the removed slot was selected, clear the selection
        if EasyModel.quickSelectBarSelectedSlot == slotIndex then
            EasyModel.SetSelectedItemStack(nil)
        end
        -- Refresh the page
        if(quickSelectBarPage) then
            quickSelectBarPage:Refresh(0.01)
        end
        if(page) then
            page:Refresh(0.01)
        end
    end
end

function EasyModel:ClearQuickSelectBarSlots()
    if not quickSelectBarPage then return end
    for i = 1, 7 do
        if EasyModel.quickSelectBarSelectedSlot == i then
            EasyModel.SetSelectedItemStack(nil)
        end
        EasyModel.quickSelectBarSlots[i] = nil
    end
    EasyModel.quickSelectBarSelectedSlot = 8
end

function EasyModel:RefreshQuickSelectBarPage()
    if(quickSelectBarPage) then
        quickSelectBarPage:Refresh(0.01)
    end
end