--[[
author:{ygy}
time:2022-11-3

local MobilePermissionPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobilePermissionPage.lua")
MobilePermissionPage.ShowPage(callback)
]]

local MobilePermissionPage = NPL.export()

local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
local permissions = {
    "android.permission.RECORD_AUDIO",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.FOREGROUND_SERVICE",
}

MobilePermissionPage.callback = nil
MobilePermissionPage.cancel_callback = nil
local page
function MobilePermissionPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = MobilePermissionPage.OnClose
end

function MobilePermissionPage.OnClose()
   
end

function MobilePermissionPage.ShowPage(callback,cancel_callback)
    local flavor = System.options.isPapaAdventure  and "papahuawei" or "huawei"
    if System.os.GetAndroidFlavor() ~= flavor then
        if callback then
            callback()
        end
        return
    end

    if MobilePermissionPage.GetAllPermissionResult() then
        if callback then
            callback()
        end
        return
    end
    MobilePermissionPage.callback = callback
    MobilePermissionPage.cancel_callback = cancel_callback
    local width = 800
    local height = 480
    local params = {
        url = "script/apps/Aries/Creator/Game/Mobile/MobilePermissionPage.html",
        name = "MobilePermissionPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        click_through=false,
        cancelShowAnimation = true,
        withBgMask=true,
        align = "_ct",
        x = -width/2,
        y = -height/2,
        width = width,
        height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function MobilePermissionPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function MobilePermissionPage.OnAgree()
    MobilePermissionPage.ClosePage()
    if MobilePermissionPage.callback then
        MobilePermissionPage.callback()
        MobilePermissionPage.callback = nil
    end
end

function MobilePermissionPage.OnNoAgree()
    MobilePermissionPage.ClosePage()
    if MobilePermissionPage.cancel_callback  then
        MobilePermissionPage.cancel_callback ()
        MobilePermissionPage.cancel_callback  = nil
    end
end

--[[
    local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
local isPermit = PlatformBridge.GetDevicePermission("android.permission.ACCESS_NETWORK_STATE")
tip("permission auth====="..tostring(isPermit))

]]
function MobilePermissionPage.GetAllPermissionResult()
    local isAllPermit = true
    for k,v in pairs(permissions) do
        local isPermit = PlatformBridge.GetDevicePermission(v)
        if not isPermit then
            isAllPermit = false
            break
        end
    end
    return isAllPermit
end