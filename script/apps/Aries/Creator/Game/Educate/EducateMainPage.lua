--[[
    author:{pbb}
    time:2023-02-14 19:42:52
    uselib:
        local EducateMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/EducateMainPage.lua")
        EducateMainPage.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionManager.lua")
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local CompetitionManager = commonlib.gettable("MyCompany.Aries.Game.Educate.Competete.Manager")
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local EducateOfflinePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Offline/EducateOfflinePage.lua")
local ClassSelectPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ClassSelectPage.lua")
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua")
local TipRoadManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoadManager.lua");
local EducateMainPage = NPL.export()
EducateMainPage.tab_view_index = 1 --侧边按钮的索引
EducateMainPage.tab_index = 1 --iframe的索引
EducateMainPage.curr_course_page = 1 --新手入门当前页
EducateMainPage.taburls = {
    {url="",index = 1},
}
local page
--#82B0FF #FFFFFF
EducateMainPage.tab_buttons = {
    {value = L"我的作品"},
    {value = L"新手入门"},
    {value = L"赛事中心"}
}
if System.options.isShenzhenAi5 then
    EducateMainPage.tab_buttons = {
        {value = L"我的作品"},
        {value = L"新手入门"},
    }
end

EducateMainPage.IsGetLessonData = false
EducateMainPage.LessonData = nil
EducateMainPage.IsShowLesson = false
EducateMainPage.IsFirstLogin = nil
local last_audio_src
function EducateMainPage.OnInit()
    print("EducateMainPage.OnInit=============================")
    page = document:GetPageCtrl()
    page.OnCreate = EducateMainPage.OnCreate
    GameLogic:Connect("WorldLoaded", self, EducateMainPage.OnWorldLoaded, "UniqueConnection");
    GameLogic.GetFilters():add_filter("click_create_new_world",EducateMainPage.SetShowCreateWorld)
    GameLogic.GetFilters():add_filter("show_my_works",EducateMainPage.ChangeTabIndex)
    GameLogic.GetFilters():add_filter("OnWorldCreate",  EducateMainPage.OnWorldCreated)
    GameLogic.GetFilters():add_filter("CheckInRace",  EducateMainPage.IsInRace)
    GameLogic.GetFilters():add_filter("ImprotP3dFile",  EducateMainPage.ImPortWorld)
    GameLogic.GetFilters():add_filter("OnBeforeLoadWorld",EducateMainPage.OnBeforeLoadWorld)
    Screen:Connect("sizeChanged", EducateMainPage, EducateMainPage.OnScreenSizeChange, "UniqueConnection")
end

function EducateMainPage.ClearFilters()
    Screen:Disconnect('sizeChanged', EducateMainPage, EducateMainPage.OnScreenSizeChange)
    GameLogic.GetFilters():remove_filter("click_create_new_world",EducateMainPage.SetShowCreateWorld)
    GameLogic.GetFilters():remove_filter("show_my_works",EducateMainPage.ChangeTabIndex)
    GameLogic.GetFilters():remove_filter("OnWorldCreate",  EducateMainPage.OnWorldCreated)
    GameLogic.GetFilters():remove_filter("CheckInRace",  EducateMainPage.IsInRace)
    GameLogic.GetFilters():remove_filter("ImprotP3dFile",  EducateMainPage.ImPortWorld)
end

function EducateMainPage.OnScreenSizeChange()
    local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
    EducateProject.CloseMenu()

    EducateProject.RefreshMenu()
end

function EducateMainPage.OnBeforeLoadWorld()
    local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
    EducateProject.CloseMenu(true)

    local CurClassPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/CurClassPage.lua")
    CurClassPage.CloseView()

    local ClassSelectPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ClassSelectPage.lua")
    ClassSelectPage.CloseView()

    EducateMainPage.ResetParams()
end

function EducateMainPage.ImPortWorld(worldPath,bSuccess)
    if bSuccess then
        EducateMainPage.RefreshPage()
        GameLogic.AddBBS(nil,L"导入世界成功")
        EducateProject.SyncLocalWorld(worldPath)
    else
        GameLogic.AddBBS(nil,L"导入世界失败")
    end
    return bSuccess,worldPath
end

function EducateMainPage.OnWorldLoaded()
    EducateMainPage.ClearTimer()
end

function EducateMainPage.OnCreate()
    if EducateMainPage.tab_view_index == 3 then
        CompetitionManager:ClearCompeteData()
        EducateMainPage.CheckShowCompete()
    else
        EducateMainPage.CheckShowLesson()
    end
end

function EducateMainPage.OnWorldCreated(worldPath)
    if worldPath and worldPath ~= "" then
        EducateMainPage.ResetParams()
    end
    return worldPath
end

function EducateMainPage.ResetParams()
    EducateMainPage.isShowCreateWorld = false
    EducateMainPage.tab_view_index = nil
end

function EducateMainPage.SetShowCreateWorld()
    KeepworkServiceWorld:LimitFreeUser(false, function(result)
        if result then
            EducateMainPage.isShowCreateWorld = true
            EducateMainPage.tab_view_index = nil
            EducateMainPage.RefreshPage(true)
        else
            _guihelper.MessageBox(L'目前仅支持1个创作世界，如需创作更多世界请联系客服', nil, _guihelper.MessageBoxButtons.OK)
        end
    end)
end

function EducateMainPage.ShowPage()
    local isOffline = System.options.isOffline
    if isOffline then
        EducateMainPage.ResetParams()
        EducateMainPage.ClearFilters()
        EducateOfflinePage.ShowPage()
        return 
    end
    EducateOfflinePage.ClearFilters()
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        EducateMainPage.ShowView()
        return
    end
    
    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                EducateMainPage.ShowView()
            end, 1000)
        end
    end)
end

function EducateMainPage.ShowView()
    CompetitionManager:Init()
    CustomCharItems:Init();
	local Game = commonlib.gettable("MyCompany.Aries.Game")
	if(Game.is_started) then
		Game.Exit()
	end

    ParaUI.GetUIObject('root'):RemoveAll()
    -- EducateMainPage.StopMusic()
    NPL.load("(gl)script/ide/TooltipHelper.lua");
    local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
    if(type(BroadcastHelper.Reset) == "function") then
        BroadcastHelper.Reset();
    end

    TipRoadManager:ReCreateRoads()

    local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin")
    NplBrowserPlugin.CloseAllBrowsers()

    AudioEngine.Init()
    EducateMainPage.ClosePageWithNoLogout()
    
    EducateMainPage.ResetParams()
    EducateMainPage.IsGetLessonData = false
    EducateMainPage.LessonData = nil
    EducateMainPage.tab_view_index  = 1
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/EducateMainPage.html",
        name = "EducateMainPage.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = -10,
        directPosition = true,
        cancelShowAnimation = true,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        align = "_fi",
            x = view_width,
            y = view_height,
            width = -view_width/2,
            height = -view_height/2,
    };
    EducateMainPage.ReportLoginTime()
    -- EducateProject.ShowCreate()
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if(params._page ) then
        EducateMainPage.page = params._page
		params._page.OnClose = function(bDestroy)
            EducateMainPage.IsShowLesson = false
            EducateMainPage.ClearFilters()
			EducateProject.CloseCreate(true)
            EducateMainPage.ClearTimer()
		end
	end

    if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", function ()
            local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
            local profile = KeepWorkItemManager.GetProfile()
            if not profile then
                return 
            end
            if EducateMainPage.page then
                if profile.portrait then
                    EducateMainPage.page:SetValue("img_protrait",profile.portrait)
                end
                
                EducateMainPage.page:SetValue("txt_user",EducateMainPage.GetFilterUserName())
            end
		end)
	end

    GameLogic.GetFilters():add_filter("on_start_login", function()
        EducateMainPage.IsFirstLogin = nil
    end);

    if not System.os.IsEmscripten() then
        commonlib.TimerManager.SetTimeout(function()
            EducateMainPage.CheckUpdate()
        end,1000)
    end
end

function EducateMainPage.GetFilterUserName()
    local username = EducateMainPage.GetUserName()
    
    if not username then
        return ""
    end
    local fontName = "System;12;bold"
    local textWidth = _guihelper.GetTextWidth(username,fontName)
    if textWidth > 82 then
        username = _guihelper.TrimUtf8TextByWidth(username,82,fontName).."..."
    end
    username = BadWordFilter.FilterString(username)
    return username
end

function EducateMainPage.ReportLoginTime()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
    local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
    QuestAction.ReportLoginTime()
end

function EducateMainPage.CheckHasSignUpActivity()
    EducateMainPage.shwoDownTime = false
    if EducateMainPage.page then
        EducateMainPage.page:Refresh(0)
    end
    EducateMainPage.IsInRaceTime = false
    local cache_policy = 'access plus 0'
    local getMyActivity = commonlib.getfield('keepwork.quiz.getMyActivity')
    getMyActivity({
        cache_policy = cache_policy
    }, function(err, msg, data)
        echo("quiz | check user sign up activity")
        echo(data, true)
        if data and data.data ~= nil and data.data.id then
            keepwork.quiz.activity.detail({
                cache_policy = "access plus 0",
                router_params = {
                    id = data.data.id
                }
            }, function(er, mg, dt)
                if er ~= 200 then
                    echo(string.format("加载活动 %d 失败！", data.data.id))
                    echo({er, mg, dt})
                    return
                end

                echo("quiz | load activity api return")
                echo(dt, true)

                local serverTimestamp = dt.data.curTimestamp
                local startTimestamp, endTimestamp
                local duration = dt.data.examDuration
                local units = dt.data.units
                local allComplete = true
                for i, unit in pairs(units) do
                    if not startTimestamp or not endTimestamp then
                        startTimestamp = unit.startTimestamp
                        endTimestamp = unit.endTimestamp
                    end
                    if not unit.isAnswer then
                        allComplete = false
                        break
                    end
                end
                if not startTimestamp or not endTimestamp then
					print("获取测试时间失败")
                    return
                end
                local examEndTime = startTimestamp + (duration or 3600)
                if examEndTime < endTimestamp then --考试时间，是取得开始时间 + 考试时长
                    endTimestamp = examEndTime
                end

                EducateMainPage.myActivityData = data
                EducateMainPage.entranceProjectId = tonumber(data.data.entranceProjectId) 
                local inRange = (startTimestamp == nil or endTimestamp == nil or serverTimestamp == nil) and false or (startTimestamp < serverTimestamp and serverTimestamp <= endTimestamp)
                print("quiz | startTimestamp",startTimestamp)
                print("quiz | endTimestamp",endTimestamp)        
                if startTimestamp ~= nil and endTimestamp ~= nil  then
                    EducateMainPage.endTimestamp = startTimestamp
                    if startTimestamp - serverTimestamp > 0 and startTimestamp - serverTimestamp <= 3600 then
                        EducateMainPage.shwoDownTime = true
                        EducateMainPage.raceName = (data.data.name ~= nil and data.data.name ~= "") and data.data.name or "赛事"
                        EducateMainPage.ShowRaceDownTime()
                        if EducateMainPage.page then
                            EducateMainPage.page:Refresh(0)
                        end
                    end
                end
                if not allComplete and inRange then
                    EducateMainPage.IsInRaceTime = true
                    EducateMainPage.ShowRaceTip(data)
                end
            end)
        end
    end)
end

function EducateMainPage.IsInRace()
    return EducateMainPage.IsInRaceTime
end

function EducateMainPage.ShowRaceTip(data)
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "competition.popup",{useNoId=true})
    EducateMainPage.CommonAlert(
        string.format("你报名参加了%s，是否前往赛事？",(data.data.name ~= nil and data.data.name ~= "") and data.data.name or "赛事"), 
        true,
        function()
            if data.data and data.data.entranceProjectId ~= nil then
                GameLogic.RunCommand(string.format("/loadworld -s %s", data.data.entranceProjectId))
                GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.popup.enter",{kpProjectId=data.data.entranceProjectId,useNoId=true})
            end
        end
    )
end

function EducateMainPage.GetServerTime()
    local timp_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
    return timp_stamp
end

function EducateMainPage.SecondFormat(seconds)
	local day = math.floor(seconds / 86400)
	local hour = math.floor((seconds - day * 86400) / 3600)
	local min = math.floor((seconds - day * 86400 - hour * 3600) / 60)
	local second = seconds - day * 86400 - hour * 3600 - min * 60
	return day,hour,min,second
end

function EducateMainPage.ShowRaceDownTime()
	EducateMainPage.ClearTimer()

    local server_time = EducateMainPage.GetServerTime()
    local remained_sec = EducateMainPage.endTimestamp - server_time
    if remained_sec < 0 then
        EducateMainPage.page:SetValue("race_name_text", "")
        EducateMainPage.page:SetValue("down_time_text", "")
        EducateMainPage.shwoDownTime = false
        EducateMainPage.ShowRaceTip(EducateMainPage.myActivityData)
        EducateMainPage.page:Refresh(0)
        return
    end
    local day,hour,min,second = EducateMainPage.SecondFormat(remained_sec)
    local s = string.format("倒计时：%02d时%02d分%02d秒",hour,min,second)
    EducateMainPage.page:SetValue("race_name_text", EducateMainPage.raceName)
    EducateMainPage.page:SetValue("down_time_text", s)
    EducateMainPage.updateTimer = commonlib.Timer:new({callbackFunc = function(timer)
        EducateMainPage.ShowRaceDownTime()
    end})
    EducateMainPage.updateTimer:Change(1000, nil)
end

function EducateMainPage.ClearTimer()
	if EducateMainPage.updateTimer then
		EducateMainPage.updateTimer:Change()
		EducateMainPage.updateTimer = nil
	end
end

function EducateMainPage.CommonAlert(info, useFormat, cb)
    local str = info
    if (useFormat) then
        str =
            [[<div style='font-size:20px;font-weight:bold;margin-left:25px;margin-top:0px;text-align:center;color:#333333'>]] ..
                info .. [[</div>]]
    end

    _guihelper.MessageBox(str, function(result)
        if result == _guihelper.DialogResult.OK then
            if (cb) then
                cb()
            end
        end
    end, _guihelper.MessageBoxButtons.OKCancel_CustomLabel, {
        -- src = 'Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/tishi_70x48_32bits.png#0 0 70 48',
        icon_width = 56,
        icon_height = 39,
        icon_x = 5,
        icon_y = -14
    }, nil, nil, nil, {
        ok = "参加赛事",
        cancel = "下次吧"
    });
end

function EducateMainPage.PlayMusic(filename, volume, pitch)
    local volume = volume or 1
    local music_audio = EducateMainPage.GetMusic(filename)
    if last_audio_src ~= music_audio then
        if(last_audio_src) then
            last_audio_src:stop();
        end
        last_audio_src = music_audio
    end
    if music_audio then
        music_audio:play2d(volume,pitch);
    end
end

function EducateMainPage.StopMusic()
	if last_audio_src then
		last_audio_src:stop();
		last_audio_src = nil;
	end
end

function EducateMainPage.GetMusic(filename)
	if(not filename or filename=="") then
		return;
	end
	filename = commonlib.Encoding.Utf8ToDefault(filename)

	local audio_src = AudioEngine.Get(filename);
	if(not audio_src) then
		if(not ParaIO.DoesAssetFileExist(filename, true)) then
			filename = ParaWorld.GetWorldDirectory()..filename;
			if(not ParaIO.DoesAssetFileExist(filename, true)) then
				return;
			end
		end		
		audio_src = AudioEngine.CreateGet(filename);
		-- audio_src.loop = false;
		audio_src.file = filename;
		-- audio_src.isBackgroundMusic = true;
	end
	
	return audio_src;
end



function EducateMainPage.PlaySound()
    EducateMainPage.PlayMusic("Audio/Haqi/keepwork/common/edu_lesson.ogg",1);
end

function EducateMainPage.RefreshPage(bCloseWorldList)
    if page then
        page:Refresh(0)
    end
    if bCloseWorldList then
        EducateProject.CloseCreate()
    end
end

function EducateMainPage.ChangeTabIndex(name)
    local index = tonumber(name)
    print("ChangeTabIndex=====================",index)
    EducateMainPage.isShowCreateWorld = false
    if index and index > 0 and index ~= EducateMainPage.tab_view_index then
        EducateMainPage.tab_view_index = index
        if index ~= 1 then
            EducateProject.CloseCreate()
        -- else
        --     EducateMainPage.SetWorldSize()
        end
        if EducateMainPage.tab_view_index == 2 then
            EducateMainPage.curr_course_page = 1
        end
        EducateMainPage.RefreshPage()
    end
end

function EducateMainPage.CheckShowCompete()
    local competeNode = ParaUI.GetUIObject("compete_button_bg")
    if not competeNode:IsValid() then
        return 
    end
    local lessonNode = ParaUI.GetUIObject("lesson_button_bg")
    if not lessonNode:IsValid() then
        return 
    end
    if EducateMainPage.tab_view_index == 3 then
        competeNode.visible =true
        lessonNode.visible = false
    end
end

function EducateMainPage.CheckShowLesson()
    local lessonNode = ParaUI.GetUIObject("lesson_button_bg")
    if not lessonNode:IsValid() then
        return 
    end
    EducateMainPage.IsHaveLessonAuth = false
    keepwork.classrooms.query({}, function(err, msg, data)
        if err == 200 then
            if data and data.rows and #data.rows > 0 and data.count> 0 then
                local packageId = data.rows and data.rows[1] and data.rows[1].lessonPackageId
                if not packageId then
                    EducateMainPage.IsShowLesson = false
                    lessonNode.visible = EducateMainPage.IsShowLesson
                    return
                end
                EducateMainPage.LessonData = data
                EducateMainPage.IsShowLesson = true  
                lessonNode.visible = EducateMainPage.IsShowLesson
                EducateMainPage.UpdateLessonRedTip(data,EducateMainPage.IsShowLesson)
                EducateMainPage.CheckLessonAuth(packageId,function(bAuth)
                    if Game.is_started then
                        return
                    end
                    EducateMainPage.IsHaveLessonAuth = bAuth
                    if bAuth then
                        commonlib.TimerManager.SetTimeout(function()
                            if EducateMainPage.IsShowLesson and not EducateMainPage.IsFirstLogin then
                                ClassSelectPage.ShowView(EducateMainPage.LessonData);
                                EducateMainPage.IsFirstLogin = true
                                EducateMainPage.PlaySound()
                            end
                        end, 2000)
                    end
                end)
            end
            return
        end
        EducateMainPage.IsShowLesson = false
        lessonNode.visible = EducateMainPage.IsShowLesson
    end)
end

function EducateMainPage.CheckLessonAuth(lessonPackageId,callback)
    if not lessonPackageId then
        callback(false)
    end
    keepwork.lessonPackage.checkLessonNoAuth({
        router_params = {id = lessonPackageId}
    }, function(err, msg, data)
        if err == 200 and (data == "false" or data == false) then
            callback(true)
            return
        end
        LOG.std(nil,"info","no auth to enter lesson",commonlib.serialize_compact(data)) 
        callback(false)
    end);
end

function EducateMainPage.UpdateLessonRedTip(data,bShow)
    if bShow then
        local tipNode = ParaUI.GetUIObject("course_tip")
        if not tipNode:IsValid() then
            return 
        end
        tipNode.visible = false
        local count = 0
        if data and data.rows and #data.rows > 0 and data.count> 0 then
            count = data.count
        end
        
        if count > 0 then
            local lessonNode = ParaUI.GetUIObject("lesson_button_bg")
            if not lessonNode:IsValid() then
                return 
            end
            tipNode.visible = true
            
            -- if page then
            --     page:SetValue("course_tip_text",count)
            -- end
        end
    end
end

function EducateMainPage.OnClickLesson()
    if not EducateMainPage.IsHaveLessonAuth then
        GameLogic.AddBBS("EducateMainPage",L"您未获得课程授权，请联系老师。",4000,"255 0 0", 20)
        return
    end
    ClassSelectPage.ShowView(EducateMainPage.LessonData);
end

function EducateMainPage.ExitToLogin()
    local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
    CreateNewWorld.profile = nil
    EducateMainPage.ResetParams()
    System.options.cmdline_world = nil
    MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
    MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
    Mod.WorldShare.MsgBox:Close()
end

function EducateMainPage.ClosePage()
    if page then
        page:CloseWindow();
        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
        if KeepworkServiceSession:IsSignedIn() then
            KeepworkServiceSession:Logout(nil, function()
                GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)
                EducateMainPage.ExitToLogin()
            end)
        else
            EducateMainPage.ExitToLogin()
        end
        page = nil
    end
end

function EducateMainPage.CheckUpdate()
    if EducateMainPage.isCheckUpdate then
        return
    end
    EducateMainPage.isCheckUpdate = true
    System.options.cmdline_world = nil
    MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
    MyCompany.Aries.Game.MainLogin:set_step({IsLoginModeSelected = true})
    MyCompany.Aries.Game.MainLogin:next_step({IsUpdaterStarted = false})
end

function EducateMainPage.ClosePageWithNoLogout()
    if page then
        page:CloseWindow()
        page = nil

        EducateMainPage.ResetParams()
        EducateMainPage.IsGetLessonData = false
        EducateMainPage.LessonData = nil
        EducateMainPage.tab_view_index  = 1
    end
end

function EducateMainPage.OpenWebUrl()
    local token = commonlib.getfield("System.User.keepworktoken") or ""
    local baseurl = "http://edu-dev.kp-para.cn/login?"
    local url = ""
    local http_env = HttpWrapper.GetDevVersion()
    if http_env == "LOCAL" or http_env == "STAGE" then
        baseurl = "http://edu-dev.kp-para.cn/login?"
    elseif http_env == "RELEASE" then
        baseurl = "http://edu-rls.kp-para.cn/login?"
    else
        baseurl = "http://edu.palaka.cn/login?"
    end
    url = baseurl.."token="..token.."&type=PC"

    local platform = System.os.GetPlatform()
    if platform == "win32" or platform == "emscripten" then
        GameLogic.RunCommand("/open "..url)
        return
    end
    GameLogic.RunCommand("/open -e "..url)
end

function EducateMainPage.OpenCompeleteUrl()
    local token = commonlib.getfield("System.User.keepworktoken") or ""
    local baseurl = "https://cp.palaka.cn/home"
    local url = ""
    local http_env = HttpWrapper.GetDevVersion()
    if http_env == "LOCAL" or http_env == "STAGE" then
        baseurl = "http://cp-dev.kp-para.cn/home"
    elseif http_env == "RELEASE" then
        baseurl = "http://cp-rls.kp-para.cn/home"
    else
        baseurl = "https://cp.palaka.cn/home"
    end
    url = baseurl
    
    local platform = System.os.GetPlatform()
    if platform == "win32" or platform == "emscripten" then
        GameLogic.RunCommand("/open "..url)
        return
    end
    GameLogic.RunCommand("/open -e "..url)
end

function EducateMainPage.SetWorldSize()
    EducateProject.GetUserWorldUsedSize()
end

function EducateMainPage.GetUserName()
    local profile = KeepWorkItemManager.GetProfile()
    if profile and profile.info and profile.info.name and profile.info.name ~= "" then
        return profile.info.name
    end
    return System.User.username
end

function EducateMainPage.LoginOutByErrToken(err)
    print(commonlib.debugstack())
    local err = err or 0
    local str = "请求数据失败，错误码是"..err
    if err == 401 then
        str = str .. "，请退出重新登陆"
    elseif err == 0 then
        str = "你的网络质量差"
    end
    GameLogic.AddBBS(nil,str)
    commonlib.TimerManager.SetTimeout(function()
        if err and err == 401 then
            EducateMainPage.ClosePage()          
        end
    end, 2000)
end