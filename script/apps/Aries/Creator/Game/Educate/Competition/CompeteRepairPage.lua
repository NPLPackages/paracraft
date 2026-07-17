--[[
Title: CompeteRepairPage
Author(s): pbb
Date: 2024/05/20
Desc:  
Use Lib:
-------------------------------------------------------
local CompeteRepairPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompeteRepairPage.lua")
CompeteRepairPage.ShowPage();
--]]

local CompeteRepairPage = NPL.export();

local page
function CompeteRepairPage.OnInit()
    page = document:GetPageCtrl();
end

function CompeteRepairPage.ShowPage()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Competition/CompeteRepairPage.html",
        name = "CompeteRepairPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        cancelShowAnimation = true,
        zorder = 1000,
        directPosition = true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
        isTopLevel = true,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end


function CompeteRepairPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function CompeteRepairPage.CloseView()
    if page then
        page:CloseWindow()
        page = nil
    end
end
