--[[
Title: Mobile Builder Frame Page
Author(s): pbb
Date: 2022 11 04
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileBuilderFramePage.lua");
local MobileBuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileBuilderFramePage");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local pe_treeview = commonlib.gettable("Map3DSystem.mcml_controls.pe_treeview");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BuilderFramePage.lua");
local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");

local MobileBuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileBuilderFramePage");

local page;

MobileBuilderFramePage.category_index = -1;
MobileBuilderFramePage.Current_Item_DS = {};
MobileBuilderFramePage.category_ds_new = {
    {text=L"建造", name="static",     enabled=true},
    {text=L"电影", name="movie",     enabled=true},
    {text=L"代码", name="character",  enabled=true},
    {text=L"机关", name="gear",	     enabled=true},
    {text=L"装饰", name="deco",       enabled=true},
	{text=L"工具", name="tool",	     enabled=true},
	{text=L"模板", name="template",   enabled=true},
}
MobileBuilderFramePage.custombtn_nodes = {
	{},{},{},{},{},{},{},{},{},
}
MobileBuilderFramePage.select_template_index = -1
MobileBuilderFramePage.select_templates = {}
MobileBuilderFramePage.templates = {
	{text=L"本地模板",name="Local Templates",enabled=true,key="local"},
	{text=L"全局模板",name="Global Templates",enabled=true,key="global"},
}

MobileBuilderFramePage.category_ds = MobileBuilderFramePage.category_ds_new;
MobileBuilderFramePage.uiversion = 1;

function MobileBuilderFramePage.OnInit(uiversion)
	MobileBuilderFramePage.OneTimeInit(uiversion);
	page = document:GetPageCtrl();
	if MobileBuilderFramePage.category_index == -1 then
		MobileBuilderFramePage.category_index = 1;
	end
	MobileBuilderFramePage.OnChangeCategory(MobileBuilderFramePage.category_index, false);
	if MobileBuilderFramePage.select_template_index == -1 then
		MobileBuilderFramePage.select_template_index = 1;
	end
	MobileBuilderFramePage.select_templates = {}
	MobileBuilderFramePage.GetAllTemplatesDS(true)
end

function MobileBuilderFramePage.RefreshPage()
	if(page) then
		page:Refresh(0.1)
	end
end

function MobileBuilderFramePage.ClearData()
	MobileBuilderFramePage.select_template_index = -1
	MobileBuilderFramePage.category_index = -1
	MobileBuilderFramePage.select_templates = {}
end

function MobileBuilderFramePage.OneTimeInit(uiversion)
	if(MobileBuilderFramePage.is_inited) then
		return;
	end
	MobileBuilderFramePage.is_inited = true;

	MobileBuilderFramePage.uiversion = uiversion;
	MobileBuilderFramePage.category_ds = MobileBuilderFramePage.category_ds_new;
end

function MobileBuilderFramePage.GetCategoryButtons()
	return MobileBuilderFramePage.category_ds;
end

-- clicked a block item
function MobileBuilderFramePage.OnClickBlock(block_id_or_item)
	if type(block_id_or_item) == "table" then
		GameLogic.GetFilters():apply_filters("user_event_stat", "tool", "pick:"..tostring(block_id_or_item.block_id), 1, nil);
	else
		GameLogic.GetFilters():apply_filters("user_event_stat", "tool", "pick:"..tostring(block_id_or_item), 1, nil);
	end

    if(block_id_or_item) then
		local item;
		if(type(block_id_or_item) ~= "table") then
			item = ItemClient.GetItem(block_id_or_item)
		else
			item = block_id_or_item;
		end
		if(item) then
			item:OnClick();
		end
	end
end

-- right click a block item, show help
function MobileBuilderFramePage.OnHelpBlock(block_id)
	GameLogic.GetFilters():apply_filters("user_event_stat", "help", "browse:"..tostring(block_id), 2, nil);

	GameLogic.RunCommand("/wiki "..tostring(block_id));
end

--- @param index number: category index
--- @param bRefreshPage boolean: num false to stop refreshing the page
function MobileBuilderFramePage.OnChangeCategory(index, bRefreshPage)
	MobileBuilderFramePage.category_index = index or MobileBuilderFramePage.category_index;
	local category = MobileBuilderFramePage.GetCategoryButtons()[MobileBuilderFramePage.category_index];
	if(category) then
		MobileBuilderFramePage.Current_Item_DS = ItemClient.GetBlockDS(category.name);
		-- if not GameLogic.Macros:IsRecording() and not GameLogic.Macros:IsPlaying() then
		-- 	MobileBuilderFramePage.UpdateItemsData(category.name)
		-- end
		MobileBuilderFramePage.Current_Item_DS = commonlib.filter(MobileBuilderFramePage.Current_Item_DS,function (block)
			return block.block_id ~= 10516 
				and block.block_id ~= 10517 
				and block.block_id ~= 10518 
				and block.block_id ~= 10519 
				and block.block_id ~= 10073
				and block.block_id ~= 10030
				and block.block_id ~= 271
				and block.block_id ~= 275
		end)
		MobileBuilderFramePage.category_name = category.name;
	end
	if category.name == "template" then
		MobileBuilderFramePage.select_template_index = -1
		MobileBuilderFramePage.OnChangeTempCategory(1,true)
	end
	if bRefreshPage == false then
		return 
	end
	MobileBuilderFramePage.RefreshPage()
end

function MobileBuilderFramePage.UpdateItemsData(category_name)
	local temp = {}
	if MobileBuilderFramePage.Current_Item_DS then
		if category_name == "movie" or category_name == "gear" or category_name == "tool" or category_name == "character" then
			for k,v in pairs(MobileBuilderFramePage.Current_Item_DS) do
				if v.block_id ~= 219 then
					temp[#temp + 1] = v
				else
					if v.uid then
						temp[#temp + 1] = v
					end
				end
			end
			MobileBuilderFramePage.Current_Item_DS = temp
		end
	end
end

function MobileBuilderFramePage.CheckHasItem(index)
	local player = GameLogic.EntityManager.GetPlayer()
	if not player then
		return false
	end
	local inventory = player.inventory
	if inventory then
		local block_id, block_count = inventory:GetItemByBagPos(tonumber(index))
		return block_id and block_id > 0
	end
end


local GetTempData = function(data)
	if not data then
		return {}
	end
	local temp = {}
	local num = #data
	for i = 1 ,num do
		local attr = data[i].attr
		if attr and data[i].name == "file" then
			temp[#temp + 1] = {
				accessdate=attr.accessdate,
				createdate=attr.createdate,
				fileattr=attr.fileattr,
				filename=attr.filename,
				filesize=attr.filesize,
				text=attr.text,
				writedate=attr.writedate
			}
		end
	end
	return temp
end
--模板
function MobileBuilderFramePage.GetAllTemplatesDS(bRefresh)
	if bRefresh or not MobileBuilderFramePage.tbAllTemplates then
		local data = BlockTemplatePage.GetAllTemplatesDS(true)
		MobileBuilderFramePage.tbAllTemplates = {}
		MobileBuilderFramePage.tbAllTemplates["all"] = {}
		MobileBuilderFramePage.tbAllTemplates["local"] = {}
		local num = #data
		for i = 1,num do
			local attr = data[i].attr
			if attr and (attr.text == "全局模板" or string.find(attr.text,"Global")) then
				local templates = data[i]
				MobileBuilderFramePage.tbAllTemplates["global"] = GetTempData(templates)
			end
			if attr and (attr.text == "本地模板" or string.find(attr.text,"Local")) then
				local templates = data[i]
				MobileBuilderFramePage.tbAllTemplates["local"] = GetTempData(templates)
			end
		end
	end
end


function MobileBuilderFramePage.OnChangeTempCategory(index,bRefresh)
	local index = tonumber(index)
	if index and MobileBuilderFramePage.select_template_index ~= index then
		MobileBuilderFramePage.select_template_index = index
		local key = MobileBuilderFramePage.templates[index].key
		MobileBuilderFramePage.select_templates = MobileBuilderFramePage.tbAllTemplates[key]
		-- echo(MobileBuilderFramePage.select_templates,true)
		MobileBuilderFramePage.RefreshPage()
	end
end

function MobileBuilderFramePage.OnClickActorContextMenuItem(node)
	local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	local filename = MobileBuilderFramePage.rightCtxValue
	local isBmax = filename:match("%.bmax$")
	if(node.Name == "take") then
		BuilderFramePage._TakeBmax(filename)
	elseif(node.Name == "loadtemplate") then
		BlockTemplatePage.CreateFromTemplate(filename);
	elseif(node.Name == "delete") then
		
		local path = GameLogic.RunCommand(string.format("/deletefile %s -backup",filename))
		if path then
			path = string.gsub(path,ParaIO.GetWritablePath(),"")
			GameLogic.AddBBS(nil, L"成功删除文件并备份为："..commonlib.Encoding.DefaultToUtf8(path))
		end
		MobileBuilderFramePage.GetAllTemplatesDS(true)
		local pre_template_index = MobileBuilderFramePage.select_template_index
		MobileBuilderFramePage.select_template_index = -1
		MobileBuilderFramePage.OnChangeTempCategory(pre_template_index ~= -1 and pre_template_index or 1,true)
	end
end

function MobileBuilderFramePage.OnShowActorContextMenu(x,y, width, height)
	if(MobileBuilderFramePage.contextMenuActor == nil)then
		MobileBuilderFramePage.contextMenuActor = CommonCtrl.ContextMenu:new{
			name = "contextMenuActor",
			width = 180,
			height = 30,
			DefaultNodeHeight = 26,
			onclick = MobileBuilderFramePage.OnClickActorContextMenuItem,
		};
		local node = MobileBuilderFramePage.contextMenuActor.RootNode;
		node:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
		local node = node:GetChild(1);
	end
	local ctl = MobileBuilderFramePage.contextMenuActor
	local node = ctl.RootNode:GetChild(1);
	if(node) then
		node:ClearAllChildren();
		local filename = MobileBuilderFramePage.rightCtxValue

		local _ctxMenuItems
		local isX = filename:match("%.x$")
		local isBmax = filename:match("%.bmax$")
		if isBmax then
			_ctxMenuItems = {
				{name="take", text=L"拿在手上"}, 
				{name="loadtemplate", text=L"展示bmax原型"},
				{name="delete", text=L"删除模板"},
			};
		elseif isX then
			_ctxMenuItems = {
				{name="take", text=L"拿在手上"},
				{name="delete", text=L"删除模板"},
			};
		else
			_ctxMenuItems = {
				{name="loadtemplate", text=L"加载模板"},
				{name="delete", text=L"删除模板"},
			};
		end
		for index, item in ipairs(_ctxMenuItems) do
			local text = item.text or item.name;
				
			if(item.name == "take") then
				
			elseif(item.name == "loadtemplate") then
			elseif(item.name == "delete") then
				
			end
			if(text) then
				local uiname;
				if(item.name~="") then
					uiname = "contextMenuActor."..item.name
				end
				node:AddChild(CommonCtrl.TreeNode:new({Text = text, uiname=uiname, Name = item.name, Type = "Menuitem", onclick = nil, }))
			end
		end
		ctl.height = (#_ctxMenuItems) * 26 + 4;
	end
	if(not x or not width) then
		x, y, width, height = _guihelper.GetLastUIObjectPos();
	end
	if(x and width) then
		MobileBuilderFramePage.contextMenuActor:Show(x, y+height);
	end
end

function MobileBuilderFramePage.OnClickTemplateItem(name)
	local index = tonumber(name)
	if not index then
		return
	end
	local item = MobileBuilderFramePage.select_templates[index]
    local isBmax = item.filename:match("%.bmax$")
    local isX = item.filename:match("%.x$")

	local mouse_button = mouse_button;
	if(mouse_button=="left") then
		if isBmax or isX then
			BuilderFramePage._TakeBmax(item.filename)
		else
			BlockTemplatePage.CreateFromTemplate(item.filename);
		end
		GameLogic.ToggleDesktop("builder");
	elseif(mouse_button=="right") then
		MobileBuilderFramePage.rightCtxValue = item.filename
		MobileBuilderFramePage.OnShowActorContextMenu()
	end
end 