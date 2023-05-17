--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-01 10:54:15
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua")
local DockConfig = NPL.export()
local worldParams;
local currentId;
local isLiked = false;
local likeCount = 0;
local isFavorited= false;
local favoriteCount = 0;

local hide_vip_world_ids = {
    ONLINE = { 18626 },
    RELEASE = { 1236 },
}

local default_filter = {
    ONLINE={79969,73104,709,852,73139,71346,55983,19405,70351,142290,119137,91605,1049714,1056645}, 
    RELEASE={20669},
    LOCAL={},
}
local dongaoIds = {
    ONLINE={119551,114607,91056,128252,128291,132939},
    RELEASE={},
    LOCAL={},
}
function GetClickStr()
    return [[NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockConfig.lua").OnClickItem("%s")]]
end

function onclick(name)
    DockConfig.OnClickItem(name)
end

_G.DOCK_CONFIG = {
    E_DOCK_DONGAO = {
        {name = "winter_camp", enabled = true, onclick=onclick, align="_lt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/WinterGames/dongao_101x93_32bits.png#0 0 101 93", },  
        {name = "papa",  enabled = true, onclick=onclick,  align="_lt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/WinterGames/papa_101x93_32bits.png#0 0 101 93", }, 
        {name = "lala",  enabled = true, onclick=onclick,  align="_lt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/WinterGames/lala_101x93_32bits.png#0 0 101 93", },    
        {name = "kaka",  enabled = true, onclick=onclick,  align="_lt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/WinterGames/kaka_101x93_32bits.png#0 0 101 93", }, 
        {name = "huanbao",  enabled = true, onclick=onclick,  align="_lt", width=100,height=90, bg ="Texture/Aries/Creator/keepwork/WinterGames/huanbao_101x93_32bits.png#0 0 101 93"},
    },
    E_DOCK_PARA = {
        {name = "esc", enabled = true, onclick=onclick,  align="_rt", sortIndex=999,  width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/xitongESC_98x94_32bits.png#0 0 100 90", },
        {name = "present",  enabled = true, onclick=onclick,  align="_rt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/btn3_libao_32bits.png#0 0 100 90", }, 
        {name = "mall", enabled = true, onclick=onclick,  align="_rt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/ziyuan_101x93_32bits.png#0 0 100 90"},
        {name = "invitefriend",  enabled = true, onclick=onclick,  align="_rt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/btn3_jieban_32bits.png#0 0 100 90", }, 
        {name = "school_center", enabled = true, onclick=onclick,  align="_rt", width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/xiaoyuan_98x94_32bits.png#0 0 100 90"},
        {name = "work", enabled = true, onclick=onclick,  align="_ctb", width=137,height=132, bg="Texture/Aries/Creator/keepwork/dock/btn_chuangzao_32bits.png#0 0 137 132"},
        {name = "explore", enabled = true, onclick=onclick,  align="_ctb", width=137,height=132, bg="Texture/Aries/Creator/keepwork/dock/btn_tansuo_32bits.png#0 0 137 132"},
        {name = "study", enabled = true, onclick=onclick,  align="_ctb", width=137,height=132, bg="Texture/Aries/Creator/keepwork/dock/btn_zhishi_32bits.png#0 0 137 132"},
        {name = "vip", enabled = true, onclick=onclick,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_huiyuan_32bits.png#0 0 85 80"},
        {name = "friends_1", enabled = true, onclick=onclick,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_haoyou_32bits.png#0 0 85 80"},
        {name = "school", enabled = true, onclick=onclick,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_xuexiao_32bits.png#0 0 85 80"},
        {name = "home", enabled = true, onclick=onclick,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_home_32bits.png#0 0 85 80"},
        {name = "character", enabled = true, onclick=onclick,  align="_rb", width = 85,height = 80, bg="Texture/Aries/Creator/keepwork/dock/btn2_renwu_32bits.png#0 0 85 80"},
        {name = "mini_map" ,width=210,enabled = true, height=248,type="special"}
    },
    E_DOCK_MINI = {
        {name = "setting", align = "_rt",enabled = true, onclick=onclick, sortIndex=999,  width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/shezhi_45x45_32bits.png#0 0 64 45",},
        {name = "share", align = "_rt",enabled = true, onclick=onclick, sortIndex=996, width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/zhuanfa_45x45_32bits.png#0 0 64 45",},
        {name = "like", align = "_rt", enabled = true, onclick=onclick, sortIndex=990, width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/meiyoudianzan_45x45_32bits.png#0 0 64 45",},
        {name = "favorite", align = "_rt", enabled = true, onclick=onclick, sortIndex=994, width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/meiyoushoucang_45x45_32bits.png#0 0 64 45",},
        {name = "mini_map" ,width=210,enabled = true,height=248,type="special"},
        {name = "mini_userinfo", enabled = true,width=363,height=100,type="special"},
    },
    E_DOCK_LESSON = {
        {name="home_point", align="_rt", enabled = true, onclick=onclick,sortIndex=997,  width = 100,height = 90,bg="Texture/Aries/Creator/keepwork/dock/fanhuichushendian_98x93_32bits.png#0 0 100 90"},
        {name="create_spage", align="_rt", enabled = true, onclick=onclick,sortIndex=998,  width = 100,height = 90,bg="Texture/Aries/Creator/keepwork/dock/fanhuichuangyi_98x93_32bits.png#0 0 100 90"},
        {name = "esc", align = "_rt", enabled = true, onclick=onclick, sortIndex=999,  width=100,height=90, bg="Texture/Aries/Creator/keepwork/dock/xitongESC_98x94_32bits.png#0 0 100 90"},
    },
    E_DOCK_NORMAL = {
        {name = "setting", align = "_rt",enabled = true, onclick=onclick, sortIndex=999,  width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/shezhi_45x45_32bits.png#0 0 64 45",},
        {name = "share", align = "_rt", enabled = true, onclick=onclick, sortIndex=996, width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/zhuanfa_45x45_32bits.png#0 0 64 45",},
        {name = "like", align = "_rt", enabled = true, onclick=onclick, sortIndex=990, width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/meiyoudianzan_45x45_32bits.png#0 0 64 45",},
        {name = "favorite", align = "_rt",enabled = true, onclick=GetClickStr(), sortIndex=994, width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/meiyoushoucang_45x45_32bits.png#0 0 64 45",}
    },
    E_DOCK_TUTORIAR = { 
        -- {name = "setting", align = "_rt",tooltip=L"系统设置", enabled = true, onclick=onclick, sortIndex=999,  width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/shezhi_45x45_32bits.png#0 0 64 45",},
        -- {name = "share", align = "_rt", tooltip=L"分享世界", enabled = true, onclick=onclick, sortIndex=996, width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/zhuanfa_45x45_32bits.png#0 0 64 45",},
        {name = "lesson", align = "_lb", tooltip=L"查看课程", enabled = true, onclick=onclick, sortIndex=995, width=206,height=116, bg="Texture/Aries/Creator/keepwork/dock/ppt_206x116_32bits.png#0 0 206 116",},
        {name = "save", align = "_rt", tooltip=L"提交作业", enabled = true, onclick=onclick, sortIndex=994, width=138,height=55, bg="Texture/Aries/Creator/keepwork/dock/zuoye_138x55_32bits.png#0 0 138 55",},
    },
    E_DOCK_PAPA = { 
        {name = "setting", align = "_rt",tooltip=L"系统设置", enabled = true, onclick=onclick, sortIndex=999,  width=64,height=45, bg="Texture/Aries/Creator/keepwork/dock/shezhi_45x45_32bits.png#0 0 64 45",},
    },
}

function DockConfig.FilterConfigByProjectId(config)
    local projectId = tonumber(GameLogic.options:GetProjectId())
    if DockConfig.IsFilterWorld(projectId) then --过滤dock的世界
        return {}
    end
    local temp = DockConfig.GetParaDockCfg(config,projectId) --并行世界
    if temp then
        return temp
    end
    if not projectId or projectId <= 0 then --普通世界没有projectId
        local temp = {}
        for k,v in pairs(config) do
            if v.name ~= "like" and v.name ~= "favorite" then
                temp[#temp + 1] = v
            end
        end
        return temp
    end
    return config
end

function DockConfig.FilterByMobilePlatform(dockCfg,dockKey)
    if System.os.IsMobilePlatform() then
        local temp= {}
        for k,v in pairs(dockCfg) do
            if v.name ~= "setting" and v.name ~= "esc" then
                temp[#temp + 1] = v
            end                
        end
        return temp
    end
    return dockCfg
end

function DockConfig.GetParaDockCfg(config,projectId)
    if DockConfig.IsParaWorld() and not DockConfig.IsShowDockPage() then
        local temp = {}
        for k,v in pairs(config) do
            if v.name == "mini_map" then
                temp[#temp + 1] = v
                break
            end
        end
        return temp
    end
    if DockConfig.IsShowDockPage() then
        local temp = {}
        for k,v in pairs(config) do
            if v.name == "present" and GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
                v.enabled = false
            end
            if v.name == "vip" and (DockConfig.IsFilterVipWorld(projectId) or System.options.isHideVip) then
                v.enabled = false
            end
        end
        for k,v in pairs(config) do
            if v.enabled then
                temp[#temp + 1] = v
            end
        end
        return temp
    end
end

function DockConfig.IsShowDockPage()
    return GameLogic.IsReadOnly() and GameLogic.options:GetProjectId() and GameLogic.GetFilters():apply_filters('is_signed_in') and DockConfig.IsParaWorld()
end

function DockConfig.IsFilterWorld(projectId)
    local projectId = tonumber(projectId)
    if projectId and projectId > 0 then
        local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
        local filters = default_filter[httpwrapper_version] or {}
        for k,v in pairs(filters) do
            if v == projectId then
                return true
            end
        end
    end
    return false
end

function DockConfig.IsFilterVipWorld(projectId)
    local projectId = tonumber(projectId)
    if projectId and projectId > 0 then
        local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
        local filters = hide_vip_world_ids[httpwrapper_version] or {}
        for k,v in pairs(filters) do
            if v == projectId then
                return true
            end
        end
    end
    return false
end

function DockConfig.IsWinterCampWorld(projectId)
    local projectId = tonumber(projectId)
    if projectId and projectId > 0 then
        local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
        local filters = dongaoIds[httpwrapper_version] or {}
        for k,v in pairs(filters) do
            if v == projectId then
                return true
            end
        end
    end
    return false
end

function DockConfig.IsAuthUserWorld()
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld');
    local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username') or ""
    if type(currentEnterWorld) == 'table' and currentEnterWorld.user and currentEnterWorld.user.username then
       return username ~= "" and username == currentEnterWorld.user.username
    end
    return false
end

function DockConfig.IsTutorialUser()
    local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
    local isReturn = RedSummerCampPPtPage.GetIsReturnOpenPage()
    local lastData = RedSummerCampPPtPage.GetLastCourseData()
    -- echo(lastData,true)
    -- print("IsTutorialUser==================",isReturn)
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local isHomeWorkWorld =  WorldCommon.GetWorldTag("isHomeWorkWorld") or false;
    local courses = {
        -- ["yyz_course"] = true,
        -- ["prepare_course"] = true,
        -- ["3D_tiyanke"]=true,
        -- ["tsyyz_test"] = true
    }
    if GameLogic.IsReadOnly() and not DockConfig.IsAuthUserWorld() then
        return false
    end
    if (lastData and isReturn and courses[lastData.code]) or isHomeWorkWorld then
        return true
    end
    return false
end

function DockConfig.IsParaWorld()
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local generatorName = WorldCommon.GetWorldTag("world_generator")
    return generatorName == "paraworld"
end

function DockConfig.IsMiniWorld()
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local generatorName = WorldCommon.GetWorldTag("world_generator")
    return generatorName == "paraworldMini"
end

function DockConfig.OnClickItem(name)
    if DockConfig.OnClickDongao(name) then
        return 
    end
    DockConfig.OnClickParaWorldDock(name)
    DockConfig.OnClickNormal(name)
end

function DockConfig.OnClickDongao(id)
    local Page = NPL.load("script/ide/System/UI/Page.lua");
    local idCnf = {
        winter_camp ="tiyujinsai",
        papa="quweibiancheng",
        lala="kuailejianzao",
        kaka="jingcaidonghua",
        huanbao="lajifenlei"
    }
    local name = idCnf[id]
    if name then
        if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
            GameLogic.RunCommand("/sendevent userVerification")
            commonlib.TimerManager.SetTimeout(function()
				_guihelper.MessageBox("你还没有完成实名认证，需要实名认证才可以参与学习。请尽快实名", nil, nil,nil,nil,nil,nil,{ ok = L"确定"});
                _guihelper.MsgBoxClick_CallBack = function(res)
                    if(res == _guihelper.DialogResult.OK) then
                        GameLogic.GetFilters():apply_filters(
                        'show_certificate',
                        function(result)
                            if (result) then                        
                                -- DockPage.RefreshPage(0.01)
                                GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                                Page.ShowWinterCampMainWindow(name)
                            end
                        end)
                    end
                end 
			end, 13000)
            return true
        end
        local profile = KeepWorkItemManager.GetProfile()
        if profile and profile.schoolId and profile.schoolId > 0 then
            Page.ShowWinterCampMainWindow(name)
            return true
        end
        GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
            KeepWorkItemManager.LoadProfile(false, function()
                local profile = KeepWorkItemManager.GetProfile()
                -- 是否选择了学校
                if profile and profile.schoolId and profile.schoolId > 0 then
                    Page.ShowWinterCampMainWindow(name)
                    return true
                end
            end)
        end);
    end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.winter_camp_main");
end

function DockConfig.OnClickParaWorldDock(id)
    if(id == "character")then
        if true then
            local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserInfoPage.lua");
            UserInfoPage.ShowPage(System.User.keepworkUsername)
        else
            GameLogic.ShowUserInfoPage({username = System.User.keepworkUsername});
        end
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.character");
    elseif(id == "work")then
		GameLogic.GetFilters():apply_filters('show_create_page');
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.work");
    elseif(id == "explore")then
        GameLogic.GetFilters():apply_filters('show_offical_worlds_page')
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.explore");
    elseif(id == "study")then
        local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
        RedSummerCampCourseScheduling.ShowView()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.study");
    elseif(id == "home")then
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.home");
        local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

        NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
        local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
        LocalLoadWorld.CreateGetHomeWorld();

        GameLogic.GetFilters():apply_filters('check_and_updated_before_enter_my_home', function()
            GameLogic.RunCommand("/loadworld home");
        end)
    elseif(id == "friends_1" or id == "friends_2")then
        local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        FriendsPage.Show();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.friends");
    elseif(id == "school")then
        GameLogic.GetFilters():apply_filters('cellar.my_school.after_selected_school', function ()
            
            KeepWorkItemManager.LoadProfile(false, function()
                local profile = KeepWorkItemManager.GetProfile()
                -- 是否选择了学校
                if profile and profile.schoolId and profile.schoolId > 0 then
                    GameLogic.QuestAction.AchieveTask("40003_1", 1, true)
                end
            end)
        end);
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.school");              
    elseif(id == "vip")then 
		local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
		VipPage.ShowPage("dock");
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.vip");
    
    elseif id == "esc" then
        GameLogic.ToggleDesktop("esc");    
    elseif (id == 'invitefriend') then
        local InviteFriend = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteFriend.lua")
        InviteFriend.ShowView()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.invitefriend");
    elseif(id == "mall")then
        local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPageV2.lua");
        KeepWorkMallPage.Show();
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.mall");
        return
    elseif(id == "school_center")then
        local SchoolCenter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolCenter/SchoolCenter.lua")
        SchoolCenter.OpenPage()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.school_center");
        return
    elseif (id == 'present') then
        if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
            GameLogic.GetFilters():apply_filters(
                'show_certificate',
                function(result)
                    if (result) then
                        GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                    end
                end
            );
        end
    elseif (id == "create_spage") then
        --GameLogic.ToggleDesktop("esc");
        GameLogic.RunCommand("/menu help.creativespace");
    elseif (id == "home_point") then
        GameLogic.RunCommand("/home");
    else
        --_guihelper.MessageBox(id);
    end
end

function DockConfig.OnClickNormal(id)
    if id == "setting" then
        print("ddddddddddddddddd",id)
        GameLogic.ToggleDesktop("esc");
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.setting");
    end
    if id == "like" then
        DockConfig.OnClickLike()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.like");
    end
    if id == "share" then
        GameLogic.RunCommand("/menu share.video_or_panorama")
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.share");
    end
    if id == "favorite" then
        if isFavorited then
            DockConfig.OnClickUnFavorite()
            GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.unfavorite");
        else
            DockConfig.OnClickFavorite()
            GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.favorite");
        end
    end
    if id == "lesson" then
        GameLogic.RunCommand("/menu help.creativespace");
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.lesson");
    end
    if id == "save" then
        local MobileSaveWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileSaveWorldPage.lua")
        MobileSaveWorldPage.ShowPage("commit_work")
        -- GameLogic.QuickSave()
        -- GameLogic.SysncHomeWorkWorld()

        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.summit");
    end
    if id ~= "setting" then
        DockConfig.HideEscPage()
    end
end

function DockConfig.HideEscPage()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EscFramePage.lua");
    local EscFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EscFramePage");
    if EscFramePage.IsVisible() then
        GameLogic.ToggleDesktop("esc");
    end
end

function DockConfig.OnClickLike()
    if isLiked then
        return 
    end
    local kpProjectId = GameLogic.options:GetProjectId()
    if not kpProjectId or tonumber(kpProjectId) == 0 then
        return
    end
	keepwork.world.star({router_params = {id = kpProjectId}}, function(err, msg, data)
		if (err == 200) then
			isLiked = true;
			GameLogic.QuestAction.SetDailyTaskValue("40012_1", nil, 1)
            DockConfig.UpdateNum()
		end
	end);
end

function DockConfig.OnClickFavorite()
    local kpProjectId = GameLogic.options:GetProjectId()
    if not kpProjectId or tonumber(kpProjectId) == 0 then
        return
    end
	keepwork.world.favorite({objectId = kpProjectId, objectType = 5}, function(err, msg, data)
		if (err == 200) then
			isFavorited = true;
            DockConfig.UpdateNum()
		end
	end);
end

function DockConfig.OnClickUnFavorite()
    local kpProjectId = GameLogic.options:GetProjectId()
    if not kpProjectId or tonumber(kpProjectId) == 0 then
        return
    end
	keepwork.world.unfavorite({objectId = kpProjectId, objectType = 5}, function(err, msg, data)
		if (err == 200) then
			isFavorited = false;
            DockConfig.UpdateNum()
		end
	end);
end

function DockConfig.UpdateNum()
    local kpProjectId = GameLogic.options:GetProjectId()
    if not kpProjectId or tonumber(kpProjectId) == 0 then
        return
    end
    keepwork.world.detail({router_params = {id = kpProjectId}}, function(err, msg, data)
        if (data) then
            likeCount = data.star or 0;
            favoriteCount = data.favorite or 0;
            DockConfig.SetLike(isLiked)
            DockConfig.SetFavorite(isFavorited)
            DockConfig.SetFavoriteNum(favoriteCount)
            DockConfig.SetLikeNum(likeCount)
        end
    end);
end

function DockConfig.Refresh(userId)
    local kpProjectId = GameLogic.options:GetProjectId()
    if not kpProjectId or tonumber(kpProjectId) == 0 then
        return
    end
	currentId = userId;
	keepwork.world.detail({router_params = {id = kpProjectId}}, function(err, msg, data)
		if (data) then
			likeCount = data.star or 0;
			favoriteCount = data.favorite or 0;
            -- print("Refresh===========",likeCount,favoriteCount)
		end
		keepwork.world.is_stared({router_params = {id = kpProjectId}}, function(err, msg, data)
			if (err == 200) then
				isLiked = data == true;
                DockConfig.SetLike(isLiked)
                DockConfig.SetLikeNum(likeCount)
			end
			keepwork.world.is_favorited({objectId = kpProjectId, objectType = 5}, function(err, msg, data)
				if (err == 200) then
					isFavorited = data == true;
                    DockConfig.SetFavorite(isFavorited)
                    DockConfig.SetFavoriteNum(favoriteCount)
				end
			end);
		end);
	end);
end

function DockConfig.SetIconData()
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local id = GameLogic.options:GetProjectId()
	id = tonumber(id);
	if (not id) then return end
	keepwork.world.detail({router_params = {id = id}}, function(err, msg, data)
		if (data and data.userId) then
			local name = WorldCommon.GetWorldTag("name");
			local world = {projectName = name, projectId = id, userId = data.userId};
            worldParams = world
            DockConfig.Refresh(worldParams.userId)
		end
	end);
end

function DockConfig.SetLike(bLike) --点赞
    local like_dock = GameLogic.DockManager:GetDockByName("like")
    if like_dock then
        local likeBg = "Texture/Aries/Creator/keepwork/dock/dianzan_45x45_32bits.png;0 0 64 45"
        if likeCount <= 0 then
            likeBg = "Texture/Aries/Creator/keepwork/dock/meiyoudianzan_45x45_32bits.png;0 0 64 45"
        end
        if bLike then
            likeBg= "Texture/Aries/Creator/keepwork/dock/dianliangdianzan_45x45_32bits.png;0 0 64 45"
        end
        like_dock:SetBackground(likeBg)
    end
end

function DockConfig.SetFavorite(bStar) --收藏
    local favorite_dock = GameLogic.DockManager:GetDockByName("favorite")
    if favorite_dock then
        local favoriteBg = "Texture/Aries/Creator/keepwork/dock/shoucang_45x45_32bits.png;0 0 64 45"
        if favoriteCount <= 0 then
           favoriteBg = "Texture/Aries/Creator/keepwork/dock/meiyoushoucang_45x45_32bits.png;0 0 64 45" 
        end
        if bStar then
            favoriteBg = "Texture/Aries/Creator/keepwork/dock/dianliangshoucang_45x45_32bits.png;0 0 64 45"
        end
        favorite_dock:SetBackground(favoriteBg)
    end
end

function DockConfig.SetFavoriteNum(num)
    local uiname = "faorite_num"
    local text = num > 0 and string.format("%d", num) or ""
    local favorite_dock = GameLogic.DockManager:GetDockByName("favorite")

    if favorite_dock and favorite_dock:IsValid() then
        local favorite_num_ui = ParaUI.GetUIObject(uiname)
        if favorite_num_ui and favorite_num_ui:IsValid() then
            ParaUI.DestroyUIObject(favorite_num_ui)
        end
        favorite_num_ui = ParaUI.CreateUIObject("text", uiname, "_lt", 0, 0, 45, 15) 
        favorite_num_ui.text = text
        favorite_num_ui.font = "System;10;norm"
        _guihelper.SetFontColor(favorite_num_ui, "#ffffff");
        _guihelper.SetUIFontFormat(favorite_num_ui, 5); 
        favorite_dock:AddChild(favorite_num_ui,0,32,uiname)
    end
end

function DockConfig.SetLikeNum(num)
    local text = num > 0 and string.format("%d", num) or ""
    local uiname = "like_num"
    local like_dock = GameLogic.DockManager:GetDockByName("like")
    if like_dock and like_dock:IsValid() then
        local like_num_ui = ParaUI.GetUIObject(uiname)
        if like_num_ui and like_num_ui:IsValid() then
            ParaUI.DestroyUIObject(like_num_ui)
        end
        like_num_ui = ParaUI.CreateUIObject("text", uiname, "_lt", 0, 0, 45, 15) 
        like_num_ui.text = text
        like_num_ui.font = "System;10;norm"
        _guihelper.SetUIFontFormat(like_num_ui, 5); --设置字体居中
        _guihelper.SetFontColor(like_num_ui, "#ffffff");
        like_dock:AddChild(like_num_ui,0,32,uiname)
    end
end


