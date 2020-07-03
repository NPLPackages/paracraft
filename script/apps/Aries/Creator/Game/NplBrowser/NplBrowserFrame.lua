--[[
Title: NplBrowserFrame
Author(s): leio
Date: 2020/6/24
Desc: 
use the lib:
------------------------------------------------------------
local NplBrowserFrame = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserFrame.lua");
NplBrowserFrame:Show("https://keepwork.com", "title", false, true);

NplBrowserFrame:Show("https://keepwork.com", "title", true, true, { left = 100, top = 50, right = 100, bottom = 50});
NplBrowserFrame:Show("https://keepwork.com", "title", false, false, { left = 100, top = 50, right = 100, bottom = 50, fixed = true, });
NplBrowserFrame:Show("https://keepwork.com", "title", true, true, { left = 100, top = 50, right = 100, bottom = 50, fixed = true, candrag = true, });

NplBrowserFrame:Goto("https://keepwork.com/zhanglei/empty/index")

-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplBrowserFrame = commonlib.inherit(nil,NPL.export());


function NplBrowserFrame:ctor()
    self.name = nil;
    self.mcml_url = "script/apps/Aries/Creator/Game/NplBrowser/NplBrowserFrame.html";
    self.options = {
	    left = 0,
	    top = 0,
	    right = 0,
	    bottom = 0,
    };
    self.min_w = 960;
    self.min_h = 560;
    self.page = nil;
    self.ui_obj = nil;
    self.width = nil;
    self.height = nil;
    self.title = "";
    self.url = nil;
    self.default_url = "https://keepwork.com";
    self.is_show_control = true;
    self.is_show_close = true;
    self.browser_name = nil;
    self.callback = nil; -- fire "ONSHOW" or "ONCLOSE" or "ONRESIZE"

    self.cef_is_preshow = false;
end
function NplBrowserFrame:OnInit(name)
    self.name = name;
    self.browser_name = string.format("NplBrowserFrame_browser_instance_%s",self.name);
    return self;
end
function NplBrowserFrame:CefIsCreated()
    return self.cef_is_created;
end
function NplBrowserFrame:PreShow(url, is_show_control)
    local id = self.browser_name;
	url = url or self.default_url;
    if(not self.cef_is_preshow)then
        NplBrowserPlugin.Start({id = id, url = url, withControl = is_show_control, x = 10000, y = 10000, width = 1, height = 1, });
        self.cef_is_preshow = true
    end
end
function NplBrowserFrame:Show(url, title, is_show_control, is_show_close, options, callback)
	url = url or self.default_url;
    self.title = title;
    self.is_show_control = is_show_control;
    self.is_show_close = is_show_close;
    self.options = options or self.options;
    
    self.callback = callback;
	NplBrowserLoaderPage.Check(function(result) 		
	if(result)then
		self:_Show(url);
	end
	end);
end
function NplBrowserFrame:_Show(url)
	local name = self.name;
	local url_changed = false;
	if(url ~= self.url)then
		url_changed = true;
		self.url = url;
	end

    local candrag = false
    local zorder = self.options.zorder or 1000;
    if(self.options.candrag)then
        candrag = true;
    end
    local _this = self:GetUIObject();
	if(not _this) then
		local width, height  = self:CalculateSize();
		if (self.options.autoscale and self.options.resizefunc) then
			width, height  = self.options.resizefunc();
		end
		self.width = width;
		self.height = height;
		_this = ParaUI.CreateUIObject("container", name, "_ct", -width / 2, -height / 2, width, height);
		_this.background="";
        _this.candrag = candrag;
		_this:SetScript("onsize", function()
			self:OnResize();
		end)

        _this:SetScript("ondragmove", function(ui_obj)
			self.is_draging = true;
		    local x, y = ui_obj:GetAbsPosition();
            if(x<0) then x=0; end
		    if(y<0) then y=0; end
            self.drag_x = x;
            self.drag_y = y;
	    end);
	    _this:SetScript("ondragend", function(ui_obj)
			self.is_draging = false;
            local x = self.drag_x;
            local y = self.drag_y;
		    if(x<0) then x=0; end
		    if(y<0) then y=0; end

		    --_this:Reposition("_lt", x, y, self.width, self.height)
			local _1, _2, w, h = ParaUI.GetUIObject("root"):GetAbsPosition();
			local left = (w - self.width)/2;
			local top = (h - self.height)/2;
			_this:Reposition("_ct", -self.width/2+x-left, -self.height/2+y-top, self.width, self.height);
	    end);

		_this:SetScript("onclick", function() end); -- just disable click through 
		_guihelper.SetFontColor(_this, "#ffffff");
		_this:AttachToRoot();
        -- added a parameter 'name' to could be found in NplBrowserManager
        local mcml_url = string.format("%s?name=%s",self.mcml_url,self.name);
		local page = System.mcml.PageCtrl:new({
			url = mcml_url
		});
		page:Create(name.."page", _this, "_fi", 0, 0, 0, 0);

		self.page = page;
	end

	if(_this and self.page)then
		_this.visible = true;
        _this.candrag = candrag;
		_this.zorder = zorder;
		self.page:CallMethod(self.browser_name, "SetVisible", true); 
		if(url_changed)then
			self.page:CallMethod(self.browser_name, "Reload", self.url); 
			self.page:Refresh(0);
		end	
	end
    if(self.callback)then
        self.callback("ONSHOW");
    end
end
function NplBrowserFrame:CalculateSize()
	local x, y, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
    local options = self.options;
	local left = options.left or 0;
	local top = options.top or 0;
	local right = options.right or 0;
	local bottom = options.bottom or 0;

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
function NplBrowserFrame:GetUIObject()
	local _this = ParaUI.GetUIObject(self.name);
	if(_this:IsValid()) then
		return _this;
	end
end
function NplBrowserFrame:Close_Internal()
    local obj = self:GetUIObject();
	if(obj) then
		obj.visible = false;
		self.page:CallMethod(self.browser_name, "SetVisible", false); 
	end
end
function NplBrowserFrame:Close()
    self:Close_Internal();
    if(self.callback)then
        self.callback("ONCLOSE");
    end
end
function NplBrowserFrame:IsVisible()
	local obj = self:GetUIObject();
	if(obj) then
		return obj.visible;
	end
end
function NplBrowserFrame:OnResize()
	local function Resize(width, height)
		if(self.width ~= width or self.height ~= height)then
			self.width = width;
			self.height = height;

			local _this = self:GetUIObject();
			_this:Reposition("_ct", -width / 2, -height / 2, width, height);
			self.page:Refresh(0);
            if(self.callback)then
			    self.callback("ONRESIZE");
            end
		end
	end
	if (self.is_draging) then
		return;
	end
	if (self.options.autoscale and self.options.resizefunc) then
		local width, height  = self.options.resizefunc();
		Resize(width, height);
		return;
	end
    if(self.options.fixed or self.options.candrag)then
        return
    end
	local width, height  = self:CalculateSize();
	Resize(width, height);
end
function NplBrowserFrame:GetTitle()
	return self.title;
end
function NplBrowserFrame:GetUrl()
	return self.url;
end
function NplBrowserFrame:GetName()
	return self.name;
end
function NplBrowserFrame:GetBrowserName()
	return self.browser_name;
end
function NplBrowserFrame:IsShowControl()
	return self.is_show_control;
end
function NplBrowserFrame:CanClose()
	return self.is_show_close;
end
function NplBrowserFrame:Goto(url)
    url = url or self.url;
    self.url = url;
    if(self.page)then
	    self.page:CallMethod(self.browser_name, "Reload", url); 
    end
end
function NplBrowserFrame:GotoEmpty()
    local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
    local url = NplBrowserManager.empty_html;
    self:Goto(url);
    commonlib.TimerManager.SetTimeout(function()  
		ParaUI.GetUIObject("root"):Focus();
	end, 1000)
end
