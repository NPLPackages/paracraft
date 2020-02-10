--[[
Title: movie clip raw base class
Author(s): LiXizhi
Date: 2019/1/16
Desc: a movie clip is a group of actors (time series entities) that are sharing the same time origin. 
multiple connected movie clip makes up a movie. The camera actor is a must have actor in a movie clip.
Similar to MovieClip, except that multiple movieclip can be created for the same movie entity.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipRaw.lua");
local MovieClipRaw = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipRaw");
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local MovieClipRaw = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipRaw"));
MovieClipRaw:Property("Name", "MovieClipRaw");
MovieClipRaw:Property({"bReuseActor", nil, "IsReuseActor", "SetReuseActor", auto=true});
MovieClipRaw:Property({"Speed", 1.0, "GetSpeed", "SetSpeed", auto=true});
MovieClipRaw:Signal("timeChanged");


function MovieClipRaw:ctor()
	-- whether actors has been created. 
	self.isActorCreated = nil;
	self.actors = {};
	self.tick = 0;
	self.time = 0;
end

-- @param entity: movie clip entity. 
function MovieClipRaw:Init(entity)
	self.entity = entity;
	if(entity) then
		return self;
	end
end

function MovieClipRaw:Destroy()
	self:Stop();
	MovieClipRaw._super.Destroy(self);
end

-- open the entity editor
function MovieClipRaw:OpenEditor()
	self.entity:OpenEditor("entity", EntityManager.GetPlayer());
end

-- get the first camera actor
function MovieClipRaw:GetCamera()
	return self:GetActorFromItemStack(self.entity:GetCameraItemStack(), true);
end
function MovieClipRaw:HasCamera()
	return self.entity:HasCamera();
end

-- get the first command actor 
function MovieClipRaw:GetCommand(bCreateIfNotExist)
	if(bCreateIfNotExist) then
		return self:GetActorFromItemStack(self.entity:CreateGetCommandItemStack(), true);
	else
		return self:GetActorFromItemStack(self.entity:GetCommandItemStack(), true);
	end
end

-- return the actor that is having the focus
function MovieClipRaw:GetFocus()
	for i, actor in pairs(self.actors) do
		if( actor:HasFocus() ) then
			return actor;
		end
	end
end

-- get actor from a given entity. 
function MovieClipRaw:GetActorByEntity(entity)
	for i, actor in pairs(self.actors) do
		if( actor:GetEntity() == entity) then
			return actor;
		end
	end
end

-- return millisecond ticks. instead of second. 
function MovieClipRaw:GetTime()
	return self.tick;
end

-- get movie clip length in ms seconds
function MovieClipRaw:GetLength()
	return math.floor(self.entity:GetMovieClipLength()*1000);
end

function MovieClipRaw:GetLengthSeconds()
	return self.entity:GetMovieClipLength();
end

-- at which time to start playing the movie in play and edit mode. default to 0. 
function MovieClipRaw:GetStartTime()
	return math.floor(self.entity:GetMovieStartTime() * 1000);
end

function MovieClipRaw:GotoBeginFrame()
	self:SetTime(self:GetStartTime() or 0);
end

function MovieClipRaw:GotoEndFrame()
	local endTime = self:GetLength();
	if(endTime) then
		self:SetTime(endTime);
	end
end

-- it is only in playing mode when activated by a circuit. 
-- any other way of triggering the movieclip is not playing mode(that is edit mode)
function MovieClipRaw:IsPlayingMode()
	return true;
end


-- time in millisecond ticks
function MovieClipRaw:SetTime(curTimeMS)
	if(self.tick ~= curTimeMS) then
		self.tick = curTimeMS;
		self.time = (curTimeMS/1000);
		-- update actors
		self:UpdateActors();
		self:timeChanged();
	end
end

function MovieClipRaw:RePlay()
	self:Stop();
	self:Resume();
end

function MovieClipRaw:IsPaused()
	return self.isPaused;
end

function MovieClipRaw:IsPlaying()
	return not self.isPaused;
end

function MovieClipRaw:Pause()
	self.isPaused = true;
	MovieManager:RemoveMovieClip(self);
end

function MovieClipRaw:Resume()
	self.isPaused = false;
	MovieManager:AddMovieClip(self);
end

function MovieClipRaw:Stop()
	self:Pause();
	self:RemoveAllActors();
end

-- this is always a valid entity. 
function MovieClipRaw:GetEntity()
	return self.entity;
end

-- find actor by its display name 
-- @return actor or nil.
function MovieClipRaw:FindActor(name)
	for i, actor in pairs(self.actors) do
		if(actor:GetDisplayName() == name) then
			return actor;
		end
	end
end

-- get the actor for a given itemstack. return nil if not exist
function MovieClipRaw:GetActorFromItemStack(itemStack, bCreateIfNotExist)
	if(itemStack) then
		for i, actor in pairs(self.actors) do
			if(actor.itemStack == itemStack) then
				return actor;
			end
		end
		if(bCreateIfNotExist) then
			local item = itemStack:GetItem();
			if(item and item.CreateActorFromItemStack) then
				local actor = item:CreateActorFromItemStack(itemStack, self.entity, self:IsReuseActor(), nil, self);
				if(actor) then
					self:AddActor(actor);
					return actor;
				end
			end
		end
	end
end

-- usually called when movie finished playing. 
function MovieClipRaw:RemoveAllActors()
	for i, actor in pairs(self.actors) do
		actor:OnRemove();
		actor:Destroy();
	end
	self.actors = {};
end

-- get the movie clip's origin x y z position in block world. 
function MovieClipRaw:GetBlockOrigin()
	return self.entity:GetBlockPos();
end

-- get real world origin. 
function MovieClipRaw:GetOrigin()
	return self.entity:GetPosition();
end

-- private function: do not call this function. 
function MovieClipRaw:AddActor(actor)
	actor:SetMovieClip(self);
	self.actors[#(self.actors)+1] = actor;
end

-- create and refresh all actors with the movie clip entity
function MovieClipRaw:RefreshActors()
	if(self.isActorCreated) then
		-- remove all actors first and then recreate all. 
	end
	-- create all actors from inventory item stack. 
	local inventory = self.entity.inventory;

	for i=1, inventory:GetSlotCount() do
		local itemStack = inventory:GetItem(i);
		if(itemStack and itemStack.count>0) then
			-- create get actor
			self:GetActorFromItemStack(itemStack, true)
		end
	end

	for i, actor in pairs(self.actors) do
		actor:OnCreate();
		local entity = actor:GetEntity()
		if(entity) then
			entity:SetSkipPicking(true);
		end
	end

	self:UpdateActors();
end

-- @param deltaTime: default to 0
function MovieClipRaw:UpdateActors(deltaTime)
	deltaTime = deltaTime or 0;
	for i, actor in pairs(self.actors) do
		actor:FrameMove(deltaTime, false);
	end
end

-- called every framemove when activated.  
-- @param deltaTime: in milli seconds. 
function MovieClipRaw:FrameMove(deltaTime)
	if(self:IsPaused()) then
		-- always return when paused
		return
	end

	local cur_time = self:GetTime() + deltaTime*self:GetSpeed();
	self:SetTime(cur_time);

	if(self:GetTime() >= self:GetLength()) then
		-- just in case there is still /t xx /end event, due to lua number precision error. 
		if(self:GetSpeed() > 0) then
			self:Pause();
		end
		self:SetTime(self:GetLength());
		-- call UpdateActors to render the last frame. 
		if(deltaTime > 0) then
			self:UpdateActors(deltaTime);
		end
	else
		self:UpdateActors(deltaTime);
	end
end

-- @param movieController: nil or a table of {time = 0, FrameMove = nil}, 
-- movieController.FrameMove(deltaTime) will be assigned by this function.
function MovieClipRaw:PlayMatchedMovie(playerEntity, movieController)
end