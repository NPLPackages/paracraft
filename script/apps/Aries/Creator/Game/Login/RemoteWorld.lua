--[[
Title: RemoteWorld
Author(s): LiXizhi
Date: 2014/1/17
Desc: represent a single downloadable remote world
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua");
local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld");
local world = RemoteWorld.LoadFromHref(url)
local world = RemoteWorld.LoadFromHref(url):SetHttpHeaders(headers)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");

local RemoteWorld = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld"));


function RemoteWorld:ctor()
end


function RemoteWorld:Init(remotefile, server, text, revision, icon, author, size, tag)
	if(not server) then
		return;
	end
	self.server = server;
	self.gs_nid, self.ws_id = server:match("^(%d+)%D(%d+)");

	self.remotefile = remotefile or "http://seed.com/TechDemo";
	if(remotefile) then
		-- just in case it is not a real file, but a seed to create the world from. 
		self.seed = remotefile:match("^http://seed.com/(.+)");
	end
	text = text or "";
	revision = revision or "";
	self.revision = revision;
	self.text = text;
	self.revision = revision;
	self.author = author;
	self.size = size;
	self.tag = tag;

	local tooltip = format(L"服务器:%s", server);
	if(revision~="") then
		tooltip = format(L"%s\n版本:%s", tooltip, revision);
	end
	self.tooltip = tooltip;

	if(icon) then
		self.icon = icon
	else
		self:SetIconByText(self.text);
	end

	self.worldpath = nil;

	-- home proxy
	if(server == "self") then
		self.force_nid = System.User.nid; 	
	else
		self.force_nid = System.User.nid; 
	end
	
	return self;
end

function RemoteWorld:SetHttpHeaders(headers)
	self.headers = headers;
	return self;
end

function RemoteWorld:SetProjectId(pid)
	self.projectId = tonumber(pid);
	return self;
end

local world_icons = {
	"Texture/blocks/items/1000_Tomato.png", 
	"Texture/blocks/items/1001_Wheat.png", 
	"Texture/blocks/items/1002_Blueberry.png", 
	"Texture/blocks/items/1003_Pumpkin.png", 
	"Texture/blocks/items/1004_Strawberry.png", 
	"Texture/blocks/items/1006_Onion.png", 
	"Texture/blocks/items/1007_Watermelon.png", 
	"Texture/blocks/items/1008_Corn.png", 
	"Texture/blocks/items/1009_Sunflower.png", 
	"Texture/blocks/items/1010_Eggplant.png", 
	"Texture/blocks/items/1011_Radish.png", 
	"Texture/blocks/items/1012_Broccoli.png", 
	"Texture/blocks/items/1013_Carrot.png", 
	"Texture/blocks/items/1014_Potato.png", 
	"Texture/blocks/items/1015_Ginger.png", 
	"Texture/blocks/items/1016_Blackberry.png", 
	"Texture/blocks/items/1017_Cucumber.png", 
	"Texture/blocks/items/1018_Spinach.png", 
	"Texture/blocks/items/1019_Sweetpotato.png", 
	"Texture/blocks/items/1020_Rye.png", 
};
-- static function
function RemoteWorld.GetIconFromText(text)
	local index = (mathlib.GetHash(text) % (#world_icons)) + 1
	return world_icons[index];
end

function RemoteWorld:SetIconByText(text)
	self.icon = RemoteWorld.GetIconFromText(text);
end


-- static: get world server record from HTML's A tag's href attr. 
-- sample
-- http://test.com/a.zip#server=1001_1#text=服务器名字
-- http://test.com/a.zip#server=self#text=服务器名字
-- http://test.com/a.zip#server#1001_1#text#服务器名字
function RemoteWorld.LoadFromHref(href, server)
	if(not href) then
		return 
	end
	server = href:match("#server[#=]([^#=]+)") or server;
	if(href and server) then
		local text = href:match("#text[#=]([^#=]+)") or server or "";
		local revision = href:match("#revision[#=]([^#=]+)") or "";
		local author = href:match("#author[#=]([^#=]+)") or "";
		local size = href:match("#size[#=]([^#=]+)") or "";
		local remotefile = href:match("^(http://.*zip)#server[#=]") or href;
		local tag = href:match("#tag[#=]([^#=]+)") or "";
		
		return RemoteWorld:new():Init(remotefile, server, text, revision, nil, author, size, tag);
	end
end

-- @param filename: this is the only required parameter. 
function RemoteWorld.LoadFromLocalFile(filename, server, text, revision, icon, author, size)
	if(not filename) then
		return 
	end
	return RemoteWorld:new():Init("local://"..filename, server or "self", text, revision, icon, author, size);
end

-- compute local file name
function RemoteWorld:ComputeLocalFileName()
	if(self.remotefile) then
		local filename;
		if(self.remotefile:match("paraengine.com/")) then
			filename = self.remotefile:match("([^/]+)%.zip$");
		else
			filename = self.remotefile:match("^(.*)%.zip") or self.remotefile;
			if(filename) then
				filename = filename:gsub("[%W%s]+", "_");
			end
		end
		local folder = ParaIO.GetWritablePath().."worlds/DesignHouse/userworlds/";
		if(self.projectId) then
			folder = folder..format("%d_%s_r%s.zip", self.projectId, filename, self.revision);
		else
			folder = folder..format("%s_r%s.zip", filename, self.revision);
		end
		return folder;
	end
end

-- get local filename
function RemoteWorld:GetLocalFileName()
	if(self.localpath) then
		return self.localpath;
	else
		self.localpath = self:ComputeLocalFileName();
		return self.localpath;
	end
end

function RemoteWorld:ClearDownloadState()
	self.FileDownloader = nil;
	self.isFinished = false;
	self.worldpath = nil;
end

function RemoteWorld:RemoveLocalFile()
	if(self:IsDownloaded()) then
		local filename = self:GetLocalFileName();
		if(filename:match("zip$")) then
			LOG.std(nil, "info", "RemoteWorld", "RemoveLocalFile %s", filename);
			ParaIO.DeleteFile(filename);
			self:ClearDownloadState();
			return true;
		else
			_guihelper.MessageBox("not zip file");
		end
	else
		return true;
	end
end

-- instead of downloading, we will generate using seed. 
function RemoteWorld:CreateWorldWithSeed(seed)
	-- TODO:
end


-- @param world: a table containing infor about the remote world. 
-- @param callbackFunc: function (bSucceed) end
-- @param refreshMode: nil|"auto"|"check"|"never"|"force".  
-- if nil or "never", we will never download again if there is already a local cached file. 
-- if "auto", we will compare Last-Modified or Content-Length in http headers, before download full file. 
-- if "force", we will always download the file. 
-- if "check", we will always check with remote server to compare file size before downloading. 
function RemoteWorld:DownloadRemoteFile(callbackFunc, refreshMode)
	refreshMode = refreshMode or "never";

	if(self.seed) then
		self:CreateWorldWithSeed(seed)
	end
	if(self.worldpath) then
		if(callbackFunc) then
			callbackFunc(true)
		end
		return;
	end

	local function OnCallbackFunc(bSuccess, dest)
		if(bSuccess) then
			self.worldpath = dest;
		end
		if(callbackFunc) then
			callbackFunc(bSuccess);
		end
	end

	local src = self.remotefile;
	local dest = self:ComputeLocalFileName();

	self.FileDownloader = self.FileDownloader or FileDownloader:new();

	local src_with_headers = src;
	if(self.headers) then
		src_with_headers = {url = src, headers = self.headers};
	end

	local showBBS = GameLogic.GetFilters():apply_filters("download_remote_world_show_bbs");
	if(refreshMode ~= "force" and ParaIO.DoesFileExist(dest)) then
		if(refreshMode == "auto") then
			local local_filesize = ParaIO.GetFileSize(dest);
			local last_filesize = self.FileDownloader:GetLastDownloadedFileSize(src);
			if(local_filesize == last_filesize) then
				LOG.std(nil, "info", "RemoteWorld", "world %s already exist locally with correct file size %d", dest, last_filesize);
				OnCallbackFunc(true, dest);
			else
				if (showBBS or showBBS == nil) then
					GameLogic.AddBBS("RemoteWorld", L("下载中...")..src, 8000, "255 0 0");
				end				
				LOG.std(nil, "info", "RemoteWorld", "remote(%d) and local(%d) file size differs, we will download again", last_filesize, local_filesize);
				self.FileDownloader:Init(L"世界", src, dest, function(bSuccess, dest)
					self.FileDownloader:Flush();
					OnCallbackFunc(bSuccess, dest);
				end, "access plus 5 mins", true);
			end
		elseif(refreshMode == "check") then			
			if (showBBS or showBBS == nil) then
				GameLogic.AddBBS("RemoteWorld", L("下载中...")..src, 8000, "255 0 0");
			end	
						
			-- get http headers only (take care of 302 http redirect)
			System.os.GetUrl(src_with_headers, function(err, msg)
				GameLogic.AddBBS("RemoteWorld", nil);
				local bUseLocalVersion;
				if(msg.rcode ~= 200 and (not msg.header or not msg.header:lower():find("\nlocation:", 1 , true))) then
					LOG.std(nil, "info", "RemoteWorld", "remote world can not be fetched, a previous downloaded world %s is used", dest);
					OnCallbackFunc(true, dest);
					return;
				else
					local content_length = msg.header:lower():match("content%-length: (%d+)");
					if(content_length) then
						content_length = tonumber(content_length);
						local local_filesize = ParaIO.GetFileSize(dest);
						if(local_filesize == content_length) then
							-- we will only compare file size: since github/master does not provide "Last-Modified: " header.
							LOG.std(nil, "info", "RemoteWorld", "remote world size not changed, previously downloaded world %s is used", dest);
							OnCallbackFunc(true, dest);
							return;
						else
							LOG.std(nil, "info", "RemoteWorld", "remote(%d) and local(%d) file size differs", content_length, local_filesize);
						end
					end
					LOG.std(nil, "info", "RemoteWorld", "remote file size can not be determined. download again.");
				end
				self.FileDownloader:Init(L"世界", src, dest, OnCallbackFunc, "access plus 5 mins", true);
			end, "-I");
		else
			LOG.std(nil, "info", "RemoteWorld", "world %s already exist locally", dest);
			OnCallbackFunc(true, dest);
		end
	else
		self.FileDownloader:Init(L"世界", src_with_headers, dest, OnCallbackFunc, "access plus 5 mins", true);	
	end
end

function RemoteWorld:IsDownloaded()
	return self:GetDownloadPercentage() == 100;
end

-- @return [-1,100]. return -1 if not downloaded. 100 if already downloaded.  
function RemoteWorld:GetDownloadPercentage()
	if(self.isFinished) then
		return 100;
	end
	local filename = self:GetLocalFileName();
	if(filename) then
		if(ParaIO.DoesFileExist(filename)) then	
			self.isFinished = true;
			return 100;
		elseif(self.FileDownloader) then
			local curSize = self.FileDownloader:GetCurrentFileSize()
			local totalSize = self.FileDownloader:GetTotalFileSize()
			if(curSize > 0) then
				return math.floor((curSize / totalSize)*100);
			else
				return 0;
			end
		end
	end
	return -1;
end
