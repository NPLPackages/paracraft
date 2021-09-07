--[[
    author:pbb
    date:
    Desc:
    use lib:
    local GetRewardResult = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/GetRewardResult.lua") 
    GetRewardResult.ShowView({gsId=10005,num=100})
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local GetRewardResult = NPL.export()
local gsId = nil
local goodNum = 0
local page = nil
function GetRewardResult.OnInit()
    page = document:GetPageCtrl();
end

function GetRewardResult.ShowView(reward)
    gsId = reward.gsId
    goodNum = reward.num
    local view_width = 470
    local view_height = 350
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/CreateReward/GetRewardResult.html",
        name = "GetRewardResult.ShowView", 
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
end

function GetRewardResult.GetRewardIcon()
    if not gsId then
        return ""
    end
    local icons = {"wuping_douzi_36X33_32bits.png#0 0 36 32","dianzan_32X32_32bits.png#0 0 32 32","pifu_64X64_32bits.png#0 0 64 64"}
    if gsId == 998 then
        return string.format("Texture/Aries/Creator/keepwork/CreateReward/%s",icons[1])
    elseif gsId == 10005 then
        return string.format("Texture/Aries/Creator/keepwork/CreateReward/%s",icons[2])
    elseif gsId == 10006 then
        return string.format("Texture/Aries/Creator/keepwork/CreateReward/%s",icons[3])
    end
end

function GetRewardResult.GetIconStyle()
    return string.format("margin-left:6px;margin-top:6px; width: 48px; height: 48px; background: url(%s);",GetRewardResult.GetRewardIcon())
end

function GetRewardResult.GetRewardTips()
    if not gsId then
        return ""
    end
    if gsId == 998 then
        return "知识豆"
    elseif gsId == 10005 then
        return "世界点赞"
    elseif gsId == 10006 then
        return "皮肤碎片"
    end
end

function GetRewardResult.IsGetLikeItem()
    if not gsId then
        return false
    end
    return gsId == 10005
end

function GetRewardResult.GetRewardDesc()    
    local str = string.format("恭喜获得%d%s,已存入背包中",goodNum,GetRewardResult.GetRewardTips())
    if GetRewardResult.IsGetLikeItem() then
        str = string.format("恭喜获得%d个作品点赞数,你可以去选择要增加赞数的作品",goodNum)
    end   
    return str
end