--[[
Title: UserExchangeSkinPage
Author(s): pbb
Date: 2022/9/19
Desc:  
Use Lib:
-------------------------------------------------------
local UserExchangeSkinPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserExchangeSkinPage.lua");
UserExchangeSkinPage.ShowPage();
--]]
local page
local UserExchangeSkinPage = NPL.export()
UserExchangeSkinPage.data = {}
function UserExchangeSkinPage.OnInit()
    page = document:GetPageCtrl();
end

function UserExchangeSkinPage.ShowPage(data)
    UserExchangeSkinPage.data = data
    -- print("=================")
    -- echo(data,true)
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/User/UserExchangeSkinPage.html",
        name = "UserExchangeSkinPage.ShowPage", 
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

