--[[
Title: databinding treeview
Author(s): LiXizhi
Date: 2010/9/13
Desc: pe:treeview

---++ pe:treeview
this control will fill entire client area, such returned top is height. if child node is not pe:treenode, it is always 
rendered inside an anonymous treenode using the default height all child nodes are created only when viewable.

*properties*: 
| *property* | *description* |
| background |  |
| DefaultNodeHeight |  |
| DefaultIconSize |  |
| ShowIcon |  |
| ItemOpenBG | The plus sign like image path |
| ItemCloseBG | The minus sign like image path |
| ItemToggleSize | the open/close item image size. default to 10. if 0 it will not be shown |
| ItemToggleRightSpacing | default to 6. the spacing between toggle item image and the text.  | 
| DefaultIndentation |  |
| VerticalScrollBarStep |  |
| VerticalScrollBarPageSize |  |
| RememberScrollPos | boolean |
| MouseOverBG | if not provided, it will use "Texture/alphadot.png" |
| DataSource | it should be a xml table to bind to  |
| DataSourceID | it should be an node id in the page to be used as the xml input |
| ClickThrough | wheather mouse event will leak to 3d scene. default to false  |
| OnClick | default onclick function(treenode) end, it can be in page scope. |
| ScrollBarTrackWidth | |
| VerticalScrollBarWidth | |

Node Method:
| DataBind(bRefreshUI) | call this function or fresh the page whenever datasource is changed. |

---+++ databinding with treeview
right now databinding is not suitable for extreamly large data source like tens of thousands of nodes
since we will need to create them all during data binding.  However, rendering is always efficient once created. 

One can provide any number of NodeTemplate inside NodeTemplates, where DataType must be the same as the xml node name in data source. 
For expandable node: the NodeTemplate must contain a single pe:treenode as its template in order to support auto expanding. 
Although the standard pe:treenode has some basic custimization, one can provide its own draw node method. 

Another cool feature is that one can control where the databinded treenodes to appear in the treeview. 
This is done by placing a <DataNodePlaceholder /> anywhere inside pe:treeview. If it is not provided, 
it will be created automatically as the last child of pe:treeview. One can optionally specify an xpath on its 
attribute to specify which portion of the data source to bind to. There can be multiple <DataNodePlaceholder /> with different xpath. 

tree view sample code: 
<verbatim> 

<pe:treeview name="tvwXMLTest" DataSource='<%={ {name="folder", attr={text="parent_folder", is_expanded=true}, {name="file", attr={text="filename"}}, }%>'
		DefaultNodeHeight = "20" OnClick="tvwOnClickNode()">
	<pe:treenode text="static nodes">
		<div>this is static nodes that are not bound to any data source. it can shown either before or after NodeTemplates</div>
	</pe:treenode>
	<NodeTemplates>
		<NodeTemplate DataType="folder">
            <pe:treenode text='<%=XPath("this|text")%>' expanded='<%=XPath("this|expanded")%>'></pe:treenode>
        </NodeTemplate>
        <NodeTemplate DataType="file">
            <div style="height:20px;">
                <%=XPath("this|text")%>
				<span color="#008000">(已完成)</span>
            </div>
        </NodeTemplate>
	</NodeTemplates>
	<DataNodePlaceholder xpath="*"/>
	<pe:treenode text="Select all file nodes">
		<DataNodePlaceholder xpath="//file"/>
	</pe:treenode>
	<div>some other static tree node after the data binded node</div>
</pe:treeview>

</verbatim>

Example 2: binding with XPath:
<verbatim>
<!--this is a sample embedded data source which is referenced by name-->
<Resource style="display:none" name="MySampleDataSource" >
    <folder text="folder1" expanded="true">
        <folder text="folder1_1" expanded="true">
            <file text="some file1" finished="true"></file>
        </folder>
        <file text="some file2"></file>
        <file text="some file3"></file>
    </folder>
    <folder text="folder2">
        <file text="some file4" finished="true"></file>
    </folder>
    <file text="some file5"></file>
</Resource>

<pe:treeview name="tvwXMLTest2" DataSourceID='MySampleDataSource' DefaultNodeHeight="20" OnClick="tvwOnClickNode()">
	<NodeTemplates>
		<NodeTemplate DataType="folder">
            <pe:treenode text='<%=XPath("this|text")%>' expanded='<%=XPath("this|expanded")%>'></pe:treenode>
        </NodeTemplate>
        <NodeTemplate DataType="file">
            <div style="height:20px;">
                <%=XPath("this|text")%>
				<span color="#008000">(已完成)</span>
            </div>
        </NodeTemplate>
	</NodeTemplates>
    <pe:treenode text="all nodes without filter" expanded="true">
        <DataNodePlaceholder xpath="*"/>
    </pe:treenode>
    <pe:treenode text="not finished nodes" expanded="true">
        <DataNodePlaceholder xpath="//file[@finished = 'true']"/>
	</pe:treenode>
</pe:treeview>
</verbatim>

---++ pe:treenode 
sub nodes of current pe:treenode are child tree nodes. For databinding, the following can also be binded data source.

*properties*: 
| *property* | *description* |
| name |  |
| selected | "true" or "false", default to false |
| text |  |
| tooltip |  |
| style | height, color, font-weight, font-size are used |
| icon |  |
| height |  |
| indent |  |
| expanded |  |
| invisible |  |
| can_select | true to allow selection. this applys to both parent and leaf node |
| OnClick | onclick function(treenode) end, it can be in page scope. |
| RenderTemplate | specify a note template type in NodeTemplates to be used for rendering on behalf of this pe:treenode. The difference is that it will have the treeview onclick, onselect function auto implemented. 
  inside RenderTemplate we can use XPath("treenode|Expanded") to retrieve property of the parent treenode object. |
| MouseOverBG | if not provided, it will use the parent treeview's MouseOverBG |
| AttributeBind | a table containing parameters that should be passed to TreeNode:BindParaAttributeObject(). 
	e.g. {att=ParaTerrain.GetAttributeObject(), bReadOnly=true, fieldNames=nil, fieldTextReplaceables={["RenderTerrain"] = "whether to draw terrain",}} |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_treeview.lua");
-------------------------------------------------------
]]
local type = type;
-----------------------------------
-- pe:treeview control: 
-----------------------------------
local pe_treeview = commonlib.gettable("Map3DSystem.mcml_controls.pe_treeview");

-- this control will fill entire client area, such returned top is height. 
-- if child node is not pe:treenode, it is always rendered inside an anonymous treenode using the default height
-- all child nodes are created only when viewable.
function pe_treeview.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:treeview"], style) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		width = left + css.width + margin_left + margin_right
	end
	if(css.height) then
		height = top + css.height + margin_top + margin_bottom
	end
	
	parentLayout:AddObject(width-left, height-top);
	parentLayout:NewLine();
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	-- Extract from datasource if it is already provided in the input. 
	local ds = mcmlNode:GetAttributeWithCode("DataSourceID");
	if(ds) then
		pe_treeview.SetDataSource(mcmlNode, rootName, ds)
	else
		local ds = mcmlNode:GetAttributeWithCode("DataSource",nil,true);
		if(ds) then
			pe_treeview.SetDataSource(mcmlNode, rootName, ds)
		end
	end
	if(mcmlNode.datasource) then
		-- instantiate child nodes from data source 
		pe_treeview.DataBind(mcmlNode, rootName, false);
	end

	-- tree view
	NPL.load("(gl)script/ide/TreeView.lua");
	local instName = mcmlNode:GetInstanceName(rootName);
	local InitialClientY = nil;

	local RememberScrollPos = mcmlNode:GetBool("RememberScrollPos") or (css.RememberScrollPos and css.RememberScrollPos~="false");
	
	if(RememberScrollPos) then
		local ctl = mcmlNode.control or CommonCtrl.GetControl(instName)
		if(ctl) then
			InitialClientY = ctl.ClientY
		end	
	end
	local ctl = CommonCtrl.TreeView:new{
		name = instName,
		alignment = "_lt",
		left = left,
		top = top,
		width = width - left,
		height = height - top,
		parent = _parent,
		DrawNodeHandler = pe_treeview.DrawNodeHandler,
		-- attr from mcmlNode
		container_bg = css.background or mcmlNode:GetString("background"), -- change to css background first
		DefaultNodeHeight = mcmlNode:GetNumber("DefaultNodeHeight") or css.DefaultNodeHeight,
		DefaultIconSize = mcmlNode:GetNumber("DefaultIconSize") or css.DefaultIconSize,
		ShowIcon = mcmlNode:GetBool("ShowIcon"),
		ItemOpenBG = mcmlNode:GetString("ItemOpenBG") or css.ItemOpenBG, 
		ItemCloseBG = mcmlNode:GetString("ItemCloseBG") or css.ItemCloseBG, 
		ItemToggleSize = mcmlNode:GetNumber("ItemToggleSize") or css.ItemToggleSize, 
		ItemToggleRightSpacing = mcmlNode:GetNumber("ItemToggleRightSpacing") or css.ItemToggleRightSpacing, 
		DefaultIndentation = mcmlNode:GetNumber("DefaultIndentation") or css.DefaultIndentation,
		VerticalScrollBarOffsetX = mcmlNode:GetNumber("VerticalScrollBarOffsetX") or css.VerticalScrollBarOffsetX,
		VerticalScrollBarStep = mcmlNode:GetNumber("VerticalScrollBarStep") or css.VerticalScrollBarStep,
		VerticalScrollBarPageSize = mcmlNode:GetNumber("VerticalScrollBarPageSize") or css.VerticalScrollBarPageSize,
		MouseOverBG = mcmlNode:GetString("MouseOverBG") or css.MouseOverBG,
		ClickThrough = mcmlNode:GetBool("ClickThrough"),
		onclick = mcmlNode:GetAttributeWithCode("OnClick"),
		-- keep a reference to instance data
		rootName = rootName,
		bindingContext = bindingContext,
		-- init client position
		InitialClientY = InitialClientY,
		VerticalScrollBarWidth = mcmlNode:GetNumber("VerticalScrollBarWidth") or css.VerticalScrollBarWidth or CommonCtrl.TreeView.VerticalScrollBarWidth,
		ScrollBarTrackWidth = mcmlNode:GetNumber("ScrollBarTrackWidth") or css.ScrollBarTrackWidth or CommonCtrl.TreeView.ScrollBarTrackWidth,
	};
	mcmlNode.control = ctl;

	if(type(ctl.onclick) == "string") then
		local pageScope = mcmlNode:GetPageCtrl():GetPageScope();
		if(pageScope) then
			ctl.onclick = commonlib.getfield(ctl.onclick, pageScope);
		end
	end

	-- add all child nodes, but does not render them. 
	pe_treeview.Refresh(mcmlNode,rootName, nil, ctl);
	ctl:Show(true);
end

-- Public method: for pe:pager
-- @param bRefreshUI: if true it will refresh treeview UI. Otherwise it will just rebuilt the child nodes
-- @param ctl: the tree view control. If nil, it will grab it from mcmlNode. However, by explicitly specify it,we can update child nodes of a different root.
-- @param scrollToEnd:if true treeview will scroll to end and show last element
-- @param showNode: scroll this to node
function pe_treeview.Refresh(mcmlNode, pageInstName, bRefreshUI, ctl, scrollToEnd, showNode)
	ctl = ctl or mcmlNode:GetControl(pageInstName);
	if(type(ctl) == "table" and ctl.RootNode) then
		local node = ctl.RootNode;
		-- clear all and rebuild
		node:ClearAllChildren();
		local childnode;
		for childnode in mcmlNode:next() do
			pe_treeview.createTreeNode(node, childnode);
		end
		if(bRefreshUI) then
			ctl:Update(scrollToEnd, showNode);
		end
	else
		log("warning: unable to find control for pe_treeview\n")
	end
end

-- public method: redraw the treeview in place. Call this function when only attributes of on the datasource node is changed. 
-- this is minimum cost, otherwise use Refresh method. 
function pe_treeview.Update(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(type(ctl) == "table" and ctl.RootNode) then
		ctl:Update();
	end
end

-- scroll to the given node. 
function pe_treeview.ScrollToRow(mcmlNode, pageInstName, nRowIndex)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(type(ctl) == "table" and ctl.RootNode) then
		if(nRowIndex) then
			local showNode = ctl.RootNode:GetChild(nRowIndex);
			if(showNode) then
				ctl:Update(nil, showNode);
			end
		end
	end
end

-- we shall skip these nodes during rendering. 
local skip_treenode_names = {
	["NodeTemplates"] = true,
	["EmptyDataTemplate"] = true,
	["FetchingDataTemplate"] = true,
}
-- append a child tree Node mcml node
function pe_treeview.createTreeNode(parentNode, mcmlNode, bindingContext)
	local bAddChild;
	local node = {mcmlNode = mcmlNode};
	local attrBind;
	if(type(mcmlNode) == "table") then
		if(mcmlNode.name == "pe:treenode") then
			mcmlNode:ApplyPreValues();
			local css = mcmlNode:GetStyle(mcmlNode.name, style) or {};

			node.alignFormat = 0;
			if(css["text-align"]) then
				if(css["text-align"] == "right") then
					node.alignFormat = 2;
				elseif(css["text-align"] == "center") then
					node.alignFormat = 1;
				end
			end

			node.Name = mcmlNode:GetAttributeWithCode("name");
			node.Text = mcmlNode:GetAttributeWithCode("text");
			node.tooltip = mcmlNode:GetAttributeWithCode("tooltip");
			node.TextColor = css["color"];
			node.font_weight = css["font-weight"];
			node.font_size = css["font-size"];
			node.Icon = mcmlNode:GetAttributeWithCode("icon");
			node.NodeHeight = tonumber(mcmlNode:GetAttributeWithCode("height")) or css["height"];
			node.indent = tonumber(mcmlNode:GetAttributeWithCode("indent"));
			local expanded = mcmlNode:GetAttributeWithCode("expanded",nil,true);
			expanded = tostring(expanded);
			node.Expanded = (expanded == "true");

			local selected = mcmlNode:GetAttributeWithCode("selected",nil,true);
			selected = tostring(selected);
			node.Selected = (selected == "true");

			node.invisible = mcmlNode:GetAttributeWithCode("invisible") == "true";
			node.MouseOverBG = mcmlNode:GetAttributeWithCode("MouseOverBG");
			node.NormalBG = mcmlNode:GetAttributeWithCode("NormalBG");
			node.onclick = mcmlNode:GetAttributeWithCode("OnClick");
			node.ItemToggleSize = mcmlNode:GetNumber("ItemToggleSize");
			if(type(node.onclick) == "string") then
				local pageScope = mcmlNode:GetPageCtrl():GetPageScope();
				if(pageScope) then
					node.onclick = commonlib.getfield(node.onclick, pageScope);
				end
			end
			bAddChild = true;
			attrBind = mcmlNode:GetAttributeWithCode("AttributeBind");
			-- search for render template, this is only set for static nodes. for databinded nodes, it is set during data binding. 
			if(not mcmlNode.render_template_node) then
				local RenderTemplate = mcmlNode:GetString("RenderTemplate");
				if(RenderTemplate) then
					local tmpNode = mcmlNode:GetParent("pe:treeview");
					if(tmpNode) then
						local tmpNode = tmpNode:GetChild("NodeTemplates");
						if(tmpNode) then
							local tmpNode = tmpNode:GetChildWithAttribute("DataType", RenderTemplate);
							if(tmpNode) then
								mcmlNode.render_template_node = tmpNode;
							else
								LOG.std("", "error", "pe:treeview", "unable to find data type %s", RenderTemplate)
							end
						end
					end
				end
			end
		elseif(mcmlNode.name == "DataNodePlaceholder") then
			-- for auto generated nodes from data source and templates
			local childnode;
			for childnode in mcmlNode:next() do
				pe_treeview.createTreeNode(parentNode, childnode, bindingContext);
			end
			return
		elseif(skip_treenode_names[mcmlNode.name]) then
			return;
		else
			--if(mcmlNode:GetAttribute("expanded")~=nil) then
				--mcmlNode:ApplyPreValues();
				--local expanded = mcmlNode:GetAttributeWithCode("expanded",nil,true);	
				--node.Expanded = (tostring(expanded) == "true");
				--if(node.Expanded) then
					--bAddChild = true;
				--end
			--end
		end
		node.type = mcmlNode.name;
	else
		node.type = "<text>";
	end
	node = parentNode:AddChild(CommonCtrl.TreeNode:new(node));
	if(attrBind) then
		bAddChild = false;
		node.DrawNodeHandler = CommonCtrl.TreeView.DrawPropertyNodeHandler;
		node:BindParaAttributeObject(attrBind.bindingContext, attrBind.att, attrBind.bReadOnly, attrBind.fieldNames, attrBind.fieldTextReplaceables)
	end
	
	-- append child treenodes if any. 
	if(bAddChild) then
		for childnode in mcmlNode:next() do
			pe_treeview.createTreeNode(node, childnode, bindingContext);
		end
	end	
end

-- draw tree node handler.
-- return nil or the new height if current node height is not suitable, it will cause the node to be redrawn.
function pe_treeview.DrawNodeHandler(_parent,treeNode)
	if(_parent == nil or treeNode == nil) then
		return
	end
	local _this;
	local left = treeNode.indent or 0; -- indentation of this node. 
	local top = 0;
	local height = treeNode:GetHeight();
	local width = treeNode.TreeView.ClientWidth;
	
	-- NOTE: show the icon only when the treenode has child
	--if(treeNode.TreeView.ShowIcon) then
	if(treeNode.TreeView.ShowIcon and treeNode:GetChildCount() == 0) then
		local IconSize = treeNode.TreeView.DefaultIconSize;
		if(treeNode.Icon~=nil and IconSize>0) then
			_this=ParaUI.CreateUIObject("button","b","_lt", left, (height-IconSize)/2 , IconSize, IconSize);
			_this.background = treeNode.Icon;
			_guihelper.SetUIColor(_this, "255 255 255");
			_parent:AddChild(_this);
		end	
		left = left + IconSize;
	end	
	
	if(treeNode.TreeView.RootNode:GetHeight() > 0) then
		left = left + treeNode.TreeView.DefaultIndentation*treeNode.Level;
	else
		left = left + treeNode.TreeView.DefaultIndentation*(treeNode.Level-1);
	end
	
	if(treeNode.type=="pe:treenode") then
		left = left + 4;
		local new_used_height;
		local mouse_over_bg = treeNode.MouseOverBG or treeNode.TreeView.MouseOverBG or "Texture/alphadot.png"
		local normal_bg = treeNode.NormalBG;

		if(treeNode:GetChildCount() > 0) then
			-- node that contains children. We shall display some
			local item_size = treeNode.ItemToggleSize or treeNode.TreeView.ItemToggleSize or 10;
			if(item_size > 0) then
				local spacing = math.floor((height - item_size)/2);
				local spacing_right = treeNode.TreeView.ItemToggleRightSpacing or 6;
				-- _this=ParaUI.CreateUIObject("button","b","_lt", left, top+6, 10, 10);
				_this=ParaUI.CreateUIObject("button","b","_lt", left, top+spacing, item_size, item_size);
				if(treeNode.mcmlNode:GetBool("can_select")) then
					_this.onclick = string.format(";CommonCtrl.TreeView.OnToggleNode(%q, %q, true)", treeNode.TreeView.name, treeNode:GetNodePath());
				else
					_this.onclick = string.format(";CommonCtrl.TreeView.OnToggleNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
				end
			
				_parent:AddChild(_this);
				if(treeNode.Expanded) then
					_this.background = treeNode.TreeView.ItemOpenBG or "Texture/3DMapSystem/common/itemopen.png";
				else
					_this.background = treeNode.TreeView.ItemCloseBG or "Texture/3DMapSystem/common/itemclosed.png";
				end

				_guihelper.SetUIColor(_this, "255 255 255");
				left = left + item_size + spacing_right;
			end
			
			if(treeNode.mcmlNode.render_template_node) then
				treeNode.mcmlNode:SetPreValue("treenode", treeNode);
				treeNode.mcmlNode:ApplyPreValues();
				local myLayout = Map3DSystem.mcml_controls.layout:new();
				myLayout:reset(left, top, width, height);
				Map3DSystem.mcml_controls.create(treeNode.TreeView.rootName, treeNode.mcmlNode.render_template_node, treeNode.TreeView.bindingContext, _parent, left, top, width, height, nil, myLayout);
				local usedW, usedH = myLayout:GetUsedSize()
				if(usedH>height) then
					new_used_height = usedH;
					height = new_used_height;
				end	
			end

			_this=ParaUI.CreateUIObject("button","b","_lt", left, top , width - left-2, height - 1);
			_parent:AddChild(_this);
			
			if(treeNode.Selected) then
				_this.background = mouse_over_bg;				
			else				
				if (normal_bg) then
					_this.background = normal_bg;
				else
					_this.background = "";
				end
				_guihelper.SetVistaStyleButton(_this, nil, mouse_over_bg);
			end
			if(treeNode.tooltip) then
				_this.tooltip = treeNode.tooltip
			end
			
			_guihelper.SetUIFontFormat(_this, 36 + treeNode.alignFormat); -- single line and vertical align
			if(treeNode.mcmlNode:GetBool("can_select")) then
				_this.onclick = string.format(";CommonCtrl.TreeView.OnToggleNode(%q, %q, true)", treeNode.TreeView.name, treeNode:GetNodePath());
			else
				_this.onclick = string.format(";CommonCtrl.TreeView.OnToggleNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
			end
			if(treeNode.Text) then
				_this.text = treeNode.Text;
			end
			if(treeNode.font_weight or treeNode.font_size) then
				_this.font = string.format("%s;%d;%s", "System", treeNode.font_size or 12, treeNode.font_weight or "norm");
			end
			if(treeNode.TextColor) then
				_guihelper.SetFontColor(_this, treeNode.TextColor);
			end
		else
			-- leaf tree node. We shall display text
			if(treeNode.mcmlNode.render_template_node) then
				treeNode.mcmlNode:SetPreValue("treenode", treeNode);
				treeNode.mcmlNode:ApplyPreValues();
				local myLayout = Map3DSystem.mcml_controls.layout:new();
				myLayout:reset(left, top, width, height);
				Map3DSystem.mcml_controls.create(treeNode.TreeView.rootName, treeNode.mcmlNode.render_template_node, treeNode.TreeView.bindingContext, _parent, left, top, width, height, treeNode.style, myLayout);
				local usedW, usedH = myLayout:GetUsedSize()
				if(usedH>height) then
					new_used_height = usedH;
					height = new_used_height;
				end	
			end

			_this=ParaUI.CreateUIObject("button","b","_lt", left, 0 , width - left-2, height - 1);
			_parent:AddChild(_this);

			if(treeNode.Selected) then
				_this.background = mouse_over_bg;
			else
				if (normal_bg) then
					_this.background = normal_bg;
				else
					_this.background = "";
				end				
				_guihelper.SetVistaStyleButton(_this, nil, mouse_over_bg);
			end
			_guihelper.SetUIFontFormat(_this, 36); -- single line and vertical align
			if(treeNode.mcmlNode:GetBool("can_select")) then
				_this.onclick = string.format(";CommonCtrl.TreeView.OnSelectNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
			else
				_this.onclick = string.format(";CommonCtrl.TreeView.OnClickNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
			end
			if(treeNode.Text) then
				_this.text = treeNode.Text;
			end
			if(treeNode.tooltip) then
				_this.tooltip = treeNode.tooltip
			end
			if(treeNode.font_weight or treeNode.font_size) then
				_this.font = string.format("%s;%d;%s", "System", treeNode.font_size or 12, treeNode.font_weight or "norm");
			end
			if(treeNode.TextColor) then
				_guihelper.SetFontColor(_this, treeNode.TextColor);
			end
		end
		if(new_used_height) then
			--treeNode.NodeHeight = new_used_height;
			return new_used_height;
		end
	else
		local myLayout = Map3DSystem.mcml_controls.layout:new();
		myLayout:reset(left, top, width, height);
	--	Map3DSystem.mcml_controls.create(treeNode.TreeView.rootName, treeNode.mcmlNode, treeNode.TreeView.bindingContext, _parent, left, top, width, height, nil, myLayout);
		Map3DSystem.mcml_controls.create(treeNode.TreeView.rootName, treeNode.mcmlNode, treeNode.TreeView.bindingContext, _parent, left, top, width, height, treeNode.style, myLayout);
		local usedW, usedH = myLayout:GetUsedSize()
		if(usedH>height) then
			--treeNode.NodeHeight = usedH;
			return usedH;
		end	
	end	
end


-- Public method: set the new data source
-- @param dataSource: if string, it is the DataSourceID. if table it is the data table itself 
function pe_treeview.SetDataSource(mcmlNode, pageInstName, dataSource)
	local pageCtrl = mcmlNode:GetPageCtrl();
	if(not pageCtrl) then return end
	if(type(dataSource) == "string") then
		-- this is data source ID, we will convert it to a function that dynamically retrieve item from the data source control. 
		mcmlNode.datasource = pageCtrl:GetNode(dataSource);
	else
		mcmlNode.datasource = dataSource;
	end
end

-----------------------------------
-- pe:bindingblock control: 
-- a single repeatable block in a pe:gridview or other iterator controls. 
-----------------------------------
local pe_bindingblock = commonlib.gettable("Map3DSystem.mcml_controls.pe_bindingblock");

-- Public method: rebind (refresh) the data.
-- each bind data row node contains page variable "index" and any other data column values for that row. 
-- the template node can then evaluate for the values of the node to dynamic generate content specific to that row. 
-- such as <%=Eval("xpath")%> will return the xpath of the node
-- @param bRefreshUI: true to refresh UI. otherwise node is updated but UI is not. 
function pe_treeview.DataBind(mcmlNode, pageInstName, bRefreshUI)
	local templates_node = mcmlNode:GetChild("NodeTemplates");
	if(not templates_node or type(mcmlNode.datasource)~="table") then
		return 
	end
	-- build a fast map for look up. 
	local template_map = mcmlNode.template_map;
	if(not template_map) then
		template_map = {};
		mcmlNode.template_map = template_map;
		local childnode;
		for childnode in templates_node:next("NodeTemplate") do
			if(childnode.attr and childnode.attr.DataType) then
				template_map[childnode.attr.DataType] = childnode;
			end
		end
	end
	-- now prepare an empty node to which all generated treenode will be added. 
	
	local output = mcmlNode:GetAllChildWithName("DataNodePlaceholder");
	if(not output) then
		local generated_node = Map3DSystem.mcml.new(nil,{name="DataNodePlaceholder"});
		mcmlNode:AddChild(generated_node);
		output = {generated_node};
	end
	local _, generated_node
	for _, generated_node in ipairs(output) do
		generated_node:ClearAllChildren();
	
		-- now tranverse the datasource to create all tree nodes. 
		-- Note: right now databinding is not suitable for extreamly large data source like tens of thousands of nodes
		-- since we will need to create them all during data binding.  
		local indent = 0;
		local function CreateTreeNode(inTable, parentNode)
			if(not inTable) then return end
			if(type(inTable) == "table") then 	
				local template_node = template_map[inTable.name]
				local thisNode;
				if(template_node) then
					-- create a child using the template. 
					local tree_node;
					if(template_node:GetChildCount() == 1) then
						local source_node = template_node[1];
						if(type(source_node) == "table") then
							if(source_node.name == "pe:treenode") then
								tree_node = source_node:clone();

								local render_template = tree_node:GetAttribute("RenderTemplate");
								if(render_template) then
									tree_node.render_template_node = template_map[render_template];
								end
							else
								tree_node = source_node:clone();
								tree_node.name = "pe:bindingblock";
							end
						elseif(type(source_node) == "string") then
							tree_node = Map3DSystem.mcml.new(nil,{name="div", source_node, n=1});
						end
					else
						tree_node = template_node:clone();
						tree_node.name = "pe:bindingblock";
					end
					if(tree_node) then
						tree_node:SetPreValue("this", inTable.attr);
						parentNode:AddChild(tree_node)
						thisNode = tree_node;
					end
				end	
				local nChildSize = table.getn(inTable);
				if(nChildSize>0) then
					indent = indent+1;
					local i, childNode
					for i, childNode in ipairs(inTable) do
						CreateTreeNode(childNode, thisNode or parentNode);
					end
					indent = indent-1;
				end
			end
		end
		-- check for xpath
		local xpath = generated_node:GetString("xpath");
		if(not xpath or xpath == "*" or xpath=="") then
			CreateTreeNode(mcmlNode.datasource, generated_node)
		else
			local node; 
			for node in commonlib.XPath.eachNode(mcmlNode.datasource, xpath) do
				CreateTreeNode(node, generated_node)
			end
		end
	end
	if(bRefreshUI) then
		local instName = mcmlNode:GetInstanceName(pageInstName);
		local ctl = CommonCtrl.GetControl(instName)
		if(ctl) then
			-- refresh the treeview control. 
			pe_treeview.Refresh(mcmlNode,pageInstName, true, ctl);
		end
	end
end