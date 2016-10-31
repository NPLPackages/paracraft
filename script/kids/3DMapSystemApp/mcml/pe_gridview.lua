--[[
Title: Grid view in MCML
Author(s): LiXizhi
Date: 2008/5/15
Desc: 
pe:gridview and related tags(pe:pager, pe:bindingblock) are used for displaying a long list of templated data with paging. Such as friends list, application list, etc. 
A recurring task in software development is to display tabular data. With the GridView control, you can display, edit, and delete data 
from many different kinds of data sources, including databases, XML files, NPL tables and business objects that expose data.

Using the GridView you can:
   * Automatically bind to and display data from a data source control.
   * Select, sort, page through, edit, and delete data from a data source control.
Additionally, you can customize the appearance and behavior of the GridView control by:
   * Specifying custom columns and styles.
   * Utilizing templates to create custom user interface (UI) elements.

Grid view sample code: 

```xml
<pe:gridview style="margin:10px" name="gvwTableTest" CellPadding="5"  AllowPaging="True" DefaultNodeHeight = "20" pagesize="10"
        DataSource='<%={{username="LiXizhi", Company="ParaEngine"}, {username="Andy", Company="ParaEngine"}, {username="Gandhi", Company="PE"}}%>'
        DataBound = "gvwTableTest_DataBound()" OnPageIndexChanging="gvwTableTest_PageIndexChanging()" OnPageIndexChanged="gvwTableTest_PageIndexChanged()">
	<Columns>
		Row index is <%=Eval("index")%><a href='<%="profile?name="..Eval("username")%>'>User Name is <%=Eval("username")%></a>Company: <%=Eval("Company")%>
	</Columns>
	<EmptyDataTemplate>
		<b>NO MATCHING USER IS FOUND 没有找到符合要求的用户</b>
	</EmptyDataTemplate>
	<FetchingDataTemplate>
		<b>Please wait while fetching data</b>
	</FetchingDataTemplate>
	<PagerSettings Position="TopAndBottom" height="26" PreviousPageText="" NextPageText=""/>
	<!--<PagerTemplate><form><input type="button" name="pre" value="previous page"/><input type="button" name="next" value="next page"/><label name="page" style="height:18px;margin:4px"/></form></PagerTemplate>-->
</pe:gridview>
```

### Data Binding with the GridView Control
The GridView control provides you with two choices for binding to data:
   * Data binding using the DataSourceID property, which allows you to bind the GridView control to a data source control. 
This is a simple approach because it allows the GridView control to take advantage of the capabilities of the data 
source control and provide built-in functionality for sorting, paging, and updating. 
   * Data binding using the DataSource property, which allows you to bind to various objects, including NPL array table, NPL function(nRowIndex) (see below). 
This approach requires you to write code for any additional functionality such as paging, and updating. 
However, using NPL function is the recommended way if your data is dynamically and asynchronously loaded such as from a web server. 

If you bind to an data source `function(nRowIndex) end`, the function must return value with following rules: 
   * if nRowIndex is number, it returns the fields in a table of the given row index. 
   * if nRowIndex is nil, it returns totalItems. One can return nil as totalItems, which tells that control that data is not available, possibly still fetching from web services.

The following is pseudo code of your datasource function. 
```lua
MyPage.ds = nil;
function MyPage.DS_Func_MyRemoteData(index) 
	if(MyPage.ds) then
		-- if we already have local data, provide it
		if(not index) then
			-- return the number of items
			return #(MyPage.ds); 
		else
			return MyPage.ds[index];
		end
	else
		-- data is not available, we will return nil and fetch the data. This will only be called once.
		-- we will use a timer to simulate remote call. 
		commonlib.TimerManager.SetTimeout(
			function()  
				MyPage.ds = { {data=1} , {data=2} };
				-- when data is available refresh the page again or just call DataBind method of the control.
				MyPage:RefreshPage();
			end, 1000); 
	end
end
```

### Formatting Data Display in the GridView Control
You can specify the layout of the GridView control's rows by using any other MCML tags inside the Columns node as shown in the grid view example above. 
Inside Columns node, use embedded script block with Eval() or XPath() method to extract data from columns of the current row. 

| ---- | --- |
| ItemsPerLine | it is a pe:gridview property which controls how many items to show on one line. Default value is 1. One can set it to a bigger value to show 
| LineWidth | width of a line in pixel. it is usually same as the grid view width. |
| LineAlign | it can only be "center". if it is "center" and ItemsPerLine is lager than 1, the columns will be centered, especially for the last row. LineWidth must also be specified.  |
| ClickThrough | wheather mouse event will leak to 3d scene. default to false  |
| | a grid of databind items, where each items is customizable via the columns property. |
| RememberScrollPos | true to remember scroll position within current page. |
| ScrollBarTrackWidth | |
| VerticalScrollBarWidth | |
| RememberLastPage | true to remember last opened page during page refresh |
| AllowPaging | true to allow paging |
| ClickThrough | whether mouse event will leak to 3d scene. default to false  |
| PagerTemplate.AutoHidePager | boolean. |
| FitHeight | if true, the height of the control will best contain the data nodes. css.min-height can also be specified. |

### GridView Paging Functionality
A pager row is displayed in a GridView control when the paging feature is enabled (when the AllowPaging property is set to true). 
The pager row contains the controls that allow the user to navigate to the different pages in the control. 
Instead of using the built-in pager row user interface (UI), you can define your own UI by using the PagerTemplate property.

To specify a custom template for the pager row, first place PagerTemplate followed by a form tags between the opening and closing tags of the GridView control. 
You can then list the contents of the template between the opening and closing PagerTemplate tags. If any buttons are named "pre" and "next" in the content, they are automatically
bounded to command action previous page and next page. If any text or label are named "page", it will be used to display current page number/page count. Here is an example
```
	<PagerTemplate><form><input type="button" name="pre" value="previous page"/><input type="button" name="next" value="next page"/><label name="page" style="height:18px;margin:4px"/></form></PagerTemplate>
```

one can also apply css style to PageSettings, like below.
```
	<PagerSettings style="margin-left:300px" Position="Bottom"/>
```

### GridView Events
You can customize the functionality of the GridView control by handling events. The GridView control provides events that occur both before and after a navigation. 
   * PageIndexChanging(gridviewName, pageindex): Occurs when a pager button is clicked, but before the GridView control performs the paging operation. This event is often handled to cancel the paging operation. 
   * PageIndexChanged(gridviewName, pageindex): Occurs when a pager button is clicked, but after the GridView control performs the paging operation. This event is commonly handled when you need to perform a task after the user navigates to a different page in the control. 
   * DataBound(gridviewName, datasource): Occurs after the GridView control has finished binding to the data source. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_gridview.lua");
-------------------------------------------------------
]]

local L = CommonCtrl.Locale("IDE");

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

local string_format = string.format;
local format = format;
-----------------------------------
-- pe:GridView control: supported attribute DefaultNodeHeight, background
-- setting DefaultNodeHeight to a proper value will increase performance.
-- Pubilc method: SetDataSource(tableOrFunc), DataBind(),
-----------------------------------
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");

-- it is a combo of pe:pager and pe:treeview controls, it just take up all spaces left
-- it will not show up if datasource is empty, even if the size is specified. 
function pe_gridview.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(not mcmlNode:GetAttributeWithCode("DataSourceID") and not mcmlNode:GetAttributeWithCode("DataSource")) then return end
		
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:GridView"]) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			width = left + css.width + margin_left + margin_right
		end
	end
	if(css.height) then
		if((top + css.height)<height) then
			height = top + css.height + margin_top + margin_bottom
		end
	end
	local parent_width, parent_height = width-left, height-top;
	
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	local name = mcmlNode:GetString("name") or "";
	
	local AllowPaging = mcmlNode:GetAttributeWithCode("AllowPaging");
	if(type(AllowPaging) == "string") then
		AllowPaging = string.lower(AllowPaging);
	end
	if(AllowPaging == "true") then
		AllowPaging = true;
	elseif(AllowPaging == "false") then
		AllowPaging = false;
	end
	--local AllowPaging = mcmlNode:GetBool("AllowPaging");
	if(AllowPaging) then
		if(not mcmlNode:GetChild("pe:pager")) then
			-- create the top and/or bottom pager panel for page navigation. 
			-- Usually a pager contains current page index, total items, next and prev page button. 
			local PagerSettings = {
				height = 26,
				-- can be either "Top", "Bottom", or "TopAndBottom"
				Position = "TopAndBottom",
			};
			local node = mcmlNode:GetChild("PagerSettings");
			if(node) then
				PagerSettings.Position = node:GetAttribute("Position") or PagerSettings.Position;
				PagerSettings.height = node:GetAttribute("height") or PagerSettings.height;
				PagerSettings.NextPageText = node:GetAttribute("NextPageText");
				PagerSettings.PreviousPageText = node:GetAttribute("PreviousPageText")
				PagerSettings.style = node:GetAttribute("style")
			end
			
			-- create at top and/or bottom
			local i
			for i=1, 2 do 
				local pagerTop;
				if( i == 1) then
					if(string.find(PagerSettings.Position, "Top")) then
						pagerTop = top
						top = top + PagerSettings.height
					end
				else	
					if(string.find(PagerSettings.Position, "Bottom")) then
						height = height - PagerSettings.height
						pagerTop = height
					end
				end
				if(pagerTop) then
					local pagerTempate = mcmlNode:GetChild("PagerTemplate")
					local node;
					if(pagerTempate) then
						node = Map3DSystem.mcml.new(nil, pagerTempate:clone());
						node.name = "pe:pager"
					else
						node = Map3DSystem.mcml.new(nil, {name="pe:pager"});
					
						if(PagerSettings.PreviousPageText or PagerSettings.NextPageText) then
							node:SetAttribute("PreviousPageText", PagerSettings.PreviousPageText);	
							node:SetAttribute("NextPageText", PagerSettings.NextPageText);	
						end	
					end	
					node:SetAttribute("height", PagerSettings.height);
					node:SetAttribute("target", name);
					if(i==1) then
						node:SetAttribute("position", "Top");
					else
						node:SetAttribute("position", "Bottom");
					end	
					if(PagerSettings.style) then
						node:SetAttribute("style", PagerSettings.style);
					end
					
					mcmlNode:AddChild(node, nil);
					
					local myLayout = Map3DSystem.mcml_controls.layout:new();
					myLayout:reset(left, pagerTop, width, pagerTop + PagerSettings.height);
					Map3DSystem.mcml_controls.create(rootName, node, bindingContext, _parent, left, pagerTop, width, height, nil, myLayout);
				end
			end	
		else
			-- if already created or specified, just use it to create. The position attribute of pe:pager defines where the pager will be located. 
			local pager;
			for pager in mcmlNode:next("pe:pager") do
				local pagerTop;
				local pagerHeight = pager:GetNumber("height") or 26;
				if( pager:GetAttribute("position") == "Top") then
					pagerTop = top
					top = top + pagerHeight
				elseif( pager:GetAttribute("position") == "Bottom") then
					height = height - pagerHeight
					pagerTop = height
				end
				if(pagerTop) then
					local myLayout = Map3DSystem.mcml_controls.layout:new();
					myLayout:reset(left, pagerTop, width, pagerTop + pagerHeight);
					Map3DSystem.mcml_controls.create(rootName, pager, bindingContext, _parent, left, pagerTop, width, height, nil, myLayout);
				end
			end
		end	
	end
	
	-- create tree view node for the rows and columns
	local TreeViewNode = mcmlNode:GetChild("pe:treeview");
	if( not TreeViewNode ) then
		local cellPadding = mcmlNode:GetAttribute("CellPadding");
		if(cellPadding) then
			cellPadding = string.match(cellPadding, "%d+");
		end	
		TreeViewNode = Map3DSystem.mcml.new(nil, {name="pe:treeview"});
		local defaultnodeheight = mcmlNode:GetAttribute("DefaultNodeHeight")
		if(defaultnodeheight) then
			TreeViewNode:SetAttribute("DefaultNodeHeight", defaultnodeheight + (cellPadding or 0))
		end
		local verticalscrollbarstep = mcmlNode:GetAttribute("VerticalScrollBarStep")
		if(verticalscrollbarstep) then
			TreeViewNode:SetAttribute("VerticalScrollBarStep", verticalscrollbarstep);
		end
		
		local verticalscrollbaroffsetX = mcmlNode:GetNumber("VerticalScrollBarOffsetX")
		if(verticalscrollbaroffsetX) then
			TreeViewNode:SetAttribute("VerticalScrollBarOffsetX", verticalscrollbaroffsetX);
		end

		TreeViewNode:SetAttribute("background", mcmlNode:GetAttribute("background"))
		TreeViewNode:SetAttribute("ShowIcon", false);
		TreeViewNode:SetAttribute("DefaultIndentation", 0);
		
		if(mcmlNode:GetBool("RememberScrollPos")) then
			TreeViewNode:SetAttribute("RememberScrollPos", true);
		end	
		if(mcmlNode:GetBool("ClickThrough")) then
			TreeViewNode:SetAttribute("ClickThrough", true);
		end	
		
		if(cellPadding) then
			TreeViewNode:SetAttribute("style", format("margin:%spx", cellPadding))
		end

		local VerticalScrollBarWidth = mcmlNode:GetNumber("VerticalScrollBarWidth")
		if(VerticalScrollBarWidth) then
			TreeViewNode:SetAttribute("VerticalScrollBarWidth", VerticalScrollBarWidth);
		end

		local ScrollBarTrackWidth = mcmlNode:GetNumber("ScrollBarTrackWidth")
		if(ScrollBarTrackWidth) then
			TreeViewNode:SetAttribute("ScrollBarTrackWidth", ScrollBarTrackWidth);
		end

		mcmlNode:AddChild(TreeViewNode, nil);
	end
	
	if( TreeViewNode ) then
		TreeViewNode:SetAttribute("name", name.."treeview");
		
		--
		-- Extract from datasource if it is already provided in the input. 
		-- this is called before the the pager control is created .
		--
		local ds = mcmlNode:GetAttribute("DataSourceID");
		if(ds) then
			pe_gridview.SetDataSource(mcmlNode, rootName, ds)
		else
			local ds = mcmlNode:GetAttributeWithCode("DataSource");
			if(ds) then
				pe_gridview.SetDataSource(mcmlNode, rootName, ds)
			end
		end
		-- search columns template information and data bind to pe:treeview (and pe:pager)
		pe_gridview.DataBind(mcmlNode, rootName, true);
	
		if(mcmlNode:GetBool("FitHeight", false)) then
			-- fit height. 
			local nRowCount = TreeViewNode:GetChildCount();
			local DefaultNodeHeight = TreeViewNode:GetNumber("DefaultNodeHeight") or 20;
			local nHeight = nRowCount * DefaultNodeHeight;

			local cellPadding = mcmlNode:GetAttribute("CellPadding");
			if(cellPadding) then
				cellPadding = tonumber(string.match(cellPadding, "%d+"));
				if(cellPadding) then
					nHeight = nHeight + cellPadding * 2;
				end
			end	

			if(css["min-height"]) then
				local min_height = css["min-height"];
				nHeight = math.max(min_height or 0, nHeight);
			end

			local nOldHeight = height-top;
			if(nOldHeight > nHeight) then
				parent_height = parent_height + nHeight-nOldHeight;
			end
			height = top + nHeight;
		end

		local myLayout = Map3DSystem.mcml_controls.layout:new();
		myLayout:reset(left, top, width, height);
		
		-- create treeview control
		Map3DSystem.mcml_controls.create(rootName, TreeViewNode, bindingContext, _parent, left, top, width, height, nil, myLayout);
	end
	parentLayout:AddObject(parent_width, parent_height);
	parentLayout:NewLine();
end

-- Public method: set the new data source
-- @param dataSource: if string, it is the DataSourceID. if table it is the data table itself, if function, it is the data function. 
function pe_gridview.SetDataSource(mcmlNode, pageInstName, dataSource)
	local pageCtrl = mcmlNode:GetPageCtrl();
	if(not pageCtrl) then return end
	if(type(dataSource) == "string") then
		-- this is data source ID, we will convert it to a function that dynamically retrieve item from the data source control. 
		local dataDourceControl = pageCtrl:GetNode(dataSource);
		if(dataDourceControl) then
			-- call the select method on data bind
			pageCtrl:CallMethod(dataSource, "Select")
			-- a function that dynamically retrieves item from the data source control. 
			mcmlNode.datasource = function(Index)
				if(Index == nil) then
					return pageCtrl:CallMethod(dataSource, "GetItemCount")
				else
					return pageCtrl:CallMethod(dataSource, "GetRow", Index)
				end
			end
		else
			commonlib.log("warning: gridview %s is unable to find data source %s\n", tostring(mcmlNode:GetAttribute("name")), dataSource)	
			return
		end
	else
		mcmlNode.datasource = dataSource;
	end
	-- reset page count when data source changes. 
	mcmlNode.pagecount = nil;
	
	-- update page count
	local pagesize = tonumber(mcmlNode:GetAttributeWithCode("pagesize"));
	if(pagesize) then
		if(type(mcmlNode.datasource) == "table") then
			mcmlNode.pagecount = math.ceil((#(mcmlNode.datasource))/pagesize);
		elseif(type(mcmlNode.datasource) == "function") then
			mcmlNode.pagecount = math.ceil((mcmlNode.datasource() or 0)/pagesize);
		end
	end	
	local OnDataBound = mcmlNode:GetAttribute("DataBound");
	if(OnDataBound) then
		-- call data bound event
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, OnDataBound, mcmlNode.GetAttribute("name"), dataSource)
	end
	
	-- we will ensure page index  is smaller than page count 
	
	local pageindex = mcmlNode:GetAttribute("pageindex");
	if(pageindex) then
		if(mcmlNode.pagecount==nil or pagesize==nil or (pageindex) > mcmlNode.pagecount) then
			mcmlNode:SetAttribute("pageindex", nil);
		end	
	end
end

-- Public method: rebind (refresh) the data.
-- each bind data row node contains page variable "index" and any other data column values for that row. 
-- the template node can then evaluate for the values of the node to dynamic generate content specific to that row. 
-- such as <%=Eval("index")%> will return the current row index
-- @param bDoNotRefreshUI: true to refresh UI. otherwise node is updated but UI is not. 
function pe_gridview.DataBind(mcmlNode, pageInstName, bDoNotRefreshUI)
	local TreeViewNode = mcmlNode:GetChild("pe:treeview");
	if(not TreeViewNode) then
		log("warning: inner tree view node not found in pe:gridview \n");
		return 
	end
	
	-- iterate and create node. 
	local cellPadding = mcmlNode:GetAttribute("CellPadding");
	if(cellPadding) then
		cellPadding = string.match(cellPadding, "%d+");
	end	
	local pagesize = tonumber(mcmlNode:GetAttributeWithCode("pagesize"));
	local AllowPaging = mcmlNode:GetBool("AllowPaging");
	local ItemsPerLine = mcmlNode:GetNumber("ItemsPerLine") or 1;

	local ScrollToEnd = mcmlNode:GetBool("ScrollToEnd");
	
	local columnsNode = mcmlNode:GetChild("Columns");
	if(columnsNode) then
		TreeViewNode:ClearAllChildren();
		
		-- test if it is empty data
		local nDataCount = true;
		local dataSourceType;
		if(type(mcmlNode.datasource) == "table") then
			nDataCount = #(mcmlNode.datasource)
			dataSourceType = 0;
		elseif(type(mcmlNode.datasource) == "function")	then
			nDataCount = mcmlNode.datasource()
			dataSourceType = 1;
		end

		if(type(nDataCount) == "number" and pagesize) then
			mcmlNode.pagecount = math.ceil(nDataCount/pagesize);
		end
		
		if(nDataCount==nil or nDataCount==0) then
			-- if empty data, show empty templates if any. 
			local EmptyTemplateNode;
			if(nDataCount == nil) then
				EmptyTemplateNode = mcmlNode:GetChild("FetchingDataTemplate") or mcmlNode:GetChild("EmptyDataTemplate");
			else
				EmptyTemplateNode = mcmlNode:GetChild("EmptyDataTemplate");
			end
			if(EmptyTemplateNode) then
				local rowNode = EmptyTemplateNode:clone();
				rowNode.name = "div";
				if(cellPadding) then
					rowNode:SetAttribute("style", format("padding-right:%spx;padding-bottom:%spx", cellPadding, cellPadding))
				end
				TreeViewNode:AddChild(rowNode, nil);
			end
		else
			-- show data of current page. 
			local nFromIndex, nToIndex = 1, nil;
			if(AllowPaging and pagesize) then
				local pageindex = mcmlNode:GetAttribute("pageindex") or 1;
				if(pageindex > (mcmlNode.pagecount or 1)) then
					pageindex = mcmlNode.pagecount or 1;
				end
				mcmlNode:SetAttribute("pageindex", pageindex);
				--mcmlNode.pageindex = mcmlNode.pageindex or 1;
				nFromIndex = (pageindex-1)*pagesize + 1;
				nToIndex = nFromIndex + pagesize - 1;
			else
				nToIndex = pagesize;
			end
			mcmlNode.eval_names_ = mcmlNode.eval_names_ or {};
			local i = nFromIndex;
			local LineNode;
			while (nToIndex==nil or i<=nToIndex) do
				local row;
				if(dataSourceType == 0) then
					row = mcmlNode.datasource[i];
				elseif(dataSourceType == 1) then
					row = mcmlNode.datasource(i);
				end
				if(type(row) == "table") then
					local rowNode = columnsNode:clone();
					rowNode.name = "pe:bindingblock";
					if(cellPadding) then
						rowNode:SetAttribute("style", format("margin-right:%spx;margin-bottom:%spx;", cellPadding, cellPadding))
					end
						
					if(ItemsPerLine == 1) then
						TreeViewNode:AddChild(rowNode, nil);
					else
						rowNode:SetAttribute("style", format("float:float;%s", rowNode:GetAttribute("style") or ""));
						
						local nSubIndex	= i % ItemsPerLine;
						if(nSubIndex == 1) then
							LineNode = Map3DSystem.mcml.new(nil,{name="div"});
							local lineAlign = mcmlNode:GetAttribute("LineAlign");
							if(lineAlign and lineAlign == "center") then
								local LineWidth = mcmlNode:GetNumber("LineWidth");
								if(LineWidth) then
									if((nDataCount-i) < ItemsPerLine) then
										local nLastRowCount = nDataCount % ItemsPerLine;
										if(nLastRowCount == 0) then
											nLastRowCount = ItemsPerLine;
										end
										local max_width = math.floor((nLastRowCount / ItemsPerLine) * LineWidth);
										LineNode:SetAttribute("style", format("max-width:%dpx", max_width));
									else
										LineNode:SetAttribute("style", format("max-width:%dpx", LineWidth));
									end
									LineNode:SetAttribute("align", "center");
								end	
							end
							TreeViewNode:AddChild(LineNode);
						end
						if(LineNode) then
							LineNode:AddChild(rowNode, nil);
						end
					end	
					
					-- set row index and all other column data in the row 
					-- so that in rowNode it can reference them via page scope Eval(), such as <%=Eval("index")%>
					local envCode = format("index=%d", i);
					local n, v;
					for n,v in pairs(mcmlNode.eval_names_) do
						mcmlNode.eval_names_[n] = false;
					end
					for n,v in pairs(row) do
						mcmlNode.eval_names_[n] = true;
						local typeV = type(v)
						if(typeV == "number") then
							envCode = format("%s\n%s=%s", envCode, n, tostring(v));
						elseif(typeV == "string") then
							envCode = string_format("%s\n%s=%q", envCode, n, v);
						elseif(typeV == "boolean" or typeV == "nil") then
							envCode = format("%s\n%s=%s", envCode, n, tostring(v));
						elseif(typeV == "table") then
							envCode = format("%s\n%s=%s", envCode, n, commonlib.serialize_compact(v));
						end
					end
					for n,v in pairs(mcmlNode.eval_names_) do
						if(not v) then
							envCode = format("%s\n%s=nil", envCode, n);
						end
					end
					rowNode:SetPreValue("this", row);
					-- set prescript attribute of pe:bindingblock
					rowNode:SetAttribute("prescript", envCode);
					i = i + 1;
				else
					break;	
				end
			end
		end
		
		-- update pager text
		if(AllowPaging and pagesize) then
			local pagerNode;
			for pagerNode in mcmlNode:next("pe:pager") do
				local pageindex = mcmlNode:GetAttribute("pageindex");
				Map3DSystem.mcml_controls.pe_pager.UpdatePager(pagerNode, pageInstName, pageindex or 0, mcmlNode.pagecount);
			end
		end	
			
		-- refresh treeview
		if(not bDoNotRefreshUI) then
			Map3DSystem.mcml_controls.pe_treeview.Refresh(TreeViewNode, pageInstName, true, nil, ScrollToEnd);
		end	
	else
		log("warning: pe_gridview.DataBind failed because Columns node is not defined\n");
	end
end

---- Public method: for pe:pager
function pe_gridview.GotoPage(mcmlNode, pageInstName, nPageIndex, bDoNotRefreshUI)
	local pagecount = pe_gridview.GetTotalPage(mcmlNode, pageInstName)
	if(nPageIndex and nPageIndex>=1 and nPageIndex<=pagecount) then
		local OnPageIndexChanging = mcmlNode:GetAttribute("OnPageIndexChanging");
		local DisableIndexChange;
		if(OnPageIndexChanging) then
			-- call page index changing event
			DisableIndexChange = Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, OnPageIndexChanging, mcmlNode.GetAttribute("name"), nPageIndex)
		end
		if(not DisableIndexChange) then
			mcmlNode:SetAttribute("pageindex", nPageIndex);
			--mcmlNode.pageindex = nPageIndex;
			pe_gridview.DataBind(mcmlNode, pageInstName, bDoNotRefreshUI)
			
			local OnPageIndexChanged = mcmlNode:GetAttribute("OnPageIndexChanged");
			if(OnPageIndexChanged) then
				-- call page index changed event
				Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, OnPageIndexChanged, mcmlNode.GetAttribute("name"), nPageIndex)
			end
		end	
	end
end

-- Public method: for pe:pager
function pe_gridview.GetTotalPage(mcmlNode, pageInstName)
	return mcmlNode.pagecount or 1;
end

-- Public method: for pe:pager
function pe_gridview.GetCurrentPage(mcmlNode, pageInstName)
	return mcmlNode:GetAttribute("pageindex") or 1;
	--return mcmlNode.pageindex or 1;
end

-- Public method: reset gird view, so that when page refreshes, the data will be fetched again and display the first page
function pe_gridview.Reset(mcmlNode, pageInstName)
	mcmlNode.pagecount = nil;
	mcmlNode:SetAttribute("pageindex", nil);
	--mcmlNode.pageindex = nil;
end

-- scroll to the given node. 
function pe_gridview.ScrollToRow(mcmlNode, pageInstName, nRowIndex)
	local TreeViewNode = mcmlNode:GetChild("pe:treeview");
	if(TreeViewNode) then
		Map3DSystem.mcml_controls.pe_treeview.ScrollToRow(TreeViewNode, pageInstName, nRowIndex);
	end
end

-----------------------------------
-- pe:bindingblock control: 
-- a single repeatable block in a pe:gridview or other iterator controls. 
-----------------------------------
local pe_bindingblock = commonlib.gettable("Map3DSystem.mcml_controls.pe_bindingblock");

-- same as <div>, except that it contains a "prescript" attribute which are executed as script. 
function pe_bindingblock.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local prescript = mcmlNode:GetAttribute("prescript");
	if(prescript) then
		Map3DSystem.mcml_controls.pe_script.DoPageCode(prescript, mcmlNode:GetPageCtrl())
	end
	mcmlNode:ApplyPreValues();

	-- just use the standard style to create the control	
	Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end

-----------------------------------
-- pe:pager control
-- page control can be bind to any other mcml control(like pe:gridview) that supports public methods 
--	"GotoPage(int)", "int GetTotalPage()", "int GetCurrentPage()"
-- To specify a customize look of a pager control, first place a form tags between the opening and closing tags of the pager control. 
-- You can then list the contents of the template between the opening and closing form tags. If any buttons are called "pre" and "next" 
-- they are automatically bounded to command action previous page and next page. If any text or label are called "page", it will be used to display current page number/page count
-----------------------------------
local pe_pager = {};
Map3DSystem.mcml_controls.pe_pager = pe_pager;

-- create pager control for navigation
function pe_pager.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	if(mcmlNode:GetChildCount() == 0) then
		--
		-- the user did not provide any template
		--
		local formNode = Map3DSystem.mcml.new(nil, {name="form"});
		mcmlNode:AddChild(formNode, nil);
		
		-- hidden input storing which control this pager is bound to
		local node = Map3DSystem.mcml.new(nil, {name="input"});
		node:SetAttribute("type", "hidden");
		node:SetAttribute("name", "target");
		node:SetAttribute("value", mcmlNode:GetAttribute("target"));
		formNode:AddChild(node, nil);
		
		-- pre button
		if(mcmlNode:GetAttribute("PreviousPageText") ~= "") then
			local nodeNav = Map3DSystem.mcml.new(nil, {name="div"});
			nodeNav:SetAttribute("name", "pre");
			nodeNav:SetAttribute("style", "float:left;color:#000066;background:;background2:url(Texture/3DMapSystem/common/href.png:2 2 2 2)");
			nodeNav:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_pager.OnPrePage");
			formNode:AddChild(nodeNav, nil);
			
			node = Map3DSystem.mcml.new(nil, {name="img"});
			node:SetAttribute("style", "background:url(Texture/3DMapSystem/common/PageLeft.png);width:16px;height:16px;margin-right:5px");
			nodeNav:AddChild(node, nil);
			
			node = Map3DSystem.mcml.new(nil, {name="span"});
			node:SetInnerText(mcmlNode:GetAttribute("PreviousPageText") or L"Previous");
			nodeNav:AddChild(node, nil);
		else
			node = Map3DSystem.mcml.new(nil, {name="input"});
			node:SetAttribute("type", "button");
			node:SetAttribute("name", "pre");
			node:SetAttribute("style", "background:url(Texture/3DMapSystem/common/PageLeft.png);width:22px;height:22px;margin:2px");
			node:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_pager.OnPrePage");
			formNode:AddChild(node, nil);
		end	

		
		-- page label
		node = Map3DSystem.mcml.new(nil, {name="label"});
		node:SetAttribute("name", "page");
		node:SetAttribute("style", "height:18px;margin-top:0px;margin-left:10px;margin-right:10px;width:50px;text-align:center");
		formNode:AddChild(node, nil);
		
		-- next button
		if(mcmlNode:GetAttribute("NextPageText")~="") then
			local nodeNav = Map3DSystem.mcml.new(nil, {name="div"});
			nodeNav:SetAttribute("name", "next");
			nodeNav:SetAttribute("style", "float:left;color:#000066;background:;background2:url(Texture/3DMapSystem/common/href.png:2 2 2 2)");
			nodeNav:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_pager.OnNextPage");
			formNode:AddChild(nodeNav, nil);
			
			node = Map3DSystem.mcml.new(nil, {name="span"});
			node:SetInnerText(mcmlNode:GetAttribute("NextPageText") or L"Next");
			nodeNav:AddChild(node, nil);
			
			node = Map3DSystem.mcml.new(nil, {name="img"});
			node:SetAttribute("style", "background:url(Texture/3DMapSystem/common/PageRight.png);width:16px;height:16px;margin-left:5px");
			nodeNav:AddChild(node, nil);
		else
			node = Map3DSystem.mcml.new(nil, {name="input"});
			node:SetAttribute("type", "button");
			node:SetAttribute("name", "next");
			node:SetAttribute("style", "background:url(Texture/3DMapSystem/common/PageRight.png);width:22px;height:22px;margin:2px");
			node:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_pager.OnNextPage");
			formNode:AddChild(node, nil);
		end	
	else	
		--
		-- use the user template
		--	
		local formNode = mcmlNode:GetChild("form");
		if(formNode) then
			local node = mcmlNode:SearchChildByAttribute("name", "target");
			if(node) then
				if(not node:GetAttribute("value")) then
					node:SetAttribute("value", mcmlNode:GetAttribute("target"));
				end	
			else
				node = Map3DSystem.mcml.new(nil, {name="input"});
				node:SetAttribute("type", "hidden");
				node:SetAttribute("name", "target");
				node:SetAttribute("value", mcmlNode:GetAttribute("target"));
				formNode:AddChild(node, nil);
			end
			
			node = mcmlNode:SearchChildByAttribute("name", "pre");
			if(node and not node:GetAttribute("onclick")) then
				node:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_pager.OnPrePage");
			end
			
			node = mcmlNode:SearchChildByAttribute("name", "next");
			if(node and not node:GetAttribute("onclick")) then
				node:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_pager.OnNextPage");
			end
		end	
	end	
	
	-- just use the standard style to create the control	
	Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end

-- previous page
function pe_pager.OnPrePage(btnName, mcmlNode)
	if(mcmlNode) then
		mcmlNode = mcmlNode:GetParent("pe:pager")
	end	
	if(mcmlNode) then
		local targetControl = mcmlNode:GetAttribute("target");
		if(targetControl) then
			local pageindex = document:GetPageCtrl():CallMethod(targetControl, "GetCurrentPage") 
			if(pageindex) then
				document:GetPageCtrl():CallMethod(targetControl, "GotoPage", pageindex-1) 
			end	
		end	
	end
end

-- next page
function pe_pager.OnNextPage(btnName, mcmlNode)
	if(mcmlNode) then
		mcmlNode = mcmlNode:GetParent("pe:pager")
	end	
	if(mcmlNode) then
		local targetControl = mcmlNode:GetAttribute("target");
		if(targetControl) then
			local pageindex = document:GetPageCtrl():CallMethod(targetControl, "GetCurrentPage") 
			if(pageindex) then
				document:GetPageCtrl():CallMethod(targetControl, "GotoPage", pageindex+1) 
			end	
		end	
	end
end

-- Public method: call this method whenever page index or page count changes.
function pe_pager.UpdatePager(mcmlNode, pageInstName, pageindex, pagecount)
	if(pageindex and pagecount) then
		local bAutoHidePager = mcmlNode:GetBool("AutoHidePager", false);
		
		local node = mcmlNode:SearchChildByAttribute("name", "page")
		if(node and node.SetUIValue) then
			local value = format("%d/%d", pageindex, pagecount);
			node:SetValue(value);
			node:SetUIValue(pageInstName, value);
			if(bAutoHidePager) then
				local ctl = node:GetControl();
				if(ctl) then
					ctl.visible = not (pagecount == 1);
				end
			end
		end

		local node = mcmlNode:SearchChildByAttribute("name", "singlepage")
		if(node and node.SetUIValue) then
			local value = format("%d", pageindex);
			node:SetValue(value);
			node:SetUIValue(pageInstName, value);
			if(bAutoHidePager) then
				local ctl = node:GetControl();
				if(ctl) then
					ctl.visible = not (pagecount == 1);
				end
			end
		end

		-- enable/disable prev button
		local node = mcmlNode:SearchChildByAttribute("name", "pre")
		if(node and node:HasMethod(pageInstName, "SetEnable")) then
			node:CallMethod(pageInstName, "SetEnable", (pageindex > 1))
			if(bAutoHidePager) then
				local ctl = node:GetControl();
				if(ctl) then
					ctl.visible = not (pagecount == 1);
				end
			end
		end
		
		-- enable/disable next button
		local node = mcmlNode:SearchChildByAttribute("name", "next")
		if(node and node:HasMethod(pageInstName, "SetEnable")) then
			node:CallMethod(pageInstName, "SetEnable", (pageindex < pagecount))
			if(bAutoHidePager) then
				local ctl = node:GetControl();
				if(ctl) then
					ctl.visible = not (pagecount == 1);
				end
			end
		end
	end
end