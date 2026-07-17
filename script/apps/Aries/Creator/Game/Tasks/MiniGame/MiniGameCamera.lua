--[[
    author: pbb
    date: 2025-10-21
    useLib: 
        local MiniGameCamera = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameCamera.lua")
        MiniGameCamera.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
local Screen = commonlib.gettable('System.Windows.Screen')
local MiniGameCamera = NPL.export()
local page 
function MiniGameCamera.OnInit()
    page = document:GetPageCtrl()
end

function MiniGameCamera.ShowPage()
    local view_width = 760
    local view_height = 540
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameCamera.html",
        name = "MiniGameCamera.ShowPage",
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = true,
        enable_esc_key = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 0,
        directPosition = true,
        click_through = true,
        align = "_ct",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
    }
    
    System.App.Commands.Call("File.MCMLWindowFrame", params)
end

function MiniGameCamera.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function MiniGameCamera.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function MiniGameCamera.OnClickStartShot()
    GameLogic.AddBBS(nil, L"开始拍摄",1500)
    commonlib.TimerManager.SetTimeout(function()
        GameLogic.RunCommand("/hide ui")
        GameLogic.RunCommand("/hide tips")
        MiniGameCamera.TakeScreenShot("MiniGameShot_"..os.date("%Y%m%d%H%M"))
    end, 2000)
end

function MiniGameCamera.TransformShotToGallery(filepath)
    local filepath = filepath or ""
    if (System.os.GetPlatform() == "android" or System.os.GetPlatform() == "ios") then
        local file = ParaIO.open(filepath, "r")
        if not file then
            return
        end
        local fileData = file:GetText(0,-1)
        local base64Data = System.Encoding.base64(fileData)
        local currentTag = EasyEditableWorld.GetCurrentTag() or "MiniGame"
        local msg = {
            paraFilePath = currentTag.."_image"..os.date("%Y%m%d%H%M")..".jpg",
            base64 = base64Data,
        }
        local jsonStr = commonlib.Json.Encode(msg)
        ParaEngine.GetAttributeObject():SetField("SaveImageToGallery", jsonStr);
        return
    end
    if not ParaIO.DoesFileExist(filepath) then
        LOG.std(nil, "error", "MiniGameCamera", "TransformShotToGallery file not exist: %s", filepath)
        return
    end
    _guihelper.MessageBox(string.format(L"拍摄已完成，是否打开目录%s？", filepath), function(res)
        if(res and res == _guihelper.DialogResult.Yes) then
            Map3DSystem.App.Commands.Call('File.WinExplorer',{
                filepath = filepath,
                silentmode = true
            });  
        end
    end, _guihelper.MessageBoxButtons.YesNo);
end

function MiniGameCamera.TakeScreenShot(name, _width, _height)
    local rootPath = MiniGameCamera.GetRootPath()
    if not rootPath then
        return
    end
    local base_height = 720
    local screen_height = Screen:GetHeight()
    local screen_width = Screen:GetWidth()
    local scale = screen_height / base_height
    local width = math.floor(screen_width / scale)
    local height = base_height
    local filepath = string.format("%sScreen Shots/%s.jpg", rootPath, name)
    ParaMovie.TakeScreenShot(filepath, width, height)
    GameLogic.AddBBS(nil, L"拍摄完成", 1000)
    GameLogic.RunCommand("/show ui")
    GameLogic.RunCommand("/show tips")
    commonlib.TimerManager.SetTimeout(function()
        MiniGameCamera.TransformShotToGallery(filepath)
    end, 1000)
end

function MiniGameCamera.GetRootPath()
    if MiniGameCamera.rootPath then
        return MiniGameCamera.rootPath
    end
    local rootPath = ""
    if System.os.GetExternalStoragePath() ~= "" then
        rootPath = System.os.GetExternalStoragePath() .. "paracraft/"
    else
        rootPath = ParaIO.GetWritablePath()
    end
    MiniGameCamera.rootPath = rootPath
    return rootPath
end
