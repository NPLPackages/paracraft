--[[
Title: UserInfoPage
Author(s): 
Date: 2020/8/6
Desc:  
Use Lib:
-------------------------------------------------------
local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserInfoPage.lua");
UserInfoPage.ShowPage();
--]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CustomSkinPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");
local Encoding = commonlib.gettable("System.Encoding");
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local UserInfoPage = NPL.export()
local SystemUserData = KeepWorkItemManager.GetProfile();
local SystemUserName = commonlib.getfield("System.User.username")
local SystemUserID = SystemUserData and SystemUserData.id or 0
local isLogin = System.User.keepworkUsername and System.User.keepworkUsername ~= ""
local player = GameLogic.GetPlayerController():GetPlayer();
local freeSkinIds = {
	80001;82001;84020;85058, --boy
	82004;84028;81018;88002;85029 --girl
}
--人物旁边的
UserInfoPage.isChangeNickName = false
UserInfoPage.userScale = 1
UserInfoPage.mainAssets = ""
UserInfoPage.mainSkin = ""
UserInfoPage.skin_category_index = -1
UserInfoPage.Current_SkinItem_DS = {}
UserInfoPage.Current_Icon_DS = {}
UserInfoPage.skin_category_ds = {
	{tex1 = "zi_toushi1_28X14_32bits", tex2 = "zi_toushi2_28X14_32bits", name = "hair", ui_index = 7},
	{tex1 = "zi_yanjing2_28X14_32bits", tex2 = "zi_yanjing1_28X14_32bits", name = "eye", ui_index = 1},
	{tex1 = "zi_zuiba1_28X14_32bits", tex2 = "zi_zuiba2_28X14_32bits", name = "mouth", ui_index = 2},
	{tex1 = "zi_yifu1_28X14_32bits", tex2 = "zi_yifu2_28X14_32bits", name = "shirt", ui_index = 3},
	{tex1 = "zi_kuzi1_28X14_32bits", tex2 = "zi_kuzi2_28X14_32bits", name = "pants", ui_index = 4},
	{tex1 = "zi_shouchi1_28X14_32bits", tex2 = "zi_shouchi2_28X14_32bits", name = "right_hand_equipment", ui_index = 6},
	{tex1 = "zi_beibu1_28X14_32bits", tex2 = "zi_beibu2_28X14_32bits", name = "back", ui_index = 5},
	{tex1 = "zi_zuoqi1_28X14_32bits", tex2 = "zi_zuoqi2_28X14_32bits", name = "pet", ui_index = 8},
};

UserInfoPage.MenuItem_DS = {
	{title="作<br/>品",ui_index = 1,text="作品", name="works"},
	{title="换<br/>装<br/>商<br/>城",ui_index = 2,text="换装商城", name="skin",isAuth = true},
	{title="荣<br/>誉",ui_index = 3,text="荣誉", name="honor"},
	{title="背<br/>包",ui_index = 4,text="背包", name="bags",isAuth = true},
	{title="账<br/>号<br/>安<br/>全",ui_index = 5,text="账号安全", name="security",isAuth = true}
}

UserInfoPage.CurBagItem_DS = {}
UserInfoPage.CurHonor_DS = {}
UserInfoPage.authUsers = {}
UserInfoPage.CurProject_DS = {}
UserInfoPage.category_name = ""
UserInfoPage.select_project_index = -1
UserInfoPage.UserData = nil
UserInfoPage.isOnlyShowHave = false
UserInfoPage.IsFollow = false
UserInfoPage.IsFriend = false
UserInfoPage.isExpland_Follow = false
_G.SKIN_ITEM_TYPE = {
	FREE = "0",
	VIP = "1",
	ONLY_BEANS_CAN_PURCHASE = "2",
	ACTIVITY_GOOD = "3",
	-- 套装部件
	SUIT_PART = "5"
}

_G.FRIEND_TYPE = {
	NORMAL = 1,
	FOLLOW = 2,
	FRIEND = 3,
}
UserInfoPage.CurFriendType = FRIEND_TYPE.NORMAL
UserInfoPage.buyClothesData = nil
local page
function UserInfoPage.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = UserInfoPage.OnCreate
end

function UserInfoPage.ShowPage(username,category_name,userId)
	local category_name = category_name or "works"
	UserInfoPage.InitData()
	local username = (username and username ~= "") and username or SystemUserName
	if not username or username == ""  then
		username = "deng123456"
	end
	local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
	if userId and tonumber(userId) > 0 then
		id = "kp" .. Encoding.base64(commonlib.Json.Encode({userId=userId}));
	end
	keepwork.user.getinfo({
		cache_policy = "access plus 0",
        router_params = {
            id = id,
        }
    },function (err, msg, data)
		if err == 200 then
			UserInfoPage.UserData = data
			-- echo(data,true)
			-- echo(SystemUserData,true)
			UserInfoPage.GetSkinIconByUserData()
			if UserInfoPage.IsAuthUser() then
				UserInfoPage.ShowView(category_name)
			else
				UserInfoPage.CheckIsFollow(function()
					UserInfoPage.CheckIsFriend(function()
						UserInfoPage.UpdateFriendType()
						UserInfoPage.ShowView(category_name)
					end)
				end)
			end
		else
			UserInfoPage.LoginOutByErrToken(err)
		end
	end)
end

function UserInfoPage.IsVisible()
	return page and page:IsVisible()
end

function UserInfoPage.InitData()
	UserInfoPage.buyClothesData = nil
	UserInfoPage.isExpland_Follow = false
	UserInfoPage.IsFollow = false
	UserInfoPage.IsFriend = false
	UserInfoPage.isOnlyShowHave = false
	UserInfoPage.skin_category_index = -1
	UserInfoPage.authUsers = {}
	UserInfoPage.CurHonor_DS = {}
	UserInfoPage.CurProject_DS = {}
	UserInfoPage.category_name = ""
	UserInfoPage.UserData = nil
	UserInfoPage.CurFriendType = FRIEND_TYPE.NORMAL
	UserInfoPage.select_project_index = -1
	UserInfoPage.Current_Icon_DS = {};
	for i = 1, #UserInfoPage.skin_category_ds do
		UserInfoPage.Current_Icon_DS[i] = {id = "", icon = "", name = ""} 
	end
	UserInfoPage.mainAssets = player and player:GetMainAssetPath()
	UserInfoPage.mainSkin = player and player:GetSkin()
	UserInfoPage.CurBagItem_DS = UserInfoPage.GetItemData()
	SystemUserData = KeepWorkItemManager.GetProfile();
	SystemUserName = commonlib.getfield("System.User.username")
	SystemUserID = SystemUserData and SystemUserData.id or 0
	UserInfoPage.isChangeNickName = UserInfoPage.CheckHasUpdateNickName()
end

function UserInfoPage.FormatTime(datetime)
	local time_stamp = type(datetime) == "string" and commonlib.timehelp.GetTimeStampByDateTime(datetime) or datetime
	local year = os.date("%Y", time_stamp)	
	local month = os.date("%m", time_stamp)
	local day = os.date("%d", time_stamp)
	local hour = os.date("%H", time_stamp)
	local min = os.date("%M", time_stamp)
	local sec = os.date("%S", time_stamp)
	return string.format("%s-%s-%s %s:%s:%s", year,month,day,hour,min,sec);
end

function UserInfoPage.GetVipDeadlineStr()
	local data = UserInfoPage.UserData
	if data then
		if data.vip == 1 and not data.vipDeadline then
			return "永久使用"
		end
		if data.vipDeadline and data.vipDeadline ~= "" then
			return UserInfoPage.GetDeadlineStr(data.vipDeadline)
		end
	end
end

function UserInfoPage.GetPurchaseTime(skinId)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
	local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
	local clothes = UserInfoPage.GetClothesOfServerData() or {}
	for i,v in ipairs(clothes) do
		if skinId and tonumber(v.itemId) == tonumber(skinId) then
			local startTime =  UserInfoPage.FormatTime(v.startAt)
			local server_time = QuestAction.GetServerTime()
			local curDateTime = UserInfoPage.FormatTime(tonumber(server_time))
			local day,hours,minutes,seconds,time_str = commonlib.GetTimeStr_BetweenToDate(startTime, curDateTime);
			if day < 10 then
				return 10 - day
			elseif day == 10 and math.abs(hours - 24) > 0 then 
				return 1
			end
		end
	end
	return 0
end

function UserInfoPage.UpdateClotheData(clothesData)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
	local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
	if clothesData then
		-- echo(clothesData,true)
		local temp = {}
		for i,v in ipairs(clothesData) do
			local startTime =  UserInfoPage.FormatTime(v.startAt)
			local server_time = QuestAction.GetServerTime()
			local curDateTime = UserInfoPage.FormatTime(tonumber(server_time))
			local day,hours,minutes,seconds,time_str = commonlib.GetTimeStr_BetweenToDate(startTime, curDateTime);
			if day < 10  then
				temp[#temp + 1] = v
			elseif day == 10 and math.abs(hours - 24) > 0 then 
				temp[#temp + 1] = v
			end
		end
		return temp
	end
end

function UserInfoPage.GetDeadlineStr(EndTime)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
	local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
	if EndTime and EndTime ~= "" then
		local deadTime =  UserInfoPage.FormatTime(EndTime)
		local server_time = QuestAction.GetServerTime()
		local curDateTime = UserInfoPage.FormatTime(tonumber(server_time))
		local day,hours,minutes,seconds,time_str = commonlib.GetTimeStr_BetweenToDate(curDateTime, deadTime);
		if day > 365 then
			return string.format("%d年%d天",math.floor(day/365),day - math.floor(day/365) * 365)
		else
			return string.format("%d天",day)			
		end
	end
end

function UserInfoPage.IsInDeadLine(EndTime)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
	local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
	if EndTime and EndTime ~= "" then
		local deadTime =  UserInfoPage.FormatTime(EndTime)
		local server_time = QuestAction.GetServerTime()
		local curDateTime = UserInfoPage.FormatTime(tonumber(server_time))
		local day,hours,minutes,seconds,time_str = commonlib.GetTimeStr_BetweenToDate(curDateTime, deadTime);
		return day > 0 or hours > 0 or minutes > 0 or seconds > 0
	end
end

function UserInfoPage.UpdateFriendType()
	if UserInfoPage.IsAuthUser() then
		return
	end
	UserInfoPage.CurFriendType = FRIEND_TYPE.NORMAL
	if UserInfoPage.IsFriend then
		UserInfoPage.CurFriendType = FRIEND_TYPE.FRIEND
		return 
	end
	if UserInfoPage.IsFollow then
		UserInfoPage.CurFriendType = FRIEND_TYPE.FOLLOW
	end
end

function UserInfoPage.CheckIsFollow(callback)
	keepwork.user.isfollow({
		objectId = UserInfoPage.UserData.id,
		objectType = 0,
	}, function(status, msg, data) 
		if (status == 200 and data and data ~= "false" and tonumber(data) ~= 0) then
			UserInfoPage.IsFollow = true
		end
		if callback then
			callback()
		end
	end)
end

function UserInfoPage.CheckIsFriend(callback)
	local username = UserInfoPage.GetUserName()
	if not username or username == "" then
		if callback then
			callback()
		end
		return 
	end
	local userid = UserInfoPage.UserData and UserInfoPage.UserData.id or -1
	keepwork.user.friends({
		username=username,
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        }
	},function(err, msg, data)
		-- commonlib.echo(data, true)
		if err == 200 and data and #data.rows > 0 then
			for i,v in ipairs(data.rows) do
				if v.id == userid then
					UserInfoPage.IsFriend = true
					break
				end
			end
		end
		if callback then
			callback()
		end
	end)
end

function UserInfoPage.UpdateUserData()
	local username = SystemUserName
	if not username or username == ""  then
		username = "deng123456"
	end
	local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
	keepwork.user.getinfo({
		cache_policy = "access plus 0",
        router_params = {
            id = id,
        }
    },function (err, msg, data)
		if err == 200 then
			UserInfoPage.UserData = data
			UserInfoPage.RefreshPage()
		else
			UserInfoPage.LoginOutByErrToken(err)
		end
	end)
end

function UserInfoPage.ShowView(category_name)
	UserInfoPage.userScale = (UserInfoPage.UserData and UserInfoPage.UserData.extra and UserInfoPage.UserData.extra.ParacraftPlayerEntityInfo) and UserInfoPage.UserData.extra.ParacraftPlayerEntityInfo.scale or 1
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/User/UserInfoPage.html",
		name = "UserInfoPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		cancelShowAnimation = true,
		enable_esc_key = false,
		zorder = 0,
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	-- echo(UserInfoPage.UserData,true)
	commonlib.TimerManager.SetTimeout(function()
		UserInfoPage.OnChangeCategory(category_name)
	end,200)
end

function UserInfoPage.OnCreate()
	if page then
		if UserInfoPage.mainAssets and UserInfoPage.mainAssets ~= "" then
			page:CallMethod("UserInfoMyPlayer", "SetAssetFile", UserInfoPage.mainAssets);
		end
		if UserInfoPage.mainSkin and UserInfoPage.mainSkin ~= "" then
			page:CallMethod("UserInfoMyPlayer", "SetCustomGeosets", UserInfoPage.mainSkin)
		end
		local module_ctl = page:FindControl("UserInfoMyPlayer")
		local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
		if scene and scene:IsValid() then
			local player = scene:GetObject(module_ctl.obj_name);
			if player then
				player:SetScale(UserInfoPage.userScale)
				player:SetFacing(1.57);
				player:SetField("HeadUpdownAngle", 0.2);
				player:SetField("HeadTurningAngle", 0);
				
			end
			-- module_ctl:SetScale(Userin)
		end
		page:SetValue("Role_Scaling", tostring(UserInfoPage.userScale));
	end
end

function UserInfoPage.SetUserScale()
	if page then
		
		local module_ctl = page:FindControl("UserInfoMyPlayer")
		local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
		if scene and scene:IsValid() then
			local player = scene:GetObject(module_ctl.obj_name);
			if player then
				player:SetScale(UserInfoPage.userScale)
			end
			-- module_ctl:SetScale(Userin)
		end
	end
end

function UserInfoPage.GetMenuDatas()
	if UserInfoPage.IsAuthUser() then
		return UserInfoPage.MenuItem_DS
	end
	local temp= {}
	for i=1,#UserInfoPage.MenuItem_DS do
		if not UserInfoPage.MenuItem_DS[i].isAuth then
			temp[#temp + 1] = UserInfoPage.MenuItem_DS[i]
		end
	end
	return temp
end

function UserInfoPage.RefreshPage()
	if page then
		page:Refresh(0)
	end
end

function UserInfoPage.ClosePage(bOnlyClose)
	if not bOnlyClose then
		UserInfoPage.ChangePlayerSkinWhenClose()
	end
	if page then
		page:CloseWindow()
		page = nil
	end
end



function UserInfoPage.GetSystemUserId()
	return SystemUserID or 0
end

function UserInfoPage.GetSystemUserName()
	return SystemUserName or ""
end

function UserInfoPage.GetUserName()
	return UserInfoPage.UserData ~= nil and UserInfoPage.UserData.username or ""
end

function UserInfoPage.GetNickName()
	local nickName = (UserInfoPage.UserData and UserInfoPage.UserData.nickname and UserInfoPage.UserData.nickname ~= "") and UserInfoPage.UserData.nickname or UserInfoPage.GetUserName()
	return nickName
end

function UserInfoPage.IsAuthUser()
	return SystemUserName and SystemUserName ~= "" and UserInfoPage.GetUserName() == SystemUserName
end

function UserInfoPage.GetFollowNum()
	local rank = UserInfoPage.UserData ~= nil and UserInfoPage.UserData.rank or {}
	return rank and rank.follow or 0 
end

function UserInfoPage.GetFansNum()
	local rank = UserInfoPage.UserData ~= nil and UserInfoPage.UserData.rank or {}
	return rank and rank.fans or 0 
end

function UserInfoPage.GetSchoolInfo()
	if UserInfoPage.UserData and UserInfoPage.UserData.school then
		return UserInfoPage.UserData.school 
	end
end

function UserInfoPage.GetSchoolName()
	local school = UserInfoPage.GetSchoolInfo()
	return school and school.name or ""
end

function UserInfoPage.GetClassInfo()
	if UserInfoPage.UserData and UserInfoPage.UserData.class then
		return UserInfoPage.UserData.class 
	end
end

function UserInfoPage.GetClassName()
	local UserClassChange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserClassChange.lua");
	local class = UserInfoPage.GetClassInfo()
	if class then
		local gradeTxt = UserClassChange.GetGradeValue(class.grade)
		local enrollmentYear = class.enrollmentYear or 2021
		local classNum = class.classNo or 1
		return enrollmentYear.."级"..gradeTxt..classNum.."班"
	end
	return ""
end

function UserInfoPage.GetRegionInfo()
	if UserInfoPage.UserData and UserInfoPage.UserData.region then
		return UserInfoPage.UserData.region 
	end
end

function UserInfoPage.GetRegisterTimeStr()
	if UserInfoPage.UserData then
		local dateTime = UserInfoPage.UserData.createdAt or ""
		local year, month, day = commonlib.timehelp.GetYearMonthDayFromStr(dateTime);
        local registerAt = tostring(year) .. "." .. tostring(month) .. "." .. tostring(day); 
		return registerAt
	end
end

function UserInfoPage.IsVip()
	if System.options.isHideVip then 
        return false
    end
	return UserInfoPage.UserData and UserInfoPage.UserData.vip == 1
end

function UserInfoPage.IsVipTeacher()
	if System.options.isHideVip then 
        return false
    end
	return UserInfoPage.UserData and UserInfoPage.UserData.tLevel == 1
end

function UserInfoPage.IsRealName()
	return UserInfoPage.UserData and UserInfoPage.UserData.isRealname == true or UserInfoPage.UserData.isRealname == "true"
end

function UserInfoPage.GetRealNameCellPhone()
	if not SystemUserData then
		return "未绑定"
	end
	if SystemUserData.cellphone and SystemUserData.cellphone ~= "" then
		return SystemUserData.cellphone
	end
	if SystemUserData.realname and SystemUserData.realname ~= "" and string.match(SystemUserData.realname,"[1][3,4,5,7,8]%d%d%d%d%d%d%d%d%d") == SystemUserData.realname then
		return SystemUserData.realname
	end
	return "未绑定"
end

function UserInfoPage.LoginOutByErrToken(err)
    local err = err or 0
    local str = "请求数据失败，错误码是"..err
    if err == 401 then
        str = str .. "，请退出重新登陆"
    elseif err == 0 then
        str = "你的网络质量差"
    end
    GameLogic.AddBBS(nil,str)
    commonlib.TimerManager.SetTimeout(function()
        if err and err == 401 then
            GameLogic.GetFilters():apply_filters('logout', nil, function()
                GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true);
                local is_enter_world = GameLogic.GetFilters():apply_filters('store_get', 'world/isEnterWorld');
                if (is_enter_world) then
                    local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop")
                    local platform = System.os.GetPlatform()
        
                    if platform == 'win32' or platform == 'mac' then
                        Desktop.ForceExit(false)
                    elseif platform ~= 'win32' then
                        Desktop.ForceExit(true)
                    end
                else
                    MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
                end
            end);            
        end
    end, 2000)
end

function UserInfoPage.OnClickEditInfo(name)
	local name = name or ""
	if name == "class" then
		local classInfo = (UserInfoPage.UserData and UserInfoPage.UserData.class) and UserInfoPage.UserData.class or nil
		local UserClassChange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserClassChange.lua");
		UserClassChange.ShowPage(classInfo,function(gradeValue,classNum,enrollmentYear)
			local gradeValue = tonumber(gradeValue);
			local classNum = tonumber(classNum) or 1
			local enrollmentYear = tonumber(enrollmentYear)
			local classdata = {
				grade = gradeValue,
				classNo = classNum,
				enrollmentYear = enrollmentYear,
			};
			keepwork.user.set_class(classdata,function (err,msg,data)
				if err == 200 then
					if UserInfoPage.UserData then
						UserInfoPage.UserData.class = classdata
					end
					UserInfoPage.RefreshPage()
				else
					UserInfoPage.LoginOutByErrToken(err)
				end
			end);
		end);
	end
	if name == "school" then
		GameLogic.GetFilters():apply_filters('cellar.my_school.select_school', function ()
            KeepWorkItemManager.LoadProfile(false, function()
                local profile = KeepWorkItemManager.GetProfile();
				if UserInfoPage.UserData then
					UserInfoPage.UserData.school = profile.school;
					UserInfoPage.RefreshPage()
				end
            end)
        end);
	end
end

function UserInfoPage.OnClickEditNickName()
	if page then
		local ctlEdit = ParaUI.GetUIObject("UserInfo.nickNameEdit")
		local ctlUserInfo = ParaUI.GetUIObject("UserInfo.nickName")
		if ctlEdit and ctlUserInfo then
			ctlEdit.visible = true
			ctlUserInfo.visible = false
		end
	end
end

function UserInfoPage.FinishEdit()
	if page then
		local name = page:GetValue("nick_name_edit");
		if (name == nil or name == "") then
			return;
		end
		if (commonlib.utf8.len(name) > 16) then
			_guihelper.MessageBox(L"输入的昵称太长，请控制在16个字以内");
			return;
		end

		if BadWordFilter.HasBadWorld(name) then
			_guihelper.MessageBox(L"包含敏感词，请重新修改");
			return 
		end

		
		local nickName = (UserInfoPage.UserData.nickname and UserInfoPage.UserData.nickname ~= "") and UserInfoPage.UserData.nickname or UserInfoPage.GetUserName()
		if nickName == name then
			UserInfoPage.CancelEdit()
			return 
		end
		if not UserInfoPage.isChangeNickName then
			UserInfoPage.UpdateNickName(name)
		else
			_guihelper.MessageBox(L"修改昵称将消耗 10 个知识豆, 请确认是否修改", function(res)
				if(res == _guihelper.DialogResult.OK) then
					local myBean = UserInfoPage.GetBeanNum()
					if myBean < 10 then
						_guihelper.MessageBox(L"知识豆不足，修改昵称失败");
						UserInfoPage.CancelEdit()
					else
						UserInfoPage.UpdateNickName(name)
					end
				end
			end, _guihelper.MessageBoxButtons.OKCancel_CustomLabel_Highlight_Right,nil,nil,nil,nil,{ ok = L"修改", cancel = L"取消", });
		end
	end
end

function UserInfoPage.UpdateNickName(nickName)
	keepwork.user.setinfo({
        router_params = {id = SystemUserID},
        nickname = nickName,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then 
            _guihelper.MessageBox(L"修改昵称失败");
			UserInfoPage.CancelEdit()
			return
        end
		KeepWorkItemManager.LoadItems(nil, function()
			if (UserInfoPage.isChangeNickName) then
				_guihelper.MessageBox("昵称修改成功, 知识豆扣除 10 个");
			else
				_guihelper.MessageBox("昵称修改成功");
				UserInfoPage.isChangeNickName = true;
			end
			UserInfoPage.CancelEdit()
			if UserInfoPage.UserData then
				UserInfoPage.UserData.nickname = nickName
			end
			GameLogic.GetFilters():apply_filters("ggs", {action = "UpdateNickName", nickname = nickName});
			GameLogic.GetFilters():apply_filters("ggs", {action = "UpdateUserInfo", userinfo = {nickname = nickName}});
			UserInfoPage.RefreshPage()
		end)
    end);
end

function UserInfoPage.CancelEdit()
	if page then
		local ctlEdit = ParaUI.GetUIObject("UserInfo.nickNameEdit")
		local ctlUserInfo = ParaUI.GetUIObject("UserInfo.nickName")
		if ctlEdit and ctlUserInfo then
			ctlEdit.visible = false
			ctlUserInfo.visible = true
		end
	end
end

function UserInfoPage.OnClickFollow()
	if not UserInfoPage.UserData then
		return 
	end
	keepwork.user.follow({
        objectType = 0,
        objectId = UserInfoPage.UserData.id,
    }, function(status, msg, data)
		if status == 200 then
			UserInfoPage.IsFollow = true
			UserInfoPage.CheckIsFriend(function()
				UserInfoPage.UpdateFriendType()
				UserInfoPage.RefreshPage()
			end)
		end
    end);
end

function UserInfoPage.OnClickCancelFollow()
	if not UserInfoPage.UserData then
		return 
	end
	keepwork.user.unfollow({
        objectType = 0,
        objectId = UserInfoPage.UserData.id,
    }, function(status, msg, data)
		if status == 200 then
			UserInfoPage.IsFollow = false
			UserInfoPage.IsFriend = false
			UserInfoPage.isExpland_Follow = false
			UserInfoPage.UpdateFriendType()
			UserInfoPage.RefreshPage()
		end
    end);
end

function UserInfoPage.OnClickChat()
	local FriendChatPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendChatPage.lua");
	FriendChatPage.Show(SystemUserData, UserInfoPage.UserData,nil,true);
	UserInfoPage.ClosePage()
end

local function GetItemIcon(item, suffix)
    local icon = item.icon;
    if(not icon or icon == "" or icon == "0") then icon = string.format("Texture/Aries/Creator/keepwork/items/item_%d%s_32bits.png", item.gsId, suffix or "") end
    return icon;
end

function UserInfoPage.OnChangeCategory(name)
	if name and name ~= "" and name ~= UserInfoPage.category_name then
		UserInfoPage.skin_category_index = -1
		UserInfoPage.category_name = name
		if UserInfoPage.category_name == "security" then
			keepwork.user.authUsers({},function (err,msg,data)
				if err == 200 then
					UserInfoPage.authUsers = data
				else
					UserInfoPage.LoginOutByErrToken(err)
				end
				UserInfoPage.RefreshPage()
			end)
		elseif UserInfoPage.category_name == "honor" then
			if not UserInfoPage.UserData then
				UserInfoPage.RefreshPage()
				return 
			end
			keepwork.user.honors({
				userId = UserInfoPage.UserData.id
			},function (err,msg,data)
				if err == 200 then
					if data  then
						UserInfoPage.CurHonor_DS = UserInfoPage.GetHonorData(data.rows)
					end
				else
					UserInfoPage.LoginOutByErrToken(err)
				end
				UserInfoPage.RefreshPage()
			end)
		elseif UserInfoPage.category_name == "works" then
			if not UserInfoPage.UserData then
				UserInfoPage.RefreshPage()
				return 
			end
			keepwork.project.list({
				userId = UserInfoPage.UserData.id,
				type = 1,
				["x-page"] = 1,                  -- 页数
				["x-per-page"] = 1000,          -- 页大小
				["x-order"] = "updatedAt-desc",     -- 按更新时间降序
			},function (err,msg,data)
				if err == 200  then
					UserInfoPage.GetProjectData(data)
				else
					UserInfoPage.LoginOutByErrToken(err)
				end
			end)
		elseif UserInfoPage.category_name == "skin" then
			local category_index = 1
			UserInfoPage.OnChangeSkinCategory(category_index,true)
		elseif UserInfoPage.category_name == "bags" then
			KeepWorkItemManager.LoadItems(nil, function()
				UserInfoPage.CurBagItem_DS = UserInfoPage.GetItemData()
				UserInfoPage.RefreshPage()
			end)
		else
			UserInfoPage.RefreshPage()
		end
	end
end

function UserInfoPage.GetProjectData(projectDts)
	local projectDatas, projectIds= {},{}
	local projectDts = projectDts or {}
	-- echo(projectDts,true)
	local projectNum = #projectDts
	if projectNum > 0 then
		for i=1,#projectDts do
			projectIds[#projectIds + 1] = projectDts[i].id
			local data = {}
			data.projectId = projectDts[i].id --世界Id
			data.favoriteNum = projectDts[i].favorite
			data.starNum = projectDts[i].star --点赞
			data.visitNum = projectDts[i].visit --访问
			data.visibility = projectDts[i].visibility  --是否可以访问
			data.worldName = projectDts[i].name and projectDts[i].name or ""--世界名
			if data.worldName == "" then
				data.worldName = projectDts[i].extra and projectDts[i].extra.worldTagName or ""
			end
			data.imageUrl = projectDts[i].extra and projectDts[i].extra.imageUrl or "https://keepwork.com/public/img/project_default_cover_new.af774e7d.png" --世界icon
			data.userInfo = projectDts[i].user and projectDts[i].user or {}
			data.isVip = (data.userInfo and data.userInfo.vip) and data.userInfo.vip or 0
			data.isVipTeacher = (data.userInfo and data.userInfo.tLevel) and data.userInfo.tLevel or 0
			data.headUrl =  (data.userInfo and data.userInfo.portrait) and data.userInfo.portrait or ""
			data.userName = (data.userInfo and data.userInfo.username) and data.userInfo.username or ""
			data.size = (projectDts[i].tag and projectDts[i].tag.size) and (math.floor(tonumber(projectDts[i].tag.size)/2^20 * 100)/100).."M" or ""
			data.updatedAt = projectDts[i].updatedAt and projectDts[i].updatedAt or "" --更新时间
			data.createdAt = projectDts[i].createdAt and projectDts[i].createdAt or "" --创建时间
			data.comment = projectDts[i].comment and projectDts[i].comment or 0 --评论
			data.rate = projectDts[i].rate and math.floor(projectDts[i].rate * 10)/10 or 0 --评分
			data.userId = (data.userInfo and data.userInfo.userId) and data.userInfo.userId or 0
			data.isFavorite = false --是否收藏
			projectDatas[#projectDatas + 1] = data
		end
		if SystemUserID and SystemUserID > 0 then
			keepwork.project.favorite_search({
				objectType = 5,
				objectId = {
					["$in"] = projectIds,
				}, 
				userId = SystemUserID,
			},function(err,msg,data)
				-- echo(data,true)
				-- echo(err)
				if err == 200 then
					if data and data.count and data.count > 0 then
						local temp = {}
						for i=1,#data.rows do
							local id = data.rows[i].objectId
							temp[id] = true
						end
						for i=1,projectNum do
							if temp[projectDatas[i].projectId] then
								projectDatas[i].isFavorite = true
							end
						end
					end
				else
					UserInfoPage.LoginOutByErrToken(err)
				end
				UserInfoPage.CurProject_DS = projectDatas
				-- echo(UserInfoPage.CurProject_DS,true)
				UserInfoPage.RefreshPage()
			end)
		else
			UserInfoPage.RefreshPage()
		end
	else
		UserInfoPage.RefreshPage()
	end
end

function UserInfoPage.OnClickGotoWorld(data)
	local worldId = data.projectId
	if worldId and worldId > 0 then
		UserInfoPage.ClosePage()
		GameLogic.RunCommand(string.format("/loadworld -s -auto %d", worldId)); 
	end
	 
end

function UserInfoPage.OnClickBack(name)
	local index = tonumber(name)
	if index and index > 0 then
		UserInfoPage.select_project_index = index
		UserInfoPage.RefreshPage()
	end
end

function UserInfoPage.OnClickShareWorld(data)
	local worldId = data.projectId
	if worldId and worldId > 0 then
		local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")
    	ShareWorld:ShowWorldCode(worldId)
	end
	UserInfoPage.select_project_index = UserInfoPage.GetSelectProjectIndex(data)
	UserInfoPage.RefreshPage()
end

function UserInfoPage.OnClickFavoriteWorld(bFavorite,projectId)
	if not projectId or projectId ==0 then
		return 
	end
	for i,v in ipairs(UserInfoPage.CurProject_DS) do
		if projectId and projectId == UserInfoPage.CurProject_DS[i].projectId then
			UserInfoPage.CurProject_DS[i].isFavorite = bFavorite
			break
		end
	end
	UserInfoPage.select_project_index = UserInfoPage.GetSelectProjectIndex(projectId)
	UserInfoPage.RefreshPage()
	if bFavorite then
		keepwork.world.favorite({objectType = 5, objectId = projectId}, function(status)
			if (status < 200 or status >= 300) then
				print("无法收藏");
			end
		end);
	else
		keepwork.world.unfavorite({objectType = 5, objectId = projectId}, function(status)
			if (status < 200 or status >= 300) then
				print("无法取消收藏");
			end
		end);
	end
end

function UserInfoPage.GetSelectProjectIndex(params)
	local projectId
	if type(params) == "number" then
		projectId = params
	end
	if type(params) == "table" then
		projectId = params.projectId
	end
	for i,v in ipairs(UserInfoPage.CurProject_DS) do
		if projectId and projectId == UserInfoPage.CurProject_DS[i].projectId then
			return i
		end
	end
	return 1
end

function UserInfoPage.GetHonorData(rows)
	local honors,honor_map = {},{}
	if rows and #rows > 0 then
		for k,item in pairs(rows) do
			local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
			if (itemTpl) then
				local extra = itemTpl.extra or {};
				table.insert(honors, {
					gsId = item.gsId,
					icon = GetItemIcon(itemTpl),
					name = itemTpl.name,
					desc = itemTpl.desc,
					createdAt = item.createdAt,
					certurl = extra.picture,
					description = extra.description,
					worldId = extra.worldId,
					has = true,
				});
				honor_map[item.gsId] = true
			end
		end
	end
	if UserInfoPage.IsAuthUser() then
		for _, itemTpl in ipairs(KeepWorkItemManager.globalstore) do
			if (not honor_map[itemTpl.gsId] and itemTpl.bagNo == 1006) then
				local extra = itemTpl.extra or {};
				table.insert(honors, {
					gsId = itemTpl.gsId,
					icon = GetItemIcon(itemTpl, "_gray"),
					name = itemTpl.name,
					desc = itemTpl.desc,
					-- createdAt = item.createdAt,
					certurl = extra.picture,
					description = extra.description,
					worldId = extra.worldId,
					has = false,
				});
			end
		end
	end
	-- echo(honors,true)
	return honors
end

function UserInfoPage.OnClickHonor(data)
	-- echo(data,true)
	if (not data.certurl or data.certurl == "") then return end;
    if (not data.has) then return end 
    
    local username = UserInfoPage.UserData.username;
    if (UserInfoPage.UserData.nickname and UserInfoPage.UserData.nickname ~= "") then 
		username = UserInfoPage.UserData.nickname 
	end
	data.username = username
	local HonorPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/HonorPage.lua");
	HonorPage.ShowPage(data);
end

function UserInfoPage.GetBindInfo(type)
	if UserInfoPage.authUsers then
		for k,v in pairs(UserInfoPage.authUsers) do
			if type and v.type == type then 
				return v
			end
		end
	end
end

function UserInfoPage.IsWeixinBind()
	return UserInfoPage.GetBindInfo(1) ~= nil
end

function UserInfoPage.GetWeixinName()
	local bindInfo = UserInfoPage.GetBindInfo(1)
	return bindInfo and bindInfo.externalUsername or ""
end

function UserInfoPage.IsQQBind()
	return UserInfoPage.GetBindInfo(0) ~= nil
end

function UserInfoPage.GetQQName()
	local bindInfo = UserInfoPage.GetBindInfo(0)
	return bindInfo and bindInfo.externalUsername or ""
end

function UserInfoPage.IsGithubBind()
	return UserInfoPage.GetBindInfo(2) ~= nil
end

function UserInfoPage.GetGithubName()
	local bindInfo = UserInfoPage.GetBindInfo(2)
	return bindInfo and bindInfo.externalUsername or ""
end

function UserInfoPage.IsWeiboBind()
	return UserInfoPage.GetBindInfo(3) ~= nil
end

function UserInfoPage.GetWeiboName()
	local bindInfo = UserInfoPage.GetBindInfo(3)
	return bindInfo and bindInfo.externalUsername or ""
end

function UserInfoPage.IsMobilePhoneBind()
	return SystemUserData and SystemUserData.cellphone and SystemUserData.cellphone ~= ""
end

function UserInfoPage.GetMobilePhoneName()
	return SystemUserData.cellphone
end

function UserInfoPage.IsEmailBind()
	return SystemUserData and SystemUserData.email and SystemUserData.email ~= ""
end

function UserInfoPage.GetEmailName()
	return SystemUserData.email
end

function UserInfoPage.OnClickGotoBind()
	local token = commonlib.getfield("System.User.keepworktoken")
	local urlbase = GameLogic.GetFilters():apply_filters("get_keepwork_url");
	local method = '/u/p/thirdPartyAccountBinding'
	local url = string.format('%s/p?url=%s&token=%s',urlbase,Mod.WorldShare.Utils.EncodeURIComponent(method),token) 
	GameLogic.RunCommand("/open "..url)
end

function UserInfoPage.GetBindInfoData()
	local temp = {}
	--微信

	if UserInfoPage.IsWeixinBind() then
		temp[#temp + 1] = {key="微信:" , name = UserInfoPage.GetWeixinName(),isBind = true ,buttonValue = "解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="微信:" , name = "未绑定",isBind = false ,buttonValue="绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsWeiboBind() then
		temp[#temp + 1] = {key="微博:" , name = UserInfoPage.GetWeiboName(),isBind = true ,buttonValue = "解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="微博:" , name = "未绑定",isBind = false ,buttonValue="绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsQQBind() then
		temp[#temp + 1] = {key="QQ:" , name = UserInfoPage.GetQQName(),isBind = true ,buttonValue = "解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="QQ:" , name = "未绑定",isBind = false ,buttonValue="绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsGithubBind() then
		temp[#temp + 1] = {key="GitHub:" , name = UserInfoPage.GetGithubName(),isBind = true ,buttonValue = "解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="GitHub:" ,name = "未绑定", isBind = false ,buttonValue="绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsEmailBind() then
		temp[#temp + 1] = {key="邮箱:" , name = UserInfoPage.GetEmailName(),isBind = true ,buttonValue = "解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="邮箱:" ,name = "未绑定", isBind = false ,buttonValue="绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsMobilePhoneBind() then
		temp[#temp + 1] = {key="手机:" , name = UserInfoPage.GetMobilePhoneName(),isBind = true ,buttonValue = "解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="手机:" ,name = "未绑定", isBind = false ,buttonValue="绑定" ,buttonName="2"}
	end
	return temp
end

function UserInfoPage.RemoveAccount()
	local Page = NPL.load("script/ide/System/UI/Page.lua");
	Page.Show({
		OnFinish = function()
			
		end,
	}, {
		url = "%vue%/Page/User/CloseAccount.html",
		draggable = false,
	});
end

function UserInfoPage.CloseLoginPage()
	local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')
	if MainLoginLoginPage then
		MainLoginLoginPage:CloseWindow()
	end
end

function UserInfoPage.UpdatePassworld()
	local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
    local RedSummerCampSchoolMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampSchoolMainPage.lua");
	UserInfoPage.ClosePage()
	MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
	--切换到修改密码
	commonlib.TimerManager.SetTimeout(function()
		local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
		if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
			_guihelper.MessageBox(L'*修改密码前请先完成实名认证。', function()
				local Certificate = NPL.load('(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua')
				Certificate:ShowMyHomePage(function(result)
					if GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
						MainLogin:UpdatePasswordRemindVisible(false)
						UserInfoPage.CloseLoginPage()
						MainLogin:ShowUpdatePassword()
					end
				end)
			end)
			return
		end

		MainLogin:UpdatePasswordRemindVisible(false)
		UserInfoPage.CloseLoginPage()
		MainLogin:ShowUpdatePassword()
		RedSummerCampSchoolMainPage.Close()
		RedSummerCampMainPage.Close()
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
		local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
		local Game = commonlib.gettable("MyCompany.Aries.Game")
		if(Game.is_started) then
			Game.Exit()
			Desktop.is_exiting = true
		end
		
	end,100)
end

function UserInfoPage.CanFill(item)
    if(not item)then
        return
    end
    local copies = item.copies or 0;
    if(copies <= 0)then
        return
    end
    if(item.bagId == 4)then
		return true       
	end
end

function UserInfoPage.GetItemData()
	local items = KeepWorkItemManager.items or {};
    local result = {};
    for k,item in ipairs(items) do
        if(UserInfoPage.CanFill(item))then
			local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (itemTpl) then
                table.insert(result, {
                    icon = GetItemIcon(itemTpl),
                    copies = item.copies,
                    name = itemTpl.name,
                    desc = itemTpl.desc,
					goodId = item.gsId
                });
			end
        end
    end
    return result;
end

-- playerinfo
function UserInfoPage.UpdatePlayerEntityInfo()
	if not UserInfoPage.IsAuthUser() then
		return
	end
	local playerEntity = GameLogic.GetPlayerController():GetPlayer();

	if playerEntity then
		playerEntity:SetMainAssetPath(UserInfoPage.mainAssets);
		playerEntity:SetSkin(UserInfoPage.mainSkin); 
		playerEntity:SetScaling(UserInfoPage.userScale)
	end

	GameLogic.options:SetMainPlayerAssetName(UserInfoPage.mainAssets);
	GameLogic.options:SetMainPlayerSkins(UserInfoPage.mainSkin);
	GameLogic.GetFilters():apply_filters("user_skin_change", UserInfoPage.mainSkin);
	local asset = MyCompany.Aries.Game.PlayerController:GetMainAssetPath()
    local skin = MyCompany.Aries.Game.PlayerController:GetSkinTexture()
	if not UserInfoPage.UserData then
		return 
	end
    local extra = UserInfoPage.UserData.extra and UserInfoPage.UserData.extra or {};
    extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
    extra.ParacraftPlayerEntityInfo.asset = asset;
    extra.ParacraftPlayerEntityInfo.skin = skin;
    extra.ParacraftPlayerEntityInfo.assetSkinGoodsItemId = 0;
	if page then
		local scaleValue = tonumber(page:GetValue("Role_Scaling"));
		extra.ParacraftPlayerEntityInfo.scale = scaleValue or UserInfoPage.userScale
	end
    keepwork.user.setinfo({
        router_params = {id = SystemUserID},
        extra = extra,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then return echo("更新玩家实体信息失败") end
        local userinfo = KeepWorkItemManager.GetProfile();
        userinfo.extra = extra;
    end);
end


local getItemIconBySkin = function(skin)
	local items = CustomCharItems:GetUsedItemsBySkin(skin);
	for _, item in ipairs(items) do
		local index = CustomSkinPage.GetIconIndexFromName(item.name);
		if (index > 0) then
			UserInfoPage.Current_Icon_DS[index].id = item.id;
			UserInfoPage.Current_Icon_DS[index].name = item.name;
			UserInfoPage.Current_Icon_DS[index].icon = item.icon;
		end
	end
end

function UserInfoPage.GetToolTipBySkinId(skinId)
	local data = CustomCharItems:GetItemById(skinId);
	if not data then
		return ""
	end
	return data.name or ""
end

function UserInfoPage.GetSkinIconByUserData()
	if UserInfoPage.UserData then
		local ParacraftPlayerEntityInfo = UserInfoPage.UserData.extra and UserInfoPage.UserData.extra.ParacraftPlayerEntityInfo or {};
		local skin = CustomCharItems:GetSkinByAsset(ParacraftPlayerEntityInfo.asset) 
		if (ParacraftPlayerEntityInfo.asset) then 
			UserInfoPage.mainAssets = ParacraftPlayerEntityInfo.asset
        end 
        if (ParacraftPlayerEntityInfo.skin) then 
			UserInfoPage.mainSkin = ParacraftPlayerEntityInfo.skin
        end 
		if UserInfoPage.mainAssets ~= CustomCharItems.defaultModelFile then
			UserInfoPage.mainAssets = CustomCharItems.defaultModelFile
			UserInfoPage.mainSkin = (skin and skin ~= "") and skin or "" 
		end
		if (ParacraftPlayerEntityInfo.asset == CustomCharItems.defaultModelFile) then
			if not CustomCharItems:CheckAvatarExist(ParacraftPlayerEntityInfo.skin) then
				getItemIconBySkin(ParacraftPlayerEntityInfo.skin)
			end
	    else
			local skin = CustomCharItems:GetSkinByAsset(ParacraftPlayerEntityInfo.asset) 
			if skin and skin ~= "" then
				getItemIconBySkin(skin)
			end
        end
	end
end

function UserInfoPage.OnChangeSkinCategory(index,bChangeMenu)
	if index and index > 0 and UserInfoPage.skin_category_index ~= index then
		UserInfoPage.skin_category_index = index or UserInfoPage.skin_category_index;
		local category = UserInfoPage.skin_category_ds[UserInfoPage.skin_category_index];
		if (category) then
			UserInfoPage.Current_SkinItem_DS = CustomCharItems:GetModelItems(UserInfoPage.mainAssets, category.name, UserInfoPage.mainSkin or "",true) or {};
		end
		UserInfoPage.UpdateItemData()
		-- print("llllllllllllllllllllll",bChangeMenu)
		-- echo(UserInfoPage.Current_SkinItem_DS,true)
		UserInfoPage.RefreshPage();
	end
end

function UserInfoPage.GetAllItemData()
	local category = UserInfoPage.skin_category_ds[UserInfoPage.skin_category_index];
	if (category) then
		UserInfoPage.Current_SkinItem_DS = CustomCharItems:GetModelItems(UserInfoPage.mainAssets, category.name, UserInfoPage.mainSkin or "",true) or {};
	end
end

function UserInfoPage.UpdateSkinGView(data)
	if data then
		page:CallMethod("gvSkinGridView","SetDataSource", data);
		page:CallMethod("gvSkinGridView","DataBind");
	end
end
local isFreeList
function UserInfoPage.IsFreeSkin(skinId)
	if not isFreeList then
		isFreeList = {}
		for k,v in pairs(freeSkinIds) do
			isFreeList[v] = true
		end
	end
	local index = tonumber(skinId)
	if index and index > 0 then
		return isFreeList[index]
	end
end

function UserInfoPage.UpdateItemData() --下架了套装，需要处理散件数据
	for i,v in ipairs(UserInfoPage.Current_SkinItem_DS) do
		if UserInfoPage.IsFreeSkin(v.id) then
			v.type = SKIN_ITEM_TYPE.FREE
		end
		if v.gsid and v.gsid ~= "" then
			v.type = SKIN_ITEM_TYPE.ACTIVITY_GOOD
		end
		if v.type == SKIN_ITEM_TYPE.SUIT_PART then
			v.type = SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE
		end
	end
	--去掉异常数据
	local temp = {}
	for i,v in ipairs(UserInfoPage.Current_SkinItem_DS) do
		if v.type == SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE and v.price and v.price ~= "" then
			temp[#temp + 1] = v
		end
		if v.type ~= SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE then
			temp[#temp + 1] = v
		end
	end
	if System.options.isHideVip then
		temp = commonlib.filter(temp,function (item)
			return item.type ~= SKIN_ITEM_TYPE.VIP
		end)
	end

	--是否选中只显示已拥有
	if UserInfoPage.isOnlyShowHave then
		local data = {}
		for i,v in ipairs(UserInfoPage.Current_SkinItem_DS) do
			if UserInfoPage.CheckSkinIsValid(v.id) then
				data[#data + 1] = v
			end
		end
		UserInfoPage.Current_SkinItem_DS = data
		return
	end

	UserInfoPage.Current_SkinItem_DS = temp
end

function UserInfoPage.GetActivityName(gsid)
    local template = KeepWorkItemManager.GetItemTemplate(gsid);
    if (template and template.desc) then
        return template.desc;
    end
end

function UserInfoPage.UpdateCustomGeosets(name)
	local index = tonumber(name)
	if index and index > 0 then
		local item = UserInfoPage.Current_SkinItem_DS[index];
		local ui_index = UserInfoPage.skin_category_ds[UserInfoPage.skin_category_index].ui_index;
		if (UserInfoPage.Current_Icon_DS[ui_index].id == item.id) then
			return;
		end

		UserInfoPage.mainSkin = CustomCharItems:AddItemToSkin(UserInfoPage.mainSkin, item);

		UserInfoPage.Current_Icon_DS[ui_index].id = item.id;
		UserInfoPage.Current_Icon_DS[ui_index].name= item.name;
		UserInfoPage.Current_Icon_DS[ui_index].icon = item.icon;
		UserInfoPage.RefreshPage();
	end
end

function UserInfoPage.CheckHasUpdateNickName()
	local GOODS_UPDATE_NICKNAME_ID = 30270 -- 是否更新过nickname
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(GOODS_UPDATE_NICKNAME_ID)
	return bHas or (copies and copies > 0)
end

function UserInfoPage.GetBeanNum()
	local BEAN_GSID = 998;
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(BEAN_GSID)
	return copies or 0;
end


function UserInfoPage.Purchase(skinId)
	local skinData = CustomCharItems:GetItemById(skinId);
	if not skinData or skinData.type ~= SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE then
		return 
	end
	-- echo(skinData,true)
	local myBean = UserInfoPage.GetBeanNum()
	local totalPrice = tonumber(skinData.price) or 0;
	if(myBean < totalPrice) then
		local UserExchangeSkinResult = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserExchangeSkinResult.lua");
		UserExchangeSkinResult.ShowFailPage()
		return;
	end

	-- local clothes = {}
	-- clothes[#clothes + 1] = {
	-- 	category = skinData.category,
	-- 	itemId = skinData.id,
	-- 	price = skinData.price
	-- }
	keepwork.user.buySingleSkinUseBean({
		clothe = {category = skinData.category, itemId = skinData.id, price = skinData.price},
		totalPrice = totalPrice
	},	function(code, msg, data)
		LOG.std(nil, 'info', 'code', code);
		-- echo(data,true)
		-- 购买成功 更新皮肤
		if code == 200 then
			-- refresh user goods
			local UserExchangeSkinResult = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserExchangeSkinResult.lua");
			UserExchangeSkinResult.ShowPage(skinData.name)
			KeepWorkItemManager.LoadItems(nil, function()
				UserInfoPage.GetClothesOfServerData(true)
				UserInfoPage.UpdateSkinGView(UserInfoPage.Current_SkinItem_DS)
			end)
		else
			UserInfoPage.LoginOutByErrToken(code)
		end
	end)
end

--- @return table: 获取需要知识豆购买类型的skin
local ONLY_BEANS_CAN_PURCHASE_GSID = 40009 --17
function UserInfoPage.GetClothesOfServerData(bRefresh)
	if not UserInfoPage.buyClothesData or bRefresh then
		local bOwn, id, bagId, copies, item = KeepWorkItemManager.HasGSItem(ONLY_BEANS_CAN_PURCHASE_GSID);
		if(item and item.serverData) then
			local clothes = UserInfoPage.UpdateClotheData(item.serverData.clothes)
			UserInfoPage.buyClothesData = clothes
			--echo(UserInfoPage.buyClothesData,true)
			return clothes
		end
	end
	return UserInfoPage.buyClothesData;
end

function UserInfoPage.ChangePlayerSkinWhenClose()
	if not UserInfoPage.IsAuthUser() then
		return 
	end
	if UserInfoPage.mainSkin and UserInfoPage.mainSkin ~= "" then
		UserInfoPage.mainSkin = UserInfoPage.RemoveAllUnvalidItems(UserInfoPage.mainSkin)
	end
	UserInfoPage.UpdatePlayerEntityInfo()
end

function UserInfoPage.RemoveSkin(name)
	local index = tonumber(name)
	if not index or index <= 0 or not UserInfoPage.IsAuthUser() then
		return 
	end
	local iconItem = UserInfoPage.Current_Icon_DS[index];
	local length = string.len(UserInfoPage.mainSkin)
	if (iconItem and iconItem.id and iconItem.id ~= "") then
		if UserInfoPage.mainSkin ~= "" and string.sub(UserInfoPage.mainSkin,length) ~= ";"then
			local curSkin = ""
			local skinTbl = commonlib.split(UserInfoPage.mainSkin,";")
			if skinTbl then
				for k,v in pairs(skinTbl) do
					curSkin = curSkin..v..";"
				end
			end
			if curSkin ~= "" then
				UserInfoPage.mainSkin = curSkin
			end
		end
		local skin = CustomCharItems:RemoveItemInSkin(UserInfoPage.mainSkin, iconItem.id);
		if (UserInfoPage.mainSkin ~= skin) then
			UserInfoPage.mainSkin = skin;
			iconItem.id = "";
			iconItem.name = "";
			iconItem.icon = "";
			UserInfoPage.RefreshPage()
		end
	end
end

function UserInfoPage.RemoveAllUnvalidItems(skin)
	local currentSkin = skin;
	local itemIds = commonlib.split(skin, ";");
	if (itemIds and #itemIds > 0) then
		for _, id in ipairs(itemIds) do
			local data = CustomCharItems:GetItemById(id);
			if (data and not UserInfoPage.CheckSkinIsValid(id)) then
				currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
			end
		end
	end
	return currentSkin;
end

function UserInfoPage.CheckSkinIsValid(skinId)
	local clothes = UserInfoPage.GetClothesOfServerData() or {};
	local data = CustomCharItems:GetItemById(skinId);
	if (data) then
		-- 活动商品
		if(data.type == SKIN_ITEM_TYPE.ACTIVITY_GOOD) then
			if(not KeepWorkItemManager.HasGSItem(data.gsid)) then
				return false
			end;
		end;
		-- VIP可用
		if(data.type == SKIN_ITEM_TYPE.VIP and not KeepWorkItemManager.IsVip()) then
			return false
		end;
		-- 知识豆可购买类型
		if(data.type == SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
			if KeepWorkItemManager.IsVip() then
				return true
			end
			-- 用户是否拥有该皮肤
			local serverDataSkin = commonlib.find(clothes, function (item)
				return item.itemId == tonumber(skinId)
			end);
			if(not serverDataSkin) then
				return false
			end;
		end;
	end
	return true
end

function UserInfoPage.GetDataIndex(data)
	for i,v in ipairs(UserInfoPage.Current_SkinItem_DS) do
		if tonumber(v.id) == tonumber(data.id) then
			return i
		end
	end
end

function UserInfoPage.GetDataIndexByName(name)
	for i,v in ipairs(UserInfoPage.Current_SkinItem_DS) do
		if name and name == v.name then
			return i
		end
	end
end

function UserInfoPage.GetSkinIdByName(name)
	for i,v in ipairs(UserInfoPage.Current_SkinItem_DS) do
		if name and name == v.name then
			return v.id
		end
	end
end

function UserInfoPage.OnClickExchangeSkin(data)
	if data and data.type == SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE and not UserInfoPage.CheckSkinIsValid(data.id) then
		local UserExchangeSkinPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserExchangeSkinPage.lua");
		UserExchangeSkinPage.ShowPage(data);
		return
	end
	if data and data.type == SKIN_ITEM_TYPE.VIP and not KeepWorkItemManager.IsVip() then
		local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
        VipPage.ShowPage("ChangeAvatarSkin", "尽享精彩形象");
	end
	if data and UserInfoPage.CheckSkinIsValid(data.id) then
		local index = UserInfoPage.GetDataIndex(data)
		if index and index > 0 then
			UserInfoPage.UpdateCustomGeosets(index)
		end
		return
	end
end

function UserInfoPage.UseSkinBySkinId(skinId)
	local data = CustomCharItems:GetItemById(skinId);
	if data then
		local index = UserInfoPage.GetDataIndex(data)
		if index and index > 0 then
			UserInfoPage.UpdateCustomGeosets(index)
		end
	end
end

function UserInfoPage.UseSkinBySkinName(skinName)
	local index = UserInfoPage.GetDataIndexByName(skinName)
	if index and index > 0 then
		UserInfoPage.UpdateCustomGeosets(index)
	end
end

function UserInfoPage.RemoveSkinByName(skinName)
	local skinId = UserInfoPage.GetSkinIdByName(skinName)
	if skinId and string.find(UserInfoPage.mainSkin,skinId) then
		for i,v in ipairs(UserInfoPage.Current_Icon_DS) do
			if tonumber(v.id) == tonumber(skinId) then
				v.id = "";
				v.name = "";
				v.icon = "";
				break
			end
		end
		local skin = CustomCharItems:RemoveItemInSkin(UserInfoPage.mainSkin, skinId);
		if (UserInfoPage.mainSkin ~= skin) then
			UserInfoPage.mainSkin = skin;
			UserInfoPage.RefreshPage()
		end
	end
end

function UserInfoPage.OnClickShowHased() 
	UserInfoPage.isOnlyShowHave = not UserInfoPage.isOnlyShowHave
	UserInfoPage.GetAllItemData()
	UserInfoPage.UpdateItemData()
	UserInfoPage.RefreshPage()
end

function UserInfoPage.CheckUserSkin()
	local user_skin = GameLogic.GetPlayerController():GetSkinTexture()
	-- 没皮肤的话不检查
	if not user_skin or user_skin == "" then
		return
	end

	-- 默认裸装的皮肤的话不检查
	local default_skin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString);
	if user_skin == default_skin then
		return
	end

	local newSkin = UserInfoPage.RemoveAllUnvalidItems(user_skin)
	if user_skin == newSkin then
		return
	end
	local playerEntity = GameLogic.GetPlayerController():GetPlayer();
	if playerEntity then
		playerEntity:SetSkin(user_skin); 
	end	
	GameLogic.options:SetMainPlayerSkins(user_skin);
	GameLogic.GetFilters():apply_filters("user_skin_change", user_skin);
	local asset = MyCompany.Aries.Game.PlayerController:GetMainAssetPath()
    local skin = MyCompany.Aries.Game.PlayerController:GetSkinTexture()
	local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
	local userinfo = Keepwork:GetUserInfo();
    local AuthUserId = userinfo.id;

    local extra = userinfo.extra or {};
    extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
    extra.ParacraftPlayerEntityInfo.asset = asset;
    extra.ParacraftPlayerEntityInfo.skin = skin;
    extra.ParacraftPlayerEntityInfo.assetSkinGoodsItemId = 0;
    keepwork.user.setinfo({
        router_params = {id = AuthUserId},
        extra = extra,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then return echo("更新玩家实体信息失败") end
        local userinfo = KeepWorkItemManager.GetProfile();
        userinfo.extra = extra;
    end);
end




