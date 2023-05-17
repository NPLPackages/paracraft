--[[
Title: CreateWorldLoadingPage
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
local CreateWorldLoadingPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/CreateWorldLoadingPage.lua")
CreateWorldLoadingPage.ShowView();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local CreateWorldLoadingPage = NPL.export();

local server_time = 0
local page
function CreateWorldLoadingPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = CreateWorldLoadingPage.OnClose
end

function CreateWorldLoadingPage.ShowView(callback, desc_list)
    if page and page:IsVisible() then
        return
    end
    CreateWorldLoadingPage.SpecialFlag = nil
    CreateWorldLoadingPage.desc_list = desc_list or {}
    CreateWorldLoadingPage.callback = callback
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/CreateWorldLoadingPage.html",
        name = "CreateWorldLoadingPage.Show", 
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

    CreateWorldLoadingPage.PlayLoadingAnim()
end

function CreateWorldLoadingPage.IsOpen()
    if page and page:IsVisible() then
        return true
    end

    return false
end

function CreateWorldLoadingPage.FreshView()
    local parent  = page:GetParentUIObject()
end

function CreateWorldLoadingPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    CreateWorldLoadingPage.FreshView()
end

function CreateWorldLoadingPage.CloseView()
    if(page)then
        page:CloseWindow(0);
        page = nil
    end
end

function CreateWorldLoadingPage.OnClose()
    CreateWorldLoadingPage.ClearData()
end

function CreateWorldLoadingPage.ClearData()
    CreateWorldLoadingPage.SpecialFlag = nil
    if CreateWorldLoadingPage.anim_timer then
        CreateWorldLoadingPage.anim_timer:Change(nil)
        CreateWorldLoadingPage.anim_timer=nil
    end
end

function CreateWorldLoadingPage.GetDesc1()
    local desc = CreateWorldLoadingPage.desc_list.desc1 or "正在为你创建超平坦地形作业世界"
    return desc
end

function CreateWorldLoadingPage.GetDesc2()
    local desc = CreateWorldLoadingPage.desc_list.desc2 or ""
    return desc
end

function CreateWorldLoadingPage.PlayLoadingAnim()
    -- for index = 1, 6 do
    --     local icon_node = page:FindControl("block_icon_" .. index)
    --     if icon_node and icon_node:IsValid() then
    --         icon_node.visible = false
    --     end
    -- end

    local show_index = 1
    local all_times = 1
    local max_num = 6

    if not CreateWorldLoadingPage.anim_timer then
        CreateWorldLoadingPage.anim_timer = commonlib.Timer:new({callbackFunc = function(timer)
            local flag = all_times > max_num    
            if all_times > max_num then       
                if CreateWorldLoadingPage.SpecialFlag ~= nil then
                    if CreateWorldLoadingPage.SpecialFlag then
                        CreateWorldLoadingPage.LoadingEnd()
                        return
                    end
                else
                    CreateWorldLoadingPage.LoadingEnd()
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

    CreateWorldLoadingPage.anim_timer:Change(500,500);
end

function CreateWorldLoadingPage.LoadingEnd()
    if CreateWorldLoadingPage.anim_timer then
        CreateWorldLoadingPage.anim_timer:Change(nil)
        CreateWorldLoadingPage.anim_timer=nil
    end

    if CreateWorldLoadingPage.callback then
        CreateWorldLoadingPage.callback()
    end

    CreateWorldLoadingPage.CloseView()
end

function CreateWorldLoadingPage.SetSpecialFlag(flag)
    CreateWorldLoadingPage.SpecialFlag = flag
end