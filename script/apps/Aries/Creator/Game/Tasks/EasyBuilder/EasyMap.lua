--[[
Title: EasyBuilder Map Task
Author(s): GitHub Copilot
Date: 2025/09/21
Desc: Easy map and character navigation tool that dynamically loads:
- Teleport points from player position list
- Character entities (EntityLiveModel) found in the world

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMap.lua");
local EasyMap = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyMap");
EasyMap:ShowPage(true)
-- To refresh character data:
EasyMap.RefreshCharacterData()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EasyMap = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyMap"));

local curInstance;
local page;


-- Always a top level task
EasyMap.is_top_level = true;
EasyMap.isLastPlayerFollowTarget = false;
EasyMap.Maps_DS = {};
EasyMap.Chars_DS = {}

-- Get all EntityLiveModel entities whose category is "character"
function EasyMap.GetCharacterEntitiesDS()
    local character_entities = {
        {name = "@player", displayname = "我(当前玩家)", order = 0}
    };
    
    -- Find all EntityLiveModel entities
    local liveModelEntities = EntityManager.FindEntities({
        category = "all",
        type = "LiveModel"
    });
    
    if liveModelEntities then
        for i, entity in ipairs(liveModelEntities) do
            -- if name does not start with a digit, it is a user-created character or it has custom geosets
            local isProperlyNamed = not string.match(entity.name, "^%d");
            if ((entity.category == "character" and isProperlyNamed) or entity:HasCustomGeosets()) then
                local order = 1
                if(entity.category ~= "character") then
                    order = order + 1
                end
                if(not isProperlyNamed) then
                    order = order + 10
                end
                
                character_entities[#character_entities + 1] = {
                    name = entity.name,
                    order = order,
                    displayname = string.len(entity.name) > 16 and  ParaMisc.UniSubString(entity.name, 1, 16) or entity.name,
                };
            end
        end
    end
    table.sort(character_entities, function(a, b) return a.order < b.order; end);
    return character_entities;
end

function EasyMap:ctor()
end

function EasyMap.DS_CharacterItems(index)
    if(index == nil) then
        return #EasyMap.Chars_DS;
    else
        return EasyMap.Chars_DS[index];
    end
end

-- Convert teleport data to Maps_DS format
function EasyMap.GetMapsDS()
    local teleportList = GameLogic.GetHomeEntity() and GameLogic.GetHomeEntity():GetPosList() or {};
    local maps_ds = {};
    
    for i, teleportData in ipairs(teleportList) do
        local displayName = teleportData.name or string.format("传送点 %d", i);
        maps_ds[i] = {
            name = teleportData.position or "0,0,0",
            displayname = displayName,
            position = teleportData.position,
            facing = teleportData.facing,
            scaling = teleportData.scaling
        };
    end
    
    return maps_ds;
end


function EasyMap.DS_MapPositions(index)
    if(index == nil) then
        return #EasyMap.Maps_DS;
    else
        return EasyMap.Maps_DS[index];
    end
end

function EasyMap.OnClickMap(index)
    if(index and EasyMap.Maps_DS[index] and EasyMap.Maps_DS[index].position) then
        local position = EasyMap.Maps_DS[index].position;
        local x, y, z = position:match("([^,]+),([^,]+),([^,]+)");
        x = tonumber(x);
        y = tonumber(y);
        z = tonumber(z);
        
        if(x and y and z) then
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
            local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX=x, blockY=y, blockZ=z});
            task:Run();
            EasyMap.OnClickClose()
        end
    end
end

function EasyMap.OnClickChar(index)
    if(index and EasyMap.Chars_DS[index]) then
        local charData = EasyMap.Chars_DS[index];
        if(charData.name) then
            local entity = charData.name == "@player" and EntityManager.GetPlayer() or EntityManager.GetEntity(charData.name)
            if(EasyMap.PossessChar(entity)) then
                EasyMap.OnClickClose()
            end
        end
    end
end

function EasyMap.PossessChar(entity)
    if(entity) then
        local lastEntity = EntityManager:GetFocus();
        if(entity ~= lastEntity) then
            if(lastEntity) then
                lastEntity:SetControlledExternally(true);
                lastEntity:SetSkipPicking(false);
                lastEntity:SetFollowTarget(nil);
            end
            entity:SetFocus();
            entity:SetControlledExternally(false);
            entity:SetSkipPicking(true);
            entity:SetFollowTarget(nil);
            if(EasyMap.isLastPlayerFollowTarget and lastEntity) then
                lastEntity:SetFollowTarget(entity);
            end
            return true
        end
    end
end

function EasyMap.GetInstance()
    return curInstance;
end

-- follow EditLightTask: keep a static InitPage(Page)
function EasyMap.InitPage(Page)
    page = Page;
end

function EasyMap:Redo()
end

function EasyMap:Undo()
end

-- follow EditLightTask lifecycle
function EasyMap:Run()
    curInstance = self;
    -- Refresh the data from teleport list and character entities each time it's accessed
    EasyMap.Maps_DS = EasyMap.GetMapsDS();
    EasyMap.Chars_DS = EasyMap.GetCharacterEntitiesDS();
    self:ShowPage(true);
end

function EasyMap:OnExit()
    self:ShowPage(false);
    self:SetFinished();
    self:CloseWindow();
    curInstance = nil;
end

function EasyMap:ShowPage(bShow)
    if(not page) then
        local width, height = 800, 450;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMap.html", 
                name = "EasyMap.ShowPage", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                bToggleShowHide=false, 
                style = CommonCtrl.WindowFrame.ContainerStyle,
                enable_esc_key = false,
                allowDrag = false,
                click_through = true, 
                bShow = (bShow ~= false),
                directPosition = true,
                    align = "_lt",
                    x = 20 + Screen:GetSafeAreaLeft(),
                    y = 90,
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

function EasyMap:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyMap:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

function EasyMap.OnClickClose()
    GameLogic.RunCommand("/take -select -bag 3");
end

function EasyMap.OnClickEditTeleportPoints()
    GameLogic.RunCommand("/tp");
end

function EasyMap.OnFollowCharacterChanged()
    if(page) then
        EasyMap.isLastPlayerFollowTarget = page:GetUIValue("FollowCharacter");
    end
end