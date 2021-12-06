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
	quick_ref="/music [-channelName] [filename|1~6] [from_time]", 
	desc=[[play or stop background music. 
@param filename: can be disk or http url file or specify a number for internal music
/music music.ogg 0	play music.ogg at current world directory from the beginning (0 seconds) 
/music 1 			play music 1 
/music stop 		to stop the music
/music 				empty means to stop all background musics
/music 1.mp3 10.1   play 1.mp3 from 10.1 seconds
/music http://tts.baidu.com/text2audio?lan=zh&ie=UTF-8&spd=4&text=hello
/music -c1 music.ogg   play music.ogg on channel "c1"
/music -c1 stop channel "c1"
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
		local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");

		local channelName;
		channelName, cmd_text = CmdParser.ParseOption(cmd_text);

		local filename, from_time
		filename, cmd_text = CmdParser.ParseFormated(cmd_text, "%S+");
		from_time, cmd_text = CmdParser.ParseInt(cmd_text);

		if(not filename or filename=="" or filename=="stop") then
			if(channelName) then
				BackgroundMusic:Stop();
			else
				BackgroundMusic:StopChannel(channelName);	
			end
		else
			filename = commonlib.Encoding.Utf8ToDefault(filename)
			if(filename and filename:match("^http")) then
				BackgroundMusic:Play(filename);
			else
				local sound = BackgroundMusic:GetMusic(filename);
				if(sound) then
					if(from_time) then
						sound:stop();
						sound:seek(from_time);
					end
					if(channelName) then
						BackgroundMusic:PlayOnChannel(channelName, sound);
					else
						BackgroundMusic:PlayBackgroundSound(sound);
					end
				end
			end
		end
	end,
};

Commands["voice"] = {
	name="voice", 
	quick_ref="/voice [-voiceNarrator number] text", 
	desc=[[play a given text in human voice
You must have internet connection to use this.
0: 女声,1: 男声,3: 逍遥,4: 丫丫,        
5003: 逍遥2,5118: 小鹿,106: 博文,110: 小童,111: 小萌,103: 米朵,5: 小娇,
10001: 小燕,10002: 许久,10003: 小萍,10004: 小婧,10005: 许小宝,10006: 万叔,
10007: 一菲,10008: 小果,10010: 小梅粤语,10011: 千雪,10012: 楠楠,10013: 芳芳,
10015: 七哥
/voice 你好 Paracraft
/voice -voiceNarrator 2  欢迎使用Paracraft
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local voiceNarrator;
		local option = true;
		while(option) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option == "voiceNarrator") then
				voiceNarrator, cmd_text = CmdParser.ParseInt(cmd_text);
			end
		end
		if cmd_text and cmd_text ~= "" then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
			local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
			SoundManager:PlayText(cmd_text, voiceNarrator);
		end
	end,
};

Commands["sound"] = {
	name="sound", 
	quick_ref="/sound name_or_filename [filename] [from_time] [volume:0-1] [pitch:0-1]", 
	desc=[[play a non-loop sound by a given name. There can be only one sound playing for each name
@param filename: filepath can be relative to current world or a http:// url. 
/sound anyname break.ogg 0.2 1.3    play break.ogg in channel anyname
/sound break    play a predefined sound
/sound 1.mp3    play 1.mp3 on its own channel.
/sound 1.mp3 10.1    play 1.mp3 from 10.1 seconds
/sound http://tts.baidu.com/text2audio?lan=zh&ie=UTF-8&spd=4&text=hello
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local sound_name, filename, fromtime, volume, pitch;
		sound_name, cmd_text = CmdParser.ParseFormated(cmd_text, "%S+");
		filename, cmd_text = CmdParser.ParseFormated(cmd_text, "%S+");
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
			local url = filename or sound_name;
			if(url and url:match("^http")) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HttpFiles.lua");
				local HttpFiles = commonlib.gettable("MyCompany.Aries.Game.Common.HttpFiles");
				HttpFiles.GetHttpFilePath(url, function(err, diskfilename) 
					if(diskfilename) then
						NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
						local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
						SoundManager:PlaySound(sound_name, diskfilename);
					end
				end)
			else
				SoundManager:PlaySound(sound_name, filename, fromtime, volume, pitch);	
			end
		end
	end,
};

Commands["stopsound"] = {
	name="stopsound", 
	quick_ref="/stopsound name", 
	desc="stop a sound by name", 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local sound_name, filename, volume, pitch;
		sound_name, cmd_text = CmdParser.ParseFormated(cmd_text, "%S+");
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
/midi [1-7]		    start from middle C, do la me fa so la si
/midi [A-Ga-g]['*]  play absolute note pitch, middle c is c'
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNote.lua");
		local EntityNote = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNote");

		if(cmd_text) then
			EntityNote.PlayCmd(cmd_text);
		end
	end,
};


Commands["/recordsound"] = {
	name="recordsound", 
	quick_ref="/recordsound", 
	desc=[[show sound recorder UI 
/recordsound
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/SoundRecorder.lua");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
		local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
		local SoundRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.SoundRecorder");
		SoundRecorder.ShowPage(function(filename)
			if(filename) then
				local diskFilepath = Files.GetFilePath(filename)
				if(diskFilepath) then
					GameLogic.AddBBS("recordsound", L"录制文件成功保存到:"..filename, 10000, "0 255 0");
					local folder = diskFilepath:gsub("[^\\/]*$", "")
					GameLogic.RunCommand("/open -d "..folder);
				end
			end
		end);
	end,
};