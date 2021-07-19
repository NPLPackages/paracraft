--[[
Title: NplBrowserManager
Author(s): leio
Date: 2020/6/24
Desc: 
use the lib:
------------------------------------------------------------
local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
NplBrowserManager:PreShowWnd(wndName, url)
NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show("https://keepwork.com", "title", false, true);
NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show("https://keepwork.com", "title", true, true, { left = 100, top = 50, right = 100, bottom = 50});
NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show("https://keepwork.com", "title", false, false, { left = 100, top = 50, right = 100, bottom = 50, fixed = true, });
NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show("https://keepwork.com", "title", true, true, { left = 100, top = 50, right = 100, bottom = 50, fixed = true, candrag = true, });

NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show("https://keepwork.com", "title", true, true, { scale_screen = "4:3:v", });

NplBrowserManager:CreateOrGet("DailyCheckBrowser"):GotoEmpty()
-------------------------------------------------------
]]
local NplBrowserFrame = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserFrame.lua");
local NplBrowserManager = NPL.export();
NplBrowserManager.browser_pages = {};
function NplBrowserManager:CreateOrGet(name)
    if(not name)then
        return
    end
    local browser_page = self.browser_pages[name];
    if(not browser_page)then
        browser_page = NplBrowserFrame:new():OnInit(name);
        self.browser_pages[name] = browser_page;
    end
    return browser_page;
end
function NplBrowserManager:CloseAll()
    for k,v in pairs(self.browser_pages) do
        v:Close();
    end
end
-- pre loading cef3 window
-- @param {table} list: window list
-- @param {string} list.name
-- @param {string} list.url
-- @param {bool} list.is_show_control
function NplBrowserManager:PreLoadWindows(list)
	NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
	local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
	NPL.load("(gl)script/ide/timer.lua");
	list = list or {};

	local function loadingAll(list)
		for k, v in ipairs(list) do
			local name = v.name;
			local url = v.url or "";
			local is_show_control = v.is_show_control;
			NplBrowserManager:CreateOrGet(name):PreShow(url, is_show_control);
		end
	end
	if(NplBrowserLoaderPage.IsLoaded()) then
		loadingAll(list);
	else
		NplBrowserLoaderPage.CheckOnce();
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			loadingAll(list);
		end})
		mytimer:Change(5000, nil)
	end
end
