--[[
Title: Audio
Author(s): LiXizhi
Date: 2014/3/3
Desc: audio command 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandAudio.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["music"] = {
	name="music", 
	mode_deny = "",
	mode_allow = "",
	quick_ref="/music [filename|1~6] [from_time]", 
	desc=[[change background music. specify a number for internal music
/music music.ogg 0	play music.ogg at current world directory from the beginning (0 seconds) 
/music 1			play music 1 
/music stop			to stop the music
/music				empty is also to stop the music
/music 1.mp3 10.1   play 1.mp3 from 10.1 seconds
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
		local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");

		local filename, from_time
		filename, cmd_text = CmdParser.ParseString(cmd_text);
		from_time, cmd_text = CmdParser.ParseInt(cmd_text);

		if(not filename or filename=="" or filename=="stop") then
			BackgroundMusic:Stop();
		else
			local sound = BackgroundMusic:GetMusic(filename);
			if(sound) then
				if(from_time) then
					sound:stop();
					sound:seek(from_time);
				end
				BackgroundMusic:PlayBackgroundSound(sound);
			end
		end
	end,
};

Commands["sound"] = {
	name="sound", 
	quick_ref="/sound name [filename] [from_time] [volume:0-1] [pitch:0-1]", 
	desc=[[play a non-loop sound by a given name. There can be only one sound playing for each name
/sound name [filename] [from_time:0] [volume:0-1] [pitch:0-2]   
/sound anyname break.ogg 0.2 1.3			play break.ogg in channel anyname
/sound break							play a predefined sound
/sound 1.mp3							play 1.mp3 on its own channel.
/sound 1.mp3 10.1						play 1.mp3 from 10.1 seconds
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local sound_name, filename, fromtime, volume, pitch;
		sound_name, cmd_text = CmdParser.ParseString(cmd_text);
		filename, cmd_text = CmdParser.ParseString(cmd_text);
		if(filename and filename:match("^[%d%.]+$")) then
			fromtime = tonumber(filename);
			filename = nil;
		else
			fromtime, cmd_text = CmdParser.ParseInt(cmd_text);	
		end
		
		volume, cmd_text = CmdParser.ParseInt(cmd_text);
		pitch, cmd_text = CmdParser.ParseInt(cmd_text);

		if(not pitch and fromtime and volume) then
			volume, pitch, fromtime = fromtime, volume, nil;
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
		local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
		if(sound_name) then
			SoundManager:PlaySound(sound_name, filename, fromtime, volume, pitch);
		end
	end,
};

Commands["stopsound"] = {
	name="stopsound", 
	quick_ref="/sound name ", 
	desc="stop a sound", 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local sound_name, filename, volume, pitch;
		sound_name, cmd_text = CmdParser.ParseString(cmd_text);
		NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
		local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
		if(sound_name) then
			SoundManager:StopSound(sound_name);
		end
	end,
};


Commands["midi"] = {
	name="midi", 
	quick_ref="/midi [0-7]", 
	desc=[[play a midi note, more information, search midiOutShortMsg for MCI api.
-- a note msg is 0x00[XX:Velocity][XX:Note][9X:9channel]
-- @param note: 0-127: 128 note keys. where 60 is middle-C key. 
-- @param velocity: usually how hard a key is pressed. 0-128. default to 64
-- @param channel: 0-15 channels. default to channel 0

/midi 0x00403C90    play a raw note 3C with velocity 40 in channel 0. 
/midi [1-7]		 do la me fa so la si     
/midi a[1-7]     lower tone
/midi g[1-7]     higher tone
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNote.lua");
		local EntityNote = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNote");

		if(cmd_text) then
			EntityNote.PlayCmd(cmd_text);
		end
	end,
};