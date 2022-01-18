--[[
Title: MovieClip Entity
Author(s): LiXizhi
Date: 2014/3/28
Desc: movie clip entity. the block should use command
/t 30 /end to control how long the movie clip is. when ending, the block will fire an output of value 15, 
which is detectable via repeater or another movie clip block. 
Put two movie block next to the other will cause the next block to play without delay.  
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
local EntityMovieClip = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClip.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipEditors.lua");
local MovieClipEditors = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipEditors");
local MovieClip = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip"));
Entity:Signal("remotelyUpdated")

-- class name
Entity.class_name = "EntityMovieClip";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- if true, we will not reset time to 0 when there is no time event. 
Entity.disable_auto_stop_time = true;
-- in seconds
-- Entity.framemove_interval = 0.01;

function Entity:ctor()
	self.movieClip = MovieClip:new():Init(self);
	self.inventory:SetOnChangedCallback(function(inventory, slot_index)
		self:OnInventoryChanged(slot_index);
	end);
	-- make it bigger than 27(default), so we can have more actors in it. 
	self.inventory:SetSlotCount(48); 
end

function Entity:OnInventoryChanged(slot_index)
	local movieClip = self:GetMovieClip()
	if(movieClip and movieClip == MovieManager:GetActiveMovieClip()) then
		movieClip:RemoveAllActors();
		movieClip:RefreshActors();
	end
end

function Entity:Detach()
	local movieClip = self:GetMovieClip()
	if(movieClip) then
		movieClip:RemoveAllActors();
		MovieManager:RemoveMovieClip(movieClip)
	end
	return Entity._super.Detach(self);
end

-- virtual function: 
function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	
	if(self.inventory:IsEmpty()) then
		-- create at least one camera if it is empty. 
		self:CreateCamera();
	end

	if(not self.cmd or self.cmd == "") then
		-- default movie length is 30 seconds. 
		self:SetCommand("/t 30 /end");
	end

	-- start as paused
	self:Pause();

	return self;
end

function Entity:GetCameraItemStack()
	return self.inventory:FindItem(block_types.names.TimeSeriesCamera);
end


-- return table map {filename=true} of referenced external files, usually bmax files in the world directory. such as {"abc.bmax", "a.fbx", }
-- if no external files are referenced, we will return nil.
function Entity:GetReferenceFiles()
	local files;
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
			if(itemStack.id == block_types.names.TimeSeriesNPC) then
				local timeSeries = itemStack.serverdata.timeseries;
				if(timeSeries and timeSeries.assetfile and timeSeries.assetfile.data) then
					local data = timeSeries.assetfile.data;
					for i = 1, #(data) do
						files = files or {}
						files[data[i]] = true;
					end
				end
			end
		end
	end
	return files;
end

-- return the number of entities replaced
function Entity:ReplaceFile(from, to)
	local count = 0;
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
			if(itemStack.id == block_types.names.TimeSeriesNPC) then
				local timeSeries = itemStack.serverdata.timeseries;
				if(timeSeries and timeSeries.assetfile and timeSeries.assetfile.data) then
					local data = timeSeries.assetfile.data;
					for i = 1, #(data) do
						if(data[i] == from) then
							data[i] = to;
							count = count + 1;
						end
					end
				end
			end
		end
	end
	return count;
end

--@return filename, filenames
local function AddToSearchResult(index, result, filename, filenames)
	result = format("%d:%s", index, result);	
	if(not filename) then
		filename = result
	else
		if(not filenames) then
			filenames = {filename}
		end
		filenames[#filenames+1] = result
	end
	return filename, filenames;
end
-- @param text: string to match
-- @param bExactMatch: if for exact match
-- return true, filename, filenames: if the file text is found. filename contains the full filename, filenames contains multiple results
function Entity:FindFile(text, bExactMatch)
	local filename, filenames;
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
			local name = itemStack:GetDataField("tooltip")
			-- skip default actor names
			if(name and name ~= "" and name ~= "actor") then
				if((bExactMatch and (name == text)) or (not bExactMatch and name:find(text))) then
					filename, filenames = AddToSearchResult(i, name, filename, filenames)
				end
			end
			if(itemStack.id == block_types.names.TimeSeriesNPC) then
				local timeSeries = itemStack.serverdata.timeseries;
				if(timeSeries and timeSeries.assetfile and timeSeries.assetfile.data) then
					local data = timeSeries.assetfile.data;
					for i = 1, #(data) do
						-- skip default actor
						if(data[i] ~= "actor") then
							if((bExactMatch and (data[i] == text)) or (not bExactMatch and data[i]:find(text))) then
								filename, filenames = AddToSearchResult(i, data[i], filename, filenames)
							end
						end
					end
				end
			end
		end
	end
	if(filename) then
		return true, filename, filenames
	end
end

local function offset_time_variable(var, offset)
	if(var and var.data) then
		local data = var.data;
		for i = 1, #(data) do
			data[i] = data[i] + offset;
		end
	end
end

-- @param offset_bx, offset_by, offset_bz: in block coordinate
function Entity:OffsetActorPositions(offset_bx, offset_by, offset_bz)
	local blockSize = BlockEngine.blocksize;
	local offset_x, offset_y, offset_z = offset_bx*blockSize, offset_by*blockSize, offset_bz*blockSize

	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
			if(itemStack.id == block_types.names.TimeSeriesNPC or itemStack.id == block_types.names.TimeSeriesOverlay) then
				local timeSeries = itemStack.serverdata.timeseries;
				if(timeSeries) then
					offset_time_variable(timeSeries.x, offset_x);
					offset_time_variable(timeSeries.y, offset_y);
					offset_time_variable(timeSeries.z, offset_z);
					if(timeSeries.block and timeSeries.block.data) then
						local data = timeSeries.block.data;
						for i = 1, #(data) do
							local blocks = data[i];
							local new_blocks = {};
							for sparse_index, b in pairs(blocks) do
								if(b[1]) then
									b[1] = b[1] + offset_bx;
									b[2] = b[2] + offset_by;
									b[3] = b[3] + offset_bz;
									new_blocks[BlockEngine:GetSparseIndex(b[1], b[2], b[3])] = b;
								end
							end
							data[i] = new_blocks;
						end
					end
				end
			elseif(itemStack.id == block_types.names.TimeSeriesCamera) then
				local timeSeries = itemStack.serverdata.timeseries;
				if(timeSeries) then
					offset_time_variable(timeSeries.lookat_x, offset_x);
					offset_time_variable(timeSeries.lookat_y, offset_y);
					offset_time_variable(timeSeries.lookat_z, offset_z);
				end
			elseif(itemStack.id == block_types.names.TimeSeriesCommands) then
				local timeSeries = itemStack.serverdata.timeseries;
				if(timeSeries and timeSeries.blocks and timeSeries.blocks.data) then
					local data = timeSeries.blocks.data;
					for i = 1, #(data) do
						local blocks = data[i];
						local new_blocks = {};
						for sparse_index, b in pairs(blocks) do
							if(b[1]) then
								b[1] = b[1] + offset_bx;
								b[2] = b[2] + offset_by;
								b[3] = b[3] + offset_bz;
								new_blocks[BlockEngine:GetSparseIndex(b[1], b[2], b[3])] = b;
							end
						end
						data[i] = new_blocks;
					end
				end
			end
		end
	end
end

function Entity:GetCommandItemStack()
	return self.inventory:FindItem(block_types.names.TimeSeriesCommands);
end

-- commands item stack is a singleton that is used for recording text, music, time of day etc. 
-- create one if it does not exist. 
function Entity:CreateGetCommandItemStack()
	return self:GetCommandItemStack() or self:CreateCommand();
end

function Entity:CreateCommand()
	local item = ItemStack:new():Init(block_types.names.TimeSeriesCommands, 1);
	local bAdded, slot_index = self.inventory:AddItem(item);
	if(slot_index) then
		return self.inventory:GetItem(slot_index);
	end
end

function Entity:CreateNPC()
	local item = ItemStack:new():Init(block_types.names.TimeSeriesNPC, 1);
	if(self.inventory:IsFull()) then
		self.inventory:SetSlotCount(self.inventory:GetSlotCount()+5);
		self:GetInventoryView():UpdateFromInventory();
	end
	local bAdded, slot_index = self.inventory:AddItem(item, nil, nil, true);
	if(slot_index) then
		return self.inventory:GetItem(slot_index);
	end
end

function Entity:CreateCamera()
	local item = ItemStack:new():Init(block_types.names.TimeSeriesCamera, 1);
	local bAdded, slot_index = self.inventory:AddItem(item, nil, nil, true);
	if(slot_index) then
		return self.inventory:GetItem(slot_index);
	end
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	return L"命令 /t [秒] /end 设置结束时间"
end

function Entity:HasCommand()
	return true;
end

function Entity:GetMovieClip()
	return self.movieClip;
end

-- only search in 4 horizontal directions
function Entity:GetNearByCodeEntity(cx, cy, cz)
	cx, cy, cz = cx or self.bx, cy or self.by, cz or self.bz;
	for side = 0, 3 do
		local dx, dy, dz = Direction.GetOffsetBySide(side);
		local x,y,z = cx+dx, cy+dy, cz+dz;
		local blockTemplate = BlockEngine:GetBlock(x,y,z);
		if(blockTemplate and blockTemplate.id == block_types.names.CodeBlock) then
			local codeEntity = BlockEngine:GetBlockEntity(x,y,z);
			if(codeEntity) then
				return codeEntity;
			end
		end
	end
end

function Entity:GetFirstActorStack()
	local firstActor;
	for i = 1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i)
		if (itemStack and itemStack.count > 0) then
			if (itemStack.id == block_types.names.TimeSeriesNPC or itemStack.id == block_types.names.TimeSeriesOverlay) then
				firstActor = itemStack;
				break
			end
		end
	end
	return firstActor;
end

function Entity:GetSelectedActorIndex()
	return self.selectedActorIndex;
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			self:OpenEditor("entity", entity);	
		end
	else
		return Entity._super.OnClick(self, x, y, z, mouse_button, entity, side);
	end
	return true;
end

-- @param editor_name: nil for default, it can be "SimpleRolePlayingEditor"
function Entity:SetDefaultEditor(editor_name)
	self.defaultEditor = editor_name;
end

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		movieClip:Stop();
	end
	self.is_playing_mode = false;
	if(self.defaultEditor == "SimpleRolePlayingEditor") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieController.lua");
		local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
		MovieClipEditors.SetDefaultMovieClipPlayer(RolePlayMovieController)
	else
		-- Open with default movie clip timeline editor
		MovieClipEditors.SetDefaultMovieClipPlayer()
	end
	MovieManager:SetActiveMovieClip(movieClip);
	return true;
end

function Entity:OpenBagEditor(editor_name, entity)
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		movieClip:Pause();
	end
	self.is_playing_mode = false;
	return Entity._super.OpenEditor(self, editor_name or "entity", entity);
end

-- @param delta_time: nil to advance to next. 
function Entity:AdvanceTime(delta_time)
	if(delta_time) then
		local cur_time = self:GetTime() + delta_time;
		self:SetTime(cur_time);
		Entity._super.AdvanceTime(self, 0);
	else
		Entity._super.AdvanceTime(self);
	end
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	-- do not load the last output like command block. movieclip does not cache the output. since its output signal only last 0.5 seconds 
	if node then
		local attr = node.attr;
		if attr then
			if(attr.extend_data) then
				self.extend_data = NPL.LoadTableFromString(attr.extend_data);
			end
			if attr.defaultEditor ~= nil then
				self.defaultEditor = attr.defaultEditor
			end
		end
	end

	self.last_output = nil;
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	if node then
		local attr = node.attr
		if self.defaultEditor ~= nil and attr then
			attr.defaultEditor = self.defaultEditor
		end
		if(self.extend_data and attr) then
			attr.extend_data = commonlib.serialize_compact(self.extend_data, bSort);
		end
	end

	return node;
end

function Entity:SetExtendData(key, value)
	if self.extend_data == nil then
		self.extend_data = {}
	end

	if self.extend_data[key] == nil then
		self.extend_data[key] = value
	end
end

-- enable or disable camera. 
function Entity:EnableCamera(bUseCamera)
	local item, slot_index = self.inventory:FindItem(block_types.names.TimeSeriesCamera);
	if(slot_index and not bUseCamera) then
		self.inventory:RemoveItem(slot_index);
	elseif(not slot_index and bUseCamera) then
		self:CreateCamera();
	end
end

-- set the last result. 
function Entity:SetLastCommandResult(last_result)
	local output = self:ComputeElectricOutput(last_result)
	if(self.last_output ~= output) then
		self.last_output = output;
		local x, y, z = self:GetBlockPos();

		if(type(output) == "number" and output>0) then
			if(output > 1) then
				-- does not deactivate immediately, instead deactivate after 2 second, just in case another movie clip is started. 
				-- setting it back after 2 seconds. 40 ticks
				if(self:HasCamera()) then
					GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self:GetBlockId(), 40);
				else
					GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self:GetBlockId(), 0);
				end
			elseif(output == 1) then
				-- end immediately
				GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self:GetBlockId(), 0);
			end
		end

		BlockEngine:NotifyNeighborBlocksChange(x, y, z, BlockEngine:GetBlockId(x, y, z));
	end
end

-- @param block_id: test for this block_id
-- @param play_dir: test for this play_dir
function Entity:IsActivatedMovieBlocks(x,y,z, block_id, play_dir)
	local src_block = BlockEngine:GetBlock(x,y,z);
	if(src_block and src_block.id == block_id) then
		local src_state = src_block:GetInternalStateNumber(x,y,z);
		if(src_state and src_state>0) then
			local entity = src_block:GetBlockEntity(x,y,z);
			if(entity and entity.play_dir ~= play_dir) then
				return true;
			end
		end
	end
end

-- check for 4 nearby directions (except for up and down)
-- and see if there is an activated  movie clip block
-- @return 0,1,2,3 or nil. 0-3 means four directions. 
function Entity:GetNearbyActivatedMovieBlocks(x,y,z, from_block_id)
	local block_id = self:GetBlockId();
	if(self:IsActivatedMovieBlocks(x-1,y,z, block_id, 1)) then
		return 0;
	end
	if(self:IsActivatedMovieBlocks(x+1,y,z, block_id, 0)) then
		return 1;
	end
	if(self:IsActivatedMovieBlocks(x,y,z-1, block_id, 3)) then
		return 2;
	end
	if(self:IsActivatedMovieBlocks(x,y,z+1, block_id, 2)) then
		return 3;
	end
end

-- virtual
function Entity:OnNeighborChanged(x,y,z, from_block_id)
	if(from_block_id == self:GetBlockId()) then
		-- check for 4 nearby directions (except for up and down)
		local activated_dir = self:GetNearbyActivatedMovieBlocks(x,y,z, from_block_id)
		if(activated_dir) then
			if(not self.isPowered) then
				self.play_dir = activated_dir;
				self.isPowered = true;
				-- we do not wait, instead we activate this block immediately. so that there is no delays between movie block.
				self:ExecuteCommand();
				return;
			end
		end
	end
	return Entity._super.OnNeighborChanged(self, x,y,z, from_block_id);
end


-- get movie length in seconds
function Entity:GetMovieClipLength()
	if(not self.length) then
		self:UpdateMovieClipLength();
	end
	return self.length or 30;
end

-- this will generate a command: /t seconds /end 
function Entity:SetMovieClipLength(seconds)
	self:UpdateMovieClipLength(seconds);
end

-- this will generate a command: /t seconds
-- only if seconds is not 0
function Entity:SetMovieStartTime(seconds)
	self:UpdateMovieStartTime(seconds)
end

function Entity:GetMovieStartTime()
	if(not self.start_seconds) then
		self:UpdateMovieStartTime();
	end
	return self.start_seconds or 0;
end

function Entity:UpdateMovieStartTime(new_time)
	local start_seconds;
	local cmds = self:GetCommandTable();
	if(cmds) then
		local end_cmd_index;
		for i, cmd in ipairs(cmds) do
			local time = cmd:match("^/t%s*([%d%.]+)$");
			if(time) then
				time = tonumber(time);
				if(time) then
					if(time >= (start_seconds or 0)) then
						start_seconds = time;
						end_cmd_index = i;
					end
				end
			end
		end
		if(new_time and new_time~=start_seconds) then
			if(end_cmd_index) then
				if(new_time~=0) then
					local cmd = cmds[end_cmd_index];
					cmds[end_cmd_index] = cmd:gsub("^(/t%s*)([%d%.]+)", "%1"..tostring(new_time));
					self:SetCommandTable(cmds);
				else
					commonlib.removeArrayItem(cmds, end_cmd_index);
					self:SetCommandTable(cmds);
				end
			elseif(new_time~=0) then
				cmds[#cmds+1] = string.format("/t %f", new_time);
				self:SetCommandTable(cmds);
			end
			
			start_seconds = new_time;
		end
	else
		if(new_time) then
			self:SetCommandTable({string.format("/t %f", new_time)});
			start_seconds = new_time;
		end
	end
	
	self.start_seconds = start_seconds or 0;
end

function Entity:UpdateMovieClipLength(new_length)
	local length;
	local cmds = self:GetCommandTable();
	if(cmds) then
		local end_cmd_index;
		for i, cmd in ipairs(cmds) do
			local time = cmd:match("^/t%s*~?([%d%.]+)%s+/end");
			if(time) then
				time = tonumber(time);
				if(time) then
					if(time >= (length or 0)) then
						length = time;
						end_cmd_index = i;
					end
				end
			end
		end
		if(new_length and new_length~=length) then
			if(end_cmd_index) then
				local cmd = cmds[end_cmd_index];
				cmds[end_cmd_index] = cmd:gsub("^(/t%s*~?)([%d%.]+)", "%1"..tostring(new_length));
			else
				cmds[#cmds+1] = string.format("/t %f /end", new_length);
			end
			self:SetCommandTable(cmds);
			length = new_length;
		end
	else
		if(new_length) then
			self:SetCommandTable({string.format("/t %f /end", new_length)});
			length = new_length;
		end
	end
	
	self.length = length or 0;
end


function Entity:SetCommand(cmd)
	Entity._super.SetCommand(self, cmd)
	self:UpdateMovieClipLength();
end

-- whether has camera
function Entity:HasCamera()
	return self:GetCameraItemStack() ~= nil;
end

-- this is necessary to force update actors when entity time is changed?
--function Entity:SetTime(time)
	--Entity._super.SetTime(self, time);
	--local movieClip = self:GetMovieClip();
	--if(movieClip) then
		--movieClip:SetTime(math.floor(time*1000));
	--end
--end

-- @param bIgnoreNeuronActivation: true to ignore neuron activation. 
-- @param bIgnoreOutput: ignore output
function Entity:ExecuteCommand(entityPlayer, bIgnoreNeuronActivation, bIgnoreOutput)
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		self:EnablePlayingMode(true);

		if(self:HasCamera()) then
			MovieManager:SetActiveMovieClip(movieClip);
			movieClip:RePlay();
		else
			movieClip:RefreshActors(true);
			movieClip:RePlay();
			MovieManager:AddMovieClip(movieClip);
		end
	end

	-- internal commmands are executed afterwards
	return Entity._super.ExecuteCommand(self, entityPlayer, bIgnoreNeuronActivation, bIgnoreOutput);
end

-- it is only in playing mode when activated by a circuit. 
-- any other way of triggering the movieclip is not playing mode(that is edit mode)
function Entity:IsPlayingMode()
	return self.is_playing_mode;
end

function Entity:EnablePlayingMode(bIsPlayerMode)
	self.is_playing_mode = bIsPlayerMode;
end

-- when the block's updateTick() is called. this function is also called. 
function Entity:OnBlockTick()
	-- setting it back
	self:SetLastCommandResult(0);
	self.is_playing_mode = false;

	local movieClip = self:GetMovieClip();

	-- deactivate the movie block when finished 
	if(MovieManager:GetActiveMovieClip() == movieClip) then
		MovieManager:SetActiveMovieClip(nil);
	else
		if(not self:HasCamera()) then
			movieClip:Pause();
			movieClip:RemoveAllActors();
			MovieManager:RemoveMovieClip(movieClip);
			-- reset time to beginning
			movieClip:SetTime(0);
		end
	end
end

-- virtual function: get array of item stacks that will be displayed to the user when user try to create a new item. 
-- @return nil or array of item stack.
function Entity:GetNewItemsList()
	local itemStackArray = {};
	local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.TimeSeriesNPC,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.TimeSeriesCamera,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.TimeSeriesOverlay,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.TimeSeriesLight,1);
	return itemStackArray;
end

-- @param name:  most likely actor bone name, such as "actorname::bones::R_Hand"
function Entity:SetLastSelectionName(name)
	self.lastSelectionName = name;
end

function Entity:GetLastSelectionName()
	return self.lastSelectionName;
end

-- called when user click to create a new item in the slot
-- @param slot: type of ItemSlot in Container View, such as self.rulebagView
function Entity:OnClickEmptySlot(slot)
	self:CreateItemOnSlot(slot);
end

-- Overriden to provide the network packet for this entity.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	return Packets.PacketUpdateEntityBlock:new():Init(x,y,z, self:SaveToXMLNode());
end

-- update from packet. 
function Entity:OnUpdateFromPacket(packet_UpdateEntityBlock)
	if(packet_UpdateEntityBlock:isa(Packets.PacketUpdateEntityBlock)) then
		local node = packet_UpdateEntityBlock.data1;
		if(node) then
			self.length = nil
			self:ClearCommand()
			self:LoadFromXMLNode(node)
			local movieClip = self:GetMovieClip()
			if(movieClip and movieClip:HasCreatedActors()) then
				movieClip:RemoveAllActors();
				movieClip:RefreshActors();
			end
			self:remotelyUpdated();
		end
	end
end

function Entity:EndEdit()
	Entity._super.EndEdit(self);
	self:MarkForUpdate();
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(not self:IsPaused()) then
		-- always advance time with 0 deltaTime here, since this entity is animated by MovieManager. 

		--if(not self:AdvanceTime(0)) then
			---- stop ticking when there is no timed event. 
			--self:SetFrameMoveInterval(nil);
		--end
	end
end

-- open entity at the given line
-- @param line: line number.
-- @param pos: cursor column position. if nil, it default to 1
function Entity:OpenAtLine(line, pos)
	self.selectedActorIndex = line
	self:OpenEditor("entity", EntityManager.GetPlayer())
	self.selectedActorIndex = nil
end

local function offset_time_variable(var, offset)
	if(var and var.data) then
		local data = var.data;
		for i = 1, #(data) do
			data[i] = data[i] + offset;
		end
	end
end

-- @param animMap: {fromId, toId} id to id map
-- @param filename: if nil, we will match all filename
-- @return bFound, count: count is the number key replaced
function Entity:RemapAnim(animMap, filename)
	local bFound, count;
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
			if(itemStack.id == block_types.names.TimeSeriesNPC) then
				local timeSeries = itemStack.serverdata.timeseries;
				if(timeSeries and timeSeries.assetfile and timeSeries.assetfile.data) then
					local dataAssetFile = timeSeries.assetfile.data;
					local fromTime, toTime = 0;
					local bAssetMatched;
					for i = 1, #(dataAssetFile) do
						if(not filename or dataAssetFile[i] == filename) then
							bAssetMatched = true
							break;
						end
					end
					if(bAssetMatched) then
						bFound = true;
						local animData = timeSeries.anim.data
						for i = 1, #(animData) do
							local newId = animMap[animData[i]]
							if(newId) then
								animData[i] = newId;
								count = (count or 0) + 1;
							end
						end
					end
				end
			end
		end
	end
	return bFound, count;
end

function Entity:GetAllActorData()
	local slotCount = self.inventory:GetSlotCount()
	local actor_datas = {}
	for i=1,slotCount do
		local itemStack = self.inventory:GetItem(i);
		if itemStack and itemStack.serverdata and itemStack.serverdata.timeseries and itemStack.id == block_types.names.TimeSeriesNPC then
			local timeseries = itemStack.serverdata.timeseries
			local assetfile = timeseries.assetfile
			local skin = timeseries.skin
			local scaling = timeseries.scaling
			local temp = {}
			temp.assetfile = assetfile.data[1] or ""
			if temp.assetfile == "customchar" then
				temp.assetfile = "character/CC/02human/CustomGeoset/actor.x"
			end
			temp.skin = skin.data[1] or ""
			temp.scaling = scaling and scaling.data[1] or 1
			actor_datas[#actor_datas + 1] = temp
		end
	end
	return actor_datas
end

function Entity:CompareSlot(entity)
	if not entity then
		return 0
	end
	local types = {}
	local diff_num = 0
	local result = {}
	--判断是否每个格子放的物品是一样的
	local isSameSlot = true
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			if itemStack.id ~= itemStack2.id then
				diff_num = diff_num + 1
				result[i] = 1
			end
		elseif itemStack and not itemStack2 then
			diff_num = diff_num + 1
			result[i] = 1
		end
	end
	return diff_num, result
end

function Entity:CompareTimeLength(entity)
	--电影方块的时间不一样
	if(self.length ~= entity.length)then
		return 1, {stander_answer=self.length, error_answer=entity.length}
	end
	return 0
end

function Entity:CompareTimes(entity)
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	local keyConfig = {
		[10061] = {"lookat_x","lookat_y","lookat_z","eye_dist","eye_liftup","eye_roll","eye_rot_y","parent"},
		[10062] = {"blockinhand","HeadUpdownAngle","HeadTurningAngle","y","x","z","assetfile","skin","speedscale","facing","roll","block","pitch","anim","scaling","gravity","parent"},
		[10063] = {"music","movieblock","cmd","tip","time","blocks","text"}
	}
	local slotCount = self.inventory:GetSlotCount()
	for slot=1, slotCount do
		local itemStack = self.inventory:GetItem(slot);
		local itemStack2 = entity.inventory:GetItem(slot)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[slot] = 1				
			end
			local config = keyConfig[itemStack.id] or {}
			for k,v in pairs(config) do
				if (timeseries1[v] and not timeseries2[v]) or (not timeseries1[v] and timeseries2[v]) then
					diff_num = diff_num + 1
					if not result[slot] then
						result[slot] = {}
					end
					result[slot][v] = 1
				end
				if (timeseries1[v] and  timeseries2[v])then
					local times1 = timeseries1[v].times
					local times2 = timeseries2[v].times
					if #times1 ~= #times2 then
						diff_num = diff_num + 1
						if not result[slot] then
							result[slot] = {}
						end
						result[slot][v] = 1 --关键帧数量不一样
					else
						local isSame = true
						local num = #times1
						for i=1,num do
							local nDeNum = math.abs(times1[i] - times2[i])
							if (nDeNum >= 200) then --关键帧大小相差200ms以上
								isSame =  false
								break
							end

						end
						if not isSame then
							diff_num = diff_num + 1 
							if not result[slot] then
								result[slot] = {}
							end
							result[slot][v] = 1
						end					
					end
				end			
			end
		end
	end
	return diff_num, result
end



function Entity:CompareText(entity)
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1			
			end
			if itemStack.id == 10063 then
				if (timeseries1.text and not timeseries2.text) or (not timeseries1.text and timeseries2.text) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.text and timeseries2.text) then
					local myCnf = timeseries1.text.data
					local otherCnf = timeseries2.text.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						if myCnf.text ~= otherCnf.text or myCnf.textbg ~= otherCnf.textbg
						or myCnf.bgcolor ~= otherCnf.bgcolor or myCnf.textanim ~= otherCnf.textanim
						or myCnf.fontcolor ~= otherCnf.fontcolor or myCnf.fontsize ~= otherCnf.fontsize
						or myCnf.textpos ~= otherCnf.textpos then
							diff_num = diff_num + 1
							result[i] = 1
						end
					end
				end
			end			
		end
	end
	return diff_num, result
end

function Entity:CompareTime(entity) --一天中的时间段
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				return false				
			end
			if itemStack.id == 10063 then
				if (timeseries1.time and not timeseries2.time) or (not timeseries1.time and timeseries2.time) then
					diff_num = diff_num + 1
					result[i] = 1
				end					
				if (timeseries1.time and timeseries2.time) then
					local myCnf = timeseries1.time.data
					local otherCnf = timeseries2.time.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if myCnf[i] - otherCnf[i] < -0.1 and myCnf[i] - otherCnf[i] > 0.1 then
								diff_num = diff_num + 1
								result[i] = 1
							end
						end
					end
				end				
			end				
		end
	end
	return diff_num, result
end

function Entity:CompareCmd(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1			
			end
			if itemStack.id == 10063 then
				if (timeseries1.cmd and not timeseries2.cmd) or (not timeseries1.cmd and timeseries2.cmd) then
					diff_num = diff_num + 1
					result[i] = 1				
				end	
				if timeseries1.cmd and timeseries2.cmd then
					local myCnf = timeseries1.cmd.data
					local otherCnf = timeseries2.cmd.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if myCnf[i] ~= otherCnf[i] then
								diff_num = diff_num + 1
								result[i] = 1
							end							
						end
					end				
				end				
			end			
		end
	end
	return diff_num, result
end

function Entity:CompareMovieBlock(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1			
			end
			if itemStack.id == 10063 then
				if (timeseries1.movieblock and not timeseries2.movieblock) or (not timeseries1.movieblock and timeseries2.movieblock) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.movieblock and timeseries2.movieblock) then
					local myCnf = timeseries1.movieblock.data
					local otherCnf = timeseries2.movieblock.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if 	myCnf[i][1] ~= otherCnf[i][1] or myCnf[i][2] ~= otherCnf[i][2]	 or myCnf[i][3] ~= otherCnf[i][3]	then	
								diff_num = diff_num + 1
								result[i] = 1
							end
						end
					end
				end					
			end				
		end
	end
	return diff_num, result
end

function Entity:CompareMusic(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1				
			end
			if itemStack.id == 10063 then
				if (timeseries1.music and not timeseries2.music) or (not timeseries1.music and timeseries2.music) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.music and timeseries2.music) then
					local myCnf = timeseries1.music.data
					local otherCnf = timeseries2.music.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if myCnf[i] ~= otherCnf[i] then
								diff_num = diff_num + 1
								result[i] = 1
							end							
						end
					end
				end	
				
			end		
		end
	end
	return diff_num, result
end

function Entity:ComparePosition(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	local tempCmpKey = {"lookat_x","lookat_y","lookat_z"}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				return false				
			end
			if itemStack.id == 10061 then
				for k,v in pairs(tempCmpKey) do
					if (timeseries1[v] and not timeseries2[v]) or (not timeseries1[v] and timeseries2[v]) then
						diff_num = diff_num + 1
						result[i] = 1
					end	
					if (timeseries1[v] and timeseries2[v]) then
						local myCnf = timeseries1[v].data
						local otherCnf = timeseries2[v].data
						if #myCnf ~= #otherCnf then
							diff_num = diff_num + 1
							result[i] = 1
						else
							local num = #myCnf
							local isSame = true
							for i=1,num do
								if (myCnf[i] - otherCnf[i] < -3 ) or (myCnf[i] - otherCnf[i] > 3 )  then
									isSame = false
									break
								end						
							end
							if not isSame then
								return isSame
							end
						end
					end						
				end
			end		
		end
	end
	return diff_num, result
end

function Entity:CompareRotation(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	local tempCmpKey = {"eye_rot_y","eye_liftup"}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1				
			end
			if itemStack.id == 10061 then
				for k,v in pairs(tempCmpKey) do
					if (timeseries1[v] and not timeseries2[v]) or (not timeseries1[v] and timeseries2[v]) then
						diff_num = diff_num + 1
						result[i] = 1
					end	
					if (timeseries1[v] and timeseries2[v]) then
						local myCnf = timeseries1[v].data
						local otherCnf = timeseries2[v].data
						if #myCnf ~= #otherCnf then
							diff_num = diff_num + 1
							result[i] = 1
						else
							local num = #myCnf
							local isSame = true
							for i=1,num do
								if (myCnf[i] - otherCnf[i] < -0.3 ) or (myCnf[i] - otherCnf[i] > 0.3 )  then
									isSame = false
									break
								end						
							end
							if not isSame then
								return isSame
							end
						end
					end
				end
			end		
		end
	end
	return diff_num, result
end

function Entity:CompareParent(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1			
			end
			if itemStack.id == 10061 then
				if (timeseries1.parent and not timeseries2.parent) or (not timeseries1.parent and timeseries2.parent) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.parent and timeseries2.parent) then
					local myCnf = timeseries1.parent.data
					local otherCnf = timeseries2.parent.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						local isSame = true
						for i=1,num do
							if myCnf[i].target ~= otherCnf.target then
								isSame = false
								break
							end
							if isSame and  (math.abs(myCnf[i].rot[1]*180/math.pi - otherCnf[i].rot[1]*180/math.pi) > 35 
								or math.abs(myCnf[i].rot[2]*180/math.pi - otherCnf[i].rot[2]*180/math.pi) > 35  
								or math.abs(myCnf[i].rot[3]*180/math.pi - otherCnf[i].rot[3]*180/math.pi) > 35) then
								isSame = false
								break
							end
							if isSame and  (math.abs(myCnf[i].pos[1] - otherCnf[i].pos[1]) > 3 
								or math.abs(myCnf[i].pos[2] - otherCnf[i].pos[2]) > 3  
								or math.abs(myCnf[i].pos[3] - otherCnf[i].pos[3]) > 3) then
								isSame = false
								break
							end
						end
						if not isSame then
							diff_num = diff_num + 1
							result[i] = 1
						end
					end
				end				
			end		
		end
	end
	return diff_num, result
end

function Entity:GetTimeseries(index)
	return 0
end

function Entity:CompareActorAni(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1				
			end
			if itemStack.id == 10062 then
				if (timeseries1.anim and not timeseries2.anim) or (not timeseries1.anim and timeseries2.anim) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.anim and timeseries2.anim) then
					local myCnf = timeseries1.anim.data
					local otherCnf = timeseries2.anim.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if myCnf[i] ~= otherCnf[i] then
								diff_num = diff_num + 1
								result[i] = 1
							end							
						end						
					end
				end				
			end		
		end
	end
	return diff_num, result
end

function Entity:CompareActorBones(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				return false				
			end
			if itemStack.id == 10062 then
				if (timeseries1.bones and not timeseries2.bones) or (not timeseries1.bones and timeseries2.bones) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.bones and timeseries2.bones) then
					local myCnf = timeseries1.bones
					local otherCnf = timeseries2.bones
					local keys = {}
					for k,v in pairs(myCnf) do
						if not otherCnf[k] then
							diff_num = diff_num + 1
							result[i] = 1						
						end
						keys[#keys] = k
					end
					local num = #keys
					for i=1,num do
						local curKey = keys[i]
						local myBoneDts = myCnf[curKey].data
						local otherBoneDts = otherCnf[curKey].data
						if string.find(curKey,"rot") then
							NPL.load("(gl)script/ide/mathlib.lua");
							local mathlib = commonlib.gettable("mathlib");
							NPL.load("(gl)script/ide/math/Quaternion.lua");
							local Quaternion = commonlib.gettable("mathlib.Quaternion");
							local temp1,temp2,temp3 = mathlib.QuatToEuler(myBoneDts) --Quaternion:new(myBoneDts):ToEulerAngles()
							myBoneDts = {temp1,temp2,temp3 }
							temp1,temp2,temp3 = mathlib.QuatToEuler(otherBoneDts) --Quaternion:new(otherBoneDts):ToEulerAngles()
							otherBoneDts = {temp1,temp2,temp3}
							local dataNum = #myBoneDts
							for dataIndex = 1,dataNum do 
								local rotDis = myBoneDts[dataIndex] - otherBoneDts[dataIndex]
								rotDis = rotDis * 180 /math.pi
								if rotDis > 35 or rotDis < -35 then
									diff_num = diff_num + 1
									result[i] = 1
								end
							end
						end
					end
				end				
			end		
		end
	end
	return diff_num, result
end

function Entity:CompareActorPosition(entity, compare_type) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result_list = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				return false				
			end
			local keys = {"x","y","z"}
			if itemStack.id == 10062 then
				for k,v in pairs(keys) do
					if not timeseries2[v] or not timeseries1[v] then
						return
					end	
					if (timeseries1[v] and timeseries2[v]) then	
						local myCnf = timeseries1[v].data
						local otherCnf = timeseries2[v].data
						local num = #myCnf
						for cnf_i=1,num do
							-- print("rrrrrrrrrrrr", v, myCnf[cnf_i], otherCnf[cnf_i])
							if myCnf[cnf_i] and otherCnf[cnf_i] and math.abs(myCnf[cnf_i] - otherCnf[cnf_i]) > 3 then
								diff_num = diff_num + 1
								if not result_list[i] then
									result_list[i] = {}
								end

								result_list[i].pos = 1
							end							
						end		
					end	
				end							
			end		
		end
	end
	return diff_num, result_list
end

function Entity:CompareActorScale(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}	
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				return false				
			end
			if itemStack.id == 10062 then
				if (timeseries1.scaling and not timeseries2.scaling) or (not timeseries1.scaling and timeseries2.scaling) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.scaling and timeseries2.scaling) then
					local myCnf = timeseries1.scaling.data
					local otherCnf = timeseries2.scaling.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if math.abs(myCnf[i] - otherCnf[i]) > 0.5 then
								diff_num = diff_num + 1
								result[i] = 1
							end							
						end						
					end
				end								
			end		
		end
	end
	return diff_num, result
end

function Entity:CompareActorHead(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1				
			end
			local keys = {"HeadUpdownAngle","HeadTurningAngle"}
			if itemStack.id == 10062 then
				for k,v in pairs(keys) do
					if (timeseries1[v] and not timeseries2[v]) or (not timeseries1[v] and timeseries2[v]) then
						diff_num = diff_num + 1
						result[i] = 1
					end	
					if (timeseries1[v] and timeseries2[v]) then
						local myCnf = timeseries1[v].data
						local otherCnf = timeseries2[v].data
						if #myCnf ~= #otherCnf then
							diff_num = diff_num + 1
							result[i] = 1
						else
							local num = #myCnf
							for i=1,num do
								local rotDis = myCnf[i] - otherCnf[i]
								rotDis = rotDis*180/math.pi
								if math.abs(rotDis) > 35 then
									diff_num = diff_num + 1
									result[i] = 1
								end							
							end						
						end
					end	
				end							
			end		
		end
	end
	return diff_num, result
end


function Entity:CompareActorSpeed(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1			
			end
			if itemStack.id == 10062 then
				if (timeseries1.speedscale and not timeseries2.speedscale) or (not timeseries1.speedscale and timeseries2.speedscale) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.speedscale and timeseries2.speedscale) then
					local myCnf = timeseries1.speedscale.data
					local otherCnf = timeseries2.speedscale.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if myCnf[i] ~= otherCnf[i] then
								diff_num = diff_num + 1
								result[i] = 1
							end							
						end						
					end
				end								
			end		
		end
	end
	return diff_num, result
end

function Entity:CompareActorModel(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1				
			end
			if itemStack.id == 10062 then
				if (timeseries1.assetfile and not timeseries2.assetfile) or (not timeseries1.assetfile and timeseries2.assetfile) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.assetfile and timeseries2.assetfile) then
					local myCnf = timeseries1.assetfile.data
					local otherCnf = timeseries2.assetfile.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if myCnf[i] ~= otherCnf[i] then
								diff_num = diff_num + 1
								result[i] = 1
							end							
						end						
					end
				end								
			end		
		end
	end
	return diff_num, result
end

function Entity:CompareActorRotation(entity) 
	-- if not entity then
	-- 	return 0
	-- end
	-- for i=1, self.inventory:GetSlotCount() do
	-- 	local itemStack = self.inventory:GetItem(i);
	-- 	local itemStack2 = entity.inventory:GetItem(i)
	-- 	if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
	-- 		local timeseries1 = itemStack.serverdata.timeseries
	-- 		local timeseries2 = itemStack2.serverdata.timeseries
	-- 		if not timeseries1 or not timeseries2  then
	-- 			return false				
	-- 		end
	-- 		if itemStack.id == 10062 then
	-- 			if (timeseries1.skin and not timeseries2.skin) or (not timeseries1.skin and timeseries2.skin) then
	-- 				return false
	-- 			end	
	-- 			if (timeseries1.skin and timeseries2.skin) then
	-- 				local myCnf = timeseries1.skin.data
	-- 				local otherCnf = timeseries2.skin.data
	-- 				if #myCnf ~= #otherCnf then
	-- 					return false
	-- 				else
	-- 					local num = #myCnf
	-- 					for i=1,num do
	-- 						if myCnf[i] ~= otherCnf[i] then
	-- 							return false
	-- 						end							
	-- 					end						
	-- 				end
	-- 			end								
	-- 		end		
	-- 	end
	-- end
	return 0
end

function Entity:CompareActorOpcatity(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1			
			end
			if itemStack.id == 10062 then
				if (timeseries1.opacity and not timeseries2.opacity) or (not timeseries1.opacity and timeseries2.opacity) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.opacity and timeseries2.opacity) then
					local myCnf = timeseries1.opacity.data
					local otherCnf = timeseries2.opacity.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if myCnf[i] ~= otherCnf[i] then
								diff_num = diff_num + 1
								result[i] = 1
							end							
						end						
					end
				end								
			end		
		end
	end
	return diff_num, result
end

function Entity:CompareActorParent(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1			
			end
			if itemStack.id == 10062 then
				if (timeseries1.parent and not timeseries2.parent) or (not timeseries1.parent and timeseries2.parent) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.parent and timeseries2.parent) then
					local myCnf = timeseries1.parent.data
					local otherCnf = timeseries2.parent.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						local isSame = true
						for i=1,num do
							if myCnf[i].target ~= otherCnf.target then
								isSame = false
								break
							end
							if isSame and  (math.abs(myCnf[i].rot[1]*180/math.pi - otherCnf[i].rot[1]*180/math.pi) > 35 
								or math.abs(myCnf[i].rot[2]*180/math.pi - otherCnf[i].rot[2]*180/math.pi) > 35  
								or math.abs(myCnf[i].rot[3]*180/math.pi - otherCnf[i].rot[3]*180/math.pi) > 35) then
								isSame = false
								break
							end
							if isSame and  (math.abs(myCnf[i].pos[1] - otherCnf[i].pos[1]) > 3 
								or math.abs(myCnf[i].pos[2] - otherCnf[i].pos[2]) > 3  
								or math.abs(myCnf[i].pos[3] - otherCnf[i].pos[3]) > 3) then
								isSame = false
								break
							end
						end
						if not isSame then
							diff_num = diff_num + 1
							result[i] = 1
						end				
					end
				end								
			end		
		end
	end
	return diff_num, result
end

function Entity:CompareActorName(entity) 
	if not entity then
		return 0
	end
	local diff_num = 0
	local result = {}
	for i=1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		local itemStack2 = entity.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				diff_num = diff_num + 1
				result[i] = 1			
			end
			if itemStack.id == 10062 then
				if (timeseries1.name and not timeseries2.name) or (not timeseries1.name and timeseries2.name) then
					diff_num = diff_num + 1
					result[i] = 1
				end	
				if (timeseries1.name and timeseries2.name) then
					local myCnf = timeseries1.name.data
					local otherCnf = timeseries2.name.data
					if #myCnf ~= #otherCnf then
						diff_num = diff_num + 1
						result[i] = 1
					else
						local num = #myCnf
						for i=1,num do
							if myCnf[i] ~= otherCnf[i] then
								diff_num = diff_num + 1
								result[i] = 1
							end							
						end						
					end
				end								
			end		
		end
	end
	return diff_num, result
end

