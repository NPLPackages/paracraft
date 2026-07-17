--[[
Title: Convert To Web Mode
Author(s): big
CreateDate: 2022.9.15
Desc: 

use the lib:
------------------------------------------------------------
local ConvertToWebMode = NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/ConvertToWebMode/ConvertToWebMode.lua");
-------------------------------------------------------
]]

local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");
local VideoRecorderSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorderSettings");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local ConvertToWebMode = NPL.export();

ConvertToWebMode.isEditboxTriggerStarted = false;

function ConvertToWebMode:OnPlay(callback)
    if (not callback or type(callback) ~= "function") then
        return
    end

    if (Macros.GetHelpLevel() == -2) then 
        if (System.os.GetPlatform() ~= "win32") then
            _guihelper.MessageBox(L"暂时只支持windows系统");
            return;
        end

        local currentEnterWorld = GameLogic.GetFilters():apply_filters("store_get", "world/currentEnterWorld");

        if (not currentEnterWorld) then
            return;
        end

        self:VideoRecorderInit();
        self:StartComputeRecordTime();
        self:BeginCapture(function()
            Macros.SetAutoPlay(true)

            callback()
        end);
    else
        callback()
    end
end

local sequence = 1;
local recordTimes = 1;
local prefix = "sequence";

function ConvertToWebMode:VideoRecorderInit()
    sequence = 1;
    recordTimes = 1;
    prefix = "sequence";

    VideoRecorderSettings.SetPreset("mp4 720p");

    local currentEnterWorld = GameLogic.GetFilters():apply_filters("store_get", "world/currentEnterWorld");

    local foldername = currentEnterWorld.foldername or "";
    local renderFolder = "temp/macros_convert/" .. commonlib.Encoding.Utf8ToDefault(foldername) .. "/" .. recordTimes .. "/";

    local beExist = true;

    while (beExist) do
        if (not ParaIO.DoesFileExist(renderFolder)) then
            beExist = false;
        else
            recordTimes = recordTimes + 1;
            renderFolder = "temp/macros_convert/" .. commonlib.Encoding.Utf8ToDefault(foldername) .. "/" .. recordTimes .. "/";
        end
    end

    self.renderFolder = renderFolder;

    commonlib.Files.CreateDirectory(renderFolder);

    VideoRecorderSettings.SetOutputFloder(renderFolder);
    VideoRecorderSettings.SetOutputFilename(prefix .. "_" .. sequence);
    VideoRecorderSettings.SetMargin(0);
    VideoRecorderSettings.start_after_seconds = 0;
end

function ConvertToWebMode:BeginCapture(callback)
    if (self.isBegan) then
        if (callback and type(callback) == "function") then
            callback();
        end

        return;
    end

    self.isBegan = true;
    GameLogic.DockManager:HideAllDock();

	if (VideoRecorder.pluginNeedRestart) then
		_guihelper.MessageBox(L"插件安装完成, 需要重新启动客户端才能使用");
	elseif (VideoRecorder.HasFFmpegPlugin()) then
		VideoRecorder.BeginCaptureImp(function(result)
            sequence = sequence + 1;
            VideoRecorderSettings.SetOutputFilename(prefix .. "_" .. sequence);

            if (callback and type(callback) == "function") then
                callback();
            end
        end)
	elseif (VideoRecorder.HasFFmpegPlugin() == false) then
		_guihelper.MessageBox(L"视频输出插件没有加载成功，请检查是否有其它客户端在使用");
	else
		_guihelper.MessageBox(
            L"你没有安装最新版的视频输出插件, 是否现在安装？",
            function(res)
                if (res and res == _guihelper.DialogResult.Yes) then
                    _guihelper.MessageBox(L"正在安装, 请稍候...");

                    VideoRecorder.InstallPlugin(function(bSucceed)
                        if (bSucceed) then
                            _guihelper.MessageBox(nil);

                            if (not VideoRecorder.HasFFmpegPlugin()) then
                                VideoRecorder.pluginNeedRestart = true
                            end

                            ConvertToWebMode:BeginCapture(callbackFunc)
                        else
                            _guihelper.MessageBox(L"安装失败了");
                        end
                    end);
                end
		    end,
            _guihelper.MessageBoxButtons.YesNo
        );
	end
end

function ConvertToWebMode:StopCapture()
    self.isBegan = false;

    VideoRecorder.EndCapture()
end

function ConvertToWebMode:GenerateMacroList()
    if (not Macros.macros or
        type(Macros.macros) ~= "table" or
        not self.renderFolder) then
        return;
    end

    local data = NPL.ToJson(Macros.macros);
    local fileName = self.renderFolder .. "macros.json";

    local writeFile = ParaIO.open(fileName, "w");

    if (writeFile:IsValid()) then
        writeFile:write(data, #data);
        writeFile:close();
    end
end

function ConvertToWebMode:StartPreview()
    NPL.load("(gl)script/apps/WebServer/WebServer.lua");
    WebServer:Start(self.renderFolder, "127.0.0.1", 8100);
end

local processTimer;

function ConvertToWebMode:StartComputeRecordTime()
    self.processTime = 0;

    if (processTimer) then
        processTimer:Change();
    end

    processTimer = commonlib.Timer:new({callbackFunc = function()
        self.processTime = self.processTime + 0.1;
    end});

    processTimer:Change(0, 100);
end

function ConvertToWebMode:StopComputeRecordTime()
    if (processTimer) then
        processTimer:Change();
    end
end

local duringTimer;

function ConvertToWebMode:StartComputeDuringTime()
    self.duringTime = 0;

    if (duringTimer) then
        duringTimer:Change();
    end

    duringTimer = commonlib.Timer:new({callbackFunc = function()
        self.duringTime = self.duringTime + 0.1;
    end});

    duringTimer:Change(0, 100);
end

function ConvertToWebMode:StopComputeDuringTime()
    if (duringTimer) then
        duringTimer:Change()
    end
end

function ConvertToWebMode:Locker(callback)
    if (Macros.GetHelpLevel() ~= -2 or
        not callback or
        type(callback) ~= "function") then
        return;
    end

    if (self.isUnlock) then
        callback(true);
        return;
    end

    local params = {
        url = "script/apps/Aries/Creator/Game/Macros/ConvertToWebMode/Locker.html",
        name = "MacroConvertToWebModeTask.Locker",
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = zorder or 0,
        allowDrag = allowDrag == nil and true or allowDrag,
        bShow = nil,
        directPosition = true,
        align = align or '_ct',
        x = -200,
        y = -75,
        width = 400,
        height = 150,
        cancelShowAnimation = true,
        bToggleShowHide = bToggleShowHide,
        click_through = clickThrough,
    }
    
    System.App.Commands.Call('File.MCMLWindowFrame', params)

    if (not params._page) then
        return;
    end

    params._page.c = "paraengine-paracraft-68017401-0c65-4ba5-a204-c4ca4b38ebf5";
    params._page.callbackFunc = function(r)
        if (not r) then
            _guihelper.MessageBox("wrong!");
            return;
        end

        self.isUnlock = true;
        NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
        local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
        DesktopMenuPage.Refresh();
        callback(r);
    end
end
