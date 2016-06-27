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
		filename = Files.GetWorldFilePath(filename);
	end
    if (sound) then
        if(filename and self.file ~= filename) then
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
		new_sound.file = filename or if_else(new_sound.file~="",  new_sound.file, Files.GetWorldFilePath(sound_name));
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
