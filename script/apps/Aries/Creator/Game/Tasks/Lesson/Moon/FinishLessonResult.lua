--[[
    author:pbb
    date:
    Desc:
    use lib:
    local FinishLessonResult = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/Moon/FinishLessonResult.lua") 
    FinishLessonResult.ShowPage(1)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local FinishLessonResult = NPL.export()
local moon_gsid = 90010 -- 数据
local moon_exid = 30049

local token_gsid = 90008 --令牌
local token_exid = 30050

local key_gsid = 90009  --钥匙
local key_exid = 30041
local m_curLesson = -1
local page = nil
local page_root
FinishLessonResult.ClientData = nil
function FinishLessonResult.OnInit()
    page = document:GetPageCtrl();
    if page then
        page_root = page:GetParentUIObject()
    end
end

function FinishLessonResult.ShowPage(curLesson)
    m_curLesson = curLesson
    local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(moon_gsid)
    if bOwn and copies > 0 then
        FinishLessonResult.ShowView()
    else
        KeepWorkItemManager.DoExtendedCost(moon_exid,function()
            FinishLessonResult.ShowView()
        end)
    end
end

function FinishLessonResult.ShowView()
    if not FinishLessonResult.CheckCanShow() then
        return
    end
    local view_width = 470
    local view_height = 350
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Lesson/Moon/FinishLessonResult.html",
        name = "FinishLessonResult.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 4,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    FinishLessonResult.ExchangeTokenOrKey()
    commonlib.TimerManager.SetTimeout(function()
        FinishLessonResult.ClosePage()
    end,5000)
end

function FinishLessonResult.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
        FinishLessonResult.ClientData = nil
    end
end

function FinishLessonResult.CheckCanShow()
    return not FinishLessonResult.CheckHasGetTokenToday() or not FinishLessonResult.CheckHasGetKeyInCurClass()
end

--判断当天是否获得令牌
function FinishLessonResult.CheckHasGetTokenToday()
    local clientData = FinishLessonResult.GetClientData()
    local moon_token = clientData["moon_token"]
    if not moon_token then
        return false
    end

    local times = tonumber(moon_token.timeStamp)
    local isGetToken = tonumber(moon_token.isGetToken) == 1
    if isGetToken and times == FinishLessonResult.GetCurDate() then
        return true
    end
    return false
end

--判断这章是否获得钥匙
function FinishLessonResult.CheckHasGetKeyInCurClass()
    local clientData = FinishLessonResult.GetClientData()
    local moon_key = clientData["moon_key"]
    if not moon_key then
        return false
    end
    local curData = moon_key[m_curLesson]
    if curData and tonumber(curData.IsGetKey) == 1 then
        return true
    end
    return false
end


function FinishLessonResult.GetCurDate()
    local server_time = QuestAction.GetServerTime()
    local year = tonumber(os.date("%Y", server_time))	
	local month = tonumber(os.date("%m", server_time))
	local day = tonumber(os.date("%d", server_time))
    local dateStamp = os.time({year = year, month = month, day = day, hour=0, min=0, sec=0})
    return dateStamp
end
--[[
令牌：一天一个
钥匙：一章一个
]]

function FinishLessonResult.ExchangeTokenOrKey()
    local isCanGetToken = false--FinishLessonResult.CheckHasGetTokenToday() == true and false or true
    local isCanGetKey = false--FinishLessonResult.CheckHasGetKeyInCurClass() == true and false or true
    if not FinishLessonResult.CheckHasGetKeyInCurClass() then isCanGetKey = true end
    if not FinishLessonResult.CheckHasGetTokenToday() then isCanGetToken = true end
    FinishLessonResult.AddItemIcon(isCanGetToken,isCanGetKey)
    
    if not FinishLessonResult.CheckHasGetTokenToday() then
        KeepWorkItemManager.DoExtendedCost(token_exid,function()
            local clientData = FinishLessonResult.GetClientData()
            local temp = clientData["moon_token"] or {}
            temp.timeStamp = FinishLessonResult.GetCurDate()
            temp.isGetToken = 1
            temp.isUse = 0
            clientData["moon_token"] = temp
            FinishLessonResult.SetClientData(clientData);
        end)
    end
    if not FinishLessonResult.CheckHasGetKeyInCurClass() then
        commonlib.TimerManager.SetTimeout(function()
            KeepWorkItemManager.DoExtendedCost(key_exid,function()
                local clientData = FinishLessonResult.GetClientData()
                local temp = clientData["moon_key"] or {}
                temp[m_curLesson] = {}
                temp[m_curLesson].IsGetKey = 1
                temp[m_curLesson].timeStamp = FinishLessonResult.GetCurDate()
                clientData["moon_key"] = temp
                FinishLessonResult.SetClientData(clientData);
            end)
            
        end,200)
        return
    end   
end

function FinishLessonResult.GetClientData()
    if FinishLessonResult.ClientData == nil then
        FinishLessonResult.ClientData = KeepWorkItemManager.GetClientData(moon_gsid) or {};
    end
    local clientData = FinishLessonResult.ClientData
    return clientData
end

function FinishLessonResult.SetClientData(clientData,cb)
    KeepWorkItemManager.SetClientData(moon_gsid, clientData, function()
        FinishLessonResult.clientData = clientData
        if cb then
            cb()
        end
    end)
end

function FinishLessonResult.IsHaveToken()
    local clientData = FinishLessonResult.GetClientData()
    local temp = clientData["moon_token"] or {}
    if temp and temp.timeStamp == FinishLessonResult.GetCurDate() and temp.isUse == 0 then
        return true
    end
    return false
end

function FinishLessonResult.UseToken()
    if FinishLessonResult.IsHaveToken() then
        local clientData = FinishLessonResult.GetClientData()
        local temp = clientData["moon_token"] or {}
        if temp and temp.timeStamp == FinishLessonResult.GetCurDate() and temp.isUse == 0 then
            temp.isUse = 1
        end
        clientData["moon_token"] = temp
        FinishLessonResult.SetClientData(clientData)
        return true
    end
    return false
end
-- 41 48   -- 33 42
function FinishLessonResult.AddItemIcon(isGetToken,isGetKey)
    local num = (isGetToken and isGetKey) and 2 or 1
    local icons = {
        {
            icon = "icon1_64X64_32bits.png;0 0 41 48",
            sizeX = 41,
            sizeY = 48,
        },
        {
            icon = "icon2_64X64_32bits.png;0 0 33 42",
            sizeX = 33,
            sizeY = 42,
        }
    }
    local tooltips = {"爬塔令牌","钥匙碎片"}
    local startX = 155 
    local startY = 110
    -- print("num ===============",num,isGetToken,isGetKey)
    if num == 2 then
        for i = 1,num do
            local giftImg = ParaUI.CreateUIObject("container", "giftbg"..i, "_lt", startX + (i-1)*90, startY, 60, 60);
            giftImg:GetAttributeObject():SetField("ClickThrough", true);
            giftImg.background = "Texture/Aries/Creator/keepwork/macro/lessonmoon/wupingdi_60X60_32bits.png;0 0 40 40:14 14 14 14"        
            page_root:AddChild(giftImg);  
    
    
            local giftItem = ParaUI.CreateUIObject("container", "giftitem"..i, "_lt", 10, 10, icons[i].sizeX, icons[i].sizeY);
            giftItem.background = string.format("Texture/Aries/Creator/keepwork/macro/lessonmoon/%s",icons[i].icon)
            giftItem.tooltip = tooltips[i]
            giftImg:AddChild(giftItem)
        end
        return 
    else

    end
    if isGetToken then
        local giftImg = ParaUI.CreateUIObject("container", "giftbg", "_lt", startX + 50, startY, 60, 60);
        giftImg:GetAttributeObject():SetField("ClickThrough", true);
        giftImg.background = "Texture/Aries/Creator/keepwork/macro/lessonmoon/wupingdi_60X60_32bits.png;0 0 40 40:14 14 14 14"        
        page_root:AddChild(giftImg);  


        local giftItem = ParaUI.CreateUIObject("container", "giftitem", "_lt", 10, 10, icons[1].sizeX, icons[1].sizeY);
        giftItem.background = string.format("Texture/Aries/Creator/keepwork/macro/lessonmoon/%s",icons[1].icon)
        giftItem.tooltip = tooltips[1]
        giftImg:AddChild(giftItem)
    end

    if isGetKey then
        local giftImg = ParaUI.CreateUIObject("container", "giftbg", "_lt", startX + 50, startY, 60, 60);
        giftImg:GetAttributeObject():SetField("ClickThrough", true);
        giftImg.background = "Texture/Aries/Creator/keepwork/macro/lessonmoon/wupingdi_60X60_32bits.png;0 0 40 40:14 14 14 14"        
        page_root:AddChild(giftImg);  


        local giftItem = ParaUI.CreateUIObject("container", "giftitem", "_lt", 10, 10, icons[2].sizeX, icons[2].sizeY);
        giftItem.background = string.format("Texture/Aries/Creator/keepwork/macro/lessonmoon/%s",icons[2].icon)
        giftItem.tooltip = tooltips[2]
        giftImg:AddChild(giftItem) 
    end
end