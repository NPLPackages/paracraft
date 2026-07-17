--[[
    author:{pbb}
    time:2023-02-09 17:50:48
    uselib:
        local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
        EducateProject.ShowCreate()
        EducateProject.ShowPage()
]]
local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
local KeepworkServicePermission = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Permission.lua')
local EducateProject = NPL.export()
local page,page_root
function EducateProject.OnInit()
    page = document:GetPageCtrl()
    if page then
        EducateProject.ShowCreate()
    end

end

function EducateProject.ShowCreate()
    if Opus and type(Opus.ShowCreate) == "function" then
        local width = 1132
        local height = 470
        local x = -510
        local y = -220
        Opus:ShowCreate(nil,width,height,x,y,true,-1)
    end
    EducateProject.GetUserWorldUsedSize()
end

function EducateProject.CheckOnlineDiskSize(callback)
    EducateProject.GetUserOnlineDiskSize(callback)
end

function EducateProject.CloseCreate(bDestroy)
    Opus:CloseOpus()
    EducateProject.CloseMenu(bDestroy)
end

function EducateProject.GetUserOnlineDiskSize(callback)
    keepwork.world.gettotalsize({},function(err,msg,data)
        if err == 200 and data then
            if System.options.isDevMode then
                print("err=========",err)
                echo(data,true)
            end
            local gbSize = 1024*1024*1024 --1GB
            local totalSize = tonumber(data.total) or 0 --总容量
            local surplus = tonumber(data.surplus) or 0 --剩余容量
            surplus = math.max(surplus,0)
            local use = tonumber(data.use) or 0 --使用容量
            if callback and type(callback) == "function" then
                callback(surplus)
            end
        else
            if err == 401 then
                GameLogic.AddBBS(nil,"用户登录态失效，请重新登录")
                GameLogic.GetFilters():apply_filters("EducateLogout", nil ,function()
                    EducateProject.GetUserOnlineDiskSize(callback)
                end)
                return
            end
            if callback and type(callback) == "function" then
                callback(0)
            end
            GameLogic.AddBBS(nil,"获取用户空间信息失败"..(err or 0))
        end
    end)
end

function EducateProject.GetUserWorldUsedSize()
    print("GetUserWorldUsedSize=====================")
    keepwork.world.gettotalsize({},function(err,msg,data)
        if err == 200 and data then
            if System.options.isDevMode then
                print("err=========",err)
                echo(data,true)
            end
            local gbSize = 1024*1024*1024 --1GB
            local totalSize = tonumber(data.total) or 0 --总容量
            local surplus = tonumber(data.surplus) or 0 --剩余容量
            surplus = math.max(surplus,0)
            local use = tonumber(data.use) or 0 --使用容量
            EducateProject.surplus = surplus
            if surplus then
                local objText = ParaUI.GetUIObject("project_memui")
                if objText:IsValid() then
                    if surplus >= 0 and surplus < gbSize then
                        objText.text = "剩余存档空间："..(math.floor((surplus/1024/1024)*10)/10).."MB"
                    else
                        objText.text = "剩余存档空间："..(math.floor((surplus/gbSize)*10)/10).."GB"
                    end
                end
            end
        else
            if err == 401 then
                GameLogic.AddBBS(nil,"用户登录态失效，请重新登录")
                GameLogic.GetFilters():apply_filters("EducateLogout", nil ,function()
                    EducateProject.GetUserWorldUsedSize()
                    EducateProject.RefreshPage()
                end)
                return
            end
            local EducateMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/EducateMainPage.lua")
            EducateMainPage.LoginOutByErrToken(err)
        end
    end)
end

function EducateProject.SyncLocalWorld(worldPath)
    if not worldPath or worldPath == "" then
        return
    end
    local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
    local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
    local ShareWorld = NPL.load('(gl)script/apps/Aries/Creator/Game/Educate/Other/ShareWorld.lua')
    local userPath = LocalServiceWorld:GetUserFolderPath()
    local worldName = worldPath:gsub(userPath,""):gsub("/","")
    local currentWorld = LocalServiceWorld:SetWorldInstanceByFoldername(worldName)
    if currentWorld then
        Mod.WorldShare.Store:Set('world/currentEnterWorld', currentWorld)
        ShareWorld:SyncWorld(function(bSuccess)
            if bSuccess then
                GameLogic.AddBBS(nil,L"保存世界成功")
            else
                GameLogic.AddBBS(nil,L"保存世界失败")
            end
            EducateProject.RefreshPage()
        end)
        return
    end
    GameLogic.AddBBS(nil,L"保存世界失败")
end

function EducateProject.RefreshPage()
    if page then
        EducateProject.CloseCreate()
        page:Refresh(0.1)
    end
end

function EducateProject.ShowOptionMenu()
    EducateProject.bIsShowMenu = not EducateProject.bIsShowMenu
    local menuName = Mod.WorldShare.Utils.IsEnglish() and "option_menu_pos_english" or "option_menu_pos"
    local nodeMenuPos = ParaUI.GetUIObject(menuName);
    if not nodeMenuPos or not nodeMenuPos:IsValid() then
        print("界面异常")
        return 
    end
    local isWindowSystem = System.os.IsWindow()
    if not EducateProject.nodeContainer or not EducateProject.nodeContainer:IsValid() then
        local x,y,width,height = nodeMenuPos:GetAbsPosition()
        local bg_height = 90
        if not isWindowSystem then
            bg_height = 50
        end
        local __this = ParaUI.CreateUIObject("container","edu_project_menu", "_lt",x + 18,y + 34,150,bg_height);
        __this.zorder = 100
        __this.background = "Texture/Aries/Creator/paracraft/Educate/Project/operatebg_32bits.png;0 0 32 32:14 14 14 14"
        __this:AttachToRoot();
        EducateProject.nodeContainer = __this

        if isWindowSystem then
            local btnNode=ParaUI.CreateUIObject("button","p3d_button", "_lt",10,10,120,30);
            btnNode.text="导入p3d文件";
            btnNode.background="Texture/Aries/Creator/paracraft/Educate/Project/button_32bits.png;0 0 32 32:14 14 14 14";
            btnNode:SetScript("onclick",function()
                EducateProject.CloseMenu()
                commonlib.TimerManager.SetTimeout(function()  
                    KeepworkServicePermission:Authentication('LimitP3dFile', function(result)
                        if result then
                            GameLogic.RunCommand("/menu file.importp3dfile")
                        else
                            _guihelper.MessageBox(L'导入P3D文件解锁请联系客服', nil, _guihelper.MessageBoxButtons.OK)
                        end
                    end)
                end, 200);
                
            end)
            __this:AddChild(btnNode)
        end
        
        local startX,startY = 10,50
        if not isWindowSystem then
            startX,startY = 10,10
        end
        btnNode=ParaUI.CreateUIObject("button","project_button", "_lt",startX,startY,120,30);
        btnNode.text="激活更多存档";
        btnNode.background="Texture/Aries/Creator/paracraft/Educate/Project/button_32bits.png;0 0 32 32:14 14 14 14";
        btnNode:SetScript("onclick",function()
            local ProjectActivationList = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ProjectActivationList.lua")
            EducateProject.CloseMenu()
            ProjectActivationList.ShowPage()
        end)
        __this:AddChild(btnNode)
        
    end
    EducateProject.nodeContainer.visible = EducateProject.bIsShowMenu
end

function EducateProject.CloseMenu(bDestroy)
    if not EducateProject.nodeContainer or not EducateProject.nodeContainer:IsValid() then
        return 
    end
    EducateProject.bIsShowMenu = false
    EducateProject.nodeContainer.visible = EducateProject.bIsShowMenu
    if bDestroy then
        ParaUI.Destroy("edu_project_menu");
    end
end

function EducateProject.RefreshMenu()
    if not EducateProject.nodeContainer or not EducateProject.nodeContainer:IsValid() then
        return 
    end
    local menuName = Mod.WorldShare.Utils.IsEnglish() and "option_menu_pos_english" or "option_menu_pos"
    local nodeMenuPos = ParaUI.GetUIObject(menuName);
    if not nodeMenuPos or not nodeMenuPos:IsValid() then
        return 
    end
    local x,y,width,height = nodeMenuPos:GetAbsPosition()
    EducateProject.nodeContainer.x = x + 18
    EducateProject.nodeContainer.y = y + 34
end

function EducateProject.OnClickSearch()
    if not page then
        return
    end
    local searchText = page:GetValue("project_search_content")
    if not searchText or searchText == "" then
        local preSearchText = Mod.WorldShare.Store:Get('world/searchText')
        if preSearchText and preSearchText ~= "" then
            Mod.WorldShare.Store:Remove('world/searchText')
        else
            GameLogic.AddBBS(nil,L"请输入搜索内容")
            return
        end
    end
    Mod.WorldShare.Store:Set('world/searchText', searchText)
    EducateProject.RefreshProjectList()
end

function EducateProject.ClearSearch()
    if not page then
        return
    end
    page:SetValue("project_search_content", "")
    Mod.WorldShare.Store:Remove('world/searchText')
    EducateProject.RefreshProjectList()
end

function EducateProject.RefreshProjectList()
    local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
    Create:GetWorldList(Create.statusFilter)
end

