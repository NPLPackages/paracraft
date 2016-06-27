--[[
Title: blocks actor
Author(s): LiXizhi
Date: 2014/3/30
Desc: for recording and playing back of blocks creation and editing. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorBlocks.lua");
local actor = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorBlocks");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks")
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorBlocks"));

-- for selection effect. 
local groupindex_select = 3;

-- whether to animate destroy blocks animation. 
-- Actor.is_anim_destroy_blocks = nil;

function Actor:ctor()
	self.block_set = {};
end

function Actor:Init(itemStack, movieclipEntity)
	if(not Actor._super.Init(self, itemStack, movieclipEntity)) then
		return;
	end
	
	local timeseries = self.TimeSeries;
	timeseries:CreateVariableIfNotExist("blocks", "Discrete");

	self:UpdateBlockSet();

	return self;
end

function Actor:IsKeyFrameOnly()
	return true;
end

-- @return true if recording. 
function Actor:SetRecording(isRecording)
	-- disable recording. 
	return false;
end

-- remove all blocks
function Actor:OnRemove()
	-- deselect all selections if any. 
	self:UpdateSelection(false);

	-- remove all block set
	for sparse_index, b in pairs(self.block_set) do
		BlockEngine:SetBlockToAir(b[1], b[2], b[3]);
	end
end


local function getSparseIndex(bx, by, bz)
	return by*30000*30000+bx*30000+bz;
end

-- update block set in block time series variable as well as the given new_blocks 
function Actor:UpdateBlockSet()
	local block_set = {};
	local v = self:GetVariable("blocks");
	for i, blocks in ipairs(v.data) do
		for sparse_index, b in pairs(blocks) do
			block_set[sparse_index] = b;
		end
	end	
	self.block_set = block_set;
end

-- add movie text at the current time. 
function Actor:AddKeyFrameOfSelectedBlocks()
	local blocks = {};
	local curSelectionInstance = SelectBlocks.GetCurrentInstance();
	if(curSelectionInstance) then	
		local curSelection = curSelectionInstance:GetCopyOfBlocks({0,0,0});
		if(curSelection and #curSelection >= 1) then
			for _, b in ipairs(curSelection) do
				-- {x,y,z,block_id, block_data, entity_data}
				blocks[getSparseIndex(b[1], b[2], b[3])] = b;
			end
		end
	end
	self:AddKeyFrameByName("blocks", nil, blocks);
	self:UpdateBlockSet();	
end

-- @param blocks: update blocks. 
function Actor:UpdateBlocks(blocks, curTime, bIsSelected)
	if(blocks) then
		self:UpdateSelection(bIsSelected, true);
		for sparse_index, b in pairs(self.block_set) do
			if(blocks[sparse_index]) then
				b = blocks[sparse_index];
				BlockEngine:SetBlock(b[1], b[2], b[3], b[4], b[5], 3, b[6]);
			else
				BlockEngine:SetBlockToAir(b[1], b[2], b[3], 3);
			end
		end
	end
end

-- update selection effect in the scene for editing mode. 
function Actor:UpdateSelection(bIsSelected, bForceUpdate)
	if(not bIsSelected) then
		bIsSelected = nil;
	end
	if(self.isSelected ~= bIsSelected or bForceUpdate) then
		self.isSelected = bIsSelected;

		ParaTerrain.DeselectAllBlock(groupindex_select);

		if(bIsSelected) then
			for sparse_index, b in pairs(self.block_set) do
				ParaTerrain.SelectBlock(b[1], b[2], b[3], true, groupindex_select);
			end
		end
	end
end

-- virtual function: display a UI to let the user to edit this keyframe's data. 
function Actor:EditKeyFrame(keyname, time)
	time = time or self:GetTime();
	local blocks = self:GetValue("blocks", time);
	-- TODO: select and highlight all blocks in current frame. 
end

function Actor:FrameMovePlaying(deltaTime, bIsSelected)
	local curTime = self:GetTime();
	if(not curTime) then
		return
	end
	local blocks = self:GetValue("blocks", curTime);
	if(self.last_blocks ~= blocks) then
		self.last_blocks = blocks;
		self:UpdateBlocks(blocks, curTime, bIsSelected);
	else
		self:UpdateSelection(bIsSelected);
	end
end
