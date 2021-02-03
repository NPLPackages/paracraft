--[[
Title: 
Author(s): 
Date: 
Desc: 
use the lib:
------------------------------------------------------------
-------------------------------------------------------
]]
local MacroCodeCampActIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampActIntro.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
local QREncode = commonlib.gettable("MyCompany.Aries.Game.Movie.QREncode");
local QRCodeView = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("WinterCamp.QRCodeView"));

function QRCodeView:ctor()
	self:ResetDrawProgress();
end

function QRCodeView:paintEvent(painter)
	if(self:width() <= 0) then
		return;
	end
	self:DrawBackground(painter);
	self:DrawSome(painter);
end

function QRCodeView:ResetDrawProgress()	
	local ok, result = QREncode.qrcode(MacroCodeCampActIntro.GetQRCodeUrl());
	if (not ok) then		
		return;
	end
	self.qrcode = result;
	self.last_x, self.last_y = 0,0;
	if(self:width() > 0) then
		self.block_size = self:width() / #self.qrcode;
	end
end

function QRCodeView:Invalidate()
	self:ResetDrawProgress();
	self:repaint();
end


function QRCodeView:showEvent()
	self:Invalidate();
end

function QRCodeView:sizeEvent()
	self:Invalidate();
end

function QRCodeView:DrawBackground(painter)
	painter:SetPen("#ffffffff");
	painter:DrawRect(self:x(), self:y(), self:width(), self:height());
end

function QRCodeView:DrawSome(painter)
	local block_size = self.block_size;
	for i = 1, #(self.qrcode) do
		for j = 1, #(self.qrcode[i]) do
			local code = self.qrcode[i][j];
			if (code < 0) then
				painter:SetPen("#000000ff"); --set pen color
				painter:DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
			end
		end
	end
end

function QRCodeView:DrawSomeWithRadius(painter)
	painter:Translate(72, 72);
	painter:Rotate(45 / math.pi * 180);
	painter:Translate(-72, -72);
	local block_size = self.block_size;
	for i = 1, #(self.qrcode) do
		for j = 1, #(self.qrcode[i]) do
			local code = self.qrcode[i][j];
			if (code < 0) then
				painter:SetPen("#fffffff"); --set pen color
				painter:DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
			end
		end
	end
	painter:Rotate(0);
end
