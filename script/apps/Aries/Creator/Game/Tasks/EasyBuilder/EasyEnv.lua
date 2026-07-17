--[[
Title: EasyBuilder Env Task
Author(s): GitHub Copilot
Date: 2025/09/21
Desc: 

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEnv.lua");
local EasyEnv = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEnv");
EasyEnv:ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EasyEnv = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEnv"));

local curInstance;
local page;

-- Always a top level task
EasyEnv.is_top_level = true;

function EasyEnv:ctor()
end

function EasyEnv.GetInstance()
    return curInstance;
end

-- follow EditLightTask: keep a static InitPage(Page)
function EasyEnv.InitPage(Page)
    page = Page;
end

function EasyEnv:Redo()
end

function EasyEnv:Undo()
end

-- follow EditLightTask lifecycle
function EasyEnv:Run()
    curInstance = self;
    self:ShowPage(true);
end

function EasyEnv:OnExit()
    self:ShowPage(false);
    self:SetFinished();
    self:CloseWindow();
    curInstance = nil;
end

function EasyEnv:ShowPage(bShow)
    if(not page) then
        local width, height = 300, 600;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEnv.html", 
                name = "EasyEnv.ShowPage", 
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
                    x = -width-20,
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

function EasyEnv:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyEnv:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end


function EasyEnv:handleLeftClickScene(event, result)
end

function EasyEnv.OnClickClose()
    if curInstance then
        curInstance:OnExit();
    end
    GameLogic.RunCommand("/take -select -bag 3");
end