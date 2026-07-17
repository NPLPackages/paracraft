--[[
-- 好友动作管理
    uselib:
    local FriendActionManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionManager.lua");
    FriendActionManager.Init()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyFriendAction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local EasyModelStove = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModelStove.lua");
local EasyFriendAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyFriendAction");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local storePageName = "friendLevelConfig"
local storeKeyName = "friendLevel"
local baseAnimPath = "character/Animation/movietemplates/player/"
local FriendActionManager = NPL.export()

function FriendActionManager.Init()
    if FriendActionManager.isInitialized then return end
    FriendActionManager.isInitialized = true
    FriendActionManager.sendMsgList = {}
    FriendActionManager.recvMsgList = {}
    FriendActionManager.friendLevelConfig = {}
    FriendActionManager.LoadFriendLevelConfig() 
    FriendActionManager.StartUpdateActionMsgs()
    GameLogic.GetFilters():remove_filter("OnGGSLogout",  FriendActionManager.OnGGSLogout);
    GameLogic.GetFilters():add_filter("OnGGSLogout",  FriendActionManager.OnGGSLogout);
    GameLogic.GetFilters():remove_filter("ggs_recv_user_action",  FriendActionManager.RecvUserAction);
    GameLogic.GetFilters():add_filter("ggs_recv_user_action",  FriendActionManager.RecvUserAction);
end

function FriendActionManager.OnWorldUnLoad()
    if FriendActionManager.actionTimer then
        FriendActionManager.actionTimer:Change()
    end
    FriendActionManager.sendMsgList = {}
    FriendActionManager.recvMsgList = {}
end

function FriendActionManager.OnWorldLoadFinished()
    GameLogic.GetCodeGlobal():RegisterTextEvent("play_cooking_dish_movie", FriendActionManager.OnPlayCookingAnimate);
    GameLogic.GetCodeGlobal():RegisterTextEvent("play_fishing_movie", FriendActionManager.OnPlayFishingAnimate);
end

function FriendActionManager.LoadFriendLevelConfig(callback) -- 加载好友等级配置
    local storeTool = FriendActionManager.GetStoreTool()
    if not storeTool then return end
    storeTool:LoadPageData(storePageName, storeKeyName, function(data)
        local friendShips = data and commonlib.deepcopy(data) or {}
        local friendLevelConfig = {}
        for key, item in pairs(friendShips) do
            friendLevelConfig[key] = {level = item[1], lastUpdateTime = item[2]}
        end
        FriendActionManager.friendLevelConfig = friendLevelConfig
        if callback and type(callback) == "function" then
            callback()
        end
    end)
end

function FriendActionManager.GetFriendLevel(username) 
    if not username or username == "" then return end
    local friendLevelConfig = FriendActionManager.friendLevelConfig[username]
    local friendSignDay = friendLevelConfig and friendLevelConfig.level or 1
    local level = FriendActionManager.GetFriendLevelBySignDay(friendSignDay)
    return (level and level > 0) and level or 1
end

function FriendActionManager.GetFriendLevelBySignDay(signDay)
    if not signDay or signDay == "" then return 1 end
    signDay = tonumber(signDay) or 0
    if signDay <= 0 then
        return 0
    end
    local k = math.floor((math.sqrt(8 * signDay + 1) - 1) / 2)
    if k < 0 then k = 0 end
    return k
end

function FriendActionManager.SaveFriendLevelConfig()
    local storeTool = FriendActionManager.GetStoreTool()
    if not storeTool then return end
    local saveData = {}
    for key, item in pairs(FriendActionManager.friendLevelConfig) do
        saveData[key] = {item.level,item.lastUpdateTime}
    end
    storeTool:SavePageData(storePageName, storeKeyName, saveData, true)
end

function FriendActionManager.AddFriendLevel(username)
    if not username or username == "" then return end
    local friendLevelConfig = FriendActionManager.friendLevelConfig[username]
    if not friendLevelConfig then
        friendLevelConfig = {}
    end
    local lastUpdateTime = friendLevelConfig.lastUpdateTime or ""
    local currentTime = os.date("%Y_%m_%d")
    if lastUpdateTime ~= currentTime or System.options.isDevMode then
        if friendLevelConfig.level then
            friendLevelConfig.level = friendLevelConfig.level + 1
        else
            friendLevelConfig.level = 1
        end
        friendLevelConfig.lastUpdateTime = os.date("%Y_%m_%d")
        FriendActionManager.friendLevelConfig[username] = friendLevelConfig
        FriendActionManager.SaveFriendLevelConfig()

        GameLogic.AddBBS("friend","恭喜你和"..username.."完成了今日的好友印记")
    end
end

function FriendActionManager.GetStoreTool()
    if not FriendActionManager.storeTool then
        NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
        FriendActionManager.storeTool = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
    end
    return FriendActionManager.storeTool
end

function FriendActionManager.OnGGSLogout(username)
    LOG.std(nil, "info", "FriendActionManager","OnGGSLogout user is %s", tostring(username)) 

    return username
end

function FriendActionManager.AddPreSendMsg(msg) -- 添加预发送消息
    if not msg then return end
    msg.msgType = "request"
    local sendUser = msg.username
    local toUser = msg.touser
    if not toUser or toUser == "" or not sendUser or sendUser == "" or sendUser == toUser then
        return
    end
    for index, item in ipairs(FriendActionManager.sendMsgList) do
        if item.username == sendUser and item.touser == toUser then
            table.remove(FriendActionManager.sendMsgList, index)
            break
        end
    end
    msg.startTime = os.time()
    table.insert(FriendActionManager.sendMsgList, msg)
    FriendActionManager.SendMsg(msg) 
    FriendActionManager.StartUpdateActionMsgs()
    FriendActionManager.ShowActionTips()
end

function FriendActionManager.SendMsg(msg) -- 发送消息
    if not msg then return end
    local playerManager = FriendActionManager.GetGGSPlayerManager()
    if playerManager and playerManager.SendUserAction then
        playerManager:SendUserAction(msg)
    end
end

function FriendActionManager.HandleSendMsg(msg) --收到请求返回
    if not msg then return end
    local sendUser = msg.username
    local toUser = msg.touser
    local action = msg.action
    if not toUser or toUser == "" or not sendUser or sendUser == "" or sendUser == toUser then
        return
    end
    local itemData = nil
    for index, item in ipairs(FriendActionManager.sendMsgList) do
        if item.username == toUser and item.touser == sendUser and item.action == action then
            itemData = item
            table.remove(FriendActionManager.sendMsgList, index)
            break
        end
    end
    if not itemData then return end --已经过期的请求
    FriendActionManager.DoAction(itemData)
    FriendActionManager.AddFriendLevel(sendUser)
    FriendActionManager.ShowActionTips()
end

function FriendActionManager.GetGGSPlayerManager()
    NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
    local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
    if AppGeneralGameClient:IsLogin() then
        local world = AppGeneralGameClient:GetWorld()
        if not world then
             return
        end
        return world:GetPlayerManager()
    end
end

function FriendActionManager.AddPreResolveMsg(msg)
    if not msg then return end
    local sendUser = msg.username
    local toUser = msg.touser
    if not toUser or toUser == "" or not sendUser or sendUser == "" or sendUser == toUser then
        return
    end
    msg.msgType = "response"
    msg.startTime = os.time()
    for index, item in ipairs(FriendActionManager.recvMsgList) do
        if item.username == sendUser and item.touser == toUser then
            table.remove(FriendActionManager.recvMsgList, index)
            break
        end
    end
    table.insert(FriendActionManager.recvMsgList, msg)
    FriendActionManager.StartUpdateActionMsgs()
    FriendActionManager.ShowActionTips()
end

function FriendActionManager.ResolveMsg(msg) -- 同意请求
    if not msg then return end
    if FriendActionManager.IsPlayingCustomMovie(msg.username) 
        or FriendActionManager.IsPlayingCustomMovie(msg.touser) then
            GameLogic.AddBBS("friend","请等待当前动作完成")
        return
    end
    local myNickName = Mod.WorldShare.Store:Get('user/nickname')
    local playerManager = FriendActionManager.GetGGSPlayerManager()
    if playerManager and playerManager.SendUserAction then
        local sendMsg = {
            action = msg.action,
            msgType = msg.msgType,
            touser = msg.username,
            username = msg.touser,
            nickname = myNickName or msg.touser,
        }
        playerManager:SendUserAction(sendMsg)
    end
    for index, item in ipairs(FriendActionManager.recvMsgList) do
        if item.username == msg.username and item.touser == msg.touser then
            table.remove(FriendActionManager.recvMsgList, index)
            break
        end
    end
    local actionname = msg.action
    FriendActionManager.DoAction(msg,true)
    FriendActionManager.AddFriendLevel(msg.username)
    FriendActionManager.ShowActionTips()
end

function FriendActionManager.SendFriendAction(actionname,touser)
    if not actionname or actionname == "" then
        return
    end
    local fromUserName = Mod.WorldShare.Store:Get('user/username')
    local fromNickName = Mod.WorldShare.Store:Get('user/nickname')
    if FriendActionManager.IsPlayingCustomMovie(fromUserName) then
        GameLogic.AddBBS("friend","请等待当前动作完成")
        return
    end
    local msg = {
        username = fromUserName,
        nickname = fromNickName or fromUserName,
        touser = touser,
        action = actionname,
    }
    FriendActionManager.AddPreSendMsg(msg)
end

function FriendActionManager.RecvUserAction(packet) -- 收到好友动作请求
    if not packet or not packet.username then
        return
    end
    local msgType = packet.msgType
    if msgType == "requestUseitem" or msgType == "responseUseitem" then
        local UserBagItemManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/UserBagItemManager.lua");
        UserBagItemManager.OnRecvUseItemMsg(packet)
        return
    end
    if msgType == "syncCustomAnimation" then
        FriendActionManager.OnPlayCustomAnimate(packet)
        return
    end
    local username = Mod.WorldShare.Store:Get('user/username')
    local touser = packet.touser or ""
    if touser ~= username then
        return true
    end
    if msgType == "request" then
        FriendActionManager.AddPreResolveMsg(packet)
    elseif msgType == "response" then
        FriendActionManager.HandleSendMsg(packet)
    end
end

function FriendActionManager.DoAction(itemData, isResolve)
    local actionName = itemData.action or ""
    local actionData = EasyFriendAction.GetActionDataByName(actionName)
    if not actionData then
        return
    end
    local animId = actionData.animId
    local animFile = actionData.animFile
    local funcName = actionData.funcName
    if isResolve and funcName and funcName == "OnClickAddFriend" then
        local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        FriendsPage.Show(3);
    end
    if animFile and animFile ~= "" then
        itemData.animFile = animFile
        FriendActionManager.DoCustomAction(itemData)
        return
    end
    if animId and tonumber(animId) < 500 then
        FriendActionManager.DoDefaultAction(itemData)
        return
    end
end

local lastParamsBeforeCustomMoviePlay = {}
function FriendActionManager.StoreLastParamsBeforeCustomMoviePlay(username, entity, effectEntity)
    if not username or not entity then
        return
    end
    local preSkin = entity:GetSkin()
    local x,y,z = entity:GetPosition()
    if not lastParamsBeforeCustomMoviePlay[username] then
        lastParamsBeforeCustomMoviePlay[username] = {
            skin = preSkin,
            animId = entity:GetCurrentAnimId(),
            position = {x,y,z},
            facing = entity:GetFacing(),
            roll = entity:GetRoll(),
            pitch = entity:GetPitch(),
            scaling = entity:GetScaling(),
            opacity = entity:GetOpacity(),
        }
        if effectEntity then
            lastParamsBeforeCustomMoviePlay[username].effectEntity = effectEntity
        end
    end
end

function FriendActionManager.IsPlayingCustomMovie(username)
    if not username or not lastParamsBeforeCustomMoviePlay[username] then
        return false
    end
    return true
end

function FriendActionManager.RestoreLastParamsBeforeCustomMoviePlay(username, entity)
    if not username or not entity then
        return
    end
    local lastParams = lastParamsBeforeCustomMoviePlay[username]
    if not lastParams then
        return
    end
    entity:SetSkin(lastParams.skin)
    entity:SetAnimation(lastParams.animId)
    if lastParams.position then
        entity:SetPosition(unpack(lastParams.position))
    end
    entity:SetFacing(lastParams.facing)
    entity:SetRoll(lastParams.roll)
    entity:SetPitch(lastParams.pitch)
    entity:SetScaling(lastParams.scaling)
    entity:SetOpacity(lastParams.opacity)
    if lastParams.effectEntity then
        lastParams.effectEntity:Destroy()
    end
    lastParamsBeforeCustomMoviePlay[username] = nil
end

--电影方块动作
function FriendActionManager.DoCustomAction(itemData)
    local animFile = itemData.animFile
    local playEntity = GameLogic.EntityManager.GetEntity("__GGS__"..itemData.username)
    local targetEntity = GameLogic.EntityManager.GetEntity("__GGS__"..itemData.touser)
    if not playEntity or not targetEntity then
        return
    end
    local channel = FriendActionManager.GetMovieChanel(itemData.username,itemData.touser)
    if not channel then
        return
    end

    FriendActionManager.StoreLastParamsBeforeCustomMoviePlay(itemData.username, playEntity)
    FriendActionManager.StoreLastParamsBeforeCustomMoviePlay(itemData.touser, targetEntity)
    local x,y,z = playEntity:GetPosition()

    CommonCtrl.FileLoader.AsyncLoadAsset(animFile, function(bSuccess, filepath)
        if bSuccess and filepath then
            channel:CreateFromTemplateFile(filepath);
            channel:SetAutoStopWhenPlayFinish(true)
            channel:Disconnect("finished");
            channel:TransformActorsByFirstActor(x, y, z, playEntity:GetFacing(), nil, playEntity:GetScaling());
            channel:BindActorAgentToEntity(1, playEntity,true);
            channel:BindActorAgentToEntity(2, targetEntity,true);
            channel:Stop()
            channel:Play(0, -1)
            channel:Connect("finished", function()
                FriendActionManager.RestoreLastParamsBeforeCustomMoviePlay(itemData.username, playEntity)
                FriendActionManager.RestoreLastParamsBeforeCustomMoviePlay(itemData.touser, targetEntity)
            end);
        end
    end)

end

function FriendActionManager.DoDefaultAction(itemData)
    local actionName = itemData.action or ""
    local actionData = EasyFriendAction.GetActionDataByName(actionName)
    if not actionData then
        return
    end
    local animId = actionData.animId
    if not animId or animId == "" then
        return
    end
    local playEntity = GameLogic.EntityManager.GetEntity("__GGS__"..itemData.username)
    local targetEntity = GameLogic.EntityManager.GetEntity("__GGS__"..itemData.touser)
    local isMineSend = itemData.username == Mod.WorldShare.Store:Get('user/username')
    if not playEntity or not targetEntity then
        return
    end
    local customAnim = actionData.customAnim or ""

    if(actionData.smiley and actionData.smiley ~= "") then
        local resolveResult = GameLogic.GetFilters():apply_filters("CustomSmileyResolve",{
            is_symbol = true,
            words = actionData.smiley,
        }) or {}
        local isResolve = resolveResult.result
        if isResolve then
            local chatContent = resolveResult.resultcontent
            local customSay = GameLogic.GetFilters():apply_filters("ggs_custom_chat")
            playEntity:Say(chatContent, 10,nil,customSay)
        end
    end

    local animDuration = actionData.animDuration or 2000;
    -- Make entities face each other
    local x1, y1, z1 = playEntity:GetPosition();
    local x2, y2, z2 = targetEntity:GetPosition();
    local dx = x2 - x1;
    local dz = z2 - z1;
    local facing = math.atan2(dx, dz) - math.pi/2; 
    playEntity:SetFacing(facing);
    targetEntity:SetFacing(facing + math.pi);
    
    local animFunc = targetEntity.SetAnimId or targetEntity.SetAnimation;
    animFunc(targetEntity, animId)
    targetEntity:SetHeadRotation(0, 0);
    commonlib.TimerManager.SetTimeout(function()
        animFunc(targetEntity, 0);
    end, animDuration);
    playEntity:SetControlledExternally(true);
    playEntity:SetHeadRotation(0, 0);
    playEntity:SetAnimation(animId);
    commonlib.TimerManager.SetTimeout(function()
        if(playEntity) then
            playEntity:SetAnimation(0);
            playEntity:SetControlledExternally(false);
            if (customAnim == "follow" and isMineSend) then
                playEntity:SetFollowTarget(targetEntity)
            elseif (customAnim == "followme" and not isMineSend) then
                targetEntity:SetFollowTarget(playEntity)
            end
        end
    end, animDuration);
end

function FriendActionManager.StartUpdateActionMsgs()
    FriendActionManager.actionTimer = FriendActionManager.actionTimer or commonlib.Timer:new({callbackFunc = function(timer)
        FriendActionManager.UpdateActionMsgs()
    end})
    FriendActionManager.actionTimer:Change(0, 1000)
end

-- 时间 和 距离
function FriendActionManager.UpdateActionMsgs()
    local isUpdate = false
    for index, item in ipairs(FriendActionManager.recvMsgList) do
        local nowTime = os.time()
        local timeDiff = nowTime - item.startTime
        if timeDiff >= 30 then
            table.remove(FriendActionManager.recvMsgList, index)
            isUpdate = true
            break
        end
    end
    for index, item in ipairs(FriendActionManager.sendMsgList) do
        local nowTime = os.time()
        local timeDiff = nowTime - item.startTime
        if timeDiff >= 30 then
            table.remove(FriendActionManager.sendMsgList, index)
            isUpdate = true
            break
        end
    end
    for index, item in ipairs(FriendActionManager.recvMsgList) do
        local username = item.username or ""
        local touser = item.touser or ""
        local distance = FriendActionManager.GetUserDistance(username, touser)
        if distance > 10 then
            table.remove(FriendActionManager.recvMsgList, index)
            isUpdate = true
            break
        end
    end
    for index, item in ipairs(FriendActionManager.sendMsgList) do
        local username = item.username or ""
        local touser = item.touser or ""
        local distance = FriendActionManager.GetUserDistance(username, touser)
        if distance > 10 then
            table.remove(FriendActionManager.sendMsgList, index)
            isUpdate = true
            break
        end
    end
    if isUpdate then
        FriendActionManager.ShowActionTips()
    end
end

function FriendActionManager.GetUserDistance(username1, username2)
    if not username1 or username1 == "" or not username2 or username2 == "" then
        return 0
    end
    local userEntity1 = GameLogic.EntityManager.GetEntity("__GGS__"..username1)
    local userEntity2 = GameLogic.EntityManager.GetEntity("__GGS__"..username2)
    if not userEntity1 or not userEntity2 then
        return 0
    end
    local bx1, by1, bz1 = userEntity1:GetBlockPos()
    local bx2, by2, bz2 = userEntity2:GetBlockPos()
    if not bx1 or not by1 or not bz1 or not bx2 or not by2 or not bz2 then
        return 0
    end
    local distance = math.floor(math.sqrt((bx1 - bx2)^2 + (by1 - by2)^2 + (bz1 - bz2)^2))
    return distance
end

function FriendActionManager.StopAction()

end

function FriendActionManager.GetMovieChanel(username1,username2)
   local key = username1.."_"..username2
   FriendActionManager.movieChanelMap = FriendActionManager.movieChanelMap or {}
   if not FriendActionManager.movieChanelMap[key] then
       FriendActionManager.movieChanelMap[key] = MovieManager:CreateGetMovieChannel(key);
   end
   return FriendActionManager.movieChanelMap[key]
end

function FriendActionManager.GetSingleMovieChanel(username,bContinuous)
    username = username or "offline"
    local key = username.."_single"
    if bContinuous then
        key = key..os.time()
    end
    FriendActionManager.movieChanelMap = FriendActionManager.movieChanelMap or {}
    FriendActionManager.movieChanelMap[username] = FriendActionManager.movieChanelMap[username] or {}
    if not FriendActionManager.movieChanelMap[username][key] then
        FriendActionManager.movieChanelMap[username][key] = MovieManager:CreateGetMovieChannel(key);
    end
    return FriendActionManager.movieChanelMap[username][key]
end

function FriendActionManager.StopSingleMovieChanel(username)
    username = username or "offline"
    FriendActionManager.movieChanelMap = FriendActionManager.movieChanelMap or {}
    FriendActionManager.movieChanelMap[username] = FriendActionManager.movieChanelMap[username] or {}
    for key, movieChanel in pairs(FriendActionManager.movieChanelMap[username]) do
        movieChanel:Stop()
    end
    FriendActionManager.movieChanelMap[username] = {}
end

function FriendActionManager.ResumePlayerState()
    
end

function FriendActionManager.GetAllNeedResolveMsg()
    local allNeedResolveMsg = {}
    for index, item in ipairs(FriendActionManager.sendMsgList) do
        table.insert(allNeedResolveMsg, item)
    end
    for index, item in ipairs(FriendActionManager.recvMsgList) do
        table.insert(allNeedResolveMsg, item)
    end
    return allNeedResolveMsg
end

function FriendActionManager.ShowActionTips()
    local allNeedResolveMsg = FriendActionManager.GetAllNeedResolveMsg()
    local FriendActionTips = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionTips.lua")
    if #allNeedResolveMsg == 0 then
        FriendActionTips.ClosePage()
        return
    end
    FriendActionTips.ShowPage(allNeedResolveMsg)
end

local maxCookingIndex = 5
local startCookingIndex = 1
local cookingStepList
local lastParamsBeforeMoviePlay

local generCookingList = function()
    if not cookingStepList then
        cookingStepList = {}
        for index = startCookingIndex, maxCookingIndex do
            cookingStepList[index] = {
                animFile=baseAnimPath.."Cooking"..index..".blocks.xml",
                actorIndex1=1,
            }
        end
    end
    return cookingStepList
end

function FriendActionManager.PlayCookingAnimate(username,bIgnoreCamera,bContinuous,params)
    generCookingList()
    
    local function play_step(index)
        if index > maxCookingIndex then 
            FriendActionManager.StopSingleMovieChanel(username)
            EasyModelStove.ShowBaseEntity(true)
            return 
        end
        local stepData = cookingStepList[index]
        if not stepData then 
            play_step(index + 1)
            return 
        end
        local animParams = {
            action = "cooking", 
            username = username, 
            animFile = stepData.animFile, 
            actorIndex1 = stepData.actorIndex1,
            nextFunc = function()
                play_step(index + 1)
            end
        }
        if params and type(params) == "table" then
            commonlib.partialcopy(animParams, params)
            local isLast = (index == maxCookingIndex)
            animParams.isLast = isLast
            if not isLast then
                animParams.actorIndex2 = 2
            end
        end
        EasyModelStove.ShowBaseEntity(false)
        FriendActionManager.PlayActionAnimate(username, animParams,bIgnoreCamera,bContinuous)
    end
    FriendActionManager.StopSingleMovieChanel(username)
    play_step(startCookingIndex)
end

function FriendActionManager.PlayGGSCookingAnimate(username,params)
    FriendActionManager.StopSingleMovieChanel(username)
    local animParams = {
        action = "cooking", 
        username = username, 
        animFile = baseAnimPath.."CookingOther.blocks.xml", 
        actorIndex1 = 1,
    }
    if params and type(params) == "table" then
        commonlib.partialcopy(animParams, params)
        if params.model and params.model ~= "" then
            animParams.isLast = true
            animParams.actorIndex2 = 2
        end
    end
    FriendActionManager.PlayActionAnimate(username, animParams)
end

function FriendActionManager.OnPlayCookingAnimate(args,msg)
    if msg and msg.type == "msg" then
        msg = msg.msg or {}
    end
    local data = msg.data or {}
    local username = Mod.WorldShare.Store:Get('user/username')
    local params = {action = "cooking", username = username, msgType = "syncCustomAnimation"}
    commonlib.partialcopy(params, data)
    FriendActionManager.SendMsg(params)
    FriendActionManager.PlayCookingAnimate(username,nil,true,params)
end

function FriendActionManager.OnPlayFishingAnimate(args,msg)
    if msg and msg.type == "msg" then
        msg = msg.msg or {}
    end
    local action = "fishing"
    local username = Mod.WorldShare.Store:Get('user/username')
    local params = {action = action, username = username, msgType = "syncCustomAnimation"}
    commonlib.partialcopy(params, msg)
    FriendActionManager.SendMsg(params)
    FriendActionManager.StopSingleMovieChanel(username)

    local animFile = baseAnimPath.."Fishing"..(params.animIndex or 1)..".blocks.xml"
    local animParams ={
        action = action, 
        username = username, 
        animFile = animFile, 
        actorIndex1 = 1,
        isLast = true,
    } 
    commonlib.partialcopy(animParams, msg)
    if msg.model and msg.model ~= "" then
        animParams.actorIndex2 = 2
    end
    FriendActionManager.PlayActionAnimate(username, animParams)
end

function FriendActionManager.OnPlayCustomAnimate(packet)
     local username = Mod.WorldShare.Store:Get('user/username')
     if packet and packet.username == username then
        return
     end
     local pName = packet.username or ""
     if FriendActionManager.GetUserDistance(username, pName) > 10 then
        return
     end
     local action = packet.action or ""
     FriendActionManager.StopSingleMovieChanel(pName)
     if action == "cooking" then
        FriendActionManager.PlayGGSCookingAnimate(pName,packet)
     elseif action == "fishing" then
        local animIndex = packet.animIndex or 1
        local animFile = baseAnimPath.."Fishing"..animIndex..".blocks.xml"
        local animParams ={
            action = action, 
            username = pName, 
            animFile = animFile, 
            actorIndex1 = 1,
            isLast = true,
        } 
        if packet.model and packet.model ~= "" then
            animParams.actorIndex2 = 2
        end
        commonlib.partialcopy(animParams, packet)
        FriendActionManager.PlayActionAnimate(pName, animParams,true)
     end
end

function FriendActionManager.PlayActionAnimate(username, params, ignoreCamera, bContinuous)
    username = username or "offline"
    local entity =  GameLogic.EntityManager.GetEntity("__GGS__"..username)
    if not entity then 
        entity =  GameLogic.GetPlayer()
    end
    local movieChanel = FriendActionManager.GetSingleMovieChanel(username,bContinuous)
    if not movieChanel then
        return
    end
    local animFile = params.animFile or ""
    if animFile == "" then
        return
    end
    local x,y,z = entity:GetPosition()
    local preSkin = entity:GetSkin()

    lastParamsBeforeMoviePlay = lastParamsBeforeMoviePlay or {}
    if not lastParamsBeforeMoviePlay[username] then
        lastParamsBeforeMoviePlay[username] = {
            skin = preSkin,
            animId = entity:GetCurrentAnimId(),
            position = {x,y,z},
            facing = entity:GetFacing(),
            roll = entity:GetRoll(),
            pitch = entity:GetPitch(),
            scaling = entity:GetScaling(),
            opacity = entity:GetOpacity(),
        }
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
    local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
    local newSkin = CustomCharItems:RemoveSkinByCategory(preSkin, "right_hand_equipment")
    entity:SetSkin(newSkin)

    CommonCtrl.FileLoader.AsyncLoadAsset(animFile, function(bSuccess, filepath)
        if bSuccess and filepath then
            movieChanel:CreateFromTemplateFile(filepath);
            movieChanel:SetAutoStopWhenPlayFinish(true)
            movieChanel:Disconnect("finished");
            movieChanel:TransformActorsByFirstActor(x, y, z, entity:GetFacing(), newSkin, entity:GetScaling(),ignoreCamera);
            if params.actorIndex1 then
                movieChanel:BindActorAgentToEntity(params.actorIndex1, entity);
            end
            local effectEntity = FriendActionManager.AddOtherEffect(entity,movieChanel,params)
            if effectEntity then
                lastParamsBeforeMoviePlay[username].effectEntity = effectEntity
            end
            movieChanel:Stop()
            movieChanel:Play(0, -1)
            movieChanel:Connect("finished", function()
                if lastParamsBeforeMoviePlay and lastParamsBeforeMoviePlay[username] then
                    entity:SetSkin(lastParamsBeforeMoviePlay[username].skin)
                    entity:SetAnimation(lastParamsBeforeMoviePlay[username].animId)
                    if lastParamsBeforeMoviePlay[username].position then
                        entity:SetPosition(unpack(lastParamsBeforeMoviePlay[username].position))
                    end
                    entity:SetFacing(lastParamsBeforeMoviePlay[username].facing)
                    entity:SetRoll(lastParamsBeforeMoviePlay[username].roll)
                    entity:SetPitch(lastParamsBeforeMoviePlay[username].pitch)
                    entity:SetScaling(lastParamsBeforeMoviePlay[username].scaling)
                    entity:SetOpacity(lastParamsBeforeMoviePlay[username].opacity)
                    if lastParamsBeforeMoviePlay[username].effectEntity then
                        lastParamsBeforeMoviePlay[username].effectEntity:Destroy()
                    end
                    lastParamsBeforeMoviePlay[username] = nil
                end
                if params and params.nextFunc and type(params.nextFunc) == "function" then
                    params.nextFunc()
                end
            end);
        end
    end)

end

function FriendActionManager.AddOtherEffect(attachedEntity,channel,params)
    if not channel or not params or not attachedEntity then
        return
    end
    local isLast = params.isLast or false
    local model = params.model or ""
    local actorIndex2 = params.actorIndex2 or 2
    if model == "" or not isLast then
        return
    end
    local x,y,z = attachedEntity:GetPosition()
    local effect = GameLogic.EntityManager.EntityLiveModel:Create({x=x,y=y -0.1,z=z})
    effect:SetModelFile(model)
    effect:setScale(1)
    effect:SetName("effect"..params.action.."_"..params.username)
    effect:SetPersistent(false); -- Don't save this entity
    effect:Attach()
    channel:BindActorAgentToEntity(actorIndex2, effect);
    return effect
end

