--[[
Title: UserInfoCtrl
Author(s): 
Date: 2024/11/14
Desc:  
Use Lib:
-------------------------------------------------------
--用户信息控件
local UserInfoCtrl = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/UserInfoCtrl.lua");
UserInfoCtrl.ShowPage(username)
--]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
local Encoding = commonlib.gettable("System.Encoding");
local UserInfoCtrl = NPL.export()
local page
UserInfoCtrl.userData = {}
function UserInfoCtrl.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = UserInfoCtrl.OnCreate
end

function UserInfoCtrl.LoadUserInfo(username,userId,callback)
	if not username and not userId then
		return
	end
    UserInfoCtrl.userData = {}
	local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
	if userId and tonumber(userId) > 0 then
		id = "kp" .. Encoding.base64(commonlib.Json.Encode({userId=userId}));
	end
	keepwork.user.getinfo({
		cache_policy = "access plus 1 day",
        router_params = {
            id = id,
        }
    },function (err, msg, data)
		if err == 200 then
            UserInfoCtrl.userData = {
                username = data.username or "",
                userId = data.id,
                nickname = data.nickname or "",
                vip = data.vip or 0,
                commonVip = data.commonVip or 0,
                portrait = data.portrait or "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png",
            }
            local extra = data.extra or {}
            if extra.ParacraftPlayerEntityInfo then
                UserInfoCtrl.userData.modelUrl = extra.ParacraftPlayerEntityInfo.asset or ""
                UserInfoCtrl.userData.modelScale = extra.ParacraftPlayerEntityInfo.scale or 1
                UserInfoCtrl.userData.skin = extra.ParacraftPlayerEntityInfo.skin or ""
                if UserInfoCtrl.userData.modelScale > 1 then
                    UserInfoCtrl.userData.modelScale = 1
                end
            end
			if callback and type(callback) == "function" then
                callback()
            end
		else
			GameLogic.AddBBS(nil,L"获取用户信息失败")
		end
	end)
end

function UserInfoCtrl.OnCreate()
    if page then
        if UserInfoCtrl.userData.modelUrl or UserInfoCtrl.userData.modelUrl ~= "" then
            page:CallMethod("user_ctrl_player","SetAssetFile",UserInfoCtrl.userData.modelUrl)
        end
        if UserInfoCtrl.userData.skin or UserInfoCtrl.userData.skin ~= "" then
            page:CallMethod("user_ctrl_player","SetCustomGeosets",UserInfoCtrl.userData.skin)
        end

    end
end

function UserInfoCtrl.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
        UserInfoCtrl.pagePosX = nil
        UserInfoCtrl.pagePosY = nil
    end
end

function UserInfoCtrl.IsShowInTeamArea()
    return UserInfoCtrl.pagePosX and UserInfoCtrl.pagePosY and UserInfoCtrl.pagePosX == 30 and UserInfoCtrl.IsVisible()
end

function UserInfoCtrl.IsVisible()
    return page and page:IsVisible()
end

function UserInfoCtrl.ShowPage(username,userId, x, y, callbackFunc)
    if not System.options.isCommunity then
		return
	end
    if UserInfoCtrl.IsVisible() then
        UserInfoCtrl.ClosePage()
    end
    local TeamPlayerPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/TeamPlayerPage.lua");
    local pageX = TeamPlayerPage.IsVisible() and 220 or 30
    local pageY = 30
    UserInfoCtrl.pagePosX = pageX
    UserInfoCtrl.pagePosY = pageY
	UserInfoCtrl.LoadUserInfo(username,userId,function()
        local params = {
            url = "script/apps/Aries/Creator/Game/Areas/ChatSystem/UserInfoCtrl.html", 
            name = "UserInfoCtrl.ShowPage", 
            app_key=MyCompany.Aries.app.app_key, 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = -10,
            enable_esc_key = false,
            isTopLevel = false,
            allowDrag = false,
            directPosition = true,
            align = "_lt",
            x = x or pageX,
            y = y or pageY,
            width = 180,
            height = 100,
        };

        System.App.Commands.Call("File.MCMLWindowFrame", params);
        
        if type(callbackFunc) == "function" then
            callbackFunc()
        end
    end)
end

function UserInfoCtrl.ShowUserOperateMenu(username,chatId,chatType, x, y)
    UserInfoCtrl.chatId = chatId
    UserInfoCtrl.chatType = chatType -- 1:私聊 private 2:群聊 team
    UserInfoCtrl.LoadUserInfo(username,nil,function()
        UserInfoCtrl.ShowUserOperate(x, y)
    end)
end

function UserInfoCtrl.GetChatData()
    if not UserInfoCtrl.chatId or not UserInfoCtrl.chatType then
        return nil
    end
    local ChatManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatManager.lua");
    return ChatManager.GetChatData(UserInfoCtrl.chatId,UserInfoCtrl.chatType)
end

function UserInfoCtrl.ShowUserOperate(x, y)
    local OperateMenuPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/OperateMenuPage.lua");
    local chatData = UserInfoCtrl.GetChatData()
    OperateMenuPage.ShowPage(3,UserInfoCtrl.userData,nil,chatData, x, y)
end
