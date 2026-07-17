--[[
Title: MallMainPage
Author(s):  pbb
CreateDate: 2023.12.6
Desc:
Use Lib:
-------------------------------------------------------
local MallMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallMainPage.lua");
MallMainPage.ShowPage();
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPageV2.lua");
local MallOtherPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallOtherPage.lua");
local MallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallPage.lua");

local MallMainPage = NPL.export();


MallMainPage.select_tab_index = 1;
MallMainPage.tabValues = {
    {index = 1, name = L"全部"},
    {index = 2, name = L"收藏"},
    {index = 3, name = L"历史"},
    {index = 4, name = L"个人"},
}
MallMainPage.bFromCodeBlock = false
local page

function MallMainPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = function()
        KeepWorkMallPage.isOpen = false
    end
end

function MallMainPage.ShowPage(bFromCodeBlock)
    if (GameLogic.GetFilters():apply_filters('is_signed_in')) then
        MallMainPage.Show(bFromCodeBlock);
        return;
    end

    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if (result == true) then
            commonlib.TimerManager.SetTimeout(function()
                MallMainPage.Show(bFromCodeBlock);
            end, 500)
        end
    end)
end

function MallMainPage.Show(bFromCodeBlock)
    MallMainPage.bFromCodeBlock = (bFromCodeBlock == true)
    MallMainPage.select_tab_index = 1
    MallMainPage.CloseOthers()
    MallManager.getInstance():LoadMallSearchHistory()
    MallManager.getInstance():LoadMallHistory()
    MallManager.getInstance():LoadMallColletIdList(function(data)
        MallMainPage.OpenView()
    end)
end

function MallMainPage.CloseOthers()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
    local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
    DesktopMenuPage.ActivateMenu(false);
    DesktopMenuPage.ShowPage(false);
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EscFramePage.lua");
    local EscFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EscFramePage");
    EscFramePage.ShowPage(false)
end

function MallMainPage.OpenView()
    KeepWorkMallPage.isOpen = true
    local params = {
        url = "script/apps/Aries/Creator/Game/KeepWorkMall/MallMainPage.html",
        name = "MallMainPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        directPosition = true,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
        cancelShowAnimation = true,
        isTopLevel = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
    };

    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function MallMainPage.CloseView()
    if page then
        page:CloseWindow();
        page = nil
    end
    MallPage.IsInited = false
    MallOtherPage.type = ""
    MallMainPage.bFromCodeBlock = false
    MallManager.getInstance():SaveMallSearchHistory()
    MallManager.getInstance():SaveMallHistory()

end

local posX = {2,106,208,316}

function MallMainPage.OnChangeMenu(index)
    local index = tonumber(index)
    if index and index > 0 and index <=4 and MallMainPage.select_tab_index ~= index then
        MallMainPage.select_tab_index = index
        MallOtherPage.type = ""
        MallMainPage.ClearSearch()
        MallMainPage.OnRefreshPage()
        if index == 1 then
            MallPage.OnChangeMenu(1)
        else
            MallMainPage.bFromCodeBlock = false
        end
    end
end

function MallMainPage.OnRefreshPage()
    if page then
        page:Refresh(0);
        local index = MallMainPage.select_tab_index
        local tabSelectNode = ParaUI.GetUIObject("tab_selecte_ctrl")
        if tabSelectNode:IsValid() then
            tabSelectNode.x = posX[index] + 208
        end
    end
end

function MallMainPage.ClearSearch()
    MallOtherPage.SearchText = ""
    MallPage.ClearSearch()
end



