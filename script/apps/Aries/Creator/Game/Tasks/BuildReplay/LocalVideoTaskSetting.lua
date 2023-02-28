--[[
Title: 本地视频任务队列界面
Author(s): hyz
Date: 2022/12/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/LocalVideoTaskSetting.lua");
local LocalVideoTaskSetting = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.LocalVideoTaskSetting");

LocalVideoTaskSetting.ShowPage()


-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/localserver/LocalStorageUtil.lua");
local LocalStorageUtil = commonlib.gettable("System.localserver.LocalStorageUtil");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/VideoRenderQueue.lua");
local VideoRenderQueue = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.VideoRenderQueue");

local LocalVideoTaskSetting = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.LocalVideoTaskSetting");

local page
function LocalVideoTaskSetting.OnInit()
    page = document:GetPageCtrl()
end

function LocalVideoTaskSetting.CheckShow()
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    if not System.options.isDevMode and not KeepWorkItemManager.IsTeacher() then
        GameLogic.AddBBS(nil,L"你没有权限使用该命令")
        return
    end
    LocalVideoTaskSetting.ShowPage()
end

function LocalVideoTaskSetting.ShowPage(bShow)
    if bShow==false then
        LocalVideoTaskSetting.ClosePage()
        return
    end
    local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/BuildReplay/LocalVideoTaskSetting.html", 
		name = "LocalVideoTaskSetting.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		click_through = false, 
		enable_esc_key = true,
		bShow = true,
		isTopLevel = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ct",
			x = -200,
			y = -170,
			width = 400,
			height = 400,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function LocalVideoTaskSetting.ClosePage()
    if page then 
        page:CloseWindow()
        page = nil 
    end
end

function LocalVideoTaskSetting.OnBtnStartTask()
    if page==nil then
        return
    end
    local str = page:GetValue("worldId_groups")
    if str=="" then
        GameLogic.AddBBS(nil,"请输入有效的世界ID") 
        return
    end

    local projectIdArr = {}
    for id,v in str:gmatch("(%d+)") do 
        projectIdArr[#projectIdArr+1] = id
    end

    local tipStr = table.concat(projectIdArr,",")
    _guihelper.MessageBox(format(L"请确认作品ID: %s", tipStr), function(res)
        if(res and res == _guihelper.DialogResult.Yes) then
            LocalVideoTaskSetting.StartLocalTasks(projectIdArr)
        end
    end, _guihelper.MessageBoxButtons.YesNo);
end

function LocalVideoTaskSetting.OnEditValueChange()
    if page==nil then
        return
    end
    local str = page:GetValue("worldId_groups")
    local newStr = str:gsub("[^%s%d;,；，]","")
    if str~=newStr then
        page:SetValue("worldId_groups",newStr)
    end
end

function LocalVideoTaskSetting.StartLocalTasks(projectIdArr)
    if #projectIdArr==0 then 
        GameLogic.AddBBS(nil,"请输入有效的世界ID") 
        return
    end
    taskArr = projectIdArr
    for k=1,#projectIdArr do 
        taskArr[k] = {projectId = tonumber(projectIdArr[k]),id = k}
    end
    LocalStorageUtil.Save_localserver("LocalVideoTasks_List", taskArr, true)
    LocalStorageUtil.Flush_localserver()

    LocalVideoTaskSetting.CheckStartRunLocalTasks()

    LocalVideoTaskSetting.ClosePage()
end 


function LocalVideoTaskSetting.CheckStartRunLocalTasks()

    local _start = function()
        local task = LocalVideoTaskSetting.GetNextLocalTask()
        if task==nil then 
            GameLogic.AddBBS(nil,L"没有本地视频任务")
            return
        end

        local path = LocalVideoTaskSetting.GetOutputLogPath()
        local oldStr = commonlib.Files.GetFileText(path)
        LocalVideoTaskSetting._oldLog = oldStr
        
        System.options.isDevMode = true
    
        VideoRenderQueue.bIsLocalMode = true
        VideoRenderQueue:Init(1142663)

        local _func;
        _func = function(acc,callback)
            if acc<0 then
                if callback then
                    callback()
                end 
                return
            end
            GameLogic.AddBBS(1,string.format(L"%s秒后开始",acc))
            commonlib.TimerManager.SetTimeout(function()
                _func(acc-1,callback)
            end,1000)
        end
        
        _func(5,function()
            GameLogic.AddBBS(1,L"开始")
            VideoRenderQueue:adminLogin("videoworker","123456",function()
                VideoRenderQueue:StartRunTasks()
            end)
        end)
    end

    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");
        local urlProtocol = UrlProtocolHandler:GetParacraftProtocol() or ''

        if System.os.GetPlatform() == 'mac' then
            urlProtocol = ParaEngine.GetAppCommandLine() or ''
        end

        urlProtocol = commonlib.Encoding.url_decode(urlProtocol)
        print("urlProtocol",urlProtocol)
        local _loginToken = urlProtocol:match('_loginToken="([%S]+)"')
        if _loginToken==nil then
            _loginToken = urlProtocol:match('_loginToken=([%S]+)')
        end
        local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')

        print("1去登录----_loginToken",_loginToken)
        MainLogin:LoginWithToken(_loginToken, function(bIsSuccessed, reason, message)
            print("bIsSuccessed",bIsSuccessed)
            if not bIsSuccessed then
                _guihelper.MessageBox(message)
            else
                _start()
            end
        end)
    else
        _start()
    end
    
end

--读取下一个本地任务
function LocalVideoTaskSetting.GetNextLocalTask()
    local taskArr = LocalStorageUtil.Load_localserver("LocalVideoTasks_List", nil, true)
    if taskArr==nil or #taskArr==0 then 
        return nil
    end
    local idx = 1
    for k,v in ipairs(taskArr) do 
        if v.videoUrl~=nil or v.isNoVideo~=nil then
            idx = k+1
        else 
            break
        end
    end
    if idx>#taskArr then
        LocalStorageUtil.Save_localserver("LocalVideoTasks_List", nil, true)
        LocalStorageUtil.Flush_localserver()
        return nil
    end
    return taskArr[idx]
end

--提交本地任务
function LocalVideoTaskSetting.SubmitTask(params)
    local taskArr = LocalStorageUtil.Load_localserver("LocalVideoTasks_List", nil, true)
    if taskArr==nil or #taskArr==0 then 
        return nil
    end
    local task = nil
    for k,v in pairs(taskArr) do 
        if v.projectId==params.projectId then
            task = v
            break
        end
    end
    if task==nil then
        return
    end
    task.filename = params.filename
    task.videoPath = params.videoPath
    task.coverPath = params.coverPath
    task.videoUrl = params.videoUrl
    task.coverUrl = params.coverUrl

    task.isNoVideo = params.isNoVideo

    LocalStorageUtil.Save_localserver("LocalVideoTasks_List", taskArr, true)
    LocalStorageUtil.Flush_localserver()

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    local username = nil

    if currentEnterWorld and type(currentEnterWorld) == 'table' then
        if currentEnterWorld.user and currentEnterWorld.user.username then
            username = currentEnterWorld.user.username
        end
    end

    print("====currentEnterWorld",currentEnterWorld)
    echo(currentEnterWorld,true)
    local tab = {}
    for k,v in ipairs(taskArr) do
        if v.isNoVideo~=nil then 
            tab[#tab+1] = string.format('{projectId=%s,username=%s,tip="无有效视频，请手工检查该世界"}',tostring(v.projectId),tostring(username))
        elseif v.videoUrl~=nil then
            tab[#tab+1] = string.format("{projectId=%s,filename=%s,videoUrl=%s,username=%s}",tostring(v.projectId),commonlib.Encoding.DefaultToUtf8(v.filename),tostring(v.videoUrl),tostring(username))
        end
    end
    local str = table.concat(tab,",\n")

    local path = LocalVideoTaskSetting.GetOutputLogPath()
    local oldStr = LocalVideoTaskSetting._oldLog
    if oldStr then
        str = string.format("%s\n\n========>>>>>>>> %s\n\n%s",oldStr,os.date("%Y-%m-%d %H:%M:%S"),str)
    end
    commonlib.Files.WriteFile(path,str)
end

function LocalVideoTaskSetting.GetOutputLogPath(isShowUI)
    local root  = ParaIO.GetWritablePath()
    if isShowUI then 
        root = commonlib.Encoding.DefaultToUtf8(root)
    end
    local path = root..string.format("temp/video/video_log_%s.txt",os.date("%Y-%m-%d"))
    return path
end