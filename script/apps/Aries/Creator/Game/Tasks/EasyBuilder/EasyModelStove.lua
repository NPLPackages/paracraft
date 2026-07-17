--[[
Title: EasyBuilder Model Stove
Author(s): GitHub Copilot
Date: 2025/09/21
Desc: 

Use the lib:
------------------------------------------------------------
local EasyModelStove = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModelStove.lua");
EasyModelStove.EnsureBase()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockInEntityHand.lua");
local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local EasyModelStove = NPL.export()

local BASE_NAME = "__easy_stove_base__"
local WOOD_NAME = "__easy_stove_wood__"
local FIRE_NAME = "__easy_stove_fire__"
local STEAM_NAME = "__easy_stove_steam__"

local BASE_MODEL = "character/CC/artwar/game/guo.x"
local WOOD_MODEL = "character/CC/artwar/game/chai.x"
local FIRE_MODEL = "character/CC/05effect/V5/huoyan/huoyan.x"
local STEAM_MODEL= "character/CC/05effect/V5/wu/WU.x"

EasyModelStove.onShowResult = nil

function EasyModelStove.SetOnShowResult(func)
    EasyModelStove.onShowResult = func
end

local function removeEntityByName(name)
    local e = EntityManager.GetEntity(name)
    if e then
        e:Destroy()
    end
end

local function getDefaultPos()
    local player = EntityManager.GetFocus();
    if not player then
        return 0,0,0
    end
    local x,y,z = player:GetPosition()
    local facing = player:GetFacing()
    local dx = 2 * math.cos(facing)
    local dz = -2 * math.sin(facing)
    return x+dx, y, z+dz
end

function EasyModelStove.GetBaseEntity()
    return EntityManager.GetEntity(BASE_NAME)
end

function EasyModelStove.GetBasePosition()
    local base = EasyModelStove.GetBaseEntity()
    if base then
        local x,y,z = base:GetPosition()
        return x,y,z
    end
    local x,y,z = getDefaultPos()
    return x,y,z
end

function EasyModelStove.GetDistanceToBase()
    local base = EasyModelStove.GetBaseEntity()
    if base then
        local x,y,z = base:GetPosition()
        local px,py,pz = getDefaultPos()
        return math.sqrt((x-px)^2 + (z-pz)^2)
    end
    return 0
end

function EasyModelStove.CreateBase(pos)
    removeEntityByName(BASE_NAME)
    removeEntityByName(WOOD_NAME)
    removeEntityByName(FIRE_NAME)
    local x,y,z
    if pos and pos.x then
        x,y,z = pos.x, pos.y, pos.z
    elseif type(pos) == "table" and #pos>=3 then
        x,y,z = pos[1], pos[2], pos[3]
    else
        x,y,z = getDefaultPos()
    end
    local base = GameLogic.EntityManager.EntityLiveModel:Create({x=x,y=y,z=z})
    base:SetModelFile(BASE_MODEL)
    base:setScale(0.15)
    base:SetName(BASE_NAME)
    base:SetStaticTag("actionname", L"烹饪");
    base:SetOnClickEvent("on_click_cooking_pot");
    base:SetActionRadius(5);
    base:SetCanDrag(true)
    base:SetPersistent(false); -- Don't save this entity
    base:Attach()
    return base
end

function EasyModelStove.EnsureBase(pos)
    local base = EasyModelStove.GetBaseEntity()
    if base and EasyModelStove.GetDistanceToBase() < 10 then
        local x,y,z = getDefaultPos()
        base:SetPosition(x,y,z)
        return base
    end
    return EasyModelStove.CreateBase(pos)
end

function EasyModelStove.ShowBaseEntity(bShow)
    local base = EasyModelStove.GetBaseEntity()
    if base then
        base:SetVisible(bShow == true)
    end
end

function EasyModelStove.PlayCampfire(onFinished)
    local x,y,z = EasyModelStove.GetBasePosition()
    removeEntityByName(WOOD_NAME)
    removeEntityByName(FIRE_NAME)
    removeEntityByName(STEAM_NAME)
    local wood = GameLogic.EntityManager.EntityLiveModel:Create({x=x,y=y -0.1,z=z})
    wood:SetModelFile(WOOD_MODEL)
    wood:setScale(0.4)
    wood:SetName(WOOD_NAME)
    wood:SetPersistent(false); -- Don't save this entity
    wood:Attach()
    local fire = GameLogic.EntityManager.EntityLiveModel:Create({x=x,y=y + 0.4,z=z})
    fire:SetModelFile(FIRE_MODEL)
    fire:setScale(0.2)
    fire:SetName(FIRE_NAME)
    fire:SetPersistent(false); -- Don't save this entity
    fire:Attach()
    local steam = GameLogic.EntityManager.EntityLiveModel:Create({x=x,y=y + 0.8,z=z})
    steam:SetModelFile(STEAM_MODEL)
    steam:setScale(0.2)
    steam:SetName(STEAM_NAME)
    steam:SetPersistent(false); -- Don't save this entity
    steam:Attach()

    local timer = commonlib.Timer:new({
        callbackFunc = function()
            removeEntityByName(WOOD_NAME)
            removeEntityByName(FIRE_NAME)
            removeEntityByName(STEAM_NAME)
            if type(onFinished) == "function" then
                onFinished()
            elseif type(EasyModelStove.onShowResult) == "function" then
                EasyModelStove.onShowResult()
            end
        end
    })
    timer:Change(3000,nil)
end

function EasyModelStove.OnRecvMessage(msg)
    if msg and msg.type == "gameConsumed" then
        local data = msg.data
        local result = data.dish
        if result and result.id then
            local icon = result.icon
            EasyModelStove.PlayCampfire(function()
                EasyModelStove.ShowResult(icon)
            end)
        end
    end
end

function EasyModelStove.ShowResult(icon)
    if not icon or icon == "" then return end
    local entity = EasyModelStove.GetBaseEntity()
    if not entity then return end
    if EasyModelStove.headOnBlock then
        EasyModelStove.headOnBlock:Destroy()
        EasyModelStove.headOnBlock = nil
    end
    if EasyModelStove.effectEntity then
        EasyModelStove.effectEntity:Destroy()
        EasyModelStove.effectEntity = nil
    end
    local ex, ey, ez = entity:GetPosition()
    local yOffset = 0.5

    local headOnBlock = EntityManager.EntityLiveModel:Create({
        x = ex, y = ey + yOffset, z = ez,
        item_id = block_types.names.LiveModel,
    })
    if not headOnBlock then return end
    headOnBlock:SetPersistent(false)
    headOnBlock:SetDummy(true)
    headOnBlock:Attach()
    headOnBlock.nohistory = true
    BlockInEntityHand.TransformEntityTo3DTexture(headOnBlock, icon)
    
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
    EasyModelStove.headOnBlock = headOnBlock

    local effectModel = "character/CC/05effect/star.x"
    local effectEntity = GameLogic.EntityManager.EntityLiveModel:Create({
        x = ex, y = ey + yOffset + 0.2, z = ez,
        item_id = block_types.names.LiveModel,
    })
    effectEntity:SetModelFile(effectModel)
    effectEntity:setScale(0.4)
    effectEntity:SetPersistent(false); -- Don't save this entity
    effectEntity:Attach()
    EasyModelStove.effectEntity = effectEntity

    local frame = 0
    local timer
    timer = commonlib.Timer:new({
        callbackFunc = function()
            frame = frame + 1
            if not EasyModelStove.headOnBlock then
                timer:Change(nil, nil)
                return
            end
            local baseEntity = EasyModelStove.GetBaseEntity()
            if not baseEntity or baseEntity.isDead then
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
            EasyModelStove.headOnBlock:SetScaling(baseScale * scale)
            local currentRotation = initialRotation + (targetRotation - initialRotation) * progress
            EasyModelStove.headOnBlock:SetFacing(currentRotation)
            local px, py, pz = baseEntity:GetPosition()
            EasyModelStove.headOnBlock:SetPosition(px, py + yOffset, pz)
            if frame >= totalFrames then
                EasyModelStove.headOnBlock:SetScaling(baseScale * targetScale)
                EasyModelStove.headOnBlock:SetFacing(targetRotation)
                EasyModelStove.headOnBlock:Destroy()
                EasyModelStove.headOnBlock = nil
                EasyModelStove.effectEntity:Destroy()
                EasyModelStove.effectEntity = nil
                timer:Change(nil, nil)
            end
        end
    })
    timer:Change(0, math.floor(frameTime*1000))
end