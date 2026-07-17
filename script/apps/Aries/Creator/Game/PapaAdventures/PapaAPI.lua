--[[
Title: Papa API with external webview
Author(s): PBB, LiXizhi, big
Date: 2023/4/2
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAPI.lua");
local PapaAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.PapaAPI");
-------------------------------------------------------
]] NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/ide/EventDispatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/Lessons/Creation.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");

local Creation = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Lessons.Creation");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local PapaUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaUtils.lua");
local PapaAPI = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),
    commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.PapaAPI"))

PapaAPI:Signal("displayModeChanged");
PapaAPI:Signal("onSaveFileChanged");

local self = PapaAPI

function PapaAPI:ctor()
    self.events = commonlib.EventSystem:new();
    self:RegisterEvent("setDisplayMode", function(msg)
        self:OnDisplayModeChange(msg and msg.mode)
    end)
    self:RegisterEvent("ExitApp", function(msg)
        self:OnExitApp()
    end)
    self:RegisterEvent("SetLoginInfo", function(msg)
        self:OnSetLoginInfo(msg)
    end)
    self:RegisterEvent("createLoadWorld", function(msg)
        self:OnCreateLoadWorld(msg)
    end)
    self:RegisterEvent("GetDeviceInfo", function(msg)
        self:GetDeviceInfo(msg)
    end)
    self:RegisterEvent("SetVoice", function(msg)
        self:SetVoice(msg)
    end)
    self:RegisterEvent("SetFullScreen", function(msg)
        self:SetFullScreen(msg)
    end)
    self:RegisterEvent("SetResolutionRatio", function(msg)
        self:SetResolutionRatio(msg)
    end)
    self:RegisterEvent("DeleteWorld", function(msg)
        local PapaWorldLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaWorldLogic.lua");
        PapaWorldLogic.DeleteWorld(msg)
    end)
    self:RegisterEvent("showSubmitPage", function(msg)
        Creation:ShowOpusSubmitPage();
    end);
    self:RegisterEvent("onSaveFile", function(msg)
        self:OnSaveFile(msg);
    end);
    self:RegisterEvent("updateVersion", function(msg)
        if System.os.GetPlatform() == "win32" then
            ParaGlobal.ShellExecute("open", System.options.launcherExeName or "ParaCraft.exe", "", "", 1);
            NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
            local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
            Desktop.ForceExit()
        else
            System.options.cmdline_world = nil
            MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
            MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
            MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
            MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
            MyCompany.Aries.Game.MainLogin:set_step({IsLoginModeSelected = true});
            MyCompany.Aries.Game.MainLogin:next_step({IsUpdaterStarted = false})
        end
    end)
    self:RegisterEvent("ExitWorld", function(msg)
        self:OnExitWorld(msg)
    end)
    self:RegisterEvent("SetWebVersion", function(msg)
        local version = msg and msg.version
        if version ~= "" then
            GameLogic.GetPlayerController():SaveLocalData("_papa_web_version_", version, true);
            MyCompany.Aries.Game.MainLogin:SetWindowTitle()
        end
    end);
    self:RegisterEvent("ClearCache",function(msg)
        GameLogic.RunCommand("/clearcache");
    end)
    self:RegisterEvent("GetWebStatus",function(msg)
        self:GetWebStatus(msg)
    end)  
    
    self:RegisterEvent("UserAgreement",function(msg)
        local platform = System.os.GetPlatform()
        local isTouchDevice = ParaEngine.GetAppCommandLineByParam('IsTouchDevice', nil);
        if platform == 'android' or platform == 'ios' or (isTouchDevice and isTouchDevice =='true') then
            NPL.load("(gl)script/ide/System/localserver/LocalStorageUtil.lua");
            local LocalStorageUtil = commonlib.gettable("System.localserver.LocalStorageUtil");
            local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
            local has_agree_userUserPrivacy = LocalStorageUtil.Load_localserver("has_agree_userUserPrivacy","false",true)
            if has_agree_userUserPrivacy=="false" then
                PlatformBridge.onAgreeUserPrivacy()
                LocalStorageUtil.Save_localserver("has_agree_userUserPrivacy","true",true)
                LocalStorageUtil.Flush_localserver()
            end
        end
    end)  
    self:RegisterEvent("SetEngineVersion",function(msg)
        self:SetEngineVersion(msg)
    end)
end

function PapaAPI:SetEngineVersion(msg) 
    self:SetDisplayMode("hide")
    local VersionSetting = NPL.load('(gl)script/apps/Aries/Creator/Game/Setting/VersionSetting.lua')
    VersionSetting.ShowPage()
end

function PapaAPI:GetWebStatus(msg)
    if msg and msg.callbackId then
        NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAdventuresMain.lua");
        local PapaAdventuresMain = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Main");
        local mode = PapaAdventuresMain:GetWebStatus()
        if mode then
            self:SendEvent("GetWebStatus",{callbackId = msg.callbackId,mode = mode})
        end
    end
end

function PapaAPI:Init(browser_name)
    self.browser_name = browser_name
    self.isCreateLoadWorld = false
    return self;
end

------------------------------------
-- API to send to webview 
------------------------------------

-- @param mode: "mini|ingame|max|hide"
function PapaAPI:SetDisplayMode(mode)
    PapaAPI:OnDisplayModeChange(mode);
end

function PapaAPI:NextStep(projectId,lessonType)
    local params = {projectId = projectId,lessonType = lessonType}
    self:SendEvent("nextStep", params);
end

function PapaAPI:CreateWorldInWorld()
    self:SetDisplayMode("show")
    self:SendEvent("CreateWorldInWorld", {});
end

    
function PapaAPI:AccountKickOut()
    self:ExitGame()
    self:SendEvent("AccountKickOut", {});
end

function PapaAPI:EnterVueHome()
    self:SendEvent("EnterVueHome", {});
end

function PapaAPI:EnterWorld()
    self:SendEvent("EnterWorld", {});
end

function PapaAPI:CloseAppWindow()
    self:SetDisplayMode("show")
    self:SendEvent("CloseAppWindow", {});
end

function PapaAPI:NplClickExitWorld()
    self:SendEvent("ClickExitWorld", {});
end

function PapaAPI:OpenMyWorks()
    self:SendEvent("OpenMyWorks", {});
end

function PapaAPI:SendWebLog(strLog)
    self:SendEvent("SendWebLog", {log=strLog});
end

function PapaAPI:SendSoftKeyboardStatus(status)
    self:SendEvent("SoftKeyboardStatus", {status=status}); --status 0 hide status 1 show
end

function PapaAPI:SendShowHomePage(username,id)
    local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
    local kpProjectId = WorldCommon.GetWorldTag("kpProjectId")
    self:SendEvent("ShowHomePage", {username=username,id=id,projectId=tonumber(kpProjectId or 0)});
end

function PapaAPI:ReportLesson()
    if not Creation or not Creation.curSection then
        return
    end
    NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
    local createTime = WorldCommon.GetWorldTag("totalEditSeconds") or 0;
    local buildCount = tonumber(WorldCommon.GetWorldTag("totalSingleBlocks")) - (self.blockNum or 0);
    local kpProjectId = WorldCommon.GetWorldTag("kpProjectId");
    local duration = (createTime - (self.startEditTime or 0))
    self:SendEvent("ReportLesson", {
        report={
            duration=duration,
            buildCount=buildCount,
            projectId=tonumber(kpProjectId or 0),
        }
    });
end
-----------------------------------
-- implement callbacks from webview
-----------------------------------

-- called when login info is set from the webview 
function PapaAPI:OnSetLoginInfo(loginInfo)
    if loginInfo then
        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua');
        loginInfo = PapaAPI.GetUrlDecodeData(loginInfo)
        KeepworkServiceSession:LoginResponse(loginInfo, 200, function(bSucceed, message)
            LOG.std("PapaAPI", "info", "profile from vue is ", commonlib.serialize_compact(loginInfo));
            PapaUtils.ReportLoginTime()
            PapaUtils.ReportDeviceInfo()
        end);
    end
end

function PapaAPI:CreateLoadWorldImp(msg)
    if self.isCreateLoadWorld then
        PapaAPI:SendEvent("CreateWorld",{callbackId = msg.callbackId,result = false,message = "同一时间重复进入世界"})
        return
    end
    self.isCreateLoadWorld = true
    if self.delayTimer then
        self.delayTimer:Change()
    end
    self.delayTimer = self.delayTimer or commonlib.Timer:new({callbackFunc = function(timer)
        self.isCreateLoadWorld = false
    end});
    self.delayTimer:Change(2000,nil)
    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    
    if msg.code then
        msg.code = commonlib.Encoding.url_decode(msg.code)
    end
    if msg.curSections and msg.curSections.contents then
        msg.curSections.contents = {}
    end
    msg = PapaAPI.GetUrlDecodeData(msg)
    LOG.std(nil, "info", "PapaAPI:OnCreateLoadWorld", "msg: %s", commonlib.serialize_compact(msg));
    local sendMsg = commonlib.copy(msg)
    sendMsg.code = "";
    if (msg.type == "lesson") then
        if (not msg or not msg.projectId or not msg.lessonId or not msg.curTask or not msg.curSections or
            not msg.curSection or not msg.scheduleId or not msg.classActivityId) then
            return;
        end

        Creation:SetCurData(msg.curTask, msg.curSections, msg.curSection, msg.classActivityId, msg.scheduleId, 1,msg.code,msg.hasNextStep,msg.submitType,msg.lessonType);
        if (not Creation.curSection or not Creation.curSection.content) then
            return;
        end
        Creation:RefreshNextStepStatus(function()
            if (Creation.page) then
                Creation.page:Refresh(0.01);
            end
        end);
        local callbackId = msg.callbackId
        if (msg.lessonType == 6) then
            if not callbackId then
                GameLogic.RunCommand("/loadworld -s -auto -lesson" .. msg.projectId);
                return 
            end
            local data = {callbackId = callbackId,world={type="tuijian",projectId=msg.projectId}}
            local PapaWorldLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaWorldLogic.lua");
            PapaWorldLogic.EnterWorld(data,true)
        elseif (msg.lessonType == 7) then
            if (Creation.curSection.content.content.homeworkType == 0) then
                Creation:LoadCreationWorld(callbackId);
            elseif (Creation.curSection.content.content.homeworkType == 1) then
                -- TODO: create plane world.
                Creation:LoadSuperFlatWorld(callbackId)
            end
        end
    else
        -- echo(msg,true)
        Creation:SetCurData()
        Creation.rejectEsc = false
        local PapaWorldLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaWorldLogic.lua");
        PapaWorldLogic.EnterWorld(msg)
    end
end

function PapaAPI:OnCreateLoadWorld(msg)
    local isSigned = GameLogic.GetFilters():apply_filters("is_signed_in")
    if isSigned then
        self:CreateLoadWorldImp(msg)
        return
    end
    local token = msg.token
    local callbackId = msg.callbackId
    if token and token ~= "" then
        local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
        MainLogin:LoginWithToken(token, function(bIsSuccessed, reason, message)
            if not bIsSuccessed then
                PapaAPI:SendEvent("CreateWorld",{callbackId = callbackId,result = false,message = reason})
                return
            end
            self:CreateLoadWorldImp(msg)
        end)
        return
    end
    PapaAPI:SendEvent("CreateWorld",{callbackId = callbackId,result = false,message = "重新帕拉卡登录创意空间失败，请联系老师"})
end

function PapaAPI.OnWorldLoaded()
    -- GameLogic:Disconnect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    Creation:Init();
end

function PapaAPI:OnSaveFile(msg)
    self:onSaveFileChanged(msg);
end

function PapaAPI:ExitGame()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
    local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
    CustomCharItems:Init();
    local Game = commonlib.gettable("MyCompany.Aries.Game")
    if(Game and Game.is_started) then
        Game.Exit()
    end
end

-- called when the webview has changed its display mode
function PapaAPI:OnDisplayModeChange(mode)
    -- TODO: fire signal and handle UI
    self:displayModeChanged(mode);
    -- notify display mode changed to PapaAPI.ts
    self:SendEvent("setDisplayMode", {
        mode = mode
    });
end

-- called when the webview wants to exit the app
function PapaAPI:OnExitApp()
    -- TODO: shut down NPL app
    NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
    local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
    Desktop.ForceExit()
end

-- called when the webview wants to get deviceInfo
function PapaAPI:GetDeviceInfo(data)
    PapaUtils.GetDeviceInfo(function(deviceInfo)
        if deviceInfo then
            data.deviceInfo = deviceInfo
            self:SendEvent("DeviceInfo", data)
        end
    end)
end

-- set voice true/false->on/off
function PapaAPI:SetVoice(data)
    echo(data)
    if data then
        local bOpen = data.voice == true or data.voice == "true"
        if (bOpen) then
            local key = "Paracraft_System_Sound_Volume"
            local sound_volume = Game.PlayerController:LoadLocalData(key, 1, true);
            if sound_volume <= 0 then
                sound_volume = 1
            end
            ParaAudio.SetVolume(sound_volume);
        else
            ParaAudio.SetVolume(0);
        end

        local key = "Paracraft_System_Sound_State";
        GameLogic.GetPlayerController():SaveLocalData(key, bOpen, true);
    end
end

-- set full screen true/false->full/not full
function PapaAPI:SetFullScreen(data)
    echo(data)
    if data then
        local bFullScreen = data.screen == true or data.screen == "true"
        local attr = ParaEngine.GetAttributeObject()
        attr:SetField("IsWindowMaximized", bFullScreen)
    end
end

-- set design resolution 1280*720 ....
function PapaAPI:SetResolutionRatio(data)
    if data then
        local attr = ParaEngine.GetAttributeObject()
        local x, y = string.match(data.ratio or "", "(%d+)%D+(%d+)");
        print(data.ratio, x, y)
        if x ~= nil and y ~= nil then
            x = tonumber(x)
            y = tonumber(y)
            if (x ~= nil and y ~= nil) then
                local size = {x, y};
                local oldsize = attr:GetField("ScreenResolution", {1020, 680});
                if (oldsize[1] ~= x or oldsize[2] ~= y) then
                    print("set field=========", x, y)
                    attr:SetField("ScreenResolution", size);
                    ParaEngine.GetAttributeObject():CallField("UpdateScreenMode");
                end
            end
        end
    end
end

function PapaAPI:OnExitWorld(msg)
    self.exitWorldMsg = msg
    local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
    local isHomeWorkWorld = WorldCommon.GetWorldTag('isHomeWorkWorld')
    local cb = function()
        local WorldExitDialog = NPL.load('Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
        if msg and msg.save and Game.is_started then
            WorldExitDialog.OnDialogResult(_guihelper.DialogResult.Yes)
        else
            WorldExitDialog.OnDialogResult(_guihelper.DialogResult.No)
        end
        PapaAPI:SendEvent("ExitWorld",{callbackId = self.exitWorldMsg.callbackId})
        self.exitWorldMsg = nil
    end
    local needUpload = false
    if msg and msg.needUpload~= nil then
        needUpload = msg.needUpload
    end
    if isHomeWorkWorld and needUpload then
        GameLogic.QuickSave()
        local ShareWorld = NPL.load('(gl)script/apps/Aries/Creator/Game/Educate/Other/ShareWorld.lua')
        ShareWorld:SyncWorldNoUI(cb)
    else
        cb()
    end
end

-- tool function
function PapaAPI:SetEditStart(time,blockNum)
    self.startEditTime = time
    self.blockNum = blockNum
end


------------------------------
-- low level event related functions 
------------------------------
-- @param callbackUniqueName: can be nil. if not, only one callback can be set per callbackUniqueName. 
function PapaAPI:RegisterEvent(name, callbackFunc, callbackUniqueName)
    self.events:AddEventListener(name, function(self, event)
        callbackFunc(event.msg)
    end, events, callbackUniqueName);
end

function PapaAPI:UnregisterEvent(name)
    self.events:RemoveEventListener(name);
end

function PapaAPI:DispatchLocalEvent(name, msg)
    self.events:DispatchEvent({
        type = name,
        msg = msg
    });
end

-- send a remote event to webview  
function PapaAPI:SendEvent(name, msg, callbackFunc)
    -- TODO: SendMessage
    if not msg then
        return
    end
    if msg.msg then -- delete the msg data receive from webview
        msg.msg = nil
    end
    msg.name = name or ""
    self:SendMessage(msg)
end

function PapaAPI:SendMessage(message)
    if not message then
        return
    end
    local p = NplBrowserPlugin.GetWindowState(self.browser_name)
    if not p then
        p = {
            id = self.browser_name
        }
    end
    if p then
        local sendMsg = {}
        if type(message) == "table" then
            sendMsg = message
            sendMsg.jsFile = "PapaAPI.ts"
        end
        if type(message) == "string" then
            sendMsg.jsFile = "PapaAPI.ts"
            sendMsg.msg = message
        end
        NplBrowserPlugin.SendMessage(p, sendMsg)
    end
end

function PapaAPI.GetUrlDecodeData(data)
    if type(data) == "string" then
        local str = commonlib.Encoding.url_decode(data)
        return commonlib.Json.Decode(str)
    end

    if type(data) == "table" then
        local jsonStr = commonlib.Json.Encode(data)
        jsonStr = commonlib.Encoding.url_decode(jsonStr)
        return commonlib.Json.Decode(jsonStr)
    end
end

-- receiving a message from webview 
function PapaAPI:OnReceiveMessageFromWebView(msg)
    local data = msg and msg.msg
    if msg.callbackSessionId then
        data.callbackId = msg.callbackSessionId
    end
	self:DispatchLocalEvent(msg.eventName, data);
end

local function activate()
    local msg = NplBrowserPlugin.TranslateJsMessage(msg);
    PapaAPI:OnReceiveMessageFromWebView(msg);
end

-- receiver for javascript:
-- NPL.activate("PapaAPI.lua", {eventName:string, msg:table, ...})
NPL.this(activate, {filename = "PapaAPI.lua"})

PapaAPI:InitSingleton();
