--[[
Title: base mcml function and base Node implementation of mcml
Author(s): LiXizhi
Date: 2008/2/15
Desc: only included and used by mcml
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_base.lua");
local node = Map3DSystem.mcml.new("pe:profile", {})
local o = Map3DSystem.mcml.buildclass(o);

-- the following is an example of creating a custom mcml tag control.
local pe_locationtracker = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_locationtracker");
function pe_locationtracker.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	-- TODO: your render code here
	-- local _this=ParaUI.CreateUIObject("button","b","_lt", left, top, right-left, bottom-top);
	-- _this.background = "Texture/alphadot.png";
	-- _parent:AddChild(_this);
	-- mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)

	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end
function pe_locationtracker.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_locationtracker.render_callback);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/localserver/UrlHelper.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/StyleItem.lua");
local StyleItem = commonlib.gettable("Map3DSystem.mcml_controls.StyleItem");
local pe_css = commonlib.gettable("Map3DSystem.mcml_controls.pe_css");

if(not Map3DSystem.mcml) then Map3DSystem.mcml = {} end

local mcml = Map3DSystem.mcml;
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local type = type
local string_find = string.find;
local string_format = string.format;
local string_gsub = string.gsub;
local string_lower = string.lower
local string_match = string.match;

local table_getn = table.getn;
local mcml_controls = commonlib.gettable("Map3DSystem.mcml_controls");
local LOG = LOG;
local CommonCtrl = commonlib.gettable("CommonCtrl");
local NameNodeMap_ = {};
local commonlib = commonlib.gettable("commonlib");
local pe_html = commonlib.gettable("Map3DSystem.mcml_controls.pe_html");
----------------------------
-- helper functions
----------------------------
-- set a node by a string name, so that the node can later be retrieved by name using GetNode().
-- @param name: string, this is usually the string returned by mcml.baseNode:GetInstanceName()
-- @param node: the node table object.
function mcml.SetNode(name, node)
	NameNodeMap_[name] = node;
end

-- get a node by a string name. 
-- @param name: string, 
function mcml.GetNode(name)
	return NameNodeMap_[name];
end

----------------------------
-- base functions
----------------------------

-- create or init a new object o of tag. it will return the input object, if tag name is not found. 
-- e.g. mcml.new(nil, {name="div"})
-- @param tagName: the tag (node) name to be created or initialized. if nil, the default "baseNode" is used.
-- @param o: the tag object to be initialized. if nil, a new one will be created. 
-- @return: the tag (node) object is returned. methods of the object can be called thereafterwards. 
function mcml.new(tagName, o)
	local baseNode = mcml[tagName or "baseNode"];
	if(baseNode) then
		o = o or {}
		if(baseNode.attr and o.attr) then
			setmetatable(o.attr, baseNode.attr)
			baseNode.attr.__index = baseNode.attr
		end
		
		setmetatable(o, baseNode)
		baseNode.__index = baseNode
		return o	
	else
		-- return the input object, if tag name is not found. 
		return o;
	end
end

-- o is a pure mcml table, after building class with it, it will be deserialized from pure data to a class contain all methods and parent|child relationships. 
-- o must be a pure table that does not contains cyclic table references. 
-- for unknown node in o, it will inherite from the baseNode. 
-- @return the input o is returned. 
function mcml.buildclass(o)
	local baseNode = mcml[o.name or "baseNode"];
	if(not baseNode) then
		baseNode = mcml["baseNode"];
	end
	if(baseNode.attr and o.attr) then
		setmetatable(o.attr, baseNode.attr)
		baseNode.attr.__index = baseNode.attr
	end
	setmetatable(o, baseNode)
	baseNode.__index = baseNode
	
	local i, child;
	for i, child in ipairs(o) do
		if(type(child) == "table") then
			mcml.buildclass(child);
			child.parent = o;
			child.index = i;
		end	
	end
	return o;
end

----------------------------
-- base node class
----------------------------

-- base class for all nodes. 
mcml.baseNode = {
	name = nil,
	parent = nil,
	-- control index in its parent
	index = 1,
}

-- return a copy of this object, everything is cloned including the parent and index of its child node. 
function mcml.baseNode:clone()
	local o = mcml.new(nil, {name = self.name})
	if(self.attr) then
		o.attr = {};
		commonlib.partialcopy(o.attr, self.attr)
	end
	local nSize = table_getn(self);
	if(nSize>0) then
		local i, node;
		for i=1, nSize do
			node = self[i];
			if(type(node)=="table" and type(node.clone)=="function") then
				o[i] = node:clone();
				o[i].index = i;
				o[i].parent = o;
			elseif(type(node)=="string") then
				o[i] = node;
			else
				LOG.warn("unknown node type when mcml.baseNode:clone() \n")	
			end
		end
		table.resize(o, nSize);
		-- table.setn(o, nSize);
	end	
	return o;
end

-- set the value of an attribute of this node. This function is rarely used. 
function mcml.baseNode:SetAttribute(attrName, value)
	self.attr = self.attr or {};
	self.attr[attrName] = value;
	if(attrName == "style") then
		-- tricky code: since we will cache style table on the node, we need to delete the cached style when it is changed. 
		self.style = nil;
	end
end

-- set the attribute if attribute is not code. 
function mcml.baseNode:SetAttributeIfNotCode(attrName, value)
	self.attr = self.attr or {};
	local old_value = self.attr[attrName];
	if(type(old_value) == "string") then
		local code = string_match(old_value, "^[<%%]%%(=.*)%%[%%>]$")
		if(not code) then
			self.attr[attrName] = value;
		end
	else
		self.attr[attrName] = value;
	end
end

-- get the value of an attribute of this node as its original format (usually string)
function mcml.baseNode:GetAttribute(attrName,defaultValue)
	if(self.attr) then
		return self.attr[attrName];
	end
	return defaultValue;
end

-- get the value of an attribute of this node (usually string)
-- this differs from GetAttribute() in that the attribute string may contain embedded code block which may evaluates to a different string, table or even function. 
-- please note that only the first call of this method will evaluate embedded code block, subsequent calls simply return the previous evaluated result. 
-- in most cases the result is nil or string, but it can also be a table or function. 
-- @param bNoOverwrite: default to nil. if true, the code will be reevaluated the next time this is called, otherwise the evaluated value will be saved and returned the next time this is called. 
-- e.g. attrName='<%="string"+Eval("index")}%>' attrName1='<%={fieldname="table"}%>'
function mcml.baseNode:GetAttributeWithCode(attrName,defaultValue, bNoOverwrite)
	if(self.attr) then
		local value = self.attr[attrName];
		if(type(value) == "string") then
			local code = string_match(value, "^[<%%]%%(=.*)%%[%%>]$")
			if(code) then
				value = mcml_controls.pe_script.DoPageCode(code, self:GetPageCtrl());
				if(not bNoOverwrite) then
					self.attr[attrName] = value;
				end	
			end
		end
		if(value ~= nil) then
			return value;
		end
	end
	return defaultValue;
end


-- get an attribute as string
function mcml.baseNode:GetString(attrName,defaultValue)
	if(self.attr) then
		return self.attr[attrName];
	end
	return defaultValue;
end

-- get an attribute as number
function mcml.baseNode:GetNumber(attrName,defaultValue)
	if(self.attr) then
		return tonumber(self.attr[attrName]);
	end
	return defaultValue;
end

-- get an attribute as integer
function mcml.baseNode:GetInt(attrName, defaultValue)
	if(self.attr) then
		return math.floor(tonumber(self.attr[attrName]));
	end
	return defaultValue;
end


-- get an attribute as boolean
function mcml.baseNode:GetBool(attrName, defaultValue)
	if(self.attr) then
		local v = string_lower(tostring(self.attr[attrName]));
		if(v == "false") then
			return false
		elseif(v == "true") then
			return true
		end
	end
	return defaultValue;
end

-- get all pure text of only text node
function mcml.baseNode:GetPureText()
	local nSize = table_getn(self);
	local i, node;
	local text = "";
	for i=1, nSize do
		node = self[i];
		if(node) then
			if(type(node) == "string") then
				text = text..node;
			end
		end
	end
	return text;
end

-- get all inner text recursively (i.e. without tags) as string. 
function mcml.baseNode:GetInnerText()
	local nSize = table_getn(self);
	local i, node;
	local text = "";
	for i=1, nSize do
		node = self[i];
		if(node) then
			if(type(node) == "string") then
				text = text..node;
			elseif(type(node) == "table") then
				text = text..node:GetInnerText();
			elseif(type(node) == "number") then
				text = text..tostring(node);
			end
		end
	end
	return text;
end

-- set inner text. It will replace all child nodes with a text node
function mcml.baseNode:SetInnerText(text)
	self[1] = text;
	commonlib.resize(self, 1);
	-- table.setn(self, 1)
end

-- get value: it is usually one of the editor tag, such as <input>
function mcml.baseNode:GetValue()
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass.GetValue) then
		return controlClass.GetValue(self);
	else
		--LOG.warn("GetValue on object "..self.name.." is not supported\n")	
	end
end

-- set value: it is usually one of the editor tag, such as <input>
function mcml.baseNode:SetValue(value)
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass.SetValue) then
		return controlClass.SetValue(self, value);
	else
		--LOG.warn("SetValue on object "..self.name.." is not supported\n")	
	end
end

-- get UI value: get the value on the UI object with current node
-- @param instName: the page instance name. 
function mcml.baseNode:GetUIValue(pageInstName)
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass.GetUIValue) then
		return controlClass.GetUIValue(self, pageInstName);
	else
		--LOG.warn("GetUIValue on object "..self.name.." is not supported\n")	
	end
end

-- set UI value: set the value on the UI object with current node
function mcml.baseNode:SetUIValue(pageInstName, value)
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass.SetUIValue) then
		return controlClass.SetUIValue(self, pageInstName, value);
	else
		--LOG.warn("SetUIValue on object "..self.name.." is not supported\n")	
	end
end


-- set UI enabled: set the enabled on the UI object with current node
function mcml.baseNode:SetUIEnabled(pageInstName, value)
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass.SetUIEnabled) then
		return controlClass.SetUIEnabled(self, pageInstName, value);
	else
		--LOG.warn("SetUIEnabled on object "..self.name.." is not supported\n")	
	end
end

-- get UI value: get the value on the UI object with current node
-- @param instName: the page instance name. 
function mcml.baseNode:GetUIBackground(pageInstName)
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass.GetUIBackground) then
		return controlClass.GetUIBackground(self, pageInstName);
	else
		--LOG.warn("GetUIValue on object "..self.name.." is not supported\n")	
	end
end

-- set UI value: set the value on the UI object with current node
function mcml.baseNode:SetUIBackground(pageInstName, value)
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass.SetUIBackground) then
		return controlClass.SetUIBackground(self, pageInstName, value);
	else
		--LOG.warn("SetSetUIBackgroundUIValue on object "..self.name.." is not supported\n")	
	end
end

-- call a control method
-- @param instName: the page instance name. 
-- @param methodName: name of the method.
-- @return: the value from method is returned
function mcml.baseNode:CallMethod(pageInstName, methodName, ...)
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass[methodName]) then
		return controlClass[methodName](self, pageInstName, ...);
	else
		LOG.warn("CallMethod (%s) on object %s is not supported\n", tostring(methodName), self.name)
	end
end

-- return true if the page node contains a method called methodName
function mcml.baseNode:HasMethod(pageInstName, methodName)
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass[methodName]) then
		return true;
	end
end

-- invoke a control method. this is same as CallMethod, except that pageInstName is ignored. 
-- @param methodName: name of the method.
-- @return: the value from method is returned
function mcml.baseNode:InvokeMethod(methodName, ...)
	local controlClass = mcml_controls.control_mapping[self.name];
	if(controlClass and controlClass[methodName]) then
		return controlClass[methodName](self, ...);
	else
		LOG.warn("InvokeMethod (%s) on object %s is not supported\n", tostring(methodName), self.name)
	end
end

function mcml.baseNode:SetObjId(id)
	self.uiobject_id = id;
end

-- get the control associated with this node. 
-- if self.uiobject_id is not nil, we will fetch it using this id, if self.control is not nil, it will be returned, otherwise we will use the unique path name to locate the control or uiobject by name. 
-- @param instName: the page instance name. if nil, we will ignore global control search in page. 
-- @return: It returns the ParaUIObject or CommonCtrl object depending on the type of the control found.
function mcml.baseNode:GetControl(pageName)
	if(self.uiobject_id) then
		local uiobj = ParaUI.GetUIObject(self.uiobject_id);
		if(uiobj:IsValid()) then
			return uiobj;
		end
	elseif(self.control) then
		return self.control;
	elseif(pageName) then
		local instName = self:GetInstanceName(pageName);
		if(instName) then
			local ctl = CommonCtrl.GetControl(instName);
			if(ctl == nil) then
				local uiobj = ParaUI.GetUIObject(instName);
				if(uiobj:IsValid()) then
					return uiobj;
				end
			else
				return ctl;	
			end
		end
	end
end

-- return font: "System;12;norm";  return nil if not available. 
function mcml.baseNode:CalculateFont(css)
	local font;
	if(css and (css["font-family"] or css["font-size"] or css["font-weight"]))then
		local font_family = css["font-family"] or "System";
		-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
		local font_size = math.floor(tonumber(css["font-size"] or 12));
		local font_weight = css["font-weight"] or "norm";
		font = string.format("%s;%d;%s", font_family, font_size, font_weight);
	end
	return font;
end

-- get UI control 
function mcml.baseNode:GetUIControl(pageName)
	if(self.uiobject_id) then
		local uiobj = ParaUI.GetUIObject(self.uiobject_id);
		if(uiobj:IsValid()) then
			return uiobj;
		end
	else
		local instName = self:GetInstanceName(pageName);
		if(instName) then
			local uiobj = ParaUI.GetUIObject(instName);
			if(uiobj:IsValid()) then
				return uiobj;
			end
		end
	end
end

-- print information about the parent nodes
function mcml.baseNode:printParents()
	log(tostring(self.name).." is a child of ")
	if(self.parent == nil) then
		log("\n")
	else
		self.parent:printParents();
	end
end

-- print this node to log file for debugging purposes. 
function mcml.baseNode:print()
	log("<"..tostring(self.name));
	if(self.attr) then
		local name, value
		for name, value in pairs(self.attr) do
			commonlib.log(" %s=\"%s\"", name, value);
		end
	end	
	local nChildSize = table_getn(self);
	if(nChildSize>0) then
		log(">");
		local i, node;
		local text = "";
		for i=1, nChildSize do
			node = self[i];
			if(type(node) == "table") then
				log("\n")
				node:print();
			elseif(type(node) == "string") then
				log(node)
			end
		end
		log("</"..self.name..">\n");
	else
		log("/>\n");
	end
end

-- set the value of a css style attribute after mcml node is evaluated. This function is rarely used. 
-- @note: one can only call this function when the mcml node is evaluated at least once, calling this function prior to evaluation will cause the style not to inherit its parent style 
-- alternatively, we can use self:SetAttribute("style", value) to change the entire attribute. 
-- @return true if succeed. 
function mcml.baseNode:SetCssStyle(attrName, value)
	if(type(self.style) == "table") then
		self.style[attrName] = value;
		return true
	else
		local style = self:GetStyle();
		style[attrName] = value;
	end
end

-- get the ccs attribute of a given css style attribute value. 
function mcml.baseNode:GetCssStyle(attrName)
	if(type(self.style) == "table") then
		return self.style[attrName];
	end
end

-- apply any css classnames in class attribute
function mcml.baseNode:ApplyClasses()
	-- apply attribute class names
	if(self.attr and self.attr.class) then
		local pageStyle = self:GetPageStyle();
		if(pageStyle) then
			local style = self:GetStyle();
			local class_names = self:GetAttributeWithCode("class", nil, true);
			if(class_names) then
				for class_name in class_names:gmatch("[^ ]+") do
					style:Merge(pe_css.default[class_name]);
					pageStyle:ApplyToStyleItem(style, class_name);
				end
			end
		end
	end
end

-- get the css style object if any. Style will only be evaluated once and saved to self.style as a table object, unless style attribute is changed by self:SetAttribute("style", value) method. 
-- @param baseStyle: nil or parent node's style object with which the current node's style is merged.
--  if the class property of this node is not nil, it the class style is applied over baseStyle. The style property if any is applied above the class and baseStyle
-- @param base_baseStyle: this is optional. it is the base style of baseStyle
-- @return: nil or the style table which is a table of name value pairs. such as {color=string, href=string}
function mcml.baseNode:GetStyle(baseStyle, base_baseStyle)
	if(self.style) then
		return self.style;
	end
	local style = StyleItem:new();
	self.style = style;

	style:Merge(base_baseStyle);
	style:Merge(baseStyle);

	self:ApplyClasses();

	--
	-- apply instance if any
	--
	if(self.attr and self.attr.style) then
		local style_code = self:GetAttributeWithCode("style", nil, true);
		style:Merge(style_code);
	end
	return style;
end

-- @param child: it can be mcmlNode or string node. 
-- @param index: 1 based index, at which to insert the item. if nil, it will be inserted to the end
function mcml.baseNode:AddChild(child, index)
	if(type(child)=="table") then
		local nCount = table_getn(self) or 0;
		child.index = commonlib.insertArrayItem(self, index, child)
		child.parent = self;
		-- table.setn(self, nCount + 1);
	elseif(type(child)=="string") then	
		local nCount = table_getn(self) or 0;
		commonlib.insertArrayItem(self, index, child)
		-- table.setn(self, nCount + 1);
	end	
end

-- detach this node from its parent node. 
function mcml.baseNode:Detach()
	local parentNode = self.parent
	if(parentNode == nil) then
		return
	end
	
	local nSize = table_getn(parentNode);
	local i, node;
	
	if(nSize == 1) then
		parentNode[1] = nil; 
		parentNode:ClearAllChildren();
		return;
	end
	
	local i = self.index;
	local node;
	if(i<nSize) then
		local k;
		for k=i+1, nSize do
			node = parentNode[k];
			parentNode[k-1] = node;
			if(node~=nil) then
				node.index = k-1;
				parentNode[k] = nil;
			end	
		end
	else
		parentNode[i] = nil;
	end	
	-- table.setn(parentNode, nSize - 1);
end

-- check whether this baseNode has a parent with the given name. It will search recursively for all ancesters. 
-- @param name: the parent name to search for. If nil, it will return parent regardless of its name. 
-- @return: the parent object is returned. 
function mcml.baseNode:GetParent(name)
	if(name==nil) then
		return self.parent
	end
	local parent = self.parent;
	while (parent~=nil) do
		if(parent.name == name) then
			return parent;
		end
		parent = parent.parent;
	end
end

-- get the root node, it will find in ancestor nodes until one without parent is found
-- @return root node.
function mcml.baseNode:GetRoot()
	local parent = self;
	while (parent.parent~=nil) do
		parent = parent.parent;
	end
	return parent;
end

-- Get the page control(PageCtrl) that loaded this mcml page. 
function mcml.baseNode:GetPageCtrl()
	return self:GetAttribute("page_ctrl") or self:GetParentAttribute("page_ctrl");
end	

-- get the page style object shared by all page elements.
function mcml.baseNode:GetPageStyle()
	local page = self:GetPageCtrl();
	if(page) then
		return page:GetStyle();
	end
end

-- search all parent with a given attribute name. It will search recursively for all ancesters.  
-- this function is usually used for getting the "request_url" field which is inserted by MCML web browser to the top level node. 
-- @param attrName: the parent field name to search for
-- @return: the nearest parent object field is returned. it may return, if no such parent is found. 
function mcml.baseNode:GetParentAttribute(attrName)
	local parent = self.parent;
	while (parent~=nil) do
		if(parent:GetAttribute(attrName)~=nil) then
			return parent:GetAttribute(attrName);
		end
		parent = parent.parent;
	end
end

-- get the url request of the mcml node if any. It will search for "request_url" attribtue field in the ancestor of this node. 
-- PageCtrl and BrowserWnd will automatically insert "request_url" attribtue field to the root MCML node before instantiate them. 
-- @return: nil or the request_url is returned. we can extract requery string parameters using regular expressions or using GetRequestParam
function mcml.baseNode:GetRequestURL()
	return self:GetParentAttribute("request_url") or self:GetAttribute("request_url");
end

-- get request url parameter by its name. for example if page url is "www.paraengine.com/user?id=10&time=20", then GetRequestParam("id") will be 10.
-- @return: nil or string value.
function mcml.baseNode:GetRequestParam(paramName)
	local request_url = self:GetRequestURL();
	return System.localserver.UrlHelper.url_getparams(request_url, paramName)
end

-- convert a url to absolute path using "request_url" if present
-- it will replace %NAME% with their values before processing next. 
-- @param url: it is any script, image or page url path which may be absolute, site root or relative path. 
--  relative to url path can not contain "/", anotherwise it is regarded as client side relative path. such as "Texture/whitedot.png"
-- @return: it always returns absolute path. however, if path cannot be resolved, the input is returned unchanged. 
function mcml.baseNode:GetAbsoluteURL(url)
	if(not url or url=="") then return url end
	-- it will replace %NAME% with their values before processing next. 
	url = paraworld.TranslateURL(url);
	
	if(string_find(url, "^([%w]*)://"))then
		-- already absolute path
	else	
		local request_url = self:GetRequestURL();
		if(request_url) then
			NPL.load("(gl)script/ide/System/localserver/security_model.lua");
			local secureOrigin = System.localserver.SecurityOrigin:new(request_url)
			
			if(string_find(url, "^/\\")) then
				-- relative to site root.
				if(secureOrigin.url) then
					url = secureOrigin.url..url;
				end	
			elseif(string_find(url, "[/\\]")) then
				-- if relative to url path contains "/", it is regarded as client side SDK root folder. such as "Texture/whitedot.png"
			elseif(string_find(url, "^#")) then	
				-- this is an anchor
				url = string_gsub(request_url,"^([^#]*)#.-$", "%1")..url
			else
				-- relative to request url path
				url = string_gsub(string_gsub(request_url, "%?.*$", ""), "^(.*)/[^/\\]-$", "%1/")..url
			end
		end	
	end
	return url;
end

-- get the user ID of the owner of the profile. 
function mcml.baseNode:GetOwnerUserID()
	local profile = self:GetParent("pe:profile") or self;
	if(profile) then
		return profile:GetAttribute("uid");
	end
end

-- Get child count
function mcml.baseNode:GetChildCount()
	return table_getn(self);
end

-- Clear all child nodes
function mcml.baseNode:ClearAllChildren()
	commonlib.resize(self, 0);
	-- table.setn(self, 0);
end

-- generate a less compare function according to a node field name. 
-- @param fieldName: the name of the field, such as "text", "name", etc
function mcml.baseNode.GenerateLessCFByField(fieldName)
	fieldName = fieldName or "name";
	return function(node1, node2)
		if(node1[fieldName] == nil) then
			return true
		elseif(node2[fieldName] == nil) then
			return false
		else
			return node1[fieldName] < node2[fieldName];
		end	
	end
end

-- generate a greater compare function according to a node field name. 
-- @param fieldName: the name of the field, such as "text", "name", etc
--   One can also build a compare function by calling mcml.baseNode.GenerateLessCFByField(fieldName) or mcml.baseNode.GenerateGreaterCFByField(fieldName)
function mcml.baseNode.GenerateGreaterCFByField(fieldName)
	fieldName = fieldName or "name";
	return function(node1, node2)
		if(node2[fieldName] == nil) then
			return true
		elseif(node1[fieldName] == nil) then
			return false
		else
			return node1[fieldName] > node2[fieldName];
		end	
	end
end

-- sorting the children according to a compare function. Internally it uses table.sort().
-- Note: child indices are rebuilt and may cause UI binded controls to misbehave
-- compareFunc: if nil, it will compare by node.name. 
function mcml.baseNode:SortChildren(compareFunc)
	compareFunc = compareFunc or mcml.baseNode.GenerateLessCFByField("name");
	-- quick sort
	table.sort(self, compareFunc)
	-- rebuild index. 
	local i, node
	for i,node in ipairs(self) do
		node.index = i;
	end
end

-- get a string containing the node path. such as "1/1/1/3"
-- as long as the baseNode does not change, the node path uniquely identifies a baseNode.
function mcml.baseNode:GetNodePath()
	local path = tostring(self.index);
	while (self.parent ~=nil) do
		path = tostring(self.parent.index).."/"..path;
		self = self.parent;
	end
	return path;
end

-- @param rootName: a name that uniquely identifies a UI instance of this object, usually the userid or app_key. The function will generate a sub control name by concartinating this rootname with relative baseNode path. 
function mcml.baseNode:GetInstanceName(rootName)
	return tostring(rootName)..self:GetNodePath();
end

-- get the first occurance of first level child node whose name is name
-- @param name: if can be the name of the node, or it can be a interger index. 
function mcml.baseNode:GetChild(name)
	if(type(name) == "number") then
		return self[name];
	else
		local nSize = table_getn(self);
		local i, node;
		for i=1, nSize do
			node = self[i];
			if(type(node)=="table" and name == node.name) then
				return node;
			end
		end
	end	
end

-- get the first occurance of first level child node whose name is name
-- @param name: if can be the name of the node, or it can be a interger index. 
-- @return nil if not found
function mcml.baseNode:GetChildWithAttribute(name, value)
	local nSize = table_getn(self);
	local i, node;
	for i=1, nSize do
		node = self[i];
		if(type(node)=="table") then
			if(value == node:GetAttribute(name)) then
				return node;
			end	
		end
	end
end

-- get the first occurance of child node whose attribute name is value. it will search for all child nodes recursively. 
function mcml.baseNode:SearchChildByAttribute(name, value)
	local nSize = table_getn(self);
	local i, node;
	for i=1, nSize do
		node = self[i];
		if(type(node)=="table") then
			if(value == node:GetAttribute(name)) then
				return node;
			else
				node = node:SearchChildByAttribute(name, value);
				if(node) then
					return node;
				end
			end	
		end
	end
end

-- return an iterator of all first level child nodes whose name is name
-- a more advanced way to tranverse mcml tree is using ide/Xpath
-- @param name: if name is nil, all child is returned. 
function mcml.baseNode:next(name)
	local nSize = table_getn(self);
	local i = 1;
	return function ()
		local node;
		while i <= nSize do
			node = self[i];
			i = i+1;
			if(not name or (type(node) == "table" and name == node.name)) then
				return node;
			end
		end
	end	
end


-- this is a jquery meta table, if one wants to add jquery-like function calls, just set this metatable as the class array table. 
-- e.g. setmetatable(some_table, jquery_metatable)
local jquery_metatable = {
	-- each invocation will create additional tables and closures, hence the performance is not supper good. 
	__index = function(t, k)
		if(type(k) == "string") then
			local func = {};
			setmetatable(func, {
				-- the first parameter is always the mcml_node. 
				-- the return value is always the last node's result
				__call = function(self, self1, ...)
					local output;
					local i, node
					for i, node in ipairs(t) do
						if(type(node[k]) == "function")then
							output = node[k](node, ...);
						end
					end
					return output;
				end,
			});
			return func;
		elseif(type(k) == "number") then
			return t[k];
		end
	end,
}

-- provide jquery-like syntax to find all nodes that match a given name pattern and then use the returned object to invoke a method on all returned nodes. 
-- it can also be used to create a new node like "<div />"
--  e.g. node:jquery("a"):show();
-- @param pattern: The valid format is [tag_name][#name_id][.class_name] or "<tag_name />". 
--  e.g. "div#name.class_name", "#some_name", ".some_class", "div"
--  e.g. "<div />" will create a new node. 
-- @param param1: additional xml node when pattern is "<tag_name />"
function mcml.baseNode:jquery(pattern, param1)
	local tagName = pattern and pattern:match("^<([^%s/>]*)");
	if(tagName) then
		param1 = param1 or {name=tagName, attr={}};
		param1.name = param1.name or tagName;
		return System.mcml.new(nil, param1);
	else
		local output = {}
		if(pattern) then
			local tag_name, pattern = pattern:match("^([^#%.]*)(.*)");
			if(tag_name == "") then
				tag_name = nil;
			end
			local id;
			if(pattern) then
				id = pattern:match("#([^#%.]+)");
			end
			local class_name;
			if(pattern) then
				class_name = pattern:match("%.([^#%.]+)");
			end
			self:GetAllChildWithNameIDClass(tag_name, id, class_name, output);
		
		end
		setmetatable(output, jquery_metatable)
		return output;
	end
end

-- show this node. one may needs to refresh the page if page is already rendered
function mcml.baseNode:show()
	self:SetAttribute("display", nil)
end

-- hide this node. one may needs to refresh the page if page is already rendered
function mcml.baseNode:hide()
	self:SetAttribute("display", "none")
end

-- get/set inner text
-- @param v: if not nil, it will set inner text instead of get
-- return the inner text or empty string. 
function mcml.baseNode:text(v)
	if(v == nil) then
		local inner_text = self[1];
		if(type(inner_text) == "string") then
			return inner_text;
		else
			return ""
		end
	else
		self:ClearAllChildren();
		self[1] = v;
	end
end

-- get/set ui or node value of the node. 
-- @param v: if not nil, it will set value instead of get
function mcml.baseNode:value(v)
	if(v == nil) then
		local value_ = self:GetUIValue();
		if(value_==nil) then
			return self:GetValue();
		else
			return value_;	
		end	
	else
		self:SetUIValue(v);
		self:SetValue(v);
	end
end

-- return a table containing all child nodes whose name is name. (it will search recursively)
-- a more advanced way to tranverse mcml tree is using ide/Xpath
-- @param name: the tag name. if nil it matches all
-- @param id: the name attribute. if nil it matches all
-- @param class: the class attribute. if nil it matches all
-- @param output: nil or a table to receive the result. child nodes with the name is saved to this table array. if nil, a new table will be created. 
-- @return output: the output table containing all children. It may be nil if no one is found and input "output" is also nil.
function mcml.baseNode:GetAllChildWithNameIDClass(name, id, class, output)
	local nSize = table_getn(self);
	local i = 1;
	local node;
	while i <= nSize do
		node = self[i];
		i = i+1;
		if(type(node) == "table") then
			if( (not name or name == node.name) and
				(not id or id == node:GetAttribute("name")) and
				(not class or class==node:GetAttribute("class")) ) then
				output = output or {};
				table.insert(output, node);
			else
				output = node:GetAllChildWithNameIDClass(name, id, class, output)
			end	
		end
	end
	return output;
end

-- return a table containing all child nodes whose name is name. (it will search recursively)
-- a more advanced way to tranverse mcml tree is using ide/Xpath
-- @param name: the tag name
-- @param output: nil or a table to receive the result. child nodes with the name is saved to this table array. if nil, a new table will be created. 
-- @return output: the output table containing all children. It may be nil if no one is found and input "output" is also nil.
function mcml.baseNode:GetAllChildWithName(name, output)
	local nSize = table_getn(self);
	local i = 1;
	local node;
	while i <= nSize do
		node = self[i];
		i = i+1;
		if(type(node) == "table") then
			if(name == node.name) then
				output = output or {};
				table.insert(output, node);
			else
				output = node:GetAllChildWithName(name, output)
			end	
		end
	end
	return output;
end

-- return an iterator of all child nodes whose attribtue attrName is attrValue. (it will search recursively)
-- a more advanced way to tranverse mcml tree is using ide/Xpath
-- @param name: if name is nil, all child is returned. 
-- @param output: nil or a table to receive the result. child nodes with the name is saved to this table array. if nil, a new table will be created. 
-- @return output: the output table containing all children. It may be nil if no one is found and input "output" is also nil.
function mcml.baseNode:GetAllChildWithAttribute(attrName, attrValue, output)
	local nSize = table_getn(self);
	local i = 1;
	local node;
	while i <= nSize do
		node = self[i];
		i = i+1;
		if(type(node) == "table") then
			if(node:GetAttribute(attrName) == attrValue) then
				output = output or {};
				table.insert(output, node);
			else
				output = node:GetAllChildWithAttribute(attrName, attrValue, output)
			end	
		end
	end
	return output;
end

-- this function will apply self.pre_values to current page scope during rendering.
-- making it accessible to XPath and Eval function.  
function mcml.baseNode:ApplyPreValues()
	if(type(self.pre_values) == "table") then
		local pageScope = self:GetPageCtrl():GetPageScope();
		if(pageScope) then
			for name, value in pairs(self.pre_values) do
				pageScope[name] = value;
			end
		end
	end
end

-- apply a given pre value to this node, so that when the node is rendered, the name, value pairs will be
-- written to the current page scope. Not all mcml node support pre values. it is most often used by databinding template node. 
function mcml.baseNode:SetPreValue(name, value)
	self.pre_values = self.pre_values or {};
	self.pre_values[name] = value;
end

-- get a prevalue by name. this function is usually called on data binded mcml node 
-- @param name: name of the pre value
-- @param bSearchParent: if true, it will search parent node recursively until name is found or root node is reached. 
function mcml.baseNode:GetPreValue(name, bSearchParent)
	if(self.pre_values) then
		return self.pre_values[name];
	elseif(bSearchParent) then
		local parent = self.parent;
		while (parent~=nil) do
			if(parent.pre_values) then
				return parent.pre_values[name];
			end
			parent = parent.parent;
		end
	end
end

-- here we will translate current node and all of its child nodes recursively, using the given langTable 
-- unless any of the child attribute disables or specifies a different lang using the trans attribute
-- @note: it will secretly mark an already translated node, so it will not be translated twice when the next time this method is called.
-- @param langTable: this is a translation table from CommonCtrl.Locale(transName); if this is nil, 
-- @param transName: the translation name of the langTable. 
function mcml.baseNode:TranslateMe(langTable, transName)
	local trans = self:GetAttribute("trans");
	if(trans) then
		if(trans == "no" or trans == "none") then 
			return
		elseif(trans ~= transName) then
			langTable = CommonCtrl.Locale(trans);
			transName = trans;
			if(not langTable) then
				LOG.warn("lang table %s is not found for the mcml page\n", trans);
			end
		end	
		-- secretly mark an already translated node, so it will not be translated twice when the next time this method is called.
		if(self.IsTranslated) then
			return
		else
			self.IsTranslated = true;
		end
	end	
	-- translate this and all child nodes recursively
	if(langTable) then
		-- translate attributes of current node. 
		if(self.attr) then
			local name, value 
			for name, value in pairs(self.attr) do
				-- we will skip some attributes. 
				if(name~="style" and name~="id" and name~="name") then
					if(type(value) == "string") then
						-- TRANSLATE: translate value
						if(langTable:HasTranslation(value)) then
							--commonlib.echo(langTable(value))
							self.attr[name] = langTable(value);
						end	
					end
				end	
			end
		end
	
		-- translate child nodes recursively. 	
		local nSize = table_getn(self);
		local i = 1;
		local node;
		while i <= nSize do
			node = self[i];
			if(type(node) == "table") then
				node:TranslateMe(langTable, transName)
			elseif(type(node) == "string") then
				-- only translate if the node is not unknown and not script node.
				if(self.name ~= "script" and self.name ~= "unknown" and self.name ~= "pe:script") then
					-- TRANSLATE: translate inner text
					if(langTable:HasTranslation(node)) then
						--commonlib.echo(langTable(node))
						self[i] = langTable(node)
					end
				end	
			end
			i = i+1;
		end
	end
end

-- if there an attribute called variables. 
-- variables are frequently used for localization in mcml. Both table based localization and commonlib.Locale based localization are supported. 
function mcml.baseNode:ProcessVariables()
	local variables_str = self:GetAttribute("variables");
	if(variables_str and not self.__variable_processed) then
		self.__variable_processed = true;

		--  a table containing all variables
		local variables = {};

		local var_name, var_value
		for var_name, var_value in string.gmatch(variables_str, "%$(%w*)=([^;%$]+)") do
			local func = commonlib.getfield(var_value) or commonlib.Locale:GetByName(var_value);
			variable = {
					var_name=var_name, 
					match_exp="%$"..var_name.."{([^}]*)}", 
					gsub_exp="%$"..var_name.."{[^}]*}", 
				};
			if(not func) then
				-- try to find a locale file with value under the given folder
				-- suppose var_value is "locale.mcml.IDE", then we will first try "locale/mcml/IDE.lua" and then try "locale/mcml/IDE_enUS.lua"
				local filename = var_value:gsub("%.", "/");
				local locale_file1 = format("%s.lua", filename);
				local locale_file2 = format("%s_%s.lua", filename, ParaEngine.GetLocale());
				if(ParaIO.DoesFileExist(locale_file1)) then
					filename = locale_file1;
				elseif(ParaIO.DoesFileExist(locale_file2)) then
					filename = locale_file2;
				else
					filename = nil;
				end
				if(filename) then
					NPL.load("(gl)"..filename);
					LOG.std(nil, "system", "mcml", "loaded variable file %s for %s", filename, var_value);
					func = commonlib.getfield(var_value) or commonlib.Locale:GetByName(var_value);
					if(not func) then
						func = commonlib.gettable(var_value);
						LOG.std(nil, "warn", "mcml", "empty table is created and used for variable %s. Ideally it should be %s or %s", var_value, locale_file1, locale_file2);
					end
				else
					LOG.std(nil, "warn", "mcml", "can not find variable table file for %s. It should be %s or %s", var_value, locale_file1, locale_file2);
				end
			end

			if(type(func) == "function") then
				variable.func = func
				variables[#variables+1] = variable;
			elseif(type(func) == "table") then
				local meta_table = getmetatable(func);
				if(meta_table and meta_table.__call) then
					variable.func = func
				else
					variable.func = function(name)
						return func[name];
					end
				end
				variables[#variables+1] = variable;
			else
				LOG.std(nil, "warn", "mcml", "unsupported $ %s params", var_name);
			end
		end

		if(#variables>0) then
			self:ReplaceVariables(variables);
		end
	end
end

function mcml.baseNode:ReplaceVariables(variables)
	if(variables) then
		-- translate this and all child nodes recursively
		-- translate attributes of current node. 
		if(self.attr) then
			local name, value 
			for name, value in pairs(self.attr) do
				-- we will skip some attributes. 
				if(type(value) == "string") then
					-- REPLACE
					local k;
					for k=1, #variables do
						local variable = variables[k];
						local var_value = value:match(variable.match_exp)
						if(var_value) then
							value = value:gsub(variable.gsub_exp, variable.func(var_value) or var_value);
							self.attr[name] = value;
						end
					end
				end
			end
		end
	
		-- translate child nodes recursively. 	
		local nSize = table_getn(self);
		local i = 1;
		local node;
		while i <= nSize do
			node = self[i];
			if(type(node) == "table") then
				node:ReplaceVariables(variables)
			elseif(type(node) == "string") then
				local value = node;
				-- REPLACE
				local k;
				for k=1, #variables do
					local variable = variables[k];
					local var_value = value:match(variable.match_exp)
					if(var_value) then
						value = value:gsub(variable.gsub_exp, variable.func(var_value) or var_value); 
						self[i] = value;
					end
				end
			end
			i = i+1;
		end
	end
end

-- This callback is used mostly with DrawDisplayBlock() function. 
-- @param mcmlNode: this mcml node. 
-- @param _parent: the ui object inside which UI controls should be created. 
-- @param left, top, width, height: this is actually left, top, right, bottom relative to _parent control (css padding is NOT applied). 
-- @param myLayout: this is the layout inside which child nodes should be created (css padding is applied). 
function mcml.baseNode.DrawChildBlocks_Callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
	for childnode in mcmlNode:next() do
		local left, top, width, height = myLayout:GetPreferredRect();
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, 
			{display=css["display"], color = css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"], ["text-shadow"] = css["text-shadow"], ["base-font-size"] = css["base-font-size"]}, myLayout)
	end
end


-- Call this function to draw display block with a custom callback. 
-- This function is usually called by the mcml tag's create() function.
-- Right now, mcml renderer uses one pass rendering, hence there is some limitation on block layout capabilities. 
-- One of the biggest limitation is that all floating display blocks must have explicit size specified in css in order to function.
-- A multi-pass renderer can do more flexible layout, yet at the cost of code complexity and CPU. 
-- This function supports all features of the original mcml's div tag. 
-- @param parentLayout: the parent layout structure. When this function returns, the parent layout will be modified. 
-- @param _parent: the ui object inside which UI controls should be created. 
-- @param left, top, width, height: this is actually left, top, right, bottom relative to _parent control. 
-- @param style: the parent css style. 
-- @param render_callback: a function(mcmlNode, rootName, bindingContext, _parent, myLayout, css) end, inside which we can render the content.
--  this function can return ignore_onclick, ignore_background. if true it will ignore onclick and background handling 
--  see self.DrawChildBlocks_Callback for an example callback
function mcml.baseNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, render_callback)
	local mcmlNode = self;
	if(mcmlNode:GetAttribute("display") == "none") then return end

	-- process any variables that is taking place. 
	mcmlNode:ProcessVariables();

	local css = mcmlNode:GetStyle(pe_html.css[mcmlNode.name], style) or {};
	if(style) then
		-- pass through some css styles from parent. 
		css.color = css.color or style.color;
		css["font-family"] = css["font-family"] or style["font-family"];
		css["font-size"] = css["font-size"] or style["font-size"];
		css["font-weight"] = css["font-weight"] or style["font-weight"];
		css["text-shadow"] = css["text-shadow"] or style["text-shadow"];
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
		if(maxWidth>max_width) then
			local left, top, right, bottom = parentLayout:GetAvailableRect();
			-- align at center. 
			local align = mcmlNode:GetAttribute("align") or css["align"];
			if(align == "center") then
				left = left + (maxWidth - max_width)/2
			elseif(align == "right") then
				left = right - max_width;
			end	
			right = left + max_width;
			parentLayout:reset(left, top, right, bottom);
		end
	end

	if(css["max-height"]) then
		local max_height = css["max-height"];
		if(maxHeight>max_height) then
			local left, top, right, bottom = parentLayout:GetAvailableRect();
			-- align at center. 
			local valign = mcmlNode:GetAttribute("valign") or css["valign"];
			if(valign == "center") then
				top = top + (maxHeight - max_height)/2
			elseif(valign == "bottom") then
				top = bottom - max_height;
			end	
			bottom = top + max_height;
			parentLayout:reset(left, top, right, bottom);
		end
	end
	
	if(mcmlNode:GetAttribute("trans")) then
		-- here we will translate all child nodes recursively, using the given lang 
		-- unless any of the child attribute disables or specifies a different lang
		mcmlNode:TranslateMe();
	end
	
	local width, height = mcmlNode:GetAttribute("width"), mcmlNode:GetAttribute("height");
	if(width) then
		css.width = tonumber(string.match(width, "%d+"));
		if(css.width and string.match(width, "%%$")) then
			if(css.position == "screen") then
				css.width = ParaUI.GetUIObject("root").width * css.width/100;
			else	
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
				if(availHeight<(css.height+margin_top+margin_bottom)) then
					css.height=availHeight-margin_top-margin_bottom;
				end
				if(css.height<=0) then
					css.height = nil;
				end
			end	
		end	
	end
	
	-- whether this control takes up space
	local bUseSpace; 
	if(css.float) then
		local minWidth = css.width or css["min-width"];
		if(minWidth) then
			if(availWidth<(minWidth+margin_left+margin_right)) then
				parentLayout:NewLine();
			end
		end	
	else
		parentLayout:NewLine();
	end
	local myLayout = parentLayout:clone();
	myLayout:ResetUsedSize();
	
	if(css.width) then
		local align = mcmlNode:GetAttribute("align") or css["align"];
		if(align and align~="left") then
			local max_width = css.width;
			local left, top, right, bottom = myLayout:GetAvailableRect();
			-- align at center. 
			if(align == "center") then
				left = left + (maxWidth - max_width)/2
			elseif(align == "right") then
				max_width = max_width + margin_left + margin_right;
				left = right - max_width;
			end	
			right = left + max_width
			myLayout:reset(left, top, right, bottom);
		end
	end
	if(css.height) then
		-- align at center. 
		local valign = mcmlNode:GetAttribute("valign") or css["valign"];
		if(valign and valign~="top") then
			local max_height = css.height;
			local left, top, right, bottom = myLayout:GetAvailableRect();
			if(valign == "center") then
				top = top + (maxHeight - max_height)/2
			elseif(valign == "bottom") then
				max_height = max_height + margin_top + margin_bottom;
				top = bottom - max_height;
			end	
			bottom = top + max_height
			myLayout:reset(left, top, right, bottom);
		end
	end

	if(css.position == "absolute") then
		-- absolute positioning in parent
		if(css.width and css.height and css.left and css.top) then
			-- if all rect is provided, we will do true absolute position. 
			myLayout:reset(css.left, css.top, css.left + css.width, css.top + css.height);
		else
			-- this still subject to parent rect. 
			myLayout:SetPos(css.left, css.top);
		end
		myLayout:ResetUsedSize();
	elseif(css.position == "relative") then
		-- relative positioning in next render position. 
		myLayout:OffsetPos(css.left, css.top);
	elseif(css.position == "screen") then	
		-- relative positioning in screen client area
		local offset_x, offset_y = 0, 0;
		local left, top = mcmlNode:GetAttribute("left"), mcmlNode:GetAttribute("top");
		if(left) then
			left = tonumber(string.match(left, "(%d+)%%$"));
			offset_x = ParaUI.GetUIObject("root").width * left/100;
		end
		if(top) then
			top = tonumber(string.match(top, "(%d+)%%$"));
			offset_y = ParaUI.GetUIObject("root").height * top/100;
		end
		local px,py = _parent:GetAbsPosition();
		myLayout:SetPos((css.left or 0)-px + offset_x, (css.top or 0)-py + offset_y); 
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

	---------------------------------
	-- draw inner nodes.
	---------------------------------
	local ignore_onclick, ignore_background, ignore_tooltip;

	
	if(render_callback) then
		local left, top, width, height = myLayout:GetPreferredRect();
		ignore_onclick, ignore_background, ignore_tooltip = render_callback(mcmlNode, rootName, bindingContext, _parent, left-padding_left, top-padding_top, width+padding_right, height+padding_bottom, myLayout, css);
	end

	local width, height = myLayout:GetUsedSize()
	width = width + padding_right + margin_right
	height = height + padding_bottom + margin_bottom
	if(css.width) then
		width = left + css.width + margin_left+margin_right;
	end	
	if(css.height) then
		height = top + css.height + margin_top+margin_bottom;
	end
	if(css["min-width"]) then
		local min_width = css["min-width"];
		if((width-left) < min_width) then
			width = left + min_width;
		end
	end
	if(css["min-height"]) then
		local min_height = css["min-height"];
		if((height-top) < min_height) then
			height = top + min_height;
		end
	end
	if(css["max-height"]) then
		local max_height = css["max-height"];
		if((height-top) > max_height) then
			height = top + max_height;
		end
	end
	if(bUseSpace) then
		parentLayout:AddObject(width-left, height-top);
		if(not css.float) then
			parentLayout:NewLine();
		end	
	end
	local onclick, ontouch;
	local onclick_for;
	if(not ignore_onclick) then
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
	end
	local tooltip
	if(not ignore_tooltip) then
		tooltip = mcmlNode:GetAttributeWithCode("tooltip",nil,true);
		if(tooltip == "") then
			tooltip = nil;
		end
	end
	local background;
	if(not ignore_background) then
		background = mcmlNode:GetAttribute("background") or css.background;
	end
	if(css["background-color"] and not ignore_background) then
		if(not background and not css.background2) then
			background = "Texture/whitedot.png";
		end
	end

	if(onclick_for or onclick or tooltip or ontouch) then
		-- if there is onclick event, the inner nodes will not be interactive.
		local instName = mcmlNode:GetInstanceName(rootName);
		local _this=ParaUI.CreateUIObject("button",instName or "b","_lt", left+margin_left, top+margin_top, width-left-margin_left-margin_right, height-top-margin_top-margin_bottom);
		mcmlNode.uiobject_id = _this.id;
		if(background) then
			_this.background = background;
			if(background~="") then
				if(css["background-color"]) then
					_guihelper.SetUIColor(_this, css["background-color"]);
				end	
				if(css["background-rotation"]) then
					_this.rotation = tonumber(css["background-rotation"])
				end
				if(css["background-repeat"] == "repeat") then
					_this:GetAttributeObject():SetField("UVWrappingEnabled", true);
				end
			end
			if(css["background-animation"]) then
				local anim_file = string.gsub(css["background-animation"], "url%((.*)%)", "%1");
				local fileName,animName = string.match(anim_file, "^([^#]+)#(.*)$");
				if(fileName and animName) then
					UIAnimManager.PlayUIAnimationSequence(_this, fileName, animName, true);
				end
			end
		else
			_this.background = "";
		end
		if(css.background2 and not ignore_background) then
			_guihelper.SetVistaStyleButton(_this, nil, css.background2);
		end
		local zorder = mcmlNode:GetNumber("zorder");
		if(zorder) then
			_this.zorder = zorder
		end
		if(onclick_for or onclick or ontouch) then
			local btnName = mcmlNode:GetAttributeWithCode("name")
			-- tricky: we will just prefetch any params with code that may be used in the callback 
			local i;
			for i=1,5 do
				if(not mcmlNode:GetAttributeWithCode("param"..i)) then
					break;
				end
			end
			if(onclick_for or onclick) then
				_this:SetScript("onclick", Map3DSystem.mcml_controls.pe_editor_button.on_click, mcmlNode, instName, bindingContext, btnName);
			elseif(ontouch) then
				_this:SetScript("ontouch", Map3DSystem.mcml_controls.pe_editor_button.on_touch, mcmlNode, instName, bindingContext, btnName);
			end
		end	
		if(tooltip) then
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
		_parent:AddChild(_this);
	else
		if(background) then
			local instName;
			if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
				-- this is solely for giving a global name to background image control so that it can be animated
				-- background image control is mutually exclusive with inner text control. hence if there is a background, inner text becomes anonymous
				instName = mcmlNode:GetInstanceName(rootName);
			end	
			local _this=ParaUI.CreateUIObject("button",instName or "b","_lt", left+margin_left, top+margin_top, width-left-margin_left-margin_right, height-top-margin_top-margin_bottom);
			_this.background = background;
			_this.enabled = false;
			mcmlNode.uiobject_id = _this.id;
			if(css["background-color"]) then
				_guihelper.SetUIColor(_this, css["background-color"]);
			else
				_guihelper.SetUIColor(_this, "255 255 255 255");
			end	
			if(css["background-rotation"]) then
				_this.rotation = tonumber(css["background-rotation"])
			end
			if(css["background-repeat"] == "repeat") then
				_this:GetAttributeObject():SetField("UVWrappingEnabled", true);
			end
			_parent:AddChild(_this);
			local zorder = mcmlNode:GetNumber("zorder");
			if(zorder) then
				_this.zorder = zorder
			end
			_this:BringToBack();
			if(css["background-animation"]) then
				local anim_file = string.gsub(css["background-animation"], "url%((.*)%)", "%1");
				local fileName,animName = string.match(anim_file, "^([^#]+)#(.*)$");
				if(fileName and animName) then
					UIAnimManager.PlayUIAnimationSequence(_this, fileName, animName, true);
				end
			end
		elseif(mcmlNode:GetBool("enabled") == false) then
			local _this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top, width-left-margin_left-margin_right, height-top-margin_top-margin_bottom);
			if(tooltip) then
				_this.tooltip = tooltip;
			end
			_this.background = background or "";
			_parent:AddChild(_this);
		end
	end	
	
	-- call onload(mcmlNode) function if any. 
	local onloadFunc = mcmlNode:GetString("onload");
	if(onloadFunc and onloadFunc~="") then
		Map3DSystem.mcml_controls.pe_script.BeginCode(mcmlNode);
		local pFunc = commonlib.getfield(onloadFunc);
		if(type(pFunc) == "function") then
			pFunc(mcmlNode);
		else
			LOG.std("", "warn", "mcml", "%s node's onload call back: %s is not a valid function.", mcmlNode.name, onloadFunc)	
		end
		Map3DSystem.mcml_controls.pe_script.EndCode(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout);
	end
end

-- fire a given page event by its name
-- @param event_name: such as "onclick". 
function mcml.baseNode:OnPageEvent(event_name, ...)
	local callback_script = self:GetString(event_name);
	if(callback_script and callback_script~="") then
		Map3DSystem.mcml_controls.OnPageEvent(self, callback_script, ...);
	end
end