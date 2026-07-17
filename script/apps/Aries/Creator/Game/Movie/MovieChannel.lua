--[[
Title: Movie Channel
Author(s): LiXizhi
Date: 2019/1/16
Desc: there can only be one movie block that is playing per channel
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local channel = MovieManager:CreateGetMovieChannel("main"):SetStartBlockPosition(x,y,z)
channel:Play(0)

-- one can play a movie block inside a given miniscenegraph texture.
local channel = MovieManager:CreateGetMovieChannel("main");
channel:CreateFromTemplateFile("paracraftlogo.blocks.xml", 0,0,0);
channel:SetScene("MyMiniSceneGraph")
channel:Play(0)

-- programmatically create a movie block in memory from a block template file, that is used to
-- play at the player's current position and bind to the player entity as an agent actor.
local channel = MovieManager:CreateGetMovieChannel("main");
channel:CreateFromTemplateFile("temp/blocktemplates/anim1.blocks.xml");
channel:SetAutoStopWhenPlayFinish(true)
local player = GameLogic.EntityManager.GetPlayer();
local x, y, z = player:GetPosition();
local bIgnoreSkin = true; -- if true, the skin of the entity will not be applied to the actor.
channel:TransformActorsByFirstActor(x, y, z, player:GetFacing(), nil, player:GetScaling());
channel:BindActorAgentToEntity(1, player, bIgnoreSkin);
-- channel:BindActorAgentToEntity(2, GameLogic.EntityManager.GetEntity("otherPlayer"), bIgnoreSkin);
channel:Play(0, -1)

-- play from a nearby movie block in the scene
local channel = MovieManager:CreateGetMovieChannel("main");
channel:CloneFromEntity(GameLogic.EntityManager.GetBlockEntity(19215,5,19230));
channel:SetAutoStopWhenPlayFinish(true)
local player = GameLogic.EntityManager.GetPlayer();
local x, y, z = player:GetPosition();
channel:TransformActorsByFirstActor(x, y, z, player:GetFacing(), nil, player:GetScaling());
channel:BindActorAgentToEntity(1, player, true);
channel:Play(0, -1)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipRaw.lua");
local MovieClipRaw = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipRaw");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MovieClip = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip");

local MovieChannel = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.MovieChannel"));
MovieChannel:Property("Name", "MovieChannel");
MovieChannel:Property({"ReuseActor", nil, "IsReuseActor", "SetReuseActor", auto=true});
MovieChannel:Property({"Speed", 1.0, "GetSpeed", "SetSpeed"});
MovieChannel:Property({"bUseCamera", true, "IsUseCamera", "SetUseCamera", auto=true});
MovieChannel:Property({"bLoop", false, "IsLooping", "SetLooping"});
MovieChannel:Property({"bStopWhenPlayFinish", false, "IsAutoStopWhenPlayFinish", "SetAutoStopWhenPlayFinish"});

MovieChannel:Signal("started");
MovieChannel:Signal("stopped");
-- finished playing in non-looped play, this should be used as One-time callback after playMovie.
-- since it will automatically remove all receivers once fired. 
MovieChannel:Signal("finished"); 

function MovieChannel:ctor()
	-- array of movie clips
	self.clips = nil
	self.curClipIndex = nil;
end

function MovieChannel:Init(name)
	self.name = name;
	return self;
end

function MovieChannel:Destroy()
	self:ResetSentientChecker()
	self:Reset();
	MovieChannel._super.Destroy(self);
end

function MovieChannel:ResetAll()
	self:ResetSentientChecker()
	self:Reset();
end

function MovieChannel:Reset()
	if(self.clips) then
		for i, clip in ipairs(self.clips) do
			clip:Destroy();
		end
		self.clips = nil;
		self.curClipIndex = nil;
	end
end

-- get the current movie clip
function MovieChannel:GetCurrentMovieClip()
	return self.clips and self.clips[self.curClipIndex];
end

function MovieChannel:SetStartBlockPosition(x, y, z)
	if(self.startX~=x or self.startY ~= y or self.startZ~=z) then
		self:Stop();
		self:Reset();
		self.startX, self.startY, self.startZ = x, y, z;
	end
	return self;
end

function MovieChannel:GetStartBlockPosition()
	return self.startX, self.startY, self.startZ;
end

function MovieChannel:CreateGetStartMovieClip(isUIPlaying)
	if(not self.clips and (self.startX or self.startupMovieEntity)) then
		local blockEntity = self.startupMovieEntity or EntityManager.GetBlockEntity(self.startX, self.startY, self.startZ);
		if(blockEntity and blockEntity.GetMovieClip) then
			self.clips = {}
			local movieClip = MovieClipRaw:new():Init(blockEntity);
			if(GameLogic.options:IsAutoMovieFPS()) then
				if isUIPlaying then
					movieClip:SetAutoFPS(false);
					movieClip:SetFPS(60)
				else
					movieClip:SetAutoFPS(true);
				end
			end
			self.clips[1] = movieClip;
			self.curClipIndex = 1;

			if(not self.startupMovieEntity) then
				blockEntity:Connect("beforeRemoved", function()
					if(self.clips and self.clips[1] == movieClip) then
						self:Reset()
					end
				end)
			end
		end
	end
	return self.clips and self.clips[1];
end

function MovieChannel:UseCamera()
	if(self:GetCurrentMovieClip()) then
		local actor = self:GetCurrentMovieClip():GetCamera();
		if(actor) then
			actor:SetFocus();
		end
	end
end

function MovieChannel:Pause()
	if(self.sentientPaused) then
		self.sentientPaused = nil;
		self.sentientTimer:Change();
	end
	if(self:GetCurrentMovieClip()) then
		self:GetCurrentMovieClip():Pause();
	end
end

function MovieChannel:IsPlaying()
	if(self:GetCurrentMovieClip()) then
		return self:GetCurrentMovieClip():IsPlaying();
	end
end

function MovieChannel:SetLooping(bLooping)
	self.bLooping = bLooping;
end

function MovieChannel:IsLooping()
	return self.bLooping;
end

function MovieChannel:SetAutoStopWhenPlayFinish(bStopWhenPlayFinish)
	self.bStopWhenPlayFinish= bStopWhenPlayFinish;
end

function MovieChannel:IsAutoStopWhenPlayFinish()
	return self.bStopWhenPlayFinish;
end

-- @param timeFrom: time in milliseconds, default to 0.
-- @param timeTo: if nil, default to timeFrom. if -1, it means total movie block length. 
function MovieChannel:Play(fromTime, toTime, bLooping, isUIPlaying)
	local movieClip = self:CreateGetStartMovieClip(isUIPlaying)
	if(movieClip) then
		if(movieClip:GetScene() ~= self:GetScene()) then
			movieClip:SetScene(self:GetScene());
		end

		self:FireFinished();
		movieClip:SetReuseActor(self:IsReuseActor());
		if(not fromTime) then
			movieClip:GotoBeginFrame();
			fromTime = movieClip:GetTime();
		else
			movieClip:SetTimeNoUpdate(fromTime);
		end
		toTime = toTime or fromTime;
		if(toTime == -1) then
			toTime = movieClip:GetLength();
		end
		movieClip:RefreshActors();
		if(self:IsUseCamera()) then
			self:UseCamera();
		end
		
		if(toTime~=fromTime) then
			movieClip:Resume();	
			if(toTime > fromTime) then
				movieClip:SetSpeed(self:GetSpeed())
			else
				movieClip:SetSpeed(-self:GetSpeed())
			end
		else
			movieClip:Pause();
		end
		self:started(); -- signal

		self.playFromTime = fromTime;
		self.playToTime = toTime;
		self:SetLooping(bLooping == true);
		if(fromTime ~= toTime) then
			movieClip:Connect("timeChanged", self, self.OnMovieTimeChange, "UniqueConnection")
		end
	end
end

function MovieChannel:PlayLooped(fromTime, toTime)
	self:Play(fromTime, toTime, true)
end

function MovieChannel:SetSpeed(speed)
	if(self.Speed ~= speed) then
		self.Speed = speed;
		if(self:GetCurrentMovieClip()) then
			self:GetCurrentMovieClip():SetSpeed(speed);
		end
	end
end

function MovieChannel:GetSpeed()
	return self.Speed or 1;
end

-- one can provide sentient checker function to auto pause the movie when the player is too far away, etc. 
-- @param sentientCheckerFunc: function() end return true if we are sentient, otherwise false. 
-- @param checkSentientInterval: default to 300 ms
function MovieChannel:SetSentientChecker(sentientCheckerFunc, checkSentientInterval)
	self.sentientCheckerFunc = sentientCheckerFunc;
	self.checkSentientInterval = checkSentientInterval or 300;
end

function MovieChannel:CheckSentient()
	if(self.sentientCheckerFunc) then
		if(not self.sentientCheckerFunc()) then
			self.sentientPaused = true;
			local movieClip = self:GetCurrentMovieClip();
			movieClip:Pause();
			self.sentientTimer = self.sentientTimer or commonlib.Timer:new({callbackFunc = function(timer)
				if(self:CheckSentient()) then
					self.sentientPaused = nil;
					movieClip:Resume();
					timer:Change()
				end
			end})
			self.sentientTimer:Change(self.checkSentientInterval, self.checkSentientInterval)
			return false;
		elseif(self.sentientPaused) then
			self.sentientPaused = nil;
			local movieClip = self:GetCurrentMovieClip();
			movieClip:Resume();
		end
	end
	return true;
end


function MovieChannel:OnMovieTimeChange()
	local movieClip = self:GetCurrentMovieClip();
	if(movieClip) then
		if(self.playToTime > self.playFromTime) then
			if(self:IsLooping()) then
				local delta = movieClip:GetTime()-self.playToTime;
				if(delta >= 0) then
					movieClip:SetTime(self.playFromTime + (delta % (self.playToTime - self.playFromTime)))
					movieClip:Resume();	
				end
				self:CheckSentient()
			else
				if(movieClip:GetTime() >= self.playToTime) then
					movieClip:Pause();
					movieClip:Disconnect("timeChanged", self, self.OnMovieTimeChange);
					movieClip:SetTime(self.playToTime);
					if(self:IsAutoStopWhenPlayFinish()) then
						movieClip:Stop()
					end
					self:FireFinished();
				else
					self:CheckSentient()
				end
			end
		else
			if(self:IsLooping()) then
				local delta = movieClip:GetTime()-self.playToTime;
				if(delta <= 0) then
					movieClip:SetTime(self.playFromTime - ((-delta) % (self.playFromTime - self.playToTime)))
					movieClip:Resume();	
				end
				if(movieClip:GetTime() >= self.playFromTime) then
					if(movieClip:GetTime() > self.playFromTime) then
						movieClip:SetTime(self.playFromTime);
					end
					movieClip:Resume();	
				end
				self:CheckSentient()
			else
				if(movieClip:GetTime() <= self.playToTime) then
					movieClip:Pause();
					movieClip:Disconnect("timeChanged", self, self.OnMovieTimeChange);
					movieClip:SetTime(self.playToTime);
					self:FireFinished();
					if(self:IsAutoStopWhenPlayFinish()) then
						movieClip:Stop()
					end
				else
					self:CheckSentient()
				end
			end
		end
	end
end

function MovieChannel:ResetSentientChecker()
	if(self.sentientTimer) then
		self.sentientTimer:Change();
		self.sentientPaused = nil;
	end
end

function MovieChannel:FireFinished()
	if(self.isFiringFinished) then
		return;
	end
	self.isFiringFinished = true;
	self:ResetSentientChecker()
	self:finished(); -- signal
	self:Disconnect("finished")
	self.isFiringFinished = nil;
end

-- stop and remove all actors
function MovieChannel:Stop()
	self:SetLooping(false);
	if(self:GetCurrentMovieClip()) then
		self:GetCurrentMovieClip():Stop();
	end
	self:FireFinished();
	self:stopped(); -- signal
end


-- where the actors are played, default to the main 3d scene. 
-- only call this function before the movie is activated. 
-- we are load all movie actors inside a given miniscenegraph by its name. 
-- @param miniSceneName: if nil, it is the default 3d scene, otherwise it is the miniscenegraph name. 
function MovieChannel:SetScene(miniSceneName)
	self.sceneName = miniSceneName
end

function MovieChannel:GetScene()
	return self.sceneName
end

-- we will clone the movie entity instead of using the original one, so that calling it is safe to call TransformActorsByFirstActor and binding to entities.
-- @param movieEntity: this could be from the EntityManager:GetBlockEntity(x,y,z)
function MovieChannel:CloneFromEntity(movieEntity)
	if(self.startupMovieEntity) then
		self:Reset()
	end
	if(movieEntity and movieEntity:isa(EntityManager.EntityMovieClip)) then
		local xmlNode = movieEntity:SaveToXMLNode()
		xmlNode.attr.name = nil;
		xmlNode.attr.linkTo = nil;
		local entity = EntityManager.EntityMovieClip:new();
		entity:LoadFromXMLNode(xmlNode);
		entity:SetPersistent(false);
		self.startupMovieEntity = entity;
	end
end

-- static function: create a movie entity in memory from a block template file. 
-- @param filename: block template file that should only contain one movie block. 
-- @param bx, by, bz: movie block position
-- @param isMainPlayer: if true, it will be a player movie entity, otherwise it will be a non-player movie entity. 
-- @param entity: if provided, it will be provide the user data of movie entity. 
-- @return movieEntity
function MovieChannel:CreateFromTemplateFile(filename, bx, by, bz)
	if(self.startupMovieEntity) then
		self:Reset()
	end
	local EntityMovieClip = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip")
	local entity = EntityMovieClip:CreateFromTemplateFile(filename, bx, by, bz)
	self.startupMovieEntity = entity;
end

-- @param x, y, z: the target position of the first actor in the movie clip in world coordinates
-- @param scaling: if not nil, it will scale all actors relative to the first actor's scaling. so that the first actor will have this scaling at the target position.
function MovieChannel:TransformActorsByFirstActor(x, y, z, facing, skin, scaling, bIgnoreCamera)
	local entity = self.startupMovieEntity;
	if(entity) then
		if bIgnoreCamera then
			for i=1, entity.inventory:GetSlotCount() do
				local itemStack = entity.inventory:GetItem(i);
				if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
					if(itemStack.id == block_types.names.TimeSeriesCamera) then
						entity.inventory:RemoveItem(i)
					end
				end
			end
		end

		local firstActorData;
		for i=1, entity.inventory:GetSlotCount() do
			local itemStack = entity.inventory:GetItem(i);
			if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
				if(itemStack.id == block_types.names.TimeSeriesNPC) then
					local timeSeries = itemStack.serverdata.timeseries;
					if(timeSeries and timeSeries.assetfile and timeSeries.assetfile.data) then
						local data = timeSeries.assetfile.data;
						for i = 1, #(data) do
							if(data[i] == "customchar" or data[i] == "character/CC/02human/CustomGeoset/actor.x") then
								firstActorData = timeSeries
							end
						end
					end
				end
			end
			if(firstActorData) then break; end
		end
		if(firstActorData)then
			local firstFrameX = firstActorData.x.data[1]
			local firstFrameZ = firstActorData.z.data[1]
			local firstFrameY = firstActorData.y.data[1]

			local offset_x = x - firstFrameX
			local offset_y = y - firstFrameY
			local offset_z = z - firstFrameZ

			offset_x = offset_x / BlockEngine.blocksize
			offset_y = offset_y / BlockEngine.blocksize
			offset_z = offset_z / BlockEngine.blocksize
			entity:OffsetActorPositions(offset_x, offset_y, offset_z);

			if(scaling) then
				local firstActorScaling = firstActorData.scaling and firstActorData.scaling.data and firstActorData.scaling.data[1] or 1
				local scale_factor = scaling / firstActorScaling
				entity:ScaleActors(scale_factor, x, y, z);
			end

			local facing_offset
			if(facing and firstActorData.facing and #firstActorData.facing.data > 0) then
				local firstFrameFacing = firstActorData.facing.data[1]
				facing_offset = mathlib.ToStandardAngle((facing or firstFrameFacing) -firstFrameFacing) 
				entity:OffsetActorFacing(facing_offset, x,y,z);
			end
			if(skin) then
				entity:OffsetActorSkin(skin)
			end
		end
	end
end


-- bind the actorIndex-th actor in the movie clip to the given global entity.
-- @param actorIndex: the index of the NPC actor in the movie clip, starting from 1. default to 1.
-- @param entity: the global entity to which the actor will be bound. it should have a unique name.
-- @param bIgnoreSkin: if true, the skin of the entity will not be applied to the actor.
function MovieChannel:BindActorAgentToEntity(actorIndex, entity, bIgnoreSkin, preserveScale)
	if(not entity or GameLogic.EntityManager.GetEntity(entity.name) ~= entity) then
		LOG.std(nil, "warn", "MovieChannel", "BindActorAgentToEntity: entity with a unique name is required. %s", entity.name or "")
		return
	end
	actorIndex = actorIndex or 1;
	local movieEntity = self.startupMovieEntity;
	local index = 0;
	if(movieEntity) then
		local actorData;
		for i=1, movieEntity.inventory:GetSlotCount() do
			local itemStack = movieEntity.inventory:GetItem(i);
			if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
				if(itemStack.id == block_types.names.TimeSeriesNPC) then
					index = index + 1;
					if(index == actorIndex) then
						actorData = itemStack.serverdata.timeseries;
						break;
					end
				end
			end
		end
		if(actorData) then
			if(actorData.name) then
				actorData.name.data[1] = entity.name;
			else
				actorData.name = {times={0,},data={entity.name,},ranges={{1,1,},},type="Discrete",name="name",};
			end
			if(actorData.isAgent) then
				actorData.isAgent.data[1] = true;
			else
				actorData.isAgent = {times={0,},data={true,},ranges={{1,1,},},type="Discrete",name="isAgent",};
			end
			if(actorData.assetfile) then
				actorData.assetfile.data[1] = entity:GetModelFile();
			else
				actorData.assetfile = {times={0,},data={entity:GetModelFile(),},ranges={{1,1,},},type="Discrete",name="assetfile",};
			end
			if(actorData.isIgnoreSkin) then
				actorData.isIgnoreSkin.data[1] = bIgnoreSkin == true;
			else
				actorData.isIgnoreSkin = {times={0,},data={bIgnoreSkin == true,},ranges={{1,1,},},type="Discrete",name="isIgnoreSkin",};
			end
			if preserveScale and preserveScale > 0 then
				local scaling = actorData.scaling and actorData.scaling.data
				if scaling and #scaling > 0 then
					local num = #scaling
					for i = 1, num do
						actorData.scaling.data[i] = actorData.scaling.data[i] * preserveScale
					end
				else
					actorData.scaling = {times={0,},data={preserveScale,},ranges={{1,1,},},type="Discrete",name="scaling",};
				end
			end
		end
	end
end
