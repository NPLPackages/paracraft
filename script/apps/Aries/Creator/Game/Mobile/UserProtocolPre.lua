--[[
Title: UserProtocolPre
Author(s): hyz
Date: 2023/01/14
Desc:  
Use Lib:
-------------------------------------------------------
local UserProtocolPre = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/UserProtocolPre.lua");
UserProtocolPre.CheckShow();
--]]
NPL.load("(gl)script/ide/System/localserver/LocalStorageUtil.lua");
local LocalStorageUtil = commonlib.gettable("System.localserver.LocalStorageUtil");
local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
local UserProtocol = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/UserProtocol.lua");

local UserProtocolPre = NPL.export()
local page


UserProtocolPre.GridDs = {{}}

function UserProtocolPre.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = UserProtocolPre.OnCreate
end
function UserProtocolPre.GetPageCtrl()
    return page;
end
function UserProtocolPre.RefreshPage()
	if(page)then
		page:Refresh(0);
	end
end
function UserProtocolPre.ClosePage()
	if(page)then
		page:CloseWindow(true)
	end
end

--只有Android端，没有同意用户协议和隐私政策的情况下，才需要强制弹出这个弹窗
--用户点击了同意以后，才能去收集硬件信息、权限等
function UserProtocolPre.CheckShow()
    if System.os.GetPlatform()~="android" then
        return 
    end
    
    local has_agree_userUserPrivacy = LocalStorageUtil.Load_localserver("has_agree_userUserPrivacy","false",true)
    if has_agree_userUserPrivacy=="true" then --已经同意过了
        PlatformBridge.onAgreeUserPrivacy()
    else
        UserProtocolPre.ShowPage()
    end
end
function UserProtocolPre.ShowPage()
    local params = {
		url = "script/apps/Aries/Creator/Game/Mobile/UserProtocolPre.html",
		name = "UserProtocolPre.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		directPosition = true,
		isTopLevel = true,
		zorder = 10,
		align = "_ct",
		x = -520/2,
		y = -570/2,
		width = 520,
		height = 570,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params)
end

function UserProtocolPre.ShowUserAgreementPage()
    UserProtocol.ShowPage(1);
end

function UserProtocolPre.ShowUserPrivacyPage()
    UserProtocol.ShowPage(2);
end

function UserProtocolPre.onBtn_agree()
    PlatformBridge.onAgreeUserPrivacy()
    LocalStorageUtil.Save_localserver("has_agree_userUserPrivacy","true",true)
    LocalStorageUtil.Flush_localserver()
    UserProtocolPre.ClosePage()
end


function UserProtocolPre.onBtn_close()
    UserProtocolPre.ClosePage()
    --ParaGlobal.ExitApp()
    --ParaGlobal.ExitApp()
end