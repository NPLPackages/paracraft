--[[
Title: inventory
Author(s): LiPeng, LiXizhi
Date: 2013/10/15
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InventoryPage.lua");
local InventoryPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InventoryPage");
InventoryPage.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local InventoryPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InventoryPage");

local page;
InventoryPage.modifyName = false;

function InventoryPage.OnInit()
	page = document:GetPageCtrl();
	if(page) then
		page.OnClose = function ()
			InventoryPage.modifyName = false;
		end
	end
	GameLogic.events:AddEventListener("OnHandToolIndexChanged", InventoryPage.OnHandToolIndexChanged, InventoryPage, "InventoryPage");
end

function InventoryPage.OnInitMobile()
	page = document:GetPageCtrl();
end

function InventoryPage.OneTimeInit()
	if(InventoryPage.is_inited) then
		return;
	end
	InventoryPage.is_inited = true;
	-- TODO: 
end

function InventoryPage:OnHandToolIndexChanged(event)
	if(page) then
		local ctl = page:FindControl("handtool_highlight_bg");
		if(ctl) then
			ctl.x = (GameLogic.GetPlayerController():GetHandToolIndex()-1)*40+3;
		end
	end
end

function InventoryPage.GetPlayerDisplayName()
	local player = EntityManager.GetPlayer()
	if(player) then
		local name = player:GetDisplayName();
		if(name) then
			return name;
		end
	end
end

function InventoryPage.SetPlayerDisplayName()
	local player = EntityManager.GetPlayer()
	if(player) then
		local obj = ParaUI.GetUIObject("inventory_player_displayname");
		local displayname = obj.text;
		player:SetDisplayName(displayname);
	end
end

function InventoryPage.ShowPage()
	if(InventoryPage.last_player ~= EntityManager.GetPlayer()) then
		InventoryPage.last_player = EntityManager.GetPlayer();
		if(page) then
			-- destroy the previous window if player has changed
			page:CloseWindow(true);
		end
	end

	if(System.options.IsMobilePlatform) then
		local params = {
			url = "script/apps/Aries/Creator/Game/Areas/InventoryPage.mobile.html", 
			name = "InventoryPage.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = false,
			bToggleShowHide=true, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			--bShow = bShow,
			click_through = true, 
			zorder = -1,
			directPosition = true,
				align = "_ct",
				x = -940/2,
				y = -610/2,
				width = 920,
				height = 542,
		};
		System.App.Commands.Call("File.MCMLWindowFrame", params);
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
		local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
		local bActivateMenu = true;
		if(page and page:IsVisible()) then
			bActivateMenu = false;
		end
		DesktopMenuPage.ActivateMenu(bActivateMenu);

		local params = {
			url = "script/apps/Aries/Creator/Game/Areas/InventoryPage.html", 
			name = "InventoryPage.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = false,
			enable_esc_key = true,
			bToggleShowHide=true, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = -3,
			allowDrag = true,
			click_through = true,
			directPosition = true,
				align = "_ct",
				x = -430/2,
				y = -460/2,
				width = 430,
				height = 460,
		};
		System.App.Commands.Call("File.MCMLWindowFrame", params);

		params._page.OnClose = function()
			DesktopMenuPage.ActivateMenu(false);
		end;
	end
	
end

