--[[
Title: PapaAdventures Lessons Creation
Author(s): big
Date: 2023.3.25
Desc: 
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/Lessons/Creation.lua");
local Creation = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Lessons.Creation");
-------------------------------------------------------
]]

local LessonsApi = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/Apis/Lessons/LessonsApi.lua");
local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua');
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
NPL.load("(gl)script/apps/Aries/Creator/Game/Tutorial/Assessment.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockLayer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/ide/System/Core/PainterContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAdventuresMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAPI.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");

local DockLayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.DockLayer");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local PainterContext = commonlib.gettable("System.Core.PainterContext");
local PapaAdventuresMain = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Main");
local PapaAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.PapaAPI");
local Assessment = commonlib.gettable("MyCompany.Aries.Creator.Game.Tutorial.Assessment")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");

local Creation = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Lessons.Creation");

function Creation:SetCurData(curTask, curSections, curSection, classActivityId, scheduleId, submitType,code,hasNextStep,lessonSubmitType,lessonType)
    self.curTask = curTask;
    self.curSections = curSections;
    self.curSection = curSection;
    self.classActivityId = classActivityId;
    self.scheduleId = scheduleId;
    self.submitType = submitType; -- 1. lesson world  2. my opus world.
    self.code = code
    self.hasNextStep = hasNextStep
    self.lessonSubmitType = lessonSubmitType
    self.IsStartSubmiteWorld = false
    self.lessonType = lessonType
    self.isLoadWorld = false
end

function Creation:Init()
    DockLayer:RemoveAll();
    -- self.hasNextStep = true;
    self.rejectEsc = false 
    self.needSaveWorld = self.lessonType == 7 or false;

    self.allSectionData = {};
    self.fetchSectionsIndex = 1;
    if self.curTask == nil then
        self:ShowPage();
    else
        self:RefreshNextStepStatus(function()
            self:ShowPage();
        end)
    end
end

function Creation:RefreshNextStepStatus(callback)
    self:GetAllSectionData(function()
        local lastCreationWorldSectionId = 0;
        
        for key, item in ipairs(self.curTask.contents) do
            if (item.sections) then
                for sKey, sItem in ipairs(item.sections) do
                    if (sItem and sItem.type == "material" and sItem.content.type == 7) then
                        lastCreationWorldSectionId = sItem.id;
                    end
                end
            end
        end

        if (lastCreationWorldSectionId == self.curSection.id) then
            -- self.hasNextStep = false;
        end

        if (callback and type(callback) == "function") then
            callback();
        end
    end);
end

function Creation:GetAllSectionData(callback)
    if (self.curTask and
        self.curTask.contents and
        type(self.curTask.contents) == "table") then

        if (self.curTask.contents[self.fetchSectionsIndex]) then
            local curItem = self.curTask.contents[self.fetchSectionsIndex];

            LessonsApi:GetLessonSections(curItem.id, function(data, err)
                if (not data or not data.contents) then
                    return;
                end

                curItem.sections = data.contents;
                self.fetchSectionsIndex = self.fetchSectionsIndex + 1;
                self:GetAllSectionData(callback);
            end);
        else
            if (callback and type(callback) == "function") then
                callback();
                self.allSectionData = {};
                self.fetchSectionsIndex = 1;
            end
        end
    end
end

function Creation:ShowPage()
    if self.page then
        self.page:CloseWindow()
        self.page = nil
    end
    local params = {
        url = "script/apps/Aries/Creator/Game/PapaAdventures/Lessons/Creation.html",
        name = "PapaAdventures.Lessons.Creation",
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = -4,
        allowDrag = false,
        bShow = nil,
        directPosition = true,
        align = '_fi',
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        cancelShowAnimation = true,
        bToggleShowHide = false,
        click_through = true,
        -- DesignResolutionWidth = 1280,
        -- DesignResolutionHeight = 720,
    };

    System.App.Commands.Call('File.MCMLWindowFrame', params);
    GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow",Creation.ShowCodeBlockWindow,Creation,"Creation");
    GameLogic.GetFilters():add_filter("DesktopModeChanged", Creation.OnChangeDesktopMode);
    self.page = params._page;
    if(params._page) then
		params._page.OnClose = function()
            GameLogic.GetFilters():remove_filter("DesktopModeChanged", Creation.OnChangeDesktopMode);
			GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", Creation.ShowCodeBlockWindow, Creation);
		end
    end
end

function Creation.OnClickChangeGameMode()
    if Creation.mode == "movie" then
        return
    end
    local bChange = GameLogic.ToggleGameMode();
end

function Creation.OnChangeDesktopMode(mode)
    Creation.mode = mode
    local btnChange = ParaUI.GetUIObject("btn_creation_change_mode")
    if mode ~= "editor" then
        btnChange.background = "Texture/Aries/Creator/keepwork/Mobile/icon/bianji_56x56_32bits.png;0 0 56 56"
    else
        btnChange.background = "Texture/Aries/Creator/keepwork/Mobile/icon/youxi_56x56_32bits.png;0 0 56 56"
    end
    if mode == "movie" then
        btnChange.background = "Texture/Aries/Creator/keepwork/Mobile/icon/bianji_56x56_32bits.png;0 0 56 56"
    end
    return mode
end

function Creation:ShowCodeBlockWindow(event)
    local bShow = event and event.bShow
    if bShow == "true" or bShow == true then
        self.SetPageVisible(false)
    else
        self.SetPageVisible(true)
    end
end

function Creation:NextStep()
    if self.needSaveWorld then
        self.needSaveWorld = false
    end
    GameLogic.QuickSave()
    local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
    local projectId = world_data and world_data.kpProjectId

    PapaAPI:NextStep(projectId,self.lessonType)
    PapaAPI:ReportLesson()
    PapaAPI:ExitGame()
end

function Creation:ShowInGameButton(bShow)
    self.IsShowInGame = bShow == true
    if self.page then
        local pnlOperate = ParaUI.GetUIObject("operate_in_game")
        if pnlOperate and pnlOperate:IsValid() then
            pnlOperate.visible = self.IsShowInGame

        end
    end
end

function Creation:OnClickInGame()
    -- PapaAPI:SetDisplayMode("max")
    PapaAPI:SendEvent("onLessonBackButtonClick",{})
end

function Creation:GetWorldFolderName(callback)
    if (not self.curSection or
        not self.curSection.content or
        not self.curSection.content.content or
        not self.curSection.content.content.homeworkName) then
        if (callback and type(callback) == "function") then
            callback();
        end
    end
    local world_name = self.curSection.content.content.homeworkName;
    self.homeworkName = world_name
    local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
    Compare:GetNewWorldName(world_name, callback)
end

function Creation:LoadSuperFlatWorld(callbackId)
    self.callbackId = callbackId
    self:GetWorldFolderName(function(worldName,worldPath,last_world_name)
        if last_world_name and last_world_name ~= "" then
            GameLogic.GetFilters():add_filter("OnBeforeLoadWorld",Creation.OnBeforeLoadWorld)
            local foldername = last_world_name
            local username = Mod.WorldShare.Store:Get("user/username");
            local worldPath = "worlds/DesignHouse/".. foldername
            if username and username ~= "" then
                worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. foldername
            end
            if (ParaIO.DoesFileExist(worldPath)) then
                --GameLogic.RunCommand(format("/loadworld -s %s", worldPath));
            else
                Creation.IsCreateWorld = true
                local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
                CreateWorld:CreateWorldByName(foldername, "superflat",false)
            end
            local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
            SyncWorld:CheckAndUpdatedByFoldername(foldername,function ()
                Creation.OpenWorld(worldPath)
                local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
                Progress.syncInstance = nil
                self.IsStartSubmiteWorld = true
                PapaAPI:SendEvent("CreateWorld",{callbackId = self.callbackId,result = true})
                self.callbackId = nil
            end,"papa_adventure")
        else
            --创建世界失败，返回browser
            PapaAPI:SendEvent("CreateWorld",{callbackId = self.callbackId,result = false,message = "name error"})
            self.callbackId = nil
        end
    end)
end

function Creation.OnBeforeLoadWorld()
    WorldCommon.SetWorldTag("isHomeWorkWorld", true);
    WorldCommon.SetWorldTag("platform", System.options.appId or "paracraft_papa");
    WorldCommon.SetWorldTag("channel", 3);
    WorldCommon.SetWorldTag("name", Creation.homeworkName or "");
    WorldCommon.SaveWorldTag()
    GameLogic.GetFilters():remove_filter("OnBeforeLoadWorld",Creation.OnBeforeLoadWorld);
end

function Creation.CreateWorldCallback(_, event)
    local worldPath = commonlib.Encoding.DefaultToUtf8(event.world_path)
    local paths = commonlib.split(worldPath,"/")
    local worldName = paths[#paths]
    if worldName and worldName ~= "" then
        local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
        SyncWorld:CheckAndUpdatedByFoldername(worldName,function ()
            Creation.OpenWorld(worldPath)
            local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
            Progress.syncInstance = nil
            Creation.IsStartSubmiteWorld = true
            PapaAPI:SendEvent("CreateWorld",{callbackId = Creation.callbackId,result = true})
            Creation.callbackId = nil
        end,"papa_adventure")
    end
   
end

function Creation.OpenWorld(worldPath)
    if Creation.isLoadWorld then
        PapaAPI:SendEvent("CreateWorld",{callbackId = Creation.callbackId,result = false,message = "同一时间重复进入世界"})
        Creation.callbackId = nil
        return
    end
    Creation.isLoadWorld = true
    if Creation.delayTimer then
        Creation.delayTimer:Change()
    end
    Creation.delayTimer = Creation.delayTimer or commonlib.Timer:new({callbackFunc = function(timer)
        Creation.isLoadWorld = false
    end});
    Creation.delayTimer:Change(2000,nil)
    if worldPath and worldPath ~= "" then
        GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
    end
end

function Creation:LoadCreationWorld(callbackId)
    if (not self.curSection or
        not self.curSection.content or
        not self.curSection.content.content or
        not self.curSection.content.content.homeworkName or
        not self.curSection.content.content.projectId or
        not self.classActivityId) then
            PapaAPI:SendEvent("CreateWorld",{callbackId = callbackId,result = false})
        return "";
    end
    local parentId = self.curSection.content.content.projectId
    if parentId and tonumber(parentId) == 0 then
        self:LoadSuperFlatWorld()
        return
    end
    self.callbackId = callbackId
    GameLogic.GetEvents():RemoveEventListener("createworld_callback",Creation.CreateWorldCallback, Creation)
    GameLogic.GetEvents():AddEventListener("createworld_callback", Creation.CreateWorldCallback, Creation, "Creation");
    GameLogic.GetFilters():add_filter("OnBeforeLoadWorld",Creation.OnBeforeLoadWorld)
    self:GetWorldFolderName(function(worldName,worldPath,last_world_name)
        local foldername = last_world_name
        local username = Mod.WorldShare.Store:Get("user/username");
        local worldPath = "worlds/DesignHouse/".. foldername
        if username and username ~= "" then
            worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. foldername
        end

        local PapaWorldLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaWorldLogic.lua");
        PapaWorldLogic.CheckWorldValidById(parentId,function(bSucceed,message)
            if not bSucceed  then
                if message == "project" then
                    PapaAPI:SendEvent("CreateWorld",{
                        callbackId = self.callbackId,
                        result = false,
                        message="配置的模板世界不存在，请联系老师"}
                    )
                    self.callbackId = nil
                    return
                end
                if message == "username" or message == "login" then
                    PapaAPI:SendEvent("CreateWorld",{
                        callbackId = self.callbackId,
                        result = false,
                        message="用户登录创意空间失败，请联系老师"}
                    )
                    self.callbackId = nil
                    return
                end
            end
            if (not ParaIO.DoesFileExist(worldPath)) then
                local cmd = format(
                    "/createworld -name \"%s\" -parentProjectId %d -update -fork %d -mode admin",
                    foldername,
                    parentId,
                    parentId
                );
                print("cmd==========",cmd)
                GameLogic.RunCommand(cmd); 
            else
                local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
                SyncWorld:CheckAndUpdatedByFoldername(foldername,function ()
                    Creation.OpenWorld(worldPath)
                    local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
                    Progress.syncInstance = nil
                    self.IsStartSubmiteWorld = true
                    PapaAPI:SendEvent("CreateWorld",{callbackId = self.callbackId,result = true})
                    self.callbackId = nil
                end,"papa_adventure")
            end
        end,true)
    end);
    
end

function Creation:ShowOpusSubmitPage(callback)
    ShareWorld:Init(function(bSucceed)
        if callback then
            callback(bSucceed)
        end
    end,
    function()
        local page_url = "script/apps/Aries/Creator/Game/PapaAdventures/Lessons/OpusSubmit.html"
        local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
        if IsMobileUIEnabled then
            page_url = "script/apps/Aries/Creator/Game/PapaAdventures/Lessons/OpusSubmit.mobile.html"
        end
        local params = {
            url = page_url,
            name = "PapaAdventures.Lessons.OpusSubmit",
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 10,
            allowDrag = false,
            bShow = nil,
            directPosition = true,
            align = '_fi',
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            cancelShowAnimation = true, 
            bToggleShowHide = true,
            click_through = false,
        };

        System.App.Commands.Call('File.MCMLWindowFrame', params);

        if (not ParaWorld.GetWorldDirectory()) then
            return "";
        end

        local filePath = Creation:GetImageUrl();

        if (params._page) then
            self.submitPage = params._page;

            if ParaIO.DoesFileExist(filePath) then
                params._page:SetUIValue('opus-submit-snapshot', filePath);
            else
                params._page:SetUIValue('opus-submit-snapshot', 'Texture/Aries/Creator/paracraft/konbaitu_266x134_x2_32bits.png# 0 0 532 268');
            end
        end
        self:UpdateNameAndDesc()
    end);
end
function Creation:UpdateNameAndDesc()
    local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
    if world_data then
        if world_data.name ~= nil  and world_data.name ~= "" and self.submitPage then
            self.submitPage:SetValue('opus_name',world_data.name)
            self.submitPage:SetValue('opus_name_unable',world_data.name)
            Creation.lastName = world_data.name
        end
        if world_data.kpProjectId ~= 0 then
            keepwork.world.detail({router_params = {id = world_data.kpProjectId}}, function(err, msg, data)
                if err == 200 then
                    if data and data.description and data.description ~= "" and self.submitPage then
                        self.submitPage:SetValue('opus-desc',data.description)
                        self.submitPage:SetValue('opus-desc-unable',data.description)
                        Creation.lastDesc = data.description
                    end
                end
            end);
        end
    end
end


function Creation:SubmitWorld(opusName, opusDesc)
    self.nameChanged = Creation.lastName ~= opusName and opusName ~= "" and opusName ~= nil
    self.descChanged = Creation.lastDesc ~= opusDesc and opusDesc ~= nil
    if self.nameChanged then
        local filterName = MyCompany.Aries.Chat.BadWordFilter.FilterString2(opusName);
        if filterName and (filterName ~= opusName or filterName:find("*")) then
            _guihelper.MessageBox(L'您输入的内容不符合互联网安全规范，请修改')
            return
        end
    else
        local filterName = MyCompany.Aries.Chat.BadWordFilter.FilterString2(Creation.lastName);
        if filterName and (filterName ~= Creation.lastName or filterName:find("*")) then
            _guihelper.MessageBox(L'您输入的内容不符合互联网安全规范，请修改')
            return
        end
    end

    if self.descChanged then
        local filterName = MyCompany.Aries.Chat.BadWordFilter.FilterString2(opusDesc);
        if filterName and (filterName ~= opusDesc or filterName:find("*") )then
            _guihelper.MessageBox(L'您输入的内容不符合互联网安全规范，请修改')
            return
        end
    else
        local filterName = MyCompany.Aries.Chat.BadWordFilter.FilterString2(Creation.lastDesc);
        if filterName and (filterName ~= Creation.lastDesc or filterName:find("*") )then
            _guihelper.MessageBox(L'您输入的内容不符合互联网安全规范，请修改')
            return
        end
    end
    local notShowFinishPage
    self.worldInfo ={opusName = opusName,opusDesc = opusDesc}
    if (self.curSections and self.curSections.id) then
        notShowFinishPage = true
        if (self.submitType == 1) then
            if (self.curSection and
                self.curSection.content and
                self.curSection.content.content and
                self.curSection.content.content.homeworkName) then
                Mod.WorldShare.Store:Set('world/projectName', self.curSection.content.content.homeworkName);
            end
    
            Mod.WorldShare.Store:Set('world/projectDesc', opusDesc);
        elseif (self.submitType == 2) then
            Mod.WorldShare.Store:Set('world/projectName', opusName);
            Mod.WorldShare.Store:Set('world/projectDesc', opusDesc);
        end
        self:StartAssement()
    else
        Mod.WorldShare.Store:Set('world/projectName', opusName);
        Mod.WorldShare.Store:Set('world/projectDesc', opusDesc);
    end
    
    local isWorldExist = false
    -- local currentWorldList = Mod.WorldShare.Store:Get('world/compareWorldList') or {}
    -- for key, item in ipairs(currentWorldList) do
    --     if opusName and self.nameChanged and item and (item.foldername == opusName) then
    --         isWorldExist = true
    --         break
    --     end
    -- end
    if not isWorldExist then
        ShareWorld:OnClick(notShowFinishPage);
        self.submitPage:CloseWindow();
        return
    end
    Mod.WorldShare.Store:Remove('world/projectName')
    _guihelper.MessageBox(L'已有相同名称的世界，请重新输入世界名')
end

function Creation:StartAssement()
    if not (self.curSections and self.curSections.id) then
        GameLogic.AddBBS(nil,"生成课程报告异常")
        return
    end
    LessonsApi:GetLessonSections(self.curSections.id, function(data, err)
        if (not data.contents or
            type(data.contents) ~= "table") then
            return;
        end

        for key, item in ipairs(data.contents) do
            if (item.index == self.curSection.index) then
                self.curSection = item;
                break;
            end
        end
        if not self.curSection or not self.curSection.content or not self.curSection.content.content or not self.curSection.content.content.report then
            GameLogic.AddBBS(nil,"生成课程报告异常")
            --self:NextStep();
            return
        end
        self.code = self.curSection.content.content.report.code
        if (not self.code or self.code == "") then
            LOG.std(nil, "debug", "Creation:SubmitWorld", "not report code.");
            --self:NextStep()
            return;
        end
        
        NPL.DoString(self.code);

        self:GetLessonReport()
    end); 
end

local grades = {"C","B","A","S"}
function Creation:GetLessonGrade(count) 
    local count = tonumber(count or 0)
    
    return count <= 4 and grades[count + 1] or "S"
end

function Creation:GetLessonReport()
    local count, reviews, finishOptions,knowledges = Assessment:GetWorkMark(); --没有批改数据，或者普通世界
    if not count or not reviews or not finishOptions then
        --GameLogic.AddBBS(nil,"作业批改异常")
        return 
    end
    LOG.std(nil,"info","Creation","GetLessonReport---------------")
    local tasks = {}
    local isHave = false
    for k,v in pairs(finishOptions) do
        if v and v[1] then
            local index = string.match(v[1],"%d+")
            if index and tonumber(index) > 0 then
                local key = "task"..index
                tasks[key] = {}
                tasks[key].status = 1
                isHave = true
            end
        end
    end
    
    local comment = (reviews and reviews[1]) and reviews[1].line or ""
    local knowledge = knowledges
    local report = {
        comment = Mod.WorldShare.Utils.UrlEncode(comment),
        stepCount = count,
        createCount = WorldCommon.GetWorldTag("totalEditSeconds"),
        buildCount = WorldCommon.GetWorldTag("totalSingleBlocks"),
        codeCount = WorldCommon.GetWorldTag("editCodeLine"),
        knowledge = Mod.WorldShare.Utils.UrlEncode(knowledge),
    }
    if isHave then
        report.tasks = tasks
    end
    self.report = report
    LOG.std(nil,"info","Creation","GetLessonReport---------------%s",commonlib.serialize_compact(report)) 
end

function Creation:UploadLessonReport()
    local count, reviews, finishOptions = Assessment:GetWorkMark(); --没有批改数据，或者普通世界
    if not count or not reviews or not finishOptions then
        --GameLogic.AddBBS(nil,"作业批改异常")
        return 
    end
    LOG.std(nil,"info","Creation","UploadLessonReport---------------")
    Assessment:Init()
end

function Creation:GetImageUrl()
    if (System.os.GetPlatform() ~= "win32") then
        return ParaIO.GetWritablePath() .. ParaWorld.GetWorldDirectory() .. "preview.jpg";
    else
        return ParaWorld.GetWorldDirectory() .. "preview.jpg";
    end
end

function Creation:ShowDialog(dialogOptions)
    local params = {
        url = "script/apps/Aries/Creator/Game/PapaAdventures/Lessons/Dialog.html",
        name = "PapaAdventures.Lessons.Dialog",
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 0,
        allowDrag = false,
        bShow = nil,
        directPosition = true,
        align = '_fi',
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        cancelShowAnimation = true,
        bToggleShowHide = false,
        click_through = true,
    };

    System.App.Commands.Call('File.MCMLWindowFrame', params);

    params._page.dialogOptions = dialogOptions;
    params._page:Refresh(0.01);
end

function Creation.OnSyncWorldFinish()
    GameLogic.GetFilters():remove_filter("SyncWorldFinish", Creation.OnSyncWorldFinish);
end

function Creation.SetOperateVisible(visible)
    local opRt = ParaUI.GetUIObject("operate_right_top")
    if opRt and opRt:IsValid() then
        opRt.visible = visible == true
        if visible == true then
            GameLogic.RunCommand("/hide dock_right_top")
        else
            GameLogic.RunCommand("/show dock_right_top")
        end
    end
end

function Creation.SetPageVisible(visible)
    if not Creation.page then
        return
    end
    local parent  = Creation.page:GetParentUIObject()
    if parent and parent:IsValid() then
        parent.visible = visible == true
    end
end
