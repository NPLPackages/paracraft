--[[
Title: Esc Frame Page
Author(s): LiXizhi
Date: 2013/10/15
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EscFramePage.lua");
local EscFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EscFramePage");
EscFramePage.ShowPage(true)
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
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local EscFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EscFramePage");

local page;
EscFramePage.newVersion = true;

EscFramePage.category_index = 1;
EscFramePage.Current_Item_DS = {};

EscFramePage.category_ds = {
    {text="系统设定", name="setting", tooltip=""},
	{text="继续游戏", name="resume", tooltip="快捷键: Esc键"},
    --{text="设置", name="settings", tooltip=""},
}

function EscFramePage.OnInit()
	EscFramePage.OneTimeInit();
	page = document:GetPageCtrl();

	EscFramePage.OnChangeCategory(nil, false);
end

function EscFramePage.OneTimeInit()
	if(EscFramePage.is_inited) then
		return;
	end
	EscFramePage.is_inited = true;
end

-- clicked a block
function EscFramePage.OnClickBlock(block_id)
end

-- @param bRefreshPage: false to stop refreshing the page
function EscFramePage.OnChangeCategory(index, bRefreshPage)
    index = index or EscFramePage.category_index;
	
	local category = EscFramePage.category_ds[index];
	if(category) then
		if(category.name == "resume") then
			page:CloseWindow();
			return;
		end
	end
	EscFramePage.category_index = index;
    
	if(bRefreshPage~=false and page) then
		page:Refresh(0.01);
	end
end

function EscFramePage.ShowPage_Mobile()
	GameLogic.RunCommand("/menu file.exit");
end

function EscFramePage.ShowPage(bShow)
	if(System.options.IsMobilePlatform) then
		EscFramePage.ShowPage_Mobile()
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
		local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
			
		local bActivateMenu = true;
		if(bShow ~= false) then
			if(page and page:IsVisible()) then
				bActivateMenu = false;
			end
			DesktopMenuPage.ActivateMenu(bActivateMenu);
		end
		EscFramePage.bForceHide = bShow == false;

		local params = {
				url = "script/apps/Aries/Creator/Game/Areas/EscFramePage.html", 
				name = "EscFramePage.ShowPage", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				bToggleShowHide=true, 
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = false,
				enable_esc_key = true,
				bShow = bShow,
				click_through = false, 
				zorder = -1,
				app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
				directPosition = true,
					align = "_ct",
					x = -300/2,
					y = -300/2,
					width = 300,
					height = 350,
			};
		System.App.Commands.Call("File.MCMLWindowFrame", params);
		if(bShow ~= false) then
			params._page.OnClose = function()
				if(not EscFramePage.bForceHide) then
					DesktopMenuPage.ActivateMenu(false);
				end
			end;
		end
	end
end