--[[
    local MacroCodeCampMiniPro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampMiniPro.lua");
    MacroCodeCampMiniPro.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/QRCodeWnd.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
local Encoding = commonlib.gettable("System.Encoding");
local QRCodeWnd = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.MacroCodeCamp.QRCodeWnd");
local MacroCodeCampMiniPro = NPL.export()--commonlib.gettable("WinterCamp.MacroCodeCamp")
MacroCodeCampMiniPro.schoolNum = 0
MacroCodeCampMiniPro.learnTime = 0
MacroCodeCampMiniPro.projectNum = 0
MacroCodeCampMiniPro.userName = ""
local page 

function MacroCodeCampMiniPro.WordsLimit(str)
    if (_guihelper.GetTextWidth(str, "System;16") > 132) then
        local text = commonlib.utf8.sub(str, 1, 8) .. "..";
        return text
    end
    return str
end

function MacroCodeCampMiniPro.OnInit()
	page = document:GetPageCtrl();
end

function MacroCodeCampMiniPro.ShowView()
    MacroCodeCampMiniPro.GetContentData()
    local view_width = 660
	local view_height = 610
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampMiniPro.html",
        name = "MacroCodeCampMiniPro.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 3,
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

function MacroCodeCampMiniPro.GetContentData()
    MacroCodeCampMiniPro.userName = commonlib.getfield("System.User.username")
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=MacroCodeCampMiniPro.userName}));
    keepwork.user.getinfo({
        cache_policy = System.localserver.CachePolicy:new("access plus 1 hour"),
        router_params = {
            id = id,
        }
    },function(err, msg, data)
        MacroCodeCampMiniPro.learnTime = (os.time() - commonlib.timehelp.GetTimeStampByDateTime(data.createdAt)) / (24*3600)
        MacroCodeCampMiniPro.projectNum = data.rank and data.rank.project or 0
        MacroCodeCampMiniPro.RefreshPage()
    end)

    keepwork.user.total_orgs({},function(err,msg,data)
        if(err ~= 200)then
            return
        end
        MacroCodeCampMiniPro.schoolNum = data.data and data.data.count or 0
        MacroCodeCampMiniPro.RefreshPage()
    end)
    
end

function MacroCodeCampMiniPro.RefreshPage()
    if page then
        page:Refresh(0.01)
    end
end

function MacroCodeCampMiniPro.GetContent(index)
    if index == 1 then
        return string.format("%d所学校,机构正在使用帕拉卡学习！",MacroCodeCampMiniPro.schoolNum)
    elseif index == 2 then
        return string.format("%s同学已学习%d天动画编程，拥有%d部作品",MacroCodeCampMiniPro.userName,MacroCodeCampMiniPro.learnTime,MacroCodeCampMiniPro.projectNum)
    end
end