--[[
Title: BackgroundMusic
Author(s): LiXizhi
Date: 2014/1/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
BackgroundMusic:Play(filename)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HttpFiles.lua");
local HttpFiles = commonlib.gettable("MyCompany.Aries.Game.Common.HttpFiles");

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");

local last_audio_src;
-- from name to audio_src
local channels = {};

local default_music_map = {
	["1"] = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
	["2"] = "Audio/Haqi/AriesRegionBGMusics/Area_SunnyBeach.ogg",
	["3"] = "Audio/Haqi/AriesRegionBGMusics/ambIceSeaSide.ogg",
	["4"] = "Audio/Haqi/AriesRegionBGMusics/ambSnowMountain.ogg",
	["5"] = "Audio/Haqi/AriesRegionBGMusics/ambDesert.ogg",
	["6"] = "Audio/Haqi/AriesRegionBGMusics/AmbLava.ogg",
	["7"] = "Audio/Haqi/AriesRegionBGMusics/ambDarkForestSea.ogg",
	["8"] = "Audio/Haqi/AriesRegionBGMusics/ambPhoenixIsland.ogg",
	["9"] = "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg",
	["10"] = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
}

-- @param filename: sound name or a table array of sound names. 
function BackgroundMusic:Init()
end

-- return true if we have just played a midi file
function BackgroundMusic:CheckPlayMidiFile(filename)
	if(filename and filename:match("%.mid$")) then
		self:Stop();
		ParaAudio.PlayWaveFile(filename);
		return true;
	end
end

function BackgroundMusic:PlayMidiNote(note)
	ParaAudio.PlayMidiMsg(note);
end

-- get audio source from file name. 
function BackgroundMusic:GetMusic(filename)
	if(not filename or filename=="") then
		return;
	end
	filename = default_music_map[filename] or filename;

	local audio_src = AudioEngine.Get(filename);
	if(not audio_src) then
		if(not ParaIO.DoesAssetFileExist(filename, true)) then
			filename = ParaWorld.GetWorldDirectory()..filename;
			if(not ParaIO.DoesAssetFileExist(filename, true)) then
				return;
			end
		end
		-- just in case it is midi file 
		if(self:CheckPlayMidiFile(filename)) then
			return;
		end
		
		audio_src = AudioEngine.CreateGet(filename);
		audio_src.loop = true;
		audio_src.file = filename;
	end
	
	return audio_src;
end

-- @param filename: file name or known audio key name. The filepath can be relative to current world directory or root directory. 
-- this can be a http or https asset file
-- @return: audio source object or nil
function BackgroundMusic:Play(filename, bToggleIfSame)
	self.lastFilename = filename;
	if(filename and filename:match("^http")) then
		HttpFiles.GetHttpFilePath(filename, function(err, diskfilename) 
			if(diskfilename and self.lastFilename == filename) then
				self:Play(diskfilename, bToggleIfSame);
			end
		end)
	else
		local audio_src = BackgroundMusic:GetMusic(filename)
		if(audio_src) then
			return self:PlayBackgroundSound(audio_src, bToggleIfSame);
		end
	end
end

-- set the current background music. but do not call play. 
function BackgroundMusic:SetMusic(audio_src, bToggleIfSame)
	if(audio_src) then
		if(last_audio_src ~= audio_src) then
			if(last_audio_src) then
				last_audio_src:stop();
			end
			last_audio_src = audio_src;
		elseif(bToggleIfSame) then
			self:Stop();
		end
	end
end

-- replace old bg music with the new one. 
-- @retun true if playing, or false if stopped.
function BackgroundMusic:PlayBackgroundSound(audio_src, bToggleIfSame)
	if(audio_src) then
		if(last_audio_src ~= audio_src) then
			if(last_audio_src) then
				last_audio_src:stop();
			end
			last_audio_src = audio_src;
			-- TODO: shall we fade in and fade out?
			audio_src:play2d(); -- then play with default. 
			return true;
		elseif(bToggleIfSame) then
			self:Stop();
			return false;
		end
	end
end

function BackgroundMusic:PlayOnChannel(name, audio_src)
	if(audio_src) then
		if(channels[name] ~= audio_src) then
			if(channels[name]) then
				channels[name]:stop();
			end
			channels[name] = audio_src;
			audio_src:play2d();
			return true;
		end
	end
end

-- @param name: channel name
function BackgroundMusic:StopChannel(name)
	if(not name) then
		self:Stop();
	else
		if(channels[name]) then
			channels[name]:stop();
			channels[name] = nil;
		end
	end
end


-- @param filename: if nil, it will stop current music. otherwise it will only stop of music is the same. 
function BackgroundMusic:Stop(filename)
	-- stop currently playing music
	if(last_audio_src) then
		if(not filename or BackgroundMusic:GetMusic(filename) == last_audio_src) then
			last_audio_src:stop();
			last_audio_src = nil;
		end
	end
	if(next(channels) ) then
		local curMusic = filename or BackgroundMusic:GetMusic(filename)
		for key, audio in pairs(channels) do
			if(not curMusic) then
				audio:stop();
			elseif(curMusic == audio) then
				audio:stop();
				channels[key] = nil
				return
			end
		end
		channels = {}
	end
end

-- return the audio source object. 
function BackgroundMusic:GetCurrentMusic()
	return last_audio_src;
end

function BackgroundMusic:ToggleMusic(filename)
	return self:Play(filename, true)
end

