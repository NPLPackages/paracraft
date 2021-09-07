--[[
Title: RailCarFiexdCameraPage
Author(s): yangguiyi
Date: 2021/7/27
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RailCar/RailCarFiexdCameraPage.lua").Show();
--]]
local RailCarFiexdCameraPage = NPL.export();
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local server_time = 0
local page

local default_setting_data = {
    is_random = false,
    change_time = 10,
    movies_list = {}
}

RailCarFiexdCameraPage.SettingData = {}

function RailCarFiexdCameraPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = RailCarFiexdCameraPage.CloseView
    page.OnCreate = RailCarFiexdCameraPage.OnCreate
end

function RailCarFiexdCameraPage.OnCreate()
    page:SetValue("time_input", RailCarFiexdCameraPage.SettingData.change_time or 0)
end
function RailCarFiexdCameraPage.Show()
    RailCarFiexdCameraPage.ShowView()
end

function RailCarFiexdCameraPage.ShowView()
    if page and page:IsVisible() then
        return
    end
    RailCarFiexdCameraPage.InitData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RailCar/RailCarFiexdCameraPage.html",
        name = "RailCarFiexdCameraPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        directPosition = true,
        
        align = "_ct",
        x = -335/2,
        y = -567/2,
        width = 335,
        height = 567,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function RailCarFiexdCameraPage.FreshView()
    local parent  = page:GetParentUIObject()
end

function RailCarFiexdCameraPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    RailCarFiexdCameraPage.FreshView()
end

function RailCarFiexdCameraPage.CloseView()
    RailCarFiexdCameraPage.ClearData()
end

function RailCarFiexdCameraPage.ClearData()
end

function RailCarFiexdCameraPage.InitData()
	local filename = "railcar_setting.txt"
    local world_data = Mod.WorldShare.Store:Get('world/currentWorld')
	local disk_folder = world_data.worldpath
	RailCarFiexdCameraPage.file_path = string.format("%s/%s", disk_folder, filename)

    local save_data = CameraController.LoadFiexdCameraSetting()
    if save_data then
        RailCarFiexdCameraPage.SettingData = save_data
    else
        RailCarFiexdCameraPage.SettingData = default_setting_data
    end

    local movies_list = RailCarFiexdCameraPage.SettingData.movies_list or {}
    if movies_list then
        for index, v in ipairs(movies_list) do
            if v.pos then
                v.desc = string.format("%s,%s,%s", v.pos[1] or 0, v.pos[2] or 0, v.pos[3] or 0)
            end
        end
    end

end

function RailCarFiexdCameraPage.Close()
    if page and page:IsVisible() then
        page:CloseWindow(0)
        RailCarFiexdCameraPage.CloseView()
    end
end


function RailCarFiexdCameraPage.ChangeIsRandom()
    RailCarFiexdCameraPage.SettingData.is_random = not RailCarFiexdCameraPage.SettingData.is_random
    page:Refresh(0)
end

function RailCarFiexdCameraPage.TimeInputOnChange()
    local value = page:GetValue("time_input")
    if not tonumber(value) and value ~= "" then
        GameLogic.AddBBS(nil, L"请输入数字", 5000, "255 0 0");
        page:SetValue("time_input", RailCarFiexdCameraPage.SettingData.change_time)
    end

    value = tonumber(value)

    if value <= 0 then
        GameLogic.AddBBS(nil, L"请输入一个大于0的数字", 5000, "255 0 0");
        page:SetValue("time_input", RailCarFiexdCameraPage.SettingData.change_time)
        return
    end

    if value then
        RailCarFiexdCameraPage.SettingData.change_time = value
    end
end

function RailCarFiexdCameraPage.Select(index)
    local movies_list = RailCarFiexdCameraPage.SettingData.movies_list
    if movies_list == nil or movies_list[index] == nil then
        return
    end

    local item = movies_list[index]
    
    item.is_select = not item.is_select
    page:Refresh(0)
end

function RailCarFiexdCameraPage.Delete(index)
    local movies_list = RailCarFiexdCameraPage.SettingData.movies_list
    if movies_list == nil or movies_list[index] == nil then
        return
    end

    table.remove(movies_list, index)
    page:Refresh(0)
end

function RailCarFiexdCameraPage.ChangeUp(index)
    local movies_list = RailCarFiexdCameraPage.SettingData.movies_list
    if movies_list == nil or movies_list[index] == nil then
        return
    end
    if index == 1 then
        return
    end

    local item = table.remove(movies_list, index)
    table.insert(movies_list, index - 1, item)
    page:Refresh(0)
end

function RailCarFiexdCameraPage.ChangeDown(index)
    local movies_list = RailCarFiexdCameraPage.SettingData.movies_list
    if movies_list == nil or movies_list[index] == nil then
        return
    end

    if index == #movies_list then
        return
    end
    local item = table.remove(movies_list, index)
    table.insert(movies_list, index + 1, item)

    page:Refresh(0)
end

function RailCarFiexdCameraPage.ClickOk()
	local filename = "railcar_setting.txt"

    local movies_list = RailCarFiexdCameraPage.SettingData.movies_list
    if #movies_list > 20 then
        GameLogic.AddBBS(nil, L"视觉列表数量过多，请勿超过20个", 5000, "255 0 0")
        return
    end

    local world_data = Mod.WorldShare.Store:Get("world/currentWorld")
	if world_data == nil then
		return
	end

    local function save_local(has_upload)
        local disk_folder = world_data.worldpath
        local file_path = string.format("%s/%s", disk_folder, filename)
        if ParaIO.DoesFileExist(disk_folder) then
            if not ParaIO.DoesFileExist(file_path, true) then
                ParaIO.CreateDirectory(file_path)
            end
            
            if has_upload then
                RailCarFiexdCameraPage.SettingData.has_upload = true
            end

            if world_data.kpProjectId then
                RailCarFiexdCameraPage.SettingData.kpProjectId = world_data.kpProjectId
            end

            local data = commonlib.Json.Encode(RailCarFiexdCameraPage.SettingData);
            local file = ParaIO.open(file_path, "w");
            if(file) then
                file:write(data, #data);
                file:close();
            end
        end

        page:CloseWindow(0)
        RailCarFiexdCameraPage.CloseView()
    end

    if world_data.kpProjectId then
        local params = {
            extra = {}
        }
        params.extra.railcar_fiexd_setting = RailCarFiexdCameraPage.SettingData;
    
        KeepworkServiceProject:UpdateProject(world_data.kpProjectId, params, function(data, err)
            if err == 200 then
                save_local(true)
            end
        end)
    else
        save_local()
    end

    -- local world_data = Mod.WorldShare.Store:Get("world/currentWorld")
    -- local CacheProjectId = NPL.load("(gl)Mod/WorldShare/database/CacheProjectId.lua")
    -- local data = CacheProjectId:GetProjectIdInfo(world_data.kpProjectId)
    -- echo(data, true)
end

function RailCarFiexdCameraPage.AddPosData(data)
    if page == nil or not page:IsVisible() then
        return
    end

    local movies_list = RailCarFiexdCameraPage.SettingData.movies_list
    if not movies_list then
        return
    end

    movies_list[#movies_list + 1] = data
    page:Refresh(0)
end

function RailCarFiexdCameraPage.AddView()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RailCar/RailCarAddCameraPage.lua").Show();
end