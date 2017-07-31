--[[
Title: Memory Clip
Author(s): LiXizhi
Date: 2017/6/2
Desc: It represents a long term memory with multiple actors over a short time period, usually less than 2 seconds. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryClip.lua");
local MemoryClip = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryClip");
local clip = MemoryClip:new():Init(context)
clip:SetMovieBlockEntity(movieClipEntity);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActor.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")

local MemoryClip = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryClip"));
MemoryClip:Property("Name", "MemoryClip");
MemoryClip:Property({"time", 0, "GetTime", "SetTime", auto=true});

function MemoryClip:ctor()
end

-- @param context: memory context that this memory clip belongs to
function MemoryClip:Init(context)
	self.context = context;
	return self;
end

function MemoryClip:GetContext()
	return self.context;
end

-- set the movie block entity as the time series data source. 
-- please note movieClipEntity is readonly and may be shared by mutiple memory context.
-- @param movieClipEntity: EntityMovieClip
function MemoryClip:SetMovieBlockEntity(movieClipEntity)
	self.movieEntity = movieClipEntity;
end

function MemoryClip:CalculateDeviation(context)
	context = context or self:GetContext();
end

-- get initial value of a given variable in timeSeries
local function GetValueAtTime0(timeSeries, name)
	local ts = timeSeries[name];
	if(ts and ts.data) then
		return ts.data[1];
	end
end

-- get the time series itemStack that matches the given player entity
-- We will return a match if the size, skin and asset in time 0 all matched. 
function MemoryClip:FindActorByStartFrame(playerContext)
	if(not playerContext) then
		return 
	end
	local inventory = self:GetActorInventory()
	local actorStack;
	local score = 0;
	for i=1, inventory:GetSlotCount() do
		local itemStack = inventory:GetItem(i);
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
			if(itemStack.id == block_types.names.TimeSeriesNPC) then
				local timeSeries = itemStack.serverdata.timeseries;
				local v = GetValueAtTime0(timeSeries, "assetfile");
				if(v and PlayerAssetFile:GetFilenameByName(v) == playerContext.assetfile) then
					-- asset file must always match
					local candidate_score = 1;
					v = GetValueAtTime0(timeSeries, "skin");
					if(v and v == playerContext.skin) then
						candidate_score = candidate_score + 1;
					end
					v = GetValueAtTime0(timeSeries, "scaling");
					if(v and v == playerContext.scaling) then
						candidate_score = candidate_score + 1;
					end
					if(candidate_score > score) then
						score = candidate_score;
						actorStack = itemStack;
					end
				end
			end
		end
	end
	return actorStack;
end

function MemoryClip:GetActorInventory()
	if(self.movieEntity) then
		return self.movieEntity.inventory;
	end
end

function MemoryClip:TransformStartTime()
	local actorStack = self:FindActorByStartFrame();
end

function MemoryClip:Activate(context)
	context = context or self:GetContext();
	context:AddToWorkingMemory(self);
	local playerContext = context:GetPlayerContext();
	local inventory = self:GetActorInventory()
	if(not context or not inventory or not playerContext) then
		return;
	end

	-- check if there is player entity
	local playerStack = self:FindActorByStartFrame(playerContext);
	local playerActor;
	if(playerStack) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActorNPC.lua");
		local MemoryActorNPC = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorNPC");
		playerActor = MemoryActorNPC:new():Init(playerStack, playerContext:GetEntity());
		if(playerActor) then
			playerActor:Activate();
		end
	end

	-- check other entities
	if(playerActor) then
		for i=1, inventory:GetSlotCount() do
			local itemStack = inventory:GetItem(i);
			if(itemStack and itemStack~=playerStack and itemStack.count > 0 and itemStack.serverdata) then
				if(itemStack.id == block_types.names.TimeSeriesNPC) then
					local timeSeries = itemStack.serverdata.timeseries;
				
					local v = GetValueAtTime0(timeSeries, "assetfile");
					if(v and v:match("bmax$")) then
						-- this is an block max model, it could be a Block Model.	
						local x, y, z = GetValueAtTime0(timeSeries, "x"), GetValueAtTime0(timeSeries, "y"), GetValueAtTime0(timeSeries, "z");
						x, y, z = playerActor:TransformToEntityPosition(x, y, z)
						local bx, by, bz = BlockEngine:block(x, y+0.1, z);
						local entity = EntityManager.GetBlockEntity(bx, by, bz);
						if(entity and entity.class_name == "EntityBlockModel") then
							-- asset file also match
							if(entity:GetModelFile() == v) then
								NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryActorBlockModel.lua");
								local MemoryActorBlockModel = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryActorBlockModel");
								local actor = MemoryActorBlockModel:new():Init(itemStack, entity);
								if(actor) then
									actor:SetOffsetFacing(playerActor:GetOffsetFacing())
									actor:Activate();
								end
							end
						end
					end
				elseif(itemStack.id == block_types.names.TimeSeriesCamera) then

				elseif(itemStack.id == block_types.names.TimeSeriesCommands) then
				
				end
			end
		end
	end
end

function MemoryClip:AddToWorkingMemory()
	self:GetContext():AddToWorkingMemory(self);
end

-- called every framemove. 
-- @param deltaTime: in millisecond ticks
function MemoryClip:FrameMove(deltaTime)
end
