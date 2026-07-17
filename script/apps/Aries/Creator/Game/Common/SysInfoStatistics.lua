--[[
    统计硬件信息
]]

--[[
Title: SysInfoStatistics
Author(s): hyz
Date: 2022/4/24
Desc: 统计硬件信息

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/SysInfoStatistics.lua");
local SysInfoStatistics = commonlib.gettable("MyCompany.Aries.Game.Common.SysInfoStatistics")
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
	
local LuaCallbackHandler = NPL.load("(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua");

local SysInfoStatistics = commonlib.gettable("MyCompany.Aries.Game.Common.SysInfoStatistics")

local hasUploaded = false

--获取路径下，version.txt的版本号
local function getVersionByPath(parentPath)
    if not ParaIO.DoesFileExist(parentPath) then
        print(string.format("path:%s 不存在,set ver=0.0.0",parentPath))
        return "0.0.0"
    end
    local version_filename = CommonLib.ToCanonicalFilePath(parentPath .. "/version.txt");
    -- print("_versionByPath :",version_filename)
    if not ParaIO.DoesFileExist(version_filename) then
        print(string.format("txt:%s 不存在,set ver=0.0.0",version_filename))
        return "0.0.0"
    end
    local version = CommonLib.GetFileText(version_filename) or "ver=0.0.0";
    version = string.gsub(version,"[%s\r\n]","");
    local __,v = string.match(version,"(.+)=(.+)");
    return v;
end

function SysInfoStatistics.uploadSysInfo(_info)
    local win_width = Screen:GetWidth()
	local win_height = Screen:GetHeight()
    local scalling = Screen:GetUIScaling(true);
    local obj = _info --整合之后的数据
    
    obj.installPath = ParaIO.GetWritablePath()
    obj.ip = NPL.GetExternalIP()
    
    obj.machineID = GameLogic.GetMachineID(ParaEngine.GetAttributeObject():GetField('MachineID', ''))
    obj.machineID_old = ParaEngine.GetAttributeObject():GetField('MachineID_old', '')
    -- obj.version = getVersionByPath(ParaIO.GetWritablePath())
    obj.version = GameLogic.options.GetClientVersion()
    obj.channelId = System.options.channelId
    obj.appId = System.options.appId
    obj.commandLine = ParaEngine.GetAppCommandLine()
    obj.isDevEnv = System.options.isDevEnv
    obj.isDevMode = System.options.isDevMode
    obj.mc = System.options.mc
    obj.platform = System.os.GetPlatform()
    obj.winwidth = win_width
    obj.winheight = win_height
    obj.scalling = scalling

    if (System.os.GetPlatform() == "ios" and System.os.CompareParaEngineVersion('1.6.1.0')) then
        obj.IDFA = IDFA.get()
    end

    local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')
    local bak_sessions = SessionsData:GetSessions()
    if bak_sessions then
        obj.account_list = {}
        -- print("=======bak_sessions")
        -- echo(bak_sessions,true)
        for k,v in ipairs(bak_sessions.allUsers) do
            if v.session and v.session.account then
                table.insert(obj.account_list,v.session.account)
            end
            
        end
        obj.softwareUUID = bak_sessions.softwareUUID
        obj.account_curent = bak_sessions.selectedUser
    end
    if System.options.isDevMode then
        print("-send sysHardwareInfo:")
        echo(obj,true)
    end
    keepwork.burieddata.uploadLog({
        type = "sysHardwareInfo",
        logs = {obj}
    },function(err,msg,data)
        if System.options.isDevMode then
            print("send sysHardwareInfo resp,code=",err)
        end
    end)
end

function SysInfoStatistics.checkGetSysInfoAndUpload(preInfo)
    local platform = System.os.GetPlatform()
    if platform=="android" or platform=="ios" or platform=="mac" then
        local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
        local sysInfo = PlatformBridge.getDeviceInfo() 
        local appInfo = PlatformBridge.getAppInfo()

        for k,v in pairs(appInfo) do
            sysInfo[k] = v
        end
        if preInfo and type(preInfo) == "table" then
            for k,v in pairs(preInfo) do
                sysInfo[k] = v
            end
        end
        SysInfoStatistics.uploadSysInfo(sysInfo)
        return
    end
    if platform ~= "win32" or System.os.IsWindowsXP() then
        return
    end
    if hasUploaded then
        return
    end
    hasUploaded = true;
    
    local str_arr = {
        { "osInfo","系统信息","wmic os get ","caption,systemDrive,version,buildNumber" },
        { "csproductInfo","主板信息","wmic csproduct get ","identifyingNumber,uuid" },
        { "cpuInfo","CPU信息","wmic cpu get ","name,manufacturer,maxClockSpeed,processorid" },
        { "memoryInfo","内存信息","wmic memorychip get ","deviceLocator,speed,manufacturer,capacity" },
        { "diskInfo","硬盘分区","wmic logicaldisk get ","deviceid,description,freespace,filesystem,size" },
        { "gpuInfo","显卡信息","wmic path win32_videoController get ","name,adapterRAM" },
    }
    local retMap = {}
    local len = 0
    local acc = 0
    for _,obj in pairs(str_arr) do
        local name = obj[1]
        local cmd = obj[3]
        local keys = commonlib.split(obj[4],",")
        retMap[name] = {}
        for i=1,#keys do 
            local key = string.lower(keys[i])
            keys[i] = key
            
            local cmdStr = cmd..key 
            len = len + 1
            ParaGlobal.ShellExecute("popen",cmdStr,"isAsync",LuaCallbackHandler.createHandler(function(msg)
                local vals_arr = {};
                local out = msg.ret;
                local arr1 = commonlib.split(out,"\n")
                for j=#arr1,1,-1 do
                    if arr1[j]=="" then
                        table.remove(arr1,j)
                    else
                        arr1[j] = arr1[j]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "") --去掉字符串首尾的空格、引号
                    end
                end
                if #arr1>0 then
                    local name1 = string.lower(arr1[1])
                    if key==name1 then
                        for k=2,#arr1 do
                            local val = arr1[k]
                            table.insert(vals_arr,val)
                        end
                    end
                    retMap[name][key] = vals_arr
                end
                acc = acc + 1
                if acc==len then
                    local newRet = {}
                    for _name,_map in pairs(retMap) do
                        local keys = {}
                        for k,vals in pairs(_map) do
                            table.insert(keys,k)
                        end
                        local newArr = {}
                        if #keys>0 then
                            local vals_size = #_map[keys[1]]
                            
                            for j=1,vals_size do
                                local temp = newArr
                                if vals_size>1 then
                                    temp = {}
                                    newArr[j] = temp
                                end
                                for key,vals in pairs(_map) do
                                    temp[key] = ParaMisc.EncodingConvert("gb2312", "utf-8", vals[j])
                                end
                            end
                        end
                        newRet[_name] = newArr
                    end
                    -- print("=======newRet")
                    -- echo(newRet,true)
                    local g = 1024*1024*1024
                    if newRet.gpuInfo.adapterram and tonumber(newRet.gpuInfo.adapterram) then
                        newRet.gpuInfo.adapterram = (math.floor(tonumber(newRet.gpuInfo.adapterram)/g*10)/10).."G"
                    end
                    for k,v in pairs(newRet.diskInfo) do
                        if v.freespace and tonumber(v.freespace) then
                            v.freespace = (math.floor(tonumber(v.freespace)/g*10)/10).."G" --剩余空间
                        end
                        if v.size and tonumber(v.size) then
                            v.size = (math.floor(tonumber(v.size)/g*10)/10).."G" --大小
                        end
                    end
                    
                    for k,v in pairs(newRet.memoryInfo) do
                        if v.capacity and tonumber(v.capacity) then
                            v.capacity = (math.floor(tonumber(v.capacity)/g*10)/10).."G" --大小
                        end
                    end
                    -- print("test log-----规范化")
                    -- echo(newRet,true)
                    if preInfo and type(preInfo) == "table" then
                        for k,v in pairs(preInfo) do
                            newRet[k] = v
                        end
                    end
                    SysInfoStatistics.uploadSysInfo(newRet)
                end
            end));
        end
    end
    
end


return SysInfoStatistics