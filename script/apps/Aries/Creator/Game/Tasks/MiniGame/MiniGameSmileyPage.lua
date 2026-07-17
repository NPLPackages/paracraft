--[[
Title: MiniGame Smiley Page
    Author(s): ParaCraft Team
    Date: 2025/6/13
    Desc: 小游戏表情界面
    Use Lib:·
    -------------------------------------------------------
    local MiniGameSmileyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameSmileyPage.lua");
    MiniGameSmileyPage.ShowPage();
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
local MiniGameSmileyPage = NPL.export()

--符号顺序必须递增
local allsymbols = {
	{ icon = "Texture/Aries/Smiley/face01_32bits.png", symbol="$1", gsid=1},
	{ icon = "Texture/Aries/Smiley/animated/face02_32bits_fps10_a003.png", symbol="$2", gsid=2},
	{ icon = "Texture/Aries/Smiley/animated/face03_32bits_fps10_a003.png", symbol="$3", gsid=3},
	{ icon = "Texture/Aries/Smiley/animated/face04_32bits_fps10_a005.png", symbol="$4", gsid=4},
	{ icon = "Texture/Aries/Smiley/animated/face05_32bits_fps10_a004.png", symbol="$5", gsid=5},
	{ icon = "Texture/Aries/Smiley/animated/face06_32bits_fps10_a003.png", symbol="$6", gsid=6},
	{ icon = "Texture/Aries/Smiley/animated/face07_32bits_fps10_a003.png", symbol="$7", gsid=7},
	{ icon = "Texture/Aries/Smiley/animated/face08_32bits_fps10_a005.png", symbol="$8", gsid=8},
	{ icon = "Texture/Aries/Smiley/animated/face09_32bits_fps10_a005.png", symbol="$9", gsid=9},
	{ icon = "Texture/Aries/Smiley/animated/face10_32bits_fps10_a005.png", symbol="$10", gsid=10},
	{ icon = "Texture/Aries/Smiley/animated/face11_32bits_fps10_a004.png", symbol="$11", gsid=11},
	{ icon = "Texture/Aries/Smiley/face12_32bits.png", symbol="$12", gsid=12},
	{ icon = "Texture/Aries/Smiley/animated/face13_32bits_fps10_a003.png", symbol="$13", gsid=13},
	{ icon = "Texture/Aries/Smiley/face14_32bits.png", symbol="$14", gsid=14},
	{ icon = "Texture/Aries/Smiley/face15_32bits.png", symbol="$15", gsid=15},
}

local placeholder = {
    icon = "Texture/Aries/Dock/AddAsFriend_32bits.png",
    symbol = "0",
    gsid = 0,
}

local page
local customNum = 4
local customActionMap = {}
MiniGameSmileyPage.pageSymbols = commonlib.copy(allsymbols)
function MiniGameSmileyPage.OnInit()
    page = document:GetPageCtrl()
end


function MiniGameSmileyPage.LoadCustomActions()
    local customAction = MiniGameMgr.GetUnLockActions()
    local actions = {}
    for k,v in pairs(customAction) do
        local actionId = v.action_id
        local actionData = PlayerAssetFile:GetAnimationItem(tostring(actionId))
        if actionData then
            customActionMap[actionData.id] = true
            table.insert(actions, {icon = actionData.icon, symbol = actionData.id, gsid = 0})
        end
    end
    local num = #actions
    if num < customNum then
        for i=1,customNum-num do
            table.insert(actions, placeholder)
        end
    end
    return actions
end

function MiniGameSmileyPage.ShowPage()
    
    local customActions = MiniGameSmileyPage.LoadCustomActions()
    for k,v in pairs(customActions) do
        table.insert(MiniGameSmileyPage.pageSymbols, v)
    end
    local view_width = 650
    local view_height = 430
    local x,y,width, height = _guihelper.GetLastUIObjectPos();
	if(not x) then
		return
	end
	x = x+width/2 - view_width/2;
	if(x<0) then
		x = 30;
	end
    y  = y - view_height - 30
    if y < 0 then
        y = 30
    end
    MiniGameSmileyPage.RegisterCustomEvent()
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameSmileyPage.html", 
        name = "MiniGameSmileyPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = true,
        enable_esc_key = false,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 0,
        directPosition = true,
        click_through = true,
        align = "_lt",
        x = x,
        y = y,
        width = view_width,
        height = view_height,
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function MiniGameSmileyPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function MiniGameSmileyPage.RegisterCustomEvent()
    if not MiniGameSmileyPage.register then
        MiniGameSmileyPage.register = true
        GameLogic.GetFilters():add_filter("CustomSmileyResolve",  MiniGameSmileyPage.CustomSmileyResolve);
    end
end

function MiniGameSmileyPage.CustomSmileyResolve(packet)
    if not packet or not packet.is_symbol then
        return
    end
    local result = {result=false,resultcontent = ""}
    local content = packet.words
    local bFind = false
    local findData = nil
    for k,v in pairs(MiniGameSmileyPage.pageSymbols) do
        if v.symbol == content then
            bFind = true
            findData = v
            break
        end
    end
    if customActionMap[findData.symbol] then
        return
    end
    if bFind then
        local imgStr = string.format([[<img style='width:%dpx;height:%dpx;background:url(%s)' />]],64,64, findData.icon);
        result.result = true
        result.resultcontent = imgStr
        return result
    end
end

function MiniGameSmileyPage.OnClickIcon(index)
    local index = tonumber(index)
    if not index then
        return
    end
    local symbol = MiniGameSmileyPage.pageSymbols[index].symbol
    MiniGameSmileyPage.SendSmileySymbol(symbol)
end

local sendTime = 0
function MiniGameSmileyPage.SendSmileySymbol(symbol)
    if tonumber(symbol) == 0 then
        GameLogic.AddBBS(nil,L"请先解锁自定义表情")
        local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoPage.lua")
        UserInfoPage.ShowPage("maisiAIMainPage","anim")
        return
    end
    local curTime = ParaGlobal.timeGetTime();
    if curTime - sendTime < 2000 then
        GameLogic.AddBBS(nil,L"发送表情过于频繁，请稍后发送")
        return true
    end
    MiniGameSmileyPage.ClosePage()
    sendTime = curTime
    if customActionMap[symbol] then
        GameLogic.RunCommand(string.format("/anim %s", symbol))
        return
    end

    MiniGameSmileyPage.DoSendSmileySymbol(symbol)
end

function MiniGameSmileyPage.TrySendLocal(symbol)
    if not symbol then
        return false
    end
    local focusEntity = GameLogic.EntityManager:GetFocus()
    if not focusEntity then
        return false
    end
    local resolveResult = GameLogic.GetFilters():apply_filters("CustomSmileyResolve",{
        is_symbol = true,
        words = symbol,
    }) or {}
    local isResolve = resolveResult.result
    if isResolve then
        local chatContent = resolveResult.resultcontent
        local customSay = GameLogic.GetFilters():apply_filters("ggs_custom_chat")
        focusEntity:Say(chatContent, 5,nil,customSay)
    end
    return isResolve
end

function MiniGameSmileyPage.DoSendSmileySymbol(symbol)
    NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
    local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
    local canSend = true
    if not AppGeneralGameClient:IsLogin() then
        canSend = false
    end
    local world = AppGeneralGameClient:GetWorld()
    if not world then
        canSend = false
    end
    local playerManager = world and world:GetPlayerManager()
    if not playerManager then
        canSend = false
    end
    if  not canSend and MiniGameSmileyPage.TrySendLocal(symbol) then
        LOG.std(nil,"info","MiniGameSmileyPage","send smiley symbol %s local success",symbol)
        return
    end
    if not canSend then
        GameLogic.AddBBS(nil,L"发送失败，请重试")
        return
    end
    local isImmediate = true
    local projectId = GameLogic.options:GetProjectId();
    local msgData = {
        ChannelIndex = 21,
        worldId = projectId,
        words = symbol,
        type = 2,
        is_keepwork = true,
        is_symbol = true,
    }
    playerManager:SendUserChat(msgData,isImmediate)
end