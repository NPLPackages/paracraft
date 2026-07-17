-- bottles
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
local MySchool = NPL.load('(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
local EventTrackingService = NPL.load('(gl)Mod/WorldShare/service/EventTracking.lua')

-- helper
local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')

local be_show_password = false
local account_agree = true
local phone_agree = true
local is_clicked_get_phone_captcha = false
local phone_account_exist = false

MainLogin.registerValidates = {
    account = {
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil,
        [5] = nil,
        [6] = nil,
        [7] = nil,
        [8] = nil,
    },
    phone = {
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil,
        [5] = nil,
        [6] = nil,
        [7] = nil,
        [8] = nil,
        [9] = nil,
    }
}

function get_page()
    return MainLogin.registerPage
end

function get_notice_page()
    return Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Register.Notice')
end

function get_is_modal()
    if not get_page() then
        return
    end
    return get_page():GetRequestParam('is_modal') == 'true' and true or false
end

function close()
    local MainLoginRegisterPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Register')

    if MainLoginRegisterPage then
        MainLoginRegisterPage:CloseWindow()
    end
end

function back()
    close()
    MainLogin:ShowLogin()
end

function set_account_mode()
    if not get_page() then
        return
    end
    local page = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Register')

    get_page():FindControl('account_register_mode').visible = true
    get_page():FindControl('phone_register_mode').visible = false

    --get_notice_page().set_mode(1)
end

function set_phone_mode()
    if not get_page() then
        return
    end

    get_page():FindControl('account_register_mode').visible = false
    get_page():FindControl('phone_register_mode').visible = true

    if get_page().phone_step == 1 then
        --get_notice_page().set_mode(2)
    elseif get_page().phone_step == 2 then
        --get_notice_page().set_mode(3)
    end
end

function set_finish()
    if not get_page() then
        return
    end
    get_page():FindControl('register_not_finish').visible = false
    get_page():FindControl('register_finish').visible = true
end

function user_agreement()
    local RegisterModal = NPL.load('(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua')
    RegisterModal:ShowUserAgreementPage()
end

function user_privacy()
    local RegisterModal = NPL.load('(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua')
    RegisterModal:ShowUserPrivacyPage()
end

function parent()
    EventTrackingService:Send(1, 'click.main_login.select_parents', nil, true)
    MainLogin:ShowParent()
end

function on_click_exit()
    MainLogin:Exit()
end

function get_container_style()
    if get_is_modal() then
        return 'margin-top: -200px;'
    end
end

-- account

function on_focus_account_account()
end

function on_focus_account_password()
end

function on_change_account_account()
    update_register_button_status()

    local account = get_page():GetValue('register_account')

    if not account or type(account) ~= 'string' or account == '' then
        MainLogin.registerValidates.account[1] = nil
        MainLogin.registerValidates.account[2] = nil
        MainLogin.registerValidates.account[3] = nil

        update_error_msg()

        return
    end

    if string.match(account, '^%a') then
        MainLogin.registerValidates.account[1] = true
    else
        MainLogin.registerValidates.account[1] = false
    end

    local sAccount = string.match(account, '[%a%d]+')

    if sAccount == account then
        MainLogin.registerValidates.account[2] = true
    else
        MainLogin.registerValidates.account[2] = false
    end

    if #account >= 4 then
        MainLogin.registerValidates.account[3] = true
    else
        MainLogin.registerValidates.account[3] = false
    end

    update_error_msg()
end

function on_change_account_password()
    -- copy value
    local password

    if be_show_password then
        password = get_page():GetValue('register_account_password_show')
    else
        password = get_page():GetValue('register_account_password_hide')
    end

    get_page():SetValue('register_account_password', password)

    update_register_button_status()

    -- validate
    local account = get_page():GetValue('register_account') or ''

    if not password or type(password) ~= 'string' or password == '' then
        MainLogin.registerValidates.account[4] = nil
        MainLogin.registerValidates.account[5] = nil
        MainLogin.registerValidates.account[6] = nil
        MainLogin.registerValidates.account[7] = nil
        MainLogin.registerValidates.account[8] = nil

        update_error_msg()

        return
    end

    if #password >= 4 then
        MainLogin.registerValidates.account[4] = true
    else
        MainLogin.registerValidates.account[4] = false
    end

    MainLogin.registerValidates.account[5] = true

    if password ~= account then
        MainLogin.registerValidates.account[6] = true
    else
        MainLogin.registerValidates.account[6] = false
    end

    if not string.match(password, '[ ]+') then
        MainLogin.registerValidates.account[7] = true
    else
        MainLogin.registerValidates.account[7] = false
    end

    update_error_msg()
end

function update_register_button_status()
    local account = get_page():GetValue('register_account') or ''
    local password = get_page():GetValue('register_account_password') or ''
    local b_button_right = true

    if not Validated:Account(account) then
        b_button_right = false
    end

    if not Validated:Password(password) then
        b_button_right = false
    end

    if account == password then
        b_button_right = false
    end

    if not account_agree then
        b_button_right = false
    end

    if b_button_right then
        --get_page():SetUIBackground('account_register_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')
    else
        --get_page():SetUIBackground('account_register_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 197 258 44')
    end
end

function set_show_password()
    if be_show_password then
        be_show_password = false

        local val = get_page():GetValue('register_account_password_show')
        get_page():SetValue('register_account_password_hide', val)
        get_page():SetValue('register_account_password', val)

        get_page():FindControl('register_account_password_show').visible = false
        get_page():FindControl('register_account_password_hide').visible = true
    else
        be_show_password = true

        local val = get_page():GetValue('register_account_password_hide')
        get_page():SetValue('register_account_password_show', val)
        get_page():SetValue('register_account_password', val)

        get_page():FindControl('register_account_password_show').visible = true
        get_page():FindControl('register_account_password_hide').visible = false
    end
end

function account_register()
    local account = get_page():GetValue('register_account') or ''
    local password = get_page():GetValue('register_account_password') or ''

    if not Validated:Account(account) then
        _guihelper.MessageBox(
            [[1.账号需要4位以上的字母或字母+数字组合；<br/>
              2.账号不可用p/P开头+数字组成；<br/>
              3.必须以字母开头；<br/>
              <div style="height: 20px;"></div>
              *推荐使用<div style="color: #ff0000;float: lefr;">名字拼音+出生年份，例如：zhangsan2010</div>]]);
        return
    end

    if not Validated:Password(password) then
        _guihelper.MessageBox(L'*密码不合法')
        return
    end

    if account == password then
        _guihelper.MessageBox(L'*密码不能与账号相同')
        return
    end

    if not account_agree then
        _guihelper.MessageBox(L'*您未同意用户协议')
        return
    end

    Mod.WorldShare.MsgBox:Show(L'正在注册，请稍候...', 10000, L'链接超时', 500, 120, 10)

    KeepworkServiceSession:CheckUsernameExist(
        account,
        function(bIsExist)
            if bIsExist then
                Mod.WorldShare.MsgBox:Close()
                _guihelper.MessageBox(format(L'*账号名%s已经被其他人注册，请使用其他账号名。', account))
                
                return
            end

            keepwork.tatfook.sensitive_words_check(
                {
                    word = account,
                },
                function(err, msg, data)
                    Mod.WorldShare.MsgBox:Close()
    
                    if err == 200 then
                        -- 敏感词判断
                        if data and #data > 0 then
                            local limit_world = data[1]
                            local begain_index, end_index = string.find(account, limit_world)

                            if (not begain_index or not end_index) then
                                return
                            end

                            local begain_str = string.sub(account, 1, begain_index - 1)
                            local end_str = string.sub(account, end_index + 1, #account)

                            local limit_name = string.format([[%s<div style="color: #ff0000;float: lefr;">%s</div>%s]], begain_str, limit_world, end_str)
                            _guihelper.MessageBox(string.format("您设定的用户名包含敏感字符 %s，请换一个。", limit_name))
                            return
                        end

                        MainLogin.account = account
                        MainLogin.password = password
                        MainLogin.agree = agree
    
                        MainLogin.callback = function()
                            get_page():SetValue('account_result', account)
                            get_page():SetValue('password_result', password)
                            set_finish()
                        end
    
                        MainLogin:RegisterWithAccount()
                    end
                end
            )
        end
    )
end

function finish()
    close()

    if true then
        MainLogin:ShowLogin()
        return
    end

    MainLogin:ShowWhere(function()
        MySchool:ShowJoinSchoolAfterRegister(function()
            MainLogin:EnterUserConsole()
        end)
    end)
end

function set_register_agree()
    account_agree = not account_agree

    if not account_agree then
        get_page():SetUIValue('agree_field_error_msg', L'*您未同意用户协议')
        get_page():FindControl('agree_field_error').visible = true
    else
        get_page():FindControl('agree_field_error').visible = false
    end
end

-- phone

function on_focus_phone_phone(name)
end

function on_focus_phone_password(name)
end

function on_focus_phone_captcha(name)
end

function on_focus_phone_account(name)

end

function on_change_phone_phone()
    on_change_next()

    local phonenumber = get_page():GetValue('phonenumber')

    if not phonenumber or type(phonenumber) ~= 'string' or phonenumber == '' then
        MainLogin.registerValidates.phone[1] = nil
        update_error_msg()

        return
    end

    if Validated:Phone(phonenumber) then
        MainLogin.registerValidates.phone[1] = true
    else
        MainLogin.registerValidates.phone[1] = false
    end

    update_error_msg()
end

function on_change_phone_password()
    local phonepassword

    if be_show_phone_password then
        phonepassword = get_page():GetValue('phonepassword_show')
    else
        phonepassword = get_page():GetValue('phonepassword_hide')
    end

    get_page():SetValue('phonepassword', phonepassword)

    on_change_next()

    if not phonepassword or type(phonepassword) ~= 'string' or phonepassword == '' then
        MainLogin.registerValidates.phone[3] = nil
        MainLogin.registerValidates.phone[4] = nil
        MainLogin.registerValidates.phone[5] = nil

        update_error_msg()

        return
    end

    if #phonepassword >= 4 then
        MainLogin.registerValidates.phone[3] = true
    else
        MainLogin.registerValidates.phone[3] = false
    end

    MainLogin.registerValidates.phone[4] = true

    if not string.match(phonepassword, '[ ]+') then
        MainLogin.registerValidates.phone[5] = true
    else
        MainLogin.registerValidates.phone[5] = false
    end

    update_error_msg()
end

function on_change_phone_captcha()
    on_change_next()

    local phonecaptcha = get_page():GetValue('phonecaptcha')

    if not phonecaptcha or type(phonecaptcha) ~= 'string' then
        MainLogin.registerValidates.phone[2] = nil
        update_error_msg()

        return
    end

    if #phonecaptcha == 0 then
        MainLogin.registerValidates.phone[2] = nil
    else
        MainLogin.registerValidates.phone[2] = true
    end

    update_error_msg()
end

function on_change_next()
    local b_next_button_right = true

    if not check_phone_number() then
        b_next_button_right = false
    end

    if not checkout_phonecaptcha() then
        b_next_button_right = false
    end

    if not check_phone_password() then
        b_next_button_right = false
    end

    if b_next_button_right then
        --get_page():SetUIBackground('phone_register_next_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')
    else
        --get_page():SetUIBackground('phone_register_next_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 197 258 44')
    end
end

function on_change_phone_account()
    local account = get_page():GetValue('phone_register_account')
    local phonepassword = get_page():GetValue('phonepassword')
    local b_button_right = true
    
    if not Validated:Account(account) then
        b_button_right = false
    end

    if account == phonepassword then
        b_button_right = false 
    end

    if b_button_right then
        --get_page():SetUIBackground('phone_register_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')
    else
        --get_page():SetUIBackground('phone_register_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 197 258 44')
    end

    if not account or type(account) ~= 'string' or account == '' then
        MainLogin.registerValidates.phone[6] = nil
        MainLogin.registerValidates.phone[7] = nil
        MainLogin.registerValidates.phone[8] = nil
        MainLogin.registerValidates.phone[9] = nil

        update_error_msg()

        return
    end

    if string.match(account, '^%a') then
        MainLogin.registerValidates.phone[6] = true
    else
        MainLogin.registerValidates.phone[6] = false
    end

    local sAccount = string.match(account, '[%a%d]+')

    if sAccount == account then
        MainLogin.registerValidates.phone[7] = true
    else
        MainLogin.registerValidates.phone[7] = false
    end

    if #account >= 4 then
        MainLogin.registerValidates.phone[8] = true
    else
        MainLogin.registerValidates.phone[8] = false
    end

    if phonepassword ~= account then
        MainLogin.registerValidates.phone[9] = true
    else
        MainLogin.registerValidates.phone[9] = false
    end

    update_error_msg()
end

function phone_register_next()
    if not check_phone_number() then
        _guihelper.MessageBox(L'*手机号码格式错误')

        return
    end

    if not checkout_phonecaptcha() then
        _guihelper.MessageBox(L'*手机验证码不能为空')

        return
    end

    if not check_phone_password() then
        _guihelper.MessageBox(L'*密码不合法')

        return
    end

    if not phone_agree then
        _guihelper.MessageBox(L'*您未同意用户协议')

        return
    end

    local phonenumber = get_page():GetValue('phonenumber')
    local phonecaptcha = get_page():GetValue('phonecaptcha')

    KeepworkServiceSession:CheckPhonenumberExist(phonenumber, function(b_is_exist)
        if b_is_exist then
            _guihelper.MessageBox(L'*手机号码已存在')

            return
        end

        KeepworkServiceSession:CellphoneCaptchaVerify(phonenumber, phonecaptcha, function(data, err)
            if err == 400 then
                _guihelper.MessageBox(L'*手机验证码错误')

                return
            end

            get_page():FindControl('phone_register_mode_step_1').visible = false
            get_page():FindControl('phone_register_mode_step_2').visible = true
            get_page().phone_step = 2
            --get_notice_page().set_mode(3)
        end)
    end)
end

function phone_register()
    local phonenumber = get_page():GetValue('phonenumber')
    local phonecaptcha = get_page():GetValue('phonecaptcha')
    local phonepassword = get_page():GetValue('phonepassword')
    local username = get_page():GetValue('phone_register_account')

    if not Validated:Account(username) then
        _guihelper.MessageBox(L'*账号需4位以上且非数字开头的字母、数字组合形式')

        return
    end

    if not Validated:Password(phonepassword) then
        _guihelper.MessageBox(L'*密码格式错误')

        return
    end

    if username == phonepassword then
        _guihelper.MessageBox(L'*密码不能与账号相同')

        return
    end

    MainLogin.phonenumber = phonenumber
    MainLogin.password = phonepassword
    MainLogin.phonecaptcha = phonecaptcha
    MainLogin.account = username

    MainLogin.callback = function()
        get_page():SetValue('account_result', username)
        get_page():SetValue('password_result', phonepassword)
        set_finish()

        if type(MainLogin.registerCallback) == 'function' then
            MainLogin.registerCallback()
        end
    end

    KeepworkServiceSession:CheckUsernameExist(username, function(b_is_exist)
        if b_is_exist then
            _guihelper.MessageBox(L'*账号已存在，请使用其他账号')
        else
            MainLogin:RegisterWithPhone()
        end
    end)
end

function set_phone_agree()
    phone_agree = not phone_agree

    if not phone_agree then
        get_page():SetUIValue('phone_agree_field_error_msg', L'*您未同意用户协议')
        get_page():FindControl('phone_agree_field_error').visible = true
    else
        get_page():FindControl('phone_agree_field_error').visible = false
    end
end

function get_phone_captcha()
    if #get_page():GetValue('phonenumber') ~= 11 then
        _guihelper.MessageBox(L'*手机号码位数不对')
        return
    end

    if phone_account_exist then
        _guihelper.MessageBox(L'*手机号码已存在')
        return
    end

    if is_clicked_get_phone_captcha then
       return 
    end

    is_clicked_get_phone_captcha = true

    local times = 60

    local timer = commonlib.Timer:new({
        callbackFunc = function(timer)
            get_page():SetValue('get_phone_captcha', format('%s(%ds)', L'重新发送', times))

            if times == 0 then
                is_clicked_get_phone_captcha = false
                get_page():SetValue('get_phone_captcha', L'获取验证码')
                timer:Change(nil, nil)
            end

            times = times - 1
        end
    })

    KeepworkServiceSession:GetPhoneCaptcha(get_page():GetValue('phonenumber'), function(data, err)
        if err == 400 and data and data.code and data.message then
            is_clicked_get_phone_captcha = false
            get_page():SetValue('getPhonecaptcha', L'获取验证码')
            GameLogic.AddBBS(nil, format('%s%s(%d)', L'获取验证码失败，错误信息：', data.message, data.code), 3000, '255 0 0')
            timer:Change(nil, nil)
        end
    end)

    timer:Change(1000, 1000)
end

function checkout_phonecaptcha()
    local phonecaptcha = get_page():GetValue('phonecaptcha')

    if phonecaptcha and #phonecaptcha == 0 then
        return false
    else
        return true
    end
end

function check_phone_password()
    local phonepassword = get_page():GetValue('phonepassword')

    if not Validated:Password(phonepassword) then
        return false
    else
        return true
    end
end

function check_phone_number()
    local phonenumber = get_page():GetValue('phonenumber')

    if not Validated:Phone(phonenumber) then
        return false
    else
        return true
    end
end

function set_show_password1()
    if be_show_phone_password then
        be_show_phone_password = false

        local val = get_page():GetValue('phonepassword_show')
        get_page():SetValue('phonepassword_hide', val)
        get_page():SetValue('phonepassword', val)

        get_page():FindControl('phonepassword_show').visible = false
        get_page():FindControl('phonepassword_hide').visible = true
    else
        be_show_phone_password = true

        local val = get_page():GetValue('phonepassword_hide')
        get_page():SetValue('phonepassword_show', val)
        get_page():SetValue('phonepassword', val)

        get_page():FindControl('phonepassword_show').visible = true
        get_page():FindControl('phonepassword_hide').visible = false
    end
end

function is_active(kind, i)
    if kind == 'account' then
        return MainLogin.registerValidates.account[i]
    elseif kind == 'phone' then
        return MainLogin.registerValidates.phone[i]
    elseif kind == 'modify' then
        return MainLogin.registerValidates.modify[i]
    end

    return nil
end

function update_error_msg()
    local account_error_msg = ''
    local password_error_msg = ''
    if is_active("account", 1) == false then
        account_error_msg = L'账号必须由字母开头'
    elseif is_active("account", 2) == false then
        account_error_msg = L'账号可以由字母、数字组成，不可添加特殊符号、空格'
    elseif is_active("account", 3) == false then
        account_error_msg = L'账号长度要大于4位'
    elseif is_active("account", 4) == false then
        password_error_msg = L'密码长度超过4位'
    elseif is_active("account", 5) == false then
        password_error_msg = L'密码可以由字母、数字、符号组成'
    elseif is_active("account", 6) == false then
        password_error_msg = L'密码不与用户名重复'
    elseif is_active("account", 7) == false then
        password_error_msg = L'密码不可使用空格键'
    end
    
    if account_error_msg ~= '' then
        get_page():SetUIValue('register_account_field_error_msg', account_error_msg)
        get_page():FindControl('register_account_field_error').visible = true
    else
        get_page():SetUIValue('register_account_field_error_msg', '')
        get_page():FindControl('register_account_field_error').visible = false
    end

    if password_error_msg ~= '' then
        get_page():SetUIValue('register_account_password_field_error_msg', password_error_msg)
        get_page():FindControl('register_account_password_field_error').visible = true
    else
        get_page():SetUIValue('register_account_password_field_error_msg', '')
        get_page():FindControl('register_account_password_field_error').visible = false
    end

    local phone_error_msg = ''
    local phone_password_error_msg = ''
    local phone_account_error_msg = ''
    if is_active("phone", 1) == false then
        phone_error_msg = L'手机号码格式错误'
    elseif is_active("phone", 2) == false then
        phone_error_msg =L'手机验证码不能为空'
    elseif is_active("phone", 3) == false then
        phone_password_error_msg = L'密码长度不少于4位'
    elseif is_active("phone", 4) == false then
        phone_password_error_msg = L'密码可以由字母、数字、符号组成'
    elseif is_active("phone", 5) == false then
        phone_password_error_msg = L'不可使用空格键'
    elseif is_active("phone", 6) == false then
        phone_account_error_msg = L'账号必须由字母开头'
    elseif is_active("phone", 7) == false then
        phone_account_error_msg = L'账号可以由字母、数字组成，不可添加特殊符号、空格'
    elseif is_active("phone", 8) == false then
        phone_account_error_msg = L'账号长度要大于4位'
    elseif is_active("phone", 9) == false then
        phone_account_error_msg = L'账号不与密码重复'
    end

    if phone_error_msg ~= '' then
        get_page():SetUIValue('register_phone_field_error_msg', phone_error_msg)
        get_page():FindControl('register_phone_field_error').visible = true
    else
        get_page():FindControl('register_phone_field_error').visible = false
        get_page():SetUIValue('register_phone_field_error_msg', '')
    end

    if phone_password_error_msg ~= '' then
        get_page():SetUIValue('register_phone_password_field_error_msg', phone_password_error_msg)
        get_page():FindControl('register_phone_password_field_error').visible = true
    else
        get_page():SetUIValue('register_phone_password_field_error_msg', '')
        get_page():FindControl('register_phone_password_field_error').visible = false
    end

    if phone_account_error_msg ~= '' then
        get_page():SetUIValue('register_account_field_error_msg_step', phone_account_error_msg)
        get_page():FindControl('register_account_field_error_step').visible = true
    else
        get_page():SetUIValue('register_account_field_error_msg_step', '')
        get_page():FindControl('register_account_field_error_step').visible = false
    end
end
