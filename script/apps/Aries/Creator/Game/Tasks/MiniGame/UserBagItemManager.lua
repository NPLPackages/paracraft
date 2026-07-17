--[[
Title: User Bag Item Manager
Author(s): ParaCraft Team
Date: 2025/11/26
Desc: Manage user bag items, visuals, and synchronization
Use Lib:
-------------------------------------------------------
local UserBagItemManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/UserBagItemManager.lua");
UserBagItemManager.Init();
-------------------------------------------------------
]]

local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local EntityPlayer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayer")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockInEntityHand.lua");
local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local FriendActionManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionManager.lua")

local UserBagItemManager = NPL.export()

UserBagItemManager.allEntities = {}
UserBagItemManager.isInit = false

function UserBagItemManager.Init()
    if UserBagItemManager.isInit then return end
    UserBagItemManager.isInit = true
    UserBagItemManager.allEntities = {}
    -- Timer for local updates and polling
    UserBagItemManager.timer = commonlib.Timer:new({callbackFunc = UserBagItemManager.OnTimer})
    UserBagItemManager.timer:Change(30, 30) -- Check every 30ms
    
    GameLogic.GetFilters():remove_filter("OnGGSUpdateRightHandItem",  UserBagItemManager.OnGGSUpdateRightHandItem);
    GameLogic.GetFilters():add_filter("OnGGSUpdateRightHandItem",  UserBagItemManager.OnGGSUpdateRightHandItem);
    UserBagItemManager.loadedFoodConfig = false
    UserBagItemManager.LoadFoodConfig()
end

function UserBagItemManager.OnTimer()
    UserBagItemManager.CheckPlayerMove()
end

function UserBagItemManager.OnGGSUpdateRightHandItem(packet)
    local username = packet.username
    local rightHandItem = packet.rightHandItem
    if not rightHandItem or rightHandItem == "" then 
        UserBagItemManager.ClearPlayerEntity(username)
        return packet 
    end
    if not username or username == "" then return packet end
    local myName = Mod.WorldShare.Store:Get('user/username')
    if myName == username then
        return
    end
    local haveItems = {}
    UserBagItemManager.allEntities[username] = UserBagItemManager.allEntities[username] or {}
    local allEntities = UserBagItemManager.allEntities[username]
    local itemData = UserBagItemManager.DeserializeItems(rightHandItem)
    if not itemData or #itemData == 0 then return packet end
    for _, item in ipairs(itemData) do
        item.username = username
        if item.name and item.name ~= "" then
            local entity = UserBagItemManager.UpdatePlayerEntity(username, item)
            if entity then
                haveItems[item.name] = entity
            end
        end
    end
    for name, entity in pairs(allEntities) do
        if not haveItems[name] then
            entity:Destroy()
            UserBagItemManager.allEntities[username][name] = nil
        end
    end
    return packet
end

function UserBagItemManager.UpdatePlayerEntity(username, item)
    if not username or username == "" then return end
    if not item or not item.name or item.name == "" then return end
    UserBagItemManager.allEntities[username] = UserBagItemManager.allEntities[username] or {}
    local entity = UserBagItemManager.allEntities[username][item.name]
    if not entity then
        if item.id and tonumber(item.id) then
            local itemId = tonumber(item.id)
            local foodConfig = UserBagItemManager.GetFoodConfigById(itemId)
            if not foodConfig then 
                return 
            end
            entity = UserBagItemManager.CreateEntityByItem(item, foodConfig)
            UserBagItemManager.allEntities[username][item.name] = entity
        end
    else
        local x,y,z = item.posx or 0, item.posy or 0, item.posz or 0
        local facing = tonumber(item.facing or 0)
        local scale = tonumber(item.scale or 1)
        local posx,posy,posz = entity:GetPosition()
        local curFacing = entity:GetFacing()
        local curScale = entity:getScale()
        if posx ~= x or posy ~= y or posz ~= z or curFacing ~= facing or curScale ~= scale then
            entity:SetPosition(x, y, z)
            entity:SetFacing(facing)
            entity:setScale(scale)
        end
    end
    return entity
end

function UserBagItemManager.AddSceneItem(item)
    if not item or not item.id then return end
    local player = EntityManager.GetPlayer()
    if not player then return end
    if UserBagItemManager.lastSceneEntity and UserBagItemManager.lastSceneEntity.isOnHead then
        UserBagItemManager.lastSceneEntity:Destroy()
        UserBagItemManager.lastSceneEntity = nil
        player:RemoveRightHandItem(UserBagItemManager.lastEntityName)
        UserBagItemManager.lastEntityName = nil
        local InventoryManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/InventoryManager.lua");
        InventoryManager.ResumeFoodItems(UserBagItemManager.lastItem)
        UserBagItemManager.lastItem = nil
    end
    local userName = Mod.WorldShare.Store:Get('user/username')
    UserBagItemManager.allEntities[userName] = UserBagItemManager.allEntities[userName] or {}
    local x, y, z = player:GetPosition()
    UserBagItemManager.lastPlayerPos = {x=x, y=y, z=z}
    local itemEntity, pos, name = UserBagItemManager.CreateItemEntity(player, item)
    UserBagItemManager.lastSceneEntity = itemEntity
    UserBagItemManager.lastEntityName = name
    UserBagItemManager.lastItem = item
    local facing = math.floor(player:GetFacing() * 10) / 10
    UserBagItemManager.PlayeCreateAnimation(function()
        local player = EntityManager.GetPlayer()
        userName = Mod.WorldShare.Store:Get('user/username')
        if player and userName and userName ~= "" then
            local itemData = {
                id = item.id,
                name = name,
                posx = pos.x or 0,
                posy = pos.y or 0,
                posz = pos.z or 0,
                scale = item.scale or 1,
                facing = item.facing or facing,
            }
            player:AddRightHandItem(itemData)
            UserBagItemManager.allEntities[userName][name] = UserBagItemManager.lastSceneEntity
        end
    end)
end

local effectEntity
function UserBagItemManager.PlayeCreateAnimation(func)
    local headOnBlock = UserBagItemManager.lastSceneEntity
    if not headOnBlock then return end
    
    local entity = EntityManager.GetPlayer()
    if not entity then return end
    local ex, ey, ez = entity:GetPosition()
    local entityHeight = entity:GetHeight() or 1.8
    local yOffset = entityHeight + 0.5

    local animationDuration = 1.5
    local animationStartScale = 0.1
    local animationPeakScale = 1.3
    local targetScale = 1.2
    local frameTime = 0.03
    local totalFrames = math.ceil(animationDuration / frameTime)
    local initialRotation = 0
    local targetRotation = math.pi
    
    local baseScale = headOnBlock:GetScaling() or 1.0
    headOnBlock:SetScaling(baseScale * animationStartScale)
    headOnBlock:SetFacing(initialRotation)

    if effectEntity  then
        effectEntity:Destroy()
        effectEntity = nil
    end

    local effectModel = "character/CC/05effect/star.x"
    effectEntity = EntityManager.EntityLiveModel:Create({
        x = ex, y = ey + yOffset + 0.2, z = ez,
        item_id = block_types.names.LiveModel,
    })
    effectEntity:SetModelFile(effectModel)
    effectEntity:SetScaling(0.4)
    effectEntity:SetPersistent(false)
    effectEntity:Attach()
    
    local frame = 0
    local timer
    timer = commonlib.Timer:new({
        callbackFunc = function()
            frame = frame + 1
            if not headOnBlock or headOnBlock.isDead then
                if effectEntity and not effectEntity.isDead then
                    effectEntity:Destroy()
                end
                timer:Change(nil, nil)
                return
            end
            
            local progress = math.min(frame / totalFrames, 1)
            local scale
            if progress < 0.5 then
                scale = animationStartScale + (progress * 2) * (animationPeakScale - animationStartScale)
            else
                scale = animationPeakScale - ((progress - 0.5) * 2) * (animationPeakScale - targetScale)
            end
            headOnBlock:SetScaling(baseScale * scale)
            local currentRotation = initialRotation + (targetRotation - initialRotation) * progress
            headOnBlock:SetFacing(currentRotation)
            
            -- Follow player if on head
            if headOnBlock.isOnHead then
                local player = EntityManager.GetPlayer()
                if player then
                    local px, py, pz = player:GetPosition()
                    headOnBlock:SetPosition(px, py + yOffset, pz)
                    if effectEntity and not effectEntity.isDead then
                         effectEntity:SetPosition(px, py + yOffset + 0.2, pz)
                    end
                end
            end

            if frame >= totalFrames then
                headOnBlock:SetScaling(baseScale * targetScale)
                headOnBlock:SetFacing(targetRotation)
                if effectEntity and not effectEntity.isDead then
                    effectEntity:Destroy()
                end
                timer:Change(nil, nil)
                if func then
                    func()
                end
            end
        end
    })
    timer:Change(0, math.floor(frameTime*1000))
end

function UserBagItemManager.UseItem(item)
    if not item then return end
    local name = item.name or ""
    local addStamina = 20
    local tips = string.format(L"+%d体力值", addStamina)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/HeadOnNumberEffect.lua");
    local HeadOnNumberEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.HeadOnNumberEffect");
    HeadOnNumberEffect.ShowNumberAtEntity(EntityManager.GetFocus(), tips, "#00ff00ff", 1200);
    HeadOnNumberEffect.ShowNumberAtUI("MiniGameMainPage.timeLimit", "+"..addStamina, "#00ff00", 1000, {finishCallback=function()
        local TimeLimitPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/TimeLimitPage.lua")
        TimeLimitPage.AddStamina(addStamina)
    end});
end

function UserBagItemManager.CheckPlayerMove()
    local curFocus = EntityManager.GetFocus()
    if not curFocus then
        return
    end
    local x, y, z = curFocus:GetPosition()
    if not UserBagItemManager.lastPlayerPos then
        UserBagItemManager.lastPlayerPos = {x=x, y=y, z=z}
        return
    end
    local dx = x - UserBagItemManager.lastPlayerPos.x
    local dy = y - UserBagItemManager.lastPlayerPos.y
    local dz = z - UserBagItemManager.lastPlayerPos.z
    if (dx*dx + dy*dy + dz*dz) > 0.25 then
        local entity = UserBagItemManager.lastSceneEntity
        if entity and entity.isOnHead then
            entity.isOnHead = false
            entity:FallDown()
            local entityName = entity:GetName()
            local px, py, pz = entity:GetPosition()
            px = math.floor(px * 10) / 10
            py = math.floor(py * 10) / 10
            pz = math.floor(pz * 10) / 10
            local player = EntityManager.GetPlayer()
            if player then
                player:UpdateRightHandItem(entityName,{posx=px,posy=py,posz=pz})
            end
        end
        UserBagItemManager.lastPlayerPos = {x=x, y=y, z=z}
    end
end

function UserBagItemManager.ClearPlayerEntity(username,itemName)
    if not username or username == "" then return end
    UserBagItemManager.allEntities[username] = UserBagItemManager.allEntities[username] or {}
    local entities = UserBagItemManager.allEntities[username]
    if itemName and entities[itemName] then
        entities[itemName]:Destroy()
         UserBagItemManager.allEntities[username][itemName] = nil
    else
        for _,entity in pairs(entities) do
            entity:Destroy()
        end
        UserBagItemManager.allEntities[username] = nil
    end
end

function UserBagItemManager.GetPlayerEntity(username,itemName)
    if not username or username == "" then return end
    UserBagItemManager.allEntities[username] = UserBagItemManager.allEntities[username] or {}
    local entities = UserBagItemManager.allEntities[username] or {}
    return entities[itemName]
end

function UserBagItemManager.GetFoodConfigById(id)
    if not UserBagItemManager.loadedFoodConfig then 
        return 
    end
    return UserBagItemManager.foodConfigById[id]
end

function UserBagItemManager.CreateEntityByItem(item, foodConfig)
    if not item or not item.name or item.name == "" then return end
    UserBagItemManager.allEntities[item.name] = UserBagItemManager.allEntities[item.name] or {}
    local x,y,z = item.posx, item.posy, item.posz
    local entity = EntityManager.EntityLiveModel:Create({
        x = x, y = y, z = z,
        item_id = block_types.names.LiveModel,
        name = item.name
    })
    local icon = foodConfig.icon or ""
    local model = foodConfig.model or ""
    entity:SetPersistent(false)
    entity:SetDummy(false)
    entity:SetCanDrag(false)
    entity.nohistory = true
    entity:SetFacing(tonumber(item.facing) or 0)

    if model and model ~= "" then
        entity:SetModelFile(model)
        entity:Refresh();
    else
        BlockInEntityHand.TransformEntityTo3DTexture(entity, icon)
    end
    
    entity:SetScaling(tonumber(item.scale) or 1)
    entity:SetPosition(x, y, z)
    entity:Attach()
    -- Setup interaction
    entity:Connect("clicked", UserBagItemManager, UserBagItemManager.OnClickEntity, "UniqueConnection")
    entity.bagItemData = item
    entity.bagOwnerName = item.username
    return entity
end

function UserBagItemManager.LoadFoodConfig(callback)
    if UserBagItemManager.loadedFoodConfig then
        if callback then
            callback()
        end
        return
    end
    UserBagItemManager.foodConfig = {}
    UserBagItemManager.foodConfigById = {}
    NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWork.lua");
    local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
    KeepWork.GetRawFile("https://keepwork.com/maisi/maisi/webgames/data/msplanet_cooking_config", function(err, msg, data)
        if err == 200 and data then
            local materials = data.materials or {}
            for _, material in pairs(materials) do
                if type(material) == "table" and #material > 0 then
                    for _, item in pairs(material) do
                        if item.id then
                            UserBagItemManager.foodConfigById[item.id] = item
                            table.insert(UserBagItemManager.foodConfig, item)
                        end
                    end
                end
            end
            local recipes = data.recipes or {}
            for _, recipe in pairs(recipes) do
                if recipe.id then
                    UserBagItemManager.foodConfigById[recipe.id] = recipe
                    table.insert(UserBagItemManager.foodConfig, recipe)
                end                
            end
            UserBagItemManager.loadedFoodConfig = true
            if callback then
                callback()
            end
        end
    end, "access plus 1 minute")
end

function UserBagItemManager.CreateItemEntity(player, item)
    if not player or not item or not item.id then return end
    local foodConfig = UserBagItemManager.GetFoodConfigById(item.id) or {}
    local x, y, z = player:GetPosition()
    local playerName = player:GetUserName()
    local startY = y + (player:GetHeight() or 1.8) + 0.5
    local entityName = playerName.."_"..item.id.."_"..ParaGlobal.GenerateUniqueID()
    x = math.floor(x * 10) / 10
    y = math.floor(startY * 10) / 10
    z = math.floor(z * 10) / 10
    local entity = EntityManager.EntityLiveModel:Create({
        x = x, y = y, z = z,
        item_id = block_types.names.LiveModel,
        name = entityName
    })
    
    entity:SetPersistent(false)
    entity:SetDummy(false)
    entity:SetCanDrag(true)
    entity.nohistory = true
    local icon = item.icon or ""
    local model = item.model or foodConfig.model
    if model and model ~= "" then
        entity:SetModelFile(model)
        entity:Refresh();
    else
        BlockInEntityHand.TransformEntityTo3DTexture(entity, icon)
    end
    local facing = player:GetFacing()
    entity:SetFacing(math.floor(facing * 10) / 10)
    
    entity:SetScaling(tonumber(item.scale) or 1)
    entity:SetPosition(x, y, z)
    entity:Attach()
    -- Setup interaction
    entity:Connect("clicked", UserBagItemManager, UserBagItemManager.OnClickEntity, "UniqueConnection")
    entity:Connect("dragBegun", UserBagItemManager, UserBagItemManager.DragBegunEntity, "UniqueConnection");
    entity:Connect("dragEnded", UserBagItemManager, UserBagItemManager.DragEndedEntity, "UniqueConnection");
    item.entityName = entityName
    entity.bagItemData = item
    entity.bagOwnerName = player:GetUserName()
    entity.isOnHead = true
    return entity,{x=x, y=y, z=z}, entityName
end

function UserBagItemManager.DragBegunEntity()
    
end

function UserBagItemManager.DragEndedEntity(dragLocation)
    local entity = UserBagItemManager.lastSceneEntity
    if entity and entity.isOnHead then
        entity.isOnHead = false
        entity:FallDown()
        local player = EntityManager.GetPlayer()
        if not player then return end
        local entityName = entity:GetName()
        local px, py, pz = entity:GetPosition()
        px = math.floor(px * 10) / 10
        py = math.floor(py * 10) / 10
        pz = math.floor(pz * 10) / 10
        player:UpdateRightHandItem(entityName,{posx=px,posy=py,posz=pz})
    end
    return true
end

function UserBagItemManager.OnClickEntity(_,mouse_button,entity)
    if not entity or not entity.bagItemData then return end
    
    local item = entity.bagItemData
    local ownerName = entity.bagOwnerName
    local myPlayer = EntityManager.GetPlayer()
    local myName = Mod.WorldShare.Store:Get('user/username')
    if myName and ownerName == myName then
        local name = item.entityName or ""
        myPlayer:RemoveRightHandItem(name)
        item.eatName = myName
        local InventoryManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/InventoryManager.lua");
        InventoryManager.RemoveFoodItem(item) 
        UserBagItemManager.PlaySingleEatFoodEffect(item, nil, function(item)
            UserBagItemManager.UseItem(item)
        end)
    else
        UserBagItemManager.SendUseItemMsg(item,ownerName,"requestUseitem")
    end
end

function UserBagItemManager.OnRecvUseItemMsg(packet)
    local msgType = packet.msgType
    local senderName = packet.username
    local item = packet.data
    local myName = Mod.WorldShare.Store:Get('user/username')
    local touser = packet.touser
    if touser and touser ~= myName then return end
    if msgType == "requestUseitem" then 
        if senderName and item then
            UserBagItemManager.ShowRequestItem(senderName, item)
        end
    elseif msgType == "responseUseitem" then
        if senderName and item then
            local ownerName = senderName
            item.eatName = myName
            item.entityName = item.name
            FriendActionManager.AddFriendLevel(senderName)
            if item.isOnHead then
                UserBagItemManager.PlayEatFoodEffect(ownerName,myName,item, function(item)
                    UserBagItemManager.UseItem(item)
                end)
            else
                UserBagItemManager.PlaySingleEatFoodEffect(item, nil, function(item)
                    UserBagItemManager.UseItem(item)
                end)
            end
        end
    end
end

function UserBagItemManager.ShowRequestItem(requesterName, itemData)
    if not itemData or not itemData.name then return end
    UserBagItemManager.approvedRequests = UserBagItemManager.approvedRequests or {}
    if UserBagItemManager.approvedRequests[itemData.name] then
        print("UserBagItemManager: Request already approved for this item, ignoring:", itemData.name)
        return
    end
    UserBagItemManager.ApproveRequest({requesterName = requesterName, requestedItemData = itemData})
end

function UserBagItemManager.ApproveRequest(requestInfo)
    if not requestInfo or not requestInfo.requesterName then return end
    local requesterName = requestInfo.requesterName
    local itemData = requestInfo.requestedItemData
    if not itemData or not itemData.name then return end
    UserBagItemManager.approvedRequests = UserBagItemManager.approvedRequests or {}
    UserBagItemManager.approvedRequests[itemData.name] = true
    local myName = Mod.WorldShare.Store:Get('user/username')
    local entity = UserBagItemManager.GetPlayerEntity(myName,itemData.name)
    itemData.isOnHead = entity and entity.isOnHead
    itemData.entityName = itemData.name
    itemData.eatName = requesterName
    local func_Remove = function(itemData)
        local itemId = tonumber(itemData.id)
        local InventoryManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/InventoryManager.lua");
        InventoryManager.RemoveFoodItem({id=itemId}) 
        local player = EntityManager.GetPlayer()
        if player then
            player:RemoveRightHandItem(itemData.name)
        end
    end
    if itemData.isOnHead then
        UserBagItemManager.PlayEatFoodEffect(myName,requesterName,itemData,func_Remove)
    else
        UserBagItemManager.PlaySingleEatFoodEffect(itemData,requesterName,func_Remove)
    end
    FriendActionManager.AddFriendLevel(requesterName)
    UserBagItemManager.SendUseItemMsg(itemData, requesterName, "responseUseitem")
    
end

function UserBagItemManager.PlayEatFoodEffect(sendUser,doUser,itemData, callback) 
    if not itemData or not itemData.id or not sendUser or not doUser then
        return
    end
    local sendEntity = EntityManager.GetEntity("__GGS__"..sendUser)
    local doEntity = EntityManager.GetEntity("__GGS__"..doUser)
    local foodEntity = EntityManager.GetEntity(itemData.entityName)
    if not sendEntity or not doEntity or not foodEntity then return end
    local channel = FriendActionManager.GetMovieChanel(sendUser,doUser)
    if not channel then return end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
    local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
    local preSkin = sendEntity:GetSkin()
    local newSkin = CustomCharItems:RemoveSkinByCategory(preSkin, "right_hand_equipment")
    sendEntity:SetSkin(newSkin,true)
    local preSkin2 = doEntity:GetSkin()
    newSkin = CustomCharItems:RemoveSkinByCategory(preSkin2, "right_hand_equipment")
    doEntity:SetSkin(newSkin,true)
    

    local facing = sendEntity:GetFacing()
    local x,y,z = sendEntity:GetPosition()
    local animFile = "config/Aries/creator/Animation/Player/Send2.blocks.xml"
    channel:CreateFromTemplateFile(animFile);
    channel:SetAutoStopWhenPlayFinish(true)
    channel:Disconnect("finished");
    channel:TransformActorsByFirstActor(x, y, z, facing, nil, sendEntity:GetScaling());
    channel:BindActorAgentToEntity(1, sendEntity, true);
    channel:BindActorAgentToEntity(2, doEntity,true);
    channel:BindActorAgentToEntity(3, foodEntity,true, 5);
    channel:Stop()
    channel:Play(0, -1)
    channel:Connect("finished", function()
        sendEntity:SetSkin(preSkin,true)
        doEntity:SetSkin(preSkin2,true)
        UserBagItemManager.PlaySingleEatFoodEffect(itemData,doUser,callback)
    end)
end

function UserBagItemManager.PlaySingleEatFoodEffect(itemData,username, callback)
    if not itemData or not itemData.id then
        return
    end
    local foodEntity = EntityManager.GetEntity(itemData.entityName)
    if not foodEntity then return end
    local attachEntity = EntityManager.GetFocus()
    if username and username ~= "" then
        attachEntity = EntityManager.GetEntity("__GGS__"..username)
    end
    if not attachEntity then return end
    local x,y,z = attachEntity:GetPosition()
    local channel = FriendActionManager.GetSingleMovieChanel(itemData.eatName)
    if not channel then
        return
    end
    local facing = attachEntity:GetFacing()
    local preSkin = attachEntity:GetSkin()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
    local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
    local newSkin = CustomCharItems:RemoveSkinByCategory(preSkin, "right_hand_equipment")
    attachEntity:SetSkin(newSkin,true)

    local animFile = "config/Aries/creator/Animation/Player/Eat1.blocks.xml"
    channel:CreateFromTemplateFile(animFile);
    channel:SetAutoStopWhenPlayFinish(true)
    channel:Disconnect("finished");
    channel:TransformActorsByFirstActor(x, y, z, facing, nil, attachEntity:GetScaling());
    channel:BindActorAgentToEntity(1, foodEntity,true, 2);
    channel:BindActorAgentToEntity(2, attachEntity,true);
    channel:Stop()
    channel:Play(0, -1)
    channel:Connect("finished", function()
        foodEntity:Destroy()
        attachEntity:SetSkin(preSkin,true)
        if callback then
            callback(itemData)
        end
    end)
end

function UserBagItemManager.SendUseItemMsg(itemData,ownerName,msgType)
    if not itemData or not itemData.id then return end
    local msg = {
        msgType = msgType,
        touser = ownerName,
        username = Mod.WorldShare.Store:Get('user/username'),
        action= "food",
        data = itemData,
    }
    FriendActionManager.SendMsg(msg)
end

function UserBagItemManager.DeserializeItems(str)
    if not str or str == "" then return nil end
    local arr = {}
    local list = commonlib.split(str, ";")
    for _, s in ipairs(list) do
        if s and s ~= "" then
            local info = commonlib.split(s, ",")
            if info and #info >= 2 then
                local it = {}
                it.id = info[1]
                it.name = info[2]
                it.posx = (info[3] ~= "") and tonumber(info[3]) or nil
                it.posy = (info[4] ~= "") and tonumber(info[4]) or nil
                it.posz = (info[5] ~= "") and tonumber(info[5]) or nil
                it.scale = info[6]
                it.facing = info[7]
                arr[#arr+1] = it
            end
        end
    end
    return arr
end

UserBagItemManager.Init()
