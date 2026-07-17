--[[
    author: pbb
    date: 2024-07-12
    uselib:
     local CommunityWorldModule = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Offline/CommunityWorldModule.lua")
     CommunityWorldModule.ShowPage()
]]

local CommunityWorldModule = NPL.export()
CommunityWorldModule.project_datas = {}
local all_projects_data = {
    {type="大型平坦世界", tagId=2001, name="大型平坦世界", project_name = "superflat", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/pingtan_200x150_32bits.png#0 0 200 150", vipType=0},
    {type="大型随机世界", tagId=2001, name="大型随机世界", project_name = "custom", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/suiji_200x150_32bits.png#0 0 200 150", vipType=0},
    {type="空白世界", tagId=2001, name="空白世界", project_name = "empty", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/kongbai_200x150_32bits.png#0 0 200 150", vipType=0},
    {type="小型平坦世界", tagId=2002, name="小型平坦世界", project_name = "paraworldMini", id = 0, img_bg="Texture/Aries/Creator/keepwork/Community/mini_200x150_32bits.png#0 0 200 150", vipType=0},
}

local page

function CommunityWorldModule.OnInit()
    page = document:GetPageCtrl()
end

function CommunityWorldModule.ShowPage(folderName)
    CommunityWorldModule.project_datas = {}
    CommunityWorldModule.create_world_folder_name = folderName
    CommunityWorldModule.HandleProjectDatas()
    local view_width, view_height = 0,0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/Offline/CommunityWorldModule.html",
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
end


function CommunityWorldModule.HandleProjectDatas()
    local cur_project_datas = commonlib.copy(all_projects_data)
    CommunityWorldModule.project_datas = {}
    for key , data in pairs(cur_project_datas) do
        CommunityWorldModule.project_datas[#CommunityWorldModule.project_datas+1] = data
    end
end

function CommunityWorldModule.OnClickProject(data)
    if data and type(data) == "table" then
        local params = commonlib.copy(data)
        if CommunityWorldModule.create_world_folder_name and CommunityWorldModule.create_world_folder_name ~= "" then
            params.folder_name = CommunityWorldModule.create_world_folder_name
        end
        local CreateNewWorldCommunity = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Project/CreateNewWorldCommunity.lua")
        CreateNewWorldCommunity.ShowPage(params)
    end
end