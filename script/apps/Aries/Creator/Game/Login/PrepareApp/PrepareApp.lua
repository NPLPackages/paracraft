--[[
Title: PrepareApp
Author(s): hyz
Date: 2022/8/15
Desc:  处理APP启动时预加载工作
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/PrepareApp/PrepareApp.lua");
local PrepareApp = commonlib.gettable("MyCompany.Aries.Game.PrepareApp");
PrepareApp.ShowPage()
--]]

local LuaCallbackHandler = NPL.load("(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
NPL.load("(gl)script/ide/FileLoader.lua");
local FileLoader = commonlib.gettable("CommonCtrl.FileLoader")

local PrepareApp = commonlib.gettable("MyCompany.Aries.Game.PrepareApp");

local _assetsList = {}
local _this = PrepareApp
local page
function PrepareApp.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = PrepareApp.OnClosed;
    page.OnCreate = PrepareApp.OnCreated;
end

function PrepareApp.OnCreated()

    
end

function PrepareApp.OnClosed()
    page = nil 
end

function PrepareApp.ShowPage()
    local url = "script/apps/Aries/Creator/Game/Login/PrepareApp/PrepareAppPage.html"

	local params = {
		url = url, 
		name = "PrepareApp.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		zorder = -2,
		bShow = bShow,
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
		cancelShowAnimation = true,
		enable_esc_key = true
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);

end

function PrepareApp.start()
    PrepareApp.ShowPage()

    PrepareApp._curProgress = 0;
    PrepareApp.bar_progress = 0;
    PrepareApp.state = {};
    

    PrepareApp.next_step()

    PrepareApp.StopProgressTimer()
    PrepareApp._progressTimer = commonlib.Timer:new({callbackFunc=PrepareApp.OnFrameMove})
    PrepareApp._progressTimer:Change(0,30)
end

function PrepareApp.StopProgressTimer()
    if PrepareApp._progressTimer then
        PrepareApp._progressTimer:Change()
        PrepareApp._progressTimer = nil 
    end
end

--刷新进度条
function PrepareApp.OnFrameMove(timer)
    local to = math.min(PrepareApp._curProgress,100);
    if to<=0 then
        return
    end

    if  PrepareApp.bar_progress<to then
        PrepareApp._waitBegin = nil
        local deltaTime = timer:GetDelta();

        PrepareApp.bar_progress = PrepareApp.bar_progress + (to-PrepareApp.bar_progress)*0.1+deltaTime*0.1;
        if PrepareApp.bar_progress>to then 
            PrepareApp.bar_progress = to 
        end
        if PrepareApp.bar_progress>=100 then
            PrepareApp.StopProgressTimer()
            PrepareApp.next_step({bHasCheckAsset = true})
        end
        PrepareApp.SetBarProgress(PrepareApp.bar_progress)
    else
        local _now = os.clock()
        if PrepareApp._waitBegin==nil then
            PrepareApp._waitBegin = _now
        else
            local waitTime = _now - PrepareApp._waitBegin;
            if waitTime>60 then --长时间没进度,看看卡在哪里了
                print("--------waitTime",waitTime)
                if to>=40 then
                    PrepareApp._waitBegin = nil
                    PrepareApp.CheckNetWork(function(bSuccess)
                        print("PrepareApp._hasNetWork",PrepareApp._hasNetWork)
                        PrepareApp._hasNetWork = bSuccess
                        if PrepareApp._hasNetWork then
                            PrepareApp.CheckAsset()
                        else
                            PrepareApp.CheckAssetWithoutNetwork()
                        end
                    end)
                end
            end
        end
    end
end

function PrepareApp.next_step(state_update)
    local state = _this.state;
	if(state_update) then
		commonlib.partialcopy(state, state_update);
	end

    if not state.bHasCheckReadPermission then
        PrepareApp.CheckReadPermission(function()
            PrepareApp._curProgress = PrepareApp._curProgress + 10
            PrepareApp.next_step({bHasCheckReadPermission = true})
        end)
    elseif not state.bHasCheckWritePermission then
        PrepareApp.CheckWritePermission(function()
            PrepareApp._curProgress = PrepareApp._curProgress + 10
            PrepareApp.next_step({bHasCheckWritePermission = true})
        end)
    elseif not state.bHasCheckNetWork then
        if System.options.cmdline_world and System.options.cmdline_world~="" then
            PrepareApp._hasNetWork = true
            PrepareApp._curProgress = PrepareApp._curProgress + 20
            PrepareApp.next_step({bHasCheckNetWork = true})
        else
            PrepareApp.CheckNetWork(function(bSuccess)
                PrepareApp._hasNetWork = bSuccess
                PrepareApp._curProgress = PrepareApp._curProgress + 20
                PrepareApp.next_step({bHasCheckNetWork = true})
            end)
        end
    elseif not state.bHasCheckAsset then
        if PrepareApp._hasNetWork then
            PrepareApp.CheckAsset()
        else
            PrepareApp.CheckAssetWithoutNetwork()
        end
    elseif not state.bHasLoadScripts then
        PrepareApp.LoadScripts(function()
            PrepareApp.next_step({bHasLoadScripts = true})
        end)
    elseif not state.bHasPreloadTextures then
        PrepareApp.PreloadTextures(function()
            PrepareApp.next_step({bHasPreloadTextures = true})
        end,3000)
    else
        MainLogin:next_step({PrepareApp = true});
    end
end

--检查根目录读写权限
function PrepareApp.CheckReadPermission(callback)
    PrepareApp.SetStateTip(L"正在检查读权限...")
    PrepareApp._curProgress = 0
    
    local root = ParaIO.GetCurDirectory(0)
    local verTxt = root.."version.txt"
    local file;
    if ParaIO.DoesFileExist(verTxt) then 
        file = ParaIO.open(verTxt,"r")
    else
        file = ParaIO.open(root.."npl_packages/ParacraftBuildinMod.zip","r")
    end
    if file and file:IsValid() then
        file:close()
        
        if callback then
            callback()
        end
    else
        PrepareApp.ShowExitAlert(L"安装目录没有文件读取权限")
    end
end

--检查根目录读写权限
function PrepareApp.CheckWritePermission(callback)
    PrepareApp.SetStateTip(L"正在检查写权限...")

    local root = ParaIO.GetCurDirectory(0)
    local temp = root.."temp/"
    if not ParaIO.DoesFileExist(temp) then
        ParaIO.CreateDirectory(temp)
    end
    
    local tempWriteFile = ParaIO.open(temp.."tempWriteFile.txt","w")
    if tempWriteFile:IsValid() then
        tempWriteFile:close()
        ParaIO.DeleteFile(temp.."tempWriteFile.txt")
        if callback then
            callback()
        end
    else
        PrepareApp.ShowExitAlert(L"安装目录没有写文件权限")
    end
end

-- ping version server for network connection 
function PrepareApp.CheckNetWork(callback)
    PrepareApp.SetStateTip(L"正在检查网络状态...")
    
	local SKIP_NETWORK_CHECK = true;
	if(SKIP_NETWORK_CHECK) then
		callback(true)
		return
	end

    local cmdStr = "ping tmlog.paraengine.com -n 1"
    local _pingFunc;
    _pingFunc = function(tryAcc)
        local _begin = os.clock()
        ParaGlobal.ShellExecute("popen",cmdStr,"isAsync",LuaCallbackHandler.createHandler(function(msg)
            local str = commonlib.Encoding.DefaultToUtf8(msg.ret)
            local hasIp = string.match(str,"%[%d+.%d+.%d+.%d+%]")
            if hasIp then
                if callback then
                    callback(true)
                end
            else
                print("tryAcc",tryAcc,str)
                if tryAcc==3 then
                    
                    if callback then
                        callback(false)
                    end
                else
                    _pingFunc(tryAcc+1)
                end
            end
        end))
    end

    local _testDownloadFunc;
    _testDownloadFunc = function(tryAcc)
        local version_url = "http://tmlog.paraengine.com/version.php"
        version_url = string.format("%s?v=%s",version_url,ParaGlobal.GetDateFormat("yyyy-M-d"));
        System.os.GetUrl(version_url, function(err, msg, data)
	        if(err == 200)then
                if callback then
                    callback(true)
                end
            else
                print("-----err",err,"tryAcc",tryAcc,os.clock())
                if tryAcc==3 then
                    _pingFunc(1)
                else
                    commonlib.TimerManager.SetTimeout(function()
                        _testDownloadFunc(tryAcc+1)
                    end,1000)
                end
            end 
        end)
    end
    _testDownloadFunc(1)
end

--没有网络，检查一下登录界面用到的资源，如果有本地缓存，允许进入登录界面
function PrepareApp.CheckAssetWithoutNetwork()
    if not _this._hasNetWork then 
        local count = 0
        for _,key in ipairs(_loginAssetsList) do
            local status = ParaIO.CheckAssetFile(key)
            if status==1 then
                count = count + 1
            else
                -- print(key,"status",status)
            end
        end
        local len = #_loginAssetsList
        print("-----xx-len",len,"count",count)
        if len>0 and count/len>0.6 then --大部分登录界面的图已经缓存过了
            _this._curProgress = 100
        else
            PrepareApp.ShowExitAlert(L"连接网络失败，请检查网络状况")
        end
    end
end

--检查并下载必要资源
function PrepareApp.CheckAsset()
    PrepareApp.SetStateTip(L"正在检查基础资源...")

    --先保证缓存文件夹创建成功
    local root = ParaIO.GetCurDirectory(0)
    local temp = root.."temp/"
    if not ParaIO.DoesFileExist(temp) then
        ParaIO.CreateDirectory(temp)
    end
    local arr = {"cache","filecache"}
    for k,v in pairs(arr) do 
        if not ParaIO.DoesFileExist(temp..v.."/") then
            ParaIO.CreateDirectory(temp..v.."/")
        end
    end
    local arr = {}
    for i=0,9 do table.insert(arr,i) end
    for i=1,26 do table.insert(arr,string.char(i+96)) end
    for k,v in pairs(arr) do 
        if not ParaIO.DoesFileExist(temp.."cache/"..v.."/") then
            ParaIO.CreateDirectory(temp.."cache/"..v.."/")
        end
    end
    
    -- commonlib.Files.GetRemoteFileText()
    
    local file_list = {}
    for _,key in ipairs(_assetsList) do
        local status = ParaIO.CheckAssetFile(key)
        if status~=1 and status~=-4 and status~=-1 then
            -- print(key,"status",status)
            table.insert(file_list,{
                filename = key,
                filesize = 1,
            })
        end
    end

    if #file_list==0 then 
        _this._curProgress = 100
    else
        if(not _this.loader)then
            _this.loader = FileLoader:new{
                logname = "log/prepare_app_loader",
            };
        end
        _this.loader:SetDownloadList(file_list);
        
        _this.loader:AddEventListener("start",function(self,event)
            PrepareApp.SetStateTip(L"正在下载基础资源...")
        end,{});
        _this.loader:AddEventListener("loading",function(self,event)
            _this._curProgress = 40 + event.percent*60
        end,{});
        _this.loader:AddEventListener("finish",function(_this,event)
            _this._curProgress = 100
        end,{});
        _this.loader:Start();
    end
end

--一些耗时的脚本层初始化工作
function PrepareApp.LoadScripts(callback)
    NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
    local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
    BadWordFilter.Init();
    if callback then
        callback()
    end
end

--预加载图片资源，减少显示page时，图片的加载时间
function PrepareApp.PreloadTextures(callback,maxTime)
    local list = {
        "Texture/Aries/Creator/keepwork/worldshare_32bits.png"
    }
    NPL.load("(gl)script/ide/AssetPreloader.lua");

    local _timer = nil
    local _isDone = false
    local function onDone()
        if not _isDone then
            _isDone = true
            if callback then
                callback()
            end
        end
    end

    local loader = commonlib.AssetPreloader:new({ callbackFunc = function(nItemsLeft, loader)
        if nItemsLeft==0 then
            if _timer then
                _timer:Change()
                _timer = nil
            end
            onDone()
        end
    end });
    for k,v in ipairs(list) do 
        loader:AddAssets(ParaAsset.LoadTexture("", v, 1));
    end
    
    loader:Start();

    _timer = commonlib.TimerManager.SetTimeout(onDone,maxTime)
end

function PrepareApp.SetBarProgress(percent)
    local progress_fg = ParaUI.GetUIObject("progress_fg")
    progress_fg.width = math.floor(500*(percent*0.01))
    progress_fg.background = string.format("Mod/WorldShare/Texture/progress_fg_500x36_32bits.png#0 0 %s 36;",progress_fg.width)
end

function PrepareApp.SetStateTip(str)
    if page then
        page:SetUIValue("text_state_tip",str)
    end
end

function PrepareApp.ShowExitAlert(str)
    PrepareApp.StopProgressTimer()

    local url = string.format("script/apps/Aries/Creator/Game/Login/PrepareApp/ExitAlert.html?tip=%s",str)

	local params = {
		url = url, 
		name = "PrepareApp.ShowExitAlert", 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		zorder = -2,
		bShow = bShow,
		directPosition = true,
			align = "_ct",
			x = -488*0.5,
			y = -234*0.5 + 0,
			width = 488,
			height = 234,
		cancelShowAnimation = true,
        -- isTopLevel = true,
		enable_esc_key = true,

	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

_assetsList = {
    --texture
    "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png",
    "Texture/3DMapSystem/common/ThemeLightBlue/slider_background_16.png",
    "Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png",
    "Texture/Aries/ChatSystem/arrow1_32bits.png",
    "Texture/Aries/ChatSystem/arrow2_32bits.png",
    "Texture/Aries/ChatSystem/arrow3_32bits.png",
    "Texture/Aries/ChatSystem/gundongtiaobg_32bits.png",
    "Texture/Aries/ChatSystem/jiahao_32bits.png",
    "Texture/Aries/Common/AssetLoader_32bits.png",
    "Texture/Aries/Common/ThemeKid/dropdown_bg.png",
    "Texture/Aries/Common/ThemeKid/editbox_32bits.png",
    "Texture/Aries/Common/bbs_toast_bg_846x45_32bits.png",
    "Texture/Aries/Common/underline_white_32bits.png",
    "Texture/Aries/Creator/Mobile/blocks_Background.png",
    "Texture/Aries/Creator/Paracraft/dengluye_1280x720_32bits.png",
    "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png",
    "Texture/Aries/Creator/Theme/scroll_track_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/10_86X86_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/11_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/16_112X112_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/17_86X86_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/2_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/4_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/5_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/6_112X112_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/7_86X86_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/9_86X86_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/shang_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/xia_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/you_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/zi1_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/zi2_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/zi3_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/zi4_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/MiniKey/zuo_94X88_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/baitiao_32x32_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/banjikebiao_141x55_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/courses_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/hengxian_16x1_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/jiantou_12x8_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/jiarubanji_111x44_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/kebiao_1129x193_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/kebiao_1130x133_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/riqi_116x36_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/riqiwanghou_17x24_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/riqiwangqian_17x24_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/watermark_bg_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/weilaikecheng_17x17_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/weishangke_17x17_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/xingqi_1130x39_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/yishangke_17x17_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/zanwukecheng_331x120_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/zhunbeishangke_17x17_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/cankaoziliao_142x54_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/chuangyilogo_146x47_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/kechengtubiao_35x35_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/shuoming_27x27_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/sousuo_48x37_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/weixuanzhon_231x145_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/wodekebao_108x44_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/xiaoanniu(hui)_88x44_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/xuanzhon_231x145_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/zuijinlogo_66x36_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/anniu_191x39_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/b4_279X110_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/bangzhu_97X27_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/bj2_478X77_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/bjk2_64X51_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/bjk_64X64_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/btn3_64X70_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/chuangyikongjian_334x368_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/di_32X60_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/laba_44x41_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/touxiang3_96X96_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/tuijianzuoping_334x421_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/main/zixueshiping_334x421_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/shentongbei/shentongbei_32bits.png",
    "Texture/Aries/Creator/keepwork/RedSummerCamp/works/works_32bits.png",
    "Texture/Aries/Creator/keepwork/UserInfo/blue_v_32bits.png",
    "Texture/Aries/Creator/keepwork/UserInfo/crown_32bits.png",
    "Texture/Aries/Creator/keepwork/Window/button/btn_hui109X45_32bits.png",
    "Texture/Aries/Creator/keepwork/Window/dakuang2_32bits.png",
    "Texture/Aries/Creator/keepwork/Window/tooltip/tipbj_32bits.png",
    "Texture/Aries/Creator/keepwork/dock/dianliangshoucang_45x45_32bits.png",
    "Texture/Aries/Creator/keepwork/dock/dianzan_45x45_32bits.png",
    "Texture/Aries/Creator/keepwork/dock/meiyoudianzan_45x45_32bits.png",
    "Texture/Aries/Creator/keepwork/dock/meiyoushoucang_45x45_32bits.png",
    "Texture/Aries/Creator/keepwork/dock/shezhi_45x45_32bits.png",
    "Texture/Aries/Creator/keepwork/map/btn_E_32X32_32bits.png",
    "Texture/Aries/Creator/keepwork/map/btn_R_32X32_32bits.png",
    "Texture/Aries/Creator/keepwork/vip/shuzishuru_32X32_32bits.png",
    "Texture/Aries/Creator/keepwork/worldshare/icon3_16X16_32bits.png",
    "Texture/Aries/Creator/keepwork/worldshare/mima_32X32_32bits.png",
    "Texture/Aries/Creator/keepwork/worldshare/remind_bg_53X64_32bits.png",
    "Texture/Aries/Creator/keepwork/worldshare/warn_32X32_32bits.png",
    "Texture/Aries/Creator/keepwork/worldshare_32bits.png",
    "Texture/Aries/Creator/paracraft/login/menu_bg_36X36_32bits.png",
    "Texture/Aries/Creator/paracraft/login/plug_16x16_32bits.png",
    "Texture/Aries/Creator/paracraft/login/server_16x16_32bits.png",
    "Texture/Aries/Creator/paracraft/login/setting_120X44_32bits.png",
    "Texture/Aries/Creator/paracraft/paracraft_explorer_32bits.png",
    "Texture/Aries/Creator/paracraft/paracraft_icon_01_32bits.png",
    "Texture/Aries/Creator/paracraft/paracraft_login_32bits.png",
    "Texture/Aries/Login/Login/teen/loading_gray_32bits.png",
    "Texture/Aries/Login/Login/teen/loading_green_32bits.png",
    "Texture/Aries/Login/Login/teen/progressbar_green_tile.png",
    "Texture/Aries/NPCs/RainbowFlower/Clock_bg_32bits.png",
    "Texture/Aries/NPCs/RainbowFlower/time_bg_32bits.png",
    "Texture/Aries/Quest/TutorialMouse_LeftClick_small_32bits.png",
    "Texture/blocks/1000_Tomato.png",
    "Texture/blocks/1001_Wheat.png",
    "Texture/blocks/Chest.png",
    "Texture/blocks/CmdTextureReplacer.png",
    "Texture/blocks/CustomGeoset/body/84082_Avatar_girl_body_72.png",
    "Texture/blocks/CustomGeoset/body/shirt_02_Avatar_boy_body_01.png",
    "Texture/blocks/CustomGeoset/body/shirt_04_paizinan1.png",
    "Texture/blocks/CustomGeoset/hair/1_Avatar_boy_hair_00.png",
    "Texture/blocks/CustomGeoset/hair/hair_16_tou.png",
    "Texture/blocks/CustomGeoset/leg/85087_Avatar_boy_leg_77.png",
    "Texture/blocks/CustomGeoset/leg/85101_Avatar_boy_leg_91.png",
    "Texture/blocks/CustomGeoset/leg/Avatar_boy_leg_xiangyu00.png",
    "Texture/blocks/CustomGeoset/main/Avatar_tsj.png",
    "Texture/blocks/ItemFrame.png",
    "Texture/blocks/Jukebox.png",
    "Texture/blocks/Paperman/eye/eye_02_blackman.png",
    "Texture/blocks/Paperman/eye/eye_boy_fps10_a001.png",
    "Texture/blocks/Paperman/mouth/mouth_boy_fps10_a001.png",
    "Texture/blocks/Piston.png",
    "Texture/blocks/Piston_Viscous.png",
    "Texture/blocks/Redstone_Button_off.png",
    "Texture/blocks/Redstone_Button_on.png",
    "Texture/blocks/Redstone_Repeater_off.png",
    "Texture/blocks/Redstone_Repeater_on1.png",
    "Texture/blocks/Redstone_Repeater_on2.png",
    "Texture/blocks/Redstone_Repeater_on3.png",
    "Texture/blocks/Redstone_Repeater_on4.png",
    "Texture/blocks/Redstone_Wire_mip1.png",
    "Texture/blocks/TeleportStone.png",
    "Texture/blocks/agentsign.png",
    "Texture/blocks/arrow.png",
    "Texture/blocks/bedrock.png",
    "Texture/blocks/bloodstain.png",
    "Texture/blocks/bookshelf_three.png",
    "Texture/blocks/box_three.png",
    "Texture/blocks/brick.png",
    "Texture/blocks/cake_top.png",
    "Texture/blocks/clay.png",
    "Texture/blocks/coal_ore.png",
    "Texture/blocks/cobblestone.png",
    "Texture/blocks/cobblestone_mossy.png",
    "Texture/blocks/codeblock_off.png",
    "Texture/blocks/codeblock_on.png",
    "Texture/blocks/colorblock.png",
    "Texture/blocks/command_block.png",
    "Texture/blocks/command_block_on.png",
    "Texture/blocks/deadbush.png",
    "Texture/blocks/destroy.png",
    "Texture/blocks/diamond_block_new.png",
    "Texture/blocks/diamond_ore.png",
    "Texture/blocks/dirt.png",
    "Texture/blocks/door_iron_lower.png",
    "Texture/blocks/door_iron_upper.png",
    "Texture/blocks/door_wood_lower.png",
    "Texture/blocks/door_wood_upper.png",
    "Texture/blocks/doortop_three.png",
    "Texture/blocks/drum.png",
    "Texture/blocks/emerald_block_new.png",
    "Texture/blocks/emerald_ore.png",
    "Texture/blocks/end_stone.png",
    "Texture/blocks/farmland_dry.png",
    "Texture/blocks/fern.png",
    "Texture/blocks/flower_dandelion.png",
    "Texture/blocks/flower_rose.png",
    "Texture/blocks/glass09.png",
    "Texture/blocks/glass_pane.png",
    "Texture/blocks/gold_block_new.png",
    "Texture/blocks/gold_ore.png",
    "Texture/blocks/grass_top.png",
    "Texture/blocks/gravel.png",
    "Texture/blocks/hay_block_three.png",
    "Texture/blocks/ice.png",
    "Texture/blocks/ice_single.png",
    "Texture/blocks/iron_bars.png",
    "Texture/blocks/iron_block_new.png",
    "Texture/blocks/iron_ore.png",
    "Texture/blocks/items/spawnpoint.png",
    "Texture/blocks/items/test32x32.png",
    "Texture/blocks/items/textframe.png",
    "Texture/blocks/items/waterdrop.png",
    "Texture/blocks/ladder.png",
    "Texture/blocks/lapis_block_new.png",
    "Texture/blocks/lapis_ore.png",
    "Texture/blocks/lava/lava_fps10_a010.png",
    "Texture/blocks/leaves_birch.png",
    "Texture/blocks/leaves_cactus_three.png",
    "Texture/blocks/leaves_jungle.png",
    "Texture/blocks/leaves_oak.png",
    "Texture/blocks/leaves_spruce.png",
    "Texture/blocks/log_birch_three.png",
    "Texture/blocks/log_jungle_three.png",
    "Texture/blocks/log_oak_three.png",
    "Texture/blocks/log_spruce_three.png",
    "Texture/blocks/melon_three.png",
    "Texture/blocks/metal_normal.png",
    "Texture/blocks/mirror.png",
    "Texture/blocks/movie_three.png",
    "Texture/blocks/mushroom_brown.png",
    "Texture/blocks/mushroom_red.png",
    "Texture/blocks/mycelium_three.png",
    "Texture/blocks/nether_brick.png",
    "Texture/blocks/netherrack.png",
    "Texture/blocks/noteblock.png",
    "Texture/blocks/nplcad3block_off.png",
    "Texture/blocks/nplcad3block_on.png",
    "Texture/blocks/obsidian.png",
    "Texture/blocks/particle_rain.png",
    "Texture/blocks/particle_rain_splash.png",
    "Texture/blocks/particle_snow.png",
    "Texture/blocks/pink_leaves.png",
    "Texture/blocks/piston_top_normal.png",
    "Texture/blocks/planks_birch.png",
    "Texture/blocks/planks_jungle.png",
    "Texture/blocks/planks_oak.png",
    "Texture/blocks/planks_spruce.png",
    "Texture/blocks/pumpkinLight_three.png",
    "Texture/blocks/pumpkin_three.png",
    "Texture/blocks/quartz_block_chiseled_top.png",
    "Texture/blocks/quartz_block_lines_top.png",
    "Texture/blocks/quartz_block_top.png",
    "Texture/blocks/quartz_ore.png",
    "Texture/blocks/rail_activator.png",
    "Texture/blocks/rail_activator_powered.png",
    "Texture/blocks/rail_detector.png",
    "Texture/blocks/rail_normal.png",
    "Texture/blocks/redstoneLight_lit.png",
    "Texture/blocks/redstone_block_new.png",
    "Texture/blocks/redstone_conductor_off.png",
    "Texture/blocks/redstone_conductor_on.png",
    "Texture/blocks/redstone_lamp_off.png",
    "Texture/blocks/redstone_lamp_on.png",
    "Texture/blocks/redstone_ore.png",
    "Texture/blocks/redstone_torch_off.png",
    "Texture/blocks/redstone_torch_on.png",
    "Texture/blocks/reeds.png",
    "Texture/blocks/sand.png",
    "Texture/blocks/sandstone_carved_three.png",
    "Texture/blocks/sandstone_smooth_three.png",
    "Texture/blocks/sandstone_three.png",
    "Texture/blocks/sandstone_top.png",
    "Texture/blocks/sapling_birch.png",
    "Texture/blocks/sapling_jungle.png",
    "Texture/blocks/sapling_oak.png",
    "Texture/blocks/sapling_spruce.png",
    "Texture/blocks/sensor_stone.png",
    "Texture/blocks/snow.png",
    "Texture/blocks/snow_dirt_three.png",
    "Texture/blocks/soul_sand.png",
    "Texture/blocks/sponge.png",
    "Texture/blocks/state_green.png",
    "Texture/blocks/state_grey.png",
    "Texture/blocks/state_hint.png",
    "Texture/blocks/state_red.png",
    "Texture/blocks/state_white.png",
    "Texture/blocks/stone.png",
    "Texture/blocks/stone_glow.png",
    "Texture/blocks/stone_slab_three.png",
    "Texture/blocks/stonebrick.png",
    "Texture/blocks/stonebrick_chiseled.png",
    "Texture/blocks/stonebrick_cracked.png",
    "Texture/blocks/stonebrick_mossy.png",
    "Texture/blocks/tnt_three.png",
    "Texture/blocks/top_grass_three.png",
    "Texture/blocks/torch.png",
    "Texture/blocks/transparent_colorblock.png",
    "Texture/blocks/trapdoor.png",
    "Texture/blocks/vine.png",
    "Texture/blocks/water/water_fps10_a009.png",
    "Texture/blocks/waterlily.png",
    "Texture/blocks/web.png",
    "Texture/blocks/wheat_stage_0.png",
    "Texture/blocks/wool_colored_black.png",
    "Texture/blocks/wool_colored_blue.png",
    "Texture/blocks/wool_colored_brown.png",
    "Texture/blocks/wool_colored_cyan.png",
    "Texture/blocks/wool_colored_gray.png",
    "Texture/blocks/wool_colored_green.png",
    "Texture/blocks/wool_colored_light_blue.png",
    "Texture/blocks/wool_colored_lime.png",
    "Texture/blocks/wool_colored_magenta.png",
    "Texture/blocks/wool_colored_orange.png",
    "Texture/blocks/wool_colored_pink.png",
    "Texture/blocks/wool_colored_purple.png",
    "Texture/blocks/wool_colored_red.png",
    "Texture/blocks/wool_colored_silver.png",
    "Texture/blocks/wool_colored_white.png",
    "Texture/blocks/wool_colored_yellow.png",
    "Texture/common/Sunset.dds",
    "Texture/common/cloud.dds",
    "Texture/dxutcontrols.dds",
    "Texture/ripple.dds",
    "Texture/ripple/WaterBumpMap.dds",
    "Texture/tileset/blocks/carpet_block_single.dds",
    "Texture/tileset/blocks/doortop_three.dds",
    "Texture/tileset/blocks/earth2_single.dds",
    "Texture/tileset/blocks/earth_purple_single.dds",
    "Texture/tileset/blocks/earth_single.dds",
    "Texture/tileset/blocks/ice2_single.dds",
    "Texture/tileset/blocks/ladder_three.dds",
    "Texture/tileset/blocks/leaf_single.dds",
    "Texture/tileset/blocks/leaves_blue_single.dds",
    "Texture/tileset/blocks/leaves_brown_single.dds",
    "Texture/tileset/blocks/leaves_green_single.dds",
    "Texture/tileset/blocks/leaves_greenlight_single.dds",
    "Texture/tileset/blocks/leaves_orange_single.dds",
    "Texture/tileset/blocks/leaves_purple_single.dds",
    "Texture/tileset/blocks/leaves_purpledark_single.dds",
    "Texture/tileset/blocks/leaves_red_single.dds",
    "Texture/tileset/blocks/leaves_reddrak_single.dds",
    "Texture/tileset/blocks/leaves_yellow_single.dds",
    "Texture/tileset/blocks/roof_blue_single.dds",
    "Texture/tileset/blocks/roof_brown_single.dds",
    "Texture/tileset/blocks/roof_green_single.dds",
    "Texture/tileset/blocks/roof_pink_single.dds",
    "Texture/tileset/blocks/roof_purple_single.dds",
    "Texture/tileset/blocks/roof_red_single.dds",
    "Texture/tileset/blocks/roof_white_single.dds",
    "Texture/tileset/blocks/roof_yellow_single.dds",
    "Texture/tileset/blocks/stone2_single.dds",
    "Texture/tileset/blocks/stone_round_single.dds",
    "Texture/tileset/blocks/stone_yellow_single.dds",
    "Texture/tileset/blocks/test_six.dds",
    "Texture/tileset/blocks/top_ice_three.dds",
    "Texture/tileset/blocks/treetrunk2_three.dds",
    "Texture/tileset/blocks/treetrunk_three.dds",
    "Texture/tileset/blocks/wall_block_red_single.dds",
    "Texture/tileset/blocks/wall_white2_single.dds",
    "Texture/tileset/blocks/water3_single.dds",
    "Texture/tileset/blocks/water4_single.dds",
    "Texture/tileset/blocks/window_three.dds",
    "Texture/tooltip2_32bits.PNG",
    "Texture/whitedot.png",

    --mesh
    "model/Skybox/skybox3/skybox3.x",
    "model/blockworld/BlockModel/block_model_four.x",
    "model/blockworld/BlockModel/block_model_one.x",
    "model/blockworld/IconModel/IconModel_32x32.x",
    "model/blockworld/TextFrame/TextFrame.x",
    "model/common/building_point/building_point.x",
    "model/common/marker_point/marker_point.x",

    --model
    "character/CC/02human/CustomGeoset/actor.x",
    "character/CC/02human/paperman/boy01.x",
    "character/CC/02human/paperman/boy06.x",
    "character/CC/05effect/Birthplace/Birthplace.x",
    "character/common/marker_point/marker_point3.x",
}

--登录界面就要用到的
_loginAssetsList = {
    "texture/aries/common/themekid/dropdown_bg.png",
    "texture/3dmapsystem/common/themelightblue/container_bg.png",
    "texture/aries/common/themekid/editbox_32bits.png",
    "texture/3dmapsystem/common/themelightblue/slider_button_16.png",
    "texture/3dmapsystem/common/themelightblue/slider_background_16.png",
    "texture/dxutcontrols.dds",
    "texture/aries/creator/keepwork/window/dakuang2_32bits.png",
    "texture/whitedot.png",
    "texture/blocks/cake_top.png",
    "texture/aries/creator/paracraft/dengluye_1280x720_32bits.png",
    "texture/aries/creator/paracraft/login/setting_120x44_32bits.png",
    "texture/aries/creator/paracraft/paracraft_login_32bits.png",
    "texture/aries/creator/theme/gamecommonicon_32bits.png",
    "texture/aries/creator/keepwork/worldshare_32bits.png",
    "texture/aries/creator/keepwork/redsummercamp/shentongbei/shentongbei_32bits.png",
    "texture/aries/creator/keepwork/redsummercamp/works/works_32bits.png",
    "texture/aries/creator/keepwork/redsummercamp/courses/courses_32bits.png",
    "texture/aries/creator/paracraft/paracraft_icon_01_32bits.png",
    "texture/aries/creator/paracraft/jianjiediban_46x51_32bits.png",
    "texture/aries/creator/paracraft/tishi_54x21_32bits.png",
    "texture/aries/creator/paracraft/fenggexian_190x9_32bits.png",
    "texture/aries/creator/paracraft/login/plug_16x16_32bits.png",
    "texture/aries/creator/paracraft/login/menu_bg_36x36_32bits.png",
    "texture/aries/creator/paracraft/login/server_16x16_32bits.png",
}