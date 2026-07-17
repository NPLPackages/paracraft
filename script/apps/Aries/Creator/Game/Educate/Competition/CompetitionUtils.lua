--[[
Title: educate Competition utils
Author(s): pbb
Date: 2023/6/9
Desc: 
Use Lib:
-------------------------------------------------------
local CompetitionUtils =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionUtils.lua")
-------------------------------------------------------
]]
local CompetitionApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionApi.lua")
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KpChatChannel = NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua')
local CompetitionUtils = NPL.export()

function CompetitionUtils.IsLogined()
    return GameLogic.GetFilters():apply_filters('is_signed_in')
end

function CompetitionUtils.GetServerTime()
    if GameLogic.IsDevMode() then
        return os.time()
    end
    local time_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
    return time_stamp or os.time()
end

function CompetitionUtils.ZipCompeteWorld(world_dir,zip_file_name,zip_file)
    if not world_dir or not zip_file_name then
        return ""
    end
    local SystemUserName = commonlib.getfield("System.User.username")
    local userName = GameLogic.GetFilters():apply_filters("store_get", "user/username");
    local extend_name = ".zip"
    local zip_name =zip_file_name
    local zip_path = zip_file
    zip_path = commonlib.Encoding.Utf8ToDefault(zip_path)
    NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
    local ZipFile = commonlib.gettable("System.Util.ZipFile");
    local zipFile = ZipFile:new();
    if (zipFile:open(zip_path, "w")) then
        zipFile:AddDirectory("exam_world/", world_dir .. "*.*", 10);
        print("压缩世界文件============",world_dir,zip_path)
        zipFile:close();
        return zip_path
    end
    return ""
end

--上传文件到七牛公共网盘
function CompetitionUtils.UpLoadFileToQiNiu(filepath, filename,call_back_func)
    Mod.WorldShare.MsgBox:Show(L'正在获取上传凭证...')
    print("开始上传世界压缩包",filepath)
    keepwork.shareToken.get({
        cache_policy = "access plus 12 second", 
        share="compete_world_repair_",
    },function(err,msg,data)
        if err==401 then
            print("上传世界压缩包失败",err)
            if call_back_func then
                call_back_func(false,err,"登录状态异常，请重试")
            end
            return
        end
        if (err ~= 200 or (not data.data) or (not data.data.token) or (not data.data.key)) then
            print("上传世界压缩包失败,数据异常~~~~~~~~~~",err)
            if call_back_func then
                call_back_func(false,err,"获取文件token失败，请重试")
            end
            return;
        end
        if err == 200 then
            local token = data.data.token
            local key = data.data.key;
            local content
            local file = ParaIO.open(filepath, "rb");
            if (not file or not file:IsValid()) then
                file:close();
                print("-------文件读取失败")
                GameLogic.AddBBS(nil,L"文件读取失败");
                return;
            end

            local size = file:GetFileSize();
            if size>10*1024*1024 then
                file:close();
                GameLogic.AddBBS("CompetitionUtils","上传的世界文件过大,请上传10MB以内的文件")
                return
            end

            content = file:GetText(0, -1);
            file:close();
            Mod.WorldShare.MsgBox:Close()
            Mod.WorldShare.MsgBox:Show(L'正在上传文件..',1000*60*10)
            GameLogic.GetFilters():apply_filters('qiniu_upload_file', token, key, filename, content,function(result, upcode)
                if upcode ~= 200 then
                    if call_back_func then
                        call_back_func(false,upcode,"提交失败，七牛文件上传失败")
                    end
                    return;
                end
                Mod.WorldShare.MsgBox:Close()
                Mod.WorldShare.MsgBox:Show(L'正在获取文件链接...')

                keepwork.shareUrl.get({cache_policy = "access plus 0", key = key}, function(urlcode, msg, data)
                    if (urlcode ~= 200 or (not data.data)) then
                        print("获取文件url失败",urlcode)
                        if call_back_func then
                            call_back_func(false,upcode,"提交失败，获取文件链接失败")
                        end
                        return;
                    end
                    echo(data,true)
                    print("世界压缩包上传成功，url====",data.data)
                    Mod.WorldShare.MsgBox:Close()
                    if call_back_func then
                        local compete_world_url = data.data
                        local separator = compete_world_url:find("?")
                        compete_world_url = string.sub(compete_world_url, 1, separator - 1)
                        call_back_func(true,{url=compete_world_url,key=key,size=size})
                    end				
                end);

                keepwork.shareFile.post({key = key}, function(err, msg, data)
                    LOG.std(nil, "info", "CompetitionUtils", "%s: {error: %s, data: %s}", "keepwork.shareFile", tostring(err), commonlib.serialize(data));
                end);              
            end)
        else
            if call_back_func then
                call_back_func(false,err,"获取文件token失败，请重试")
            end
        end
    end)
end

function CompetitionUtils.GetTimeFormat(startTime,endTime)
    local startTimestamp,endTimestamp,startTimeStr,endTimeStr
    startTimestamp = commonlib.timehelp.GetTimeStampByDateTime(startTime)
    startTimeStr = os.date("%Y-%m-%d %H:%M:%S",startTimestamp)
    endTimestamp = commonlib.timehelp.GetTimeStampByDateTime(endTime)
    endTimeStr = os.date("%Y-%m-%d %H:%M:%S",endTimestamp)

    return startTimeStr.."~"..endTimeStr,startTimestamp,endTimestamp
end

function CompetitionUtils.GetTimeFormatWithSpacing(timeStr)
    local startTimestamp = commonlib.timehelp.GetTimeStampByDateTime(timeStr)
    local startTimeStr = os.date("%Y-%m-%d  %H:%M",startTimestamp)
    return startTimeStr,startTimestamp
end

function CompetitionUtils.GetTimeFormatStr(time_stamp)
    local time_stamp = time_stamp or 0
    local day = math.floor(time_stamp / 86400)
	local hour = math.floor((time_stamp - day * 86400) / 3600)
	local min = math.floor((time_stamp - day * 86400 - hour * 3600) / 60)
	local second = time_stamp - day * 86400 - hour * 3600 - min * 60
    if day > 0 then
        return string.format("%02d天%02d时%02d分%02d秒",day,hour,min,second)
    end
    if hour > 0 then
        return string.format("%02d时%02d分%02d秒",hour,min,second)
    end
    if min > 0 then
        return string.format("%02d分%02d秒",min,second)
    end
    return string.format("%02d秒",second)
end

function CompetitionUtils.GetWebParacraftUrl(type)
    local baseUrl = "https://webparacraft.keepwork.com?http_env=ONLINE"
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    if httpwrapper_version == "STAGE" or httpwrapper_version == "RELEASE" then
        baseUrl = "https://emscripten.keepwork.com?http_env="..httpwrapper_version
    end
    if type and type == "world" then
        return baseUrl.."&worldfile="
    end

    if type and type == "pid" then
        return baseUrl.."&pid="
    end
    return baseUrl
end

function CompetitionUtils.JoinCompeteRoom(roomKey,callback)
    if  not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","CompetitionUtils","加入房间"..(roomKey or "").."失败,赛事socket网络链接失败")
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            KpChatChannel.client:Send("app/join",{ rooms = { roomKey }, });
            if callback and type(callback) == 'function' then
                callback(KpChatChannel.IsConnected() )
            end
        end,5*1000)
        return
    end
    KpChatChannel.client:Send("app/join",{ rooms = { roomKey }, });
    print("加入房间"..(roomKey or "").."成功",KpChatChannel.IsConnected())
    if callback and type(callback) == 'function' then
        callback(KpChatChannel.IsConnected() )
    end
end 

function CompetitionUtils.ReconnectSocket(callback)
    if not KpChatChannel.client or not KpChatChannel.IsConnected() then
        local connect_count = 1
        local totalConnectTime = 1
        local maxConnectTime = 3
        KpChatChannel.TryToConnect()
        local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
            if KpChatChannel.IsConnected() then
                if callback and type(callback) == 'function' then
                    callback(true)
                end
                timer:Change()
            else
                connect_count = connect_count + 1
                if connect_count > 5 then
                    connect_count = 1
                    KpChatChannel.TryToConnect()
                    totalConnectTime = totalConnectTime + 1
                    if totalConnectTime > maxConnectTime then
                        if callback and type(callback) == 'function' then
                            callback(false)
                        end
                        timer:Change()
                    end
                end
            end
        end});
        mytimer:Change(0,1000)
    end
end

function CompetitionUtils.LeaveCompeteRoom(roomKey,callback)
    if not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","CompetitionUtils","离开房间"..(roomKey or "").."失败,赛事socket网络链接失败")
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            KpChatChannel.client:Send("app/leave",{ rooms = { roomKey }, });
            if callback and type(callback) == 'function' then
                callback(KpChatChannel.IsConnected() )
            end
        end,5*1000)
        return
    end
    KpChatChannel.client:Send("app/leave",{ rooms = { roomKey }, });
    if callback and type(callback) == 'function' then
        callback(KpChatChannel.IsConnected() )
    end
end

function CompetitionUtils.BroadcastMsg(roomKey,msgdata,callback)
    if (not msgdata or type(msgdata) ~= "table") then
        return
    end
    local broadcastFunc = function()
        if KpChatChannel.IsConnected() then
            CompetitionUtils.JoinCompeteRoom(roomKey,callback)
        end
        KpChatChannel.client:Send("app/broadcast", msgdata);
        if callback and type(callback) == 'function' then
            callback(KpChatChannel.IsConnected() )
        end
    end

    if not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","CompetitionUtils","发送广播消息失败,赛事socket网络链接失败，房间名称是"..(roomKey or ""))
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            broadcastFunc()
        end,5*1000)
        return
    end
    broadcastFunc()
end





