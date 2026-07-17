--[[
    author: pbb
    date: 2024-05-13
    description: 显示用户信息页面
    uselib:
     local CommunityUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityUserInfo.lua")
     CommunityUserInfo.ShowPage()
]]

NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/apps/Aries/Chat/BadWordFilter.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CustomSkinPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");
local Encoding = commonlib.gettable("System.Encoding");
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
local BadWordFilter = commonlib.gettable("MyCompany.Aries.Chat.BadWordFilter");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local SkinManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinManager.lua")
local CommunityTitleInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityTitleInfo.lua")
local CommunityUserInfo = NPL.export()
local SystemUserData = KeepWorkItemManager.GetProfile();
local SystemUserName = commonlib.getfield("System.User.username")
local SystemUserID = SystemUserData and SystemUserData.id or 0
local isLogin = System.User.keepworkUsername and System.User.keepworkUsername ~= ""
local player = GameLogic.GetPlayerController():GetPlayer();

--人物旁边的
CommunityUserInfo.isChangeNickName = false
CommunityUserInfo.userScale = 1
CommunityUserInfo.mainAssets = ""
CommunityUserInfo.mainSkin = ""
CommunityUserInfo.skin_category_index = -1
CommunityUserInfo.Current_SkinItem_DS = {}
CommunityUserInfo.Current_Icon_DS = {}
CommunityUserInfo.skin_category_ds = {
	{tex1 = "zi_toushi1_28X14_32bits", tex2 = "zi_toushi2_28X14_32bits", name = "hair", value=L"头饰",  ui_index = 7},
	{tex1 = "zi_yanjing2_28X14_32bits", tex2 = "zi_yanjing1_28X14_32bits", name = "eye", value=L"眼睛",  ui_index = 1},
	{tex1 = "zi_zuiba1_28X14_32bits", tex2 = "zi_zuiba2_28X14_32bits", name = "mouth", value=L"嘴巴",  ui_index = 2},
	{tex1 = "zi_yifu1_28X14_32bits", tex2 = "zi_yifu2_28X14_32bits", name = "shirt", value=L"衣服",  ui_index = 3},
	{tex1 = "zi_kuzi1_28X14_32bits", tex2 = "zi_kuzi2_28X14_32bits", name = "pants", value=L"裤子",  ui_index = 4},
	{tex1 = "zi_shouchi1_28X14_32bits", tex2 = "zi_shouchi2_28X14_32bits", name = "right_hand_equipment", value=L"手持",  ui_index = 6},
	{tex1 = "zi_beibu1_28X14_32bits", tex2 = "zi_beibu2_28X14_32bits", name = "back", value=L"背部",  ui_index = 5},
	-- {tex1 = "zi_zuoqi1_28X14_32bits", tex2 = "zi_zuoqi2_28X14_32bits", name = "pet", ui_index = 8},
};

CommunityUserInfo.MenuItem_DS = {
	{title=L"作品",ui_index = 1,text=L"作品", name="works"},
	{title=L"外观",ui_index = 2,text=L"外观", name="skin",isAuth = true},
	{title=L"荣誉",ui_index = 3,text=L"荣誉", name="honor"},
	-- {title=L"背包",ui_index = 4,text=L"背包", name="bags",isAuth = true},
	{title=L"账号",ui_index = 4,text=L"账号", name="security",isAuth = true}
}

CommunityUserInfo.CurBagItem_DS = {}
CommunityUserInfo.CurHonor_DS = {}
CommunityUserInfo.authUsers = {}
CommunityUserInfo.CurProject_DS = {}
CommunityUserInfo.category_name = ""
CommunityUserInfo.select_project_index = -1
CommunityUserInfo.UserData = nil
CommunityUserInfo.isOnlyShowHave = true
CommunityUserInfo.IsFollow = false
CommunityUserInfo.IsFriend = false
CommunityUserInfo.isExpland_Follow = false
local SKIN_ITEM_TYPE = {
	FREE = "0",
	SVIP = "1",
	ONLY_BEANS_CAN_PURCHASE = "2",
	ACTIVITY_GOOD = "3",
	VIP = "4",
	-- 套装部件
	SUIT_PART = "5"
}
CommunityUserInfo.SKIN_ITEM_TYPE = SKIN_ITEM_TYPE

local FRIEND_TYPE = {
	NORMAL = 1,
	FOLLOW = 2,
	FRIEND = 3,
}
CommunityUserInfo.FRIEND_TYPE = FRIEND_TYPE;

CommunityUserInfo.CurFriendType = FRIEND_TYPE.NORMAL
CommunityUserInfo.buyClothesData = nil
local page
function CommunityUserInfo.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = CommunityUserInfo.OnCreate
end

function CommunityUserInfo.ShowPage(username,category_name,userId)
	local category_name = category_name or "works"
	if System.options.isHideVip then
		CommunityUserInfo.MenuItem_DS = {
			{title=L"作品",ui_index = 1,text=L"作品", name="works"},
			{title=L"荣誉",ui_index = 2,text=L"荣誉", name="honor"},
			-- {title=L"背包",ui_index = 4,text=L"背包", name="bags",isAuth = true},
			{title=L"账号",ui_index = 3,text=L"账号", name="security",isAuth = true}
		}
		if category_name == "skin" or category_name == "bags" then
			category_name = "honor"
		end
	end
	CommunityUserInfo.InitData()
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
			CommunityUserInfo.UserData = data

            if CommunityUserInfo.UserData.nickname == nil or CommunityUserInfo.UserData.nickname == "" then
                CommunityUserInfo.UserData.nickname = CommunityUserInfo.UserData.username
                CommunityUserInfo.UserData.limit_nickname = CommunityUserInfo.UserData.username
            else
                CommunityUserInfo.UserData.limit_nickname = commonlib.GetLimitLabel(CommunityUserInfo.UserData.nickname, 26)
            end
            CommunityUserInfo.UserData.is_vip = CommunityUserInfo.UserData.vip == 1
            CommunityUserInfo.UserData.is_common_vip = CommunityUserInfo.UserData.commonVip == 1
            CommunityUserInfo.UserData.limit_username = CommunityUserInfo.UserData.username
			-- echo(data,true)
			-- echo(SystemUserData,true)
			CommunityUserInfo.GetSkinIconByUserData()
			if CommunityUserInfo.IsAuthUser() then
				CommunityUserInfo.ShowView(category_name)
			else
				if System.options.isPapaAdventure then
					NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAPI.lua");
					local PapaAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.PapaAPI");
					PapaAPI:SendShowHomePage(username,id)
					return
				end
				CommunityUserInfo.CheckIsFollow(function()
					CommunityUserInfo.CheckIsFriend(function()
						CommunityUserInfo.UpdateFriendType()
						CommunityUserInfo.ShowView(category_name)
					end)
				end)
			end
		else
			CommunityUserInfo.LoginOutByErrToken(err)
		end
	end)
end

function CommunityUserInfo.IsCommonVip()
	if not CommunityUserInfo.UserData or System.options.isHideVip then
		return false
	end
	return CommunityUserInfo.UserData.is_vip or CommunityUserInfo.UserData.is_common_vip
end

function CommunityUserInfo.IsSuperVip()
	if not CommunityUserInfo.UserData or System.options.isHideVip then
		return false
	end
	return CommunityUserInfo.UserData.is_vip
end

function CommunityUserInfo.IsVisible()
	return page and page:IsVisible()
end

function CommunityUserInfo.InitData()
	CommunityUserInfo.buyClothesData = nil
	CommunityUserInfo.isExpland_Follow = false
	CommunityUserInfo.IsFollow = false
	CommunityUserInfo.IsFriend = false
	CommunityUserInfo.isOnlyShowHave = true
	CommunityUserInfo.skin_category_index = -1
	CommunityUserInfo.authUsers = {}
	CommunityUserInfo.CurHonor_DS = {}
	CommunityUserInfo.CurProject_DS = {}
	CommunityUserInfo.category_name = ""
	CommunityUserInfo.UserData = nil
	CommunityUserInfo.CurFriendType = FRIEND_TYPE.NORMAL
	CommunityUserInfo.select_project_index = -1
	CommunityUserInfo.Current_Icon_DS = {};
	for i = 1, #CommunityUserInfo.skin_category_ds do
		CommunityUserInfo.Current_Icon_DS[i] = {id = "", icon = "", name = ""} 
	end
	CommunityUserInfo.mainAssets = player and player:GetMainAssetPath()
	CommunityUserInfo.mainSkin = player and player:GetSkin()
	CommunityUserInfo.CurBagItem_DS = CommunityUserInfo.GetItemData()
	SystemUserData = KeepWorkItemManager.GetProfile();
	SystemUserName = commonlib.getfield("System.User.username")
	SystemUserID = SystemUserData and SystemUserData.id or 0
	SkinManager.GenerateUnLockSkinMap()
	CommunityUserInfo.isChangeNickName = CommunityUserInfo.CheckHasUpdateNickName()
end

function CommunityUserInfo.FormatTime(datetime)
	local time_stamp = type(datetime) == "string" and commonlib.timehelp.GetTimeStampByDateTime(datetime) or datetime
	local year = os.date("%Y", time_stamp)	
	local month = os.date("%m", time_stamp)
	local day = os.date("%d", time_stamp)
	local hour = os.date("%H", time_stamp)
	local min = os.date("%M", time_stamp)
	local sec = os.date("%S", time_stamp)
	return string.format("%s-%s-%s %s:%s:%s", year,month,day,hour,min,sec);
end

function CommunityUserInfo.GetVipDeadlineStr()
	local data = CommunityUserInfo.UserData
	if data then
		if data.vip == 1 and not data.vipDeadline then
			return "永久使用"
		end
		if data.vipDeadline and data.vipDeadline ~= "" then
			return CommunityUserInfo.GetDeadlineStr(data.vipDeadline)
		end
	end
end

function CommunityUserInfo.GetPurchaseTime(skinId)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
	local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
	local clothes = CommunityUserInfo.GetClothesOfServerData() or {}
	for i,v in ipairs(clothes) do
		if skinId and tonumber(v.itemId) == tonumber(skinId) then
			local startTime =  CommunityUserInfo.FormatTime(v.startAt)
			local server_time = QuestAction.GetServerTime()
			local curDateTime = CommunityUserInfo.FormatTime(tonumber(server_time))
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

function CommunityUserInfo.GetDeadlineStr(EndTime)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
	local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
	if EndTime and EndTime ~= "" then
		local deadTime =  CommunityUserInfo.FormatTime(EndTime)
		local server_time = QuestAction.GetServerTime()
		local curDateTime = CommunityUserInfo.FormatTime(tonumber(server_time))
		local day,hours,minutes,seconds,time_str = commonlib.GetTimeStr_BetweenToDate(curDateTime, deadTime);
		if day > 365 then
			return string.format("%d年%d天",math.floor(day/365),day - math.floor(day/365) * 365)
		else
			return string.format("%d天",day)			
		end
	end
end

function CommunityUserInfo.IsInDeadLine(EndTime)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
	local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
	if EndTime and EndTime ~= "" then
		local deadTime =  CommunityUserInfo.FormatTime(EndTime)
		local server_time = QuestAction.GetServerTime()
		local curDateTime = CommunityUserInfo.FormatTime(tonumber(server_time))
		local day,hours,minutes,seconds,time_str = commonlib.GetTimeStr_BetweenToDate(curDateTime, deadTime);
		return day > 0 or hours > 0 or minutes > 0 or seconds > 0
	end
end

function CommunityUserInfo.UpdateFriendType()
	if CommunityUserInfo.IsAuthUser() then
		return
	end
	CommunityUserInfo.CurFriendType = FRIEND_TYPE.NORMAL
	if CommunityUserInfo.IsFriend then
		CommunityUserInfo.CurFriendType = FRIEND_TYPE.FRIEND
		return 
	end
	if CommunityUserInfo.IsFollow then
		CommunityUserInfo.CurFriendType = FRIEND_TYPE.FOLLOW
	end
end

function CommunityUserInfo.CheckIsFollow(callback)
	keepwork.user.isfollow({
		objectId = CommunityUserInfo.UserData.id,
		objectType = 0,
	}, function(status, msg, data) 
		if (status == 200 and data and data ~= "false" and tonumber(data) ~= 0) then
			CommunityUserInfo.IsFollow = true
		end
		if callback then
			callback()
		end
	end)
end

function CommunityUserInfo.CheckIsFriend(callback)
	local username = CommunityUserInfo.GetUserName()
	if not username or username == "" then
		if callback then
			callback()
		end
		return 
	end
	local userid = CommunityUserInfo.UserData and CommunityUserInfo.UserData.id or -1
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
					CommunityUserInfo.IsFriend = true
					break
				end
			end
		end
		if callback then
			callback()
		end
	end)
end

function CommunityUserInfo.UpdateUserData()
	local username = SystemUserName
	if not username or username == ""  then
		username = "deng123456"
	end
	local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
	keepwork.user.getinfo({
		cache_policy = "access plus 10 seconds",
        router_params = {
            id = id,
        }
    },function (err, msg, data)
		if err == 200 then
			CommunityUserInfo.UserData = data
			CommunityUserInfo.RefreshPage()
		else
			CommunityUserInfo.LoginOutByErrToken(err)
		end
	end)
end

function CommunityUserInfo.ShowView(category_name)
	CommunityUserInfo.userScale = (CommunityUserInfo.UserData and CommunityUserInfo.UserData.extra and CommunityUserInfo.UserData.extra.ParacraftPlayerEntityInfo) and CommunityUserInfo.UserData.extra.ParacraftPlayerEntityInfo.scale or 1
	if CommunityUserInfo.userScale > 1 then
		CommunityUserInfo.userScale = 1
	end
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityUserInfoDialog.html",
		name = "CommunityUserInfo.ShowView", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		cancelShowAnimation = true,
		enable_esc_key = false,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	commonlib.TimerManager.SetTimeout(function()
		CommunityUserInfo.OnChangeCategory(category_name)
	end,200)
end

function CommunityUserInfo.OnCreate()
	if page then
		if CommunityUserInfo.mainAssets and CommunityUserInfo.mainAssets ~= "" then
			page:CallMethod("CommunityUserInfoMyPlayer", "SetAssetFile", CommunityUserInfo.mainAssets);
		end
		if CommunityUserInfo.mainSkin and CommunityUserInfo.mainSkin ~= "" then
			page:CallMethod("CommunityUserInfoMyPlayer", "SetCustomGeosets", CommunityUserInfo.mainSkin)
		end
		local module_ctl = page:FindControl("CommunityUserInfoMyPlayer")
		local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
		if scene and scene:IsValid() then
			local player = scene:GetObject(module_ctl.obj_name);
			if player then
				player:SetScale(CommunityUserInfo.userScale)
				player:SetFacing(1.57);
				player:SetField("HeadUpdownAngle", 0.2);
				player:SetField("HeadTurningAngle", 0);
				
			end
		end
		page:SetValue("Role_Scaling", tostring(CommunityUserInfo.userScale));
	end
end

function CommunityUserInfo.SetUserScale()
	if page then
		local module_ctl = page:FindControl("CommunityUserInfoMyPlayer")
		local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
		if scene and scene:IsValid() then
			local player = scene:GetObject(module_ctl.obj_name);
			if player then
				player:SetScale(CommunityUserInfo.userScale)
			end
		end
	end
end

function CommunityUserInfo.GetMenuDatas()
	if CommunityUserInfo.IsAuthUser() then
		return CommunityUserInfo.MenuItem_DS
	end
	local temp= {}
	for i=1,#CommunityUserInfo.MenuItem_DS do
		if not CommunityUserInfo.MenuItem_DS[i].isAuth then
			temp[#temp + 1] = CommunityUserInfo.MenuItem_DS[i]
		end
	end
	return temp
end

function CommunityUserInfo.RefreshPage()
	if page then
		page:Refresh(0)
	end
end

function CommunityUserInfo.ClosePage(bChangeSkin)
	if bChangeSkin then
		CommunityUserInfo.ChangePlayerSkinWhenClose()
	end
	if page then
		page:CloseWindow()
		page = nil
	end
end

function CommunityUserInfo.CloseInfoPage()
	if page then
		page:CloseWindow()
		page = nil
	end
end

function CommunityUserInfo.GetSystemUserId()
	return SystemUserID or 0
end

function CommunityUserInfo.GetSystemUserName()
	return SystemUserName or ""
end

function CommunityUserInfo.GetUserName()
	return CommunityUserInfo.UserData ~= nil and CommunityUserInfo.UserData.username or ""
end

function CommunityUserInfo.GetNickName()
	local nickName = (CommunityUserInfo.UserData and CommunityUserInfo.UserData.nickname and CommunityUserInfo.UserData.nickname ~= "") and CommunityUserInfo.UserData.nickname or CommunityUserInfo.GetUserName()
	return nickName
end

function CommunityUserInfo.IsAuthUser()
	return SystemUserName and SystemUserName ~= "" and CommunityUserInfo.GetUserName() == SystemUserName
end

function CommunityUserInfo.GetFollowNum()
	local rank = CommunityUserInfo.UserData ~= nil and CommunityUserInfo.UserData.rank or {}
	return rank and rank.follow or 0 
end

function CommunityUserInfo.GetFansNum()
	local rank = CommunityUserInfo.UserData ~= nil and CommunityUserInfo.UserData.rank or {}
	return rank and rank.fans or 0 
end

function CommunityUserInfo.GetSchoolInfo()
	if CommunityUserInfo.UserData and CommunityUserInfo.UserData.school then
		return CommunityUserInfo.UserData.school 
	end
end

function CommunityUserInfo.GetSchoolName()
	local school = CommunityUserInfo.GetSchoolInfo()
	return school and school.name or ""
end

function CommunityUserInfo.GetClassInfo()
	if CommunityUserInfo.UserData and CommunityUserInfo.UserData.class then
		return CommunityUserInfo.UserData.class 
	end
end

function CommunityUserInfo.GetClassName()
	local UserClassChange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserClassChange.lua");
	local class = CommunityUserInfo.GetClassInfo()
	if class then
		local gradeTxt = UserClassChange.GetGradeValue(class.grade)
		local enrollmentYear = class.enrollmentYear or 2021
		local classNum = class.classNo or 1
		return enrollmentYear.."级"..gradeTxt..classNum.."班"
	end
	return ""
end

function CommunityUserInfo.GetRegionInfo()
	if CommunityUserInfo.UserData and CommunityUserInfo.UserData.region then
		return CommunityUserInfo.UserData.region 
	end
end

function CommunityUserInfo.GetRegisterTimeStr()
	if CommunityUserInfo.UserData then
		local dateTime = CommunityUserInfo.UserData.createdAt or ""
		local year, month, day = commonlib.timehelp.GetYearMonthDayFromStr(dateTime);
        local registerAt = tostring(year) .. "." .. tostring(month) .. "." .. tostring(day); 
		return registerAt
	end
end

function CommunityUserInfo.IsVipTeacher()
	if System.options.isHideVip then 
        return false
    end
	return CommunityUserInfo.UserData and CommunityUserInfo.UserData.tLevel == 1
end

function CommunityUserInfo.IsRealName()
	return CommunityUserInfo.UserData and CommunityUserInfo.UserData.isRealname == true or CommunityUserInfo.UserData.isRealname == "true"
end

function CommunityUserInfo.GetRealNameCellPhone()
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

function CommunityUserInfo.LoginOutByErrToken(err)
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

function CommunityUserInfo.OnClickEditInfo(name)
	local name = name or ""
	if name == "class" then
		local classInfo = (CommunityUserInfo.UserData and CommunityUserInfo.UserData.class) and CommunityUserInfo.UserData.class or nil
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
					if CommunityUserInfo.UserData then
						CommunityUserInfo.UserData.class = classdata
					end
					CommunityUserInfo.RefreshPage()
				else
					CommunityUserInfo.LoginOutByErrToken(err)
				end
			end);
		end);
	end
	if name == "school" then
		GameLogic.GetFilters():apply_filters('cellar.my_school.select_school', function ()
            KeepWorkItemManager.LoadProfile(false, function()
                local profile = KeepWorkItemManager.GetProfile();
				if CommunityUserInfo.UserData then
					CommunityUserInfo.UserData.school = profile.school;
					CommunityUserInfo.RefreshPage()
				end
            end)
        end);
	end
end

function CommunityUserInfo.OnClickEditNickName()
	if page then
		local ctlEdit = ParaUI.GetUIObject("UserInfo.nickNameEdit")
		local ctlUserInfo = ParaUI.GetUIObject("UserInfo.nickName")
		if ctlEdit and ctlUserInfo then
			ctlEdit.visible = true
			ctlUserInfo.visible = false
		end
	end
end

function CommunityUserInfo.FinishEdit()
	if page then
		local name = page:GetValue("nick_name_edit");
		if (name == nil or name == "") then
			return;
		end
		if (commonlib.utf8.len(name) > 16) then
			_guihelper.MessageBox(L"输入的昵称太长，请控制在16个字以内");
			return;
		end

		local filterName = BadWordFilter.FilterString2(name);
		if name ~= filterName then
			_guihelper.MessageBox(L"包含敏感词，请重新修改");
			return 
		end

		
		local nickName = (CommunityUserInfo.UserData.nickname and CommunityUserInfo.UserData.nickname ~= "") and CommunityUserInfo.UserData.nickname or CommunityUserInfo.GetUserName()
		if nickName == name then
			CommunityUserInfo.CancelEdit()
			return 
		end
		if not CommunityUserInfo.isChangeNickName then
			CommunityUserInfo.UpdateNickName(name)
		else
			_guihelper.MessageBox(L"修改昵称将消耗 10 个知识豆, 请确认是否修改", function(res)
				if(res == _guihelper.DialogResult.OK) then
					local myBean = CommunityUserInfo.GetBeanNum()
					if myBean < 10 then
						_guihelper.MessageBox(L"知识豆不足，修改昵称失败");
						CommunityUserInfo.CancelEdit()
					else
						CommunityUserInfo.UpdateNickName(name)
					end
				end
			end, _guihelper.MessageBoxButtons.OKCancel_CustomLabel_Highlight_Right,nil,nil,nil,nil,{ ok = L"修改", cancel = L"取消", });
		end
	end
end

function CommunityUserInfo.UpdateNickName(nickName)
	keepwork.user.setinfo({
        router_params = {id = SystemUserID},
        nickname = nickName,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then 
            _guihelper.MessageBox(L"修改昵称失败");
			CommunityUserInfo.CancelEdit()
			return
        end
		KeepWorkItemManager.LoadItems(nil, function()
			if (CommunityUserInfo.isChangeNickName) then
				_guihelper.MessageBox("昵称修改成功, 知识豆扣除 10 个");
			else
				_guihelper.MessageBox("昵称修改成功");
				CommunityUserInfo.isChangeNickName = true;
			end
			CommunityUserInfo.CancelEdit()
			if CommunityUserInfo.UserData then
				CommunityUserInfo.UserData.nickname = nickName
			end
			GameLogic.GetFilters():apply_filters("ggs", {action = "UpdateNickName", nickname = nickName});
			GameLogic.GetFilters():apply_filters("ggs", {action = "UpdateUserInfo", userinfo = {nickname = nickName}});
			CommunityUserInfo.RefreshPage()
		end)
    end);
end

function CommunityUserInfo.CancelEdit()
	if page then
		local ctlEdit = ParaUI.GetUIObject("UserInfo.nickNameEdit")
		local ctlUserInfo = ParaUI.GetUIObject("UserInfo.nickName")
		if ctlEdit and ctlUserInfo then
			ctlEdit.visible = false
			ctlUserInfo.visible = true
		end
	end
end

function CommunityUserInfo.OnClickFollow()
	if not CommunityUserInfo.UserData then
		return 
	end
	keepwork.user.follow({
        objectType = 0,
        objectId = CommunityUserInfo.UserData.id,
    }, function(status, msg, data)
		if status == 200 then
			CommunityUserInfo.IsFollow = true
			CommunityUserInfo.CheckIsFriend(function()
				CommunityUserInfo.UpdateFriendType()
				CommunityUserInfo.RefreshPage()
			end)
		end
    end);
end

function CommunityUserInfo.OnClickCancelFollow()
	if not CommunityUserInfo.UserData then
		return 
	end
	keepwork.user.unfollow({
        objectType = 0,
        objectId = CommunityUserInfo.UserData.id,
    }, function(status, msg, data)
		if status == 200 then
			CommunityUserInfo.IsFollow = false
			CommunityUserInfo.IsFriend = false
			CommunityUserInfo.isExpland_Follow = false
			CommunityUserInfo.UpdateFriendType()
			CommunityUserInfo.RefreshPage()
		end
    end);
end

function CommunityUserInfo.OnClickChat()
	local FriendChatPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendChatPage.lua");
	FriendChatPage.Show(SystemUserData, CommunityUserInfo.UserData,nil,true);
	CommunityUserInfo.ClosePage()
end

local function GetItemIcon(item, suffix)
    local icon = item.icon;
    if(not icon or icon == "" or icon == "0") then icon = string.format("Texture/Aries/Creator/keepwork/items/item_%d%s_32bits.png", item.gsId, suffix or "") end
    return icon;
end

function CommunityUserInfo.OnChangeCategory(name)
	if name and name ~= "" and name ~= CommunityUserInfo.category_name then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_category", {category = name,useNoId=true},nil,true);
		CommunityUserInfo.skin_category_index = -1
		CommunityUserInfo.category_name = name
		if CommunityUserInfo.category_name == "security" then
			keepwork.user.authUsers({},function (err,msg,data)
				if err == 200 then
					CommunityUserInfo.authUsers = data
				else
					CommunityUserInfo.LoginOutByErrToken(err)
				end
				CommunityUserInfo.RefreshPage()
			end)
		elseif CommunityUserInfo.category_name == "honor" then
			if not CommunityUserInfo.UserData then
				CommunityUserInfo.RefreshPage()
				return 
			end
			keepwork.user.honors({
				userId = CommunityUserInfo.UserData.id
			},function (err,msg,data)
				if err == 200 then
					if data  then
						CommunityUserInfo.CurHonor_DS = CommunityUserInfo.GetHonorData(data.rows)
					end
				else
					CommunityUserInfo.LoginOutByErrToken(err)
				end
				CommunityUserInfo.RefreshPage()
			end)
		elseif CommunityUserInfo.category_name == "works" then
			if not CommunityUserInfo.UserData then
				CommunityUserInfo.RefreshPage()
				return 
			end
			keepwork.project.list({
				userId = CommunityUserInfo.UserData.id,
				type = 1,
				["x-page"] = 1,                  -- 页数
				["x-per-page"] = 1000,          -- 页大小
				["x-order"] = "updatedAt-desc",     -- 按更新时间降序
			},function (err,msg,data)
				if err == 200  then
					CommunityUserInfo.GetProjectData(data)
				else
					CommunityUserInfo.LoginOutByErrToken(err)
				end
			end)
		elseif CommunityUserInfo.category_name == "skin" then
			local category_index = 1
			CommunityUserInfo.OnChangeSkinCategory(category_index,true)
		elseif CommunityUserInfo.category_name == "bags" then
			KeepWorkItemManager.LoadItems(nil, function()
				CommunityUserInfo.CurBagItem_DS = CommunityUserInfo.GetItemData()
				CommunityUserInfo.RefreshPage()
			end)
		else
			CommunityUserInfo.RefreshPage()
		end
	end
end

function CommunityUserInfo.GetProjectData(projectDts)
	local projectDatas, projectIds= {},{}
	local projectDts = projectDts or {}
	-- echo(projectDts,true)
	local projectNum = #projectDts
	if projectNum > 0 then
		for i=1,#projectDts do
            -- echo(projectDts[i],true)
            if projectDts[i].channel == nil or projectDts[i].channel == 0 then
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
                data.imageUrl = projectDts[i].extra and projectDts[i].extra.imageUrl or "https://keepwork.com/_nuxt/project_default_cover_new.380556d4.png" --世界icon
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
							if projectDatas[i] and projectDatas[i].projectId and temp[projectDatas[i].projectId] then
								projectDatas[i].isFavorite = true
							end
						end
					end
				else
					CommunityUserInfo.LoginOutByErrToken(err)
				end
				CommunityUserInfo.CurProject_DS = projectDatas
				-- echo(CommunityUserInfo.CurProject_DS,true)
				CommunityUserInfo.RefreshPage()
			end)
		else
			CommunityUserInfo.RefreshPage()
		end
	else
		CommunityUserInfo.RefreshPage()
	end
end

function CommunityUserInfo.OnClickGotoWorld(data)
	local worldId = data.projectId
	if worldId and worldId > 0 then
		CommunityUserInfo.ClosePage()
		GameLogic.RunCommand(string.format("/loadworld -s -auto %d", worldId)); 
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_world", {worldId = worldId,useNoId=true},nil,true);
	end
	 
end

function CommunityUserInfo.OnClickBack(name)
	local index = tonumber(name)
	if index and index > 0 then
		CommunityUserInfo.select_project_index = index
		CommunityUserInfo.RefreshPage()
	end
end

function CommunityUserInfo.OnClickShareWorld(data)
	local worldId = data.projectId
	if worldId and worldId > 0 then
		local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")
    	ShareWorld:ShowWorldCode(worldId)
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_share_world", {worldId = worldId,useNoId=true},nil,true);
	end
	CommunityUserInfo.select_project_index = CommunityUserInfo.GetSelectProjectIndex(data)
	CommunityUserInfo.RefreshPage()
end

function CommunityUserInfo.OnClickFavoriteWorld(bFavorite,projectId)
	if not projectId or projectId ==0 then
		return 
	end
	for i,v in ipairs(CommunityUserInfo.CurProject_DS) do
		if projectId and projectId == CommunityUserInfo.CurProject_DS[i].projectId then
			CommunityUserInfo.CurProject_DS[i].isFavorite = bFavorite
			break
		end
	end
	CommunityUserInfo.select_project_index = CommunityUserInfo.GetSelectProjectIndex(projectId)
	CommunityUserInfo.RefreshPage()
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

function CommunityUserInfo.GetSelectProjectIndex(params)
	local projectId
	if type(params) == "number" then
		projectId = params
	end
	if type(params) == "table" then
		projectId = params.projectId
	end
	for i,v in ipairs(CommunityUserInfo.CurProject_DS) do
		if projectId and projectId == CommunityUserInfo.CurProject_DS[i].projectId then
			return i
		end
	end
	return 1
end

function CommunityUserInfo.GetHonorData(rows)
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
	if CommunityUserInfo.IsAuthUser() then
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

function CommunityUserInfo.GetVipIcon()
    local KpUserTag = NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/KpUserTag.lua");
	local profile = KeepWorkItemManager.GetProfile()
	local user_tag = KpUserTag.GetMcml(profile);
	return user_tag
end

function CommunityUserInfo.OnClickHonor(data)
	-- echo(data,true)
	if (not data.certurl or data.certurl == "") then return end;
    if (not data.has) then return end 
    
    local username = CommunityUserInfo.UserData.username;
    if (CommunityUserInfo.UserData.nickname and CommunityUserInfo.UserData.nickname ~= "") then 
		username = CommunityUserInfo.UserData.nickname 
	end
	data.username = username
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_honor", {useNoId=true},nil,true);
	local HonorPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/HonorPage.lua");
	HonorPage.ShowPage(data);
end

function CommunityUserInfo.GetBindInfo(type)
	if CommunityUserInfo.authUsers then
		for k,v in pairs(CommunityUserInfo.authUsers) do
			if type and v.type == type then 
				return v
			end
		end
	end
end

function CommunityUserInfo.IsWeixinBind()
	return CommunityUserInfo.GetBindInfo(1) ~= nil
end

function CommunityUserInfo.GetWeixinName()
	local bindInfo = CommunityUserInfo.GetBindInfo(1)
	return bindInfo and bindInfo.externalUsername or ""
end

function CommunityUserInfo.IsQQBind()
	return CommunityUserInfo.GetBindInfo(0) ~= nil
end

function CommunityUserInfo.GetQQName()
	local bindInfo = CommunityUserInfo.GetBindInfo(0)
	return bindInfo and bindInfo.externalUsername or ""
end

function CommunityUserInfo.IsGithubBind()
	return CommunityUserInfo.GetBindInfo(2) ~= nil
end

function CommunityUserInfo.GetGithubName()
	local bindInfo = CommunityUserInfo.GetBindInfo(2)
	return bindInfo and bindInfo.externalUsername or ""
end

function CommunityUserInfo.IsWeiboBind()
	return CommunityUserInfo.GetBindInfo(3) ~= nil
end

function CommunityUserInfo.GetWeiboName()
	local bindInfo = CommunityUserInfo.GetBindInfo(3)
	return bindInfo and bindInfo.externalUsername or ""
end

function CommunityUserInfo.IsMobilePhoneBind()
	return SystemUserData and SystemUserData.cellphone and SystemUserData.cellphone ~= ""
end

function CommunityUserInfo.GetMobilePhoneName()
	return SystemUserData.cellphone
end

function CommunityUserInfo.IsEmailBind()
	return SystemUserData and SystemUserData.email and SystemUserData.email ~= ""
end

function CommunityUserInfo.GetEmailName()
	return SystemUserData.email
end

function CommunityUserInfo.OnClickGotoBind()
	local token = commonlib.getfield("System.User.keepworktoken")
	local urlbase = GameLogic.GetFilters():apply_filters("get_keepwork_url");
	local method = '/u/p/userData'
	local url = string.format('%s/p?url=%s&token=%s',urlbase,Mod.WorldShare.Utils.EncodeURIComponent(method),token) 
	GameLogic.RunCommand("/open "..url)
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_bind", {useNoId=true},nil,true);
end

function CommunityUserInfo.GetBindInfoData()
	local temp = {}
	--微信

	if CommunityUserInfo.IsWeixinBind() then
		temp[#temp + 1] = {key=L"微信:" , name = CommunityUserInfo.GetWeixinName(),isBind = true ,buttonValue = L"去解绑 >" ,buttonName="1"}
	else
		temp[#temp + 1] = {key=L"微信:" , name = L"未绑定",isBind = false ,buttonValue=L"去绑定 >" ,buttonName="2"}
	end

	if CommunityUserInfo.IsWeiboBind() then
		temp[#temp + 1] = {key=L"微博:" , name = CommunityUserInfo.GetWeiboName(),isBind = true ,buttonValue = L"去解绑 >" ,buttonName="1"}
	else
		temp[#temp + 1] = {key=L"微博:" , name = L"未绑定",isBind = false ,buttonValue=L"去绑定 >" ,buttonName="2"}
	end

	if CommunityUserInfo.IsQQBind() then
		temp[#temp + 1] = {key="QQ:" , name = CommunityUserInfo.GetQQName(),isBind = true ,buttonValue = L"去解绑 >" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="QQ:" , name = L"未绑定",isBind = false ,buttonValue=L"去绑定 >" ,buttonName="2"}
	end

	if CommunityUserInfo.IsGithubBind() then
		temp[#temp + 1] = {key="GitHub:" , name = CommunityUserInfo.GetGithubName(),isBind = true ,buttonValue = L"去解绑 >" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="GitHub:" ,name = L"未绑定", isBind = false ,buttonValue=L"去绑定 >" ,buttonName="2"}
	end

	if CommunityUserInfo.IsEmailBind() then
		temp[#temp + 1] = {key=L"邮箱:" , name = CommunityUserInfo.GetEmailName(),isBind = true ,buttonValue = L"去解绑 >" ,buttonName="1"}
	else
		temp[#temp + 1] = {key=L"邮箱:" ,name = L"未绑定", isBind = false ,buttonValue=L"去绑定 >" ,buttonName="2"}
	end

	if CommunityUserInfo.IsMobilePhoneBind() then
		temp[#temp + 1] = {key=L"手机:" , name = CommunityUserInfo.GetMobilePhoneName(),isBind = true ,buttonValue = L"去解绑 >" ,buttonName="1"}
	else
		temp[#temp + 1] = {key=L"手机:" ,name = L"未绑定", isBind = false ,buttonValue=L"去绑定 >" ,buttonName="2"}
	end
	return temp
end

function CommunityUserInfo.RealName()
	local CommunityTitleInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityTitleInfo.lua")
	CommunityTitleInfo.OnClickRealname()
end

function CommunityUserInfo.RemoveAccount()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_remove_account", {useNoId=true},nil,true);
	local RemoveAccount = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/RemoveAccount.lua")
     RemoveAccount.ShowPage()
end

function CommunityUserInfo.CloseLoginPage()
	local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')
	if MainLoginLoginPage then
		MainLoginLoginPage:CloseWindow()
	end
end

function CommunityUserInfo.UpdatePassworld()
	local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
    local RedSummerCampSchoolMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampSchoolMainPage.lua");
	CommunityUserInfo.ClosePage()
	MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
	--切换到修改密码
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_update_password", {useNoId=true},nil,true);
	commonlib.TimerManager.SetTimeout(function()
		local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
		if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
			_guihelper.MessageBox(L'*修改密码前请先完成实名认证。', function()
				local Certificate = NPL.load('(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua')
				Certificate:ShowMyHomePage(function(result)
					if GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
						MainLogin:UpdatePasswordRemindVisible(false)
						CommunityUserInfo.CloseLoginPage()
						MainLogin:ShowUpdatePassword()
					end
				end)
			end)
			return
		end

		MainLogin:UpdatePasswordRemindVisible(false)
		CommunityUserInfo.CloseLoginPage()
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

function CommunityUserInfo.CanFill(item)
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

function CommunityUserInfo.GetItemData()
	local items = KeepWorkItemManager.items or {};
    local result = {};
    for k,item in ipairs(items) do
        if(CommunityUserInfo.CanFill(item))then
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
function CommunityUserInfo.UpdatePlayerEntityInfo()
	if not CommunityUserInfo.IsAuthUser() then
		return
	end
	local playerEntity = GameLogic.GetPlayerController():GetPlayer();

	if playerEntity then
		playerEntity:SetMainAssetPath(CommunityUserInfo.mainAssets);
		playerEntity:SetSkin(CommunityUserInfo.mainSkin); 
		playerEntity:SetScaling(CommunityUserInfo.userScale)
	end

	GameLogic.options:SetMainPlayerAssetName(CommunityUserInfo.mainAssets);
	GameLogic.options:SetMainPlayerSkins(CommunityUserInfo.mainSkin);
	GameLogic.GetFilters():apply_filters("user_skin_change", CommunityUserInfo.mainSkin);
	local asset = MyCompany.Aries.Game.PlayerController:GetMainAssetPath()
    local skin = MyCompany.Aries.Game.PlayerController:GetSkinTexture()
	if not CommunityUserInfo.UserData then
		return 
	end
    local extra = CommunityUserInfo.UserData.extra and CommunityUserInfo.UserData.extra or {};
    extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
    extra.ParacraftPlayerEntityInfo.asset = asset;
    extra.ParacraftPlayerEntityInfo.skin = skin;
    extra.ParacraftPlayerEntityInfo.assetSkinGoodsItemId = 0;
	if page then
		extra.ParacraftPlayerEntityInfo.scale = CommunityUserInfo.userScale
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
			CommunityUserInfo.Current_Icon_DS[index].id = item.id;
			CommunityUserInfo.Current_Icon_DS[index].name = item.name;
			CommunityUserInfo.Current_Icon_DS[index].icon = item.icon;
		end
	end
end

function CommunityUserInfo.GetToolTipBySkinId(skinId)
	local data = CustomCharItems:GetItemById(skinId);
	if not data then
		return ""
	end
	return data.name or ""
end

function CommunityUserInfo.GetSkinIconByUserData()
	if CommunityUserInfo.UserData then
		local ParacraftPlayerEntityInfo = CommunityUserInfo.UserData.extra and CommunityUserInfo.UserData.extra.ParacraftPlayerEntityInfo or {};
		local skin = CustomCharItems:GetSkinByAsset(ParacraftPlayerEntityInfo.asset) 
		if (ParacraftPlayerEntityInfo.asset) then 
			CommunityUserInfo.mainAssets = ParacraftPlayerEntityInfo.asset
        end 
        if (ParacraftPlayerEntityInfo.skin) then 
			CommunityUserInfo.mainSkin = ParacraftPlayerEntityInfo.skin
        end 
		if CommunityUserInfo.mainAssets ~= CustomCharItems.defaultModelFile then
			CommunityUserInfo.mainAssets = CustomCharItems.defaultModelFile
			CommunityUserInfo.mainSkin = (skin and skin ~= "") and skin or "" 
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

function CommunityUserInfo.OnChangeSkinCategory(index,bChangeMenu)
	if index and index > 0 and CommunityUserInfo.skin_category_index ~= index then
		CommunityUserInfo.skin_category_index = index or CommunityUserInfo.skin_category_index;
		local category = CommunityUserInfo.skin_category_ds[CommunityUserInfo.skin_category_index];
		if (category) then
			CommunityUserInfo.Current_SkinItem_DS = CustomCharItems:GetModelItems(CommunityUserInfo.mainAssets, category.name, CommunityUserInfo.mainSkin or "",true) or {};
		end
		CommunityUserInfo.UpdateItemData()
		-- print("llllllllllllllllllllll",bChangeMenu)
		-- echo(CommunityUserInfo.Current_SkinItem_DS,true)
		CommunityUserInfo.RefreshPage();
	end
end

function CommunityUserInfo.GetAllItemData()
	local category = CommunityUserInfo.skin_category_ds[CommunityUserInfo.skin_category_index];
	if (category) then
		CommunityUserInfo.Current_SkinItem_DS = CustomCharItems:GetModelItems(CommunityUserInfo.mainAssets, category.name, CommunityUserInfo.mainSkin or "",true) or {};
	end
end

function CommunityUserInfo.UpdateSkinGView(data)
	if data then
		page:CallMethod("gvSkinGridView","SetDataSource", data);
		page:CallMethod("gvSkinGridView","DataBind");
	end
end

function CommunityUserInfo.UpdateItemData() --下架了套装，需要处理散件数据
	for i,v in ipairs(CommunityUserInfo.Current_SkinItem_DS) do
		if v.gsid and v.gsid ~= "" then
			v.type = SKIN_ITEM_TYPE.ACTIVITY_GOOD
		end
		if v.type == SKIN_ITEM_TYPE.SUIT_PART then
			v.type = SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE
		end
	end
	--去掉异常数据
	local temp = {}
	for i,v in ipairs(CommunityUserInfo.Current_SkinItem_DS) do
		if v.type == SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE and v.price and v.price ~= "" and tonumber(v.price) > 0 then
			temp[#temp + 1] = v
		end
		if v.type ~= SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE then
			temp[#temp + 1] = v
		end
	end
	if System.options.isHideVip then
		temp = commonlib.filter(temp,function (item)
			return item.type ~= SKIN_ITEM_TYPE.VIP and item.type ~= SKIN_ITEM_TYPE.SVIP
		end)
	end
	CommunityUserInfo.UpdateSkinIcon()
	--是否选中只显示已拥有
	if CommunityUserInfo.isOnlyShowHave then
		local data = {}
		for i,v in ipairs(CommunityUserInfo.Current_SkinItem_DS) do
			if CommunityUserInfo.CheckSkinIsValid(v.id) then
				data[#data + 1] = v
			end
		end
		CommunityUserInfo.Current_SkinItem_DS = data
		return
	end

	CommunityUserInfo.Current_SkinItem_DS = temp
	
end

function CommunityUserInfo.UpdateSkinIcon()
	local category = CommunityUserInfo.skin_category_ds[CommunityUserInfo.skin_category_index];
	if category and category.name and category.name == "eye" then
		for i,v in ipairs(CommunityUserInfo.Current_SkinItem_DS) do
			if v.icon and v.icon ~= "" then
				v.icon = string.gsub(v.icon, "Texture/Aries/Creator/keepwork/Avatar/icons/", "Texture/Aries/Creator/keepwork/Community/eye/");
			end
		end
	end
end

function CommunityUserInfo.GetActivityName(gsid)
    local template = KeepWorkItemManager.GetItemTemplate(gsid);
    if (template and template.desc) then
        return template.desc;
    end
end

function CommunityUserInfo.UpdateCustomGeosets(name)
	local index = tonumber(name)
	if index and index > 0 then
		local item = CommunityUserInfo.Current_SkinItem_DS[index];
		local ui_index = CommunityUserInfo.skin_category_ds[CommunityUserInfo.skin_category_index].ui_index;
		if (CommunityUserInfo.Current_Icon_DS[ui_index].id == item.id) then
			return;
		end

		CommunityUserInfo.mainSkin = CustomCharItems:AddItemToSkin(CommunityUserInfo.mainSkin, item);

		CommunityUserInfo.Current_Icon_DS[ui_index].id = item.id;
		CommunityUserInfo.Current_Icon_DS[ui_index].name= item.name;
		CommunityUserInfo.Current_Icon_DS[ui_index].icon = item.icon;
		CommunityUserInfo.RefreshPage();
	end
end

function CommunityUserInfo.CheckHasUpdateNickName()
	local GOODS_UPDATE_NICKNAME_ID = 30270 -- 是否更新过nickname
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(GOODS_UPDATE_NICKNAME_ID)
	return bHas or (copies and copies > 0)
end

function CommunityUserInfo.GetBeanNum()
	local BEAN_GSID = 998;
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(BEAN_GSID)
	return copies or 0;
end


function CommunityUserInfo.Purchase(skinId)
	local skinData = CustomCharItems:GetItemById(skinId);
	if not skinData or skinData.type ~= SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE then
		return 
	end
	-- echo(skinData,true)
	local myBean = CommunityUserInfo.GetBeanNum()
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
				CommunityUserInfo.GetClothesOfServerData(true)
				CommunityUserInfo.UpdateSkinGView(CommunityUserInfo.Current_SkinItem_DS)
			end)
		else
			CommunityUserInfo.LoginOutByErrToken(code)
		end
	end)
end

function CommunityUserInfo.GetClothesOfServerData(bRefresh)
	if not CommunityUserInfo.buyClothesData or bRefresh then
		local SkinManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/SkinManager.lua")
		local clothes = SkinManager.GetServerSkinData()
		CommunityUserInfo.buyClothesData = clothes
	end
	return CommunityUserInfo.buyClothesData;
end

function CommunityUserInfo.ChangePlayerSkinWhenClose()
	if not CommunityUserInfo.IsAuthUser() then
		return 
	end
	if CommunityUserInfo.mainSkin and CommunityUserInfo.mainSkin ~= "" then
		CommunityUserInfo.mainSkin = CommunityUserInfo.RemoveAllUnvalidItems(CommunityUserInfo.mainSkin)
	end
	CommunityUserInfo.UpdatePlayerEntityInfo()
end

function CommunityUserInfo.RemoveSkin(name)
	local index = tonumber(name)
	if not index or index <= 0 or not CommunityUserInfo.IsAuthUser() then
		return 
	end
	if System.options.isHideVip then
        return
    end
	local iconItem = CommunityUserInfo.Current_Icon_DS[index];
	local length = string.len(CommunityUserInfo.mainSkin)
	if (iconItem and iconItem.id and iconItem.id ~= "") then
		if CommunityUserInfo.mainSkin ~= "" and string.sub(CommunityUserInfo.mainSkin,length) ~= ";"then
			local curSkin = ""
			local skinTbl = commonlib.split(CommunityUserInfo.mainSkin,";")
			if skinTbl then
				for k,v in pairs(skinTbl) do
					curSkin = curSkin..v..";"
				end
			end
			if curSkin ~= "" then
				CommunityUserInfo.mainSkin = curSkin
			end
		end
		local skin = CustomCharItems:RemoveItemInSkin(CommunityUserInfo.mainSkin, iconItem.id);
		if (CommunityUserInfo.mainSkin ~= skin) then
			CommunityUserInfo.mainSkin = skin;
			iconItem.id = "";
			iconItem.name = "";
			iconItem.icon = "";
			CommunityUserInfo.RefreshPage()
		end
	end
end

function CommunityUserInfo.RemoveAllUnvalidItems(skin)
	local newSkin = SkinManager.RemoveAllUnvalidItems(skin)
	return newSkin
end

function CommunityUserInfo.CheckSkinUsed(skinId)
	local skinId = tostring(skinId)
	local mainSkin = CommunityUserInfo.mainSkin or ""
	local skinIdStr = CustomCharItems:SkinStringToItemIds(mainSkin)
	if skinIdStr and string.find(skinIdStr, skinId) then
		return true
	end
	return false
end

function CommunityUserInfo.CheckSkinIsValid(skinId)
	local isValid = SkinManager.CheckSkinIsValid(skinId)
	return isValid
end

function CommunityUserInfo.GetDataIndex(data)
	for i,v in ipairs(CommunityUserInfo.Current_SkinItem_DS) do
		if tonumber(v.id) == tonumber(data.id) then
			return i
		end
	end
end

function CommunityUserInfo.GetDataIndexByName(name)
	for i,v in ipairs(CommunityUserInfo.Current_SkinItem_DS) do
		if name and name == v.name then
			return i
		end
	end
end

function CommunityUserInfo.GetSkinIdByName(name)
	for i,v in ipairs(CommunityUserInfo.Current_SkinItem_DS) do
		if name and name == v.name then
			return v.id
		end
	end
end

function CommunityUserInfo.UseSkinBySkinId(skinId)
	local data = CustomCharItems:GetItemById(skinId);
	if data then
		local index = CommunityUserInfo.GetDataIndex(data)
		if index and index > 0 then
			CommunityUserInfo.UpdateCustomGeosets(index)
		end
	end
end

function CommunityUserInfo.UseSkinBySkinName(skinName)
	local index = CommunityUserInfo.GetDataIndexByName(skinName)
	if index and index > 0 then
		CommunityUserInfo.UpdateCustomGeosets(index)
	end
end

function CommunityUserInfo.RemoveSkinByName(skinName)
	local skinId = CommunityUserInfo.GetSkinIdByName(skinName)
	if skinId and string.find(CommunityUserInfo.mainSkin,skinId) then
		for i,v in ipairs(CommunityUserInfo.Current_Icon_DS) do
			if tonumber(v.id) == tonumber(skinId) then
				v.id = "";
				v.name = "";
				v.icon = "";
				break
			end
		end
		local skin = CustomCharItems:RemoveItemInSkin(CommunityUserInfo.mainSkin, skinId);
		if (CommunityUserInfo.mainSkin ~= skin) then
			CommunityUserInfo.mainSkin = skin;
			CommunityUserInfo.RefreshPage()
		end
	end
end

function CommunityUserInfo.OnClickShowHased() 
	CommunityUserInfo.isOnlyShowHave = not CommunityUserInfo.isOnlyShowHave
	CommunityUserInfo.GetAllItemData()
	CommunityUserInfo.UpdateItemData()
	CommunityUserInfo.RefreshPage()
end

function CommunityUserInfo.CopyUserID()
	if CommunityUserInfo.UserData then
		local userId = CommunityUserInfo.UserData.id
		if userId then
			ParaMisc.CopyTextToClipboard(tostring(userId))
			GameLogic.AddBBS(nil,"用户ID已复制到剪贴板")
		end
	end
end

function CommunityUserInfo.GetUserId()
	if CommunityUserInfo.UserData then
		return tostring(CommunityUserInfo.UserData.id)
	end
	return ""
end

-- 更新mouse效果
function CommunityUserInfo.ResetSelectStatus()
    if true then
        return
    end
    local pageSize = CommunityUserInfo.CurProject_DS and #CommunityUserInfo.CurProject_DS or 0
    for i = 1, pageSize do
        local project_select_bg = page:FindControl("project_select_bg"..i)
        local project_bg = page:FindControl("project_bg"..i)
        local project_preview_select2_bg = page:FindControl("project_preview_select2_bg"..i)
        local project_preview_select1_bg = page:FindControl("project_preview_select1_bg"..i)
        local project_preview_border_select_bg = page:FindControl("project_preview_border_select_bg"..i)
        local project_preview_border_normal_bg = page:FindControl("project_preview_border_normal_bg"..i)
        if project_select_bg then
            project_select_bg.visible = false
        end
        if project_bg then
            project_bg.visible = true
        end
        if project_preview_select2_bg then
            project_preview_select2_bg.visible = false
        end
        if project_preview_select1_bg then
            project_preview_select1_bg.visible = false
        end
        if project_preview_border_select_bg then
            project_preview_border_select_bg.visible = false
        end
        if project_preview_border_normal_bg then
            project_preview_border_normal_bg.visible = true
        end
        local project_info_bg = page:FindControl("project_info_bg"..i)
        if project_info_bg then
            project_info_bg.visible = true
        end
    end
end



function CommunityUserInfo.OnMouseEnterImp(index,isBg,isPreview)
    if not page or not index then
        return
    end
    
    local project_select_bg = page:FindControl("project_select_bg"..index)
    if project_select_bg then
        project_select_bg.visible = true
    end

    local project_bg = page:FindControl("project_bg"..index)
    if project_bg then
        project_bg.visible = false
    end

    local project_preview_select2_bg = page:FindControl("project_preview_select2_bg"..index)
    if project_preview_select2_bg then
		local isShow = false
        if isPreview then
            isShow = true
        end
        project_preview_select2_bg.visible = isShow
    end

    local project_preview_select1_bg = page:FindControl("project_preview_select1_bg"..index)
    if project_preview_select1_bg then
		local isShow = true
        if isPreview then
            isShow = false
        end
        project_preview_select1_bg.visible = isShow
    end

    local project_preview_border_select_bg = page:FindControl("project_preview_border_select_bg"..index)
    if project_preview_border_select_bg then
        project_preview_border_select_bg.visible = true
    end

    local project_preview_border_normal_bg = page:FindControl("project_preview_border_normal_bg"..index)
    if project_preview_border_normal_bg then
        project_preview_border_normal_bg.visible = false
    end
    local project_info_bg = page:FindControl("project_info_bg"..index)
    if project_info_bg then
        project_info_bg.visible = false
    end
end

function CommunityUserInfo.OnMouseLeaveImp(index,isBg,isPreview)
    if not page or not index then
        return
    end
    
    local project_select_bg = page:FindControl("project_select_bg"..index)
    if project_select_bg then
        local isShow = false
        if isPreview then
            isShow = true
        end
        project_select_bg.visible = isShow
    end

    local project_bg = page:FindControl("project_bg"..index)
    if project_bg then
        local isShow = true
        if isPreview then
            isShow = false
        end
        project_bg.visible = isShow
    end

    local project_preview_select2_bg = page:FindControl("project_preview_select2_bg"..index)
    if project_preview_select2_bg then
        project_preview_select2_bg.visible = false
    end

    local project_preview_select1_bg = page:FindControl("project_preview_select1_bg"..index)
    if project_preview_select1_bg then
        local isShow = false
        if isPreview then
            isShow = true
        end
        project_preview_select1_bg.visible = isShow
    end

    local project_preview_border_select_bg = page:FindControl("project_preview_border_select_bg"..index)
    if project_preview_border_select_bg then
        local isShow = false
        if isPreview then
            isShow = true
        end
        project_preview_border_select_bg.visible = isShow
    end

    local project_preview_border_normal_bg = page:FindControl("project_preview_border_normal_bg"..index)
    if project_preview_border_normal_bg then
        local isShow = false
        if isBg then
            isShow = true
        end
        project_preview_border_normal_bg.visible = isShow
    end
    local project_info_bg = page:FindControl("project_info_bg"..index)
    if project_info_bg then
        local isShow = false
        if isBg then
            isShow = true
        end
        project_info_bg.visible = isShow
    end
end

function CommunityUserInfo.OnBgMouseEnter(index)
    CommunityUserInfo.ResetSelectStatus()
    CommunityUserInfo.OnMouseEnterImp(index,true)
end

function CommunityUserInfo.OnBgMouseLeave(index)
    CommunityUserInfo.ResetSelectStatus()
    CommunityUserInfo.OnMouseLeaveImp(index,true)
end

function CommunityUserInfo.OnPreviewMouseEnter(index)
    CommunityUserInfo.ResetSelectStatus()
    CommunityUserInfo.OnMouseEnterImp(index,false,true)
end

function CommunityUserInfo.OnPreviewMouseLeave(index)
    CommunityUserInfo.ResetSelectStatus()
    CommunityUserInfo.OnMouseLeaveImp(index,false,true)
end

function CommunityUserInfo.OnSkinMouseEnter(index)
	if not page or not index then
		return
	end
	local skin_select_bg = page:FindControl("skin_select_item_bg"..index)
	local skin_item_bg = page:FindControl("skin_item_bg"..index)
	if skin_item_bg and skin_select_bg then
		skin_item_bg.visible = false
		skin_select_bg.visible = true
	end
end

function CommunityUserInfo.OnSkinMouseLeave(index)
	if not page or not index then
		return
	end
	local skin_select_bg = page:FindControl("skin_select_item_bg"..index)
	local skin_item_bg = page:FindControl("skin_item_bg"..index)
	if skin_item_bg and skin_select_bg then
		skin_item_bg.visible = true
		skin_select_bg.visible = false
	end
end