--[[
Title: video recorder
Author(s): LiXizhi
Date: 2014/5/15
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");
VideoRecorder.ToggleRecording();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorderSettings.lua");
local VideoRecorderSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorderSettings");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");

local max_resolution = {4906, 2160};
local default_resolution = {640, 480};
local before_capture_resolution;
function VideoRecorder.ToggleRecording()
	if(ParaMovie.IsRecording()) then
		VideoRecorder.EndCapture();
	else
		VideoRecorder.BeginCapture();
	end
end

function VideoRecorder.OpenOutputDirectory()
	VideoRecorderSettings.OnOpenOutputFolder();
end

function VideoRecorder.GetCurrentVideoFileName()
	return VideoRecorderSettings.GetOutputFilepath(); 
end

function VideoRecorder.HasFFmpegPlugin()
	local attr = ParaMovie.GetAttributeObject();
	return attr:GetField("HasMoviePlugin",false);
end

-- @param callbackFunc: called when started. function(bSucceed) end
function VideoRecorder.BeginCapture(callbackFunc)
	if(VideoRecorder.HasFFmpegPlugin()) then
		VideoRecorderSettings.ShowPage(function(res)
			if(res == "ok") then
				VideoRecorder.AdjustWindowResolution(function()
					local start_after_seconds = VideoRecorderSettings.start_after_seconds or 0;
					local elapsed_seconds = 0;
					local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
						
						if(elapsed_seconds >= start_after_seconds) then
							timer:Change();
							BroadcastHelper.PushLabel({id="MovieRecord", label = "", max_duration=0, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
							GameLogic.options:SetClickToContinue(false);
							local attr = ParaMovie.GetAttributeObject();
							attr:SetField("RecordingFPS", VideoRecorderSettings.GetFPS())
							attr:SetField("VideoBitRate", VideoRecorderSettings.GetVideoBitRate())
							attr:SetField("CaptureAudio", VideoRecorderSettings.IsRecordAudio())
							local margin = VideoRecorderSettings.GetMargin() or 0;
							if(attr:GetField("StereoCaptureMode", 0)~=0) then
								margin = 0;
							elseif(VideoRecorderSettings.GetStereoMode() ~=0) then
								attr:SetField("StereoCaptureMode", VideoRecorderSettings.GetStereoMode());
								margin = 0;
							end
							attr:SetField("MarginLeft", margin);
							attr:SetField("MarginTop", margin);
							attr:SetField("MarginRight", margin);
							attr:SetField("MarginBottom", margin);
							ParaMovie.BeginCapture(VideoRecorderSettings.GetOutputFilepath())
							VideoRecorder.ShowRecordingArea(true);
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
			else
				if(callbackFunc) then
					callbackFunc(false);
				end
			end
		end);
	else
		_guihelper.MessageBox(L"你没有安装最新版的视频输出插件, 请到官方网站下载安装");
		if(callbackFunc) then
			callbackFunc(false);
		end
	end
end

function VideoRecorder.FrameCapture()
end

-- adjust window resolution
-- @param callbackFunc: function is called when window size is adjusted. 
function VideoRecorder.AdjustWindowResolution(callbackFunc)
	local att = ParaEngine.GetAttributeObject();
	local cur_resolution = att:GetField("WindowResolution", {400, 300}); 
	local preferred_resolution = VideoRecorderSettings.GetResolution();
	-- reserve place for render borders which indicates whether the screen is being recorded or not
	local margin = VideoRecorderSettings.GetMargin();
	preferred_resolution[1] = preferred_resolution[1] + margin*2;
	preferred_resolution[2] = preferred_resolution[2] + margin*2;
	if(cur_resolution[1] > max_resolution[1] or cur_resolution[2] > max_resolution[2]) then
		if(not preferred_resolution or not preferred_resolution[1]) then
			preferred_resolution = max_resolution;
		end
	end

	if(preferred_resolution and preferred_resolution[1]) then
		att:SetField("ScreenResolution", preferred_resolution); 
		att:CallField("UpdateScreenMode");
		before_capture_resolution = cur_resolution;
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			if(callbackFunc) then
				callbackFunc();
			end
		end})
		mytimer:Change(1000, nil);
	else
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			if(callbackFunc) then
				callbackFunc();
			end
		end})
		mytimer:Change(100, nil);
	end
end

function VideoRecorder.RestoreWindowResolution()
	if(before_capture_resolution) then
		local att = ParaEngine.GetAttributeObject();
		local cur_resolution = att:GetField("ScreenResolution", {400, 300}); 
		if(cur_resolution[1] < before_capture_resolution[1] or cur_resolution[2] < before_capture_resolution[2]) then
			att:SetField("ScreenResolution", before_capture_resolution); 
			att:CallField("UpdateScreenMode");
		end
		before_capture_resolution = nil;
	end
end

function VideoRecorder.EndCapture()
	ParaMovie.EndCapture();
	VideoRecorder.ShowRecordingArea(false);
	GameLogic.options:SetClickToContinue(true);
	VideoRecorder.RestoreWindowResolution();
end

function VideoRecorder.ShowRecordingArea(bShow)
	if(VideoRecorder.HasFFmpegPlugin()) then
		local _parent = ParaUI.GetUIObject("RecordSafeArea");
		if(not bShow) then
			if(_parent:IsValid()) then
				_parent.visible = false;
				ParaUI.Destroy(_parent.id);
			end
			if(VideoRecorder.title_timer) then
				VideoRecorder.title_timer:Change();
			end
			if(VideoRecorder.last_text) then
				ParaEngine.SetWindowText(VideoRecorder.last_text);
				VideoRecorder.last_text = nil;
			end
			return;
		else
			if(not _parent:IsValid()) then
				local attr = ParaMovie.GetAttributeObject();
				local margin_left, margin_top, margin_right, margin_bottom = attr:GetField("MarginLeft",0), attr:GetField("MarginTop",0), attr:GetField("MarginRight",0), attr:GetField("MarginBottom",0);
				local border_width = 2;
				_parent = ParaUI.CreateUIObject("container", "RecordSafeArea", "_fi", 0,0,0,0);
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
				
				local _this = ParaUI.CreateUIObject("container", "top", "_mb", 0, 0, 0, margin_bottom);
				_this.background = "Texture/whitedot.png";
				_this.enabled = false;
				_border:AddChild(_this);
				
				local _this = ParaUI.CreateUIObject("container", "logo", "_lt", margin_left+20, margin_top+20, 200, 103);
				_this.background = L"Texture/Aries/Creator/Login/ParaCraftMovieWaterMark.png;0 0 200 103";
				_this.enabled = false;
				_parent:AddChild(_this);
			end
			_parent.visible = true;

			local last_text = ParaEngine.GetWindowText();
			local tip_text = L"正在录制中: F9停止";
			if(last_text~=tip_text) then
				VideoRecorder.last_text = last_text;
				ParaEngine.SetWindowText(tip_text);
			end
			VideoRecorder.start_time = ParaGlobal.timeGetTime();
			VideoRecorder.title_timer = VideoRecorder.title_timer or commonlib.Timer:new({callbackFunc = function(timer)
				local elapsed_time = ParaGlobal.timeGetTime() - VideoRecorder.start_time;
				local h,m,s = commonlib.timehelp.SecondsToHMS(elapsed_time/1000);
				local strTime = string.format(L"正在录制中: %02d:%02d (F9停止)", m, math.floor(s));
				ParaEngine.SetWindowText(strTime);
			end})
			VideoRecorder.title_timer:Change(1000,1000);

			_parent:GetChild("logo").visible = VideoRecorderSettings.IsShowLogo();

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
