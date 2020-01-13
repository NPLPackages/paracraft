--[[
Title: Temporary Http files used in current World
Author(s): LiXizhi
Date: 2016/12/2
Desc: files are saved to "temp/worldHttpFiles/" folder using md5(url) plus 
known file extension according to Content-Type in returned http headers 
or file extensions in url.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HttpFiles.lua");
local HttpFiles = commonlib.gettable("MyCompany.Aries.Game.Common.HttpFiles");
HttpFiles.GetHttpFilePath("https://github.com/LiXizhi/HourOfCode/archive/master.zip", function(err, filename) echo({err, filename}) end)
HttpFiles.ClearDiskCache();
-------------------------------------------------------
]]
local HttpFiles = commonlib.gettable("MyCompany.Aries.Game.Common.HttpFiles");

HttpFiles.diskfolder = "temp/worldHttpFiles/";

---------------------------------
-- a single remote file
---------------------------------
local RemoteFile = commonlib.inherit(nil, {});

RemoteFile.max_retry_count = 3;

function RemoteFile:ctor()
end

function RemoteFile:init(url, bCache)
	self.url = url;
	self.bCache = bCache;
	self.filename = nil;
	self.err = nil;
	local filename = ParaMisc.md5(self.url);
	self.disk_filename = HttpFiles.diskfolder..filename;
	NPL.load("(gl)script/ide/Files.lua");
	local result = commonlib.Files.Find({}, HttpFiles.diskfolder, 0, 1000, filename..".*")
	if(#result>=1) then
		LOG.std(nil, "info", "RemoteFile", "use existing file for url %s", self.url);
		self.filename = HttpFiles.diskfolder..result[1].filename;
	end	
	return self;
end

-- force download again
function RemoteFile:Download()
	self.err = nil;
	self.filename = nil;
	self.downloading = true;

	local filename = self.disk_filename;
	ParaIO.CreateDirectory(filename);

	if((self.retry_count or 0)== 0) then
		LOG.std(nil, "info", "RemoteFile", "begin downloading file url: %s", self.url);
	end

	System.os.GetUrl(self.url, function(rcode, msg, data)
		if(rcode == 200 and data) then
			local fileExt = self.url:match("%.(%w%w%w)$");
			if(msg.header) then
				local content_type = string.lower(msg.header):match("\ncontent%-type:%s*([^\r\n]+)");
				if(content_type) then
					if(content_type:match("mp3") or content_type:match("audio")) then
						fileExt = "mp3";
					elseif(content_type:match("wav")) then
						fileExt = "wav";
					elseif(content_type:match("ogg")) then
						fileExt = "ogg";
					elseif(content_type:match("mp4")) then
						fileExt = "mp4";
					elseif(content_type:match("jpg")) then
						fileExt = "jpg";
					elseif(content_type:match("png")) then
						fileExt = "png";
					elseif(content_type:match("stl")) then
						fileExt = "stl";
					end
				end
			end
			if(fileExt) then
				filename = filename .. "." ..fileExt;
			end
			self.err = nil;
			self.filename = filename;
			local file = ParaIO.open(filename, "w");
			if(file) then
				LOG.std(nil, "info", "RemoteFile", "remote file url: %s downloaded to %s", self.url, filename);
				file:write(data, #data);
				file:close();
			else
				LOG.std(nil, "warn", "RemoteFile", "can not save file to %s", filename);
				self.err = true;
			end
		else
			self.err = rcode;
		end
		if(self.err) then
			self.retry_count = (self.retry_count or 0) + 1;
			if(self.retry_count < self.max_retry_count) then
				LOG.std(nil, "info", "RemoteFile", "retry download remote file url: %s %d times", self.url, self.retry_count);
				self:Download();
				return;
			end
		end
		self:FlushCallback();
	end);
end

function RemoteFile:FlushCallback()
	self.downloading = nil;
	if(self.callbacks) then
		for _, callback in ipairs(self.callbacks) do
			callback(self.err, self.filename);
		end
		self.callbacks = nil;
	end
end

function RemoteFile:GetFile(callbackFunc)
	if(self.err or self.filename) then
		if(callbackFunc) then
			callbackFunc(nil, self.filename);
		end
	else
		self.callbacks = self.callbacks or {};
		self.callbacks[#self.callbacks+1] = callbackFunc;

		if(not self.downloading) then
			self:Download();
		end
	end
end

---------------------------------
-- singleton files
---------------------------------

-- url to RemoteFile map
local filecache = {};

-- download http file
-- @param url: must begin with http or https and proper file extension. 
-- @param callbackFunc: callback of function(err, filename) end, where err is nil if succeed. filename is local disk file.
-- @param bCache: reserved. no use. 
function HttpFiles.GetHttpFilePath(url, callbackFunc, bCache)
	if(url and url:match("^https?://")) then
		local file = filecache[url];
		if(not file) then
			file = RemoteFile:new():init(url);
			filecache[url] = file;
		end
		return file:GetFile(callbackFunc, bCache);
	end
end

-- clear all http file cache on disk
function HttpFiles.ClearDiskCache()
	local count = ParaIO.DeleteFile(HttpFiles.diskfolder.."*.*");
	LOG.std(nil, "info", "HttpFiles.ClearDiskCache", "%d files deleted", count or 0);
end

