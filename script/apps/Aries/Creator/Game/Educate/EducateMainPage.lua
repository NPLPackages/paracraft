--[[
    author:{pbb}
    time:2023-02-14 19:42:52
    uselib:
        local EducateMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/EducateMainPage.lua")
        EducateMainPage.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local EducateProject = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProject.lua")
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
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
    {value = L"大赛详情"}
}
EducateMainPage.IsGetLessonData = false
EducateMainPage.LessonData = nil
EducateMainPage.IsShowLesson = false
EducateMainPage.IsFirstLogin = nil
local last_audio_src
function EducateMainPage.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = EducateMainPage.OnCreate
    GameLogic.GetFilters():add_filter("click_create_new_world",EducateMainPage.SetShowCreateWorld)
    GameLogic.GetFilters():add_filter("show_my_works",EducateMainPage.ChangeTabIndex)
    GameLogic.GetFilters():add_filter("OnWorldCreate",  EducateMainPage.OnWorldCreated)
end

function EducateMainPage.OnCreate()
    EducateMainPage.CheckShowLesson()
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
    EducateMainPage.isShowCreateWorld = true
    EducateMainPage.tab_view_index = nil
    EducateMainPage.RefreshPage(true)
end

function EducateMainPage.ShowPage()
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
    CustomCharItems:Init();

	local Game = commonlib.gettable("MyCompany.Aries.Game")
	if(Game.is_started) then
		Game.Exit()
	end
    ParaUI.GetUIObject('root'):RemoveAll()
    -- EducateMainPage.StopMusic()
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
    
    EducateProject.ShowCreate()
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if(params._page ) then
		params._page.OnClose = function(bDestroy)
			EducateProject.CloseCreate()
		end
	end

    if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", function ()
            local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
            local profile = KeepWorkItemManager.GetProfile()
            if not profile then
                return 
            end
            if profile.portrait then
                page:SetValue("img_protrait",profile.portrait)
            end
            page:SetValue("txt_user",EducateMainPage.GetUserName())
		end)
	end

    GameLogic.GetFilters():add_filter("on_start_login", function()
        EducateMainPage.IsFirstLogin = nil
    end);
    EducateMainPage.CheckHasSignUpActivity()
end

function EducateMainPage.CheckHasSignUpActivity()
    local cache_policy = 'access plus 0'
    local getMyActivity = commonlib.getfield('keepwork.quiz.getMyActivity')
    getMyActivity({
        cache_policy = cache_policy
    }, function(err, msg, data)
        if data and data.data ~= nil and data.data.id then
            echo(data, true)
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

                local inRange = (startTimestamp == nil or endTimestamp==nil) and false or (startTimestamp < serverTimestamp and serverTimestamp <= endTimestamp)
                if not allComplete and inRange then
                    EducateMainPage.CommonAlert(
                        string.format("你报名参加了%s，是否前往赛事？",
                            (data.data.name ~= nil and data.data.name ~= "") and data.data.name or "赛事"), true,
                        function()
                            if data.data.entranceProjectId ~= nil then
                                GameLogic.RunCommand(string.format("/loadworld -s %s", data.data.entranceProjectId))
                            end
                        end)
                end
            end)
        end
    end)
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
    if index and index == 3 then
        EducateMainPage.CheckHasSignUpActivity()
        EducateMainPage.OpenCompeleteUrl()
        return
    end
    EducateMainPage.isShowCreateWorld = false
    if index and index > 0 and index ~= EducateMainPage.tab_view_index then
        EducateMainPage.tab_view_index = index
        if index ~= 1 then
            EducateProject.CloseCreate()
        else
            EducateMainPage.SetWorldSize()
        end
        if EducateMainPage.tab_view_index == 2 then
            EducateMainPage.curr_course_page = 1
        end
        EducateMainPage.RefreshPage()
    end
end

function EducateMainPage.CheckShowLesson()
    local lessonNode = ParaUI.GetUIObject("lesson_button_bg")
    if not lessonNode:IsValid() then
        return 
    end
    keepwork.classrooms.query({}, function(err, msg, data)
        if err == 200 then
            EducateMainPage.IsShowLesson = false
            if data and data.rows and #data.rows > 0 and data.count> 0 then
                EducateMainPage.LessonData = data
                EducateMainPage.IsShowLesson = true       
            end
            lessonNode.visible = EducateMainPage.IsShowLesson
            EducateMainPage.UpdateLessonRedTip(data,EducateMainPage.IsShowLesson)
            -- if EducateMainPage.IsShowLesson and not EducateMainPage.IsFirstLogin then
            --     EducateMainPage.PlaySound()
            -- end
            commonlib.TimerManager.SetTimeout(function()
                if EducateMainPage.IsShowLesson and not EducateMainPage.IsFirstLogin then
                    EducateMainPage.OnClickLesson()
                    EducateMainPage.IsFirstLogin = true
                    EducateMainPage.PlaySound()
                end
            end, 2000)
            
            return
        end
        EducateMainPage.IsShowLesson = false
        lessonNode.visible = EducateMainPage.IsShowLesson
    end)
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
    NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/ClassSelectPage.lua").ShowView(EducateMainPage.LessonData);
end

function EducateMainPage.ClosePage()
    if page then
        page:CloseWindow();
        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
        KeepworkServiceSession:Logout(nil, function()
        Mod.WorldShare.MsgBox:Close()
            local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
            CreateNewWorld.profile = nil
            EducateMainPage.ResetParams()
            System.options.cmdline_world = nil
            MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
            MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
            MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
            MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
            MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
        end)
        page = nil
    end
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
    local token = commonlib.getfield("System.User.keepworktoken")
    local baseurl = "http://edu-dev.kp-para.cn/login?"
    local url = ""
    local http_env = HttpWrapper.GetDevVersion()
    if http_env == "LOCAL" or http_env == "STAGE" then
        baseurl = "http://edu-dev.kp-para.cn/login?"
    elseif http_env == "RELEASE" then
        baseurl = "http://edu-dev.kp-para.cn/login?"
    else
        baseurl = "http://edu.palaka.cn/login?"
    end
    url = baseurl.."token="..token.."&type=PC"
    GameLogic.RunCommand("/open "..url)

end

function EducateMainPage.OpenCompeleteUrl()
    local token = commonlib.getfield("System.User.keepworktoken")
    local baseurl = "https://keepwork.com/cp/home?"
    local url = baseurl.."token="..token
    GameLogic.RunCommand("/open "..url)
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