--[[
Title: Students2In1WorksPage
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
local Students2In1WorksPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/Students2In1WorksPage.lua");
Students2In1WorksPage.Show()
--]]
local Students2In1WorksPage = NPL.export();
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local server_time = 0
local page
local page_item_num = 25
function Students2In1WorksPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = Students2In1WorksPage.OnClose
end

function Students2In1WorksPage.Show()
    World2In1.LoadAllWorlds("grade", function(projects_data)
        Students2In1WorksPage.ShowView(projects_data)
    end);	
end

function Students2In1WorksPage.ShowView(projects_data)
    if page and page:IsVisible() then
        return
    end
    Students2In1WorksPage.projects_data = projects_data
    Students2In1WorksPage.max_page_num = math.floor(#Students2In1WorksPage.projects_data/page_item_num) + 1
    Students2In1WorksPage.page_index = 1
    Students2In1WorksPage.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/Students2In1WorksPage.html",
        name = "Students2In1WorksPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -592/2,
        y = -592/2,
        width = 592,
        height = 592,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function Students2In1WorksPage.FreshView()
    local parent  = page:GetParentUIObject()
end

function Students2In1WorksPage.RefreshPage()
    if(page)then
        page:Refresh(0);
    end
end

function Students2In1WorksPage.ClosePage()
	if (page) then
		page:CloseWindow();
        page = nil
	end
end

function Students2In1WorksPage.OnClose()
    Students2In1WorksPage.ClearData()
end

function Students2In1WorksPage.ClearData()
end

function Students2In1WorksPage.HandleData()
    if Students2In1WorksPage.page_index > Students2In1WorksPage.max_page_num then
        Students2In1WorksPage.page_index = 1
    end

    local grid_data = {}
    local start_index = (Students2In1WorksPage.page_index - 1) * page_item_num
    local max_num = #Students2In1WorksPage.projects_data
    for index = start_index + 1, start_index + page_item_num do
        if index > max_num then
            break
        end
        grid_data[#grid_data + 1] = Students2In1WorksPage.projects_data[index]
    end
    Students2In1WorksPage.GridData = grid_data
end

function Students2In1WorksPage.GetItemName(index)
    local data = Students2In1WorksPage.GridData[index]
    if not data or not data.user then
        return ""
    end
    local user_name = data.user.nickname or data.user.username
    user_name = commonlib.GetLimitLabel(user_name, 9)
    return user_name
end

function Students2In1WorksPage.ClickGridItem(index)
    local data = Students2In1WorksPage.GridData[index]
    if not data or not data.name then
        return
    end

    World2In1.OnEnterRegionByProjectName("grade", data.name)
    Students2In1WorksPage.ClosePage()
end

function Students2In1WorksPage.ClickNextPage()
    Students2In1WorksPage.page_index = Students2In1WorksPage.page_index + 1

    if Students2In1WorksPage.page_index > Students2In1WorksPage.max_page_num then
        Students2In1WorksPage.page_index = 1
    end

    Students2In1WorksPage.HandleData()
    Students2In1WorksPage.RefreshPage()
end