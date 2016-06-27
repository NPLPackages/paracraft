--[[
Title: World Revision
Author(s): LiXizhi
Date: 2014/4/28
Desc: a simple revision system for world files
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local world_revision = WorldRevision:new():init(worlddir);
world_revision:Checkout();
if(not world_revision:Commit()) then
	world_revision:Backup();
	world_revision:Commit(true);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/SaveWorldPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local WorldRevision = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision"));

local backup_folder = "worlds/DesignHouse/backups/";
-- only backup for the most recent 3 days. default to 3.
local max_days_to_backup = 3;
-- max number of backup on the topmost(most recent date). default to 3. 
local max_backups_on_topday = 3;
-- max number of backup on the older days
local max_backups_on_olderday = 1;

function WorldRevision:ctor()

end

function WorldRevision:init(worlddir)
	-- world directory
	self.worlddir = worlddir or ParaWorld.GetWorldDirectory();
	self.worldname = self.worlddir:match("([^/\\]+)[/\\]?$");
	self.revision_filename = self.worlddir.."revision.xml";
	self.current_revision = self.current_revision or 1;
	self.isModified = false;
	return self;
end

-- checkout revision. 
function WorldRevision:Checkout()
	self.current_revision = self:GetDiskRevision();
	return self.current_revision;
end

-- get the current revision
function WorldRevision:GetRevision()
	return self.current_revision;
end

-- load revision. 
function WorldRevision:GetDiskRevision()
	local revision;
	
	local file = ParaIO.open(self.revision_filename, "r");
	if(file and file:IsValid()) then
		revision = tonumber(file:GetText()) or self.current_revision;
		file:close();
	end
	return revision or 1;
end

function WorldRevision:HasConflict()
	if(self:GetDiskRevision() > self:GetRevision()) then
		return true;
	end
end

function WorldRevision:SetModified()
	self.isModified = true;
end

function WorldRevision:IsModified()
	return self.isModified;
end

-- @param bForceCommit: if true, it will commit using current version regardless of conflict. 
-- return true if commited successfully. 
function WorldRevision:Commit(bForceCommit)
	if(bForceCommit or not self:HasConflict()) then
		self.current_revision = self:GetRevision() + 1;
		self:SetModified();

		self:SaveRevision();
		return true
	end
end

function WorldRevision:GetBackupFileName()
	return string.format("%s%s_%s_%d.zip", backup_folder,self.worldname, ParaGlobal.GetDateFormat("yyyyMMdd"), self:GetRevision());
end

-- backup current revision to zip file if the zip file does not exist. 
function WorldRevision:Backup()
	self:AutoCleanupBackup();
	local filename = self:GetBackupFileName();
	if(not ParaIO.DoesFileExist(filename)) then
		ParaIO.CreateDirectory(filename);
		self:GeneratePackage(filename);
		LOG.std(nil, "info", "WorldRevision", "save world backup to %s", filename);
		BroadcastHelper.PushLabel({id="backup", label = format("版本%d 备份完毕", self:GetRevision()), max_duration=3000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	else
		LOG.std(nil, "error", "WorldRevision", "backup file already exist %s", filename);
		BroadcastHelper.PushLabel({id="backup", label = format("版本%d 之前备份过了", self:GetRevision()), max_duration=3000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
end

-- get world directory 
function WorldRevision:GetWorldDirectory()
	return self.worlddir;
end

function WorldRevision:OnOpenRevisionDir()
	local folder = self:GetBackupFileName():gsub("[^/\\]*$", "");
	Map3DSystem.App.Commands.Call("File.WinExplorer", folder);
end

-- automatically delete outdated backup files. 
-- it only keeps max_backups_on_olderday copies on max_days_to_backup, 
-- except for the most recent day where max_backups_on_topday is kept. 
function WorldRevision:AutoCleanupBackup()
	local filename = self:GetBackupFileName();
	
	local result = commonlib.Files.Find({}, backup_folder, 0, 10000, self.worldname.."*.*");
	table.sort(result, function(a, b)
		return (a.filename > b.filename)
	end)

	local top_date;
	local last_date;
	local filecount_on_last_date = 0;
	local date_count = 0;
	for i, file in ipairs(result) do
		local date, revision = file.filename:match("_(%d+)_(%d+)%.zip$");
		if(date and revision) then
			top_date = top_date or date;
			if(date == (last_date or date)) then
				filecount_on_last_date = filecount_on_last_date + 1;
				date_count = 1;
			else
				filecount_on_last_date = 1;
				date_count = date_count + 1;
			end

			local bDeleteFile;
			if(date_count > max_days_to_backup) then
				bDeleteFile = true;
			else
				if(top_date == date) then
					if(filecount_on_last_date > max_backups_on_topday) then
						bDeleteFile = true;
					end
				else
					if(filecount_on_last_date > max_backups_on_olderday) then
						bDeleteFile = true;
					end
				end
			end
			if(bDeleteFile) then
				local filename = backup_folder..file.filename;
				ParaIO.DeleteFile(filename);
				LOG.std(nil, "info", "WorldRevision", "auto delete backup %s", filename);
			end
			last_date = date;
		end
	end
end

-- compress and generate zip package for the current world.
-- it will ignore ./blockworld and package ./blockworld.lastsave   
-- @param filename: the output zip file. 
function WorldRevision:GeneratePackage(filename)
	-- compress the world in self.source, if it is not already compressed
	local worldpath = self:GetWorldDirectory();
	local zipfile = filename;
	local worldname = self.worldname;

	local function MakePackage_()
		local writer = ParaIO.CreateZip(zipfile,"");

		local result = commonlib.Files.Find({}, self:GetWorldDirectory(), 0, 500, function(item)
			return true;
		end)

		for i, item in ipairs(result) do
			local filename = item.filename;
			local filename_lowercased = string.lower(filename)
			if(filename_lowercased=="blockworld.lastsave") then
				local last_world_folder = worldpath..filename.."/";
				local files = commonlib.Files.Find({}, last_world_folder, 0, 500, function(item)
					return true;
				end)
				-- this fixed a bug when zip fails adding the lastsave folder because it looks like a file instead of folder to zip. 
				local dest_folder = worldname.."/blockworld.lastsave/";
				for _, file in ipairs(files) do
					if(file.filename) then
						writer:AddDirectory(dest_folder, last_world_folder..file.filename, 0);
					end
				end
			elseif(filename_lowercased=="blockworld") then
				-- ignore this folder
			elseif(filename) then
				local ext = commonlib.Files.GetFileExtension(filename);
				if(ext) then
					-- add all files
					writer:AddDirectory(worldname, worldpath..filename, 0);
				else
					-- add all folders
					writer:AddDirectory(worldname.."/"..filename.."/", worldpath..filename.."/".."*.*", 6);
				end
			end
		end

		-- writer:AddDirectory(worldname, worldpath.."*.*", 6);
		writer:close();
		LOG.std(nil, "info", "WorldRevision", "successfully generated package to %s", commonlib.Encoding.DefaultToUtf8(zipfile))
	end
	
	if(ParaIO.DoesFileExist(zipfile)) then
		ParaAsset.CloseArchive(zipfile);
		ParaIO.DeleteFile(zipfile);
	end
	MakePackage_();
end

function WorldRevision:SaveRevision()
	local revision = self:GetRevision();
	local file = ParaIO.open(self.revision_filename, "w");
	if(file and file:IsValid()) then
		file:WriteString(tostring(revision));
		file:close();
		LOG.std(nil, "info", "WorldRevision", "save revision %d for world %s", revision, self.revision_filename);
	end
end

-- TODO: not implemented
-- @param intervalSeconds: number seconds to do auto save. must be at least 10 seconds.
function WorldRevision:SetAutoSave(intervalSeconds)
	if(intervalSeconds and intervalSeconds<10) then
		return;
	end 
	self.autoSaveInterval = intervalSeconds;
end

-- ticks every second
function WorldRevision:Tick()
	
end