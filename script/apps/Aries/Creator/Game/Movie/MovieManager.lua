--[[
Title: Movie Manager
Author(s): LiXizhi
Date: 2014/3/30
Desc: managing current movie clip
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local MovieClip = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip");

local MovieManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager"));
MovieManager:Property("Name", "MovieManager");

MovieManager:Signal("activeMovieClipChanged", function(clip) end);

function MovieManager:ctor()
	self.active_clips = commonlib.UnorderedArraySet:new();
	GameLogic.GetFilters():add_filter("show", MovieManager.ShowFilter);
end

-- called when enter block world. 
function MovieManager:Init()
	MovieManager:InitSingleton();
	self:Reset();
end

function MovieManager:Reset()
	self.current_movieclip = nil;
	self.active_clips:clear();
	self:activeMovieClipChanged(self.current_movieclip);
end

-- get the currently active movie clip
function MovieManager:GetActiveMovieClip()
	return self.current_movieclip;
end

-- return true if current actor is playing(not paused), otherwise return nil or false, such as recording or paused. 
-- usually we will disable all player heading when current player is playing back stored sequence. 
function MovieManager:IsCurrentActorPlayingback()
	local movieClip = self:GetActiveMovieClip();
	if(movieClip) then
		local actor = movieClip:GetFocus();
		if(actor) then
			return not actor:IsRecording() and not actor:IsPaused();
		end
	end
end

-- toggle live video recording. recording is automatically stopped when there is no movie clip to play. 
-- Hot key is R when in movie playing mode. 
function MovieManager:ToggleCapture()
	if(not self:IsCapturing())  then
		self:BeginCapture();
	else
		self:EndCapture();
	end
end

function MovieManager:IsCapturing()
	return self.is_video_recording;
end

-- automatically hide all ui, replay and record from the current movie clip. 
function MovieManager:BeginCapture()
	local movie_clip = self:GetActiveMovieClip();
	if(movie_clip) then
		self.is_video_recording = true;

		-- always replay
		movie_clip:RePlay();
		movie_clip:Pause();
		movie_clip:RefreshPlayModeUI();
		VideoRecorder.BeginCapture(function(bSucceed)
			if(bSucceed) then
				movie_clip:Resume();
			else
				self.is_video_recording = false;
				movie_clip:RefreshPlayModeUI();
			end
		end);
	end
end

function MovieManager:EndCapture()
	self.is_video_recording = false;
	VideoRecorder.EndCapture();

	if(ParaIO.DoesFileExist(VideoRecorder.GetCurrentVideoFileName())) then
		_guihelper.MessageBox("录制完成, 是否现在打开文件目录？", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				VideoRecorder.OpenOutputDirectory();
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	end
end

function MovieManager:TryPushMovieMode(movie_clip)
	if(not self.lastmode) then
		self.lastmode = GameMode:GetMode();
		Desktop.OnActivateDesktop("movie");
		GameLogic.options:SetClickToContinue(false);
	end
end

function MovieManager:TryPopMovieMode()
	if(self.lastmode) then
		local lastmode = self.lastmode
		self.lastmode = nil;
		if(not self.isExiting) then
			Desktop.OnActivateDesktop(lastmode);
		end
		GameLogic.options:SetClickToContinue(true);
	end
end

function MovieManager:IsLastModeEditor()
	return (self.lastmode == "editor");
end

function MovieManager.ShowFilter(name, bShow)
	if(name == "movie.controller") then
		local self = MovieManager;
		local movie_clip = self:GetActiveMovieClip();
		if(movie_clip) then
			movie_clip:ShowGUI(bShow~=false, true);
		end
		return;
	end
	return name;
end

-- called when unload world
function MovieManager:Exit()
	local movie_clip = self:GetActiveMovieClip();
	if(movie_clip) then
		self.isExiting = true;
		self:SetActiveMovieClip(nil);
		self.isExiting = nil;
	end
end

-- set currently activate movie clip. 
function MovieManager:SetActiveMovieClip(movie_clip)
	if(movie_clip ~= self.current_movieclip) then
		if(self.current_movieclip) then
			-- exit movie capturing when the whole movie is finished. no more clips to play
			if(not movie_clip) then
				if(self:IsCapturing()) then
					self:EndCapture();
					self.current_movieclip:RefreshPlayModeUI();	
				end
			end
			self.current_movieclip:OnDeactivated(movie_clip);
		end

		self:RemoveMovieClip(self.current_movieclip);
		self:AddMovieClip(movie_clip);
		self.current_movieclip = movie_clip;
		
		if(movie_clip) then
			self:TryPushMovieMode(movie_clip);
			movie_clip:OnActivated();
			-- make the clip last trigger entity, so that relative command can be used. 
			EntityManager.SetLastTriggerEntity(movie_clip:GetEntity());
		else
			self:TryPopMovieMode();
		end
		self:activeMovieClipChanged(self.current_movieclip);
	end
end

function MovieManager:AddMovieClip(movieclip)
	if(movieclip) then
		self.active_clips:add(movieclip);
	end
end

function MovieManager:RemoveMovieClip(movieclip)
	if(movieclip) then
		self.active_clips:removeByValue(movieclip);
	end
end

-- called every framemove. 
-- @param deltaTime: in millisecond ticks
function MovieManager:FrameMove(deltaTime)
	for i=1, #self.active_clips do
		local movie_clip = self.active_clips[i];
		if(movie_clip) then
			movie_clip:FrameMove(deltaTime);	
		end
	end
end
