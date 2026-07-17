--[[
    author: pbb
    date: 2025-04-08
    useLib: 
        local TimeLimitPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/TimeLimitPage.lua")
        TimeLimitPage.ShowTimeLimit()
]]
local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local keepwork_time_key = "keepwork_game_time"
local env
if (type(System.os.IsEmscripten) == 'function' and System.os.IsEmscripten()) then
    env = 'asIframeInWebParacraft'
else
    env = 'asWebviewInParacraftClient'
end
local diffTime = 1
local saveTimeDistance = 30
local baseStamina = 160 -- 初始精力
local chargingTime = 0
local chargeDis = 2
local base_url = string.format("https://keepwork.com/public/resource/miniGameProxy.html?projectPath=maisi/maisi/webgames/data&gameName=timelimit_dialog&%s=true",env)
local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local TimeLimitPage = NPL.export()

function TimeLimitPage.GetPageParams()
    local gameTimeDatas = TimeLimitPage.GetGameTime()
    if not gameTimeDatas then
        return
    end
    local gameTime = gameTimeDatas.gameTime
    local isLateNight = TimeLimitPage.IsLateNight()
    return gameTime,isLateNight 
end

function TimeLimitPage.IsLateNight()
    local hour = tonumber(os.date("%H"))
    local isLateNight = hour < 8 or hour >= 23
    return isLateNight
end

function TimeLimitPage.IsCustomGameStarted()
    if not GameLogic.MiniGameMgr then
        return false
    end
    local isCustomGameStarted = GameLogic.MiniGameMgr:IsCustomGameStarted()
    return isCustomGameStarted
end

function TimeLimitPage.ShowTimeLimit()
    local isCanShow = not MiniGamePage.IsVisible() and TimeLimitPage.IsCustomGameStarted() and MiniGameMainPage.UIMode == "Task"
    if not isCanShow then
        LOG.std(nil,"info","TimeLimitPage","TimeLimitPage.ShowTimeLimit is not valid")
        return
    end
    local gameTime,lateNight = TimeLimitPage.GetPageParams()
    gameTime = gameTime or 0
    gameTime = math.ceil(gameTime/60)
    lateNight = lateNight or false
    local url = base_url .. "&gametime=" .. gameTime .. "&nighttime=" .. tostring(lateNight)
    MiniGamePage.OpenBrowser(url,function()
        --TimeLimitPage.Close()
    end)
end

function TimeLimitPage.Close()
    MiniGamePage.ClosePage()
end

local keepwork_time_key = "keepwork_game_time"

function TimeLimitPage.ResetGameTimeData()
    TimeLimitPage.gameTimeDatas = nil
    TimeLimitPage.GetGameTime()
end

function TimeLimitPage.GetGameTime()
    if not TimeLimitPage.gameTimeDatas then
        local gameTimeDatas = GameLogic.GetPlayerController():LoadRemoteData(keepwork_time_key,nil) or {}
        if not gameTimeDatas.gameTime then
            gameTimeDatas.gameTime  = 0
        end
        if not gameTimeDatas.today then
            gameTimeDatas.today = os.date("%Y-%m-%d")
        end
        if not gameTimeDatas.stamina then
            gameTimeDatas.stamina = TimeLimitPage.GetBaseStamina()
        end
        if gameTimeDatas.today ~= os.date("%Y-%m-%d")  then 
            gameTimeDatas.gameTime = 0
            gameTimeDatas.today = os.date("%Y-%m-%d")
            gameTimeDatas.stamina = TimeLimitPage.GetBaseStamina()
            TimeLimitPage.gameTimeDatas = gameTimeDatas
            TimeLimitPage.SaveGameTime()
            return TimeLimitPage.gameTimeDatas
        end
        TimeLimitPage.gameTimeDatas = gameTimeDatas
    end
    return TimeLimitPage.gameTimeDatas
end

function TimeLimitPage.SaveGameTime()
    if not TimeLimitPage.gameTimeDatas then
        return
    end
    GameLogic.GetPlayerController():SaveRemoteData(keepwork_time_key, TimeLimitPage.gameTimeDatas)
end

function TimeLimitPage.UpdateTimeLimit()
    if not System.options.mc then
        return
    end
    local gameTimeDatas = TimeLimitPage.GetGameTime()
    if not gameTimeDatas then
        return
    end
    if gameTimeDatas.today ~= os.date("%Y-%m-%d") then
        --挂机跨天
        TimeLimitPage.gameTimeDatas = nil
        gameTimeDatas = TimeLimitPage.GetGameTime()
    end
    TimeLimitPage.UpdateUserStamina()
    saveTimeDistance = saveTimeDistance - diffTime
    gameTimeDatas.gameTime = gameTimeDatas.gameTime + diffTime
    if saveTimeDistance <= 0 then
        TimeLimitPage.SaveGameTime()
        saveTimeDistance = 30        
    end
    GameLogic.GetCodeGlobal():BroadcastTextEvent("gameTimeUpdated", gameTimeDatas)
end

function TimeLimitPage.CheckPlayerMoved()
    local player =GameLogic.EntityManager and GameLogic.EntityManager.GetFocus()
    if not player then
        return
    end
    if not TimeLimitPage.pos then
        local bx,by,bz = player:GetBlockPos()
        TimeLimitPage.pos = {bx,by,bz}
        return true
    end
    local bx,by,bz = player:GetBlockPos()
    if bx ~= TimeLimitPage.pos[1] or by ~= TimeLimitPage.pos[2] or bz ~= TimeLimitPage.pos[3] then
        TimeLimitPage.pos = {bx,by,bz}
        return true
    end
    return false
end

local updateStaminaDistance = 5
local addStaminaDistance = 25
function TimeLimitPage.UpdateUserStamina()
    local gameTimeDatas = TimeLimitPage.GetGameTime()
    if not gameTimeDatas then
        return
    end
    updateStaminaDistance = updateStaminaDistance - diffTime
    if updateStaminaDistance <= 0 then
        updateStaminaDistance = 5
        if TimeLimitPage.CheckPlayerMoved() then
            gameTimeDatas.stamina = gameTimeDatas.stamina - 1
            if gameTimeDatas.stamina <= 0 then
                gameTimeDatas.stamina = 0
            end
            TimeLimitPage.RefreshStaminaProgress()
        end
    end
    addStaminaDistance = addStaminaDistance - diffTime
    if addStaminaDistance <= 0 then
        addStaminaDistance = 25
        TimeLimitPage.AddStamina((TimeLimitPage.isCharging and 2 or 1))
    end
end

function TimeLimitPage.Reducestamina(num)
    local gameTimeDatas = TimeLimitPage.GetGameTime()
    if not gameTimeDatas then
        return
    end
    gameTimeDatas.stamina = gameTimeDatas.stamina - num
    if gameTimeDatas.stamina <= 0 then
        gameTimeDatas.stamina = 0
    end
    TimeLimitPage.RefreshStaminaProgress()
end

function TimeLimitPage.AddStamina(num)
    local gameTimeDatas = TimeLimitPage.GetGameTime()
    if not gameTimeDatas then
        return
    end
    gameTimeDatas.stamina = gameTimeDatas.stamina + num
    if gameTimeDatas.stamina >= TimeLimitPage.GetBaseStamina() then
        gameTimeDatas.stamina = TimeLimitPage.GetBaseStamina()
        -- GameLogic.AddBBS(nil, L"体力值已恢复")
    end
    TimeLimitPage.RefreshStaminaProgress()
end

function TimeLimitPage.RefreshStaminaProgress()
    local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua");
    MiniGameMainPage.SetStamina()
end

function TimeLimitPage.GetBaseStamina()
    return baseStamina
end

function TimeLimitPage.GetStamina()
    local gameTimeDatas = TimeLimitPage.GetGameTime()
    if not gameTimeDatas then
        return 0
    end
    return gameTimeDatas.stamina
end

function TimeLimitPage.CheckTimeLimit()
     if System.options.isEducatePlatform or System.options.isPapaAdventure then
        return false
    end
    if not System.options.mc then
        return false
    end
    return true
end

function TimeLimitPage.IsTimeLimited()
    if not TimeLimitPage.CheckTimeLimit() then
        return false
    end
    if TimeLimitPage.isUnLimited then
        return false
    end
    if TimeLimitPage.IsLateNight() then
        return true
    end
    return false
end

function TimeLimitPage.OnRecvMessage(msg)
    local action = msg.type;
    if action == "addExtraGameTime_client" then
        
    end
    if action == "clearDailyGameTime_client" then
        
    end
    if action == "cancelDailyTimeLimit_client" then
        TimeLimitPage.Close()
        TimeLimitPage.isUnLimited = true
    end
end

function TimeLimitPage.StartCharging()
    if not TimeLimitPage.timeCtrl then
        return
    end
    TimeLimitPage.isCharging = true
    if not TimeLimitPage.chargingTimer then
        TimeLimitPage.chargingTimer = commonlib.Timer:new({
            callbackFunc = function()
                local gameTimeDatas = TimeLimitPage.GetGameTime()
                if not gameTimeDatas then
                    return false
                end
                if gameTimeDatas.stamina <= TimeLimitPage.GetBaseStamina() then
                    if TimeLimitPage.canRecharge then
                        TimeLimitPage.isCharging = true
                    else
                        TimeLimitPage.isCharging = false
                    end
                else
                    TimeLimitPage.StopCharging()
                end
            end
        })
    end
    TimeLimitPage.chargingTimer:Change(0,1000)
end


function TimeLimitPage.StopCharging()
    if TimeLimitPage.chargingTimer then
        TimeLimitPage.chargingTimer:Change()
    end
    TimeLimitPage.isCharging = false
end

function TimeLimitPage.TickBatteryRecharge()
    TimeLimitPage.canRecharge = true
    if not TimeLimitPage.delayChargeTimer then
        TimeLimitPage.delayChargeTimer = commonlib.Timer:new({
            callbackFunc = function()
                TimeLimitPage.canRecharge = false
                if TimeLimitPage.isCharging then
                    TimeLimitPage.StopCharging()
                end
            end
        })
    end
    TimeLimitPage.delayChargeTimer:Change(5*1000, nil)
end