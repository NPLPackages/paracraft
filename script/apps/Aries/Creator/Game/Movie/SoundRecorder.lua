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
	-- filename is recording/rec[yyyy-M-d]_[HH-mm-ss].ogg
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

-- @param OnClose: function(result, values) end 
-- result is "ok" is user clicks the OK button. 
function SoundRecorder.ShowPage(OnClose)
	SoundRecorder.result = nil;
	SoundRecorder.status = nil;
	SoundRecorder.mytimer = SoundRecorder.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		SoundRecorder.OnTimer(timer);
	end})

	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/SoundRecorder.html", 
		name = "SoundRecorder.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		click_through = false, 
		enable_esc_key = true,
		bShow = true,
		isTopLevel = true,
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
		if(OnClose) then
			OnClose(SoundRecorder.result);
		end
		AudioEngine.StopRecording()
		page = nil;
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
	if(page and SoundRecorder.status == "recording") then
		local text = string.format(L"录制中: %.2f秒", (commonlib.TimerManager.GetCurrentTime() - SoundRecorder.startRecordTime) / 1000);
		page:SetUIValue("text", text);
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
	SoundRecorder.status = "recorded"
	SoundRecorder.recordedDuration = commonlib.TimerManager.GetCurrentTime() - SoundRecorder.startRecordTime;
	SoundRecorder.RefreshPage()
	SoundRecorder.mytimer:Change();

	AudioEngine.StopRecording()
	SoundRecorder.tempFilename = AudioEngine.SaveRecording(tmpCapturedFile, SoundRecorder.recordSoundQuality);
	if(not SoundRecorder.tempFilename) then
		SoundRecorder.OnReRecord()
		_guihelper.MessageBox(L"无法录制声音，请确定你已经连接了麦克风")
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