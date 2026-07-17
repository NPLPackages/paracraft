--[[
Title: VipFullPage
Author(s): leio, ygy, big
CreateDate: 2021.7.9
ModifyDate: 2022.8.18
Desc:  
Use Lib:
-------------------------------------------------------
local VipFullPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipFullPage.lua");
VipFullPage.ShowPage();
--]]

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local ServerConfigManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/ServerConfigManager.lua");

NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/ide/DateTime.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local Encoding = commonlib.gettable("System.Encoding");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local VipFullPage = NPL.export()
local page

VipFullPage.products_types = {
	twelve_month_vip = "twelve_month_vip", 
	six_month_vip = "six_month_vip"
};

VipFullPage.pay_types = {
	weixin = "weixin", 
	zhifubao = "zhifubao"
};

VipFullPage.GridDs = {{}}

VipFullPage.products = {};
VipFullPage.loaded_products = false;
VipFullPage.selected_product = VipFullPage.products_types.twelve_month_vip; -- "six_month_vip" or "twelve_month_vip"
VipFullPage.selected_pay = VipFullPage.pay_types.weixin; -- "weixin" or "zhifubao"
VipFullPage.orders = {};
VipFullPage.selected_order = nil;
VipFullPage.order_state_map = {};
VipFullPage.timer = nil;
VipFullPage.desc = nil; -- vip功能描述
VipFullPage.default_cache_policy = "access plus 1 month";
VipFullPage.showRealNameGift = false;

function VipFullPage.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = VipFullPage.OnCreate
end

function VipFullPage.GetPageCtrl()
    return page;
end

function VipFullPage.RefreshPage()
	if(page)then
		page:Refresh(0);
	end
end

function VipFullPage.ClosePage()
	if(page)then
		page:CloseWindow(true)
	end
end

function VipFullPage.VipIsValidCallback()
	VipFullPage.ClosePage();
end

function VipFullPage.ShowPage(key, desc)
	if (System.options.isHideVip) then
		return;
	end

	ServerConfigManager.GetConfigData(function()
		-- 云南的话走其他界面
		local yunnanVipPageConfig = ServerConfigManager.GetConfigByName("yunnanVipPage")
		local user_region = KeepWorkItemManager.GetUserRegion() or {}

		if yunnanVipPageConfig and yunnanVipPageConfig.config and yunnanVipPageConfig.config.regionId == user_region.stateId then
			local SpecialAreaVipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/SpecialAreaVipPage.lua");
			SpecialAreaVipPage.ShowPage();
		else
			if GameLogic.GetFilters():apply_filters('check_unavailable_before_open_vip')==true then
				return
			end
			
			VipFullPage.selected_order = nil;
			VipFullPage.order_state_map = {};
			VipFullPage.orders = {};
			GameLogic.GetFilters():remove_filter("became_vip", VipFullPage.VipIsValidCallback);
			GameLogic.GetFilters():add_filter("became_vip", VipFullPage.VipIsValidCallback);
			VipFullPage.LoadPruducts(function(v)
				if(v)then
					VipFullPage.ShowPage__(key, desc);
					VipFullPage.OnSelected();
				end
			end)
		end
	end)
end

function VipFullPage.ShowPage__(key, desc)
	VipFullPage.key = key; 
	VipFullPage.desc = desc; -- vip功能描述
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.funnel.open', { from = key })
    local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/User/VipFullPage.html",
			name = "VipFullPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			directPosition = true,
			isTopLevel = true,
			zorder = 1,
			DesignResolutionWidth = 1280,
			DesignResolutionHeight = 720,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if not VipFullPage.BindFilter then
		VipFullPage.BindFilter = true
		NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
		local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
		local viewport = ViewportManager:GetSceneViewport();
		viewport:Connect("sizeChanged", VipFullPage, function()
			commonlib.TimerManager.SetTimeout(function()
				VipFullPage.RefreshPage()
			end, 100);
			
		end, "UniqueConnection");
	end
end

-- 加载产品列表，获取价格
function VipFullPage.LoadPruducts(callback)
	if(VipFullPage.loaded_products)then
		if(callback)then
			callback(true);
		end
		return
	end
	--[[
	return {
  products={
    {
      code="six_month_vip",
      description="",
      id=5,
      name="",
      picUrl="",
      price=49800 
    },
    {
      code="twelve_month_vip",
      description="",
      id=6,
      name="",
      picUrl="",
      price=88000 
    } 
  } 
}
	--]]
	local cache_key = VipFullPage.CreateKeyByParams("VipFullPage.LoadPruducts.v1")
	local cache_item = HttpWrapper.GetCacheByKey(cache_key, VipFullPage.default_cache_policy);
	if(cache_item)then
		VipFullPage.products = cache_item;
		if(callback)then
			callback(true);
		end
	end
	keepwork.pay.searchVipProducts({
        codes = {
            "six_month_vip","twelve_month_vip"
        },
    },function(err, msg, data)
		if(err ~= 200)then
			commonlib.echo("==========OnSearchVipProducts err");
			commonlib.echo(err);
			commonlib.echo(msg);
			commonlib.echo(data,true);
			return
		end
        VipFullPage.products = data.products;
		 HttpWrapper.SetCacheByKey(cache_key, VipFullPage.products);
		if(callback)then
			callback(true);
		end
    end)
end

-- get product info
-- @param product_type: "six_month_vip" or "twelve_month_vip"
function VipFullPage.GetProduct(product_type)
	if(not product_type)then
		return
	end
	for k,v in ipairs(VipFullPage.products) do
		if(v.code == product_type)then
			return v;
		end
	end
end

--@param:productCode: "six_month_vip" or "twelve_month_vip"
--@param:channel: "wx_pub_qr" or "alipay_qr"
function VipFullPage.OnCreateOrGetOrder(productCode, channel, callback)

    local product = VipFullPage.orders[productCode] or {};
    if(product)then
        local order = product[channel];
        if(order)then
            if(callback)then
                callback(order)
            end
            return
        end
    end
    local product_template = VipFullPage.GetProduct(productCode);
    if(not product_template)then
        return
    end

	local input = {
        payAmount = product_template.price,
        quantity = 1,
        channel = channel,
        productCode = productCode,
    }
	local url_queries = commonlib.copy(input);
	local profile = KeepWorkItemManager.GetProfile()
	url_queries.userId = profile.id;
	local cache_key = VipFullPage.CreateKeyByParams("VipFullPage.OnCreateOrGetOrder.v1", url_queries)
	local cache_item = HttpWrapper.GetCacheByKey(cache_key, VipFullPage.default_cache_policy);
	VipFullPage.SaveOrderCacheKeyForUser(cache_key);
	if(cache_item)then
		product[channel] = cache_item;
        VipFullPage.orders[productCode] = product;
        if(callback)then
            callback(cache_item)
        end
		return
	end
    keepwork.pay.clientVip(input, function(err, msg, data)
        if(err ~= 200)then
			commonlib.echo("==========OnCreateOrGetOrder");
			commonlib.echo(err);
			commonlib.echo(msg);
			commonlib.echo(data,true);                
            return
        end
        product[channel] = data;
        VipFullPage.orders[productCode] = product;
		 HttpWrapper.SetCacheByKey(cache_key, data)
        if(callback)then
            callback(data)
        end
    end)
end

function VipFullPage.CreateOrGetImgPath(order)
    if(not order)then
        return
    end
    local id = order.id;
	local day = ParaGlobal.GetDateFormat("yyyy-M-d")
    local filepath = string.format("temp/vip/tempqr/%s/%s.png", day, tostring(id));
	if(ParaIO.DoesFileExist(filepath))then
		return filepath;
	end
    local QR = order.QR or "";
    QR = string.match(QR, "data:image/png;base64,(.+)");
    local src = Encoding.unbase64(QR)
	
    ParaIO.CreateDirectory(filepath)
    local file = ParaIO.open(filepath, "w");
	if(file:IsValid()) then
		file:write(src,#src);
		file:close();
    end
    return filepath;
end

 -- "weixin" or "zhifubao"
function VipFullPage.OnSelectedPay(type)
    type = type or VipFullPage.pay_types.weixin
    VipFullPage.selected_pay = type; 
    local channel;
    if(type == VipFullPage.pay_types.weixin)then
        channel = "wx_pub_qr";
    elseif(type == VipFullPage.pay_types.zhifubao)then
        channel = "alipay_qr";    
    end
    VipFullPage.selected_order = nil;
    VipFullPage.OnCreateOrGetOrder(VipFullPage.selected_product, channel, function(order)
        VipFullPage.selected_order = order;
        VipFullPage.RefreshPage();
    end)
end

 -- "six_month_vip" or "twelve_month_vip"
function VipFullPage.OnSelected(type)
    type = type or VipFullPage.products_types.twelve_month_vip
    VipFullPage.selected_product = type; 
    --VipFullPage.OnSelectedPay(VipFullPage.selected_pay)

	VipFullPage.selected_order = nil;
    VipFullPage.GetQuickResponseCode(VipFullPage.selected_product, function(order)
        VipFullPage.selected_order = order;
        VipFullPage.RefreshPage();
    end)
end

function VipFullPage.Update()
	if(page and page:IsVisible())then
		VipFullPage.OnCheckOrderState();

		if(VipFullPage.selected_order)then
			local id = VipFullPage.selected_order.id;
			local state = VipFullPage.order_state_map[id];
			-- 订单状态 0：已创建, 1： 未支付，2: 已支付， 3：订单完成，4：订单关闭
			if(state == 2 or state == 3 or state == 4 )then
				VipFullPage.ClearTimer();
				VipFullPage.ClosePage();
                _guihelper.MessageBox("支付成功");
				-- 清空订单缓存
				VipFullPage.ClearOrderCacheKeys();
				KeepWorkItemManager.LoadProfile(true, function()  --刷新用户信息                  
                    GameLogic.GetFilters():apply_filters('login_with_token')
                    GameLogic.GetFilters():apply_filters('cellar.vip_notice.close')
                    GameLogic.GetFilters():apply_filters('became_vip')
               end)
			   return
			end
		end
	else
		VipFullPage.ClearTimer();
	end
end

function VipFullPage.OnCheckOrderState()
	if(not VipFullPage.selected_order)then
		return
	end
	local id = VipFullPage.selected_order.id;
	 keepwork.pay.systemOrders({
        router_params = {
        id = id,
        },
    },function(err, msg, data)
		if(err ~= 200)then
			return
		end
		VipFullPage.order_state_map[id] = data.state;
    end)
end

function VipFullPage.StartTimer()
	if(not VipFullPage.timer)then
		VipFullPage.timer = commonlib.Timer:new({callbackFunc = function(timer)
			VipFullPage.Update()
		end})
	end
	VipFullPage.timer:Change(0, 3000);
end

function VipFullPage.ClearTimer()
	if(VipFullPage.timer)then
		VipFullPage.timer:Change();
		VipFullPage.timer = nil;
	end
end

function VipFullPage.ClearOrderCacheKeys()
	local values = VipFullPage.GetOrderCacheKeysForUSer() or {};
	for k,v in pairs(values) do
		HttpWrapper.DeleteCacheByKey(k);
	end
end

-- 和用户订单关联的cache key
function VipFullPage.GetOrderCacheKeysForUSer()
	local profile = KeepWorkItemManager.GetProfile()
	local userId = profile.id;
	local item_key = string.format("VipPage_Order_CacheKeys_%s",tostring(userId));
	return GameLogic.GetPlayerController():LoadLocalData(item_key, {}, true);
end

function VipFullPage.SaveOrderCacheKeyForUser(key)
	if(not key)then
		return
	end
	local values = VipFullPage.GetOrderCacheKeysForUSer();
	values[key] = true;

	local profile = KeepWorkItemManager.GetProfile()
	local userId = profile.id;
	local item_key = string.format("VipPage_Order_CacheKeys_%s",tostring(userId));
	GameLogic.GetPlayerController():SaveLocalData(item_key, values, true);
end

function VipFullPage.GetVipStateDesc()
    local profile = KeepWorkItemManager.GetProfile()
    local state = profile.vip == 1 and "已开通" or "未开通"
    local date_desc = ""
	local b_life_time;
    if profile.vip == 1 and profile.vipDeadline == nil then
        date_desc = "永久"
		b_life_time = true;
    elseif profile.vip ~= 1 then
        date_desc = "未开通"
    else
        local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(profile.vipDeadline)
        date_desc = os.date("%Y.%m.%d", time_stamp)
    end

	if profile.vip ~= 1 then
        return "你还不是会员"
    end
	local s; 
	if(b_life_time)then
		s = "永久会员";
	else
		s = string.format("你的会员在%s后到期，续费后将自动延期", date_desc)
	end
    return s;
end

function VipFullPage.CreateKeyByParams(url, url_queries)
	url_queries = url_queries or {};
	local input_cache_url = NPL.EncodeURLQuery(url, url_queries);
	return input_cache_url;
end

function VipFullPage.CreateOrGetQRImgFile(productCode, from, QR)
	local userId = GameLogic.GetFilters():apply_filters('get_user_id') 
	productCode = productCode or ""
	from = from or "";
	local day = ParaGlobal.GetDateFormat("yyyy-M-d")
    local filepath = string.format("temp/vip/tempqrv1/%s/%s_%s_%s.png", day, tostring(userId), productCode, from);
	if(ParaIO.DoesFileExist(filepath))then
		return filepath;
	end
	QR = QR or "";
    QR = string.match(QR, "data:image/png;base64,(.+)");
    local src = Encoding.unbase64(QR)
	
    ParaIO.CreateDirectory(filepath)
    local file = ParaIO.open(filepath, "w");
	if(file:IsValid()) then
		file:write(src,#src);
		file:close();
    end
    return filepath;
end

function VipFullPage.GetQRInputUrl(productCode, from)
    local userId = GameLogic.GetFilters():apply_filters('get_user_id') 
	productCode = productCode or ""
	from = from or "";
	local hosts = {
		ONLINE = "https://keepwork.com",
		RELEASE = "http://rls.kp-para.cn",
		STAGE = "http://dev.kp-para.cn",
	};
    local httpwrapper_version = HttpWrapper.GetDevVersion();
	local host = hosts[httpwrapper_version];
	if(VipFullPage.IsDevMode())then
		productCode = "test"
	end
	local url = string.format("%s/p/vb/payOrder?userId=%d&productCode=%s&from=%s", host, userId, productCode, from);
	return url;
end

--@param:productCode: "six_month_vip" or "twelve_month_vip"
function VipFullPage.GetQuickResponseCode(productCode, callback)
	local input_url_cache = VipFullPage.GetQRInputUrl(productCode);
	local cache_item = HttpWrapper.GetCacheByKey(input_url_cache, VipFullPage.default_cache_policy);
	if(cache_item)then
        if(callback)then
            callback(cache_item)
        end
		return
	end
	local input_url = VipFullPage.GetQRInputUrl(productCode, VipFullPage.key);
	keepwork.pay.generateQR({
		text = input_url
	},function(err, msg, data)           
        if(err ~= 200)then
            return
        end
        if(callback)then
            callback(data)
        end
    end)
end

function VipFullPage.IsDevMode()
    if(System and System.options)then
        return System.options.isDevEnv;
    end
end

function VipFullPage.GetDesc2()
    local notOrganizationVipDesc = "电脑、手机、ipad均可使用~"

	if(KeepWorkItemManager.IsOrgStudentVip()) then
		local studentDeadline = KeepWorkItemManager.GetProfile().studentDeadline or "";
		studentDeadline = commonlib.timehelp.GetTimeStampByDateTime(studentDeadline)
        studentDeadline = os.date("%Y.%m.%d", studentDeadline)
		return "机构权限已激活，到期时间为 "..studentDeadline;
	end

	return notOrganizationVipDesc;
end

function VipFullPage.OnCreate()
	VipFullPage.SetActive("mouse_enter_tip",false)
	VipFullPage.SetActive("phone_captcha_error",false)
	VipFullPage.SetActive("phone_number_error",false)

	local reward_node = page:FindUIControl("reward_node")
	if reward_node and reward_node:IsValid() then
		local parent_width = 686
		reward_node.x = parent_width/2 - reward_node.width/2
	end
end

function VipFullPage.SetActive(uiname,visible)
	local pNode = ParaUI.GetUIObject(uiname)
    if pNode then
        pNode.visible = visible
    end
end

function VipFullPage.OnMouseEnter(tipUiName)
	VipFullPage.SetActive(tipUiName,true)
end

function VipFullPage.OnMouseLeave(tipUiName)
    local pNode = ParaUI.GetUIObject(tipUiName)
    if pNode then
        pNode.visible = false
    end
end

function VipFullPage.HasVipReward()
	return VipFullPage.has_vip_reward
end
