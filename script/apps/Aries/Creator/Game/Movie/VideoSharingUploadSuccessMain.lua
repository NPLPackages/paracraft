--[[
	author:pbb
	date:
	Desc:
	use lib:
	local VideoSharingUploadSuccessMain = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingUploadSuccessMain.lua") 
	VideoSharingUploadSuccessMain.ShowView()
]]
local QREncode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
local VideoSharingUploadSuccessMain = NPL.export()

local page = nil
function VideoSharingUploadSuccessMain.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = VideoSharingUploadSuccessMain.OnCreate()
end

function VideoSharingUploadSuccessMain.ShowView(url)
	VideoSharingUploadSuccessMain.GernerreateQRCode(url)
	local view_width = 710
	local view_height = 460
	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/VideoSharingUploadSuccessMain.html",
		name = "VideoSharingUploadSuccessMain.ShowView", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		zorder = 0,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
		directPosition = true,
		align = "_ct",
			x = -view_width/2,
			y = -view_height/2,
			width = view_width,
			height = view_height,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function VideoSharingUploadSuccessMain.GernerreateQRCode(url)
	if url then
		local ok, result = QREncode.qrcode(url);
		if (not ok) then
			_guihelper.MessageBox("生成二维码失败")
			return;
		end
		VideoSharingUploadSuccessMain.qrcode = result
	end	
end

function VideoSharingUploadSuccessMain.SetVideoCdnUrl(url)
	if url then
		VideoSharingUploadSuccessMain.cndUrl = url
	end
end

function VideoSharingUploadSuccessMain.OnCreate()
    local parent  = page:GetParentUIObject()
    local qrcode_width = 192
    local qrcode_height = 192
    local block_size = qrcode_width / #VideoSharingUploadSuccessMain.qrcode
    local qrcode = ParaUI.CreateUIObject("container", "vipshare_video_main", "_lt", 256, 220, qrcode_width, qrcode_height);
    qrcode:SetField("OwnerDraw", true); -- enable owner draw paint event
    qrcode:SetField("SelfPaint", true);
    qrcode:SetScript("ondraw", function(test)
        for i = 1, #(VideoSharingUploadSuccessMain.qrcode) do
            for j = 1, #(VideoSharingUploadSuccessMain.qrcode[i]) do
                local code = VideoSharingUploadSuccessMain.qrcode[i][j];
                if (code < 0) then
                    ParaPainter.SetPen("#000000ff");
                    ParaPainter.DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
                end
            end
        end
        
    end);
	qrcode.zorder = 6
    parent:AddChild(qrcode);
end