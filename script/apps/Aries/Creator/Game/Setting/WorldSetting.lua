--[[
Title: World Setting
Author: pbb  copy form big's OpusSetting
CreateDate: 2023.07.11
Desc: 
use the lib:
------------------------------------------------------------
local WorldSetting = NPL.load('(gl)script/apps/Aries/Creator/Game/Setting/WorldSetting.lua')
WorldSetting.ShowPage()
------------------------------------------------------------
]]

-- libs
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand")
--- service
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua")

local page
local WorldSetting = NPL.export()

WorldSetting.select_tab_index = 1

local self = WorldSetting

function WorldSetting.OnInit()
    page = document:GetPageCtrl()
end

function WorldSetting.ShowPage()
    WorldSetting.select_tab_index = 1
    local view_width = 510
    local view_height = 390
    local params = {
        url = "script/apps/Aries/Creator/Game/Setting/WorldSetting.html",
        name = "WorldSetting.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    WorldSetting.GetWorldData(params)
end

function WorldSetting.ShowOtherSettingPage()
    WorldSetting.select_tab_index = 2 
    if page then
        page:Refresh(0.01)
    end
end

function WorldSetting.GetPageTitle()
    local title = L"项目设置"
    if WorldSetting.select_tab_index == 2 then
        title = L"额外设置"
    end
    return title
end

function WorldSetting.GetWorldData(params)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return
    end

    Mod.WorldShare.MsgBox:Wait()
    if not WorldSetting.IsGetProjectData then
        KeepworkServiceProject:GetProject(currentWorld.kpProjectId, function(data, err)
            Mod.WorldShare.MsgBox:Close()

            if type(data) == 'table' then
                if data.visibility and data.visibility == 0 then
                    -- public
                    params._page:GetNode('public'):SetAttribute('checked', 'checked')
                    params._page:SetValue('private', false)
                    if data.extra and((data.extra.vipEnabled and data.extra.vipEnabled == 1) or (data.extra.isVipWorld and data.extra.isVipWorld == 1)) then
                        params._page:SetValue('vip_checkbox', true)
                        self.isVipWorld = true
                    else
                        params._page:SetValue('vip_checkbox', false)
                        self.isVipWorld = false
                    end

                    if data.extra and(data.extra.isCommonVipWorld and data.extra.isCommonVipWorld == 1) then
                        params._page:SetValue('common_vip_checkbox', true)
                        self.isCommonVipWorld = true
                    else
                        params._page:SetValue('common_vip_checkbox', false)
                        self.isCommonVipWorld = false
                    end

                    if data.extra and data.extra.encode_world and data.extra.encode_world == 1 then
                        params._page:SetValue('encode_world', true)
                        self.encode_world = true
                    else
                        params._page:SetValue('encode_world', false)
                        self.encode_world = false
                    end

                elseif data.visibility == 1 then
                    -- private
                    params._page:SetValue('public', false)
                    params._page:GetNode('private'):SetAttribute('checked', 'checked')
                end
            end
            params._page:Refresh(0.01)
        end)
    end
end

function WorldSetting:SetPublic(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        return false
    end

    local params = {}

    if value == 'public' then
        params.visibility = 0
    elseif value == 'private' then
        params.visibility = 1
    end

    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, "255 0 0")
        end
    end)
end

function WorldSetting:SetVip(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return
    end

    local params = {
        extra = {}
    }

    if value then
        params.extra.isVipWorld = 1
    else
        params.extra.isVipWorld = 0
    end

    params.extra.vipEnabled = 0

    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
            self.isVipWorld = value
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, '255 0 0')
        end
    end)
end

function WorldSetting:SetCommonVip(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return
    end

    local params = {
        extra = {}
    }

    if value then
        params.extra.isCommonVipWorld = 1
    else
        params.extra.isCommonVipWorld = 0
    end

    params.extra.vipEnabled = 0

    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
            self.isCommonVipWorld = value
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, '255 0 0')
        end
    end)
end


function WorldSetting:SetInstituteVip(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        return false
    end

    local params = {
        extra = {}
    }

    if value then
        params.extra.instituteVipEnabled = 1
    else
        params.extra.instituteVipEnabled = 0
    end

    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
            self.instituteVipEnabled = value
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, '255 0 0')
        end
    end)
end

function WorldSetting:SetEncodeWorld(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return
    end

    local params = {
        extra = {}
    }

    if value then
        params.extra.encode_world = 1
    else
        params.extra.encode_world = 0
    end
    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
            self.encode_world = true
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, '255 0 0')
        end
    end)
end


