--[[
Title: freeze world
Author(s): LiXizhi, WangYanXiang
Date: 2023/07/04
Desc: If freezeworld mode is on, blocks created before the /freezeworld command is frozen and can not be deleted or edited. 
In freeworld mode, only new blocks can be added or deleted. One can leave, add readonly blocks, 
then enter freeze mode again to add non-editable blocks, or one can use AddReadonlyBlockTemplate to add readonly blocks like above.
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/EditableWorld.lua")
local EditableWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.EditableWorld")
GameLogic.EditableWorld:Reset()
GameLogic.EditableWorld:FreezeWorld(bEnable)
GameLogic.EditableWorld:SaveEditPoints()
GameLogic.EditableWorld:LoadEditPoints()
GameLogic.EditableWorld:IsEditableBlock(bx, by, bz)
GameLogic.EditableWorld:SaveToWorldSlot(1)
GameLogic.EditableWorld:LoadFromWorldSlot(1)
GameLogic.EditableWorld:GetEditCount()

-- to add readonly blocks when loaded, using following commands:
GameLogic.EditableWorld:AddReadonlyBlockTemplate(filename, subtag)
GameLogic.EditableWorld:RemoveReadonlyBlockTemplate(filename)
GameLogic.EditableWorld:RemoveReadonlyBlockTemplateBySubTag(subtag)
GameLogic.EditableWorld:RemoveAllReadonlyBlockTemplates()

-- to see if there are any conflicts when adding readonly blocks from a file
local filename = GameLogic.EditableWorld:GetSlotFilename(1)
local blocks = GameLogic.EditableWorld:GetConflictBlocksFromFile(filename);
GameLogic.AddBBS(nil, "conflicting blocks:"..(#blocks), 3000, "255 0 0");
GameLogic.EditableWorld:ShowConflictBlocks(blocks, selectGroupIndex)
GameLogic.EditableWorld:ClearSelections()

GameLogic.RunCommand("/setworldinfo -editableWorldname msplanet")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua")
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local EditableWorld = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.EditableWorld"))
EditableWorld:Signal("editableCountChanged")

EditableWorld.isFreezeWorld = false
EditableWorld.isMemoryMode = false
EditableWorld.editCount = 0
-- Auto-save related properties
EditableWorld.autoSaveEnabled = false
EditableWorld.autoSaveTimer = nil
EditableWorld.autoSaveDelay = 3000 -- 3 seconds delay after last edit
EditableWorld.autoSaveFilename = nil
EditableWorld.restoreFolder = "__restore"
EditableWorld.maxRestoreFiles = 30 -- Maximum number of files to keep in restore folder
EditableWorld.tempEditableWorldsPath = "temp/editableworlds/" 
EditableWorld.editableWorldsPath = "worlds/editableworlds/" -- Path for storing editable world files
EditableWorld.maxLiveEntities = nil -- Maximum number of live entities allowed (nil = unlimited)

local addBlocks = {}
function EditableWorld:ctor()
	self:Clear()
	self.firstBlockData = {}
	GameLogic:Connect("WorldLoaded", self, self.OnEnterWorld, "UniqueConnection")
	GameLogic:Connect("WorldUnloaded", self, self.OnLeaveWorld, "UniqueConnection")
	GameLogic:Connect("WorldSaved", self, self.OnWorldSaved, "UniqueConnection")

	--[[ Perform migration on first initialization only
	if(not EditableWorld.isMigrated) then
		-- TODO: remove this after 1 month. 
		EditableWorld.isMigrated = true
		self:MigrateTempEditableWorldsOnce()
	end
	]]
end

function EditableWorld:GetEditableFolder(worldName)
	worldName = tostring(worldName or self:GetDefaultWorldName());
	local path = ParaIO.GetWritablePath().. self.editableWorldsPath..(System.User.username or "0").."/"..worldName.."/"
	return path
end

-- OBSOLETE: Migrate files from temp/editableworlds/ to worlds/editableworlds/ (called once per app)
function EditableWorld:MigrateTempEditableWorldsOnce()
	local tempPath = ParaIO.GetWritablePath() .. self.tempEditableWorldsPath
	local targetPath = ParaIO.GetWritablePath() .. self.editableWorldsPath
	
	-- Check if temp directory exists
	if not ParaIO.DoesFileExist(tempPath, false) then
		return
	end

	-- Check if migration has already been done
	local migrationMarkerFile = ParaIO.GetWritablePath() .. "temp/editableworlds/.migrated"
	if ParaIO.DoesFileExist(migrationMarkerFile, true) then
		return -- Migration already done
	end
	
	-- Find all files recursively in temp path (max depth 5 to get all subdirectories)
	local files = commonlib.Files.Find({}, tempPath, 5, 10000, function(item)
		return item and item.filename and item.filename:match("%.[^%.]+$")
	end)
	
	for _, file in ipairs(files) do
		if file.filename and file.filename ~= "" then
			local sourceFile = tempPath .. file.filename
			local targetFile = targetPath .. file.filename
			
			-- Create target directory if it doesn't exist
			ParaIO.CreateDirectory(targetFile)
			
			-- Move file from temp to permanent location
			if ParaIO.DoesFileExist(sourceFile, true) then
				if ParaIO.MoveFile(sourceFile, targetFile) then
					LOG.std(nil, "info", "EditableWorld", "Migrated file: %s -> %s", sourceFile, targetFile)
				else
					LOG.std(nil, "warn", "EditableWorld", "Failed to migrate file: %s -> %s", sourceFile, targetFile)
				end
			end
		end
	end
	
	-- Create marker file to indicate migration is complete
	ParaIO.CreateDirectory(migrationMarkerFile)
	local markerFile = ParaIO.open(migrationMarkerFile, "w")
	if markerFile:IsValid() then
		markerFile:WriteString("migrated")
		markerFile:close()
	end
	
	LOG.std(nil, "info", "EditableWorld", "Migration of temp editable worlds complete")
end

function EditableWorld:Clear()
	addBlocks = {}
	self.blocksMap = {}
	self.firstBlockData = {}
	self.liveEntityNames = {}
	self.editCount = 0
	self.currentSubTag = nil
end

function EditableWorld:Reset()
	self:Clear()
	if(not self.isMemoryMode and not GameLogic.IsReadOnly()) then
		self:WriteEditPointsToFile();
	end
end

-- call this before you call FreezeWorld()
-- if isMemoryMode is true, then the editable blocks will not be saved to disk.
function EditableWorld:SetMemoryMode(bEnable)
	self.isMemoryMode = bEnable
end

function EditableWorld:OnEnterWorld()
	self.filename = Files.WorldPathToFullPath("editableBlocks.txt")
	self:LoadEditPoints()
	-- self:EnableAutoSave()
end

function EditableWorld:OnLeaveWorld()
	self:UnregisterHooks()
	self.isFreezeWorld = false;
	self.isMemoryMode = false;
	self.subtagToActionnameCache = nil
	self.subtagToFilename = {}
	self:SetDefaultWorldName(nil)
	-- Disable auto-save when leaving world
	self:DisableAutoSave()
	-- Reset max live entities limit
	self.maxLiveEntities = nil
	self:Clear()
end

function EditableWorld:RegisterHooks()
	if self.hasRegistered then
		return
	end
	self.hasRegistered = true
	GameLogic.events:AddEventListener("CreateBlockTask", self.OnCreateBlockTask, self, "EditableWorld")
	GameLogic.events:AddEventListener("CreateDiffIdBlockTask", self.OnCreateBlockTask, self, "EditableWorld")
	GameLogic.events:AddEventListener("DestroyBlockTask", self.OnDestroyBlockTask, self, "EditableWorld")
	GameLogic.GetFilters():add_filter("BatchModifyBlocks", EditableWorld.OnBlockRegionChange)
	GameLogic.GetFilters():add_filter("CreateEntityTask", EditableWorld.OnCreateEntity)
	GameLogic.GetFilters():add_filter("create_block_event", EditableWorld.OnCreateBlockEvent)
	UndoManager:Connect("commandAdded", self, self.OnCommandAdded, "UniqueConnection");
end

function EditableWorld:UnregisterHooks()
	GameLogic.events:RemoveEventListener("CreateBlockTask", self.OnCreateBlockTask, self, "EditableWorld")
	GameLogic.events:RemoveEventListener("CreateDiffIdBlockTask", self.OnCreateBlockTask, self, "EditableWorld")
	GameLogic.events:RemoveEventListener("DestroyBlockTask", self.OnDestroyBlockTask, self, "EditableWorld")
	GameLogic.GetFilters():remove_filter("BatchModifyBlocks",EditableWorld.OnBlockRegionChange);
	GameLogic.GetFilters():remove_filter("CreateEntityTask", EditableWorld.OnCreateEntity);
	GameLogic.GetFilters():remove_filter("create_block_event", EditableWorld.OnCreateBlockEvent);
	UndoManager:Disconnect("commandAdded", self, self.OnCommandAdded);
	self.hasRegistered = false
end

function EditableWorld:OnCommandAdded(task)
	if(task) then
		local entity = task.draggingEntity or task.entity;
		if(entity) then
			if(entity.isFromEditableWorld) then
				self:AddEditCount()
			end
		else
			-- TODO: check for more cases like block changes
			self:AddEditCount()
		end
	end
end

function EditableWorld.OnCreateEntity(entity)
	local self = GameLogic.CreateGetEditableWorld();
	self:AddLiveEntity(entity)
	self:AddEditCount()
	return entity
end

function EditableWorld.OnBlockRegionChange(blocks, is_delete)
	local self = GameLogic.CreateGetEditableWorld();
	if type(blocks) == "table" then
		for i = 1, #blocks do
			local b = blocks[i];
			local x,y,z = b[1],b[2],b[3]
						
			if is_delete then
				--self:RemoveEditablePos(x,y,z)
			else
				self:AddEditablePos(x, y, z)
			end
		end
		self:AddEditCount(#blocks)
	end
	return blocks, is_delete
end

function EditableWorld.OnCreateBlockEvent(name)
	local self = GameLogic.CreateGetEditableWorld();
	self:AddEditCount()
	return name
end

function EditableWorld:OnWorldSaved()
	if(self.isMemoryMode) then
		return
	end
	self:SaveEditPoints();
end

function EditableWorld:GetBlockCanDestroy(x,y,z)
	if self.isFreezeWorld then
		return self:IsEditableBlock(x,y,z)
	end
	return true
end

function EditableWorld:IsEditableBlockForced(x,y,z)
	local mapIndex = GameLogic.BlockEngine:GetSparseIndex(x,y,z)
	return self.blocksMap[mapIndex] == true
end

function EditableWorld:IsEditableBlock(x,y,z)
	if self.isFreezeWorld then
		local mapIndex = GameLogic.BlockEngine:GetSparseIndex(x,y,z)
		return self.blocksMap[mapIndex] == true
	end
	return true;
end

function EditableWorld:OnCreateBlockTask(event)
	if self.isFreezeWorld and event.x ~= nil and event.y~= nil  and  event.z ~= nil then
		self:AddEditablePos(event.x, event.y, event.z)
		self:AddEditCount()
	end
end

function EditableWorld:AddEditablePos(x, y, z, bForceAdd)
	if bForceAdd or not self:IsEditableBlock(x,y,z) then
		self.blocksMap = self.blocksMap or {}
		local mapIndex = GameLogic.BlockEngine:GetSparseIndex(x,y,z)
		self.blocksMap[mapIndex] = true

		if(bForceAdd or self.isFreezeWorld) then
			self:AddEditCount()
		end
	end
end

function EditableWorld:RemoveEditablePos(x,y,z)
	if self:IsEditableBlock(x,y,z) then
		local mapIndex = GameLogic.BlockEngine:GetSparseIndex(x,y,z)
		self.blocksMap[mapIndex] = nil
	end
end

function EditableWorld:OnDestroyBlockTask(event)
	if self.isFreezeWorld then
		if event.x ~= nil and event.y~= nil  and  event.z ~= nil then
			--self:RemoveEditablePos(event.x, event.y, event.z)
		end
		self:AddEditCount()
	end
end

function EditableWorld:IsWorldFrozen()
	return self.isFreezeWorld
end

function EditableWorld:FreezeWorld(bEnable, isMemoryMode)
	LOG.std(nil, "info", "EditableWorld", "Set FreezeWorld %s, isMemoryMode %s",tostring(bEnable),tostring(isMemoryMode))
	if(isMemoryMode ~= nil) then
		self.isMemoryMode = isMemoryMode
	end
	self.isFreezeWorld = bEnable
	if self.isFreezeWorld then
		self:RegisterHooks()
	else
		self:UnregisterHooks()
	end

	if(not self.isMemoryMode) then
		self:Reset()	
		WorldCommon.SetWorldTag("isFreezeWorld",self.isFreezeWorld)
		WorldCommon.SaveWorldTag()
	end
end

-- save all editable block location to file
function EditableWorld:SaveEditPoints()
	local isFreezeWorld = WorldCommon.GetWorldTag("isFreezeWorld")
	if isFreezeWorld and not self.isMemoryMode then
		addBlocks = {}
		local x,y,z,_x,_y,_z
		local index = 0
		for k, v in commonlib.keysorted_pairs(self.blocksMap) do    
			index = index + 1
			x,y,z = GameLogic.BlockEngine:FromSparseIndex(k)
			if index == 1 then
				-- 第一个坐标为绝对坐标保存
				_x,_y,_z = x,y,z
				table.insert(addBlocks,x)
				table.insert(addBlocks,y)
				table.insert(addBlocks,z)
			else
				-- 往后的坐标存的是相对于第一个坐标的相对值
				table.insert(addBlocks,x - _x)
				table.insert(addBlocks,y - _y)
				table.insert(addBlocks,z - _z)
			end
		end
		self:WriteEditPointsToFile();
	end
end

function EditableWorld:WriteEditPointsToFile(filename)
	local file = ParaIO.open(filename or self.filename, "w");
	if(file:IsValid()) then
		LOG.std(nil, "info", "EditableWorld", "Save blocks in freeze mode")
		file:WriteString(commonlib.serialize_compact(addBlocks));
		file:close();
		return true;
	else
		LOG.std(nil, "warn", "EditableWorld", "Failed saving blocks in freeze mode");
		return false;
	end	
end

function EditableWorld:HandleDataToMap()
	self.blocksMap = {}
	local totalCount = math.ceil(#addBlocks / 3)
	local mapIndex,x,y,z
	for i = 1, totalCount do
		if i == 1 then
			-- 前三个数值为第一个坐标点,保持不变
			x,y,z = addBlocks[(i - 1) * 3 + 1],addBlocks[(i - 1) * 3 + 2],addBlocks[(i - 1) * 3 + 3]
		else
			-- 往后每三个数值为下一个坐标点,是相对与第一个坐标的相对值，需要加上第一个坐标的值
			x = addBlocks[(i - 1) * 3 + 1] + addBlocks[1]
			y = addBlocks[(i - 1) * 3 + 2] + addBlocks[2]
			z = addBlocks[(i - 1) * 3 + 3] + addBlocks[3]
		end
		mapIndex = GameLogic.BlockEngine:GetSparseIndex(x,y,z)
		self.blocksMap[mapIndex] = true
	end
end

function EditableWorld:LoadEditPoints()
	self.isFreezeWorld = WorldCommon.GetWorldTag("isFreezeWorld")
	if self.isFreezeWorld and not self.isMemoryMode then
		LOG.std(nil, "info", "EditableWorld", "Load FreezeWorld blocks %s",tostring(self.isFreezeWorld))
		if not ParaIO.DoesFileExist(self.filename, true) then
			addBlocks = {}
			self:WriteEditPointsToFile();
			self.blocksMap = {}
		else
			addBlocks = commonlib.LoadTableFromFile(self.filename)
			self:HandleDataToMap()
		end
		self:RegisterHooks()
	end
end

function EditableWorld:AddLiveEntity(entity, bCheckLimit)
	if(entity) then
		entity.isFromEditableWorld = true;

		-- if max live entity limit is set and reached, notify user and do not add
		if bCheckLimit and self:IsMaxLiveEntityLimitReached() then
			local count = self:GetLiveEntityCount()
			GameLogic.AddBBS(nil, string.format(L"已达到最大物品数量: %d/%d", count, self.maxLiveEntities), 6000, "255 0 0");
			entity:Destroy()
			return
		end

		
		self.liveEntityNames = self.liveEntityNames or {}
		self.liveEntityNames[entity.name] = true
		-- use AddEditCount to properly trigger autosave and increment count
		self:AddEditCount()
		return true
	end
end

function EditableWorld:SaveToBlockTemplate(filename)
	
	ParaIO.CreateDirectory(filename);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");

	-- add blocks
	local blocks = {};
	local bx, by, bz;
	for k, v in pairs(self.blocksMap) do    
		bx,by,bz = BlockEngine:FromSparseIndex(k)
		local blockId, blockData = BlockEngine:GetBlockIdAndData(bx, by, bz);
		if(blockId and blockId ~= 0) then
			blocks[#blocks + 1] = {bx, by, bz, blockId, blockData, BlockEngine:GetBlockEntityData(bx, by, bz)};
		end
	end
	local totalBlocks = #blocks
	-- add live entities
	local liveEntities = {};
	local totalLiveEntities = 0
	if(self.liveEntityNames) then
		for name, _ in pairs(self.liveEntityNames) do
			local entity = EntityManager.GetEntity(name);
			if(entity and entity.isFromEditableWorld) then
				liveEntities[#liveEntities + 1] = entity:SaveToXMLNode();
				totalLiveEntities = totalLiveEntities + 1
			end
		end
	end
	-- add player position
	local params = {};
	local bx, by, bz = EntityManager.GetFocus():GetBlockPos();
	-- params.player_pos = format("%d,%d,%d", bx, by, bz);
	-- if block position is nil or 0, it will load using absolute position if any. 
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, params = params, 
		blocks = blocks,liveEntities=liveEntities, 
		exportReferencedFiles = true, 
		onlyExportTempFiles = true})
	if(task:Run()) then
		LOG.std(nil, "info", "EditableWorld", "Save %d blocks to file %s", totalBlocks, filename)
		self.editCount = 0
		-- Remove paired autosave file after successful save (only if not saving to autosave file itself)
		if not filename:match("%.autosave") then
			self:RemoveAutoSaveFile(filename)
		end
		-- return success and stats table
		return true, {blocks = totalBlocks, liveEntities = totalLiveEntities};
	else
		LOG.std(nil, "warn", "EditableWorld", "Failed saving blocks to %s", filename);
	end
end

function EditableWorld:AddBlockTemplate(filename)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = filename, 
			blockX = 0, blockY = 0, blockZ = 0, UseAbsolutePos = true, nohistory = true, 
			TeleportPlayer = true
		})
	if(task:Run()) then
		LOG.std(nil, "info", "EditableWorld", "Load blocks from file %s", filename)
		self.editCount = 0
		return true;
	else
		LOG.std(nil, "warn", "EditableWorld", "Failed loading blocks from %s", filename);
	end
end

function EditableWorld:GetDefaultWorldName()
	return (self.defaultWorldname or WorldCommon.GetWorldTag("kpProjectId") or WorldCommon.GetWorldTag("name") or "Unnamed");
end

-- there is a command for this function: /setworldinfo -editableWorldname 
function EditableWorld:SetDefaultWorldName(name)
	self.defaultWorldname = name;
end

-- @param nSlotIndex
-- @param worldName: optional, default to project id or current world name.
function EditableWorld:LoadFromWorldSlot(nSlotIndex, worldName, subTag)
	local filename = self:GetSlotFilename(nSlotIndex, worldName, subTag)
	local bSucceed = self:LoadFromFile(filename)
	self.currentSubTag = subTag;
	-- Update the current filename and set new auto-save filename
	self.templateFilename = filename
	self:SetAutoSaveFilename()
	UndoManager.Clear();

	if(bSucceed) then
		local hasAutoSave, autosaveFilename = self:HasAutoSaveFileForSlot(nSlotIndex, worldName, subTag)
		if hasAutoSave then
			self:MoveToRestoreFolder(autosaveFilename);
			self:RemoveAutoSaveFile(filename);
			GameLogic.AddBBS("EditableWorldTip", L"检测到没有同步的存档，已为您备份，可随时找回", 10000, "255 0 0");
		end
		return true;
	end
end

function EditableWorld:GetCurrentSubTag()
	return self.currentSubTag;
end

function EditableWorld:LoadFromFile(filename)
	-- Auto-save current world if there are unsaved edits before loading new file
	self:AutoSaveBeforeLoad()
	
	self:RestoreToEmpty(true);
	
	if ParaIO.DoesFileExist(filename, true) then
		if(self:AddBlockTemplate(filename)) then
			-- Apply filter to notify about load failure
			GameLogic.GetFilters():apply_filters("editableworld_load", {filename = filename})
			return true;
		end
	end
	
end

-- save to temp/editableworlds/worldName/[nSlotIndex].[subTag].blocks.xml
-- @param nSlotIndex: index or filename, if string, it is treated as filename directly ignoring subTag
-- @param worldName: optional, default to project id or current world name.
function EditableWorld:GetSlotFilename(nSlotIndex, worldName, subTag)
	worldName = tostring(worldName or self:GetDefaultWorldName());
	local path = self:GetEditableFolder(worldName)
	local filename
	if type(nSlotIndex) == "string" then
		-- nSlotIndex is a filename string, use it directly
		filename = path..nSlotIndex
	else
		-- otherwise treat it as a slot index
		filename = path..tostring(nSlotIndex or 1)..".blocks.xml"
		if subTag and subTag ~= "" then
			filename = path..tostring(nSlotIndex or 1).."."..subTag..".blocks.xml"
		end
	end
	return filename;
end

-- @param nSlotIndex: index or filename
-- @param worldName: optional, default to project id or current world name.
function EditableWorld:SaveToWorldSlot(nSlotIndex, worldName, subTag)
	local filename = self:GetSlotFilename(nSlotIndex, worldName, subTag)
	local success, stats = self:SaveToBlockTemplate(filename)
	if(success) then
		self.templateFilename = filename
		self:SetAutoSaveFilename()
		return filename, stats;
	end
end

-- get all saved slots for a given world name.
-- @param worldName: optional, default to project id or current world name.
-- @return: a list of {index = n, filename = "1[.subtag].blocks.xml", subTag = "xxx"}
function EditableWorld:GetLocalWorldSlots(worldName, subTag)
	local slots = {}
	local path = self:GetEditableFolder(worldName)
	
	local result = commonlib.Files.Find({}, path, 0, 500, function(item)
		if(item.filename:match("%d+%..*blocks%.xml$")) then
			return true;
		end
	end)
	
	for _, file in ipairs(result) do
		local filename = file.filename
		local index, extractedSubTag = nil, nil
		
		if subTag and subTag ~= "" then
			local pattern = "^(%d+)%." .. subTag .. "%.blocks%.xml$"
			index = filename:match(pattern)
		else
			local pattern1 = "^(%d+)%.(.+)%.blocks%.xml$"
			local idx, sub = filename:match(pattern1)
			if idx and sub then
				index = idx
				extractedSubTag = sub
			else
				local pattern2 = "^(%d+)%.blocks%.xml$"
				index = filename:match(pattern2)
				extractedSubTag = nil -- 不带subTag
			end
		end
		
		if index then
			local data = {
				slotIndex = tonumber(index),
				filename = path..filename, 
				writedate = file.writedate, 
				filesize = file.filesize,
				subTag = extractedSubTag
			}
			slots[#slots + 1] = data
		end
	end
	
	table.sort(slots, function(a, b)
		if a.slotIndex ~= b.slotIndex then
			return a.slotIndex < b.slotIndex
		end
		return a.writedate > b.writedate
	end)
	return slots
end

function EditableWorld:RestoreToEmpty(bIgnoreUndoManager)
	
	local blocks =  self.blocksMap;
	local liveEntityNames = self.liveEntityNames;
	self:Reset()
	
	-- for all blocks, SetBlockToAir
	local bx, by, bz;
	for k, v in pairs(blocks) do
		bx,by,bz = BlockEngine:FromSparseIndex(k)
		BlockEngine:SetBlockToAir(bx, by, bz);
	end

	-- for all live entities, destroy them
	if(liveEntityNames) then
		for name, _ in pairs(liveEntityNames) do
			local entity = EntityManager.GetEntity(name);
			if(entity and entity.isFromEditableWorld) then
				entity:Destroy();
			end
		end
	end
	if(not bIgnoreUndoManager) then
    	UndoManager.Clear();
	end
end

-- Get the current edit count
-- @return: number of edits since last load or save
function EditableWorld:GetEditCount()
	return self.editCount or 0
end

-- Increment the edit count by a specified number (default is 1)
function EditableWorld:AddEditCount(count)
	self.editCount = (self.editCount or 0) + (count or 1)
	
	self:editableCountChanged();
end

-- check if there are no edits in the editable world
function EditableWorld:IsEmpty()
	return (self.editCount or 0) == 0 and (not self.liveEntityNames or next(self.liveEntityNames) == nil) and (not self.blocksMap or next(self.blocksMap) == nil)
end

-- Enable auto-save functionality
-- This will save the world to a temporary file after a few seconds of inactivity following edits
function EditableWorld:EnableAutoSave()
	if self.autoSaveEnabled then
		return -- Already enabled
	end
	
	self.autoSaveEnabled = true
	self:Connect("editableCountChanged", self, self.TriggerAutoSave, "UniqueConnection")
	LOG.std(nil, "info", "EditableWorld", "Auto-save enabled. Will save to: %s", self.autoSaveFilename or "N/A")
end

-- Disable auto-save functionality
function EditableWorld:DisableAutoSave()
	if not self.autoSaveEnabled then
		return -- Already disabled
	end
	
	self.autoSaveEnabled = false
	self:Disconnect("editableCountChanged", self, self.TriggerAutoSave)
	
	-- Cancel any pending auto-save timer
	if self.autoSaveTimer then
		self.autoSaveTimer:Change()
		self.autoSaveTimer = nil
	end
	
	LOG.std(nil, "info", "EditableWorld", "Auto-save disabled")
end

-- Set the auto-save filename based on current loaded file
function EditableWorld:SetAutoSaveFilename()
	local currentFilename = self.templateFilename
	if not currentFilename or currentFilename == "" then
		-- slot 0 for unnamed slots
		currentFilename = self:GetSlotFilename(0, self:GetDefaultWorldName())
	end
	if currentFilename and currentFilename ~= "" then
		-- Remove .autosave suffix if it already exists to avoid double-suffixing
		if currentFilename:match("%.autosave$") then
			currentFilename = currentFilename:gsub("%.autosave$", "")
		end
		-- Use current loaded file + ".autosave"
		self.autoSaveFilename = currentFilename .. ".autosave"
	end
end

-- Trigger auto-save after a delay
function EditableWorld:TriggerAutoSave()
	if not self.autoSaveEnabled then
		return
	end
	
	-- Set up new timer
	self.autoSaveTimer = self.autoSaveTimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:DoAutoSave()
		self.autoSaveTimer = nil
	end})
	
	-- Start timer with the specified delay
	self.autoSaveTimer:Change(self.autoSaveDelay, nil)
end

-- Perform the actual auto-save operation
function EditableWorld:DoAutoSave(bForced)
	if not bForced and (not self.autoSaveEnabled or self.editCount == 0) then
		return
	end
	
	-- Set auto-save filename if not already set
	if not self.autoSaveFilename then
		self:SetAutoSaveFilename()
	end
	
	-- Save the current state to auto-save file
	local success, stats = self:SaveToBlockTemplate(self.autoSaveFilename)

	-- If template filename and autosave filename have identical content, delete the autosave file
	if self.templateFilename and self.autoSaveFilename then
		local templateSize = ParaIO.GetFileSize(self.templateFilename)
		local autosaveSize = ParaIO.GetFileSize(self.autoSaveFilename)
		
		-- Compare file sizes first for quick check
		if templateSize == autosaveSize then
			if ParaIO.DeleteFile(self.autoSaveFilename) then
				LOG.std(nil, "info", "EditableWorld", "Deleted autosave file (identical content to template): %s", self.autoSaveFilename)
			end
		end
	end

	if success then
		LOG.std(nil, "info", "EditableWorld", "Auto-saved blocks to %s", self.autoSaveFilename)
		return true, stats
	else
		LOG.std(nil, "warn", "EditableWorld", "Failed to auto-save to %s", self.autoSaveFilename)
	end
end

-- Check if auto-save is enabled
-- @return: boolean indicating if auto-save is enabled
function EditableWorld:IsAutoSaveEnabled()
	return self.autoSaveEnabled == true
end

-- Set auto-save delay
-- @param delay: delay in milliseconds (default is 3000ms = 3 seconds)
function EditableWorld:SetAutoSaveDelay(delay)
	self.autoSaveDelay = delay or 3000
end

function EditableWorld:BackupWorldSlot(nSlotIndex, worldName, subTag)
	local filename = self:GetSlotFilename(nSlotIndex, worldName, subTag)
	if ParaIO.DoesFileExist(filename, true) then
		return self:MoveToRestoreFolder(filename, true)
	end
end

function EditableWorld:DeleteWorldSlot(slotIndex, worldName, subTag)
	local filename = self:GetSlotFilename(slotIndex, worldName, subTag)
	if ParaIO.DoesFileExist(filename, true) then
		-- Backup the main file before deleting
		self:MoveToRestoreFolder(filename, true)
		
		if ParaIO.DeleteFile(filename) then
			LOG.std(nil, "info", "EditableWorld", "Deleted world slot file: %s", filename)
			-- Also remove paired autosave file if exists
			self:RemoveAutoSaveFile(filename)
			GameLogic.AddBBS(nil, string.format(L"已备份并删除存档 %d, 你可随时本地找回", slotIndex or 1), 3000, "0 255 0");
			return true
		else
			LOG.std(nil, "warn", "EditableWorld", "Failed to delete world slot file: %s", filename)
		end
	end
end

-- Remove the autosave file paired with a given filename
-- @param filename: the main file for which to remove the autosave file. if nil, use current autoSaveFilename
function EditableWorld:RemoveAutoSaveFile(filename)
	local autosaveFilename
	if not filename then
		autosaveFilename = self.autoSaveFilename
		if not autosaveFilename then
			return -- no autosave file to remove
		end
	else
		autosaveFilename = filename .. ".autosave"
	end
	
	if ParaIO.DoesFileExist(autosaveFilename, true) then
		-- Move to restore folder instead of deleting
		if self:MoveToRestoreFolder(autosaveFilename) then
			LOG.std(nil, "info", "EditableWorld", "Moved autosave file to restore folder: %s", autosaveFilename)
		else
			LOG.std(nil, "warn", "EditableWorld", "Failed to move autosave file to restore folder: %s", autosaveFilename)
		end
	end
end

-- Move a file to the restore folder with a datetime-stamped filename
-- @param sourceFilename: the file to move
-- @param bCopy: if true, copy instead of move
-- @return: boolean indicating success
function EditableWorld:MoveToRestoreFolder(sourceFilename, bCopy)
	if not sourceFilename or not ParaIO.DoesFileExist(sourceFilename, true) then
		return false
	end
	
	-- Extract directory and filename from source path
	local sourceDir = sourceFilename:match("^(.+)[/\\][^/\\]+$") or ""
	local originalFilename = sourceFilename:match("([^/\\]+)$") or "unknown"
	
	-- Create restore folder in the same directory as the original file
	local restorePath = sourceDir .. "/" .. self.restoreFolder .. "/"
	ParaIO.CreateDirectory(restorePath)
	
	-- Generate filename based on file size
	local filesize = ParaIO.GetFileSize(sourceFilename)
	
	-- Create new filename with filesize
	-- Remove .autosave suffix from original filename if present
	originalFilename = originalFilename:gsub("%.autosave$", "")
	local restoreFilename = restorePath .. originalFilename .. "_" .. filesize
	
	-- Use filesize-based filename (identical filesizes will overwrite)
	local finalRestoreFilename = restoreFilename
	
	-- Copy or move the file based on bCopy parameter
	local success
	if bCopy then
		success = ParaIO.CopyFile(sourceFilename, finalRestoreFilename, true)
	else
		success = ParaIO.MoveFile(sourceFilename, finalRestoreFilename)
	end
	
	if success then
		local operation = bCopy and "Copied" or "Moved"
		LOG.std(nil, "info", "EditableWorld", "%s file to restore folder: %s -> %s", operation, sourceFilename, finalRestoreFilename)
		
		-- Clean up old files in restore folder to maintain file limit
		self:CleanupRestoreFolder(restorePath)
		
		return true
	else
		local operation = bCopy and "copy" or "move"
		LOG.std(nil, "warn", "EditableWorld", "Failed to %s file to restore folder: %s -> %s", operation, sourceFilename, finalRestoreFilename)
		return false
	end
end

-- Clean up restore folder to keep only the most recent files (limit defined by maxRestoreFiles)
-- @param restorePath: path to the restore folder to clean up
function EditableWorld:CleanupRestoreFolder(restorePath)
	if not restorePath then
		return
	end
	
	-- Find all files in restore folder
	local files = {}
	local result = commonlib.Files.Find({}, restorePath, 0, 10000, function(item)
		return true
	end)
	
	-- Build list with file info
	for _, file in ipairs(result) do
		if file.filename and file.filename ~= "" then
			files[#files + 1] = {
				filename = restorePath .. file.filename,
				writedate = file.writedate or 0
			}
		end
	end
	
	-- Sort by writedate (newest first)
	table.sort(files, function(a, b)
		return a.writedate > b.writedate
	end)
	
	-- Remove files beyond the limit
	local removedCount = 0
	for i = self.maxRestoreFiles + 1, #files do
		if ParaIO.DeleteFile(files[i].filename) then
			LOG.std(nil, "debug", "EditableWorld", "Removed old restore file: %s", files[i].filename)
			removedCount = removedCount + 1
		else
			LOG.std(nil, "warn", "EditableWorld", "Failed to remove old restore file: %s", files[i].filename)
		end
	end
	
	if removedCount > 0 then
		LOG.std(nil, "info", "EditableWorld", "Cleaned up %d old files from restore folder (keeping most recent %d)", removedCount, self.maxRestoreFiles)
	end
end


function EditableWorld:GetRestoreWorldSlots(worldName)
	local filename = self:GetSlotFilename(0, worldName)
	-- Extract directory from filename and build restore path
	local sourceDir = filename:match("^(.+)[/\\][^/\\]+$") or ""
	local restorePath = sourceDir .. "/" .. self.restoreFolder .. "/"
	local slots = {}
	
	-- Find all restore files for the given world
	local result = commonlib.Files.Find({}, restorePath, 0, 10000, function(item)
		return true
	end)
	
	-- Build list of slot indices from filenames
	for _, file in ipairs(result) do
		local name = file.filename:gsub("%.blocks%.xml","")
		slots[#slots + 1] = {name=name, filename = restorePath .. file.filename, 
			writedate = file.writedate, filesize = file.filesize, 
			writedateNumber = file.writedate and commonlib.timehelp.GetNumberFromDateString(file.writedate)
		}
	end
	-- Sort by writedate (newest first)
	table.sort(slots, function(a, b)
		return a.writedateNumber > b.writedateNumber
	end)
	return slots
end

-- Auto-save current world before loading a new file if there are unsaved edits
function EditableWorld:AutoSaveBeforeLoad()
	-- Only auto-save if there are unsaved edits
	if self.editCount == 0 or not self.autoSaveEnabled then
		return
	end
	
	-- Get current autosave filename
	local currentAutoSaveFilename = self.autoSaveFilename
	if not currentAutoSaveFilename then
		self:SetAutoSaveFilename()
		currentAutoSaveFilename = self.autoSaveFilename
	end
	
	-- If we still don't have a filename, can't proceed
	if not currentAutoSaveFilename then
		LOG.std(nil, "warn", "EditableWorld", "Cannot auto-save before load: no autosave filename available")
		return
	end
	
	-- Save the current state to auto-save file
	local success, stats = self:SaveToBlockTemplate(currentAutoSaveFilename)
    
	if success then
		local blocksSaved = (stats and stats.blocks) or 0
		LOG.std(nil, "info", "EditableWorld", "Auto-saved %d blocks before loading new file to %s", blocksSaved, currentAutoSaveFilename)
	else
		LOG.std(nil, "warn", "EditableWorld", "Failed to auto-save before loading new file to %s", currentAutoSaveFilename)
	end
end

-- Check if there is an autosave file for a given filename
-- @param filename: the main file to check for autosave
-- @return: boolean indicating if autosave file exists, and the autosave filename
function EditableWorld:HasAutoSaveFile(filename)
	if not filename then
		return false, nil
	end
	
	local autosaveFilename = filename .. ".autosave"
	local exists = ParaIO.DoesFileExist(autosaveFilename, true)
	
	return exists, autosaveFilename
end

-- Load from autosave file if it exists
-- @param filename: the main file for which to load autosave
-- @return: boolean indicating success
function EditableWorld:LoadFromAutoSave(filename)
	local hasAutoSave, autosaveFilename = self:HasAutoSaveFile(filename)
	
	if hasAutoSave then
		UndoManager.Clear();
		return self:LoadFromFile(autosaveFilename)
	end
	
	return false
end

-- Check if autosave file exists for a given slot
-- @param nSlotIndex: slot index
-- @param worldName: optional, default to current world name
-- @return: boolean indicating if autosave file exists, and the autosave filename
function EditableWorld:HasAutoSaveFileForSlot(nSlotIndex, worldName, subtag)
	local mainFilename = self:GetSlotFilename(nSlotIndex, worldName, subtag)
	return self:HasAutoSaveFile(mainFilename)
end

-- Load from autosave file for a given slot if it exists
-- @param nSlotIndex: slot index
-- @param worldName: optional, default to current world name
-- @return: boolean indicating success
function EditableWorld:LoadFromSlotAutoSave(nSlotIndex, worldName, subtag)
	local hasAutoSave, autosaveFilename = self:HasAutoSaveFileForSlot(nSlotIndex, worldName, subtag)

	if hasAutoSave then
		if self:LoadFromFile(autosaveFilename) then
			-- Update the current filename and set new auto-save filename
			self.templateFilename = self:GetSlotFilename(nSlotIndex, worldName, subtag)
			self:MoveToRestoreFolder(self.templateFilename, true);
		
			if(nSlotIndex == 0) then
				-- tricky: remove autosave file for slot 0 by moving it to template filename
				-- we may also do this for all local slots with empty subTag (not subTag or subTag == "")
				ParaIO.MoveFile(autosaveFilename, self.templateFilename)
			end
			self:SetAutoSaveFilename()
			UndoManager.Clear();
			GameLogic.AddBBS(nil, string.format(L"加载自动备份的存档成功 - 槽位 %d", nSlotIndex or 1), 3000, "255 255 0");
			return true
		end
	end
	
	return false
end

-- Get the next available slot index for a given world name and subTag
-- @param worldName: optional, default to project id or current world name.
-- @param subTag: optional, subTag to filter slots
-- @param startIndex: optional, start searching from this index (default: 1)
-- @return: next available slot index, or nil if no available slot found within reasonable range
function EditableWorld:GetNextAvailableSlotIndex(worldName, subTag, startIndex)
	startIndex = startIndex or 1
	local maxSearchRange = 1000 -- Prevent infinite search
	
	-- Get all existing slots for this world and subTag
	local existingSlots = self:GetLocalWorldSlots(worldName, subTag)
	local usedIndices = {}
	
	-- Create a lookup table of used indices
	for _, slot in ipairs(existingSlots) do
		usedIndices[slot.slotIndex] = true
	end
	
	-- Find the first available index starting from startIndex
	for i = startIndex, startIndex + maxSearchRange do
		if not usedIndices[i] then
			return i
		end
	end
	
	return nil -- No available slot found
end

-- Get all available slot indices within a range
-- @param worldName: optional, default to project id or current world name.
-- @param subTag: optional, subTag to filter slots
-- @param maxSlots: optional, maximum number of slots to check (default: 100)
-- @return: array of available slot indices
function EditableWorld:GetAvailableSlotIndices(worldName, subTag, maxSlots)
	maxSlots = maxSlots or 100
	
	-- Get all existing slots for this world and subTag
	local existingSlots = self:GetLocalWorldSlots(worldName, subTag)
	local usedIndices = {}
	local availableIndices = {}
	
	-- Create a lookup table of used indices
	for _, slot in ipairs(existingSlots) do
		usedIndices[slot.index] = true
	end
	
	-- Find all available indices within the range
	for i = 1, maxSlots do
		if not usedIndices[i] then
			availableIndices[#availableIndices + 1] = i
		end
	end
	
	return availableIndices
end

local allowedConflictBlockIds = {
	[76] = true, -- still water
	[113] = true, -- grass
	[116] = true, -- flower
	[115] = true, -- flower2
	[114] = true, -- grass2
	[132] = true, -- grass3
}

-- returns an array of conflict blocks in the format of {x, y, z, blockId, blockData}
function EditableWorld:GetConflictBlocksFromFile(filename)
	local conflicts = {}
	if ParaIO.DoesFileExist(filename, true) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.LoadToMemory, filename = filename, 
				blockX = 0, blockY = 0, blockZ = 0, })
		if(task:Run()) then
			local loadedBlocks = task.blocks or {}
			for _, b in ipairs(loadedBlocks) do
				local bx, by, bz = b[1], b[2], b[3]
				if self:IsEditableBlockForced(bx, by, bz) then
					conflicts[#conflicts + 1] = {bx, by, bz, b[4], b[5]}
				else
					local blockId = BlockEngine:GetBlockId(bx, by, bz);
					if(blockId ~= 0 and not allowedConflictBlockIds[blockId]) then
						-- also consider non-editable blocks that are not air as conflicts
						conflicts[#conflicts + 1] = {bx, by, bz, b[4], b[5]}
					end
				end
			end
			local liveEntities = task.liveEntities or {}
			if(liveEntities and #liveEntities > 0) then
				for _, entityNode in ipairs(liveEntities) do
					local bx = entityNode.attr.bx
					local by = entityNode.attr.by
					local bz = entityNode.attr.bz
					if bx and by and bz then
						if self:IsEditableBlockForced(bx, by, bz) or EntityManager.GetEntityInBlock(bx, by, bz, "LiveModel") then
							conflicts[#conflicts + 1] = {bx, by, bz, 0, 0}
						else
							local blockId = BlockEngine:GetBlockId(bx, by, bz);
							if(blockId ~= 0 and not allowedConflictBlockIds[blockId]) then
								conflicts[#conflicts + 1] = {bx, by, bz, 0, 0}
							end
						end
					end
				end
			end
		end
	end
	return conflicts
end

-- Selection group indices used to control the visual representation of block placement frames.
-- These indices determine which frame appearance to show based on the placement state.
-- @param blocks: table - An array of blocks to check for placement conflicts. Each block
-- @param selectGroupIndex: number (1-6) default to 3
-- Selection group indices used to control the visual representation of block placement frames.
-- These indices determine which frame appearance to show based on the placement state.
-- 1: default selection
-- 2: empty/no selection state
-- 3: block cannot be placed here
-- 4: placeable but doesn't match held block
-- 5: placeable and matches held block
-- 6: auto-selected blocks
function EditableWorld:ShowConflictBlocks(blocks, selectGroupIndex)
	selectGroupIndex = selectGroupIndex or 3;
	
	-- Save the groupIndex to array for later clearing
	self.activeSelectionGroups = self.activeSelectionGroups or {}
	self.activeSelectionGroups[selectGroupIndex] = true
	
	if(blocks and #blocks > 0) then
		for _, b in ipairs(blocks) do
			local x, y, z = b[1], b[2], b[3]
			ParaTerrain.SelectBlock(x, y, z, true, selectGroupIndex);
		end
	end
end

function EditableWorld:ClearSelections()
	-- Clear all active selection groups
	if self.activeSelectionGroups then
		for groupIndex, _ in pairs(self.activeSelectionGroups) do
			ParaTerrain.DeselectAllBlock(groupIndex);
		end
		self.activeSelectionGroups = {}
	end
end

function EditableWorld:GetTemplateFileAtSubTag(subtag)
	if not subtag then
		return nil
	end
	self.subtagToFilename = self.subtagToFilename or {}
	return self.subtagToFilename[subtag]
end

-- @param subtag: there can only be one block template loaded at a time for each filename or at subtag. 
-- @return: entity references loaded from the block template file
function EditableWorld:AddReadonlyBlockTemplate(filename, subtag)
	local lastFreezedWorld = self.isFreezeWorld;
	if lastFreezedWorld then
		self:FreezeWorld(false);
	end
	
	self.readonlyBlockTemplates = self.readonlyBlockTemplates or {}
	self.subtagToFilename = self.subtagToFilename or {}
	
	-- If subtag is provided, check if we already have a template loaded for this subtag
	if subtag then
		local existingFilename = self.subtagToFilename[subtag]
		if existingFilename and existingFilename ~= filename then
			-- Remove the previously loaded template for this subtag
			self:RemoveReadonlyBlockTemplate(existingFilename)
		end
		self.subtagToFilename[subtag] = filename
	end
	
	if(not self.readonlyBlockTemplates[filename]) then
		self.readonlyBlockTemplates[filename] = true;

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = filename, 
			blockX = 0, blockY = 0, blockZ = 0, UseAbsolutePos = true, nohistory = true, 
			TeleportPlayer = true, 
			keepEntityReferences = true,
		})
		if(task:Run()) then	
			-- keep track of all live entities including renamed ones here
			self.readonlyBlockTemplates[filename] = task.entity_references or true;
		end
	end

	if lastFreezedWorld then
		self:FreezeWorld(true);
	end
	return self.readonlyBlockTemplates[filename];
end

function EditableWorld:RemoveReadonlyBlockTemplateBySubTag(subtag)
	if not subtag then
		return
	end
	self.subtagToFilename = self.subtagToFilename or {}
	local filename = self.subtagToFilename[subtag]
	if filename then
		self:RemoveReadonlyBlockTemplate(filename)
	end
end

function EditableWorld:RemoveReadonlyBlockTemplate(filename)
	local lastFreezedWorld = self.isFreezeWorld;
	if lastFreezedWorld then
		self:FreezeWorld(false);
	end
	self.readonlyBlockTemplates = self.readonlyBlockTemplates or {}
	if(self.readonlyBlockTemplates[filename]) then
		local entity_references = self.readonlyBlockTemplates[filename]
		self.readonlyBlockTemplates[filename] = nil;
		
		-- Remove from subtag mapping if exists
		if self.subtagToFilename then
			for subtag, mappedFilename in pairs(self.subtagToFilename) do
				if mappedFilename == filename then
					self.subtagToFilename[subtag] = nil
					break
				end
			end
		end
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.LoadToMemory, filename = filename, 
				blockX = 0, blockY = 0, blockZ = 0, })
		if(task:Run()) then
			local loadedBlocks = task.blocks or {}
			for _, b in ipairs(loadedBlocks) do
				local bx, by, bz = b[1], b[2], b[3]
				if not self:IsEditableBlockForced(bx, by, bz) then
					BlockEngine:SetBlockToAir(bx, by, bz);
				end
			end
			if(type(entity_references) == "table" and #entity_references > 0) then
				for _, entity in ipairs(entity_references) do
					if entity then
						entity:Destroy();
					end
				end
			end
		end
	end

	if lastFreezedWorld then
		self:FreezeWorld(true);
	end
end

function EditableWorld:RemoveAllReadonlyBlockTemplates()
	local lastFreezedWorld = self.isFreezeWorld;
	if lastFreezedWorld then
		self:FreezeWorld(false);
	end
	self.readonlyBlockTemplates = self.readonlyBlockTemplates or {}
	for filename, _ in pairs(self.readonlyBlockTemplates) do
		self:RemoveReadonlyBlockTemplate(filename)
	end
	self.readonlyBlockTemplates = {}
	self.subtagToFilename = {}
	if lastFreezedWorld then
		self:FreezeWorld(true);
	end
end

-- one can call this as often as needed. it will build cache on first use.
function EditableWorld:GetActionNameFromSubtag(subtag)
    if not subtag or subtag == "" then
        return nil;
    end
    -- Build cache on first use
	if not self.subtagToActionnameCache then
		self.subtagToActionnameCache = {};

		-- Search all checkpoint entities in the world
		EntityManager.ForEachEntity(function(entity)
			local actionname = entity:GetTagField("actionname");
			if actionname then
				local entitySubtag = entity:GetTagField("subtag");
				if entitySubtag and entitySubtag ~= "" and actionname then
					self.subtagToActionnameCache[entitySubtag] = actionname;
				end
			end
		end);
    end
    return self.subtagToActionnameCache[subtag];
end

-- Set the maximum number of live entities allowed in the scene
-- @param maxCount: number - maximum number of live entities (nil for unlimited)
function EditableWorld:SetMaxLiveEntities(maxCount)
	self.maxLiveEntities = maxCount
	LOG.std(nil, "info", "EditableWorld", "Set max live entities to: %s", tostring(maxCount or "unlimited"))
end

-- Get the maximum number of live entities allowed
-- @return: number or nil (nil means unlimited)
function EditableWorld:GetMaxLiveEntities()
	return self.maxLiveEntities
end

-- Get the current count of live entities in the editable world
-- @return: number - current count of live entities
function EditableWorld:GetLiveEntityCount()
	if not self.liveEntityNames then
		return 0
	end
	local count = 0
	local toRemove
	for name, _ in pairs(self.liveEntityNames) do
		local entity = EntityManager.GetEntity(name)
		if not entity then
			toRemove = toRemove or {}
			toRemove[#toRemove + 1] = name
		else
			count = count + 1
		end
	end
	if toRemove  then
		for _, name in ipairs(toRemove) do
			self.liveEntityNames[name] = nil
		end
	end
	return count
end

-- @param func: function(entity) - function to be called for each live entity, if the function return true, we will stop iteration.
function EditableWorld:ForEachLiveEntity(func)
	if not self.liveEntityNames then
		return
	end
	local toRemove
	for name, _ in pairs(self.liveEntityNames) do
		local entity = EntityManager.GetEntity(name)
		if not entity then
			toRemove = toRemove or {}
			toRemove[#toRemove + 1] = name
		else
			if(func(entity)) then
				break
			end
		end
	end
	if toRemove  then
		for _, name in ipairs(toRemove) do
			self.liveEntityNames[name] = nil
		end
	end
end

-- Check if the maximum live entity limit has been reached
-- @return: boolean - true if limit reached, false otherwise (always false if no limit set)
function EditableWorld:IsMaxLiveEntityLimitReached()
	if not self.maxLiveEntities then
		return false -- No limit set, so never reached
	end
	return self:GetLiveEntityCount() >= self.maxLiveEntities
end

-- Get the total number of editable blocks in the blocksMap
-- @return: number - total count of editable blocks
function EditableWorld:GetTotalNumberOfEditableBlocks()
	if not self.blocksMap then
		return 0
	end
	local count = 0
	for _ in pairs(self.blocksMap) do
		count = count + 1
	end
	return count
end
