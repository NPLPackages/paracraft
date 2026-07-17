--[[
    author:{pbb}
    time:2025-02-17 13:50:48
    uselib:
        local UserInfoOfflinePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoOfflinePage.lua")
        UserInfoOfflinePage.ShowPage()
]]
NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
local UserInfoOfflinePage = NPL.export()

local page
local skinConfig = {
    "80001;84117;81001;88002;85083;83190;",
    "80001;84116;81001;88002;85130;83212;",
    "80001;84062;81003;88002;85081;83213;",
    "80001;82086;84016;81024;88002;85094;",
    "80001;82027;84003;81024;88002;85098;",
    "80001;84029;81024;88002;85054;83054;"
}
local AIGC_SAVE_KEY = "aries_aigc_player_key"
function UserInfoOfflinePage.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = UserInfoOfflinePage.OnCreate
    page.OnClose = UserInfoOfflinePage.OnClose
end
UserInfoOfflinePage.skinIndex = -1
UserInfoOfflinePage.offlineName = ""
local function IsRandomName(name)
    if not name or name == "" then
        return true
    end
    name = string.lower(name)
    local regex = "^bob%d+$"
    local regex2 = "^alice%d+$"
    if string.match(name, regex) or string.match(name, regex2) then
        return true
    end
    return false
end

function UserInfoOfflinePage.OnCreate()
    UserInfoOfflinePage.RefreshSkin()
    UserInfoOfflinePage.RefreshBg()
    UserInfoOfflinePage.RefreshOtherInfo()
end

function UserInfoOfflinePage.RefreshOtherInfo()
    if UserInfoOfflinePage.offlineName and UserInfoOfflinePage.offlineName ~= "" then
        page:SetUIValue("offlineName",UserInfoOfflinePage.offlineName)
    end
end

function UserInfoOfflinePage.RefreshBg()
    local preBtn = ParaUI.GetUIObject("UserInfoOfflinePage.previewAvatar")
    local nextBtn = ParaUI.GetUIObject("UserInfoOfflinePage.nextAvatar")
    local preBg = ParaUI.GetUIObject("UserInfoOfflinePage.previewBg")
    local nextBg = ParaUI.GetUIObject("UserInfoOfflinePage.nextBg")
    if not preBtn or not preBtn:IsValid() or not nextBtn or not nextBtn:IsValid() or not preBg or not preBg:IsValid() or not nextBg or not nextBg:IsValid() then
        return
    end
    local skinIndex = UserInfoOfflinePage.skinIndex % 2
    local maxSkinIndex = math.ceil(#skinConfig / 2)
    local skinUIIndex = UserInfoOfflinePage.GetSkinIndex()
    if skinUIIndex == 1 then
        preBtn.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;260 176 120 84"
        preBtn.enabled = false
        nextBtn.enabled = true
        nextBtn.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;132 176 120 84"
    elseif skinUIIndex == maxSkinIndex then
        preBtn.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;4 176 120 84"
        nextBtn.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;388 265 120 84"
        preBtn.enabled = true
        nextBtn.enabled = false
    else
        preBtn.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;4 176 120 84"
        nextBtn.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;132 176 120 84"
        preBtn.enabled = true
        nextBtn.enabled = true
    end
    if skinIndex == 0 then
        preBg.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;44 447 32 32:14 14 14 14"
        nextBg.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;4 478 32 32:14 14 14 14"
    elseif skinIndex == 1 then
        preBg.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;4 478 32 32:14 14 14 14"
        nextBg.background = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;44 447 32 32:14 14 14 14"
    end
end

function UserInfoOfflinePage.RefreshSkin()
    local skinUIIndex = UserInfoOfflinePage.GetSkinIndex()
    local skinConfigStr = skinConfig[skinUIIndex * 2 - 1]
    local nextSkinConfigStr = skinConfig[skinUIIndex * 2]
    if skinConfigStr and skinConfigStr ~= "" then
        page:CallMethod("UserInfoMyPlayer1","SetCustomGeosets",skinConfigStr)
    end
    local module_ctl = page:FindControl("UserInfoMyPlayer1")
    local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
    if scene and scene:IsValid() then
        local player = scene:GetObject(module_ctl.obj_name);
        if player then
            player:SetScale(1)
            player:SetFacing(1.57);
            player:SetField("HeadUpdownAngle", 0.2);
            player:SetField("HeadTurningAngle", 0);
            
        end
    end
    if nextSkinConfigStr and nextSkinConfigStr ~= "" then
        page:CallMethod("UserInfoMyPlayer2","SetCustomGeosets",nextSkinConfigStr)
    end
    local module_ctl = page:FindControl("UserInfoMyPlayer2")
    local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
    if scene and scene:IsValid() then
        local player = scene:GetObject(module_ctl.obj_name);
        if player then
            player:SetScale(1)
            player:SetFacing(1.57);
            player:SetField("HeadUpdownAngle", 0.2);
            player:SetField("HeadTurningAngle", 0);
            
        end
    end
end

function UserInfoOfflinePage.OnClose()

end

function UserInfoOfflinePage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function UserInfoOfflinePage.RefreshPage()
    if page then
        page:Refresh(0.01)
    end
end

function UserInfoOfflinePage.OnPreviewAvatar()
    UserInfoOfflinePage.skinIndex = UserInfoOfflinePage.skinIndex - 2
    if UserInfoOfflinePage.skinIndex < 1 then
        UserInfoOfflinePage.skinIndex = 1
    end
    UserInfoOfflinePage.RefreshPage()
end

function UserInfoOfflinePage.OnNextAvatar()
    UserInfoOfflinePage.skinIndex = UserInfoOfflinePage.skinIndex + 2
    if UserInfoOfflinePage.skinIndex > #skinConfig then
        UserInfoOfflinePage.skinIndex = #skinConfig
    end
    UserInfoOfflinePage.RefreshPage()
end

function UserInfoOfflinePage.OnSelectAvatar(index)
    local skinUIIndex = UserInfoOfflinePage.GetSkinIndex()
    if index == 1 then
        UserInfoOfflinePage.skinIndex = skinUIIndex * 2 - 1
    else
        UserInfoOfflinePage.skinIndex = skinUIIndex * 2
    end
    UserInfoOfflinePage.GetRandomName()
    UserInfoOfflinePage.RefreshPage()
end

function UserInfoOfflinePage.GetSkinIndex()
    local skinIndex = UserInfoOfflinePage.skinIndex
    if skinIndex == -1 then
        return 1
    end
    return math.ceil(skinIndex / 2)
end

function UserInfoOfflinePage.OnInitOfflineData()
    local offline_data = GameLogic.GetPlayerController():LoadLocalData(AIGC_SAVE_KEY,{},true);
    if offline_data then
        UserInfoOfflinePage.offlineName = (offline_data.name and offline_data.name ~= "") and offline_data.name or ""
        UserInfoOfflinePage.skinIndex = offline_data.skinIndex or 1
    end
    AppGeneralGameClient:SetAnonymousUserName(nil)
    UserInfoOfflinePage.GetRandomName()
end

function UserInfoOfflinePage.IsClearSaveData()
    local offline_data = GameLogic.GetPlayerController():LoadLocalData(AIGC_SAVE_KEY,{},true);
    if offline_data and offline_data.name and offline_data.name ~= "" and IsRandomName(UserInfoOfflinePage.offlineName)  then
        GameLogic.GetPlayerController():SaveLocalData(AIGC_SAVE_KEY,{},true)
        return true
    end
    return false
end

function UserInfoOfflinePage.SaveOfflineData()
    local offline_data = {}
    local need_save = false
    if not IsRandomName(UserInfoOfflinePage.offlineName) then
        offline_data.name = UserInfoOfflinePage.offlineName
        need_save = true
    end
    if UserInfoOfflinePage.skinIndex ~= -1 then
        offline_data.skinIndex = UserInfoOfflinePage.skinIndex
        need_save = true
    end
    if not need_save then
        return
    end
    if not UserInfoOfflinePage.IsClearSaveData() then
        GameLogic.GetPlayerController():SaveLocalData(AIGC_SAVE_KEY,offline_data,true)
    end
end

function UserInfoOfflinePage.ShowPage()
    local is_signed_in = GameLogic.GetFilters():apply_filters('is_signed_in')
    if is_signed_in then
        GameLogic.AddBBS("notice",L"你已登录，无法使用离线模式", 5000, "0 255 0")
        return
    end
    UserInfoOfflinePage.OnInitOfflineData()
    local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoOfflinePage.html",
		name = "UserInfoOfflinePage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		cancelShowAnimation = true,
		enable_esc_key = true,
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end


function UserInfoOfflinePage.OnConfirm()
    local skinConfigStr = skinConfig[UserInfoOfflinePage.skinIndex]
    if not skinConfigStr or skinConfigStr == "" then
        GameLogic.AddBBS("notice",L"请选择头像", 5000, "0 255 0")
        return 
    end
    if page then
        UserInfoOfflinePage.offlineName = page:GetUIValue("offlineName") or ""
    end
    if not UserInfoOfflinePage.offlineName or UserInfoOfflinePage.offlineName == "" then
        GameLogic.AddBBS("notice",L"请输入昵称,或随机昵称", 5000, "0 255 0")
        return
    end
    UserInfoOfflinePage.RefreshGGSInfo()
    UserInfoOfflinePage.SaveOfflineData()
    UserInfoOfflinePage.ClosePage()
end

function UserInfoOfflinePage.RefreshGGSInfo() -- 刷新多人联网信息
    local playerEntity = GameLogic.GetPlayerController():GetPlayer();
	if playerEntity then
        local skinConfigStr = skinConfig[UserInfoOfflinePage.skinIndex]
        if skinConfigStr and skinConfigStr ~= "" then
		    playerEntity:SetSkin(skinConfigStr); 
        end
	end
    AppGeneralGameClient:SetAnonymousUserName(UserInfoOfflinePage.offlineName)
    if AppGeneralGameClient:IsLogin() then
        GameLogic.GetFilters():apply_filters("ggs", {action = "UpdateNickName", nickname = UserInfoOfflinePage.offlineName});
        GameLogic.GetFilters():apply_filters("ggs", {action = "UpdateUserInfo", 
            userinfo = {
                nickname = UserInfoOfflinePage.offlineName, 
                username=UserInfoOfflinePage.offlineName,
            }});
        return
    end
end

function UserInfoOfflinePage.OnClickLogin()
    GameLogic.CheckSignedIn(L"请先登录", function(result)
        if result then
            UserInfoOfflinePage.ClosePage()
            UserInfoOfflinePage.ShowOnlinePage()
        end
    end)
end

function UserInfoOfflinePage.ShowOnlinePage() -- 显示在线界面
    local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoPage.lua")
    UserInfoPage.ShowPage()
end

function UserInfoOfflinePage.GetRandomName(bForce)
    if not IsRandomName(UserInfoOfflinePage.offlineName) and not bForce then
        return
    end
    math.randomseed(ParaGlobal.timeGetTime());
    local skinIndex = UserInfoOfflinePage.skinIndex % 2
    if skinIndex == 1 then
        UserInfoOfflinePage.offlineName = "Bob".. string.format("%03d", math.random(1, 999))
    elseif skinIndex == 0 then
        UserInfoOfflinePage.offlineName = "Alice".. string.format("%03d", math.random(1, 999))
    end
end

function UserInfoOfflinePage.OnRandomName()
    UserInfoOfflinePage.GetRandomName(true)
    UserInfoOfflinePage.RefreshOtherInfo()
end

