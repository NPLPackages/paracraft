--[[
Title: Builder Frame Page
Author(s): LiXizhi
Date: 2013/10/15
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BuilderFramePage.lua");
local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");
BuilderFramePage.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");

local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local pe_treeview = commonlib.gettable("Map3DSystem.mcml_controls.pe_treeview");

local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");

local page;

BuilderFramePage.category_index = 1;
BuilderFramePage.Current_Item_DS = {};

BuilderFramePage.category_ds_old = {
    {text=L"建造", name="static",    enabled=true},
    {text=L"装饰", name="deco",      enabled=true},
    {text=L"人物", name="character", enabled=true},
    {text=L"机关", name="gear",      enabled=true},
    {text=L"工具", name="tool",      enabled=true},
    {text=L"模板", name="template",  enabled=true},
}

BuilderFramePage.category_ds_new = {
    {text=L"建造", name="static",     enabled=true},
    {text=L"电影", name="movie",     enabled=true},
    {text=L"代码", name="character",  enabled=true},
    {text=L"背包", name="playerbag",     enabled=true},
    {text=L"机关", name="gear",	     enabled=true},
    {text=L"装饰", name="deco",       enabled=true},
	{text=L"工具", name="tool",	     enabled=true},
	{text=L"模板", name="template",   enabled=true},
}

BuilderFramePage.category_ds_touch = {
	--{text="全部", name="all",     enabled=true},
	{text=L"方块", name="static",     enabled=true},
	{text=L"装饰", name="deco",       enabled=true},
	{text=L"电影", name="movie",     enabled=true},
	-- {text=L"人物", name="character",  enabled=true},
	{text=L"机关", name="gear",	     enabled=true},
	{},
    {text=L"关闭", name="close",     enabled=true},
	--{text=L"全部", name="all",     enabled=true},
    --{text=L"自然", name="nature",     enabled=true},
    --{text=L"背包", name="playerbag",     enabled=true},
    --{text=L"装饰", name="deco",       enabled=true},
	--{text=L"工具", name="tool",	     enabled=true},
	--{text=L"模板", name="template",   enabled=true},
};
BuilderFramePage.category_ds = BuilderFramePage.category_ds_new;
BuilderFramePage.uiversion = 1;
BuilderFramePage.isSearching = false;
BuilderFramePage.EmptyText = L"搜索: 输入ID或名字";

function BuilderFramePage.OnInit(uiversion)
	BuilderFramePage.OneTimeInit(uiversion);
	page = document:GetPageCtrl();
	BuilderFramePage.OnChangeCategory(nil, false);
	GameLogic.GetFilters():remove_filter("bulid_frame_page_refresh",BuilderFramePage.RefreshPage)
	GameLogic.GetFilters():add_filter("bulid_frame_page_refresh",BuilderFramePage.RefreshPage)
end

function BuilderFramePage.RefreshPage()
	if(page) then
		BlockTemplatePage.GetAllTemplatesDS(true)
		page:Refresh(0)
	end
end

function BuilderFramePage.OneTimeInit(uiversion)
	if(BuilderFramePage.is_inited) then
		return;
	end
	BuilderFramePage.is_inited = true;

	BuilderFramePage.uiversion = uiversion;
	BuilderFramePage.category_ds = nil;
	
	if(System.options.IsMobilePlatform) then
		BuilderFramePage.category_ds = BuilderFramePage.category_ds_touch;
	elseif(uiversion == 0) then
		BuilderFramePage.category_ds = BuilderFramePage.category_ds_old;
	elseif(uiversion == 1) then
		BuilderFramePage.category_ds = BuilderFramePage.category_ds_new;
	end
end

function BuilderFramePage.GetCategoryButtons()
	return BuilderFramePage.category_ds;
end

-- clicked a block item
function BuilderFramePage.OnClickBlock(block_id_or_item)
	if type(block_id_or_item) == "table" then
		GameLogic.GetFilters():apply_filters("user_event_stat", "tool", "pick:"..tostring(block_id_or_item.block_id), 1, nil);
	else
		GameLogic.GetFilters():apply_filters("user_event_stat", "tool", "pick:"..tostring(block_id_or_item), 1, nil);
	end

	local search_text_obj = ParaUI.GetUIObject("block_search_text_obj");
	if(search_text_obj:IsValid())then
		search_text_obj:LostFocus();
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
function BuilderFramePage.OnHelpBlock(block_id)
	GameLogic.GetFilters():apply_filters("user_event_stat", "help", "browse:"..tostring(block_id), 2, nil);

	GameLogic.RunCommand("/wiki "..tostring(block_id));
end

--- @param index number: category index
--- @param bRefreshPage boolean: num false to stop refreshing the page
function BuilderFramePage.OnChangeCategory(index, bRefreshPage)
	BuilderFramePage.category_index = index or BuilderFramePage.category_index;
	local category = BuilderFramePage.GetCategoryButtons()[BuilderFramePage.category_index];
	if(category) then
		BuilderFramePage.Current_Item_DS = ItemClient.GetBlockDS(category.name);
		BuilderFramePage.category_name = category.name;
	end

	BuilderFramePage.isSearching = false;
	if(page) then
		page:Refresh(0);
	end

	-- TODO 国际化-搜索: 输入模板名字
	ParaUI.GetUIObject("block_search_text_obj"):SetField(
		"EmptyText", 
		if_else(BuilderFramePage.category_index ~= 8, L"搜索: 输入ID或名字", L"搜索: 输入模板名字"));

	-- reset template list
	BuilderFramePage.SearchTemplate(nil);
end

local first_search = true;
local search_text_nil;
function BuilderFramePage.SearchBlockOrigin(search_text)
	--local block_tag;
	if(search_text) then
		-- template search
		if(BuilderFramePage.category_index == 8) then
			BuilderFramePage.SearchTemplate(search_text);
		end

		local block_tag = string.gsub(search_text,"%s","");
		local btnName = format("BuilderFramePage.category_%d", BuilderFramePage.category_index)
		
		if(block_tag == "") then
			search_text_nil = true;
			local cur_category_obj = ParaUI.GetUIObject(btnName);
			cur_category_obj.background = "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;208 89 21 21:8 8 8 8";

			local category = BuilderFramePage.GetCategoryButtons()[1];
			BuilderFramePage.Current_Item_DS = ItemClient.GetBlockDS(category.name);
		else
			if(first_search or search_text_nil) then
				search_text_nil = false;
				local cur_category_obj = ParaUI.GetUIObject(btnName);
				cur_category_obj.background = "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;179 89 21 21:8 8 8 8";
			end 
			
			BuilderFramePage.Current_Item_DS = ItemClient.SearchBlocks(block_tag,"all");
		end
	end
	local gvw_name = "new_builder_gvwItems";
	local node = page:GetNode(gvw_name);
	pe_gridview.DataBind(node, gvw_name, false);
end
-- 加下防抖, 输入延迟200ms后调用搜索函数
BuilderFramePage.SearchBlock = commonlib.debounce(BuilderFramePage.SearchBlockOrigin, 200)

--- @param search_text string
--- @return nil
function BuilderFramePage.SearchTemplate(search_text)
	local name = "gvwBlockTemplates";
	if(not page) then
		return
	end
	local node = page:GetNode(name);

	pe_treeview.SetDataSource(
		node, 
		page.name, 
		BlockTemplatePage.GetAllTemplatesDS(true, search_text));
	pe_treeview.DataBind(node, page.name, true);
end

function BuilderFramePage.ShowMobilePage(bShow)

	local params = {
			url = "script/apps/Aries/Creator/Game/Areas/BuilderFramePage.mobile.html",
			name = "QuickSelectBar.ShowMobilePage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			bToggleShowHide=true, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			--bShow = bShow,
			click_through = true, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -940/2,
				y = -610/2,
				width = 920,
				height = 532,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
--
	--System.App.Commands.Call("File.MCMLWindowFrame", {
			--url = "script/apps/Aries/Creator/Game/Areas/BuilderFramePage.mobile.html",
			--name = "QuickSelectBar.ShowPage", 
			--isShowTitleBar = false,
			--DestroyOnClose = true,
			--style = CommonCtrl.WindowFrame.ContainerStyle,
			--allowDrag = false,
			--bShow = bShow,
			--zorder = -5,
			--click_through = true, 
			--directPosition = true,
				--align = "_ct",
				--x = -860/2,
				--y = -550/2,
				--width = 860,
				--height = 550,
		--});
end

function BuilderFramePage._TakeBmax(filename)
	local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
	local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	filename = Files.GetRelativePath(filename)
	filename = commonlib.Encoding.DefaultToUtf8(filename)
	if(xmlRoot) then
		local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");
		if(node and node[1]) then
			local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
			if(root_node and root_node[1]) then
				local node = commonlib.XPath.selectNode(root_node, "/pe:blocks");
				if(node and node[1]) then
					local blocks = NPL.LoadTableFromString(node[1]);
					for _, b in ipairs(blocks) do
						if(b[4]) then
							local block_template = block_types.get(b[4]);
							if(block_template) then
								if b[6] and b[6].attr and b[6].attr.filename then
									filename = b[6].attr.filename
								end
							end
						end
					end
				end
			end
		end
	end
	
	if not filename:match("%.bmax$") and not filename:match("%.x$") then
		return
	end

	GameLogic.RunCommand(string.format("/take BlockModel {tooltip=%q}", filename));

	-- local block_id = 254
	-- local x, y, z = ParaScene.GetPlayer():GetPosition();
	-- local bx, by, bz = BlockEngine:block(x, y+0.5, z);
	
	-- local xml_data = {
	-- 	attr={
	-- 		bx=bx,
	-- 		by=by,
	-- 		bz=bz,
	-- 		class="EntityBlockModel",
	-- 		facing=3.14,
	-- 		filename=filename,
	-- 		item_id=block_id,
	-- 		stackHeight=0.2 
	-- 	},
	-- 	name="entity" 
	-- }
	
	-- local block = block_types.get(block_id);
	-- local block_data = block:GetMetaDataFromEnv(bx, by, bz, side, side_region);
	-- if(BlockEngine:SetBlock(bx, by, bz, block_id, block_data, 3, xml_data)) then
	-- 	block:play_create_sound();
	-- end
end

function BuilderFramePage.OnClickActorContextMenuItem(node)
	local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	local filename = BuilderFramePage.rightCtxValue
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
		BlockTemplatePage.GetAllTemplatesDS(true)
		if page then
			page:Refresh(0)
		end
	end
end

function BuilderFramePage.OnShowActorContextMenu(x,y, width, height)
	if(BuilderFramePage.contextMenuActor == nil)then
		BuilderFramePage.contextMenuActor = CommonCtrl.ContextMenu:new{
			name = "contextMenuActor",
			width = 180,
			height = 30,
			DefaultNodeHeight = 26,
			onclick = BuilderFramePage.OnClickActorContextMenuItem,
		};
		local node = BuilderFramePage.contextMenuActor.RootNode;
		node:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
		local node = node:GetChild(1);
	end
	local ctl = BuilderFramePage.contextMenuActor
	local node = ctl.RootNode:GetChild(1);
	if(node) then
		node:ClearAllChildren();
		local filename = BuilderFramePage.rightCtxValue

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
		BuilderFramePage.contextMenuActor:Show(x, y+height);
	end
end

function BuilderFramePage.OnClickTemplateItem(name, mcmlNode)
	local item = mcmlNode:GetPreValue("this", true);
    local isBmax = item.filename:match("%.bmax$")
    local isX = item.filename:match("%.x$")

	local mouse_button = mouse_button;
	if(mouse_button=="left") then
		if isBmax or isX then
			BuilderFramePage._TakeBmax(item.filename)
		else
			BlockTemplatePage.CreateFromTemplate(item.filename);
		end
	elseif(mouse_button=="right") then
		BuilderFramePage.rightCtxValue = item.filename
		BuilderFramePage.OnShowActorContextMenu()
	end
end 
