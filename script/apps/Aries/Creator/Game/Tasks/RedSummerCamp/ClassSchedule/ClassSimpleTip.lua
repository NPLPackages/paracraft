--[[
Title: 
Author(s): hyz
Date: 2022/6/14
Desc: 课程表相关的几个建议提示弹窗
use the lib:
------------------------------------------------------------
local ClassSimpleTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSimpleTip.lua") 
ClassSimpleTip.ShowIntoClassRoomGuide()
-------------------------------------------------------
]]
local ClassManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/ClassManager/ClassManager.lua");
local ClassSimpleTip = NPL.export()

local page;
function ClassSimpleTip.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ClassSimpleTip.OnClosed;
    page.OnCreate = ClassSimpleTip.OnCreated;
end

function ClassSimpleTip.OnCreated()

end

function ClassSimpleTip.OnClosed()
    page = nil 
end

function ClassSimpleTip.ClosePage()
    if page then
        page:CloseWindow()
    end
end

local btn_name_enterClass = L"进入课堂"
local btn_confirm = L"确定"
local btn_cancel = L"取消"
function ClassSimpleTip.OnBtnClick(name)
    repeat
        if name=="ShowIntoClassRoomGuide" then --课程开始了，跳转PPT页面
            if ClassSimpleTip.enterClassRoom_callback then
                ClassSimpleTip.enterClassRoom_callback()
            end
        elseif name=="ShowIsClassTimeTip" then --到了上课时间，上课
            if ClassSimpleTip.startClass_callback then
                ClassSimpleTip.startClass_callback()
            end
        elseif name=="ShowInviteCodeTip" then --邀请码，关闭
        elseif name=="ShowJumpTo_adjustSchedule" then --跳转课程中心
            ClassSimpleTip.OnBtnJumpKeepWork_adjustSchedule()
        elseif name=="ShowAfterClassConfirmTip" then --下课
            if ClassSimpleTip.afterClass_callback then
                ClassSimpleTip.afterClass_callback()
            end
        elseif name=="copy_invitecode" then
            local text_invitecode = page:GetValue("text_invitecode")
            ParaMisc.CopyTextToClipboard(text_invitecode);
            GameLogic.AddBBS(nil,L"班级ID已复制到剪贴板")
            break
        end
        ClassSimpleTip.ClosePage()
    until true
    
end

--学生身份，显示进入课堂提示
function ClassSimpleTip.ShowIntoClassRoomGuide(tip,callback,noClose)
    if System.options.channelId_431 then
        return
    end
    ClassSimpleTip.enterClassRoom_callback = callback
    local confirm_text = btn_name_enterClass
    local cancel_text = nil
    local tipstyle = "font-size: 20px;padding-top: 26px;text-align: center;"
    local key = "ShowIntoClassRoomGuide"
    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSimpleTip.html?key=%s&tip=%s&confirm_text=%s&tipstyle=%s&noClose=%s",key,tip,confirm_text,tipstyle,tostring(not (not noClose))), 
        name = "ClassSimpleTip.ShowIntoClassRoomGuide", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        bShow = true,
        click_through = false, 
        zorder = 0,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -496/2,
            y = -234/2,
            width = 496,
            height = 234,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

--到了上课时间，是否开始上课
function ClassSimpleTip.ShowIsClassTimeTip(tip,callback,url_adjustSchedule)
    ClassSimpleTip.startClass_callback = callback
    ClassSimpleTip.url_adjustSchedule = url_adjustSchedule
    local confirm_text = btn_name_enterClass
    local cancel_text = nil
    local key = "ShowIsClassTimeTip"
    local extxml = [[
        <div valign="bottom" align="center" width="280px" height="45px" style="position: relative;margin-bottom: -15px;">
            <div align="center" style="text-align:center; float: left; font-size: 12px;color:#2e9be7" onclick="ClassSimpleTip.OnBtnJumpKeepWork_adjustSchedule"><%= L"*课程计划有变，去调整排课信息"%></div>
        </div>

        
    ]]
    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSimpleTip.html?key=%s&tip=%s&confirm_text=%s&cancel_text=%s&btn_bottom_margin=34px&extxml=%s",key,tip,btn_confirm,btn_cancel,extxml), 
        name = "ClassSimpleTip.ShowIsClassTimeTip", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 0,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -496/2,
            y = -234/2,
            width = 496,
            height = 234,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end


function ClassSimpleTip.OnCheck(bool)
    local isChecked = bool
    -- GameLogic.AddBBS(nil,tostring(bool))
end


--课程正式开始，显示邀请码
function ClassSimpleTip.ShowInviteCodeTip(classInviteCode)
    local tip = string.format(L"课程正式开始，请将下方的邀请码告知学生，让还未加入班级的学生加入班级和课堂中","")
    local confirm_text = btn_name_enterClass
    local cancel_text = nil
    local key = "ShowInviteCodeTip"
    local tipstyle = "font-size: 16px;padding-top: 20px;text-align: left;"
    classInviteCode = classInviteCode or ""
    local extxml = [[
        <div valign="bottom" align="center" width="280px" height="45px" style="position: relative;margin-bottom: 65px;">
            <div style="float: left; font-size: 16;margin-top: 4px;"><%= L"班级ID:" %></div>
            <div  style=" margin-left: 6px;margin-right: 6px; float: left; background:url(Texture/Aries/Creator/keepwork/vip/shuzishuru_32X32_32bits.png#0 0 32 32:14 14 14 14);" width="157" height="32">
                <label name="text_invitecode" style="height: 32px;font-size:18;margin-top: 2px;margin-left: 2px;" value="<%=classInviteCode%>"></label>
            </div>
            <div style="float: left;margin-top: 2px;">
                <input type="button" value='<%= L"复制" %>' name='copy_invitecode' onclick="ClassSimpleTip.OnBtnClick" style="float: left;text-offset-y: -2;font-weight: normal;font-size: 14; width: 56px;height: 29px; background: url(Texture/Aries/Creator/keepwork/RedSummerCamp/courses/anniu_56x29_32bits.png#0 0 56 29);"/>
            </div>
        </div>

        <div align="right" style="margin-top: 30px; margin-right: 32px;" width="200px" heigh="20px">
            <div  align="right" style="width:14px;height:11px;float: right;margin-right: 10px;margin-top: 4px;">
                <input type="checkbox" checked="false" name="dont_show_page" style="float: right; width:14px;height:11px" tooltip="是否显示模型包围盒"
                CheckedBG="Texture/Aries/Creator/keepwork/RedSummerCamp/courses/gouxuankuang_14x11_32bits.png#0 0 14 11" 
                UncheckedBG="Texture/Aries/Creator/keepwork/RedSummerCamp/courses/gouxuankuang_11x11_32bits.png#0 0 14 11"
                onclick="ClassSimpleTip.OnCheck"/>
            </div>
            <div align="right" style="float: right;margin-right: 28px; font-size: 12px;text-align: right;" width="80px">
                <%= L"不再显示" %>
            </div>
        </div>
    ]]
    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSimpleTip.html?key=%s&tip=%s&confirm_text=%s&tipstyle=%s&classInviteCode=%s&extxml=%s",key,tip,btn_confirm,tipstyle,classInviteCode,extxml), 
        name = "ClassSimpleTip.ShowInviteCodeTip", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 0,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -496/2,
            y = -234/2,
            width = 496,
            height = 234,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

--是否确定下课
function ClassSimpleTip.ShowAfterClassConfirmTip(callback)
    ClassSimpleTip.afterClass_callback = callback
    local tip = string.format(L"是否确定下课?","")
    local confirm_text = btn_confirm
    local cancel_text = btn_cancel
    local tipstyle = "font-size: 20px;padding-top: 40px;text-align: center;"
    local key = "ShowAfterClassConfirmTip"
    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSimpleTip.html?key=%s&tip=%s&confirm_text=%s&cancel_text=%s&tipstyle=%s",key,tip,confirm_text,cancel_text,tipstyle), 
        name = "ClassSimpleTip.ShowAfterClassConfirmTip", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 0,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -496/2,
            y = -234/2,
            width = 496,
            height = 234,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

ClassSimpleTip.classees_ds = {}
function ClassSimpleTip.DS_classes()
    -- ClassSimpleTip.classees_ds = {
    --     {
    --         name = "一年级1班"
    --     },
    --     {
    --         name = "一年级2班"
    --     },
    -- }
    return ClassSimpleTip.classees_ds
end

function ClassSimpleTip.GetClassName(index)
    local info = ClassSimpleTip.classees_ds[index]
    local str = info.name or ""
    if info.status==3 then
        str = str.."(已结业)"
    end
    return str
end

ClassSimpleTip._isExpland = false --是否展开
function ClassSimpleTip.OnClickExpandAllClass()
    ClassSimpleTip._isExpland = not ClassSimpleTip._isExpland
    if ClassSimpleTip._isExpland then
    else
    end
    if page then
        page:Refresh(0)
    end
end

function ClassSimpleTip.OnClickSelectClass(name)
    local idx = tonumber(name)
    local info = ClassSimpleTip.classees_ds[idx]
    ClassSimpleTip._isExpland = not ClassSimpleTip._isExpland
    if page then
        -- GameLogic.AddBBS(2,idx.."选中")
        ClassSimpleTip.curSelIdx = idx;
        page:Refresh(0)
    end
end

function ClassSimpleTip.OnBtnJumpKeepWork_createClass()
    local token = commonlib.getfield("System.User.keepworktoken")
    local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
    local urlbase = KeepworkService:GetKeepworkUrl()    

    local method = '/s/myOrganization'
    if orgUrl then
        
    end
    local url = format('%s/p?url=%s&token=%s&toCreateClass=true', urlbase, Mod.WorldShare.Utils.EncodeURIComponent(method), token or "")
    print("--------url1",url)
    if url then
        GameLogic.RunCommand("/open "..url)
    end
end

function ClassSimpleTip.OnBtnJumpKeepWork_adjustSchedule()
    
    local url = ClassSimpleTip.url_adjustSchedule
    print("--------url2",url)
    if url then
        GameLogic.RunCommand("/open "..url)
    end
end

function ClassSimpleTip.OnBtnConfirmSelectClass()
    if ClassSimpleTip.curSelIdx==nil then
        GameLogic.AddBBS(nil,"请选择班级")
        return
    end
    local idx = tonumber(ClassSimpleTip.curSelIdx)
    local info = ClassSimpleTip.classees_ds[idx]
    if info==nil then
        GameLogic.AddBBS(nil,"出错了，找不到班级",nil,"255 0 0")
        return
    end
    ClassSimpleTip.ClosePage()
    if ClassSimpleTip.chooseClassCallback then
        ClassSimpleTip.chooseClassCallback(idx)
    end
end

--选择上课班级
function ClassSimpleTip.ShowChooseClass(ds,callback)
    ClassSimpleTip.curSelIdx = nil
    ClassSimpleTip.classees_ds = ds
    ClassSimpleTip.chooseClassCallback = callback
    local tip = string.format(L"请选择上课班级","")
    local confirm_text = btn_confirm
    local cancel_text = nil
    local tipstyle = "font-size: 20px;padding-top: 15px;text-align: center;"
    local key = "ShowChooseClass"

    local ds = ClassSimpleTip.DS_classes()

    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ChooseClass.html?key=%s&tip=%s&confirm_text=%s&tipstyle=%s",key,tip,confirm_text,tipstyle), 
        name = "ClassSimpleTip.ShowChooseClass", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 0,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -496/2,
            y = -(234+160)/2+80,
            width = 496,
            height = 234+160,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

--没有排课，跳转keepWork
function ClassSimpleTip.ShowJumpTo_adjustSchedule(url_adjustSchedule)
    ClassSimpleTip.url_adjustSchedule = url_adjustSchedule
    local tip = string.format(L"该班级当前时间暂未排课，请先前往教学中心排课后再来上课","")
    local confirm_text = L"去排课"
    local cancel_text = nil
    local tipstyle = "font-size: 20px;padding-top: 30px;text-align: center;"
    local key = "ShowJumpTo_adjustSchedule"
    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/ClassSchedule/ClassSimpleTip.html?key=%s&tip=%s&confirm_text=%s&tipstyle=%s",key,tip,confirm_text,tipstyle), 
        name = "ClassSimpleTip.ShowJumpTo_adjustSchedule", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 0,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -496/2,
            y = -234/2,
            width = 496,
            height = 234,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end