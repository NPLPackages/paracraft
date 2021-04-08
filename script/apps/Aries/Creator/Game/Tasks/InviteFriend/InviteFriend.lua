--[[
    author:pbb
    date:
    Desc:
    use lib:
        local InviteFriend = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteFriend.lua")
        InviteFriend.ShowView()
]]
local InviteCopyTips = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteCopyTips.lua")
local InviteFail = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteFail.lua")
local InviteSuccess = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteSuccess.lua")
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
local InviteFriend = NPL.export()

local page = nil

InviteFriend.invitenum = 1
InviteFriend.invitecode = ""
InviteFriend.isinvited = false
InviteFriend.inviterewards = {}
InviteFriend.exchanges = {
    {
        tooltip = "海魂裤",
        index = 1,
        invitenum = 1,
    },
    {
        tooltip ="黄色海魂衫",
        index = 2,
        invitenum = 3,
    },
    {
        tooltip ="蓝色小书包",
        index = 3,
        invitenum = 7,
    },
    {
        tooltip ="超大气球帽",
        index = 4,
        invitenum = 15,
    }
}
function InviteFriend.OnInit()
    page = document:GetPageCtrl();
end

function InviteFriend.GetPageCtrl()
    return page 
end

function InviteFriend.ShowView()
    keepwork.invitefriend.invitationInfo({},function(err, msg, data)        
        if err == 200 then
            InviteFriend.InitInviteInfo(data)
            InviteFriend.ShowPage()
        else
            _guihelper.MessageBox("数据异常~")
        end
    end)    
end

function InviteFriend.ShowPage()
    local view_width = 770
    local view_height = 470
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/InviteFriend/InviteFriend.html",
        name = "InviteFriend.ShowView", 
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
    InviteFriend.GetMyInviteCode()
end

function InviteFriend.GetMyInviteCode()
    keepwork.invitefriend.invitationCode({},function(err, msg, data)        
        if err == 200 then
            InviteFriend.invitecode = data.invitationCode
            if page then
                page:Refresh(0.5)
            end
        end
    end)
end

function InviteFriend.InitInviteInfo(data)
    InviteFriend.isinvited = data.invited
    InviteFriend.invitenum = data.inviteCount
    InviteFriend.inviterewards = data.inviteRewards
end

function InviteFriend.CheckIsExchange(index)
    return InviteFriend.invitenum >= InviteFriend.exchanges[index].invitenum
end

function InviteFriend.CheckExchanged(index)
    local isExchanged = false
    for k,v in pairs(InviteFriend.inviterewards) do
        if v.level == index then
            isExchanged = true
            break
        end
    end
    return isExchanged
end

function InviteFriend.IsRealName()
    if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        _guihelper.MessageBox("你还没有完成实名认证，需要实名认证才可领取奖励哦。", nil, nil,nil,nil,nil,nil,{ ok = L"确定"});
        _guihelper.MsgBoxClick_CallBack = function(res)
            if(res == _guihelper.DialogResult.OK) then
                if page then
                    page:CloseWindow()
                end
                GameLogic.GetFilters():apply_filters(
                'show_certificate',
                function(result)
                    if (result) then                        
                        DockPage.RefreshPage(0.01)
                        GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                    end
                end)
            end
        end 
        return false
    end
    return true
end

function InviteFriend.ClickOk(code) 
    if not InviteFriend.IsRealName() then
        return 
    end
    if InviteFriend.isinvited then
        _guihelper.MessageBox("您已经填写过同学的邀请码了哟~")
        return
    end
    if not code or #code <= 0 then
        _guihelper.MessageBox("请输入正确的邀请码~")
        return      
    end
    keepwork.invitefriend.useInvitationCode({
        invitationCode = code,
    },function(err, msg, data)
        if err == 200 then            
            InviteSuccess.ShowView()
        elseif err == 400 then
            local errStr = data.code == 48 and "你已填写过邀请码" or "你输入的邀请码有误，请核对后重新填写"
            InviteFail.ShowView(errStr)
        else
            _guihelper.MessageBox("接口异常~")
        end
    end)
end

function InviteFriend.ClickExchange(data)
    if not InviteFriend.IsRealName() then
        return 
    end
    local item = InviteFriend.exchanges[data.index].tooltip
    keepwork.invitefriend.inviteReward({
        level = data.index,
    },function(err, msg, data)
        if err == 200 then
            _guihelper.MessageBox("兑换"..item.."成功~") 
            InviteFriend.GetInviteInfo()           
        end
    end)
end

function InviteFriend.CopyToClipboard()
    local str = string.format([[你的好友%s正在“帕拉卡”学习线上编程，现邀请你加入和他一起学习创造。快去下载安装吧，现在加入还有奖励哟，记得输入邀请码领取奖励哦
    邀请码：%s
    下载链接：https://www.paracraft.cn/download]],System.User.username,InviteFriend.invitecode)
    ParaMisc.CopyTextToClipboard(str);    
    InviteCopyTips.ShowView()
end

function InviteFriend.GetInviteInfo()
    keepwork.invitefriend.invitationInfo({},function(err, msg, data)        
        if err == 200 then
            InviteFriend.InitInviteInfo(data)
            if page then
                page:Refresh(0.01)
                local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
                KeepWorkItemManager.GetFilter():apply_filters("KeepWorkItemManager_LoadItems");
            end
        else
            _guihelper.MessageBox("数据异常~")
        end
    end)
end

function InviteFriend.ClickRealName()    
    if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        if page then
            page:CloseWindow()
        end
        GameLogic.GetFilters():apply_filters(
            'show_certificate',
            function(result)
                if (result) then
                    DockPage.RefreshPage(0.01)
                    GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                end
            end
        );
    end
end

