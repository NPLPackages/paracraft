--[[
Title: Aries Registration Page
Author(s): leio
Date: 2017/8/8
Desc:  script/apps/Aries/Partners/keepwork/KeepWorkRegPage.html
Display recommended world server list. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Partners/keepwork/KeepWorkRegPage.lua");
local KeepWorkRegPage = commonlib.gettable("MyCompany.Aries.keepwork.KeepWorkRegPage")
KeepWorkRegPage.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Login/AccountUserSelectPage.lua");
local AccountUserSelectPage = commonlib.gettable("MyCompany.Aries.AccountUserSelectPage");
local KeepWorkRegPage = commonlib.gettable("MyCompany.Aries.keepwork.KeepWorkRegPage")

---------------------------------
-- page event handlers
---------------------------------
-- singleton page
local page;
local MainLogin = commonlib.gettable("MyCompany.Aries.MainLogin");
local session;
local realnm_reg;
local reg_values = {};

local string_len = string.len;
local math_mod = math.mod;
local string_match = string.match;

-- init
function KeepWorkRegPage.OnInit()
	page = document:GetPageCtrl();
	--local self = document:GetPageCtrl();
	--local name = self:GetRequestParam("name")
	--self:SetNodeValue("fileName", name);
	session= page:GetRequestParam("session") or "";
	realnm_reg = page:GetRequestParam("realname_reg") or false;
end
function KeepWorkRegPage.ShowPage()
    System.App.Commands.Call("File.MCMLWindowFrame", {
	    url = "script/apps/Aries/Partners/keepwork/KeepWorkRegPage.html",
	    name = "Aries.KeepWorkRegPage", 
	    isShowTitleBar = false,
	    allowDrag = false,
	    DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
	    style = CommonCtrl.WindowFrame.ContainerStyle,
	    zorder = 1000,
	    directPosition = true,
	    enable_esc_key = true,
	    align = "_ct",
	    x = -900/2,
	    y = -600/2,
	    width = 800,
	    height = 600,
    });
end

function KeepWorkRegPage.RealnameReg()	
	page:CloseWindow();
	local realnm=1;
	MyCompany.Aries.UserLoginPage.OnClickRegister(realnm);
end

function KeepWorkRegPage.IsOK()
	NPL.load("(gl)script/ide/common_validators.lua");
	local IsIDNO = commonlib.validators.id.IsIDNO;
	local IsDate = commonlib.validators.date.IsDate;

	local ErrorColor = "#FF0000";
	local GoodColor = "#00aa00";
	local bIsOK=true;
	reg_values.username = page:GetValue("username");
	reg_values.password = page:GetValue("password");
	reg_values.password_confirm = page:GetValue("password_confirm");	
	
	--commonlib.echo("=================reg_values.password");
	--commonlib.echo(reg_values.password);

	local sbirthday="";

	if (realnm_reg) then
		
		reg_values.realname = page:GetValue("realname");
		local idno = page:GetValue("idno") or "";
		reg_values.idno = idno;
		if (not IsIDNO(idno)) then
			page:SetUIValue("idno_label", "身份证号由15或18位组成，如果不知道，可以向爸爸妈妈借看一下户口本");
			page:CallMethod("idno_label", "SetUIColor", ErrorColor);
			bIsOK=false;	
		else
			page:SetUIValue("idno_label", "身份证号正确!");
			page:CallMethod("idno_label", "SetUIColor", GoodColor);							

			local areacode,birthdate,lastcode;
			if (string_len(idno)==15)then
				sareacode,sbirthdate,slastcode=string_match(idno,"^(%w%w%w%w%w%w)(%w%w%w%w%w%w)(%w%w%w)");
				sbirthdate="19"..sbirthdate;
			else
				sareacode,sbirthdate,slastcode,slastchar=string_match(idno,"^(%w%w%w%w%w%w)(%w%w%w%w%w%w%w%w)(%w%w%w)(%w)");
			end
			local sbirthyear,sbirthmonth,sbirthday = string_match(sbirthdate,"(%d%d%d%d)(%d%d)(%d%d)");
			
			local birth_year = tonumber(sbirthyear) or 1990;
			local birth_month = tonumber(sbirthmonth) or 1;
			local birth_day = tonumber(sbirthday) or 1;
			local lastcode = tonumber(slastcode) or 0;
			if (IsDate(birth_year,birth_month,birth_day)) then
				reg_values.birthday = tonumber(sbirthdate);
				local sexcode=math_mod(lastcode,2);
				if (sexcode==0) then
					reg_values.sex = 0;
				else
					reg_values.sex = 2;
				end			
			end
		end
	else 	
		--reg_values.sex = tonumber(page:GetValue("sex"));
		--local sbirth_year = page:GetValue("birth_year");
		--local sbirth_month = page:GetValue("birth_month");
		--local sbirth_day = page:GetValue("birth_day");
		--local birth_month = tonumber(sbirth_month) or 1;
		--local birth_day = tonumber(sbirth_day) or 1;
--
		--if (birth_month<10) then
			--sbirthday = sbirth_year.."0"..tostring(birth_month);
		--else
			--sbirthday = sbirth_year..tostring(birth_month);
		--end
		--if (birth_day<10) then
			--sbirthday = sbirthday.."0"..tostring(birth_day);
		--else
			--sbirthday = sbirthday..tostring(birth_day);
		--end		
		--reg_values.birthday = tonumber(sbirthday);
		reg_values.sex = 4;	
		reg_values.birthday = 20000101;
		reg_values.idno = "0";
		reg_values.realname = "";
		-- reg_values.email = "";
		reg_values.email = page:GetValue("email") or "";
	end
	
--	reg_values.txtVeriCode = string.lower(page:GetValue("txtVeriCode"));
--	reg_values.session = session;

--	if(string.len(reg_values.txtVeriCode) ~= 4) then
--		page:SetUIValue("vfy_label", "请输入左边显示的4位验证码!");
--		page:CallMethod("vfy_label", "SetUIColor", ErrorColor);
--		bIsOK=false;
--	else
--		page:SetUIValue("vfy_label", "请输入左边显示的4位验证码!");
--		page:CallMethod("vfy_label", "SetUIColor", ErrorColor);
--	end

	local agree_rule =page:GetValue("agree_rule");
	if(type(agree_rule) == "boolean") then 
		if(not agree_rule) then
			page:SetUIValue("agreerule_label", "你还没有同意注册协议！");
			page:CallMethod("agreerule_label", "SetUIColor", ErrorColor);
			bIsOK=false;
		else
			page:SetUIValue("agreerule_label", "");
			page:CallMethod("agreerule_label", "SetUIColor", GoodColor);
		end		
	end	

	local usernamelen = string.len(reg_values.username);
	local passwdlen = string.len(reg_values.password);
	local top50={};
	if ( passwdlen==6 ) then
		top50={"123456","123321","123123","789456","112233","qwerty","asdfgh","456123","qazwsx","159753","121212","147258","123654","159357","zxcvbn","456789","123789","654321","741852","asdasd","234567","345678","456789","567890","012345"};
	elseif (passwdlen==7) then
		top50={"zxcvbnm","1234567","7758258","1234560","5201314"};
	elseif (passwdlen==9) then
		top50={"123456789","789456123","asdfghjkl","147258369","741852963","123123123","987654321","qazwsxedc","963852741","123654789","147852369"};
	else
		top50 ={"12345678","1234567890","qwertyuiop","0123456789","7894561230","12345678910","1233211234567"};
	end
	if(reg_values.username ~= string.match(reg_values.username, "[a-zA-Z_0-9]+")) then
		page:SetUIValue("username_label", "用户名只能由大小写字母、数字、下划线组成");
		page:CallMethod("username_label", "SetUIColor", ErrorColor);
		bIsOK=false;
	elseif( usernamelen < 6 ) then
		page:SetUIValue("username_label", "用户名长度最少6个字节");
		page:CallMethod("username_label", "SetUIColor", ErrorColor);
		bIsOK=false;
    elseif( usernamelen > 30 ) then
		page:SetUIValue("username_label", "用户名长度最长30个字节");
		page:CallMethod("username_label", "SetUIColor", ErrorColor);
		bIsOK=false;
	else
		page:SetUIValue("username_label", "");
    end
    if(reg_values.password ~= string.match(reg_values.password, "[a-zA-Z_0-9]+")) then
		page:SetUIValue("password_label", "密码只能由大小写字母、数字、下划线组成");
		page:CallMethod("password_label", "SetUIColor", ErrorColor);
		bIsOK=false;
	elseif( passwdlen < 6 ) then
		page:SetUIValue("password_label", "密码长度最少6个字节");
		page:CallMethod("password_label", "SetUIColor", ErrorColor);
		bIsOK=false;
	elseif( passwdlen > 16 ) then	
		page:SetUIValue("password_label", "密码长度最长16个字节");
		page:CallMethod("password_label", "SetUIColor", ErrorColor);
		bIsOK=false;
	else
		local firstChar = string.sub(reg_values.password,1,1);
		local cmpString = string.rep(firstChar,6);
		if (cmpString == reg_values.password) then
			page:SetUIValue("password_label", "该密码容易被盗，请修改为更复杂的密码");
			page:CallMethod("password_label", "SetUIColor", ErrorColor);
			bIsOK=false;
		else
			local _,v;
			local testID=1;
			for _,v in pairs(top50) do
				if (reg_values.password == v) then
					page:SetUIValue("password_label", "该密码容易被盗，请修改为更复杂的密码");
					page:CallMethod("password_label", "SetUIColor", ErrorColor);
					testID = 0;
					break;
				end
			end
			if (testID==1) then
				page:SetUIValue("password_label", "密码长度符合规则");
				page:CallMethod("password_label", "SetUIColor", GoodColor);
			end
		end
	end
		
	if(reg_values.password ~= reg_values.password_confirm) then	
		page:SetUIValue("password_confirm_label", "两次密码输入不一致哦!请再次输入上面的密码！");
		page:CallMethod("password_confirm_label", "SetUIColor", ErrorColor);
		bIsOK=false;
	else
		if(string.len(reg_values.password_confirm)==0)then
			page:SetUIValue("password_confirm_label", "密码不能为空!请再次输入上面的密码，确保一致！");
			page:CallMethod("password_confirm_label", "SetUIColor", ErrorColor);
			bIsOK=false;
		else
			page:SetUIValue("password_confirm_label", "密码输入一致!");
			page:CallMethod("password_confirm_label", "SetUIColor", GoodColor);
		end
	end

	if (realnm_reg or true) then
		local chkEmail,chkEmail_len = string.find(reg_values.email, "[A-Za-z0-9%.%%%+%-%_]+@[A-Za-z0-9%.%%%+%-%_]+%.%w%w%w?%w?");
		local Email_len = string.len(reg_values.email);
	--	if(not string.find(reg_values.email, "[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?")) then	
		if(not chkEmail) then	
			page:SetUIValue("email_label", "电子邮箱格式不正确，请重新输入!");
			page:CallMethod("email_label", "SetUIColor", ErrorColor);
			bIsOK=false;
		elseif (Email_len > 60) then
			page:SetUIValue("email_label", "电子邮箱过长，请重新输入!");
			page:CallMethod("email_label", "SetUIColor", ErrorColor);
			bIsOK=false;
		else
			page:SetUIValue("email_label", "请输入自己的邮箱，这是你取回密码最重要的途径！");
			page:CallMethod("email_label", "SetUIColor", GoodColor);
		end
	end

	page:SetUIEnabled("confirm_btn", bIsOK);
	
	return bIsOK;
end

function KeepWorkRegPage.RegisterEmailChk()
	reg_values.email = page:GetValue("email");
	local ErrorColor = "#FF0000";
	local GoodColor = "#00aa00";
	
	local bIsOK=true;

	if (realnm_reg or true) then
		local chkEmail,chkEmail_len = string.find(reg_values.email, "[A-Za-z0-9%.%%%+%-%_]+@[A-Za-z0-9%.%%%+%-%_]+%.%w%w%w?%w?");
		local Email_len = string.len(reg_values.email);

		if(not chkEmail) then	
			local thisDay=ParaGlobal.GetDateFormat("yMMdd");
			local thisTime=ParaGlobal.GetTimeFormat("HHmmss");
			local vmail="sample"..thisDay..thisTime.."@163.com";
			page:SetUIValue("email_label", "电子邮箱格式不正确，请重新输入!");
			page:CallMethod("email_label", "SetUIColor", ErrorColor);
			page:SetUIValue("email",vmail);
			bIsOK=false;
		elseif (Email_len > 60) then
			page:SetUIValue("email_label", "电子邮箱过长，请重新输入!");
			page:CallMethod("email_label", "SetUIColor", ErrorColor);
			bIsOK=false;
		elseif (chkEmail_len < Email_len or chkEmail ~=1) then
			local vmail=string.sub(reg_values.email,chkEmail,chkEmail_len);
			page:SetUIValue("email_label", "电子邮箱格式不正确，请重新输入!");
			page:CallMethod("email_label", "SetUIColor", ErrorColor);
			page:SetUIValue("email",vmail);
			bIsOK=false;
		else
			page:SetUIValue("email_label", "请输入自己的邮箱，这是你取回密码最重要的途径！");
			page:CallMethod("email_label", "SetUIColor", GoodColor);		
		end
	end

	if(bIsOK) then
		KeepWorkRegPage.OnRegister();
	else
		_guihelper.MessageBox("电子邮箱格式不正确! 系统已帮你纠正，请重新检查！如果已经正确，请按<font color='#ff0000'>下一步</font>！");
		bIsOK=true;
	end
end

--function KeepWorkRegPage.OnRegister(name, values)
function KeepWorkRegPage.OnRegister()
	local bIsOK=KeepWorkRegPage.IsOK();
	if(bIsOK) then
		--reg_values.email = string.lower(reg_values.email);
		--MainLogin.state.reg_user = {username = reg_values.email, password = reg_values.password, session=reg_values.session, vericode=reg_values.txtVeriCode, no = reg_values.idno, gender = reg_values.sex, birthday=reg_values.birthday , realname=reg_values.realname};
        local username = reg_values.username;
        local password = reg_values.password;
		local email = string.lower(reg_values.email);
        -- local url = "http://keepwork.com/api/wiki/models/user/register"; 
		local url = "https://api.keepwork.com/core/v0/users/register";
		

		_guihelper.MessageBox("注册中，请稍后...");

        System.os.GetUrl({
            url = url,
            json = true,
            form = {
                username = username,
		        password = password,
				email = email,
            }
		}, function(err, msg, data)
			LOG.std(nil, "debug", "keepwork register err", err);
			LOG.std(nil, "debug", "keepwork register msg", msg);
			LOG.std(nil, "debug", "keepwork register data", data);

			local function showError(data)
				if(data and data.error)then
					local s = string.format("注册失败了，可能用户名已经存在或不符合要求。%s",data.error.message or "");
					_guihelper.MessageBox(s);
				else
					_guihelper.MessageBox("注册失败了，可能用户名已经存在或不符合要求。");
				end
			end
			if(err == 200)then
				_guihelper.CloseMessageBox();
				-- data = data.data;
                if(data and data.token)then
                    token = data.token;
					LOG.std(nil, "debug", "keepwork register token", token);
					if(token)then
						if(data.userinfo and data.userinfo.username)then
							username = data.userinfo.username; -- use username in the callback info
						end
						if(data.username) then
							username = data.username;
						end
						LOG.std(nil, "debug", "keepwork register username", username);

						AccountUserSelectPage.CloseWindow();
                        NPL.load("(gl)script/apps/Aries/Partners/keepwork/KeepWorkLogin.lua");
                        local KeepWorkLogin = commonlib.gettable("MyCompany.Aries.Partners.keepwork.KeepWorkLogin");
                        KeepWorkLogin.forms = {
                            username = username,
                            checkbox_remember_username = true,
                        }
                        KeepWorkLogin.agreeOauth(username,KeepWorkLogin.client_id,token);
					end
				else
					showError(data);
				end
			else
				showError(data);
			end
        end);
		if(page) then
			page:CloseWindow();
		end		
	end
end

function KeepWorkRegPage.OnClose()
	page:CloseWindow();
end
function KeepWorkRegPage.VisitTaoMeeService()
	ParaGlobal.ShellExecute("open", "https://keepwork.com/official/keepwork/license/license_cn", "", "", 1);
end