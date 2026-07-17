--[[
    author:{pbb}
    time:2024-05-06 17:50:48
    uselib:
        local ShareProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/ShareProjectList.lua")
]]
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local ShareProjectList = NPL.export()

local self = ShareProjectList

ShareProjectList.currentWorldList = {}
ShareProjectList.pageList = {}
ShareProjectList.curPage = 1
ShareProjectList.perPage = 12
ShareProjectList.select_project_index = 1
ShareProjectList.statusFilter = nil
ShareProjectList.is_modify_world_name = false

local page
function ShareProjectList.OnInit()
    --TODO: init
    page = document:GetPageCtrl()
    if page then
        ShareProjectList.GetProjectList()
    end
end

function ShareProjectList.RefreshPage(time)
    if page then
        page:Refresh(time or 0)
        print("refresh share project page")
    end
end

function ShareProjectList.OnClose()
    ShareProjectList.ClearData()
end

function ShareProjectList.ClearData()
    ShareProjectList.is_modify_world_name = false
    ShareProjectList.select_project_index = 1
    ShareProjectList.curPage = 1
    ShareProjectList.perPage = 12
    ShareProjectList.statusFilter = nil
end


function ShareProjectList.GetPageList()
    if not self.currentWorldList then
        return
    end
    local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
    if page then
        self.pageList = {}
        local itemCount = self.curPage * self.perPage

        for key, item in ipairs(self.currentWorldList) do
            if key <= itemCount then
                self.pageList[#self.pageList + 1] = item
            end
        end

        local gvw_name = "gw_share_world_ds";
        local  worldDsNode = page:GetNode(gvw_name);
        if(worldDsNode) then
            --worldDsNode:SetAttribute('DataSource', self.pageList or {})
            pe_gridview.DataBind(worldDsNode, gvw_name, false);
        end
    end
end

function ShareProjectList.GetSelectWorld(index)
    local world_index = tonumber(index)
    if not world_index or world_index < 1 or world_index > #self.pageList then
        return
    end
    return self.pageList[world_index]
end

function ShareProjectList.GetCurWorldInfo(infoType,worldIndex)
    local index = tonumber(worldIndex)
    local selectedWorld = self.GetSelectWorld(index)

    if selectedWorld then
        return selectedWorld[infoType]
    end
end


function ShareProjectList.IsProjectSelected(index)
    return index and index == ShareProjectList.select_project_index
end

function ShareProjectList.GetProjectList(statusFilter,callback)
    self.statusFilter = nil
    Create:SetWorldListType("SHARED")
    Mod.WorldShare.Store:Remove('world/compareWorldList') -- clear compare world list
    Create:GetWorldList(self.statusFilter, function(currentWorldList)
        self.currentWorldList = currentWorldList
        print("currentWorldList===========", #self.currentWorldList)
        -- echo(self.currentWorldList,true)
        self.GetPageList()

        if callback and type(callback) == 'function' then
            callback()
        end

    end)
end

function ShareProjectList.OnSwitchWorld(index)
    if not index then
        return
    end
    ShareProjectList.select_project_index = index
    print("OnSwitchWorld============", index)
    Create:OnSwitchWorld(index)
end

function ShareProjectList.WorldRename(currentItemIndex, tempModifyWorldname, callback)
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

function ShareProjectList.ShowExtraPanel()
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
    local ctl = ShareProjectList.contextMenuCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "ShareProjectList.contextMenuCtrl",
            width = Mod.WorldShare.Utils.IsEnglish() and 144 or 114,
			height = 164, 
            style = menuStyle,
			onclick = ShareProjectList.OnClickContextMenuItem,
		};
		ShareProjectList.contextMenuCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
    if node then
        node:ClearAllChildren();
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"项目主页" .. "", Name = "web", Type = "Menuitem", onclick = nil, }))
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"切换版本" .. "", Name = "revision", Type = "Menuitem", onclick = nil, }))
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"打开文件夹" .. "", Name = "folder", Type = "Menuitem", onclick = nil, }))
        node:AddChild(CommonCtrl.TreeNode:new({Text = L"退出世界" .. "", Name = "exit", Type = "Menuitem", onclick = nil, }))
    end
    ctl:Show(mouse_x, mouse_y);
end

function ShareProjectList.OnClickContextMenuItem(node)
	local name = node.Name
    ShareProjectList.OnClickExtra(name)
end

function ShareProjectList.OnClickExtra(name)
    if not name  or name == '' then
        return
    end
    local DeleteWorld = NPL.load('(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua')
    print("OnClickExtra====================", name)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    if not currentWorld or next(currentWorld) == nil then
        return
    end
    if name == "web" then
        local kpProjectId = currentWorld.kpProjectId
        if not kpProjectId or kpProjectId == 0 then
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
            ShareProjectList.GetProjectList(self.statusFilter)
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
                                    ShareProjectList.GetProjectList(self.statusFilter)
                                else
                                    DeleteWorld:DeleteLocal(function()
                                        ShareProjectList.GetProjectList(self.statusFilter)
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
        ShareProjectList.OnDeleteProject()
    end
end

function ShareProjectList.OnMouseWheel()

end

function ShareProjectList.SearchProject(searchText)
    self.GetProjectList(self.statusFilter, function()
        
    end)
end

function ShareProjectList.OnOpenProject(index)
    if not index then
        return
    end
    Create:EnterWorld(index)
end

function ShareProjectList.OnSyncProject(index)
    if not index then
        return
    end
    Create:Sync(index)
end

function ShareProjectList.OnDeleteProject()
    Create:DeleteWorld(ShareProjectList.select_project_index,function()
        ShareProjectList.GetProjectList(self.statusFilter)
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

function ShareProjectList.ResetSelectStatus()
    if true then
        return
    end
    local pageSize = ShareProjectList.pageList and #ShareProjectList.pageList or 0
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



function ShareProjectList.OnMouseEnterImp(index,isBg,isPreview,isSync,isShare,isMore)
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

function ShareProjectList.OnMouseLeaveImp(index,isBg,isPreview,isSync,isShare,isMore)
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

function ShareProjectList.OnBgMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,true)
end

function ShareProjectList.OnBgMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,true)
end

function ShareProjectList.OnPreviewMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,true)
end

function ShareProjectList.OnPreviewMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,true)
end

function ShareProjectList.OnSyncMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,true)
end

function ShareProjectList.OnSyncMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,true)
end

function ShareProjectList.OnShareMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,false,true)
end

function ShareProjectList.OnShareMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,false,true)
end

function ShareProjectList.OnMoreMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,false,false,true)
end

function ShareProjectList.OnMoreMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,false,false,true)
end
