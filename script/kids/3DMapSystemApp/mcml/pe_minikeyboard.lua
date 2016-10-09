--[[
Title: mini-keyboard input page
Author(s): WD, refactored by LiXizhi
Date: 2011/08/22
---++ pe:minikeyboard
| *attribute* | *descriptiong* |
| name | |
| for | name of the input control to bind to.  |
<verbatim>
	<div>
		<input type="text" name="txtEditBox" style="width:200px;height:25px;" />
		<input type="button" name="mini2" value="UseMiniKeyboard" for="minikeyboard"/>
		<pe:minikeyboard name="minikeyboard" for="txtEditBox" />
	</div>
</verbatim>
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_minikeyboard.lua");
-------------------------------------------------------
]]

local pe_minikeyboard = commonlib.gettable("Map3DSystem.mcml_controls.pe_minikeyboard");

function pe_minikeyboard.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_minikeyboard.render_callback);
end

function pe_minikeyboard.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	NPL.load("(gl)script/ide/MiniKeyboard.lua");
	
	mcmlNode.control = mcmlNode.control or CommonCtrl.MiniKeyboard:new({
			name = mcmlNode:GetAttribute("name"),
			alignment = "_lt",
			left = left,
			top = top,
			parent_relative = _parent,
			onchange = function(value, key)
				local bindNodeName = mcmlNode:GetAttribute("for");
				local pageCtrl = mcmlNode:GetPageCtrl();
				if(pageCtrl and bindNodeName) then
					echo({bindNodeName, value})
					pageCtrl:SetValue(bindNodeName, value);
				end
			end,
			maxlength = tonumber(mcmlNode:GetAttributeWithCode("maxlength")),
			displaymode = mcmlNode:GetAttributeWithCode("displaymode"),
			color = css["color"], 
			frame_background = "Texture/Aries/Common/ThemeTeen/pane_bg_32bits.png:7 7 7 7",
			panel_background = "Texture/Aries/Common/ThemeTeen/pane_border_32bits.png:7 7 7 7",
			fontsize = css["font-size"],
		});
end

-- some other control forwarded a click message to this control
-- @param mcmlNode: the for node target
-- @param fromNode: from which node the click event is fired. 
function pe_minikeyboard.HandleClickFor(mcmlNode, fromNode, bindingContext)
	if(mcmlNode.control) then
		
		local sForName = mcmlNode:GetAttribute("for");
		if(sForName) then
			local pageCtrl = mcmlNode:GetPageCtrl()
			if(pageCtrl) then
				mcmlNode.control:SetValue(pageCtrl:GetUIValue(sForName));
			end
		end
		mcmlNode.control:Show();
	end
end