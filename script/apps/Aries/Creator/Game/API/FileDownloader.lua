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
-------------------------------------------------------
]]
local FileDownloader = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader"));

function FileDownloader:ctor()
end

-- init and start downloading
-- @param text: display title during download, if nil, default to local file name. 
-- @param url: remote url
-- @param localFile: local filename or folder. if empty it will be computed from the url and saved to somewhere at "temp/webcache/*"
--  if it is a folder name ending with /, it will be saved to that folder with the name of the url file. 
-- @param callbackFunc: if succeed, function(true, localFile) end, if not, function(false, errorMsg) end
-- @param cachePolicy: default to "access plus 5 mins"
-- @param bAutoDeleteCacheFile: if true we will remove cache file after downloaded.
function FileDownloader:Init(text, url, localFile, callbackFunc, cachePolicy, bAutoDeleteCacheFile)
	self.url = url;
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
	self:Start(self.url, self.localFile, self.callbackFunc, cachePolicy);

	return self;
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
function FileDownloader:Start(src, dest, callbackFunc, cachePolicy)
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

	local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
	local label_id = src or "userworlddownload";
	if(self.text ~= "official_texture_package") then
		BroadcastHelper.PushLabel({id=label_id, label = format(L"%s: 正在下载中,请耐心等待", self.text), max_duration=20000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
	end
	local res = ls:GetFile(System.localserver.CachePolicy:new(cachePolicy or "access plus 5 mins"),
		src,
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
			if(msg.DownloadState == "") then
				text = L"下载中..."
				if(msg.totalFileSize) then
					self.totalFileSize = msg.totalFileSize;
					self.currentFileSize = msg.currentFileSize;
					text = string.format(L"下载中: %d/%dKB", math.floor(msg.currentFileSize/1024), math.floor(msg.totalFileSize/1024));
				end
				
				GameLogic.GetFilters():apply_filters("downloadFile_notify", 0, text, math.floor(msg.currentFileSize/1024), math.floor(msg.totalFileSize/1024));
			elseif(msg.DownloadState == "complete") then
				text = L"下载完毕";				
				GameLogic.GetFilters():apply_filters("downloadFile_notify", 1, text);
			elseif(msg.DownloadState == "terminated") then
				text = L"下载终止了";
				OnFail(L"下载终止了");				
				GameLogic.GetFilters():apply_filters("downloadFile_notify", 2, text);
			end
			if(text and self.text ~= "official_texture_package") then
				BroadcastHelper.PushLabel({id=label_id, label = format(L"文件%s: %s", self.text, text), max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
			end	
		end
	);
	if(not res) then
		OnFail(L"重复下载");
	end
end