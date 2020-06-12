--[[
Title: video sharing upload
Author(s): 
Date: 
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingUpload.lua");
local VideoSharingUpload = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingUpload");
VideoSharingUpload.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharing.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.share.lua");
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local StorageFilesApi = NPL.load("(gl)Mod/WorldShare/api/Storage/Files.lua")
local QiniuRootApi = NPL.load("(gl)Mod/WorldShare/api/Qiniu/Root.lua")
local VideoSharing = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharing");
local VideoSharingUpload = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingUpload");
local QREncode = commonlib.gettable("MyCompany.Aries.Game.Movie.QREncode");

--local download_tip_url = "http://dev.kp-para.cn/p/video-share/";
local download_tip_url = "https://keepwork.com/p/video-share/";

local page;
function VideoSharingUpload.OnInit()
	page = document:GetPageCtrl();
end

function VideoSharingUpload.ShowPage(condition)
	VideoSharingUpload.result = nil;
	VideoSharingUpload.start_after_seconds = nil;
	condition = condition or "?name=ready"
	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/VideoSharingUpload.html"..condition, 
		name = "VideoSharingUpload.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		click_through = false, 
		bShow = true,
		isTopLevel = true,
		zorder = 0,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ct",
			x = -200,
			y = -160,
			width = 400,
			height = 320,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function VideoSharingUpload.OnClose()
	if (VideoSharingUpload.QRCodeWnd) then
		VideoSharingUpload.QRCodeWnd:Hide();
	end
	page:CloseWindow();
end

function VideoSharingUpload.OnOK()
	if (not KeepworkService:IsSignedIn()) then
		LoginModal:ShowPage();
		return;
	end
	local upload_timer = commonlib.Timer:new({callbackFunc = function(timer)
		keepwork.shareToken.get({cache_policy = "access plus 12 hour", share = "video_share"},function(err, msg, data)
			if (err ~= 200 or (not data.data) or (not data.data.token) or (not data.data.key)) then
				VideoSharingUpload.UploadFailed("keepwork.shareToken", err, data);
				return;
			end

			local file_path = VideoSharing.GetOutputFile();
			local file = ParaIO.open(file_path, "rb");
			if (not file:IsValid()) then
				file:close();
				VideoSharingUpload.UploadFailed("open file", -1, {filename = file_path});
				return;
			end
			local content = file:GetText(0, -1);
			file:close();

			if not content then
				VideoSharingUpload.UploadFailed("read file", -1, {filename = file_path});
				return;
			end

			local token = data.data.token;
			local key = data.data.key;
			local file_name = commonlib.Encoding.DefaultToUtf8(ParaIO.GetFileName(file_path));
			QiniuRootApi:Upload(
				token,
				key,
				file_name,
				content,
				function(result, err)
					if err ~= 200 then
						VideoSharingUpload.UploadFailed("QiniuRootApi:Upload", err, result);
						return;
					end

					keepwork.shareUrl.get({cache_policy = "access plus 0", key = key}, function(err, msg, data)
						if (err ~= 200 or (not data.data)) then
							VideoSharingUpload.UploadFailed("keepwork.shareUrl", err, data);
							return;
						end
						VideoSharingUpload.ShowQRCode(data.data.."&attname="..file_name);
					end);

					keepwork.shareFile.post({key = key}, function(err, msg, data)
						LOG.std(nil, "info", "VideoSharingUpload", "%s: {error: %s, data: %s}", "keepwork.shareFile", tostring(err), commonlib.serialize(data));
					end);
				end
			)
		end)
	end});
	upload_timer:Change(100, nil);
	page:CloseWindow();
	VideoSharingUpload.ShowPage("?name=upload");
end

function VideoSharingUpload.UploadFailed(stage, error, data)
	LOG.std(nil, "info", "VideoSharingUpload", "%s: {error: %s, data: %s}", stage, tostring(error), commonlib.serialize(data));
	page:CloseWindow();
	VideoSharingUpload.ShowPage("?name=error");
end

function VideoSharingUpload.ShowQRCode(url)
	url = download_tip_url..commonlib.Encoding.url_encode(url);
	local ok, result = QREncode.qrcode(url);
	if (not ok) then
		VideoSharingUpload.UploadFailed("QRCode", -1, {info = "url to qrcode error"});
		return;
	end

	VideoSharingUpload.qrcode = result;
	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QRCodeWnd.lua");
	VideoSharingUpload.QRCodeWnd = commonlib.gettable("MyCompany.Aries.Game.Movie.QRCodeWnd");
	VideoSharingUpload.QRCodeWnd:Show();

	page:CloseWindow();
	VideoSharingUpload.ShowPage("?name=finish");
end
