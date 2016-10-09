--[[
Title: html form input tags. it belongs to the pe editor tags category and requires pe_editor to run. 
Author(s): LiXizhi
Date: 2008/2/19
Desc: HTMP<input> pe:editor-radiobox(same as <input type="radio">) pe:editor-checkbox (same as <input type="checkbox">) 
HTML<select AllowUserEdit="false"> and <option>, where AllowUserEdit default to false

---++ select
|AllowUserEdit| bool|
| IsReadonly | bool|
| onclick | on select event, function(name,value) end|
| onselect | same as onclick.|
| DataSource | the data source table array of {{value="0", text="zero"},{value="1"}}, where the each sub item is attr table of option node.  |
<verbatim>
	<select name="blood" AllowUserEdit="false">
        <option value="0" selected="selected">O</option>
        <option value="2">A</option>
        <option value="3">B</option>
        <option value="4">AB</option>
    </select><br/>
	<select name="blood" AllowUserEdit="false" DataSource='<%={{value="0", text="zero", selected="true"},{value="1"},{value="2"},}%>'>
	</select><br/>
</verbatim>

---++ input type radio box
Single or multiple selection radio box. 
| attribute | description |
| max | default to 1, how many items can be selected in the group at the same time. |
| min | default to 1, at least one must be selected |
| Label | inner text |
| onclick | a callback of type function(value, mcmlNode) end |
| checked | "true" or "false". default ot false.  |
| tooltip | mouse over tips |
| CheckedBG | unchecked background texture. if nil, it first defaults to css.background, then default to default style.  |
| UncheckedBG | unchecked background texture. if nil, it first defaults to css.background, then default to default style.  |
| background2 | background2 texture, when unselected this is the mouse over bg texture, when selected, this is a permenent bg texture |
| css.padding | number default to 0, the spacing between foreground image and backround image |

Note: GetValue() will return a second paramter containing a table array of selected values, if max attribute is larger than 1. 

<verbatim>
	<form>
		<input type="radio" name="gender" value="male" checked="true"/>Male
		<input type="radio" name="gender" value="female" checked="true"/>Female
	</form>
	
	-- onclick event is also supported, where OnRadioClicked(value, mcmlNode). value is the radio box value
	<input type="radio" name="groupname" max="2" value="ClickValue1" onclick="OnRadioClicked()"/>Click1
	<input type="radio" name="groupname" max="2" value="ClickValue2" onclick="OnRadioClicked()"/>Click2
	<input type="radio" name="groupname" max="2" value="ClickValue3" onclick="OnRadioClicked()"/>Click3
	<script type="text/npl">
		function OnRadioClicked(value, mcmlNode)    
			_guihelper.MessageBox(value);
			local v,values = pageCtrl:GetValue("groupname");
			commonlib.echo({value, v, values});
		end
	</script>
</verbatim>

---++ input type check box
check box control.It can be inside form node or not. checked property can have script binding
<verbatim>
	<input type="checkbox" name="MyCheckBox" checked="true"/>Click Me
	-- onclick event is also supported, where OnCheckBoxClicked(bChecked, mcmlNode). 
	<input type="checkbox" name="MyCheckBox" onclick="OnCheckBoxClicked()"/>Click1
	<script type="text/npl">
		function OnCheckBoxClicked(bChecked, mcmlNode)    
			_guihelper.MessageBox(bChecked);
		end
	</script>
</verbatim>

*properties*
| checked | |
| tooltip | |
| onclick | function(bChecked, mcmlNode) end |

---++ pe:fileupload
it displays a text box and Browse button.  When click the button, pe:fileupload shows a windows system open file dialog to select a file to textbox. 
It is equivalent to <input type="file" />

*example*
<verbatim>
	The node may contain inner child templates. e.g.
	<pe:fileupload name="filename" type="file" onchange=""><input style="width:200px"/><input type="button" value="browse..."/><pe:fileupload>
	if inner template does not exist, it will create them by default. e.g. simply write: 
	<pe:fileupload name="filename" type="file" onchange="" dir="worlds">
</verbatim>

*properties*
| dir | initial directory. such as "worlds", "texture". if dir property is nil, it will open using external win32 file browser. If not, it will use internal IDE file browser. |
| onchange | a callback function of type function(fileloaderName, filename) end |
| fileext | nil (default to all media file), "*." (folder only) or string, such as "all files(*.*)", "images(*.jpg; *.png; *.dds)", "animations(*.swf; *.wmv; *.avi)", "web pages(*.htm; *.html; *.xml)" |
| CheckFileExists | boolean, if false, it will check file existance. defaults to true. |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_html_input.lua");
-------------------------------------------------------
]]
local L = CommonCtrl.Locale("IDE");

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-----------------------------------
-- html <input> control: radio, checkbox, text
-----------------------------------
local pe_input = {};
Map3DSystem.mcml_controls.pe_input = pe_input;

function pe_input.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout)
	local type = mcmlNode:GetString("type");
	if(type == nil or type == "text") then
		Map3DSystem.mcml_controls.pe_editor_text.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout);	
	elseif(type == "password") then
		Map3DSystem.mcml_controls.pe_editor_text.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout);	
	elseif(type == "radio") then
		Map3DSystem.mcml_controls.pe_editor_radio.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout);
	elseif(type == "checkbox") then
		Map3DSystem.mcml_controls.pe_editor_checkbox.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout);
	elseif(type == "hidden") then
		Map3DSystem.mcml_controls.pe_editor_hidden.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout);
	elseif(type == "submit" or type == "button" or type == "reset" ) then
		Map3DSystem.mcml_controls.pe_editor_button.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	elseif(type == "file") then
		Map3DSystem.mcml_controls.pe_fileupload.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	else
		-- TODO: others types
	end
end

-- get the MCML value on the node
function pe_input.GetValue(mcmlNode)
	local type = mcmlNode:GetString("type");
	if(type == nil or type == "text") then
		-- bad word filter for Aries project
		if(mcmlNode:GetBool("SkipAutoBadWordFilter")) then
			return Map3DSystem.mcml_controls.pe_editor_text.GetValue(mcmlNode);
		else
			if(commonlib.getfield("MyCompany.Aries.Chat.BadWordFilter")) then
				local ret = Map3DSystem.mcml_controls.pe_editor_text.GetValue(mcmlNode);
				return Map3DSystem.mcml_controls.pe_editor_text.GetValue(mcmlNode);
			else
				return Map3DSystem.mcml_controls.pe_editor_text.GetValue(mcmlNode);
			end
		end
	elseif(type == "password") then
		return Map3DSystem.mcml_controls.pe_editor_text.GetValue(mcmlNode);
	elseif(type == "radio") then
		return Map3DSystem.mcml_controls.pe_editor_radio.GetValue(mcmlNode);
	elseif(type == "checkbox") then
		return Map3DSystem.mcml_controls.pe_editor_checkbox.GetValue(mcmlNode);
	elseif(type == "hidden") then
		return Map3DSystem.mcml_controls.pe_editor_hidden.GetValue(mcmlNode);
	elseif(type == "submit" or type == "button" or type == "reset" ) then
		return Map3DSystem.mcml_controls.pe_editor_button.GetValue(mcmlNode);
	elseif(type == "file") then
		return Map3DSystem.mcml_controls.pe_fileupload.GetValue(mcmlNode);
	else
		-- TODO: others types
	end
end

-- get the MCML value on the node
function pe_input.SetValue(mcmlNode, value)
	local type = mcmlNode:GetString("type");
	if(type == nil or type == "text") then
		Map3DSystem.mcml_controls.pe_editor_text.SetValue(mcmlNode, value);
	elseif(type == "password") then
		Map3DSystem.mcml_controls.pe_editor_text.SetValue(mcmlNode, value);
	elseif(type == "radio") then
		Map3DSystem.mcml_controls.pe_editor_radio.SetValue(mcmlNode, value);
	elseif(type == "checkbox") then
		Map3DSystem.mcml_controls.pe_editor_checkbox.SetValue(mcmlNode, value);
	elseif(type == "hidden") then
		Map3DSystem.mcml_controls.pe_editor_hidden.SetValue(mcmlNode, value);
	elseif(type == "submit" or type == "button" or type == "reset" ) then
		Map3DSystem.mcml_controls.pe_editor_button.SetValue(mcmlNode, value);
	elseif(type == "file") then
		Map3DSystem.mcml_controls.pe_fileupload.SetValue(mcmlNode, value);
	else
		-- TODO: others types
	end
end

-- get the UI value on the node
function pe_input.GetUIValue(mcmlNode, pageInstName)
	local type = mcmlNode:GetString("type");
	if(type == nil or type == "text") then
		if(mcmlNode:GetBool("SkipAutoBadWordFilter")) then
			return Map3DSystem.mcml_controls.pe_editor_text.GetUIValue(mcmlNode, pageInstName);
		else
			-- bad word filter for Aries project
			if(commonlib.getfield("MyCompany.Aries.Chat.BadWordFilter")) then
				local ret = Map3DSystem.mcml_controls.pe_editor_text.GetUIValue(mcmlNode, pageInstName);
				return MyCompany.Aries.Chat.BadWordFilter.FilterString(ret);
			else
				return Map3DSystem.mcml_controls.pe_editor_text.GetUIValue(mcmlNode, pageInstName);
			end
		end
	elseif(type == "file") then
		return Map3DSystem.mcml_controls.pe_fileupload.GetUIValue(mcmlNode, pageInstName);
	elseif(type == "submit" or type == "button" or type == "reset" ) then
		return Map3DSystem.mcml_controls.pe_editor_button.GetUIValue(mcmlNode, pageInstName);
	elseif(type == "checkbox") then	
		return Map3DSystem.mcml_controls.pe_editor_checkbox.GetUIValue(mcmlNode, pageInstName);
	elseif(type == "radio") then
		return Map3DSystem.mcml_controls.pe_editor_radio.GetUIValue(mcmlNode, pageInstName);
	end	
end

-- set the UI value on the node
function pe_input.SetUIValue(mcmlNode, pageInstName, value)
	local type = mcmlNode:GetString("type");
	if(type == nil or type == "text") then
		Map3DSystem.mcml_controls.pe_editor_text.SetUIValue(mcmlNode, pageInstName, value);
	elseif(type == "file") then
		Map3DSystem.mcml_controls.pe_fileupload.SetUIValue(mcmlNode, pageInstName, value);
	elseif(type == "submit" or type == "button" or type == "reset" ) then
		Map3DSystem.mcml_controls.pe_editor_button.SetUIValue(mcmlNode, pageInstName, value);	
	elseif(type == "checkbox") then	
		Map3DSystem.mcml_controls.pe_editor_checkbox.SetUIValue(mcmlNode, pageInstName, value);
	elseif(type == "radio") then
		Map3DSystem.mcml_controls.pe_editor_radio.SetUIValue(mcmlNode, pageInstName, value);
	end	
end

-- some other control forwarded a click message to this control
-- @param mcmlNode: the for node target
-- @param fromNode: from which node the click event is fired. 
function pe_input.HandleClickFor(mcmlNode, fromNode, bindingContext)
	local type = mcmlNode:GetString("type");
	
	if(type == "submit" or type == "button" or type == "reset" ) then
		Map3DSystem.mcml_controls.pe_editor_button.HandleClickFor(mcmlNode, fromNode, bindingContext);	
	elseif(type == "checkbox") then	
		Map3DSystem.mcml_controls.pe_editor_checkbox.HandleClickFor(mcmlNode, fromNode, bindingContext);	
	elseif(type == "radio") then
		Map3DSystem.mcml_controls.pe_editor_radio.HandleClickFor(mcmlNode, fromNode, bindingContext);	
	end	
end

-- set the UI background on the node
function pe_input.GetUIBackground(mcmlNode, pageInstName)
	local type = mcmlNode:GetString("type");
	if(type == "submit" or type == "button") then
		return Map3DSystem.mcml_controls.pe_editor_button.GetUIBackground(mcmlNode, pageInstName);
	end	
end

-- set the UI background on the node
function pe_input.SetUIBackground(mcmlNode, pageInstName, value)
	local type = mcmlNode:GetString("type");
	if(type == "submit" or type == "button") then
		Map3DSystem.mcml_controls.pe_editor_button.SetUIBackground(mcmlNode, pageInstName, value);
	end	
end

-- set the UI enabled on the node
function pe_input.SetUIEnabled(mcmlNode, pageInstName, value)
	local type = mcmlNode:GetString("type");
	if(type == "submit" or type == "button") then
		Map3DSystem.mcml_controls.pe_editor_button.SetUIEnabled(mcmlNode, pageInstName, value);
	end	
end

-- public method
function pe_input.SetEnable(mcmlNode, pageInstName, value)
	local type = mcmlNode:GetString("type");
	if(type == nil or type == "text") then
		
	elseif(type == "submit" or type == "button" or type == "reset" ) then
		Map3DSystem.mcml_controls.pe_editor_button.SetEnable(mcmlNode, pageInstName, value);	
	end
end

-----------------------------------
-- <input type="hidden"> or  <pe:editor-hidden> control
-----------------------------------
local pe_editor_hidden = {};
Map3DSystem.mcml_controls.pe_editor_hidden = pe_editor_hidden;

-- no size
function pe_editor_hidden.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local btnName = mcmlNode:GetInstanceName(rootName);
	local value = mcmlNode:GetAttributeWithCode("value")
	if(bindingContext) then
		local editorInstName, name = bindingContext.editorInstName or "", mcmlNode:GetString("name") or "_defaultHidden";
		bindingContext.values = bindingContext.values or {};
		bindingContext.values[name] = value;
	end	
end

-- get the MCML value on the node
function pe_editor_hidden.GetValue(mcmlNode)
	return mcmlNode:GetAttributeWithCode("value");
end

-- get the MCML value on the node
function pe_editor_hidden.SetValue(mcmlNode, value)
	mcmlNode:SetAttribute("value", value);
end

-----------------------------------
-- <input type="radio"> or  <pe:editor-radiobox> control
-----------------------------------

local pe_editor_radio = commonlib.gettable("Map3DSystem.mcml_controls.pe_editor_radio");
pe_editor_radio.checked_bg = pe_editor_radio.checked_bg or "Texture/radiobox.png";
pe_editor_radio.unchecked_bg = pe_editor_radio.unchecked_bg or "Texture/unradiobox.png";
pe_editor_radio.iconSize = pe_editor_radio.iconSize or 16;
pe_editor_radio._radio_BGs = {};

-- 20, 20 in size. 
-- NOTE by Andy 2009/4/24: checked and unchecked background and sizing added for radio box
--		some tricks can be used, such as vertical tabs buttons
function pe_editor_radio.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle({}) or {};
	local width = css.width or pe_editor_radio.iconSize;
	local height = css.height or pe_editor_radio.iconSize;
	
	if(css.padding) then
		width = width + css.padding*2;
		height = height + css.padding*2;
	end

	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
		
	local left, top = parentLayout:AddObject(width+margin_left+margin_right, height+margin_top+margin_bottom);
	local btnName = mcmlNode:GetInstanceName(rootName);
	local groupName = mcmlNode:GetString("name") or "_defaultRadioGroup";
	local value = mcmlNode:GetAttributeWithCode("value");
	local checked = mcmlNode:GetAttributeWithCode("checked");
	-- NOTE: some pages use checked="checked", some use checked="true"
	if(type(checked) == "string") then
		if(checked == "true" or checked == "checked") then
			checked = true;
		else
			checked = false;
		end
	end

	local max = tonumber(mcmlNode:GetAttributeWithCode("max")) or 1; -- max number of concurrent selection
	local min = tonumber(mcmlNode:GetAttributeWithCode("min")) or 1;

	local _this = ParaUI.CreateUIObject("button", btnName, "_lt", left+margin_left, top+margin_top, width, height)
	mcmlNode.uiobject_id = _this.id; -- keep the uiobject's reference id
	local label = mcmlNode:GetString("Label");
	if(label)then
		_this.text = label;
	end
	if(css.padding) then
		_this:GetAttributeObject():SetField("Padding", css.padding)
	end

	local checked_BG = mcmlNode:GetAttributeWithCode("CheckedBG");
	if(not checked_BG and css.background) then
		checked_BG = css.background;
		mcmlNode:SetAttribute("CheckedBG", checked_BG);
	end
	checked_BG = checked_BG or pe_editor_radio.checked_bg;

	local unchecked_BG = mcmlNode:GetAttributeWithCode("UncheckedBG");
	if(not unchecked_BG and css.background) then
		unchecked_BG = css.background;
		mcmlNode:SetAttribute("UncheckedBG", unchecked_BG);
	end
	unchecked_BG = unchecked_BG or pe_editor_radio.unchecked_bg;
	
	local background2 = mcmlNode:GetString("background2");

	if(bindingContext) then
		local editorInstName = bindingContext.editorInstName or "";
		bindingContext._radiogroups = bindingContext._radiogroups or {};
		local group = bindingContext._radiogroups[groupName];
		if(not group) then
			group = {};
			bindingContext._radiogroups[groupName] = group;
		end
		group[btnName] = value or true;

		if(checked) then
			bindingContext.values = bindingContext.values or {};
			bindingContext.values[groupName] = value;
		end
	else
		editorInstName = "";
	end
	if(checked) then
		_this.background = checked_BG;
		if(background2) then
			_guihelper.SetUIColor(_this, "255 255 255");
			_guihelper.SetVistaStyleButtonBright(_this, checked_BG, background2);
		end
	else
		_this.background = unchecked_BG;
		if(background2) then
			_guihelper.SetUIColor(_this, "255 255 255");
			_guihelper.SetVistaStyleButton(_this, nil, background2);
		end
	end
	mcmlNode.checked = checked;
	
	_this:SetScript("onclick", pe_editor_radio.onclick, mcmlNode, bindingContext, groupName);

	local animstyle = mcmlNode:GetAttributeWithCode("animstyle",nil, true);
	if(animstyle) then
		_this.animstyle = tonumber(animstyle);
	end
	if(css["background-color"]) then
		_guihelper.SetUIColor(_this, css["background-color"]);
	end
	local tooltip = mcmlNode:GetAttributeWithCode("tooltip");
	if(tooltip) then
		_this.tooltip = tooltip;
	end
	_parent:AddChild(_this);
end

-- user clicks the button. 
function pe_editor_radio.onclick(uiobj, mcmlNode, bindingContext, groupName)
	local bChecked;
	if(uiobj and mcmlNode)then
		local value = mcmlNode:GetAttributeWithCode("value");
		local max = tonumber(mcmlNode:GetAttributeWithCode("max")) or 1;
		local min = tonumber(mcmlNode:GetAttributeWithCode("min")) or 1;

		if(bindingContext) then
			bindingContext.values[groupName] = value;
		end

		pe_editor_radio.set_ui_value_internal(uiobj, mcmlNode, value, groupName);

		local onclickscript = mcmlNode:GetString("onclick");
		if(onclickscript and onclickscript~="") then
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclickscript, value, mcmlNode);
		end
	end
end

-- some other control forwarded a click message to this control
-- @param mcmlNode: the for node target
-- @param fromNode: from which node the click event is fired. 
function pe_editor_radio.HandleClickFor(mcmlNode, fromNode, bindingContext)
	local uiobj;
	if(mcmlNode.uiobject_id) then
		uiobj = ParaUI.GetUIObject(mcmlNode.uiobject_id);
	end
	pe_editor_radio.onclick(uiobj, mcmlNode, bindingContext, mcmlNode:GetString("name") or "_defaultRadioGroup");
end

function pe_editor_radio.set_ui_value_internal(uiobj, mcmlNode, value, groupName)
	local bChecked;
	if(uiobj and mcmlNode)then
		local max = tonumber(mcmlNode:GetAttributeWithCode("max")) or 1;
		local min = tonumber(mcmlNode:GetAttributeWithCode("min")) or 1;

		local parentNode = mcmlNode:GetParent("form") or mcmlNode:GetParent("pe:editor") or mcmlNode:GetRoot();
		if(parentNode) then
			local radios = parentNode:GetAllChildWithAttribute("name", groupName);
			if(radios) then
				local max_left = max - 1;
				local i, radio;
				local count = 0;
				local is_last_checked = true;
				for i, radio in ipairs(radios) do
					local radio_value = radio:GetAttributeWithCode("value");
					local ctl = radio:GetControl();
					
					if(radio_value ~= value) then
						if(max_left>0) then
							max_left = max_left - 1;
							count = count + 1;
						else
							radio.checked = false;
							radio:SetAttribute("checked", nil);
							if(ctl) then
								local unchecked_BG = radio:GetAttributeWithCode("UncheckedBG") or pe_editor_radio.unchecked_bg;
								local background2 = radio:GetString("background2");
								ctl.background = unchecked_BG;
								if(background2) then
									_guihelper.SetVistaStyleButton(ctl, nil, background2);
								end
							end	
						end
					elseif(radio_value == value) then
						is_last_checked = false;
						radio.checked = true;
						radio:SetAttribute("checked", "true");
						if(ctl) then
							local checked_BG = radio:GetAttributeWithCode("CheckedBG") or pe_editor_radio.checked_bg;
							local background2 = radio:GetString("background2");
							ctl.background = checked_BG;
							if(background2) then
								_guihelper.SetVistaStyleButtonBright(ctl, nil, background2);
							end
						end
					end	
				end
				if(count >= min and is_last_checked) then
					local unchecked_BG = mcmlNode:GetAttributeWithCode("UncheckedBG") or pe_editor_radio.unchecked_bg;
					local background2 = mcmlNode:GetString("background2");
					uiobj.background = unchecked_BG;
					mcmlNode.checked = false;
					if(background2) then
						_guihelper.SetVistaStyleButton(uiobj, nil, background2);
					end
					mcmlNode:SetAttribute("checked", nil);
				end
			end
		end
	end
end

-- get the UI value on the node
-- if there is multiple selection, the second return paramter is a table array containing selected values.
-- @return value, values
function pe_editor_radio.GetUIValue(mcmlNode, pageInstName)
	local checked_BG = mcmlNode:GetAttributeWithCode("CheckedBG") or pe_editor_radio.checked_bg;
	
	local value,values;
	local parentNode = mcmlNode:GetParent("form") or mcmlNode:GetParent("pe:editor") or mcmlNode:GetRoot();
	if(parentNode) then
		local radios = parentNode:GetAllChildWithAttribute("name", mcmlNode:GetAttribute("name"));
		if(radios) then
			local i, radio;
			for i, radio in ipairs(radios) do
				if(radio.checked) then
					if(not value) then
						value = radio:GetAttribute("value");
					else
						if( not values) then
							values = { value }
						end
						values[#values+1] = radio:GetAttribute("value");
					end
				end	
			end
		end
	end
	return values or value;
end

-- get the MCML value on the node
-- if there is multiple selection, the second return paramter is a table array containing selected values.
-- @return value, values
function pe_editor_radio.GetValue(mcmlNode)
	local value,values;
	local parentNode = mcmlNode:GetParent("form") or mcmlNode:GetParent("pe:editor") or mcmlNode:GetRoot();
	if(parentNode) then
		local radios = parentNode:GetAllChildWithAttribute("name", mcmlNode:GetAttribute("name"));
		if(radios) then
			local i, radio;
			for i, radio in ipairs(radios) do
				if(radio:GetAttribute("checked")) then
					if(not value) then
						value = radio:GetAttribute("value");
					else
						if( not values) then
							values = { value }
						end
						values[#values+1] = radio:GetAttribute("value");
					end
				end
			end
		end
	end
	return value, values;
end

-- set the MCML value on the node
function pe_editor_radio.SetValue(mcmlNode, value)
	local parentNode = mcmlNode:GetParent("form") or mcmlNode:GetParent("pe:editor") or mcmlNode:GetRoot();
	if(parentNode) then
		local radios = parentNode:GetAllChildWithAttribute("name", mcmlNode:GetAttribute("name"));
		if(radios) then
			local i, radio;
			for i, radio in ipairs(radios) do
				if(radio:GetAttribute("value") == value) then
					radio.checked = true;
					radio:SetAttribute("checked", "true");
				else
					radio.checked = false;
					if(radio:GetAttribute("checked"))then
						radio:SetAttribute("checked", nil);
					end
				end
			end
		end
	end
end

-- set the MCML value on the node
function pe_editor_radio.SetUIValue(mcmlNode, pageInstName, value)
	local parentNode = mcmlNode:GetParent("form") or mcmlNode:GetParent("pe:editor") or mcmlNode:GetRoot();
	if(parentNode) then
		local groupName = mcmlNode:GetAttribute("name");
		local radios = parentNode:GetAllChildWithAttribute("name", groupName);
		if(radios) then
			local i, radio;
			for i, radio in ipairs(radios) do
				if(radio:GetAttribute("value") == value) then
					local ctl = radio:GetControl();
					if(ctl) then
						pe_editor_radio.set_ui_value_internal(ctl, radio, value, groupName);
					end
					break;
				end
			end
		end
	end
end

-----------------------------------
-- <input type="checkbox"> or  <pe:editor-checkbox> control
-----------------------------------
local pe_editor_checkbox = commonlib.gettable("Map3DSystem.mcml_controls.pe_editor_checkbox");

pe_editor_checkbox.checked_bg = pe_editor_checkbox.checked_bg or "Texture/checkbox2.png";
pe_editor_checkbox.unchecked_bg = pe_editor_checkbox.unchecked_bg or "Texture/uncheckbox2.png";
pe_editor_checkbox.iconSize = pe_editor_checkbox.iconSize or 16;

-- 20, 20 in size. 
-- NOTE by Andy 2009/4/29: checked and unchecked background and sizing added for check box
function pe_editor_checkbox.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle({}) or {};
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	
	local iconSize = mcmlNode:GetNumber("iconsize") or pe_editor_checkbox.iconSize;
	local width = css.width or iconSize or 20;
	local height = css.height or iconSize or 20;
		
	local left, top = parentLayout:AddObject(width+margin_left+margin_right, height+margin_top+margin_bottom);
	
	
	local btnName = mcmlNode:GetInstanceName(rootName);
	local value = mcmlNode:GetAttributeWithCode("checked", nil, true);
	-- NOTE: some pages use checked="checked", some use checked="true"
	if(type(value) == "string") then
		if(value == "true" or value == "checked") then
			value = true;
		else
			value = false;
		end
	end
	
	local IsEnabled = mcmlNode:GetBool("enabled")
	local name = mcmlNode:GetAttributeWithCode("name") or "_defaultCheckbox";
	
	local iconWidth = width;
	local iconHeight = height;
	
	local _this = ParaUI.CreateUIObject("button", btnName, "_lt", left+margin_left, top+margin_top+(height-iconHeight)/2, iconWidth, css.height or iconHeight)
	mcmlNode.uiobject_id = _this.id; -- keep the uiobject's reference id

	local zorder = mcmlNode:GetNumber("zorder");
	if(zorder) then
		_this.zorder = zorder;
	end

	local checked_BG = mcmlNode:GetAttributeWithCode("CheckedBG") or pe_editor_checkbox.checked_bg;
	local unchecked_BG = mcmlNode:GetAttributeWithCode("UncheckedBG") or pe_editor_checkbox.unchecked_bg;

	local editorInstName;
	if(bindingContext) then
		editorInstName = bindingContext.editorInstName or "";
		bindingContext.values = bindingContext.values or {};
		if(value) then
			bindingContext.values[name] = true;
		else
			bindingContext.values[name] = false;
		end	
	else
		editorInstName = "";
	end
	if(value) then
		_this.background = checked_BG;
		mcmlNode.checked = true;
	else
		_this.background = unchecked_BG;
		mcmlNode.checked = false;
	end
	
	_this:SetScript("onclick", pe_editor_checkbox.onclick, mcmlNode, bindingContext, name);
	
	if(mcmlNode:GetString("tooltip")) then
		_this.tooltip = mcmlNode:GetString("tooltip")
	end
	
	if(IsEnabled~=nil) then
		_this.enabled = IsEnabled;
	end
	_parent:AddChild(_this);
end

-- user clicks the button. 
function pe_editor_checkbox.onclick(uiobj, mcmlNode, bindingContext, groupName)
	if(uiobj and mcmlNode)then
		mcmlNode.checked = not mcmlNode.checked;

		if(not mcmlNode.checked) then
			uiobj.background = mcmlNode:GetAttributeWithCode("UncheckedBG") or pe_editor_checkbox.unchecked_bg;
		else
			uiobj.background = mcmlNode:GetAttributeWithCode("CheckedBG") or pe_editor_checkbox.checked_bg;
		end
		
		if(bindingContext) then
			bindingContext.values[groupName] = mcmlNode.checked;
		end
	
		local onclickscript = mcmlNode:GetString("onclick");
		if(onclickscript and onclickscript~="") then
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclickscript, mcmlNode.checked, mcmlNode);
		end
	end
end

-- some other control forwarded a click message to this control
-- @param mcmlNode: the for node target
-- @param fromNode: from which node the click event is fired. 
function pe_editor_checkbox.HandleClickFor(mcmlNode, fromNode, bindingContext)
	local uiobj;
	if(mcmlNode.uiobject_id) then
		uiobj = ParaUI.GetUIObject(mcmlNode.uiobject_id);
	end
	pe_editor_checkbox.onclick(uiobj, mcmlNode, bindingContext, mcmlNode:GetAttributeWithCode("name") or "_defaultCheckbox");
end

-- get the MCML value on the node
function pe_editor_checkbox.GetValue(mcmlNode)
	if(mcmlNode:GetAttribute("checked")) then
		return true;
	else
		return false;
	end
end

-- get the MCML value on the node
function pe_editor_checkbox.SetValue(mcmlNode, value)
	if(value) then
		mcmlNode:SetAttribute("checked", "true")
	else
		mcmlNode:SetAttribute("checked", nil)
	end
end

-- get the UI value on the node
function pe_editor_checkbox.GetUIValue(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		local bg = ctl.background;
		if(bg) then
			bg = string.gsub(bg, "[;:].*$", "");
			return (bg == (mcmlNode:GetAttributeWithCode("CheckedBG") or pe_editor_checkbox.checked_bg))
		end	
	end
end

-- set the UI value on the node
function pe_editor_checkbox.SetUIValue(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl and ctl.background) then
		if(value) then
			ctl.background = mcmlNode:GetAttributeWithCode("CheckedBG") or pe_editor_checkbox.checked_bg;
			mcmlNode.checked = true;
		else
			ctl.background = mcmlNode:GetAttributeWithCode("UncheckedBG") or pe_editor_checkbox.unchecked_bg;
			mcmlNode.checked = false;
		end
	end
end
-----------------------------------
-- html <select> control
-----------------------------------
local pe_select = commonlib.gettable("Map3DSystem.mcml_controls.pe_select");

pe_select.dropdownBtn_bg = pe_select.dropdownBtn_bg or "Texture/3DMapSystem/Desktop/DropdownBtn.png";
pe_select.editbox_bg = pe_select.editbox_bg or "Texture/3DMapSystem/Desktop/LoginPageTextbox.png: 7 7 7 7";
pe_select.container_bg = pe_select.container_bg or nil;
pe_select.listbox_bg = pe_select.listbox_bg or nil;

-- increment left by the width of this control. control width is sized according to text length. 
-- the dropdownlistbox control takes up 20 pixels in height
function pe_select.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local name = mcmlNode:GetString("name");
	local rows =  mcmlNode:GetNumber("size") or 1;

	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["input-select"]);
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
		
	local left, top, width, height = parentLayout:GetPreferredRect();
	width, height  = width-left-margin_left-margin_right, (css.lineheight or 20)*rows;
	if(css.width and css.width<width) then
		width = css.width
	end
	if(css.height) then
		height = css.height;
	end	
	left=left+margin_left;
	top=top+margin_top
	
	local instName = mcmlNode:GetInstanceName(rootName);
	
	local ds = mcmlNode:GetAttributeWithCode("DataSource",nil,true);
	if(ds) then
		pe_select.SetDataSource(mcmlNode, rootName, ds)
	end
	
	if(mcmlNode.datasource) then
		-- instantiate child nodes from data source 
		pe_select.DataBind(mcmlNode, rootName, false);
	end

	if(rows==1) then
		local items = {};
		local selected_text;
		-- search options
		local childnode;
		-- width of the longest item text 
		local preferredWidth=0;
		for childnode in mcmlNode:next("option") do
			local text = childnode:GetInnerText();
			if(text == "") then
				text = childnode:GetString("value") or "";
			end
			
			local value = childnode:GetString("value");
			local width = _guihelper.GetTextWidth(text)
			if(preferredWidth < width) then
				preferredWidth = width;
			end
			
			if(childnode:GetAttribute("selected")) then
				selected_text = text;
			end
			table.insert(items, text);
			if(text~=value) then
				if(not items.values) then
					items.values = {};
				end	
				items.values[text] = value;
			end
		end
		preferredWidth = preferredWidth + 20 + 5;
		if(mcmlNode:GetNumber("width") or css.width) then
			width =  mcmlNode:GetNumber("width") or css.width;
		elseif(preferredWidth<width) then
			width = preferredWidth;
		end
		
		NPL.load("(gl)script/ide/dropdownlistbox.lua");
		local ctl = CommonCtrl.dropdownlistbox:new{
			name = instName,
			alignment = "_lt",
			left=left, top=top,
			width = width,
			height = height,
			dropdownheight = math.min(math.max((height-2)*table.getn(items), (height-2)*3), 300),
			parent = _parent,
			editbox_bg = pe_select.editbox_bg,
			dropdownbutton_bg = pe_select.dropdownBtn_bg,
			container_bg = pe_select.container_bg,
			listbox_bg = pe_select.listbox_bg,
			dropdownbutton_width = pe_select.dropdownbutton_width,
			dropdownbutton_height = pe_select.dropdownbutton_height,
			items = items,
			text = selected_text,
			AllowUserEdit = mcmlNode:GetBool("AllowUserEdit"),
			IsReadonly = mcmlNode:GetBool("IsReadonly"),
		};
		ctl:Show();
		mcmlNode.control = ctl;
		if(bindingContext and name) then
			bindingContext:AddBinding(bindingContext.values, name, instName, commonlib.Binding.ControlTypes.IDE_dropdownlistbox, "value")
		end
		
		-- on select event handler
		local onselect = mcmlNode:GetAttribute("onclick") or mcmlNode:GetAttribute("onselect");
		ctl.onselect = function (sCtrlName, value)
			pe_select.SetValue(mcmlNode, value)
			if(onselect and onselect~="") then
				Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onselect, name, value)
			end
		end
	else
		local _this=ParaUI.CreateUIObject("listbox",instName, "_lt",left, top,width,height);
		_parent:AddChild(_this);
		
		width =  mcmlNode:GetNumber("width") or css.width or width;
		mcmlNode.uiobject_id = _this.id;
		
		-- search options
		local childnode;
		local index = 0;
		for childnode in mcmlNode:next("option") do
			local text = childnode:GetInnerText();
			if(text == "") then
				text = childnode:GetString("value") or "";
			end
			_this:AddTextItem(text);
			if(childnode:GetAttribute("selected")) then
				_this.value = index;
			end
			index = index + 1;
		end
		if(bindingContext and name) then
			bindingContext:AddBinding(bindingContext.values, name, instName, commonlib.Binding.ControlTypes.ParaUI_listbox, "text")
		end
		
		-- on select event handler
		local onselect = mcmlNode:GetAttribute("onclick") or mcmlNode:GetAttribute("onselect");
		if(onselect and onselect~="") then
			_this:SetScript("onselect", function()
				 pe_select.onselect(mcmlNode, name or "", onselect);
			end);
		end
	end
	parentLayout:AddObject(width+margin_left+margin_right, margin_top+margin_bottom+height);
end

-- Public method: set the new data source
-- @param dataSource: if string, it is the DataSourceID. if table it is the data table itself 
function pe_select.SetDataSource(mcmlNode, pageInstName, dataSource)
	local pageCtrl = mcmlNode:GetPageCtrl();
	if(not pageCtrl) then return end
	if(type(dataSource) == "string") then
		-- this is data source ID, we will convert it to a function that dynamically retrieve item from the data source control. 
		mcmlNode.datasource = pageCtrl:GetNode(dataSource);
	else
		mcmlNode.datasource = dataSource;
	end
end

-- Public method: rebind (refresh) the data.
function pe_select.DataBind(mcmlNode, pageInstName, bRefreshUI)
	if(not mcmlNode.datasource) then
		return 
	end
	-- clear all children
	mcmlNode:ClearAllChildren();
	local inTable = mcmlNode.datasource;
	local nChildSize = table.getn(inTable);
	if(nChildSize>0) then
		local i, childNode
		for i, childNode in ipairs(inTable) do
			local sub_node = Map3DSystem.mcml.new(nil, {name="option", attr=childNode, childNode.text});
			mcmlNode:AddChild(sub_node);
		end
	end
end

-- for listbox only
function pe_select.onselect(mcmlNode, name, onselectscript)
	local ctl = mcmlNode:GetControl();
	if(ctl and ctl.id and onselectscript and onselectscript~="") then
		local _this=ParaUI.GetUIObject(ctl.id);
		if(_this:IsValid()) then
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onselectscript, name, _this.text)
		end		
	end
end


-- get the MCML value on the node
function pe_select.GetValue(mcmlNode)
	for childnode in mcmlNode:next("option") do
		if(childnode:GetAttribute("selected")) then
			return childnode:GetString("value") or childnode:GetInnerText();
		end
	end
end

function pe_select.GetText(mcmlNode)
	for childnode in mcmlNode:next("option") do
		if(childnode:GetAttribute("selected")) then
			return childnode:GetInnerText() or childnode:GetString("value");
		end
	end
end

-- set the MCML value on the node
function pe_select.SetValue(mcmlNode, value)
	local hasValue;
	local childnode;
	for childnode in mcmlNode:next("option") do
		local text = childnode:GetString("value") or childnode:GetInnerText();
		if(text == value) then
			childnode:SetAttribute("selected", "true")
			hasValue = true;
		else
			if(childnode:GetAttribute("selected")) then
				childnode:SetAttribute("selected", nil)
			end
		end
	end
	if(not hasValue) then
		-- add a new item if no value matches.
		local NewOption = Map3DSystem.mcml.new(nil, {name="option"});
		NewOption:SetAttribute("value", value);
		NewOption:SetInnerText(value);
		NewOption:SetAttribute("selected", "true")
		
		mcmlNode:AddChild(NewOption, nil);
	end
end

-- public method: add name value to the node
function pe_select.AddNameValue(mcmlNode, pageInstName, value, name)
	local hasValue;
	local childnode;
	for childnode in mcmlNode:next("option") do
		local text = childnode:GetString("value") or childnode:GetInnerText();
		if(text == value) then
			hasValue = true;
		end
	end
	if(not hasValue) then
		-- add a new item if no value matches.
		local NewOption = Map3DSystem.mcml.new(nil, {name="option"});
		NewOption:SetAttribute("value", value);
		NewOption:SetInnerText(name or value);
		mcmlNode:AddChild(NewOption, nil);
	end
end

-- get the UI value on the node
function pe_select.GetUIValue(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		if(type(ctl)=="table" and type(ctl.GetText) == "function") then
			return ctl:GetValue();
		else
			return ctl.text;
		end	
	end
end

-- set the UI value on the node
function pe_select.SetUIValue(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		if(type(ctl)=="table" and type(ctl.SetText) == "function") then
			ctl:SetValue(value);
		else
			ctl.text = value;
		end	
	end
end


-----------------------------------
-- pe:fileupload control for <pe:fileupload> and <input type="file"> tag
-- it displays a text box and Browse button. The node may contain inner child templates. e.g.
-- <pe:fileupload name="filename" type="file" onchange=""><input style="width:200px"/><input type="button" value="browse..."/><pe:fileupload>
-- if inner template does not exist, it will create them by default. e.g. simple write: 
-- <pe:fileupload name="filename" type="file" onchange="" dir="worlds" fileext="images(*.jpg;*.bmp)" CheckFileExists="false">
-- if dir property is nil, it will open using external win32 file browser
-----------------------------------

local pe_fileupload = {};
Map3DSystem.mcml_controls.pe_fileupload = pe_fileupload;

-- Creates a file upload object with a text box and Browse button.
-- this is just a combo control.
function pe_fileupload.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local name = mcmlNode:GetString("name");
	
	if(mcmlNode:GetChildCount()<2) then
		local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:fileupload"]);
		local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
			
		local left, top, width, height = parentLayout:GetPreferredRect();
		width = width-left-margin_left-margin_right;
		if(css.width and css.width<width) then
			width = css.width
		end
		
		-- this is big enough for both chinese and english button text
		local btnWidth = 75; 
		-- add a text box input node
		local textInput = Map3DSystem.mcml.new(nil, {name="input"});
		textInput:SetAttribute("type", "text");
		textInput:SetAttribute("style", string.format("width:%dpx", math.max(10, width-btnWidth)));
		mcmlNode:AddChild(textInput, nil);
		
		-- add a browse button input node
		local browseBtn = Map3DSystem.mcml.new(nil, {name="input"});
		browseBtn:SetAttribute("type", "button");
		browseBtn:SetAttribute("style", "margin-top:0px");
		browseBtn:SetAttribute("value", L"Browse...");
		mcmlNode:AddChild(browseBtn, nil);
	end
	
	local childnode;
	for childnode in mcmlNode:next() do
		if(childnode.name=="input") then
			local type = childnode:GetAttribute("type");
			if(type==nil or type=="text") then
				if(mcmlNode:GetAttribute("value")) then
					childnode:SetAttribute("value", mcmlNode:GetAttribute("value"));
				end	
				local textName = name or "fileupload";
				textName = textName.."text"
				childnode:SetAttribute("name", textName);
				
			elseif (type=="button" or type=="submit") then
				local textName = name or "fileupload";
				textName = textName.."button"
				childnode:SetAttribute("name", textName);
				childnode:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_fileupload.OnClickBrowseBtn");
			end
		end
	end

	-- just use the standard style to create the control	
	Map3DSystem.mcml_controls.pe_simple_styles.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	
	if(bindingContext and name) then
		bindingContext:AddBinding(bindingContext.values, name, rootName, commonlib.Binding.ControlTypes.MCML_node, name)
	end
end

-- click function
function pe_fileupload.OnClickBrowseBtn(name)
	local textName = string.gsub(name, "button$", "text")
	-- open a file
	local fileloaderName = string.gsub(name, "button$", "")
	local fileloader = document:GetPageCtrl():GetNode(fileloaderName);
	if(fileloader) then
		local fileext = fileloader:GetAttribute("fileext");
		local dir = fileloader:GetAttribute("dir");
		local CheckFileExists = fileloader:GetAttribute("CheckFileExists") ~= "false";
		local onchangeScript = fileloader:GetAttribute("onchange") or fileloader:GetAttribute("onselect") or fileloader:GetAttribute("onclick")
		if(not dir) then
			NPL.load("(gl)script/ide/OpenFileDialog.lua");
			local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32();
			if(filename) then
				document:GetPageCtrl():SetUIValue(textName, commonlib.Encoding.DefaultToUtf8(filename));
				if(onchangeScript) then
					Map3DSystem.mcml_controls.OnPageEvent(fileloader, onchangeScript, fileloaderName, filename)
				end
			end
		elseif(dir == "*.") then
			NPL.load("(gl)script/ide/OpenFolderDialog.lua");
			local pageCtrl = document:GetPageCtrl();
			local ctl = CommonCtrl.OpenFolderDialog:new{
				rootfolder = "",
				selectedFolderPath = "",
				OnSelected = function(sCtrlName, folderPath) 
					pageCtrl:SetUIValue(textName, commonlib.Encoding.DefaultToUtf8(folderPath))
					if(onchangeScript) then
						Map3DSystem.mcml_controls.OnPageEvent(fileloader, onchangeScript, fileloaderName, folderPath)
					end	
				end
			};
			ctl:Show();
		else
			local pageCtrl = document:GetPageCtrl();
			NPL.load("(gl)script/ide/OpenFileDialog.lua");
			local ctl = CommonCtrl.OpenFileDialog:new{
				name = "OpenFileDialog1",
				alignment = "_ct",
				left=-256, top=-150,
				width = 512,
				height = 380,
				parent = nil,
				CheckFileExists = CheckFileExists,
				fileextensions = {fileext or L"all files(*.*)", "images(*.jpg; *.png; *.dds)", "animations(*.swf; *.wmv; *.avi)", "web pages(*.htm; *.html; *.xml)",},
				folderlinks = {
					{path = dir, text = dir},
					{path = "Model/", text = L"Model"},
					{path = "Texture/", text = L"Texture"},
					{path = "character/", text = L"Character"},
					{path = "script/", text = L"Script"},
					{path = "/", text = L"Root Directory"},
				},
				onopen = function(name, filename)
					pageCtrl:SetUIValue(textName, commonlib.Encoding.DefaultToUtf8(filename))
					if(onchangeScript) then
						Map3DSystem.mcml_controls.OnPageEvent(fileloader, onchangeScript, fileloaderName, filename)
					end	
				end
			};
			ctl:Show(true);
		end	
	end
end

-- get the MCML value on the node
function pe_fileupload.GetValue(mcmlNode)
	local childnode;
	for childnode in mcmlNode:next("input") do
		if(childnode:GetAttribute("type") == "text") then
			return Map3DSystem.mcml_controls.pe_editor_text.GetValue(childnode);
		end
	end
	return mcmlNode:GetAttribute("value")
end

-- set the MCML value on the node
function pe_fileupload.SetValue(mcmlNode, value)
	local childnode;
	for childnode in mcmlNode:next("input") do
		if(childnode:GetAttribute("type") == "text") then
			Map3DSystem.mcml_controls.pe_editor_text.SetValue(childnode, value);
			return
		end
	end
	mcmlNode:SetAttribute("value", value)
end

-- get the UI value on the node
function pe_fileupload.GetUIValue(mcmlNode, pageInstName)
	local childnode;
	for childnode in mcmlNode:next("input") do
		if(childnode:GetAttribute("type") == "text") then
			return Map3DSystem.mcml_controls.pe_editor_text.GetUIValue(childnode, pageInstName);
		end
	end
end

-- set the UI value on the node
function pe_fileupload.SetUIValue(mcmlNode, pageInstName, value)
	local childnode;
	for childnode in mcmlNode:next("input") do
		if(childnode:GetAttribute("type") == "text") then
			Map3DSystem.mcml_controls.pe_editor_text.SetUIValue(childnode, pageInstName, value);
			break;
		end
	end
end
