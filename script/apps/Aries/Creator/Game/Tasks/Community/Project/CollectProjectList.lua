--[[
    author:{pbb}
    time:2024-05-06 17:50:48
    uselib:
        local CollectProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/CollectProjectList.lua")
]]
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkEsServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkEsService/KeepworkEsServiceProject.lua')
local WorldShareKeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local LocalServiceHistory = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceHistory.lua')

local CollectProjectList = NPL.export()
local self = CollectProjectList

CollectProjectList.curPage = 1
CollectProjectList.dataCount = nil
CollectProjectList.select_project_index = 1
CollectProjectList.worksTree = {}

local page

function CollectProjectList.OnInit()
    page = document:GetPageCtrl()
    if page then
        CollectProjectList.GetProjectList()
    end
end

function CollectProjectList.RefreshPage(time)
    if page then
        page:Refresh(time or 0)
    end
    print("Refresh collect project list Page")
end

function CollectProjectList.RefreshList()
    if page then
        local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
        local gvw_name = "gw_collect_ds";
        local  worldDsNode = page:GetNode(gvw_name);
        if(worldDsNode) then
            pe_gridview.DataBind(worldDsNode, gvw_name, false);
        end
        CollectProjectList.UpdateFavorateAndStar()
    end
end

function CollectProjectList.GetProjectList()
    Mod.WorldShare.MsgBox:Show(L'请稍候...', nil, nil, nil, nil, 10)
    KeepworkServiceProject:GetMyFavoriteProjects({ page = self.curPage, perPage = 20  }, function(data, err)
        Mod.WorldShare.MsgBox:Close()
        if not data or
            type(data) ~= 'table' or
            not data.rows or
            type(data.rows) ~= 'table' or
            next(data.rows) == nil or
            err ~= 200 then
            return
        end
        CollectProjectList.dataCount = data.count
        local mapData = {}

        -- map data struct
        for key, item in ipairs(data.rows) do
            local isVipWorld = false

            if item.extra and item.extra.isVipWorld == 1 then
                isVipWorld = true
            end

            mapData[#mapData + 1] = {
                id = item.id,
                name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or '',
                cover =
                    item.extra and
                    type(item.extra.imageUrl) == 'string' and
                    item.extra.imageUrl ~= '' and
                    item.extra.imageUrl or
                    'Texture/Aries/Creator/paracraft/konbaitu_266x134_x2_32bits.png# 0 0 532 268',
                username = item.user and type(item.user.username) == 'string' and item.user.username or '',
                updated_at = item.updatedAt and type(item.updatedAt) == 'string' and item.updatedAt or '',
                user = item.user and type(item.user) == 'table' and item.user or {},
                isVipWorld = isVipWorld,
                total_view = item.visit,
                total_like = item.star,
                total_mark = item.favorite,
                total_comment = item.comment,
                level = item.level or 0,
                isSystemGroupMember = item.isSystemGroupMember,
                isFreeWorld = item.isFreeWorld,
                timeRules = item.timeRules,
                visibility = item.visibility,
                extra = item.extra,
            }
        end

        local rows = mapData

        if self.curPage ~= 1 then
            self.HandleWorldsTree(rows, function(rows)
                for key, item in ipairs(rows) do
                    self.worksTree[#self.worksTree + 1] = item
                end
                CollectProjectList.RefreshList()
            end)
        else
            self.HandleWorldsTree(rows, function(rows)
                self.worksTree = rows
                CollectProjectList.RefreshList()
            end)
        end
    end)
end

function CollectProjectList.HandleWorldsTree(rows, callback)
    if not rows or type(rows) ~= 'table' then
        return false
    end

    local projectIds = {}

    for key, item in ipairs(rows) do
        item.isFavorite = false
        item.isStar = false
        item.type = nil

        projectIds[#projectIds + 1] = item.id
    end

    if KeepworkServiceSession:IsSignedIn() then
        keepwork.project.favorite_search({
            objectType = 5,
            objectId = {
                ['$in'] = projectIds,
            }, 
            userId = Mod.WorldShare.Store:Get('user/userId'),
        }, function(status, msg, data)
            if data and
               type(data) == 'table' and
               data.rows and
               type(data.rows) == 'table' and
               #data.rows ~= 0 then
                for key, item in ipairs(rows) do
                    for dKey, dItem in ipairs(data.rows) do
                        if tonumber(item.id) == tonumber(dItem.objectId) then
                            item.isFavorite = true
                        end
                    end
                end
            end

            WorldShareKeepworkServiceProject:GetStaredProjects(projectIds, function(data, err)
                if data and next(data) then
                    for key, item in ipairs(rows) do
                        for dKey, dItem in ipairs(data.rows) do
                            if tonumber(item.id) == tonumber(dItem.projectId) then
                                item.isStar = true
                            end
                        end
                    end
                end

                if callback and type(callback) == 'function' then
                    callback(rows)
                end
            end)
        end)
    else
        if callback and type(callback) == 'function' then
            callback(rows)
        end
    end
end

function CollectProjectList.OnOpenProject(index)
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return
    end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_collect_frame.click_open_project", {id = curItem.id, useNoId=true},nil,true);
    local username = Mod.WorldShare.Store:Get('user/username')
    local user = curItem.user
    if (user and user.username == username) then
        GameLogic.RunCommand('/loadworld -s -auto ' .. curItem.id)
        return
    end

    local isCanEnter = true
    if curItem.visibility == 1 then
        if not KeepworkServiceSession:IsSignedIn() then
            isCanEnter = false 
        end
        if curItem.level == 0 then
            isCanEnter = false
        end
    end

    if curItem.isSystemGroupMember and curItem.level == 0 then
        isCanEnter = false
    end

    local extra = curItem.extra
    if not curItem.isSystemGroupMember and
            ((extra.vipEnabled and extra.vipEnabled == 1) or
            (extra.isVipWorld and extra.isVipWorld == 1)) then
            if not KeepworkServiceSession:IsSignedIn() then
                isCanEnter = false
            else
                if not GameLogic.IsVip() then
                    isCanEnter = false
                end
            end
    end
    if isCanEnter then
        GameLogic.RunCommand('/loadworld -s -auto ' .. curItem.id)
    else
        GameLogic.AddBBS(nil,"该项目暂无访问权限！",3000,"255 0 0")
    end
end

function CollectProjectList.OnSwitchWorld(index)
    if self.select_project_index ~= index then
        self.select_project_index = index
        CollectProjectList.RefreshList()
    end
end

function CollectProjectList.IsProjectSelected(index)
    if index == self.select_project_index then
        return true
    end

    return false
end

function CollectProjectList.SearchProject(searchText)
    if not searchText or type(searchText) ~= 'string' or searchText == '' then
        return
    end
    --CollectProjectList.GetProjectList(searchText)
end


--收藏
function CollectProjectList.OnFavoriteProject(index)
    local worldinfo = CollectProjectList.worksTree[index]
    if not worldinfo then return end
    keepwork.world.favorite({objectType = 5, objectId = worldinfo.id}, function(status)
        worldinfo.isFavorite = true
        worldinfo.total_mark = worldinfo.total_mark + 1
        if page then
            CollectProjectList.RefreshList()
			CollectProjectList.OnFavoriteMouseEnter(index)
        end
    end)
end

--取消收藏
function CollectProjectList.OnUnfavoriteProject(index)
    local worldinfo = CollectProjectList.worksTree[index]
    if not worldinfo then return end
    keepwork.world.unfavorite({objectType = 5, objectId = worldinfo.id}, function(status)
        worldinfo.isFavorite = false
        worldinfo.total_mark = worldinfo.total_mark - 1
        if page then
            CollectProjectList.RefreshList()
            CollectProjectList.OnFavoriteMouseEnter(index)
        end
    end)
end

--点赞
function CollectProjectList.OnStarProject(index)
    local worldinfo = CollectProjectList.worksTree[index]
    if not worldinfo then return end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_collect_frame.click_star", {id = worldinfo.id, useNoId=true},nil,true);
    keepwork.world.star({router_params = {id = worldinfo.id}}, function(err, msg, data)
        worldinfo.isStar = true
        worldinfo.total_like = worldinfo.total_like + 1
        if page then
            CollectProjectList.RefreshList()
            CollectProjectList.OnStarMouseEnter(index)
        end
    end)
end

--取消点赞
function CollectProjectList.OnUnstarProject(index)
    local worldinfo = CollectProjectList.worksTree[index]
    if not worldinfo then return end
    keepwork.world.star({router_params = {id = worldinfo.id}}, function(err, msg, data)
        worldinfo.isStar = false
        worldinfo.total_like = worldinfo.total_like - 1
        if page then
            CollectProjectList.RefreshList()            
            CollectProjectList.OnStarMouseEnter(index)
        end
    end)
end

function CollectProjectList.OnMouseWheel()
    if not page then
        return
    end
    local worldDS = page:GetNode('gw_collect_ds')
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

    for key, item in ipairs(self.worksTree) do
        if item and (key < startIndex or key > endIndex) then
            local previewPath = item.cover
            if previewPath and type(previewPath) == 'string' then
                ParaAsset.LoadTexture('', previewPath, 1):UnloadAsset()
            end
        end
    end
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

function CollectProjectList.UpdateFavorateAndStar()
    local pageSize = CollectProjectList.worksTree and #CollectProjectList.worksTree or 0
    for i = 1, pageSize do
        local isStar = CollectProjectList.worksTree[i].isStar
        local isFavorite = CollectProjectList.worksTree[i].isFavorite
        local project_favorite_btn = ParaUI.GetUIObject("CreateEmbed.favorite"..i)
        local project_star_btn = ParaUI.GetUIObject("CreateEmbed.star"..i)
        if project_favorite_btn and project_star_btn then
            local isShow = false
            project_star_btn.background = isStar and "Texture/Aries/Creator/keepwork/community_32bits.png;386 238 16 16" or "Texture/Aries/Creator/keepwork/community_32bits.png;341 102 16 16"
            project_favorite_btn.background = isFavorite and "Texture/Aries/Creator/keepwork/community_32bits.png;266 238 16 16" or "Texture/Aries/Creator/keepwork/community_32bits.png;318 102 16 16"
        end
    end
end

function CollectProjectList.OnClickFavorite(index)
    local worldinfo = CollectProjectList.worksTree[index]
    if not worldinfo then return end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_collect_frame.click_favorite", {id = worldinfo.id, useNoId=true},nil,true);
    if worldinfo.isFavorite then
        CollectProjectList.OnUnfavoriteProject(index)
    else
        CollectProjectList.OnFavoriteProject(index)
    end
end

function CollectProjectList.ResetSelectStatus()
    if true then
        return
    end
    local pageSize = CollectProjectList.worksTree and #CollectProjectList.worksTree or 0
    for i = 1, pageSize do
        local isStar = CollectProjectList.worksTree[i].isStar
        local isFavorite = CollectProjectList.worksTree[i].isFavorite
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

        local project_favorite_btn = ParaUI.GetUIObject("CreateEmbed.favorite"..i)
        local project_star_btn = ParaUI.GetUIObject("CreateEmbed.star"..i)
        if project_favorite_btn and project_star_btn then
            local isShow = false
            project_favorite_btn.visible = isShow
            project_star_btn.visible = isShow
            project_star_btn.background = isStar and "Texture/Aries/Creator/keepwork/community_32bits.png;386 238 16 16" or "Texture/Aries/Creator/keepwork/community_32bits.png;341 102 16 16"
            project_favorite_btn.background = isFavorite and "Texture/Aries/Creator/keepwork/community_32bits.png;266 238 16 16" or "Texture/Aries/Creator/keepwork/community_32bits.png;318 102 16 16"
        end

        UpdateCheckBox(i,"share",false)
    end
end



function CollectProjectList.OnMouseEnterImp(index,isBg,isPreview,isShare,isStar,isFavorite)
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
        if isPreview or isStar or isFavorite then
            isShow = true
        end
        project_preview_select2_bg.visible = isShow
    end

    local project_favorite_btn = ParaUI.GetUIObject("CreateEmbed.favorite"..index)
    local project_star_btn = ParaUI.GetUIObject("CreateEmbed.star"..index)
    if project_favorite_btn and project_star_btn then
        local isShow = false
        if isFavorite or isStar or isPreview then
            isShow = true
        end
        project_favorite_btn.visible = isShow
        project_star_btn.visible = isShow
    end

    local project_preview_select1_bg = page:FindControl("project_preview_select1_bg"..index)
    if project_preview_select1_bg then
        local isShow = true
        if isPreview or isStar or isFavorite then
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
    if isShare then
        UpdateCheckBox(index,"share",true)
    end
end

function CollectProjectList.OnMouseLeaveImp(index,isBg,isPreview,isShare,isStar,isFavorite)
    -- print("OnMouseLeaveImp====",index,isBg,isPreview,isShare,isStar,isFavorite)
    if not page or not index then
        return
    end
    
    local project_select_bg = page:FindControl("project_select_bg"..index)
    if project_select_bg then
        local isShow = false
        if isPreview and isShare then
            isShow = true
        end
        project_select_bg.visible = isShow
    end

    local project_bg = page:FindControl("project_bg"..index)
    if project_bg then
        local isShow = true
        if isPreview and isShare then
            isShow = false
        end
        project_bg.visible = isShow
    end

    local project_preview_select2_bg = page:FindControl("project_preview_select2_bg"..index)
    if project_preview_select2_bg then
        local isShow = false
        if isStar or isFavorite then
            isShow = true
        end
        project_preview_select2_bg.visible = isShow
    end

    local project_favorite_btn = ParaUI.GetUIObject("CreateEmbed.favorite"..index)
    local project_star_btn = ParaUI.GetUIObject("CreateEmbed.star"..index)
    if project_favorite_btn and project_star_btn then
        local isShow = false
        if isFavorite or isStar then
            isShow = true
        end
        project_favorite_btn.visible = isShow
        project_star_btn.visible = isShow
    end

    local project_preview_select1_bg = page:FindControl("project_preview_select1_bg"..index)
    if project_preview_select1_bg then
        local isShow = false
        if isPreview and isShare then
            isShow = true
        end
        project_preview_select1_bg.visible = isShow
    end

    local project_preview_border_select_bg = page:FindControl("project_preview_border_select_bg"..index)
    if project_preview_border_select_bg then
        local isShow = false
        if isPreview and isShare then
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
    UpdateCheckBox(index,"share",false)
end

function CollectProjectList.OnBgMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,true)
end

function CollectProjectList.OnBgMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,true)
end

function CollectProjectList.OnPreviewMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,true)
end

function CollectProjectList.OnPreviewMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,true)
end

function CollectProjectList.OnShareMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,true)
end

function CollectProjectList.OnShareMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,true)
end

function CollectProjectList.OnStarMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,false,true)
end


function CollectProjectList.OnStarMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,false,true)
end


function CollectProjectList.OnFavoriteMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,false,false,true)
end


function CollectProjectList.OnFavoriteMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,false,false,true)
end

