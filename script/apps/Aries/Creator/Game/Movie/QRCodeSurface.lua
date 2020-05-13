--[[
Title: 
Author(s): 
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QRCodeSurface.lua");
local QRCodeSurface = commonlib.gettable("Paracraft.Controls.QRCodeSurface");

-- it is important for the parent window to enable self paint and disable auto clear background. 
window:EnableSelfPaint(true);
window:SetAutoClearBackground(false);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharingUpload.lua");
local VideoSharingUpload = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharingUpload");

local QRCodeSurface = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("Paracraft.Controls.QRCodeSurface"));

function QRCodeSurface:ctor()
	self:ResetDrawProgress();
end

function QRCodeSurface:paintEvent(painter)
	if(self:width() <= 0) then
		return;
	end
	self:DrawBackground(painter);
	self:DrawSome(painter);
end

function QRCodeSurface:ResetDrawProgress()
	self.qrcode = VideoSharingUpload.qrcode;
	self.last_x, self.last_y = 0,0;
	if(self:width() > 0) then
		self.block_size = self:width() / #self.qrcode;
	end
end

function QRCodeSurface:Invalidate()
	self:ResetDrawProgress();
	self:repaint();
end


function QRCodeSurface:showEvent()
	self:Invalidate();
end

function QRCodeSurface:sizeEvent()
	self:Invalidate();
end

function QRCodeSurface:DrawBackground(painter)
	painter:SetPen("#ffffffff");
	painter:DrawRect(self:x(), self:y(), self:width(), self:height());
end

function QRCodeSurface:DrawSome(painter)
	local block_size = self.block_size;
	for i = 1, #(self.qrcode) do
		for j = 1, #(self.qrcode[i]) do
			local code = self.qrcode[i][j];
			if (code < 0) then
				painter:SetPen("#000000ff");
				painter:DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
			end
		end
	end
end
