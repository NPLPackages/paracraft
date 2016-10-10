--[[
Title: component tags controls.
Author(s): LiXizhi
Date: 2008/5/22
Desc: A collection of useful componet tags for recurring tasks. pe:download, pe:custom

---++ pe:download
pe:download downloads resources from "src" to "dest" before its inner content is interactible or rendered. 
The download can start either on-demand or automatically according to the AutoStart property. During downloading, a progress bar overlay is shown.

__example__
<verbatim>
	<pe:download src="http://ufies.org/txt/mozilla1280.jpg" dest="Temp/Textures/mozilla1280.jpg" cachepolicy="access plus 2 days">
		<notready enabled="true">
			<label name="status" class="box" style="height:18px;width:120px;margin:3px"/><br />
			<input type="button" name="start" value="Start Download"/>
			<input type="button" name="stop" value="Stop Download"/>
		</notready>
		<ready>
			Successfully downloaded<br/>
			<input type="button" name="refresh" value="Refresh"/>
			<img width="64" height="64" src="Temp/Textures/mozilla1280.jpg"/>
		</ready>
	</pe:download>
	
	<pe:download src="http://ufies.org/txt/mozilla1280.jpg" dest="Temp/Textures/mozilla1280.jpg" auto>
		<a href="#">
			only clickable when download is done.
		</a>
	</pe:download>
</verbatim>

__Properties__:

| *Property*	| *Descriptions*				 |
| src			| the source url where to download the file. It may be an image file or a zip file. |
| dest			| the destination local disk file path where to download the file will be saved as. One can renames the file or extension when saving it. |
| autostart		| If true the download will begin automatically, otherwise it will be started until the user clicked on it. Default is false. |
| notready		| This is an optional node which, if present, will be shown before the downloaded file is ready. if not present, either ready node or the entire inner text of pe:download will be shown. the inner nodes of notready shall not depends on the "src" resource. |
| ready			| This is an optional node which, if present, will be shown after the downloaded file is ready. if not present, the entire inner text of pe:download will be shown |
| cachepolicy	| Default cache policy,default to "access plus 2 days", please refer to CachePolicy for formatting. such as "access plus 2 hours",  "access plus 10 seconds"|

   * Note1: the pe:download AND its inner node content is NOT interactive until the download process is complete. When download is complete, the pe:download functions in the exactly same way as its inner nodes.
   * Note2: use notready and ready node if you want to display something that depends on the downloaded resource. 
However, if you are not using them, make sure the inner nodes are NOT dependent on the downloading resource, 
because the inner nodes will be rendered when control is created (i.e. may BEFORE download completes), however the inner nodes are not interactible until the download fully completed. 

__Methods__:

| *Methods*		| *Descriptions*			|
| StartDownload	| start or resume downloading			|
| StopDownload	| Stop downloading			|

__Events__:

| *Events*		| *Descriptions*			|
| OnProgress()	| called when a fraction of the downloaded file is received	|

---+++ Customizing the look
You can fully customize the appearance of the download control, using the background property of the pe:download, the ready and the notready property nodes. 

when the enabled attribute of the notready property is set to true, the controls inside notready property will be interactive. and that it may contain child button nodes
whose name is "start", "stop", "status". They will map to start download button, stop download button, status text label, respectively. Please see the example code above. 

Content that are neither inside "ready" nor "notready" node will always be rendered. When there is no "notready" property defined, we will just append a default one at the end of the inner content. 
Normally it just says "not downloaded yet"

ready property may contain child button node whose name is "refresh". It will map to refresh download button. Please see the example code above. 

---++ pe:custom
this tag allows you to embed page level NPL UI object inside an mcml page 
The most important attribute is oncreate and style and name. 
*note*: if name is not nil, oncreate's params.name will be a unqiue string id inside the page. 
<verbatim>
	<pe:custom name="MyCustom" oncreate="OnCreateFunc" style="width:100px;height:50px">
	
	-- @param params contains information inside which the NPL UI objects can be created. 
	function OnCreateFunc(params, mcmlNode)
		local p = {
			name = params.name,
			alignment = params.alignment,
			left = params.left,
			top = params.top,
			width = params.width,
			height = params.height,
			parent = params.parent,
		}
	end
</verbatim>

---++ pe:world
Internally it is translated to <a> which, when clicked will jump and login to the game world. 
The inner nodes of pe:world are rendered like normal mcml nodes. 

| *Property*	| *Descriptions*				 |
| worldpath		| the downloaded local world path from which to load the world |
| role			| the role of the current user that will join the world. values may be "guest", "administrator", "poweruser", "friend". If this is nil, it will be default to "guest" or "administrator" depending on the server type. |
| server		| if this is nil, it will be loaded as an offline world unless autolobby is specified. if it is like "jgsl://username@domain" or just "username@domain", it will login to the server according to server type. In most cases, it is JGSL. |
| uid			| if this is nil, it will be loaded as an offline world unless autolobby is specified. the server user's uid. this is only used when server is not nil.
| autolobby		| if this is true, paraworld.lobby.* api will be used to either host or join an existing world with given worldpath.|

*example*
<verbatim>
	<pe:world worldpath = "temp/worlds/some_world_id.zip" role="guest" server="jgsl://lixizhi1@pala5.com">
		click to join<br/>
        <img style="background:url(worlds/Templates/Empty/smallisland/preview.jpg);width:160px;height:90px"/>
    </pe:world>
</verbatim>

---++ pe:if and pe:if-not
content are only created when the condition evaluates to true. 

*example*
<verbatim>
	<pe:if condition='<%=Eval("ReleaseBuild")%>'>
	        This is a release build.
    </pe:if>
    <pe:if-not condition='<%=Eval("ReleaseBuild")%>'>
            This is a debug build.
    </pe:if-not>
</verbatim>

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_component.lua");
-------------------------------------------------------
]]
local pe_html = commonlib.gettable("Map3DSystem.mcml_controls.pe_html");
if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

local L = CommonCtrl.Locale("IDE");

local Locale = {
	downloading = L"Downloading ...",
	complete = L"Download complete",
	terminated = L"Download terminated",
	percentage = L"Completing: %d/%dKB",
	NotDownloaded  = L"Not downloaded",
	ClickToDownload  = L"Click to start download",
}

----------------------------------------------------------------------
-- pe:download: 
----------------------------------------------------------------------

local pe_download = {};
Map3DSystem.mcml_controls.pe_download = pe_download;

-- create control: a grey semi-transparent button blocks the client area until the download is completed. 
function pe_download.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local src = paraworld.TranslateURL(mcmlNode:GetAttributeWithCode("src"));
	local dest = mcmlNode:GetAttributeWithCode("dest");
	
	local autostart = mcmlNode:GetAttributeWithCode("autostart");
	-- whether download is completed. 
	local bIsReady;
	
	if(dest and mcmlNode.status~="downloading") then
		if(ParaIO.DoesFileExist(dest, true)) then
			bIsReady = true;
		end
	end
	
	if(autostart and not bIsReady) then
		-- start or resume downloading
		pe_download.StartDownload(mcmlNode, rootName)
	end
	
	local myLayout = parentLayout:clone();
	myLayout:SetUsedSize(0,0);
	
	local readyNode = mcmlNode:GetChild("ready")
	local notreadyNode = mcmlNode:GetChild("notready")
		
	if(bIsReady) then
		-- show ready template
		if(readyNode) then
			readyNode:SetAttribute("display", nil);
			node = readyNode:SearchChildByAttribute("name", "refresh");
			if(node and not node:GetAttribute("onclick")) then
				node:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_download.onclick_refreshdownload");
			end
		end
		if(notreadyNode) then
			notreadyNode:SetAttribute("display", "none"); -- hide notready
		end
		mcmlNode:SetAttribute("onclick", nil);
		mcmlNode:SetAttribute("tooltip", nil);
	else
		-- show notready template
		if(readyNode) then
			readyNode:SetAttribute("display", "none"); -- hide ready
		end
		if(notreadyNode) then
			notreadyNode:SetAttribute("display", nil);
		else
			-- if user does not provide any notready template, we will provide a simple default version here. 
			notreadyNode = Map3DSystem.mcml.new(nil, {name="notready"});
			mcmlNode:AddChild(notreadyNode, nil);
			local statusNode = Map3DSystem.mcml.new(nil, {name="label"});
			statusNode:SetAttribute("name", "status");
			statusNode:SetAttribute("style", "height:18px;width:120px;padding-left:5px;padding-right:5px;background:url(Texture/alphadot.png);");
			notreadyNode:AddChild(statusNode, nil);
		end
		
		if(notreadyNode) then
			-- update template
			local node = notreadyNode:SearchChildByAttribute("name", "status");
			if(node) then
				node:SetInnerText(mcmlNode.status_text or Locale.NotDownloaded);
			end
			
			node = notreadyNode:SearchChildByAttribute("name", "start");
			if(node and not node:GetAttribute("onclick")) then
				node:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_download.onclick_startdownload");
			end
			
			node = notreadyNode:SearchChildByAttribute("name", "stop");
			if(node and not node:GetAttribute("onclick")) then
				node:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_download.onclick_stopdownload");
			end
		end	

		if(notreadyNode and notreadyNode:GetAttribute("enabled")) then
			mcmlNode:SetAttribute("onclick", nil);
			mcmlNode:SetAttribute("tooltip", nil);
		else
			-- if no template is provided, we will make the inner content non-interactive and redirect its onclick to start download command action
			mcmlNode:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_download.onclick");
			mcmlNode:SetAttribute("tooltip", Locale.ClickToDownload.."\n"..tostring(src));
		end	
	end
	-- just use the standard style to create the control	
	Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end

-- private: user clicks any part of the control when in not ready state
function pe_download.onclick(nodeName, mcmlNode)
	local pageCtrl = mcmlNode:GetPageCtrl()
	if(not pageCtrl) then return end 
	if(mcmlNode.name~="pe:download") then
		mcmlNode = mcmlNode:GetParent("pe:download");
	end	
	if(mcmlNode == nil) then 
		log("pe:download not found in pe_download.onclick\n");
		return;
	end
	-- start downloading
	pe_download.StartDownload(mcmlNode, pageCtrl.name)
end

-- private: 
function pe_download.onclick_startdownload(nodeName, mcmlNode)
	if(mcmlNode.name~="pe:download") then
		mcmlNode = mcmlNode:GetParent("pe:download");
	end	
	if(mcmlNode == nil) then 
		log("pe:download not found in pe_download.onclick_startdownload\n");
		return;
	end
	local pageCtrl = mcmlNode:GetPageCtrl()
	pe_download.StartDownload(mcmlNode, pageCtrl.name)
end

-- private: 
function pe_download.onclick_stopdownload(nodeName, mcmlNode)
	if(mcmlNode.name~="pe:download") then
		mcmlNode = mcmlNode:GetParent("pe:download");
	end	
	if(mcmlNode == nil) then 
		log("pe:download not found in pe_download.onclick_stopdownload\n");
		return;
	end
	
	local pageCtrl = mcmlNode:GetPageCtrl()
	pe_download.StopDownload(mcmlNode, pageCtrl.name);
end

-- private: refresh downloading. download needs to be stopped first. 
function pe_download.onclick_refreshdownload(nodeName, mcmlNode)
	if(mcmlNode.name~="pe:download") then
		mcmlNode = mcmlNode:GetParent("pe:download");
	end	
	if(mcmlNode == nil) then 
		log("pe:download not found in pe_download.onclick_refreshdownload\n");
		return;
	end
	
	-- download without caching
	pe_download.StartDownload(mcmlNode, nil, "access plus 0 day")
	local pageCtrl = mcmlNode:GetPageCtrl()
	if(mcmlNode.status == "downloading") then
		pageCtrl:Refresh(0.1);
	end	
end


-- Public method: start downloading. 
-- @param mcmlNode: the pe:download node
-- @param cachepolicy: Default cache policy,default to mcmlNode:GetAttribute("cachepolicy"), please refer to CachePolicy for formatting. such as "access plus 2 hours",  "access plus 10 seconds"
-- To refresh downloaded files, just call with "access plus 0 day"
function pe_download.StartDownload(mcmlNode, pageInstName, cachepolicy)
	local pageCtrl = mcmlNode:GetPageCtrl();
	if(pageCtrl == nil) then return end
	
	if(mcmlNode.status == "downloading") then
		return; -- already downloading, just prevents downloading twice
	end
	
	local src = paraworld.TranslateURL(mcmlNode:GetAttributeWithCode("src"));
	local dest = mcmlNode:GetAttributeWithCode("dest");
	
	if(src and dest) then
		mcmlNode.status = "downloading";
		mcmlNode.status_text = Locale.downloading;
		
		-- resource store
		local ls = System.localserver.CreateStore(nil, 1);
		if(not ls) then
			log("error: failed creating local server ResourceStore \n")
			return 
		end
		
		-- testing: get file with a clear all. 
		-- ls:DeleteAll();
		-- ls:GetFile(System.localserver.CachePolicy:new("access plus 0"),
		
		
		ls:GetFile(System.localserver.CachePolicy:new(cachepolicy or mcmlNode:GetAttribute("cachepolicy") or "access plus 2 days"),
			src,
			function (entry)
				if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
					mcmlNode.status = "complete";
					pageCtrl:Refresh();
					commonlib.log("pe:download successfully downloaded file from %s to %s\n", src, dest);
				else
					mcmlNode.status = "error";	
				end	
			end,
			nil,
			function (msg, url)
				local text;
				if(msg.DownloadState == "") then
					text = Locale.downloading
					if(msg.totalFileSize) then
						text = string.format("œ¬‘ÿ÷–: %d/%dKB", math.floor(msg.currentFileSize/1024), math.floor(msg.totalFileSize/1024));
					end
				elseif(msg.DownloadState == "complete") then
					text = Locale.complete;
				elseif(msg.DownloadState == "terminated") then
					text = Locale.terminated;
				end
				if(text) then
					mcmlNode.status_text = text;
					mcmlNode:CallMethod(pageCtrl.name, "RefreshStatus");
				end	
			end
		);
		mcmlNode:CallMethod(pageCtrl.name, "RefreshStatus");
	end	
end

-- Public method: 
function pe_download.StopDownload(mcmlNode, pageInstName)
	-- Stop downloading
end

-- Public method: refresh download status, such as rotating sandtimer, such as updating status text
function pe_download.RefreshStatus(mcmlNode, pageInstName)
	if(mcmlNode.status_text) then
		local node = mcmlNode:SearchChildByAttribute("name", "status");
		if(node) then
			node:SetUIValue(pageInstName, mcmlNode.status_text)
		end
	end	
end

----------------------------------------------------------------------
-- pe:roomhost: internally it is a predefined grid view of online hosts. 
----------------------------------------------------------------------

local pe_roomhost = {};
Map3DSystem.mcml_controls.pe_roomhost = pe_roomhost;

function pe_roomhost.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
end

----------------------------------------------------------------------
-- pe:custom: a user provided mcml create control function, set value function, etc.  
----------------------------------------------------------------------

local pe_custom = {};
Map3DSystem.mcml_controls.pe_custom = pe_custom;

-- the control takes up all available spaces yet without creating any newline
function pe_custom.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(pe_html.css["div"], style) or {};
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
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	local instName;
	if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
		instName = mcmlNode:GetInstanceName(rootName);
	end	
	
	local params = {
		name = instName or "",
		alignment = "_lt",
		left = left,
		top = top,
		width = width - left,
		height = height - top,
		parent = _parent,
		background = css.background,
	}
	
	-- call the on create function(params) in page scoping
	local oncreateFunc = mcmlNode:GetString("oncreate");
	if(oncreateFunc) then
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, oncreateFunc, params, mcmlNode);
	end
end

----------------------------------------------------------------------
-- pe:world: internally it is just translated to <a> which when clicked will jump and login to the game world. 
----------------------------------------------------------------------

local pe_world = {};
Map3DSystem.mcml_controls.pe_world = pe_world;

function pe_world.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local worldpath = mcmlNode:GetAttributeWithCode("worldpath");

	local server = mcmlNode:GetAttributeWithCode("server");
	local role = mcmlNode:GetAttributeWithCode("role");
	local autolobby = mcmlNode:GetBool("autolobby");
	mcmlNode:SetAttribute("onclick", "Map3DSystem.App.Commands.Call");
	mcmlNode:SetAttribute("param1", Map3DSystem.App.Commands.GetLoadWorldCommand())
	mcmlNode:SetAttribute("param2", {worldpath=worldpath, server=server, role=role, autolobby=autolobby, uid=mcmlNode:GetAttributeWithCode("uid")});
	-- use the pe_a style to create the control	
	Map3DSystem.mcml_controls.pe_a.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end

----------------------------------------------------------------------
-- pe:if: handles MCML tag <pe:if>
-- Only renders the content inside the tag if the condition evaluates to true
----------------------------------------------------------------------

local pe_if = {};
Map3DSystem.mcml_controls.pe_if = pe_if;

-- pe_name is just a wrapper of button control with user name as text
function pe_if.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local condition = mcmlNode:GetAttributeWithCode("condition", nil, true);
	
	if(condition==true or condition=="true") then
		-- if no control mapping found, create each child node. 
		local css = mcmlNode:GetStyle(pe_html.css[mcmlNode.name], style) or {};
		Map3DSystem.mcml.baseNode.DrawChildBlocks_Callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, parentLayout, css)

		--local childnode;
		--for childnode in mcmlNode:next() do
			--local left, top, width, height = parentLayout:GetPreferredRect();
			--Map3DSystem.mcml_controls.create(rootName,childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
		--end
	end
end

----------------------------------------------------------------------
-- pe:if_not: handles MCML tag <pe:if-not>
-- Only renders the content inside the tag if the condition evaluates to true
----------------------------------------------------------------------

local if_not = {};
Map3DSystem.mcml_controls.if_not = if_not;

-- pe_name is just a wrapper of button control with user name as text
function if_not.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local condition = mcmlNode:GetAttributeWithCode("condition", nil, true);
	
	if(not condition or condition=="false") then
		-- if no control mapping found, create each child node. 
		local css = mcmlNode:GetStyle(pe_html.css[mcmlNode.name], style) or {};
		Map3DSystem.mcml.baseNode.DrawChildBlocks_Callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, parentLayout, css)

		--local childnode;
		--for childnode in mcmlNode:next() do
			--local left, top, width, height = parentLayout:GetPreferredRect();
			--Map3DSystem.mcml_controls.create(rootName,childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
		--end
	end
end
local pe_repeat = {};
Map3DSystem.mcml_controls.pe_repeat = pe_repeat;
local string_format = string.format;
local format = format;
function pe_repeat.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local DataSource = mcmlNode:GetAttributeWithCode("DataSource", nil, true);
	local columnsNode = mcmlNode:GetChild("pe:repeatitem");
	if(not columnsNode)then return end

	-- now prepare an empty node to which all generated node will be added. 
	local generated_node = mcmlNode:GetChild("DataNodePlaceholder");
	if(not generated_node) then
		generated_node = Map3DSystem.mcml.new(nil,{name="DataNodePlaceholder"});
		mcmlNode:AddChild(generated_node);
	else
		generated_node:ClearAllChildren();
	end

	if(DataSource and type(DataSource) == "table")then
		for i,row in ipairs(DataSource) do
			if(type(row) == "table") then
				local rowNode = columnsNode:clone();
				rowNode:SetPreValue("this", row);
				rowNode:SetPreValue("index", i);
				for n,v in pairs(row) do
					rowNode:SetPreValue(n, v);
				end

				--[[
				mcmlNode.eval_names_ = {};
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
				Map3DSystem.mcml_controls.pe_script.DoPageCode(envCode, mcmlNode:GetPageCtrl())
				]]

				generated_node:AddChild(rowNode);
				rowNode:ApplyPreValues();

				local left, top, width, height = parentLayout:GetPreferredRect();
				Map3DSystem.mcml_controls.create(rootName,rowNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
			end
		end
	end
end