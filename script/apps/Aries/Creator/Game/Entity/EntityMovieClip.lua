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
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
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

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip"));

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
	self.inventory:SetOnChangedCallback(function()
		self:OnInventoryChanged();
	end);
	-- make it bigger than 27(default), so we can have more actors in it. 
	self.inventory:SetSlotCount(48); 
end

function Entity:OnInventoryChanged()
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
	local bAdded, slot_index = self.inventory:AddItem(item);
	if(slot_index) then
		return self.inventory:GetItem(slot_index);
	end
end

function Entity:CreateCamera()
	local item = ItemStack:new():Init(block_types.names.TimeSeriesCamera, 1);
	local bAdded, slot_index = self.inventory:AddItem(item);
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

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		movieClip:Stop();
	end
	self.is_playing_mode = false;
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
	self.last_output = nil;
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	return node;
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
				GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self:GetBlockId(), 40);
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
	if(self:IsActivatedMovieBlocks(x,y,z-1, block_id, 2)) then
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
			MovieClipController.SetFocusToItemStackCamera();
		else
			movieClip:RefreshActors();
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