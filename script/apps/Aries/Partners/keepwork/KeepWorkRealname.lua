local KeepWorkRealname = NPL.export()
KeepWorkRealname.haqi_game_timer = nil
KeepWorkRealname.game_time = 0
KeepWorkRealname.m_age = 0
KeepWorkRealname.IsHoliday = false
function KeepWorkRealname.LoadGameTime()
	local local_data = MyCompany.Aries.Player.LoadLocalData("KeepWork_Haqi_Game_Time",{},true);
	local savetime = local_data.savetime or 0
	if savetime == 0 or tonumber(savetime) ~= KeepWorkRealname.GetTimeStampZero() then
		KeepWorkRealname.game_time = 0
		return
	end
	KeepWorkRealname.game_time = tonumber(local_data.gametime)
	if local_data.roleage then
		KeepWorkRealname.m_age = tonumber(local_data.roleage)
	end
	KeepWorkRealname.InitServerTime()
	KeepWorkRealname.InitIsHoliday()
end

function KeepWorkRealname.SaveGameTime()
	local local_data = MyCompany.Aries.Player.LoadLocalData("KeepWork_Haqi_Game_Time",{},true);
	local_data.gametime = KeepWorkRealname.game_time
	local_data.savetime = KeepWorkRealname.GetTimeStampZero()
	local_data.roleage = KeepWorkRealname.m_age
	MyCompany.Aries.Player.SaveLocalData("KeepWork_Haqi_Game_Time", local_data,true)
end

function KeepWorkRealname.GetMaxGameTime()
    if System.options.isDevMode then
        return 60
    end
	return 60*60*KeepWorkRealname.GetHourNum()
end

function KeepWorkRealname.GetHourNum()
    if not KeepWorkRealname.IsHoliday then
        return 1.5
    end
    return 2
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

function KeepWorkRealname.ChekLimitGameTime()
	if KeepWorkRealname.IsLimitTime() then
		return true
	end
	return false
end

function KeepWorkRealname.IsLimitTime()
    if System.options.isDevMode then
        return KeepWorkRealname.game_time > KeepWorkRealname.GetMaxGameTime()
    end
    return KeepWorkRealname.game_time > KeepWorkRealname.GetMaxGameTime() and KeepWorkRealname.GetUserAge() < 18
end

function KeepWorkRealname.SetUserAge(idcardAuth)
	if not idcardAuth then
		return 0 
	end
	local id_user = idcardAuth.idNum
	local year = tonumber(string.sub(id_user,7,10))
    local month = tonumber(string.sub(11,12))
    local day = tonumber(string.sub(13,14))
	local cur_year = tonumber(os.date("%Y", KeepWorkRealname.GetServerTime()))	
	KeepWorkRealname.m_age = cur_year - year
	System.User.IsRealname = true
	System.User.IsAdult = KeepWorkRealname.m_age >= 18 and 1 or 2
end

function KeepWorkRealname.GetUserAge()
	return KeepWorkRealname.m_age or 0
end

function KeepWorkRealname.CheckCanLogin()
	if KeepWorkRealname.GetUserAge() >= 18 then
		return true
	end	
	local curTime = KeepWorkRealname.GetServerTime()
	local today_weehours = KeepWorkRealname.GetTimeStampZero()
	local limit_time_stamp = today_weehours + 8 * 60 * 60 + 0 * 60
	local limit_time_end_stamp = today_weehours + 22 * 60 * 60 + 0 * 60
	if curTime < limit_time_stamp or curTime > limit_time_end_stamp then
		return false
	end
	return true
end

function KeepWorkRealname.CheckCanEnterGame()
    if not KeepWorkRealname.CheckCanLogin() then
        _guihelper.MessageBox("未到游戏时间,请在8点到22点时间段内登录游戏")
        return false
    end

    if KeepWorkRealname.ChekLimitGameTime() then
        _guihelper.MessageBox("你今天的游戏时长已超"..KeepWorkRealname.GetHourNum().."小时，请在明天8点到22点时间段内登录游戏")
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

function KeepWorkRealname.InitServerTime()
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
    if System.options.isDevMode then
        return os.time()
    end
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
	end);
end