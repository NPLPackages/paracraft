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
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplBrowserPage = commonlib.gettable("NplBrowser.NplBrowserPage");

NplBrowserPage.width = 800;
NplBrowserPage.height = 560;
NplBrowserPage.default_window_name = "NplBrowserWindow_Instance";
NplBrowserPage.default_template_url = "script/apps/Aries/Creator/Game/NplBrowser/pe_nplbrowser_template.html";
NplBrowserPage.default_url = "www.keepwork.com";
NplBrowserPage.url = nil;
NplBrowserPage.is_show = false;
function NplBrowserPage.Init()
    NplBrowserPage.pageCtrl= document:GetPageCtrl();
end

function NplBrowserPage.Open(name, url, alignment, x, y, width, height, window_template_url, zorder)
    NplBrowserLoaderPage.Check(function(result)
        if(result)then
            NplBrowserPage._Open(name, url, alignment, x, y, width, height, window_template_url, zorder)
        end
    end)
end
-- Create or open a cef window.
-- @param name:an unique window's name, default value is "NplBrowserWindow_Instance".
-- @param url:a web address which will be opened by cef window.
-- @param alignment:window's alignment,default value is "_ct" which means center top alignment. "_lt" may be a common choice, it means left top alignment.
-- @param x:window's x coordinates. the original point locate at left top corner.
-- @param x:window's y coordinates. the original point locate at left top corner.
-- @param width:window's width.
-- @param height:window's height.
-- @param window_template_url:a mcml page which rendering the style of cef window, default value is "Mod/NplBrowser/pe_nplbrowser_template.html"
-- @param zorder:the show level of Window,default value is 10001.
function NplBrowserPage._Open(name, url, alignment, x, y, width, height, window_template_url, zorder)
    NplBrowserPage.url = url or NplBrowserPage.default_url;
	name = name or NplBrowserPage.default_window_name;
	zorder = zorder or 10001;
	alignment = alignment or "_ct";
	width = width or NplBrowserPage.width;
	height = height or NplBrowserPage.height

	x = x or -width/2;
	y = y or -height/2;
		
	window_template_url = window_template_url or NplBrowserPage.default_template_url;
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

    params._page.OnClose = function()
        NplBrowserPage.SetVisible(false)
    end
    local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
        NplBrowserPage.SetVisible(NplBrowserPage.pageCtrl:IsVisible())
	end})
	mytimer:Change(500)
end
function NplBrowserPage.SetVisible(b)
    if(NplBrowserPage.pageCtrl)then
        NplBrowserPage.pageCtrl:CallMethod("nplbrowser_instance", "SetVisible", b); 
    end
end



