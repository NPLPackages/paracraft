--[[
Title: Movie Channel
Author(s): LiXizhi
Date: 2019/1/16
Desc: there can only be one movie block is that playing per channel
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
MovieChannel:Property({"ReuseActor", true, "IsReuseActor", "SetReuseActor", auto=true});
MovieChannel:Property({"Speed", 1.0, "GetSpeed", "SetSpeed", auto=true});
MovieChannel:Property({"UseCamera", true, "IsUseCamera", "SetUseCamera", auto=true});

MovieChannel:Signal("started");
MovieChannel:Signal("stopped");

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
	MovieClipRaw._super.Destroy(self);
end


function MovieChannel:Reset()
	if(self.clips) then
		for i, clip in ipairs(self.clips) do
			self:Destroy();
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

-- @param timeFrom: time in milliseconds, default to 0.
-- @param timeTo: if nil, default to timeFrom. if -1, it means total movie block length. 
function MovieChannel:Play(fromTime, toTime)
	local movieClip = self:CreateGetStartMovieClip()
	if(movieClip) then
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
		if(toTime>fromTime) then
			movieClip:Resume();	
		end
	end
end

function MovieChannel:PlayLooped(fromTime, toTime)
end

-- stop and remove all actors
function MovieChannel:Stop()
	if(self:GetCurrentMovieClip()) then
		self:GetCurrentMovieClip():Stop();
	end
end