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
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local StorageFilesApi = NPL.load("(gl)Mod/WorldShare/api/Storage/Files.lua")
local QiniuRootApi = NPL.load("(gl)Mod/WorldShare/api/Qiniu/Root.lua")
local VideoSharing = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharing");
local VideoSharingUpload = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingUpload");
local QREncode = commonlib.gettable("MyCompany.Aries.Game.Movie.QREncode");

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
		allowDrag = true,
		click_through = false, 
		bShow = true,
		isTopLevel = true,
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
		local file_path = VideoSharing.GetOutputFile();
		StorageFilesApi:Token(file_path, function(data, err)
			commonlib.echo(data);
			if not data.token or not data.key then
				VideoSharingUpload.UploadFailed();
				return false;
			end

			local file = ParaIO.open(file_path, "rb");
			if (not file:IsValid()) then
				file:close();
				VideoSharingUpload.UploadFailed();
				return false;
			end
			local content = file:GetText(0, -1);
			file:close();

			if not content then
				VideoSharingUpload.UploadFailed();
				return false;
			end

			QiniuRootApi:Upload(
				data.token,
				data.key,
				ParaIO.GetFileName(file_path),
				content,
				function(_, err)
					if err ~= 200 then
						VideoSharingUpload.UploadFailed();
						return false;
					end

					StorageFilesApi:List(function(listData, err)
						if listData and type(listData.data) ~= 'table' then
							VideoSharingUpload.UploadFailed();
							return false
						end

						for key, item in ipairs(listData.data) do
							if item.key == data.key then
								if item.downloadUrl then
									VideoSharingUpload.ShowQRCode(item.downloadUrl.."&attname="..ParaIO.GetFileName(file_path));
									return true
								end
							end
						end

						VideoSharingUpload.UploadFailed();
					end)
				end
			)
		end)
	end});
	upload_timer:Change(100, nil);
	VideoSharingUpload.ShowPage("?name=upload");
end

function VideoSharingUpload.UploadFailed()
	commonlib.echo("failed");
end

function VideoSharingUpload.ShowQRCode(url)
	local ok, result = QREncode.qrcode(url);
	if (not ok) then
		VideoSharingUpload.UploadFailed();
		return;
	end

	VideoSharingUpload.qrcode = result;
	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QRCodeWnd.lua");
	VideoSharingUpload.QRCodeWnd = commonlib.gettable("MyCompany.Aries.Game.Movie.QRCodeWnd");
	VideoSharingUpload.QRCodeWnd:Show();

	VideoSharingUpload.ShowPage("?name=finish");
end
