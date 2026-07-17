--[[
Title: EasyBuilder Action Task
Author(s): GitHub Copilot
Date: 2025/09/21
Desc: 

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAction.lua");
local EasyAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAction");
EasyAction:ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityAnimation = commonlib.gettable("MyCompany.Aries.Game.Effects.EntityAnimation");
local EasyAction = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAction"));

local curInstance;
local page;

-- Always a top level task
EasyAction.is_top_level = true;

function EasyAction:ctor()
end

function EasyAction.GetInstance()
    return curInstance;
end

-- follow EditLightTask: keep a static InitPage(Page)
function EasyAction.InitPage(Page)
    page = Page;
    -- populate with current focus entity's animations on open
    EasyAction.RefreshAnimsForFocus();
end

function EasyAction:Redo()
end

function EasyAction:Undo()
end

-- follow EditLightTask lifecycle
function EasyAction:Run()
    curInstance = self;
    self:ShowPage(true);
    local player = EntityManager.GetFocus();
    if player then
        -- support drag and drop to apply skin
        player:SetSkipPicking(false);

        -- switch to third person look ahead camera mode for better fixed view
        GameLogic.RunCommand("/camera -mode ThirdPersonLookAhead");
    end
end

function EasyAction:OnExit()
    EasyAction.Cancel()
end

function EasyAction.Cancel()
    if(curInstance) then
        local self = curInstance;
        self:ShowPage(false);
        self:SetFinished();
        self:CloseWindow();
        curInstance = nil;
        local entity = EntityManager:GetFocus();
        if(entity) then
            entity:SetControlledExternally(false);
            entity:SetSkipPicking(true);
        end
    end
end

function EasyAction:ShowPage(bShow)
    if(not page) then
        local width, height = 360, 600;
        local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAction.html", 
                name = "EasyAction.ShowPage", 
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

function EasyAction:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyAction:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

-- data source for animations list
EasyAction.anims_ds = {}
function EasyAction.GetModelAnimDs()
    return EasyAction.anims_ds;
end

-- facial expressions (copied from ParaLife, skin id pairs)
local face_path = "Texture/Aries/Creator/keepwork/Paralife/expression/"
EasyAction.face_ds = {
    { icon = face_path.."tou1_64x53_32bits.png",  skin = "81007;88002" },
    { icon = face_path.."tou2_64x53_32bits.png",  skin = "81010;88016" },
    { icon = face_path.."tou3_64x53_32bits.png",  skin = "81074;88017" },
    { icon = face_path.."tou4_64x53_32bits.png",  skin = "81004;88013" },
    { icon = face_path.."tou5_64x53_32bits.png",  skin = "81017;88007" },
    { icon = face_path.."tou6_64x53_32bits.png",  skin = "81049;88004" },
    { icon = face_path.."tou7_64x53_32bits.png",  skin = "81007;88008" },
    { icon = face_path.."tou8_64x53_32bits.png",  skin = "81008;88002" },
    { icon = face_path.."tou9_64x53_32bits.png",  skin = "81019;88002" },
    { icon = face_path.."tou10_64x53_32bits.png", skin = "81075;88012" },
    { icon = face_path.."tou11_64x53_32bits.png", skin = "81010;88009" },
    { icon = face_path.."tou12_64x53_32bits.png", skin = "81005;88007" },
    { icon = face_path.."tou13_64x53_32bits.png", skin = "81031;88002" },
    { icon = face_path.."tou14_64x53_32bits.png", skin = "81025;88019" },
    { icon = face_path.."tou15_64x53_32bits.png", skin = "81032;88019" },
    { icon = face_path.."tou16_64x53_32bits.png", skin = "81038;88011" },
    { icon = face_path.."tou17_64x53_32bits.png", skin = "81037;88010" },
    { icon = face_path.."tou18_64x53_32bits.png", skin = "81043;88005" },
    { icon = face_path.."tou19_64x53_32bits.png", skin = "81053;88016" },
    { icon = face_path.."tou20_64x53_32bits.png", skin = "81057;88013" },
    { icon = face_path.."lian1_64x53_32bits.png", skin = "81017;88019" },
    { icon = face_path.."lian2_64x53_32bits.png", skin = "81014;88019" },
    { icon = face_path.."lian5_64x53_32bits.png", skin = "81006;88015" },
}

function EasyAction.GetFaceDs()
    return EasyAction.face_ds;
end

-- Apply a face (skin parts) to current focused human model
function EasyAction.OnSelectFace(id)
    if(not id) then return end
    local face = EasyAction.face_ds[id];
    local entity = EntityManager:GetFocus();
    if(not entity or not face) then return end
    -- only for live model with custom geosets (human)
    if entity.PutOnCustomCharItem and entity:HasCustomGeosets() then
        for skin in string.gmatch(face.skin, "([^;]+)") do
            entity:PutOnCustomCharItem(skin)
        end
    end
end

function EasyAction.OnDragFacialIconEnd(name)
	local index = tonumber(name)
	local face = EasyAction.face_ds[index];
    if(not face) then return end
    
    local results = SelectionManager:MousePickWithFingerSize(false, false, true)

    if results and #results > 0 then
        for _, r in ipairs(results) do
            local entity = r.entity
            if entity and entity.PutOnCustomCharItem and entity:HasCustomGeosets() then
                for skin in string.gmatch(face.skin, "([^;]+)") do
                    entity:PutOnCustomCharItem(skin)
                end
                break;
            end
        end
    end
end

function EasyAction.OnDragAnimButtonEnd(name)
    local id = tonumber(name)
    if(type(id) ~= "number") then return end
    local currentEntity = EntityManager:GetFocus();
    local mainAssetPath = currentEntity:GetMainAssetPath();
    local results = SelectionManager:MousePickWithFingerSize(false, false, true)
    if results and #results > 0 then
        for _, r in ipairs(results) do
            local entity = r.entity
            if entity and entity.PlayMovieFile then
                entity:PlayMovieFile(nil); -- stop any playing movie
            end
            -- only apply to same type of entity as current focus entity
            if entity and entity.SetAnimation and entity:GetMainAssetPath() == mainAssetPath then
                -- entity:SetAnimation(id)
                EasyAction.SetEntityAnim(entity, id)
                break;
            end
        end
    end
end

function EasyAction.SetEntityAnim(entity, id)
    if not entity then return end
    local isCustom = false
    for _, v in ipairs(EasyAction.anims_ds) do
        if v.attr.id == id and v.attr.type == "custom" then
            isCustom = true
            break
        end
    end
    if isCustom then
        local idStr = tostring(id)
        if entity.PlayCustomAnimation then
            entity:PlayCustomAnimation(idStr)
        end
        return
    end
    entity:SetAnimation(id)
end

-- Build animations for current focus entity and bind to UI
function EasyAction.RefreshAnimsForFocus()
    local entity = EntityManager:GetFocus();
    local options = {};
    if(entity and entity.GetMainAssetPath) then
        local assetfile = entity:GetMainAssetPath();
        if(assetfile) then
            assetfile = PlayerAssetFile:GetFilenameByName(assetfile) or assetfile;
            local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
            local attr = ParaXModelAttr:new():initFromAssetFile(assetfile);
            local animations = attr and attr:GetAnimations();
            if(animations) then
                for _, anim in ipairs(animations) do
                    if(anim.animID) then
                        options[#options+1] = { value = anim.animID, text = EntityAnimation.GetAnimTextByID(anim.animID, assetfile) };
                    end
                end
                table.sort(options, function(a,b) return a.value < b.value; end)
            end
        end
    end
    local ds = EasyAction.anims_ds;
    table.clear(ds);
    for i, opt in ipairs(options) do
        ds[i] = { name = "anim", attr = { text = opt.text, id = opt.value } };
    end
    EasyAction.GetCustomActions(ds)
    if(page) then
        page:CallMethod("tvwAnimIds", "DataBind", true);
    end
end

function EasyAction.GetCustomActions(ds)
    local entity = EntityManager:GetFocus();
    if not entity or not entity:HasCustomGeosets() then 
        return 
    end
    local SkinUnLockManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinUnLockManager.lua")
    local allAnimations = PlayerAssetFile:GetAllAnimations()
	if not allAnimations or #allAnimations == 0 then
		return {}
	end
    for k, v in pairs(allAnimations) do
        if SkinUnLockManager.IsUnlocked(v.id) then
            table.insert(ds, 1 ,{name = "anim", attr={id = tonumber(v.id), text = L"(临时)"..(v.displayname or "动作"..tostring(v.id)) ,type="custom"}})
        end
    end
end

-- Handle click: apply animation to current focus entity (no canvas)
function EasyAction.OnSelectAnimId(id)
    id = tonumber(id);
    if(type(id) ~= "number") then return end
    local entity = EntityManager:GetFocus();
    if(entity) then
        if(entity.SetAnimation) then
            -- entity:SetControlledExternally(true)
            entity:SetAnimation(id);
        end
    end
end

function EasyAction.OnClickClose()
    GameLogic.RunCommand("/take -select -bag 3");
end


-- add camera mode switch handler
function EasyAction.OnClickSetCameraMode(name, mcmlNode)
    local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
    if GameLogic and name and name ~= "" then
        GameLogic.RunCommand(string.format("/camera -mode %s", name));
    end
end

function EasyAction.OnStopAnimation()
    local entity = EntityManager:GetFocus();
    if(entity) then
        if(entity.SetAnimation) then
            entity:SetControlledExternally(false)
            entity:SetAnimation(0);
        end
        if entity.PlayMovieFile then
            entity:PlayMovieFile(nil)
        end
    end
end
