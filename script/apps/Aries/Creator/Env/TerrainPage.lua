--[[
Title: Environment Terrain page
Author(s): LiXizhi
Date: 2010/1/26
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Env/TerrainPage.lua");
------------------------------------------------------------
]]

local TerrainPage = commonlib.gettable("MyCompany.Aries.Creator.TerrainPage")
local TerraPaintPage = commonlib.gettable("MyCompany.Aries.Creator.TerraPaintPage")
local TerraFormPage = commonlib.gettable("MyCompany.Aries.Creator.TerraFormPage")
local ToolTipsPage = commonlib.gettable("MyCompany.Aries.Creator.ToolTipsPage")

TerrainPage.Name = "TerrainPage";

-- called to init page
function TerrainPage.OnInit()
	self = TerrainPage;
	local Page = document:GetPageCtrl();
	Page.OnClose = TerrainPage.OnClose;
	self.page = Page;
	
	-- change tab page according to url parameter
	local tabpage = Page:GetRequestParam("tab");
    if(tabpage and tabpage~="") then
        Page:SetValue("TerraTabs", tabpage);
    end
end

-- reset all 3d marker
function TerrainPage.Reset3DHook()
	if(type(TerraPaintPage.OnClose) == "function") then
		TerraPaintPage.OnClose()
	end	
	if(type(TerraFormPage.OnClose) == "function") then
		TerraFormPage.OnClose()
	end	
end

function TerrainPage.OnClickPaintTab()
	TerrainPage.Reset3DHook()
	ToolTipsPage.ShowPage("terra_paint");
end

function TerrainPage.OnClickFormTab()
	TerrainPage.Reset3DHook()
	ToolTipsPage.ShowPage("terra_form");
end


function TerrainPage.OnClose()
	TerrainPage.Reset3DHook();
end

