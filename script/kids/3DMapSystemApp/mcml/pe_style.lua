--[[
Title: pe_style
Author(s): LiXizhi
Date: 2015/6/2
Desc: it only renders its child nodes if condition is true

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_style.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/DOM.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/StyleManager.lua");
local StyleManager = commonlib.gettable("System.Windows.mcml.StyleManager");

-----------------------------------
-- pe:script and html script node
-----------------------------------
local pe_style = commonlib.gettable("Map3DSystem.mcml_controls.pe_style");

--  <style type="text/mcss" src="">
--  </style>
function pe_style.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout)
	local self = mcmlNode;

	if(self.isLoaded) then
		return
	end
	self.isLoaded = true;

	-- nil or "text/mcss"
	local scriptType = self:GetString("type");
	-- Defines a URL to a file that contains the script (instead of inserting the script into your HTML document, you can refer to a file that contains the script)
	local src = self:GetString("src");
	if(src and src ~= "") then
		local pageStyle = self:GetPageStyle();
		if(pageStyle) then
			local style = StyleManager:GetStyle(src);
			if(style) then
				pageStyle:AddReference(style);
			end
		end
	end

	local code = self:GetPureText();
	if(code~=nil and code~="") then
		local pageStyle = self:GetPageStyle();
		if(pageStyle) then
			pageStyle:LoadFromString(code);
		end
	end
end
