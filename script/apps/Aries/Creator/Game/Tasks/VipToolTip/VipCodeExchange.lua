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
    local view_width = 400
    local view_height = 300
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchange.html",
        name = "VipCodeExchange.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 11,
        --app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
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
end

function VipCodeExchange.Exchange(code)
    local code  = code or ""
    if code and code ~= "" then
        if string.find(code, "[a-zA-Z]+") then
            keepwork.activateCodes.activate({
                key=code,
            },function(err, msg, data)
                if err == 200 then
                    local day = data.period
                    if day > 0 then
                        local goodName = ""
                        local exchange = data.exchangeResult
                        if exchange then
                            local goods = exchange.gainList or {}
                            for i = 1 ,#goods do
                                goodName = goodName..goods[i].goodsInfo.name.."," 
                            end
                        end
                        local str = goodName ~= "" and "恭喜你获得了"..day.."天会员,["..""..goodName.."]" or "恭喜你获得了"..day.."天会员"
                        VipCodeExchangeResult.ShowView(str)
                        VipCodeExchange.RefreshUserInfo()
                        VipCodeExchange.ClosePage()   
                    else
                        --GameLogic.AddBBS(nil,"会员兑换的天数不可小于0")
                        local goodName = ""
                        local exchange = data.exchangeResult
                        if exchange then
                            local goods = exchange.gainList or {}
                            for i = 1 ,#goods do
                                local goodNum = goods[i].amount
                                goodName = goodName..goods[i].goodsInfo.name.."x"..goodNum.."," 
                            end
                        end
                        if goodName ~= "" then
                            local str = "兑换成功！"
                            VipCodeExchangeResult.ShowView(str)
                            VipCodeExchange.ClosePage()   
                            return
                        end
                        GameLogic.AddBBS(nil,"兑换配置不合理")
                    end
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