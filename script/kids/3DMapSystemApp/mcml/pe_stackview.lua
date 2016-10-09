--[[
Title: databinding stack view
Author(s): LiXizhi
Date: 2010/9/16
Desc: pe:stackview behaves just like a div, however its child content can be from a databinding source

---++ pe:stackview
This control will fill entire client area, such returned top is height. 
Child node can be pe:stacknode which support auto size and behaves like a div with css style "float:left".
Databinding is more like pe_stackview tag. 

*properties*: 
| *property* | *description* |
| background |  |
| DefaultItemHeight |  |
| DefaultItemWidth |  |
| CellSpacing |  |
| DataSource | it should be a xml table to bind to  |
| DataSourceID | it should be an node id (name attribute) in the page to be used as the xml input |

Node Method:
| DataBind(bRefreshUI) | call this function or fresh the page whenever datasource is changed. |

---+++ databinding with stackview
right now databinding is not suitable for extremely large data source like hundreds of nodes
since we will need to create them all during data binding.  

One can provide any number of NodeTemplate inside NodeTemplates, where DataType must be the same as the xml node name in data source. 

Another cool feature is that one can control where the databinded stacknodes to appear in the stackview. 
This is done by placing a <DataNodePlaceholder /> anywhere inside pe:stackview. If it is not provided, 
it will be created automatically as the last child of pe:stackview. One can optionally specify an xpath on its 
attribute to specify which portion of the data source to bind to. There can be multiple <DataNodePlaceholder /> with different xpath. 

tree view sample code: 
<verbatim> 

<pe:stackview name="tvwXMLTest" DataSource='<%={ {name="folder", attr={text="parent_folder", is_expanded=true}, {name="file", attr={text="filename"}}, }%>' >
	<NodeTemplates>
		<NodeTemplate DataType="folder">
            <div>'<%=Eval("this|text")%>'</div>
        </NodeTemplate>
        <NodeTemplate DataType="file">
            <div style="height:20px;">
                <%=Eval("this|text")%>
				<span color="#008000">(ÒÑÍê³É)</span>
            </div>
        </NodeTemplate>
	</NodeTemplates>
	<DataNodePlaceholder xpath="*"/>
</pe:stackview>

</verbatim>

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_stackview.lua");
-------------------------------------------------------
]]
local type = type;
-----------------------------------
-- pe:stackview control: 
-----------------------------------
local pe_stackview = commonlib.gettable("Map3DSystem.mcml_controls.pe_stackview");

-- this control will fill entire client area, such returned top is height. 
-- if child node is not pe:stacknode, it is always rendered inside an anonymous stacknode using the default height
-- all child nodes are created only when viewable.
function pe_stackview.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:stackview"], style) or {};
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
	local ds = mcmlNode:GetAttribute("DataSourceID");
	if(ds) then
		pe_stackview.SetDataSource(mcmlNode, rootName, ds)
	else
		local ds = mcmlNode:GetAttributeWithCode("DataSource",nil,true);
		if(ds) then
			pe_stackview.SetDataSource(mcmlNode, rootName, ds)
		end
	end
	if(mcmlNode.datasource) then
		-- instantiate child nodes from data source 
		pe_stackview.DataBind(mcmlNode, rootName, false);
	end
	
	-- now create the container
	local instName = mcmlNode:GetInstanceName(rootName);
	local _this=ParaUI.CreateUIObject("container",instName or "c","_lt", left+margin_left, top+margin_top, width-left-margin_left-margin_right, height-top-margin_top-margin_bottom);
	if(css.background) then
		_this.background = css.background;
	end
	if(css["background-color"]) then
		_guihelper.SetUIColor(_this, css["background-color"]);
	else
		_guihelper.SetUIColor(_this, "255 255 255 255");
	end	
	if(css["background-rotation"]) then
		_this.rotation = tonumber(css["background-rotation"])
	end
	_parent:AddChild(_this);

	-- add all child nodes, but does not render them. 
	pe_stackview.Refresh(mcmlNode,rootName);
end

-- we shall skip these nodes during rendering. 
local skip_stacknode_names = {
	["NodeTemplates"] = true,
	["EmptyDataTemplate"] = true,
	["FetchingDataTemplate"] = true,
}

-- Public method: 
function pe_stackview.Refresh(mcmlNode, pageInstName)
	local instName = mcmlNode:GetInstanceName(pageInstName);
	local _parent = ParaUI.GetUIObject(instName);
	if(_parent:IsValid()) then
		_parent:RemoveAll();
		local parentLayout = Map3DSystem.mcml_controls.layout:new();
		local width, height = _parent.width, _parent.height;
		parentLayout:reset(0, 0, width, height);
		local childnode;
		for childnode in mcmlNode:next() do
			if(type(childnode) == "table") then
				if(not skip_stacknode_names[childnode.name]) then
					Map3DSystem.mcml_controls.create(pageInstName, childnode, nil, _parent, 0, 0, width, height, nil, parentLayout)
				end
			end
		end
	end
end


-- Public method: set the new data source
-- @param dataSource: if string, it is the DataSourceID. if table it is the data table itself 
function pe_stackview.SetDataSource(mcmlNode, pageInstName, dataSource)
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
function pe_stackview.DataBind(mcmlNode, pageInstName, bRefreshUI)
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
	-- now prepare an empty node to which all generated stacknode will be added. 
	
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
		local function Createstacknode(inTable, parentNode)
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
							tree_node = template_node[1]:clone();
							tree_node.name = "pe:bindingblock";
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
						Createstacknode(childNode, thisNode or parentNode);
					end
					indent = indent-1;
				end
			end
		end
		-- check for xpath
		local xpath = generated_node:GetString("xpath");
		if(not xpath or xpath == "*" or xpath=="") then
			Createstacknode(mcmlNode.datasource, generated_node)
		else
			local node; 
			for node in commonlib.XPath.eachNode(mcmlNode.datasource, xpath) do
				Createstacknode(node, generated_node)
			end
		end
	end
	if(bRefreshUI) then
		pe_stackview.Refresh(mcmlNode,pageInstName);
	end
end