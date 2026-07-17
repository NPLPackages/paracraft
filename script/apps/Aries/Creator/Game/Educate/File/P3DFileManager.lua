--[[
    author:{pbb}
    time:2023-09-24 18:42:52
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/File/P3DFileManager.lua")
        local P3DFileManager = commonlib.gettable("MyCompany.Aries.Game.Educate.P3DFileManager");
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UrlProtocolHandler.lua");
local UrlProtocolHandler = commonlib.gettable("MyCompany.Aries.Creator.Game.UrlProtocolHandler");
local P3DFileManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Educate.P3DFileManager"));
local signature_file_name ="p3dfile.txt"
function P3DFileManager:Init()

end

function P3DFileManager:GetP3dFilePath()
    local filters = {{L"p3d(*.p3d)",  "*.p3d"}}
    local title = L"打开文件"
    local IsSaveMode = false
    local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32(filters, title,"", IsSaveMode);
    local fileType = self:GetFileType(filename)
    LOG.std(nil,"info","P3DFileManager","open file path=%s,type=%s",filename,fileType)
    if filename == "" or not filename then
        return
    end
    if not fileType or (fileType ~= "zip" and fileType ~= "pkg") then
        GameLogic.AddBBS(nil,L"暂不支持该加密方式的p3d文件")
        return 
    end
    return filename
end

function P3DFileManager:OpenP3dFile()
    self:LoadP3dFile(self:GetP3dFilePath())
end

function P3DFileManager:GetFileType(path)
    local path = path or ""
    local file = ParaIO.open(path, "r")
    local fileType = nil
    if (file:IsValid()) then
        local o = {}
        file:ReadBytes(4, o)
        if (o[1] == 80 and o[2] == 75) then
            fileType = "zip"
		elseif (o[1] == 0x2e and o[2] == 0x70 and o[3] == 0x6b and o[4] == 0x67) then -- 2e 70 6b 67 is hex of ".pkg"
            fileType = "pkg"
        end
        file:close()
    end
    return fileType
end

function P3DFileManager:ZipWorld()
    GameLogic.QuickSave();
    if not self:IsRemoteWorld() then
        return self:ZipWorldImp()
    end
    if self:IsRemoteWorld() and self:IsMineWorld() then
        local worldDir = "temp/temp_world"
        local srcPath = GameLogic.GetWorldDirectory()
        commonlib.Files.CopyFolder(srcPath, worldDir)
        if self:ClearWorldInfo(worldDir) then
            local zipDir = ParaIO.GetCurDirectory(0)..worldDir.."/"
            local zip_path,pkg_path = self:ZipWorldImp(zipDir)
            return zip_path,pkg_path,zipDir
        end
    end
    GameLogic.AddBBS("P3DFileManager",L"该世界暂不支持导出p3d文件")
end

function P3DFileManager:ClearWorldInfo(worldDir)
    if not worldDir then
        return false
    end
    local tagPath = worldDir.."/tag.xml"
    if not ParaIO.DoesFileExist(tagPath) then
        return false
    end
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld') or {};
    local username = GameLogic.GetFilters():apply_filters('store_get','user/username')
    local xmlRoot = ParaXML.LuaXML_ParseFile(tagPath)
    for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
        node.attr.parentInfo = (node.attr.parentInfo or "")..((node.attr.parentInfo and node.attr.parentInfo ~= "") and "," or "")..(username or "") .. "/" .. (currentEnterWorld and currentEnterWorld.kpProjectId) 
        break
    end
    return self:SaveXMLDataToFile(xmlRoot, tagPath)
end

function P3DFileManager:ZipWorldImp(worldDir)
    local extend_name = ".zip"
    local zip_path = ParaIO.GetCurDirectory(0).."temp/p3dtemp"..extend_name
    local pkg_path = ParaIO.GetCurDirectory(0).."temp/p3dtemp"..".pkg"
    zip_path = commonlib.Encoding.Utf8ToDefault(zip_path)
    local zipDir = worldDir or GameLogic.GetWorldDirectory()
    NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
    local ZipFile = commonlib.gettable("System.Util.ZipFile");
    local zipFile = ZipFile:new();
    if (zipFile:open(zip_path, "w")) then
        zipFile:AddDirectory("p3dtemp/", zipDir.."*.*", 10);
        zipFile:ZipAddData("p3dtemp/"..signature_file_name, "this is a valid p3d file"); --add signature
        zipFile:close();
        zipFile:SaveAsPKG()
        return zip_path,pkg_path
    end
end

function P3DFileManager:IsMineWorld()
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld') or {};
    local username = GameLogic.GetFilters():apply_filters('store_get','user/username')
    if username and username ~= "" and currentEnterWorld 
        and currentEnterWorld.user 
        and currentEnterWorld.user.username 
        and currentEnterWorld.user.username == username then
        return true
    end
    return false
end

function P3DFileManager:IsRemoteWorld()
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld') or {};
    return currentEnterWorld and currentEnterWorld.kpProjectId and tonumber(currentEnterWorld.kpProjectId) > 0
end

function P3DFileManager:CheckIsSpecialWorld()
    -- if not System.options.isEducatePlatform then
    --     return false
    -- end
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld') or {};
    -- echo(currentEnterWorld,true)
    local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
    local channel = tonumber((WorldCommon.GetWorldTag("channel") or 0))
    local isVisibility = tonumber((WorldCommon.GetWorldTag("visibility") or 0))
    local server_channel = currentEnterWorld.channel or 0
    if (channel ~= 0 or server_channel ~= 0) and ((currentEnterWorld.visibility and currentEnterWorld.visibility and currentEnterWorld.visibility == 1) or isVisibility == 1) then
        return true
    end
    
    local foldername = currentEnterWorld.foldername or ""
    --print("foldername=============",foldername)
    local regexStr = "^exam_world%d+_%d+_%d+_%d+"
    local regexStr1 = "^%d%d%d%d%d%d%d%d_%d+_%d+"
    if string.match(foldername,regexStr) or string.match(foldername,regexStr1) then
        return true
    end
    return false
end

function P3DFileManager:ExportWorldToP3dFile()
    if GameLogic.IsReadOnly() then
        GameLogic.AddBBS("P3DFileManager",L"只读世界暂不支持该功能")
        return
    end
    
    if self:CheckIsSpecialWorld() then
        GameLogic.AddBBS("P3DFileManager",L"该世界暂不支持导出p3d文件")
        return
    end
    
    if not self:CheckProtocolValid() then
        UrlProtocolHandler:RegisterFileExtensionProtocol()
    end
    local worldDirectory = GameLogic.GetWorldDirectory()
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld') or {};
    local worldName = currentEnterWorld.name or "default"
    local exportDir = ParaIO.GetCurDirectory(13) --桌面目录
    local filters = {{L"p3d(*.p3d)",  "*.p3d"}}
    local title = L"保存文件"
    local IsSaveMode = false
    local destFileName = worldName..".p3d"
    local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32(filters, title,exportDir, true);
    if filename then
        local fileDir,postfix = string.match(filename,"(.+)%.(.+)$");
        if(not postfix or ( postfix and string.lower(postfix) ~= "p3d" ))then
            filename = filename .. ".p3d";
        end
        if ParaIO.DoesFileExist(filename) then
            _guihelper.MessageBox(L"当前文件已存在，是否覆盖",function()
                local zip_path,pkg_path,tempDir = self:ZipWorld()
                if zip_path and zip_path ~= "" and pkg_path and pkg_path ~= "" then
                    if(not ParaIO.CopyFile(pkg_path, filename,true))then
                        LOG.std(nil,"info","P3DFileManager","export world %s to %s failed",pkg_path,filename)
                    else
                        if not System.options.isDevMode then
                            ParaIO.DeleteFile(zip_path)
                            ParaIO.DeleteFile(pkg_path)
                        end
                        GameLogic.AddBBS("P3DFileManager",L"世界导出成功")
                    end
                end
                if tempDir and ParaIO.DoesFileExist(tempDir) then
                    ParaIO.DeleteFile(tempDir)
                end
            end)
            return
        end
        local zip_path,pkg_path,tempDir = self:ZipWorld()
        if zip_path and zip_path ~= "" and pkg_path and pkg_path ~= "" then
            if(not ParaIO.CopyFile(pkg_path, filename,true))then
                LOG.std(nil,"info","P3DFileManager","export world %s to %s failed",pkg_path,filename)
            else
                if not System.options.isDevMode then
                    ParaIO.DeleteFile(zip_path)
                    ParaIO.DeleteFile(pkg_path)
                end
                GameLogic.AddBBS("P3DFileManager",L"世界导出成功")
            end
        end
        if tempDir and ParaIO.DoesFileExist(tempDir) then
            ParaIO.DeleteFile(tempDir)
        end
    end
end

function P3DFileManager:CheckFileValid(strFilepath)
    if not strFilepath or strFilepath == "" then
        LOG.std(nil,"info","P3DFileManager","file is invalid")
        return
    end
    if not ParaIO.DoesFileExist(strFilepath) then
		LOG.std(nil,"info","P3DFileManager","file is not exist in %s",strFilepath)
        GameLogic.AddBBS(nil,L"p3d文件不存在")
        return
	end
    
    local filename = strFilepath:match("[/\\]([^/\\]+%.%w%w%w)$");
    if not filename:match("%.p3d$") then
        LOG.std(nil,"info","P3DFileManager","this is not p3d file")
        GameLogic.AddBBS(nil,L"导入的不是p3d文件")
        return
    end
    if not self:CheckFileValid1(strFilepath) then
        LOG.std(nil,"info","P3DFileManager","打开文件失败，p3d文件已损坏")
        GameLogic.AddBBS(nil,L"打开文件失败，p3d文件已损坏")
        return
    end
    return true
end

function P3DFileManager:CheckFileValid1(strFilepath)
    local output,output1 = {},{}
    ParaAsset.OpenArchive(strFilepath, true)
    commonlib.Files.Find(output, '', 0, 500, ':tag.xml', strFilepath)
    commonlib.Files.Find(output1, '', 0, 500, ':'..signature_file_name, strFilepath)
    ParaAsset.CloseArchive(strFilepath)
    
    if #output == 0  then --or #output1 == 0
        local fileType = self:GetFileType(strFilepath)
        local filename = strFilepath:match("[/\\]([^/\\]+%.%w%w%w)$");
        local destPath = "temp/"..filename:gsub(".p3d","."..fileType)
        local bCopyResult = ParaIO.CopyFile(strFilepath,destPath,true)

        ParaAsset.OpenArchive(destPath, true)
        commonlib.Files.Find(output, '', 0, 500, ':tag.xml', destPath)
        commonlib.Files.Find(output1, '', 0, 500, ':'..signature_file_name, destPath)
        ParaAsset.CloseArchive(destPath)

        ParaIO.DeleteFile(destPath)
    end

    if #output == 0 then
        return 
    end
    -- if #output1 == 0 then
    --     return
    -- end
    return true
end

function P3DFileManager:GetValidFile(strFilepath)
    local isReplace = false
    if not strFilepath or strFilepath == "" then
        return strFilepath,isReplace
    end
    local output,output1 = {},{}
    ParaAsset.OpenArchive(strFilepath, true)
    commonlib.Files.Find(output, '', 0, 500, ':tag.xml', strFilepath)
    commonlib.Files.Find(output1, '', 0, 500, ':'..signature_file_name, strFilepath)
    ParaAsset.CloseArchive(strFilepath)
    
    if #output == 0 then --or #output1 == 0
        local fileType = self:GetFileType(strFilepath)
        local filename = strFilepath:match("[/\\]([^/\\]+%.%w%w%w)$");
        local destPath = "temp/"..filename:gsub(".p3d","."..fileType)
        local bCopyResult = ParaIO.CopyFile(strFilepath,destPath,true)

        ParaAsset.OpenArchive(destPath, true)
        commonlib.Files.Find(output, '', 0, 500, ':tag.xml', destPath)
        commonlib.Files.Find(output1, '', 0, 500, ':'..signature_file_name, destPath)
        ParaAsset.CloseArchive(destPath)
        strFilepath = destPath
        isReplace = true
    end
    return strFilepath,isReplace
end

function P3DFileManager:LoadP3dFile(strFilepath)
    if not self:CheckProtocolValid() then
        UrlProtocolHandler:RegisterFileExtensionProtocol()
    end
    if not self:CheckFileValid(strFilepath) then  
        return
    end
    local path,isNew = self:GetValidFile(strFilepath)
    strFilepath = isNew and ParaIO.GetCurDirectory(0)..path or strFilepath

    local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
    if WorldCommon.IsModified() then
        _guihelper.MessageBox(format(L"当前世界未保存，是否直接打开: %s?", strFilepath), function(res)
            if(res == _guihelper.DialogResult.Yes) then
                GameLogic.RunCommand("/loadworld "..strFilepath)
            end
        end, _guihelper.MessageBoxButtons.YesNo);
        return
    end
    GameLogic.RunCommand("/loadworld "..strFilepath)
    
end

function P3DFileManager:ImportP3dFile(filePath,bOpen,callback)
    local strFilepath = (filePath and filePath ~= "") and filePath or self:GetP3dFilePath()
    if not self:CheckFileValid(strFilepath) then
        return
    end
    GameLogic.CheckSignedIn(L"请先登录！", function()
        self:ImportP3dFileImp(strFilepath,bOpen,callback)
    end);
end

function P3DFileManager:GetTagValue(tagPath,key)
    local xmlRoot
    if not self.xmlRoot then
        self.xmlRoot = ParaXML.LuaXML_ParseFile(tagPath)
        xmlRoot = commonlib.copy(self.xmlRoot)
    else
        xmlRoot = commonlib.copy(self.xmlRoot)
    end
    local data;
    if(xmlRoot) then
        for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
            data = node.attr
            break
        end
        return data and data[key]
    end 
end

function P3DFileManager:ImportP3dFileImp(filePath,bOpen,callback)
    if not self:CheckProtocolValid() then
        UrlProtocolHandler:RegisterFileExtensionProtocol()
    end
    local fileType = self:GetFileType(filePath)
    local filename = filePath:match("[/\\]([^/\\]+%.%w%w%w)$");
    local destPath = "temp/"..filename:gsub(".p3d","."..fileType)
    local bCopyResult = ParaIO.CopyFile(filePath,destPath,true)
    if bCopyResult then
        local unzipPath = "temp/p3dtemp/"
        local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
        local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
        local default_path = LocalServiceWorld:GetDefaultSaveWorldPath()
        local default_user_path = LocalServiceWorld:GetUserFolderPath()
        LocalService:MoveZipToFolder(unzipPath, destPath,function()
            local fileList = LocalService:LoadFiles(unzipPath, true, true)
            echo(fileList,true)
            if not fileList or type(fileList) ~= 'table' or #fileList == 0 then
                return
            end
            local zipRootPath = ''
            if fileList[1] and fileList[1].filesize == 0 then
                zipRootPath = fileList[1].filename
            end
            self.xmlRoot = nil
            local tagPath = ""
            for k,v in pairs(fileList) do
                if v.filename:find("tag.xml") then
                    tagPath = v.file_path
                    break
                end
            end
            if tagPath == "" then
                return
            end
            local name = self:GetTagValue(tagPath,"name") or "defaultWorld"
            if ParaIO.DoesFileExist(default_user_path.."/"..name.."/tag.xml") then
                name = name.."_"..os.time()
            end
            self.worldName = name
            local worldpath = default_user_path.."/"..name.."/"
            ParaIO.CreateDirectory(worldpath)

            for key, item in ipairs(fileList) do
                if key ~= 1 then
                    local relativePath = commonlib.Encoding.Utf8ToDefault(item.filename:gsub(zipRootPath .. '/', ''))
                    if item.filesize == 0 then
                        
                        local folderPath = worldpath .. relativePath .. '/'

                        ParaIO.CreateDirectory(folderPath)
                    else
                        local filePath = worldpath .. relativePath
                        if not filePath:find(signature_file_name) then
                            ParaIO.MoveFile(item.file_path, filePath)
                        end
                    end
                end
            end

            ParaIO.DeleteFile(unzipPath)
            ParaIO.DeleteFile(destPath)
            if bOpen then
                GameLogic.GetFilters():add_filter("OnBeforeLoadWorld",P3DFileManager.OnBeforeLoadWorld)
                GameLogic.RunCommand("/loadworld "..worldpath)
                GameLogic.GetFilters():apply_filters("ImprotP3dFile",worldpath,true)
                return
            end
            
            if self.xmlRoot then
                local filename = worldpath.."tag.xml"
                local bSuccess = self:SaveXMLDataToFile(self.xmlRoot, filename)
                GameLogic.GetFilters():apply_filters("ImprotP3dFile",worldpath,bSuccess)
                if not bSuccess then
                    ParaIO.DeleteFile(worldpath)
                end
            end
        end)
    end
end

function P3DFileManager:OnBeforeLoadWorld()
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    WorldCommon.SetWorldTag("kpProjectId", 0);
    WorldCommon.SetWorldTag("platform", "paracraft_431");
    WorldCommon.SetWorldTag("name", P3DFileManager.worldName);
    WorldCommon.SetWorldTag("isHomeWorkWorld", false);
    WorldCommon.SetWorldTag("hasCopyright", false);
    WorldCommon.SetWorldTag("isVipWorld", false);

    WorldCommon.SetWorldTag("lessonPackageName", "");
    WorldCommon.SetWorldTag("lessonName", "");
    WorldCommon.SetWorldTag("materialName", "");
    WorldCommon.SetWorldTag("classroomId", "");
    WorldCommon.SetWorldTag("sectionContentId", "");
    WorldCommon.SetWorldTag("isFreezeWorld", false);

    WorldCommon.SetWorldTag("totalEditSeconds", 0);
    WorldCommon.SetWorldTag("totalClicks", 0);
    WorldCommon.SetWorldTag("totalKeyStrokes", 0);
    WorldCommon.SetWorldTag("totalSingleBlocks", 0);
    WorldCommon.SetWorldTag("totalWorkScore", 0);
    WorldCommon.SetWorldTag("totalWorkScore_bak", 0);
    WorldCommon.SetWorldTag("editCodeLine", 0);
    WorldCommon.SetWorldTag("model_entity_num", 0);

    WorldCommon.SetWorldTag("hide_player", nil);

    WorldCommon.SaveWorldTag()

    P3DFileManager.worldName = ""
    GameLogic.GetFilters():remove_filter("OnBeforeLoadWorld",P3DFileManager.OnBeforeLoadWorld);
end

-- return true if succeed
function P3DFileManager:SaveXMLDataToFile(xmlRoot, filename)
	local bSucceed = false;
	if(xmlRoot) then
		xmlRoot = self:ClearXmlData(xmlRoot)
		local xml_data = commonlib.Lua2XmlString(xmlRoot, true, true) or "";
		if (#xml_data >= 10240) then
			local writer = ParaIO.CreateZip(filename, "");
			if (writer:IsValid()) then
				writer:ZipAddData("data", xml_data);
				writer:close();
				bSucceed = true;
			end
		else
			local file = ParaIO.open(filename, "w");
			if(file:IsValid()) then
				file:WriteString(xml_data);
				file:close();

				bSucceed = true;
			end
		end
	end
	return bSucceed;
end

function P3DFileManager:ClearXmlData(xmlRoot)
    if not xmlRoot then return xmlRoot end
    for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
        node.attr.kpProjectId = 0
        node.attr.platform = System.options.appId or "paracraft"
        node.attr.name = (self.worldName and self.worldName ~= "") and self.worldName or node.attr.name
        node.attr.isHomeWorkWorld = false
        node.attr.hasCopyright = false
        node.attr.isVipWorld = false

        node.attr.lessonPackageName = ""
        node.attr.lessonName = ""
        node.attr.materialName = ""
        node.attr.classroomId = ""
        node.attr.sectionContentId = ""
        node.attr.isFreezeWorld = false

        node.attr.totalEditSeconds = 0
        node.attr.totalClicks = 0
        node.attr.totalKeyStrokes = 0
        node.attr.totalSingleBlocks = 0
        node.attr.totalWorkScore = 0
        node.attr.totalWorkScore_bak = 0
        node.attr.editCodeLine = 0
        node.attr.model_entity_num = 0

        node.attr.hide_player = nil
        break
    end
    self.worldName = ""
    return xmlRoot
end

function P3DFileManager:CheckProtocolValid()
    return UrlProtocolHandler:HasFileExtensionProtocol()
end

P3DFileManager:InitSingleton()
