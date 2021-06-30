--[[
Title: InvalidKeyPage
Author(s): yangguiyi
Date: 2020/9/2
Desc:  
Use Lib:
-------------------------------------------------------
local InvalidKeyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/InvalidKeyPage.lua");
InvalidKeyPage.Show();
--]]
local WorldKeyManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyManager.lua")
local InvalidKeyPage = NPL.export();
local page;
local DateTool = os.date
InvalidKeyPage.Current_Item_DS = {};
local UserData = {}
local FollowList = {}
local SearchIdList = {}

function InvalidKeyPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = InvalidKeyPage.CloseView
end

function InvalidKeyPage.Show(world_data)
    InvalidKeyPage.world_data = world_data

    local att = ParaEngine.GetAttributeObject();
    local oldsize = att:GetField("ScreenResolution", {1280,720});

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/WorldKey/InvalidKeyPage.html",
        name = "InvalidKeyPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -400/2,
        y = -180/2,
        width = 400,
        height = 180,
    };
        
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function InvalidKeyPage.Paste()
    local text = ParaMisc.GetTextFromClipboard() or "";
    page:SetValue("key_text", text)
end

function InvalidKeyPage.CloseView()
    -- body
end

function InvalidKeyPage.WriteOff()
    local key = page:GetValue("key_text")
    if key == nil or key == "" then
        GameLogic.AddBBS(nil, L"请输入激活码", 3000, "255 0 0")
        return
    end
    WorldKeyManager.AddInvalidKey(key, InvalidKeyPage.world_data, function()
        if page then
            page:CloseWindow(0)
            InvalidKeyPage.CloseView()
        end
    end)
end