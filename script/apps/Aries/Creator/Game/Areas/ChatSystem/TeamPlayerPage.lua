--[[
Title: TeamPlayerPage
Author(s): 
Date: 2024/11/14
Desc:  
Use Lib:
-------------------------------------------------------
--队伍频道用户界面（有队伍是显示队伍成员，没有队伍显示自己）
local TeamPlayerPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamPlayerPage.lua");
TeamPlayerPage.ShowPage()
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local TeamManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamManager.lua");
local page
local TeamPlayerPage = NPL.export()
TeamPlayerPage.allUserInfo = {}
function TeamPlayerPage.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = TeamPlayerPage.OnCreate
end

function TeamPlayerPage.IsGameStarted()
    local is_enter_world = GameLogic.GetFilters():apply_filters('store_get', 'world/isEnterWorld');
    return Game.is_started or is_enter_world
end

function TeamPlayerPage.ShowPage()
    if TeamPlayerPage.CheckClose() then
        TeamPlayerPage.ClosePage()
        return
    end
    local is_signed_in = GameLogic.GetFilters():apply_filters('is_signed_in')
	if not is_signed_in then
        LOG.std(nil, "info", "TeamPlayerPage", "please sign in first");
        return
    end
    GameLogic.CheckSignedIn(L"请先登录！", function()
        if not TeamPlayerPage.IsGameStarted() then
            return
        end
        
        if not TeamManager:IsShowTeamMember() then
            if TeamManager.IsShowRoleInfo() then
                TeamPlayerPage.ShowSelf()
            end
            return 
        end
        TeamPlayerPage.ShowTeam()
    end);
end

function TeamPlayerPage.CheckClose()
    print("TeamPlayerPage check close", TeamPlayerPage.IsGameStarted(), TeamManager:IsShowTeamMember(), TeamManager.IsShowRoleInfo())
    if not TeamPlayerPage.IsGameStarted() then
        return true
    end

    if TeamManager:IsShowTeamMember() or TeamManager.IsShowRoleInfo() then
        return false
    end

    if not TeamManager:IsShowTeamMember() and not TeamManager.IsShowRoleInfo() then
        return true
    end
    return false
end

function TeamPlayerPage.CloseWindow()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function TeamPlayerPage.ClosePage()
    TeamPlayerPage.CloseWindow()
    TeamPlayerPage.allUserInfo = {}
end

function TeamPlayerPage.RefreshPage()
    if page then
        page:Refresh(0.2)
    end
end

function TeamPlayerPage.IsVisible()
    return page and page:IsVisible()
end

function TeamPlayerPage.InitData(isSelf)
    TeamPlayerPage.allUserInfo = {}
    if isSelf then
        local profile = KeepWorkItemManager.GetProfile() 
        if not profile then
            return
        end
        local user_info = {
            userId = profile.id,
            username = profile.username,
            nickname = profile.nickname,
            portrait = profile.portrait or "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png",
            vip = profile.vip or 0,
            commonVip = profile.commonVip or 0,
        }
        local extra = profile.extra or {}
        if extra.ParacraftPlayerEntityInfo then
            user_info.modelUrl = extra.ParacraftPlayerEntityInfo.asset or ""
            user_info.skin = extra.ParacraftPlayerEntityInfo.skin or ""
            user_info.scale = extra.ParacraftPlayerEntityInfo.scale or 1
            if user_info.scale > 1 then
                user_info.scale = 1
            end
        end
        TeamPlayerPage.allUserInfo[#TeamPlayerPage.allUserInfo + 1] = user_info
        return
    end
    local all_team_info = TeamManager:GetAllTeamInfo()
    if not all_team_info then
        return
    end
    for k, v in pairs(all_team_info) do
        local team_user_info = v.userinfo
        if team_user_info then
            local user_info = {
                userId = team_user_info.id,
                username = team_user_info.username,
                nickname = team_user_info.nickname or "",
                portrait = team_user_info.portrait or "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png",
                vip = team_user_info.vip or 0,
                commonVip = team_user_info.commonVip or 0,
            }
            local extra = team_user_info.extra or {}
            if extra.ParacraftPlayerEntityInfo then
                user_info.modelUrl = extra.ParacraftPlayerEntityInfo.asset or ""
                user_info.skin = extra.ParacraftPlayerEntityInfo.skin or ""
                user_info.scale = extra.ParacraftPlayerEntityInfo.scale or 1
            end
            TeamPlayerPage.allUserInfo[#TeamPlayerPage.allUserInfo + 1] = user_info
        end
    end
end

function TeamPlayerPage.ShowSelf()
    TeamPlayerPage.InitData(true)
    TeamPlayerPage.ShowPlayerPage()
end

function TeamPlayerPage.ShowTeam()
    TeamPlayerPage.InitData(false)
    TeamPlayerPage.ShowPlayerPage()
end

function TeamPlayerPage.OnCreate()
    if not page then
        return
    end
    
    if TeamPlayerPage.timer  then
        TeamPlayerPage.timer:Change()
    end
    TeamPlayerPage.role_index = 1
    TeamPlayerPage.timer = TeamPlayerPage.timer or commonlib.Timer:new({callbackFunc = function(timer)
        local all_team_info = TeamManager:GetAllTeamInfo() or {}
        local num = #all_team_info
        if num == 0 then
            timer:Change()
            return
        end
		if TeamPlayerPage.role_index <= num then
			local data = all_team_info[TeamPlayerPage.role_index]
            local team_ctrl_name = "team_player_"..TeamPlayerPage.role_index
            local modelUrl, skin = TeamPlayerPage.GetPlayerInfo(data)
			if modelUrl and modelUrl ~= "" then
				page:CallMethod(team_ctrl_name,"SetAssetFile",modelUrl)
            end
            if skin and skin ~= "" then
                page:CallMethod(team_ctrl_name,"SetCustomGeosets",skin)
            end
            TeamPlayerPage.role_index = TeamPlayerPage.role_index + 1
        else
            timer:Change()
        end
	end})
    TeamPlayerPage.timer:Change(0, 200)
end

function TeamPlayerPage.GetPlayerInfo(data)
    if not data then
        return
    end
    local user_info = data.userinfo or {}
    local extra = user_info.extra or {}
    local ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {}
    local modelUrl = ParacraftPlayerEntityInfo.asset or ""
    local skin = ParacraftPlayerEntityInfo.skin or ""
    return modelUrl, skin
end

function TeamPlayerPage.IsTeamLeader(data)
    local all_team_info = TeamManager:GetAllTeamInfo()
    if not all_team_info or not data then
        return false
    end
    local teamLeaderInfo = all_team_info[1]
    if not teamLeaderInfo then
        return false
    end
    -- echo(teamLeaderInfo,true)
    local my_userId = Mod.WorldShare.Store:Get('user/userId')
    local id1 = tonumber(teamLeaderInfo.userId)
    local id2 = tonumber(data.userId)
    if not id1 or not id2 then
        return false
    end
    return my_userId == id1
end

function TeamPlayerPage.ShowPlayerPage()
    if TeamPlayerPage.IsVisible() then
        TeamPlayerPage.CloseWindow()
    end
    TeamPlayerPage.CloseUserCtrl()
    local num = #TeamPlayerPage.allUserInfo
    local params = {
        url = "script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamPlayerPage.html", 
        name = "TeamPlayerPage.ShowPage", 
        app_key=MyCompany.Aries.app.app_key, 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = -10,
        enable_esc_key = false,
        isTopLevel = false,
        allowDrag = false,
        directPosition = true,
        align = "_lb",
        x = 20,
        y = -90 - num *80,
        width = 180,
        height = num *80,
    };

    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function TeamPlayerPage.CloseUserCtrl()
    local UserInfoCtrl = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/UserInfoCtrl.lua");
    if UserInfoCtrl.IsShowInTeamArea() then
        UserInfoCtrl.ClosePage()
    end
end

function TeamPlayerPage.ShowTeamOperate(user)
    if not user then
        return
    end
    if not TeamPlayerPage.IsShowTeamMember() then
        print("not have team")
        return
    end
    local isTeamLeader = TeamPlayerPage.IsTeamLeader(user)
    local OperateMenuPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/OperateMenuPage.lua");
    OperateMenuPage.ShowPage(2,user,isTeamLeader)
end

function TeamPlayerPage.IsShowTeamMember()
    return TeamManager:IsShowTeamMember()
end

