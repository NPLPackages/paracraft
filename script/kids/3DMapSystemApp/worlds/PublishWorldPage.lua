--[[
Title: publish world page
Author(s): LiXizhi
Date: 2008/6/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/PublishWorldPage.lua");
-------------------------------------------------------
]]

-- create class
local PublishWorldPage = {};
commonlib.setfield("Map3DSystem.App.worlds.PublishWorldPage", PublishWorldPage)

-- show the default category page. 
function PublishWorldPage.OnInit()
	local page = document:GetPageCtrl();
end
