--[[
Title: power point class
Author(s): LiXizhi
Date: 2010/12/7
Desc: 

---++ pe:powerpoint
pe:powerpoint is to create guided interactive UI tooltips. 
It can grey out unclickable region on the screen, and guide the user to click on a certain area of the screen and then proceed to the next area. 
<verbatim>
<script type="text/npl">
function onGotoPage()
    Page:SetValue("MyPPT", "2")
end
function onGotoNextPage()
    Page:SetValue("MyPPT", "next")
end
function onGotoPrevPage()
    Page:SetValue("MyPPT", "prev")
end
</script>
<input type="button" zorder="300" onclick="onGotoPrevPage" name="prev" value="Goto prev page"/>
<input type="button" zorder="300" onclick="onGotoNextPage" name="next" value="Goto next page"/>
<pe:powerpoint value="1" style="position:relative;width:500px;height:300px;">
	<div name="1">
		<pe:maskarea style="position:relative;margin-left:100px;margin-top:50px;width:50px;height:30px;"/>
		<div style="position:relative;margin-left:100px;margin-top:50px;width:150px;height:30px;">
			This can be some tooltip text 1
		</div>
	</div>
	<div name="2">
		<pe:maskarea method="add" style="position:relative;margin-left:100px;margin-top:50px;width:50px;height:30px;"/>
		<div style="position:relative;margin-left:100px;margin-top:50px;width:150px;height:30px;">
			This can be some tooltip text 2
		</div>
	</div>
</pe:powerpoint>
</verbatim>

Note: the first level child must all have unique names. 

| *property* | *desc*|
| value | one of its first level child name or nil, this will be the first page to show. If "next", it will show next page. if "prev", it will show previous page.  | 
| zorder| defaults to 100. | 

---++ pe:maskarea
this tag is used to mask a rectangular area or its complimentary region so that the masked region is not clickable. 
When defining the mask, the parent(full region) is always the page control's direct _parent ParaUI container. 

| *property* | *desc*|
| method | "substract", "add". default to "substract". when "substract", it is the complimentary region that is masked. otherwise it is the inner region that is masked. | 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_powerpoint.lua");
-------------------------------------------------------
]]

local mcml_controls = commonlib.gettable("Map3DSystem.mcml_controls");

-----------------------------------
-- pe:powerpoint control
-----------------------------------
local pe_powerpoint = commonlib.gettable("Map3DSystem.mcml_controls.pe_powerpoint");

function pe_powerpoint.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
	-- create the background container
	local _this=ParaUI.CreateUIObject("container","b","_lt", left, top, width-left, height-top);
	_this.background = css.background or "";
	_this.zorder = mcmlNode:GetNumber("zorder") or 100;
	_parent:AddChild(_this);
	mcmlNode.uiobject_id = _this.id;
	mcmlNode.css = css;
	if(mcmlNode:GetBool("ClickThrough")) then
		_this:GetAttributeObject():SetField("ClickThrough", true);
	else
		_this:SetScript("onmousedown", function() 
			pe_powerpoint.OnClick(mcmlNode);
		end)
	end
	local value = mcmlNode:GetAttributeWithCode("value");
	pe_powerpoint.SetValue(mcmlNode, value);
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

-- user clicked the page and should proceed to the next page. 
function pe_powerpoint.OnClick(mcmlNode)
	pe_powerpoint.GotoNextPage(mcmlNode);
end

-- goto next page. if there is no last page. it will display empty page.
function pe_powerpoint.GotoNextPage(mcmlNode)
	local value = mcmlNode:GetAttributeWithCode("value");
	
	local nextnode
	local childnode;
	local bFound;
	for childnode in mcmlNode:next() do
		if(childnode:GetAttribute("name") == value) then
			bFound = true;
		elseif(bFound) then
			nextnode = childnode;
			break;
		end
	end
	if(not nextnode) then
		pe_powerpoint.SetValue(mcmlNode, nil)
	else
		pe_powerpoint.SetValue(mcmlNode, nextnode:GetAttribute("name"));
	end	
end

-- goto previous page. if not found, we will display the last page. 
function pe_powerpoint.GotoPrevPage(mcmlNode)
	local value = mcmlNode:GetAttributeWithCode("value");
	
	local prevnode;
	local childnode;
	local bFound;
	for childnode in mcmlNode:next() do
		if(childnode:GetAttribute("name") == value) then
			bFound = true;
			break;
		end
		prevnode = childnode;
	end
	if(prevnode) then
		pe_powerpoint.SetValue(mcmlNode, prevnode:GetAttribute("name"));
	end
end

function pe_powerpoint.GetValue(mcmlNode, value)
	return mcmlNode:GetAttributeWithCode("value");
end

-- @param value: if nil, it will disable the pe_powerpoint, otherwise it will show a given page's. 
-- if it is "next", it will be the next page. 
function pe_powerpoint.SetValue(mcmlNode, value)
	if(value == "next") then
		pe_powerpoint.GotoNextPage(mcmlNode);
		return;
	elseif(value == "prev") then
		pe_powerpoint.GotoPrevPage(mcmlNode);
		return;
	end

	mcmlNode:SetAttribute("value", value);
	if(not mcmlNode.uiobject_id) then 
		return 
	end
	local childnode;
	local curNode;
	local bFound;
	for childnode in mcmlNode:next() do
		if(childnode:GetAttribute("name") == value) then
			childnode:SetAttribute("display", nil);
			curNode = childnode;
			bFound = true;
		else
			childnode:SetAttribute("display", "none");
		end
	end

	local _this = ParaUI.GetUIObject(mcmlNode.uiobject_id);
	if(not _this:IsValid()) then
		return
	end

	if(not bFound) then
		_this.visible = false;
		_this:RemoveAll();
	else
		_this.visible = true;
		_this:RemoveAll();

		local myLayout = mcml_controls.layout:new();
		local width, height = _this.width, _this.height;
		myLayout:reset(0, 0, width, height);
		-- for inner nodes
		mcmlNode:DrawChildBlocks_Callback(mcmlNode:GetAttribute("name") or "default"..tostring(_this.id), nil, _this, 0, 0, width, height, myLayout, mcmlNode.css)
	end
end

function pe_powerpoint.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_powerpoint.render_callback);
end


-----------------------------------
-- pe_maskarea control
-----------------------------------
local pe_maskarea = commonlib.gettable("Map3DSystem.mcml_controls.pe_maskarea");

function pe_maskarea.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
	-- create the background container
	
	local method = mcmlNode:GetAttributeWithCode("method") or "substract";
	local zorder = mcmlNode:GetNumber("zorder");

	local bg_texture = css.background or "Texture/alphadot.png";
	local bg_color = css["background-color"] or "255 255 255";
		
	if(method == "substract") then
		-- use 4 "button" to cover the outer region
		local outer_width, outer_height = _parent.width, _parent.height;

		local _this;
		_this=ParaUI.CreateUIObject("button","b","_lt", 0, 0, width, top);
		_this.background = bg_texture;
		if (zorder) then  _this.zorder = zorder; end
		_parent:AddChild(_this);
		_guihelper.SetUIColor(_this, bg_color)

		_this=ParaUI.CreateUIObject("button","b","_lt", 0, top, left, outer_height-top);
		_this.background = bg_texture;
		if (zorder) then  _this.zorder = zorder; end
		_parent:AddChild(_this);
		_guihelper.SetUIColor(_this, bg_color)

		_this=ParaUI.CreateUIObject("button","b","_lt", left, height, outer_width-left, outer_height-height);
		_this.background = bg_texture;
		if (zorder) then  _this.zorder = zorder; end
		_parent:AddChild(_this);
		_guihelper.SetUIColor(_this, bg_color)
		
		_this=ParaUI.CreateUIObject("button","b","_lt", width, 0, outer_width-width, height);
		_this.background = bg_texture;
		if (zorder) then  _this.zorder = zorder; end
		_parent:AddChild(_this);
		_guihelper.SetUIColor(_this, bg_color)

	elseif(method == "add") then
		local _this=ParaUI.CreateUIObject("button","b","_lt", left, top, width-left, height-top);
		_this.background = bg_texture;
		if (zorder) then  _this.zorder = zorder; end
		_parent:AddChild(_this);
		_guihelper.SetUIColor(_this, bg_color)
	elseif(method == "full") then
		local _this=ParaUI.CreateUIObject("button","b","_fi", 0, 0, 0, 0);
		_this.background = bg_texture;
		_this.enabled = false;
		if (zorder) then  _this.zorder = zorder; end
		_parent:AddChild(_this);
		_guihelper.SetUIColor(_this, bg_color)
	else
		LOG.std(nil,"warning", "mcml", "unknown method for pe_maskarea %s", tostring(method));
	end

	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function pe_maskarea.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_maskarea.render_callback);
end