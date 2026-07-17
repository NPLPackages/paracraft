--[[
Title: TeamUserCtrl
Author(s): 
Date: 2024/11/14
Desc:  
Use Lib:
-------------------------------------------------------
--用户信息控件
local TeamUserCtrl = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamUserCtrl.lua");
TeamUserCtrl.CheckShow()
--]]
local TeamManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamManager.lua");
local TeamUserCtrl = NPL.export()
local self = TeamUserCtrl

function TeamUserCtrl.OnInit()
    self.page = document:GetPageCtrl()
    self.page.OnCreate = self.OnCreate
end

function TeamUserCtrl.Refresh()
    if not self.page then
        return 
    end
    self.page:Refresh(0.1)
end

function TeamUserCtrl.OnCreate()
    if not self.page then
        return
    end
    
    if TeamUserCtrl.timer  then
        TeamUserCtrl.timer:Change()
    end
    TeamUserCtrl.role_index = 1
    TeamUserCtrl.timer = TeamUserCtrl.timer or commonlib.Timer:new({callbackFunc = function(timer)
        local all_team_info = TeamManager:GetAllTeamInfo() or {}
        local num = #all_team_info
        if num == 0 then
            timer:Change()
            return
        end
		if TeamUserCtrl.role_index <= num then
			local data = all_team_info[TeamUserCtrl.role_index]
            local team_ctrl_name = "team_ctrl_player_"..TeamUserCtrl.role_index
            local modelUrl, skin = TeamUserCtrl.GetPlayerInfo(data)
			if modelUrl and modelUrl ~= "" then
				self.page:CallMethod(team_ctrl_name,"SetAssetFile",modelUrl)
            end
            if skin and skin ~= "" then
                self.page:CallMethod(team_ctrl_name,"SetCustomGeosets",skin)
            end
            TeamUserCtrl.role_index = TeamUserCtrl.role_index + 1
        else
            timer:Change()
        end
	end})
    TeamUserCtrl.timer:Change(0, 200)
end

function TeamUserCtrl.GetPlayerInfo(data)
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

function TeamUserCtrl.CheckShow()
    local CommunityMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.lua")
    if not CommunityMainPage.IsVisible() then
        self.ClosePage()
        return
    end
    if not TeamManager:IsShowTeamMember() then
        self.ClosePage()
        return
    end
    
    self.ShowPage()
end

function TeamUserCtrl.GetTeamMembers()
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
                nickname = team_user_info.nickname,
                portrait = team_user_info.portrait or "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png",
                vip = team_user_info.vip or 0,
                commonVip = team_user_info.commonVip or 0,
            }
            local extra = team_user_info.extra or {}
            if extra.ParacraftPlayerEntityInfo then
                user_info.modelUrl = extra.ParacraftPlayerEntityInfo.asset or ""
                user_info.skin = extra.ParacraftPlayerEntityInfo.skin or ""
                user_info.scale = extra.ParacraftPlayerEntityInfo.scale or 1
                if user_info.scale > 1 then
                    user_info.scale = 1
                end
            end
            TeamUserCtrl.allUserInfo[#TeamUserCtrl.allUserInfo + 1] = user_info
        end
    end
end

function TeamUserCtrl.ShowPage()
    if self.page then
        self.ClosePage()
    end
	TeamUserCtrl.allUserInfo = {}
    TeamUserCtrl.GetTeamMembers()
    local CommunityMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityMainPage.lua")
    local x,y,width, height = CommunityMainPage.GetTeamButtonInfo()
	if(not x) then
		return
	end
	x = x+width+30;
	if(x<0) then 
		x = 170;
	end
    local teamNum = #TeamUserCtrl.allUserInfo
    print("TeamUserCtrl.ShowPage=",x,y,width, height)
    local params = {
		url = "script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamUserCtrl.html", 
		name = "TeamUserCtrl.ShowPage", 
		-- app_key=MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		--zorder = 2,
		enable_esc_key = false,
		isTopLevel = false,
		allowDrag = false,
		directPosition = true,
			align = "_lt",
			x = x,
			y = y- height/2,
			width = teamNum * 42 + (teamNum+1) * 12,
			height = 60,
	};

	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function TeamUserCtrl.ClosePage()
	if self.page then
		self.page:CloseWindow()
        self.page = nil
	end
end

function TeamUserCtrl.IsTeamLeader(data)
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

function TeamUserCtrl.ShowTeamOperate(user)
    if not user then
        return
    end
    
    local isTeamLeader = TeamUserCtrl.IsTeamLeader(user)
    local OperateMenuPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/OperateMenuPage.lua");
    OperateMenuPage.ShowPage(4,user,isTeamLeader)
end