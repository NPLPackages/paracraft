--[[
Title: ClassCodeLoginLogin
Author(s): pbb
Date: 2023/11/18
Desc:  
Use Lib:
-------------------------------------------------------
local ClassCodeLoginLogin = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/ClassCode/ClassCodeLoginLogin.lua")
ClassCodeLoginLogin.ShowPage()
--]]
local ClassCodeLoginLogin = NPL.export();

local defaultParams = {
    name="张小娴",
    className="六（一）班",
    orgName = "北京大学",
    userId = 245625,
    username="py25635" 
}
ClassCodeLoginLogin.pageData = {}
local page
function ClassCodeLoginLogin.OnInit()
    page = document:GetPageCtrl();
end


function ClassCodeLoginLogin.ShowPage(data)
    ClassCodeLoginLogin.pageData = data or defaultParams
    echo(ClassCodeLoginLogin.pageData,true)
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Educate/ClassCode/ClassCodeLoginLogin.html",
        name = "ClassCodeLoginLogin.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 4,
        directPosition = true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
        isTopLevel = true,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end


function ClassCodeLoginLogin.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function ClassCodeLoginLogin.CloseView()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function ClassCodeLoginLogin.OnClickLogin()
    if not ClassCodeLoginLogin.pageData or not page then
        return
    end
    local password = page:GetValue('password')

    local platform = "PC"

    if System.os.GetPlatform() == 'mac' or
       System.os.GetPlatform() == 'win32' then
        platform = 'PC'
    elseif System.os.GetPlatform() == 'android' or
           System.os.GetPlatform() == 'ios' then
        platform = 'MOBILE'
    end

    local params = {
        code = ClassCodeLoginLogin.pageData.code or "",
        userId = ClassCodeLoginLogin.pageData.userId or "",
        password = password,
        machineCode = GameLogic.GetMachineID(ParaEngine.GetAttributeObject():GetField('MachineID','')),    
    }
    Mod.WorldShare.MsgBox:Show(L'正在登录，请稍候...', nil, nil, nil, nil, 1000)
    local versionXml = ParaXML.LuaXML_ParseFile('config/Aries/creator/paracraft_script_version.xml')

    params.version = versionXml[1][1]
    if System.os.IsWindowsXP() then
        params.version = "9.0.0"
    end
    if System.options and System.options.appId then
        params.appId = System.options.appId
    end
    params.platform = platform

    keepwork.classcode.login(params,function(err,msg,response)
        Mod.WorldShare.MsgBox:Close()
        if not response or type(response) ~= "table" then
            _guihelper.MessageBox(format(L'服务器数据错误(%d/%s)', err,tostring(response)))
            return
        end
        if err ~= 200 then
            if response and response.code and response.message then
                if response.code == 77 then
                    _guihelper.MessageBox(format(L'*%s(%d)', response.message, response.code))
                end
                page:SetUIValue('password_field_error_msg', format(L'*%s(%d)', response.message, response.code))
            else
                if err == 0 then
                    page:SetUIValue('password_field_error_msg', format(L'*网络异常或超时，请检查网络(%d)', err))
                else
                    page:SetUIValue('password_field_error_msg', format(L'*系统维护中(%d)', err))
                end
            end
            local passwordFieldError = page:FindControl('password_field_error')
            if passwordFieldError then
                passwordFieldError.visible = true
            end
            return
        end
        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua');
        KeepworkServiceSession:LoginResponse(response, 200, function(bSucceed, message)
            LOG.std("ClassCodeLoginLogin", "info", "profile from code is ", commonlib.serialize_compact(response));
            GameLogic.AddBBS(nil,"登陆成功")

            ClassCodeLoginLogin.CloseView()
            ClassCodeLoginLogin.LoginSuccess()
        end);
    end)
end

function ClassCodeLoginLogin.OnClickBack()
    ClassCodeLoginLogin.CloseView()
    local SelectNamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/ClassCode/SelectNamePage.lua")
    SelectNamePage.HidePage(false)
end

function ClassCodeLoginLogin.LoginSuccess()
    local SelectNamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/ClassCode/SelectNamePage.lua")
    SelectNamePage.CloseView()
    local ClassCodeLogin = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/ClassCode/ClassCodeLogin.lua")
    ClassCodeLogin.OnClose()

    local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
    if MainLogin then
        MainLogin:Next()
    end
end


