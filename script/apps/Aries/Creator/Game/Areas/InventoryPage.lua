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
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
	local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
	local bActivateMenu = true;
	if(page and page:IsVisible()) then
		bActivateMenu = false;
	end
	DesktopMenuPage.ActivateMenu(bActivateMenu and not IsMobileUIEnabled);
	
	if IsMobileUIEnabled then
		InventoryPage.GetProfile()
	end
	local params = customParams or {
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
	params =  GameLogic.GetFilters():apply_filters('GetUIPageHtmlParam',params,"InventoryPage");
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		DesktopMenuPage.ActivateMenu(false);
	end;
end

function InventoryPage.GetProfile()
	local function handle()
		InventoryPage.RefreshPage()
	end
	if InventoryPage.profile == nil then
		local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
		local profile = KeepWorkItemManager.GetProfile()
		if (profile.username == nil or profile.username == "") then
		    KeepWorkItemManager.LoadProfile(true, function(err, msg, data)
		        if(err ~= 200)then
		            return
		        end
		        if data.username and data.username ~= "" then
					InventoryPage.profile = profile
		           handle()
		        end
		    end)
		else    
		    InventoryPage.profile = profile
		    handle()
		end
	else
		handle()
	end
end

function InventoryPage.GetUserName()
	if InventoryPage.profile then
		return InventoryPage.profile.username
	end
end

function InventoryPage.GetNickName()
	if InventoryPage.profile then
		return InventoryPage.profile.nickname
	end
end

function InventoryPage.GetSchoolName()
	if InventoryPage.profile and InventoryPage.profile.school then
		return InventoryPage.profile.school.name
	end
	return ""
end

function InventoryPage.RefreshPage()
	if page then
		page:Refresh(0)
	end
end

