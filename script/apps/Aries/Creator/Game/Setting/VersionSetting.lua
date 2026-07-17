--[[
Title: Version Setting
Author: pbb  
CreateDate: 2023.09.04
Desc: 
use the lib:
------------------------------------------------------------
local VersionSetting = NPL.load('(gl)script/apps/Aries/Creator/Game/Setting/VersionSetting.lua')
VersionSetting.ShowPage()
------------------------------------------------------------
]]

-- libs
NPL.load('(gl)Mod/WorldShare/cellar/JumpAppStoreDialog/JumpAppStoreDialog.lua');
local JumpAppStoreDialog = commonlib.gettable('Mod.WorldShare.cellar.JumpAppStoreDialog');

local page
local VersionSetting = NPL.export()



function VersionSetting.OnInit()
    page = document:GetPageCtrl()
end

function VersionSetting.ShowPage()
    local view_width = 510
    local view_height = 390
    local params = {
        url = "script/apps/Aries/Creator/Game/Setting/VersionSetting.html",
        name = "VersionSetting.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_ct",
        zorder=10002,
        isTopLevel = true,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    _guihelper.CloseMessageBox(true);
end

function VersionSetting.GetPageTitle()
    local title = L"客户端版本设置"
    return title
end

function VersionSetting.GetRealParaEngineVersion()
    if not VersionSetting.paraEngineVer then
        local verStr = ParaEngine.GetVersion()
        local major,minor = unpack(commonlib.split(verStr,"."))
        VersionSetting.paraEngineVer = verStr
        VersionSetting.paraEngineMajorVer = tonumber(major)
        VersionSetting.paraEngineMinorVer = tonumber(minor)
    end
    return VersionSetting.paraEngineVer,VersionSetting.paraEngineMajorVer,VersionSetting.paraEngineMinorVer
end

function VersionSetting.GetResourceVersion()
    return GameLogic.options.GetClientVersion();
end

function VersionSetting.GetLoginVersion()
    local versionXml = ParaXML.LuaXML_ParseFile('config/Aries/creator/paracraft_script_version.xml');
    local login_version = versionXml[1][1] or "";
    return login_version
end

function VersionSetting.SetEngineVersion()
    if not page then
        return
    end
    local versionStr = page:GetValue("engine_version","")
    if versionStr and versionStr ~= "" then
        System.os.SetParaEngineVersion(versionStr)
        page:Refresh(0.01)
    end

end

function VersionSetting.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
    local Game = commonlib.gettable("MyCompany.Aries.Game")
    if(Game and Game.is_started) then
        return
    end
    if System.options.isPapaAdventure then
        VersionSetting.ShowPapa()       
        return
    end
end

function VersionSetting.OnExitGame()
    local Game = commonlib.gettable("MyCompany.Aries.Game")
    if(Game and Game.is_started) then
        Game.Exit()
        NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
        local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
        CustomCharItems:Init();
    end
end

function VersionSetting.OnConfirmClick()
    VersionSetting.OnExitGame()
    if page then
        page:CloseWindow()
        page = nil
    end
    JumpAppStoreDialog.ignore = false
    System.options.cmdline_world = nil
    if System.options.isPapaAdventure then
        VersionSetting.UpdatePapaVersion()
        return
    end
    MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
    MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
end

function VersionSetting.UpdatePapaVersion()
    if (not System.os.CompareParaEngineVersion('1.5.1.0')) then
        local jumpUrl = MyCompany.Aries.Game.MainLogin:GetDownLoadUrl();
        if (not JumpAppStoreDialog.ignore) then
            JumpAppStoreDialog.style = 2;
            JumpAppStoreDialog.ignoreCallback = VersionSetting.ShowPapa
            JumpAppStoreDialog.Show(0, 0, jumpUrl);
            return;
        end
    end
    VersionSetting.ShowPapa()
end

function VersionSetting.ShowPapa()
    NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAPI.lua");
    local PapaAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.PapaAPI");
    PapaAPI:SetDisplayMode("show")
end



