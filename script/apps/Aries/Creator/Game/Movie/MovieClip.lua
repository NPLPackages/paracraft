--[[
Title: movie clip
Author(s): LiXizhi
Date: 2014/3/30
Desc: a movie clip is a group of actors (time series entities) that are sharing the same time origin. 
multiple connected movie clip makes up a movie. The camera actor is a must have actor in a movie clip.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClip.lua");
local MovieClip = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local MovieClip = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip"));
MovieClip:Property("Name", "MovieClip");

MovieClip:Signal("timeChanged");

local groupindex_hint = 3; 

MovieClip.start_time = 0;

function MovieClip:ctor()
	-- whether actors has been created. 
	self.isActorCreated = nil;
	self.actors = {};
end

-- @param entity: movie clip entity. 
function MovieClip:Init(entity)
	self.entity = entity;
	if(entity) then
		return self;
	end
end

function MovieClip:Destroy()
	self:RemoveAllActors();
	MovieClip._super.Destroy(self);
end

-- open the entity editor
function MovieClip:OpenEditor()
	self.entity:OpenEditor("entity", EntityManager.GetPlayer());
end

-- private function: do not call this function. 
-- set one of the actor is recording. 
-- currently only one actor can be made in recording state. 
-- in future or multi-player version, we may allow multiple entity
function MovieClip:SetActorRecording(actor, bIsRecording)
	if(self.recording_actor ~= actor) then
		if(bIsRecording) then
			if(self.recording_actor) then
				self.recording_actor:SetRecording(false);
			end
			self.recording_actor = actor;
			MovieClipTimeLine:ShowTimeline("recording");
		end
	elseif(not bIsRecording) then
		self.recording_actor = nil;
		MovieClipTimeLine:ShowTimeline("not_recording");
	end
end

-- get the first camera actor
function MovieClip:GetCamera()
	return self:GetActorFromItemStack(self.entity:GetCameraItemStack(), true);
end
function MovieClip:HasCamera()
	return self.entity:HasCamera();
end


-- get the first command actor 
function MovieClip:GetCommand(bCreateIfNotExist)
	if(bCreateIfNotExist) then
		return self:GetActorFromItemStack(self.entity:CreateGetCommandItemStack(), true);
	else
		return self:GetActorFromItemStack(self.entity:GetCommandItemStack(), true);
	end
end

-- it is only in playing mode when activated by a circuit. 
-- any other way of triggering the movieclip is not playing mode(that is edit mode)
function MovieClip:IsPlayingMode()
	if(self.entity) then
		return self.entity:IsPlayingMode();
	end
end

-- called when this movie clip is currently playing. 
function MovieClip:OnActivated()
	local x, y, z = self:GetBlockOrigin();
	if(x) then
		ParaTerrain.SelectBlock(x,y,z, true, groupindex_hint);
	end
	self:GotoBeginFrame();
	self:RefreshActors();
	self:RefreshPlayModeUI();
end

-- show/hide timeline and controller according to whether we are in edit mode or recording. 
function MovieClip:RefreshPlayModeUI()
	if(GameMode:CanShowTimeLine() and (MovieManager:IsLastModeEditor() and not MovieManager:IsCapturing())) then
		self:ShowGUI(true);
	else
		self:ShowGUI(false);
	end
end

-- show/hide timeline and controller GUI. 
-- @param bForceEditorMode: true to force editor mode. 
function MovieClip:ShowGUI(bShow, bForceEditorMode)
	if(bShow) then
		if(bForceEditorMode) then
			MovieClipController:SetForceEditorMode(bForceEditorMode);
		end
		MovieClipTimeLine:ShowTimeline("activated");
		MovieClipController.ShowPage(true);
	else
		MovieClipTimeLine:ShowTimeline();
		MovieClipController.ShowPage(false);
		QuickSelectBar.ShowPage(false);
	end
end

-- return the actor that is having the focus
function MovieClip:GetFocus()
	for i, actor in pairs(self.actors) do
		if( actor:HasFocus() ) then
			return actor;
		end
	end
end

-- get currently selected actor in the movie clip controller.
function MovieClip:GetSelectedActor()
	local itemStack = MovieClipController.GetItemStack()
	if(itemStack) then
		for i, actor in pairs(self.actors) do
			if( actor:GetItemStack() == itemStack ) then
				return actor;
			end
		end
	end
end


-- called when this movie clip is no longer playing. 
-- @param next_movieclip: the next movie clip to play. will hand over the camera focus to the next clip 
-- instead of handing over to current player. 
function MovieClip:OnDeactivated(next_movieclip)
	local x, y, z = self:GetBlockOrigin();
	if(x) then
		ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint);
	end
	if(next_movieclip) then
		local last_camera_actor = self:GetFocus();
		if(last_camera_actor and last_camera_actor.class_name=="ActorCamera" ) then
			-- immediately just to the next movie clip's camera if current one has focus. 
			local actor = next_movieclip:GetCamera();
			if(actor) then
				actor:FrameMove(0);
				actor:SetFocus();
				-- trasfer the stored player camera settings before last movie clip is played.
				actor:SetRestoreCamSettings(last_camera_actor:GetRestoreCamSettings());
			end
		end
	end
	self:RemoveAllActors();
	MovieClipTimeLine:ShowTimeline(nil);
	MovieClipController.ShowPage(false);
end

-- get actor from a given entity. 
function MovieClip:GetActorByEntity(entity)
	for i, actor in pairs(self.actors) do
		if( actor:GetEntity() == entity) then
			return actor;
		end
	end
end

-- return millisecond ticks. instead of second. 
function MovieClip:GetTime()
	local time = self.entity:GetTime()
	if(self.time ~= time) then
		self.time = time;
		self.tick = math.floor(time*1000+0.5);
	end
	return self.tick;
end

-- get movie clip length in ms seconds
function MovieClip:GetLength()
	return math.floor(self.entity:GetMovieClipLength()*1000);
end

function MovieClip:GetLengthSeconds()
	return self.entity:GetMovieClipLength();
end

function MovieClip:SetStartTime(time)
	self.entity:SetMovieStartTime(time/1000);
	self:timeChanged();
end

-- set movie clip length in ms seconds
function MovieClip:SetLength(time)
	self.entity:SetMovieClipLength(time/1000);
	self:timeChanged();
end

function MovieClip:UpdateDisplayTimeRange(fromTime, toTime)
	self.display_time_from = fromTime;
	self.display_time_to = toTime;
	self:timeChanged();
end

-- at which time to start playing the movie in play and edit mode. default to 0. 
function MovieClip:GetStartTime()
	return math.floor(self.entity:GetMovieStartTime() * 1000);
end

function MovieClip:GotoBeginFrame()
	self:SetTime(self:GetStartTime() or 0);
end

function MovieClip:GotoEndFrame()
	local endTime = self:GetLength();
	if(endTime) then
		self:SetTime(endTime);
	end
end

-- time in millisecond ticks
function MovieClip:SetTime(curTimeMS)
	if(self:GetTime() ~= curTimeMS) then
		self.entity:SetTime(curTimeMS/1000);
		if(self == MovieManager:GetActiveMovieClip()) then
			-- update actors
			self:UpdateActors();
		end
		self:timeChanged();
	end
end

function MovieClip:RePlay()
	self:Stop();
	self:Resume();
end

-- whether is recording actor's action. 
function MovieClip:SetRecording(bIsRecording)
	local actor = self:GetFocus();
	if(actor) then
		return actor:SetRecording(bIsRecording);
	end
end

function MovieClip:IsPaused()
	return self.entity:IsPaused();
end

function MovieClip:IsPlaying()
	return not self:IsPaused();
end

function MovieClip:Pause()
	self:SetRecording(false);
	self.entity:Pause();
end

function MovieClip:Resume()
	self.entity:Resume();
end

function MovieClip:Stop()
	self:Pause();
	self:SetTime(0);
end

-- this is always a valid entity. 
function MovieClip:GetEntity()
	return self.entity;
end

-- making all actors to play mode, instead of recording mode. 
function MovieClip:SetAllActorsToPlayMode()
	for i, actor in pairs(self.actors) do
		actor:SetRecording(false);
	end
end

-- find actor by its display name 
-- @return actor or nil.
function MovieClip:FindActor(name)
	for i, actor in pairs(self.actors) do
		if(actor:GetDisplayName() == name) then
			return actor;
		end
	end
end

function MovieClip:NewActorName()
	local index = #(self.actors);
	while (true) do
		local name = "actor"..index;
		if(not self:FindActor(name)) then
			return name;
		else
			index = index + 1;
		end
	end
end

-- get the actor for a given itemstack. return nil if not exist
function MovieClip:GetActorFromItemStack(itemStack, bCreateIfNotExist)
	if(itemStack) then
		for i, actor in pairs(self.actors) do
			if(actor.itemStack == itemStack) then
				return actor;
			end
		end
		if(bCreateIfNotExist) then
			local item = itemStack:GetItem();
			if(item and item.CreateActorFromItemStack) then
				local actor = item:CreateActorFromItemStack(itemStack, self.entity);
				if(actor) then
					self:AddActor(actor);
					return actor;
				end
			end
		end
	end
end

-- usually called when movie finished playing. 
function MovieClip:RemoveAllActors()
	for i, actor in pairs(self.actors) do
		actor:OnRemove();
		actor:Destroy();
	end
	self.actors = {};
end

-- get the movie clip's origin x y z position in block world. 
function MovieClip:GetBlockOrigin()
	return self.entity:GetBlockPos();
end

-- get real world origin. 
function MovieClip:GetOrigin()
	return self.entity:GetPosition();
end


function MovieClip:CreateNPC()
	local itemStack = self.entity:CreateNPC()
	if(itemStack) then
		return itemStack;
	end
end

function MovieClip:CreateCamera()
	local itemStack = self.entity:CreateCamera();
	if(itemStack) then
		return itemStack;
	end
end

-- private function: do not call this function. 
function MovieClip:AddActor(actor)
	self.actors[#(self.actors)+1] = actor;
end

-- create and refresh all actors with the movie clip entity
function MovieClip:RefreshActors()
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

	self:UpdateActors();
end

-- @param deltaTime: default to 0
function MovieClip:UpdateActors(deltaTime)
	deltaTime = deltaTime or 0;
	local actor_selected = self:GetSelectedActor();
	for i, actor in pairs(self.actors) do
		local bIsSelected = (actor == actor_selected);
		actor:FrameMove(deltaTime, bIsSelected);
	end
end

-- called every framemove when activated.  
-- @param deltaTime: in milli seconds. 
function MovieClip:FrameMove(deltaTime)
	if(self:IsPaused()) then
		if(self == MovieManager:GetActiveMovieClip()) then
			-- make the actor controllable when paused. 
			local actor = self:GetFocus();
			if(actor) then
				if(actor:IsAllowUserControl()) then
					actor:SetControllable(true);
				else
					actor:SetControllable(false);
				end
			end
		end
		-- always return when paused
		return
	end

	self.entity:AdvanceTime(deltaTime/1000);

	if(self:GetTime() >= self:GetLength()) then
		-- just in case there is still /t xx /end event, due to lua number precision error. 
		self.entity:AdvanceTime();
		self:SetTime(self:GetLength());
		self:Pause();

		-- call UpdateActors to render the last frame. 
		if(deltaTime > 0) then
			self:UpdateActors(deltaTime);
		end
	else
		self:UpdateActors(deltaTime);
	end
	if(deltaTime~=0) then
		self:timeChanged();
	end
end
