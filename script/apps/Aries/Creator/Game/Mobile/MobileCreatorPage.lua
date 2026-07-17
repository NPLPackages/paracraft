--[[
    author:{pbb}
    time:2022-11-03 15:53:50
    use lib:
        local MobileCreatorPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileCreatorPage.lua")
        MobileCreatorPage.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/CreatorDesktop.lua");
local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
local MobileCreatorPage = NPL.export()

MobileCreatorPage.tabview_ds = {
    {text=L"建造", name="building", url="script/apps/Aries/Creator/Game/Mobile/MobileBuilderFramePage.html?version=1", enabled=true},
    {text=L"环境", name="env", url="script/apps/Aries/Creator/Game/Mobile/MobileEnvFramePage.html?version=1", enabled=true}, 
}
MobileCreatorPage.tabview_index = 1
MobileCreatorPage.IsExpanded = false
local page
function MobileCreatorPage.OnInit()
    page = document:GetPageCtrl();
end

function MobileCreatorPage.ShowPage(bShow)
    if bShow == nil then
        local isShow = MobileCreatorPage.IsVisible()
        MobileCreatorPage.IsExpanded = not isShow
    else
        MobileCreatorPage.IsExpanded = bShow
    end
    if not MobileCreatorPage.IsExpanded then
        MobileCreatorPage.ClosePage()
        return 
    end
    if CreatorDesktop.IsMovie then
        MobileCreatorPage.tabview_ds = {
            {text=L"环境", name="env", url="script/apps/Aries/Creator/Game/Mobile/MobileEnvFramePage.html?version=1", enabled=true}, 
        }
    else
        MobileCreatorPage.tabview_ds = {
            {text=L"建造", name="building", url="script/apps/Aries/Creator/Game/Mobile/MobileBuilderFramePage.html?version=1", enabled=true},
            {text=L"环境", name="env", url="script/apps/Aries/Creator/Game/Mobile/MobileEnvFramePage.html?version=1", enabled=true}, 
        }
    end
    MobileCreatorPage.tabview_index = 1

    local params = {
        url = "script/apps/Aries/Creator/Game/Mobile/MobileCreatorPage.html",
        name = "MobileCreatorPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        cancelShowAnimation = true,
            align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            DesignResolutionWidth = 1280,
            DesignResolutionHeight = 720,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if(params._page) then
		params._page.OnClose = function()
			if CreatorDesktop.IsMovie then
				CreatorDesktop.IsMovie = false
				CreatorDesktop.IsExpanded = false
                MobileCreatorPage.IsExpanded = false
                if CreatorDesktop.new_page_params then
                    CreatorDesktop.new_page_params.align = "_ctr"
                    CreatorDesktop.new_page_params.x = 0
                end
			end
			
		end
    end
end

function MobileCreatorPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function MobileCreatorPage.GetTab()
    local url = MobileCreatorPage.tabview_ds[MobileCreatorPage.tabview_index].url
	return url
end

function MobileCreatorPage.IsVisible()
    return page and page:IsVisible()
end

function MobileCreatorPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end 