--[[
Title: test all mcml design tags
Author(s): LiXizhi
Date: 2008/3/10
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/test/test_mcmlBrowser.lua");
test.test_mcmlBrowser()
-------------------------------------------------------
]]
if(not test) then test={} end 

log("mcmlBrowser Test case loaded\n");

-- test passed by LiXizhi on 2008.3.10
-- %TESTCASE{"MCML browser window", func="test.test_mcmlBrowser", input = {url="script/kids/3DMapSystemApp/mcml/test/browser.xml", DisplayNavBar = true}}%
function test.test_mcmlBrowser(input)
	input = input or {url="script/kids/3DMapSystemApp/mcml/test/browser.xml", DisplayNavBar = true}
	NPL.load("(gl)script/kids/3DMapSystemApp/mcml/BrowserWnd.lua");
	local ctl = Map3DSystem.mcml.BrowserWnd:new{
		name = "McmlBrowserWnd1",
		alignment = "_lt",
		left=0, top=0,
		width = 512,
		height = 512,
		DisplayNavBar = input.DisplayNavBar,
		parent = nil,
	};
	ctl:Show();
	ctl:Goto(input.url);
end

