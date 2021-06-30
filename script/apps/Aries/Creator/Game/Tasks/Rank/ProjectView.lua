    --[[
Title: ProjectView
Author(s): yangguiyi
Date: 2021/4/20
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/ProjectView.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local ProjectView = NPL.export();
ProjectView.ProjectData = {}

function ProjectView.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ProjectView.CloseView
end

function ProjectView.Show(id)
    id = 144

	keepwork.world.detail({router_params = {id = id}}, function(err, msg, data)
        if err == 200 then
            print("dqqqqqqqqqqqqqqqqqqq", err, msg)
            commonlib.echo(data, true)
        end
	end);
    local world_id_list = {id}
    keepwork.world.search({
        type = 1,
        id = id,
    },function(err, msg, data)
        print("获取关注列表结果", err, msg)
        commonlib.echo(data, true)
        if err == 200 then
            ProjectView.HandleData(data)
            ProjectView.ShowView()
        end
    end)
end

function ProjectView.ShowView()
    if page and page:IsVisible() then
        return
    end
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Rank/ProjectView.html",
        name = "ProjectView.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -996/2,
        y = -613/2,
        width = 996,
        height = 613,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ProjectView.FreshView()
    local parent  = page:GetParentUIObject()
end

function ProjectView.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    ProjectView.FreshView()
end

function ProjectView.CloseView()
    ProjectView.ClearData()
end

function ProjectView.ClearData()
end

function ProjectView.HandleData(data)
    local item = data.rows[1]
    local isVipWorld = false

    if item.extra and item.extra.isVipWorld == 1 then
        isVipWorld = true
    end

    ProjectView.ProjectData = {
        id = item.id,
        name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or "",
        cover = item.extra and type(item.extra.imageUrl) == 'string' and item.extra.imageUrl or "",
        username = item.user and type(item.user.username) == 'string' and item.user.username or "",
        updated_at = item.updatedAt and type(item.updatedAt) == 'string' and item.updatedAt or "",
        user = item.user and type(item.user) == 'table' and item.user or {},
        isVipWorld = isVipWorld,
        total_view = item.visit,
        total_like = item.star,
        total_mark = item.favorite,
        total_comment = item.comment
    }
end