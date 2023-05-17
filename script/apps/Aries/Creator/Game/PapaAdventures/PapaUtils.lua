--[[
    author:{pbb}
    date:2023.4.6.22.36
    uselib:
        local PapaUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaUtils.lua");
]]
local PapaUtils = NPL.export()

function PapaUtils.Init()
    
end

--[[echo: return {
RAM="可用/总共:1.72 GB/7.77GB"，
android_sdk_version=31,
android_version="12"，
androidid="5c63284fab3b9d77"，
appName="Paracraft"，
buildNumber=39,
bundleId="com.tatfook.paracraft" ,
language="zh",
manufacturer="HUAWEI"，
phone_model="TAS-ANOo"，
region="CN""，
screensize="2143×1080",
sdcard="可用/总共:14.36 GB/117 GB"，
versionName="2.1.23"
}
]]

--[[
oecho: return {
appName="Paracraft" ,
appversion="49"",
buildNumber="2.0.12",
bundleId="com.tatfook. paracraft" ,
device_model=" iPhone" ,
device_name="iPhone" ,
device_system_name="i0s"",
device_system_version=""16.1",
ios_model="iPhone14,2"",
ios_model_name=" iPhone 13 Pro" ,
language="zh" ,
region="cn" ,
sdcard=""104G 1 119G"
]]
--[[echo:return {
  appName="Paracraft",
  appVersion="2.0.9",
  buildNumber="71",
  bundleId="com.tatfook.paracraftmac",
  language="zh",
  mac_model="MacBookAir10,1",  
  mac_model_name="MacBook Air (M1, 2020)",
  region="cn" 
}]]

function PapaUtils.GetMemoryInfo(sysInfo)
    if not sysInfo then
        return ""
    end
    if platform=="android" then
        if sysInfo.RAM  then
            return sysInfo.RAM
        end
        return "android_8G"
    end

    if platform=="ios"then
        if sysInfo.sdcard  then
            return sysInfo.sdcard
        end
        return "ios_8G"
    end

    if platform=="mac" then
        return "mac_8G"
    end
end

function PapaUtils.GetOsInfo(sysInfo)
    if not sysInfo then
        return ""
    end
    if platform=="android" then
        if sysInfo.manufacturer and sysInfo.phone_model then
            return sysInfo.manufacturer..sysInfo.phone_model
        end
        return "Android"
    end

    if platform=="ios"then
        if sysInfo.ios_model_name and sysInfo.ios_model then
            return sysInfo.ios_model_name..sysInfo.ios_model
        end
        return "Iphone"
    end

    if platform=="mac" then
        if sysInfo.mac_model_name then
            return sysInfo.mac_model_name
        end
        return "Mac"
    end
end

function PapaUtils.GetDeviceInfo(call_back_func)
    local platform = System.os.GetPlatform()
    if platform=="android" or platform=="ios" or platform=="mac" then
        local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
        local sysInfo = PlatformBridge.getDeviceInfo() 
        local appInfo = PlatformBridge.getAppInfo()

        for k,v in pairs(appInfo) do
            sysInfo[k] = v
        end
        local deviceInfo = {}
        deviceInfo.gpuInfo = {}
        deviceInfo.osInfo = PapaUtils.GetOsInfo(sysInfo)
        deviceInfo.cpuInfo = ""
        deviceInfo.memoryInfo = PapaUtils.GetMemoryInfo(sysInfo)
        deviceInfo.netInfo = "able"
        deviceInfo.miniPhoneInfo = "able"

        deviceInfo.clientVersion = GameLogic.options.GetClientVersion()
        local deviceList = {};
        local devices = ParaEngine.GetAttributeObject():GetField("AudioDeviceName", "");
        if (devices and devices ~= "") then
            local names = commonlib.split(devices, ";");
            for i = 1, #names do
                deviceList[#deviceList + 1] = {
                    text = names[i],
                    value = names[i]
                };
            end
        end
        deviceInfo.soundDevices = deviceList

        deviceInfo.ip = NPL.GetExternalIP()
        deviceInfo.machineID = ParaEngine.GetAttributeObject():GetField('MachineID', '')
        deviceInfo.machineID_old = ParaEngine.GetAttributeObject():GetField('MachineID_old', '')

        local versionXml = ParaXML.LuaXML_ParseFile('config/Aries/creator/paracraft_script_version.xml')
        local login_version = versionXml[1][1] or ""
        deviceInfo.login_version = login_version
        deviceInfo.appId = System.options.appId
        if call_back_func then
            call_back_func(deviceInfo)
        end
        return
    end

    local LuaCallbackHandler = NPL.load("(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua");
    local str_arr = {{"osInfo", "系统信息", "wmic os get ", "caption,systemDrive,version,buildNumber"},
                     {"csproductInfo", "主板信息", "wmic csproduct get ", "identifyingNumber,uuid"},
                     {"cpuInfo", "CPU信息", "wmic cpu get ", "name,manufacturer,maxClockSpeed,processorid"},
                     {"memoryInfo", "内存信息", "wmic memorychip get ", "deviceLocator,speed,manufacturer,capacity"},
                     {"diskInfo", "硬盘分区", "wmic logicaldisk get ",
                      "deviceid,description,freespace,filesystem,size"},
                     {"gpuInfo", "显卡信息", "wmic path win32_videoController get ", "name,adapterRAM"}}
    local retMap = {}
    local len = 0
    local acc = 0
    for _, obj in pairs(str_arr) do
        local name = obj[1]
        local cmd = obj[3]
        local keys = commonlib.split(obj[4], ",")
        retMap[name] = {}
        for i = 1, #keys do
            local key = string.lower(keys[i])
            keys[i] = key

            local cmdStr = cmd .. key
            len = len + 1
            ParaGlobal.ShellExecute("popen", cmdStr, "isAsync", LuaCallbackHandler.createHandler(function(msg)
                local vals_arr = {};
                local out = msg.ret;
                local arr1 = commonlib.split(out, "\n")
                for j = #arr1, 1, -1 do
                    if arr1[j] == "" then
                        table.remove(arr1, j)
                    else
                        arr1[j] = arr1[j]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "") -- 去掉字符串首尾的空格、引号
                    end
                end
                if #arr1 > 0 then
                    local name1 = string.lower(arr1[1])
                    if key == name1 then
                        for k = 2, #arr1 do
                            local val = arr1[k]
                            table.insert(vals_arr, val)
                        end
                    end
                    retMap[name][key] = vals_arr
                end
                acc = acc + 1
                if acc == len then
                    local newRet = {}
                    for _name, _map in pairs(retMap) do
                        local keys = {}
                        for k, vals in pairs(_map) do
                            table.insert(keys, k)
                        end
                        local newArr = {}
                        if #keys > 0 then
                            local vals_size = #_map[keys[1]]

                            for j = 1, vals_size do
                                local temp = newArr
                                if vals_size > 1 then
                                    temp = {}
                                    newArr[j] = temp
                                end
                                for key, vals in pairs(_map) do
                                    temp[key] = vals[j]
                                end
                            end
                        end
                        newRet[_name] = newArr
                    end
                    local deviceInfo = {}
                    echo(newRet.gpuInfo)
                    local isMutiGpu = false
                    deviceInfo.gpuInfo = {}
                    for k,v in pairs(newRet.gpuInfo) do
                        if type(v) == "table" then --有多個顯卡
                            isMutiGpu = true
                            deviceInfo.gpuInfo[#deviceInfo.gpuInfo + 1] = {name = ParaMisc.EncodingConvert("gb2312", "utf-8", v.name),adapterram = v.adapterram}
                        end
                    end
                    if not isMutiGpu then
                        deviceInfo.gpuInfo[#deviceInfo.gpuInfo + 1] = {name = ParaMisc.EncodingConvert("gb2312", "utf-8", newRet.gpuInfo.name),adapterram = newRet.gpuInfo.adapterram }
                    end
                    echo(deviceInfo.gpuInfo)
                    print("osinfo=======",ParaMisc.EncodingConvert("gb2312", "utf-8", newRet.osInfo.caption))
                    deviceInfo.osInfo = ParaMisc.EncodingConvert("gb2312", "utf-8", newRet.osInfo.caption)
                    deviceInfo.cpuInfo = newRet.cpuInfo.name

                    local isMutiMemory = true
                    if newRet.memoryInfo and newRet.memoryInfo.capacity and tonumber(newRet.memoryInfo.capacity) > 0 then
                        isMutiMemory = false
                    end
                    local memory = 0
                    local g = 1024 * 1024 * 1024
                    if isMutiMemory then
                        for k, v in pairs(newRet.memoryInfo) do
                            if v.capacity and tonumber(v.capacity) then
                                v.capacity = (math.floor(tonumber(v.capacity) / g * 10) / 10) -- 大小
                                memory = memory + v.capacity
                            end
                        end
                    else
                        memory = (math.floor(tonumber(newRet.memoryInfo.capacity) / g * 10) / 10) --单内存条
                    end
                    deviceInfo.memoryInfo = memory .. "G"
                    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/PrepareApp/PrepareApp.lua");
                    local PrepareApp = commonlib.gettable("MyCompany.Aries.Game.PrepareApp");

                    PrepareApp.CheckNetWork(function(bSuccess)
                        deviceInfo.netInfo = bSuccess == true and "able" or "unable"
                        AudioEngine.StartRecording()
                        commonlib.TimerManager.SetTimeout(function()
                            AudioEngine.StopRecording()
                            local tmpCapturedFile = "temp/capture.ogg";
                            local tempFilename = AudioEngine.SaveRecording(tmpCapturedFile, 0.1);
                            if (tempFilename) then
                                deviceInfo.miniPhoneInfo = "able"
                            else
                                deviceInfo.miniPhoneInfo = "unable"
                            end

                            deviceInfo.clientVersion = GameLogic.options.GetClientVersion()
                            local deviceList = {};
                            local devices = ParaEngine.GetAttributeObject():GetField("AudioDeviceName", "");
                            if (devices and devices ~= "") then
                                local names = commonlib.split(devices, ";");
                                for i = 1, #names do
                                    deviceList[#deviceList + 1] = {
                                        text = names[i],
                                        value = names[i]
                                    };
                                end
                            end
                            deviceInfo.soundDevices = deviceList

                            -- deviceInfo.installPath = ParaIO.GetWritablePath()
                            deviceInfo.ip = NPL.GetExternalIP()
                            deviceInfo.machineID = ParaEngine.GetAttributeObject():GetField('MachineID', '')
                            deviceInfo.machineID_old = ParaEngine.GetAttributeObject():GetField('MachineID_old', '')

                            local versionXml = ParaXML.LuaXML_ParseFile('config/Aries/creator/paracraft_script_version.xml')
                            local login_version = versionXml[1][1] or ""
                            deviceInfo.login_version = login_version
                            deviceInfo.appId = System.options.appId
                            if call_back_func then
                                call_back_func(deviceInfo)
                            end
                        end, 1000);
                    end)
                end
            end));
        end
    end
end  

function PapaUtils.IsPapaCreate()
	NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/Lessons/Creation.lua");
	local Creation = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Lessons.Creation");
	if Creation and Creation.curSection then
        if Creation.curSection.content.type == 6 or  Creation.curSection.content.type == 7 then
            return true
        else
            return false
        end
    else
        return false
    end
end