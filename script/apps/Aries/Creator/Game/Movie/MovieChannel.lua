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
	self:Reset();
	MovieChannel._super.Destroy(self);
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

function MovieChannel:CreateGetStartMovieClip()
	if(not self.clips and self.startX) then
		local blockEntity = EntityManager.GetBlockEntity(self.startX, self.startY, self.startZ);
		if(blockEntity and blockEntity.GetMovieClip) then
			self.clips = {}
			self.clips[1] = MovieClipRaw:new():Init(blockEntity);
			self.curClipIndex = 1;
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

-- @param timeFrom: time in milliseconds, default to 0.
-- @param timeTo: if nil, default to timeFrom. if -1, it means total movie block length. 
function MovieChannel:Play(fromTime, toTime, bLooping)
	
	local movieClip = self:CreateGetStartMovieClip()
	if(movieClip) then
		self:FireFinished();
		movieClip:SetReuseActor(self:IsReuseActor());
		if(not fromTime) then
			movieClip:GotoBeginFrame();
			fromTime = movieClip:GetTime();
		else
			movieClip:SetTime(fromTime);
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
			else
				if(movieClip:GetTime() >= self.playToTime) then
					movieClip:Pause();
					movieClip:Disconnect("timeChanged", self, self.OnMovieTimeChange);
					movieClip:SetTime(self.playToTime);
					self:FireFinished();
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
			else
				if(movieClip:GetTime() <= self.playToTime) then
					movieClip:Pause();
					movieClip:Disconnect("timeChanged", self, self.OnMovieTimeChange);
					movieClip:SetTime(self.playToTime);
					self:FireFinished();
				end
			end
		end
	end
end

function MovieChannel:FireFinished()
	self:finished(); -- signal
	self:Disconnect("finished")
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