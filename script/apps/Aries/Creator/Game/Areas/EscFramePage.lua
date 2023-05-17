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
	GameLogic:Connect("WorldUnloaded", EscFramePage, EscFramePage.OnWorldUnloaded, "UniqueConnection");
end

function EscFramePage.OnWorldUnloaded()
	if page then
		page:CloseWindow()
	end
	GameLogic:Disconnect("WorldUnloaded", EscFramePage, EscFramePage.OnWorldUnload);
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

function EscFramePage.IsVisible()
	return page and page:IsVisible()
end

function EscFramePage.ShowPage(bShow)
    GameLogic.GetFilters():apply_filters("OnShowEscFrame", bShow);
    if (System.options.IsMobilePlatform) then
        EscFramePage.ShowPage_Mobile()
    else
        local isCustomShow = GameLogic.GetFilters():apply_filters('EscFramePage.ShowPage', false, bShow)
        if not isCustomShow then
            NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
            NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileUIRegister.lua")
            local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
            local MobileUIRegister = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileUIRegister");
            local isMobile = MobileUIRegister.GetMobileUIEnabled()
            if isMobile then
                EscFramePage.GetProfile()
            end
            local bActivateMenu = true;
            if (bShow ~= false) then
                if (EscFramePage.IsVisible()) then
                    bActivateMenu = false;
                end
                DesktopMenuPage.ActivateMenu(bActivateMenu);
            end
            local width, height = 390, 350
            EscFramePage.bForceHide = bShow == false;
            local url = "script/apps/Aries/Creator/Game/Areas/EscFramePage.html"
            if System.options.channelId_431 then
                url = "script/apps/Aries/Creator/Game/Educate/Other/EscFramePage.431.html"
            elseif System.options.isPapaAdventure then
                url = "script/apps/Aries/Creator/Game/Areas/EscFrameTutorialPage.html"
                width, height = 500, 340
            end
            local params = {
                url = url,
                name = "EscFramePage.ShowPage",
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide = true,
                style = CommonCtrl.WindowFrame.ContainerStyle,
                allowDrag = false,
                enable_esc_key = true,
                bShow = bShow,
                click_through = false,
                zorder = 10,
                -- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
                directPosition = true,
                align = "_ct",
                x = -width / 2,
                y = -height / 2,
                width = width,
                height = height
                -- DesignResolutionWidth = 1280,
                -- DesignResolutionHeight = 720,
            };
            params = GameLogic.GetFilters():apply_filters('GetUIPageHtmlParam', params, "EscFramePage");
            System.App.Commands.Call("File.MCMLWindowFrame", params);
            if (bShow ~= false) then
                params._page.OnClose = function()
                    if (not EscFramePage.bForceHide) then
                        GameLogic.GetFilters():apply_filters("OnEscFrameClose");
                        DesktopMenuPage.ActivateMenu(false);
                        page = nil
                    end
                end;
            end
        end
    end
end

function EscFramePage.GetProfile()
	local function handle()
		if(page) then
			page:Refresh(0.01);
		end
	end
	if EscFramePage.profile == nil then
		local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
		local profile = KeepWorkItemManager.GetProfile()
		if (profile.username == nil or profile.username == "") then
		    KeepWorkItemManager.LoadProfile(true, function(err, msg, data)
		        if(err ~= 200)then
		            return
		        end
		        if data.username and data.username ~= "" then
					EscFramePage.profile = data
		           handle()
		        end
		    end)
		else    
		    EscFramePage.profile = profile
		    handle()
		end
	else
		handle()
	end
end

function EscFramePage.GetUserName()
	if EscFramePage.profile then
		return EscFramePage.profile.username
	end
end

function EscFramePage.GetNickName()
	if EscFramePage.profile then
		return EscFramePage.profile.nickname
	end
end

function EscFramePage.GetSchoolName()
	if EscFramePage.profile and EscFramePage.profile.school then
		return EscFramePage.profile.school.name
	end
	return ""
end