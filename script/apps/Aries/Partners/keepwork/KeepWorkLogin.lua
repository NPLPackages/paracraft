--[[
Title: keepwork login page
Author(s): leio
Date: 2017/7/20
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Partners/keepwork/KeepWorkLogin.lua");
local KeepWorkLogin = commonlib.gettable("MyCompany.Aries.Partners.keepwork.KeepWorkLogin");
KeepWorkLogin.ShowPage(url)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
NPL.load("(gl)script/apps/Aries/Login/MainLogin.lua");
local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
local MainLogin = commonlib.gettable("MyCompany.Aries.MainLogin");

local KeepWorkLogin = commonlib.gettable("MyCompany.Aries.Partners.keepwork.KeepWorkLogin");
KeepWorkLogin.client_id = "1000003";
function KeepWorkLogin.OnInit()
    KeepWorkLogin.page = document:GetPageCtrl();
end

function KeepWorkLogin.LoadLocalData()
    local local_data = MyCompany.Aries.Player.LoadLocalData("KeepWork_Local_UserInfo_Data", {});
    return local_data.username,local_data.password;
end
function KeepWorkLogin.SaveLocalData(username,password)
    local local_data = MyCompany.Aries.Player.LoadLocalData("KeepWork_Local_UserInfo_Data", {});
    if(username)then
        local_data.username = username;
        local_data.password = password;
    else
        local_data.username = nil;
        local_data.password = nil;
    end
    MyCompany.Aries.Player.SaveLocalData("KeepWork_Local_UserInfo_Data", local_data)
end
function KeepWorkLogin.ClosePage()
    if(KeepWorkLogin.page)then
        KeepWorkLogin.page:CloseWindow();
    end
end

function KeepWorkLogin.ShowPage()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldLoginDocker.lua");
	local ParaWorldLoginDocker = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldLoginDocker")
	ParaWorldLoginDocker.InitParaWorldClient();

	if(System.User and System.User.keepworktoken) then
		if(System.User.keepworktoken == "waiting") then
			KeepWorkLogin.mytimer = KeepWorkLogin.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
				if(System.User.keepworktoken == "error") then
					timer:Change();
				elseif(System.User.keepworktoken ~= "waiting") then
					KeepWorkLogin.LoginWithToken(System.User.keepworktoken)
					timer:Change();
				end
			end})
			KeepWorkLogin.mytimer:Change(300, 300);
		elseif(System.User.keepworktoken == "error") then
			return 
		else
			KeepWorkLogin.LoginWithToken(System.User.keepworktoken)
		end
	else
		KeepWorkLogin.ShowLoginPage()
	end
end

function KeepWorkLogin.site()
	return "https://keepwork.com";
end

function KeepWorkLogin.LoginWithToken(token)
	local url = format("%s/api/wiki/models/user/getProfile", KeepWorkLogin.site())
	System.os.GetUrl({
        url = url,
        json = true,
        headers = {
            ["Authorization"] = " Bearer " .. token,
        },
    }, function(err, msg, data)
		if(err == 200) then
			local userInfo = data.data;
			if(userInfo and userInfo.username) then
				local username = userInfo.username;
				LOG.std(nil, "debug", "keepwork login username", username);
				LOG.std(nil, "debug", "keepwork login token", token);
				KeepWorkLogin.agreeOauth(username, KeepWorkLogin.client_id, token);
			end
		else
			System.User.keepworktoken = nil;
			_guihelper.MessageBox("登陆凭证过期，请重新登陆!")
			KeepWorkLogin.ShowLoginPage()
		end
	end)
end

function KeepWorkLogin.ShowLoginPage()
	local width, height = 960, 560;
	local params = {
		url = "script/apps/Aries/Partners/keepwork/KeepWorkLogin.html", 
		name = "keepwork.KeepWorkLogin", 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1,
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
	};
	
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

-- return true if we can login
function KeepWorkLogin.CheckLoginTime()
	-- cold down time
    KeepWorkLogin.last_send_time = KeepWorkLogin.last_send_time or 0;
	local curTime = ParaGlobal.timeGetTime();
	if((curTime-KeepWorkLogin.last_send_time) < 3000) then
        _guihelper.MessageBox("正在登陆，请等待。。。");
		return;
	end
	KeepWorkLogin.last_send_time = curTime;
	return true
end

function KeepWorkLogin.OnClickLogin(btnName, forms)
    if(not KeepWorkLogin.CheckLoginTime()) then
		return 
	end

	local username = string.gsub(forms.user_name or "", "^%s*(.-)%s*$", "%1");
	local password = string.gsub(forms.password or "", "^%s*(.-)%s*$", "%1");
	
	NPL.load("(gl)script/apps/Aries/Login/ExternalUserModule.lua");
	local ExternalUserModule = commonlib.gettable("MyCompany.Aries.ExternalUserModule");
	local region_config = ExternalUserModule:GetConfig();
    forms = forms or {};
    if(not forms.checkbox_remember_username) then
		forms.checkbox_remember_password = false;
	end
	
    if(not username or string.len(username) == 0)then
		local s = string.format([[%s不能为空!]],MyCompany.Aries.ExternalUserModule:GetConfig().account_name);
        _guihelper.MessageBox(s)
		return
    end
    if(not password or string.len(password) == 0)then
		local s = string.format([[%s不能为空!]],MyCompany.Aries.ExternalUserModule:GetConfig().account_name);
        _guihelper.MessageBox("密码不能为空!")
		return
    end
	
	if(string.len(username)>50) then
		local s = string.format([[请输入正确的%s或Email]],MyCompany.Aries.ExternalUserModule:GetConfig().account_name);
		_guihelper.MessageBox(s)
		return
	end

    KeepWorkLogin.forms = {
        username = username,
        password = password,
        checkbox_remember_username = forms.checkbox_remember_username,
        checkbox_remember_password = forms.checkbox_remember_password,
    }
    local url = "https://keepwork.com/api/wiki/models/user/login";
    System.os.GetUrl({
        url = url,
        json = true,
        form = {
            username = username,
		    password = password,
        }
    }, function(err, msg, data)
		LOG.std(nil, "debug", "keepwork login err", err);
		LOG.std(nil, "debug", "keepwork login msg", msg);
		LOG.std(nil, "debug", "keepwork login data", data);
        if(err and err == 503)then
            _guihelper.MessageBox("keepwork正在维护中，我们马上回来");
            return 
        end
        if(data and data.data and data.data.token)then
			_guihelper.MessageBox(nil);
            if(data.data.userinfo and data.data.userinfo.username)then
                username = data.data.userinfo.username; -- use username in the callback info
            end
            local token = data.data.token;
		    LOG.std(nil, "debug", "keepwork login username", username);
		    LOG.std(nil, "debug", "keepwork login token", token);
            KeepWorkLogin.agreeOauth(username,KeepWorkLogin.client_id,token)
            return 
        end
        if(data and data.error)then
            _guihelper.MessageBox(data.error.message);
            return
        end
    end);
end
function KeepWorkLogin.agreeOauth(username,client_id,token)
    local url = "https://keepwork.com/api/wiki/models/oauth_app/agreeOauth";
    System.os.GetUrl({
        url = url,
        json = true,
        form = {
            username = username,
		    client_id = client_id,
        },
        headers = {
            ["Authorization"] = " Bearer " .. token,
        },
    }, function(err, msg, data)
		LOG.std(nil, "debug", "keepwork agreeOauth err", err);
		LOG.std(nil, "debug", "keepwork agreeOauth msg", msg);
		LOG.std(nil, "debug", "keepwork agreeOauth data", data);
        if(err and err == 503)then
            _guihelper.MessageBox("keepwork正在维护中，我们马上回来");
            return 
        end
        if(data and data.data and data.data.code)then
            local code = data.data.code;
		    LOG.std(nil, "debug", "keepwork agreeOauth code", code);
			

            KeepWorkLogin.ClosePage()
			if(not System.User.keepworktoken) then
				System.User.keepworktoken = token; -- save token
				if(KeepWorkLogin.forms.checkbox_remember_username)then
					if(KeepWorkLogin.forms.checkbox_remember_password)then
						KeepWorkLogin.SaveLocalData(KeepWorkLogin.forms.username,KeepWorkLogin.forms.password)
					else
						KeepWorkLogin.SaveLocalData(KeepWorkLogin.forms.username,nil)
					end
				else
					KeepWorkLogin.SaveLocalData(nil);
				end
			end

            MainLogin:next_step({IsLoginStarted=true, 
                auth_user = {
			        username = username,
			        plat = Platforms.PLATS.KEEPWORK,
			        token = code,
			        oid = string.lower(username),
                    from = Platforms.PLATS.KEEPWORK,
                    loginplat = 1,
                    rememberusername = true
                }
            });
            return;
        end
         if(data and data.error)then
            _guihelper.MessageBox(data.error.message);
        end
    end);
end
function KeepWorkLogin.OnClickChangePassword()
	NPL.load("(gl)script/apps/Aries/Login/ExternalUserModule.lua");
	local ExternalUserModule = commonlib.gettable("MyCompany.Aries.ExternalUserModule");
	local cfg = ExternalUserModule:GetConfig();
	local url_changepasswd= cfg.account_change_url;
	ParaGlobal.ShellExecute("open", url_changepasswd, "", "", 1);
end

function KeepWorkLogin.OnClickForgetPassword()
	NPL.load("(gl)script/apps/Aries/Login/ExternalUserModule.lua");
	local ExternalUserModule = commonlib.gettable("MyCompany.Aries.ExternalUserModule");
	local cfg = ExternalUserModule:GetConfig();
	local url_forgetpasswd= cfg.account_forget_url;
	ParaGlobal.ShellExecute("open", url_forgetpasswd, "", "", 1);
end
-- uncheck remember password if remember username is unchecked. 
function KeepWorkLogin.OnCheckRememberUsername(bChecked)
	if(not bChecked) then
		KeepWorkLogin.page:SetValue("checkbox_remember_password", false);
	end
end

-- notify the user if the password checkbox is checked
function KeepWorkLogin.OnCheckRememberPassword(bChecked)
	if(bChecked == true) then
		local s = string.format([[只有在自己家里上网才能选择“记住密码”；<br/>
		并且要牢记自己的%s和密码哦！
		]],MyCompany.Aries.ExternalUserModule:GetConfig().account_name);
		_guihelper.MessageBox(s);
	end
end