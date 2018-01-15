--[[
Title: all controls for editor display controls.
Author(s): LiXizhi
Date: 2008/2/15
Desc: pe:editor,pe:container(alignment="_ctt") pe:editor-divider, pe:editor-buttonset, pe:editor-button(DefaultButton=true), pe:editor-custom, form

---++ Button or input tag
| *Property*	| *Descriptions*				 |
| type			| "submit", "button", onclick event format is different for these two. |
| onclick		| onclick callback of type function(btnName,mcmlNode) if type is not "submit" or function(btnName, values, bindingContext), if type is "submit". document object is available inside the function. |
| param[1-5]	| additional params to be passed to onclick event.  |
| tooltip		| mouse over tooltip |
| enabled		| "true" or "false", whether to enable the button. |
| PasswordChar  | "*", if one wants to display "*" for any text input|
| DefaultButton	| boolean, default to false. if true it is the default button when enter is pressed. If type is submit, it is the default button by default. |
| textscale		| float of text scale, usually 1.1-1.5 | 
| shadow		| bool of shadow |
| animstyle		| int of ParaUIObject.animstyle |
| textcolor     | for single line editbox only. this is the text color. |
| cursor		| the mouse over cursor file |
| onkeyup		| onkeyup callback of type function(name,mcmlNode) if type is "text"|
| CaretColor    | the caret color of the edit box, only used when type is "text" and it is single lined | 
| autofocus     | if true, the text input will automatically get key focus. | 
| uiname		| the low level ui name. so that if unique, we will be able to get it via ParaUI.GetUIObject(uiname) |
| hotkey		|  the virtual key name such as "DIK_A, DIK_F1, DIK_SPACE" |
| href			| if there is no onclick event then this is same as <a> tag |
| spacing		| for text or button control.  |
button css property
| background-rotation	| [-3.14, 3.14]|
| padding				| spacing between the foreground image and background2 image |
| spacing				| spacing between the text and background, mostly used in auto sized button |
| text-align			| "left","right", default to center aligned |
| text-valign			| "top", "center", default to center aligned vertically. Note text-align must be specified in order for this attribute to take effect.  |
| text-noclip			| true, false, default to false. whether text should be cliped. Note text-align must be specified in order for this attribute to take effect.   |
| text-singleline		| true, false, default to true. whether text should be single lined. Note text-align must be specified in order for this attribute to take effect.  |
| text-wordbreak        | default to false. |
| text-offset-x			| offset the text inside the button |
| text-offset-y			| offset the text inside the button |
| min-width				| min-width of the button. if the button text is long, the actual width may be bigger. |
| max-width				| max-width of the button. force using left align if text is too long. |
Here is a sample of a button with padding
<verbatim>
	<input type="button" name="btn1" value="hello" tooltip="button with padding and background2" style="padding:10px;background2:url(Texture/alphadot.png);" />
</verbatim>

__note__: if button type property is "submit", it must be inside a form tag, in order for its bindingcontext and values to take effect in its onclick event handler. 

---++ pe:container and pe:editor tags
only these tags support css right float and css vertical alignment, as well as alignment property e.g.
   1. style="float:right;vertical-align: bottom" is similar to "_rb" or right bottom in NPL. And it does not consume parent space. 
   1. style="float:left;vertical-align: bottom" is similar to "_lb" or right bottom in NPL. And it does not consume parent space. 
   1. style="float:right;" is similar to "_rt" or right top  in NPL. And it does not consume parent space. 
   1. alignment="_ctt", where the alignment property supports all NPL alignment types
   1. relation and visible style attributes are supported. 

| *Property*	| *Descriptions* |
| ClickThrough | true to click through |
| onclick | function(name, mcmlNode) end | 
| onsize | this is useful to detect size change of windows.  |
| SelfPaint | whether it will paint on its own render target. name attribute must be specified. |
| oncreate | function(name, mcmlNode) end, called when container is just created.  | 
| for | function(name, mcmlNode) end  |
| valign | "center" which will vertically align using the used height of inner controls. userful if the inner text height is unknown. |

---++ form tag
it is similar to html form tag except that the target property recoginizes mcml targets. 

*target property* <br/>
It may be "_self", "_blank", "_mcmlblank", "[iframename]". if this property is specified, the href will be regarded as mcml page file even if it begins with http. 
iframename can be any iframe control name, where the href mcml page will be opened. if it is "_self", it will be opened in the current page control.
if it is "_mcmlblank", it will be opened in a new popup mcml window. 

---++ textarea
| *Property*	| *Descriptions* |
| rows | number of rows |
| endofline | we shall replace all occurances of endofline text inside inner text with "\n". Commonly used endofline is ";" and "<br/>" |
| WordWrap  | boolean, default to "false", whether use word wrapping, only valid when SingleLineEdit is true|
| SingleLineEdit | boolean, default to "false", whether to use one line only for editing. It is possible to edit in one line and show in multiple line when WordWrap is true. |
| enable_ime |  false to disable ime |
| syntax_map | text highlighter to use. currently only "NPL","PureText" are supported. default to nil. |
| EmptyText | empty text to display such as "click to enter text ..." |
| VerticalScrollBarStep | |
| fontsize | font size to use for multiline text. | 
| css.lineheight | line height for multiline text. |
| spacing	| for text or button control.  |
| UseSystemControl | true to use advanced multiple line edit box in new system control |
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_editor.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_hotkey.lua");
local hotkey_manager = commonlib.gettable("Map3DSystem.mcml_controls.hotkey_manager");
NPL.load("(gl)script/ide/TooltipHelper.lua");
local mcml_controls = commonlib.gettable("Map3DSystem.mcml_controls");
-----------------------------------
-- pe:editor and pe:container control
-----------------------------------
local pe_editor = commonlib.gettable("Map3DSystem.mcml_controls.pe_editor");
-- all temp bindings: a mapping from pe_editor instance name to its binding object. 
pe_editor.allBindings = {};

-- create a new binding object with an editor instance name. 
function pe_editor.NewBinding(instName, bindingContext)
	bindingContext = bindingContext or commonlib.BindingContext:new();
	bindingContext.editorInstName = instName;
	bindingContext.values = bindingContext.values or {};
	pe_editor.allBindings[instName] = bindingContext;
	return bindingContext;
end

-- get the binding context. the bindingContext.values is the data source, which is a table of name value pairs retrieved from the sub controls. 
function pe_editor.GetBinding(instName)
	return pe_editor.allBindings[instName];
end

-- create editor or pe_container
function pe_editor.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	local instName = mcmlNode:GetInstanceName(rootName);
	if(mcmlNode.name == "pe:editor") then
		-- create a new binding context whenever a pe_editor is met. 
		bindingContext = pe_editor.NewBinding(instName, bindingContext);
		bindingContext.formNode_ = mcmlNode;
	end	
	
	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default[mcmlNode.name] or Map3DSystem.mcml_controls.pe_html.css[mcmlNode.name]) or {};
	
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

	local availWidth, availHeight = parentLayout:GetPreferredSize();
	local maxWidth, maxHeight = parentLayout:GetMaxSize();
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
		width,height = myLayout:GetSize();
	elseif(css.position == "relative") then
		-- relative positioning in next render position. 
		myLayout:OffsetPos(css.left, css.top);
		width,height = myLayout:GetSize();
	else
		left, top, width, height = myLayout:GetPreferredRect();
		myLayout:SetPos(left,top);
		bUseSpace = true;	
	end
	
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
	
	-- create editor container
	local parent_left, parent_top, parent_width, parent_height = myLayout:GetPreferredRect();
	
	parent_left = parent_left-padding_left;
	parent_top = parent_top-padding_top;
	parent_width = parent_width + padding_right
	parent_height = parent_height + padding_bottom
	local _this
	if(alignment == "_fi") then
		left, top, width, height = parentLayout:GetPreferredRect();
		_this = ParaUI.CreateUIObject("container", instName, alignment, parent_left, parent_top, width-(parent_width), height-(parent_height))
	else
		_this = ParaUI.CreateUIObject("container", instName, alignment, parent_left, parent_top, parent_width-parent_left,parent_height-parent_top)
	end
	_parent:AddChild(_this);
	_parent = _this;

	if(mcmlNode:GetAttributeWithCode("SelfPaint", nil)) then
		_this:SetField("SelfPaint", true);
	end
	mcmlNode.uiobject_id = _this.id;

	--replaced by leio:2012/08/15
	--if(mcmlNode:GetBool("visible", true) == false) then
		--_this.visible = false;
	--end
	local visible = mcmlNode:GetAttributeWithCode("visible", nil, true);
	visible = tostring(visible);
	if(visible and visible == "false")then
		_this.visible = false;
	end
	
	if(mcmlNode:GetBool("enabled", true) == false) then
		_this.enabled = false;
	end

	if(mcmlNode:GetNumber("zorder")) then
		_this.zorder = mcmlNode:GetNumber("zorder");
	end
	local bClickThrough = mcmlNode:GetAttributeWithCode("ClickThrough")
	if( bClickThrough==true or bClickThrough == "true") then
		_this:SetField("ClickThrough", true);
	end

	if(css["background-color"]) then
		css.background = css.background or "Texture/whitedot.png";
	end

	if(css.background) then
		_this.background = css.background;
		if(css["background-color"]) then
			_guihelper.SetUIColor(_this, css["background-color"]);
		end
		if(css["colormask"]) then
			_guihelper.SetColorMask(_this, css["colormask"]);
		end
	end
	
	-- create contentLayout, so that they are all relative to the new container.
	local contentLayout = myLayout:clone();
	contentLayout:OffsetPos(-parent_left, -parent_top);
	contentLayout:IncHeight(-parent_top)
	contentLayout:IncWidth(-parent_left)
	contentLayout:SetUsedSize(contentLayout:GetAvailablePos())
	
	-- create each child node. 
	pe_editor.refresh(rootName, mcmlNode, bindingContext, _parent, 
		{color = css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["base-font-size"]=css["base-font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"],["line-height"] = css["line-height"], 
			 ["text-shadow"] = css["text-shadow"], ["shadow-color"]=css["shadow-color"], ["shadow-quality"]=css["shadow-quality"]
		}, contentLayout)
	
	-- calculate used size
	local width, height = contentLayout:GetUsedSize(); 
	if(mcmlNode:GetAttribute("valign") == "center") then 
		local _, used_height = contentLayout:GetUsedSize();
		local _, parent_height = contentLayout:GetSize();
		local offset_y = math.floor((parent_height - used_height)*0.5);
		if(offset_y > 0) then
			width = width + offset_y;
			_parent.y = _parent.y + offset_y;
		end
	end

	myLayout:AddObject(width-padding_left, height-padding_top);
	
	local left, top = parentLayout:GetAvailablePos();
	width, height = myLayout:GetUsedSize()
	width = width + padding_right + margin_right
	height = height + padding_bottom + margin_bottom
	if(css.width) then
		width = left + css.width + margin_left+margin_right;
	end	
	if(css.height) then
		height = top + css.height + margin_top+margin_bottom;
	end
	-- resize container
	if(alignment ~= "_fi") then
		_parent.height = height-top-margin_top-margin_bottom;
		_parent.width = width-left-margin_right-margin_left;
	end	
	
	if(alignment == "_lt") then
		if(bUseSpace) then
			parentLayout:AddObject(width-left, height-top);
			if(not css.float) then
				parentLayout:NewLine();
			end	
		end
	elseif(alignment == "_rt") then
		_parent.x = - _parent.width- margin_left - margin_right;
	elseif(alignment == "_rb") then
		_parent.x = - _parent.width- margin_left - margin_right;
		_parent.y = - _parent.height- margin_top - margin_bottom;
	elseif(alignment == "_lb") then
		_parent.y = - _parent.height- margin_top - margin_bottom;
	end	
	
	if(css.visible and css.visible== "false") then
		_parent.visible = false;
	end

	-- handle onclick event
	local onclick;
	local onclick_for;
	local ontouch;

	onclick = mcmlNode:GetString("onclick");
	if(onclick == "") then
		onclick = nil;
	end
	onclick_for = mcmlNode:GetString("for");
	if(onclick_for == "") then
		onclick_for = nil;
	end
	ontouch = mcmlNode:GetString("ontouch");
	if(ontouch == "") then
		ontouch = nil;
	end

	local tooltip = mcmlNode:GetString("tooltip");
	if(tooltip and tooltip~="") then
		_parent.tooltip = tooltip;
	end

	local btnName = mcmlNode:GetAttributeWithCode("name")
	if(onclick_for or onclick or ontouch) then
		-- tricky: we will just prefetch any params with code that may be used in the callback 
		for i=1,5 do
			if(not mcmlNode:GetAttributeWithCode("param"..i)) then
				break;
			end
		end
		if(onclick_for or onclick) then
			_parent:SetScript("onmouseup", Map3DSystem.mcml_controls.pe_editor_button.on_click, mcmlNode, nil, bindingContext, btnName);
		elseif(ontouch) then
			_parent:SetScript("ontouch", Map3DSystem.mcml_controls.pe_editor_button.on_touch, mcmlNode, nil, bindingContext, btnName);
		end
	end

	local oncreate_callback = mcmlNode:GetAttributeWithCode("oncreate");
	if(oncreate_callback) then
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, oncreate_callback, btnName, mcmlNode)
	end

	local onsize_callback = mcmlNode:GetAttributeWithCode("onsize");
	if(onsize_callback) then
		_parent:SetScript("onsize",  function(uiobj)
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onsize_callback, btnName, mcmlNode, uiobj)
		end)
	end
end

-- refresh the inner controls. 
function pe_editor.refresh(rootName, mcmlNode, bindingContext, _parent, style, contentLayout)
	-- clear this container
	_parent:RemoveAll();
	
	-- create all child nodes UI controls. 
	local labelwidth = mcmlNode:GetNumber("labelwidth");
	local _, childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = contentLayout:GetPreferredRect();
		
		if((type(childnode) == "table") and 
			(childnode.name == "pe:editor-text" or childnode.name == "pe:editor-custom" or childnode.name == "pe:editor-buttonset" or childnode.name == "pe:editor-divider"))then
			local lableText = childnode:GetAttribute("label");
			if(lableText and lableText~="") then
				local _this = ParaUI.CreateUIObject("text", "", "_lt", left, top+3, labelwidth, 16)
				--_guihelper.SetUIFontFormat(_this, 2 + 32 + 256); -- align to right and single lined. 
				_this.text = lableText;
				_parent:AddChild(_this);
			end
			
			contentLayout:NewLine();
			local innerLayout = contentLayout:clone();
			innerLayout:OffsetPos(labelwidth, nil);
			left, top, width, height = innerLayout:GetPreferredRect();
			Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, innerLayout)
			contentLayout:AddChildLayout(innerLayout);
			contentLayout:NewLine();
		else
			Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, contentLayout)
		end	
	end
end
-----------------------------------
-- HTML <form> control
-----------------------------------
local pe_form = {};
Map3DSystem.mcml_controls.pe_form = pe_form;
-- similar to HTML <form>
function pe_form.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	local instName = mcmlNode:GetInstanceName(rootName);
	-- create a new binding context whenever a pe_editor is met. 
	bindingContext = pe_editor.NewBinding(instName, bindingContext);
	bindingContext.formNode_ = mcmlNode;
	
	-- create each child node. 
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = parentLayout:GetPreferredRect();
		Map3DSystem.mcml_controls.create(rootName,childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	end
end

-----------------------------------
-- pe:editor-custom control
-----------------------------------
local pe_editor_custom = {};
Map3DSystem.mcml_controls.pe_editor_custom = pe_editor_custom;

-- increase the top by height. 
function pe_editor_custom.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	parentLayout:NewLine();
	local myLayout = parentLayout:clone();
	myLayout:ResetUsedSize();
	
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = myLayout:GetPreferredRect();
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, myLayout)
	end
	myLayout:NewLine();
	local left, top = parentLayout:GetAvailablePos();
	local width, height = myLayout:GetUsedSize();
	width, height = width-left, height -top;
	local minHeight = mcmlNode:GetNumber("height");
	if(minHeight>height) then
		height = minHeight;
	end
	parentLayout:AddObject(width, height);
	parentLayout:NewLine();
end


-----------------------------------
-- pe:editor-buttonset control
-----------------------------------
local pe_editor_buttonset = commonlib.gettable("Map3DSystem.mcml_controls.pe_editor_buttonset");

-- increment left by the width of this button. Button width is sized according to text length. 
-- the buttonset control takes up 26 pixels in height
function pe_editor_buttonset.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	parentLayout:NewLine();
	local myLayout = parentLayout:clone();
	myLayout:ResetUsedSize();
	local css = mcmlNode:GetStyle();
	
	-- search any buttons 
	local childnode;
	for childnode in mcmlNode:next("pe:editor-button") do
		local left, top, width, height = myLayout:GetPreferredRect();
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, nil, myLayout)
	end
	myLayout:NewLine();
	local left, top = parentLayout:GetAvailablePos();
	local width, height = myLayout:GetUsedSize();
	width, height = width-left, height -top;
	parentLayout:AddObject(width, height);
	parentLayout:NewLine();
	
	if(css and css.background) then
		local _this=ParaUI.CreateUIObject("button","s","_lt", left, top, width, height);
		_this.background = css.background;
		_this.enabled = false;
		if(css["background-color"]) then
			_guihelper.SetUIColor(_this, css["background-color"]);
		else
			_guihelper.SetUIColor(_this, "255 255 255 255");
		end	
		_parent:AddChild(_this);
		_this:BringToBack();
	end
end


-----------------------------------
-- pe:editor-button control
-----------------------------------

local pe_editor_button = commonlib.gettable("Map3DSystem.mcml_controls.pe_editor_button");

-- a mapping from button name to mcml node instance.
pe_editor_button.button_instances = {};

-- the button control takes up 26 pixels in height, and button itself is 22 pixel height and has a default spacing of 5. 
function pe_editor_button.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	local buttonText =  mcmlNode:GetString("text") or mcmlNode:GetAttributeWithCode("value", nil, true) or mcmlNode:GetInnerText();
	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default["pe:editor-button"] or Map3DSystem.mcml_controls.pe_html.css["pe:editor-button"]);

	local textscale = mcmlNode:GetNumber("textscale") or css.textscale;

	--
	-- for font: font-family: Arial; font-size: 14pt;font-weight: bold; 
	-- 
	local font;
	local scale;
	if(css and (css["font-family"] or css["font-size"] or css["font-weight"]))then
		local font_family = css["font-family"] or "System";
		-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
		local font_size = math.floor(tonumber(css["font-size"] or 12));
		local max_font_size = 20;
		local min_font_size = 11;
		if(font_size>max_font_size) then
			font_size = max_font_size;
		end
		if(font_size<min_font_size) then
			font_size = min_font_size;
		end
		local font_weight = css["font-weight"] or "norm";
		font = string.format("%s;%d;%s", font_family, font_size, font_weight);
	end
	
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	

	local maxWidth, maxHeight = parentLayout:GetMaxSize();
	local width, height = mcmlNode:GetAttribute("width"), mcmlNode:GetAttribute("height");
	if(width) then
		css.width = tonumber(string.match(width, "%d+"));
		if(css.width and string.match(width, "%%$")) then
			if(css.position == "screen") then
				css.width = ParaUI.GetUIObject("root").width * css.width/100;
			else
				local availWidth, availHeight = parentLayout:GetPreferredSize();	
				css.width=math.floor((maxWidth-margin_left-margin_right)*css.width/100);
				if(availWidth<(css.width+margin_left+margin_right)) then
					css.width=availWidth-margin_left-margin_right;
				end
				if(css.width<=0) then
					css.width = nil;
				end
			end	
		end	
	end
	if(height) then
		css.height = tonumber(string.match(height, "%d+"));
		if(css.height and string.match(height, "%%$")) then
			if(css.position == "screen") then
				css.height = ParaUI.GetUIObject("root").height * css.height/100;
			else	
				css.height=math.floor((maxHeight-margin_top-margin_bottom)*css.height/100);
				local availWidth, availHeight = parentLayout:GetPreferredSize();	
				if(availHeight<(css.height+margin_top+margin_bottom)) then
					css.height=availHeight-margin_top-margin_bottom;
				end
				if(css.height<=0) then
					css.height = nil;
				end
			end	
		end	
	end
		
	local buttonWidth;
	local height = css.height or 22;

	if(css.width) then
		buttonWidth = css.width;
	else
		buttonWidth = _guihelper.GetTextWidth(buttonText, font) * (textscale or 1);
		local spacing = mcmlNode:GetNumber("spacing") or css.spacing;
		if(spacing) then
			buttonWidth = buttonWidth + spacing * 2;
		else
			buttonWidth = buttonWidth + 5;
		end
		
		if(css["min-width"]) then
			local min_width = css["min-width"];
			if(min_width and min_width>buttonWidth) then
				buttonWidth = min_width;
			end
		elseif(css["max-width"]) then
			local max_width = css["max-width"];
			if(max_width and max_width<buttonWidth) then
				if((buttonWidth - max_width) > 20) then
					css["text-align"] = css["text-align"] or "left";
				end
				buttonWidth = max_width;
			end
		end
	end
	if(css.padding) then
		buttonWidth = buttonWidth + css.padding*2;
		height = height + css.padding*2;
	end
		
	width = parentLayout:GetPreferredSize();
	
	if((buttonWidth+margin_left+margin_right)>width) then
		parentLayout:NewLine();
		width = parentLayout:GetMaxSize();
		if(buttonWidth>width and not css.width) then
			buttonWidth = width
		end
	end
	left, top = parentLayout:GetAvailablePos();

	local align = mcmlNode:GetAttribute("align") or css.align;
	if(align and align~="left") then
		local max_width = buttonWidth;
		local left, top, right, bottom = parentLayout:GetAvailableRect();
		-- align at center. 
		if(align == "center") then
			margin_left = (maxWidth - max_width)/2
		elseif(align == "right") then
			margin_left = right - max_width - margin_right - left;
		end	
	end
	
	-- align at center. 
	local valign = mcmlNode:GetAttribute("valign");
	if(valign and valign~="top") then
		local max_height = css.height;
		local left, top, right, bottom = myLayout:GetAvailableRect();
		if(valign == "center") then
			height = height + (maxHeight - max_height)/2
		elseif(valign == "bottom") then
			height = bottom - max_height - margin_bottom;
		end	
	end	
	
	local instName = mcmlNode:GetAttributeWithCode("uiname", nil, true) or mcmlNode:GetInstanceName(rootName);
	local _this = ParaUI.CreateUIObject("button", instName or "b", "_lt", left+margin_left, top+margin_top, buttonWidth, height)
	mcmlNode.uiobject_id = _this.id; -- keep the uiobject's reference id
	if(css.padding) then
		_this:SetField("Padding", css.padding)
	end
	if(css["text-offset-x"]) then
		_this:SetField("TextOffsetX", tonumber(css["text-offset-x"]) or 0)
	end
	if(css["text-offset-y"]) then
		_this:SetField("TextOffsetY", tonumber(css["text-offset-y"]) or 0)
	end

	if(buttonText and buttonText~="") then
		_this.text = buttonText;
	end
	if(font) then
		_this.font = font;
	end
	local bg = mcmlNode:GetAttributeWithCode("background");
	
	if(bg or css.background) then
		local replace_bg = mcmlNode:GetAttributeWithCode("Replace_BG");
		if(replace_bg)then
			_this.background = replace_bg;
		else
			_this.background = bg or css.background;
		end

		local normal_bg = mcmlNode:GetAttributeWithCode("Normal_BG") or css.Normal_BG;
		local mouseover_bg = mcmlNode:GetAttributeWithCode("MouseOver_BG") or css.MouseOver_BG;
		local pressed_bg = mcmlNode:GetAttributeWithCode("Pressed_BG") or css.Pressed_BG;
		local disabled_bg = mcmlNode:GetAttributeWithCode("Disabled_BG") or normal_bg or css.background;
		if(normal_bg and mouseover_bg and pressed_bg and disabled_bg) then
			_guihelper.SetVistaStyleButton3(_this, normal_bg, mouseover_bg, disabled_bg, pressed_bg);
		elseif(normal_bg and mouseover_bg and pressed_bg == nil) then
			_guihelper.SetVistaStyleButton3(_this, normal_bg, mouseover_bg, disabled_bg, nil);
		end
		if(css["background-color"]) then
			_guihelper.SetUIColor(_this, css["background-color"]);
		end
		if(css["background-rotation"]) then
			_this.rotation = tonumber(css["background-rotation"])
		end
		if(css.color) then
			_guihelper.SetButtonFontColor(_this, css.color, css.color2);
		end
	else
		if(pe_editor.default_button_offset_y) then
			_this:SetField("TextOffsetY", pe_editor.default_button_offset_y);
		end
	end
	if(css.background2) then
		local bg2_color;
		if(css["background2-color"]) then
			bg2_color = css["background2-color"]
		end
		_guihelper.SetVistaStyleButton(_this, nil, css.background2, bg2_color);
	end
	
	local alignFormat = 1;	-- center align
	if(css["text-align"]) then
		if(css["text-align"] == "right") then
			alignFormat = 2;
		elseif(css["text-align"] == "left") then
			alignFormat = 0;
		end
	end
	if(css["text-singleline"] ~= "false") then
		alignFormat = alignFormat + 32;
	else
		if(css["text-wordbreak"] == "true") then
			alignFormat = alignFormat + 16;
		end
	end
	if(css["text-noclip"] ~= "false") then
		alignFormat = alignFormat + 256;
	end
	if(css["text-valign"] ~= "top") then
		alignFormat = alignFormat + 4;
	end
	_guihelper.SetUIFontFormat(_this, alignFormat)
		
	if(mcmlNode:GetAttribute("enabled")) then
		if(mcmlNode:GetBool("enabled") == nil) then
			_this.enabled = mcmlNode:GetAttributeWithCode("enabled");
		else
			_this.enabled = mcmlNode:GetBool("enabled");
		end
	end
	local visible = mcmlNode:GetAttributeWithCode("visible", nil, true);
	if(visible~=true and visible and tostring(visible) == "false")then
		_this.visible = false;
	end

	local zorder = mcmlNode:GetNumber("zorder") or css.zorder;
	if(zorder) then
		_this.zorder = zorder;
	end
		
	local href = mcmlNode:GetAttributeWithCode("href");
	local onclick = mcmlNode.onclickscript or mcmlNode:GetString("onclick");
	if(onclick == "")then
		onclick = nil;
	end
	local onclick_for = mcmlNode:GetString("for");
	if(onclick_for == "") then
		onclick_for = nil;
	end
	local ontouch = mcmlNode:GetString("ontouch");
	if(ontouch == "")then
		ontouch = nil;
	end
	if(href) then
		if(href ~= "#") then
			href = mcmlNode:GetAbsoluteURL(href);
		end
		-- open in current window	
		-- looking for an iframe in the ancestor of this node. 
		local pageCtrl = mcmlNode:GetPageCtrl();
		if(pageCtrl) then
			local pageCtrlName = pageCtrl.name;
			if(href:match("^http://")) then
				-- TODO: this may be a security warning
				_this.onclick = string.format([[;ParaGlobal.ShellExecute("open", %q, "", "", 1);]], href);
			else
				_this.onclick = string.format(";Map3DSystem.mcml_controls.pe_a.OnClickHRefToTarget(%q, %q)", href, pageCtrlName);
			end
		else
			log("warning: mcml <input type=\"button\"> can not find any iframe in its ancestor node to which the target url can be loaded\n");
		end
	elseif(onclick or onclick_for or ontouch) then
		local btnName = mcmlNode:GetAttributeWithCode("name",nil,true)
		-- tricky: we will just prefetch any params with code that may be used in the callback 
		local i;
		for i=1,5 do
			if(not mcmlNode:GetAttributeWithCode("param"..i)) then
				break;
			end
		end
		local hotkey = mcmlNode:GetAttributeWithCode("hotkey", nil, true);
		if(hotkey and onclick) then
			hotkey_manager.register_key(hotkey, function(virtual_key)
				local uiobj;
				if(mcmlNode.uiobject_id) then
					uiobj = ParaUI.GetUIObject(mcmlNode.uiobject_id);
					if(uiobj and uiobj:IsValid()) then
						return pe_editor_button.on_click(uiobj, mcmlNode, instName, bindingContext, btnName);
					end
				end
			end, mcmlNode.uiobject_id);
		end
		if(onclick or onclick_for) then
			_this:SetScript("onclick", pe_editor_button.on_click, mcmlNode, instName, bindingContext, btnName);
		elseif(ontouch) then
			_this:SetScript("ontouch", pe_editor_button.on_touch, mcmlNode, instName, bindingContext, btnName);
		end
	end
	local onmouseenter = mcmlNode:GetString("onmouseenter");
	if(onmouseenter and onmouseenter ~= "")then
		_this:SetScript("onmouseenter", pe_editor_button.onmouseenter, mcmlNode, instName, bindingContext, btnName);
	end
	local onmouseleave = mcmlNode:GetString("onmouseleave");
	if(onmouseleave and onmouseleave ~= "")then
		_this:SetScript("onmouseleave", pe_editor_button.onmouseleave, mcmlNode, instName, bindingContext, btnName);
	end

	local force_ui_name = mcmlNode:GetAttributeWithCode("force_ui_name");
	if(force_ui_name) then
		_this.name = force_ui_name;
	end
	
	-- create a default button for the container to allow enter in text input to directly invoke submit call
	local btnType = mcmlNode:GetString("type");
	if(btnType == "submit") then
		_this:SetDefault(true);
	end

	local tooltip = mcmlNode:GetAttributeWithCode("tooltip",nil,true);
	if(tooltip and tooltip ~= "")then
		local tooltip_page = string.match(tooltip or "", "page://(.+)");
		local tooltip_static_page = string.match(tooltip or "", "page_static://(.+)");
		if(tooltip_page) then
			CommonCtrl.TooltipHelper.BindObjTooltip(mcmlNode.uiobject_id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"), mcmlNode:GetNumber("show_width"),mcmlNode:GetNumber("show_height"),mcmlNode:GetNumber("show_duration"), nil, nil, nil, mcmlNode:GetBool("is_lock_position"), mcmlNode:GetBool("use_mouse_offset"), mcmlNode:GetNumber("screen_padding_bottom"));
		elseif(tooltip_static_page) then
			CommonCtrl.TooltipHelper.BindObjTooltip(mcmlNode.uiobject_id, tooltip_static_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"), mcmlNode:GetNumber("show_width"),mcmlNode:GetNumber("show_height"),mcmlNode:GetNumber("show_duration"),mcmlNode:GetBool("enable_tooltip_hover"),mcmlNode:GetBool("click_through"));
		else
			_this.tooltip = tooltip;
		end
	end
	local animstyle = mcmlNode:GetNumber("animstyle") or css.animstyle
	if(animstyle) then
		_this.animstyle = animstyle;
	end
	
	if(textscale) then
		_this.textscale = mcmlNode:GetNumber("textscale") or css.textscale;
	end
	if(mcmlNode:GetBool("shadow") or css["text-shadow"]) then
		_this.shadow = true;
		if(css["shadow-quality"]) then
			_this:SetField("TextShadowQuality", tonumber(css["shadow-quality"]) or 0);
		end
		if(css["shadow-color"]) then
			_this:SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD(css["shadow-color"]));
		end
	end
		
	if(mcmlNode:GetBool("alwaysmouseover")) then
		_this:SetField("AlwaysMouseOver", true);
	end
		
	_parent:AddChild(_this);
		
	if(mcmlNode:GetAttribute("DefaultButton")) then
		_this:SetDefault(true);
	end
	
	local cursor_file = mcmlNode:GetAttributeWithCode("cursor");
	if(cursor_file and cursor_file~="") then
		_this.cursor = cursor_file;
	end

	if(css.position ~= "relative") then
		parentLayout:AddObject(buttonWidth+margin_left+margin_right, margin_top+margin_bottom+height);
	end
end
-- @param instName: obsoleted field. can be nil.
function pe_editor_button.onmouseenter(uiobj, mcmlNode, instName, bindingContext, buttonName)
	if(not mcmlNode or not uiobj) then
		return
	end
	local onmouseenter = mcmlNode:GetString("onmouseenter");
	if(onmouseenter == "")then
		onmouseenter = nil;
	end
	local result;
	if(onmouseenter) then
		-- the callback function format is function(buttonName, mcmlNode, touchEvent) end
		result = Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onmouseenter, buttonName, mcmlNode)
	end
	return result;
end
-- @param instName: obsoleted field. can be nil.
function pe_editor_button.onmouseleave(uiobj, mcmlNode, instName, bindingContext, buttonName)
	if(not mcmlNode or not uiobj) then
		return
	end
	local onmouseleave = mcmlNode:GetString("onmouseleave");
	if(onmouseleave == "")then
		onmouseleave = nil;
	end
	local result;
	if(onmouseleave) then
		-- the callback function format is function(buttonName, mcmlNode, touchEvent) end
		result = Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onmouseleave, buttonName, mcmlNode)
	end
	return result;
end
-- @param instName: obsoleted field. can be nil.
function pe_editor_button.on_touch(uiobj, mcmlNode, instName, bindingContext, buttonName)
	if(not mcmlNode or not uiobj) then
		return
	end
	local ontouch = mcmlNode:GetString("ontouch");
	if(ontouch == "")then
		ontouch = nil;
	end
	local result;
	if(ontouch) then
		-- the callback function format is function(buttonName, mcmlNode, touchEvent) end
		result = Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, ontouch, buttonName, mcmlNode, msg)
	end
	return result;
end

-- this is the new on_click handler. 
-- @param instName: obsoleted field. can be nil.
function pe_editor_button.on_click(uiobj, mcmlNode, instName, bindingContext, buttonName)
	if(not mcmlNode or not uiobj) then
		return
	end
	local onclick = mcmlNode.onclickscript or mcmlNode:GetString("onclick");
	if(onclick == "")then
		onclick = nil;
	end
	local onclick_for = mcmlNode:GetString("for");
	if(onclick_for == "") then
		onclick_for = nil;
	end
	local result;
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
			result = Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, buttonName, values, bindingContext, mcmlNode);
		else
			-- user clicks the button, yet without form info
			-- the callback function format is function(buttonName, mcmlNode) end
			result = Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, buttonName, mcmlNode)
		end
	end
	if(onclick_for) then
		-- call the OnClick method of the mcml control by id or name
		local pageCtrl = mcmlNode:GetPageCtrl();
		if(pageCtrl) then
			local target_node = pageCtrl:GetNodeByID(onclick_for);
			if(target_node) then
				if(target_node ~= mcmlNode) then
					target_node:InvokeMethod("HandleClickFor", mcmlNode, bindingContext);
				else
					LOG.std(nil, "warn", "mcml", "the for target of %s can not be itself", onclick_for);	
				end
			else
				LOG.std(nil, "warn", "mcml", "the for target of %s is not found in the page", onclick_for);
			end
		end
	end
	return result;
end

-- some other control forwarded a click message to this control
-- @param mcmlNode: the for node target
-- @param fromNode: from which node the click event is fired. 
function pe_editor_button.HandleClickFor(mcmlNode, fromNode, bindingContext)
	local uiobj;
	if(mcmlNode.uiobject_id) then
		uiobj = ParaUI.GetUIObject(mcmlNode.uiobject_id);
	end
	pe_editor_button.on_click(uiobj, mcmlNode, nil, bindingContext, mcmlNode:GetAttribute("name"));
end

-- obsoleted: get the onclick script based on the button node and bindingContext
-- @param instName: button instance name for the mcmlNode
-- @param mcmlNode: the mcml button node object
-- @param bindingContext: the bindingContext
-- @return: nil or the onclick script with heading ";"
function pe_editor_button.GetOnClickScript(instName, mcmlNode, bindingContext)
	local onclickscript;
	local editorInstName;
	if(bindingContext) then
		editorInstName = bindingContext.editorInstName or ""
	end
	local name, onclick = mcmlNode:GetAttributeWithCode("name") or "", mcmlNode.onclickscript or mcmlNode:GetString("onclick") or "";
	local btnType = mcmlNode:GetString("type")
	if(onclick ~= "") then
		if( btnType=="submit") then
			onclickscript = string.format(";Map3DSystem.mcml_controls.pe_editor_button.OnClick(%q,%q,%q,%q)", editorInstName or "", name, onclick, instName or "");
		else
			onclickscript = string.format(";Map3DSystem.mcml_controls.pe_editor_button.OnGeneralClick(%q,%q,%q)", name, onclick, instName or "");
		end	
	else
		if(btnType == "submit")then
			-- if it is a submit button without onclick, we will search for <form> and <pe:editor> tag
			-- and use automatic HTTP URL GET. 
		
			local formNode = mcmlNode:GetParent("form") or mcmlNode:GetParent("pe:editor")
			if(formNode) then
				-- find target page ctrl inside which to open the new url
				local pageCtrlName;
				local _targetName = formNode:GetString("target");
				if(_targetName==nil or _targetName== "_self") then
					-- open in current window	
					-- looking for an iframe in the ancestor of this node. 
					local pageCtrl = formNode:GetPageCtrl();
					if (pageCtrl) then
						pageCtrlName = pageCtrl.name;
					else
						log("warning: mcml <form> can not find any iframe in its ancestor node to which the target url can be loaded\n");
					end
											
				elseif(_targetName== "_blank") then
					-- TODO: open in a new window	
				elseif(_targetName== "_mcmlblank") then
					-- TODO: open in a new window	
				else
					-- search for iframes with the target name
					local iFrames = formNode:GetRoot():GetAllChildWithName("iframe");
					local _;
					if(iFrames) then
						for _, iframe in ipairs(iFrames) do
							-- only accept iframe node with the same name of _targetName
							if(iframe:GetString("name") == _targetName) then
								pageCtrlName = iframe:GetInstanceName(rootName);
							end
						end
					end
					if(not pageCtrlName) then
						log("warning: mcml <form> can not find the iframe target ".._targetName.."\n");
					end	
				end
				if(pageCtrlName) then
					--
					-- find target url
					--
					local url = formNode:GetAttribute("action");
					if(url) then
						onclickscript = string.format(";Map3DSystem.mcml_controls.pe_editor_button.OnSubmit(%q,%q,%q,%q)", editorInstName or "", name, url, pageCtrlName);
					else
						log("warning: <form> or <pe:editor> tag does not have a action attribute, the submit button has no where to post request.\n");
					end
				end	
			else
				log("warning: a submit button is not inside <form> or <pe:editor> node \n")	
			end
		end
	end	
	return onclickscript;
end

-- get the MCML value on the node
function pe_editor_button.GetValue(mcmlNode)
	return mcmlNode:GetAttribute("text") or mcmlNode:GetAttribute("value") or mcmlNode:GetInnerText();
end

-- get the MCML value on the node
function pe_editor_button.SetValue(mcmlNode, value)
	if(mcmlNode:GetAttribute("text")) then
		mcmlNode:SetAttribute("text", value);
	elseif(mcmlNode:GetAttribute("value"))then	
		mcmlNode:SetAttribute("value", value);
	elseif(mcmlNode:GetInnerText()~="") then
		mcmlNode:SetInnerText(value)
	else
		-- default to value property
		mcmlNode:SetAttribute("value", value);
	end
end

-- get the UI value on the node
function pe_editor_button.GetUIValue(mcmlNode, pageInstName)
	local btn = mcmlNode:GetControl(pageInstName);
	if(btn) then
		return btn.text;
	end
end

-- set the UI value on the node
function pe_editor_button.SetUIValue(mcmlNode, pageInstName, value)
	local btn = mcmlNode:GetControl(pageInstName);
	if(btn) then
		if(type(value) == "number") then
			value = tostring(value);
		elseif(type(value) == "table") then
			return
		end 
		btn.text = value;
	end
end

-- set the UI enabled on the node
function pe_editor_button.SetUIEnabled(mcmlNode, pageInstName, value)
	local btn = mcmlNode:GetControl(pageInstName);
	mcmlNode:SetAttribute("enabled", tostring(value));
	if(btn) then
		if(type(value) == "boolean") then
			btn.enabled = value;
		end 
	end
end

-- get the UI background on the node
function pe_editor_button.GetUIBackground(mcmlNode, pageInstName)
	local btn = mcmlNode:GetControl(pageInstName);
	if(btn) then
		if(type(value) == "string") then
			return btn.background;
		end 
	end
end

-- set the UI background on the node
function pe_editor_button.SetUIBackground(mcmlNode, pageInstName, value)
	local btn = mcmlNode:GetControl(pageInstName);
	mcmlNode:SetCssStyle("background", value);
	if(btn) then
		if(type(value) == "string") then
			btn.background = value;
			--mcmlNode:SetCssStyle("background", value);
		end 
	end
end
-- Public method: for button. 
-- @param bEnable: true to enable the button. 
function pe_editor_button.SetEnable(mcmlNode, pageInstName, bEnabled)
	local btn = mcmlNode:GetControl(pageInstName);
	if(btn) then
		local invisibleondisabled = mcmlNode:GetBool("invisibleondisabled");
		if(invisibleondisabled == true) then
			btn.visible = (bEnabled == true);
		end
		btn.enabled = (bEnabled == true);
	end
end

-- obsoleted: user clicks the button yet without form info
-- the callback function format is function(buttonName, mcmlNode) end
function pe_editor_button.OnGeneralClick(buttonName, callback, instName)
	Map3DSystem.mcml_controls.OnPageEvent(pe_editor_button.button_instances[instName], callback, buttonName, pe_editor_button.button_instances[instName])
end

-- obsoleted: similar to pe_editor_button.OnGeneralClick except that the callback function is called with given parameters. 
function pe_editor_button.OnParamsClick(callback, instName, ...)
	Map3DSystem.mcml_controls.OnPageEvent(pe_editor_button.button_instances[instName], callback, ...)
end

-- obsoleted: user clicks the normal button. 
-- the callback function format is function(buttonName, values, bindingContext) end
function pe_editor_button.OnClick(editorInstName, buttonName, callback, instName)
	local bindingContext;
	if(editorInstName and editorInstName~="")then
		bindingContext = pe_editor.GetBinding(editorInstName);
	end	
	local values;
	if(bindingContext) then
		bindingContext:UpdateControlsToData();
		values = bindingContext.values
	end	
	Map3DSystem.mcml_controls.OnPageEvent(pe_editor_button.button_instances[instName], callback, buttonName, values, bindingContext)
end

-- obsoleted(may be refactored in future): user clicks the submit button. we will automatically post to url. Local server is not used. 
-- @param buttonName
-- @param editorInstName
-- @param url: the HTTP get url
-- @param pageCtrlName: where to open the submitted page
function pe_editor_button.OnSubmit(editorInstName, buttonName, url, pageCtrlName)
	local bindingContext = pe_editor.GetBinding(editorInstName);
	local values;
	if(bindingContext) then
		bindingContext:UpdateControlsToData();
		values = bindingContext.values
		if(url) then
			local ctl = CommonCtrl.GetControl(pageCtrlName);
			if(ctl ~= nil) then
				NPL.load("(gl)script/ide/System/localserver/UrlHelper.lua");
				url = System.localserver.UrlHelper.BuildURLQuery(url, values);
				--_guihelper.MessageBox(url.."\n"..pageCtrlName.."\n");
				-- disable caching for page get in this place
				local cachePolicy = System.localserver.CachePolicy:new("access plus 0");
				ctl:Init(url, cachePolicy, true);
			else
				log("warning: unable to find page ctrl "..pageCtrlName.."\n")	
			end
		end
	end	
end

-----------------------------------
-- pe:editor-text control
-----------------------------------

local pe_editor_text = {};
Map3DSystem.mcml_controls.pe_editor_text = pe_editor_text;

-- increment top by the height of the control. 
-- the control takes up (22*rows) pixels in height, and editbox itself is 22 pixel height. 
function pe_editor_text.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local name = mcmlNode:GetAttributeWithCode("name",nil,true);
	local text =  mcmlNode:GetAttribute("text") or mcmlNode:GetAttributeWithCode("value",nil,true) or mcmlNode:GetInnerText();
	local rows =  mcmlNode:GetNumber("rows") or 1;
	
	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default["pe:editor-text"] or mcml_controls.pe_html.css["pe:editor-text"]);
	
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
		
	local left, top, width, height = parentLayout:GetPreferredRect();
	local lineheight;
	if(css["line-height"]) then
		lineheight = tonumber(css["line-height"]);
	end
	width, height = width-left-margin_left-margin_right, css.height or (lineheight or 20)*rows;
	if(css.width and (rows==1 or css.width<width)) then
		width = css.width
	end
	if(css.height and (rows==1 or css.height<height)) then
		height = css.height;
	end	
	parentLayout:AddObject(width+margin_left+margin_right, margin_top+margin_bottom+height);
	left=left+margin_left;
	top=top+margin_top
	
	local instName = mcmlNode:GetAttributeWithCode("uiname", nil, true) or mcmlNode:GetInstanceName(rootName);
	
	if(rows>1 or mcmlNode.name=="textarea") then
		
		-- multiline editbox
		NPL.load("(gl)script/ide/MultiLineEditbox.lua");
		local ctl = CommonCtrl.MultiLineEditbox:new{
			name = instName,
			alignment = "_lt",
			left=left, top=top,
			width = width,
			height = height,
			parent = _parent,
			DefaultNodeHeight = lineheight,
			fontsize = mcmlNode:GetNumber("fontsize"),
			ReadOnly = mcmlNode:GetBool("ReadOnly"),
			ShowLineNumber = mcmlNode:GetBool("ShowLineNumber"),
			SingleLineEdit = mcmlNode:GetBool("SingleLineEdit"),
			VerticalScrollBarStep = mcmlNode:GetNumber("VerticalScrollBarStep"),
			WordWrap = mcmlNode:GetBool("WordWrap"),
			textcolor = mcmlNode:GetString("textcolor") or css.textcolor,
			empty_text = mcmlNode:GetAttributeWithCode("EmptyText"),
			container_bg = "",
			bUseSystemControl = mcmlNode:GetBool("UseSystemControl"),
		};
		local onkeyup = mcmlNode:GetString("onkeyup");
		if(onkeyup)then
			ctl.onkeyup = function()
				Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onkeyup, name, mcmlNode);
			end
		end

		local onchange = mcmlNode:GetString("onchange");
		if(onchange)then
			ctl.onchange = function()
				Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onchange, name, mcmlNode);
			end
		end

		local syntax_map = mcmlNode:GetString("syntax_map");
		if(syntax_map) then
			ctl.syntax_map = CommonCtrl.MultiLineEditbox["syntax_map_"..syntax_map];
		end

		ctl:Show(true);
		local endofline = mcmlNode:GetString("endofline")
		if(endofline) then
			text = string.gsub(text, endofline, "\n");
		end
		ctl:SetText(text);
		mcmlNode.control = ctl;
		if(bindingContext and name) then
			bindingContext:AddBinding(bindingContext.values, name, instName, commonlib.Binding.ControlTypes.IDE_editbox, "text")
		end
	else
		-- single line editbox
		local _this;
		if(("password" == mcmlNode:GetString("type")) or mcmlNode:GetString("PasswordChar")) then
			_this = ParaUI.CreateUIObject("editbox", instName, "_lt", left, top, width, height)
			_this.text = text;
			_this.background = css.background;
			_this.PasswordChar = mcmlNode:GetString("PasswordChar") or "*";
			_parent:AddChild(_this);
		else
			if(mcmlNode:GetString("enable_ime") ~= "false") then
				_this = ParaUI.CreateUIObject("imeeditbox", instName, "_lt", left, top, width, height)
			else
				_this = ParaUI.CreateUIObject("editbox", instName, "_lt", left, top, width, height)
			end
			_this.text = text;
			_this.background = css.background;
			_parent:AddChild(_this);
		end	
		if(_this and mcmlNode:GetBool("ReadOnly")) then
			_this.enabled = false;
		end
		mcmlNode.uiobject_id = _this.id;

		if(System.options.IsMobilePlatform and css and (css["font-family"] or css["font-size"] or css["font-weight"]))then
			local font_family = css["font-family"] or "System";
			-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
			local font_size = math.floor(tonumber(css["font-size"] or 12));
			local font_weight = css["font-weight"] or "norm";
			local font = string.format("%s;%d;%s", font_family, font_size, font_weight);
			_this.font = font;
		end
		
		local empty_text = mcmlNode:GetAttributeWithCode("EmptyText");
		if(empty_text and empty_text~="") then
			_this:SetField("EmptyText", empty_text);
		end

		if(mcmlNode:GetBool("autofocus")) then
			_this:Focus();
		end
		
		if(mcmlNode:GetString("tooltip")) then
			_this.tooltip = mcmlNode:GetString("tooltip")
		end

		local spacing = mcmlNode:GetNumber("spacing")
		if(spacing) then
			_this.spacing = spacing;
		end

		if(mcmlNode:GetString("onkeyup")) then
			_this:SetScript("onkeyup", pe_editor_text.onkeyup, mcmlNode, instName, bindingContext, name);
		end
		if(mcmlNode:GetString("onmodify") or mcmlNode:GetString("onchange")) then
			_this:SetScript("onmodify", pe_editor_text.onmodify, mcmlNode, instName, bindingContext, name);
		end
		if(mcmlNode:GetString("onactivate")) then
			_this:SetScript("onactivate", pe_editor_text.onactivate, mcmlNode, instName, bindingContext, name);
		end

		local CaretColor = mcmlNode:GetString("CaretColor") or css.CaretColor;
		if(CaretColor) then
			_this:SetField("CaretColor", _guihelper.ColorStr_TO_DWORD(CaretColor));
		end
		
		if(css["text-shadow"]) then
			_this.shadow = true;
			if(css["shadow-quality"]) then
				_this:SetField("TextShadowQuality", tonumber(css["shadow-quality"]) or 0);
			end
			if(css["shadow-color"]) then
				_this:SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD(css["shadow-color"]));
			end
		end
		

		local text_color = mcmlNode:GetString("textcolor") or css.textcolor;
		if(text_color) then
			_guihelper.SetFontColor(_this, text_color)
		end
		
		if(bindingContext and name) then
			bindingContext:AddBinding(bindingContext.values, name, instName, commonlib.Binding.ControlTypes.ParaUI_editbox, "text")
		end
	end	
end
-- this is the new on_click handler. 
function pe_editor_text.onactivate(uiobj, mcmlNode, instName, bindingContext, name)
	if(not mcmlNode or not uiobj) then
		return
	end
	local onactivate = mcmlNode:GetString("onactivate") or "";
	-- the callback function format is function(name, mcmlNode) end
	Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onactivate, name, mcmlNode,uiobj);
end

-- this is the new on_click handler. 
function pe_editor_text.onkeyup(uiobj, mcmlNode, instName, bindingContext, name)
	if(not mcmlNode or not uiobj) then
		return
	end
	local onkeyup = mcmlNode:GetString("onkeyup") or "";
	-- the callback function format is function(name, mcmlNode) end
	Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onkeyup, name, mcmlNode,uiobj);
end

-- this is the onchange handler. 
function pe_editor_text.onmodify(uiobj, mcmlNode, instName, bindingContext, name)
	if(not mcmlNode or not uiobj) then
		return
	end
	local onmodify = mcmlNode:GetString("onmodify") or mcmlNode:GetString("onchange") or "";
	-- the callback function format is function(name, mcmlNode) end
	Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onmodify, name, mcmlNode,uiobj);
end


-- get the MCML value on the node
function pe_editor_text.GetValue(mcmlNode)
	local text = mcmlNode:GetAttribute("text") or mcmlNode:GetAttribute("value") or mcmlNode:GetInnerText();
	if(mcmlNode:GetBool("UseBadWordFilter")) then
		text = MyCompany.Aries.Chat.BadWordFilter.FilterString(text);
	end
	return text;
end

-- set the MCML value on the node
function pe_editor_text.SetValue(mcmlNode, value)
	if(type(value) == "number") then
		value = tostring(value);
	elseif(type(value) == "table") then
		return
	end 
	
	if(mcmlNode:GetAttribute("text")) then
		mcmlNode:SetAttribute("text", value);
	elseif(mcmlNode:GetAttribute("value"))then	
		mcmlNode:SetAttribute("value", value);
	elseif(mcmlNode:GetInnerText()~="") then
		mcmlNode:SetInnerText(value)
	else
		-- default to value property
		mcmlNode:SetAttribute("value", value);
	end
end

-- get the UI value on the node
function pe_editor_text.GetUIValue(mcmlNode, pageInstName)
	local editBox = mcmlNode:GetControl(pageInstName);
	if(editBox) then
		if(type(editBox)=="table" and type(editBox.GetText) == "function") then
			return editBox:GetText();
		else
			return editBox.text;
		end	
	end
end

-- set the UI value on the node
function pe_editor_text.SetUIValue(mcmlNode, pageInstName, value)
	local editBox = mcmlNode:GetControl(pageInstName);
	if(editBox) then
		if(type(value) == "number") then
			value = tostring(value);
		elseif(type(value) == "table") then
			return
		end 
		if(type(editBox)=="table" and type(editBox.SetText) == "function") then
			editBox:SetText(value);
		else
			editBox.text = value;
		end	
	end
end

-----------------------------------
-- pe:editor-divider control: just render a dummy gray line
-----------------------------------
local pe_editor_divider = {};
Map3DSystem.mcml_controls.pe_editor_divider = pe_editor_divider;

-- increment top by divider height, e.g. 5 pixels. 
function pe_editor_divider.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,  style, parentLayout)
	parentLayout:NewLine();
	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default["hr"] or Map3DSystem.mcml_controls.pe_html.css["hr"]);
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	local left, top, width = parentLayout:GetPreferredRect();
	local height = css.height or 1;
	parentLayout:AddObject(width-left, margin_top+margin_bottom+height);
	parentLayout:NewLine();
	
	local _this = ParaUI.CreateUIObject("button", "b", "_lt", left+margin_left, top+margin_top, width-left-margin_left-margin_right, height)
	_this.enabled = false;
	if(css.background) then
		_this.background = css.background;
		if(css["background-color"]) then
			_guihelper.SetUIColor(_this, css["background-color"]);
		else
			_guihelper.SetUIColor(_this, "255 255 255 255");
		end	
	end
	_parent:AddChild(_this);
end


