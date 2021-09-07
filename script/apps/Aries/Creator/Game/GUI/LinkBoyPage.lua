--[[
Title: LinkBoy Page
Author(s): leio
Date: 2021/7/15
Desc: run linkboy in paracraft
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/LinkBoyPage.lua");
local LinkBoyPage = commonlib.gettable("MyCompany.Aries.Game.GUI.LinkBoyPage");
LinkBoyPage.ShowPage();
LinkBoyPage.OnStartDownload();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/Files.lua");
NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
local ZipFile = commonlib.gettable("System.Util.ZipFile");

local LinkBoyPage = commonlib.gettable("MyCompany.Aries.Game.GUI.LinkBoyPage");

local page;
LinkBoyPage.root  = "linkboy"
LinkBoyPage.run_name  = "linkboy.exe";
LinkBoyPage.exe_full_path  = nil;
LinkBoyPage.source_url = "https://cdn.keepwork.com/paracraft/linkboy/linkboy_v4.60.zip?ver=v4.60";
LinkBoyPage.version  = "v4.60"
LinkBoyPage.maxFilesCnt = 100000;
LinkBoyPage.is_loading = false;
LinkBoyPage.loader = nil;
LinkBoyPage.timer = nil;
LinkBoyPage.cache_policy = "access plus 1 month";
function LinkBoyPage.OnInit()
	page = document:GetPageCtrl();
end

function LinkBoyPage.ShowPage()
	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/LinkBoyPage.html", 
			name = "LinkBoyPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -280/2,
				y = -130/2,
				width = 280,
				height = 130,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	
	LinkBoyPage.SetState(string.format("%s", LinkBoyPage.version));
end
-- return example: "linkboy/versions/linboy_v4.60.rar"
function LinkBoyPage.GetCurVersionZipName()
	local localFile = string.format("%s/versions/linkboy_%s.zip",LinkBoyPage.root, LinkBoyPage.version);
	return localFile;
end
-- return example: "linkboy/versions/linboy_v4.60"
function LinkBoyPage.GetCurVersionRoot()
	local filepath = string.format("%s/versions/linkboy_%s",LinkBoyPage.root, LinkBoyPage.version);
	return filepath;
end
function LinkBoyPage.OnStartDownload()
	if(LinkBoyPage.is_loading)then
		return 
	end
	LinkBoyPage.is_loading = true;
	local localFile = LinkBoyPage.GetCurVersionZipName();
	if(ParaIO.DoesFileExist(localFile))then
	    LOG.std(nil, "warn", "LinkBoyPage", "this version is existed: %s", localFile);
		local destFileName = commonlib.Files.splitText(localFile);
		LinkBoyPage.SetState("正在安装，请稍等");
		commonlib.TimerManager.SetTimeout(function()  
			LinkBoyPage.Decompress(localFile,destFileName);
			LinkBoyPage.SetState("安装成功");
			LinkBoyPage.is_loading = false;
		end, 1000)
		return
	end
	LinkBoyPage.SetState(string.format("开始下载", LinkBoyPage.version));
	LinkBoyPage.loader = LinkBoyPage.loader or FileDownloader:new();
	LinkBoyPage.loader:SetSilent();

	

	LinkBoyPage.loader:Init(nil, LinkBoyPage.source_url, localFile, function(b, msg)
		LinkBoyPage.OnStopDownload();
		LinkBoyPage.loader:Flush();
		LinkBoyPage.SetState("下载完成");
		if(b)then
			local destFileName = commonlib.Files.splitText(localFile);
			LinkBoyPage.SetState("正在安装，请稍等");
			commonlib.TimerManager.SetTimeout(function()  
				LinkBoyPage.Decompress(localFile,destFileName);
				LinkBoyPage.SetState("安装成功");
			end, 1000)
		else
			LinkBoyPage.SetState("下载失败");
		end
	end, LinkBoyPage.cache_policy);

	LinkBoyPage.timer = LinkBoyPage.timer or commonlib.Timer:new({callbackFunc = function(timer)
		local cur_size = LinkBoyPage.loader:GetCurrentFileSize() or 0;
		local total_size = LinkBoyPage.loader:GetTotalFileSize() or 0;
		local percent = 100;
		if(cur_size > 0 and total_size > 0)then
			percent = math.floor(10000 * (cur_size / total_size)) / 100;
		end
		LinkBoyPage.SetState(string.format("下载进度:%.2f%%", percent));
	end})

	LinkBoyPage.timer:Change(0, 1000);
end
function LinkBoyPage.OnStopDownload()
	if(LinkBoyPage.timer)then
		LinkBoyPage.timer:Change()
	end
	LinkBoyPage.is_loading = false;
end
function LinkBoyPage.Decompress(sourceFileName,destFileName)
    if(not sourceFileName or not destFileName)then return end
	if(ParaIO.DoesFileExist(sourceFileName))then
        local zipFile = ZipFile:new();
        if(zipFile:open(sourceFileName)) then
			LOG.std(nil, "info", "LinkBoyPage", "Decompress: %s -> %s", sourceFileName, destFileName);
	        zipFile:unzip(destFileName .. "/", LinkBoyPage.maxFilesCnt);
	        zipFile:close();
		else
			LOG.std(nil, "error", "LinkBoyPage", "Open failed: %s", sourceFileName);
			ParaIO.DeleteFile(sourceFileName);
        end
	else
		LOG.std(nil, "error", "LinkBoyPage", "the file isn't existed: %s", sourceFileName);
    end
end
function LinkBoyPage.OnSearchRunExeName()
	local localFile = LinkBoyPage.GetCurVersionZipName();
	local root = commonlib.Files.splitText(localFile);
	LOG.std(nil, "info", "LinkBoyPage", "serach from : %s", root);
    local run_path;
    local result = commonlib.Files.Find({}, root, 4, LinkBoyPage.maxFilesCnt, "*.exe") or {}
    for k,item in ipairs(result) do
        local ext = commonlib.Files.GetFileExtension(item.filename);
        if(ext)then
            ext = string.lower(ext)
            if(ext == "exe")then
                local dir,name = commonlib.Files.splitPath(item.filename)
                if(string.lower(name) == LinkBoyPage.run_name)then
                    run_path = dir
                end
            end
        end
    end
    return run_path
end
function LinkBoyPage.OnRun()
	if(LinkBoyPage.is_loading)then
		return
	end
	if(LinkBoyPage.exe_full_path)then
        if(not ParaIO.DoesFileExist(LinkBoyPage.exe_full_path))then
            LinkBoyPage.exe_full_path = nil
        else
            ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..LinkBoyPage.exe_full_path, "", "", 1);
            LinkBoyPage.OnClose();    
            return 
		end
    end
    local run_path = LinkBoyPage.OnSearchRunExeName();
    local filepath = string.format("%s/%s/%s", LinkBoyPage.GetCurVersionRoot(), run_path or "", LinkBoyPage.run_name);
	LOG.std(nil, "info", "LinkBoyPage", "run: %s", filepath);
    if(not ParaIO.DoesFileExist(filepath))then
		LOG.std(nil, "error", "LinkBoyPage", "the file isn't existed: %s", filepath);
		LinkBoyPage.OnStartDownload();
        return 
	end
    LinkBoyPage.OnClose();
    LinkBoyPage.exe_full_path = filepath;
    ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..LinkBoyPage.exe_full_path, "", "", 1);
end

function LinkBoyPage.OnClose()
	if(page)then
		page:CloseWindow();
	end
end
function LinkBoyPage.SetState(txt)
	if(page)then
		page:SetUIValue("state", txt);
	end
end
