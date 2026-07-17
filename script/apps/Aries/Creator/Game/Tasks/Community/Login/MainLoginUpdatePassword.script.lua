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
local phone_show_field = ''
local b_next_button_right = true
local phone_account_exist = false

MainLogin.registerValidates = {
    modify = {
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil,
        [5] = nil,
    }
}

function get_page()
    return Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.UpdatePassword')
end

function get_notice_page()
    return Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Register.Notice')
end

function close()
    if get_page() then
        get_page():CloseWindow()
    end
end

function back()
    close()
    MainLogin:ShowLogin()
end

function update_password()
    local cur_password = get_page():GetValue("cur_password") or ""
    local new_password = get_page():GetValue("new_password") or ""
    local new_password_again = get_page():GetValue("new_password_again") or ""

    if cur_password == '' then
        _guihelper.MessageBox(L'请输入当前密码')
        return
    end

    if new_password == '' then
        _guihelper.MessageBox(L'请输入新的密码')
        return
    end

    if new_password_again == '' then
        _guihelper.MessageBox(L'请再次输入需要设置的新密码')
        return
    end

    if new_password ~= new_password_again then
        _guihelper.MessageBox(L'两次输入的密码不一致，请检查输入是否有误。')
        return
    end

    if new_password == cur_password then
        _guihelper.MessageBox(L'新密码与旧密码一致，请检查输入是否有误。')
        return
    end

    if not Validated:Password(new_password) then
        _guihelper.MessageBox(L'新密码不合法。')
        return
    end

    keepwork.user.pwd(
        {
            password = new_password,
            oldpassword = cur_password,
        },
        function(err, msg, data)
            if data == true then
                _guihelper.MessageBox(L'修改密码成功，请重新登录')
                
                KeepworkServiceSession:Logout(nil, function()
                    Mod.WorldShare.MsgBox:Close()
                    close()
                    MainLogin:ShowLogin()
                end)

            else
                _guihelper.MessageBox(L'修改密码失败，请确认当前密码是否正确')
            end
        end
    )
end

function on_change_cur_password()
end

function on_change_new_password()
    local password = get_page():GetValue('new_password')
    local account = Mod.WorldShare.Store:Get('user/username') or ''

    if not password or type(password) ~= 'string' or password == '' then
        MainLogin.registerValidates.modify[1] = nil
        MainLogin.registerValidates.modify[2] = nil
        MainLogin.registerValidates.modify[3] = nil
        MainLogin.registerValidates.modify[4] = nil

        update_error_msg()

        return
    end

    if #password >= 4 then
        MainLogin.registerValidates.modify[1] = true
    else
        MainLogin.registerValidates.modify[1] = false
    end

    MainLogin.registerValidates.modify[2] = true

    if not string.match(password, '[ ]+') then
        MainLogin.registerValidates.modify[3] = true
    else
        MainLogin.registerValidates.modify[3] = false
    end

    if password ~= account then
        MainLogin.registerValidates.modify[4] = true
    else
        MainLogin.registerValidates.modify[4] = false
    end

    update_error_msg()
end

function on_change_new_password_again()
    local password = get_page():GetValue('new_password')
    local password_again = get_page():GetValue('new_password_again')

    if not password_again or type(password_again) ~= 'string' or password_again == '' then
        MainLogin.registerValidates.modify[5] = nil

        update_error_msg()

        return
    end

    if password == password_again then
        MainLogin.registerValidates.modify[5] = true
    else
        MainLogin.registerValidates.modify[5] = false
    end

    update_error_msg()
end

function parent()
    EventTrackingService:Send(1, 'click.main_login.select_parents', nil, true)
    MainLogin:ShowParent()
end

function on_click_exit()
    MainLogin:Exit()
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
    local password_error_msg = ''
    if is_active("modify", 1) == false then
        password_error_msg = L'密码长度超过4位'
    elseif is_active("modify", 2) == false then
        password_error_msg = L'密码可以由字母、数字、符号组成'
    elseif is_active("modify", 3) == false then
        password_error_msg = L'不可使用空格键'
    elseif is_active("modify", 4) == false then
        password_error_msg = L'账号不与密码重复'
    elseif is_active("modify", 5) == false then
        password_error_msg = L'两次输入的密码不一致，请检查输入是否有误。'
    end

    if password_error_msg ~= '' then
        get_page():SetUIValue('update_account_password_field_error_msg', password_error_msg)
        get_page():FindControl('update_account_password_field_error').visible = true
    else
        get_page():SetUIValue('update_account_password_field_error_msg', '')
        get_page():FindControl('update_account_password_field_error').visible = false
    end
end
