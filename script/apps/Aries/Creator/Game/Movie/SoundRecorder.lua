--[[
Title: Sound recorder
Author(s): LiXizhi
Date: 2021/10/4
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/SoundRecorder.lua");
local SoundRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.SoundRecorder");
SoundRecorder.ShowPage(function(filename)
	
end);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local SoundRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.SoundRecorder");
local tmpCapturedFile = "temp/capture.ogg";

-- [0.1, 1]: 0.1 is lowest recording quality with smallest file size
SoundRecorder.recordSoundQuality = 0.1
SoundRecorder.startRecordTime = 0;
SoundRecorder.recordedDuration = 0;

local page;
function SoundRecorder.OnInit()
	page = document:GetPageCtrl();
end

-- @param maxDuration: default to nil, we will continue recording until user clicks the stop button. Otherwise we will start immediately and stop after maxDuration seconds.
function SoundRecorder.CaptureSound(filename, OnClose, maxDuration, isSilent)
	SoundRecorder.ShowPage(OnClose, filename, "immediate", maxDuration, isSilent)
end

-- @param OnClose: function(result, values) end 
-- @param outputFilename: if nil, default to "temp/capture.ogg", it can also be wav file. 
-- @param mode: default to nil, or "immediate", if "immediate" we will return immediately after recording.
-- @param maxDuration: default to nil, we will continue recording until user clicks the stop button. Otherwise we will stop after maxDuration seconds.
-- result is "ok" is user clicks the OK button. 
function SoundRecorder.ShowPage(OnClose, outputFilename, mode, maxDuration, isSilent)
	if (System.os.GetPlatform() == "android") then
		if(RequestAndroidPermission and RequestAndroidPermission.RequestRecordAudioPermission) then
			RequestAndroidPermission.RequestRecordAudioPermission();
		end
	end

	SoundRecorder.result = nil;
	SoundRecorder.status = nil;
	SoundRecorder.OnCloseCallback = OnClose;
	SoundRecorder.mode = mode;
	SoundRecorder.outputFilename = outputFilename or tmpCapturedFile;
	SoundRecorder.maxDuration = maxDuration;
	SoundRecorder.mytimer = SoundRecorder.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		SoundRecorder.OnTimer(timer);
	end})
	if(not isSilent) then
		local params = {
			url = "script/apps/Aries/Creator/Game/Movie/SoundRecorder.html", 
			name = "SoundRecorder.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = mode ~= "immediate",
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = mode ~= "immediate",
			zorder = mode == "immediate" and 1000 or nil,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -200,
				y = -170,
				width = 400,
				height = 320,
		};
		System.App.Commands.Call("File.MCMLWindowFrame", params);

		params._page.OnClose = function()
			AudioEngine.StopRecording()
			page = nil;
		end
	end

	if(SoundRecorder.maxDuration and SoundRecorder.mode == "immediate") then
		SoundRecorder.OnRecord()
	end
end

function SoundRecorder.IsRecordAudio()
	return settings.isRecordAudio == true;
end

function SoundRecorder.OnClose()
	if(page) then
		page:CloseWindow();
	end
end

function SoundRecorder.RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function SoundRecorder.OnSave()
	if(page) then
		-- copy temp file to world/recording/rec[yyyy-M-d]_[HH-mm-ss].ogg
		local filename = format("recording/rec%s_%s.ogg", ParaGlobal.GetDateFormat("yyyy-M-d"), ParaGlobal.GetTimeFormat("HH-mm-ss"));
		local absFilePath = Files.WorldPathToFullPath(filename);
		ParaIO.CreateDirectory(absFilePath)
		if(ParaIO.CopyFile(SoundRecorder.tempFilename, absFilePath, true)) then
			AudioEngine.Stop(filename)
			AudioEngine.Stop(absFilePath)
			SoundRecorder.result = filename
		end
		page:CloseWindow();
	end
end

function SoundRecorder.OnTimer(timer)
	if(SoundRecorder.status == "recording") then
		local totalSeconds =  (commonlib.TimerManager.GetCurrentTime() - SoundRecorder.startRecordTime) / 1000
		if (page) then
			local text;
			if(SoundRecorder.maxDuration) then
				text = string.format(L"录制中: %.2f秒/%d秒", totalSeconds, SoundRecorder.maxDuration);
			else
				text = string.format(L"录制中: %.2f秒", totalSeconds);
			end
			if(SoundRecorder.mode ~= 'immediate') then
				page:SetUIValue("text", text);
			else
				page:SetUIValue("textImmediate", text);
			end
		end

		if(SoundRecorder.maxDuration and totalSeconds > SoundRecorder.maxDuration) then
			SoundRecorder.OnStopRecord()
		end
	else
		timer:Change();
	end
end

function SoundRecorder.OnRecord()
	SoundRecorder.status = "recording"
	SoundRecorder.startRecordTime = commonlib.TimerManager.GetCurrentTime()
	SoundRecorder.RefreshPage()
	SoundRecorder.mytimer:Change(10, 100);
	AudioEngine.StartRecording()
end

function SoundRecorder.OnStopRecord()
	if(SoundRecorder.status == "recorded") then
		AudioEngine.StopRecording()
		return
	end
	SoundRecorder.status = "recorded"
	SoundRecorder.recordedDuration = commonlib.TimerManager.GetCurrentTime() - SoundRecorder.startRecordTime;
	SoundRecorder.RefreshPage()
	SoundRecorder.mytimer:Change();

	AudioEngine.StopRecording()
	SoundRecorder.tempFilename = AudioEngine.SaveRecording(SoundRecorder.outputFilename, SoundRecorder.recordSoundQuality);
	if(not SoundRecorder.tempFilename) then
		-- SoundRecorder.OnReRecord()
		-- _guihelper.MessageBox(L"无法录制声音，请确定你已经连接了麦克风")
		LOG.std(nil, "warn", "SoundRecorder", "failed to record sound. you may not have proper recording device")
	end
	if(SoundRecorder.mode == "immediate") then
		SoundRecorder.result = SoundRecorder.tempFilename;
		SoundRecorder.OnClose()
	end
	if(SoundRecorder.OnCloseCallback) then
		SoundRecorder.OnCloseCallback(SoundRecorder.result);
		SoundRecorder.OnCloseCallback = nil;
	end
end

function SoundRecorder.OnPlay()
	if(SoundRecorder.tempFilename) then
		AudioEngine.Stop(SoundRecorder.tempFilename)
		local audio_src = AudioEngine.CreateGet(SoundRecorder.tempFilename)
		audio_src.file = SoundRecorder.tempFilename
		audio_src:play();
	end
end

function SoundRecorder.OnReRecord()
	SoundRecorder.status = nil;
	SoundRecorder.RefreshPage()
end