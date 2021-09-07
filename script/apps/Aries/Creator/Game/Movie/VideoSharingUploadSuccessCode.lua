--[[
	author:pbb
	date:
	Desc:
	use lib:
	local VideoSharingUploadSuccessCode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingUploadSuccessCode.lua") 
	VideoSharingUploadSuccessCode.ShowView()
]]
local QREncode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
local VideoSharingUploadSuccessCode = NPL.export()

local page = nil
function VideoSharingUploadSuccessCode.OnInit()
	page = document:GetPageCtrl();
	page.Create = VideoSharingUploadSuccessCode.OnCreate()
end

function VideoSharingUploadSuccessCode.ShowView(url)
	VideoSharingUploadSuccessCode.GernerreateQRCode(url)
	local view_width = 420
	local view_height = 425
	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/VideoSharingUploadSuccessCode.html",
		name = "VideoSharingUploadSuccessCode.ShowView", 
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

function VideoSharingUploadSuccessCode.GernerreateQRCode(url)
	if url then
		local ok, result = QREncode.qrcode(url);
		if (not ok) then
			_guihelper.MessageBox("生成二维码失败")
			return;
		end
		VideoSharingUploadSuccessCode.qrcode = result
	end	
end

function VideoSharingUploadSuccessCode.OnCreate()
    local parent  = page:GetParentUIObject()
    local qrcode_width = 192
    local qrcode_height = 192
    local block_size = qrcode_width / #VideoSharingUploadSuccessCode.qrcode
    local qrcode = ParaUI.CreateUIObject("container", "vipshare_video_code", "_lt", 110, 156, qrcode_width, qrcode_height);
    qrcode:SetField("OwnerDraw", true); -- enable owner draw paint event
    qrcode:SetField("SelfPaint", true);
    qrcode:SetScript("ondraw", function(test)
        for i = 1, #(VideoSharingUploadSuccessCode.qrcode) do
            for j = 1, #(VideoSharingUploadSuccessCode.qrcode[i]) do
                local code = VideoSharingUploadSuccessCode.qrcode[i][j];
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