--[[
Title: pe:fileloader
Author(s): Leio, LiXizhi
Date: 2010/11/20
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_fileloader.lua");

---++ pe:fileloader tag
show/hide page content according to whether some asset file is successfully downloaded.
Internally, it will refresh the page after all UI have been loaded.
Note: Always put this tag in front of show/hide elements. if one wants to put pe:fileloader tag after other tag, then one needs to set "alwaysrefresh" attribute to true. 
However, it is highly recommended to put this tag in the front of a page. 

attributes:
| name | this must be a globally unique name for each set of input files. if nil, it will be the containing page url.  |
| loading_show | the jquery path to show during file loading. e.g. "div#loading". The controlled tag must support display attribute, such as div, a, etc. Most common mcml tag supports it. |
| loading_hide | the jquery path to hide  during file loading. e.g. "div#content".The controlled tag must support display attribute, such as div, a, etc. |
| alwaysrefresh | boolean, default to false. it is highly recommended to set this to false and put pe:fileloader tag in front of other tags. That way, it will not call page:Refresh() if the loader is already finished during page rendering. |
| loader_callback | update function when some new files are available. 
						function OnUpdateProgress(args)
							if(not args)then return end
							local type = args.type;
							local p = 0;
							if(type == "start")then
								p = 0;
							elseif(type == "loading")then
								p = args.percent or 0;
							elseif(type == "finish")then
								p = 1;
							end
							p = math.floor(p * 100);
						end
| datasource | it must be an array table with filename like below {{ filename = "file1.png",},{ filename = "file2.png" },}
| autoload | whether to start downloading automatically. default to true.  |
| logname | the log file. such as "log/mcml_preloader". default to "", which means no log. |

It can also use child nodes as datasource, which will be merged with the data source. like this <asset key="aaa.dds"/>
<verbatim>
	<pe:fileloader name="loader_name_must_be_unique" loading_show="#loader" loading_hide="#content" datasource="<%={{filename="a.png"}} %>">
		<asset key="a.dds" />
		<asset key="b.x" />
	</pe:fileloader>
	<div name="loader">
		ui to display during loading
		<!--we can usually reference another file for the loader UI-->
        <pe:template filename="script/apps/Aries/Dialog/AriesPageLoaderTemplate.html"></pe:template>
	</div>
	<div name="content">ui to display after assets have been downloaded. </div>
</verbatim>

@see "script/kids/3DMapSystemApp/mcml/test/test_pe_fileloader.html" for more examples. 
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/FileLoader.lua");

local pe_fileloader = commonlib.gettable("Map3DSystem.mcml_controls.pe_fileloader");
local loaders = {};
function pe_fileloader.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local name = mcmlNode:GetAttribute("name");
	if(not name) then
		name = mcmlNode:GetPageCtrl().url;
	end
	
	local loading_show =  mcmlNode:GetAttributeWithCode("loading_show") or "";
	local loading_hide =  mcmlNode:GetAttributeWithCode("loading_hide") or "";
	local loader_callback =  mcmlNode:GetAttributeWithCode("loader_callback") or "";
	local datasource =  mcmlNode:GetAttributeWithCode("datasource") or "";
	local autoload =  mcmlNode:GetAttributeWithCode("autoload") or "true";
	local logname = mcmlNode:GetAttributeWithCode("logname") or ""; 
	local list = {};

	if(type(datasource) == "table")then
		local k,v;
		for k,v in ipairs(datasource) do
			local filename = v.filename;
			local filesize = v.filesize;
			table.insert(list,{filename = filename, filesize = filesize, });
		end
	end

	-- merge child nodes to datasource.
	local node;
	for node in mcmlNode:next("asset") do
		local key = node:GetAttribute("key");
		if(key and key ~= "")then
			table.insert(list,{filename = key});
		end
	end
	local loader = loaders[name];
	if(not loader)then
		LOG.std("", "system", "pe_fileloader", "new page loader added %s", name);
		
		loader = CommonCtrl.FileLoader:new{
			download_list = list,--下载文件列表
			logname = logname,--log文件地址
		}
		loaders[name] = loader;
	else
		loader.download_list = list;
	end
	-- keep a reference here
	mcmlNode.control = loader;  

	local page = mcmlNode:GetPageCtrl();
	-- tricky: we will avoid calling page:Refresh() if content have already been downloaded. 
	local bNeedsRefresh = false;
	if(mcmlNode:GetAttribute("alwaysrefresh") == "true") then
		bNeedsRefresh = true;
	end
	
	loader:AddEventListener("start",function(self,event)
			mcmlNode.is_started_ = true;
			pe_fileloader.do_function(mcmlNode,loader_callback,event);
			page(loading_show).show();
			page(loading_hide).hide();
			-- shall we do a page refresh here?
			if(bNeedsRefresh) then
				page:Refresh(); 
			end
	end,{});
	loader:AddEventListener("loading",function(self,event)
			pe_fileloader.do_function(mcmlNode,loader_callback,event);
	end,{});
	loader:AddEventListener("finish",function(self,event)
			pe_fileloader.do_function(mcmlNode,loader_callback,event);
			page(loading_show).hide();
			page(loading_hide).show();
			-- shall we do a page refresh here?
			if(bNeedsRefresh) then
				page:Refresh();
			end
	end,{});
	if(autoload == "true" or autoload == true)then
		if(not mcmlNode.is_started_) then
			-- tricky, we will only start once, to prevent page refresh for recursive calls to start() and onfinish() method. 
			loader:Start();
		end
	end
	bNeedsRefresh = true;
end

function pe_fileloader.do_function(mcmlNode,loader_callback,event)
	if(not mcmlNode)then return end

	local set_value_target = mcmlNode:GetAttribute("set_value_target"); 
	local set_text_target = mcmlNode:GetAttribute("set_text_target"); 
	if(set_value_target or set_text_target) then
		local args = event;
		local type = args.type;
		local p = 0;
		if(type == "start")then
			p = 0;
		elseif(type == "loading")then
			p = args.percent or 0;
		elseif(type == "finish")then
			p = 1;
		end
		p = math.floor(p * 100);
		local pageCtrl = mcmlNode:GetPageCtrl();
		if(pageCtrl) then
			if(set_value_target) then
				pageCtrl:SetUIValue(set_value_target, p);
			end
			if(set_text_target) then
				pageCtrl:SetUIValue(set_text_target, string.format("%.2f%%", p));
			end
		end
	end

	-- invoke call back if any. 
	if(not loader_callback or loader_callback == "") then
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, loader_callback, event);
	end
end

