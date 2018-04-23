--[[
Title: upload world page
Author(s): LiXizhi
Date: 2008/6/29
Desc: 
It uploads the current world to user's logical path "worlds/[worldname].zip" on the remote server using paraworldAPI. 
The proceduce is make a zip package, and then upload to file server. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/UploadWorldPage.lua");
-------------------------------------------------------
]]
local L = CommonCtrl.Locale("IDE");

-- create class
local UploadWorldPage = {};
commonlib.setfield("Map3DSystem.App.worlds.UploadWorldPage", UploadWorldPage)

-- singleton
local page;

-- show the default category page. 
function UploadWorldPage.OnInit()
	page = document:GetPageCtrl();
	page:SetNodeValue("worldpath", ParaWorld.GetWorldDirectory());
	if(not Map3DSystem.User.HasRight("Save"))then
		page:SetNodeValue("result", "您没有权限发布这个世界.");
	end
	
	local filepath = ParaWorld.GetWorldDirectory().."preview.jpg";
	if(ParaIO.DoesFileExist(filepath, true)) then
		page:SetNodeValue("WorldImage", filepath);
	else
		page:SetNodeValue("WorldImage", "Texture/3DMapSystem/brand/noimageavailable.dds");
	end	
end

-- close the window
function UploadWorldPage.OnClose()
	Map3DSystem.App.Commands.Call("File.SaveAndPublish");
end

function UploadWorldPage.OnOpenWorldDir()
	Map3DSystem.App.Commands.Call("File.WinExplorer", ParaWorld.GetWorldDirectory());
end
function UploadWorldPage.OnQuickPublish()
	if(not Map3DSystem.User.HasRight("Save"))then
		_guihelper.MessageBox("对不起, 您没有权限发布这个世界.");
		return 
	end
	
	-- start a new task each time the publish button is clicked. 
	UploadWorldPage.currentTask = UploadWorldPage.NewTask({source=Map3DSystem.world.name, type = UploadWorldPage.TaskType.NormalWorld});
	UploadWorldPage.UpdateUIForTask();
end

function UploadWorldPage.OnGeneratePackage()
	UploadWorldPage.OnClose()
	if(not Map3DSystem.User.HasRight("Save"))then
		_guihelper.MessageBox("对不起, 您没有权限发布这个世界.");
		return 
	end
	
	-- compress the world in self.source, if it is not already compressed
	local source = Map3DSystem.world.name;
	local worldpath = source.."/";
	local zipfile = source..".zip";
	local worldname = string.gsub(source, ".*/(.-)$", "%1");

	local function MakePackage_()
		local writer = ParaIO.CreateZip(zipfile,"");
		writer:AddDirectory(worldname, worldpath.."*.*", 6);
		writer:close();
		autotips.AddMessageTips(string.format("世界成功打包到%s", zipfile));
	end
	
	if(ParaIO.DoesFileExist(zipfile)) then
		_guihelper.MessageBox(string.format("是否确定覆盖之前的世界:%s", zipfile), function ()
			ParaAsset.CloseArchive(zipfile);
			ParaIO.DeleteFile(zipfile);
			MakePackage_()
		end)
	else
		MakePackage_();
	end
end


function UploadWorldPage.OnPublishLink()
	UploadWorldPage.OnClose()
	if(not Map3DSystem.User.HasRight("Save"))then
		_guihelper.MessageBox("对不起, 您没有权限发布这个世界.");
		return 
	end
	autotips.AddMessageTips("此功能暂时不支持");
end

function UploadWorldPage.OnProgressBarStep(mcmlNode, step)
	ParaEngine.ForceRender();
end

-- update the current Uploader UI according to a given task. 
-- @param task: if nil, the UploadWorldPage.currentTask is used.
function UploadWorldPage.UpdateUIForTask(task)
	if(not task) then
		task = UploadWorldPage.currentTask;
		if(not task) then
			return
		end	
	end
	if(not page) then
		return
	end
	local _this;
	_this = page:FindControl("quickpublish")
	if(_this) then 	_this.enabled = false; else return end
	_this = page:FindControl("publishlink")
	if(_this) then 	_this.enabled = false; else return end
	_this = page:FindControl("packageonly")
	if(_this) then 	_this.enabled = false; else return end
	
	if(task.worldURLText) then
		page:SetUIValue("worldpath", task.source)
	else
		page:SetUIValue("worldpath", task.source)
	end	
	page:SetUIValue("txtUploadStatistics", task.subtaskStatistics)
	page:SetUIValue("txtUploadProgress", task.ProgressText)
	page:SetUIValue("progressbar", task.progress)
	
	if(task.type == UploadWorldPage.TaskType.NormalWorld or task.type == UploadWorldPage.TaskType.AdsWorld) then
		-- for world Uploader
		if(task.errorcode == 0) then
			if(task.progress == 100) then
				page:SetUIValue("result", L"successfully uploaded your 3D world")
				_this = page:FindControl("quickpublish")
				if(_this) then 	_this.enabled = true; else return end
				_this = page:FindControl("publishlink")
				if(_this) then 	_this.enabled = true; else return end
				_this = page:FindControl("packageonly")
				if(_this) then 	_this.enabled = true; else return end
			else
				page:SetUIValue("result", L"Please wait. It may take a few minutes.")
				--_this:GetChild("enterworld").enabled = false;
			end	
		else
			page:SetUIValue("txtUploadProgress", L"Upload is broken")
			
			if(task.errorcode == 1) then
				page:SetUIValue("result", L"Server connection is not found or broken")
			else
				if(task.errormessage~=nil) then
					page:SetUIValue("result", task.errormessage)
				end	
			end
			
			_this = page:FindControl("quickpublish")
			if(_this) then 	_this.enabled = true; else return end
			_this = page:FindControl("publishlink")
			if(_this) then 	_this.enabled = true; else return end
			_this = page:FindControl("packageonly")
			if(_this) then 	_this.enabled = true; else return end
		end	
	end
end

------------------------------------
-- upload task: 
-- stages: Start()->CompressWorld()->GetIP()->SyncWorld();  Stop();
------------------------------------

UploadWorldPage.NextNumber = 0;
UploadWorldPage.TaskPool = {}; -- a pool of {UploadWorldPage.Task} with index Task.source.
UploadWorldPage.currentTask = nil; -- the current task that should be displayed via the UI.
UploadWorldPage.MaxTotalsize = 10240000; -- user can only upload file size smaller than 10 MB.

-- the Upload task type
UploadWorldPage.TaskType = {
	NormalWorld = 0,
	AdsTexture = 1,
	AdsWorld = 2,
};

UploadWorldPage.Task = {
	-- the local world path, such as worlds/lixizhi or worlds/lixizhi.zip. if it is not a zip, it will convert it to a zip file. 
	source = nil,
	-- task type: 0 for world Uploading task;1 for normal file Upload
	type = 0,
	-- task priority: not used at the moment
	priority = 0,
	-- a value between 0 and 100
	progress = 0,
	-- Upload progress text
	ProgressText = "",
	-- if this is nil, the worldURLText will be the same as source
	worldURLText = nil,
	-- a string indicating a sub task Upload statistics, such as "100KB/2000KB", different tasks may have different formats.
	subtaskStatistics = "",
	-- this is assigned automatically. the larger the value, the later the task is added to the pool
	number = 0,
	-- start time: the time when the task is started. 
	starttime=0,
	-- error code: 0 means no error; 1 means line broken. 
	errorcode = 0,
	-- error message: string
	errormessage = nil,
	-- state: 0 paused, 1 started, -1 stoped
	state = 0,
};
UploadWorldPage.Task.__index = UploadWorldPage.Task;


-- Create a new task such as UploadWorldPage.NewTask({source="worlds/lixizhi", type = UploadWorldPage.TaskType.NormalWorld})
function UploadWorldPage.NewTask(o)
	if(not o or not o.source) then
		log("UploadWorldPage.NewTask(o) must has a table parameter with a source field\n"); return;
	end
	setmetatable(o, UploadWorldPage.Task);
	
	-- assign it a number
	o.number = UploadWorldPage.NextNumber;
	UploadWorldPage.NextNumber = UploadWorldPage.NextNumber + 1;
	-- Add it to task pool
	UploadWorldPage.TaskPool[o.source] = o;
	-- start the task immediately
	o:Start();
	return o
end

-- stop and remove a given task from the task pool
function UploadWorldPage.DeleteTask(o)
	if(o ~= nil) then
		-- stop it any way
		o:Stop();
		-- remove the current task if they are equal
		if(UploadWorldPage.currentTask ~= nil and UploadWorldPage.currentTask.source == o.source) then
			UploadWorldPage.currentTask = nil;
		end
		-- remove from the task pool
		UploadWorldPage.TaskPool[o.source] = nil;
	end
end

-- Get the given task by source string, it may return nil if source is not in the task pool
function UploadWorldPage.GetTask(source)
	return UploadWorldPage.TaskPool[source];
end

-------------------------------------------------
-- UploadWorldPage.task functions
-- task stages: Start()->CompressWorld()->GetIP()->SyncWorld();  Stop();
-------------------------------------------------

-- start this task
function UploadWorldPage.Task:Start()
	self.state = 1;
	if(self.type == UploadWorldPage.TaskType.NormalWorld) then
		-- for world sync: start the first stage
		self:CompressWorld();
	end
end

-- stop this task
-- @param errorcode: [int] it can be nil
-- @param errormessage: [string] it can be nil
function UploadWorldPage.Task:Stop(errorcode, errormessage)
	self.state = -1;
	self.errorcode = errorcode;
	self.errormessage = errormessage;
	self:UpdateUI();
	-- TODO: stop web services
end

-- only update UI if the current UI is this
function UploadWorldPage.Task:UpdateUI()
	if(UploadWorldPage.currentTask ~= nil and UploadWorldPage.currentTask.source == self.source) then
		UploadWorldPage.UpdateUIForTask(self);
	end
end

---------------------------------------
-- local stage: compress world to zip file
---------------------------------------
function UploadWorldPage.Task:CompressWorld()
	if(self.state == -1) then return end
	
	self.progress = 10;
	
	if(string.find(self.source, ".*%.zip$")==nil) then
		-- compress the world in self.source, if it is not already compressed
		local worldpath = self.source.."/";
		local zipfile = self.source..".zip";
		local worldname = string.gsub(self.source, ".*/(.-)$", "%1");
		
		if(ParaIO.DoesFileExist(zipfile)) then
			ParaAsset.CloseArchive(zipfile);
			ParaIO.DeleteFile(zipfile);
		end	
			
		local writer = ParaIO.CreateZip(zipfile,"");
		writer:AddDirectory(worldname, worldpath.."*.*", 6);
		writer:close();	
		self.worldzipfile = zipfile;
		self.ProgressText = string.format(L"world is successfully packed to %s and ready for publication.", zipfile);
		self:UpdateUI();
		
		log("world is compressed to "..zipfile.."\n")
		ParaEngine.ForceRender();
	else
		self.worldzipfile = self.source;	
	end
	self:SyncSpaceServer();
end

---------------------------------------
-- web stage: sync with the space server
---------------------------------------
function UploadWorldPage.Task:SyncSpaceServer()
	if(self.state == -1) then return end
	
	local worldzipfile = self.worldzipfile;
	self.worldname = string.gsub(worldzipfile, ".*/(.-)$", "%1");
	self.totalsize = ParaIO.GetFileSize(worldzipfile);
	if(self.totalsize>UploadWorldPage.MaxTotalsize) then
		self:Stop(3, L"Your world is too big; you need to apply to the administrators.");
		return;
	end
	
	self.ProgressText = string.format(L"Uploading to %s; Total file size %d KB", self.worldname, math.floor(self.totalsize/1000) );
	local msg = {
		src = worldzipfile,
		-- upload to worlds folder on remote server
		filepath = "worlds/"..self.worldname,
		overwrite = 1, -- overwrite it.
	};
	local res = paraworld.map.UploadFileEx(msg, "paraworld", function(msg)
		self:SyncSpaceServer_callback(msg)
	end)
	if(res == paraworld.errorcode.LoginRequired) then
		self:Stop(3, _guihelper.MessageBox("请先登陆"));
	end
	--_guihelper.MessageBox(L"Unable to upload your work, your local file does not exist".."\n");
end

function UploadWorldPage.Task:SyncSpaceServer_callback(msg)
	if(msg~=nil and msg.fileSize) then
		if(msg.fileURL~=nil) then
			commonlib.log("world space file successfully uploaded to %s\n", msg.fileURL)
			self.progress = 100;
			self.worldURLText = msg.fileURL;
			self.ProgressText = L"Upload complete!";
			self.subtaskStatistics = string.format("%d KB",  math.floor(self.totalsize/1000));
			self:UpdateUI();
		else
			self.progress = self.progress + 5;
			if(self.progress> 90) then
				self.progress = 90;
			end
			self.subtaskStatistics = string.format("%d/%d KB", math.floor(tonumber(msg.fileSize)/1000),  math.floor(self.totalsize/1000));
			self:UpdateUI();
		end	
	elseif(msg==nil) then
		self:Stop(3, _guihelper.MessageBox(L"Network is not available, please try again later".."\n"));
	else
		commonlib.echo(msg)
		self:Stop(3, _guihelper.MessageBox(L"We are unable to upload your work to the community website\n"));
	end	
end
