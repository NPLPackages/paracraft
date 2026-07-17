--[[
author:pbb
date:20240122
Desc:世界分享页面
use lib:
local WorldSharePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ShareWorld/WorldSharePage.lua") 
WorldSharePage.ShowView(data)
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local WorldSharePage = NPL.export()
local page
WorldSharePage.WorldData = nil
function WorldSharePage.OnInit()
    page = document:GetPageCtrl();
end

function WorldSharePage.ShowView(data)
    WorldSharePage.WorldData = data or {}
    local view_width = 0
    local view_height = 0
    local pageUrl = "script/apps/Aries/Creator/Game/Tasks/ShareWorld/WorldSharePage.html"
    if System.options.isEducatePlatform then
        pageUrl = "script/apps/Aries/Creator/Game/Tasks/ShareWorld/WorldSharePage.431.html"
    end
    if System.options.isCommunity then
        pageUrl = "script/apps/Aries/Creator/Game/Tasks/ShareWorld/CommunityWorldSharePage.html"
    end
    local params = {
        url = pageUrl,
        name = "WorldSharePage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_fi",
        zorder=9,
        isTopLevel=true,
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);   
    params._page.OnClose = function()
        WorldSharePage.OnClose()
    end
end

function WorldSharePage.OnClose()
    WorldSharePage.WorldData = nil
    WorldSharePage.share_link = nil
end

function WorldSharePage.GetShareLink()
    if not WorldSharePage.share_link then
        local http_env = HttpWrapper.GetDevVersion()
        if not http_env or http_env == "" then
            http_env = "ONLINE"
        end
        local baseUrl = "https://webparacraft.keepwork.com/ParaCraftSingleThread.html?"
        if http_env ~= "ONLINE" then
            baseUrl = "https://emscripten.keepwork.com//ParaCraftSingleThread.html?"
        end
        
        
        baseUrl = baseUrl .. "http_env=" .. http_env
        if System.options.isEducatePlatform then
            baseUrl = baseUrl .. "&channelId="..System.options.channelId
        end
        if WorldSharePage.WorldData then
            local kpProjectId = WorldSharePage.WorldData.kpProjectId
            if kpProjectId then
                baseUrl = baseUrl .. "&pid=" .. kpProjectId
            end
        end
        baseUrl = baseUrl .."&cmd=".. Mod.WorldShare.Utils.EncodeURIComponent("/hide quickselectbar")
        WorldSharePage.share_link = baseUrl
    end
    return WorldSharePage.share_link
end

function WorldSharePage.OnClickCopyLink()
    if not page then
        return 
    end
    
    local url = WorldSharePage.GetShareLink()
    ParaMisc.CopyTextToClipboard(url);
    GameLogic.AddBBS(nil,"链接已拷贝到剪贴板")
end
