--[[
    author:{pbb}
    time:2024-05-06 17:50:48
    uselib:
        local ProjectMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/ProjectMainPage.lua")
        ProjectMainPage.ShowPage()
]]
local MyProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/MyProjectList.lua")
local ShareProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/ShareProjectList.lua")
local CollectProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/CollectProjectList.lua")
local HistoryProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/HistoryProjectList.lua")
local menu_data_sources = {
    {name="my_project",value=L"我的项目",iframe="script/apps/Aries/Creator/Game/Tasks/Community/Project/MyProjectList.html"},
    {name="share_project",value=L"协作项目",iframe="script/apps/Aries/Creator/Game/Tasks/Community/Project/ShareProjectList.html"},
    {name="collect_project",value=L"收藏项目", iframe="script/apps/Aries/Creator/Game/Tasks/Community/Project/CollectProjectList.html"},
    {name="history_project",value=L"加载记录", iframe="script/apps/Aries/Creator/Game/Tasks/Community/Project/HistoryProjectList.html"},
}


local ProjectMainPage = NPL.export()
ProjectMainPage.IsLoaded = false
local page

function ProjectMainPage.OnInit()
    page = document:GetPageCtrl()
    if page then
        if not ProjectMainPage.IsLoaded then
            Mod.WorldShare.Store:Remove('world/searchText')
            ProjectMainPage.select_tab = 1
            ProjectMainPage.IsLoaded = true
        end
    end
end

function ProjectMainPage.ShowPage()
    ProjectMainPage.select_tab = 1
    local view_width, view_height = 1090,640
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/Project/ProjectMainPage.html",
        name = "ProjectMainPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        cancelShowAnimation = true,
        directPosition = true,
            align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ProjectMainPage.GetCategoryDSIndex()
    return ProjectMainPage.select_tab
end

function ProjectMainPage.GetMenuData()
    return menu_data_sources
end

function ProjectMainPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function ProjectMainPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function ProjectMainPage.ChangeMenuTab(index)
    if ProjectMainPage.select_tab ~= index then
        ProjectMainPage.select_tab = index
        MyProjectList.OnClose()
        Mod.WorldShare.Store:Remove('world/searchText')
        page:SetValue("search_content", "")
        ProjectMainPage.RefreshPage()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_main.click_menu", {useNoId=true},nil,true);
    end
end

function ProjectMainPage.ClearFrameData()
    ProjectMainPage.IsLoaded = false
    Mod.WorldShare.Store:Remove('world/searchText')
    MyProjectList.OnClose()
end

function ProjectMainPage.ChangeSearch()
    if not page then
        return
    end
    local searchPanel = ParaUI.GetUIObject("search_container")
    local normalPanel = ParaUI.GetUIObject("no_search_container")
    if searchPanel and searchPanel:IsValid() and normalPanel and normalPanel:IsValid() then
        searchPanel.visible = true
        normalPanel.visible = false
    end
end

function ProjectMainPage.ClearSearch()
    if not page then
        return
    end
    page:SetValue("search_content", "")
    local preSearchText = Mod.WorldShare.Store:Get('world/searchText')
    if preSearchText and preSearchText ~= "" then
        Mod.WorldShare.Store:Remove('world/searchText')
    end
    local searchText = page:GetValue("search_content")
    --搜索我的项目
    if ProjectMainPage.select_tab == 1 then
        MyProjectList.SearchProject(searchText)
    end
    --搜索协作项目
    if ProjectMainPage.select_tab == 2 then
        ShareProjectList.SearchProject(searchText)
    end
end

function ProjectMainPage.CloseSearch()
    if not page then
        return
    end
    local searchPanel = ParaUI.GetUIObject("search_container")
    local normalPanel = ParaUI.GetUIObject("no_search_container")
    if searchPanel and searchPanel:IsValid() and normalPanel and normalPanel:IsValid() then
        searchPanel.visible = false
        normalPanel.visible = true
    end
    page:SetValue("search_content", "")
    local preSearchText = Mod.WorldShare.Store:Get('world/searchText')
    if preSearchText and preSearchText ~= "" then
        Mod.WorldShare.Store:Remove('world/searchText')
    end
    local searchText = page:GetValue("search_content")
    --搜索我的项目
    if ProjectMainPage.select_tab == 1 then
        MyProjectList.SearchProject(searchText)
    end
    --搜索协作项目
    if ProjectMainPage.select_tab == 2 then
        ShareProjectList.SearchProject(searchText)
    end
end

function ProjectMainPage.OnSearchInputFocusOut()
    if not page then
        return
    end
    local searchPanel = ParaUI.GetUIObject("search_container")
    local normalPanel = ParaUI.GetUIObject("no_search_container")
    if searchPanel and searchPanel:IsValid() and normalPanel and normalPanel:IsValid() then
        searchPanel.visible = false
        normalPanel.visible = true
    end
end

function ProjectMainPage.OnClickSearch()
    if not page then
        return
    end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_main.click_search", {useNoId=true},nil,true);
    local searchText = page:GetValue("search_content")
    if not searchText or searchText == "" then
        local preSearchText = Mod.WorldShare.Store:Get('world/searchText')
        if preSearchText and preSearchText ~= "" then
            Mod.WorldShare.Store:Remove('world/searchText')
        else
            GameLogic.AddBBS(nil,L"请输入搜索内容")
            return
        end
    end
    if ProjectMainPage.select_tab == 1 or ProjectMainPage.select_tab == 2 then
        Mod.WorldShare.Store:Set('world/searchText', searchText)
    end
    --搜索我的项目
    if ProjectMainPage.select_tab == 1 then
        MyProjectList.SearchProject(searchText)
    end
    --搜索协作项目
    if ProjectMainPage.select_tab == 2 then
        ShareProjectList.SearchProject(searchText)
    end
    --搜索搜藏列表
    if ProjectMainPage.select_tab == 3 then
        CollectProjectList.SearchProject(searchText)
    end
    -- 搜索历史记录
    if ProjectMainPage.select_tab == 4 then
        HistoryProjectList.SearchProject(searchText)
    end
end

function ProjectMainPage.GetIframeUrl()
    if not page then
        return ""
    end
    return menu_data_sources[ProjectMainPage.select_tab].iframe
end

function ProjectMainPage.OnClickCreate()
    MyProjectList.OnCreateProject()
end

