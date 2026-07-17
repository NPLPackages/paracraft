--[[
use the lib:
------------------------------------------------------------
local ShareWorld = NPL.load('(gl)script/apps/Aries/Creator/Game/Educate/Other/ShareWorld.lua')
ShareWorld.ShowPage()
-------------------------------------------------------
]]
NPL.load('(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua')
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local SnapshotPage = commonlib.gettable('MyCompany.Apps.ScreenShot.SnapshotPage')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local ShareWorld = NPL.export()

local page

function ShareWorld.OnInit()
    page = document:GetPageCtrl()
end

function ShareWorld.ShowPage()
    local func = function()
        local worldname = GameLogic.GetWorldDirectory():match("([^/\\]+)$")
        if not worldname then
            worldname = WorldCommon.GetWorldTag("name")
        end
        local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get','world/currentEnterWorld') 
        if not currentEnterWorld then
            KeepworkServiceProject:GetProjectIdByWorldName(
                worldname,
                false,
                function()
                    Compare:GetCurrentWorldInfo(
                        function()
                            Compare:Init(GameLogic.GetWorldDirectory(), function(result)
                                if result then
                                    ShareWorld.ShowView()
                                end
                            end)
                        end
                    )
                end
            )
            return
        end
        if GameLogic.IsReadOnly() or currentEnterWorld.is_zip then
            --ShareWorld:ShowWorldCode(currentEnterWorld.kpProjectId)
            return
        end
        KeepworkServiceProject:GetProjectIdByWorldName(
                currentEnterWorld.foldername,
                currentEnterWorld.shared,
                function()
                    Compare:GetCurrentWorldInfo(
                        function()
                            Compare:Init(currentEnterWorld.worldpath, function(result)
                                if result then
                                    ShareWorld.ShowView()
                                end
                            end)
                        end
                    )
                end
            )
    end

    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        func()
        return
    end
    
    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                func()
            end, 1000)
        end
    end)
end

function ShareWorld.ShowView()
    local view_width = 640
    local view_height = 380
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/Other/ShareWorld.html",
        name = "ShareWorld.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        -- DesignResolutionWidth = 1280,
		-- DesignResolutionHeight = 720,
        align = "_ct",
            width = view_width,
            height = view_height,
            x = -view_width/2,
            y = -view_height/2,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    if params._page then
        local filePath = ShareWorld:GetPreviewImagePath()
        if ParaIO.DoesFileExist(filePath) then
            params._page:SetUIValue('share_world_image', filePath)
        else
            params._page:SetUIValue('share_world_image', 'Texture/Aries/Creator/paracraft/konbaitu_266x134_x2_32bits.png# 0 0 532 268')
        end
    end
end

function ShareWorld:ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function ShareWorld:GetWorldSize()
    local worldpath = ParaWorld.GetWorldDirectory()

    if not worldpath then
        return 0
    end

    local filesTotal = LocalService:GetWorldSize(worldpath)

    return Mod.WorldShare.Utils.FormatFileSize(filesTotal),filesTotal
end

function ShareWorld:GetRemoteRevision()
    return tonumber(GameLogic.GetFilters():apply_filters('store_get','world/remoteRevision')) or 0
end

function ShareWorld:GetCurrentRevision()
    return tonumber(GameLogic.GetFilters():apply_filters('store_get','world/currentRevision')) or 0 
end

function ShareWorld:OnClick()
    local canBeShare = true
    local msg = ''

    if WorldCommon:IsModified() then
        canBeShare = false
        msg = L'当前世界未保存，是否继续上传世界？'
    end

    if canBeShare and self:GetRemoteRevision() > self:GetCurrentRevision() then
        canBeShare = false
        msg = L'当前本地版本小于远程版本，是否继续上传？'
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if not LocalServiceWorld:CheckWorldIsCorrect(currentEnterWorld) then
        local worldConfig = [[
-- Auto generated by ParaEngine 
type = lattice
TileSize = 533.333313
([0-63],[0-63]) = %WORLD%/flat.txt
        ]]

        local worldConfigFile = ParaIO.open(currentEnterWorld.worldpath .. '/worldconfig.txt', 'w')

        worldConfigFile:write(worldConfig, #worldConfig)
        worldConfigFile:close()
    end

    self:SyncWorld()
end

function ShareWorld:ShowWorldCode(projectId)
    Mod.WorldShare.MsgBox:Wait()

    KeepworkServiceProject:GenerateMiniProgramCode(
        projectId,
        function(bSucceed, wxacode)
            Mod.WorldShare.MsgBox:Close()

            if not bSucceed then
                GameLogic.AddBBS(nil, L'生成二维码失败', 3000, '255 0 0')
                return
            end

            Mod.WorldShare.Utils.ShowWindow(
                520,
                305,
                'Mod/WorldShare/cellar/ShareWorld/Code.html?wxacode='.. (wxacode or ''),
                'Mod.WorldShare.ShareWorld.Code',nil,nil,nil,nil,10
            )
        end
    )
end

function ShareWorld:TakeSharePageImage()
    if SnapshotPage.TakeSnapshot(
        self:GetPreviewImagePath(),
        300,
        200,
        false
       ) then
        self:UpdateImage(true)
    end
end

function ShareWorld:Snapshot()
    -- take a new screenshot
    self:TakeSharePageImage()

    GameLogic.RunCommand('/save')
end

function ShareWorld:UpdateImage(bRefreshAsset)
    if page then
        local filePath = self:GetPreviewImagePath()

        page:SetUIValue('share_world_image', filePath)

        -- release asset
        if bRefreshAsset then
            ParaAsset.LoadTexture('', filePath, 1):UnloadAsset()
        end
    end
end

function ShareWorld:GetPreviewImagePath()
    if not ParaWorld.GetWorldDirectory() then
        return ''
    end

    if System.os.GetPlatform() ~= 'win32' then
        return ParaIO.GetWritablePath() .. ParaWorld.GetWorldDirectory() .. 'preview.jpg'
    else
        return ParaWorld.GetWorldDirectory() .. 'preview.jpg'
    end
end

function ShareWorld:GetWorldName()
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get','world/currentEnterWorld') or {}

    return currentEnterWorld.text or ''
end


function ShareWorld:SyncWorld(callback,syncType)
    if GameLogic.IsReadOnly() then
        self.callback = nil
        GameLogic.AddBBS(nil, L'当前世界为只读世界，无法保存上传')
        return
    end
    self.callback = callback
    self:CheckCanUpload(function()
        local revision = GameLogic.options:GetRevision()
        local current_revision = Mod.WorldShare.Store:Get('world/currentRevision')
        if current_revision and revision and current_revision ~= revision then
            Mod.WorldShare.Store:Set('world/currentRevision', revision)
        end
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
        if not currentEnterWorld then
            GameLogic.AddBBS(nil, L'当前世界数据异常，无法上传')
            return 
        end
        if not Compare:IsMineWorld(currentEnterWorld) and not Compare:IsSharedToMe(currentEnterWorld) then
            self.callback = nil
            GameLogic.AddBBS(nil, L'当前世界不是你创建的或没有共享给你，暂时无法上传')
            return
        end
        Mod.WorldShare.Store:Set('world/currentWorld', currentEnterWorld)
        SyncWorld:CheckTagName(function()
            SyncWorld:SyncToDataSource(
                function(result, msg)
                    Compare:GetCurrentWorldInfo(function()
                        if type(self.callback) == 'function' then
                            self.callback(true)
                        end
                    end)
                end
            ) 
            self:ClosePage()
        end)
    end,syncType)
end

function ShareWorld:SyncWorldNoUI(callback)
    self:CheckCanUpload(function()
        local version = GameLogic.options:GetRevision()
        local world_data = Mod.WorldShare.Store:Get('world/currentEnterWorld')
        if not world_data then
            world_data = Mod.WorldShare.Store:Get('world/currentWorld')
        end
        local curProjectId = world_data and world_data.kpProjectId
        Mod.WorldShare.Store:Set('world/currentRevision', version or 1)
        GameLogic.AddBBS(nil,"正在保存世界")
        if curProjectId and tonumber(curProjectId) and tonumber(curProjectId) > 0 then
            GameLogic.GetFilters():apply_filters(
                'service.keepwork_service_world.set_world_instance_by_pid',
                tonumber(curProjectId),
                function()
                    GameLogic.GetFilters():apply_filters(
                        'service.sync_to_data_source.init',
                        function(result, option)
                            if option.method == 'UPDATE-PROGRESS-FINISH' then
                                GameLogic.AddBBS(nil,"保存世界成功")
                                self:ClosePage()
                                if callback then
                                    callback(true)
                                end
                            end
                        end)
                end
            )
        else
            GameLogic.GetFilters():apply_filters(
                'service.sync_to_data_source.init',
                function(result, option)
                    if option.method == 'UPDATE-PROGRESS-FINISH' then
                        GameLogic.AddBBS(nil,"保存世界成功")
                        self:ClosePage()
                        if callback then
                            callback(true)
                        end
                    end
                end)
        end
    end)
end


function ShareWorld:CheckCanUpload(callback,synctype)
    local _,world_size = self:GetWorldSize()
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get','world/currentEnterWorld') or {}
    local kpProjectId = currentEnterWorld.kpProjectId or 0
    local params = {}
    if kpProjectId and kpProjectId > 0 then
        if not System.options.isPapaAdventure then
            params.projectId = kpProjectId
        end
    end
    params.fileSize = world_size
    local maxSize = GameLogic.IsVip('LimitWorldSize20Mb',false) == true and 50*1024*1024 or 20*1024*1024
    keepwork.world.checkupload(params,function(err,msg,data)
        if System.options.isDevMode then
            print("err=========",err)
            print("maxsize====",maxSize,type(maxSize),world_size,type(world_size))
            echo(data)
        end
        if err == 200 and data == true then
            if callback then
                callback()
            end
        elseif err == 401 then
            GameLogic.GetFilters():apply_filters('logout')
            GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
            GameLogic.CheckSignedIn(L"请先登录", function(result)
                if result then
                    self:CheckCanUpload(callback,synctype)
                else
                    self:ExitWorld(synctype,true)
                end
            end)
        else
            GameLogic.QuickSave()
            self:ExitWorld(synctype)
        end
    end)
end

function ShareWorld:ExitWorld(synctype,bIgnoreLogin)
    local text = bIgnoreLogin and L"登录失败，您将无法保存对该世界的修改" or L"在线存储空间不足，您将无法保存对该世界的修改" 
    if synctype and synctype == "exit_world" then
        _guihelper.MessageBox(text, function(res)
            if res and res == _guihelper.DialogResult.OK then
                local WorldExitDialog = NPL.load('Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
                WorldExitDialog.OnDialogResult(_guihelper.DialogResult.No)
            end
        end,_guihelper.MessageBoxButtons.OKCancel_CustomLabel,nil, nil, nil, nil, {ok=L"直接退出"})
        return
    end
    _guihelper.MessageBox(text)
end
