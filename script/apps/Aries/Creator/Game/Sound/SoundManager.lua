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
	[20011] = 7,
}

-- 20007: 'zh-CN-XiaoruiNeural', // 晓睿 （女）
-- 20008: 'zh-CN-XiaoshuangNeural', // 晓双（女童）
-- 20015: 'zh-HK-HiuGaaiNeural', // 曉佳 （女）
-- 20016: 'zh-HK-WanLungNeural', // 雲龍 （男）
-- 20017: 'zh-TW-HsiaoChenNeural', // 曉臻
-- 20018: 'zh-TW-HsiaoYuNeural', // 曉雨

-- 小燕	Xiaoxuan 晓萱
-- 许久	Yunxi 云希
-- 小萍	Xiaomo 晓墨
-- 小婧	Xiaohan 晓涵
-- 许小宝	YunJhe 雲哲
-- 万叔	yunye 云野
-- 一菲	xiaoyan 晓颜
-- 小果	Xiaochen 晓辰
-- 小梅(粤语）   晓曼	HiuMaan 曉曼
-- 千雪	Xiaoqiu 晓秋
-- 楠楠	xiaoyou 晓悠
-- 芳芳	Xiaoxiao 晓晓
-- 七哥	YunYang 云扬

-- playText旧参数转新参数
local PlayTextToMicrosoft = {
	[10001] = 20009,
	[10002] = 20012,
	[10003] = 20005,
	[10004] = 20004,
	[10005] = 20019,
	[10006] = 20013,
	[10007] = 20010,
	[10008] = 20003,
	[10010] = 20014,
	[10011] = 20006,
	[10012] = 20011,
	[10013] = 20001,
	[10015] = 20002,
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
function SoundManager:PlaySound(channel_name, filename, from_time, volume, pitch, play_start_cb, play_end_cb)
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
		if play_start_cb then
			sound:SetPlayStartCb(play_start_cb)
		end

		if play_end_cb then
			sound:SetPlayEndCb(play_end_cb)
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

		if play_start_cb then
			new_sound:SetPlayStartCb(play_start_cb)
		end

		if play_end_cb then
			new_sound:SetPlayEndCb(play_end_cb)
		end

		new_sound:play2d(volume, pitch);

		self.playingSounds[sound_name] = new_sound;
    end

	GameLogic.GetFilters():apply_filters('sound_starts_playing', sound_name)
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
-- @param name:音效名称 会自动从音效库中查找音效 运行传文件路径 必传
-- @param entity:播放音效的entity对象	必传
-- @param volume:音量
-- @param pitch:音高
-- @param priority:权重
-- @param loop:是否循环
-- @param play_start_cb:开始播放声音前的回调
-- @param play_end_cb:播放结束时的回调
-- @param is_cover_paly:是否覆盖同一频道的声音重新播放
-- @param channel:频道

function SoundManager:PlayEntitySound(name, entity, volume, pitch, priority, loop, play_start_cb, play_end_cb, is_cover_paly, channel, is_follow_entity)
	if not name or not entity then
		return
	end

	local sound_name = channel or "entity_"..entity.entityId;
	local sound_template = self:GetRandomSoundByName(name);
	local file_name = sound_template and sound_template.file or Files.GetWorldFilePath(name)
	local sound = self.playingSounds[sound_name];
	if (sound) then
		if not is_cover_paly then
			self:UpdateSoundLocation(entity);
			return
		end

	else
		if (AudioEngine.IsPlaying(sound_name)) then
			AudioEngine.Stop(sound_name);
		end

		if file_name then
			sound = AudioEngine.CreateGet(sound_name);
			sound.file = file_name;
			sound.loop = true;
			self.playingSounds[sound_name] = sound;
		end
	end

	if not sound then
		return
	end

	sound:SetFileName(file_name);
	if loop ~= nil then
		sound.loop = loop
	end

	if play_start_cb then
		sound:SetPlayStartCb(play_start_cb)
	end

	if play_end_cb then
		sound:SetPlayEndCb(play_end_cb)
	end

	if is_follow_entity then
		self:AddEntityFollowSound(entity, sound)
		-- entity:AddFollowSound(sound)
	end

	local x, y, z = entity:GetPosition();
	sound:play3d(x, y, z, nil, volume, pitch);
end

function SoundManager:AddEntityFollowSound(entity, sound)
	if not entity or not entity.entityId then
		return
	end

	if not self.entity_list then
		self.entity_list = {}
	end
	if not self.entity_list[entity] then
		self.entity_list[entity]  = {}
		self:EntityReferenceCountChange(1)

		entity:Connect("beforeDestroyed", self, self.BeforeEntityDestroyed);
		entity:Connect("valueChanged", self, self.OnEntityPositionChange);
	end

	local sound_list = self.entity_list[entity]
	if not sound_list[sound] then
		sound_list[sound] = sound
	end
end

function SoundManager:BeforeEntityDestroyed(entity)
	if not self.entity_list then
		return
	end

	if self.entity_list[entity] then
		self.entity_list[entity] = nil
		self:EntityReferenceCountChange(-1)
	end
end

function SoundManager:OnEntityPositionChange(entity)
	if not self.entity_list then
		return
	end
	-- local self = SoundManager
	local sound_list = self.entity_list[entity]
	if not sound_list then
		return
	end

	local activity_count = 0
	for key, sound in pairs(sound_list) do
		if sound and sound:isPlaying() then
			local x, y, z = entity:GetPosition();
			sound:move(x, y, z);
			activity_count = activity_count + 1
		else
			sound_list[key] = nil
		end
	end
	
	if activity_count == 0 then
		entity:Disconnect("beforeDestroyed", self, self.BeforeEntityDestroyed);
		entity:Disconnect("valueChanged", self, self.OnEntityPositionChange);
		self.entity_list[entity] = nil
		self:EntityReferenceCountChange(-1)
	end
end

function SoundManager:EntityReferenceCountChange(flag)
	if not self.entity_reference_count then
		self.entity_reference_count = 0
	end

	self.entity_reference_count = self.entity_reference_count + flag

	if self.entity_reference_count == 0 then
		self.entity_list = nil
		self.entity_reference_count = nil
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

-- 让电影方块中的演员嘴巴动起来
function SoundManager:PlayActorText(play_text, voicenarrator, voice_actor, prepare_cb, use3dvoice)
	if voice_actor and voice_actor.SetVoiceMouthSkin then
		local entity = voice_actor:GetEntity()
		local play_entity = use3dvoice and entity or nil
		local channel = "entity_"..entity.entityId
		if use3dvoice then
			channel = channel .. "_3d"
		end
		self:PlayText(play_text, voicenarrator, nil, channel,
			function()
				voice_actor:SetVoiceMouthSkin("88009")
			end,
			function()
				voice_actor:SetVoiceMouthSkin()
			end,
			prepare_cb, play_entity)
	else
		self:PlayText(play_text, voicenarrator, nil, nil, nil, nil, prepare_cb)
	end
	
end


-- @param text: 合成文本
-- @param voiceNarrator: 发音人, 0为女声，1为男声， 3为情感合成-逍遥，4为情感合成-丫丫；逍遥（精品）=5003，
--小鹿=5118，博文=106，小童=110，小萌=111，米朵=103，小娇=5，默认为丫丫(女童音)
-- @param nTimeoutSeconds: 时间限制 超过该时间则不播放声音 单位：秒
-- @param play_start_cb: 播放开始时的回调
-- @param play_end_cb: 播放结束时的回调
-- @param prepare_cb: 下载音效完成后的回调
-- @param play_entity: 播放音效的entity对象 3d音效
function SoundManager:PlayText(text,  voiceNarrator, nTimeoutSeconds, channel, play_start_cb, play_end_cb, prepare_cb, play_entity)
	if nil == text or text == "" or text == '""' then
		return
	end
	voiceNarrator = voiceNarrator or 10012
	voiceNarrator = tonumber(voiceNarrator)
	nTimeoutSeconds = nTimeoutSeconds or 7

	-- 一部分参数转变
	if PlayTextToMicrosoft[voiceNarrator] then
		voiceNarrator = PlayTextToMicrosoft[voiceNarrator]
	end

	local start_timestamp = commonlib.TimerManager.GetCurrentTime();
	self:PrepareText(text,  voiceNarrator, function(file_path)
		if (commonlib.TimerManager.GetCurrentTime() - start_timestamp)/1000 > nTimeoutSeconds then
			if prepare_cb then
				prepare_cb(false)
			end
			if play_end_cb then
				play_end_cb(false)
			end
			return
		end

		channel = channel or "playtext" .. voiceNarrator
		self:SetPlayTextChannel(channel)
		if play_entity then
			self:PlayEntitySound(file_path, play_entity, 5, nil, nil, false, play_start_cb, play_end_cb, true, channel, true)
		else
			self:PlaySound(channel, file_path, nil, nil, nil, play_start_cb, play_end_cb)
		end

		if prepare_cb then
			prepare_cb(true, channel)
		end
	end,function()
		if prepare_cb then
			prepare_cb(false)
		end
		if play_end_cb then
			play_end_cb(false)
		end
	end)
end

-- @param text: 合成文本
-- @param voiceNarrator: 发音人, 0为女声，1为男声， 3为情感合成-逍遥，4为情感合成-丫丫，默认为丫丫(女童音)
-- @param callbackFunc: 下载声音后的回调函数
function SoundManager:PrepareText(text,  voiceNarrator, callbackFunc,onFail)
	if nil == text or text == "" or text == '""' then
		return
	end
	
	local text_lenth = UniString.GetTextLength(text)
	if text_lenth > 200 then
		GameLogic.AddBBS(nil, L"该文本超过字数上限，最多200个文字");
		return
	end

	voiceNarrator = voiceNarrator or 10012
	voiceNarrator = tonumber(voiceNarrator)
	
	-- 一部分参数转变
	if PlayTextToMicrosoft[voiceNarrator] then
		voiceNarrator = PlayTextToMicrosoft[voiceNarrator]
	end
	
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
			if type(data)~="string" then 
				keepwork.burieddata.uploadLog({
					type = "NPLDebug",
					logs = {
						file = "script/apps/Aries/Creator/Game/Sound/SoundManager.lua",
						line = "514",
						msg = "System.os.GetUrl, download text voice data is not string",
						url = url,
					}
				},function(err,msg,data)
					
				end)
				if onFail then
					onFail()
				end
				return
			end
			local file_path = self:SaveTempSoundFile(voiceNarrator, md5_value, data)
			if callbackFunc then
				callbackFunc(file_path)
			end
		else
			self:DownloadSound(text, voiceNarrator, md5_value, function(download_data)
				if type(download_data)~="string" then 
					keepwork.burieddata.uploadLog({
						type = "NPLDebug",
						logs = {
							file = "script/apps/Aries/Creator/Game/Sound/SoundManager.lua",
							line = "534",
							msg = "self:DownloadSound ,download text voice data is not string",
							url = url,
						}
					},function(err,msg,data)
						
					end)
					return
				end
				local file_path = self:SaveTempSoundFile(voiceNarrator, md5_value, download_data)
				if callbackFunc then
					callbackFunc(file_path)
				end
			end,onFail)
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
	local suffix = self:GetPlayTextFileSuffix(voiceNarrator)
	local filename = md5_value .. suffix
	NPL.load("(gl)script/ide/Files.lua");
	local disk_folder = self:GetPlayTextDiskFolder()
	local file_path = string.format("%s/%s/%s", disk_folder, voiceNarrator, filename)
	if ParaIO.DoesFileExist(file_path, true) then
		local file = ParaIO.open(file_path, "r")
		if file then
			if(file:IsValid()) then
				file:close()
				return file_path
			end
			file:close()
		end
	end
end

function SoundManager:SaveTempSoundFile(voiceNarrator, md5_value, data)
	if not data then
		return
	end

	local suffix = self:GetPlayTextFileSuffix(voiceNarrator)
	local filename = md5_value .. suffix
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

function SoundManager:GetPlayTextFileSuffix(voiceNarrator)
	-- voiceNarrator = tonumber(voiceNarrator) 
	-- if not voiceNarrator then
	-- 	return ".mp3"
	-- end

	-- if PlayTextToMicrosoft[voiceNarrator] or tonumber(voiceNarrator) > 20000 then
	-- 	return ".wav"
	-- end

	return ".mp3"
end

function SoundManager:DownloadSound(text, voiceNarrator, md5_value, callback,onFail)
	-- 没登录的话不允许请求这个接口
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
		if onFail then
			onFail()
		end
        return
    end


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
		else
			if onFail then
				onFail()
			end
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