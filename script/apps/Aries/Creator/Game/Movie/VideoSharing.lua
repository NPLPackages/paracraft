--[[
Title: video recorder for sharing
Author(s): 
Date:
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharing.lua");
local VideoSharing = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharing");
VideoSharing.ToggleRecording();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingSettings.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingUpload.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");
local VideoSharingSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingSettings");
local VideoSharingUpload = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingUpload");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local VideoSharing = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharing");


function VideoSharing.ToggleRecording(time, callback)
	if (ParaMovie.IsRecording()) then
		VideoSharing.EndCapture(false);
		ParaIO.DeleteFile(VideoSharing.GetOutputFile());
	end
	VideoSharingSettings.total_time = time;
	VideoSharing.BeginCapture(callback);
end

function VideoSharing.StopRecording()
	if (ParaMovie.IsRecording()) then
		VideoSharing.EndCapture(false);
	end
end

function VideoSharing.GetOutputFile()
	VideoSharing.output = VideoSharing.output or (VideoSharingSettings.GetOutputFilepath());
	return VideoSharing.output;
end

-- @param callbackFunc: called when started. function(bSucceed) end
function VideoSharing.BeginCapture(callbackFunc)
	function startCapture()
		VideoSharing.output = nil;
		AudioEngine.SetGarbageCollectThreshold(99999);
		VideoRecorder.AdjustWindowResolution(function()
			local start_after_seconds = VideoSharingSettings.start_after_seconds or 0;
			local elapsed_seconds = 0;
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				
				if(elapsed_seconds >= start_after_seconds) then
					timer:Change();
					BroadcastHelper.PushLabel({id="MovieRecord", label = "", max_duration=0, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
					GameLogic.options:SetClickToContinue(false);
					local attr = ParaMovie.GetAttributeObject();
					attr:SetField("RecordingFPS", VideoSharingSettings.GetFPS())
					attr:SetField("VideoBitRate", VideoSharingSettings.GetVideoBitRate())
					attr:SetField("CaptureAudio", VideoSharingSettings.IsRecordAudio())
					local margin = VideoSharingSettings.GetMargin() or 0;
					if(attr:GetField("StereoCaptureMode", 0)~=0) then
						margin = 0;
					elseif(VideoSharingSettings.GetStereoMode() ~=0) then
						attr:SetField("StereoCaptureMode", VideoSharingSettings.GetStereoMode());
						margin = 0;
					end
					attr:SetField("MarginLeft", margin);
					attr:SetField("MarginTop", margin);
					attr:SetField("MarginRight", margin);
					attr:SetField("MarginBottom", margin);
					ParaMovie.BeginCapture(VideoSharing.GetOutputFile())
					VideoSharing.ShowRecordingArea(true);
					if(callbackFunc) then
						callbackFunc(true);
					end
				else
					BroadcastHelper.PushLabel({id="MovieRecord", label = format(L"%d秒后开始录制", start_after_seconds-elapsed_seconds), max_duration=2000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
				end
				elapsed_seconds = elapsed_seconds + timer:GetDelta()/1000;
				if(elapsed_seconds >= start_after_seconds) then
					BroadcastHelper.PushLabel({id="MovieRecord", label = "", max_duration=0, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
				end
			end})
			mytimer:Change(0, 500);
		end)
	end
	if(VideoRecorder.HasFFmpegPlugin()) then
		if (VideoSharingSettings.total_time) then
			VideoSharingSettings.OnClose();
			startCapture();
		else
			VideoSharingSettings.ShowPage(function(res)
				if(res == "ok") then
					startCapture();
				else
					if(callbackFunc) then
						callbackFunc(false);
					end
				end
			end);
		end
	elseif(VideoRecorder.HasFFmpegPlugin()==false) then
		_guihelper.MessageBox(L"视频输出插件没有加载成功，请检查是否有其它客户端在使用")
	else
		_guihelper.MessageBox(L"你没有安装最新版的视频输出插件, 是否现在安装？", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				_guihelper.MessageBox(L"正在安装, 请稍候...");
				VideoRecorder.InstallPlugin(function(bSucceed)
					if(bSucceed) then
						_guihelper.MessageBox(nil);
						VideoSharing.BeginCapture(callbackFunc)
					else
						_guihelper.MessageBox(L"安装失败了");
					end
				end)
			end
		end, _guihelper.MessageBoxButtons.YesNo);
		if(callbackFunc) then
			callbackFunc(false);
		end
	end
end

function VideoSharing.EndCapture(showUpload)
	AudioEngine.SetGarbageCollectThreshold(10);
	ParaMovie.EndCapture();
	VideoSharing.ShowRecordingArea(false);
	GameLogic.options:SetClickToContinue(true);
	VideoRecorder.RestoreWindowResolution();

	if (showUpload) then
		VideoSharingUpload.ShowPage();
	end
end

--宇哥的需求，录制模式下不显示esc，记录原有的esc状态
VideoSharing.IsShowEscDock = nil
function VideoSharing.UpdateEscDock(bShow)
	local EscDock = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/EscDock.lua") 
	if VideoSharing.IsShowEscDock  == nil then
		VideoSharing.IsShowEscDock = EscDock.IsVisible() == true
	end
	if bShow then
		EscDock.ShowView(not bShow)
	else
		local isShow = VideoSharing.IsShowEscDock ~= nil and VideoSharing.IsShowEscDock or false
		EscDock.ShowView(isShow)
		VideoSharing.IsShowEscDock = nil
	end
end


function VideoSharing.ShowRecordingArea(bShow)
	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AsyncLoaderProgressBar.lua");
	local AsyncLoaderProgressBar = commonlib.gettable("Map3DSystem.App.Assets.AsyncLoaderProgressBar");
	if(VideoRecorder.HasFFmpegPlugin()) then
		VideoSharing.UpdateEscDock(bShow)
		local _parent = ParaUI.GetUIObject("ShareSafeArea");
		if(not bShow) then
			if(AsyncLoaderProgressBar.GetDefaultAssetBar()) then
				AsyncLoaderProgressBar.GetDefaultAssetBar():Show(true)
			end
			if(_parent:IsValid()) then
				_parent.visible = false;
				ParaUI.Destroy(_parent.id);
			end
			if(VideoSharing.title_timer) then
				VideoSharing.title_timer:Change();
				VideoSharing.title_timer = nil;
			end
			if (VideoSharing.tail_timer) then
				VideoSharing.tail_timer:Change();
				VideoSharing.tail_timer = nil;
			end
			if(VideoSharing.last_text) then
				ParaEngine.SetWindowText(VideoSharing.last_text);
				VideoSharing.last_text = nil;
			end
			return;
		else
			if(AsyncLoaderProgressBar.GetDefaultAssetBar()) then
				AsyncLoaderProgressBar.GetDefaultAssetBar():Show(false)
			end
			if(not _parent:IsValid()) then
				local attr = ParaMovie.GetAttributeObject();
				local margin_left, margin_top, margin_right, margin_bottom = attr:GetField("MarginLeft",0), attr:GetField("MarginTop",0), attr:GetField("MarginRight",0), attr:GetField("MarginBottom",0);
				local border_width = 2;
				_parent = ParaUI.CreateUIObject("container", "ShareSafeArea", "_fi", 0,0,0,0);
				_parent.background = "";
				_parent.enabled = false;
				_parent.zorder = 100;
				_parent:AttachToRoot();

				local _border = ParaUI.CreateUIObject("container", "border", "_fi", 0,0,0,0);
				_border.background = "";
				_border.enabled = false;
				_parent:AddChild(_border);

				local _this = ParaUI.CreateUIObject("container", "top", "_mt", 0, 0, 0, margin_top);
				_this.background = "Texture/whitedot.png";
				_this.enabled = false;
				_border:AddChild(_this);

				local _this = ParaUI.CreateUIObject("container", "left", "_ml", 0, margin_top, margin_left, margin_bottom);
				_this.background = "Texture/whitedot.png";
				_this.enabled = false;
				_border:AddChild(_this);

				local _this = ParaUI.CreateUIObject("container", "right", "_mr", 0, margin_top, margin_right, margin_bottom);
				_this.background = "Texture/whitedot.png";
				_this.enabled = false;
				_border:AddChild(_this);
				
				local _this = ParaUI.CreateUIObject("container", "bottom", "_mb", 0, 0, 0, margin_bottom);
				_this.background = "Texture/whitedot.png";
				_this.enabled = false;
				_border:AddChild(_this);
				
				local _this = ParaUI.CreateUIObject("container", "logo", "_lt", margin_left+20, margin_top+20, 200, 103);
				_this.background = L"Texture/Aries/Creator/Login/ParaCraftMovieWaterMark.png;0 0 200 103";
				_this.enabled = false;
				_parent:AddChild(_this);
				
				local _this = ParaUI.CreateUIObject("container", "mask_tail", "_fi", 0,0,0,0);
				_this.background = "Texture/whitedot.png";
				_this.enabled = false;
				_this.visible= false;
				_parent:AddChild(_this);

				local _this = ParaUI.CreateUIObject("text", "tail_text1", "_ct", 0,0,0,40);
				_this.enabled = false;
				_this.visible = false;
				_this.text = L"使用Paracraft制作";
				_this.font = "System;40;bold";
				_guihelper.SetUIFontFormat(_this, 36)
				_guihelper.SetButtonFontColor(_this, "#FCFCFC", "#FCFCFC");
				local x = _this:GetTextLineSize();
				_this.x = _this.x - x / 2;
				_this.y = _this.y - 20;
				_parent:AddChild(_this);

				local _this = ParaUI.CreateUIObject("text", "tail_text2", "_ct", 0,0,0,40);
				_this.enabled = false;
				_this.visible = false;
				_this.text = L"https://paracraft.cn/";
				_this.font = "System;20";
				_guihelper.SetUIFontFormat(_this, 36)
				_guihelper.SetButtonFontColor(_this, "#FCFCFC", "#FCFCFC");
				local x = _this:GetTextLineSize();
				_this.x = _this.x - x / 2;
				_this.y = _this.y + 50;
				_parent:AddChild(_this);
			end
			_parent.visible = true;

			local last_text = ParaEngine.GetWindowText();
			local tip_text = L"开始录制 ";
			if(last_text~=tip_text) then
				VideoSharing.last_text = last_text;
				ParaEngine.SetWindowText(tip_text);
			end
			VideoSharing.start_time = ParaGlobal.timeGetTime();

			VideoSharing.tail_timer = VideoSharing.tail_timer or commonlib.Timer:new({callbackFunc = function(timer)
				local elapsed_time = ParaGlobal.timeGetTime() - VideoSharing.start_time;
				local alpha = (1 - ((VideoSharingSettings.total_time-1.2) * 1000 - elapsed_time) / 1000) * 255;
				if (alpha > 220) then
					alpha = 255
				end
				if (alpha > 192) then
					_parent:GetChild("tail_text1").visible = true;
					_parent:GetChild("tail_text2").visible = true;
				end
				local tail = _parent:GetChild("mask_tail");
				tail.visible = true;
				tail.colormask = "0 0 0 "..alpha;
				tail:ApplyAnim();
			end});

			VideoSharing.show_tail = false;
			VideoSharing.title_timer = VideoSharing.title_timer or commonlib.Timer:new({callbackFunc = function(timer)
				local elapsed_time = ParaGlobal.timeGetTime() - VideoSharing.start_time;
				local h,m,s = commonlib.timehelp.SecondsToHMS(elapsed_time/1000);
				local strTime = string.format(L"正在录制中: %02d:%02d (%02d秒后自动停止)", m, math.floor(s), VideoSharingSettings.total_time);
				ParaEngine.SetWindowText(strTime);
				if ((not VideoSharing.show_tail) and elapsed_time >= (VideoSharingSettings.total_time-2) * 1000) then
					VideoSharing.show_tail = true;
					VideoSharing.tail_timer:Change(0, 100);
				end
				if (elapsed_time >= (VideoSharingSettings.total_time) * 1000) then
					VideoSharing.EndCapture(true);
				end
			end})
			if (VideoSharingSettings.total_time == 10 or VideoSharingSettings.total_time == 30) then
				VideoSharing.title_timer:Change(1000,500);
			end

			_parent:GetChild("logo").visible = VideoSharingSettings.IsShowLogo();

			local border_cont = _parent:GetChild("border");

			if(ParaMovie.IsRecording()) then
				border_cont.colormask = "255 0 0 192";
				border_cont:ApplyAnim();
			else
				border_cont.colormask = "0 255 0 192";
				border_cont:ApplyAnim();
			end

		end
	end
end
