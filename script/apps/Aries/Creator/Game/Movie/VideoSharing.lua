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
local VideoSharingSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingSettings");
local VideoSharingUpload = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingUpload");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local VideoSharing = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharing");

-- TODO: modify this if you updated the plugin
local download_url = "https://cdn.keepwork.com/paracraft/Mod/MovieCodecPluginV9.zip"
local download_version = "0.0.9";
-- this is the minimum version 
VideoSharing.MIN_MOVIE_CODEC_PLUGIN_VERSION = 8;


local max_resolution = {4906, 2160};
local default_resolution = {640, 480};
local before_capture_resolution;

-- automatically download and install the plugin
function VideoSharing.InstallPlugin(callbackFunc)
	-- GameLogic.RunCommand("/install -mod https://keepwork.com/wiki/mod/packages/packages_install/paracraft?id=12")
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
	local ModManager = commonlib.gettable("Mod.ModManager");
	ModManager:GetLoader():InstallFromUrl(download_url, function(bSucceed, msg, package) 
		LOG.std(nil, "info", "CommandInstall", "bSucceed:  %s: %s", tostring(bSucceed), msg or "");
		if(bSucceed and package) then
			ModManager:GetLoader():SetPluginInfo(package.name, {
				url = download_url, 
				displayName = L"电影导出插件", 
				version = download_version,
				author = "lixizhi",
				packageId = 12, 
				homepage = "https://keepwork.com/wiki/mod/packages/packages_install/paracraft?id=12",
		        projectType = "paracraft",
			})
			ModManager:GetLoader():RebuildModuleList();
			ModManager:GetLoader():EnablePlugin(package.name, true, true);
			ModManager:GetLoader():SaveModTableToFile();
			ModManager:GetLoader():LoadPlugin(package.name);
			
		end
		if(callbackFunc) then
			callbackFunc(bSucceed);
		end
	end);
end

function VideoSharing.ToggleRecording(time)
	if (ParaMovie.IsRecording()) then
		VideoSharing.EndCapture(false);
		ParaIO.DeleteFile(VideoSharing.GetOutputFile());
	end
	VideoSharingSettings.total_time = time;
	VideoSharing.BeginCapture();
end

function VideoSharing.GetOutputFile()
	VideoSharing.output = VideoSharing.output or (VideoSharingSettings.GetOutputFilepath());
	return VideoSharing.output;
end

-- @return true if plugin is enabled, false if installed but can not be enabled, nil if not installed
function VideoSharing.HasFFmpegPlugin()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
	local ModManager = commonlib.gettable("Mod.ModManager");
	local plugin = ModManager:GetMod("MovieCodecPlugin");
	if(plugin and plugin:GetVersion() >= VideoSharing.MIN_MOVIE_CODEC_PLUGIN_VERSION) then
		local attr = ParaMovie.GetAttributeObject();
		return attr:GetField("HasMoviePlugin",false);
	end
end

-- @param callbackFunc: called when started. function(bSucceed) end
function VideoSharing.BeginCapture(callbackFunc)
	function startCapture()
		VideoSharing.output = nil;
		AudioEngine.SetGarbageCollectThreshold(99999);
		VideoSharing.AdjustWindowResolution(function()
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
	if(VideoSharing.HasFFmpegPlugin()) then
		if (VideoSharingSettings.total_time == 10 or VideoSharingSettings.total_time == 30) then
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
	elseif(VideoSharing.HasFFmpegPlugin()==false) then
		_guihelper.MessageBox(L"视频输出插件没有加载成功，请检查是否有其它客户端在使用")
	else
		_guihelper.MessageBox(L"你没有安装最新版的视频输出插件, 是否现在安装？", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				_guihelper.MessageBox(L"正在安装, 请稍后...");
				VideoSharing.InstallPlugin(function(bSucceed)
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

-- adjust window resolution
-- @param callbackFunc: function is called when window size is adjusted. 
function VideoSharing.AdjustWindowResolution(callbackFunc)
	local att = ParaEngine.GetAttributeObject();
	local cur_resolution = att:GetField("WindowResolution", {400, 300}); 
	local preferred_resolution = VideoSharingSettings.GetResolution();
	
	-- reserve space in resolution for render borders which indicates whether the screen is being recorded or not
	local margin = VideoSharingSettings.GetMargin();
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

function VideoSharing.RestoreWindowResolution()
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

function VideoSharing.EndCapture(showUpload)
	AudioEngine.SetGarbageCollectThreshold(10);
	ParaMovie.EndCapture();
	VideoSharing.ShowRecordingArea(false);
	GameLogic.options:SetClickToContinue(true);
	VideoSharing.RestoreWindowResolution();

	if (showUpload) then
		VideoSharingUpload.ShowPage();
	end
end

function VideoSharing.ShowRecordingArea(bShow)
	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AsyncLoaderProgressBar.lua");
	local AsyncLoaderProgressBar = commonlib.gettable("Map3DSystem.App.Assets.AsyncLoaderProgressBar");
	if(VideoSharing.HasFFmpegPlugin()) then
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
			VideoSharing.title_timer:Change(1000,500);

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
