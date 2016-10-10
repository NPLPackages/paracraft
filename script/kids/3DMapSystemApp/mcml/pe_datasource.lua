--[[
Title: data source control in mcml
Author(s): LiXizhi
Date: 2008/5/18
Desc: MCML includes data source controls that allow you to work with different types of data sources such as a database, 
an XML file, or a middle-tier business object. Data source controls connect to and retrieve data from a data source 
and make it available for other controls to bind to, without requiring code. 

---+++ Data Source Control Comparison
   * ObjectDataSource: Enables you to work with a business object or other NPL table that rely on middle-tier objects to manage data. 
   * Mqldatasource: Enables you to work with ParaWorldAPI Server. It supports advanced caching capabilities. The control also supports paging when data is returned via MCQL.
   * XmlDataSource: Enables you to work with an XML file, especially for hierarchical TreeView or Menu control. Supports filtering capabilities using XPath expressions

---+++ ObjectDataSource control overview

---+++ XmlDataSource control overview
The XmlDataSource loads XML data from an XML file specified using the DataFile property. XML data can also be loaded from the Data property
Please note that DataFile can be both a local file or a remote xml file via HTTP. 

<verbatim>
	<pe:xmldatasource name="OfficialAppDataSource" DataFile="Apps.xml" XPath="//category[@name='OfficialApps']">
		<data>
		  <Apps>
			<category name="OfficialApps">
			  <app name="Creation" Author="ParaEngine" IsBeta="True"/>
			  <app name="Environment" Author="ParaEngine"/>
			  <app name="Avatar" Author="ParaEngine"/>
			</category>
			<category name="Game">
			  <app name="Dance" Author="ParaEngine"/>
			  <app name="RPG Maker" Author="ParaEngine"/>
			</category>
		  </Apps>
		</data>
	</pe:xmldatasource>
	
	<pe:gridview name="gvwApps" DataSourceID="OfficialAppDataSource" style="margin:10px" CellPadding="5"  AllowPaging="True" DefaultNodeHeight = "20" pagesize="12" >
		<Columns>
			Name: <%=XPath("app.attr.name")%>
		</Columns>
	</pe:gridview>
</verbatim>

| *Property*  | *description* |
| cachepolicy | default to 1 hour, example "access plus 10 seconds" |
| XPath | XPath in xml data |
| DataFile | external or local xml file to bind to |
| data | xml node to bind to |

---+++ MqlDataSource control overview
Represents an MQL query result to data-bound controls. For more information about MQL, see microcomos query language related topics. 
You can use the MqlDataSource control in conjunction with a data-bound control (like pe:gridbiew) to retrieve data from 
paraworld central server and to display, and sort data on a MCML page with little or no code.

To retrieve data from an underlying database, set the SelectCommand property with an MQL query (similar to SQL). 
The MqlDataSource control retrieves data whenever the Select method is called. The Select method is automatically called by controls 
that are bound to the MqlDataSource when their DataBind method is called. If you set the DataSourceID property of a data-bound control, 
the control automatically binds to data from the data source, as required. 

*example*
<verbatim>
	<pe:mqldatasource name="FriendsDataSource" DataSourceMode="DataReader" SelectCommand="select uid,createDate,uname from users where uname=@username" cachepolicy="access plus 1 hour">
		<SelectParameters>
			<pe:parameter name="username" type="string" defaultvalue="ParaEngine" />
			<pe:parameter name="age" type="number" defaultvalue="10" />
		</SelectParameters>
	</pe:mqldatasource>
	
	<pe:gridview name="gvwFriends" DataSourceID="FriendsDataSource" style="margin:10px" CellPadding="5"  AllowPaging="True" DefaultNodeHeight = "20" pagesize="12" >
		<Columns>
			uname: <%=Eval("uname")%>
			uid: <%=Eval("uid")%>
			create date: <%=Eval("createDate")%>
		</Columns>
	</pe:gridview>
</verbatim>

| *Property*	| *description* |
| SelectCommand | select query string. see MQL for more information. it may contain parameters like the example above |
| cachepolicy	| default to 1 hour, example "access plus 10 seconds" |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_datasource.lua");
-------------------------------------------------------
]]

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-----------------------------------
-- pe:xmldatasource control: 
-----------------------------------

local pe_xmldatasource = {};
Map3DSystem.mcml_controls.pe_xmldatasource = pe_xmldatasource;

-- data source control.
function pe_xmldatasource.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
end

-- public method: call this method to actually retrieve query result from mql data source, it will bind parameters if any. 
-- whenever the data is available it will call Refresh() method to refresh the page. 
function pe_xmldatasource.Select(mcmlNode, pageInstName)
end

-- get data root node
function pe_xmldatasource.GetDataRootNode(mcmlNode)
	local dataNode = mcmlNode:GetChild("dataroot");
	if(not dataNode) then
		dataNode = mcmlNode:GetChild("data");
		if(dataNode) then
			pe_xmldatasource.OnDownloaded_CallBack(dataNode, nil, {rootName= rootName, mcmlNode=mcmlNode})
		else
			local datafile = mcmlNode:GetAttribute("DataFile");
			if(datafile) then
				if(string.find(datafile, "^http://")) then
					-- for remote url, use the local server to retrieve the data
					
					-- TRICKY: we use the "fetching" attribute to prevent the same request to be made multiple times in the same place during page refresh. 
					-- the "fetching" attribute is set after the remote request is issued. We also check if the result is available immediately after the call, 
					-- because some unexpired/expired version maybe returned and we can display it without waiting for the actual asynchronous result. 
					if(not mcmlNode:GetAttribute("fetching")) then
						local ls = System.localserver.CreateStore(nil, 2);
						if(ls)then
							local cachepolicy = mcmlNode:GetString("cachepolicy");
							if(cachepolicy) then
								cachepolicy = System.localserver.CachePolicy:new(cachepolicy)
							else
								cachepolicy = System.localserver.CachePolicies["1 hour"]
							end
							local bFetching = ls:CallXML(cachepolicy, datafile, pe_xmldatasource.OnDownloaded_CallBack, {rootName= rootName, mcmlNode=mcmlNode})
							mcmlNode:SetAttribute("fetching", bFetching==true)
						end
					end	
				else
					-- for local file, open it directly
					-- remove requery string when parsing file. 
					local filename = string.gsub(datafile, "%?.*$", "")
					local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
					if(type(xmlRoot)=="table" and table.getn(xmlRoot)>0) then
						pe_xmldatasource.OnDownloaded_CallBack(xmlRoot, nil, {rootName= rootName, mcmlNode=mcmlNode})
					else
						log("warning: unable to open local page "..datafile.."\n")
					end
				end	
			end
		end	
		dataNode = mcmlNode:GetChild("dataroot");
	end
	return dataNode;
end

-- private: data is available now. when data is available it will call Refresh method of the page. 
function pe_xmldatasource.OnDownloaded_CallBack(xmlRoot, appkey, params)
	if(not params or not params.mcmlNode or not xmlRoot) then return end
	
	local dataNode = params.mcmlNode:GetChild("dataroot");
	if(dataNode) then
		dataNode:Detach();
		dataNode = nil;
	end
	if(dataNode == nil) then
		local xpath = params.mcmlNode:GetString("XPath");
		if(xpath) then
			-- use XPath to find the data node. 
			NPL.load("(gl)script/ide/XPath.lua");
			local node;
			for node in commonlib.XPath.eachNode(xmlRoot, xpath) do
				dataNode = node;
				dataNode.name = "dataroot";
				break;
			end
		else
			dataNode = xmlRoot;
			dataNode.name = "dataroot";
		end
		
		if(dataNode) then
			params.mcmlNode:AddChild(dataNode);
			
			-- refresh page if data is later available. 
			if(params.mcmlNode:GetAttribute("fetching")) then
				params.mcmlNode:GetPageCtrl():Refresh();
			end
		else
			-- just do an empty node. 	
			dataNode = Map3DSystem.mcml.new(nil, {name="dataroot"});
			params.mcmlNode:AddChild(dataNode);
		end	
	end
end

-- public method: set page size
function pe_xmldatasource.SetPageSize(mcmlNode, pageInstName, pagesize)
	mcmlNode.pagesize = pagesize;
end

-- public method: get row as an NPL table.
-- @param Index: 1 based row index 
-- it will return nil if no row found at index. 
function pe_xmldatasource.GetRow(mcmlNode, pageInstName, Index)
	local dataNode = pe_xmldatasource.GetDataRootNode(mcmlNode);
	
	if(dataNode and Index and Index>=1 and table.getn(dataNode)>=Index) then
		local node = dataNode[Index];
		local output = {};
		
		local function copy_table(dest,src)
			if(src.attr) then
				commonlib.partialcopy(dest, src.attr);
			end	
			local nSrcSize = table.getn(src);
			if(nSrcSize>0) then
				local i;
				for i = 1, nSrcSize do 
					local node = src[i];
					if(type(node) == "table") then
						dest[node.name] = {};
						copy_table(dest[node.name], node);
					elseif(type(node) == "string") then
						dest["text"] = node;
					end	
				end
			end
		end
		
		if(type(node) == "table") then
			copy_table(output, node)
		end	
		return output;
	end
end

-- public method: get item count
function pe_xmldatasource.GetItemCount(mcmlNode, pageInstName, Index)
	local dataNode = pe_xmldatasource.GetDataRootNode(mcmlNode);
	if(dataNode) then
		return table.getn(dataNode);
	end
	return 0;
end


-----------------------------------
-- pe:mqldatasource control: 
--<pe:xmldatasource name="FriendsDataSource" DataSourceMode="DataReader" SelectCommand="select uid,createDate,uname from users where uname=@username"/>
	--<SelectParameters>
		--<pe:parameter name="username" type="string" defaultvalue="ParaEngine" />
	--</SelectParameters>
--</pe:xmldatasource>
-----------------------------------

local pe_mqldatasource = {};
Map3DSystem.mcml_controls.pe_mqldatasource = pe_mqldatasource;

-- data source control.
function pe_mqldatasource.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
end

-- public method: call this method to actually retrieve query result from mql data source, it will bind parameters if any. 
-- whenever the data is available it will call Refresh() method to refresh the page. 
-- @param bForeceUpdate: if this is true, it will force updating.
function pe_mqldatasource.Select(mcmlNode, pageInstName, bForeceUpdate)
	-- TRICKY: we use the "fetching" attribute to prevent the same request to be made multiple times in the same place during page refresh. 
	-- the "fetching" attribute is set after the remote request is issued. We also check if the result is available immediately after the call, 
	-- because some unexpired/expired version maybe returned and we can display it without waiting for the actual asynchronous result. 
	if(not bForeceUpdate and mcmlNode:GetAttribute("fetching")) then
		return;
	end
	local selectCommand = mcmlNode:GetString("SelectCommand");
	
	if(selectCommand) then
		-- replace all parameters 
		local param;
		while (true) do
			param = string.match(selectCommand, "[^%w]@(%w+)")
			if(param) then
				local value = pe_mqldatasource.GetParameter(mcmlNode, nil, "SelectParameters", param);
				if(type(value) == "string") then
					-- value can not contain ' character. we shall escape it 
					-- Caution: default escape characters vary by DBMS and can be overridden. For most DBMS, 
					-- doubling the single-quote character is the default means of escaping a single-quote;
					selectCommand = string.gsub(selectCommand, "^(.*)(@%w+)(.*)$", string.format("%%1'%s'%%3", string.gsub(value, "'", "''")))
				elseif(type(value) == "number") then
					selectCommand = string.gsub(selectCommand, "^(.*)(@%w+)(.*)$", string.format("%%1'%s'%%3", tostring(value)))
				else
					log("warning: unknown parameter "..param.." is found \n")	
					break;
				end	
			else
				break;
			end
		end
		-- commonlib.echo(selectCommand)
		-- call the web service query. 
		local msg = {
			query = selectCommand,
		};
		local cachepolicy = mcmlNode:GetString("cachepolicy");
		if(cachepolicy) then
			msg.cache_policy = System.localserver.CachePolicy:new(cachepolicy)
		else
			msg.cache_policy = System.localserver.CachePolicies["1 hour"]
		end
		
		local bFetching = paraworld.MQL.query(msg, "paraworld", function(msg)
			if(msg) then
				local n, v;
				for n, v in pairs(msg) do
					if(type(v)=="table") then
						-- use the first found table as respond table
						mcmlNode.datatable = v;
						break;
					end
				end
				mcmlNode.datatable = mcmlNode.datatable or {};
				local pageCtrl = mcmlNode:GetPageCtrl();
				if(pageCtrl) then
					pageCtrl:Refresh();
				end
			end
		end);
		mcmlNode:SetAttribute("fetching", bFetching==true)
	end
end

-- public method: set a parameter
-- @param ParamCategory: it must be "SelectParameters" at the moment. 
-- @param name: parameter name
-- @param value: value of the parameter to set. 
function pe_mqldatasource.SetParameter(mcmlNode, pageInstName, ParamCategory, name, value)
	local paramsNode = mcmlNode:GetChild(ParamCategory);
	if(paramsNode) then
		local param = paramsNode:SearchChildByAttribute("name", name);
		if(param) then
			param:SetAttribute("value", value);
		end
	end
end

-- public method: get a parameter
-- @param ParamCategory: it must be "SelectParameters" at the moment. 
-- @param name: parameter name
-- @return: value of the parameter. it will return nil if not found. 
function pe_mqldatasource.GetParameter(mcmlNode, pageInstName, ParamCategory, name)
	local paramsNode = mcmlNode:GetChild(ParamCategory);
	if(paramsNode) then
		local param = paramsNode:SearchChildByAttribute("name", name);
		if(param) then
			local value = param:GetAttribute("value") or param:GetAttribute("defaultvalue");
			local type = param:GetAttribute("type");
			if(type == "number") then
				value = tonumber(value);
			end
			return value;
		end
	end
end

-- public method: set page size
function pe_mqldatasource.SetPageSize(mcmlNode, pageInstName, pagesize)
	mcmlNode.pagesize = pagesize;
end

-- public method: get row as an NPL table.
-- @param Index: 1 based row index 
-- it will return nil if no row found at index. 
function pe_mqldatasource.GetRow(mcmlNode, pageInstName, Index)
	if(type(mcmlNode.datatable) == "table") then
		return mcmlNode.datatable[Index];
	end
end

-- public method: get item count. It will return nil, if data is not available yet. 
function pe_mqldatasource.GetItemCount(mcmlNode, pageInstName)
	if(type(mcmlNode.datatable) == "table") then
		return #(mcmlNode.datatable);
	end
	return nil;
end