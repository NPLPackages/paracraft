--[[
Title: Costume Inventory
Author: pbb
Date: 2025-04-08
Desc: 简化的皮肤预览界面，用于预览和穿戴选中的皮肤
Use Lib:
    local EasyCharPreview = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCharPreview.lua")
    EasyCharPreview.Show(selectedSkinItem)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local SkinManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinManager.lua")

local EasyCharPreview = NPL.export()

local page
local currentSkinItems

-- 初始化
function EasyCharPreview.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = EasyCharPreview.UpdatePreviewCharacter
end

function EasyCharPreview.IsSelectMainPlayer()
    local playerEntity = GameLogic.GetPlayer();
    return EasyCharPreview.selectEntity == playerEntity
end

function EasyCharPreview.GetHasSkinMap()
    local hasSkinMap = {}
    if EasyCharPreview.preSkin and EasyCharPreview.preSkin ~= "" then
        local skinIds = commonlib.split(EasyCharPreview.preSkin, ";")
        for _, id in ipairs(skinIds) do
            hasSkinMap[id] = true
        end
    end
    return hasSkinMap
end
--[[
SkinManager.RemoveAllUnvalidItems(skin, currentSkinMaps)
]]

function EasyCharPreview.Show(skinItems, targetEntity)
    local playerEntity = GameLogic.GetPlayer();
    local focusEntity = targetEntity or GameLogic.EntityManager.GetFocus();
    EasyCharPreview.allSelectItems = {}
    EasyCharPreview.allSelectItems[#EasyCharPreview.allSelectItems+1] = skinItems
    if focusEntity and focusEntity:HasCustomGeosets() then
        playerEntity = focusEntity
    end
    EasyCharPreview.mainAssets = playerEntity and playerEntity:GetMainAssetPath()
    if CustomCharItems:CheckReplaceAsset(EasyCharPreview.mainAssets) then
        EasyCharPreview.mainAssets = CustomCharItems.defaultModelFile
    end
    local playerSkin = playerEntity and playerEntity:GetSkin()
    EasyCharPreview.preSkin = playerSkin
	EasyCharPreview.mainSkin = playerSkin
    EasyCharPreview.selectEntity = playerEntity
    if skinItems and type(skinItems) == "table" then
        EasyCharPreview.mainSkin = EasyCharPreview.GetNewSkin(skinItems)
    end
    local view_width = 260
    local view_height = 400
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCharPreview.html",
        name = "EasyCharPreview.Show",
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
        x = -view_width - 440,
        y = 65,
        width = view_width,
        height = view_height,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
    }
    
    System.App.Commands.Call("File.MCMLWindowFrame", params)
    
end

function EasyCharPreview.IsVisible()
    return page and page:IsVisible()
end

function EasyCharPreview.RefreshPage()
    if page then
        page:Refresh(0.01)
    end
end

-- 关闭界面
function EasyCharPreview.Close()
    if page then
        page:CloseWindow()
        page = nil
    end
    EasyCharPreview.currentSkinItems = nil
end

function EasyCharPreview.CloseEasyChar()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyChar.lua");
    local EasyChar = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyChar");
    EasyChar.GetInstance():OnExit()
end

-- 应用多个挂件到实际角色
function EasyCharPreview.ApplySkinsToPlayer()
    if EasyCharPreview.preSkin and EasyCharPreview.mainSkin and EasyCharPreview.preSkin == EasyCharPreview.mainSkin then
        GameLogic.AddBBS(nil,L"皮肤未更新")
        EasyCharPreview.Close()
        EasyCharPreview.CloseEasyChar()
        return --当前皮肤没有更改
    end
    local suitItem = CustomCharItems:GetSuitItemBySkin(EasyCharPreview.mainSkin)
    if suitItem and suitItem.id then
        local isUnlock = SkinManager.GetUnLockManager().IsUnlocked(suitItem.id)
        if not isUnlock then
            local BuyConfirm = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/BuyConfirm.lua")
            BuyConfirm.ShowPage(suitItem,function(result)
                if result then
                    SkinManager.PurchaseSingleSkin(suitItem,function(result,msg)
                        if result and result == true then
                            SkinManager.GetUnLockManager().UnlockSkin(suitItem.id, "suit")
                            EasyCharPreview.UpdateUserSkin()
                        else
                            if msg and msg ~= "" then
                                _guihelper.MessageBox(msg);
                            end
                            EasyCharPreview.mainSkin = EasyCharPreview.preSkin
                            EasyCharPreview.UpdateUserSkin()
                        end
                    end)
                end
            end)
        else
            EasyCharPreview.UpdateUserSkin()
        end
        return
    end
    local curSkinMaps = EasyCharPreview.GetHasSkinMap()
    local newSkin = SkinManager.RemoveAllUnvalidItems(EasyCharPreview.mainSkin, curSkinMaps)
    if newSkin ~= EasyCharPreview.mainSkin then
        local validSkinIds = commonlib.split(newSkin, ";")
        local allSkinIds = commonlib.split(EasyCharPreview.mainSkin, ";")
        local validSkinMaps = {}
        for _, id in ipairs(validSkinIds) do
            validSkinMaps[id] = true
        end
        local needBuyItems = {}
        for _, id in ipairs(allSkinIds) do
            if not validSkinMaps[id] then
                needBuyItems[#needBuyItems+1] = CustomCharItems:GetItemById(id)
            end
        end
        local SkinConfirm = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/SkinConfirm.lua")
        SkinConfirm.ShowPage(needBuyItems,function(result)
            if not result then
                EasyCharPreview.mainSkin = EasyCharPreview.preSkin
            end
            EasyCharPreview.UpdateUserSkin()
        end)
        return
    end
    EasyCharPreview.UpdateUserSkin()
end

function EasyCharPreview.UpdateUserSkin()
    if not EasyCharPreview.IsSelectMainPlayer() then
        if EasyCharPreview.selectEntity then
            EasyCharPreview.selectEntity:SetMainAssetPath(EasyCharPreview.mainAssets);
		    EasyCharPreview.selectEntity:SetSkin(EasyCharPreview.mainSkin); 
            EasyCharPreview.Close()
            EasyCharPreview.CloseEasyChar()
        end
        return
    end
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    local playerEntity = GameLogic.GetPlayerController():GetPlayer();
	if playerEntity then
		playerEntity:SetMainAssetPath(EasyCharPreview.mainAssets);
		playerEntity:SetSkin(EasyCharPreview.mainSkin); 
	end
    local userId = Mod.WorldShare.Store:Get('user/userId') or ''
    if userId == ""  then
        GameLogic.AddBBS(nil,L"用户不存在")
        EasyCharPreview.Close()
        EasyCharPreview.CloseEasyChar()
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
            GameLogic.options:SetMainPlayerAssetName(EasyCharPreview.mainAssets);
            GameLogic.options:SetMainPlayerSkins(EasyCharPreview.mainSkin);
            local extra = data.extra or {};
            extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
            extra.ParacraftPlayerEntityInfo.skin = EasyCharPreview.mainSkin;
            extra.ParacraftPlayerEntityInfo.assetSkinGoodsItemId = 0;
            GameLogic.GetFilters():apply_filters("user_skin_change", EasyCharPreview.mainSkin);
            keepwork.user.setinfo({
                router_params = {id = userId},
                extra = extra,
            }, function(status, msg, data) 
                EasyCharPreview.Close()
                EasyCharPreview.CloseEasyChar()
                if (status < 200 or status >= 300) then 
                    return 
                end
                local userinfo = KeepWorkItemManager.GetProfile()
                userinfo.extra = extra
            end);
		end
	end)
end

-- 点击旋转
function EasyCharPreview.OnClickRotate(direction)
    if not page or not direction then
        return
    end
	local rotate = direction == "left" and -5 or 5
	local ctlName = "EasyCharPreviewPlayer"
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
function EasyCharPreview.UpdatePreviewCharacter()
    if not page then
        return
    end
    
    local ctlName = "EasyCharPreviewPlayer"
    local module_ctl = page:FindControl(ctlName)
    if not module_ctl then
        return
    end
    
    if EasyCharPreview.mainAssets and EasyCharPreview.mainAssets ~= "" then
		page:CallMethod(ctlName, "SetAssetFile", EasyCharPreview.mainAssets);
	end
	if EasyCharPreview.mainSkin and EasyCharPreview.mainSkin ~= "" then
		page:CallMethod(ctlName, "SetCustomGeosets", EasyCharPreview.mainSkin)
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
function EasyCharPreview.SetSkinItems(skinItems)
    if not skinItems or type(skinItems) ~= "table" then
        return false
    end
    EasyCharPreview.allSelectItems[#EasyCharPreview.allSelectItems+1] = skinItems
    EasyCharPreview.mainSkin = EasyCharPreview.GetNewSkin(skinItems)
    EasyCharPreview.RefreshPage()
end

function EasyCharPreview.GetNewSkin(skinItems)
    if not skinItems or type(skinItems) ~= "table" then
        return
    end
    EasyCharPreview.currentSkinItems = skinItems
    local skinId = skinItems.id
    local suitItem = SkinManager.GetBagManager().GetSuitItemInfo(skinId)
    if suitItem then
        return suitItem.skin
    end
    local needAddItem = CustomCharItems:GetItemById(skinId);
    if needAddItem then
        return CustomCharItems:AddItemToSkin(EasyCharPreview.mainSkin, needAddItem)
    end
end

function EasyCharPreview.RemoveSkinsFromPlayer()
    if type(EasyCharPreview.currentSkinItems) ~= "table" then
        return
    end
    local skinItems = EasyCharPreview.currentSkinItems
    local skinId = skinItems.id
    local suitItem = SkinManager.GetBagManager().GetSuitItemInfo(skinId)
    if suitItem then
        local suitSkin = suitItem.skin
        local skinIds = commonlib.split(suitSkin, ";")
        local curSkinIds = commonlib.split(EasyCharPreview.mainSkin, ";")
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
        EasyCharPreview.mainSkin = newSkin
        EasyCharPreview.ApplySkinsToPlayer()
        return
    end
    local needRemoveItem = CustomCharItems:GetItemById(skinId);
    if needRemoveItem then
       EasyCharPreview.mainSkin = EasyCharPreview.mainSkin:gsub(skinId..";", ""):gsub(skinId, "")
    end
    EasyCharPreview.ApplySkinsToPlayer()
end
