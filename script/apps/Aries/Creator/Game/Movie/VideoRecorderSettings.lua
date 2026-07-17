--[[
Title: video recording settings
Author(s): LiXizhi
Date: 2014/5/21
Desc: video recording settings. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorderSettings.lua");
local VideoRecorderSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorderSettings");
VideoRecorderSettings.ShowPage(function(settings)
end);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");
local VideoRecorderSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorderSettings");

local settings = {
	Codec="mp4",
	VideoResolution={640, 480},
	VideoBitRate = 1200000, 
	FPS = 25, 
	filename="temp.mp4",
	-- default to windows desktop
	folder=ParaIO.GetCurDirectory(13), -- "Screen Shots/",
	isRecordAudio = true,
	isShowLogo = true,
	margin = 16,
};

local presets = {
	["mp4"]	= {
		Codec="mp4",
		VideoResolution={640, 480},
		VideoBitRate = 1200000, 
		FPS = 25, 
		margin = 16,
		stereo = 0,
	},
	-- there must be a space after mp4, since codec extension is deduced from key name. 
	["mp4 560p"] = {
		Codec="mp4",
		VideoResolution={960, 560},
		VideoBitRate = 2400000, 
		FPS = 25, 
		margin = 16,
		stereo = 0,
	},
	-- there must be a space after mp4, since codec extension is deduced from key name. 
	["mp4 720p"] = {
		Codec="mp4",
		VideoResolution={1280, 720},
		VideoBitRate = 5120000, 
		FPS = 30, 
		margin = 16,
		stereo = 0,
	},
	["auto video share"] = {
		Codec="mp4",
		VideoResolution={960, 720},
		VideoBitRate = 5120000, 
		FPS = 60, 
		margin = 0,
		stereo = 0,
	},
	-- there must be a space after mp4, since codec extension is deduced from key name. 
	["mp4 1080p"] = {
		Codec="mp4",
		VideoResolution={1920, 1080},
		VideoBitRate = 7776000, 
		FPS = 30, 
		margin = 16,
		stereo = 0,
	},
	["mp4 stereo"] = {
		Codec="mp4",
		VideoResolution={1280, 720},
		VideoBitRate = 2400000, 
		FPS = 25, 
		margin = 0,
		stereo = 2, -- stereo mode:left and right eye
	},
	-- ["mp4 ODS 2k"] = {
	-- 	Codec="mp4",
	-- 	VideoResolution={2048, 2048},
	-- 	VideoBitRate = 51608000, 
	-- 	FPS = 60, 
	-- 	margin = 0,
	-- 	stereo = 6,
	-- 	preset_stereo = 6,
	-- 	widthPerDegree = 2,
	-- },
	-- ["mp4 ODS 1280P"] = {
	-- 	Codec="mp4",
	-- 	VideoResolution={1280, 1280},
	-- 	VideoBitRate = 51608000, 
	-- 	FPS = 60, 
	-- 	margin = 0,
	-- 	stereo = 6,
	-- 	preset_stereo = 6,
	-- 	widthPerDegree = 2,
	-- 	checkboxShader = false,
	-- },
	["mp4 ODS single eye"] = {
		Codec="mp4",
		VideoResolution={2160, 1080},
		VideoBitRate = 51608000, 
		FPS = 60, 
		margin = 0,
		stereo = 8,
		preset_stereo = 8,
		widthPerDegree = 540,
		checkboxShader = false,
	},
	["mp4 ODS single eye macro"] = {
		Codec="mp4",
		VideoResolution={1280, 1280},
		VideoBitRate = 51608000, 
		FPS = 60, 
		margin = 0,
		stereo = 8,
		preset_stereo = 8,
		widthPerDegree = 2,--横向，每个角度2像素
		checkboxShader = false,
	},
	["flv"]	= {
		Codec="flv",
		VideoResolution={640, 480},
		VideoBitRate = 800000, 
		FPS = 25, 
		margin = 16,
		stereo = 0,
	},
	["gif"]	= {
		Codec="gif",
		VideoResolution={320, 240},
		VideoBitRate = 400000, 
		FPS = 15, 
		margin = 16,
		stereo = 0,
	},
	["avi"]	= {
		Codec="avi",
		VideoResolution={640, 480},
		VideoBitRate = 800000, 
		FPS = 25, 
		margin = 16,
		stereo = 0,
	},
	["mov"]	= {
		Codec="mov",
		VideoResolution={640, 480},
		VideoBitRate = 800000, 
		FPS = 25, 
		margin = 16,
		stereo = 0,
	},
	-- ["mp3"]	= {
	-- 	Codec="mp3",
	-- 	VideoResolution={640, 480},
	-- 	VideoBitRate = 0, 
	-- 	FPS = 60, 
	-- 	margin = 16,
	-- 	stereo = 0,
	-- },
}

local page;
function VideoRecorderSettings.OnInit()
	page = document:GetPageCtrl();
end

-- @param OnClose: function(result, values) end 
-- result is "ok" is user clicks the OK button. 
function VideoRecorderSettings.ShowPage(OnClose)
	VideoRecorderSettings.result = nil;
	VideoRecorderSettings.start_after_seconds = nil;
	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/VideoRecorderSettings.html", 
		name = "VideoRecorderSettings.ShowPage", 
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
			height = 360,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if(VideoRecorderSettings.last_preset) then
		page:SetValue("Preset", VideoRecorderSettings.last_preset);
	end
	VideoRecorderSettings.UpdateUIFromSettings();

	params._page.OnClose = function()
		if(OnClose) then
			OnClose(VideoRecorderSettings.result, settings);
		end
	end
end

function VideoRecorderSettings.SetFPS(fps)
	settings.FPS = fps or 25;
end

function VideoRecorderSettings.GetFPS()
	return settings.FPS or 25;
end

function VideoRecorderSettings.GetResolution()
	return settings.VideoResolution;
end

function VideoRecorderSettings.SetResolution(resolution)
	settings.VideoResolution = resolution;
end

function VideoRecorderSettings.GetVideoBitRate()
	return settings.VideoBitRate;
end

function VideoRecorderSettings.GetCodec()
	return settings.Codec;
end

function VideoRecorderSettings.GetCodecExtension()
	return settings.Codec;
end

function VideoRecorderSettings.GetStereoMode()
	return settings.stereo or 0;
end

function VideoRecorderSettings.GetOdsWidthPerDegree()
	return settings.widthPerDegree or nil;
end

function VideoRecorderSettings.SetOutputFloder(folder)
	if folder==nil then
		return
	end
	if ParaIO.DoesFileExist(folder) then
		settings.folder = folder
	end
end

function VideoRecorderSettings.GetOutputFilepath()
	local path = format("%s%s.%s", settings.folder, VideoRecorderSettings.GetOutputFilename(), VideoRecorderSettings.GetCodecExtension())
	print("GetOutputFilepath",path)
	echo(settings,true)
	return format("%s%s.%s", settings.folder, VideoRecorderSettings.GetOutputFilename(), VideoRecorderSettings.GetCodecExtension());
end

function VideoRecorderSettings.SetOutputFilename(filename)
	VideoRecorderSettings.filename = filename
end

function VideoRecorderSettings.GetOutputFilename()
	if VideoRecorderSettings.filename then
		return VideoRecorderSettings.filename
	end
	local dir = ParaWorld.GetWorldDirectory();
	local folder_name = dir:match("([^\\/]+)[\\/]$");
	folder_name = folder_name or "movie";
	return folder_name;
end

function VideoRecorderSettings.IsRecordAudio()
	return settings.isRecordAudio == true;
end

function VideoRecorderSettings.IsShowLogo()
	if System.options.isShenzhenAi5 then
		return false;
	end
	return settings.isShowLogo == true;
end

function VideoRecorderSettings.OnReset()
	VideoRecorderSettings.SetPreset("mp4");
end

function VideoRecorderSettings.SetMargin(margin)
	if (not margin or type(margin) ~= "number") then
		return;
	end

	settings.margin = margin;
end

function VideoRecorderSettings.GetMargin()
	return settings.margin or 16;
end

function VideoRecorderSettings.SetMarginRect(margin)
	if (not margin or type(margin) ~= "table") then
		return;
	end

	settings.marginRect = margin;
end

function VideoRecorderSettings.GetMarginRect()
	local ret = settings.marginRect;
	settings.marginRect = nil
	return  ret;
end

function VideoRecorderSettings.UpdateUIFromSettings()
	if(page) then
		local VideoResolution;
		if(settings.VideoResolution[1]) then
			VideoResolution = format("%d*%d", settings.VideoResolution[1],settings.VideoResolution[2])
		else
			VideoResolution = "current";
		end
		page:SetValue("VideoResolution", VideoResolution);
		page:SetValue("VideoBitRate", tostring(settings.VideoBitRate));
		page:SetValue("FPS", tostring(settings.FPS));
		page:SetValue("filename", commonlib.Encoding.DefaultToUtf8(VideoRecorderSettings.GetOutputFilepath()));
		page:SetValue("IsRecordAudio", VideoRecorderSettings.IsRecordAudio());
		page:SetValue("IsShowLogo", VideoRecorderSettings.IsShowLogo());
		page:SetValue("safemargin", tostring(VideoRecorderSettings.GetMargin()));
		page:SetValue("stereomode", VideoRecorderSettings.GetStereoMode()~=0);
		page:SetValue("lockCameraDist", tostring(VideoRecorderSettings.GetLockCameraDist()));
		page:SetValue("isLockCameraUpDir", VideoRecorderSettings.GetIsLockCameraUpDir());
		page:SetValue("isIgnoreUI", VideoRecorderSettings.GetIsIgnoreUI());
		if settings.checkboxShader==false then
			page:SetValue("checkboxShader", false);
		end
	end
end

function VideoRecorderSettings.UpdateUIToSettings()
	if(page) then
		local codec = page:GetValue("Preset", nil)
		if(codec) then
			codec = codec:match("^(%S+)");
			settings.Codec = codec;
		end

		local videores = page:GetValue("VideoResolution", nil)
		if(videores) then
			local width, height = videores:match("(%d+)%D+(%d+)")
			if(width and height) then
				settings.VideoResolution[1] = tonumber(width);
				settings.VideoResolution[2] = tonumber(height);
			else
				-- use current resolution, round to multiple of 4
				NPL.load("(gl)script/ide/System/Windows/Screen.lua");
				local Screen = commonlib.gettable("System.Windows.Screen");
				settings.VideoResolution[1] = math.floor(Screen:GetWidth()/4)*4;
				settings.VideoResolution[2] = math.floor(Screen:GetHeight()/4)*4;
			end
		end
		
		local VideoBitRate = page:GetValue("VideoBitRate", nil)
		if(VideoBitRate) then
			settings.VideoBitRate = tonumber(VideoBitRate);
		end

		local FPS = page:GetValue("FPS", nil)
		if(FPS) then
			settings.FPS = tonumber(FPS);
		end
		local IsRecordAudio = page:GetUIValue("IsRecordAudio", true)
		settings.isRecordAudio = IsRecordAudio;

		local IsShowLogo = page:GetUIValue("IsShowLogo", true)
		settings.isShowLogo = IsShowLogo;

		local margin = page:GetValue("safemargin", nil)
		if(margin) then
			settings.margin = tonumber(margin);
		end

		settings.stereo = if_else(page:GetValue("stereomode", nil), settings.preset_stereo,0);

		settings.isLockCameraUpDir = page:GetUIValue("isLockCameraUpDir", true)
		settings.isIgnoreUI = page:GetUIValue("isIgnoreUI", false)
		settings.lockCameraDist = tonumber(page:GetValue("lockCameraDist", nil))
	end
end

function VideoRecorderSettings.OnClose()
	page:CloseWindow();
end

function VideoRecorderSettings.SetPreset(value)
	if(presets[value]) then
		commonlib.partialcopy(settings, presets[value]);
		VideoRecorderSettings.UpdateUIFromSettings();
	end
end

function VideoRecorderSettings.IsOdsStereo()
    return VideoRecorderSettings.last_preset=="mp4 ODS single eye" or VideoRecorderSettings.last_preset=="mp4 ODS single eye macro"
end

--全景模式下，是否锁死摄像机俯仰角为0
function VideoRecorderSettings.GetIsLockCameraUpDir()
	return settings.isLockCameraUpDir or true
end

--全景模式下，录屏时是否忽略UI
function VideoRecorderSettings.GetIsIgnoreUI()
	return settings.isIgnoreUI or false
end

--全景模式下，是否锁死摄像机距离，0表示不锁死
function VideoRecorderSettings.GetLockCameraDist()
	return tonumber(settings.lockCameraDist) or 20
end

function VideoRecorderSettings.OnSelectPreset(name, value)
	VideoRecorderSettings.last_preset = value;
	if page then
		page:Refresh(0)
	end
	VideoRecorderSettings.SetPreset(value);
end

function VideoRecorderSettings.OnOpenOutputFolder()
	Map3DSystem.App.Commands.Call("File.WinExplorer", settings.folder);
end

function VideoRecorderSettings.OnStartAfterThreeSecond()
	VideoRecorderSettings.start_after_seconds = 3;
	VideoRecorderSettings.OnOK();
end

function VideoRecorderSettings.OnOK()
	if(page) then
		VideoRecorderSettings.UpdateUIToSettings();
		VideoRecorderSettings.result = "ok";
		page:CloseWindow();
	end
end

function VideoRecorderSettings.GetAbsoluteOutputFolder()
	local folder = settings.folder;
	if(not folder:match(":")) then
		folder = ParaIO.GetCurDirectory(0)..folder;
		folder = folder:gsub("/", "\\");
		return folder;
	else
		return folder;
	end
end

function VideoRecorderSettings.OnClickSelectOutputFolder()
	
	ParaEngine.GetAttributeObject():SetField("OpenFileFolder", VideoRecorderSettings.GetAbsoluteOutputFolder());
	local folder = ParaEngine.GetAttributeObject():GetField("OpenFileFolder", "");
	if(folder and folder~="" ) then
		if(not folder:match("/\\$")) then
			folder = folder.."\\";
		end
		if(settings.folder ~= folder) then
			settings.folder = folder;
			if page then
				page:Refresh(0)
			end
			VideoRecorderSettings.UpdateUIFromSettings();
		end
	end
end
