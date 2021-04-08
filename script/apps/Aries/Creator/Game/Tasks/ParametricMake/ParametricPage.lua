--[[
Title: ParametricPage 
Author(s): leio
Date: 2021/3/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParametricMake/ParametricPage.lua");
local ParametricPage = commonlib.gettable("ParametricMake.ParametricPage");


------------------------------------------------------------
--]]

local ParametricPage = commonlib.gettable("ParametricMake.ParametricPage");

local page
function ParametricPage.onInit()
	page = document:GetPageCtrl();
end
function ParametricPage.show(name, align, x, y, width, height)
	ParametricPage.close();
	if(not name)then
		return
	end
	local url = string.format("script/apps/Aries/Creator/Game/Tasks/ParametricMake/ParametricPage.html?name=%s",name);
	local params = {
			url = url,
			name = "ParametricPage_" .. name, 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = false,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = align,
				x = x,
				y = y,
				width = width,
				height = height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
function ParametricPage.close()
	if(page)then
		page:CloseWindow(0);
	end
end

function ParametricPage.outputDroplist(node,p)
    if(p)then
        local name = p.name;
        local type = p.type;
        local enum = node:getDefineEnum(type);
		local options = "";
		for k,v in ipairs(enum.values) do
			local option;
			if(p.value == v.value)then
				option = string.format([[<option selected="selected" value="%s">%s</option>]], v.value, v.label);
			else
				option = string.format([[<option value="%s">%s</option>]], v.value, v.label);
			end
			options = options .. option;
		end
		local s = string.format([[ <select name="%s" onselect="onChangeEnum">%s </select>]], name, options); 
		return s;
    end      
end