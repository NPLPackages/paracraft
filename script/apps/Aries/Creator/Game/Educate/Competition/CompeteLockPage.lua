--[[
    uselib:
        local CompeteLockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompeteLockPage.lua")
        CompeteLockPage.ShowPage()
]]

local CompeteLockPage = NPL.export()
local page
function CompeteLockPage.OnInit()
    page = document:GetPageCtrl()
end

function CompeteLockPage.ShowPage()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Competition/CompeteLockPage.html",
        name = "CompeteLockPage.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = -30,
        click_through = false,
        directPosition = true,
        cancelShowAnimation = true,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        align = "_fi",
            width = view_width,
            height = view_height,
            x = -view_width/2,
            y = -view_height/2,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CompeteLockPage.ClosePage()
    if page then
        page:CloseWindow()
    end
    page = nil
end
