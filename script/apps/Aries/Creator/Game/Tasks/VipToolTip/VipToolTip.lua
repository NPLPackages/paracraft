--[[
Title: VersionNotice
Author(s):  big
Date: 2020.01.14
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local VipToolTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolTip.lua")
VipToolTip:Init(true)
------------------------------------------------------------
]]
-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

-- UI
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local UserInfo = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/UserInfo.lua")
local VipToolTip = NPL.export()
VipToolTip.onlyRecharge = false;

function VipToolTip:Init(bEnable, callback)
    VipToolTip.callback = callback
    if not KeepworkService:IsSignedIn() then
        GameLogic.GetFilters():apply_filters('store_set',"user/loginText",L"您需要登录并成为VIP用户，才能使用此功能")
        LoginModal:Init(function(bSuccesed)
            if bSuccesed then
                self:CheckVip(bEnable)
            end
        end)
    else
        self:CheckVip(bEnable)
    end
end

function VipToolTip:CheckVip(bEnable)
    if (not GameLogic.GetFilters():apply_filters('store_get', 'user/isVip') or bEnable) then
        VipToolTip.onlyRecharge = bEnable;
        self:ShowPage()
    else
        if type(self.callback) == "function" then
            VipToolTip.callback()
        end
    end
end

function VipToolTip:ShowPage()  
    local view_width = 0
	local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolTip.html",
        name = "VipToolTip:ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
            align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.vip_popup')
end

function VipToolTip:RefreshVipInfo()
    UserInfo:LoginWithToken(VipToolTip.callback);
end

function VipToolTip:Close()
   
end