--[[
Title: A CaptureTask processes a CaptureRequest asynchronously in the background
Author(s): LiXizhi
Date: 2008/2/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/capture_task.lua");
-------------------------------------------------------
]]

if(not Map3DSystem.localserver) then Map3DSystem.localserver = {} end

local npl_thread_name = __rts__:GetName();
if(npl_thread_name == "main") then
	npl_thread_name = "";
end

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB.lua");
local WebCacheDB = commonlib.gettable("Map3DSystem.localserver.WebCacheDB");

------------------------------------------------------------------------------
-- A CaptureRequest encapslates the parameters to a ResourceStore.capture() API call. Multiple urls can be specified in a single API call.
-- Note: Use TaskManager:new_request() to create an instance of this class
------------------------------------------------------------------------------
local CaptureRequest  = {
	-- int: captureId assigned by ResourceStore for this request
	id,
	-- request type, if nil, it is auto determined. this is 1 for URL request; and 2 for file request. 
	type = nil,
	-- url string or array of un-resolved urls provided by the caller
	urls = nil,
	-- url string or array of resolved urls in the same order as urls
	full_urls = nil,
	-- [optional] request msg of web service. only used when the request urls are for npl web services. 
	msg = nil,
	-- function to call when the a url request is complete. function(msg, callbackContext or url) end, where msg is the returned msg if any, url if the url that has responded. 
	callbackFunc = nil,
	-- this is an optional parameter that is passed to callbackFunc and OnTaskComplete
	callbackContext = nil,
	-- nil or function to call when the all urls in the request are completed. function(succeed, callbackContext) end
	OnTaskComplete = nil,
	
};
Map3DSystem.localserver.CaptureRequest = CaptureRequest;

------------------------------------------------------------------------------
-- TaskManager keeps a list of active task, one should use the task manager to add new request/task. 
-- the task manager will only start a new task if there is no previous same task or the previous one times out. 
-- this is a singleton class. 
------------------------------------------------------------------------------
local TaskManager = {
	-- mapping from request id to their associated CaptureTask. 
	tasks = {},
	-- urls that is currently being processed. mapping from url to true. 
	urls={},
	-- next request id, increased by one when each new request is created. 
	next_request_id = 0,
};
Map3DSystem.localserver.TaskManager = TaskManager;

-- create a new request for urls. it will return nil if there is already a same request being processed.
-- Note: this function will add urls to self.urls
-- @param urls: [in|out] url string or an array of un-resolved urls provided by the caller
-- @param requestType: nil if undetermined. 1 for url request, and 2 for file download request. 
-- if it is an array, when the function returns, urls that are being processed will be removed. 
function TaskManager:new_request(urls, requestType)
	if(type(urls) == "string") then
		if(self.urls[urls]) then
			return
		else
			self.urls[urls] = true;
		end
	elseif(type(urls) == "table") then
		-- remove urls that is already being processed from the array. 
		local i = 1;
		local url = urls[i];
		while url do
			if(self.urls[url]) then
				commonlib.removeArrayItem(urls, i);
				log("warning: duplicate url removed from capture task:"..url.."\n")
			else
				self.urls[url] = true;
				i=i+1;
			end
			url = urls[i];
		end
		if(table.getn(urls)==0) then
			return
		end
	end
	-- create a new request 
	local o = {id = self.next_request_id, urls = urls, type=requestType};
	setmetatable(o, CaptureRequest)
	CaptureRequest.__index = CaptureRequest
	self.next_request_id = self.next_request_id+1;
	return o;
end

-- return true if there is already a url being processed. 
-- @param url: url string. 
function TaskManager:HasUrl(url)
	return self.urls[urls];
end

-- return the task object by it request id.  
function TaskManager:GetTask(request_id)
	return self.tasks[request_id];
end


-- process a finished url request 
-- @param request_id: request id 
-- @param index: url index in the request
function Map3DSystem.localserver.ProcessURLRequest_result(request_id, index)
	local task = TaskManager:GetTask(request_id);
	if(not task) then
		log(string.format("warning: task request_id : %d not found in task manager.\n", request_id))
		return nil
	end
	local url = task:GetUrl(index);
	-- remove url from url that is being processed. 
	TaskManager.urls[url] = nil;
	
	local success;
	if(msg.code~=0 or msg.rcode~=200)  then
		commonlib.log("warning: cannot connect %s code=%s, rcode=%s.\n", url, tostring(msg.code), tostring(msg.rcode))

		-- if fetching failed, we will return the local server version (even if it is expired). 
		-- if there is no local server version either, the HTTP msg is returned.
		local ls = Map3DSystem.localserver.CreateStore(nil, 3);
		if(ls) then
			local entry = ls:GetItem(url);
			if(entry) then
				commonlib.log("however, a local version is found and returned\n")
				msg = {data = entry.payload.data, header=entry.payload.headers, code=0, rcode=200};
			end
		end
		-- call the callback func per url. 
		-- Use the local server
		task:NotifyUrlComplete(index, msg);
	else
		-- new item is successfully fetched.
		local new_item = {
			entry = WebCacheDB.EntryInfo:new({
				url = url,
			}),
			payload = WebCacheDB.PayloadInfo:new({
				status_code = Map3DSystem.localserver.HttpConstants.HTTP_OK,
				cached_filepath = nil,
				data = msg.data,
				headers = msg.headers,
			}),
		};
		
		-- call the callback func per url. 
		if(task:NotifyUrlComplete(index, msg)) then
			-- only save if url complete return true, meaning a valid message. 
			success = task.store_:PutItem(new_item);
		end	
	end
	
	if (success) then
		task:AddProcessedUrl(url);
	end
	
	-- process the next item in the task. 
	task:Run(index+1);
end

-- process a finished web service
-- @param request_id: request id 
-- @param index: url index in the request
function Map3DSystem.localserver.ProcessWS_result(request_id, index)
	--log(request_id..", "..index..commonlib.serialize(msg))
	
	local task = TaskManager:GetTask(request_id);
	if(not task) then
		log(string.format("warning: task request_id : %d not found in task manager.\n", request_id))
		return nil
	end
	local url = task:GetUrl(index);
	-- remove url from url that is being processed. 
	TaskManager.urls[url] = nil;
	
	local success;
	if(msg == nil)  then
		log(url.." returns an error msg: "..tostring(msgerror).."\n"); 
	else
		local new_item = {
			entry = WebCacheDB.EntryInfo:new({
				url = url,
			}),
			payload = WebCacheDB.PayloadInfo:new({
				status_code = Map3DSystem.localserver.HttpConstants.HTTP_OK,
				cached_filepath = nil,
				data = commonlib.serialize(msg),
			}),
		};
		success = task.store_:PutItem(new_item);
	end
	
	if (success) then
		task:AddProcessedUrl(url);
	end
	
	-- callthe callback func per url. 
	task:NotifyUrlComplete(index, msg);
	
	-- process the next item in the task. 
	task:Run(index+1);
end

-- process a NPL.AsyncDownload result
-- @param request_id: request id 
-- @param index: url index in the request
function Map3DSystem.localserver.ProcessFile_result(request_id, index)
	--log(request_id..", "..index..commonlib.serialize(msg))
	
	local task = TaskManager:GetTask(request_id);
	if(not task) then
		log(string.format("warning: task request_id : %d not found in task manager.\n", request_id))
		return nil
	end
	local url = task:GetUrl(index);
	
	if(url and msg~=nil) then
		-- notify progress
		task:NotifyUrlProgress(index, msg)
	end	
	
	if(url and msg~=nil and msg.DownloadState=="complete") then
		-- finished download
		TaskManager.urls[url] = nil;
		
		local dataDir = task.store_:GetDataDir();
		local DestFile;
		if(dataDir) then
			local tempfile = string.format("temp/tempdownloads/%d-%d.dat", request_id, index);
			-- overwrite the last file if exist. 
			local entry = task.store_:GetItem(url);
			if(entry) then
				DestFile = entry.payload.cached_filepath
				-- TODO: security check if dest folder is not in local server data dir?
			end
			if (not DestFile or DestFile == "") then
				local filename = string.gsub(url, ".*/", "");
				filename = string.gsub(filename, "[%?#].*$", "");
				DestFile = string.format("%s%s-%s", dataDir, ParaGlobal.GenerateUniqueID(), filename);
			end
			-- copy temp to local store's data directory. 
			ParaIO.CopyFile(tempfile, DestFile, true);
			-- delete temp file
			local alltempfiles = string.gsub(tempfile, "%.%d+%.dat$", ".*");
			ParaIO.DeleteFile(alltempfiles);
		else
			log("error: failed creating server directory in capture task.\n");
			task:Release();	
			return
		end
		local new_item = {
			entry = WebCacheDB.EntryInfo:new({
				url = url,
			}),
			payload = WebCacheDB.PayloadInfo:new({
				status_code = Map3DSystem.localserver.HttpConstants.HTTP_OK,
				cached_filepath = DestFile,
				data = nil,
			}),
		};
		
		if(msg.ContentType and string.find(msg.ContentType, "text/html")) then
			-- this is an HTTP web page. we will save the headers as well. 
			new_item.payload.headers = msg.Headers;
			-- new_item.payload.status_code = msg.StatusCode;
			new_item.payload.status_line = msg.StatusDescription;
		else
		end
		
		success = task.store_:PutItem(new_item);
		
		if (success) then
			task:AddProcessedUrl(url);
		end
		

		-- callthe callback func per url. 
		task:NotifyUrlComplete(index, new_item);
		
		-- process the next item in the task.
		task:Run(index+1);
	elseif(msg and msg.DownloadState and msg.DownloadState~="") then
		if(msg.DownloadState == "terminated") then
			TaskManager.urls[url] = nil;
		end
	end
end

------------------------------------------------------------------------------
-- A CaptureTask processes a CaptureRequest asynchronously in the background. 
-- Notification messages are sent to the listener as each url in the request is completed.
------------------------------------------------------------------------------
local CaptureTask = {
	-- Notification message codes sent to listeners
	CAPTURE_TASK_COMPLETE = 0,
	CAPTURE_URL_SUCCEEDED = 1,
	CAPTURE_URL_FAILED = 2,
	
	-- a reference to the ResourceStore making this capture
	store_ = nil,
	-- type of CaptureRequest
	capture_request_ = nil,
	-- mapping from finished url to true. 
	processed_urls_ = nil,
	
	--
	-- For async task
	--
	-- whether initialized
	is_initialized_ = nil,
	is_aborted_ = nil,
};
Map3DSystem.localserver.CaptureTask = CaptureTask;

-- return the task object if succeed. otherwise nil.
-- upon created it will be automatically added to the TaskManager. The capture task can be accessed via its request id, 
-- and will be automatically removed when the task is completed. 
-- @param store: the ResourceStore object
-- @param request: type of CaptureRequest, usually from TaskManager:new_request(urls);
function CaptureTask:new(store, request)
	if(not store or not request or TaskManager.tasks[request.id]) then
		return
	end
	
	local o = {};
	setmetatable(o, self)
	self.__index = self
	if(not o:Init(store, request)) then
		return
	end
	return o
end

-- return true if succeed. otherwise nil. 
-- upon return it will be automatically added to the TaskManager. The capture task can be accessed via its request id, 
-- @param store: the ResourceStore object
-- @param request: type of CaptureRequest
function CaptureTask:Init(store, request)
	if(not store or not request or not request.id or TaskManager.tasks[request.id]) then
		log("warning: request uintialized when calling CaptureTask:Init()\n")
		return;
	end
	if (not store:StillExistsInDB()) then
		self.is_initialized_ = nil;
		return;
	end
	
	self.store_ = store;
	self.capture_request_ = request;
	self.processed_urls_ = nil;
	self.is_initialized_  = true;
	
	-- add to task manager. 
	TaskManager.tasks[request.id] = self;
	return true;
end

-- Gracefully aborts the task that was previously started
function CaptureTask:Abort()
	self.is_aborted_ = true;
	NPL.CancelDownload(tostring(self.capture_request_.id));
	self:Release();
end

-- run and process all requests one by one.
-- @param index: from which index to process. if nil, it will be 1. 
function CaptureTask:Run(index)
	local num_urls = self:GetUrlCount();
	local i = index or 1;
	if(i<=num_urls) then
		local url = self:GetUrl(i);
		
		if(not self.capture_request_.type) then
			if(Map3DSystem.localserver.UrlHelper.IsWebSerivce(url)) then
				-- url is for web service
				-- get rid of query string
				local wsAddr = string.gsub(url, "%?.*$", "");
				--log(url.." is registered and called\n")
				NPL.RegisterWSCallBack(wsAddr, string.format("Map3DSystem.localserver.ProcessWS_result(%d, %d)", self.capture_request_.id, i));
				NPL.CallWebservice(wsAddr, self.capture_request_.msg or {});
			else
				-- url is for file and web pages. 
				
				-- we will first download to the temp folder.It may resume from last download
				-- get rid of query string ? and separator section #
				local file_url = string.gsub(url, "[%?#].*$", "");
				ParaIO.CreateDirectory("temp/tempdownloads/");
				local filename = string.format("temp/tempdownloads/%d-%d.dat", self.capture_request_.id, i);
				-- delete dest file to prevent multi-section download
				ParaIO.DeleteFile(filename); 
				-- download to temp directory. 
				NPL.AsyncDownload(file_url, filename, string.format("Map3DSystem.localserver.ProcessFile_result(%d, %d)", self.capture_request_.id, i), tostring(self.capture_request_.id));
			end	
		elseif(self.capture_request_.type== 1) then
			-- URL request
			NPL.AppendURLRequest(url, format("(%s)Map3DSystem.localserver.ProcessURLRequest_result(%d, %d)", npl_thread_name, self.capture_request_.id, i), nil, "r");
		elseif(self.capture_request_.type== 2) then
			-- FILE download request
		end	
	end
	if(i > num_urls) then
		-- finished all url request. 
		-- call the task complete callback. 
		self:NotifyTaskComplete(true);
		self:Release();
	end
end

-- close and remove from task pool
function CaptureTask:Release()
	-- remove from task pool
	TaskManager.tasks[self.capture_request_.id] = nil;
end

function CaptureTask:GetUrlCount()
	if (self.is_aborted_) then
		return 0;
	end
	if(type(self.capture_request_.urls) == "string") then
		return 1;
	else
		return table.getn(self.capture_request_.urls);
	end
end

function CaptureTask:GetUrl(index)
	if (self.is_aborted_) then
		return 0;
	end
	if(type(self.capture_request_.urls) == "string") then
		if(index == 1) then
			return self.capture_request_.urls;
		end	
	else
		return self.capture_request_.urls[index];
	end
end

-- add a processed url. 
function CaptureTask:AddProcessedUrl(url)
	self.processed_urls_ = self.processed_urls_ or {};
	table.insert(self.processed_urls_, url);
end

-- NOT USED: return true if processed. 
function CaptureTask:ProcessUrl(url)
	-- Don't continue to fetch urls if the store has been removed
	if (not self.store_.StillExistsInDB()) then
		return;
	end
	
	-- If we've already processed this url within this capture task, there is
	-- no need to fetch it again. This can occur if the array urls the caller
	-- has passed in contains duplicates, or when working with multiple urls
	-- that redirect to the same location.
	if (self.processed_urls[url]) then
		return true;
	end

	-- If we have an existing item for this url in our store, get it's modification date
	local previous_version_mod_date;
	local existing_item = self.store_:GetItemInfo(url);
	if (existing_item)  then
		-- TODO: do not make a new request within a day?
		-- or shall we make an http_modified_since request to determine whether to sync again?
	end

	----------------------------------  
	-- TODO: the following code is actually on return. 
	----------------------------------
end

-- @param msg: data to be passed to the user specified callback. It usually contains the progress of the given url
-- format is msg = {DownloadState=""|"complete"|"terminated", totalFileSize=number, currentFileSize=number, PercentDone=number} is the input
function CaptureTask:NotifyUrlProgress(index, msg)
	if(self.capture_request_.callbackProgressFunc) then
		self.capture_request_.callbackProgressFunc(msg, self.capture_request_.callbackContext or self:GetUrl(index));
	end	
end

-- @param msg: data to be passed to the user specified callback. could be web service msg or entry object for files. 
-- @return: true is returned if msg is not nil after msg translation. 
function CaptureTask:NotifyUrlComplete(index, msg)
	if(self.capture_request_.callbackFunc) then
		if(self.capture_request_.funcMsgTranslator) then
			msg = self.capture_request_.funcMsgTranslator(msg)
		end
		local bRes = (msg ~= nil);
		self.capture_request_.callbackFunc(msg, self.capture_request_.callbackContext or self:GetUrl(index));
		return bRes;
	end	
end

function CaptureTask:NotifyTaskComplete(success)
	if(self.capture_request_.OnTaskComplete) then
		self.capture_request_.OnTaskComplete(success, self.callbackContext);
	end
end


function CaptureTask:HttpGetUrl(full_url,if_mod_since_date, payload)
end

 