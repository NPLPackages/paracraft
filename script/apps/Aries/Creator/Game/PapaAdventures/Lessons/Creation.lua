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

function Creation:SetCurData(curTask, curSections, curSection, classActivityId, scheduleId, submitType,code,hasNextStep)
    self.curTask = curTask;
    self.curSections = curSections;
    self.curSection = curSection;
    self.classActivityId = classActivityId;
    self.scheduleId = scheduleId;
    self.submitType = submitType; -- 1. lesson world  2. my opus world.
    self.code = code
    self.hasNextStep = hasNextStep
end

function Creation:Init()
    DockLayer:RemoveAll();
    -- self.hasNextStep = true;
    self.rejectEsc = false--self.curSection and (self.curSection.content.type == 6 or  self.curSection.content.type == 7) or false;
    self.needSaveWorld = self.curSection and (self.curSection.content.type == 7) or false;

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
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
    };

    System.App.Commands.Call('File.MCMLWindowFrame', params);

    self.page = params._page;
end

function Creation:NextStep()
    if self.needSaveWorld then
        self.needSaveWorld = false
        GameLogic.QuickSave()
    end
    PapaAPI:SetDisplayMode("ingame")
    PapaAPI:NextStep()
    PapaAPI:ExitGame()
end

function Creation:GetWorldFolderName()
    if (not self.curSection or
        not self.curSection.content or
        not self.curSection.content.content or
        not self.curSection.content.content.homeworkName) then
        return "";
    end

    return self.curSection.content.content.homeworkName;
end

function Creation:LoadSuperFlatWorld()
   if self:GetWorldFolderName() ~= "" then
        GameLogic.GetFilters():add_filter("OnBeforeLoadWorld",Creation.OnBeforeLoadWorld)
        local foldername = self:GetWorldFolderName();
        local username = Mod.WorldShare.Store:Get("user/username");
        local worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. foldername
        if (ParaIO.DoesFileExist(worldPath)) then
            --GameLogic.RunCommand(format("/loadworld -s %s", worldPath));
        else
            local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
            CreateWorld:CreateWorldByName(foldername, "superflat",false)
        end
        local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
        SyncWorld:CheckAndUpdatedByFoldername(foldername,function ()
            GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
            local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
            Progress.syncInstance = nil
        end,"papa_adventure")
   end
end

function Creation:OnBeforeLoadWorld()
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    WorldCommon.SetWorldTag("isHomeWorkWorld", true);
    WorldCommon.SaveWorldTag()
    GameLogic.GetFilters():remove_filter("OnBeforeLoadWorld",Creation.OnBeforeLoadWorld);
end

function Creation:LoadCreationWorld()
    if (not self.curSection or
        not self.curSection.content or
        not self.curSection.content.content or
        not self.curSection.content.content.homeworkName or
        not self.curSection.content.content.projectId or
        not self.classActivityId) then
        return "";
    end
    local parentId = self.curSection.content.content.projectId
    if parentId and tonumber(parentId) == 0 then
        self:LoadSuperFlatWorld()
        return
    end
    GameLogic.GetFilters():add_filter("OnBeforeLoadWorld",Creation.OnBeforeLoadWorld)
    local foldername = self:GetWorldFolderName();
    local username = Mod.WorldShare.Store:Get("user/username");
    local worldPath = "worlds/DesignHouse/_user/" .. username .. "/" .. foldername

    local function tryFunc(callback)
        local tryTime = 0;
        local timer;
        timer = commonlib.Timer:new({
            callbackFunc = function()
                if (tryTime >= 5) then
                    timer:Change(nil, nil);
                    return;
                end
    
                if (ParaIO.DoesFileExist(worldPath)) then
                    timer:Change(nil, nil);
                    if callback then
                        callback()
                    end
                end
                
                tryTime = tryTime + 1;
            end
        }, 500);
        timer:Change(0, 500);
    end

    if (not ParaIO.DoesFileExist(worldPath)) then
        local cmd = format(
            "/createworld -name \"%s\" -parentProjectId %d -update -fork %d",
            foldername,
            self.curSection.content.content.projectId,
            self.curSection.content.content.projectId
        );
        GameLogic.RunCommand(cmd);
    end
    tryFunc(function()
        local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
        SyncWorld:CheckAndUpdatedByFoldername(foldername,function ()
            GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
            local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
            Progress.syncInstance = nil
        end,"papa_adventure")
    end)
end

function Creation:ShowOpusSubmitPage(callback)
    ShareWorld:Init(function(bSucceed)
        self:UploadLessonReport();
        if callback then
            callback(bSucceed)
        end
    end,
    function()
        local params = {
            url = "script/apps/Aries/Creator/Game/PapaAdventures/Lessons/OpusSubmit.html",
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
            click_through = true,
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
                   
                    echo(data, true)
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
    self.nameChanged = Creation.lastName ~= opusName and opusName ~= ""
    self.descChanged = Creation.lastDesc ~= opusDesc
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
        ShareWorld:OnClick(true);
    else
        Mod.WorldShare.Store:Set('world/projectName', opusName);
        Mod.WorldShare.Store:Set('world/projectDesc', opusDesc);
        ShareWorld:OnClick();
    end
    self.submitPage:CloseWindow();
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
    local count, reviews, finishOptions = Assessment:GetWorkMark(); --没有批改数据，或者普通世界
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
    local report = {
        comment = comment,
        stepCount = count,
        createCount = WorldCommon.GetWorldTag("totalEditSeconds"),
        buildCount = WorldCommon.GetWorldTag("totalSingleBlocks"),
        codeCount = WorldCommon.GetWorldTag("editCodeLine"),
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
    PapaAPI:ExitGame()
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
