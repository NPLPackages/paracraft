--[[
Title: EasyBuilder Char Task
Author(s): GitHub Copilot
Date: 2025/09/21
Desc: 

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyChar.lua");
local EasyChar = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyChar");
EasyChar:ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EasyCharPreview = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCharPreview.lua")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EasyChar = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyChar"));

local curInstance;
local page;

-- Always a top level task
EasyChar.is_top_level = true;

function EasyChar:ctor()
end

function EasyChar.GetInstance()
    return curInstance;
end


function EasyChar.OnInit()
    page = document:GetPageCtrl();
end

function EasyChar:Redo()
end

function EasyChar:Undo()
end

-- follow EditLightTask lifecycle
function EasyChar:Run()
    curInstance = self;
    self:ShowPage(true);
end

function EasyChar:OnExit()
    self:ShowPage(false);
    self:SetFinished();
    self:CloseWindow()
    curInstance = nil;
end

function EasyChar:ShowPage(bShow)
    if not self:CheckShow() then
        GameLogic.AddBBS(nil,L"当前角色不存在，或者不支持换装")
        return
    end
    if(not page) then
        local width, height = 420, 630;
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyChar.html", 
            name = "EasyChar.ShowPage", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            bToggleShowHide=false, 
            style = CommonCtrl.WindowFrame.ContainerStyle,
            enable_esc_key = false,
            allowDrag = false,
            click_through = true, 
            bShow = (bShow ~= false),
            directPosition = true,
            align = "_rt",
            x = -width,
            y = 64,
            width = width,
            height = height,
        };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
        curInstance = curInstance or self;
        if(params._page) then
            params._page.OnClose = function()
                page = nil;
            end
        end
    else
        if(bShow == false) then
            page:CloseWindow();
        else
            page:Refresh(0.1);
        end
    end
end

function EasyChar:CheckShow()
    local focus_entity = EntityManager.GetFocus();
    if not focus_entity then
        return false
    end
    if not focus_entity:HasCustomGeosets() then
        return false
    end
    return true
end

function EasyChar:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyChar:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

function EasyChar.OnClickClose()
    GameLogic.RunCommand("/take -select -bag 3");
    EasyCharPreview.Close()
end

function EasyChar:handleLeftClickScene(event, result)
end

function EasyChar:IsVisible()
    return page and page:IsVisible()
end

function EasyChar:SetPlayerSkin(mainSkin,oldSkin,curSkinItems)
    if not mainSkin or mainSkin== "" then
        return
    end
    if not self:IsVisible() then
        return
    end

    if EasyCharPreview.IsVisible() then
        EasyCharPreview.SetSkinItems(curSkinItems)
    else
        EasyCharPreview.Show(curSkinItems)
    end
end