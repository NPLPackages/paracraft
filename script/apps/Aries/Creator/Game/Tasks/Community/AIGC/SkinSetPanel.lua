--[[
    author:{pbb}
    time:2025-02-18 13:50:48
    uselib:
    local SkinSetPanel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/SkinSetPanel.lua")
    SkinSetPanel.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CustomSkinPage.lua");
local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local SkinManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinManager.lua")

local page
local SkinSetPanel = NPL.export() 
local freeSkinIds = {80001,82001,84020,85058,82004,84028,81018,88002,85029}
local basepath = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png#"
SkinSetPanel.skin_category_ds = {
	{icon1 = basepath.."128 427 56 56", icon2 = basepath.."202 319 56 56", name = "hair", value=L"头饰",  ui_index = 7},
	{icon1 = basepath.."266 318 56 56", icon2 = basepath.."266 262 56 56", name = "eye", value=L"眼睛",  ui_index = 1},
	{icon1 = basepath.."132 536 56 56", icon2 = basepath.."199 536 56 56", name = "mouth", value=L"嘴巴",  ui_index = 2},
	{icon1 = basepath.."132 377 56 56", icon2 = basepath.."202 262 56 56", name = "shirt", value=L"衣服",  ui_index = 3},
	{icon1 = basepath.."132 479 56 56", icon2 = basepath.."265 371 56 56", name = "pants", value=L"裤子",  ui_index = 4},
	{icon1 = basepath.."0 334 56 56", icon2 = basepath.."196 374 56 56", name = "right_hand_equipment", value=L"手持",  ui_index = 6},
	{icon1 = basepath.."137 326 56 56", icon2 = basepath.."138 266 56 56", name = "back", value=L"背部",  ui_index = 5},
	{icon1 = basepath.."326 326 56 56", icon2 = basepath.."72 326 56 56", name = "suit", value=L"套装",  ui_index = 8},
};

SkinSetPanel.SkinQualitys = {
	{text=L"全部", price=0, value=-1},
	{text=L"普通", price=25, value=1},
	{text=L"稀有", price=50, value=2},
	{text=L"卓越", price=100, value=3},
	{text=L"绝迹", price=200, value=4},
	{text=L"限定", price=400, value=5},
}
SkinSetPanel.search_text = ""
SkinSetPanel.select_quality_index = 1

local SKIN_ITEM_TYPE = {
	FREE = "0",
	SVIP = "1",
	ONLY_BEANS_CAN_PURCHASE = "2",
	ACTIVITY_GOOD = "3",
	VIP = "4",
	SUIT_PART = "5",
}
SkinSetPanel.SKIN_ITEM_TYPE = SKIN_ITEM_TYPE

SkinSetPanel.mainSkin = ""
SkinSetPanel.skin_category_index = -1
SkinSetPanel.Current_SkinItem_DS = {}
SkinSetPanel.frameName = ""
SkinSetPanel.isOnlyShowHave = false
function SkinSetPanel.OnInit(frameName)
    if frameName and frameName ~= "" then
		SkinSetPanel.frameName = frameName
        SkinSetPanel.InitData()
    end
    page = document:GetPageCtrl()
	page.OnClose = SkinSetPanel.OnClose
end

function SkinSetPanel.ShowPage()
    SkinSetPanel.InitData()
    local view_width = 440
    local view_height = 630
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/AIGC/SkinSetPanel.html",
        name = "SkinSetPanel.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_lt",
        x = 0,
        y = 0,
        width = view_width,
        height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params)

    commonlib.TimerManager.SetTimeout(function()
        SkinSetPanel.OnChangeSkinCategory(1,true)
	end,200)
end

function SkinSetPanel.OnClose()
	SkinSetPanel.frameName = ""
	print("destroy frame==================")
end

function SkinSetPanel.UpdateParentPage(items)
	if SkinSetPanel.frameName == "userinfo" then
		local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoPage.lua")
		UserInfoPage.SetPlayerSkin(SkinSetPanel.mainSkin,SkinSetPanel.preSkin,items)
	elseif SkinSetPanel.frameName == "easychar" then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyChar.lua");
		local EasyChar = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyChar");
		EasyChar.GetInstance():SetPlayerSkin(SkinSetPanel.mainSkin,SkinSetPanel.preSkin,items)
	end
end

function SkinSetPanel.RefreshPage()
    if not page then
        return
    end
    page:Refresh(0)
end

function SkinSetPanel.GetMainAsset()
    -- if System.options.isEducatePlatform then
    --     return "character/CC/02human/CustomGeoset/actor_kaka.x"
    -- end
    return "character/CC/02human/CustomGeoset/actor.x"
end

function SkinSetPanel.GetItemIconBySkin(skin)
	local items = CustomCharItems:GetUsedItemsBySkin(skin);
	for _, item in ipairs(items) do
		local index = CustomSkinPage.GetIconIndexFromName(item.name);
		if (index > 0) then
			SkinSetPanel.Current_Icon_DS[index].id = item.id;
			SkinSetPanel.Current_Icon_DS[index].name = item.name;
			SkinSetPanel.Current_Icon_DS[index].icon = item.icon;
		end
	end
end

function SkinSetPanel.InitData()
	SkinManager.GetUnLockManager().LoadSkinConfigs()
    local SystemUserData = KeepWorkItemManager.GetProfile();
    SkinSetPanel.UserData = SystemUserData
    SkinSetPanel.Current_Icon_DS = {};
	for i = 1, #SkinSetPanel.skin_category_ds do
		SkinSetPanel.Current_Icon_DS[i] = {id = "", icon = "", name = ""} 
	end
    local playerEntity = GameLogic.GetPlayer();
	if SkinSetPanel.frameName == "easychar" then
		local focusEntity = GameLogic.EntityManager.GetFocus();
		if focusEntity and focusEntity:HasCustomGeosets() then
			playerEntity = focusEntity
		end
	end
	local skin = playerEntity and playerEntity:GetSkin() or ""
    SkinSetPanel.mainSkin = skin
	SkinSetPanel.preSkin = skin
    SkinSetPanel.GetItemIconBySkin(SkinSetPanel.mainSkin)
    SkinSetPanel.search_text = ""
	SkinSetPanel.select_quality_index = 1
	if SkinSetPanel.frameName and SkinSetPanel.frameName ~= "" then
		commonlib.TimerManager.SetTimeout(function()
			SkinSetPanel.OnChangeSkinCategory(1,true)
		end,200)
	end
end

function SkinSetPanel.OnChangeSkinCategory(index,bChangeMenu)
	if index and index > 0 and SkinSetPanel.skin_category_index ~= index then
		SkinSetPanel.skin_category_index = index or SkinSetPanel.skin_category_index;
		local category = SkinSetPanel.skin_category_ds[SkinSetPanel.skin_category_index];
		if (category) then
			SkinSetPanel.Current_SkinItem_DS = SkinSetPanel.GetCustomItems(category.name)
		end
		SkinSetPanel.selectSkinItemId = nil
		SkinSetPanel.UpdateItemData()
		SkinSetPanel.search_text = ""
		SkinSetPanel.select_quality_index = 1
		SkinSetPanel.RefreshPage();
		SkinSetPanel.FileterSkins()
	end
end

function SkinSetPanel.GetAllItemData()
	local category = SkinSetPanel.skin_category_ds[SkinSetPanel.skin_category_index];
	if (category) then
		SkinSetPanel.Current_SkinItem_DS = SkinSetPanel.GetCustomItems(category.name)
	end
end

function SkinSetPanel.GetCustomItems(category)
	if not category or category == "" then
		return {}
	end
	local items = {}
	if category == "suit" then
		items = CustomCharItems:GetAllSuits()
	else
		items = CustomCharItems:GetModelItems(SkinSetPanel.GetMainAsset(), category, SkinSetPanel.mainSkin or "",true) or {}
	end
	return items
end

function SkinSetPanel.UpdateSkinGView(data)
	if data and page then
		page:CallMethod("gvSkinIframeGridView","SetDataSource", data);
		page:CallMethod("gvSkinIframeGridView","DataBind");
		page:SetValue("checkShow", SkinSetPanel.isOnlyShowHave)
	end
end

local isFreeList
function SkinSetPanel.IsFreeSkin(skinId)
	if not isFreeList then
		isFreeList = {}
		for k,v in pairs(freeSkinIds) do
			isFreeList[v] = true
		end
	end
	local index = tonumber(skinId)
	if index and index > 0 then
		return isFreeList[index]
	end
end

function SkinSetPanel.UpdateItemData()
	for i,v in ipairs(SkinSetPanel.Current_SkinItem_DS) do
		if SkinSetPanel.IsFreeSkin(v.id) then
			v.type = SKIN_ITEM_TYPE.FREE
		end
		if v.gsid and v.gsid ~= "" then
			v.type = SKIN_ITEM_TYPE.ACTIVITY_GOOD
		end
		if v.type == SKIN_ITEM_TYPE.SUIT_PART then
			v.type = SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE
		end
		if v.price and v.price ~= "" then -- 只要有价格就是知识豆购买
			v.type = SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE
		end
		if v.isFree and v.isFree == "1" or (v.price and v.price ~= "" and tonumber(v.price) == 0) then
			v.type = SKIN_ITEM_TYPE.FREE
		end
		if v.isVipFree and v.isVipFree == "1" then
			v.type = SKIN_ITEM_TYPE.VIP
		end
	end
	local temp = {}
	for i,v in ipairs(SkinSetPanel.Current_SkinItem_DS) do
		if v.type == SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE and v.price and v.price ~= "" and tonumber(v.price) > 0 then
			temp[#temp + 1] = v
		end
		if v.type ~= SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE then
			temp[#temp + 1] = v
		end
	end
	temp = SkinSetPanel.UpdateItemDataByLocks(temp)
	SkinSetPanel.UpdateSkinIcon()
	SkinSetPanel.Current_SkinItem_DS = temp
end

-- 用户虚拟背包
function SkinSetPanel.UpdateItemDataByLocks(items)
	if not items or #items == 0 then
		return items
	end
	for k, v in pairs(items) do
		if v and v.id and SkinManager.GetUnLockManager().IsUnlocked(v.id) then
			v.has = 1
		else
			v.has = 0
		end
	end
	return items
end


function SkinSetPanel.GetUnPurchasedSkins(items)
	if not items or #items == 0 then
		return items
	end
	local temp = {}
	for k, v in pairs(items) do
		if v and v.id and not SkinManager.GetUnLockManager().IsUnlocked(v.id) then
			table.insert(temp, v)
		end
	end
	return temp
end

function SkinSetPanel.PurchaseItem(name,mcmlNode)
	local param1 = mcmlNode:GetAttribute("param1")
	if not param1 then
		_guihelper.MessageBox(L"购买皮肤失败，参数错误，请稍后再试");
		return
	end
	local item = param1
	local canUnlock, reason = SkinManager.GetUnLockManager().CanUnlock(item.id)
	if not canUnlock then
		if reason and reason ~= "" then
			_guihelper.MessageBox(reason);
		else
			_guihelper.MessageBox(L"购买皮肤失败，不满足解锁条件，请稍后再试");
		end
		return
	end
	local BuyConfirm = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/BuyConfirm.lua")
    BuyConfirm.ShowPage(item,function(result)
		if result then
			SkinManager.PurchaseSingleSkin(item,function(result,msg)
				if result and result == true then
					SkinManager.GetUnLockManager().UnlockSkin(item.id, item.category)
					SkinSetPanel.AddVirtualBagItem(item,function(result,msg)
						if result and result == true then
							GameLogic.AddBBS(nil,L"恭喜你，解锁皮肤成功:"..item.name);
						end
					end)
                    SkinSetPanel.GetAllItemData()
                    SkinSetPanel.UpdateItemData()
                    SkinSetPanel.RefreshPage()
                    SkinSetPanel.FileterSkins()
				else
					if msg and msg ~= "" then
						_guihelper.MessageBox(msg);
					end
				end
			end)
		end
	end)
end

function SkinSetPanel.AddVirtualBagItem(item,callback) --背包属于收藏的逻辑了，不可收藏套装
	SkinManager.GetBagManager().AddItem("skin", item, nil, function(result, msg)
		if not result then
			_guihelper.MessageBox(L"添加物品失败:"..(msg or ""));
			return
		end
		if callback and type(callback) == "function" then
			callback(result, msg)
		end
	end)
end


function SkinSetPanel.UpdateSkinIcon()
	local category = SkinSetPanel.skin_category_ds[SkinSetPanel.skin_category_index];
	if category and category.name and category.name == "eye" then
		for i,v in ipairs(SkinSetPanel.Current_SkinItem_DS) do
			if v.icon and v.icon ~= "" then
				v.icon = string.gsub(v.icon, "Texture/Aries/Creator/keepwork/Avatar/icons/", "Texture/Aries/Creator/keepwork/Community/eye/");
			end
		end
	end
end

function SkinSetPanel.RefreshPageBySkin(items)
	SkinSetPanel.RefreshPage();
	SkinSetPanel.FileterSkins()
	SkinSetPanel.UpdateParentPage(items)
end

function SkinSetPanel.UpdateCustomGeosets(name,mcmlNode)
	local param1 = mcmlNode:GetAttribute("param1")
	if param1 then
		local item = param1
		local ui_index = SkinSetPanel.skin_category_ds[SkinSetPanel.skin_category_index].ui_index;
		local category = SkinSetPanel.skin_category_ds[SkinSetPanel.skin_category_index].name;
		if category and category == "suit" then
			SkinSetPanel.mainSkin = item.skin
			SkinSetPanel.selectSkinItemId = item.id;
			SkinSetPanel.RefreshPageBySkin(item)
			return
		end
		if (SkinSetPanel.Current_Icon_DS[ui_index].id == item.id) then
			SkinSetPanel.RefreshPageBySkin(item)
			return;
		end
		SkinSetPanel.mainSkin = CustomCharItems:AddItemToSkin(SkinSetPanel.mainSkin, item);
		SkinSetPanel.selectSkinItemId = item.id;
		SkinSetPanel.Current_Icon_DS[ui_index].id = item.id;
		SkinSetPanel.Current_Icon_DS[ui_index].name= item.name;
		SkinSetPanel.Current_Icon_DS[ui_index].icon = item.icon;
		SkinSetPanel.RefreshPageBySkin(item)
	end
end

function SkinSetPanel.CheckSkinSelected(skinId)
	if SkinSetPanel.selectSkinItemId and SkinSetPanel.selectSkinItemId == skinId then
		return true
	end
	return false
end

function SkinSetPanel.GetBeanNum()
	local BEAN_GSID = 998;
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(BEAN_GSID)
	return copies or 0;
end

function SkinSetPanel.GetUnValidSkinData(skin1,skin2)
	local itemIds = commonlib.split(skin1, ";");
	local itemIds2 = commonlib.split(skin2, ";");
	local temps = {}
	local num1 = #itemIds
	local num2 = #itemIds2
	local itemExists = {}
	for i = 1, num2 do
		itemExists[itemIds2[i]] = true
	end
	for i = 1, num1 do
		if not itemExists[itemIds[i]] then
			local skinId = (itemIds[i])
			local skinData = CustomCharItems:GetItemById(skinId);
			temps[#temps + 1] = skinData;
		end
	end
	
	return temps
end

function SkinSetPanel.RemoveAllUnvalidItems(skin)
	local newSkin = SkinManager.RemoveAllUnvalidItems(skin)
	return newSkin
end

function SkinSetPanel.CheckSkinUsed(skinId)
	local skinId = tostring(skinId)
	local mainSkin = SkinSetPanel.mainSkin or ""
	local skinIdStr = CustomCharItems:SkinStringToItemIds(mainSkin)
	if skinIdStr and string.find(skinIdStr, skinId) then
		return true
	end
	return false
end

function SkinSetPanel.GetDataIndex(data)
	for i,v in ipairs(SkinSetPanel.Current_SkinItem_DS) do
		if tonumber(v.id) == tonumber(data.id) then
			return i
		end
	end
end

function SkinSetPanel.RemoveSkinByName(skinName)
	local skinId = SkinSetPanel.GetSkinIdByName(skinName)
	if skinId and string.find(SkinSetPanel.mainSkin,skinId) then
		for i,v in ipairs(SkinSetPanel.Current_Icon_DS) do
			if tonumber(v.id) == tonumber(skinId) then
				v.id = "";
				v.name = "";
				v.icon = "";
				break
			end
		end
		local skin = CustomCharItems:RemoveItemInSkin(SkinSetPanel.mainSkin, skinId);
		if (SkinSetPanel.mainSkin ~= skin) then
			SkinSetPanel.mainSkin = skin;
			SkinSetPanel.RefreshPage()
		end
	end
end

function SkinSetPanel.OnSearchSkin()
	local searchText = page:GetValue("skin_search")
	if searchText and searchText ~= "" then
		SkinSetPanel.SearchSkins(searchText)
	else
		SkinSetPanel.search_text = ""
		SkinSetPanel.FileterSkins()
	end
end

function SkinSetPanel.SearchSkins(searchText)
	if not searchText or searchText == "" and SkinSetPanel.search_text ~= "" then
		SkinSetPanel.search_text = ""
		return
	end
	if searchText ~= SkinSetPanel.search_text then
		SkinSetPanel.search_text = searchText
		SkinSetPanel.FileterSkins()
	end
end

function SkinSetPanel.GetCurrentQuality()
	local curQuality = SkinSetPanel.SkinQualitys[SkinSetPanel.select_quality_index]
	return curQuality and curQuality.text or L"全部"
end

function SkinSetPanel.FileterSkins(filterIndex)
	if not filterIndex or filterIndex == "" then
		filterIndex = SkinSetPanel.select_quality_index
	end
	local index = tonumber(filterIndex)
	if index and index > 0 and index <= #SkinSetPanel.SkinQualitys then
		if SkinSetPanel.select_quality_index ~= index then
			SkinSetPanel.select_quality_index = index
		end
		local quality = SkinSetPanel.SkinQualitys[index]
		local curSkins = {}
		if quality and quality.price then
			for i, v in ipairs(SkinSetPanel.Current_SkinItem_DS) do
				if (v and v.price and tonumber(v.price) == quality.price) or quality.price == 0 then
					table.insert(curSkins, v)
				end
			end
		end
		if quality and quality.text and quality.text ~= "" then
			if page then
				page:SetValue("label_quality", quality.text)
			end
		end
		if SkinSetPanel.search_text and SkinSetPanel.search_text ~= "" then
			local temp = {}
			for i, v in ipairs(curSkins) do
				if v and v.name and string.find(v.name, SkinSetPanel.search_text) then
					table.insert(temp, v)
				end
			end
			curSkins = temp 
		end
		if SkinSetPanel.isOnlyShowHave then
			local temp = {}
			for i, v in ipairs(curSkins) do
				if v and (v.has == 1 or v.type == SKIN_ITEM_TYPE.FREE) then
					table.insert(temp, v)
				end
			end
			curSkins = temp 
		end
		SkinSetPanel.UpdateSkinGView(curSkins)
	end
end

function SkinSetPanel.ShowSkinQuality()
	local parent = ParaUI.GetUIObject("SkinSetPanel.skin_quality_container")
	local x,y
	if parent:IsValid() then
		x,y,_,_ = parent:GetAbsPosition()
	end
	local menuStyle = commonlib.copy(CommonCtrl.ContextMenu.DefaultStyle)
    menuStyle.menuitemHeight = 36
    menuStyle.menu_bg = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;282 598 32 32:14 14 14 14"
    menuStyle.item_bg = "Texture/Aries/Creator/keepwork/Community/community_userinfo.png;329 598 32 32:14 14 14 14"
    menuStyle.level1itemcolor = "#4E5969FF"
	menuStyle.mouseover_textcolor = "#1D2129"
	menuStyle.textFont = "System;12;bold"
    local ctl = SkinSetPanel.contextCategoryCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "SkinSetPanel.contextCategoryCtrl",
			width = Mod.WorldShare.Utils.IsEnglish() and 144 or 114,
			height = 164, 
			onclick = SkinSetPanel.OnClickCatoryItem,
            style = menuStyle,
		};
		SkinSetPanel.contextCategoryCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
    if node then
        node:ClearAllChildren();
        for key, item in ipairs(SkinSetPanel.SkinQualitys) do
			local text = item.text
			if key == SkinSetPanel.select_quality_index then
				text = item.text .. "             √"
			end
            local tree_node = CommonCtrl.TreeNode:new({Text = text, Name = tostring(key), Type = "Menuitem", onclick = nil, });
            node:AddChild(tree_node);
        end
    end
    ctl:Show(x, y + 36);
end

function SkinSetPanel.OnClickCatoryItem(node)
	local name = node.Name
    if not name  or name == '' then
        return
    end
	SkinSetPanel.FileterSkins(name)
end

function SkinSetPanel.OnClickShowHased()
	SkinSetPanel.isOnlyShowHave = not SkinSetPanel.isOnlyShowHave
	SkinSetPanel.FileterSkins()
end