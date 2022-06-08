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

-- TODO: modify this if you updated the plugin
local download_url = "https://cdn.keepwork.com/paracraft/Mod/MovieCodecPluginV9.zip"
local download_version = "0.0.9";
-- this is the minimum version 
VideoRecorder.MIN_MOVIE_CODEC_PLUGIN_VERSION = 8;


local max_resolution = {4906, 2160};
local before_capture_resolution;

-- automatically download and install the plugin
function VideoRecorder.InstallPlugin(callbackFunc)
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

function VideoRecorder.ToggleRecording()
	if(ParaMovie.IsRecording()) then
		-- may be is recording in VideoSharing
		if (VideoRecorder.isRecording) then
			VideoRecorder.EndCapture();
		end
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

-- @return true if plugin is enabled, false if installed but can not be enabled, nil if not installed
function VideoRecorder.HasFFmpegPlugin()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
	local ModManager = commonlib.gettable("Mod.ModManager");
	local plugin = ModManager:GetMod("MovieCodecPlugin");
	if(plugin and plugin:GetVersion() >= VideoRecorder.MIN_MOVIE_CODEC_PLUGIN_VERSION) then
		local attr = ParaMovie.GetAttributeObject();
		return attr:GetField("HasMoviePlugin",false);
	end
end

function VideoRecorder.BeginCaptureImp()
end


-- @param callbackFunc: called when started. function(bSucceed) end
function VideoRecorder.BeginCapture(callbackFunc)
	if(VideoRecorder.HasFFmpegPlugin()) then
		VideoRecorderSettings.ShowPage(function(res)
			if(res == "ok") then
				VideoRecorder.isRecording = true;
				AudioEngine.SetGarbageCollectThreshold(99999);
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
	elseif(VideoRecorder.HasFFmpegPlugin()==false) then
		_guihelper.MessageBox(L"视频输出插件没有加载成功，请检查是否有其它客户端在使用")
	else
		_guihelper.MessageBox(L"你没有安装最新版的视频输出插件, 是否现在安装？", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				_guihelper.MessageBox(L"正在安装, 请稍候...");
				VideoRecorder.InstallPlugin(function(bSucceed)
					if(bSucceed) then
						_guihelper.MessageBox(nil);
						VideoRecorder.BeginCapture(callbackFunc)
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

function VideoRecorder.FrameCapture()
end

-- adjust window resolution
-- @param callbackFunc: function is called when window size is adjusted. 
function VideoRecorder.AdjustWindowResolution(callbackFunc)
	local att = ParaEngine.GetAttributeObject();
	local cur_resolution = att:GetField("ScreenResolution", {400, 300}); 
	local preferred_resolution = VideoRecorderSettings.GetResolution();
	
	-- reserve space in resolution for render borders which indicates whether the screen is being recorded or not
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
	
	-- restore resolution from margins that reserved for borders
	preferred_resolution[1] = preferred_resolution[1] - margin*2;
	preferred_resolution[2] = preferred_resolution[2] - margin*2;
	VideoRecorderSettings.SetResolution(preferred_resolution);
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
	AudioEngine.SetGarbageCollectThreshold(10);
	ParaMovie.EndCapture();
	VideoRecorder.ShowRecordingArea(false);
	GameLogic.options:SetClickToContinue(true);
	VideoRecorder.RestoreWindowResolution();
	VideoRecorder.isRecording = false;
end
--宇哥的需求，录制模式下不显示esc，记录原有的esc状态
VideoRecorder.IsShowEscDock = nil
function VideoRecorder.UpdateEscDock(bShow)
	local EscDock = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/EscDock.lua") 
	if VideoRecorder.IsShowEscDock  == nil then
		VideoRecorder.IsShowEscDock = EscDock.IsVisible() == true
	end
	if bShow then
		EscDock.ShowView(not bShow)
	else
		local isShow = VideoRecorder.IsShowEscDock ~= nil and VideoRecorder.IsShowEscDock or false
		EscDock.ShowView(isShow)
		VideoRecorder.IsShowEscDock = nil
	end
end


function VideoRecorder.ShowRecordingArea(bShow)
	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AsyncLoaderProgressBar.lua");
	local AsyncLoaderProgressBar = commonlib.gettable("Map3DSystem.App.Assets.AsyncLoaderProgressBar");
	if(VideoRecorder.HasFFmpegPlugin()) then
		local MiniWorldUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/MiniWorldUserInfo.lua");
		VideoRecorder.UpdateEscDock(bShow)
		local _parent = ParaUI.GetUIObject("RecordSafeArea");
		if(not bShow) then
			if(AsyncLoaderProgressBar.GetDefaultAssetBar()) then
				AsyncLoaderProgressBar.GetDefaultAssetBar():Show(true)
			end
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

			MiniWorldUserInfo.ShowTemporaryHide()
			return;
		else
			if(AsyncLoaderProgressBar.GetDefaultAssetBar()) then
				AsyncLoaderProgressBar.GetDefaultAssetBar():Show(false)
			end
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

			MiniWorldUserInfo.TemporaryHide()
		end
	end
end
