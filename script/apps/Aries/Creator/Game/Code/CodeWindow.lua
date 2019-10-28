--[[
Title: a 2d window for use in code block
Author(s): LiXizhi
Date: 2019/10/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeWindow.lua");
local CodeWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeWindow")
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeContext2d.lua");
local CodeContext2d = commonlib.gettable("MyCompany.Aries.Game.Code.CodeContext2d")

local CodeWindow = commonlib.inherit(commonlib.gettable("System.Windows.Window"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeWindow"));
CodeWindow:Signal("mousePressEventReceived")
CodeWindow:Signal("mouseMoveEventReceived")
CodeWindow:Signal("mouseReleaseEventReceived")

function CodeWindow:ctor()
	self.isContextPrepared = false;
end

function CodeWindow:SetCodeBlock(codeblock)
	self.codeblock = codeblock
end

function CodeWindow:prepareCodeContext()
	if(self.context2d) then
		return
	end
	self:EnableSelfPaint(true);
	self:SetAutoClearBackground(false);

	self.context2d = CodeContext2d:new();
	self.context2d:SetWindow(self);
	self.context2d:clearRect();
end

-- @param name: default to "2d"
function CodeWindow:getContext(name)
	self:prepareCodeContext()
	return self.context2d;
end

-- only for use in code block API
-- @param eventName: "onmousedown", "onmouseup", "onmousemove"
function CodeWindow:registerEvent(eventName, callback)
	if(eventName == "onmousedown") then
		self:Connect("mousePressEventReceived", callback)
	elseif(eventName == "onmouseup") then
		self:Connect("mouseReleaseEventReceived", callback)
	elseif(eventName == "onmousemove") then
		self:Connect("mouseMoveEventReceived", callback)
	end
end

-- refresh page control
function CodeWindow:Refresh(delay)
	if(self.page) then
		self.page:Refresh(delay);
	end
end

-- get page
function CodeWindow:GetPage()
	return self.page;
end

-- virtual: just save the page object
function CodeWindow:LoadComponent(url)
	local page, _ = CodeWindow._super.LoadComponent(self, url);	
	self.page = page;
	return page, _;
end

-- @param event_type: "mousePressEvent", "mouseMoveEvent", "mouseWheelEvent", "mouseReleaseEvent"
function CodeWindow:handleMouseEvent(event)
	local event_type = event:GetType();
	if(event_type == "mousePressEvent") then
		self:mousePressEventReceived(event);
	elseif(event_type == "mouseMoveEvent") then
		self:mouseMoveEventReceived(event);
	elseif(event_type == "mouseReleaseEvent") then
		self:mouseReleaseEventReceived(event);
	end
	CodeWindow._super.handleMouseEvent(self, event);
end

-- virtual
function CodeWindow:Render(painterContext)
	if(self.context2d) then
		local ok, msg = pcall(self.context2d.Render, self.context2d, painterContext)
		if(not ok and msg) then
			painterContext:DrawText(0,0, "error in painting");
			painterContext:DrawText(0,20, msg);
		end
	end
	return CodeWindow._super.Render(self, painterContext);
end
