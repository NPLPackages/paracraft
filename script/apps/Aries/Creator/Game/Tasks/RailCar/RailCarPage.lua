--[[
Title: RailCarPage
Author(s): yangguiyi
Date: 2021/7/27
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RailCar/RailCarPage.lua").Show();
--]]
local RailCarPage = NPL.export();
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local server_time = 0
local page
function RailCarPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = RailCarPage.CloseView
    page.OnCreate = RailCarPage.OnCreate
end

function RailCarPage.OnCreate()
    local railcar_setting_icon = ParaUI.GetUIObject("railcar_setting_icon");
    local camera_data = RailCarPage.CameraType[RailCarPage.select_cameratype_index]

    if railcar_setting_icon:IsValid() and camera_data then
        railcar_setting_icon.visible = GameLogic.GameMode:IsEditor() and camera_data.type == "lock_fixed"
    else
        railcar_setting_icon.visible = false
    end
end

function RailCarPage.Show()
    RailCarPage.ShowView()
end

function RailCarPage.ShowView()
    if page and page:IsVisible() then
        return
    end

    if not RailCarPage.has_bind then
        GameLogic.GetFilters():add_filter("PlayerMountEntity", function(player_entity, target_entity)
            if target_entity == nil then
                RailCarPage.Close()

                CameraController.SetRailCarCameraMod(nil)
            end
        end);

        RailCarPage.has_bind = true
    end
    RailCarPage.InitData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RailCar/RailCarPage.html",
        name = "RailCarPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        click_through = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = 0,
        directPosition = true,
        
        align = "_rb",
        x = -410,
        y = -155,
        width = 410,
        height = 155,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function RailCarPage.FreshView()
    local parent  = page:GetParentUIObject()
end

function RailCarPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    RailCarPage.FreshView()
end

function RailCarPage.CloseView()
    RailCarPage.ClearData()
end

function RailCarPage.ClearData()
    if RailCarPage.RailCarCamareTimer then
        RailCarPage.RailCarCamareTimer:Change()
        RailCarPage.RailCarCamareTimer = nil
    end
end

function RailCarPage.InitData()
    RailCarPage.CameraType = {
        {type = "lock_first_person", icon="icon_1_32bits.png", name ="第一人称模式", select_icon = "icon_1_select_32bits.png"},
        {type = "lock_surround", icon="icon_2_32bits.png", name ="第三人称跟随拍摄", select_icon = "icon_2_select_32bits.png"},
        {type = "lock_fixed", icon="icon_3_32bits.png", name ="固定机位拍摄", select_icon = "icon_3_select_32bits.png"},
        -- {type = "lock_movie_view", icon="icon_4_32bits.png", name ="haha", select_icon = "icon_4_select_32bits.png"},
        {type = "lock_random", icon="icon_5_32bits.png", name ="随机", select_icon = "icon_5_select_32bits.png"},
        {type = "unlock", icon="icon_6_32bits.png", name ="标准模式（默认）", select_icon = "icon_6_select_32bits.png"},
    }

    -- local movies_pos = GameLogic.GetFilters():apply_filters("railcar_fiexd_movie_pos");
    local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
    local is_in_lessonbox = World2In1.GetIsLessonBox()
    if is_in_lessonbox and World2In1.GetRegionType() == "creator" then
        table.insert(RailCarPage.CameraType, 4, {type = "lock_movie_view", icon="icon_4_32bits.png", name ="环绕拍摄", select_icon = "icon_4_select_32bits.png"})
    end

    RailCarPage.select_cameratype_index = #RailCarPage.CameraType
end

function RailCarPage.Close()
    if page and page:IsVisible() then
        page:CloseWindow(0)
        RailCarPage.CloseView()
    end
end

function RailCarPage.RefreshStepCount(step_count)
    if page == nil then
        return
    end
    page:SetValue("step_count", step_count .. "m")
end

function RailCarPage.OnClickLockFirstPerson()
    -- body
end

function RailCarPage.ChangeCameraType(index)    
    local camera_data = RailCarPage.CameraType[index]
    if camera_data == nil then
        return
    end

    -- if RailCarPage.select_cameratype_index == index and camera_data.type ~= "lock_surround" then
    --     return
    -- end

    RailCarPage.SelectType(index)

    if camera_data.type then
        if camera_data.type == "lock_random" then
            RailCarPage.RandomCamera()
        elseif camera_data.type == "unlock" then
            CameraController.SetRailCarCameraMod(nil)
        else
            CameraController.SetRailCarCameraMod(camera_data.type)
        end
        
    end
end

function RailCarPage.SelectType(index)
    if RailCarPage.RailCarCamareTimer then
        RailCarPage.RailCarCamareTimer:Change()
        RailCarPage.RailCarCamareTimer = nil
    end

    if page == nil or not page:IsVisible() then
        return
    end

    index = index or #RailCarPage.CameraType
    RailCarPage.select_cameratype_index = index
    page:Refresh(0)
end

function RailCarPage.GetIcon(index)
    local camera_data = RailCarPage.CameraType[index]
    if camera_data == nil then
        return ""
    end
    
    local icon = camera_data.icon
    if RailCarPage.select_cameratype_index == index then
        icon = camera_data.select_icon
    end

    return string.format("Texture/Aries/Creator/keepwork/RailCar/%s#0 0 64 64", icon)
end

function RailCarPage.OpenFiedCameraSetting()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RailCar/RailCarFiexdCameraPage.lua").Show();
end

function RailCarPage.RandomCamera()
    if RailCarPage.RailCarCamareTimer then
        RailCarPage.RailCarCamareTimer:Change()
        RailCarPage.RailCarCamareTimer = nil
    end

    local random_list = {1, 2, 3}
    RailCarPage.RandomOneCamera(random_list)
end

function RailCarPage.RandomOneCamera(random_list)
    if RailCarPage.RailCarCamareTimer then
        RailCarPage.RailCarCamareTimer:Change()
        RailCarPage.RailCarCamareTimer = nil
    end

    if #random_list == 0 then
        RailCarPage.RandomCamera()
        return
    end

    local index = math.random(1, #random_list)
    local random_index = table.remove(random_list, index)
    local camera_data = RailCarPage.CameraType[random_index]
    if camera_data.type then
        CameraController.SetRailCarCameraMod(camera_data.type)

        RailCarPage.RailCarCamareTimer = commonlib.Timer:new({callbackFunc = function()
            RailCarPage.RandomOneCamera(random_list)
        end})
        RailCarPage.RailCarCamareTimer:Change(60 * 1000);
    end
end
