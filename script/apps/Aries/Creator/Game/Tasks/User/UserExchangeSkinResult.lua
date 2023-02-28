--[[
Title: UserExchangeSkinResult
Author(s): pbb
Date: 2022/9/19
Desc:  
Use Lib:
-------------------------------------------------------
local UserExchangeSkinResult = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserExchangeSkinResult.lua");
UserExchangeSkinResult.ShowPage();
UserExchangeSkinResult.ShowFailPage()
--]]
local page
local UserExchangeSkinResult = NPL.export()
UserExchangeSkinResult.name = ""
function UserExchangeSkinResult.OnInit()
    page = document:GetPageCtrl();
end

function UserExchangeSkinResult.ShowPage(name)
    UserExchangeSkinResult.name = name
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/User/UserExchangeSkinSuccess.html",
        name = "UserExchangeSkinResult.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        -- DesignResolutionWidth = 1280,
		-- DesignResolutionHeight = 720,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function UserExchangeSkinResult.ShowFailPage()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/User/UserExchangeSkinFail.html",
        name = "UserExchangeSkinResult.ShowFailPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        -- DesignResolutionWidth = 1280,
		-- DesignResolutionHeight = 720,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end


