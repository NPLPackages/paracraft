--[[
Title: NplBrowserManager
Author(s): leio
Date: 2020/6/24
Desc: 
use the lib:
------------------------------------------------------------
local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
NplBrowserManager:PreShowAll();
NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show("https://keepwork.com", "title", false, true);
NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show("https://keepwork.com", "title", true, true, { left = 100, top = 50, right = 100, bottom = 50});
NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show("https://keepwork.com", "title", false, false, { left = 100, top = 50, right = 100, bottom = 50, fixed = true, });
NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show("https://keepwork.com", "title", true, true, { left = 100, top = 50, right = 100, bottom = 50, fixed = true, candrag = true, });

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
-- previous to load cef3 exe 
function NplBrowserManager:PreShowAll()
    NplBrowserManager:CreateOrGet("DailyCheckBrowser"):PreShow(NplBrowserManager.empty_html, false);
    NplBrowserManager:CreateOrGet("TeachingQuest_BrowserPage"):PreShow(NplBrowserManager.empty_html, false);
end