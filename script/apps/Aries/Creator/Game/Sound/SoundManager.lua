--[[
Title: Sound Manager
Author(s): LiXizhi
Date: 2014/6/20
Desc: Sound Manager for 3D (Moving) Entities
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
SoundManager:Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/AudioEngine/AudioEngine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local AudioEngine = commonlib.gettable("AudioEngine");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local UniString = commonlib.gettable("System.Core.UniString")
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local Diskfolder = nil

local VoiceNarratorDefaulSpd = {
	[10012] = 7,
}

-- @param filename: sound name or a table array of sound names. 
function SoundManager:Init()
	-- mapping from name to sound 
	self.playingSounds = {};
end

-- Stops all currently playing sounds
function SoundManager:StopAllSounds()
	if(self.playingSounds) then
		for sound_name, sound in pairs(self.playingSounds) do
			AudioEngine.Stop(sound_name);
		end
		self.playingSounds = {};
	end
end

-- Updates the sound associated with soundEntity with the position and velocity of trackEntity. 
-- @param soundEntity: whose sound to be updated. 
-- @param trackEntity: the position and speed to read from. if nil, it will be soundEntity. 
function SoundManager:UpdateSoundLocation(soundEntity, trackEntity)
	trackEntity = trackEntity or soundEntity;
    local sound_name = "entity_"..soundEntity.entityId;

	local sound = self.playingSounds[sound_name];
    if (sound) then
		if (AudioEngine.IsPlaying(sound_name)) then
			local x, y, z = trackEntity:GetPosition();
			-- update position and velocity
            sound:move(x, y, z);
        else
			self.playingSounds[sound_name] = nil;
        end
    end
end

-- Returns true if a sound is currently associated with the given entity, or false otherwise.
function SoundManager:IsEntitySoundPlaying(soundEntity)
    if (soundEntity) then
        local sound_name = "entity_"..soundEntity.entityId;
		if (AudioEngine.IsPlaying(sound_name)) then
			return true;
        end
    end
end

function SoundManager:GetRandomSoundByName(name)
	return AudioEngine.Get(name);
end

-- by default all sound is non-loop.
-- @param channel_name: or sound_name, there can be only one sound playing on each channel.
--  one can also use the sound filename as the channel name.
-- @param filename: if nil it is the channel_name
function SoundManager:PlaySound(channel_name, filename, from_time, volume, pitch)
    local sound_name = channel_name;
	local sound = self.playingSounds[sound_name];
	if(filename) then
		local filename_ = Files.GetWorldFilePath(filename);
		if(filename_) then
			filename = filename_;
		else
			local soundTemplate = AudioEngine.Get(filename)
			if(soundTemplate) then
				filename = soundTemplate.file;
			else
				filename = nil;
			end
		end
	end
    if (sound) then
        if(filename and sound.file ~= filename) then
			sound:SetFileName(filename);
		end
		if(from_time) then
			sound:stop();
			sound:seek(from_time);
		end
		
		sound:play2d(volume, pitch);
    else
		if (AudioEngine.IsPlaying(sound_name)) then
            AudioEngine.Stop(sound_name);
        end
		local new_sound = AudioEngine.CreateGet(sound_name);

		new_sound.file = filename or (new_sound.file~="" and new_sound.file or Files.GetWorldFilePath(sound_name));
		if(not new_sound.file) then
			LOG.std(nil, "warn", "SoundManager", "sound: %s does not exist. \n", sound_name);
			return 
		end
		new_sound.loop = false;
		if(from_time) then
			new_sound:stop();
			new_sound:seek(from_time);
		end
		new_sound:play2d(volume, pitch);

		self.playingSounds[sound_name] = new_sound;
    end
end

-- @param channel_name: or sound_name, there can be only one sound playing on each channel.
function SoundManager:StopSound(channel_name)
	local sound_name = channel_name;
    if (self.playingSounds[sound_name]) then
        if (AudioEngine.IsPlaying(sound_name)) then
            AudioEngine.Stop(sound_name);
        end
		self.playingSounds[sound_name] = nil;
	end
end

-- If a sound is already playing from the given entity, update the position and velocity of that sound to match the
-- entity. Otherwise, start playing a sound from that entity. Setting the last flag to true will prevent other
-- sounds from overriding this one. 
-- @param name:
-- @param entity:
-- @param volume:
-- @param pitch:
-- @param priority:
function SoundManager:PlayEntitySound(name, entity, volume, pitch, priority)
    if (entity) then
        local sound_name = "entity_"..entity.entityId;
		local sound = self.playingSounds[sound_name];
        if (sound) then
            self:UpdateSoundLocation(entity);
        else
			if (AudioEngine.IsPlaying(sound_name)) then
                AudioEngine.Stop(sound_name);
            end
			if (name) then
                local sound_template = self:GetRandomSoundByName(name);
                if (sound_template) then
					local new_sound = AudioEngine.CreateGet(sound_name);
                    new_sound.file = sound_template.file;
					new_sound.loop = true;

					local x, y, z = entity:GetPosition();
					new_sound:play3d(x, y, z, nil, volume, pitch);
					self.playingSounds[sound_name] = new_sound;
                end
            end
        end
    end
end

-- Stops playing the sound associated with the given entity
function SoundManager:StopEntitySound(entity)
    if (entity) then
        local sound_name = "entity_"..entity.entityId;
        if (self.playingSounds[sound_name]) then
            if (AudioEngine.IsPlaying(sound_name)) then
                AudioEngine.Stop(sound_name);
            end
			self.playingSounds[sound_name] = nil;
		end
    end
end

-- Sets the pitch of the sound associated with the given entity, if one is playing. 
function SoundManager:SetEntitySoundPitch(entity, pitch)
    if (entity) then
        local sound_name = "entity_"..entity.entityId;

		if (AudioEngine.IsPlaying(sound_name)) then
            AudioEngine.SetPitch(sound_name, pitch);
        end
    end
end

-- Sets the volume of the sound associated with the given entity, if one is playing. 
function SoundManager:SetEntitySoundVolume(entity, volume)
    if (entity) then
        local sound_name = "entity_"..entity.entityId;

		if (AudioEngine.IsPlaying(sound_name)) then
            AudioEngine.SetVolume(sound_name, volume);
        end
    end
end

local vibrate_click = { time = 2000, };

-- vibrate for some time.
-- @param time: duration in ms seconds. default to 1ms
function SoundManager:Vibrate(time)
	vibrate_click.time = time or 30;
	if(MobileDevice and MobileDevice.vibrate and GameLogic.options:IsVibrationEnabled()) then
		MobileDevice.vibrate( vibrate_click );
	end
end

-- @param pattern: such as {0, 100, 1000, 300, 200, 100, 500, 200, 100} Start without a delay
-- Each element then alternates between vibrate, sleep, vibrate, sleep...
-- {delay, vibrate, sleep, vibrate, sleep, ...}
-- @param repeatTime:  repeat time, default to 1. 0 for infinity loop
function SoundManager:VibrateWithPattern(pattern, repeatTime)
	if(MobileDevice and MobileDevice.vibrate and GameLogic.options:IsVibrationEnabled()) then
		MobileDevice.vibrateWithPattern({ pattern = pattern, repeatTime = repeatTime or 1,});
	end
end

-- stop all vibrations. 
function SoundManager:CancelVibrate()
	if(MobileDevice and MobileDevice.vibrate and GameLogic.options:IsVibrationEnabled()) then
		MobileDevice.cancelVibrate();
	end
end


-- @param text: 合成文本
-- @param voiceNarrator: 发音人, 0为女声，1为男声， 3为情感合成-逍遥，4为情感合成-丫丫；逍遥（精品）=5003，
--小鹿=5118，博文=106，小童=110，小萌=111，米朵=103，小娇=5，默认为丫丫(女童音)
-- @param nTimeoutMS: 时间限制 超过该时间则不播放声音 单位：秒
function SoundManager:PlayText(text,  voiceNarrator, nTimeoutMS)
	if nil == text or text == "" or text == '""' then
		return
	end
	voiceNarrator = voiceNarrator or 10012
	nTimeoutMS = nTimeoutMS or 7

	local start_timestamp = commonlib.TimerManager.GetCurrentTime();
	self:PrepareText(text,  voiceNarrator, function(file_path)
		if (commonlib.TimerManager.GetCurrentTime() - start_timestamp)/1000 > nTimeoutMS then
			return
		end

		local channel = "playtext" .. voiceNarrator
		self:SetPlayTextChannel(channel)
		self:PlaySound(channel, file_path)
	end)
end

-- @param text: 合成文本
-- @param voiceNarrator: 发音人, 0为女声，1为男声， 3为情感合成-逍遥，4为情感合成-丫丫，默认为丫丫(女童音)
-- @param callbackFunc: 下载声音后的回调函数
function SoundManager:PrepareText(text,  voiceNarrator, callbackFunc)
	if nil == text or text == "" or text == '""' then
		return
	end
	
	local text_lenth = UniString.GetTextLength(text)
	if text_lenth > 200 then
		GameLogic.AddBBS(nil, L"该文本超过字数上限，最多200个文字");
		return
	end

	voiceNarrator = voiceNarrator or 10012
	local md5_value = self:GetPlayTextMd5(text, voiceNarrator)
	-- 检测是否有本地文件
	local file_path = SoundManager:GetTempSoundFile(voiceNarrator, md5_value)
	if file_path then
		if callbackFunc then
			callbackFunc(file_path)
		end
		return
	end

	-- 判断cdn上有无缓存
	local httpwrapper_version = HttpWrapper.GetDevVersion();
	local url = httpwrapper_version == "ONLINE" and "http://qiniu-audio.keepwork.com" or "http://qiniu-audio-dev.keepwork.com"
	url = string.format("%s/%s?%s", url, md5_value, math.random(1, 100))

	System.os.GetUrl(url, function(err, msg, data)
		if err == 200 and data then
			local file_path = self:SaveTempSoundFile(voiceNarrator, md5_value, data)
			if callbackFunc then
				callbackFunc(file_path)
			end
		else
			self:DownloadSound(text, voiceNarrator, md5_value, function(download_data)
				local file_path = self:SaveTempSoundFile(voiceNarrator, md5_value, download_data)
				if callbackFunc then
					callbackFunc(file_path)
				end
			end)
		end
	end);

	-- if GameLogic.IsVip() or GameLogic.IsReadOnly() then

	-- elseif not GameLogic.IsReadOnly() then
	-- 	self:DownloadSoundByBaiDu("您需要成为会员才能播放这段文字", callbackFunc)
	-- end
end

function SoundManager:StopPlayText()
	if self.playtext_sound_channel then
		local sound_name = self.playtext_sound_channel;
		if (self.playingSounds[sound_name]) then
			AudioEngine.Stop(sound_name);
			self.playingSounds[sound_name] = nil;
		end
		self.playtext_sound_channel = nil
	end
end

function SoundManager:SetPlayTextChannel(channel)
	self.playtext_sound_channel = channel
end

function SoundManager:GetTempSoundFile(voiceNarrator, md5_value)
	local filename = md5_value .. ".mp3"
	NPL.load("(gl)script/ide/Files.lua");
	local disk_folder = self:GetPlayTextDiskFolder()
	local file_path = string.format("%s/%s/%s", disk_folder, voiceNarrator, filename)
	if ParaIO.DoesFileExist(file_path, true) then
		return file_path
	end
end

function SoundManager:SaveTempSoundFile(voiceNarrator, md5_value, data)
	local filename = md5_value .. ".mp3"
	local disk_folder = self:GetPlayTextDiskFolder()
	local file_path = string.format("%s/%s/%s", disk_folder, voiceNarrator, filename)
	ParaIO.CreateDirectory(file_path)
	local file = ParaIO.open(file_path, "w");
	if(file) then
		file:write(data, #data);
		file:close();
	end

	return file_path
end

function SoundManager:DownloadSound(text, voiceNarrator, md5_value, callback)
	local spd = VoiceNarratorDefaulSpd[voiceNarrator] or 5
	keepwork.user.playtext({
		text = text,
		key = md5_value,
		options = {per = voiceNarrator, spd = spd},
	}, function(err, msg, data)
		if err == 200 then
			System.os.GetUrl(data.data, function(download_err, download_msg, download_data)
				if download_err == 200 then
					callback(download_data)
				end
			end);
		end
	end)
end

function SoundManager:DownloadSoundByBaiDu(text, callback, speed, lang)
	speed = speed or 5;
	lang = lang or "zh";

	if(text~="") then
		local url = format("https://tts.baidu.com/text2audio?per=1&lan=%s&ie=UTF-8&spd=%d&text=%s", lang, speed, commonlib.Encoding.url_encode(text));
		NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HttpFiles.lua");
		local HttpFiles = commonlib.gettable("MyCompany.Aries.Game.Common.HttpFiles");
		HttpFiles.GetHttpFilePath(url, function(err, diskfilename) 
			if(diskfilename) then
				callback(diskfilename)
			end
		end)
	end
end

function SoundManager:GetSoundDuration(channel_name, filename)
    local sound_name = channel_name;
	local sound = self.playingSounds[sound_name];
	if(filename) then
		local filename_ = Files.GetWorldFilePath(filename);
		if(filename_) then
			filename = filename_;
		else
			local soundTemplate = AudioEngine.Get(filename)
			if(soundTemplate) then
				filename = soundTemplate.file;
			else
				filename = nil;
			end
		end
	end
	
    if (sound) then
        if(filename and sound.file ~= filename) then
			sound:SetFileName(filename);
		end

		local source = sound:GetSource()
		return source.TotalAudioTime or 0
    else
		local new_sound = AudioEngine.CreateGet(sound_name);

		new_sound.file = filename or (new_sound.file~="" and new_sound.file or Files.GetWorldFilePath(sound_name));
		if(not new_sound.file) then
			LOG.std(nil, "warn", "SoundManager", "sound: %s does not exist. \n", sound_name);
			return 
		end
		local source = new_sound:GetSource()
		return source.TotalAudioTime or 0
    end
end

function SoundManager:GetPlayTextMd5(text, voiceNarrator)
	local spd = VoiceNarratorDefaulSpd[voiceNarrator]
	if spd and spd ~= 5 then
		return ParaMisc.md5(string.format("%s_%s_%s", text, voiceNarrator, spd))
	end
	
	return ParaMisc.md5(string.format("%s_%s", text, voiceNarrator, spd))
end

function SoundManager:GetPlayTextDiskFolder()
    if(not DiskFolder) then
		DiskFolder = ParaIO.GetWritablePath().."temp/PlayText"
   end
    
	return DiskFolder
end

function SoundManager:IsPlayTextSoundPlaying()
	if self.playingSounds == nil then
		return false
	end

	for k, v in pairs(self.playingSounds) do
		if string.find(k, "playtext") and AudioEngine.IsPlaying(k) then
			return true
		end
	end

	return false
end