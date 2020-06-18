--[[
Title: NplBrowserPage
Author(s): leio
Date: 2019.3.24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPage.lua");
local NplBrowserPage = commonlib.gettable("NplBrowser.NplBrowserPage");
NplBrowserPage.Open();
NplBrowserPage.Open("test","www.keepwork.com","title",nil,"_ct",100,100,400,600, nil, nil, function()
    commonlib.echo("============onclose");
end);

NplBrowserPage.Goto("test", "https://keepwork.com/zhanglei/empty/index")
- NplBrowserPlugin
https://github.com/tatfook/NplBrowser
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");

local NplBrowserPage = commonlib.inherit(nil,commonlib.gettable("NplBrowser.NplBrowserPage"));

NplBrowserPage.width = 800;
NplBrowserPage.height = 560;
NplBrowserPage.default_window_name = "NplBrowserWindow_Instance";
NplBrowserPage.default_template_url = "script/apps/Aries/Creator/Game/NplBrowser/pe_nplbrowser_template.html";
NplBrowserPage.default_url = "www.keepwork.com";
NplBrowserPage.pages_map= {}; -- hold window's name and NplBrowserPage instance
function NplBrowserPage.CheckNumber(v)
    if(v == nil)then
        return
    end
    if(type(v) == "string")then
        v = tonumber(v);
    end
    return v;
end
-- Create a cef window.
-- @param name:an unique window's name, default value is "NplBrowserWindow_Instance".
-- @param url:a web address which will be opened by cef window.
-- @param title: the title of window
-- @param withControl: true show control bar
-- @param alignment:window's alignment,default value is "_ct" which means center top alignment. "_lt" may be a common choice, it means left top alignment.
-- @param x:window's x coordinates. the original point locate at left top corner.
-- @param x:window's y coordinates. the original point locate at left top corner.
-- @param width:window's width.
-- @param height:window's height.
-- @param window_template_url:a mcml page which rendering the style of cef window, default value is "Mod/NplBrowser/pe_nplbrowser_template.html"
-- @param zorder:the show level of Window,default value is 10001.
-- @param callback: callback function for close
function NplBrowserPage:Create(name, url, title, withControl, alignment, x, y, width, height, window_template_url, zorder, callback)
    url = url or NplBrowserPage.default_url;
	name = name or NplBrowserPage.default_window_name;
	zorder = zorder or 10001;
	alignment = alignment or "_ct";
	width = NplBrowserPage.CheckNumber(width) or NplBrowserPage.width;
	height = NplBrowserPage.CheckNumber(height) or NplBrowserPage.height

	x = NplBrowserPage.CheckNumber(x) or -width/2;
	y = NplBrowserPage.CheckNumber(y) or -height/2;
		
	window_template_url = window_template_url or NplBrowserPage.default_template_url;

    self.name = name;
    self.url = url;
    self.title = title;
    self.withControl = withControl;
    self.callback = callback;
    local params = {
		url = window_template_url, 
		name = name, 
		app_key=MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = false, -- prevent many ViewProfile pages staying in memory
		bToggleShowHide = true,
		enable_esc_key = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		zorder = zorder,
		directPosition = true,
			align = alignment,
			x = x,
			y = y,
			width = width,
			height = height,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
    self.params = params;

    local pageCtrl = params._page;

    NplBrowserPlugin.OnCreatedCallback("nplbrowser_instance", function()
        if(self.pageCtrl)then
            self.pageCtrl:Refresh(0);
            self:Reload();
        end
    end)
    if(pageCtrl)then
        self.pageCtrl = pageCtrl;
        NplBrowserPage.pages_map[name] = self;
        pageCtrl.npl_browser_page = self;
        pageCtrl.OnClose = function()
            self:SetVisible(false)
        end

        -- make pe_nplbrowser_template.html can find himself
        pageCtrl:Refresh(0);
        self:Reload();
    end
    return self;
end
function NplBrowserPage.Goto(name, url)
    if(not name)then
        return
    end
    local npl_browser_page = NplBrowserPage.GetPage(name);
    if(npl_browser_page)then
        npl_browser_page:Reload(url)
    end
end
-- Create or open a cef window after download resources
function NplBrowserPage.Open(name, url, title, withControl, alignment, x, y, width, height, window_template_url, zorder)
    NplBrowserLoaderPage.Check(function(result)
        if(result)then
	        name = name or NplBrowserPage.default_window_name;
            local npl_browser_page = NplBrowserPage.GetPage(name);
            
            if(not npl_browser_page)then
                NplBrowserPage:new():Create(name, url, title, withControl, alignment, x, y, width, height, window_template_url, zorder)
            else
                npl_browser_page:Close()
                npl_browser_page.url = url;
                npl_browser_page.title = title;
                local params = npl_browser_page.params;
                System.App.Commands.Call("File.MCMLWindowFrame", params);	
                npl_browser_page:SetVisible(true);
                npl_browser_page:Reload();
            end
        end
    end)
end
function NplBrowserPage:Reload(url)
    url = url or self.url
    if(self.pageCtrl)then
        self.pageCtrl:CallMethod("nplbrowser_instance", "Reload", url); 
    end
end
function NplBrowserPage:SetVisible(b)
    if(self.pageCtrl)then
        self.pageCtrl:CallMethod("nplbrowser_instance", "SetVisible", b); 
    end
end
function NplBrowserPage:Close()
	self:SetVisible(false)
    if(self.pageCtrl)then
		self.pageCtrl:CloseWindow(); 
    end
    if(self.callback)then
        self.callback();
    end
end
-- get the instance of NplBrowserPage
function NplBrowserPage.GetPage(name)
    if(not name)then
        return
    end
    return NplBrowserPage.pages_map[name];
end



