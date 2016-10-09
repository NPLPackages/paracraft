--[[
Title: TODO: An UpdateTask checks for an update to a ManagedResourceStore
Author(s): LiXizhi
Date: 2008/3/4
Desc: An UpdateTask checks for an update to a ManagedResourceStore, and if found downloads the updated files and stores them locally in the WebCacheDB.
Upon completion of a successful update, the version that was downloaded will be in the VERSION_CURRENT ready state.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/update_task.lua");
-------------------------------------------------------
]]

if(not Map3DSystem.localserver) then Map3DSystem.localserver = {} end

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/WebCacheDB.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/capture_task.lua");

local WebCacheDB = Map3DSystem.localserver.WebCacheDB;
local TaskManager = Map3DSystem.localserver.TaskManager;

-- Returns true if an UpdateTask for the managed store is running
-- @param store_id: server id of the managed store. 
function Map3DSystem.localserver.IsUpdateTaskForStoreRunning(store_id)
	-- TODO: 
end

------------------------------------------------------------------------------
-- A UpdateTask processes a CaptureRequest asynchronously in the background. 
-- Notification messages are sent to the listener as each url in the request is completed.
------------------------------------------------------------------------------
local UpdateTask = {
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
Map3DSystem.localserver.UpdateTask = UpdateTask;

-- return the task object if succeed. otherwise nil.
-- upon created it will be automatically added to the TaskManager. The capture task can be accessed via its request id, 
-- and will be automatically removed when the task is completed. 
-- @param store: the ResourceStore object
-- @param request: type of CaptureRequest, usually from TaskManager:new_request(urls);
function UpdateTask:new(store, request)
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
function UpdateTask:Init(store, request)
	if(not store or not request or not request.id or TaskManager.tasks[request.id]) then
		log("warning: request uintialized when calling UpdateTask:Init()\n")
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
function UpdateTask:Abort()
	self.is_aborted_ = true;
	NPL.CancelDownload(tostring(self.capture_request_.id));
	self:Release();
end

-- run and process all requests one by one.
-- @param index: from which index to process. if nil, it will be 1. 
function UpdateTask:Run(index)
	local num_urls = self:GetUrlCount();
	local i = index or 1;
	if(i<=num_urls) then
		local url = self:GetUrl(i);
		
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
	end
	if(i > num_urls) then
		-- finished all url request. 
		-- call the task complete callback. 
		self:NotifyTaskComplete(true);
		self:Release();
	end
end

-- close and remove from task pool
function UpdateTask:Release()
	-- remove from task pool
	TaskManager.tasks[self.capture_request_.id] = nil;
end

function UpdateTask:GetUrlCount()
	if (self.is_aborted_) then
		return 0;
	end
	if(type(self.capture_request_.urls) == "string") then
		return 1;
	else
		return table.getn(self.capture_request_.urls);
	end
end

function UpdateTask:GetUrl(index)
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
function UpdateTask:AddProcessedUrl(url)
	self.processed_urls_ = self.processed_urls_ or {};
	table.insert(self.processed_urls_, url);
end

function UpdateTask:NotifyListener(status, success)
end


-- @param msg: data to be passed to the user specified callback. could be web service msg or entry object for files. 
function UpdateTask:NotifyUrlComplete(index, msg)
	if(self.capture_request_.callbackFunc) then
		self.capture_request_.callbackFunc(msg, self:GetUrl(index));
	end	
end

function UpdateTask:NotifyTaskComplete(success)
	if(self.capture_request_.OnTaskComplete) then
		self.capture_request_.OnTaskComplete(success);
	end
end

function UpdateTask:HttpGetUrl(full_url,if_mod_since_date, payload)
end

 