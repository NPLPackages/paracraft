--[[
Title: 视频分享页
Author(s): hyz
Date: 2022/8/30
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingPage.lua");
local VideoSharingPage = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingPage");
VideoSharingPage.CheckShow();
-------------------------------------------------------
]]
NPL.load('(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua')
local SnapshotPage = commonlib.gettable('MyCompany.Apps.ScreenShot.SnapshotPage')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/KeepworkProjectsApi.lua')


NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua')
local VideoSharingUploadSuccessCode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingUploadSuccessCode.lua") 

local VideoSharingPage = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingPage");

local page;

function VideoSharingPage.OnInit()
	page = document:GetPageCtrl();
    page.OnClose = VideoSharingPage.OnClosed;
    page.OnCreate = VideoSharingPage.OnCreated;

end

function VideoSharingPage.OnCreated()

end

function VideoSharingPage.OnClosed()
    page = nil 
end

function VideoSharingPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function VideoSharingPage._ShowPage()
    -- icon="Texture/Aries/Creator/keepwork/Quest/biaoti_renwu2_32bits.png#0 0 128 64" help_type="task" 
    local params = {
        url = "script/apps/Aries/Creator/Game/Movie/VideoSharingPage.html", 
        name = "VideoSharingPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        -- DesignResolutionWidth = 1280,
        -- DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -652/2,
            y = -442/2,
            width = 652,
            height = 442,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    VideoSharingPage.refreshRemoteInfo()
end

function VideoSharingPage.CheckShow()
    if not (GameLogic.GetFilters():apply_filters('is_signed_in')) then
        GameLogic.CheckSignedIn()
        return
    end
    VideoSharingPage.currentWorldKeepworkInfo = nil
    VideoSharingPage.hasVideo = false
    VideoSharingPage.hasAutoVideo = false
    local userId = Mod.WorldShare.Store:Get('user/userId')
    local projectId = tonumber(WorldCommon.GetWorldTag("kpProjectId"))
    if projectId==nil or projectId==0 then
        _guihelper.MessageBox(L"您的世界没有上传，是否先上传", function(res)
            if(res and res == _guihelper.DialogResult.Yes)then -- SaveWorldPage.ShowSharePage
                GameLogic.RunCommand("/menu file.uploadworld");
            end
        end, _guihelper.MessageBoxButtons.YesNo);
    else
        KeepworkServiceProject:GetProject(tonumber(projectId), function(data)
            -- print("=======ssssssssssssssssss")
            -- echo(data,true)
            if data and data.world and data.world.worldName then
                VideoSharingPage.currentWorldKeepworkInfo = data
            end

            if VideoSharingPage.currentWorldKeepworkInfo.userId~=userId then
                GameLogic.AddBBS(nil,L"只能分享自己的世界")
            else
                local info = VideoSharingPage.currentWorldKeepworkInfo
                VideoSharingPage.bCheckdAutoVideo = not info.extra.cancelAutoGenVideo
                local hasPanorama = info and info.extra and info.extra.cubeMap and #info.extra.cubeMap==6;
                local hasVideo = info and info.extra and info.extra.video and info.extra.video~="";
                local hasAutoVideo = info and info.autoVideo and info.autoVideo.url and info.autoVideo.url~="";
                local hasWxacode = info and info.wxacode and info.wxacode~=""

                VideoSharingPage.hasPanorama = not (not hasPanorama)
                VideoSharingPage.hasVideo = not (not hasVideo)
                VideoSharingPage.hasAutoVideo = not (not hasAutoVideo)

                VideoSharingPage._ShowPage()
            end
        end)
    end
end

function VideoSharingPage.hasRemoteInfoLoaded()
    return VideoSharingPage.currentWorldKeepworkInfo~=nil
end

function VideoSharingPage.refreshRemoteInfo()
    local info = VideoSharingPage.currentWorldKeepworkInfo
    
    local userId = Mod.WorldShare.Store:Get('user/userId')
    if not GameLogic.IsReadOnly() and info.userId==userId then
        if page then
            page:SetUIValue('text_remoteVersion', L"在线版本："..(Mod.WorldShare.Store:Get('world/remoteRevision') or L'无'))
        end
    end
    
    if page then
        local node = page:GetNode("check_autovideo")
        if(node) then
            node:SetUIValue("checked",VideoSharingPage.bCheckdAutoVideo)
        end
    end

    local worldUrl = KeepworkService:GetShareUrl() or ""
    
    if page then
        if VideoSharingPage.hasPanorama then
            page:SetUIValue("btn_record_2",L"重新录制")
        end
        if VideoSharingPage.hasVideo then
            page:SetUIValue("btn_record_1",L"重新录制")
        end

        local img_qrcode = page:GetNode("img_qrcode")
        if img_qrcode then
            img_qrcode:SetUIValue("src",info.wxacode)
        end

        page:SetUIValue("share_text_url",worldUrl)
    end
end

function VideoSharingPage.Snapshot()
    if SnapshotPage.TakeSnapshot(
        ShareWorld:GetPreviewImagePath(),
        300,
        200,
        false
       ) then
        VideoSharingPage.UpdateImage(true)
    end
end

function VideoSharingPage.UpdateImage(bRefreshAsset)
    if page then
        local filepath = ShareWorld:GetPreviewImagePath()

        page:SetUIValue('ShareWorldImage', filepath)

        if bRefreshAsset then
            ParaAsset.LoadTexture('', filepath, 1):UnloadAsset()
        end

        -- increase version number
        -- GameLogic.QuickSave()
        GameLogic.world_revision:Commit(true)
        Mod.WorldShare.Store:Set('world/currentRevision',Mod.WorldShare.Store:Get('world/currentRevision') +1)
        VideoSharingPage.updateLocalVersion()
    end
end

function VideoSharingPage.updateLocalVersion()
    if page then
        page:SetUIValue('text_localVersion', L"在线版本："..(Mod.WorldShare.Store:Get('world/currentRevision') or L'无'))
    end
end

function VideoSharingPage.GetPreviewImagePath()
    return ParaWorld.GetWorldDirectory() .. 'preview.jpg'
end

function VideoSharingPage.on_check_autovideo()
    if page then
        local node = page:GetNode("check_autovideo")
        local params = {
            extra = {
                cancelAutoGenVideo = VideoSharingPage.bCheckdAutoVideo
            }
        }
        local projectId = tonumber(WorldCommon.GetWorldTag("kpProjectId"))
        KeepworkServiceProject:UpdateProject(projectId, params, function(data, err)
            if err ~= 200 then
                return
            end
            VideoSharingPage.bCheckdAutoVideo = not VideoSharingPage.bCheckdAutoVideo
            if(node) then
                node:SetUIValue("checked",VideoSharingPage.bCheckdAutoVideo)
            end
        end)
    end
end

function VideoSharingPage.on_btn_click(name,mcmlNode)
    local info = VideoSharingPage.currentWorldKeepworkInfo

    local shareUrl = KeepworkService:GetShareUrl()

    local projectId = tonumber(WorldCommon.GetWorldTag("kpProjectId"))
    local projectName = WorldCommon.GetWorldTag("name")

    if name=="btn_record_1" then
        VideoSharingPage.ClosePage()
        GameLogic.RunCommand("/share 20")
    elseif name=="btn_download_1" then
        local url = info.extra.video
        VideoSharingUploadSuccessCode.ShowView(url)
    elseif name=="btn_record_2" then
        GameLogic.RunCommand("/menu share.panoramasharing")
        VideoSharingPage.ClosePage()
    elseif name=="btn_download_3" then
        VideoSharingUploadSuccessCode.ShowView(info.autoVideo.url)
    elseif name=="btn_copy_link" then
        ParaMisc.CopyTextToClipboard(shareUrl)
        GameLogic.AddBBS(nil,L"已复制链接")
    elseif name=="btn_wechat" then
        local str = string.format("【项目ID:%s %s】%s",projectId,projectName,shareUrl)
        ParaMisc.CopyTextToClipboard(str)
        GameLogic.AddBBS(nil,L"已复制链接")
    elseif name=="btn_qq" then
        local str = string.format("【项目ID:%s %s】%s",projectId,projectName,shareUrl)
        ParaMisc.CopyTextToClipboard(str)
        GameLogic.AddBBS(nil,L"已复制链接")
    end
end

local do_modify = false
function VideoSharingPage.is_name_modified()
    return do_modify
end

function VideoSharingPage.on_click_modify_name()
    do_modify = true
    if(page) then
        page:Refresh(0)
    end
end 

function VideoSharingPage.on_click_save_name()
    local temp_modify_worldname = page:GetUIValue("input_name")
    -- 客户端处理铭感词
    local temp = MyCompany.Aries.Chat.BadWordFilter.FilterString(temp_modify_worldname);
    if temp~=temp_modify_worldname then 
        _guihelper.MessageBox(L"该世界名称不可用，请重新设定");
        return
    end
    -- print("temp_modify_worldname",temp_modify_worldname)
    --print("========ssssssss",temp,"原名",WorldCommon.GetWorldTag("name"))

    if temp=="" or temp==WorldCommon.GetWorldTag("name") then
        do_modify = false
        if(page) then
            page:Refresh(0)
        end
        return
    end
    
    -- update world name
    local param = {
        extra = {
            worldTagName = temp
        }
    }
    local projectId = tonumber(WorldCommon.GetWorldTag("kpProjectId"))
    GameLogic.world_revision:Commit(true)
    Mod.WorldShare.Store:Set('world/currentRevision',Mod.WorldShare.Store:Get('world/currentRevision') +1)
    -- local world not exist
    KeepworkProjectsApi:UpdateProject(
        projectId,
        param,
        function(data, err)
            print("------err",err)
            echo(data,true)
            if err ~= 200 then
                do_modify = false
                if(page) then
                    page:Refresh(0)
                end
                return
            end
            WorldCommon.SetWorldTag("name",temp)
            WorldCommon.SaveWorldTag()
            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
            if currentWorld then
                currentWorld.text = temp
                currentWorld.name = temp
            end
            do_modify = false
            if(page) then
                page:Refresh(0)
            end

            GameLogic.options:ResetWindowTitle()
            
            GameLogic.AddBBS(nil,L"世界名名称修改成功")
        end,
        function(err,errdata)
            if err and err.code==8 then
                _guihelper.MessageBox(err.message);
            end
            print("------err",err)
            echo(err,true)
        end
    )
end