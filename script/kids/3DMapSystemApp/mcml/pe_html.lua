--[[
Title: rendering all supported html tags
Author(s): LiXizhi
Date: 2008/2/16
Desc: support formatting to the following tag and their attributes: 
<verbatim>
_text_, h1, h2,h3, h4, li, p, div, hr, font, span, strong, a(href), img(attr: src,height, width, title), form, label
__anyTag__(style="float:left;color: #006699; text-align: right;background:url;background-color:#FF0000;
	font-family: Arial; font-size: 14pt;font-weight: bold;text-shadow:true;
	left: -60px; position: relative|absolute|screen; top: 30px;width: 100px;height: 100px;
	class:"box";margin:5;margin-top:5;padding:5;" onload="MyOnLoadFunc" display="none"),
	_Note_: MyOnLoadFunc(mcmlNode) is called immediately after the mcml node UI is created. This is usually used in <pe:mcml onload="MyClass.MyFunc()"></pe:mcml>
<input type="text|radio|checkbox|submit|button|hidden|reset|password" name="", value=""/> <textarea name="music" rows="4"></textarea>
By default: text, span, font,a(href) will be inline controls, i.e. they float around previous control, allowing content to automatically wrap to the next line. 

NOTE: 2010/7/20 by andy: base-font-size is added
</verbatim>

---++ div tag
Div is one of the most frequently used display blocks. It is a container of other tags. 

| *Property*	| *Descriptions*				 |
| style			| string: css style string most css properties are supported. |
| class			| some prefined css style name. such as "box", "defaultbutton" |
| background	| same as css style property background |
| background2	| the mouse over background, only valid when there is onclick or tooltip attribute |
| display		| if this is "none", the node will be skipped during rendering. |
| onclick		| when this is set, the inner nodes are rendered but not interactive, clicking on the client area of div will trigger the onclick(name, mcmlNode) call back function |
| tooltip		| mouse over tooltip.Only valid when onclick is not empty.  |   
| width			| it can be like "100px" or "90%", it will override settings in style attribute|   
| height		| it can be like "100px" or "90%", it will override settings in style attribute|   
| align			| nil or "center", "right" is supported. it is only used when css:max-width or css:width or attr:width is specified |   
| valign		| nil or "center", "bottom" is supported. it is only used when css:max-height or css:height or attr:height is specified |
| enabled       | "true" or "false", if "false", all inner nodes will be locked. ccs.background will be displayed as an overlay image. |
| trans			| for any div style tags, including the pe:mcml page, we can use the trans attribute to specify how the child nodes are translated. if this is "no" or "none", no translation of the child nodes are used. otherwise, it is the translation file's base name, such as "IDE", "ParaWorld", "OfficialMCML" |
| variables		| It is used to define code variables that will be replaced in all the attribute values and inner text of current and child nodes. The most common use is do localizations. such as "$=locale.mcml". it can also define multiple variables "$=locale.mcml;$enUS=local.mcml.enUS". In mcml code one can use ${SOME_LANG} or $enUS{SOME_LANG} to replace. see pe_localization.html for example. |
| text-singleline | if "true", the child node will always be displayed in a single line as if the width is infinite even the actual width may be a much smaller value. This is compatible with "width", "min-width", "max-width". Useful in localization.  |
Special css property
| background-rotation | [-3.14, 3.14]|
| background-animation | url(filename#anim_name), such as "background-animation:url(script/UIAnimation/CommonBounce.lua.table#ShakeLR)"|
| max-width | if the max-width is specified, content will have a maximum width. if the align property is "center", content will be centered. this is usually used on the pe:mcml tag such as <verbatim><pe:mcml style="max-width:400px" align="center">text</pe:mcml></verbatim>|
| max-height | |
| min-width | |
| min-height | |
| line-height | it can be "100%", or absolute values like "12px" |
| font-size | font size |
| base-font-size | force using a given font size without scaling |
| zorder | default is 0. this is like z-index |

background property: the css background can be of following. e.g.
   1. background:a.jpg; This is an image relative to the current page's directory.
   1. background:url(a.jpg: 4 4 4 4); we can specify a sub region like in NPL control's background property
   1. background:url(a.jpg# 0 0 32 32); where # stands for ; in standard NPL UI background property, since css does not allow ; in string.

---++ a tag
it is similar to html a tag except that the href property recoginizes the following url. 

*href property* <br/>
if href begins with "open://filepath", it will try to open the file using ShellExecute("open", "explorer.exe",rootDir..filepath). It will automatically append paraengine root directory prior to filepath. 
if href begins with "http://filepath" and target property is not specified, it will ask the user whether to open the link using an external or internel Internet web browser. 
if href is just a file without any sub directory, it will be considered a relative path and will automatically append the current page directory before opening it. 
if href is a file with sub directory, it will be regarded as a local file relative to the root of paraengine directory. 

*target property* <br/>
It may be "_self", "_blank", "_mcmlblank", "[iframename]". if this property is specified, the href will be regarded as mcml page file even if it begins with http. 
iframename can be any iframe control name, where the href mcml page will be opened. if it is "_self", it will be opened in the current page control.
if it begins with "_mcmlblank", it will be opened in a new popup mcml window. "framewidth" and "frameheight" property can be used to specify newly opened window size. 

*onclick property* <br/>
if there is an onclick property and href is not specified, the onclick function will be called with parameters specified in param1, param2, ... property of the node. 
Please note that: unlike button onclick, the function is not executed in page scoping and therefore must be a global function.  
However if the type property is button or name or id property is not nil, page scoping is enabled. Example 
<verbatim>
	without page scoping: <a onclick="Map3DSystem.App.profiles.ProfileManager.AddAsFriend" param1='<%=Eval("uid")%>'>Add as friend</a>
	with page scoping: <a type="button" onclick="Map3DSystem.App.CCS.AvatarRegPage.UpdateAvatar" param1='<%=Eval("index")%>'>select</a>
</verbatim>

*other properties*: 
| tooltip | mouse over text to display |
| height | forcing a given height, such as in chat pe:name |
| isbuttonstyle | if true, the mouse over effect is always displayed. |
| name | name of the control |
| type | "button" |
| target | "_blank", "_self" |
| onclick | if "name" attribute is provided or type="button" we will invoke within the page scoping, otherwise it is global scoping.  |
| url | if target is "_blank", and url begins with "http://", it will be opened with the default internet browser  |
| param1 | additional params passed to onclick |
| param2-5 | additional params passed to onclick  |
<verbatim>
	<a onclick="Map3DSystem.App.profiles.ProfileManager.AddAsFriend" param1='<%=Eval("uid")%>'>Add as friend</a>
</verbatim>
---++ iframe tag
*properties*: 
| src | empty or the url of mcml page to load by default |
| cachepolicy | cache policy to use with the default src url. such as "access plus 10 days" |
| AutoSize | boolean, defaults to false. AutoSize only takes effect when the parent page is refreshed and the inner page can be evaluated without using postponed page:refresh(). |
| alignment | "_fi" if fill, it will ignore all margin and padding. default to "_lt", left top. |
---++ pe:webbrowser tag
*properties*: 
| url | initial url |
| onchange | when the page is loaded or redirected. this message is sent. onchange(locationURL, mcmlNode) end, where locationURL is the current loaded url. It may differ from the initial url |
*method*
| Refresh, Stop, GoBack, GoForward | | 
| Goto | url |
| SetContent | string content such as "<html><body>hello world</body></html>" |
| FindText | string to find |

<verbatim>
	<pe:webbrowser name="mybw" url="www.baidu.com" onchange="OnPageChanged" style="width:400px;height:300px;"></pe:webbrowser>
</verbatim>
---++ img tag
| src | image path, it can be URL image. if src contains "[;:]", it is treated as a local image. |
| animstyle | a number of animation styles. see ParaUIObject.animstyle |
| uiname	| the low level ui name. so that if unique, we will be able to get it via ParaUI.GetUIObject(uiname) |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_html.lua");
-------------------------------------------------------
]]
local L = CommonCtrl.Locale("IDE");
local type = type;
local mcml_controls = commonlib.gettable("Map3DSystem.mcml_controls");

-----------------------------------
-- pe_html: pure text
-----------------------------------
local pe_html = commonlib.gettable("Map3DSystem.mcml_controls.pe_html");

pe_html.css = {
	["h1"] = {
		["margin-top"] = 3,
		["margin-left"] = 0,
		["margin-bottom"] = 5,
		["font-weight"] = "bold",
		["font-size"] = "13",
		headimage = "Texture/unradiobox.png",
		headimagewidth = 16,
	},
	["h2"] = {
		["margin-top"] = 3,
		["margin-left"] = 0,
		["margin-bottom"] = 3,
		["font-weight"] = "bold",
		["font-size"] = "12",
		headimage = "Texture/unradiobox.png",
		headimagewidth = 14,
	},
	["h3"] = {
		["margin-top"] = 3,
		["margin-left"] = 0,
		["margin-bottom"] = 2,
		["font-weight"] = "bold",
		headimage = "Texture/unradiobox.png",
		headimagewidth = 12,
	},
	["h4"] = {
		["margin-top"] = 3,
		["margin-left"] = 0,
		["margin-bottom"] = 1,
		["font-weight"] = "bold",
		headimage = "Texture/unradiobox.png",
		headimagewidth = 10,
	},
	["li"] = {
		["margin-top"] = 0,
		["margin-left"] = 0,
		["margin-bottom"] = 0,
		headimage = "Texture/unradiobox.png",
		headimagewidth = 8,
	},
	["ul"] = {
		["margin-top"] = 3,
		["margin-left"] = 5,
		["margin-bottom"] = 3,
	},
	["p"] = {
		["margin-top"] = 1,
		["margin-left"] = 0,
		["margin-bottom"] = 1,
	},
	["span"] = {
	},
	["font"] = {
		["font-family"] = Map3DSystem.DefaultFontFamily,
		["font-size"] = Map3DSystem.DefaultFontSize,
		["font-weight"] = Map3DSystem.DefaultFontWeight,
	},
	["b"] = {
		["font-weight"] = "bold",
	},
	["strong"] = {
		["font-weight"] = "bold",
	},
	["img"] = {
		["width"] = 200,
		["height"] = 150,
	},
	["hr"] = {
		["margin-top"] = 2,
		["margin-left"] = 5,
		["margin-right"] = 5,
		["margin-bottom"] = 2,
		["height"] = 1,
		background = "Texture/whitedot.png",
		["background-color"] = "150 150 150 255",
	},
	["a"] = {
		color = "#1940be", --"#006699",
		["padding"] = 1,
		-- TODO: use a small image with a 1 pixel bright border. 
		background = "Texture/3DMapSystem/common/href.png:2 2 2 2"
	},
	["iframe"] = {
		["padding"] = 0,
		["margin"] = 0,
	},
	["div"] = {
		-- whether this object allows surrounding controls to floating around(either before or after) it. 
		-- Note: the css.width can be explicitly specified or not, in order for this control to float after previous control. 
		-- float = "left",
	},
	["pe:mcml"] = {
	},
	
	-- HTML extension
	["pe:a"] = {
		color = "#006699",
		["padding"] = 10,
		["margin"] = 0,
		--["margin-top"] = 32,
		--["margin-bottom"] = 32,
		--["margin-left"] = 32,
		--["margin-right"] = 32,
		-- TODO: use a small image with a 1 pixel bright border. 
		background = "Texture/3DMapSystem/common/href.png:2 2 2 2",
	},
	["pe:world"] = {
		color = "#1940be", --"#006699",
		["padding"] = 1,
		background = "Texture/3DMapSystem/common/href.png:2 2 2 2",
	},
	-- social tags
	["pe:avatar"] = {
		["width"] = 256,
		["height"] = 256,
	},
	["pe:name"] = {
		--["color"] = "#006699",
		float="left",
	},
	["pe:profile-photo"] = {
		float="left",
	},
	["pe:flash"] = {
	},
	-- item tags
	["pe:slot"] = {
		["width"] = 48,
		["height"] = 48,
	},
	["pe:item"] = {
		["width"] = 48,
		["height"] = 48,
	},
	-- map related tags
	["pe:map"] = {
		["width"] = 640,
		["height"] = 480,
	},
	
	["pe:minimap"] = {
		["width"] = 128,
		["height"] = 128,
	},
	
	-- HTML related tags
	["pe:editor"] = {
		["padding"] = 5,
	},
	["pe:editor-button"] = {
		["margin-top"] = 2,
		["margin-bottom"] = 2,
		["height"] = 22,
	},
	["pe:editor-text"] = {
		["margin-top"] = 0,
		["margin-bottom"] = 2,
		["lineheight"] = 20,
	},
	["pe:treeview"] = {
	},
	["pe:treenode"] = {
	},
	["pe:filebrowser"] = {
	},
	["pe:canvas3d"] = {
	},
	["pe:GridView"] = {
	},
	["pe:pager"] = {
	},
	["pe:download"] = {
		background = "Texture/3DMapSystem/common/href.png:2 2 2 2",
	},
	["pe:label"] = {
		height = 18,
	},
	["pe:fileupload"] = {
	},
	["pe:progressbar"] = {
	},
	["pe:sliderbar"] = {
	},
	["pe:numericupdown"] = {
		width=120,
		height=20,
	},
	["pe:colorpicker"] = {
		width=182,
		height=50,
	},
	["pe:slide"] = {
		width=300,
		height=50,
		background="",
	},
	["input-select"] = {
		--["margin-top"] = 0,
		["margin-bottom"] = 2,
		["lineheight"] = 20,
	},
	["pe:tabs"] = {
		["padding-left"] = 10,
		["ItemSpacing"] = 2,
		["padding-right"] = 0,
		-- this is used as the tab button height
		["padding-top"] = 18, 
		--["background"] = "Texture/3DMapSystem/common/ThemeLightBlue/tabview_body.png: 5 5 5 5",
		--["background"] = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4",
		["background"] = "Texture/Aquarius/Common/Container_32bits.png: 5 5 5 5",
		["TextColor"] = "0 0 0",
		["SelectedTextColor"] = "0 0 0",
		-- please note that: MouseOverItemBG does not support 9 tile ":" texture name yet.
		-- ["MouseOverItemBG"] = "Texture/Aquarius/Common/Tabitem_Selected_32bits.png; 0 0 16 18: 6 15 6 2",
		["UnSelectedMenuItemBG"] = "Texture/Aquarius/Common/Tabitem_Unselected_32bits.png; 0 0 16 18: 6 15 6 2",
		["SelectedMenuItemBG"] = "Texture/Aquarius/Common/Tabitem_Selected_32bits.png; 0 0 16 18: 6 15 6 2",
		["UnSelectedMenuItemBottomBG"] = "Texture/Aquarius/Common/Tabitem_Unselected_32bits.png; 0 14 16 18: 6 15 6 2",
		["SelectedMenuItemBottomBG"] = "Texture/Aquarius/Common/Tabitem_Selected_32bits.png; 0 14 16 18: 6 15 6 2",
	},
	["pe:tab-item"] = {
		-- the tab button height plus some space, such as 20+1
		["padding-top"] = 5, 
		--["padding-bottom"] = 5,
	},
	["pe:ribbonbar"] = {
		-- the tab button bottom height plus some space, such as 16+4
		float="left",
		margin=1,
		["padding"] = 2, 
		["padding-bottom"] = 16,
		--["color"] = "#000000", -- text color
		["background"] = "Texture/3DMapSystem/common/ThemeLightBlue/ribbonbar.png: 5 5 5 20",
		["background2"] = "Texture/3DMapSystem/common/ThemeLightBlue/ribbonbar_hl.png: 5 5 5 20",
	},
	["pe:command"] = {
		["margin"] = 4, 
		["margin-left"] = 2, 
		["margin-right"] = 2,
		-- button width
		["width"] = 20, -- 28 is good
	},
	["pe:asset"] = {
		-- button width
		["width"] = 48,
	},
	["pe:bag"] = {
		["padding"] = 2, 
	},

	["pe:minikeyboard"] = {
		["position"] = "relative",
	},
	["pe:goalpointer"] = {
		["position"] = "relative",
		float="left",
	},
	["pe:mcworld"] = {
		float="left",
		["margin-left"] = 2,
		["padding-bottom"] = 1,
	},
};

function pe_html.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height)
	-- TODO
end

-----------------------------------
-- pe_mcml: Not Used. the root node
-----------------------------------
local pe_mcml = commonlib.gettable("Map3DSystem.mcml_controls.pe_mcml");

function pe_mcml.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout)
	return mcml_controls.pe_simple_styles.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout);
end


-----------------------------------
-- pe_text: pure text
-----------------------------------
local pe_text = commonlib.gettable("Map3DSystem.mcml_controls.pe_text");

-- it will create text in available position as single lined, or as multilined in new line position. 
-- the control takes up whatever vertical space needed to display the text as a paragraph,
-- @param mcmlNode: is a text
-- @param css: nil or a table containing css style, such as {color=string, href=string}. This is a style object to be associated with each node.
function pe_text.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout)
	if(type(mcmlNode) == "string") then
		-- TODO: do the HTML white space replace, use &#32; instead. 
		-- currently NPL xml parser does not translate nbsp;, so we have to do it manually here. 
		local buttonText = string.gsub(mcmlNode, "nbsp;", " ");
		-- convert HTML special characters like &#XXXX; to the current NPL code page. 
		--log(ParaMisc.EncodingConvert("HTML", "", "&#24320;&#21457;&#32593;&#30340;"));
		
		-- font-family: Arial; font-size: 14pt;font-weight: bold; 
		local font;
		local scale;
		local instName;
		local line_padding = 2;
		local textflow;
		if(css) then
			instName = css.instName;
			if(css["font-family"] or css["font-size"] or css["font-weight"])then
				local font_family = css["font-family"] or "System";
				-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
				local font_size = math.floor(tonumber(css["font-size"] or 12));
				local max_font_size = tonumber(css["base-font-size"]) or 14;
				local min_font_size = tonumber(css["base-font-size"]) or 11;
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
			if(css["line-height"]) then
				local font_size = tonumber(css["font-size"]) or 12;
				local line_height = css["line-height"];
				local line_height_percent = line_height:match("(%d+)%%");
				if(line_height_percent) then
					line_height_percent = tonumber(line_height_percent);
					line_padding = math.ceil((line_height_percent*font_size*0.01-font_size)*0.5);
				else
					line_height = line_height:match("(%d+)");
					line_height = tonumber(line_height);
					if(line_height) then
						line_padding = math.ceil((line_height-font_size)*0.5);
					end
				end
			end
			textflow = css.textflow;
		end
		
		local buttonWidth = _guihelper.GetTextWidth(buttonText, font);
		
		-- buttonWidth = buttonWidth + 3;
		if(buttonWidth>0) then
			width = parentLayout:GetPreferredSize();
			if(width == 0) then
				parentLayout:NewLine();
				left, top, width, height = parentLayout:GetPreferredRect();
				width = parentLayout:GetPreferredSize();
			end
			local remaining_text_func;
			if(buttonWidth>width and width>0) then
				if(css and css["display"] == "block") then
					
				else
					-- for inline block, we will display recursively in multiple line
					local trim_text, remaining_text = _guihelper.TrimUtf8TextByWidth(buttonText,width,font)

					if(trim_text and trim_text~="" and remaining_text and remaining_text~="") then
						remaining_text_func = function()
							parentLayout:NewLine();
							local left, top, width, height = parentLayout:GetPreferredRect();
							pe_text.create(rootName,remaining_text, bindingContext, _parent, left, top, width, height, css, parentLayout);
						end
						buttonText = trim_text;
						buttonWidth = _guihelper.GetTextWidth(buttonText, font);
						if(buttonWidth<=0) then
							return;
						end
					end
				end
				--width = parentLayout:GetMaxSize();
				--if(buttonWidth>width) then
					--buttonWidth = width
				--end
			end
			left, top = parentLayout:GetAvailablePos();

			local _this = ParaUI.CreateUIObject("text", instName or "b", "_lt", left, top+line_padding, buttonWidth, 14)
			_this.text = buttonText;
			if(font) then
				_this.font = font;
			end
			_parent:AddChild(_this);
			_this:DoAutoSize();
			width = buttonWidth;
			height = _this.height;
			
			if(scale) then
				_this.scalingx = scale;
				_this.scalingy = scale;
				_this.translationx = (width * scale - width)/2;
				_this.translationy = (height * scale - height)/2;
				width = width * scale;
				height = height * scale;
			end	
			height = height + line_padding + line_padding;
			if(css) then
				if(css.color) then
					_guihelper.SetFontColor(_this, css.color);
				end	
				if(css["text-align"]) then
					local aval_left, aval_top, aval_width, aval_height = parentLayout:GetPreferredRect();
					if(css["text-align"] == "right") then
						_this.x = aval_width-width;
						width = aval_width; -- tricky: it will assume all width
					elseif(css["text-align"] == "center") then
						local shift_x = (aval_width - aval_left - width)/2
						_this.x = aval_left + shift_x;
						width = width + shift_x; -- tricky: it will assume addition width
					end
				end
				if(css["text-shadow"]) then
					_this.shadow = true;
					if(css["shadow-quality"]) then
						_this:GetAttributeObject():SetField("TextShadowQuality", tonumber(css["shadow-quality"]) or 0);
					end
					if(css["shadow-color"]) then
						_this:GetAttributeObject():SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD(css["shadow-color"]));
					end
				end	
			end
			
			-- this fixed an bug that text overrun the preferred rect.
			-- however, multiple lines of scaled font may still appear wrong, but will not affect parent layout after the fix.
			local max_width = parentLayout:GetPreferredSize();
			if(width>max_width) then
				width = max_width;
			end
			parentLayout:AddObject(width, height);

			if(remaining_text_func) then
				remaining_text_func();
			end
		end
	elseif(type(mcmlNode) == "table") then
		mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
	end
end

-----------------------------------
-- pe_span: <span> which is similar to pe_text and <div>, except that it does not add block-level division. it simple iterate all children and add styles to it. 
-- this is very useful when you want to highlight some inline text color without changing the layout. 
-----------------------------------
local pe_span = commonlib.gettable("Map3DSystem.mcml_controls.pe_span");

-- changing the layout. 
function pe_span.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle(nil, style) or {};
	
	local margin_left, margin_top = (css["margin-left"] or 0),(css["margin-top"] or 0);

	if(margin_left~=0 or margin_top~=0) then
		local x_, y_ = parentLayout:GetPreferredPos()
		parentLayout:SetPreferredPos(x_ + margin_left, y_ + margin_top);
	end

	for childnode in mcmlNode:next() do
		local left, top, width, height = parentLayout:GetPreferredRect();
		if(type(childnode) == "string") then
			css.textflow = true;
			pe_text.create(rootName,childnode, bindingContext, _parent, left, top, width, height, css, parentLayout)
			css.textflow = false;
		else
			Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, css, parentLayout)
		end
	end
end


-----------------------------------
-- pe_font: it handles HTML tags of <font> . <font> is considered deprecated by HTML, so use span to format inline text instead. 
-----------------------------------
local pe_font = {};
Map3DSystem.mcml_controls.pe_font = pe_font;
function pe_font.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(style) then
		style = {color=style.color, ["font-family"] = style["font-family"],  ["font-size"]=style["font-size"], ["font-weight"] = style["font-weight"], ["text-shadow"] = style["text-shadow"]}
	end
	local css = mcmlNode:GetStyle(pe_html.css[mcmlNode.name], style);
	
	local margin_left, margin_top = (css["margin-left"] or 0),(css["margin-top"] or 0);
	if(margin_left~=0 or margin_top~=0) then
		local x_, y_ = parentLayout:GetPreferredPos()
		parentLayout:SetPreferredPos(x_ + margin_left, y_ + margin_top);
	end

	local instName;
	if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
		-- this is solely for giving a global name to inner text control so that it can be animated
		instName = mcmlNode:GetInstanceName(rootName);
	end	
	local parentStyle = {instName=instName, color = mcmlNode:GetAttribute("color") or css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"], ["text-shadow"] = css["text-shadow"], };
	for childnode in mcmlNode:next() do
		local left, top, width, height = parentLayout:GetPreferredRect();
		if(type(childnode) == "string") then
			css.textflow = true;
			pe_text.create(rootName,childnode, bindingContext, _parent, left, top, width, height, parentStyle, parentLayout)
			css.textflow = false;
		else
			Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, parentStyle, parentLayout)
		end
	end
end

-- get the MCML value on the node
function pe_font.GetValue(mcmlNode)
	return mcmlNode:GetInnerText();
end

-- set the MCML value on the node
function pe_font.SetValue(mcmlNode, value)
	if(type(value) == "string") then
		mcmlNode:SetInnerText(value);
	end	
end


-----------------------------------
-- pe_simple_styles: it handles HTML tags of h1, h2,h3, h4, li, p, div, 
-- each supporting css style property. 
-- it supports "display" attribute, it is similar to css.display property, except that it only recognize "none" as input
-----------------------------------
local pe_simple_styles = commonlib.gettable("Map3DSystem.mcml_controls.pe_simple_styles");


-- always create the control on a new line and use up all available horizontal space. 
-- the control takes up whatever vertical space needed to display its inner content,
-- @param mcmlNode: is a text
function pe_simple_styles.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName,bindingContext, _parent, left, top, width, height, parentLayout, style, pe_simple_styles.RenderBlock_callback)
end

-- the render callback
function pe_simple_styles.RenderBlock_callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
	if(css.headimage) then
		local headimagewidth = css.headimagewidth or 16;
		myLayout:OffsetPos(headimagewidth+3, nil);
		
		-- reference image is 20 pixel
		local _this=ParaUI.CreateUIObject("button","b","_lt", left, top+(20-headimagewidth)/2, headimagewidth, headimagewidth);
		_this.background = css.headimage;
		_guihelper.SetUIColor(_this, "255 255 255");
		_parent:AddChild(_this);
	end
	
	local instName;
	if(not css.background or css.background=="") then
		if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
			-- this is solely for giving a global name to inner text control so that it can be animated
			instName = mcmlNode:GetInstanceName(rootName);
		end	
	end
	
	local is_single_line = css["text-singleline"] == "true";
	local old_width
	if(is_single_line) then
		old_width = myLayout.width;
		-- force infinite width
		myLayout.width = 10000; 
	end

	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = myLayout:GetPreferredRect();
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, 
			{instName = instName, display=css["display"], color = css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"], ["text-shadow"] = css["text-shadow"], ["base-font-size"] = css["base-font-size"], ["line-height"]=css["line-height"], 
				["shadow-color"]=css["shadow-color"], ["shadow-quality"]=css["shadow-quality"]
			}, myLayout)
	end

	if(old_width and old_width < myLayout.usedWidth) then
		myLayout.usedWidth = old_width;
		if(old_width < myLayout.availableX) then
			myLayout.availableX = old_width;
		end
	end
end

-- get the MCML value on the node
function pe_simple_styles.GetValue(mcmlNode)
	return mcmlNode:GetInnerText();
end

-- set the MCML value on the node
function pe_simple_styles.SetValue(mcmlNode, value)
	if(type(value) == "string") then
		mcmlNode:SetInnerText(value);
	end	
end


-----------------------------------
-- pe_webbrowser: windows activeX based web browser as a child window. 
-- It will only show up in windowed mode application. 
-----------------------------------
local pe_webbrowser = commonlib.gettable("Map3DSystem.mcml_controls.pe_webbrowser");

function pe_webbrowser.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName,bindingContext, _parent, left, top, width, height, parentLayout, style, pe_webbrowser.RenderBlock_callback)
end

-- the render callback
function pe_webbrowser.RenderBlock_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local _this=ParaUI.CreateUIObject("webbrowser","wb","_lt", left, top, right-left, bottom-top);
	local url = mcmlNode:GetAttributeWithCode("url", "", true);
	if(url) then
		_this.text = url;
	end
	_parent:AddChild(_this);

	mcmlNode.uiobject_id = _this.id;

	local onchangeScript = mcmlNode:GetAttribute("onchange")

	if(onchangeScript) then
		_this:SetScript("onchange",  function(uiobj)
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onchangeScript, uiobj.text, mcmlNode)
		end)
	end

	 -- mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

-- get the MCML value on the node
function pe_webbrowser.GetValue(mcmlNode)
	return mcmlNode:GetAttributeWithCode("url");
end

-- set the MCML value on the node
function pe_webbrowser.SetValue(mcmlNode, value)
	if(type(value) == "string") then
		mcmlNode:SetAttribute("url", value);
	end	
end

-- refresh the page. 
function pe_webbrowser.Goto(mcmlNode, pageInstName, value)
	if(type(value) == "string") then
		local ctl = mcmlNode:GetControl(pageInstName);
		if(ctl) then
			ctl.text = value;
		end
	end
end

-- find text
function pe_webbrowser.FindText(mcmlNode, pageInstName, value)
	if(type(value) == "string") then
		local ctl = mcmlNode:GetControl(pageInstName);
		if(ctl) then
			ctl:GetAttributeObject():SetField("FindText", value);
		end
	end
end

-- set content
function pe_webbrowser.SetContent(mcmlNode, pageInstName, value)
	if(type(value) == "string") then
		local ctl = mcmlNode:GetControl(pageInstName);
		if(ctl) then
			ctl:GetAttributeObject():SetField("Content", value);
		end
	end
end

-- get content
function pe_webbrowser.GetContent(mcmlNode, pageInstName, value)
	if(type(value) == "string") then
		local ctl = mcmlNode:GetControl(pageInstName);
		if(ctl) then
			return ctl:GetAttributeObject():GetField("Content", "");
		end
	end
end

-- refresh the page. 
function pe_webbrowser.Refresh(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		ctl:GetAttributeObject():CallField("Refresh");
	end
end

-- stop the page. 
function pe_webbrowser.Stop(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		ctl:GetAttributeObject():CallField("Stop");
	end
end

-- go back. 
function pe_webbrowser.GoBack(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		ctl:GetAttributeObject():CallField("GoBack");
	end
end

-- go forward. 
function pe_webbrowser.GoForward(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		ctl:GetAttributeObject():CallField("GoForward");
	end
end
-----------------------------------
-- pe_iframe: it handles HTML tags of <iframe>
-----------------------------------
local pe_iframe = {};
Map3DSystem.mcml_controls.pe_iframe = pe_iframe;

-- the control takes up all space needed if frame size is not specified,
function pe_iframe.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end

	local instName = mcmlNode:GetInstanceName(rootName);
	

	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["iframe"]);
	
	local alignment = mcmlNode:GetAttributeWithCode("alignment", nil, true);
	if(not alignment) then
		alignment =  "_lt";
		if(css.float == "right") then
			if(css["vertical-align"] and css["vertical-align"] == "bottom") then
				alignment = "_rb";
			else
				alignment = "_rt";
			end
		else
			if(css["vertical-align"] and css["vertical-align"] == "bottom") then
				alignment = "_lb";
			end
		end		
	end

	local padding_left, padding_top, padding_bottom, padding_right = 
			(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
			(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);
	
	parentLayout:NewLine();
	width = mcmlNode:GetNumber("width") or css.width;
	height = mcmlNode:GetNumber("height") or css.height;
	local parent_left, parent_top, parent_width, parent_height = parentLayout:GetPreferredRect();
	left = parent_left+margin_left+padding_left;
	top = parent_top+margin_top+padding_top;
	if(width == nil) then
		width = parent_width-parent_left-(margin_right+margin_left+padding_left+padding_right);
	end
	if(height == nil) then
		height = parent_height-parent_top-(margin_top+margin_bottom+padding_top+padding_bottom);
	end
	
	local _bg;
	if(css and css.background and css.background~="") then
		_bg = ParaUI.CreateUIObject("container", "bg", "lt", left-padding_left, top-padding_top, width+padding_left+padding_right, height+padding_top+padding_bottom);
		_parent:AddChild(_bg);
		_bg.background = css.background;
		if(css["background-color"]) then
			_guihelper.SetUIColor(_bg, css["background-color"]);
		else
			_guihelper.SetUIColor(_bg, "#FFFFFF");
		end
	end
	
	local _iframe;
	if(alignment == "_fi") then
		_iframe = ParaUI.CreateUIObject("container", instName, "_fi", 0, 0, 0, 0);
	else
		_iframe = ParaUI.CreateUIObject("container", instName, "_lt", left, top, width, height);
	end
	local click_through = mcmlNode:GetBool("ClickThrough");
	if(click_through) then
		_this:GetAttributeObject():SetField("ClickThrough", click_through);
	end

	_iframe.background = "";
	_parent:AddChild(_iframe);
	
	NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
	
	-- create PageCtrl 
	local cache_policy = mcmlNode:GetString("cachepolicy");
	if(cache_policy) then
		cache_policy = System.localserver.CachePolicy:new(cache_policy)
	end	
	local srcPage = Map3DSystem.mcml.PageCtrl:new({
		url = mcmlNode:GetAbsoluteURL(mcmlNode:GetAttributeWithCode("src",nil,true)),
		cache_policy = cache_policy,
		parentpage = mcmlNode:GetPageCtrl(),
		click_through = click_through,
	});
	
	if(alignment == "_fi") then
		srcPage:Create(instName, _iframe, "_fi", 0, 0, 0, 0);
	else
		srcPage:Create(instName, _iframe, "_lt", 0, 0, width, height);
	end
	mcmlNode.pageCtrl = srcPage; -- keep a reference here
	mcmlNode.control = srcPage; 

	if(mcmlNode:GetBool("AutoSize")) then
		-- please note: AutoSize only takes effect when the parent page is refreshed and the inner page can be evaluated without using postponed page:refresh(). 
		local used_width, used_height = srcPage:GetUsedSize();
		if(used_width and used_height and (_iframe.width~= used_width or _iframe.height~= used_height)) then
			_iframe.width = used_width;
			_iframe.height = used_height;
			if(_bg) then
				_bg.width = used_width - width + _bg.width;
				_bg.height = used_height - height + _bg.height;
			end
			width = used_width;
			height = used_height;
		end
	end

	parentLayout:AddObject(width+margin_right+margin_left+padding_left+padding_right, height+margin_top+margin_bottom+padding_top+padding_bottom);
	parentLayout:NewLine();
end

-- get the MCML value on the node
function pe_iframe.GetValue(mcmlNode)
	return mcmlNode:GetAttributeWithCode("src");
end

-- set the MCML value on the node
function pe_iframe.SetValue(mcmlNode, value)
	mcmlNode:SetAttribute("src", value);
end

-- set the UI value on the node
function pe_iframe.SetUIValue(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		ctl:Redirect(value, nil, false, 0.1);
	end
end

-- refresh the page. 
function pe_iframe.Refresh(mcmlNode, pageInstName, value)
	if(mcmlNode.pageCtrl) then
		mcmlNode.pageCtrl:Refresh(value);
	end
end

-----------------------------------
-- pe_a: it handles HTML tags of <a>
-----------------------------------
local pe_a = {};
Map3DSystem.mcml_controls.pe_a = pe_a;

-- the control takes up whatever vertical space needed to display its inner content,
function pe_a.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end

	if(style) then
		style = {color=style.color, ["font-family"] = style["font-family"],  ["font-size"]=style["font-size"], ["font-weight"] = style["font-weight"], ["text-shadow"] = style["text-shadow"], ["shadow-color"]=style["shadow-color"], ["shadow-quality"]=style["shadow-quality"]}
	end
	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default[mcmlNode.name] or pe_html.css[mcmlNode.name], style);
	
	local padding_left, padding_top, padding_bottom, padding_right = 
			(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
			(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
			
	local myLayout = parentLayout:clone();
	myLayout:ResetUsedSize();
	
	myLayout:OffsetPos(padding_left, padding_top);
	myLayout:IncHeight(-padding_bottom);
	myLayout:IncWidth(-padding_right);
	
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = myLayout:GetPreferredRect();
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, 
			{color = mcmlNode:GetAttribute("color") or css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"], ["text-shadow"] = css["text-shadow"], ["shadow-color"]=css["shadow-color"], ["shadow-quality"]=css["shadow-quality"]}, myLayout)
	end
	
	local aval_width, aval_height;
	left, top, aval_width, aval_height = parentLayout:GetPreferredRect();
	
	local _, curPreferredY = myLayout:GetPreferredPos();
	if(curPreferredY>(padding_top+top)) then
		parentLayout:NewLine();
		left, top = parentLayout:GetPreferredPos();
	end
	width, height = myLayout:GetUsedSize();
	width, height = width+padding_right-left, height+padding_bottom-top;
	height = css["height"] or height;
	parentLayout:AddObject(width, height);
	
	local isbuttonstyle = mcmlNode:GetBool("isbuttonstyle");

	if(css["text-align"] == "center") then
		-- tricky: this allows "text-align" to work with <a>, well in some cases. 
		local center_padding = (aval_width - width - left);
		left = left + center_padding;
		width = width - center_padding;
	end

	local _this=ParaUI.CreateUIObject("button","b","_lt", left, top, width,height);
	if(css and css.background) then
		if(isbuttonstyle) then
			_this.background = css.background;
			if(css["background-color"]) then
				_guihelper.SetUIColor(_this, css["background-color"]);
			end
		else
			_guihelper.SetVistaStyleButton(_this, "", css.background, css["background-color"])
		end
		
	else
		_this.background = "";
	end
	local href = mcmlNode:GetAttributeWithCode("href");
	local onclick = mcmlNode:GetAttributeWithCode("onclick");

	if(href) then
		if(href ~= "#") then
			href = mcmlNode:GetAbsoluteURL(href);
		end	
		
		if(mcmlNode:GetAttributeWithCode("tooltip")) then
			_this.tooltip = mcmlNode:GetAttributeWithCode("tooltip")
		else
			_this.tooltip = "点击打开:"..href;
		end
			
		local _targetName = mcmlNode:GetString("target");
		if(type(_targetName) == "string") then
			-- open in an iframe target.we only support the iframe target
			
			if(_targetName== "_blank") then
				-- TODO: open in a new window
				if(href:match("^http://")) then
					-- TODO: this may be a security warning
					_this.onclick = string.format([[;ParaGlobal.ShellExecute("open", %q, "", "", 1);]], href);
				end
			elseif(_targetName== "_self") then
				-- open in current window	
				-- looking for an iframe in the ancestor of this node. 
				local pageCtrl = mcmlNode:GetPageCtrl();
				if (pageCtrl) then
					local pageCtrlName = pageCtrl.name;
					_this.onclick = string.format(";Map3DSystem.mcml_controls.pe_a.OnClickHRefToTarget(%q, %q)", href, pageCtrlName);
				else
					log("warning: mcml <a target=_self> can not find any iframe in its ancestor node to which the target url can be loaded\n");
				end
			elseif(string.match(_targetName, "^_mcmlblank")) then	
				-- open in a new mcml window	
				_this.onclick = string.format(";Map3DSystem.mcml_controls.pe_a.OnClickHRefToMcmlBrowser(%q, %q, %s, %s)", href, _targetName, 
					tostring(mcmlNode:GetAttribute("framewidth")), tostring(mcmlNode:GetAttribute("frameheight")));
			else
				-- search for iframes with the target name
				local iFrames = mcmlNode:GetRoot():GetAllChildWithName("iframe");
				local pageCtrlName, _;
				if(iFrames) then
					for _, iframe in ipairs(iFrames) do
						-- only accept iframe node with the same name of _targetName
						if(iframe:GetString("name") == _targetName) then
							pageCtrlName = iframe:GetInstanceName(rootName);
						end
					end
				end
				if(pageCtrlName) then
					_this.onclick = string.format(";Map3DSystem.mcml_controls.pe_a.OnClickHRefToTarget(%q, %q)", href, pageCtrlName);
				else
					log("warning: mcml <a> can not find the iframe target ".._targetName.."\n");
					_this.onclick = string.format(";Map3DSystem.mcml_controls.OnClickHRef(%q)", href);
				end	
			end	
		else
			_this.onclick = string.format(";Map3DSystem.mcml_controls.OnClickHRef(%q)", href);
		end
	elseif(onclick) then
		local i;
		local param1 = mcmlNode:GetAttributeWithCode("param1",nil,true);
		local param2 = mcmlNode:GetAttributeWithCode("param2",nil,true);
		local param3 = mcmlNode:GetAttributeWithCode("param3",nil,true);
		local param4 = mcmlNode:GetAttributeWithCode("param4",nil,true);
		local param5 = mcmlNode:GetAttributeWithCode("param5",nil,true);
		
		_this:SetScript("onclick", function(uiobj)
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, param1, param2, param3, param4, param5);
		end);

		if(mcmlNode:GetAttributeWithCode("tooltip")) then
			_this.tooltip = mcmlNode:GetAttributeWithCode("tooltip")
		end
	else
		if(mcmlNode:GetAttributeWithCode("tooltip")) then
			local tooltip = mcmlNode:GetAttributeWithCode("tooltip");
			local tooltip_page = string.match(tooltip or "", "page://(.+)");
			if(tooltip_page) then
				local is_lock_position, use_mouse_offset;
				if(mcmlNode:GetAttribute("tooltip_is_lock_position") == "true") then
					is_lock_position, use_mouse_offset = true, false
				end
				CommonCtrl.TooltipHelper.BindObjTooltip(_this.id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"),
					nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset);
			else
				_this.tooltip = tooltip;
			end
		end	
	end
	_parent:AddChild(_this);
end

-- onclick function of the href target is iframe
-- @param href: url
-- @param pageCtrlName: iframe PageCtrl name
function pe_a.OnClickHRefToTarget(href, pageCtrlName)
	if(href and href~="") then
		local ctl = CommonCtrl.GetControl(pageCtrlName);
		if(ctl ~= nil) then
			local cachePolicy -- = System.localserver.CachePolicy:new("access plus 0");
			ctl:Init(href, cachePolicy, true);
		end
	end	
end

-- onclick function of the href target is iframe. 
-- if x,y is not specified, it will center the window.If width, height is not provided, it will use default size 660,480
-- default zorder is 1. 
-- @param href: url
-- @param pageCtrlName: mcml popup window name. it usually begins with "_mcmlblank"
-- @param width, height: window width, height. 
function pe_a.OnClickHRefToMcmlBrowser(href, mcmlWindowName, width, height)
	width = width or 660
	height = height or 480
	
	local params = {url=href, name=mcmlWindowName, title=L"MCML Browser", DisplayNavBar = true, width=width, height=height}
	if(width and params.x == nil) then
		local ScreenWidth = ParaUI.GetUIObject("root").width
		params.x = (ScreenWidth-width)/2
	end
	if(height and params.y == nil) then
		local ScreenHeight = ParaUI.GetUIObject("root").height
		params.y = (ScreenHeight-height)/2
	end
	
	params.x = params.x or mouse_x;
	params.y = params.y or mouse_y;
	params.zorder = params.zorder or 1;
	Map3DSystem.App.Commands.Call("File.MCMLBrowser", params);
end

-- get the MCML value on the node
function pe_a.GetValue(mcmlNode)
	return mcmlNode:GetInnerText();
end

-- set the MCML value on the node
function pe_a.SetValue(mcmlNode, value)
	if(type(value) == "string") then
		mcmlNode:SetInnerText(value);
	end	
end


-----------------------------------
-- OBSOLETED 2008.5.26 use pe:download instead: pe_pe_a: it handles tags of <pe:a>
-----------------------------------
local pe_pe_a = {};
Map3DSystem.mcml_controls.pe_pe_a = pe_pe_a;

-- the control takes up whatever vertical space needed to display its inner content,
function pe_pe_a.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(style) then
		style = {color=style.color, ["font-family"] = style["font-family"],  ["font-size"]=style["font-size"], ["font-weight"] = style["font-weight"]}
	end
	
	local css = mcmlNode:GetStyle(pe_html.css[mcmlNode.name], style);
	
	local padding_left, padding_top, padding_bottom, padding_right = 
			(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
			(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);
			
	local myLayout = parentLayout:clone();
	myLayout:ResetUsedSize();
	myLayout:OffsetPos(padding_left, padding_top);
	myLayout:IncHeight(-padding_bottom);
	myLayout:IncWidth(-padding_right);
	
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = myLayout:GetPreferredRect();
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, 
			{color = mcmlNode:GetAttribute("color") or css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"]}, myLayout)
	end
	
	left, top = parentLayout:GetPreferredPos();
	local _, curPreferredY = myLayout:GetPreferredPos();
	if(curPreferredY > (padding_top + top)) then
		parentLayout:NewLine();
		left, top = parentLayout:GetPreferredPos();
	end
	width, height = myLayout:GetUsedSize();
	width, height = width + padding_right - left, height + padding_bottom - top;
	
	parentLayout:AddObject(width, height);
	
	local _btn = ParaUI.CreateUIObject("button", "b", "_lt", left, top, width, height);
	if(css and css.background) then
		_guihelper.SetVistaStyleButton(_btn, "", css.background)
		--_this.background = css.background;
	else
		_btn.background = "";
	end
	
	-- downloader
	--local _downloader = ParaUI.CreateUIObject("container", "c", "_lt", left, top, width, margin_top);
	local _downloader = ParaUI.CreateUIObject("container", "b", "_lt", left, top, width, height);
	_downloader.background = "";
	_parent:AddChild(_downloader);
	
	local ID = ParaGlobal.GenerateUniqueID();
	local _waiting = ParaUI.CreateUIObject("container", ID, "_ct", -32, -32, 64, 64);
	_waiting.background = "Texture/3DMapSystem/common/waiting.png";
	_downloader:AddChild(_waiting);
	
	
	--NPL.load("(gl)script/ide/progressbar.lua");
	--local ctl = CommonCtrl.progressbar:new{
		--name = "progressbar1",
		--alignment = "_lt",
		--left = 0, 
		--top = 0,
		--width = width, 
		--height = margin_top, 
		--Minimum = 0,
		--Maximum = 100,
		--Value = 30, 
		--Step = 10,
		--block_color = "97 0 255", -- "10 36 106",
		--parent = _downloader,
	--};
	--ctl:Show();
	
	
	local src = mcmlNode:GetString("src");
	local dest = mcmlNode:GetString("dest");
	
	if(src ~= nil and dest ~= nil) then
	
		local fileName = "script/UIAnimation/CommonProgress.lua.table";
		UIAnimManager.PlayUIAnimationSequence(_waiting, fileName, "WaitingSpin", true);
		
		-- resource store
		local ls = System.localserver.CreateStore("Downloader", 1);
		if(not ls) then
			log("error: failed creating local server ResourceStore \n")
			return 
		else
			log("web service store: Downloader is opened\n");
		end

		-- clear all. 
		--ls:DeleteAll();

		-- testing  get file
		--ls:GetFile(System.localserver.CachePolicy:new("access plus 1 hour"),
		ls:GetFile(System.localserver.CachePolicy:new("access plus 0"),
			src,
			function (entry)
				local _waiting = ParaUI.GetUIObject(ID);
				if(_waiting:IsValid() == true) then
					UIAnimManager.StopLoopingUIAnimationSequence(_waiting, fileName, "WaitingSpin");
					_waiting.visible = false;
					--_waiting.color = "0 0 0 0";
					_btn:BringToFront();
				end
				ParaIO.CopyFile(entry.payload.cached_filepath, dest, true);
				--log("SUCCEED: resource store\n entry = "..commonlib.serialize(entry));
			end
		);
	else
		_waiting.visible = false;
		_btn:BringToFront();
	end
	
	_this = _btn;
	
	local href = mcmlNode:GetString("href");
	if(href) then
		local _targetName = mcmlNode:GetString("target");
		if(type(_targetName) == "string") then
			-- open in an iframe target.we only support the iframe target
			_this.tooltip = "点击打开:"..href;
			
			if(_targetName== "_blank") then
				-- TODO: open in a new window	
			elseif(_targetName== "_self") then
				-- open in current window	
				-- looking for an iframe in the ancestor of this node. 
				local pageCtrl = mcmlNode:GetPageCtrl();
				if (pageCtrl) then
					local pageCtrlName = pageCtrl.name;
					_this.onclick = string.format(";Map3DSystem.mcml_controls.pe_a.OnClickHRefToTarget(%q, %q)", href, pageCtrlName);
				else
					log("warning: mcml <a target=_self> can not find any iframe in its ancestor node to which the target url can be loaded\n");
				end
			else
				-- search for iframes with the target name
				local iFrames = mcmlNode:GetRoot():GetAllChildWithName("iframe");
				local pageCtrlName, _;
				if(iFrames) then
					for _, iframe in ipairs(iFrames) do
						-- only accept iframe node with the same name of _targetName
						if(iframe:GetString("name") == _targetName) then
							pageCtrlName = iframe:GetInstanceName(rootName);
						end
					end
				end
				if(pageCtrlName) then
					_this.onclick = string.format(";Map3DSystem.mcml_controls.pe_a.OnClickHRefToTarget(%q, %q)", href, pageCtrlName);
				else
					log("warning: mcml <a> can not find the iframe target ".._targetName.."\n");
					_this.onclick = string.format(";Map3DSystem.mcml_controls.OnClickHRef(%q)", href);
				end	
			end	
		else
			href = mcmlNode:GetAbsoluteURL(href);
			_this.tooltip = "点击打开:"..href;
			_this.onclick = string.format(";Map3DSystem.mcml_controls.OnClickHRef(%q)", href);
		end
	end
	
	-- TODO: ondownloadcomplete function
	--		invoked when the download process is complete
	
	-- onclick function
	local name = mcmlNode:GetString("name") or "";
	local onclick = mcmlNode:GetString("onclick") or "";
	if(onclick ~= "") then
		local editorInstName;
		if(bindingContext) then
			editorInstName = bindingContext.editorInstName or "";
		end
		-- NOTE: small trick concatenate the onclick function string with the former one
		-- and invoke the pe_editor_button onclick function to trigger the callback function
		_this.onclick = (_this.onclick or "")..string.format(";Map3DSystem.mcml_controls.pe_editor_button.OnClick(%q,%q,%q)", editorInstName or "", name, onclick);
	end
	_parent:AddChild(_btn);
end

-----------------------------------
-- pe_img: it handles HTML tags of <img>
-----------------------------------
local pe_img = {};
Map3DSystem.mcml_controls.pe_img = pe_img;

-- the control takes up whatever vertical space needed to display its inner content,
-- @param mcmlNode: is a text
function pe_img.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end

	local src = mcmlNode:GetAttributeWithCode("src",nil,true) or "";
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["img"]) or {};
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	
	local bUseSpace;
	if(css.position == "absolute") then
		-- absolute positioning in parent
		left = (css.left or 0);
		top = (css.top or 0);
	elseif(css.position == "relative") then
		-- relative positioning in next render position. 
		left = left + (css.left or 0);
		top = top + (css.top or 0);
	else
		left = left + (css.left or 0);
		top = top + (css.top or 0);
		bUseSpace = true;	
	end
			
	local tmpWidth = tonumber(mcmlNode:GetAttributeWithCode("width")) or css.width
	if(tmpWidth) then
		if((left + tmpWidth+margin_left+margin_right)<width) then
			width = left + tmpWidth+margin_left+margin_right;
		else
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
			width = left + tmpWidth+margin_left+margin_right;
		end
	end
	local tmpHeight = tonumber(mcmlNode:GetAttributeWithCode("height")) or css.height
	if(tmpHeight) then
		height = top + tmpHeight+margin_top+margin_bottom
	end
			
	if(bUseSpace) then
		parentLayout:AddObject(width-left, height-top);
	end
	
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	local instName = mcmlNode:GetAttributeWithCode("uiname", nil, true);
	if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
		instName = mcmlNode:GetInstanceName(rootName);
	end	
	
	
	local _this = ParaUI.CreateUIObject("button",instName or "b","_lt", left, top, width-left, height-top);
	--_this.enabled = false;
	if(src == "") then
		_this.background = css.background or "";
	else
		-- tricky: this allows dynamic images to update itself, _this.background only handles static images with fixed size.
		if(string.match(src, "[;:]")) then
			_this.background = mcmlNode:GetAbsoluteURL(src);
		else
			_this.background = mcmlNode:GetAbsoluteURL(src);
		end	
	end
	if(css["background-repeat"] == "repeat") then
		_this:GetAttributeObject():SetField("UVWrappingEnabled", true);
	end
	local animstyle = mcmlNode:GetAttributeWithCode("animstyle",nil, true);
	if(animstyle) then
		_this.animstyle = tonumber(animstyle);
	end
	mcmlNode.uiobject_id = _this.id;

	local tooltip; 
	tooltip = mcmlNode:GetAttributeWithCode("bindtooltip");
	if(tooltip and tooltip ~= "")then
		CommonCtrl.TooltipHelper.BindObjTooltip(_this.id, tooltip, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"), mcmlNode:GetNumber("show_width"),mcmlNode:GetNumber("show_height"),mcmlNode:GetNumber("show_duration"), nil, nil, nil, mcmlNode:GetBool("is_lock_position"), mcmlNode:GetBool("use_mouse_offset"), mcmlNode:GetNumber("screen_padding_bottom"));
	else
		tooltip = mcmlNode:GetAttributeWithCode("tooltip",nil,true);
		if(tooltip) then
			_this.tooltip = tooltip;
		end
	end
	if(mcmlNode:GetNumber("zorder")) then
		_this.zorder = mcmlNode:GetNumber("zorder");
	end
	local enabled = mcmlNode:GetBool("enabled");
	if(enabled == false) then
		_this.enabled = false;
	end
	if(mcmlNode:GetBool("alwaysmouseover")) then
		_this:GetAttributeObject():SetField("AlwaysMouseOver", true);
	end
	_guihelper.SetUIColor(_this, mcmlNode:GetAttributeWithCode("color") or css["background-color"] or "255 255 255");
	
	_parent:AddChild(_this);
	
	local onclick = mcmlNode:GetString("onclick");
	if(onclick == "")then
		onclick = nil;
	end
	if(onclick) then
		local btnName = mcmlNode:GetAttributeWithCode("name",nil,true)
		-- tricky: we will just prefetch any params with code that may be used in the callback 
		local i;
		for i=1,5 do
			if(not mcmlNode:GetAttributeWithCode("param"..i)) then
				break;
			end
		end
		_this:SetScript("onclick", pe_img.on_click, mcmlNode, instName, bindingContext, btnName);
	end
	if(string.find(src, "http://")) then
		-- TODO: garbage collect HTTP textures after it is no longer used?
	end
end
-- this is the new on_click handler. 
-- @param instName: obsoleted field. can be nil.
function pe_img.on_click(uiobj, mcmlNode, instName, bindingContext, buttonName)
	if(not mcmlNode or not uiobj) then
		return
	end
	local onclick = mcmlNode.onclickscript or mcmlNode:GetString("onclick");
	if(onclick == "")then
		onclick = nil;
	end
	if(onclick) then
		local btnType = mcmlNode:GetString("type");
		if( btnType=="submit") then
			-- user clicks the normal button. 
			-- the callback function format is function(buttonName, values, bindingContext, mcmlNode) end
			local values;
			if(bindingContext) then
				bindingContext:UpdateControlsToData();
				values = bindingContext.values
			end	
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, buttonName, values, bindingContext, mcmlNode);
		else
			-- user clicks the button, yet without form info
			-- the callback function format is function(buttonName, mcmlNode) end
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, buttonName, mcmlNode)
		end
	end
end
-- get the MCML value on the node
function pe_img.GetValue(mcmlNode)
	local src = mcmlNode:GetAttribute("src");
	if(src == nil) then
		local css = mcmlNode:GetStyle();
		if(css) then
			src = css.background;
		end
	end
	return src;
end

-- set the MCML value on the node
function pe_img.SetValue(mcmlNode, value)
	mcmlNode:SetAttribute("src", value);
end

-- get the UI value on the node
function pe_img.GetUIValue(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		return ctl.background;
	end
end

-- set the UI value on the node
function pe_img.SetUIValue(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl and ctl.SetBGImageAndRect) then
		ctl.background = mcmlNode:GetAbsoluteURL(value);
	end
end

-----------------------------------
-- pe_label: it handles tags of <pe:label> or HTML <label>
-----------------------------------
local pe_label = {};
Map3DSystem.mcml_controls.pe_label = pe_label;

-- the control takes up all available spaces yet without creating any newline
-- @param mcmlNode: is a text
function pe_label.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end

	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:label"], style) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			width = left + css.width + margin_left  + margin_right
		end
	end
	if(css.height) then
		if((top + css.height)<height) then
			height = top + css.height + margin_top  + margin_bottom
		end
	end
	parentLayout:AddObject(width-left, height-top);
	
	left = left + margin_left
	top = top + margin_top + 2; -- add 2 pixels so that it has same height with pe:text
	width = width - margin_right - left;
	height = height - margin_bottom - top;
	
	local instName;
	if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
		instName = mcmlNode:GetInstanceName(rootName);
	end	
	
	local _this = ParaUI.CreateUIObject("text", instName or "b", "_lt", left, top, width, height);
	mcmlNode.uiobject_id = _this.id;
	_this.autosize=false;
	_this.background = css.background or "";
	if(css["text-shadow"]) then
		_this.shadow = true;
	end	
	_this.text = mcmlNode:GetAttributeWithCode("value", nil, true) or mcmlNode:GetInnerText();
	
	if(mcmlNode:GetBool("autosize")) then
		_this.autosize = true;
		_this:DoAutoSize();
	end
	
	local alignFormat = 16; -- wordbreak
	if(css["text-align"]) then
		if(css["text-singleline"] == "true") then
			alignFormat = alignFormat + 32;
		end
		if(css["text-noclip"] == "true") then
			alignFormat = alignFormat + 256;
		end
		if(css["text-valign"] == "center") then
			alignFormat = alignFormat + 4;
		end
		if(css["text-align"] == "right") then
			alignFormat = alignFormat + 2;
		elseif(css["text-align"] == "center") then
			alignFormat = alignFormat + 1;
		end
	end
	_guihelper.SetUIFontFormat(_this, alignFormat);
	if(css.color) then
		_guihelper.SetFontColor(_this, css.color);
	end
	
	if(css["font-family"] or css["font-size"] or css["font-weight"])then
		local font_family = css["font-family"] or "System";
		-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
		local font_size = math.floor(tonumber(css["font-size"] or 12));
		local max_font_size = tonumber(css["base-font-size"]) or 14;
		local min_font_size = tonumber(css["base-font-size"]) or 11;
		
		local scale;
		
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
		
		_this.font = font;
		if(scale) then
			_this.scalingx = scale;
			_this.scalingy = scale;
			_this.translationx = (width * scale - width)/2;
			_this.translationy = (height * scale - height)/2;
		end				
	end
		
	_parent:AddChild(_this);
end

-- get the MCML value on the node
function pe_label.GetValue(mcmlNode)
	return mcmlNode:GetInnerText();
end

-- set the MCML value on the node
function pe_label.SetValue(mcmlNode, value)
	mcmlNode:SetInnerText(tostring(value));
end

-- get the UI value on the node
function pe_label.GetUIValue(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		return ctl.text;
	end
end

-- set the UI value on the node
function pe_label.SetUIValue(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		if(value ~= nil) then
			value = tostring(value);
		end
		ctl.text = value;
		if(ctl.autosize == true) then
			ctl:DoAutoSize();
		end
	end
end

-- set the UI color on the node
function pe_label.SetUIColor(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		_guihelper.SetFontColor(ctl, value);
	end
end

-----------------------------------
-- pe_br: line break
-----------------------------------
local pe_br = commonlib.gettable("Map3DSystem.mcml_controls.pe_br");
function pe_br.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	parentLayout:NewLine();
end
