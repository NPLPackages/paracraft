--[[
Title: ContactTeacherPage
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
local ContactTeacherPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ContactTeacher/ContactTeacherPage.lua")
ContactTeacherPage.Show();
--]]
local ContactTeacherPage = NPL.export();
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
local server_time = 0
local page
function ContactTeacherPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ContactTeacherPage.CloseView
end

function ContactTeacherPage.Show(vip_remind_key, vip_remind_desc)
    ContactTeacherPage.vip_remind_key = vip_remind_key
    ContactTeacherPage.vip_remind_desc = vip_remind_desc
    ContactTeacherPage.ShowView()
end

function ContactTeacherPage.ShowView()
    if page and page:IsVisible() then
        return
    end
    ContactTeacherPage.HandleData()

    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ContactTeacher/ContactTeacherPage.html",
        name = "ContactTeacherPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -488/2,
        y = -385/2,
        width = 488,
        height = 385,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ContactTeacherPage.FreshView()
    local parent  = page:GetParentUIObject()
end

function ContactTeacherPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    ContactTeacherPage.FreshView()
end

function ContactTeacherPage.CloseView()
    ContactTeacherPage.ClearData()
end

function ContactTeacherPage.ClearData()
end

function ContactTeacherPage.HandleData()
end

function ContactTeacherPage.OnClickContactTeacher()
    -- body
end

function ContactTeacherPage.OnClickBuyVip()
    -- body
end

function ContactTeacherPage.GetSchoolDesc()
    local profile = KeepWorkItemManager.GetProfile() or {}
    if not profile.school or not profile.school.name then
        return
    end
    local school_name = profile.school.name
    local class_name = Keepwork:GetGradeClassName()

    local desc = string.format("您学校（%s）%s", school_name, class_name)
    return desc
end

function ContactTeacherPage.GetUserDesc()
    local profile = KeepWorkItemManager.GetProfile() or {}
    local player_name = profile.nickname
    if player_name == nil or player_name == "" then
        player_name = profile.username
    end

    if player_name == nil or player_name == "" then
        return ""
    end

    local number = profile.realname or ""
    local desc = string.format("%s 同学（手机号：%s）", player_name, number)

    return desc
end

function ContactTeacherPage.GetFunctionDesc()
    local function_desc = ContactTeacherPage.vip_remind_desc or ""
    local desc = string.format("希望贵校申请开通帕拉卡“%s”功能的使用权限。", function_desc)

    return desc
end

function ContactTeacherPage.OnClickCopy()
    local link_desc = "请点击这里联系客服申请开通：https://work.weixin.qq.com/kfid/kfcf794bf130083e719"
    local copy_desc = string.format("尊敬的老师，您好！\n%s\n%s\n%s\n%s", ContactTeacherPage.GetSchoolDesc(), ContactTeacherPage.GetUserDesc(), ContactTeacherPage.GetFunctionDesc(), link_desc)
    ParaMisc.CopyTextToClipboard(copy_desc);
    GameLogic.AddBBS(nil,"复制成功")
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.contact_teacher.copy");
end