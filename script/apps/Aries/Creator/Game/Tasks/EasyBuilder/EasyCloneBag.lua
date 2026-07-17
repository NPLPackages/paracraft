--[[
Title: EasyBuilder Clone Bag Task
Author(s): LiXizhi
Date: 2025/10/12
Desc: Clone live models from the scene into bag slots and create them anywhere across different worlds or editable worlds
Currently, it only support EntityLiveModel whose asset path starts with "temp/blocktemplates/" and has GetCanDrag() method returning true.

The global bag entity is persisted to local user data (userdata.db) and will:
- Load from disk only once when first initialized (marked with isCloneBagLoaded flag on the entity)
- Save to disk automatically whenever the inventory changes (items added, removed, or cleared)
- Persist across different worlds and sessions

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCloneBag.lua");
local EasyCloneBag = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyCloneBag");
local cloneBag = EasyCloneBag:new()
cloneBag:Run();

EasyCloneBag:ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")           
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EasyCloneBag = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyCloneBag"));

EasyCloneBag:Signal("bagClosed");
EasyCloneBag:Signal("beforeItemClicked"); -- return true to prevent default action
EasyCloneBag:Signal("afterEntityCreated");


local curInstance;
local page;
local bagDS = {};

-- Always a top level task
EasyCloneBag.is_top_level = true;

function EasyCloneBag:ctor()
end

function EasyCloneBag.GetInstance()
    return curInstance;
end

-- Initialize page
function EasyCloneBag.InitPage(Page)
    page = Page;
    EasyCloneBag.InitializeBag();
end

-- Initialize the global bag entity
function EasyCloneBag.InitializeBag()
    local bagEntity = GameLogic.GetGlobalBagEntity();
    -- Ensure bag has inventory
    if not bagEntity:GetInventory() then
        bagEntity:SetBagSize(16);
    end
    
    -- Load from local storage only once
    EasyCloneBag.LoadBagFromDisk(bagEntity);
    
    -- Initialize bag data source
    EasyCloneBag.bagDS = {};
    for i = 1, bagEntity:GetInventory():GetSlotCount() do
        table.insert(EasyCloneBag.bagDS, {});
    end
        
    -- Get inventory view and bind it to the bag slots
    EasyCloneBag.inventoryView = bagEntity:GetInventoryView();
end

-- Load bag data from disk (only once per entity)
function EasyCloneBag.LoadBagFromDisk(bagEntity)
    if not bagEntity then return end
    
    -- Check if already loaded
    if bagEntity.isCloneBagLoaded then
        return
    end
    
    -- Mark as loaded
    bagEntity.isCloneBagLoaded = true;
    
    -- Load from local storage
    local savedData = GameLogic.GetPlayerController():LoadLocalData("EasyCloneBag_inventory", nil, true);
    
    if savedData and savedData.inventory then
        local inventory = bagEntity:GetInventory();
        if inventory then
            -- Load inventory from saved XML node structure
            inventory:LoadFromXMLNode(savedData.inventory);
        end
    end
end

-- Save bag data to disk
function EasyCloneBag.SaveBagToDisk()
    local bagEntity = GameLogic.GetGlobalBagEntity();
    if not bagEntity then return end
    
    local inventory = bagEntity:GetInventory();
    if not inventory then return end
    
    -- Save inventory to XML node structure
    local inventoryNode = {};
    inventory:SaveToXMLNode(inventoryNode);
    
    local savedData = {
        inventory = inventoryNode,
        timestamp = os.time()
    };
    
    -- Save to local storage (global, not world-specific)
    GameLogic.GetPlayerController():SaveLocalData("EasyCloneBag_inventory", savedData, true, false);
end

-- Get bag slot count
function EasyCloneBag.GetBagSlotCount()
    local bagEntity = GameLogic.GetGlobalBagEntity();
    if bagEntity and bagEntity:GetInventory() then
        return bagEntity:GetInventory():GetSlotCount();
    end
    return 0;
end

-- Get inventory view for binding to slots
function EasyCloneBag.GetInventoryView()
    return EasyCloneBag.inventoryView;
end

function EasyCloneBag:Redo()
end

function EasyCloneBag:Undo()
end

-- Run the task
function EasyCloneBag:Run()
    curInstance = self;
    self:LoadSceneContext();
    self:ShowPage(true);
    self.finished = false;
end

function EasyCloneBag:OnExit()
    EasyCloneBag.Cancel()
end

function EasyCloneBag.Cancel()
    if(curInstance) then
        local self = curInstance;
        self:UnloadSceneContext();
        self:ShowPage(false);
        self:SetFinished();
        self:CloseWindow();
        self.finished = true;
        curInstance = nil;
    end
end

function EasyCloneBag:ShowPage(bShow)
    if(not page) then
        local width, height = 360, 460;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCloneBag.html", 
                name = "EasyCloneBag.ShowPage", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide=false, 
                style = CommonCtrl.WindowFrame.ContainerStyle,
                enable_esc_key = false,
                allowDrag = true,
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

function EasyCloneBag:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
    if(curInstance) then
        curInstance:bagClosed();
    end
end

function EasyCloneBag:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

-- Click on a slot to create the model at player feet
function EasyCloneBag.OnClickSlot(slotIndex)
    local self = EasyCloneBag.GetInstance();
    if not self then return end;

    slotIndex = tonumber(slotIndex);
    if not slotIndex then return end;
    
    local bagEntity = GameLogic.GetGlobalBagEntity();
    if not bagEntity then return end;
    
    local inventory = bagEntity:GetInventory();
    if not inventory then return end;
    
    local itemStack = inventory:GetItem(slotIndex);
    if not itemStack then return end;
    
    local entity = self:beforeItemClicked()
    if(not entity) then
        entity = self:CreateModelAtPlayerFeet(itemStack);
    end
    if(entity) then
        -- Remove one item from the stack
        inventory:RemoveItem(slotIndex, 1);

        if EasyCloneBag.inventoryView then
            EasyCloneBag.inventoryView:UpdateFromInventory();
            -- Save to disk when inventory changes
            EasyCloneBag.SaveBagToDisk();
        end
    end
end

-- Create a cloned model at player's feet
function EasyCloneBag:CreateModelAtPlayerFeet(itemStack)
    if not itemStack then return end;
    
    local player = EntityManager.GetFocus();
    if not player then return end;
    
    local bx, by, bz = player:GetBlockPos();
    
    -- Check if there are any Live entities in the block and block above
    local entities = EntityManager.GetEntitiesByMinMax(bx, by, bz, bx, by+1, bz, EntityManager.EntityLiveModel, nil);
    if entities and #entities > 0 then
        GameLogic.AddBBS("CloneBag", L"此位置已有模型，无法创建。", 3000, "255 0 0");
        return nil;
    end

    local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
    local ItemLiveModel = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel");
    
    itemStack = itemStack:Copy();
    local item = ItemClient.GetItem(itemStack.id);
    if item and item.SpawnNewEntityModel then 
        local xmlNode = itemStack:GetDataField("xmlNode");
		if(xmlNode and xmlNode.attr) then
            -- Check if model file exists before spawning
            local assetPath = xmlNode.attr.filename;
            if assetPath then
                if not Files.FileExists(assetPath) then
                    if(xmlNode.attr.tempFilename and Files.FileExists(xmlNode.attr.tempFilename)) then
                        assetPath = xmlNode.attr.tempFilename;
                        xmlNode.attr.filename = assetPath;
                    else
                        GameLogic.AddBBS("CloneBag", L"模型文件不存在，无法创建。", 5000, "255 0 0");
                        return nil;
                    end
                end
                -- Copy to world directory if not readonly and not frozen
                if not GameLogic.IsReadOnly() and not GameLogic.CreateGetEditableWorld():IsWorldFrozen() then
                    local worldPath = Files.WorldPathToFullPath(assetPath, true);
                    if not worldPath and assetPath:match("^temp/") then
                        -- File is not in world directory and in temp folder, copy it to blocktemplates/ folder of the same filename in world directory 
                        local sourceFile = ParaIO.open(assetPath, "r");
                        if sourceFile:IsValid() then
                            local content = sourceFile:GetText(0, -1);
                            sourceFile:close();
                            
                            -- Generate target path in world directory
                            local filename = assetPath:match("([^/]+)$");
                            local targetFilename = "blocktemplates/".. filename;
                            local targetFullPath = GameLogic.GetWorldDirectory() .. targetFilename;
                            
                            ParaIO.CreateDirectory(targetFullPath);
                            local targetFile = ParaIO.open(targetFullPath, "w");
                            if targetFile:IsValid() then
                                targetFile:WriteString(content, #content);
                                targetFile:close();
                                -- Update xmlNode with new world-relative path
                                xmlNode.attr.filename = targetFilename;
                                GameLogic.AddBBS("CloneBag", L"模型文件已复制到当前世界", 5000, "0 255 0");
                            end
                        end
                    end
                end
            end
        end
        local entity = item:SpawnNewEntityModel(bx, by, bz, player:GetFacing(), itemStack);
        if(entity) then
            self:afterEntityCreated(entity);
            return entity;
        end
    end
end

-- Close the window
function EasyCloneBag.OnClickClose()
    if curInstance then
        EasyCloneBag.Cancel()
    else
        EasyCloneBag:CloseWindow()
    end
end

-- Clear all slots
function EasyCloneBag.OnClickClearAll()
    local bagEntity = GameLogic.GetGlobalBagEntity();
    if not bagEntity then return end;
    
    local inventory = bagEntity:GetInventory();
    if not inventory then return end;
    
    -- Clear all items from inventory
    inventory:Clear();
    
    if EasyCloneBag.inventoryView then
        EasyCloneBag.inventoryView:UpdateFromInventory();
        -- Save to disk when inventory changes
        EasyCloneBag.SaveBagToDisk();
    end
end

function EasyCloneBag:mousePressEvent(event)
end

function EasyCloneBag:mouseMoveEvent(event)
end

function EasyCloneBag:mouseReleaseEvent(event)
    local context = self:GetSceneContext();
	if(not context) then
		return;
	end
    context.is_click = event:isClick()
    
	if(context.is_click) then
		local result = context:CheckMousePick();
        if result and result.entity and result.entity:isa(EntityManager.EntityLiveModel) then
            local entity = result.entity;
            local filename = entity:GetModelFile()
            local tempFilename;
            if not filename or entity:IsLocked() then
                GameLogic.AddBBS("CloneBag", L"此模型被锁定，无法复制。可联系作者求取。", 5000, "255 0 0");
                return
            end
            if PlayerAssetFile:IsCustomModelOrGeosets(filename) then
                GameLogic.AddBBS("CloneBag", L"可换装角色禁止复制。", 5000, "255 0 0");
                return
            end
            -- Check if filename is a .bmax or .x file and save it to temp/blocktemplates/
            local ext = filename:match("%.([^%.]+)$");
            if ext == "bmax" or ext == "x" then
                local worldPath = Files.WorldPathToFullPath(filename, true);
                if worldPath then
                    -- It's a world file, need to save to temp/blocktemplates/
                    local sourceFile = ParaIO.open(worldPath, "r");
                    if not sourceFile:IsValid() then
                        GameLogic.AddBBS("CloneBag", L"无法读取模型文件。", 5000, "255 0 0");
                        return
                    end
                    
                    local content = sourceFile:GetText(0, -1);
                    sourceFile:close();
                    
                    -- Compute hash of the content
                    local hash = ParaMisc.md5(content);
                    
                    local targetFilename = "temp/blocktemplates/".. hash .. "."..ext;
                    local targetFullPathPath = ParaIO.GetWritablePath() .. targetFilename;
                    ParaIO.CreateDirectory(targetFullPathPath);
                    
                    local targetFile = ParaIO.open(targetFullPathPath, "w");
                    if(targetFile:IsValid()) then
                        targetFile:WriteString(content, #content);
                        targetFile:close();
                        tempFilename = targetFilename;
                    else
                        GameLogic.AddBBS("CloneBag", L"无法复制模型文件。", 5000, "255 0 0");
                        return
                    end
                end
            end

            local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient")
            local item = ItemClient.GetItem(entity:GetBlockId())
            if not item then return end;
            local itemStack = item:ConvertEntityToItem(entity)
            if(itemStack and tempFilename) then
                -- also save the tempFilename in case we move asset across worlds
                local xmlNode = itemStack:GetDataField("xmlNode");
                if(xmlNode and xmlNode.attr) then
                    xmlNode.attr.tempFilename = tempFilename;
                end
            end

            local bagEntity = GameLogic.GetGlobalBagEntity();
            if itemStack and bagEntity and bagEntity:GetInventory() then
                if(bagEntity:GetInventory():AddItem(itemStack)) then
                    if EasyCloneBag.inventoryView then
                        EasyCloneBag.inventoryView:UpdateFromInventory();
                        -- Save to disk when inventory changes
                        EasyCloneBag.SaveBagToDisk();
                    end
                    GameLogic.AddBBS("CloneBag", L"模型已复制到时空口袋中。", 3000, "0 255 0");
                    EasyCloneBag:RefreshPage();
                else
                    GameLogic.AddBBS("CloneBag", L"时空口袋已满，无法复制。", 3000, "255 0 0");
                end
                
            end
        else
            GameLogic.AddBBS("CloneBag", L"点击场景中的模型放入时空口袋。", 3000, "255 255 0");
        end
	end
end