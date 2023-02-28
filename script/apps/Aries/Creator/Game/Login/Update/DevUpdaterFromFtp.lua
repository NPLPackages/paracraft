--[[
Title: DevUpdaterFromFtp
Author(s):  hyz
Date: 2023-02-14
Desc: 从Ftp下载dev环境的最新更新
use the lib:
------------------------------------------------------------
local DevUpdaterFromFtp = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/Update/DevUpdaterFromFtp.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/ParacraftCI/FtpUtil.lua");
local FtpUtil = commonlib.gettable("FtpUtil")
local ftp_util = FtpUtil.createWithDevUpdateAddress()

local DevUpdaterFromFtp = commonlib.inherit(nil, NPL.export());

NPL.load("(gl)script/ide/Files.lua");
local lfs = commonlib.Files.GetLuaFileSystem();

local function _createDir(path)
	if not ParaIO.DoesFileExist(path) then
		if System.os.GetPlatform()=="win32" then
			return ParaIO.CreateDirectory(path)
		else
			return lfs.mkdir(path)
		end
    end
end 

local function _deleteFile(path)
	if ParaIO.DoesFileExist(path) then
		if System.os.GetPlatform()=="win32" then
			ParaIO.DeleteFile(path)
		else
			os.remove(path)
		end
	end
end 

local function _getMd5(path)
	local file = ParaIO.open(path , "rb");
	if(file:IsValid()) then
		local text = file:GetText(0, -1);
		file:close();

		local md5 = ParaMisc.md5(text)
		return md5
	else
		file:close();
		commonlib.echo(string.format("get md5 failed! %s",path))
	end	
end

local curDir = ParaIO.GetCurDirectory(0);
local tempDir = curDir.."temp/"
_createDir(tempDir)
tempDir = tempDir.."dev_update_ftp/"
_createDir(tempDir)

local ftpRootUrl = "paracraft/dev_update_source_1"

local remote_p4vListUrl = ftpRootUrl.."/filelist.p4v"
local remote_pkgListUrl = ftpRootUrl.."/filelist.pkg."
local remote_modListUrl = ftpRootUrl.."/filelist.mod."
local remote_p4vRevisionUrl = ftpRootUrl.."/p4v.revision"
local remote_versionUrl = ftpRootUrl.."/version"

local localVersionReadPath = tempDir.."version.dev"

local applyManifestFile = tempDir.."manifest.apply"
local applyVerFile = tempDir.."version.apply"

function DevUpdaterFromFtp:ctor()
    self.remote_list = {}
    self.localVer = 0
    self.remoteVer = 0
    self.needUpdate = false
end

function DevUpdaterFromFtp:Check(callback)
    local _start = os.clock()
    local remote_versionStr = ftp_util:getRemoteText(remote_versionUrl)
    print("remote_versionStr",remote_versionStr)
    
    self.remoteVer = tonumber(remote_versionStr);
    if not remote_versionStr or not self.remoteVer then
        GameLogic.AddBBS(nil,"ftp资源版本号获取失败")
        if callback then
            callback(false)
        end
        return
    end
   
    
    local local_versionStr = commonlib.Files.GetFileText(localVersionReadPath)
    self.localVer = tonumber(local_versionStr) or 0

    local _end = os.clock()
    print("DevUpdaterFromFtp:Check------used time:",_end-_start)

    self.needUpdate = self.localVer<self.remoteVer

    self.needUpdate = self.needUpdate or self.localVer==self.remoteVer --有可能存在更新下载好却没有应用更新的情况，下次直接应用
    if callback then
        callback(self.needUpdate)
    end

    return self.needUpdate
end

function DevUpdaterFromFtp:StartUpdate(callback)
    if self.needUpdate then
        local function onError()
            _guihelper.MessageBox("ftp应用更新失败，请重启客户端", function(result)
			    if(result == _guihelper.DialogResult.OK)then
			        if callback then 
                        callback()
                    end
			    end
		    end, _guihelper.MessageBoxButtons.OK);
        end
        self:_downloadManifest(function(isSuccess)
            if not isSuccess then
                onError()
                return
            end
            self:_downloadFiles(function(isSuccess)
                if not isSuccess then
                    onError()
                    return
                end
                self:_createApplyManifest(function(isSuccess,noNeedApply)
                    if not isSuccess then
                        onError()
                        return
                    end
                    if noNeedApply then
                        _guihelper.MessageBox("您的内容已经与ftp相同,无需更新，点击确定直接进入", function(result)
                            if(result == _guihelper.DialogResult.OK)then
                                if callback then 
                                    callback()
                                end
                            end
                        end, _guihelper.MessageBoxButtons.OK);
                        return
                    end
                    _guihelper.MessageBox("ftp,更新文件已准备好，是否应用更新？（不应用则直接进入软件）", function(result)
                        if(result == _guihelper.DialogResult.Yes)then
                            self:_applyUpdate()
                        else
                            if callback then 
                                callback()
                            end
                        end
                    end, _guihelper.MessageBoxButtons.YesNo);
                end)
            end)
        end)
    else
        if callback then 
            callback()
        end
    end
end

--去ftp下载清单列表和版本号
function DevUpdaterFromFtp:_downloadManifest(callback)
    local function _download(listUrl,relativeFloder,callback)
        local _start = os.clock()
        local remote_listStr = ftp_util:getRemoteText(listUrl)
        print("remote_listStr")
        echo(remote_listStr)
        
        local list = commonlib.totable(remote_listStr)
        
        if not remote_listStr or not list then
            if callback then 
                callback(false)
            end
           
            return
        end
        for k,v in pairs(list) do 
            local md5 = v 
            local remotePath = k:gsub("[\r\n%s]$","")
            local relativePath = remotePath:gsub(relativeFloder,""):gsub("^[/\\]+","")
            local localPath = tempDir..self:_getDevVersion().."/"..relativePath;
            
            self.remote_list[relativePath] = {
                remotePath = ftpRootUrl.."/"..remotePath,
                relativePath = relativePath,
                localPath = localPath,
                md5 = md5,
            }
            
        end
        
        local _end = os.clock()
        print("DevUpdaterFromFtp:downloadManifest------used time:",_end-_start)

        if callback then 
            callback(true)
        end

        return true
    end

    self.remote_list = {}
    
    local pkg_targetBranch = ParaEngine.GetAppCommandLineByParam("ftp_updater_pkg_branch", "dev")
    local mod_targetBranch = ParaEngine.GetAppCommandLineByParam("ftp_updater_mod_branch", "master")
    _download(remote_p4vListUrl,"p4v_upload/",function(isSuccessP4v)
        _download(remote_modListUrl..mod_targetBranch,"build_mod_"..mod_targetBranch,function(isSuccessMod)
            _download(remote_pkgListUrl..pkg_targetBranch,"build_pkg_"..pkg_targetBranch,function(isSuccessPkg)
                if not isSuccessP4v and not isSuccessMod and not isSuccessPkg then
                    GameLogic.AddBBS(nil,"ftp资源清单获取失败")
                end
                print("filelist----isSuccessP4v",isSuccessP4v)
                print("filelist----isSuccessMod",isSuccessMod)
                print("filelist----isSuccessPkg",isSuccessPkg)
                for k,v in pairs(self.remote_list) do 
                    local remotePath = string.lower(v.remotePath)
                    if remotePath:match("p4v_upload/main150727.pkg") or remotePath:match("p4v_upload/npl_packages/paracraftbuildinmod.zip") then 
                        self.remote_list[k] = nil
                        print("--------不下载p4v的mod和增量pkg",k)
                    end
                end
                for k,v in pairs(self.remote_list) do 
                    local realPath = curDir..v.relativePath
                    if _getMd5(realPath)==v.md5 then
                        self.remote_list[k] = nil
                        print("-------已与本地文件相同,无需下载",v.relativePath,"remotePath:",v.remotePath)
                    end
                end
                callback(isSuccessP4v or isSuccessMod or isSuccessPkg)
            end)
        end)
    end)
    
    return true
end

function DevUpdaterFromFtp:_downloadFiles(callback)
    local ftpDownArr = {}
    for k,v in pairs(self.remote_list) do 
        table.insert(ftpDownArr,{v.localPath,v.remotePath})
    end

    local _start = os.clock()
    ftp_util:downloadFiles(ftpDownArr)
    local _end = os.clock()
    print("DevUpdaterFromFtp:_downloadFiles------used time:",_end-_start)
    
    local isCorrect = true --下载的文件是正确的
    for k,v in pairs(self.remote_list) do 
        local _md5 = _getMd5(v.localPath)
        if _md5~=v.md5 then 
            print("check md5 failed",v.localPath)
            isCorrect = false
        else
            v.file_size = commonlib.Files.GetFileSize(v.localPath)

        end
    end

    print("==========self.remote_list")
    echo(self.remote_list,true)

    if not isCorrect then
        print("error 下载文件校验失败")
    else
        print("ftp 下载完成")
        commonlib.Files.WriteFile(localVersionReadPath,self.remoteVer.."")
    end
    if callback then
        callback(isCorrect)
    end

    return isCorrect
end

function DevUpdaterFromFtp:_getDevVersion()
    local curRealVersion = GameLogic.options.GetClientVersion()
    local devVersion = curRealVersion
    local _,n = devVersion:gsub("%.",".")
    if n==3 then
        print("0 devVersion",devVersion)
        devVersion = devVersion:gsub("%.%d+$","")
        print("1 devVersion",devVersion)
    end
    
    devVersion = devVersion.."."..self.remoteVer

    return devVersion
end

--生成filelist.manifest, 方便调起Launcher 应用更新
function DevUpdaterFromFtp:_createApplyManifest(callback)
    local launcherExe = System.options.launcherExeName or "ParaCraft.exe"

    local arr = {}
    for k,obj in pairs(self.remote_list) do
        
        local url = string.format("xxx/%s,%s,%s.p",obj.relativePath,obj.md5,obj.file_size)
        local path = string.format("temp/dev_update_ftp/%s/%s",self:_getDevVersion(),obj.relativePath)
        local tab = {
            url,
            path,
            obj.relativePath,
            tostring(true),
            tostring(true),
        }
        local line = table.concat(tab,"|")
        
        if string.lower(obj.relativePath)==string.lower(launcherExe) then --Launcher直接先复制过去,剩下的文件，再来由launcher复制
            self.moveLauncherTask = {
                fromPath = curDir..path,
                toPath = curDir..obj.relativePath,
            }
        else
            self.moveLauncherTask = nil
            table.insert(arr,line)
        end
    end
    if #arr==0 then
        callback(true,true)
        return true
    end
    local str = table.concat(arr,"\r\n")
    print(str)
    _deleteFile(applyManifestFile)
    commonlib.Files.WriteFile(applyManifestFile,str)

    local devVersion = self:_getDevVersion()
    print("2 devVersion",devVersion)
    
    commonlib.Files.WriteFile(applyVerFile,"ver="..devVersion)
    
    local isSuccess = ParaIO.DoesFileExist(applyManifestFile) and ParaIO.DoesFileExist(applyVerFile)
    
    if callback then
        callback(isSuccess)
    end

    return isSuccess
end

function DevUpdaterFromFtp:_applyUpdate()
    local launcherExe = curDir..(System.options.launcherExeName or "ParaCraft.exe")
    
    if self.moveLauncherTask then
        print("-----move launcher to:",self.moveLauncherTask.fromPath,"=>>",self.moveLauncherTask.toPath)
        if(not ParaIO.MoveFile(self.moveLauncherTask.fromPath, self.moveLauncherTask.toPath))then
            print("-------move launcher failed")
        end
    end

    local applyManifestFile = applyManifestFile
    local applyVerFile = applyVerFile
    applyManifestFile = commonlib.Encoding.DefaultToUtf8(applyManifestFile) --防止中文路径Launcher识别不到
    applyVerFile = commonlib.Encoding.DefaultToUtf8(applyVerFile) --防止中文路径Launcher识别不到
    
    local isFixMode = false
    local cmdStr = string.format('isFixMode=%s justNeedCopy=true applyManifestFile="%s" applyVerFile="%s" 430storagePath="temp/dev_update_ftp/"',tostring(isFixMode),applyManifestFile,applyVerFile)
    print("cmdStr",cmdStr)

    print("launcherExe",launcherExe)
    ParaGlobal.ShellExecute("open", launcherExe, cmdStr, "", 1);
    ParaGlobal.ExitApp();
    ParaGlobal.ExitApp();
end