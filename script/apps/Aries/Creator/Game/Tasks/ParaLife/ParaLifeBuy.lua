--[[
Title: ParaLifeBuy
Author(s): wyx
Date: 2022/2/17
Desc: Move common use logic from codeblock to ParaLifeBuy
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBuy.lua");
-------------------------------------------------------
]]
local ParaLifeBuy = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Paralife")
local KeepworkUsersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkUsersApi.lua")

function ParaLifeBuy:CheckBuy(productCode)
    local macAddress = ParaLifeBuy:GetMachineID(productCode)
    local isHas = GameLogic.GetPlayerController():LoadRemoteData(macAddress,false)
    return isHas
end

function ParaLifeBuy:GetMachineID(productCode)
    NPL.load("(gl)script/apps/Aries/Desktop/GameMemoryProtector.lua");
    local GameMemoryProtector = commonlib.gettable("MyCompany.Aries.Desktop.GameMemoryProtector")
    local MachineID = GameLogic.GetMachineID(ParaEngine.GetAttributeObject():GetField('MachineID', ''))
    local md5 = GameMemoryProtector.hash_func_md5(MachineID..productCode)
    return md5
end

function ParaLifeBuy:Buy(productCode,loopAsk)
    local isHas = ParaLifeBuy:CheckBuy(productCode)
    if isHas then
        self:ShowTipAlreadyBrought()
    else
        local macAddress = ParaLifeBuy:GetMachineID(productCode)
        ParaLifeBuy.macAddress = macAddress
        ParaLifeBuy.productCode = productCode
        self:CheckHasBrought(function (isHas)
            if isHas then
                GameLogic.GetPlayerController():SaveRemoteData(macAddress,isHas)
                self:ShowTipAlreadyBrought()
            else
                if ParaLifeBuy.lastOpenLink ~= nil and ParaLifeBuy.lastOpenLink ~= "" 
                    and ParaLifeBuy.macAddress ~= nil and ParaLifeBuy.macAddress ~= "" 
                    and ParaLifeBuy.productCode ~= nil and ParaLifeBuy.productCode ~= "" then
                    self:GotoBuy(ParaLifeBuy.lastOpenLink)
                    return
                else
                    KeepworkUsersApi:BuySchemes(macAddress,productCode,
                        function(data, err)
                            if err == 200 then
                                ParaLifeBuy.lastOpenLink = data.openlink
                                self:GotoBuy(data.openlink,loopAsk)
                            end
                        end,
                        function(data, err)
                           LOG.std("buy fail")
                        end
                    )
                end
            end
        end)

    end
end

function ParaLifeBuy:ShowTipAlreadyBrought()
    _guihelper.MessageBox(L"您已购买该商品，请勿重复购买")
end

function ParaLifeBuy:GotoBuy(openLink,loopAsk)
    if System.os.IsTouchMode() then
        GameLogic.RunCommand(string.format("/open -e %s",openLink))
    else
        ParaGlobal.ShellExecute("open",openLink, "","", 1);
    end
    local checkPay = function (noPayCb)
        self:CheckHasBrought(function (isHas)
            if isHas then
                GameLogic.GetPlayerController():SaveRemoteData(ParaLifeBuy.macAddress,isHas)
                ParaLifeBuy.macAddress = nil
                ParaLifeBuy.productCode = nil
                ParaLifeBuy.lastOpenLink = nil
            else
                if noPayCb ~= nil then
                    noPayCb()
                end
            end
        end)
    end
    commonlib.TimerManager.SetTimeout(function() 
        _guihelper.MessageBox(L"是否已经成功购买完成?", function(res)    
            local isHas = ParaLifeBuy:CheckBuy(ParaLifeBuy.productCode)
            if not isHas then
                checkPay(function()
					if loopAsk then
						self:GotoBuy(openLink,loopAsk)
					end
                end)
            end
        end, _guihelper.MessageBoxButtons.YesNo);
    end, 100)
end

function ParaLifeBuy:CheckHasBrought(callback)
    KeepworkUsersApi:ParalifeLicenses(ParaLifeBuy.macAddress ,ParaLifeBuy.productCode,
       function(data, err)
           if err == 200 then
               callback(data.isHas)
           end
       end,
       function(data, err)
            LOG.std("Check fail !!!")
       end
   )
end

