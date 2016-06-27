--[[
Title: World Simulator
Author(s): LiXizhi
Date: 2012/11/30
Desc: Ticking all world blocks, embient sound, natural phenomena, etc. 
This is only responsible for block based simulation, not entities or neurons. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldSim.lua");
local WorldSim = commonlib.gettable("MyCompany.Aries.Game.WorldSim")
local world_sim = WorldSim:new();
world_sim:FrameMove();

GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self.id);
GameLogic.GetSim():isBlockTickScheduledThisTick(x,y,z);
GameLogic.GetSim():AddBlockEvent(x, y, z, block_id, event_id, param);
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/TickEntry.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/BlockDamageProgress.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldTracker.lua");
local BlockDamageProgress = commonlib.gettable("MyCompany.Aries.Game.Common.BlockDamageProgress");
local TickEntry = commonlib.gettable("MyCompany.Aries.Game.TickEntry")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local TimerManager = commonlib.gettable("commonlib.TimerManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

---------------------------
-- create class
---------------------------
local WorldSim = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.WorldTracker"), commonlib.gettable("MyCompany.Aries.Game.WorldSim"))

-- 50 millisecond. 20FPS. 
WorldSim.TickInterval = 50;

-- how many ticks to expire damaged blocks. 30 for 1 seconds. 
WorldSim.damagedBlockExpireTicks = 300;

function WorldSim:ctor()
	self.tick_count = 0;
	self.pendingTickListEntriesHashSet = {};
	self.pendingTickListEntries = commonlib.List:new();
	self.pendingTickListEntriesThisTick = commonlib.List:new();
	self.blockEventCache = commonlib.List:new();
	-- a list of blocks being damaged. 
	self.damagedBlocks = commonlib.List:new();
end


-- detach from previous and attach to the new one.
function WorldSim:AttachWorld(world)
	if(self.world~=world) then
		if(self.world) then
			self.world:RemoveWorldTracker(self);
		end
		self.world = world;
		self.world:AddWorldTracker(self);
	end
end

function WorldSim:CheckAttachWorld()
	if(self.world ~= GameLogic.GetWorld()) then
		self:AttachWorld(GameLogic.GetWorld());
	end
end

function WorldSim:Init()
	self:InitDayLightParams();
	self:CheckAttachWorld();
	return self;
end


-- day light and whether params
function WorldSim:InitDayLightParams()
	local att = ParaScene.GetAttributeObject();
	att:SetField("FogStart", GameLogic.options.fog_start);
	att:SetField("FogEnd", GameLogic.options.fog_end);

	self.last_day_time = nil;

	if(not self.daylight_anim) then
		NPL.load("(gl)script/ide/TimeSeries/TimeSeries.lua");
		local ctl = TimeSeries:new{name = "daylight",};
		self.daylight_anim = ctl;
		-- fog color animation data in 0,1000 time range. 0 is night, 1000 is noon. 
		ctl:Load({
			{	name="fogcolor_r", tableType="AnimBlock", type="Linear", ranges={{1,8}}, 
				times = {0,  200, 350, 400, 450, 600, 650, 1000}, 
				data  = {0.1,0.2, 0.2, 0.3, 0.9, 0.9,	0.7,	1},
			},
			{	name="fogcolor_g", tableType="AnimBlock", type="Linear", ranges={{1,8}}, 
				times = {0,  200, 350, 400, 450, 600, 650, 1000}, 
				data  = {0.1,0.2, 0.2, 0.3, 0.5, 0.7,	0.7,	1},
			},
			{	name="fogcolor_b", tableType="AnimBlock", type="Linear", ranges={{1,8}}, 
				times = {0,  200, 350, 400, 450, 600, 650, 1000}, 
				data  = {0.1,0.6, 0.8, 0.9, 0.2, 0.5,	0.7,	1},
			},

			{	name="skycolor_r", tableType="AnimBlock", type="Linear", ranges={{1,8}}, 
				times = {0,  200, 350, 400, 450, 600, 650, 1000}, 
				data  = {0.1,0.2, 0.2, 0.3, 0.9, 0.9,	1,	1},
			},
			{	name="skycolor_g", tableType="AnimBlock", type="Linear", ranges={{1,8}}, 
				times = {0,  200, 350, 400, 450, 600, 650, 1000}, 
				data  = {0.1,0.2, 0.2, 0.3, 0.5, 0.7,	1,	1},
			},
			{	name="skycolor_b", tableType="AnimBlock", type="Linear", ranges={{1,8}}, 
				times = {0,  200, 350, 400, 450, 600, 650, 1000}, 
				data  = {0.1,0.6, 0.8, 0.9, 0.2, 0.5,	1,	1},
			},
		});
	end
end

function WorldSim:GetTimeOfDayStd()
	return self.last_day_time or 0;
end

-- @param time: set current time of day. 0 or nil means noon, -0.5 is dawn, 0.5 is twilight. 1,-1 is midnight
function WorldSim:SetTimeOfDayStd(time)
	ParaScene.SetTimeOfDaySTD(time or 0);
	self:OnTickDayLight();
end


function WorldSim:GetSunLightAttr()
	if(not self.attrSun or not self.attrSun:IsValid()) then
		self.attrSun = ParaScene.GetAttributeObjectSunLight();
	end
	return self.attrSun;
end

function WorldSim:GetSkyAttr()
	if(not self.attrSky or not self.attrSky:IsValid()) then
		self.attrSky = ParaScene.GetAttributeObjectSky();
	end
	return self.attrSky;
end

function WorldSim:OnTickDayLight(fForceUpdate)
	-- in the range [-1,1], 0 means at noon, -1 is morning. 1 is twilight.
	local time_std = ParaScene.GetTimeOfDaySTD()

	if(self.last_day_time ~= time_std or fForceUpdate) then
		local last_day_time = self.last_day_time;
		self.last_day_time = time_std;	
		
		local att = self:GetSunLightAttr();
		if(att:GetField("DayLength", 10000) > 1000000 and not last_day_time and not fForceUpdate) then
			self.last_day_time = time_std;
			return;
		end

		local bIsSimulatedSky = self:GetSkyAttr():GetField("SimulatedSky", false);

		-- update block intensity. 
		if(ParaTerrain.SetBlockWorldSunIntensity) then
			local skylight_intensity;
			skylight_intensity = math.cos(time_std * 3.14159265) * 2.0 + 0.5;
			if (skylight_intensity < 0.0) then
				skylight_intensity = 0.0;
			end
			if (skylight_intensity > 1.0) then
				skylight_intensity = 1.0;
			end
			ParaTerrain.SetBlockWorldSunIntensity(skylight_intensity);
		end

		
		-- only update in simulated sky
		if(not bIsSimulatedSky) then
			local time = math.floor(1000-math.abs(time_std*1000));
			if(GameLogic.options.auto_skycolor) then
				local r = self.daylight_anim["fogcolor_r"]:getValue(1, time);
				local g = self.daylight_anim["fogcolor_g"]:getValue(1, time);
				local b = self.daylight_anim["fogcolor_b"]:getValue(1, time);

				if(r and g and b) then
					local att = ParaScene.GetAttributeObject();
					att:SetField("FogColor", {r, g, b});

					-- setting the sun color
					local att = self:GetSunLightAttr();
					local sum = (r+g+b+0.001);
					att:SetField("Diffuse", {0.5 + r/sum*3*0.5, 0.5 + g/sum*3*0.5, 0.5 + b/sum*3*0.5});
				end
			end

			if(GameLogic.options.auto_skycolor) then
				local r = self.daylight_anim["skycolor_r"]:getValue(1, time);
				local g = self.daylight_anim["skycolor_g"]:getValue(1, time);
				local b = self.daylight_anim["skycolor_b"]:getValue(1, time);

				if(r and g and b) then
					self:GetSkyAttr():SetField("SkyColor", {r, g, b});
				end
			end
		end
	end
end

function WorldSim:DetachWorld()
	if(self.world) then
		self.world:RemoveWorldTracker(self);
		self.world = nil;
	end
end

function WorldSim:OnExit()
	self:DetachWorld();
end

function WorldSim:Save()
end


function WorldSim:Load()
end

-- 1FPS
function WorldSim:TickAmbientEnv()
	self:OnTickDayLight();
end

-- 10FPS: random tick blocks
function WorldSim:TickRandom()
end

-- Returns true if the given block will receive a scheduled tick in this tick. 
function WorldSim:isBlockTickScheduledThisTick(x,y,z, block_id)
    local list = self.pendingTickListEntriesThisTick;
	local tick_entry = list:first();
	while (tick_entry) do
		if(tick_entry:IsBlock(x,y,z)) then
			return true;
		end
		tick_entry = list:next(tick_entry);
	end
end

-- return true if block tick is scheduled
function WorldSim:isBlockTickScheduled(x,y,z)
	if(self.pendingTickListEntriesHashSet[TickEntry.GetHashCodeFrom(x,y,z)]) then
		return true;
	end
end

-- 15FPS: Runs through the list of pending block updates and ticks them
function WorldSim:TickPendingScheduled()
	local cur_time = TimerManager.GetCurrentTime();

	local list = self.pendingTickListEntries;
	local count = 0;
	local tick_entry = list:first();
		
	while (tick_entry and tick_entry.scheduledTime <= cur_time and count<1000) do
		self.pendingTickListEntriesHashSet[tick_entry:GetHashCode()] = nil;
		local old_entry = tick_entry;
		tick_entry = list:remove(tick_entry);
		self.pendingTickListEntriesThisTick:push_back(old_entry);
		count = count + 1;
	end

	list = self.pendingTickListEntriesThisTick;
	local tick_entry = list:first();
	while (tick_entry) do
		local block_id = ParaTerrain.GetBlockTemplateByIdx(tick_entry.x, tick_entry.y, tick_entry.z);
		if(block_id>0 and block_types.IsAssociatedBlockID(block_id, tick_entry.block_id)) then
			local block = block_types.get(block_id);
			if(block) then
				block:updateTick(tick_entry.x, tick_entry.y, tick_entry.z);
			end
		end

		tick_entry = list:next(tick_entry);
	end
	list:clear();
end

-- this is a public function to schedule a block updateTick some time in the future
-- @param tick_delay: default to one simulation step tick rate. 
-- @param priority: default to 0
function WorldSim:ScheduleBlockUpdate(x,y,z, block_id, tick_delay, priority)
	priority = priority or 0;
	tick_delay = tick_delay or 1;
    local tick_entry = TickEntry:new():Init(x,y,z, block_id, TimerManager.GetCurrentTime()+tick_delay*self.TickInterval, priority);
    
    if (not self.pendingTickListEntriesHashSet[tick_entry:GetHashCode()]) then
        self.pendingTickListEntriesHashSet[tick_entry:GetHashCode()] = tick_entry;

		local list = self.pendingTickListEntries;
		local entry = list:first();
		while (entry) do
			if(entry:compare(tick_entry) <= 0) then
				entry = list:next(entry);
			else
				list:insert_before(tick_entry, entry);
				break;
			end
		end
		if(not entry) then
			list:push_back(tick_entry);
		end
    end
end

-- Adds a block event with the given Args to the blockEventCache. During the next tick(), the block specified will
-- have its OnBlockEvent handler called with the given parameters function(x, y, z, event_id, param);
function WorldSim:AddBlockEvent(x, y, z, block_id, event_id, param)
    local event= {x=x, y=y, z=z, block_id=block_id, event_id=event_id, param=param};
	local list = self.blockEventCache;
	local item = list:first();
	while (item) do
		if(item.x == x and item.y == y  and item.z == z and item.block_id == block_id and item.event_id == event_id and item.param == param) then
			return;
		end
		item = list:next(item);
	end
    list:push_back(event);
end

-- Send and apply locally all pending BlockEvents to each player with 64m radius of the event.
function WorldSim:SendAndApplyBlockEvents()
	local list = self.blockEventCache;
	local item = list:first();
	while (item) do
		if (self:OnBlockEvent(item)) then
			-- TODO: send to nearby players
		end
		item = list:next(item);
	end
	list:clear();
end

-- Called to apply a pending BlockEvent to apply to the current world.
function WorldSim:OnBlockEvent(event)
    local block_id = BlockEngine:GetBlockId(event.x, event.y, event.z);
	if(block_id == event.block_id) then
		local block = block_types.get(block_id);
		if(block) then
			block:OnBlockEvent(event.x, event.y, event.z, event.event_id, event.param);
			return true;
		end
	end
end

-- remove timed out blocks
function WorldSim:TickDamagedBlocks()
	local damagedBlock = self.damagedBlocks:first();
	local needUpdate;
	while (damagedBlock) do
		if((self.tick_count - damagedBlock:GetCreationTime()) > self.damagedBlockExpireTicks) then
			damagedBlock = self.damagedBlocks:remove(damagedBlock);
			needUpdate = true;
		else
			damagedBlock = self.damagedBlocks:next(damagedBlock);
		end
	end
	if(needUpdate) then
		self:UpdateDamagedBlockRenderer();
	end
end

function WorldSim:GetBlockDamagedProgress(x, y, z)
	local damagedBlock = self.damagedBlocks:first();
	while (damagedBlock) do
		if(damagedBlock.x == x and damagedBlock.y==y and damagedBlock.z==z) then
			return damagedBlock:GetProgress();
		end
		damagedBlock = self.damagedBlocks:next(damagedBlock);
	end
	return 0;
end

-- virtual: set new damage to a given block
-- @param damage: [1-10), other values will remove it. 
function WorldSim:DestroyBlockPartially(entityId, x,y,z, damage)
	if (damage >= 0 and damage < 10) then
		local damagedBlock = self.damagedBlocks:first();
		while (damagedBlock) do
			if(damagedBlock.x == x and damagedBlock.y==y and damagedBlock.z==z) then
				break;
			end
			damagedBlock = self.damagedBlocks:next(damagedBlock);
		end
        if (not damagedBlock) then
            damagedBlock = BlockDamageProgress:new():init(x,y,z);
            self.damagedBlocks:add(damagedBlock);
        end
        damagedBlock:SetProgress(damage);
        damagedBlock:SetCreationTime(self.tick_count);
		if(self.damagedBlocks:last()~=damagedBlock) then
			-- the most recent one is moved to the end of the queue
			self.damagedBlocks:remove(damagedBlock);
			self.damagedBlocks:add(damagedBlock);
		end
		self.most_recent_damaged = damagedBlock;
    else
		-- remove block progress from the list
		local damagedBlock = self.damagedBlocks:first();
		while (damagedBlock) do
			if(damagedBlock.x == x and damagedBlock.y==y and damagedBlock.z==z) then
				self.most_recent_damaged = damagedBlock;
				self.damagedBlocks:remove(damagedBlock);
				break;
			end
			damagedBlock = self.damagedBlocks:next(damagedBlock);
		end
    end
	self:UpdateDamagedBlockRenderer();
end

function WorldSim:UpdateDamagedBlockRenderer()
	-- only render the most recently damaged block
	local damagedBlock = self.damagedBlocks:last();
	if (damagedBlock and self.most_recent_damaged == damagedBlock) then
		ParaTerrain.SetDamagedBlock(damagedBlock.x, damagedBlock.y, damagedBlock.z);
		ParaTerrain.SetDamagedDegree(damagedBlock:GetDamagedDegree());
	else
		ParaTerrain.SetDamagedDegree(0);
	end
end

function WorldSim:GetDamagedBlocks()
	return self.damagedBlocks;
end

-- 30FPS
function WorldSim:FrameMove(deltaTime)
	self.tick_count = self.tick_count + 1;

	self:CheckAttachWorld();

	if(self.tick_count%3 == 0) then
		self:TickRandom();
	end
	if(self.tick_count%2 == 1) then
		self:SendAndApplyBlockEvents();
		self:TickPendingScheduled();
	end
	if(self.tick_count%30 == 29) then
		self:TickAmbientEnv();
	end
	if(self.tick_count%20 == 19) then
		self:TickDamagedBlocks();
	end
end

