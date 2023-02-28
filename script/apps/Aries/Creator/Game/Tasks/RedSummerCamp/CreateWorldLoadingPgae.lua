--[[
Title: CreateWorldLoadingPgae
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
local CreateWorldLoadingPgae = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/CreateWorldLoadingPgae.lua")
CreateWorldLoadingPgae.ShowView();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local CreateWorldLoadingPgae = NPL.export();

local server_time = 0
local page
function CreateWorldLoadingPgae.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = CreateWorldLoadingPgae.OnClose
end

function CreateWorldLoadingPgae.ShowView(callback, desc_list)
    if page and page:IsVisible() then
        return
    end
    CreateWorldLoadingPgae.SpecialFlag = nil
    CreateWorldLoadingPgae.desc_list = desc_list or {}
    CreateWorldLoadingPgae.callback = callback
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/CreateWorldLoadingPgae.html",
        name = "CreateWorldLoadingPgae.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        isTopLevel = true,
        -- enable_esc_key = true,
        zorder = 0,
        -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -760/2,
        y = -364/2,
        width = 760,
        height = 364,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    CreateWorldLoadingPgae.PlayLoadingAnim()
end

function CreateWorldLoadingPgae.IsOpen()
    if page and page:IsVisible() then
        return true
    end

    return false
end

function CreateWorldLoadingPgae.FreshView()
    local parent  = page:GetParentUIObject()
end

function CreateWorldLoadingPgae.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    CreateWorldLoadingPgae.FreshView()
end

function CreateWorldLoadingPgae.CloseView()
    if(page)then
        page:CloseWindow(0);
        page = nil
    end
end

function CreateWorldLoadingPgae.OnClose()
    CreateWorldLoadingPgae.ClearData()
end

function CreateWorldLoadingPgae.ClearData()
    CreateWorldLoadingPgae.SpecialFlag = nil
    if CreateWorldLoadingPgae.anim_timer then
        CreateWorldLoadingPgae.anim_timer:Change(nil)
        CreateWorldLoadingPgae.anim_timer=nil
    end
end

function CreateWorldLoadingPgae.GetDesc1()
    local desc = CreateWorldLoadingPgae.desc_list.desc1 or "正在为你创建超平坦地形作业世界"
    return desc
end

function CreateWorldLoadingPgae.GetDesc2()
    local desc = CreateWorldLoadingPgae.desc_list.desc2 or ""
    return desc
end

function CreateWorldLoadingPgae.PlayLoadingAnim()
    -- for index = 1, 6 do
    --     local icon_node = page:FindControl("block_icon_" .. index)
    --     if icon_node and icon_node:IsValid() then
    --         icon_node.visible = false
    --     end
    -- end

    local show_index = 1
    local all_times = 1
    local max_num = 6

    if not CreateWorldLoadingPgae.anim_timer then
        CreateWorldLoadingPgae.anim_timer = commonlib.Timer:new({callbackFunc = function(timer)
            local flag = all_times > max_num    
            if all_times > max_num then       
                if CreateWorldLoadingPgae.SpecialFlag ~= nil then
                    if CreateWorldLoadingPgae.SpecialFlag then
                        CreateWorldLoadingPgae.LoadingEnd()
                        return
                    end
                else
                    CreateWorldLoadingPgae.LoadingEnd()
                    return
                end

                if show_index > max_num then
                    show_index = 1
                    for index = 1, max_num do
                        local icon_node = page:FindControl("block_icon_" .. index)
                        if icon_node and icon_node:IsValid() then
                            icon_node.visible = false
                        end
                    end
                end
            end

            local icon_node = page:FindControl("block_icon_" .. show_index)
            if icon_node and icon_node:IsValid() then
                icon_node.visible = true
            end
    
            show_index = show_index + 1
            all_times = all_times + 1
        end})
    end

    CreateWorldLoadingPgae.anim_timer:Change(500,500);
end

function CreateWorldLoadingPgae.LoadingEnd()
    if CreateWorldLoadingPgae.anim_timer then
        CreateWorldLoadingPgae.anim_timer:Change(nil)
        CreateWorldLoadingPgae.anim_timer=nil
    end

    if CreateWorldLoadingPgae.callback then
        CreateWorldLoadingPgae.callback()
    end

    CreateWorldLoadingPgae.CloseView()
end

function CreateWorldLoadingPgae.SetSpecialFlag(flag)
    CreateWorldLoadingPgae.SpecialFlag = flag
end