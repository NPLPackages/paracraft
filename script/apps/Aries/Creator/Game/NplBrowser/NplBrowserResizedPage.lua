--[[
Title: NplBrowserResizedPage
Author(s): leio
Date: 2020/5/15
Desc: 
use the lib:
------------------------------------------------------------
local NplBrowserResizedPage = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserResizedPage.lua");
NplBrowserResizedPage:Show("https://keepwork.com", "title", false, true);

NplBrowserResizedPage:Show("https://keepwork.com", "title", true, true, { left = 100, top = 50, right = 100, bottom = 50;});
NplBrowserResizedPage:Show("https://keepwork.com", "title", false, false, { left = 100, top = 50, right = 100, bottom = 50;});

-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplBrowserResizedPage = NPL.export();

NplBrowserResizedPage.name = "NplBrowserResizedPage_instance";
NplBrowserResizedPage.mcml_url = "script/apps/Aries/Creator/Game/NplBrowser/NplBrowserResizedPage.html";
NplBrowserResizedPage.padding_options = {
	left = 0,
	top = 0,
	right = 0,
	bottom = 0,
};
NplBrowserResizedPage.min_w = 960;
NplBrowserResizedPage.min_h = 560;
NplBrowserResizedPage.page = nil;
NplBrowserResizedPage.ui_obj = nil;
NplBrowserResizedPage.width = nil;
NplBrowserResizedPage.height = nil;
NplBrowserResizedPage.title = "";
NplBrowserResizedPage.url = nil;
NplBrowserResizedPage.default_url = "https://keepwork.com";
NplBrowserResizedPage.is_show_control = true;
NplBrowserResizedPage.is_show_close = true;
NplBrowserResizedPage.browser_name = "NplBrowserResizedPage_browser_instance";
NplBrowserResizedPage.callback = nil; -- fire "ONSHOW" or "ONCLOSE" or "ONRESIZE"
function NplBrowserResizedPage:Show(url, title, is_show_control, is_show_close, padding_options,callback)
	url = url or NplBrowserResizedPage.default_url;
    self.title = title;
    self.is_show_control = is_show_control;
    self.is_show_close = is_show_close;
    self.padding_options = padding_options or self.padding_options;
    self.callback = callback;
	NplBrowserLoaderPage.Check(function(result) 		
	if(result)then
		self:_Show(url);
	end
	end);
end
function NplBrowserResizedPage:_Show(url)
	local name = self.name;
	local url_changed = false;
	if(url ~= self.url)then
		url_changed = true;
		self.url = url;
	end

    local _this = self:GetUIObject();
	if(not _this) then
		local width, height  = self:CalculateSize();
		self.width = width;
		self.height = height;
		_this = ParaUI.CreateUIObject("container", name, "_ct", -width / 2, -height / 2, width, height);
		_this.zorder = -2;
		_this.background="";
		_this:SetScript("onsize", function()
			self:OnResize();
		end)

		_this:SetScript("onclick", function() end); -- just disable click through 
		_guihelper.SetFontColor(_this, "#ffffff");
		_this:AttachToRoot();
		local page = System.mcml.PageCtrl:new({
			url= self.mcml_url
		});
		page:Create(name.."page", _this, "_fi", 0, 0, 0, 0);

		self.page = page;
	end
	if(_this and self.page)then
		_this.visible = true;
		self.page:CallMethod(self.browser_name, "SetVisible", true); 
		if(url_changed)then
			self.page:CallMethod(self.browser_name, "Reload", self.url); 
		end	
	end
    self.callback("ONSHOW");
end
function NplBrowserResizedPage:CalculateSize()
	local x, y, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
    local padding_options = self.padding_options;
	local left = padding_options.left or 0;
	local top = padding_options.top or 0;
	local right = padding_options.right or 0;
	local bottom = padding_options.bottom or 0;

	local w = width - left - right;
	local h = height - top - bottom;
	
	if(w < self.min_w)then
		w = self.min_w
	end
	if(h < self.min_h)then
		h = self.min_h
	end
	return w,h;
end
function NplBrowserResizedPage:GetUIObject()
	local _this = ParaUI.GetUIObject(self.name);
	if(_this:IsValid()) then
		return _this;
	end
end
function NplBrowserResizedPage:Close()
    local obj = self:GetUIObject();
	if(obj) then
		obj.visible = false;
		self.page:CallMethod(self.browser_name, "SetVisible", false); 
        if(self.callback)then
            self.callback("ONCLOSE");
        end
	end
end
function NplBrowserResizedPage:IsVisible()
	local obj = self:GetUIObject();
	if(obj) then
		return obj.visible;
	end
end
function NplBrowserResizedPage:OnResize()
	local width, height  = self:CalculateSize();
	if(self.width ~= width or self.height ~= height)then
		self.width = width;
		self.height = height;

		local _this = self:GetUIObject();
		_this:Reposition("_ct", -width / 2, -height / 2, width, height);
		self.page:Refresh(0);
        self.callback("ONRESIZE");
	end
end
function NplBrowserResizedPage:GetTitle()
	return self.title;
end
function NplBrowserResizedPage:GetUrl()
	return self.url;
end
function NplBrowserResizedPage:IsShowControl()
	return self.is_show_control;
end
function NplBrowserResizedPage:CanClose()
	return self.is_show_close;
end

