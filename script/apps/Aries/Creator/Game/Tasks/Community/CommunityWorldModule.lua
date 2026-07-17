--[[
    author: pbb
    date: 2024-05-12
    uselib:
     local CommunityWorldModule = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityWorldModule.lua")
     CommunityWorldModule.ShowPage()
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local http_env = HttpWrapper.GetDevVersion()

--https://keepwork-dev.kp-para.cn/deng123456/worldtemplates/community
local templatePath = {
    STAGE = "deng123456/worldtemplates/community",
    RELEASE = "deng123456/worldtemplates/community",
    ONLINE = "official/online_settings/paracraft/world_templates"
}

local CommunityWorldModule = NPL.export()

local all_projects_data = {
    {type="大型平坦世界", tagId=2001, name="大型平坦世界", project_name = "superflat", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/pingtan_200x150_32bits.png#0 0 200 150", vipType=0},
    {type="大型随机世界", tagId=2001, name="大型随机世界", project_name = "custom", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/suiji_200x150_32bits.png#0 0 200 150", vipType=0},
    {type="空白世界", tagId=2001, name="空白世界", project_name = "empty", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/kongbai_200x150_32bits.png#0 0 200 150", vipType=0},
    {type="小型平坦世界", tagId=2002, name="小型平坦世界", project_name = "paraworldMini", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/mini_200x150_32bits.png#0 0 200 150", vipType=0},
}

if System.os.IsEmscripten() then
    all_projects_data = {
        {type="大型平坦世界", tagId=2001, name="大型平坦世界", project_name = "superflat", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/pingtan_200x150_32bits.png#0 0 200 150", vipType=0},
        {type="空白世界", tagId=2001, name="空白世界", project_name = "empty", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/kongbai_200x150_32bits.png#0 0 200 150", vipType=0},
        {type="小型平坦世界", tagId=2002, name="小型平坦世界", project_name = "paraworldMini", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/mini_200x150_32bits.png#0 0 200 150", vipType=0},
    }
end

CommunityWorldModule.TypeData = {
    {name="本地",tagId=0, childrens = {
        {name="大型世界", tagId=2001, project_list = {}},
        {name="迷你世界", tagId=2002, project_list = {}},
    }},
}


local page

function CommunityWorldModule.GetTemplateData(callback)
    NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWork.lua");
    local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
    local template_path = templatePath[http_env]
    KeepWork.GetRawFileByPath(template_path, function(err, msg, data)
        if err ~= 200 or not data then
            if callback and type(callback) == "function" then
                callback()
            end
            return
        end
        local dataList = commonlib.split(data, '\r\n')
        if not dataList or type(dataList) ~= 'table' then
            if callback and type(callback) == "function" then
                callback()
            end
            return
        end
        local type_data = {}
        local template_data = {}
        for i, v in ipairs(dataList) do
            template_data[#template_data + 1] = commonlib.LoadTableFromString(v)
        end
       
        --先找出树节点的父类
        local category_datas = {}
        for i, v in ipairs(template_data) do
            type_data[v.tagId] = v.type
            if v.childrens and type(v.childrens) == "table" then
                category_datas[#category_datas+1] = {name = v.type,tagId = v.tagId,childrens = v.childrens}
            end
        end

        --再找出子节点的信息
        for i, v in ipairs(category_datas) do
            if v.childrens and type(v.childrens) == "table" then
                local childrens = {}
                for j, child in ipairs(v.childrens) do
                    childrens[#childrens + 1] = {name = type_data[child], tagId = child, project_list = {}}
                end
                v.childrens = childrens
            end
        end
        
        -- print("handle data end=================")
        -- echo(template_data,true)
        -- echo(category_datas,true)
        if callback and type(callback) == "function" then
            callback(template_data,category_datas)
        end
    end, "access plus 10 seconds")
end

function CommunityWorldModule.OnInit()
    page = document:GetPageCtrl()
end

function CommunityWorldModule.ShowPage(folderName)
    CommunityWorldModule.GetTemplateData(function(template_data, category_datas)
        CommunityWorldModule.server_template_data = template_data
        CommunityWorldModule.server_category_datas = category_datas

        CommunityWorldModule.create_world_folder_name = folderName
        CommunityWorldModule.HandleCategoryDatas()
        local view_width, view_height = 0,0
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityWorldModule.html",
            name = "CommunityWorldModule.ShowPage", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = false,
            enable_esc_key = true,
            cancelShowAnimation = true,
            directPosition = true,
                align = "_fi",
                x = -view_width/2,
                y = -view_height/2,
                width = view_width,
                height = view_height,
        };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
    end)
end

function CommunityWorldModule.RefreshPage(bOnlyRereshTree)
    if page then
        if bOnlyRereshTree then
            page:CallMethod('tvwMenus', 'SetDataSource', CommunityWorldModule.category_datas)
            page:CallMethod('tvwMenus', 'DataBind')

            page:CallMethod('CommunityWorldModule.slot_gridview1', 'SetDataSource', CommunityWorldModule.project_datas)
            page:CallMethod('CommunityWorldModule.slot_gridview1', 'DataBind')
        else
            page:Refresh(0.01)
        end 
        
    end
end

function CommunityWorldModule.HandleCategoryDatas()
    local category_datas = {}
    local idx = 1
    local type_datas = commonlib.copy(CommunityWorldModule.TypeData)
    if CommunityWorldModule.server_category_datas and type(CommunityWorldModule.server_category_datas) == "table" then
        for i, v in ipairs(CommunityWorldModule.server_category_datas) do
            local category = CommunityWorldModule.server_category_datas[i]
            type_datas[#type_datas + 1] = category
        end
    end
    for key, data in pairs(type_datas) do
        local category = type_datas[key]
        category_datas[idx] = category_datas[idx] or {}
        
        local cur_category = category_datas[idx]
        cur_category.name = "category"
        cur_category.attr = {tagId = category.tagId, text = category.name, background = category.background, expanded = false ,count = 0,}

        local childrens = category.childrens
        if childrens and #childrens > 0 then
            for jdx, child in ipairs(childrens) do
                local child_category = childrens[jdx]
                cur_category[#cur_category+1] = {name = "children" , attr = {tagId = child_category.tagId, text = child_category.name, background = child_category.background, expanded = false, count = 0,}}
            end
        end
        cur_category.attr.count = #cur_category
        idx = idx + 1
    end
    category_datas[1].attr.expanded = true
    CommunityWorldModule.selected_category = category_datas[1]
    CommunityWorldModule.category_datas = category_datas
    CommunityWorldModule.HandleProjectDatas()
end

function CommunityWorldModule.ChangeCategory(index)

end

function CommunityWorldModule.OnSelectMenu(data)
    local selected_category = nil
    for k, v in pairs(CommunityWorldModule.category_datas) do
		if type(v) == "table" and v.name == "category" and type(data) == "table" then
			if v.attr.text == data.text then
				v.attr.expanded = not v.attr.expanded
                selected_category = v   
			end
		end
    end
    if selected_category then
        CommunityWorldModule.selected_category = selected_category
        CommunityWorldModule.HandleProjectDatas()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.module_page.click_category", {useNoId=true},nil,true);
    end
    CommunityWorldModule.RefreshPage(true)
end

function CommunityWorldModule.OnClickCategory(data)
    if CommunityWorldModule.selected_category ~= data then
        CommunityWorldModule.selected_category = data
        CommunityWorldModule.HandleProjectDatas()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.module_page.click_category", {useNoId=true},nil,true);
        CommunityWorldModule.RefreshPage()
    end
end

function CommunityWorldModule.IsMenuSelected(data)
    if CommunityWorldModule.selected_category and data then
        local name = CommunityWorldModule.selected_category.name
        if name == "category" then
            return CommunityWorldModule.selected_category.attr.text == data.text
        end
        return CommunityWorldModule.selected_category.text == data.text
    end
    return false
end

function CommunityWorldModule.HandleProjectDatas()
    local cur_category = CommunityWorldModule.selected_category
    local cur_project_datas = commonlib.copy(all_projects_data)
    if CommunityWorldModule.server_template_data and type(CommunityWorldModule.server_template_data) == "table" then
        for i, v in ipairs(CommunityWorldModule.server_template_data) do
            cur_project_datas[#cur_project_datas + 1] = v
        end
    end
    if cur_category and type(cur_category) == "table" then
        CommunityWorldModule.project_datas = {}
        if cur_category.attr and type(cur_category.attr) == "table" then
            local category_nums = cur_category.attr.count
            local tagIds = {}
            if category_nums > 0 then
                for i = 1, category_nums do
                    local child = cur_category[i]
                    if child and type(child) == "table" and child.name == "children" and type(child.attr) == "table" then
                        tagIds[#tagIds+1] = child.attr.tagId
                    end
                end
                tagIds[#tagIds + 1] = cur_category.attr.tagId
            else
                tagIds[#tagIds + 1] = cur_category.attr.tagId
            end

            for i = 1, #tagIds do
                local tagId = tagIds[i]
                for key , data in pairs(cur_project_datas) do
                    if data.tagId == tagId and data.name and data.name ~= "" then
                        CommunityWorldModule.project_datas[#CommunityWorldModule.project_datas+1] = data
                    end
                end
            end
        else
            local tagIds = {cur_category.tagId}
            for i = 1, #tagIds do
                local tagId = tagIds[i]
                for key , data in pairs(cur_project_datas) do
                    if data.tagId == tagId and data.name and data.name ~= "" then
                        CommunityWorldModule.project_datas[#CommunityWorldModule.project_datas+1] = data
                    end
                end
            end
        end

    end
end

function CommunityWorldModule.CheckVIPItem(data,callback)
    if data and type(data) == "table" then
        if data.vipType > 0 then
            local vipKey = data.vipType == 1 and "VipWorldTemplate" or "SvipWorldTemplate"
            GameLogic.CheckSignedIn(L"请先登录", function(bSucceed)
                if bSucceed then
                    GameLogic.IsVip(vipKey, true, function(result)
                        if result then
                            if callback and type(callback) == "function" then
                                callback()
                            end
                        end
                    end);
                else
                    GameLogic.AddBBS(nil, L"登录失败，请重试")
                end
            end)
        elseif data.id > 0 then
            GameLogic.CheckSignedIn(L"请先登录", function(bSucceed)
                if bSucceed then
                    if callback and type(callback) == "function" then
                        callback()
                    end
                else
                    GameLogic.AddBBS(nil, L"登录失败，请重试")
                end
            end)
        else
            if callback and type(callback) == "function" then
                callback()
            end
        end
    end
end 

function CommunityWorldModule.OnClickProject(data)
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.module_page.click_template", {project_name = data.project_name,project_id = data.id,useNoId=true},nil,true);
    CommunityWorldModule.CheckVIPItem(data,function()
        if data and type(data) == "table" then
            local params = commonlib.copy(data)
            if CommunityWorldModule.create_world_folder_name and CommunityWorldModule.create_world_folder_name ~= "" then
                params.folder_name = CommunityWorldModule.create_world_folder_name
            end
            local CreateNewWorldCommunity = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/CreateNewWorldCommunity.lua")
            CreateNewWorldCommunity.ShowPage(params)
        end
    end)
    
end