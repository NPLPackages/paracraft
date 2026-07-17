--[[
Title: Costume Inventory
Author: pbb
Date: 2025-04-08
Desc: 简化的皮肤预览界面，用于预览和穿戴选中的皮肤
Use Lib:
    local CostumeInventory = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/CostumeInventory.lua")
    CostumeInventory.Show(selectedSkinItem)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local SkinManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinManager.lua")

local CostumeInventory = NPL.export()

local page
local currentSkinItems

-- 初始化
function CostumeInventory.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = CostumeInventory.UpdatePreviewCharacter
end

function CostumeInventory.IsSelectMainPlayer()
    local playerEntity = GameLogic.GetPlayer();
    return CostumeInventory.selectEntity == playerEntity
end

-- 显示服装预览界面
-- @param skinItems: 皮肤物品数据
-- @param targetEntity: 目标实体，nil表示使用焦点实体
function CostumeInventory.Show(skinItems, targetEntity)
    local playerEntity = GameLogic.GetPlayer();
    local focusEntity = targetEntity or GameLogic.EntityManager.GetFocus();
    
    if focusEntity and focusEntity:HasCustomGeosets() then
        playerEntity = focusEntity
    end
    CostumeInventory.mainAssets = playerEntity and playerEntity:GetMainAssetPath()
    if CustomCharItems:CheckReplaceAsset(CostumeInventory.mainAssets) then
        CostumeInventory.mainAssets = CustomCharItems.defaultModelFile
    end
    local playerSkin = playerEntity and playerEntity:GetSkin()
    CostumeInventory.preSkin = playerSkin
	CostumeInventory.mainSkin = playerSkin
    CostumeInventory.selectEntity = playerEntity
    if skinItems and type(skinItems) == "table" then
        CostumeInventory.mainSkin = CostumeInventory.GetNewSkin(skinItems)
    end
    local view_width = 260
    local view_height = 400
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MiniGame/CostumeInventory.html",
        name = "CostumeInventory.Show",
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = true,
        enable_esc_key = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        zorder = 0,
        directPosition = true,
        click_through = false,
        align = "_rt",
        x = -view_width - 420 - 20,
        y = 20,
        width = view_width,
        height = view_height,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
    }
    
    System.App.Commands.Call("File.MCMLWindowFrame", params)
    
end

function CostumeInventory.IsVisible()
    return page and page:IsVisible()
end

function CostumeInventory.RefreshPage()
    if page then
        page:Refresh(0.01)
    end
end

-- 关闭界面
function CostumeInventory.Close()
    if page then
        page:CloseWindow()
        page = nil
    end
    CostumeInventory.currentSkinItems = nil
end

-- 应用多个挂件到实际角色
function CostumeInventory.ApplySkinsToPlayer()
    if CostumeInventory.preSkin and CostumeInventory.mainSkin and CostumeInventory.preSkin == CostumeInventory.mainSkin then
        GameLogic.AddBBS(nil,L"皮肤未更新")
        CostumeInventory.Close()
        return --当前皮肤没有更改
    end
    if not CostumeInventory.IsSelectMainPlayer() then
        if CostumeInventory.selectEntity then
            CostumeInventory.selectEntity:SetMainAssetPath(CostumeInventory.mainAssets);
		    CostumeInventory.selectEntity:SetSkin(CostumeInventory.mainSkin); 
            CostumeInventory.Close()
        end
        return
    end
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    local playerEntity = GameLogic.GetPlayerController():GetPlayer();
	if playerEntity then
		playerEntity:SetMainAssetPath(CostumeInventory.mainAssets);
		playerEntity:SetSkin(CostumeInventory.mainSkin); 
	end
    local userId = Mod.WorldShare.Store:Get('user/userId') or ''
    if userId == ""  then
        GameLogic.AddBBS(nil,L"用户不存在")
        CostumeInventory.Close()
        return
    end
	local id = "kp" .. System.Encoding.base64(commonlib.Json.Encode({userId=userId}));
	keepwork.user.getinfo({
		cache_policy = "access plus 10 seconds",
        router_params = {
            id = id,
        }
    },function (err, msg, data)
		if err == 200 and data then
            GameLogic.options:SetMainPlayerAssetName(CostumeInventory.mainAssets);
            GameLogic.options:SetMainPlayerSkins(CostumeInventory.mainSkin);
            local extra = data.extra or {};
            extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
            extra.ParacraftPlayerEntityInfo.skin = CostumeInventory.mainSkin;
            extra.ParacraftPlayerEntityInfo.assetSkinGoodsItemId = 0;
            GameLogic.GetFilters():apply_filters("user_skin_change", CostumeInventory.mainSkin);
            keepwork.user.setinfo({
                router_params = {id = userId},
                extra = extra,
            }, function(status, msg, data) 
                CostumeInventory.Close()
                if (status < 200 or status >= 300) then 
                    GameLogic.AddBBS(nil,"更新失败") 
                    return 
                end
                local userinfo = KeepWorkItemManager.GetProfile();
                userinfo.extra = extra;
                GameLogic.AddBBS(nil,"更新成功") 
            end);
		end
	end)
end

-- 点击旋转
function CostumeInventory.OnClickRotate(direction)
    if not page or not direction then
        return
    end
	local rotate = direction == "left" and -5 or 5
	local ctlName = "CostumePreviewPlayer"
	local module_ctl = page:FindControl(ctlName)
	if not module_ctl then
		return
	end
	local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
	if scene and scene:IsValid() then
		local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
		fRotY = fRotY+ rotate * 0.1
		scene:CameraSetEyePosByAngle(fRotY, fLiftupAngle, fCameraObjectDist);
	end
end



-- 更新预览角色
function CostumeInventory.UpdatePreviewCharacter()
    if not page then
        return
    end
    
    local ctlName = "CostumePreviewPlayer"
    local module_ctl = page:FindControl(ctlName)
    if not module_ctl then
        return
    end
    
    if CostumeInventory.mainAssets and CostumeInventory.mainAssets ~= "" then
		page:CallMethod(ctlName, "SetAssetFile", CostumeInventory.mainAssets);
	end
	if CostumeInventory.mainSkin and CostumeInventory.mainSkin ~= "" then
		page:CallMethod(ctlName, "SetCustomGeosets", CostumeInventory.mainSkin)
	end

    -- 设置角色姿态
    local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName)
    if scene and scene:IsValid() then
        local objPlayer = scene:GetObject(module_ctl.obj_name)
        if objPlayer then
            objPlayer:SetFacing(1.57)
            objPlayer:SetField("HeadUpdownAngle", 0.2)
            objPlayer:SetField("HeadTurningAngle", 0)
        end
    end
end


-- 批量设置挂件
function CostumeInventory.SetSkinItems(skinItems)
    if not skinItems or type(skinItems) ~= "table" then
        return false
    end
    CostumeInventory.mainSkin = CostumeInventory.GetNewSkin(skinItems)
    CostumeInventory.RefreshPage()
end

function CostumeInventory.GetNewSkin(skinItems)
    if not skinItems or type(skinItems) ~= "table" then
        return
    end
    CostumeInventory.currentSkinItems = skinItems
    local skinId = skinItems.id
    local suitItem = SkinManager.GetBagManager().GetSuitItemInfo(skinId)
    if suitItem then
        return suitItem.skin
    end
    local needAddItem = CustomCharItems:GetItemById(skinId);
    if needAddItem then
        return CustomCharItems:AddItemToSkin(CostumeInventory.mainSkin, needAddItem)
    end
end

function CostumeInventory.RemoveSkinsFromPlayer()
    if type(CostumeInventory.currentSkinItems) ~= "table" then
        return
    end
    local skinItems = CostumeInventory.currentSkinItems
    local skinId = skinItems.id
    local suitItem = SkinManager.GetBagManager().GetSuitItemInfo(skinId)
    if suitItem then
        local suitSkin = suitItem.skin
        local skinIds = commonlib.split(suitSkin, ";")
        local curSkinIds = commonlib.split(CostumeInventory.mainSkin, ";")
        local suitMaps = {}
        for _, id in ipairs(skinIds) do
            suitMaps[id] = true
        end
        local newSkin = ""
        for _, id in ipairs(curSkinIds) do
            if not suitMaps[id] or id == "80001" then
                newSkin = newSkin .. id .. ";"
            end
        end
        CostumeInventory.mainSkin = newSkin
        CostumeInventory.ApplySkinsToPlayer()
        return
    end
    local needRemoveItem = CustomCharItems:GetItemById(skinId);
    if needRemoveItem then
       CostumeInventory.mainSkin = CostumeInventory.mainSkin:gsub(skinId..";", ""):gsub(skinId, "")
    end
    CostumeInventory.ApplySkinsToPlayer()
end
