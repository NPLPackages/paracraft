--[[
Title: JumpAppStoreDialog
Author(s): huangyz, big
CreateDate: 2022.10.20
ModifyDate: 2023.03.04
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/Update/JumpAppStoreDialog.lua");
local JumpAppStoreDialog = commonlib.gettable("MyCompany.Aries.Game.Login.Update.JumpAppStoreDialog");
-------------------------------------------------------
]]

local JumpAppStoreDialog = commonlib.gettable("MyCompany.Aries.Game.Login.Update.JumpAppStoreDialog");
local page;

function JumpAppStoreDialog:OnInit()
    page = document:GetPageCtrl();
end

function JumpAppStoreDialog.Show(latestVer,curVer,jumpUrl)
    JumpAppStoreDialog._jumpUrl = jumpUrl or "https://www.paracraft.cn/download";

    System.App.Commands.Call(
        "File.MCMLWindowFrame",
        {
            url = format("script/apps/Aries/Creator/Game/Login/Update/JumpAppStoreDialog.html?latestVersion=%s&curVersion=%s", latestVer, curVer), 
            name = "JumpAppStoreDialog", 
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 1,
            allowDrag = false,
            isTopLevel = true,
            directPosition = true,
            align = "_ct",
            x = -210,
            y = -100,
            width = 420,
            height = 250,
        }
    );

    JumpAppStoreDialog._isDownloadFinished = false;
end

function JumpAppStoreDialog.OnClickUpdate()
    if (System.os.GetPlatform() == "mac") then
        ParaGlobal.ShellExecute("open", JumpAppStoreDialog._jumpUrl, "", "", 1);
    else
        ParaGlobal.ShellExecute("openExternalBrowser", JumpAppStoreDialog._jumpUrl, "", "", 1);
    end
end

return JumpAppStoreDialog;