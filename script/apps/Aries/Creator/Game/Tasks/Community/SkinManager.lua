--[[
    author: pbb
    date: 2025-03-25
    description: 客户端皮肤管理逻辑
    uselib:
     local SkinManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinManager.lua")
]]
--- @return table: 获取需要知识豆购买类型的skin
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local SkinManager = NPL.export()
local AIGC_GSID = 40004 --40009 --17
local defaultSkinMale = "80001;82001;84070;81018;88002;85058;87001;"
local defaultSkinFemale = "80001;82004;84072;81018;88002;85029;87001;"
local defaultSkin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString);

local managerUnLocks = {}
local SKIN_ITEM_TYPE = {
	FREE = "0",
	SVIP = "1",
	ONLY_BEANS_CAN_PURCHASE = "2",
	ACTIVITY_GOOD = "3",
	VIP = "4",
}

function SkinManager.Init()
    if not SkinManager.Inited then
        SkinManager.Inited = true
    end
end

function SkinManager.GetBagManager()
    if not SkinManager.bagManager then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/VirtualBagManager.lua");
        SkinManager.bagManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.VirtualBagManager") 
    end
    return SkinManager.bagManager
end

function SkinManager.GetServerSkinData()
    local clientData = KeepWorkItemManager.GetClientData(AIGC_GSID) or {};
    local clothes = clientData.clothes or {}
    local client_clothe_map = {}
    for k, v in pairs(clothes) do
        if v.id and tonumber(v.id) then
            client_clothe_map[tonumber(v.id)] = v
        end
    end
    return clothes
end


function SkinManager.UpdateSkinByExpireTime()
    SkinManager.CheckUserSkin()
end

function SkinManager.CheckUserSkin()
	local user_skin = GameLogic.GetPlayerController():GetSkinTexture()
	if not user_skin or user_skin == "" then
		return
	end
	local default_kaka_skin = "80001;84129;81112;88042;" 
	local asset = MyCompany.Aries.Game.PlayerController:GetMainAssetPath() or ""
    local isChangeSkin = false
	if not System.options.isEducatePlatform then
		if asset:find("actor_kaka.x") or user_skin == default_kaka_skin or not PlayerAssetFile:CheckDefaultSkinValid(user_skin) then
			asset = "character/CC/02human/CustomGeoset/actor.x"
			user_skin = defaultSkinMale
            isChangeSkin = true
        else
			local newSkin = SkinManager.RemoveAllUnvalidItems(user_skin)
            if not newSkin or newSkin == ""  then
                newSkin = defaultSkinMale
            end
			if user_skin == newSkin then
				return
			end	
            user_skin = newSkin
		end
	else
		asset = "character/CC/02human/CustomGeoset/actor_kaka.x"
		user_skin = default_kaka_skin
        isChangeSkin = true
	end
	if not isChangeSkin then
		return
	end
	local playerEntity = GameLogic.GetPlayerController():GetPlayer();
	if playerEntity then
		playerEntity:SetSkin(user_skin); 
		playerEntity:SetMainAssetPath(asset)
	end	
	GameLogic.options:SetMainPlayerAssetName(asset);
	GameLogic.options:SetMainPlayerSkins(user_skin);
	GameLogic.GetFilters():apply_filters("user_skin_change", user_skin);
    
	local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
	local userinfo = Keepwork:GetUserInfo() or {};
    local AuthUserId = userinfo.id;
	local skin = MyCompany.Aries.Game.PlayerController:GetSkinTexture() or ""
    local extra = userinfo.extra or {};
    extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
    extra.ParacraftPlayerEntityInfo.asset = asset;
    extra.ParacraftPlayerEntityInfo.skin = skin;
    extra.ParacraftPlayerEntityInfo.assetSkinGoodsItemId = 0;
    keepwork.user.setinfo({
        router_params = {id = AuthUserId},
        extra = extra,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then return echo("更新玩家实体信息失败") end
        local userinfo = KeepWorkItemManager.GetProfile();
        userinfo.extra = extra;
        echo("更新玩家实体信息成功")
    end);
end


function SkinManager.SetServerSkinData(clothes,callback)
    local clientData = KeepWorkItemManager.GetClientData(AIGC_GSID) or {};
    local new_clothes = SkinManager.UpdateByCategory(clothes)
    
    clientData.clothes = new_clothes;
    KeepWorkItemManager.SetClientData(AIGC_GSID, clientData, callback)
end

local function get_new_item(a, b)
    if not a or not b then return a end
    if a.category == b.category then
        local a_start = commonlib.timehelp.GetTimeStampByDateTime(a.startAt)
        local b_start = commonlib.timehelp.GetTimeStampByDateTime(b.startAt)
        return a_start > b_start and a or b
    end
end

function SkinManager.UpdateByCategory(clothes) --单一分类只能存在一个
    if not clothes or type(clothes) ~= "table" or #clothes == 0 then
        return
    end
    local categoty_map = {}
    local temp_items = {}
    for k, v in ipairs(clothes) do
        if v.category and not categoty_map[v.category] then
            categoty_map[v.category] = v
        else
            categoty_map[v.category] = get_new_item(categoty_map[v.category], v)
        end
    end
    for k, v in pairs(categoty_map) do
        if v and v.category then
            table.insert(temp_items, v)
        end
    end
    return temp_items
end

function SkinManager.GetBeanNum()
    local BEAN_GSID = 998;
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(BEAN_GSID)
	return copies or 0;
end

function SkinManager.PurchaseSingleSkin(skin_data,callback)
    if not skin_data then
        if callback and type(callback) == "function" then
            callback(false)
        end
        return
    end
    local items = {};
    local totalPrice = 0;
    if type(skin_data) == "string" then -- 80001;80006;...
        skin_data = CustomCharItems:SkinStringToTable(skin_data)
    end
    if type(skin_data) ~= "table" then 
        if callback and type(callback) == "function" then
            callback(false)
        end
        return
    end
    local time_stamp = SkinManager.GetServerTime()
    if(skin_data.price and tonumber(skin_data.price) > 0) then
        totalPrice = tonumber(skin_data.price)
    end
    if totalPrice <= 0 then
        if callback and type(callback) == "function" then
            callback(true, "该皮肤不需要购买~")
        end
        return
    end
    local myBean = SkinManager.GetBeanNum()
    if(myBean < totalPrice) then
        local tipStr = "你当前拥有".. myBean .. "知识豆，知识豆不足, 无法购买~" 
		if callback and type(callback) == "function" then
            callback(false, tipStr)
        end
		return;
	end
    keepwork.user.bean_reduce({
        count = totalPrice,
    },function(err,msg,data)
        print("reduce bean result=======================",err)
       if err == 200 then
            KeepWorkItemManager.LoadItems(nil, function()
                if callback and type(callback) == "function" then
                    callback(true)
                end
            end)
           return
       end 
       if callback and type(callback) == "function" then
            callback(false, "购买失败，请稍后再试~")
        end
    end)
end

function SkinManager.PurchaseSkin(skin_data,callback)
    if not skin_data then
        SkinManager.ShowPurchaseResult(nil,false,callback) 
        return
    end
    local items = {};
    local totalPrice = 0;
    if type(skin_data) == "string" then -- 80001;80006;...
        skin_data = CustomCharItems:SkinStringToTable(skin_data)
    end
    if type(skin_data) ~= "table" then 
        SkinManager.ShowPurchaseResult(nil,false,callback) 
        return
    end
    local time_stamp = SkinManager.GetServerTime()
    for i, v in ipairs(skin_data) do
        if(v.price and tonumber(v.price) > 0) then
            totalPrice = totalPrice + tonumber(v.price)
			table.insert(items, {
				category = v.category,
				itemId = tonumber(v.id),
				price = tonumber(v.price),
                startAt = commonlib.timehelp.FormatTimeStampToDate(time_stamp)
			});
		end
    end
    local myBean = SkinManager.GetBeanNum()
    if(myBean < totalPrice) then
        local tipStr = "你当前拥有".. myBean .. "知识豆，知识豆不足, 无法购买~" 
		SkinManager.ShowPurchaseResult(tipStr,false,callback) 
		return;
	end
    local currentSkins = SkinManager.GetServerSkinData()
    keepwork.user.bean_reduce({
        count = totalPrice,
    },function(err,msg,data)
        print("reduce bean result=======================",err)
       if err == 200 then
            for i, v in ipairs (items) do
                currentSkins[#currentSkins+1] = v
            end
            SkinManager.SetServerSkinData(currentSkins,function()
                KeepWorkItemManager.LoadItems(nil, function()
                    GameLogic.AddBBS(nil, L"购买成功~", 3000, "255 255 255")
                    SkinManager.ShowPurchaseResult(nil,true,callback) 
                end)
                LOG.std(nil, "info", "SkinManager", "PurchaseSkin success data is ".. commonlib.serialize_compact(currentSkins))
            end)
           return
       end 
       SkinManager.ShowPurchaseResult("购买失败，请稍后再试~",false,callback) 
    end)
end

function SkinManager.ShowPurchaseResult(tipStr,result,callback)
    if tipStr and tipStr ~= "" then
        _guihelper.MessageBox(tipStr, function ()
           if callback and type(callback) == "function" then
               callback(result)
           end
        end);
        return
    end
    if callback and type(callback) == "function" then
        callback(result)
    end
end

function SkinManager.GetServerTime()
    if System.options.isDevMode then
        return os.time()
    end
    local timp_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
    return timp_stamp or os.time()
end

function SkinManager.FormatTime(datetime)
	local time_stamp = type(datetime) == "string" and commonlib.timehelp.GetTimeStampByDateTime(datetime) or datetime
	local year = os.date("%Y", time_stamp)	
	local month = os.date("%m", time_stamp)
	local day = os.date("%d", time_stamp)
	local hour = os.date("%H", time_stamp)
	local min = os.date("%M", time_stamp)
	local sec = os.date("%S", time_stamp)
	return string.format("%s-%s-%s %s:%s:%s", year,month,day,hour,min,sec);
end

function SkinManager.GenerateUnLockSkinMap()
    managerUnLocks = {}
    local unlockSkins = SkinManager.GetUnLockManager().GetUnlockedSkinMap()
    for skinId, v in pairs(unlockSkins) do
        local suitItem = CustomCharItems:GetSuitItemById(skinId)
        if suitItem and type(suitItem) == "table" then
            local skin = suitItem.skin
            local skinIds = commonlib.split(skin, ";")
            for _, v in ipairs(skinIds) do
                managerUnLocks[v] = true
            end
        else
            managerUnLocks[skinId] = true
        end
    end
end

function SkinManager.IsUnLockSkin(skinId)
    local skin = tostring(skinId)
    return managerUnLocks[skin]
end

function SkinManager.RemoveAllUnvalidItems(skin, existSkinMaps)
    existSkinMaps = existSkinMaps or {}
	local currentSkin = skin;
    local item = CustomCharItems:GetSuitItemBySkin(skin)
    if item and type(item) == "table" then
        local suitId = item.id
        if not SkinManager.GetUnLockManager().IsUnlocked(suitId) then
            local defaultSkin = "80001;81018;88042"
            return defaultSkin
        else
            return currentSkin
        end
    end
    SkinManager.GenerateUnLockSkinMap()
	local itemIds = commonlib.split(skin, ";");
	if (itemIds and #itemIds > 0) then
		for _, id in ipairs(itemIds) do
			local data = CustomCharItems:GetItemById(id);
            local isValid = SkinManager.CheckSkinIsValid(id)
            local isExist = existSkinMaps[id]
			if (data and not isValid and not isExist) then
				currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
			end
		end
	end
	return currentSkin;
end

function SkinManager.CheckSkinIsValid(skinId)
	local clothes = SkinManager.GetServerSkinData() or {};
	local data = CustomCharItems:GetItemById(skinId);
	if (data) then
        if data.price and tonumber(data.price) > 0 then -- 配置了价格的默认都是知识豆可购买
            data.type = SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE
        end
        if (data.price and tonumber(data.price) == 0) or data.isFree == "1" then
            data.type = SKIN_ITEM_TYPE.FREE
        end
		-- VIP可用
		if(data.type == SKIN_ITEM_TYPE.VIP and not SkinManager.IsCommonVip()) then
			return false
		end;
		-- SVIP可用
		if(data.type == SKIN_ITEM_TYPE.SVIP and not SkinManager.IsSuperVip()) then
			return false
		end;
        
		-- 知识豆可购买类型
		if(data.type == SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
            local isUnlock = SkinManager.IsUnLockSkin(skinId)
			if(not isUnlock) then
				return false
			end;
		end;
	end
	return true
end

function SkinManager.IsCommonVip()
	local profile = KeepWorkItemManager.GetProfile()
    if not profile or System.options.isHideVip then
		return false
	end
	return profile.vip == 1 or profile.commonVip == 1
end

function SkinManager.IsSuperVip()
	local profile = KeepWorkItemManager.GetProfile()
    if not profile or System.options.isHideVip then
		return false
	end
	return profile.vip == 1
end

function SkinManager.GetUnLockManager()
    if not SkinManager.UnLockManager then
        local SkinUnLockManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinUnLockManager.lua")
        SkinManager.UnLockManager = SkinUnLockManager
    end
    return SkinManager.UnLockManager
end


