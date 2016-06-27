--[[
Title: a single music track on the time line
Author(s): LiXizhi
Date: 2014/10/15
Desc: playing a music file on the time line, dragging the time line will automatically seek to the music file
allowing precise editing between music and 3d scene. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorMusic.lua");
local ActorMusic = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorMusic");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MovieClip = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorMusic"));

function Actor:ctor()
end

function Actor:Init(itemStack, movieclipEntity)
	if(not Actor._super.Init(self, itemStack, movieclipEntity)) then
		return;
	end
	
	local timeseries = self.TimeSeries;
	-- location array of movie blocks on the timeline.
	timeseries:CreateVariableIfNotExist("music", "Discrete");

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
	self.last_audio_src = nil;
	self.last_start_time = nil;
	self.last_is_paused = nil;
	self.last_music_time = nil;
end


-- virtual function: display a UI to let the user to edit this keyframe's data. 
-- @param default_value: if nil, it will be the one already on the timeline. {filename, start_time}
function Actor:EditKeyFrame(keyname, time, default_value, callbackFunc)
	local curTime = time or self:GetTime();
	local h,m,s = commonlib.timehelp.SecondsToHMS(curTime/1000);
	local strTime = string.format("%.2d:%.2d", m,math.floor(s));
	local old_value = default_value or self:GetValue(keyname, curTime);
	local old_value_str;
	if(old_value and old_value[1]) then
		old_value_str = string.format("%s %f", old_value[1], old_value[2] or 0);
	end
	local title = format(L"起始时间%s, 请输入文件名与播放位置:<br/>xxx.mp3 [开始时间(单位秒)]", strTime);

	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
	local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
	OpenFileDialog.ShowPage(title, function(result)
		if(result and result~="") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
			local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
			local cmd_text = result;
			local filename, start_time;
			filename, cmd_text = CmdParser.ParseString(cmd_text);
			start_time, cmd_text = CmdParser.ParseInt(cmd_text);
			start_time = start_time or 0;
			if(filename) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
				local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
				if(not Files.GetWorldFilePath(filename)) then
					_guihelper.MessageBox(format(L"当前世界的目录下没有文件: %s", filename));
				else
					local value = {filename, start_time};
					self:AddKeyFrameByName(keyname, nil, value);
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end
	end,old_value_str, L"声音文件", "audio")
end

function Actor:CreateKeyFromUI(keyname, callbackFunc)
	local default_value;
	self:EditKeyFrame(keyname, nil, default_value, callbackFunc);	
end

function Actor:FrameMovePlaying(deltaTime, bIsSelected)
	local curTime = self:GetTime();
	if(not curTime) then
		return
	end
	local music_pos = self:GetValue("music", curTime);
	if(not music_pos) then
		return;
	end
	local filename, start_time = music_pos[1], music_pos[2];

	-- change the current time of the movie block. 
	local var = self:GetVariable("music");
	local fromTime, toTime = var:getTimeRange(1, curTime);
	local firstTime = var:GetFirstTime();

	if(firstTime > curTime) then
		return;
	end
	

	local activeMovieClip = MovieManager:GetActiveMovieClip();
	local isPlayingMode = activeMovieClip:GetEntity():IsPlayingMode();
	local cur_music = BackgroundMusic:GetCurrentMusic();
	local audio_src = BackgroundMusic:GetMusic(filename);
	if(audio_src) then
		if( (math.abs(curTime - (self.last_music_time or 0)) > 500) or
			(self.last_audio_src ~= audio_src or self.last_start_time~=start_time) or 
			(deltaTime == 0 and activeMovieClip and activeMovieClip:IsPaused()) or 
			(activeMovieClip and not activeMovieClip:IsPaused() and self.last_is_paused) ) then
			audio_src:stop();
			local local_time = start_time+(curTime-fromTime)/1000;
			audio_src:seek(local_time);
			-- echo({start_time, curTime-fromTime, curTime, fromTime});
			if(cur_music ~= audio_src) then
				BackgroundMusic:SetMusic(audio_src);
			end
			if(activeMovieClip:IsPaused()) then
				if(not self.last_is_paused) then
					audio_src:pause();
					self.last_is_paused = true;
				end
			else
				if(self.last_is_paused) then
					self.last_is_paused = nil;
					audio_src:play2d();
				else
					audio_src:play2d();
				end
			end
		end
		self.last_audio_src = audio_src;
		self.last_start_time = start_time;
		self.last_music_time = curTime;
	end
	
end
