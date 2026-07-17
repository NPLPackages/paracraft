--[[
    @author pbb
    @date 2024/07/11
    @description This is the script for the Community Offline page.
    @uselib:
        local CommunityOfflinePage =NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Offline/CommunityOfflinePage.lua")
        CommunityOfflinePage.ShowPage()
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")

local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua");

local CommunityOfflinePage = NPL.export()

CommunityOfflinePage.currentWorldList = {}
CommunityOfflinePage.pageList = {}
CommunityOfflinePage.curPage = 1
CommunityOfflinePage.perPage = 12
CommunityOfflinePage.select_project_index = 1
CommunityOfflinePage.statusFilter = nil
CommunityOfflinePage.is_modify_world_name = false
local m_bIsNotInWorld = false
local self = CommunityOfflinePage
local page
function CommunityOfflinePage.OnInit()
    page = document:GetPageCtrl()
end

function CommunityOfflinePage.InitOffline(bIsNotInWorld)
    if not m_bIsNotInWorld then
        return
    end
    CustomCharItems:Init();
    local Game = commonlib.gettable("MyCompany.Aries.Game")
    if(Game.is_started) then
        Game.Exit()
        Mod.WorldShare.Store:Set('world/isShowExitPage', true)
        Mod.WorldShare.Store:Remove('world/currentWorld')
        Mod.WorldShare.Store:Remove('world/currentEnterWorld')
        Mod.WorldShare.Store:Remove('world/isEnterWorld')
    end
    

    GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)

    local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
    CreateNewWorld.profile = nil
    ParaUI.GetUIObject('root'):RemoveAll()
    NPL.load("(gl)script/ide/TooltipHelper.lua");
    local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
    if(type(BroadcastHelper.Reset) == "function") then
        BroadcastHelper.Reset();
    end
    TipRoadManager:ReCreateRoads()
    CommunityOfflinePage.ClosePage()
    AudioEngine.Init()
end

function CommunityOfflinePage.ShowPage(bIsNotInWorld)
    m_bIsNotInWorld = bIsNotInWorld == true
    CommunityOfflinePage.InitOffline()
    local view_width = 0
	local view_height = 0
	local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/Offline/CommunityOfflinePage.html",
        name = "CommunityOfflinePage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        --app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        isTopLevel = true,
        cancelShowAnimation = true,
        directPosition = true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
    CommunityOfflinePage.SetWindowText()
    self.currentWorldList = {}
    self.pageList = {}
    CommunityOfflinePage.RefreshPage()
    CommunityOfflinePage.GetProjectList()
end

function CommunityOfflinePage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function CommunityOfflinePage.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function CommunityOfflinePage.SetWindowText()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
    local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
    if MainLogin then
        MainLogin:SetWindowTitle()
    end
end

function CommunityOfflinePage.CloseWindow()
    CommunityOfflinePage.ClosePage()
    if m_bIsNotInWorld then
        System.options.cmdline_world = nil
        local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
        CreateNewWorld.profile = nil
        MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
        MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
        MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
        MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
        MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})

        --Map3DSystem.App.Commands.Call("Profile.Aries.Restart", {method="soft"});
        local OfflineAccountManager = NPL.load('(gl)Mod/WorldShare/cellar/OfflineAccount/OfflineAccountManager.lua')
        OfflineAccountManager.ResetOfflineStatus()

        CommunityOfflinePage.SetWindowText()
        m_bIsNotInWorld = false
    end
end

function CommunityOfflinePage.GetPageList()
    if not self.currentWorldList then
        return
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
        local gvw_name = "gw_offline_world_ds";
        local  worldDsNode = page:GetNode(gvw_name);
        if(worldDsNode) then
            worldDsNode:SetAttribute('DataSource', self.pageList or {})
        end
        if page then
            page:Refresh(0.02)
        end
    end
end

function CommunityOfflinePage.GetSelectWorld(index)
    local world_index = tonumber(index)
    if not world_index or world_index < 1 or world_index > #self.pageList then
        return
    end
    return self.pageList[world_index]
end

function CommunityOfflinePage.GetCurWorldInfo(infoType,worldIndex)
    local index = tonumber(worldIndex)
    local selectedWorld = self.GetSelectWorld(index)
    if selectedWorld then
        return selectedWorld[infoType]
    end
end

function CommunityOfflinePage.IsProjectSelected(index)
    return index and index == CommunityOfflinePage.select_project_index
end

function CommunityOfflinePage.GetProjectList(status,callback)
    self.statusFilter = nil
    Create:GetWorldList(self.statusFilter, function(currentWorldList)
        self.currentWorldList = currentWorldList
        
        self.GetPageList()
        if callback and type(callback) == 'function' then
            callback()
        end

    end)
end

function CommunityOfflinePage.OnSwitchWorld(index)
    if not index then
        return
    end
    CommunityOfflinePage.select_project_index = index
    --print("OnSwitchWorld============", index)
    Create:OnSwitchWorld(index)
end

function CommunityOfflinePage.WorldRename(currentItemIndex, tempModifyWorldname, callback)
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


function CommunityOfflinePage.ShowExtraPanel()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld or next(currentWorld) == nil then
        return {}
    end
    local menuStyle = commonlib.copy(CommonCtrl.ContextMenu.DefaultStyle)
    menuStyle.menuitemHeight = 36
    menuStyle.item_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;344 7 32 32:14 14 14 14"
    menuStyle.menu_bg = "Texture/Aries/Creator/keepwork/community_32bits.png;307 8 32 32:14 14 14 14"
    menuStyle.level1itemcolor = "#A8A7B0FF"
	menuStyle.mouseover_textcolor = "#ffffff"
    local ctl = CommunityOfflinePage.contextMenuCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "CommunityOfflinePage.contextMenuCtrl",
			width = Mod.WorldShare.Utils.IsEnglish() and 144 or 114,
			height = 164, 
			onclick = CommunityOfflinePage.OnClickContextMenuItem,
            style = menuStyle,
		};
		CommunityOfflinePage.contextMenuCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
    if node then
        node:ClearAllChildren();
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"打开文件夹" .. "", Name = "folder", Type = "Menuitem", onclick = nil, }))
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"删除世界" .. "", Name = "delete", Type = "Menuitem", onclick = nil, }))
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"修改世界名称" .. "", Name = "edit", Type = "Menuitem", onclick = nil, }))
    end
    ctl:Show(mouse_x, mouse_y);
end

function CommunityOfflinePage.HideExtraPanel()

end

function CommunityOfflinePage.OnClickContextMenuItem(node)
	local name = node.Name
    CommunityOfflinePage.OnClickExtra(name)
end

function CommunityOfflinePage.OnClickExtra(name)
    if not name  or name == '' then
        return
    end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_my_frame.click_project_operate", {name = name,useNoId=true},nil,true);
    local DeleteWorld = NPL.load('(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua')
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld or next(currentWorld) == nil then
        return
    end
    if name == "folder" then
        if System.os.GetPlatform() ~= 'win32' and
            System.os.GetPlatform() ~= 'mac' then
            _guihelper.MessageBox(L'暂不支持当前系统打开文件夹')
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
    elseif name == "delete" then
        CommunityOfflinePage.OnDeleteProject()
    elseif name == "edit" then
        CommunityOfflinePage.is_modify_world_name = true
        CommunityOfflinePage.RefreshPage()
    end
end

function CommunityOfflinePage.OnMouseWheel()
    if not page then
        return
    end
    local worldDS = page:GetNode('gw_offline_world_ds')
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

function CommunityOfflinePage.OnCreateProject()
    local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
    CreateWorld:CreateNewWorld(nil, function()
        CommunityOfflinePage.RefreshPage(0.01)
    end)
end

function CommunityOfflinePage.OnOpenProject(index)
    if not index then
        return
    end
    Create:EnterWorld(index)
end

function CommunityOfflinePage.OnDeleteProject()
    Create:DeleteWorld(CommunityOfflinePage.select_project_index,function()
        CommunityOfflinePage.GetProjectList(self.statusFilter)
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
                btn.background = bg
            end
        end
	end
end

function CommunityOfflinePage.ResetSelectStatus()
    
end



function CommunityOfflinePage.OnMouseEnterImp(index,isBg,isPreview,isMore)
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
    if isMore then
        UpdateCheckBox(index,"more",true)
    end
end

function CommunityOfflinePage.OnMouseLeaveImp(index,isBg,isPreview,isMore)
    if not page or not index then
        return
    end
    
    local project_select_bg = page:FindControl("project_select_bg"..index)
    if project_select_bg then
        local isShow = false
        if isPreview and isMore then
            isShow = true
        end
        project_select_bg.visible = isShow
    end

    local project_bg = page:FindControl("project_bg"..index)
    if project_bg then
        local isShow = true
        if isPreview and isMore then
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
        if isPreview and isMore then
            isShow = true
        end
        project_preview_select1_bg.visible = isShow
    end

    local project_preview_border_select_bg = page:FindControl("project_preview_border_select_bg"..index)
    if project_preview_border_select_bg then
        local isShow = false
        if isPreview and isMore then
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
    UpdateCheckBox(index,"more",false)
end

function CommunityOfflinePage.OnBgMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,true)
end

function CommunityOfflinePage.OnBgMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,true)
end

function CommunityOfflinePage.OnPreviewMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,true)
end

function CommunityOfflinePage.OnPreviewMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,true)
end

function CommunityOfflinePage.OnMoreMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,true)
end

function CommunityOfflinePage.OnMoreMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,true)
end