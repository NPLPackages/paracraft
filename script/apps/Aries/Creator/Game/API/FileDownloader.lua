--[[
Title: FileDownloader
Author(s): LiXizhi
Date: 2014/1/22
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
FileDownloader:new():Init(text, url, localFile, callbackFunc);
FileDownloader:new():Init(nil, url);
FileDownloader:new():Init("Texture1", "http:/pe.com/blocktexture_FangKuaiGaiNian_16Bits.zip", "worlds/BlockTextures/");
FileDownloader:new():Init("Texture1", {url="https://baidu.com/", headers={Authorization = "Bearer XXXX"} }, nil, function(bSucceed, filename) echo(filename) end);
-------------------------------------------------------
]]
local FileDownloader = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader"));

FileDownloader.maxRetryCount = 2;

function FileDownloader:ctor()
end

-- init and start downloading
-- @param text: display title during download, if nil, default to local file name. 
-- @param url: remote url string or a table of {url, headers={}}
-- @param localFile: local filename or folder. if empty it will be computed from the url and saved to somewhere at "temp/webcache/*"
--  if it is a folder name ending with /, it will be saved to that folder with the name of the url file. 
-- @param callbackFunc: if succeed, function(true, localFile) end, if not, function(false, errorMsg) end
-- @param cachePolicy: default to "access plus 5 mins"
-- @param bAutoDeleteCacheFile: if true we will remove cache file after downloaded.
-- @param maxRetryCount: default to 2, we will try at least 2 times. 
-- @param progressCallbackFunc: function OnProgress(downloadState, text,currentFileSize, totalFileSize)  end, if provided, we will silence global tips
-- downloadState(0:downloading, 1:complete, 2:terminated),text(downloadFile text tips),currentFileSize, totalFileSize
function FileDownloader:Init(text, url, localFile, callbackFunc, cachePolicy, bAutoDeleteCacheFile, maxRetryCount, progressCallbackFunc)
	if(type(url) == "table") then
		self.url = url.url;
		self.headers = url.headers;
	else
		self.url = url;
		self.headers = nil;
	end

	if(localFile and localFile:match("/$"))then
		-- if it is a folder
		local filename = url:match("([^/]+)$");
		localFile = localFile..filename;
	end
	self.localFile = localFile;
	self.text = text or self.localFile;
	self.callbackFunc = callbackFunc;

	self.totalFileSize = -1;
	self.currentFileSize = 0;
	self.bAutoDeleteCacheFile = bAutoDeleteCacheFile;
	self.retryCount = 0;
	self.maxRetryCount = maxRetryCount;
	self.progressCallbackFunc = progressCallbackFunc;
	if(progressCallbackFunc) then
		self:SetSilent(true)
	end
	self:Start(self.url, self.localFile, self.callbackFunc, cachePolicy, self.headers);

	return self;
end

-- it displays nothing.
function FileDownloader:SetSilent()
	self.isSilent = true;
end

function FileDownloader:GetTotalFileSize()
	return self.totalFileSize or -1;
end

function FileDownloader:GetCurrentFileSize()
	return self.currentFileSize or 0;
end

-- delete cache file if any from temp/WebCache folder
function FileDownloader:DeleteCacheFile()
	if(self.cached_filepath) then
		LOG.std(nil, "info", "FileDownloader", "DeleteCacheFile %s", self.cached_filepath);
		ParaIO.DeleteFile(self.cached_filepath);
		self.cached_filepath = nil;
	end
end

-- it will return 0 if not found, or file size in bytes
function FileDownloader:GetLastDownloadedFileSize(url)
	local ls = System.localserver.CreateStore(nil, 1);
	if(ls) then
		local entry = ls:GetItem(url);
		if(entry and entry.payload and entry.payload.data) then
			local data = NPL.LoadTableFromString(entry.payload.data)
			if(data and data.totalFileSize) then
				return data.totalFileSize;
			end
		end
	end
	return 0;
end

function FileDownloader:Flush()
	local ls = System.localserver.CreateStore(nil, 1);
	if(ls) then
		ls:Flush();
	end
end

-- start file downloading. 
function FileDownloader:Start(src, dest, callbackFunc, cachePolicy, headers)
	local function OnSucceeded(filename)
		self.isFetching = false;
		if(callbackFunc) then
			callbackFunc(true, filename)
		end
	end

	local function OnFail(msg)
		self.isFetching = false;
		if(callbackFunc) then
			callbackFunc(false, msg);
		end
	end
	-- downloadState(0:downloading, 1:complete, 2:terminated),text(downloadFile text tips),currentFileSize, totalFileSize
	local function OnProgress(downloadState, text, currentFileSize, totalFileSize)
		GameLogic.GetFilters():apply_filters("downloadFile_notify", downloadState, text, currentFileSize, totalFileSize);
		if(self.progressCallbackFunc) then
			self.progressCallbackFunc(downloadState, text, currentFileSize, totalFileSize)
		end
	end
	
	local ls = System.localserver.CreateStore(nil, 1);
	if(not ls) then
		OnFail(L"本地数据失败");
		return;
	end
	
	if(self.isFetching) then
		OnFail(L"还在下载中...");
		return;
	end
	self.isFetching = true;

	local showLabel = GameLogic.GetFilters():apply_filters("file_downloader_show_label");

	local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
	local label_id = src or "userworlddownload";
	if(self.text ~= "official_texture_package" and (showLabel or showLabel == nil)) then
		if(not self.isSilent) then
			BroadcastHelper.PushLabel({id=label_id, label = format(L"%s: 正在下载中,请耐心等待", self.text or ""), max_duration=20000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
		end
	end
	LOG.std(nil, "info", "FileDownloader", "begin download file %s", src or "");
	
	local url = src;
	if(headers) then
		url = {url = url, headers = headers};
	end

	local res = ls:GetFile(System.localserver.CachePolicy:new(cachePolicy or "access plus 5 mins"),
		url,
		function (entry)
			if(dest) then
				if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
					self.cached_filepath = entry.payload.cached_filepath;
					if(self.bAutoDeleteCacheFile) then
						self:DeleteCacheFile();
					end
					--  download complete
					LOG.std(nil, "info", "FileDownloader", "successfully downloaded file from %s to %s", src, dest);
					OnSucceeded(dest);
				else
					LOG.std(nil, "info", "FileDownloader", "failed copy file from %s to %s", src, dest);
					OnFail(L"无法复制文件到指定目录");
				end	
			else
				LOG.std(nil, "info", "FileDownloader", "successfully downloaded file to %s", entry.payload.cached_filepath);
				OnSucceeded(entry.payload.cached_filepath);
			end
		end,
		nil,
		function (msg, url)
			local text;
			self.DownloadState = self.DownloadState;
			local isRedText = false;
			if(msg.DownloadState == "") then
				text = L"下载中..."
				if(msg.totalFileSize) then
					self.totalFileSize = msg.totalFileSize;
					self.currentFileSize = msg.currentFileSize;
					text = string.format(L"下载中: %d/%dKB", math.floor(msg.currentFileSize/1024), math.floor(msg.totalFileSize/1024));
				end
				
				OnProgress(0, text, math.floor(msg.currentFileSize/1024), math.floor(msg.totalFileSize/1024));
			elseif(msg.DownloadState == "complete") then
				text = L"下载完毕";				
				OnProgress(1, text);
			elseif(msg.DownloadState == "terminated") then
				text = L"下载终止了";
				self.retryCount =  self.retryCount + 1;
				if(self.retryCount <= self.maxRetryCount) then
					isRedText = true;
					LOG.std(nil, "warn", "FileDownloader", "downloading terminated for %s, we will try %d times", commonlib.serialize_compact(url), self.retryCount);
					LOG.std(nil, "warn", "FileDownloader", msg);
					self.isFetching = false;
					self:Start(src, dest, callbackFunc, cachePolicy, headers)
				else
					OnFail(L"下载终止了");
					isRedText = true;
					LOG.std(nil, "warn", "FileDownloader", "downloading terminated for %s", commonlib.serialize_compact(url));
					LOG.std(nil, "warn", "FileDownloader", msg);
					OnProgress(2, text);	
				end
			end
			if(not self.isSilent and text and self.text ~= "official_texture_package" and (showLabel or showLabel == nil)) then
				BroadcastHelper.PushLabel({id=label_id, label = format(L"文件%s: %s", self.text or "", text), max_duration=10000, color = isRedText and "255 0 0" or "0 255 0", scaling=1.1, bold=true, shadow=true,});
			end	
		end
	);
	if(not res) then
		OnFail(L"重复下载");
	end
end