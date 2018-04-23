--[[
Title: world info page
Author(s): LiXizhi
Date: 2008/6/9
Desc: 
it takes worldpath as parameter like 
<verbatim>
	script/kids/3DMapSystemApp/worlds/WorldInfoPage.html?worldpath=worlds/MyWorlds/abc
</verbatim>
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/WorldInfoPage.lua");
-------------------------------------------------------
]]

-- create class
local WorldInfoPage = {};
commonlib.setfield("Map3DSystem.App.worlds.WorldInfoPage", WorldInfoPage)

function WorldInfoPage.OnInit()
	local page = document:GetPageCtrl();
	local worldpath = page:GetRequestParam("worldpath");
	if(worldpath) then
		local worldname = string.match(worldpath, "(%w+)$");
		page:SetNodeValue("worldname", worldname)
		local previewimage = worldpath.."/preview.jpg";
		if(ParaIO.DoesFileExist(previewimage, true)) then
			page:SetNodeValue("previewimage", previewimage)
		end
	end
end