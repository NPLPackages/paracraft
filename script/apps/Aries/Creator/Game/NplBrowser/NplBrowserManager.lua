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

NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Goto("https://keepwork.com/zhanglei/empty/index")
NplBrowserManager:CreateOrGet("DailyCheckBrowser"):GotoEmpty()
-------------------------------------------------------
]]
local NplBrowserFrame = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserFrame.lua");
local NplBrowserManager = NPL.export();
NplBrowserManager.empty_html = "https://keepwork.com/zhanglei/empty/index"
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

-- preload a given window to a given url, so it is faster to show later. 
-- @param url: default to empty page. 
function NplBrowserManager:PreShowWnd(wndName, url)
	NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
	local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
	if(NplBrowserLoaderPage.IsLoaded()) then
		NplBrowserManager:CreateOrGet(wndName):PreShow(url or NplBrowserManager.empty_html, false);
	else
		self.preShowList = self.preShowList or {}
		if(self.preShowList[wndName]==nil) then
			self.preShowList[wndName] = url or NplBrowserManager.empty_html;
		end
		NplBrowserLoaderPage.CheckOnce()
	end
end

function NplBrowserManager:LoadAllPreShowWindows()
	if(self.preShowList) then
		for wnd, url in pairs(self.preShowList) do
			if(url) then
				NplBrowserManager:CreateOrGet(wnd):PreShow(url, false);
				self.preShowList[wnd] = false;
			end
		end
	end
end