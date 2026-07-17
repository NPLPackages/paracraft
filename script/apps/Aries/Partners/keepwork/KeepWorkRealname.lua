local KeepWorkRealname = NPL.export()
KeepWorkRealname.haqi_game_timer = nil
KeepWorkRealname.game_time = 0
KeepWorkRealname.m_age = 0
KeepWorkRealname.IsHoliday = false
local limit_age = 18
function KeepWorkRealname.LoadGameTime()
	local local_data = MyCompany.Aries.Player.LoadLocalData("KeepWork_Haqi_Game_Time",{},true);
	local savetime = local_data.savetime or 0
	if savetime == 0 or tonumber(savetime) ~= KeepWorkRealname.GetTimeStampZero() then
		KeepWorkRealname.game_time = 0
		return
	end
	KeepWorkRealname.game_time = tonumber(local_data.gametime)
end

function KeepWorkRealname.InitServerConfig(callback)
	KeepWorkRealname.callback = callback
	KeepWorkRealname.InitServerTime(function()
		KeepWorkRealname.InitIsHoliday()
	end)
end

function KeepWorkRealname.SaveGameTime()
	local local_data = MyCompany.Aries.Player.LoadLocalData("KeepWork_Haqi_Game_Time",{},true);
	local_data.gametime = KeepWorkRealname.game_time
	local_data.savetime = KeepWorkRealname.GetTimeStampZero()
	local_data.roleage = KeepWorkRealname.m_age
	MyCompany.Aries.Player.SaveLocalData("KeepWork_Haqi_Game_Time", local_data,true)
end

function KeepWorkRealname.GetMaxGameTime()
	return 60*60*KeepWorkRealname.GetHourNum()
end

function KeepWorkRealname.GetHourNum()
	local weekNum = KeepWorkRealname.GetWeekNum()
    if not KeepWorkRealname.IsHoliday or (weekNum >= 1 and weekNum <= 4) then
        return 0
    end
    return 1
end

function KeepWorkRealname.StartGame()
	KeepWorkRealname.haqi_game_timer = commonlib.Timer:new({callbackFunc = function(timer)
		KeepWorkRealname.game_time = KeepWorkRealname.game_time + 1
		if KeepWorkRealname.IsLimitTime()  then
			GameLogic.AddBBS(nil,"游戏时间不足，正在退出")
			MyCompany.Aries.Desktop.Dock.LeaveTown();
            if KeepWorkRealname.haqi_game_timer then
				KeepWorkRealname.haqi_game_timer:Change()
				KeepWorkRealname.haqi_game_timer = nil
			end
		end
		if KeepWorkRealname.IsOutLimitTime() and KeepWorkRealname.GetUserAge() < limit_age then 
			GameLogic.AddBBS(nil,"当天游戏时间已到，请在明天20点到21点时间段内游戏")
			MyCompany.Aries.Desktop.Dock.LeaveTown();
            if KeepWorkRealname.haqi_game_timer then
				KeepWorkRealname.haqi_game_timer:Change()
				KeepWorkRealname.haqi_game_timer = nil
			end
		end
	end})
	KeepWorkRealname.haqi_game_timer:Change(0, 1000);
end

function KeepWorkRealname.ExitGame()
	if KeepWorkRealname.haqi_game_timer then
		KeepWorkRealname.haqi_game_timer:Change()
		KeepWorkRealname.haqi_game_timer = nil
	end
	KeepWorkRealname.SaveGameTime()
end

function KeepWorkRealname.CheckLimitGameTime()
	if KeepWorkRealname.IsLimitTime() then
		return true
	end
	return false
end

function KeepWorkRealname.IsLimitTime()
    return KeepWorkRealname.game_time > KeepWorkRealname.GetMaxGameTime() and KeepWorkRealname.GetUserAge() < limit_age
end

function KeepWorkRealname.SetUserAge(idcardAuth)
	if not idcardAuth then
		return 0 
	end
	local id_user = idcardAuth.idNum
	local year,month,day = KeepWorkRealname.getBirthDateFromIDCard(id_user)
	year,month,day = tonumber(year),tonumber(month),tonumber(day)
	local cur_year = tonumber(os.date("%Y", KeepWorkRealname.GetServerTime()))	
	KeepWorkRealname.m_age = tonumber(cur_year) - year
	System.User.IsRealname = true
	System.User.IsAdult = KeepWorkRealname.m_age >= limit_age and 1 or 2
end

function KeepWorkRealname.getBirthDateFromIDCard(idCard)
    -- 检查身份证号长度
    if #idCard ~= 18 and #idCard ~= 15 then
        return nil, "身份证号长度不正确"
    end

    local birthDate

    if #idCard == 18 then
        -- 18位身份证号
        birthDate = idCard:sub(7, 14)  -- 获取出生日期部分（YYYYMMDD）
    elseif #idCard == 15 then
        -- 15位身份证号
        local year = "19" .. idCard:sub(7, 9) -- 15位身份证年份前加"19"
        local month = idCard:sub(10, 11)
        local day = idCard:sub(12, 13)
        birthDate = year .. month .. day
    end

    -- 格式化出生日期为 YYYY-MM-DD
    return birthDate:sub(1, 4), birthDate:sub(5, 6), birthDate:sub(7, 8)
end

function KeepWorkRealname.GetUserAge()
	return KeepWorkRealname.m_age or 0
end

function KeepWorkRealname.CheckCanLogin()
	if KeepWorkRealname.GetUserAge() >= limit_age then
		return true
	end	
	local curTime = KeepWorkRealname.GetServerTime()
	local weekNum = KeepWorkRealname.GetWeekNum()
	if weekNum >= 1 and weekNum <= 4 then
		return false
	end
	if KeepWorkRealname.IsOutLimitTime() then
		return false
	end
	return true
end

function KeepWorkRealname.IsOutLimitTime()
	local curTime = KeepWorkRealname.GetServerTime()
	local today_weehours = KeepWorkRealname.GetTimeStampZero()
	local limit_time_stamp = today_weehours + 20 * 60 * 60 + 0 * 60
	local limit_time_end_stamp = today_weehours + 21 * 60 * 60 + 0 * 60
	if curTime < limit_time_stamp or curTime > limit_time_end_stamp then
		return true
	end
	return false
end

function KeepWorkRealname.CheckCanEnterGame()
    if not KeepWorkRealname.CheckCanLogin() then
		local msg_content = [[<div style="font-size:10px; base-font-size:10px;">根据国家新闻出版署《关于防止未成年人沉迷网络游戏的通知》《关于进一步严格管理切实防止未成年人沉迷网络游戏的通知》，未成年玩家仅可在周五、周六、周日及法定节假日的20时至21时登录游戏。您已被认证为未成年玩家，当前无法进入游戏。</div>]]
		_guihelper.MessageBox(msg_content)
		return false
    end
	if KeepWorkRealname.CheckLimitGameTime() then
        _guihelper.MessageBox("你今天的游戏时长已满，请在明天20点到21点时间段内登录游戏")
        return false
    end

    return true
end

function KeepWorkRealname.GetTimeStampZero()
	local curTime = KeepWorkRealname.GetServerTime()
	local year = tonumber(os.date("%Y", curTime))	
	local month = tonumber(os.date("%m", curTime))
	local day = tonumber(os.date("%d", curTime))
	local today_weehours = os.time({year = year, month = month, day = day, hour=0, min=0, sec=0})
	return today_weehours
end

function KeepWorkRealname.LoginAction(type)
    NPL.load("(gl)script/apps/Aries/Partners/keepwork/KeepWorkLogin.lua");
    local KeepWorkLogin = commonlib.gettable("MyCompany.Aries.Partners.keepwork.KeepWorkLogin");
    KeepWorkLogin.LoginAction(type)
end

function KeepWorkRealname.InitServerTime(callback)
    local url = "https://api.keepwork.com/core/v0/keepworks/currentTime";
	System.os.GetUrl({
		url = url,
		headers = {
			["Authorization"] = " Bearer " .. (System.User.keepworktoken or ""),
		},
	}, function(err, msg, data)
		if(err and err == 503)then
			_guihelper.MessageBox("keepwork正在维护中，我们马上回来");
			return 
		end
		if data and data.timestamp then
			KeepWorkRealname.server_stamp = math.floor(data.timestamp/1000)
			KeepWorkRealname.UpdateServerTime()
		end
		if not KeepWorkRealname.server_stamp then
			_guihelper.MessageBox("同步服务器时间失败，请重启游戏");
			return
		end
		if callback and type(callback) == "function" then
			callback()
		end
	end);
end

function KeepWorkRealname.UpdateServerTime()
    if not KeepWorkRealname.server_stamp then
        return
    end
	if KeepWorkRealname.update_server_timer then
		KeepWorkRealname.update_server_timer:Change()
		KeepWorkRealname.update_server_timer = nil
	end
    KeepWorkRealname.update_server_timer = commonlib.Timer:new({callbackFunc = function(timer)
		KeepWorkRealname.server_stamp = KeepWorkRealname.server_stamp + 1
	end})
	KeepWorkRealname.update_server_timer:Change(0, 1000);
end

function KeepWorkRealname.GetServerTime()
    return KeepWorkRealname.server_stamp or os.time()
end

function KeepWorkRealname.InitIsHoliday()
	local url = "https://api.keepwork.com/core/v0/holiday";
	System.os.GetUrl({
		url = url,
		headers = {
			["Authorization"] = " Bearer " .. (System.User.keepworktoken or ""),
		},
	}, function(err, msg, data)
		if(err and err == 503)then
			_guihelper.MessageBox("keepwork正在维护中，我们马上回来");
			return 
		end
		if data and data.isHoliday then
			KeepWorkRealname.IsHoliday = data.isHoliday
		end
		if KeepWorkRealname.callback and type(KeepWorkRealname.callback) == "function" then
			KeepWorkRealname.callback()
		end
	end);
end

function KeepWorkRealname.GetWeekNum()
	local curTime = KeepWorkRealname.GetServerTime()
    local time_stamp = curTime or 0
    local weekNum = os.date("*t",time_stamp).wday - 1
    if weekNum == 0 then
        weekNum = 7
    end
    return weekNum
end