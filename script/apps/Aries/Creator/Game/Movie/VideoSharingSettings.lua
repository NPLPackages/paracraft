--[[
Title: video recording settings
Author(s): LiXizhi
Date: 2014/5/21
Desc: video recording settings. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingSettings.lua");
local VideoSharingSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingSettings");
VideoSharingSettings.ShowPage(function(settings)
end);
-------------------------------------------------------
]]
local VideoSharingSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingSettings");
VideoSharingSettings.start_after_seconds = 0;

local settings = {
	Codec="mp4",
	VideoResolution={960, 560},
	VideoBitRate = 2400000, 
	FPS = 25, 
	filename="temp.mp4",
	-- default to windows desktop
	folder=ParaIO.GetCurDirectory(13), -- "Screen Shots/",
	isRecordAudio = true,
	isShowLogo = true,
	margin = 16,
	stereo = 0,
};

local page;
function VideoSharingSettings.OnInit()
	page = document:GetPageCtrl();
end

-- @param OnClose: function(result, values) end 
-- result is "ok" is user clicks the OK button. 
function VideoSharingSettings.ShowPage(OnClose)
	VideoSharingSettings.result = nil;
	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/VideoSharingSettings.html", 
		name = "VideoSharingSettings.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		isTopLevel = true,
		allowDrag = false,
		click_through = false, 
		enable_esc_key = true,
		bShow = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ct",
			x = -650/2,
			y = -390/2,
			width = 650,
			height = 390,
		cancelShowAnimation = true,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if(OnClose) then
			OnClose(VideoSharingSettings.result, settings);
		end
	end
end

function VideoSharingSettings.GetFPS()
	return settings.FPS or 25;
end

function VideoSharingSettings.GetResolution()
	return settings.VideoResolution;
end

function VideoSharingSettings.GetVideoBitRate()
	return settings.VideoBitRate;
end

function VideoSharingSettings.GetCodec()
	return settings.Codec;
end

function VideoSharingSettings.GetCodecExtension()
	return settings.Codec;
end

function VideoSharingSettings.GetStereoMode()
	return settings.stereo or 0;
end

function VideoSharingSettings.GetOutputFilepath()
	local date, hour = commonlib.timehelp.GetLocalTime();
	return format(L"%s%s_∂Ã ”∆µ_%s-%s.%s", settings.folder, VideoSharingSettings.GetOutputFilename(), date, hour, VideoSharingSettings.GetCodecExtension());
end

function VideoSharingSettings.GetOutputFilename()
	local dir = ParaWorld.GetWorldDirectory();
	local folder_name = dir:match("([^\\/]+)[\\/]$");
	folder_name = folder_name or "movie";
	return folder_name;
end

function VideoSharingSettings.IsRecordAudio()
	return settings.isRecordAudio == true;
end

function VideoSharingSettings.IsShowLogo()
	return settings.isShowLogo == true;
end

function VideoSharingSettings.GetMargin()
	return settings.margin or 16;
end

function VideoSharingSettings.OnClose()
	if (page) then
		page:CloseWindow();
	end
end

function VideoSharingSettings.OnOK()
	if(page) then
		VideoSharingSettings.result = "ok";
		page:CloseWindow();
	end
end

function VideoSharingSettings.OnClick10Seconds()
	VideoSharingSettings.start_after_seconds = 3;
	VideoSharingSettings.total_time = 10;
	VideoSharingSettings.OnOK();
end

function VideoSharingSettings.OnClick30Seconds()
	VideoSharingSettings.start_after_seconds = 3;
	VideoSharingSettings.total_time = 30;
	VideoSharingSettings.OnOK();
end