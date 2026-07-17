--[[
    author:{pbb}
    time:2023-02-22 13:19:07
    uselib:
        local EducateProjectManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProjectManager.lua")
    params: 用来做本地世界自动备份的
]]
local ShareWorld = NPL.load('(gl)script/apps/Aries/Creator/Game/Educate/Other/ShareWorld.lua')
local EducateProjectManager = NPL.export()
EducateProjectManager.BackTimer = nil
EducateProjectManager.BackWorldPath = "temp/backworlds/"
EducateProjectManager.CurrentCreateWorldName = ""

EducateProjectManager.IsWorldLoaded = false
EducateProjectManager.IsSwfLoadingFinished = false

function EducateProjectManager.Init()
    EducateProjectManager.BackTimer = nil
    EducateProjectManager.CurrentCreateWorldName = ""
    EducateProjectManager.IsWorldLoaded = false
    EducateProjectManager.IsSwfLoadingFinished = false
    EducateProjectManager.RegisterEvent()
end

function EducateProjectManager.GetCurWorldDirectory()
    return GameLogic.GetWorldDirectory()
end

function EducateProjectManager.GetUserWorldDirectory()
    local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
    return LocalServiceWorld:GetUserFolderPath()
end

function EducateProjectManager.RegisterEvent()   
    GameLogic:Disconnect("WorldLoaded", EducateProjectManager, EducateProjectManager.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldLoaded", EducateProjectManager, EducateProjectManager.OnWorldLoaded, "UniqueConnection");

    GameLogic.GetEvents():RemoveEventListener("createworld_callback",EducateProjectManager.CreateWorldCallback, EducateProjectManager, "EducateProjectManager")
    GameLogic.GetEvents():AddEventListener("createworld_callback", EducateProjectManager.CreateWorldCallback, EducateProjectManager, "EducateProjectManager");

    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  EducateProjectManager.OnLoadingProgressFinish);
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page", EducateProjectManager.OnLoadingProgressFinish);

    GameLogic.GetFilters():add_filter("OnWorldCreate",  function(worldPath)
        EducateProjectManager.CurrentCreateWorldName = worldPath
        return worldPath
    end)
end

function EducateProjectManager.CreateWorldCallback(_, event)
    local worldPath = commonlib.Encoding.DefaultToUtf8(event.world_path)
    local paths = commonlib.split(worldPath,"/")
    local worldName = paths[#paths]
    if worldName and worldName ~= "" then
        EducateProjectManager.CurrentCreateWorldName = worldName
    end
end

function EducateProjectManager.OnLoadingProgressFinish()
    EducateProjectManager.IsSwfLoadingFinished = true
    EducateProjectManager.StartSycUserWorld()
end

function EducateProjectManager:OnWorldLoaded()
    EducateProjectManager.IsWorldLoaded = true
    EducateProjectManager.StartSycUserWorld()
end

function EducateProjectManager.StartSycUserWorld()
    if not EducateProjectManager.IsSwfLoadingFinished or not EducateProjectManager.IsWorldLoaded then
        return
    end
    print("EducateProjectManager.CurrentCreateWorldName===============",EducateProjectManager.CurrentCreateWorldName)
    if System.options.isEducatePlatform then
        if not System.options.isOffline then
            if EducateProjectManager.CurrentCreateWorldName and EducateProjectManager.CurrentCreateWorldName ~= "" then
                GameLogic.AddBBS(nil,"世界创建成功，开始自动保存世界")
                GameLogic.QuickSave();
                ShareWorld:SyncWorld(function()
                    EducateProjectManager.CurrentCreateWorldName = ""
                    EducateProjectManager.IsWorldLoaded = false
                    EducateProjectManager.IsSwfLoadingFinished = false
                    GameLogic.AddBBS(nil,"世界保存成功")
                end)
            end
        else
            EducateProjectManager.IsWorldLoaded = false
            EducateProjectManager.IsSwfLoadingFinished = false
            EducateProjectManager.CurrentCreateWorldName = ""
        end
        
        if GameLogic.IsReadOnly() then
            return
        end
        --开始自动保存
        if System.options.isDevMode then
            GameLogic.AddBBS(nil,"开启世界自动保存")
        end
        GameLogic.CreateGetAutoSaver():SetCheckModified()
        GameLogic.CreateGetAutoSaver():SetSaveMode();
        GameLogic.CreateGetAutoSaver():SetInterval(2);
    end
   
end



--下面的代码暂时没用
--------------------------------------------------------------
--分享世界结束以后也需要停止备份
function EducateProjectManager.OnSyncWorldFinish()
    -- EducateProjectManager.StopBackUserworld()
    -- EducateProjectManager.ResetUserWorld() 
end

function EducateProjectManager:OnWorldUnloaded()
    EducateProjectManager.StopBackUserworld()
    EducateProjectManager.DeleteUserWorldsLocal()
end

function EducateProjectManager.GetWorldBackPath()
    local username = GameLogic.GetFilters():apply_filters('store_get','user/username')
    if username and username ~= "" then
        return EducateProjectManager.BackWorldPath..username.."/"
    end
end

--判断是否有需要恢复的世界
function EducateProjectManager.CheckResumeUserWorld()
    local tempPath = EducateProjectManager.GetWorldBackPath()
    if not tempPath or tempPath == "" then
        return false
    end
    local outFiles = commonlib.Files.Find({},tempPath,0,1000)
    if outFiles and #outFiles > 0 then
        return true,outFiles
    end
    return false
end

-- 恢复世界，从临时目录中拷贝世界到用户目录，并且进入世界
function EducateProjectManager.ResumeUserWorld()
    local bCanResume,files = EducateProjectManager.CheckResumeUserWorld()
    if bCanResume and files and #files > 0 then
        local copyFolderNames = {}
        for key, item in ipairs(files) do
            if item.fileattr == 16 then --folder
                copyFolderNames[#copyFolderNames + 1] = item.filename
            end
        end
        if #copyFolderNames > 0 then
            for i=1,#copyFolderNames do
                local folderName = copyFolderNames[i]
                local srcPath = EducateProjectManager.GetWorldBackPath()..folderName
                local dstPath = EducateProjectManager.GetUserWorldDirectory().."/"..folderName
                commonlib.Files.CopyFolder(srcPath, dstPath)

                commonlib.TimerManager.SetTimeout(function()
                    print("进入备份的世界")
                    -- GameLogic.RunCommand(string.format('/loadworld %s', commonlib.Encoding.DefaultToUtf8(dstPath)))
                end, 10)
                break
            end
        end

        EducateProjectManager.DeleteUserWorldBacks()
    end
end

--上传以后，去除备份目录下的临时存档，停止临时自动存档逻辑
function EducateProjectManager.ResetUserWorld() 
    if EducateProjectManager.CurrentCreateWorldName and EducateProjectManager.CurrentCreateWorldName ~= "" then
        local tempPath = EducateProjectManager.GetWorldBackPath()..EducateProjectManager.CurrentCreateWorldName
        print("ResetUserWorld=============",tempPath)
        commonlib.Files.DeleteFolder(tempPath)
        EducateProjectManager.CurrentCreateWorldName = ""
    end
end


function EducateProjectManager.StartBackUserWorld()
    if EducateProjectManager.CurrentCreateWorldName and EducateProjectManager.CurrentCreateWorldName ~= "" then
        local time = 20*1000--60*60*1000
        local worldPath = EducateProjectManager.GetCurWorldDirectory()
        local path = EducateProjectManager.GetUserWorldDirectory().."/"..EducateProjectManager.CurrentCreateWorldName
        EducateProjectManager.BackTimer = EducateProjectManager.BackTimer or commonlib.Timer:new({callbackFunc = function(timer)
            if ParaIO.DoesFileExist(path .. '/tag.xml', false) then --这个世界创建成功
                local backPath = EducateProjectManager.GetWorldBackPath()
                if backPath and backPath ~= "" then
                    local dstPath = backPath..EducateProjectManager.CurrentCreateWorldName
                    commonlib.Files.CopyFolder(path, dstPath)
                end
            end
        end})
        EducateProjectManager.BackTimer:Change(0, time);
    end
end

function EducateProjectManager.StopBackUserworld()
    if EducateProjectManager.BackTimer then
        EducateProjectManager.BackTimer:Change()
        EducateProjectManager.BackTimer = nil
    end
end

function EducateProjectManager.DeleteUserWorldBacks()
    local bCanResume,files = EducateProjectManager.CheckResumeUserWorld()
    if bCanResume and files and #files > 0 then
        local copyFolderNames = {}
        for key, item in ipairs(files) do
            if item.fileattr == 16 then --folder
                copyFolderNames[#copyFolderNames + 1] = item.filename
            end
        end
        if #copyFolderNames > 0 then
            for i=1,#copyFolderNames do
                local folderName = copyFolderNames[i]
                local tempPath = EducateProjectManager.GetWorldBackPath()..folderName
                commonlib.Files.DeleteFolder(tempPath)
            end
        end
    end
end

-- 如果用户强行退出，则删除用户本地的世界,只删除431渠道的
function EducateProjectManager.DeleteUserWorldsLocal()
    if EducateProjectManager.CurrentCreateWorldName and EducateProjectManager.CurrentCreateWorldName ~= "" then
        local worldPath = EducateProjectManager.GetCurWorldDirectory()
        local path = EducateProjectManager.GetUserWorldDirectory().."/"..EducateProjectManager.CurrentCreateWorldName
        if ParaIO.DoesFileExist(path .. '/tag.xml', false) then
            commonlib.Files.DeleteFolder(path)
        end
        EducateProjectManager.CurrentCreateWorldName = ""

        -- EducateProjectManager.DeleteUserWorldBacks()
    end
end

