--[[
Title: InstanllGuide
Author(s): yangguiyi
Date: 2021/11/1
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldShare/InstanllGuide.lua").Show();
--]]
local InstanllGuide = NPL.export();
local page

function InstanllGuide.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = InstanllGuide.CloseView
end

function InstanllGuide.Show(projectId)
    InstanllGuide.ShowView()
end

function InstanllGuide.ShowView()
    if page and page:IsVisible() then
        return
    end
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/WorldShare/InstanllGuide.html",
        name = "InstanllGuide.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 10,
        directPosition = true,
        
        align = "_ct",
        x = -516/2,
        y = -357/2,
        width = 516,
        height = 357,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function InstanllGuide.FreshView()
    local parent  = page:GetParentUIObject()
end

function InstanllGuide.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function InstanllGuide.CloseView()
end