--[[
    author:pbb
    date:
    Desc:
    use lib:
    local VipCodeExchange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchange.lua") 
    VipCodeExchange.ShowView()
]]
local VipCodeExchangeResult = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchangeResult.lua") 
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
local RedSummerCampCourseScheduling = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampCourseSchedulingV2.lua") 
local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/ide/timer.lua");

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local VipCodeExchange = NPL.export()

local page = nil
function VipCodeExchange.OnInit()
    page = document:GetPageCtrl();
end

function VipCodeExchange.ShowView()
    local view_width = 0--400
    local view_height = 0--300
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchange.html",
        name = "VipCodeExchange.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 11,
        cancelShowAnimation = true,
        directPosition = true,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function VipCodeExchange.ClosePage()
    if page then
        page:CloseWindow()
    end
end

function VipCodeExchange.RefreshUserInfo()
    commonlib.TimerManager.SetTimeout(function()  
        KeepWorkItemManager.LoadProfile(false, function()  --刷新用户信息                  
            GameLogic.GetFilters():apply_filters('became_vip')
            VipPage.ClosePage()
        end)
    end, 3000)

    UserPermission.LoadUserRoles()
end

function VipCodeExchange.Exchange(code)
    local code  = code or ""
    if code and code ~= "" then
        if string.find(code, "[a-zA-Z]+") then
            keepwork.activateCodes.activate({
                key=code,
            },function(err, msg, data)
                if err == 200 then
                    VipCodeExchange.ClosePage()  
                    local day = data.period
                    local role = data.role
                    VipCodeExchange.RefreshUserInfo()
                    RedSummerCampCourseScheduling.ExchangeLessonSuc()
                    VipCodeExchangeResult.ShowView("恭喜你激活码使用成功。")                    
                else
                    if data and data.message then
                        VipCodeExchangeResult.ShowView(data.message)
                    end
                end
            end)
            return 
        end
        keepwork.paracraftVipCode.activate({
            key=code,
        },function(err, msg, data) 
            if err == 200 then
                VipCodeExchange.ClosePage()    
                if data and type(data) == 'table' and data.message then
					VipCodeExchangeResult.ShowView("恭喜你激活了帕拉卡会员礼包")
					VipCodeExchange.RefreshUserInfo()
                end 
            else
                VipCodeExchange.ExchangeOrgCode(code)
            end
        end)
    else
        VipCodeExchangeResult.ShowView("请输入正确的兑换码")
    end
end

function VipCodeExchange.ExchangeOrgCode(code)
    keepwork.orgActivateCode.activate({
        key=code,
    },function (err, msg, data)
        if err == 200 then
            VipCodeExchange.ClosePage()    
            if data and type(data) == 'table' and data.message then
                VipCodeExchangeResult.ShowView("加入机构成功")
                VipCodeExchange.RefreshUserInfo()
            end 
            return
        end
        -- echo(msg)
        VipCodeExchangeResult.ShowView("使用激活码激活失败！")
        -- if data and type(data) == 'table' and data.message then
        --     VipCodeExchangeResult.ShowView(data.message)
        -- end

        -- if data and type(data) == "string" then
        --     local dataParams = {}
        --     NPL.FromJson(data, dataParams)

        --     if dataParams and type(dataParams) == 'table' and dataParams.message then
        --         VipCodeExchangeResult.ShowView(dataParams.message)
        --     end
        -- end
    end)
end