--[[
    活动页
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampActIntro.lua");
    local MacroCodeCampActIntro = commonlib.gettable("WinterCamp.MacroCodeCamp")
    MacroCodeCampActIntro.ShowView()

    local MacroCodeCampActIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampActIntro.lua");
    MacroCodeCampActIntro.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/QRCodeWnd.lua");
local QRCodeWnd = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.MacroCodeCamp.QRCodeWnd");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local MacroCodeCampActIntro = NPL.export()--commonlib.gettable("WinterCamp.MacroCodeCamp")

local page 
local parent_root
local strPath = ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampActIntro.lua")'
MacroCodeCampActIntro.isEnterJoin = false
local httpwrapper_version = HttpWrapper.GetDevVersion();
local projectId = GameLogic.options:GetProjectId();
MacroCodeCampActIntro.campIds = {
    ONLINE = 41570,
    RELEASE = 1471,
}
MacroCodeCampActIntro.isShowVipBtn = false

MacroCodeCampActIntro.keepworkList = {
    ONLINE = "https://keepwork.com",
    STAGE = "http://dev.kp-para.cn",
    RELEASE = "http://rls.kp-para.cn",
    LOCAL = "http://dev.kp-para.cn"
}

function MacroCodeCampActIntro.CheckCanShow()
    if MacroCodeCampActIntro.CheckIsInWinCamp() then
        return true
    end
    return false
end

function MacroCodeCampActIntro.OnInit()
    page = document:GetPageCtrl();
    parent_root  = page:GetParentUIObject()   
end

function MacroCodeCampActIntro.ShowView(isShowVip)
    if not MacroCodeCampActIntro.CheckCanShow() then
        return 
    end
    MacroCodeCampActIntro.isShowVipBtn = isShowVip or false
    local view_width = 1030
	local view_height = 600
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampActIntro.html",
        name = "MacroCodeCampActIntro.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 2,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
            align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    MacroCodeCampActIntro.OnRefreshPage()
end

function MacroCodeCampActIntro.GetQRCodeUrl()
    local urlbase = MacroCodeCampActIntro.keepworkList[httpwrapper_version];
	local uerid = GameLogic.GetFilters():apply_filters("store_get",'user/userId');
    local url = string.format("%s/p/qr/purchase?userId=%s&from=%s",urlbase, uerid, "vip_wintercamp1_join");
    return url
end

function MacroCodeCampActIntro.CheckIsInWinCamp()
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local world_id = WorldCommon.GetWorldTag("kpProjectId");    
    local campId = MacroCodeCampActIntro.campIds[httpwrapper_version]
    return tonumber(world_id) == campId
end

function MacroCodeCampActIntro.ShowQRCode()  
    -- if QRCodeWnd then
    --     QRCodeWnd:Show(parent_root);        
    -- end
    ParaUI.GetUIObject("miniCode").visible = true
end

function MacroCodeCampActIntro.HideQRCode()  
    -- if QRCodeWnd then
    --     QRCodeWnd:Hide()
    -- end
    ParaUI.GetUIObject("miniCode").visible = false
end

function MacroCodeCampActIntro.ClosePage()
    if page then
        page:CloseWindow()
    end
    MacroCodeCampActIntro.HideQRCode() 
    MacroCodeCampActIntro.isShowVipBtn = false
    MacroCodeCampActIntro.isEnterJoin = false 
end

function MacroCodeCampActIntro.OnRefreshPage(delaytime)
    if(page)then
        page:Refresh(delaytime or 0);
    end
    MacroCodeCampActIntro.RegisterButton()
    MacroCodeCampActIntro.GetVipRestNum()
    MacroCodeCampActIntro.InitSkinIcon()
    MacroCodeCampActIntro.InitMouseTip()
    MacroCodeCampActIntro.InitMiniCode()
end

function MacroCodeCampActIntro.RegisterButton() 
    local detail_btn = ParaUI.CreateUIObject("button", "ShowDetail", "_lt", 760, 80, 108, 42);
    detail_btn.visible = true
    detail_btn.onclick = string.format([[%s.OnBtnDetailClick();]],strPath)
    detail_btn.background = "Texture/Aries/Creator/keepwork/WinterCamp/btn3_108X42_32bits.png;0 0 108 42";
    parent_root:AddChild(detail_btn);

    if (not System.User.isVip and not System.User.isVipSchool) or MacroCodeCampActIntro.isShowVipBtn then
        local join_bt = ParaUI.CreateUIObject("button", "JoinAct", "_lt", 390, 500, 223, 80);
        join_bt.visible = true
        join_bt.background = "Texture/Aries/Creator/keepwork/WinterCamp/btn_223X80_32bits.png;0 0 223 80";
        parent_root:AddChild(join_bt);

        local scancode_bt = ParaUI.CreateUIObject("button", "ScanCode", "_lt", 390, 500, 223, 80);
        scancode_bt.visible = false
        scancode_bt.background = "Texture/Aries/Creator/keepwork/WinterCamp/btn2_223X80_32bits.png;0 0 223 80";
        parent_root:AddChild(scancode_bt);

        local textVipRest = ParaUI.CreateUIObject("button", "vip_rest", "_lt", 410, 446, 200, 80);
        textVipRest.enabled = false;
        textVipRest.text = "剩余：100名";
        textVipRest.background = "";
        textVipRest.font = "System;16;bold";
        textVipRest.visible = false
        _guihelper.SetButtonFontColor(textVipRest, "#072D4B", "#072D4B");
        parent_root:AddChild(textVipRest);

        join_bt.onmouseenter =  string.format([[%s.BtnJoinOnMouseEnter();]],strPath) 
        scancode_bt.onmouseleave = string.format([[%s.BtnScanCodeOnMouseLeave();]],strPath)
    end 
    local visitor_bt = ParaUI.CreateUIObject("button", "VisitorScene", "_lt", 42, 162, 208, 149);
    visitor_bt.background = "Texture/Aries/Creator/keepwork/WinterCamp/tu5_208X149_32bits.png;0 0 208 149";
    visitor_bt.onclick = string.format([[%s.OnClick(1);]],strPath)           
    visitor_bt.onmouseenter = string.format([[%s.OnMouseEnter(1);]],strPath) 
    visitor_bt.onmouseleave = string.format([[%s.OnMouseLeave(1);]],strPath)
    parent_root:AddChild(visitor_bt)

    local protect_bt = ParaUI.CreateUIObject("button", "ProtectSelf", "_lt", 748, 162, 208, 149);
    protect_bt.background = "Texture/Aries/Creator/keepwork/WinterCamp/tu7_208X149_32bits.png;0 0 208 149";
    protect_bt.onclick = string.format([[%s.OnClick(2);]],strPath)           
    protect_bt.onmouseenter = string.format([[%s.OnMouseEnter(2);]],strPath) 
    protect_bt.onmouseleave = string.format([[%s.OnMouseLeave(2);]],strPath)
    parent_root:AddChild(protect_bt)

    local programer_bt = ParaUI.CreateUIObject("button", "Programer", "_lt", 42, 386, 208, 149);
    programer_bt.background = "Texture/Aries/Creator/keepwork/WinterCamp/tu6_208X149_32bits.png;0 0 208 149";
    programer_bt.onclick = string.format([[%s.OnClick(3);]],strPath)           
    programer_bt.onmouseenter = string.format([[%s.OnMouseEnter(3);]],strPath) 
    programer_bt.onmouseleave = string.format([[%s.OnMouseLeave(3);]],strPath)
    parent_root:AddChild(programer_bt)

    local programerf_bt = ParaUI.CreateUIObject("button", "Programerf", "_lt", 748, 386, 208, 149);
    programerf_bt.background = "Texture/Aries/Creator/keepwork/WinterCamp/tu8_208X149_32bits.png;0 0 208 149";
    programerf_bt.onclick = string.format([[%s.OnClick(4);]],strPath)           
    programerf_bt.onmouseenter = string.format([[%s.OnMouseEnter(4);]],strPath) 
    programerf_bt.onmouseleave = string.format([[%s.OnMouseLeave(4);]],strPath)
    parent_root:AddChild(programerf_bt)    
end

function MacroCodeCampActIntro.OnBtnDetailClick()
    local MacroCodeCampIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampIntro.lua");
    MacroCodeCampIntro.ShowView()
end

function MacroCodeCampActIntro.BtnJoinOnMouseEnter()
    --print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    MacroCodeCampActIntro.isEnterJoin = true
    MacroCodeCampActIntro.OnRefreshPage()
    MacroCodeCampActIntro.ShowQRCode() 
    ParaUI.GetUIObject("JoinAct").visible = false
    ParaUI.GetUIObject("ScanCode").visible = true

    ParaUI.GetUIObject("Programerf").background = "Texture/Aries/Creator/keepwork/WinterCamp/tu4_208X149_32bits.png;0 0 208 149";
    ParaUI.GetUIObject("Programer").background = "Texture/Aries/Creator/keepwork/WinterCamp/tu2_208X149_32bits.png;0 0 208 149";
    ParaUI.GetUIObject("ProtectSelf").background = "Texture/Aries/Creator/keepwork/WinterCamp/tu3_208X149_32bits.png;0 0 208 149";
    ParaUI.GetUIObject("VisitorScene").background = "Texture/Aries/Creator/keepwork/WinterCamp/tu1_208X149_32bits.png;0 0 208 149";
end

function MacroCodeCampActIntro.BtnScanCodeOnMouseLeave()
    --print("zzzzzzzzzzzzzzzzzzzzzzzzzz")
    MacroCodeCampActIntro.isEnterJoin = false
    MacroCodeCampActIntro.OnRefreshPage()
    MacroCodeCampActIntro.HideQRCode() 
    ParaUI.GetUIObject("JoinAct").visible = true
    ParaUI.GetUIObject("ScanCode").visible = false

    ParaUI.GetUIObject("Programerf").background = "Texture/Aries/Creator/keepwork/WinterCamp/tu8_208X149_32bits.png;0 0 208 149";
    ParaUI.GetUIObject("Programer").background = "Texture/Aries/Creator/keepwork/WinterCamp/tu6_208X149_32bits.png;0 0 208 149";
    ParaUI.GetUIObject("ProtectSelf").background =  "Texture/Aries/Creator/keepwork/WinterCamp/tu7_208X149_32bits.png;0 0 208 149";
    ParaUI.GetUIObject("VisitorScene").background = "Texture/Aries/Creator/keepwork/WinterCamp/tu5_208X149_32bits.png;0 0 208 149";
end
--[[
    【云游】【防疫】【编程】:（19236,12,19250）、（19200,12,19323）、（19265,11,19147）

    用处1： 从任意世界， 传送到某个世界的指定位置。 (需要世界里面注册这个事件)
    /loadworld -inplace  530 | /sendevent globalSetPos  {x, y, z}
    
    用处2： 传密码和参数到某个世界， 让通过直接PID无法进入世界。 
    比如任务系统传送世界
    /loadworld -inplace  530 | /sendevent globalQuestLogin  {level=1, password="1234"}
]]
function MacroCodeCampActIntro.OnClick(index)
    if MacroCodeCampActIntro.CheckNeedRealName() then
        MacroCodeCampActIntro.ClosePage()
        return
    end
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local world_id = WorldCommon.GetWorldTag("kpProjectId");    
    if index == 4 then
        --print("show programer viwe")
        local MacroCodeCampMiniPro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampMiniPro.lua");
        MacroCodeCampMiniPro.ShowView()
        GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.promotion.winter_camp.first_page', { from = "wintercamp_act"..index })
        return
    end
    
    -- print("OnClick data========",index,world_id)
    local campId = MacroCodeCampActIntro.campIds[httpwrapper_version]
    if tonumber(world_id) == campId then
        MacroCodeCampActIntro.DoWinterCampEvent(index)
    else
        GameLogic.RunCommand(string.format("/loadworld -force -s %d", campId));
    end
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.promotion.winter_camp.first_page', { from = "wintercamp_act"..index })
end

function MacroCodeCampActIntro.DoWinterCampEvent(index)
    local pos = {
        {19236,12,19250},
        {19200,12,19323},
        {19265,11,19147},
    }
   
    if index == 1 then        
        --GameLogic.RunCommand(string.format("/goto  %d %d %d", pos[index][1],pos[index][2],pos[index][3]));
        MacroCodeCampActIntro.ClosePage()
        commonlib.TimerManager.SetTimeout(function()             
            GameLogic.GetCodeGlobal():BroadcastTextEvent("PlayGuideMovies", {}, function()
                -- print("asddasdasdasdasdasdasdasdasd")
            end);
        end,1000)
    elseif index == 2 then
        GameLogic.GetCodeGlobal():BroadcastTextEvent("openUI", {name = "taskMain"}, function()
            MacroCodeCampActIntro.ClosePage()
        end);
    elseif index == 3 then 
        GameLogic.RunCommand(string.format("/goto  %d %d %d", pos[index][1],pos[index][2],pos[index][3]));
        MacroCodeCampActIntro.ClosePage()
        commonlib.TimerManager.SetTimeout(function()            
            GameLogic.QuestAction.OpenCampCourseView()
        end,500)                       
    end
end

function MacroCodeCampActIntro.OnMouseEnter(index)
    local names = {"VisitorScene","ProtectSelf","Programer","Programerf"}
    local bgs = {
        "Texture/Aries/Creator/keepwork/WinterCamp/1.png",
        "Texture/Aries/Creator/keepwork/WinterCamp/2.png",
        "Texture/Aries/Creator/keepwork/WinterCamp/3.png",
        "Texture/Aries/Creator/keepwork/WinterCamp/4.png",
    }
    -- print("OnMouseEnter data========",index)

    --ParaUI.GetUIObject(names[index]).background = bgs[index];
    
end

function MacroCodeCampActIntro.OnMouseLeave(index)
    local names = {"VisitorScene","ProtectSelf","Programer","Programerf"}
    local bgs = {
        "Texture/Aries/Creator/keepwork/WinterCamp/scene.png",
        "Texture/Aries/Creator/keepwork/WinterCamp/fy.png",
        "Texture/Aries/Creator/keepwork/WinterCamp/bc.png",
        "Texture/Aries/Creator/keepwork/WinterCamp/bb.png",     
    }
    -- print("OnMouseLeave data========",index)

    --ParaUI.GetUIObject(names[index]).background = bgs[index];
end

function MacroCodeCampActIntro.GetVipRestNum()
    if System.User.isVip then
        return
    end
    keepwork.wintercamp.restvip({},function(err, msg, data)
        print("test.GetVipRest")
        -- commonlib.echo(err);
        -- commonlib.echo(msg);
        -- commonlib.echo(data,true);
        if err == 200 then
            local viprest = data.rest
            ParaUI.GetUIObject("vip_rest").text= string.format("剩余：%d名",viprest)
            ParaUI.GetUIObject("vip_rest").visible = true
        end
    end)
end

function MacroCodeCampActIntro.CheckNeedRealName()
    if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
        _guihelper.MessageBox("亲爱的同学，冬令营活动需要实名才能参与，快去实名吧。", nil, nil,nil,nil,nil,nil,{ ok = L"确定"});
                _guihelper.MsgBoxClick_CallBack = function(res)
                    if(res == _guihelper.DialogResult.OK) then
                        GameLogic.GetFilters():apply_filters(
                        'show_certificate',
                        function(result)
                            if (result) then
                                local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
                                DockPage.RefreshPage(0.01)
                                GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                            end
                        end)
                    end
                end     
        return true
    end
    return false
end

function MacroCodeCampActIntro.InitMiniCode()
    local miniCode = ParaUI.CreateUIObject("container", "miniCode", "_lt", 404, 174, 192, 192);
    miniCode.background = "Texture/Aries/Creator/keepwork/WinterCamp/minipro_photo_32bits.png"; 
    miniCode.visible = false  
    parent_root:AddChild(miniCode)
end

function MacroCodeCampActIntro.InitSkinIcon()
    local skin1 = ParaUI.CreateUIObject("button", "skin1", "_lt", 290, 322, 81, 90);
    skin1.background = "Texture/Aries/Creator/keepwork/WinterCamp/mousetip/2_81X90_32bits.png;0 0 81 90";
    skin1.onmouseenter = string.format([[%s.OnSkinEnter(1);]],strPath) 
    skin1.onmouseleave = string.format([[%s.OnSkinLeave(1);]],strPath)
    parent_root:AddChild(skin1)

    local skin2 = ParaUI.CreateUIObject("button", "skin2", "_lt", 290, 420, 81, 90);
    skin2.background = "Texture/Aries/Creator/keepwork/WinterCamp/mousetip/1_81X90_32bits.png;0 0 81 90";
    skin2.onmouseenter = string.format([[%s.OnSkinEnter(2);]],strPath) 
    skin2.onmouseleave = string.format([[%s.OnSkinLeave(2);]],strPath)
    parent_root:AddChild(skin2)    

    local skin3 = ParaUI.CreateUIObject("button", "skin3", "_lt", 625, 322, 81, 90);
    skin3.background = "Texture/Aries/Creator/keepwork/WinterCamp/mousetip/3_81X90_32bits.png;0 0 81 90";
    skin3.onmouseenter = string.format([[%s.OnSkinEnter(4);]],strPath) 
    skin3.onmouseleave = string.format([[%s.OnSkinLeave(4);]],strPath)
    parent_root:AddChild(skin3)

    local skin4 = ParaUI.CreateUIObject("button", "skin4", "_lt", 625, 432, 81, 90);
    skin4.background = "Texture/Aries/Creator/keepwork/WinterCamp/mousetip/4_81X90_32bits.png;0 0 81 90";
    skin4.onmouseenter = string.format([[%s.OnSkinEnter(3);]],strPath) 
    skin4.onmouseleave = string.format([[%s.OnSkinLeave(3);]],strPath)
    parent_root:AddChild(skin4)
end

function MacroCodeCampActIntro.OnSkinEnter(index)
    MacroCodeCampActIntro.ShowMouseTip(index)
end

function MacroCodeCampActIntro.OnSkinLeave(index)
    ParaUI.GetUIObject("tipBg").visible = false
end

function MacroCodeCampActIntro.InitMouseTip()
    local tipBg = ParaUI.CreateUIObject("container", "tipBg", "_lt", 400, 200, 130, 140);
    tipBg.background = "Texture/Aries/Creator/keepwork/WinterCamp/mousetip/bjk_32bits.png;0 0 32 32:12 12 14 14"; 
    tipBg.visible = false  
    parent_root:AddChild(tipBg)

    local textName = ParaUI.CreateUIObject("button", "textName", "_lt", 0, 8, 130, 14);
    textName.enabled = false;
    textName.text = "吉祥如意套装(男)";
    textName.background = "";
    textName.font = "System;12;norm";
    _guihelper.SetButtonFontColor(textName, "#ffffff", "#ffffff");
    tipBg:AddChild(textName);

    local skinIcon = ParaUI.CreateUIObject("container", "skinIcon", "_lt", 40, 24, 53, 77);
    skinIcon.background = "Texture/Aries/Creator/keepwork/WinterCamp/mousetip/3_53X77_32bits.png;0 0 53 77";   
    tipBg:AddChild(skinIcon)

    local textDesc = ParaUI.CreateUIObject("button", "textDesc", "_lt", 0, 102, 130, 14);
    textDesc.enabled = false;
    textDesc.text = "用户完成填写反馈表";
    textDesc.background = "";
    textDesc.font = "System;12;norm";
    _guihelper.SetButtonFontColor(textDesc, "#ffffff", "#ffffff");
    tipBg:AddChild(textDesc);

    local textDesc1 = ParaUI.CreateUIObject("button", "textDesc1", "_lt", 0, 118, 130, 14);
    textDesc1.enabled = false;
    textDesc1.text = "获得亲子证书时发放";
    textDesc1.background = "";
    textDesc1.font = "System;12;norm";
    _guihelper.SetButtonFontColor(textDesc1, "#ffffff", "#ffffff");
    tipBg:AddChild(textDesc1);
end

local skin_config = {
    {
        url = "3_53X77_32bits.png",
        name = "幻想星球套装(男)",
        desc = "小程序完成亲子绑定",
        desc1 = "获得亲子证书时发放",
    },
    {
        url = "5_53X77_32bits.png",
        name = "吉祥如意套装(男)",
        desc = "完成防疫任务",
        desc1 = "获得防疫证书时发放",
    }, 
    {
        url = "6_53X77_32bits.png",
        name = "吉祥如意套装(女)",
        desc = "完成防疫任务",
        desc1 = "获得防疫证书时发放",
    },   
    {
        url = "4_53X77_32bits.png",
        name = "幻想星球套装(女)",
        desc = "小程序完成亲子绑定",
        desc1 = "获得亲子证书时发放",
    },               
    
}

local pos_config = {
    {x = 160,y = 220},
    {x = 160,y = 420},
    {x = 706,y = 420},
    {x = 706,y = 220},    
}

function MacroCodeCampActIntro.ShowMouseTip(index)
    ParaUI.GetUIObject("tipBg").visible = true
    ParaUI.GetUIObject("tipBg").x = pos_config[index].x
    ParaUI.GetUIObject("tipBg").y = pos_config[index].y
    ParaUI.GetUIObject("textName").text = skin_config[index].name
    ParaUI.GetUIObject("skinIcon").background = string.format("Texture/Aries/Creator/keepwork/WinterCamp/mousetip/%s;0 0 53 77",skin_config[index].url)
    ParaUI.GetUIObject("textDesc").text = skin_config[index].desc
    ParaUI.GetUIObject("textDesc1").text = skin_config[index].desc1
end

