--[[
    author:pbb
    date:
    Desc:
    use lib:
    local VipCodeExchange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchange.lua") 
    VipCodeExchange.ShowView()
]]
local VipCodeExchangeResult = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchangeResult.lua") 
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local VipCodeExchange = NPL.export()

local page = nil
function VipCodeExchange.OnInit()
    page = document:GetPageCtrl();
end

function VipCodeExchange.ShowView()
    local view_width = 400
    local view_height = 200
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchange.html",
        name = "VipCodeExchange.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 4,
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

function VipCodeExchange.Exchange(code)
    local code  = code or ""
    if code and code ~= "" then
        keepwork.paracraftVipCode.activate({
            key=code,
        },function(err, msg, data)           
            if err == 200 then
                VipCodeExchange.ClosePage()    
                if data and type(data) == 'table' and data.message then
                    VipCodeExchangeResult.ShowView("恭喜你激活了帕拉卡会员礼包")
                end    
                return
            end
            if data and type(data) == 'table' and data.message then
                --GameLogic.AddBBS(nil, format(L"激活失败，原因：%s（%d）", data.message, err), 3000, "255 0 0")
                VipCodeExchangeResult.ShowView(data.message)
            end
    
            if data and type(data) == "string" then
                local dataParams = {}
                NPL.FromJson(data, dataParams)
    
                if dataParams and type(dataParams) == 'table' and dataParams.message then
                    --GameLogic.AddBBS(nil, format(L"激活失败，原因：%s（%d）", dataParams.message, err), 3000, "255 0 0")
                    VipCodeExchangeResult.ShowView(dataParams.message)
                end
            end
        end)
    else
        VipCodeExchangeResult.ShowView("请输入正确的兑换码")
    end
end