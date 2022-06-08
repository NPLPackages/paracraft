--[[
Title: Paracraft debug
Author(s): LiXizhi
Date: 2021/12/5
Desc: for printing logs in main thread, this is a singleton class.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ParacraftDebug.lua");
local ParacraftDebug = commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug");
ParacraftDebug:Connect("onMessage", function(errorMsg, stackInfo)   end);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local ParacraftDebug = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug"));

--  function(errorMsg, stackInfo)   end
ParacraftDebug:Signal("onMessage");

function ParacraftDebug:ctor()
	ParacraftDebug.Restart()
end

-- static function 
function ParacraftDebug.Restart()
	commonlib.debug.SetNPLRuntimeErrorCallback(ParacraftDebug.OnNPLErrorCallBack)
	if(commonlib.debug.SetNPLRuntimeDebugTraceLevel) then
		commonlib.debug.SetNPLRuntimeDebugTraceLevel(5);
	end
end

function ParacraftDebug.OnNPLErrorCallBack(errorMessage)
	log(errorMessage);
	local stackInfo;
	if(type(errorMessage) == "string") then
		local title;
		title, stackInfo = errorMessage:match("^([^\r\n]+)\r?\n(.*)$")
		if(stackInfo) then
			errorMessage = title;
		end
	end
	ParacraftDebug:onMessage(errorMessage, stackInfo);

	ParacraftDebug:SendErrorLog("NplRuntimeError", {
		errorMessage = errorMessage,
		stackInfo = stackInfo,
	})
end

--获取路径下，version.txt的版本号
local function getVersionByPath(parentPath)
    if not ParaIO.DoesFileExist(parentPath) then
        print(string.format("path:%s 不存在,set ver=0.0.0",parentPath))
        return "0.0.0"
    end
	if CommonLib==nil then
		return nil
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

--检查有没有错误日志文件（crash时会复制一份到temp/log.crash.txt），有的话读取最后面的200行，上报
function ParacraftDebug:CheckSendCrashLog()
	if not (keepwork and keepwork.burieddata and keepwork.burieddata.uploadLog) then
		return
	end
	local path = "temp/log.crash.txt"
	local bakPath = "temp/log.crash.txt.bak"
	if ParaIO.DoesFileExist(path) then
		local file = ParaIO.open(path,"r")
		if not file:IsValid() then
			return
		end
		local str = file:GetText()
		local arr = commonlib.split(str,"\r\n")
		
		local uselessLines = {
			"unload unused asset file",
			"gateway/events/send",
		}
		
		local acc = 0
		local retTab = {}
		for i=#arr ,1,-1 do
			local line = arr[i]
			local skip = false
			for k,v in pairs(uselessLines) do
				if string.find(line,v) then
					skip = true
					break;
				end
			end
			if not skip then
				acc = acc + 1
				table.insert(retTab,line)
			end
			if acc==400 then
				break
			end
		end

		local errlog = table.concat(retTab,"\r\n")
		self:SendErrorLog("CrashErr",{
			logtxt = errlog
		})

		ParaIO.MoveFile(path,bakPath)  --备个份
	end
end

-- send runtime error log to our log service
function ParacraftDebug:SendErrorLog(logType,obj)
	if type(obj)~="table" then
		return
	end
	if not (keepwork and keepwork.burieddata and keepwork.burieddata.uploadLog) then
		return
	end
	if System.options.isDevMode then
		print("-------isDevMode不发送错误日志:",logType)
		echo(obj,true)
		return
	end

	obj.ip = NPL.GetExternalIP()
    obj.machineID = ParaEngine.GetAttributeObject():GetField('MachineID', '')
    obj.version = getVersionByPath(ParaIO.GetWritablePath())
    obj.channelId = System.options.channelId
    obj.commandLine = ParaEngine.GetAppCommandLine()
    obj.isDevEnv = System.options.isDevEnv
    obj.isDevMode = System.options.isDevMode
    obj.mc = System.options.mc

	local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')
	if SessionsData then
		local bak_sessions = SessionsData:GetSessions()
		if bak_sessions then
			obj.softwareUUID = bak_sessions.softwareUUID
			obj.account_curent = bak_sessions.selectedUser
		end
	end

	keepwork.burieddata.uploadLog({
        type = logType,
        logs = {obj}
    },function(err,msg,data)
        if System.options.isDevMode then
            print("send npl error log resp,code=",err)
        end
    end)
end

ParacraftDebug:InitSingleton();