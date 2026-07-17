--[[
    author:{pbb}
    time:2024-05-06 17:50:48
    uselib:
        local MyProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/MyProjectList.lua")
]]
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local MyProjectList = NPL.export()

local self = MyProjectList

MyProjectList.select_tab = -1
MyProjectList.sort_index = -1
MyProjectList.sort_order = -1
MyProjectList.currentWorldList = {}
MyProjectList.pageList = {}
MyProjectList.curPage = 1
MyProjectList.perPage = 12
MyProjectList.select_project_index = 1
MyProjectList.statusFilter = nil
MyProjectList.is_modify_world_name = false

local menu_data_sources = {
    {name="all", status="all",value=L"全部存档" },
    {name="online",  status="ONLINE",value=L"在线存档" },
    {name="local" , status="LOCAL",value=L"本地存档" },
    {name="recycle" , status="RECYCLE",value=L"回收站" },
}

local sort_data = {
    {name=L"创建时间", value="createTime"},
    {name=L"编辑时间", value="editTime"},
}

local page
local isFromAIGC = false

function MyProjectList.OnInit(bFromAIGC)
    --TODO: init
    isFromAIGC = bFromAIGC
    page = document:GetPageCtrl()
    if page then
        if MyProjectList.select_tab == -1 then
            MyProjectList.ChangeMenuTab(1)
        end
    end
end

function MyProjectList.RefreshPage(time)
    if page then
        page:Refresh(time or 0)
        print("refresh my project page")
    end
end

function MyProjectList.OnClose()
    self.select_tab = -1
    self.sort_index = -1
    self.sort_order = -1
    self.searchText = nil
end

function MyProjectList.GetMenuData()
    return menu_data_sources
end

function MyProjectList.GetCategoryDSIndex()
    return MyProjectList.select_tab
end

function MyProjectList.ClearData()
    MyProjectList.is_modify_world_name = false
    MyProjectList.sort_index = -1
    MyProjectList.sort_order = -1
    MyProjectList.select_project_index = 1
    MyProjectList.curPage = 1
    MyProjectList.perPage = 12
    MyProjectList.statusFilter = nil
end

function MyProjectList.ChangeMenuTab(index)
    if index and index == MyProjectList.select_tab then
        return
    end
    MyProjectList.select_tab = index
    self.currentWorldList = {}
    self.pageList = {}
    MyProjectList.ClearData()
    MyProjectList.RefreshPage()
    
    local status = menu_data_sources[index].status
    MyProjectList.GetProjectList(status)
end

function MyProjectList.GetSortData()
    return sort_data
end

function MyProjectList.GetSortType()
    return MyProjectList.sort_order
end

function MyProjectList.IsSortSelected(index)
    return index == MyProjectList.sort_index
end

function MyProjectList.OnSortProject(index)
    if not index then
        return
    end
    if index == MyProjectList.sort_index then
        if MyProjectList.sort_order == 0 then
            MyProjectList.sort_order = 1
        else
            MyProjectList.sort_order = 0
        end
    else
        MyProjectList.sort_index = index
        MyProjectList.sort_order = 0
    end
    MyProjectList.is_modify_world_name = false
    MyProjectList.select_project_index = 1
    MyProjectList.RefreshPage()
    MyProjectList.GetPageList()
end



function MyProjectList.GetPageList()
    if not self.currentWorldList then
        return
    end

    --排序
    if MyProjectList.sort_index > 0 then
        local sortKey = sort_data[MyProjectList.sort_index].value
        local sortOrder = MyProjectList.sort_order == 0 and "DESC" or "ASC"
        local worldList = Mod.WorldShare.Store:Get('world/compareWorldList') or {}
        table.sort(worldList, function(a, b)
            if sortKey == "createTime" then
                if not a or not b or not a.createTime or not b.createTime then
                    return false
                end
                if sortOrder == "DESC" then
                    return a.createTime > b.createTime
                end
                if sortOrder == "ASC" then
                    return a.createTime < b.createTime
                end
            elseif sortKey == "editTime" then
                if not a or not b or not a.modifyTime or not b.modifyTime then
                    return false
                end
                if sortOrder == "DESC" then
                    return a.modifyTime > b.modifyTime
                end
                if sortOrder == "ASC" then
                    return a.modifyTime < b.modifyTime
                end
            end
        end)
        self.currentWorldList = worldList
        Mod.WorldShare.Store:Set('world/compareWorldList', self.currentWorldList)
    end

    local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
    if page then
        local pageData = {}
        local itemCount = self.curPage * self.perPage
        for key, item in ipairs(self.currentWorldList) do
            if key <= itemCount then
                pageData[#pageData + 1] = item
            end
        end
        
        self.pageList = pageData
        local gvw_name = "gw_world_ds";
        local  worldDsNode = page:GetNode(gvw_name);
        if(worldDsNode) then
            worldDsNode:SetAttribute('DataSource', self.pageList or {})
        end
        if page then
            page:Refresh(0.02)
        end
    end
end

function MyProjectList.GetSelectWorld(index)
    local world_index = tonumber(index)
    if not world_index or world_index < 1 or world_index > #self.pageList then
        return
    end
    return self.pageList[world_index]
end

function MyProjectList.GetCurWorldInfo(infoType,worldIndex)
    local index = tonumber(worldIndex)
    local selectedWorld = self.GetSelectWorld(index)
    if selectedWorld then
        return selectedWorld[infoType]
    end
end

function MyProjectList.IsProjectSelected(index)
    return index and index == MyProjectList.select_project_index
end

function MyProjectList.GetWorldListType()
    if MyProjectList.select_tab == 4 then
        return "DELETED"
    end
    return "MINE"
end

function MyProjectList.IsSelectRecycle()
    return MyProjectList.select_tab == 4
end

function MyProjectList.GetProjectList(status,callback)
    if status == "all" then
        statusFilter = nil
    else
        statusFilter = status
    end
    local worldListType = MyProjectList.GetWorldListType()
    self.statusFilter = statusFilter
    Create:SetWorldListType(worldListType)
    Mod.WorldShare.Store:Remove('world/compareWorldList') -- clear compare world list
    Create:GetWorldList(self.statusFilter, function(currentWorldList)
        self.currentWorldList = currentWorldList
        -- print("currentWorldList===========", #self.currentWorldList)
        -- echo(self.currentWorldList,true)
        self.GetPageList()

        if callback and type(callback) == 'function' then
            callback()
        end

    end)
end

function MyProjectList.OnSwitchWorld(index)
    if not index then
        return
    end
    MyProjectList.select_project_index = index
    --print("OnSwitchWorld============", index)
    Create:OnSwitchWorld(index)
end

function MyProjectList.WorldRename(currentItemIndex, tempModifyWorldname, callback)
    if not page then
        return
    end

    local currentWorld = Compare:GetSelectedWorld(currentItemIndex)

    if not currentWorld then
        return
    end

    if currentWorld.is_zip then
        GameLogic.AddBBS(nil, L'暂不支持重命名zip世界', 3000, '255 0 0')
        return
    end

    if not tempModifyWorldname or tempModifyWorldname == '' then
        return
    end

    if currentWorld.status ~= 2 then
        if currentWorld.name == tempModifyWorldname then
            return
        end

        local tag = LocalService:GetTag(currentWorld.worldpath)

        -- update local tag name
        tag.name = tempModifyWorldname
        currentWorld.name = tempModifyWorldname

        LocalService:SetTag(currentWorld.worldpath, tag)
        Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
    end

    if KeepworkServiceSession:IsSignedIn() and
       currentWorld.status and
       currentWorld.status ~= 1 and
       currentWorld.kpProjectId and
       currentWorld.kpProjectId ~= 0 then

        -- update project info
        local tag = LocalService:GetTag(currentWorld.worldpath)

        if currentWorld.status ~= 2 then
            -- update sync world
            -- local world exist

            -- get members for shared world
            KeepworkServiceProject:GetMembers(currentWorld.kpProjectId, function(data)
                local members = {}

                for key, item in ipairs(data) do
                    members[#members + 1] = item.username
                end
                
                currentWorld.members = members

                Mod.WorldShare.Store:Set('world/currentRevision', currentWorld.revision)
                Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)
    
                SyncWorld:SyncToDataSource(function(result, msg)
                    if callback and type(callback) == 'function' then
                        callback()
                    end
                end)
            end)
        elseif currentWorld.status == 2 then
            -- just remote world exist
            KeepworkServiceWorld:GetWorld(
                currentWorld.foldername,
                currentWorld.shared,
                currentWorld.user.id,
                function(data)
                    local extra = data and data.extra or {}

                    extra.worldTagName = tempModifyWorldname

                    -- local world not exist
                    KeepworkServiceProject:UpdateProject(
                        currentWorld.kpProjectId,
                        {
                            extra = extra
                        },
                        function(data, err)
                            if callback and type(callback) == 'function' then
                                callback()
                            end
                        end
                    )
                end
            )
        end
    else
        if callback and type(callback) == 'function' then
            callback()
        end
    end

    return true
end

function MyProjectList.OnShowCategory()
    --menu_bg
    local menuStyle = commonlib.copy(CommonCtrl.ContextMenu.DefaultStyle)
    menuStyle.menuitemHeight = 36
    menuStyle.item_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;344 7 32 32:14 14 14 14"
    menuStyle.menu_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;307 8 32 32:14 14 14 14"
    menuStyle.level1itemcolor = "#A8A7B0FF"
	menuStyle.mouseover_textcolor = "#ffffff"
	menuStyle.textFont = "System;12;bold"
    local ctl = MyProjectList.contextCategoryCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "MyProjectList.contextCategoryCtrl",
			width = Mod.WorldShare.Utils.IsEnglish() and 144 or 114,
			height = 164, 
			onclick = MyProjectList.OnClickCatoryItem,
            style = menuStyle,
		};
		MyProjectList.contextCategoryCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
    if node then
        node:ClearAllChildren();
        for key, item in ipairs(menu_data_sources) do
            local tree_node = CommonCtrl.TreeNode:new({Text = item.value, Name = item.name, Type = "Menuitem", onclick = nil, });
            node:AddChild(tree_node);
        end
    end
    local showX = 160
    local showY = 168
    if isFromAIGC then
        showX = 270
        showY = 156
    end
    ctl:Show(showX, showY);
end

function MyProjectList.OnClickCatoryItem(node)
    local name = node.Name
    local index = 0 
    for key, item in ipairs(menu_data_sources) do
        if item.name == name then
            index = key
            break
        end
    end
    if index == 0 then
        return
    end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_my_frame.click_category", {index = index,useNoId=true},nil,true);
    MyProjectList.ChangeMenuTab(index)
end

function MyProjectList.ShowExtraPanel()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld or next(currentWorld) == nil then
        return {}
    end

    if not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        self.ShowExtraPanelImp()
        return
    end

    Create:CheckWorldArchived(currentWorld.kpProjectId, self.ShowExtraPanelImp)
end

function MyProjectList.ShowExtraPanelImp()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local menuStyle = commonlib.copy(CommonCtrl.ContextMenu.DefaultStyle)
    menuStyle.menuitemHeight = 36
    menuStyle.item_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;344 7 32 32:14 14 14 14"
    menuStyle.menu_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;307 8 32 32:14 14 14 14"
    menuStyle.level1itemcolor = "#A8A7B0FF"
	menuStyle.mouseover_textcolor = "#ffffff"
    local ctl = MyProjectList.contextMenuCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "MyProjectList.contextMenuCtrl",
			width = Mod.WorldShare.Utils.IsEnglish() and 144 or 114,
			height = 164, 
			onclick = MyProjectList.OnClickContextMenuItem,
            style = menuStyle,
		};
		MyProjectList.contextMenuCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
    if node then
        node:ClearAllChildren();
        if self.IsSelectRecycle() then
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"恢复" .. "", Name = "restore", Type = "Menuitem", onclick = nil, }))
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"彻底删除" .. "", Name = "clear", Type = "Menuitem", onclick = nil, }))
        else
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"切换版本" .. "", Name = "revision", Type = "Menuitem", onclick = nil, }))
            node:AddChild(CommonCtrl.TreeNode:new({Text = L"打开文件夹" .. "", Name = "folder", Type = "Menuitem", onclick = nil, }))
            if not isFromAIGC then
                node:AddChild(CommonCtrl.TreeNode:new({Text = L"删除世界" .. "", Name = "delete", Type = "Menuitem", onclick = nil, }))
                node:AddChild(CommonCtrl.TreeNode:new({Text = L"项目主页" .. "", Name = "web", Type = "Menuitem", onclick = nil, }))
                node:AddChild(CommonCtrl.TreeNode:new({Text = L"修改世界名称" .. "", Name = "edit", Type = "Menuitem", onclick = nil, }))
            end
        end
    end
    ctl:Show(mouse_x, mouse_y);
end

function MyProjectList.HideExtraPanel()

end

function MyProjectList.OnClickContextMenuItem(node)
	local name = node.Name
    MyProjectList.OnClickExtra(name)
end

function MyProjectList.OnClickExtra(name)
    if not name  or name == '' then
        return
    end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_my_frame.click_project_operate", {name = name,useNoId=true},nil,true);
    local DeleteWorld = NPL.load('(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua')
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld or next(currentWorld) == nil then
        return
    end
    if name == "web" then
        local kpProjectId = currentWorld.kpProjectId
        if not kpProjectId or kpProjectId == 0 then
            GameLogic.AddBBS(nil, L'请先上传世界')
            return
        end
        local url = format('/pbl/project/%d/', kpProjectId)
        Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
    elseif name == "revision" then
        if currentWorld and currentWorld.status == 1 then
            _guihelper.MessageBox(L'此世界仅在本地，无需切换版本')
            return
        end
        local VersionChange = NPL.load('(gl)Mod/WorldShare/cellar/VersionChange/VersionChange.lua')
        VersionChange:Init(currentWorld.foldername, function()
            MyProjectList.GetProjectList(self.statusFilter)
        end)
    elseif name == "folder" then
        if System.os.GetPlatform() ~= 'win32' and
            System.os.GetPlatform() ~= 'mac' then
            _guihelper.MessageBox(L'暂不支持当前系统打开文件夹')
            return
        end


        if currentWorld and
            type(currentWorld) == 'table' and
            currentWorld.status and
            currentWorld.status == 2 then
            _guihelper.MessageBox(L'请先下载世界')
            return
        end

        local worldpath = currentWorld.worldpath or ''

        Map3DSystem.App.Commands.Call(
            'File.WinExplorer',
            {
                filepath = ParaIO.GetWritablePath() .. worldpath,
                silentmode = true
            }
        )
    elseif name == "exit" then
        local selectedWorld = currentWorld
        _guihelper.MessageBox(
            format(L'确定要退出《%s》项目？<br />(注意：退出后本地数据也会删除！)', selectedWorld.text),
            function(res)
                if res and res == _guihelper.DialogResult.Yes then
                    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

                    if currentWorld.kpProjectId == selectedWorld.kpProjectId then
                        KeepworkServiceProject:LeaveMultiProject(currentWorld.kpProjectId, function(data, err)
                            if err == 200 then
                                if currentWorld.status == 2 then
                                    MyProjectList.GetProjectList(self.statusFilter)
                                else
                                    DeleteWorld:DeleteLocal(function()
                                        MyProjectList.GetProjectList(self.statusFilter)
                                    end, true)
                                end
                            end
                        end)
                    end
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )
    elseif name == "delete" then
        MyProjectList.OnDeleteProject()

    elseif name == "restore" then
        MyProjectList.RestoreWorld(currentWorld)
    elseif name == "clear" then
        MyProjectList.ForceDeletedWorld(currentWorld)
    elseif name == "edit" then
        MyProjectList.is_modify_world_name = true
        MyProjectList.RefreshPage()
    end
end

function MyProjectList.ForceDeletedWorld(currentWorld)
    if not currentWorld or next(currentWorld) == nil then
        return
    end
    keepwork.project.forcedelete({
        router_params = {
                id = currentWorld.kpProjectId,
        }
    },function(err,msg,data)
        if err == 200 then
            GameLogic.AddBBS(nil, L'删除成功')
            
            MyProjectList.GetProjectList(self.statusFilter)
        end
    end)
end

function MyProjectList.RestoreWorld(currentWorld)
    if not currentWorld or next(currentWorld) == nil then
        return
    end
    keepwork.project.update({
        router_params = {
            id = currentWorld.kpProjectId,
        },
        isDeleted=0,
    },function(err,msg,data)
        if err == 200 then
            GameLogic.AddBBS(nil, L'恢复世界成功')
            MyProjectList.GetProjectList(self.statusFilter)
        end
    end)
end

function MyProjectList.OnMouseWheel()
    if not page then
        return
    end
    local worldDS = page:GetNode('gw_world_ds')
    local curLine = 0

    if worldDS then
        if worldDS:GetChild('pe:treeview') and
           worldDS:GetChild('pe:treeview').control then
            local control = worldDS:GetChild('pe:treeview').control

            if control then
                curLine = math.ceil(control.ClientY / 260)
            end
        end
    end
    local lineNum = 4
    local startLine = curLine * lineNum - 2
    local startIndex
    local endIndex

    if (startLine - lineNum) > 0 then
        startIndex = startLine - lineNum
        endIndex = startIndex + 16
    else
        startIndex = startLine > 0 and startLine or 1  
        endIndex = startIndex + 12
    end

    for key, item in ipairs(self.pageList) do
        if item and
           (key < startIndex or key > endIndex) then
            if item.status and tonumber(item.status) == 2 then
                local project = item.project

                if project and
                   type(project) == 'table' and
                   project.extra and
                   type(project.extra) == 'table' and
                   project.extra.imageUrl and
                   type(project.extra.imageUrl) == 'string' and
                   project.extra.imageUrl ~= '' then
                    ParaAsset.LoadTexture('', project.extra.imageUrl, 1):UnloadAsset()
                end
            else
                local worldpath = item.worldpath

                if worldpath and type(worldpath) == 'string' then
                    local preview = worldpath .. 'preview.jpg'
                    ParaAsset.LoadTexture('', preview, 1):UnloadAsset()
                end                        
            end
        end
    end
end

function MyProjectList.SearchProject(searchText)
    MyProjectList.GetProjectList(self.statusFilter)
end

function MyProjectList.OnCreateProject()
    local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
    CreateWorld:CreateNewWorld(nil, function()
        MyProjectList.RefreshPage(0.01)
    end)
end

function MyProjectList.OnOpenProject(index)
    if not index then
        return
    end
    Create:EnterWorld(index)
end

function MyProjectList.OnSyncProject(index)
    if not index then
        return
    end
    MyProjectList.OnSwitchWorld(index)
    Create:Sync(function(result)
        if result then
            MyProjectList.GetProjectList(self.statusFilter)
        end
    end)
end

function MyProjectList.OnDeleteProject()
    Create:DeleteWorld(MyProjectList.select_project_index,function()
        MyProjectList.GetProjectList(self.statusFilter)
    end)
end

-- 更新mouse效果
local base_texture_path = "Texture/Aries/Creator/keepwork/"
local btnBgConfig = {
    sync = {
        bg = base_texture_path .. "community_32bits.png;188 54 20 20",
        bg_hover = base_texture_path .. "community_32bits.png;216 54 20 20",
    },
    share = {
        bg = base_texture_path .. "community_32bits.png;188 99 20 20",
        bg_hover = base_texture_path .. "community_32bits.png;216 99 20 20",
    },
    more = {
        bg = base_texture_path .. "community_32bits.png;266 100 20 20",
        bg_hover = base_texture_path .. "community_32bits.png;242 100 20 20",
    },
}

local function UpdateCheckBox(name,btnName,bChecked)
    local index = tonumber(name)
    if not index then
        return
    end
	if(page) then
        if btnBgConfig[btnName] then
            local uiname = "CreateEmbed."..btnName..index
            local btn = ParaUI.GetUIObject(uiname)
            if btn and btn:IsValid() then
                local bg = bChecked and btnBgConfig[btnName].bg_hover or btnBgConfig[btnName].bg 
                if isFromAIGC then
                    bg = btnBgConfig[btnName].bg_hover
                end
                btn.background = bg
            end
        end
	end
end

function MyProjectList.ResetSelectStatus()
    if true then
        return
    end
    local pageSize = MyProjectList.pageList and #MyProjectList.pageList or 0
    for i = 1, pageSize do
        local project_select_bg = page:FindControl("project_select_bg"..i)
        local project_bg = page:FindControl("project_bg"..i)
        local project_preview_select2_bg = page:FindControl("project_preview_select2_bg"..i)
        local project_preview_select1_bg = page:FindControl("project_preview_select1_bg"..i)
        local project_preview_border_select_bg = page:FindControl("project_preview_border_select_bg"..i)
        local project_preview_border_normal_bg = page:FindControl("project_preview_border_normal_bg"..i)
        if project_select_bg then
            project_select_bg.visible = false
        end
        if project_bg then
            project_bg.visible = true
        end
        if project_preview_select2_bg then
            project_preview_select2_bg.visible = false
        end
        if project_preview_select1_bg then
            project_preview_select1_bg.visible = false
        end
        if project_preview_border_select_bg then
            project_preview_border_select_bg.visible = false
        end
        if project_preview_border_normal_bg then
            project_preview_border_normal_bg.visible = true
        end
        local project_info_bg = page:FindControl("project_info_bg"..i)
        if project_info_bg then
            project_info_bg.visible = true
        end
        UpdateCheckBox(i,"sync",false)
        UpdateCheckBox(i,"share",false)
        UpdateCheckBox(i,"more",false)
    end
end



function MyProjectList.OnMouseEnterImp(index,isBg,isPreview,isSync,isShare,isMore)
    if not page or not index then
        return
    end
    
    local project_select_bg = page:FindControl("project_select_bg"..index)
    if project_select_bg then
        project_select_bg.visible = true
    end

    local project_bg = page:FindControl("project_bg"..index)
    if project_bg then
        project_bg.visible = false
    end

    local project_preview_select2_bg = page:FindControl("project_preview_select2_bg"..index)
    if project_preview_select2_bg then
        local isShow = false
        if isPreview then
            isShow = true
        end
        project_preview_select2_bg.visible = isShow
    end

    local project_preview_select1_bg = page:FindControl("project_preview_select1_bg"..index)
    if project_preview_select1_bg then
        local isShow = true
        if isPreview then
            isShow = false
        end
        project_preview_select1_bg.visible = isShow
    end

    local project_preview_border_select_bg = page:FindControl("project_preview_border_select_bg"..index)
    if project_preview_border_select_bg then
        project_preview_border_select_bg.visible = true
    end

    local project_preview_border_normal_bg = page:FindControl("project_preview_border_normal_bg"..index)
    if project_preview_border_normal_bg then
        project_preview_border_normal_bg.visible = false
    end
    local project_info_bg = page:FindControl("project_info_bg"..index)
    if project_info_bg then
        project_info_bg.visible = false
    end
    if isSync then
        UpdateCheckBox(index,"sync",true)
    end
    if isShare then
        UpdateCheckBox(index,"share",true)
    end
    if isMore then
        UpdateCheckBox(index,"more",true)
    end
end

function MyProjectList.OnMouseLeaveImp(index,isBg,isPreview,isSync,isShare,isMore)
    if not page or not index then
        return
    end
    
    local project_select_bg = page:FindControl("project_select_bg"..index)
    if project_select_bg then
        local isShow = false
        if isPreview and isSync and isShare and isMore then
            isShow = true
        end
        project_select_bg.visible = isShow
    end

    local project_bg = page:FindControl("project_bg"..index)
    if project_bg then
        local isShow = true
        if isPreview and isSync and isShare and isMore then
            isShow = false
        end
        project_bg.visible = isShow
    end

    local project_preview_select2_bg = page:FindControl("project_preview_select2_bg"..index)
    if project_preview_select2_bg then
        project_preview_select2_bg.visible = false
    end

    local project_preview_select1_bg = page:FindControl("project_preview_select1_bg"..index)
    if project_preview_select1_bg then
        local isShow = false
        if isPreview and isSync and isShare and isMore then
            isShow = true
        end
        project_preview_select1_bg.visible = isShow
    end

    local project_preview_border_select_bg = page:FindControl("project_preview_border_select_bg"..index)
    if project_preview_border_select_bg then
        local isShow = false
        if isPreview and isSync and isShare and isMore then
            isShow = true
        end
        project_preview_border_select_bg.visible = isShow
    end

    local project_preview_border_normal_bg = page:FindControl("project_preview_border_normal_bg"..index)
    if project_preview_border_normal_bg then
        local isShow = false
        if isBg then
            isShow = true
        end
        project_preview_border_normal_bg.visible = isShow
    end
    local project_info_bg = page:FindControl("project_info_bg"..index)
    if project_info_bg then
        local isShow = false
        if isBg then
            isShow = true
        end
        project_info_bg.visible = isShow
    end
    UpdateCheckBox(index,"sync",false)
    UpdateCheckBox(index,"share",false)
    UpdateCheckBox(index,"more",false)
end

function MyProjectList.OnBgMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,true)
end

function MyProjectList.OnBgMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,true)
end

function MyProjectList.OnPreviewMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,true)
end

function MyProjectList.OnPreviewMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,true)
end

function MyProjectList.OnSyncMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,true)
end

function MyProjectList.OnSyncMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,true)
end

function MyProjectList.OnShareMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,false,true)
end

function MyProjectList.OnShareMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,false,true)
end

function MyProjectList.OnMoreMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,false,false,true)
end

function MyProjectList.OnMoreMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,false,false,true)
end


