--[[
Title: default css class
Author(s): LiXizhi
Date: 2008/3/10
Desc: One can assign css classes defined in this file to mcml tag by adding class attribute. 
e.g. <div class="container"></div> will apply the "container" css to the mcml control. 
for default html css, please see pe_html file. 
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/default_css.lua");
-- Map3DSystem.mcml_controls.pe_css.default["container"]

local my_default_css = commonlib.gettable("Map3DSystem.mcml_controls.pe_css.default");
my_default_css["defaultbutton"] = {background = "Texture/3DMapSystem/common/ThemeLightBlue/btn_bg_highlight.png: 4 4 4 4",};
-------------------------------------------------------
]]
-----------------------------------
-- pe_html: pure text
-----------------------------------
local pe_css = commonlib.gettable("Map3DSystem.mcml_controls.pe_css");

local default_css = {
	["container"] = {
		background = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4",
	},
	["darkbox"] = {
		background = "Texture/3DMapSystem/common/ThemeLightBlue/listbox_bg.png: 4 4 4 4",
	},
	["lightbox"] = {
		background = "Texture/3DMapSystem/common/ThemeLightBlue/editbox_bg.png: 4 4 4 4",
	},
	["box"] = {
		background = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4",
	},
	-- traditional web form boarder class
	["form"] = {
		background = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4",
	},
	["highlightbutton"] = {
		background = "Texture/3DMapSystem/common/ThemeLightBlue/btn_bg_highlight.png: 4 4 4 4",
	},
	["defaultbutton"] = {
		background = "Texture/3DMapSystem/common/ThemeLightBlue/btn_bg_highlight.png: 4 4 4 4",
	},
	["blue"] = {
		background = "Texture/whitedot.png",
		["background-color"] = "0 0 200",
	},
	["white"] = {
		background = "Texture/whitedot.png",
	},
	["logo"] = {
		-- TODO: background = "Texture/whitedot.png",
	},
	["a_inverse"] = {
		background="Texture/3DMapSystem/common/href_yellow.png:2 2 2 2",
		color = "#C8E3F1",
	},
	
	---------------------------------------
	-- one can overwrite default html styles defined in pe_html here. 
	---------------------------------------
};
-- default css stule
if(not pe_css.default) then
	pe_css.default = default_css;
else
	local name, value
	for name, value in pairs(default_css) do
		if(not pe_css.default[name]) then
			pe_css.default[name] = value;
		end
	end
end

-- @param name: the css class name
function pe_css.GetDefault(name)
	return pe_css.default[name]
end

-- @param name: the css class name
-- @param bOverwrite: true to overwrite if exist
function pe_css.SetDefault(name, style, bOverwrite)
	if(not pe_css.default[name] or bOverwrite) then
		pe_css.default[name] = style;
	end
end