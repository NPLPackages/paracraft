-- UI
local RegisterModal = NPL.load("(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua")

-- service
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua")
local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
isClickedGetPhoneCaptcha = false

local VipFullPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipFullPage.lua");

local clickConcealPayButtonTimes = 1

function ClosePage()
    if VipFullPage.showRealNameGift then
        VipFullPage.showRealNameGift = false
        VipFullPage.RefreshPage()
    else
        VipFullPage.GetPageCtrl():CloseWindow();
    end
end

function OnOpenVipCode()
    local VipCodeExchange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchange.lua")
    VipCodeExchange.ShowView();
end

function IsSelected(type)
    return VipFullPage.selected_product == type
end

-- "six_month_vip" or "twelve_month_vip"
function OnSelected(type)
    VipFullPage.OnSelected(type);
end

function IsSelectedPay(type)
    --return VipFullPage.selected_pay == type
    return false;
end

-- "weixin" or "zhifubao"
function OnSelectedPay(type)
    VipFullPage.OnSelectedPay(type);
end

function GetQR()
    if(VipFullPage.selected_order)then
        --local filepath = VipFullPage.CreateOrGetImgPath(VipFullPage.selected_order);
        local QR = VipFullPage.selected_order.data;
        local filepath = VipFullPage.CreateOrGetQRImgFile(VipFullPage.selected_product, VipFullPage.key, QR)
        return filepath;
    end
end

function GetOrderID()
    if(VipFullPage.selected_order)then
        return VipFullPage.selected_order.id
    end
end

function GetOrderState()
    if(VipFullPage.selected_order)then
    return VipFullPage.order_state_map[VipFullPage.selected_order.id];
    end
end

function OnClickAndroid()
    local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")
    VipToolNew.OnClickbuy()
end

function GetPlatform()
    return System.os.GetPlatform();
end

function OpenParentsPage()
    VipFullPage.GetPageCtrl():CloseWindow();
    local RedSummerCampParentsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampParentsPage.lua");
    RedSummerCampParentsPage.Show();
end

function IsDevMode()
    if(System and System.options)then
        return System.options.isDevEnv;
    end
end

function HasDesc()
    if(VipFullPage.desc)then
        return true;
    end
end

function GetDesc()
    if(VipFullPage.desc)then
        return string.format("(%s)",VipFullPage.desc);
    end
end

function GetDesc2()
    return VipFullPage.GetDesc2();
end

function GetVipStateDesc()
    return VipFullPage.GetVipStateDesc()
end

function CanShowVip()
    local platform = System.os.GetPlatform();

    if (platform == "ios" or platform == "mac") then
        return false;
    end

    return true;
end

function ConcealPay()
    if (System.os.GetPlatform() ~= "ios" and
        System.os.GetPlatform() ~= "mac") then
        return
    end

    if (clickConcealPayButtonTimes >= 3) then
        clickConcealPayButtonTimes = 1
        OnOpenVipCode()
    else
        if (clickConcealPayButtonTimes >= 2 and clickConcealPayButtonTimes < 3) then
            GameLogic.AddBBS(nil, format(L"再按%d次打开激活页面", 3 - clickConcealPayButtonTimes), 1000, "128 128 255")
        end
        clickConcealPayButtonTimes = clickConcealPayButtonTimes + 1
    end
end

function need_certificate()
    local is_verified = GameLogic.GetFilters():apply_filters('store_get', 'user/isVerified');
    if is_verified then
        return false
    else
        return true
    end
end

function OnMouseEnter(name,mcmlNode)
    local tipUiName = mcmlNode:GetAttribute("tip")
    VipFullPage.OnMouseEnter(tipUiName)
end

function OnMouseLeave(name,mcmlNode)
    local tipUiName = mcmlNode:GetAttribute("tip")
    VipFullPage.OnMouseLeave(tipUiName)
end

hasBeenSent = false

function send()
    if hasBeenSent then
        return 
    end

    local phoneNumber = VipFullPage.GetPageCtrl():GetValue('phonenumber')

    if not GameLogic.GetFilters():apply_filters('helper.validated.phone', phoneNumber) then
        GameLogic.AddBBS(nil, L'手机格式错误', 3000, '255 0 0')
        return
    end

    hasBeenSent = true

    local times = 60

    local timer = commonlib.Timer:new({
        callbackFunc = function(timer)
            VipFullPage.GetPageCtrl():SetValue('send_button', format('%s(%ds)', L'重新发送', times))

            if times == 0 then
                hasBeenSent = false
                VipFullPage.GetPageCtrl():SetValue('send_button', L'发送短信')
                timer:Change(nil, nil)
                GameLogic.GetFilters():apply_filters("store_unsubscribe", "user/ParentPhoneVerification")
            end

            times = times - 1
        end
    })

    GameLogic.GetFilters():apply_filters(
        'api.keepwork.users.parent_cellphone_captcha',
        phoneNumber,
        function(data, err)
            if err ~= 200 or
               data == nil or
               data == '' then
                return;
            end

            GameLogic.AddBBS(nil, L'发送成功', 3000, '0 255 0');
        end
    )

    timer:Change(1000, 1000);

    GameLogic.GetFilters():apply_filters(
        "store_subscribe",
        "user/ParentPhoneVerification",
        function()
            timer:Change(nil, nil)

            GameLogic.GetFilters():apply_filters("store_unsubscribe", "user/ParentPhoneVerification")
            GameLogic.GetFilters():apply_filters("store_set", "user/isVerified", true)
            GameLogic.GetFilters():apply_filters("service.session.check_verify")

            VipFullPage.RefreshPage()
            RedSummerCampMainPage.RefreshPage()
        end
    )
end

function ClearNumberErrorTip()
    VipFullPage.SetActive("phone_number_error",false)
end

function ClearCaptchaErrorTip()
    VipFullPage.SetActive("phone_captcha_error",false)
end

function HasRealName()
    return KeepworkServiceSession:IsRealName()
end

function home_install()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldShare/InstanllGuide.lua").Show();
end

function IsConnectTeacherSever()
    if System.options.isChannel_430 then
        return true;
    end
end

function IsOfflineMode()
    local offline = not GameLogic.GetFilters():apply_filters('is_signed_in')
    return offline
end

function ShowRealNameGift()
    return VipFullPage.showRealNameGift
end

function OnLogin()
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
    GameLogic.GetFilters():apply_filters('check_signed_in', "请先登录", function(result)
            if result == true then
            commonlib.TimerManager.SetTimeout(function()
            KeepWorkItemManager.LoadProfile(true, function()  --刷新用户信息                  
                VipFullPage.RefreshPage()
                RedSummerCampMainPage.RefreshPage()
                end)
                
                end, 500)
            end
        end)
    end
end

function OnClickIKnow()
    VipFullPage.showRealNameGift = false;
    VipFullPage.RefreshPage();
end

function HasVipReward()
    return VipFullPage.HasVipReward();
end

function GridDs(index)
	if (index == nil) then    
		return #VipFullPage.GridDs;
	else
		return VipFullPage.GridDs[index];
	end
end

function GetPriceDesc()
	if IsSelected("twelve_month_vip") then
		return L"已优惠320元";
	end

	return L"已优惠102元";
end

function GetPrice()
    if IsSelected("twelve_month_vip") then
        return L"880元";
    end

    return L"498元";
end

function OnOpenVipQuestionPage()
    local VipQuestionPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipQuestionPage.lua");
    VipQuestionPage.ShowPage();
end
