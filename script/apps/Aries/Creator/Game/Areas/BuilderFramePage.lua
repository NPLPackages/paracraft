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
    {text=L"方块", name="static",     enabled=true},
    -- {text=L"自然", name="nature",     enabled=true},
	{text=L"电影", name="movie",     enabled=true},
    {text=L"人物", name="character",  enabled=true},
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

function BuilderFramePage.OnInit(uiversion)
	BuilderFramePage.OneTimeInit(uiversion);
	page = document:GetPageCtrl();
	BuilderFramePage.OnChangeCategory(nil, false);
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

-- clicked a block
function BuilderFramePage.OnClickBlock(block_id)
	local search_text_obj = ParaUI.GetUIObject("block_search_text_obj");
	if(search_text_obj:IsValid())then
		search_text_obj:LostFocus();
	end	
    if(block_id) then
		local item = ItemClient.GetItem(block_id)
		if(item) then
			item:OnClick();
		end
	end
end

-- @param bRefreshPage: false to stop refreshing the page
function BuilderFramePage.OnChangeCategory(index, bRefreshPage)
    BuilderFramePage.category_index = index or BuilderFramePage.category_index;
	local category = BuilderFramePage.GetCategoryButtons()[BuilderFramePage.category_index];
	if(category) then
		BuilderFramePage.Current_Item_DS = ItemClient.GetBlockDS(category.name);
		BuilderFramePage.category_name = category.name;
	end


	BuilderFramePage.isSearching = false;
    
	if(bRefreshPage~=false and page) then
		page:Refresh(0.01);
	end
end

local first_search = true;
local search_text_nil;

function BuilderFramePage.SearchBlock(search_text)
	--local block_tag;
	if(search_text) then
		local block_tag = string.gsub(search_text,"%s","");
		if(block_tag == "") then
			search_text_nil = true;
			local cur_category_obj = ParaUI.GetUIObject("builder_cur_category_btn");
			cur_category_obj.background = "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;208 89 21 21:8 8 8 8";

			local category = BuilderFramePage.GetCategoryButtons()[1];
			BuilderFramePage.Current_Item_DS = ItemClient.GetBlockDS(category.name);
		else
			if(first_search or search_text_nil) then
				search_text_nil = false;
				local cur_category_obj = ParaUI.GetUIObject("builder_cur_category_btn");
				cur_category_obj.background = "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;179 89 21 21:8 8 8 8";
			end 
			
			BuilderFramePage.Current_Item_DS = ItemClient.SearchBlocks(block_tag,"all");
		end
	end
	local gvw_name = "new_builder_gvwItems";
	local node = page:GetNode(gvw_name);
	pe_gridview.DataBind(node, gvw_name, false);

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