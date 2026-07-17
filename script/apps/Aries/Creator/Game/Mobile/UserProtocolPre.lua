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
function UserProtocolPre.CheckShow(onClose)
    if System.os.GetPlatform()~="android" and not onClose then
        return 
    end
    UserProtocolPre.onCloseFunc = onClose
    UserProtocolPre.IsAgreePrivacy = false
    local has_agree_userUserPrivacy = LocalStorageUtil.Load_localserver("has_agree_userUserPrivacy","false",true)
    if has_agree_userUserPrivacy=="true" then --已经同意过了
        PlatformBridge.onAgreeUserPrivacy()
        UserProtocolPre.IsAgreePrivacy = true
        if onClose and type(onClose) == "function" then
            onClose()
        end
    else

        UserProtocolPre.ShowPage()
    end
end

function UserProtocolPre.ShowPage()
    
    local htmlStr = "script/apps/Aries/Creator/Game/Mobile/UserProtocolPre.html"
    if UserProtocolPre.onCloseFunc then
        htmlStr = "script/apps/Aries/Creator/Game/Mobile/UserProtocolPre_new.html"
    end
    local params = {
		url = htmlStr,
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
		height = 590,
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
    LocalStorageUtil.Save_localserver("partner_name",System.options.partner,true)
    LocalStorageUtil.Flush_localserver()
    UserProtocolPre.ClosePage()
    if UserProtocolPre.onCloseFunc and type(UserProtocolPre.onCloseFunc) == "function" then
        UserProtocolPre.onCloseFunc()
    end
end


function UserProtocolPre.onBtn_close()
    UserProtocolPre.ClosePage()
    if UserProtocolPre.onCloseFunc and type(UserProtocolPre.onCloseFunc) == "function" then
        _guihelper.MessageBox(
            "您未同意用户协议和隐私政策,请重新查看？",
            function(res)
                if (res and res == _guihelper.DialogResult.Yes) or System.options.isStrictGameMode then
                    UserProtocolPre.CheckShow(UserProtocolPre.onCloseFunc)
                else
                    ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
                    ParaGlobal.ExitApp()
                    ParaGlobal.ExitApp()
                end
            end,
            _guihelper.MessageBoxButtons.YesNo,nil,nil,nil,nil,{ ok = L"是", cancel = L"否", title = L"提示", }
        )
        return
    end

    ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
    ParaGlobal.ExitApp()
    ParaGlobal.ExitApp()
end

function UserProtocolPre.OnBtnCheck()
    UserProtocolPre.IsAgreePrivacy = not UserProtocolPre.IsAgreePrivacy
    UserProtocolPre.RefreshPage()
end