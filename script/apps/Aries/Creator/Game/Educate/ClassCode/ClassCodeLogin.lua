--[[
Title: ClassCodeLogin
Author(s): pbb
Date: 2023/09/06
Desc:  
Use Lib:
-------------------------------------------------------
local ClassCodeLogin = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/ClassCode/ClassCodeLogin.lua")
ClassCodeLogin.ShowView();
--]]
local length = 6
local ClassCodeLogin = NPL.export()
ClassCodeLogin.ClassCode = ""
local page,pageRoot
function ClassCodeLogin.OnInit()
    page = document:GetPageCtrl();
    pageRoot = page:GetRootUIObject()
    page.OnCreate = ClassCodeLogin.OnCreate;
end

function ClassCodeLogin.OnCreate()
    if not page or not page:IsVisible() then
        return
    end
    ClassCodeLogin.CreateCodePanel()
end

function ClassCodeLogin.ShowView()
    ClassCodeLogin.ClassCode = ""
    local viewWidth = 0
    local viewHeight = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/ClassCode/ClassCodeLogin.html",
        name = "ClassCodeLogin.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 0,
        directPosition = true,
        align = "_fi",
        x = -viewWidth/2,
        y = -viewHeight/2,
        width = viewWidth,
        height = viewHeight,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
        cancelShowAnimation = true,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    ClassCodeLogin.OnShowExtra()
end

function ClassCodeLogin.OnShowExtra()
    Mod.WorldShare.Utils.ShowWindow(
        220,
        220,
        'script/apps/Aries/Creator/Game/Educate/Login/MainLoginExtra.html',
        'Mod.WorldShare.cellar.MainLogin.Extra',
        80,
        520,
        '_lb',
        false,
        0,
        nil,
        false
    )
end

function ClassCodeLogin.OnClose()
    if not page then
        return
    end
    page.OnCreate = nil;
    page:CloseWindow();
    page = nil;

    local MainLoginExtraPage = Mod.WorldShare.Store:Get('page/ClassCodeLogin.Extra')

    if MainLoginExtraPage then
        MainLoginExtraPage:CloseWindow()
    end

    ClassCodeLogin.ClassCode = ""
    if (ClassCodeLogin.aniTimer) then
        ClassCodeLogin.aniTimer:Change()
        ClassCodeLogin.aniTimer = nil
    end
end

function ClassCodeLogin.CreateCodePanel()
    local parentRoot = ParaUI.GetUIObject("ClassCodeLogin.background")
    if not parentRoot or not parentRoot:IsValid() then
        return
    end


    local left, top, width, height = 38,164,267,34
    local spacing = 16
    local inputWidth = width + spacing * 2

    local _parent = ParaUI.CreateUIObject("container", "input_back", "_lt", left, top, inputWidth, height);
    _parent.background = "";
    _parent:GetAttributeObject():SetField("ClickThrough", true);
	_parent.zorder = 10
	parentRoot:AddChild(_parent);

    -- 显示框
    local singleWidth = 27;
    for i = 1, length do
        local x = (singleWidth + spacing) * (i - 1)
        if (i > 3) then
            x = x + 40
        end
        local y = 0
        local _this = ParaUI.CreateUIObject("container", "ClassCode_input_bg_".. i, "_lt",  x, y, singleWidth, 34);
        _this.background = "Texture/Aries/Creator/paracraft/Educate/Login1/input_41x51_32bits.png;0 0 41 51";
        _this.zorder = 2;
        _this:GetAttributeObject():SetField("ClickThrough", true);
        _parent:AddChild(_this);

        _this = ParaUI.CreateUIObject("text", "ClassCode_input_text_"..i, "_lt",  x, y, singleWidth, 34);
        _this.text = "";
        _this.font = "System;20;bold";
        _this.color = "#38374D";
        _this.zorder = 3;
        _guihelper.SetUIFontFormat(_this, 5)
        _parent:AddChild(_this);
    end

    local text = "|" --光标
    local caretObject = ParaUI.CreateUIObject("text", "ClassCode_caret", "_lt", 0, 0, singleWidth, 34);
    caretObject.text = text;
    caretObject.font = "System;20;normal";
    caretObject.zorder = 3;
    _guihelper.SetUIFontFormat(caretObject, 5)
    _parent:AddChild(caretObject);
    caretObject.visible = false

    local separatorObject = ParaUI.CreateUIObject("text", "ClassCode_separator", "_lt", (singleWidth +spacing) * 3 - 2,  0, singleWidth, 34);
    separatorObject.text = "——"
    separatorObject.color = "#A8A7B0"
    separatorObject.font = "System;20;normal";
    separatorObject.zorder = 3;
    _guihelper.SetUIFontFormat(separatorObject, 5)
    _parent:AddChild(separatorObject);
    
end

function ClassCodeLogin.CheckTextValid(text)
    if text == "" then
        return false
    end
    local isFindNotNum = false
    local trueText = ""
    for i = 1, #text do
        local c = string.sub(text, i, i)
        if (tonumber(c) ~= nil) then
            trueText = trueText.. c
        else
            isFindNotNum = true
            break
        end
    end
    return isFindNotNum,trueText
end

function ClassCodeLogin.OnTextFocusIn()
    if ClassCodeLogin.ClassCode and #ClassCodeLogin.ClassCode == length then
        ClassCodeLogin.HideCaret()
        return
    end
    local editText = ParaUI.GetUIObject("ClassCode_input")
    if (editText and editText:IsValid()) then
        editText:SetCaretPosition(-1);
    end
    ClassCodeLogin.PlayCaretAni()
end

function ClassCodeLogin.OnTextFocusOut()
    ClassCodeLogin.HideCaret()
end

function ClassCodeLogin.OnTextChanged()
    local editText = ParaUI.GetUIObject("ClassCode_input")
    if (editText and editText:IsValid()) then
        local text = editText.text
        if text == "" then
            ClassCodeLogin.SetText("")
            return
        end
        local isValid,trueText = ClassCodeLogin.CheckTextValid(text)
        if isValid then
            editText.text = (trueText and trueText ~= "") and trueText or ""
            editText:SetCaretPosition(-1);
            return
        end
        if #text > length then
            text = text:sub(1, length)
            editText.text = text
            editText:SetCaretPosition(-1);
            return
        end

        if #text == length then
            ClassCodeLogin.HideCaret()
        else
            if not ClassCodeLogin.aniTimer or not ClassCodeLogin.aniTimer.enabled then
                ClassCodeLogin.PlayCaretAni()
            end
        end

        
        local trueText= ClassCodeLogin.GetNumber(text)
        if trueText and trueText == "" then
            ClassCodeLogin.SetText("")
            return
        end

        if (trueText and trueText ~= "") then
            ClassCodeLogin.SetText(trueText)
        end
    end
end

function ClassCodeLogin.SetText(str)
    local caretIndex = 1
    for i = 1, #str do
        local c = string.sub(str, i, i)
        if (c >= '0' and c <= '9' and tonumber(c) ~= nil) then
            caretIndex = caretIndex + 1
        end
    end
    if (caretIndex > length) then
        caretIndex = length
    end
    local caretObject = ParaUI.GetUIObject("ClassCode_caret")
    if (caretObject and caretObject:IsValid()) then
        local textObj = ParaUI.GetUIObject("ClassCode_input_text_"..caretIndex)
        if (textObj and textObj:IsValid()) then
            caretObject.x = textObj.x
        end
    end
    ClassCodeLogin.ClassCode = str
    for i = 1, length do
        local textObj = ParaUI.GetUIObject("ClassCode_input_text_"..i)
        if (textObj and textObj:IsValid()) then
            textObj.text = (str and str ~= "") and str:sub(i, i) or ""
        end
    end
end

function ClassCodeLogin.PlayCaretAni()
    local index = 0
    local caretObject = ParaUI.GetUIObject("ClassCode_caret")
    local editText = ParaUI.GetUIObject("ClassCode_input")
    if (caretObject and caretObject:IsValid()) then
        ClassCodeLogin.aniTimer = ClassCodeLogin.aniTimer or commonlib.Timer:new({callbackFunc = function(timer)
            index = index + 1
            caretObject.visible = index % 2 == 0
            if (index > 100) then
                index = 1
            end
            if (editText and editText:IsValid()) then
                editText:SetCaretPosition(-1);
            end
        end})
        ClassCodeLogin.aniTimer:Change(0,400)
    end
end

function ClassCodeLogin.HideCaret()
    local caretObject = ParaUI.GetUIObject("ClassCode_caret")
    if (caretObject and caretObject:IsValid()) then
        caretObject.visible = false
    end
    if (ClassCodeLogin.aniTimer) then
        ClassCodeLogin.aniTimer:Change()
    end
end

function ClassCodeLogin.GetNumber(str) --纯数字
    local trueText = ""
    for i = 1, #str do
        local c = string.sub(str, i, i)
        if (c >= '0' and c <= '9' and tonumber(c) ~= nil) then
            trueText = trueText.. c
        end
    end
    return trueText
end

function ClassCodeLogin.GetString(str) --纯字母
    local trueText = ""
    for i = 1, #str do
        local c = string.sub(str, i, i)
        if (c >= 'a' and c <= 'z') then
            trueText = trueText.. c
        elseif (c >= 'A' and c <= 'Z') then
            trueText = trueText.. c
        end
    end
    return trueText
end

function ClassCodeLogin.OnClickBack()
    ClassCodeLogin.OnClose()
    local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
    if System.options.channelId == "431" and (System.os.GetPlatform() == "ios" or System.os.GetPlatform() == "android") then
        MainLogin:ShowMobile()
        return
    end
    MainLogin:ShowLogin()
end

function ClassCodeLogin.OnClickNext()
    if not page then
        return
    end
    local editText = ParaUI.GetUIObject("ClassCode_input")
    if not editText or not editText:IsValid() then
        return
    end
    local code = editText.text

    local SelectNamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/ClassCode/SelectNamePage.lua")
    SelectNamePage.ShowPage(code)
end

