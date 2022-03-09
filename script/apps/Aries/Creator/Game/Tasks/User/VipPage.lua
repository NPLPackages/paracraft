--[[
Title: VipPage
Author(s): leio
Date: 2021/7/9
Desc:  
Use Lib:
-------------------------------------------------------
local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
VipPage.ShowPage();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/timer.lua");
local Encoding = commonlib.gettable("System.Encoding");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
NPL.load("(gl)script/ide/DateTime.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
NPL.load("(gl)script/ide/DateTime.lua");

local VipPage = NPL.export()
local page

VipPage.products_types = {
	twelve_month_vip = "twelve_month_vip", 
	six_month_vip = "six_month_vip"
};
VipPage.pay_types = {
	weixin = "weixin", 
	zhifubao = "zhifubao"
};


VipPage.products = {};
VipPage.loaded_products = false;
VipPage.selected_product = VipPage.products_types.twelve_month_vip; -- "six_month_vip" or "twelve_month_vip"
VipPage.selected_pay = VipPage.pay_types.weixin; -- "weixin" or "zhifubao"
VipPage.orders = {};
VipPage.selected_order = nil;
VipPage.order_state_map = {};
VipPage.timer = nil;
VipPage.desc = nil; -- vip功能描述
VipPage.default_cache_policy = "access plus 1 month";
VipPage.showRealNameGift = false
function VipPage.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = VipPage.OnCreate
end
function VipPage.GetPageCtrl()
    return page;
end
function VipPage.RefreshPage()
	if(page)then
		page:Refresh(0);
	end
end
function VipPage.ClosePage()
	if(page)then
		page:CloseWindow(true)
	end
end
function VipPage.VipIsValidCallback()
	VipPage.ClosePage();
end

function VipPage.ShowPage(key, desc)

	VipPage.selected_order = nil;
	VipPage.order_state_map = {};
	VipPage.orders = {};
	GameLogic.GetFilters():remove_filter("became_vip", VipPage.VipIsValidCallback);
	GameLogic.GetFilters():add_filter("became_vip", VipPage.VipIsValidCallback);
	VipPage.LoadPruducts(function(v)
		if(v)then
			VipPage.ShowPage__(key, desc);
			VipPage.OnSelected();
			--VipPage.StartTimer();
		end
	end)
end
function VipPage.ShowPage__(key, desc)
	VipPage.key = key; 
	VipPage.desc = desc; -- vip功能描述
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.funnel.open', { from = key })
    local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/User/VipPage.html",
			name = "VipPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 10,
			directPosition = true,
				align = "_ct",
				x = -690/2,
				y = -530/2 + 15,
				width = 690,
				height = 530,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	-- 更新奖励显示
	-- local is_verified = GameLogic.GetFilters():apply_filters('store_get', 'user/isVerified');
	-- if not is_verified then
	-- 	local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')
	-- 	local machineCode = SessionsData:GetDeviceUUID()
	-- 	keepwork.user.macAddresses({
	-- 		router_params = {
	-- 			id = machineCode,
	-- 		}
	-- 	},function(err, msg, data)
	-- 		VipPage.has_vip_reward = true
	-- 		if err == 200 then
	-- 			if data and data.realnameUserId and data.realnameUserId ~= 0 then
	-- 				VipPage.has_vip_reward = false
	-- 			end
	-- 		end
	-- 		VipPage.RefreshPage();
	-- 	end)
	-- end
end

-- 加载产品列表，获取价格
function VipPage.LoadPruducts(callback)
	if(VipPage.loaded_products)then
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
	local cache_key = VipPage.CreateKeyByParams("VipPage.LoadPruducts.v1")
	local cache_item = HttpWrapper.GetCacheByKey(cache_key, VipPage.default_cache_policy);
	if(cache_item)then
		VipPage.products = cache_item;
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
        VipPage.products = data.products;
		 HttpWrapper.SetCacheByKey(cache_key, VipPage.products);
		if(callback)then
			callback(true);
		end
    end)
end
-- get product info
-- @param product_type: "six_month_vip" or "twelve_month_vip"
function VipPage.GetProduct(product_type)
	if(not product_type)then
		return
	end
	for k,v in ipairs(VipPage.products) do
		if(v.code == product_type)then
			return v;
		end
	end
end
--@param:productCode: "six_month_vip" or "twelve_month_vip"
--@param:channel: "wx_pub_qr" or "alipay_qr"
function VipPage.OnCreateOrGetOrder(productCode, channel, callback)

    local product = VipPage.orders[productCode] or {};
    if(product)then
        local order = product[channel];
        if(order)then
            if(callback)then
                callback(order)
            end
            return
        end
    end
    local product_template = VipPage.GetProduct(productCode);
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
	local cache_key = VipPage.CreateKeyByParams("VipPage.OnCreateOrGetOrder.v1", url_queries)
	local cache_item = HttpWrapper.GetCacheByKey(cache_key, VipPage.default_cache_policy);
	VipPage.SaveOrderCacheKeyForUser(cache_key);
	if(cache_item)then
		product[channel] = cache_item;
        VipPage.orders[productCode] = product;
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
        VipPage.orders[productCode] = product;
		 HttpWrapper.SetCacheByKey(cache_key, data)
        if(callback)then
            callback(data)
        end
    end)
end
 function VipPage.CreateOrGetImgPath(order)
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
function VipPage.OnSelectedPay(type)
    type = type or VipPage.pay_types.weixin
    VipPage.selected_pay = type; 
    local channel;
    if(type == VipPage.pay_types.weixin)then
        channel = "wx_pub_qr";
    elseif(type == VipPage.pay_types.zhifubao)then
        channel = "alipay_qr";    
    end
    VipPage.selected_order = nil;
    VipPage.OnCreateOrGetOrder(VipPage.selected_product, channel, function(order)
        VipPage.selected_order = order;
        VipPage.RefreshPage();
    end)

end
 -- "six_month_vip" or "twelve_month_vip"
function VipPage.OnSelected(type)
    type = type or VipPage.products_types.twelve_month_vip
    VipPage.selected_product = type; 
    --VipPage.OnSelectedPay(VipPage.selected_pay)

	VipPage.selected_order = nil;
    VipPage.GetQuickResponseCode(VipPage.selected_product, function(order)
        VipPage.selected_order = order;
        VipPage.RefreshPage();
    end)

end

function VipPage.Update()
	if(page and page:IsVisible())then
		VipPage.OnCheckOrderState();

		if(VipPage.selected_order)then
			local id = VipPage.selected_order.id;
			local state = VipPage.order_state_map[id];
			-- 订单状态 0：已创建, 1： 未支付，2: 已支付， 3：订单完成，4：订单关闭
			if(state == 2 or state == 3 or state == 4 )then
				VipPage.ClearTimer();
				VipPage.ClosePage();
                _guihelper.MessageBox("支付成功");
				-- 清空订单缓存
				VipPage.ClearOrderCacheKeys();
				KeepWorkItemManager.LoadProfile(true, function()  --刷新用户信息                  
                    GameLogic.GetFilters():apply_filters('login_with_token')
                    GameLogic.GetFilters():apply_filters('cellar.vip_notice.close')
                    GameLogic.GetFilters():apply_filters('became_vip')
               end)
			   return
			end
		end
	else
		VipPage.ClearTimer();
	end

end
function VipPage.OnCheckOrderState()
	if(not VipPage.selected_order)then
		return
	end
	local id = VipPage.selected_order.id;
	 keepwork.pay.systemOrders({
        router_params = {
        id = id,
        },
    },function(err, msg, data)
		if(err ~= 200)then
			return
		end
		VipPage.order_state_map[id] = data.state;
    end)
end
function VipPage.StartTimer()
	if(not VipPage.timer)then
		VipPage.timer = commonlib.Timer:new({callbackFunc = function(timer)
			VipPage.Update()
		end})
	end
	VipPage.timer:Change(0, 3000);
end
function VipPage.ClearTimer()
	if(VipPage.timer)then
		VipPage.timer:Change();
		VipPage.timer = nil;
	end
end
function VipPage.ClearOrderCacheKeys()
	local values = VipPage.GetOrderCacheKeysForUSer() or {};
	for k,v in pairs(values) do
		HttpWrapper.DeleteCacheByKey(k);
	end
end
-- 和用户订单关联的cache key
function VipPage.GetOrderCacheKeysForUSer()
	local profile = KeepWorkItemManager.GetProfile()
	local userId = profile.id;
	local item_key = string.format("VipPage_Order_CacheKeys_%s",tostring(userId));
	return GameLogic.GetPlayerController():LoadLocalData(item_key, {}, true);
end
function VipPage.SaveOrderCacheKeyForUser(key)
	if(not key)then
		return
	end
	local values = VipPage.GetOrderCacheKeysForUSer();
	values[key] = true;

	local profile = KeepWorkItemManager.GetProfile()
	local userId = profile.id;
	local item_key = string.format("VipPage_Order_CacheKeys_%s",tostring(userId));
	GameLogic.GetPlayerController():SaveLocalData(item_key, values, true);
end

function VipPage.GetVipStateDesc()
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

--    if profile.vip ~= 1 then
--        return string.format("会员状态：%s", state)
--    end
--
--    return string.format("会员状态：%s &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;有效日期：%s", state, date_desc)
end

function VipPage.CreateKeyByParams(url, url_queries)
	url_queries = url_queries or {};
	local input_cache_url = NPL.EncodeURLQuery(url, url_queries);
	return input_cache_url;
end

function VipPage.CreateOrGetQRImgFile(productCode, from, QR)
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
function VipPage.GetQRInputUrl(productCode, from)
    local userId = GameLogic.GetFilters():apply_filters('get_user_id') 
	productCode = productCode or ""
	from = from or "";
	local hosts = {
		ONLINE = "https://keepwork.com",
		RELEASE = "http://rls.kp-para.cn",
	};
    local httpwrapper_version = HttpWrapper.GetDevVersion();
	local host = hosts[httpwrapper_version];
	if(VipPage.IsDevMode())then
		productCode = "test"
	end
	local url = string.format("%s/p/vb/payOrder?userId=%d&productCode=%s&from=%s", host, userId, productCode, from);
	return url;
end

--@param:productCode: "six_month_vip" or "twelve_month_vip"
function VipPage.GetQuickResponseCode(productCode, callback)
	local input_url_cache = VipPage.GetQRInputUrl(productCode);
	local cache_item = HttpWrapper.GetCacheByKey(input_url_cache, VipPage.default_cache_policy);
	if(cache_item)then
        if(callback)then
            callback(cache_item)
        end
		return
	end
	local input_url = VipPage.GetQRInputUrl(productCode, VipPage.key);
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
function VipPage.IsDevMode()
    if(System and System.options)then
        return System.options.isDevEnv;
    end
end

function VipPage.GetDesc2()
    local notOrganizationVipDesc = "电脑、手机、ipad均可使用~"

	if(KeepWorkItemManager.IsOrgStudentVip()) then
		local studentDeadline = KeepWorkItemManager.GetProfile().studentDeadline or "";
		studentDeadline = commonlib.timehelp.GetTimeStampByDateTime(studentDeadline)
        studentDeadline = os.date("%Y.%m.%d", studentDeadline)
		return "机构权限已激活，到期时间为 "..studentDeadline;
	end

	return notOrganizationVipDesc;
end


function VipPage.OnCreate()
	VipPage.SetActive("mouse_enter_tip",false)
	VipPage.SetActive("phone_captcha_error",false)
	VipPage.SetActive("phone_number_error",false)

	local reward_node = page:FindUIControl("reward_node")
	if reward_node and reward_node:IsValid() then
		local parent_width = 686
		reward_node.x = parent_width/2 - reward_node.width/2
	end
end

function VipPage.SetActive(uiname,visible)
	local pNode = ParaUI.GetUIObject(uiname)
    if pNode then
        pNode.visible = visible
    end
end

function VipPage.OnMouseEnter(tipUiName)
	VipPage.SetActive(tipUiName,true)
end

function VipPage.OnMouseLeave(tipUiName)
    local pNode = ParaUI.GetUIObject(tipUiName)
    if pNode then
        pNode.visible = false
    end
end

function VipPage.HasVipReward()
	return VipPage.has_vip_reward
end