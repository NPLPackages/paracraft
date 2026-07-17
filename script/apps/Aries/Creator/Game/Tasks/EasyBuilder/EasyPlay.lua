--[[
Title: EasyPlay Game Mode Task
Author(s): GitHub Copilot
Date: 2025/09/28
Desc: Easy Play provides two simple buttons: possession (附身) and view switching (视角).

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyPlay.lua");
local EasyPlay = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyPlay");
EasyPlay:ShowPage(true)
EasyPlay.OnClickPossession()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMap.lua");
local EasyMap = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyMap");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EasyPlay = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyPlay"));

local curInstance;
local page;

-- Always a top level task
EasyPlay.is_top_level = true;

function EasyPlay:ctor()
    -- Initialize camera mode to ThirdPerson by default
    EasyPlay.currentCameraMode = "ThirdPerson"
end

-- Handle character switching (possession) - take control of nearby character
function EasyPlay.OnClickPossession()
    local currentEntity = EntityManager:GetFocus();
    local nearbyEntity = EasyPlay.FindNearbyCharacter(currentEntity);
    
    if(nearbyEntity) then
        -- Switch control to the nearby character
        if(EasyMap.PossessChar(nearbyEntity)) then
            -- Show feedback message
            -- local entityName = nearbyEntity.name or "未知角色";
            -- GameLogic.AddBBS("statusBar", string.format("已附身到: %s", entityName), 3000, "255 255 0");
            return;
        end
    else
        GameLogic.AddBBS("statusBar", "附近没有找到可附身的角色", 3000, "255 255 0");
    end
end

-- Find nearby character that can be possessed using AABB collision detection
function EasyPlay.FindNearbyCharacter(currentEntity, searchRadius)
    if(not currentEntity) then
        return nil;
    end
    searchRadius = searchRadius or 5;
    local nearestEntity = nil;
    
    -- Create expanded AABB around current entity
    local aabb = currentEntity:GetCollisionAABB():clone_from_pool();
    aabb:Expand(searchRadius, searchRadius, searchRadius);
    local entities = EntityManager.GetEntitiesByAABBExcept(aabb, currentEntity);
    
    local forceIncludePlayer = currentEntity ~= EntityManager.GetPlayer() and EntityManager.GetPlayer() or nil;
    if(entities) then
        local nearestDistance = 99999;
        local x, y, z = currentEntity:GetPosition();

        for _, entity in ipairs(entities) do
            -- Check if it's a controllable entity
            if entity == forceIncludePlayer or 
               (entity.class_name == "LiveModel" and 
                (entity.category == "character" or
                entity:HasCustomGeosets())) then
                local distance = entity:GetDistanceSq(x,y,z);
                
                if distance < nearestDistance then
                    nearestDistance = distance;
                    nearestEntity = entity;
                end
            end
        end
    end
    
    return nearestEntity;
end

-- Handle view/camera switching
function EasyPlay.OnClickView()
    -- Cycle through ThirdPerson, ThirdPersonLookCamera, and ThirdPersonLookAhead modes
    if not EasyPlay.currentCameraMode then
        EasyPlay.currentCameraMode = "ThirdPerson"
    end
    
    if EasyPlay.currentCameraMode == "ThirdPerson" then
        -- Switch to third person face camera (no face tracking)
        GameLogic.RunCommand("/camera -mode ThirdPersonLookCamera");
        EasyPlay.currentCameraMode = "ThirdPersonLookCamera"
        GameLogic.AddBBS("statusBar", "视角: 看镜头", 3000, "0 255 255");
    elseif EasyPlay.currentCameraMode == "ThirdPersonLookCamera" then
        -- Switch to third person look ahead (fixed forward view)
        GameLogic.RunCommand("/camera -mode ThirdPersonLookAhead");
        EasyPlay.currentCameraMode = "ThirdPersonLookAhead"
        GameLogic.AddBBS("statusBar", "视角: 看前方固定", 3000, "0 255 255");
    else
        -- Switch back to regular third person
        GameLogic.RunCommand("/camera -mode ThirdPerson");
        EasyPlay.currentCameraMode = "ThirdPerson"
        GameLogic.AddBBS("statusBar", "视角: 看鼠标", 3000, "0 255 255");
    end
end


function EasyPlay.GetInstance()
    return curInstance;
end

-- follow EditLightTask: keep a static InitPage(Page)
function EasyPlay.InitPage(Page)
    page = Page;
end

function EasyPlay:Redo()
end

function EasyPlay:Undo()
end

-- follow EditLightTask lifecycle
function EasyPlay:Run()
    curInstance = self;
    if(not self.bIgnoreShowPage) then
        self:ShowPage(true);
    end
    self:LoadSceneContext();
end

function EasyPlay:OnExit()
    self:ShowPage(false);
    self:SetFinished();
    self:CloseWindow();
    local MiniGameUserBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserBag.lua");
    MiniGameUserBag.ClosePage()
    self:UnloadSceneContext();
    curInstance = nil;
end

function EasyPlay:ShowPage(bShow)
    if(not page) then
        local width, height = 64, 200;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyPlay.html", 
                name = "EasyPlay.ShowPage", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide=false, 
                style = CommonCtrl.WindowFrame.ContainerStyle,
                enable_esc_key = false,
                allowDrag = false,
                click_through = true, 
                zorder = -3,
                bShow = (bShow ~= false),
                directPosition = true,
                    align = "_rt",
                    x = -10 - width,
                    y = 120,
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

function EasyPlay:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyPlay:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

function EasyPlay:keyPressEvent(event)
    local ItemEasyBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Items.ItemEasyBuilder");
    ItemEasyBuilder:keyPressEvent(event)
    if(event:isAccepted()) then
        return
    end
	local dik_key = event.keyname;
    if(dik_key == "DIK_E")then
        GameLogic.RunCommand("/take -select -bag 5");
        event:accept();
    elseif(dik_key == "DIK_P")then
        EasyPlay.OnClickPossession()
        event:accept();
    elseif(dik_key == "DIK_F5")then
        EasyPlay.OnClickView()
        event:accept();
    else
        self:GetSceneContext():keyPressEvent(event);
    end
end

function EasyPlay:mouseReleaseEvent(event)
    local context = self:GetSceneContext();

    if(event.mouse_button == "right") then
        -- disable all right click events
        event:accept();
    end
    context._super.mouseReleaseEvent(context, event);

    if(event:isAccepted()) then
		return
	end
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


function EasyPlay:handleRightClickScene(event, result)
    -- self:handleSceneClick(event, result)
end

function EasyPlay:handleLeftClickScene(event, result)
    self:handleSceneClick(event, result)
end

function EasyPlay:handleMiddleClickScene(event, result)
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

function EasyPlay:handleSceneClick(event, result)
    if not event:isClick() or not curInstance or not result or not result.blockX then return end
    
    if(not event.shift_pressed and not event.alt_pressed) then
        -- first try the game logics if it is processed. such as an action neuron block.
        if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
            -- this fixed a bug where block entity is larger than the block like the physics block model.
            local bx, by, bz = result.entity:GetBlockPos();
            isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, EntityManager.GetPlayer(), result.side);
        else
            if(result.block_id and result.block_id>0) then
                isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
            elseif(result.entity) then
                isProcessed = GameLogic.GetPlayerController():OnClickEntity(result.entity, result.blockX, result.blockY, result.blockZ, event.mouse_button);
            end
        end
    end
    if(isProcessed) then
        event:accept()
        return
    end
end
