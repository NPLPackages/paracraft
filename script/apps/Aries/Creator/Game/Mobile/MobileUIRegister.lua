
--[[
    author:hyz
    time:2022-11-3
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileUIRegister.lua")
        local MobileUIRegister = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileUIRegister");
        MobileUIRegister.SetMobileUIEnable(true)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileMainPage.lua")
local MobileMainPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileMainPage");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local MobileUIRegister = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileUIRegister")

MobileUIRegister._mobileUIEnabled = false;
if System.options.IsTouchDevice then
    MobileUIRegister._mobileUIEnabled = true
end

function MobileUIRegister.GetIsDevMode()
    -- return System.os.GetPlatform()=="win32" and System.options.isDevMode
    return true
end

function MobileUIRegister.SetMobileUIEnable(enabled)
    if not bInitOnce then
        bInitOnce = true 
        GameLogic.GetFilters():add_filter("MobileUIRegister.IsMobileUIEnabled",MobileUIRegister.OnIsMobileUIEnabled)
    end
    MobileUIRegister._mobileUIEnabled = enabled
    GameLogic.GetFilters():remove_filter("GetUIPageHtmlParam",MobileUIRegister.OnGetUIPageHtmlParam)
    GameLogic.GetFilters():remove_filter("SystemSettingsPage.CheckBoxBackground",MobileUIRegister.OnSystemSettingsPageUpdateCheckBox)

    if MobileUIRegister._mobileUIEnabled then
        GameLogic.GetFilters():add_filter("GetUIPageHtmlParam",MobileUIRegister.OnGetUIPageHtmlParam)
        GameLogic.GetFilters():add_filter("SystemSettingsPage.CheckBoxBackground",MobileUIRegister.OnSystemSettingsPageUpdateCheckBox)
    end

    MobileMainPage.ShowPage(enabled)
    
    MobileUIRegister.UpdateUI()
    if(System.options.IsTouchDevice) then
		local TouchVirtualKeyboardIcon = GameLogic.GetFilters():apply_filters("TouchVirtualKeyboardIcon");
		if not TouchVirtualKeyboardIcon then
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboardIcon.lua");
			TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon");
		end

		TouchVirtualKeyboardIcon.ShowSingleton(not enabled);
	end

    if enabled then
        NPL.load("(gl)script/mobile/paracraft/Areas/SystemMenuPage.lua");
        local SystemMenuPage = commonlib.gettable("ParaCraft.Mobile.Desktop.SystemMenuPage");
        SystemMenuPage.ClosePage()
    end
end

function MobileUIRegister.UpdateUI()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
    local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
    if  EditModelTask.GetInstance() then
        EditModelTask.GetInstance():CloseWindow();
        EditModelTask.GetInstance():ShowPage()
    end

    if QuickSelectBar.IsVisible() then
        QuickSelectBar.ShowPage(false)
        QuickSelectBar.ShowPage(true)
    end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectColor/SelectColor.lua");
    local SelectColor = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectColor");
    if SelectColor.GetInstance() then
        SelectColor.GetInstance():CloseWindow();
        SelectColor.GetInstance():ShowPage()
    end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/TerrainBrushTask.lua");
	local TerrainBrushTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.TerrainBrushTask");
    if TerrainBrushTask.GetInstance() then
        TerrainBrushTask.GetInstance():CloseWindow();
        TerrainBrushTask.GetInstance():ShowPage()
    end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BoneBlock/SelectBone.lua");
    local SelectBone = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBone");
    if SelectBone.GetInstance() then
        SelectBone.GetInstance():CloseWindow();
        SelectBone.GetInstance():ShowPage()
    end
end

function MobileUIRegister.OnIsMobileUIEnabled()
    return MobileUIRegister._mobileUIEnabled
end

function MobileUIRegister.OnGetUIPageHtmlParam(params,pageName)
    if not MobileUIRegister._mobileUIEnabled then
        return params
    end
    
    if pageName=="SystemSettingsPage" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/SystemSettingsPage.mobile.html"
        params.x = -574/2
        params.y = -686/2
        params.width = 574
        params.height = 686
        params.withBgMask = true
    elseif pageName=="SelectBlocksTask" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/MobileSelectBlocksTask.html"
        params.align = "_ctt"
        params.y = -3
        params.width = 629
        params.height = 103
        params.allowDrag = false
    elseif pageName=="EscFramePage" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/MobileEscFramePage.html"
        params.x = -904/2
        params.y = -496/2
        params.width = 904
        params.height = 496
        params.withBgMask = true
    elseif pageName == "TransformWnd" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/MobileTransformWnd.html"
        params.align = "_ctt"
        params.x = 0
        params.y = -3
        params.width = 651
        params.height = 103
        params.allowDrag = false
    elseif pageName == "MirrorWnd" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/MobileMirrorWnd.html"
        params.align = "_ctt"
        params.x = 0
        params.y = -3
        params.width = 760
        params.height = 103
        params.zorder = 1
        params.allowDrag = false
    elseif pageName == "CreateNewWorld" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/MobileCreateNewWorld.html"
        params.align = "_ct"
        params.x = -800/2
        params.y = -642/2
        params.width = 800
        params.height = 642
        params.withBgMask = true
    elseif pageName == "ExportTask" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/MobileExportTask.html"
        params.align = "_ct"
        params.x = -1072/2
        params.y = -680/2
        params.width = 1072
        params.height = 680
        params.withBgMask = true
    elseif pageName=="ChangeTexturePage" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/ChangeTexturePage.mobile.html"
        params.x = -1080/2
        params.y = -694/2
        params.width = 1080
        params.height = 694
        params.withBgMask = true
        params.bgMaskOpacity = 0.5
    elseif pageName=="QuickSelectBar" then
        params.width = 900
        params.height = 150
        params.url = "script/apps/Aries/Creator/Game/Areas/QuickSelectBar.mobile.html"
        params.isMobile = MobileUIRegister._mobileUIEnabled == true
    elseif pageName == "InventoryPage" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/MobileInventoryPage.html"
        params.zorder = 2
        params.x = -816/2
        params.DestroyOnClose = true
        params.y = -720/2
        params.width = 816
        params.height = 720
        params.click_through = false
        params.allowDrag = false
        params.withBgMask = true
    elseif pageName == "MovieClipTimeLine" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/MovieClipTimeLine.mobile.html"
    elseif pageName == "MovieClipController" then
        params.url = "script/apps/Aries/Creator/Game/Mobile/MovieClipController.mobile.html"
        params.width = 293
        params.height = 380
        params.x = -params.width-20
        params.y = -params.height - 252        
    end

    params.DesignResolutionWidth = 1280
    params.DesignResolutionHeight = 720
    return params
end

function MobileUIRegister.OnSystemSettingsPageUpdateCheckBox(page, name, bChecked)
    if not MobileUIRegister._mobileUIEnabled then
        return nil
    end
    if(page) then
		bChecked = bChecked == true or bChecked == "true";
        
		page:CallMethod(name, "SetUIBackground", bChecked and "Texture/Aries/Creator/keepwork/Mobile/SystemsSetting/switch_on_240x50_32bits.png#0 0 240 50" or "Texture/Aries/Creator/keepwork/Mobile/SystemsSetting/switch_off_240x50_32bits.png#0 0 242 50");
		page:CallMethod(name.."_textOn", "SetUIColor",bChecked and "#000000" or "#ffffff")
		page:CallMethod(name.."_textOff", "SetUIColor",bChecked and "#ffffff" or "#000000")
        
        -- local _textOn = ParaUI.GetUIObject(name.."_textOn")
		-- local _textOff = ParaUI.GetUIObject(name.."_textOff")
        
        -- GameLogic.AddBBS(nil,"_textOn~=nil:"..tostring(_textOn~=nil))
        -- _textOn:SetCurrentState("normal");
        -- _textOn:GetFont("text").color = _guihelper.ConvertColorToRGBAString(color);

        -- -- _guihelper.SetFontColor(_textOn, bChecked and "#000000" or "#ffffff");
        -- _guihelper.SetFontColor(_textOff, bChecked and "#ffffff" or "#000000");
	end
    return false
end

function MobileUIRegister.GetMobileUIEnabled()
    return MobileUIRegister._mobileUIEnabled
end