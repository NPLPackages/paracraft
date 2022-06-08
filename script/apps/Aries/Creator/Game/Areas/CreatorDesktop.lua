--[[
Title: creator desktop
Author(s): LiXizhi
Date: 2013/10/15
Desc: the creator desktop
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/CreatorDesktop.lua");
local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
CreatorDesktop.StaticInit();
CreatorDesktop.ShowPage(true)
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

local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local page;
CreatorDesktop.views = {
	{name="builder", property_wnd_url="script/apps/Aries/Creator/Game/Areas/BuilderFramePage.html", content_wnd_url="script/apps/Aries/Creator/Game/Areas/InventoryPage.html", 
		allowed_game_modes = {["creative"]={content_wnd_url=""}, ["editor"]={content_wnd_url=""}, ["survival"]={property_wnd_url=""}, ["game"]={property_wnd_url=""}, }},
	{name="env", property_wnd_url="script/apps/Aries/Creator/Game/Areas/EnvFramePage.html", content_wnd_url=""},
	{name="world", property_wnd_url="script/apps/Aries/Creator/Game/Areas/WorldFramePage.html", content_wnd_url=""},
	{name="esc", property_wnd_url="script/apps/Aries/Creator/Game/Areas/EscFramePage.html", content_wnd_url=""},
}

CreatorDesktop.current_view = CreatorDesktop.views[1];

function CreatorDesktop.OnInit()
	page = document:GetPageCtrl();
	GameLogic.events:AddEventListener("game_mode_change", CreatorDesktop.OnGameModeChanged, CreatorDesktop, "CreatorDesktop");
end

-- callback function
function CreatorDesktop:OnGameModeChanged()
	CreatorDesktop.UpdateModeUI();
end

function CreatorDesktop.UpdateModeUI()
	if(page) then
		local mode = GameLogic.GetMode();
		CreatorDesktop.SetView();
	end
end

function CreatorDesktop.CloseWindow()
	if page then
		page:CloseWindow()
		page = nil
	end
end

-- toggle a given view by it name
-- @param name: such as "builder", if nil, it just toggle last view
function CreatorDesktop.ShowView(name, bShow)
	if(name and CreatorDesktop.GetCurrentView().name ~= name) then
		CreatorDesktop.OnChangeView(name);
	end
	CreatorDesktop.ShowPage(bShow);
end

function CreatorDesktop.ShowPage(bShow)
	if(not bShow) then
		if(page and page:IsVisible()) then
			bShow = false;
			-- do a full collection here
			collectgarbage("collect");
		else
			bShow = true;
		end
	end

	CreatorDesktop.params = CreatorDesktop.params  or {
			url = "script/apps/Aries/Creator/Game/Areas/CreatorDesktop.html", 
			name = "CreatorDesktop.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			bToggleShowHide=true, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			bShow = bShow,
			click_through = true, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	CreatorDesktop.params.bShow = bShow;
	System.App.Commands.Call("File.MCMLWindowFrame", CreatorDesktop.params);

end

function CreatorDesktop.ToggleGameMode()
	
end

-- set the current view. Never refresh the page, otherwise it will be recursively called. 
-- @param view: table value
function CreatorDesktop.SetView(view)
	local mode = GameLogic.GetMode();
	
	local view = view or CreatorDesktop.current_view;
	CreatorDesktop.current_view = view;

	local view_property = view;
	if(view.allowed_game_modes and view.allowed_game_modes[mode]) then
		view_property = view.allowed_game_modes[mode];
	end

	GameLogic.events:DispatchEvent({type = "view_change" , view = CreatorDesktop.current_view,});

	if(page) then
		page:SetValue("property_wnd", view_property.property_wnd_url or view.property_wnd_url or "");
		local content_wnd_url  = view_property.content_wnd_url or view.content_wnd_url or "";
		page:SetValue("content_wnd", view_property.content_wnd_url or view.content_wnd_url or "");

		local black_canvas = page:FindControl("black_canvas");
		if(black_canvas) then
			if(content_wnd_url == "") then
				black_canvas.visible = false;
			else
				black_canvas.visible = true;
			end
		end
	end
end

function CreatorDesktop.OnChangeTabview(index)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BuilderFramePage.lua");
    local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");
    BuilderFramePage.isSearching = false;
    CreatorDesktop.tabview_index = tonumber(index);
	if(CreatorDesktop.new_page) then
		CreatorDesktop.new_page:Refresh(0.01);
	end
end

-- change view
function CreatorDesktop.OnChangeView(value)
	local _, view;
	for _, view in ipairs(CreatorDesktop.views) do
		if(view.name == value) then
			CreatorDesktop.SetView(view);
			break;
		end
	end
end

-- get the current view info table. 
function CreatorDesktop.GetCurrentView()
	return CreatorDesktop.current_view;
end

CreatorDesktop.tabview_index = 1;
--CreatorDesktop.tabview_Item_DS = {};

CreatorDesktop.tabview_ds = {
    {text=L"建造", name="building", url="script/apps/Aries/Creator/Game/Areas/BuilderFramePage.html?version=1", enabled=true}, -- script/apps/Aries/Creator/Game/Areas/BuilderFramePage.html
    {text=L"环境", name="env", url="script/apps/Aries/Creator/Game/Areas/EnvFramePage.html?version=1", enabled=true}, -- script/apps/Aries/Creator/Game/Areas/EnvFramePage.html
}

CreatorDesktop.new_page = nil;
CreatorDesktop.IsExpanded = false;
CreatorDesktop.IsMovie = false
function CreatorDesktop.GetTab()
	return CreatorDesktop.tabview_ds[CreatorDesktop.tabview_index];
end

function CreatorDesktop:OnGameModeChangedNew()
	if(GameLogic.GameMode:GetMode() == "game" and self.IsExpanded) then
		CreatorDesktop.ShowNewPage(false);
	end
end

-- filtering the /show command
-- /show desktop.builder.[static|movie|character|playerbag|gear|deco|tool|template|env]
-- e.g. /show desktop.builder.env
-- @param bShow: true to show, otherwise to hide
function CreatorDesktop.ShowFilter(name, bShow)
	if(name and (GameLogic.GameMode:IsEditor() or GameLogic.GameMode:IsMovieMode())) then
		if(name:match("^desktop%.builder")) then
			local tab = name:match("^desktop%.builder%.(.+)$");
			if(bShow == false) then
				-- hide page
			elseif(tab == "env") then
				CreatorDesktop.tabview_index = 2;
			else
				CreatorDesktop.tabview_index = 1;
				local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");
				if(BuilderFramePage.GetCategoryButtons) then
					local ds = BuilderFramePage.GetCategoryButtons();
					for index, item in ipairs(ds) do
						if(item.name == tab) then
							BuilderFramePage.category_index = index;
						end
					end
				end
			end
			CreatorDesktop.ShowNewPage(bShow~=false);
			return;
		end
	end
	return name;
end

function CreatorDesktop.StaticInit()
	if(CreatorDesktop.isInited) then
		return;
	end
	CreatorDesktop.isInited = true;
	GameLogic.GetFilters():add_filter("show", CreatorDesktop.ShowFilter);
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BuilderFramePage.lua");
	local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");
	BuilderFramePage.OneTimeInit(1);
end

function CreatorDesktop.IsVisible()
	if(CreatorDesktop.new_page and CreatorDesktop.new_page:IsVisible()) then
		return true;
	end
end

-- @param IsExpanded: nil to toggle. true or false to show expanded or not. false by default. 
function CreatorDesktop.ShowNewPage(IsExpanded)
	if(IsExpanded == nil) then
		local isVisible = CreatorDesktop.IsVisible()
		if(isVisible) then
			IsExpanded = not CreatorDesktop.IsExpanded;
			if(IsExpanded) then
				-- do a full collection here
				collectgarbage("collect");
			end
		else
			GameLogic.GetFilters():apply_filters("user_event_stat", "tool", "browse", 1, nil);

			IsExpanded = true;
		end
	end
	if(IsExpanded and not CreatorDesktop.IsMovie) then
		GameLogic.events:AddEventListener("game_mode_change", CreatorDesktop.OnGameModeChangedNew, CreatorDesktop, "CreatorDesktop");
	end

	if(CreatorDesktop.new_page and CreatorDesktop.IsExpanded) then
		local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");
		BuilderFramePage.isSearching = false;
		local search_text_obj = ParaUI.GetUIObject("block_search_text_obj");
		if(search_text_obj:IsValid())then
			search_text_obj:LostFocus();
		end	
	end
	CreatorDesktop.IsExpanded = IsExpanded;

	if(CreatorDesktop.IsExpanded and not CreatorDesktop.IsMovie) then
		GameLogic:desktopLayoutRequested("CreatorDesktop");
	end
	if CreatorDesktop.IsMovie then
		CreatorDesktop.tabview_ds = {
			{text=L"环境", name="env", url="script/apps/Aries/Creator/Game/Areas/EnvFramePage.html?version=1", enabled=true}, -- script/apps/Aries/Creator/Game/Areas/EnvFramePage.html
		}
		CreatorDesktop.tabview_index = 1;
	else
		CreatorDesktop.tabview_ds = {
			{text=L"建造", name="building", url="script/apps/Aries/Creator/Game/Areas/BuilderFramePage.html?version=1", enabled=true}, -- script/apps/Aries/Creator/Game/Areas/BuilderFramePage.html
			{text=L"环境", name="env", url="script/apps/Aries/Creator/Game/Areas/EnvFramePage.html?version=1", enabled=true}, -- script/apps/Aries/Creator/Game/Areas/EnvFramePage.html
		}
	
		-- 处理工具箱(只在二合一世界处理)
		local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
		local world2in1_tool_data = World2In1.GetToolItems()
		if world2in1_tool_data and #world2in1_tool_data > 0 then
			table.insert(CreatorDesktop.tabview_ds, {text=L"世界", name="world", url="script/apps/Aries/Creator/Game/Areas/World2In1FramePage.html?version=1", enabled=true})
		elseif CreatorDesktop.tabview_index == 3 then
			CreatorDesktop.tabview_index = 1;
		end
	end
	--CreatorDesktop.new_page_params or
	CreatorDesktop.new_page_params =  {
			url = "script/apps/Aries/Creator/Game/Areas/NewDesktopPage.html", 
			--url = url,
			name = "CreatorDesktop.ShowNewPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=true, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			-- enable_esc_key = true,
			click_through = true, 
			zorder = -1,
			refresh = true,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = CreatorDesktop.IsMovie and "_rt" or "_ctr",
				x = CreatorDesktop.IsMovie and -240 or 0,
				y = 0,
				width = 240,
				height = 506,
		};
	CreatorDesktop.new_page_params.bShow = IsExpanded;
	System.App.Commands.Call("File.MCMLWindowFrame", CreatorDesktop.new_page_params);

	if(IsExpanded) then
		GameLogic:Connect("desktopLayoutRequested", CreatorDesktop, CreatorDesktop.OnLayoutRequested, "UniqueConnection");
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
	local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
	if(CreatorDesktop.new_page_params._page) then
		CreatorDesktop.new_page_params._page.OnClose = function()
			DesktopMenuPage.ActivateMenu(false);
			if CreatorDesktop.IsMovie then
				CreatorDesktop.IsMovie = false
				CreatorDesktop.IsExpanded = false
				CreatorDesktop.new_page_params.align = "_ctr"
				CreatorDesktop.new_page_params.x = 0
			end
			
		end;
	end
	DesktopMenuPage.ActivateMenu(IsExpanded and not CreatorDesktop.IsMovie);

	GameLogic.events:DispatchEvent({type = "ShowCreatorDesktop" , bShow = IsExpanded});	
end

function CreatorDesktop:OnLayoutRequested(requesterName)
	if(requesterName ~= "CreatorDesktop") then
		if(CreatorDesktop.IsExpanded) then
			CreatorDesktop.ShowNewPage(false);
		end
	end
end

function CreatorDesktop.SetIsMovie(isMovie)
	CreatorDesktop.IsMovie = isMovie
end
