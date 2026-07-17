--[[
    author:{pbb}
    time:2024-05-06 17:50:48
    uselib:
        local HistoryProjectList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/HistoryProjectList.lua")
]]
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkService/KeepworkServiceProject.lua')
local WorldShareKeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local LocalServiceHistory = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceHistory.lua')

local HistoryProjectList = NPL.export()
local self = HistoryProjectList

HistoryProjectList.curPage = 1
HistoryProjectList.select_project_index = 1
HistoryProjectList.worksTree = {}

local page

function HistoryProjectList.OnInit()
    page = document:GetPageCtrl()
    if page then
        HistoryProjectList.GetProjectList()
    end
end

function HistoryProjectList.RefreshPage(time)
    if page then
        page:Refresh(time or 0)
    end
    print("Refresh history project list Page")
end

function HistoryProjectList.RefreshList()
    if page then
        local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
        local gvw_name = "gw_histroy_ds";
        local  worldDsNode = page:GetNode(gvw_name);
        if(worldDsNode) then
            pe_gridview.DataBind(worldDsNode, gvw_name, false);
        end
        HistoryProjectList.UpdateFavorateAndStar()
    end
end

function HistoryProjectList.GetProjectList()
    local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
    local historyItems = LocalServiceHistory:GetWorldRecord()

    local historyIds = {}

    for key, item in ipairs(historyItems) do
        historyIds[#historyIds + 1] = item.projectId
    end
    KeepworkServiceProject:GetProjectByIds(
        historyIds,
        { perPage = 10000 },
        function(data, err)
            if not data or
               type(data) ~= 'table' and
               not data.rows and
               type(data.rows) ~= 'table' then
                return
            end

            local mapData = {}

            for key, item in ipairs(data.rows) do
                for hKey, hItem in ipairs(historyItems) do
                    if item.id == hItem.projectId then
                        item.visitTime = hItem.date
                        break
                    end
                end

                mapData[#mapData + 1] = {
                    id = item.id,
                    name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or '',
                    cover = 
                        item.extra and
                        type(item.extra.imageUrl) == 'string' and
                        item.extra.imageUrl and
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
                    visitTime = item.visitTime,
                    level = item.level or 0,
                    isSystemGroupMember = item.isSystemGroupMember,
                    isFreeWorld = item.isFreeWorld,
                    timeRules = item.timeRules,
                    visibility = item.visibility,
                    extra = item.extra,
                }
            end

            table.sort(mapData, function(a, b)
                if not a or
                   not a.visitTime or
                   not b or
                   not b.visitTime then
                    return false
                end

                return a.visitTime > b.visitTime
            end)

            self.HandleWorldsTree(mapData, function(rows)
                self.worksTree = rows

                HistoryProjectList.RefreshList()
            end)
        end
    )
end

function HistoryProjectList.HandleWorldsTree(rows, callback)
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

function HistoryProjectList.OnOpenProject(index)
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return
    end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_history_frame.click_enter_world", {useNoId=true},nil,true);
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

function HistoryProjectList.OnSwitchWorld(index)
    if self.select_project_index ~= index then
        self.select_project_index = index
        if page then
            local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
            local gvw_name = "gw_histroy_ds";
            local  worldDsNode = page:GetNode(gvw_name);
            if(worldDsNode) then
                pe_gridview.DataBind(worldDsNode, gvw_name, false);
            end
        end
    end
end

function HistoryProjectList.IsProjectSelected(index)
    if index == self.select_project_index then
        return true
    end

    return false
end

function HistoryProjectList.SearchProject(searchText)
    if not searchText or type(searchText) ~= 'string' or searchText == '' then
        return
    end
end

--收藏
function HistoryProjectList.OnFavoriteProject(index)
    local worldinfo = HistoryProjectList.worksTree[index]
    if not worldinfo then return end
    keepwork.world.favorite({objectType = 5, objectId = worldinfo.id}, function(status)
        worldinfo.isFavorite = true
        worldinfo.total_mark = worldinfo.total_mark + 1
        if page then
            HistoryProjectList.RefreshList()
            HistoryProjectList.OnFavoriteMouseEnter(index)
        end
    end)
end

--取消收藏
function HistoryProjectList.OnUnfavoriteProject(index)
    local worldinfo = HistoryProjectList.worksTree[index]
    if not worldinfo then return end
    keepwork.world.unfavorite({objectType = 5, objectId = worldinfo.id}, function(status)
        worldinfo.isFavorite = false
        worldinfo.total_mark = worldinfo.total_mark - 1
        if page then
            HistoryProjectList.RefreshList()
            HistoryProjectList.OnFavoriteMouseEnter(index)
        end
    end)
end

--点赞
function HistoryProjectList.OnStarProject(index)
    local worldinfo = HistoryProjectList.worksTree[index]
    if not worldinfo then return end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_history_frame.click_star", {id =worldinfo.id,useNoId=true},nil,true);
    keepwork.world.star({router_params = {id = worldinfo.id}}, function(err, msg, data)
        worldinfo.isStar = true
        worldinfo.total_like = worldinfo.total_like + 1
        if page then
            HistoryProjectList.RefreshList()
            HistoryProjectList.OnStarMouseEnter(index)
        end
    end)
end

--取消点赞
function HistoryProjectList.OnUnstarProject(index)
    
end

function HistoryProjectList.OnMouseWheel()
    if not page then
        return
    end
    local worldDS = page:GetNode('gw_histroy_ds')
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

function HistoryProjectList.UpdateFavorateAndStar()
    local pageSize = HistoryProjectList.worksTree and #HistoryProjectList.worksTree or 0
    for i = 1, pageSize do
        local isStar = HistoryProjectList.worksTree[i].isStar
        local isFavorite = HistoryProjectList.worksTree[i].isFavorite
        local project_favorite_btn = ParaUI.GetUIObject("CreateEmbed.favorite"..i)
        local project_star_btn = ParaUI.GetUIObject("CreateEmbed.star"..i)
        if project_favorite_btn and project_star_btn then
            local isShow = false
            project_star_btn.background = isStar and "Texture/Aries/Creator/keepwork/community_32bits.png;386 238 16 16" or "Texture/Aries/Creator/keepwork/community_32bits.png;341 102 16 16"
            project_favorite_btn.background = isFavorite and "Texture/Aries/Creator/keepwork/community_32bits.png;266 238 16 16" or "Texture/Aries/Creator/keepwork/community_32bits.png;318 102 16 16"
        end
    end
end

function HistoryProjectList.OnClickFavorite(index)
    local worldinfo = HistoryProjectList.worksTree[index]
    if not worldinfo then return end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.project_history_frame.click_favorite", {id =worldinfo.id,useNoId=true},nil,true);
    if worldinfo.isFavorite then
        HistoryProjectList.OnUnfavoriteProject(index)
    else
        HistoryProjectList.OnFavoriteProject(index)
    end
end

function HistoryProjectList.ResetSelectStatus()
    if true then
        return
    end
    local pageSize = HistoryProjectList.worksTree and #HistoryProjectList.worksTree or 0
    for i = 1, pageSize do
        local isStar = HistoryProjectList.worksTree[i].isStar
        local isFavorite = HistoryProjectList.worksTree[i].isFavorite
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



function HistoryProjectList.OnMouseEnterImp(index,isBg,isPreview,isShare,isStar,isFavorite)
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

function HistoryProjectList.OnMouseLeaveImp(index,isBg,isPreview,isShare,isStar,isFavorite)
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

function HistoryProjectList.OnBgMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,true)
end

function HistoryProjectList.OnBgMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,true)
end

function HistoryProjectList.OnPreviewMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,true)
end

function HistoryProjectList.OnPreviewMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,true)
end

function HistoryProjectList.OnShareMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,true)
end

function HistoryProjectList.OnShareMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,true)
end

function HistoryProjectList.OnStarMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,false,true)
end


function HistoryProjectList.OnStarMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,false,true)
end


function HistoryProjectList.OnFavoriteMouseEnter(index)
    self.ResetSelectStatus()
    self.OnMouseEnterImp(index,false,false,false,false,true)
end


function HistoryProjectList.OnFavoriteMouseLeave(index)
    self.ResetSelectStatus()
    self.OnMouseLeaveImp(index,false,false,false,false,true)
end


