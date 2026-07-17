--[[
    local WebImageFileDialog = NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/WebImageFileDialog.lua");
    WebImageFileDialog.Show(pageType, callback)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local WebImageFileDialog = NPL.export()
TYPE = {
    DOWN = 1,
    USE = 2,
    COMMUNITY = 3,
}
local httpwrapper_version = HttpWrapper.GetDevVersion();
local keepworkList = {
    ONLINE = 'https://keepwork.com',
    STAGE = 'http://keepwork-dev.kp-para.cn',
    RELEASE = 'http://rls.kp-para.cn',
}

local self = WebImageFileDialog;

function WebImageFileDialog.OnInit()

end

function WebImageFileDialog.Show(pageType, callback)
    if (GameLogic.GetFilters():apply_filters('is_signed_in')) then
        WebImageFileDialog.InitShow(pageType, callback)
        return;
    end

    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if (result == true) then
            commonlib.TimerManager.SetTimeout(function()
                WebImageFileDialog.InitShow(pageType, callback)
            end, 500)
        end
    end)
end

function WebImageFileDialog.InitShow(pageType, callback)
    self.pageType = pageType;
    self.callback = callback;
    self.browser_name = "image_nplbrowser_instance";
    local token = Mod.WorldShare.Store:Get("user/token")
    if not token or token == "" then
        GameLogic.AddBBS(nil,"登录异常，请重试")
        return 
    end
    local baseUrl = keepworkList[httpwrapper_version]
    local testUrl = "http://10.27.1.115:3001"
    local paramsUrl = "/cloudStorage?isVideoShow=0&isShareCloudShow=0&isApplicable=1&isNoMediaFileShow=0&src=paracraft&token="
    if self.pageType == TYPE.COMMUNITY then
        paramsUrl = "/cloudStorage?token="
    end
    local url = baseUrl..paramsUrl.. token
    WebImageFileDialog.ShowDialog(url)
end 

function WebImageFileDialog.GetTitle()
    if self.pageType == TYPE.COMMUNITY then
        return L"在线网盘"
    end
    return L"选择图片"
end

function WebImageFileDialog.ShowDialog(url)
    self.url = url;
    self.select_file_path = ""
    local view_width, view_height = 800,600
    local params = {
        url = "script/apps/Aries/Creator/Game/GUI/WebImageFileDialog.html",
        name = "WebImageFileDialog.ShowDialog", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder=11,
        cancelShowAnimation = true,
        directPosition = true,
            align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    if (params._page) then
        self.pageCtrl = params._page;
        params._page.OnClose = function()
            if self.callback then
                LOG.std(nil, "info", "WebImageFileDialog", "OnClose filename is %s", self.select_file_path);
                self.callback(self.select_file_path)
            end
        end
    end
end

function WebImageFileDialog.OnClose()
    if (self.pageCtrl) then
        self.pageCtrl:CloseWindow(true)
        self.pageCtrl = nil
    end
end

function WebImageFileDialog.OpenUrl(url)
    if self.pageCtrl then
        self.url = url;
        self.pageCtrl:CallMethod(self.browser_name, "Reload", self.url)
    end
end

function WebImageFileDialog.OnReceiveMessageFromWebView(msg)
    if not msg or type(msg) ~= "table" then
        return
    end
    local data = msg.msg
    if type(msg.msg) == "string" then
        data = commonlib.Json.Decode(msg.msg)
    end
    if msg.eventName and msg.eventName ~= "" then
        data.eventName = msg.eventName
    end
    LOG.std(nil,"info","WebImageFileDialog","OnReceiveMessageFromWebView file success ,fileData = %s",commonlib.serialize_compact(data))
    WebImageFileDialog.OnReceiveKeepWorkFile(data)
end

function WebImageFileDialog.OnReceiveKeepWorkFile(data)
    if not data or type(data) ~= "table" then
        return
    end
    local eventName = data.eventName
    local fileUrl = data.url
    if not fileUrl or fileUrl == "" then
        fileUrl = data.downloadUrl
    end
    if not fileUrl or fileUrl == "" then
        GameLogic.AddBBS(nil,"文件获取失败，请重试")
        return 
    end
    local fileName = data.filename
    local totalSize = data.file and data.file.size or 0
    local fileExt = data.ext
    local sizeStr = data.displaySize
    local params = {
        url = fileUrl,
        filename = fileName,
        fileExt = fileExt,
        totalSize = totalSize,
        sizeStr = sizeStr,
        eventName = eventName,
    }
    WebImageFileDialog.OnResolveFile(params)
end

function WebImageFileDialog.OnResolveFile(params)
    if not params or type(params) ~= "table" then
        return
    end
    local eventName = params.eventName
    if eventName == "DownloadKeepWorkFile" then
        WebImageFileDialog.OnDownloadFile(params)
    elseif eventName == "SelectKeepWorkFile" then
        WebImageFileDialog.OnSelectKeepWorkFile(params)
    end
end

function WebImageFileDialog.OnDownloadFile(params)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
    local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
    NPL.load("(gl)script/ide/System/localserver/factory.lua");
    local cache_policy = System.localserver.CachePolicy:new("access plus 1 days");
    local ls = System.localserver.CreateStore();
    if(not ls) then
        log("error: failed creating local server resource store \n")
        return
    end

    local destFile = GameLogic.GetWorldDirectory()..params.filename
    ls:GetFile(cache_policy, params.url, function(entry)
        if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
            if not ParaIO.DoesFileExist(destFile)  then
                ParaIO.CreateDirectory(destFile);
            end
            if(ParaIO.CopyFile(entry.payload.cached_filepath, destFile, true)) then
                Files.NotifyNetworkFileChange(destFile)
                self.select_file_path = destFile
                GameLogic.FlushDiskIO()
                self.OnClose()
                LOG.std(nil, "info", "WebImageFileDialog", "success to copy from %s to %s", entry.payload.cached_filepath, destFile);
            else
                LOG.std(nil, "info", "WebImageFileDialog", "failed to copy from %s to %s", entry.payload.cached_filepath, destFile);
            end
        end
    end)
end

function WebImageFileDialog.OnSelectKeepWorkFile(params)
    if self.pageType == TYPE.DOWN or self.pageType == TYPE.COMMUNITY then
        self.OnDownloadFile(params)
        return
    end
    if self.pageType == TYPE.USE then
        self.select_file_path = params.url
        self.OnClose()
    end
end

local function activate()
    local msg = NplBrowserPlugin.TranslateJsMessage(msg);
    WebImageFileDialog.OnReceiveMessageFromWebView(msg);
end

NPL.this(activate, {filename = "WebImageFileDialog.lua"})
