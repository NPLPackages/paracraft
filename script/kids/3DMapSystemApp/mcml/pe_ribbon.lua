--[[
Title: office 2007 ribbon-like controls
Author(s): LiXizhi
Date: 2008/10/28
Desc: pe:ribbonbar
		
---++ pe:ribbonbar
styles: background, background2, color, padding-top, padding-bottom. 
	If padding bottom is larger than top, label text is displayed on bottom, otherwise on top.
	if attribute vertical is true, available styles padding-left, padding-right
	If padding left is larger than right, label text is displayed on left, otherwise on right.
attributes: 
| tooltip | text displayed when mouse over |
| color | text color for label and all inner controls |
| label | label of this ribbon |
| labelcommand | app command to be called, when user clicks on the ribbon label |
| vertical | if true, show the ribbon page vertcially |

File browser sample code: 
<verbatim> 
     <pe:ribbonbar name="myFileBrowser" dialoglaunch="" title="My Group">
     </pe:ribbonbar>
</verbatim>

---++ pe:command
Similar to pe:button, but it is usually bind to a command and is displayed as an image button.
styles: background, width=32, height
attributes: 
| command or cmd| app command name to be called, when user clicks on the button |
| params | a string or table to be passed to the command. If it is table, it will be serialized to sCode. it must not be long. |
| tooltip | text displayed when mouse over |
| enabled | enable the command |
| width | size of icon |
| animstyle | number such as 11, 12, 13, 14, 21, 22,23,24 |

<verbatim> 
	<pe:command cmd="Profile.Login"/>
	<pe:command cmd="File.MCMLBrowser" params="script/apps/HelloChat/Ribbons/CreationTab.html"/>
	<pe:command cmd="File.MCMLBrowser" params='<%={url="script/apps/HelloChat/Ribbons/CreationTab.html"}%>'/>
</verbatim>

---++ pe:ribbon
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_ribbon.lua");
-------------------------------------------------------
]]

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-----------------------------------
-- pe:ribbonbar control:
-----------------------------------
local pe_ribbonbar = {};
Map3DSystem.mcml_controls.pe_ribbonbar = pe_ribbonbar;

-- tab pages are only created when clicked. 
function pe_ribbonbar.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	--Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	if(mcmlNode:GetAttribute("display") == "none") then return end
	-- clone and merge new style if the node has css style property
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css[mcmlNode.name]) or {};
	if(style) then
		-- pass through some css styles from parent. 
		css.color = css.color or style.color;
		css["font-family"] = css["font-family"] or style["font-family"];
		css["font-size"] = css["font-size"] or style["font-size"];
		css["font-weight"] = css["font-weight"] or style["font-weight"];
	end
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	
	local availWidth, availHeight = parentLayout:GetPreferredSize();
	local maxWidth, maxHeight = parentLayout:GetMaxSize();
	if(css["max-width"]) then
		local max_width = css["max-width"];
		if(max_width) then
			if(maxWidth>max_width) then
				local left, top, right, bottom = parentLayout:GetAvailableRect();
				-- align at center. 
				if(mcmlNode:GetAttribute("align")=="center") then
					left = left + (maxWidth - max_width)/2
				elseif(mcmlNode:GetAttribute("align")=="right") then
					left = right - max_width;
				end	
				right = left + max_width
				parentLayout:reset(left, top, right, bottom);
			end
		end
	end
	
	local width, height = mcmlNode:GetAttribute("width"), mcmlNode:GetAttribute("height");
	if(width) then
		css.width = tonumber(string.match(width, "%d+"));
		if(css.width and string.match(width, "%%$")) then
			css.width=math.floor((maxWidth-margin_left-margin_right)*css.width/100);
			if(availWidth<(css.width+margin_left+margin_right)) then
				css.width=availWidth-margin_left-margin_right;
			end
			if(css.width<=0) then
				css.width = nil;
			end
		end	
	end
	if(height) then
		css.height = tonumber(string.match(height, "%d+"));
		if(css.height and string.match(height, "%%$")) then
			css.height=math.floor((maxHeight-margin_top-margin_bottom)*css.height/100);
			if(availHeight<(css.height+margin_top+margin_bottom)) then
				css.height=availHeight-margin_top-margin_bottom;
			end
			if(css.height<=0) then
				css.height = nil;
			end
		end	
	end
	
	-- whether this control takes up space
	local bUseSpace; 
	if(css.float) then
		if(css.width) then
			if(availWidth<(css.width+margin_left+margin_right)) then
				parentLayout:NewLine();
			end
		end	
	else
		parentLayout:NewLine();
	end
	local myLayout = parentLayout:clone();
	myLayout:ResetUsedSize();
	
	if(css.position == "absolute") then
		-- absolute positioning in parent
		myLayout:SetPos(css.left, css.top);
	elseif(css.position == "relative") then
		-- relative positioning in next render position. 
		myLayout:OffsetPos(css.left, css.top);
	else
		myLayout:OffsetPos(css.left, css.top);
		bUseSpace = true;	
	end
	
	left,top = myLayout:GetAvailablePos();
	myLayout:SetPos(left,top);
	width,height = myLayout:GetSize();
	
	if(css.width) then
		myLayout:IncWidth(left+margin_left+margin_right+css.width-width)
	end
	
	if(css.height) then
		myLayout:IncHeight(top+margin_top+margin_bottom+css.height-height)
	end	
	
	-- for inner control preferred size
	myLayout:OffsetPos(margin_left+padding_left, margin_top+padding_top);
	myLayout:IncWidth(-margin_right-padding_right)
	myLayout:IncHeight(-margin_bottom-padding_bottom)	
	
	
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = myLayout:GetPreferredRect();
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, 
			{instName = instName, color = css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"]}, myLayout)
	end
	
	local left, top = parentLayout:GetAvailablePos();
	local width, height = myLayout:GetUsedSize()
	width = width + padding_right + margin_right
	height = height + padding_bottom + margin_bottom
	if(css.width) then
		width = left + css.width + margin_left+margin_right;
	end	
	if(css.height) then
		height = top + css.height + margin_top+margin_bottom;
	end
	
	if(bUseSpace) then
		parentLayout:AddObject(width-left, height-top);
		if(not css.float) then
			parentLayout:NewLine();
		end	
	end
	
	local label = mcmlNode:GetAttributeWithCode("label");
	if(label and label~="") then
	
		local font;
		local scale;
		if(css["font-family"] or css["font-size"] or css["font-weight"])then
			local font_family = css["font-family"] or "System";
			-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
			local font_size = math.floor(tonumber(css["font-size"] or 12));
			local max_font_size = 14;
			local min_font_size = 11;
			if(font_size>max_font_size) then
				scale = font_size/max_font_size
				font_size = max_font_size;
			end
			if(font_size<min_font_size) then
				scale = font_size/min_font_size
				font_size = min_font_size;
			end
			local font_weight = css["font-weight"] or "norm";
			font = string.format("%s;%d;%s", font_family, font_size, font_weight);
		end
			
		local labelWidth, labelHeight = width-left-margin_left-margin_right, height-top-margin_top-margin_bottom;
		local _this;
		
		local isVertical;
		if(mcmlNode:GetAttribute("vertical")) then
			isVertical = mcmlNode:GetBool("vertical")
		end
		if(isVertical == true) then
			-- NOTE by Andy: vertical label supported for left or right aligned ribbon page
			if(padding_left<padding_right) then
				-- text on right
				-- NOTE by Andy: i separate the visual label and the clickable entity to two buttons
				-- here is the rotated visual label
				_this = ParaUI.CreateUIObject("button","b","_lt", 
					left+margin_left + padding_right/2 - labelHeight/2, top+margin_top+labelWidth-padding_right - padding_right/2 + labelHeight/2, 
					labelHeight, padding_right);
				_this.rotation = math.pi/2;
				_this.text = label;
				_this.background = "";
				_this.enabled = false;
				if(font) then
					_this.font = font;
				end
				if(css.color) then
					_guihelper.SetFontColor(_this, css.color);
				end
				_parent:AddChild(_this);
				
				-- and here is the button with onclick command call
				_this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top+labelWidth-padding_right, padding_right, labelHeight);
			else
				-- text on left
				_this = ParaUI.CreateUIObject("button","b","_lt", 
					left+margin_left + padding_left/2 - labelHeight/2, top+margin_top - padding_left/2 + labelHeight/2, 
					labelHeight, padding_left);
				_this.rotation = math.pi/2;
				_this.text = label;
				_this.background = "";
				_this.enabled = false;
				if(font) then
					_this.font = font;
				end
				if(css.color) then
					_guihelper.SetFontColor(_this, css.color);
				end
				_parent:AddChild(_this);
				
				_this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top, padding_left, labelHeight);
			end
		else
			if(padding_top<padding_bottom) then
				-- text on bottom
				_this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top+labelHeight-padding_bottom, labelWidth, padding_bottom);
				_this.text = label;
			else
				-- text on top
				_this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top+labelHeight, labelWidth, padding_top);
				_this.text = label;
			end
			if(font) then
				_this.font = font;
			end
		end
		
		--if(padding_top<padding_bottom) then
			---- text on bottom
			--_this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top+labelHeight-padding_bottom, labelWidth, padding_bottom);
		--else
			---- text on top
			--_this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top+labelHeight, labelWidth, padding_top);
		--end	
		
		_this.background = "";
		local tooltip = mcmlNode:GetAttributeWithCode("tooltip");
		if(tooltip and tooltip~="") then
			_this.tooltip = tooltip
		end
		if(css.color) then
			_guihelper.SetFontColor(_this, css.color);
		end	
		local labelcommand = mcmlNode:GetAttributeWithCode("labelcommand");
		if(labelcommand and labelcommand~="") then
			_this.onclick = string.format(";Map3DSystem.App.Commands.Call(%q);", labelcommand);
		end
		_parent:AddChild(_this);
	end
	
	if(css.background and css.background~="") then
		local _this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top, width-left-margin_left-margin_right, height-top-margin_top-margin_bottom);
		--_this.enabled = false;
		if(css.background2) then
			_guihelper.SetVistaStyleButton5(_this, css.background, css.background2);
			_this:GetAttributeObject():SetField("AlwaysMouseOver", true);
		else
			_this.background = css.background;
		end
		_parent:AddChild(_this);
		_this:BringToBack();
	end
end

-----------------------------------
-- pe:command control:
-----------------------------------
local pe_command = {};
Map3DSystem.mcml_controls.pe_command = pe_command;

-- tab pages are only created when clicked. 
function pe_command.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:command"]);
	local commandName =  mcmlNode:GetAttributeWithCode("cmd") or mcmlNode:GetAttributeWithCode("command");
	local background;
	local tooltip;
	if(commandName) then
		local command = Map3DSystem.App.Commands.GetCommand(commandName);
		if(command) then
			if(command.ButtonText)  then
				tooltip = command.ButtonText;
			end
			if(command.icon) then
				background = command.icon;
			end
		end
	end
	tooltip = mcmlNode:GetString("tooltip") or tooltip;
	if(css and css.background) then
		background = css.background;
	end
	
	local buttonWidth = mcmlNode:GetNumber("width") or css.width;
	
	width = parentLayout:GetPreferredSize();
	if(buttonWidth>width) then
		parentLayout:NewLine();
		width = parentLayout:GetMaxSize();
		if(buttonWidth>width) then
			buttonWidth = width
		end
	end
	left, top = parentLayout:GetAvailablePos();
	
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	
	local height = css.height or buttonWidth;
	local _this = ParaUI.CreateUIObject("button", "b", "_lt", left+margin_left, top+margin_top, buttonWidth, height)
	
	if(background) then
		_this.background = background;
	end
	if(tooltip) then
		_this.tooltip = tooltip
	end
	if(mcmlNode:GetAttribute("enabled")) then
		_this.enabled = mcmlNode:GetBool("enabled")
	end
	
	local animstyle = mcmlNode:GetNumber("animstyle");
	if(animstyle~=nil) then
		_this.animstyle = animstyle;
	end
	
	if(commandName and commandName~="") then
		local params = mcmlNode:GetAttributeWithCode("params");
		if(type(params) == "string") then
			params = string.format("%q", params);
		elseif(type(params) == "table") then
			params = commonlib.serialize_compact(params)
		else
			params = "nil";
		end
		
		_this.onclick = string.format(";Map3DSystem.App.Commands.Call(%q,%s);", commandName, params);
	end
	_parent:AddChild(_this);
	
	parentLayout:AddObject(buttonWidth+margin_left+margin_right, margin_top+margin_bottom+height);
end