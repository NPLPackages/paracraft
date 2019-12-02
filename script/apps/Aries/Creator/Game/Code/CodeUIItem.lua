--[[
Title: Code UI Item
Author(s): LiXizhi
Date: 2018/6/17
Desc: a display unit of code UI. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeUIItem.lua");
local CodeUIItem = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUIItem");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UITextElement.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeGlobals.lua");
local CodeGlobals = commonlib.gettable("MyCompany.Aries.Game.Code.CodeGlobals");
local CodeUIItem = commonlib.inherit(commonlib.gettable("System.Windows.UITextElement"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeUIItem"));

CodeUIItem:Property({"Color", "#000000"});
CodeUIItem:Property({"title", nil, "GetTitle", "SetTitle", auto=true});
CodeUIItem:Property({"BackgroundColor", "#ffffff", auto=true});
CodeUIItem:Property({"padding_left", 5, });
CodeUIItem:Property({"padding_top", 5, });
CodeUIItem:Property({"padding_right", 5, });
CodeUIItem:Property({"padding_bottom", 5, });
-- left top and no clipping
CodeUIItem:Property({"Alignment", 32+256, auto=true, desc="text alignment"});
CodeUIItem:Property({"globalVariableName", nil, "GetGlobalVariableName", "SetGlobalVariableName", auto=true});

function CodeUIItem:ctor()
end

function CodeUIItem:Init(name, codeUI)
	self.name = name;
	self.codeUI = codeUI;
	self:SetFontSize(14);
	return self;
end

function CodeUIItem:GetText()
	return "test";
end

-- automatically hide variable if code is unloaded
function CodeUIItem:TrackCodeBlock(codeblock)
	if(self.codeblock ~= codeblock) then
		if(self.codeblock) then
			self.codeblock:Disconnect("codeUnloaded", self, self.OnCodeUnloaded);
		end
		if(codeblock) then
			codeblock:Connect("codeUnloaded", self, self.OnCodeUnloaded, "UniqueConnection");
		end
		self.codeblock = codeblock;
	end
end

function CodeUIItem:GetCodeBlock()
	return self.codeblock;
end

function CodeUIItem:OnCodeUnloaded()
	if(self.codeUI) then
		self.codeUI:RemoveItem(self.name);
	end
end

function CodeUIItem:paintEvent(painter)
	local name = self:GetGlobalVariableName();
	local text;
	if(name) then
		if(self.codeblock) then
			-- we will try the containing codeblock's globals
			text = self.codeblock:GetCodeEnv()[name];
		else
			text = GameLogic.GetCodeGlobal():GetGlobal(name);
		end
		
		
		if(type(text) == "table") then
			text = commonlib.serialize_in_length(text, 100);
		else
			text = tostring(text);
		end
		local title = self:GetTitle();
		if(title and title ~="") then
			text = format("%s: %s", title, text or "");
		end
	end

	local x, y = self:x(), self:y();
	text = text or self:GetText();
	if(text and text~="") then
		painter:SetFont(self:GetFont());
		painter:SetPen(self:GetColor());
		self:DrawTextScaledEx(painter, x+self.padding_left, y+self.padding_top, self:width()-self.padding_left-self.padding_right, self:height()-self.padding_top-self.padding_bottom, text, self:GetAlignment(), self:GetFontScaling());
	end
end