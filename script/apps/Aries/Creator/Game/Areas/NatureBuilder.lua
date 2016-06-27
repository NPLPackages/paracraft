--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/NatureBuilder.lua");
local NatureBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.NatureBuilder");
NatureBuilder.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local NatureBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.NatureBuilder");

local page;
-- this is a value between [100-255]
local block_light_scale = 180;

NatureBuilder.has_real_terrain = "unknown";

function NatureBuilder.OnInit()
	page = document:GetPageCtrl();
	
	local color = ParaTerrain.GetBlockAttributeObject():GetField("BlockLightColor", GameLogic.options.BlockLightColor);
	page:SetNodeValue("BlockColorpicker", string.format("%d %d %d", color[1]*block_light_scale, color[2]*block_light_scale, color[3]*block_light_scale));
end

function NatureBuilder.ShowPage(bShow)
	
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/NatureBuilder.html", 
			name = "NatureBuilder.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_rb",
				x = -260,
				y = -550,
				width = 260,
				height = 450,
		});
	if(NatureBuilder.has_real_terrain ~= "unknown" and  GameLogic.options.has_real_terrain ~= NatureBuilder.has_real_terrain) then
		if(page) then
			LOG.std(nil, "debug", "NatureBuilder", "page rebuild")
			page:Rebuild();
		end
	end
	NatureBuilder.has_real_terrain = GameLogic.options.has_real_terrain;
end

function NatureBuilder.OnSkyColorChanged(r,g,b)
	MyCompany.Aries.Creator.SkyPage.OnFogColorChanged(r,g,b);
	MyCompany.Aries.Creator.SkyPage.OnSkyColorChanged(255,255,255);
end

function NatureBuilder.OnBlockColorChanged(r,g,b)
	if(r and g and b) then
		r = r/block_light_scale;
		g = g/block_light_scale;
		b = b/block_light_scale;
		ParaTerrain.GetBlockAttributeObject():SetField("BlockLightColor", {r,g,b});
	end
end
