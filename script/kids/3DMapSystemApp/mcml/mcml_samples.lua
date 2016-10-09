--[[
Title: sample MCML code used by ParaWorld
Author(s): LiXizhi
Date: 2008/3/18
Desc: MCML is used in various places in ParaWorld's social user interface. Here we present a few MCML code samples.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_samples.lua");
-- this file is for documentation purposes only. 
%TESTCASE{"MCMLExamples", func="commonlib.NPLDocGen.GenerateTWikiTopic", input={WikiWord = "MCMLExamples", ClassName = "MCML Examples", input = {"script/kids/3DMapSystemApp/mcml/mcml_samples.lua"},}}%
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/NPLDocGen.lua");

-- MCML for front page login 
-- @code: script/kids/3DMapSystemUI/Desktop/LoginPage.html
-- @code: script/kids/3DMapSystemApp/Login/StartPage.html
function Login()
end

-- MCML for user registration
-- @code: script/kids/3DMapSystemApp/Login/NewUserRegPage.html
-- @code: script/kids/3DMapSystemApp/profiles/AvatarRegPage.html
-- @code: script/kids/3DMapSystemApp/profiles/ProfileRegPage.html
-- @code: script/kids/3DMapSystemApp/profiles/MapRegPage.html
function UserRegistration()
end

-- test cases used when developing MCML 
-- @code: script/kids/3DMapSystemApp/mcml/test/browser.xml
-- @code: script/kids/3DMapSystemApp/mcml/test/dlg_layoutflow.xml
-- @code: script/kids/3DMapSystemApp/mcml/test/dlg_tabs.xml
function MCML_Testcases()
end