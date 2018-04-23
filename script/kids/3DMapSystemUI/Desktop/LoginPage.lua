--[[
Title: code behind page for LoginPage.html (OBSOLETED: use inline script instead)
Author(s): LiXizhi
Date: 2008/4/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/LoginPage.lua");
-------------------------------------------------------
]]

local LoginPage = {};
commonlib.setfield("Map3DSystem.UI.Desktop.LoginPage", LoginPage)

---------------------------------
-- page event handlers
---------------------------------

-- first time init page
function LoginPage.OnInit()
	local self = document:GetPageCtrl();
	self:SetNodeValue("username", Map3DSystem.User.Name);
	self:SetNodeValue("password", Map3DSystem.User.Password);
end
