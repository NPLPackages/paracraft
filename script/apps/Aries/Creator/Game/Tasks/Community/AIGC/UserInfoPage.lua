--[[
    author:{pbb}
    time:2025-02-18 13:50:48
    uselib:
        local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoPage.lua")
        UserInfoPage.ShowPage()
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
local UserInfoPage = NPL.export()
local SystemUserData = KeepWorkItemManager.GetProfile();
local SystemUserName = commonlib.getfield("System.User.username")
local SystemUserID = SystemUserData and SystemUserData.id or 0

--人物旁边的
UserInfoPage.isChangeNickName = false
UserInfoPage.mainAssets = ""
UserInfoPage.mainSkin = ""

UserInfoPage.MenuItem_DS = {
	{title=L"外观装扮",ui_index = 1,text=L"外观装扮", name="skin",isAuth = true},
	{title=L"角色动作",ui_index = 1,text=L"角色动作", name="anim",isAuth = true},
	{title=L"我的作品",ui_index = 2,text=L"我的作品", name="works"},
	-- {title=L"荣誉称号",ui_index = 3,text=L"荣誉称号", name="honor"},
	{title=L"账号设置",ui_index = 4,text=L"账号设置", name="security",isAuth = true}
}
UserInfoPage.CurAnimations_DS = {}
UserInfoPage.CurBagItem_DS = {}
UserInfoPage.CurHonor_DS = {}
UserInfoPage.authUsers = {}
UserInfoPage.CurProject_DS = {}
UserInfoPage.category_name = ""
UserInfoPage.select_project_index = -1
UserInfoPage.UserData = nil
UserInfoPage.IsFollow = false
UserInfoPage.IsFriend = false
UserInfoPage.isExpland_Follow = false

UserInfoPage.SkinQualitys = {
	{text=L"全部", price=0, value=-1},
	{text=L"普通", price=25, value=1},
	{text=L"稀有", price=50, value=2},
	{text=L"卓越", price=100, value=3},
	{text=L"绝迹", price=200, value=4},
	{text=L"限定", price=400, value=5},
	--{text=L"限量", price=800, value=6},
}
UserInfoPage.search_text = ""
UserInfoPage.select_quality_index = 1

local SKIN_ITEM_TYPE = {
	FREE = "0",
	SVIP = "1",
	ONLY_BEANS_CAN_PURCHASE = "2",
	ACTIVITY_GOOD = "3",
	VIP = "4",
	-- 套装部件
	SUIT_PART = "5",
	VIP_FREE = "6", -- vip免费
}
UserInfoPage.SKIN_ITEM_TYPE = SKIN_ITEM_TYPE

local FRIEND_TYPE = {
	NORMAL = 1,
	FOLLOW = 2,
	FRIEND = 3,
}
UserInfoPage.FRIEND_TYPE = FRIEND_TYPE;

UserInfoPage.CurFriendType = FRIEND_TYPE.NORMAL
local page
function UserInfoPage.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = UserInfoPage.OnCreate
end

function UserInfoPage.ShowPage(username,category_name,userId)
	if username and username == "maisiAIMainPage" then
		GameLogic.CheckSignedIn(L"请先登录", function(result)
			if result then
				UserInfoPage.ShowPage(nil,category_name)
			end
		end)
		UserInfoPage.isFromMaisi = true
		return
	end
	UserInfoPage.isFromMaisi = false
	local category_name = category_name or "skin"
	UserInfoPage.InitData()
	local username = (username and username ~= "") and username or SystemUserName
	if not username or username == ""  then
		username = "deng123456"
	end
	local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
	if userId and tonumber(userId) > 0 then
		id = "kp" .. Encoding.base64(commonlib.Json.Encode({userId=userId}));
	end
	Mod.WorldShare.MsgBox:Wait(10000,L"用户信息加载中.....")
	ParaAsset.LoadTexture("","Texture/Aries/Creator/keepwork/Community/user_bg.jpg",1);
	keepwork.user.getinfo({
		cache_policy = "access plus 10 seconds",
        router_params = {
            id = id,
        }
    },function (err, msg, data)
		if err == 200 then
			UserInfoPage.UserData = data

            if UserInfoPage.UserData.nickname == nil or UserInfoPage.UserData.nickname == "" then
                UserInfoPage.UserData.nickname = UserInfoPage.UserData.username
                UserInfoPage.UserData.limit_nickname = UserInfoPage.UserData.username
            else
                UserInfoPage.UserData.limit_nickname = commonlib.GetLimitLabel(UserInfoPage.UserData.nickname, 26)
            end
            UserInfoPage.UserData.is_vip = UserInfoPage.UserData.vip == 1
            UserInfoPage.UserData.is_common_vip = UserInfoPage.UserData.commonVip == 1
            UserInfoPage.UserData.limit_username = UserInfoPage.UserData.username
			UserInfoPage.ShowView(category_name)
		else
			UserInfoPage.LoginOutByErrToken(err)
		end
	end)
end

function UserInfoPage.IsCommonVip()
	if not UserInfoPage.UserData or System.options.isHideVip then
		return false
	end
	local isVip = KeepWorkItemManager.IsVip()
	return isVip
end

function UserInfoPage.IsSuperVip()
	if not UserInfoPage.UserData or System.options.isHideVip then
		return false
	end
	return UserInfoPage.UserData.is_vip
end

function UserInfoPage.IsVisible()
	return page and page:IsVisible()
end

function UserInfoPage.InitData()
	UserInfoPage.authUsers = {}
	UserInfoPage.CurHonor_DS = {}
	UserInfoPage.CurProject_DS = {}
	UserInfoPage.category_name = ""
	UserInfoPage.UserData = nil
	UserInfoPage.CurFriendType = FRIEND_TYPE.NORMAL
	UserInfoPage.select_project_index = -1
	local player = GameLogic.GetPlayerController():GetPlayer();
	
	UserInfoPage.mainAssets = player and player:GetMainAssetPath()
	UserInfoPage.mainSkin = player and player:GetSkin()

	-- reset to default model if current model is not default model, since we only support default model now.
	if(UserInfoPage.mainAssets ~= CustomCharItems.defaultModelFile) then
		UserInfoPage.mainAssets = CustomCharItems.defaultModelFile
		UserInfoPage.mainSkin = ""
	end
	UserInfoPage.CurBagItem_DS = UserInfoPage.GetItemData()
	UserInfoPage.CurAnimations_DS = UserInfoPage.GetAnimationData()
	SystemUserData = KeepWorkItemManager.GetProfile();
	SystemUserName = commonlib.getfield("System.User.username")
	SystemUserID = SystemUserData and SystemUserData.id or 0
	UserInfoPage.isChangeNickName = UserInfoPage.CheckHasUpdateNickName()
	UserInfoPage.search_text = ""
	UserInfoPage.select_quality_index = 1
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

function UserInfoPage.ShowView(category_name)
	Mod.WorldShare.MsgBox:Close()
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/Community/AIGC/UserInfoPage.html",
		name = "UserInfoPage.ShowView", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		cancelShowAnimation = true,
		enable_esc_key = true,
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
		UserInfoPage.OnChangeCategory(category_name)
	end,200)

	NPL.load("(gl)script/ide/System/Windows/Screen.lua");
	local Screen = commonlib.gettable("System.Windows.Screen");
	Screen:Connect("sizeChanged", UserInfoPage, UserInfoPage.OnScreenSizeChanged, "UniqueConnection")
end

function UserInfoPage.OnScreenSizeChanged()
	if not UserInfoPage.OnScreenChangeImp then
		UserInfoPage.OnScreenChangeImp = commonlib.debounce(function()
			UserInfoPage.RefreshPage()
		end, 100)
	end
	UserInfoPage.OnScreenChangeImp()
end

function UserInfoPage.OnCreate()
	UserInfoPage.UpdateSignTag() 
	UserInfoPage.UpdateUserSkin()
end

function UserInfoPage.UpdateUserSkin()
	if not page then
		return
	end
	local ctlName = "UserInfoPageMyPlayer"
	if UserInfoPage.category_name == "anim" then
		ctlName = "UserInfoPageMyPlayerAnim"
	end
	local module_ctl = page:FindControl(ctlName)
	if not module_ctl then
		return
	end
	if UserInfoPage.mainAssets and UserInfoPage.mainAssets ~= "" then
		page:CallMethod(ctlName, "SetAssetFile", UserInfoPage.mainAssets);
	end
	if UserInfoPage.mainSkin and UserInfoPage.mainSkin ~= "" then
		page:CallMethod(ctlName, "SetCustomGeosets", UserInfoPage.mainSkin)
	end
	local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
	if scene and scene:IsValid() then
		local player = scene:GetObject(module_ctl.obj_name);
		if player then
			player:SetFacing(1.57);
			player:SetField("HeadUpdownAngle", 0.2);
			player:SetField("HeadTurningAngle", 0);
			
		end
	end
end

function UserInfoPage.OnClickRotate(btnType)
	if not btnType then
		return
	end
	local rotate = btnType == "left" and -5 or 5
	local ctlName = "UserInfoPageMyPlayer"
	if UserInfoPage.category_name == "anim" then
		ctlName = "UserInfoPageMyPlayerAnim"
	end
	local module_ctl = page:FindControl(ctlName)
	if not module_ctl then
		return
	end
	local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
	if scene and scene:IsValid() then
		local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
		fRotY = fRotY+ rotate * 0.1
		scene:CameraSetEyePosByAngle(fRotY, fLiftupAngle, fCameraObjectDist);
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

function UserInfoPage.RefreshPage(delay)
	if page then
		page:Refresh(delay or 0)
	end
end

function UserInfoPage.ClosePage(bChangeSkin)
	if bChangeSkin then
		UserInfoPage.ChangePlayerSkinWhenClose()
	end
	if page then
		page:CloseWindow()
		page = nil
	end
end

function UserInfoPage.CloseInfoPage()
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

function UserInfoPage.GetRegisterTimeStr()
	if UserInfoPage.UserData then
		local dateTime = UserInfoPage.UserData.createdAt or ""
		local year, month, day = commonlib.timehelp.GetYearMonthDayFromStr(dateTime);
        local registerAt = tostring(year) .. "." .. tostring(month) .. "." .. tostring(day); 
		return registerAt
	end
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

		local filterName = BadWordFilter.FilterString2(name);
		if name ~= filterName then
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

local function GetItemIcon(item, suffix)
    local icon = item.icon;
    if(not icon or icon == "" or icon == "0") then icon = string.format("Texture/Aries/Creator/keepwork/items/item_%d%s_32bits.png", item.gsId, suffix or "") end
    return icon;
end

function UserInfoPage.OnChangeCategory(name)
	if name and name ~= "" and name ~= UserInfoPage.category_name then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_category", {category = name,useNoId=true},nil,true);
		UserInfoPage.animationIndex = -1
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
		elseif UserInfoPage.category_name == "bags" then
			KeepWorkItemManager.LoadItems(nil, function()
				UserInfoPage.CurBagItem_DS = UserInfoPage.GetItemData()
				UserInfoPage.RefreshPage()
			end)
		elseif UserInfoPage.category_name == "anim" then

			UserInfoPage.RefreshPage()
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
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_world", {worldId = worldId,useNoId=true},nil,true);
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
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_share_world", {worldId = worldId,useNoId=true},nil,true);
	end
	UserInfoPage.select_project_index = UserInfoPage.GetSelectProjectIndex(data)
	UserInfoPage.RefreshPage()
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

function UserInfoPage.GetVipIcon()
    local KpUserTag = NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/KpUserTag.lua");
	local profile = KeepWorkItemManager.GetProfile()
	local user_tag = KpUserTag.GetMcml(profile);
	return user_tag
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
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_honor", {useNoId=true},nil,true);
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
	local method = '/u/p/userData'
	local url = string.format('%s/p?url=%s&token=%s',urlbase,Mod.WorldShare.Utils.EncodeURIComponent(method),token) 
	GameLogic.RunCommand("/open "..url)
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_bind", {useNoId=true},nil,true);
end

function UserInfoPage.GetBindInfoData()
	local temp = {}
	--微信

	if UserInfoPage.IsWeixinBind() then
		temp[#temp + 1] = {key=L"微信:" , name = UserInfoPage.GetWeixinName(),isBind = true ,buttonValue = L"去解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key=L"微信:" , name = L"未绑定",isBind = false ,buttonValue=L"去绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsWeiboBind() then
		temp[#temp + 1] = {key=L"微博:" , name = UserInfoPage.GetWeiboName(),isBind = true ,buttonValue = L"去解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key=L"微博:" , name = L"未绑定",isBind = false ,buttonValue=L"去绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsQQBind() then
		temp[#temp + 1] = {key="QQ:" , name = UserInfoPage.GetQQName(),isBind = true ,buttonValue = L"去解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="QQ:" , name = L"未绑定",isBind = false ,buttonValue=L"去绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsGithubBind() then
		temp[#temp + 1] = {key="GitHub:" , name = UserInfoPage.GetGithubName(),isBind = true ,buttonValue = L"去解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key="GitHub:" ,name = L"未绑定", isBind = false ,buttonValue=L"去绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsEmailBind() then
		temp[#temp + 1] = {key=L"邮箱:" , name = UserInfoPage.GetEmailName(),isBind = true ,buttonValue = L"去解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key=L"邮箱:" ,name = L"未绑定", isBind = false ,buttonValue=L"去绑定" ,buttonName="2"}
	end

	if UserInfoPage.IsMobilePhoneBind() then
		temp[#temp + 1] = {key=L"手机:" , name = UserInfoPage.GetMobilePhoneName(),isBind = true ,buttonValue = L"去解绑" ,buttonName="1"}
	else
		temp[#temp + 1] = {key=L"手机:" ,name = L"未绑定", isBind = false ,buttonValue=L"去绑定" ,buttonName="2"}
	end
	return temp
end

function UserInfoPage.GetBindInfoStyle()
	local maxWidth = 0
	for k,v in ipairs(UserInfoPage.GetBindInfoData()) do
		local name = v.name or ""
		local width = _guihelper.GetTextWidth(name, "System;12;norm")
		if (width > maxWidth) then
			maxWidth = width
		end
	end
	local  style = string.format("float: left; margin-left: 130px; margin-top: 0px;width: %d px",maxWidth + 20)
	return style
end

function UserInfoPage.RemoveAccount()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_remove_account", {useNoId=true},nil,true);
	local RemoveAccount = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/RemoveAccount.lua")
     RemoveAccount.ShowPage()
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
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.user_page.click_update_password", {useNoId=true},nil,true);
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

function UserInfoPage.SetPlayerSkin(skin,oldSkin)
	if not UserInfoPage.IsVisible() then
		return
	end
	if not skin or skin == "" or  UserInfoPage.mainSkin == skin then
		return
	end
	UserInfoPage.preSkin = oldSkin
	UserInfoPage.mainSkin = skin
	UserInfoPage.UpdateUserSkin()
end

function UserInfoPage.ChangePlayerSkinWhenClose()
	if not UserInfoPage.IsAuthUser() or UserInfoPage.category_name ~= "skin" then
		return 
	end
	local skin = CustomCharItems:ChangeSkinStringToItems(UserInfoPage.mainSkin)
	if skin and skin ~= "" then
		UserInfoPage.mainSkin = SkinManager.RemoveAllUnvalidItems(skin)
	end
	local isNeedRemove = false
	if skin and skin ~= "" and skin ~= UserInfoPage.mainSkin then
		isNeedRemove = true
	end
	if isNeedRemove and UserInfoPage.preSkin and UserInfoPage.preSkin ~= "" 
		and UserInfoPage.preSkin ~= UserInfoPage.mainSkin then
		UserInfoPage.mainSkin = UserInfoPage.preSkin
		UserInfoPage.preSkin = ""
	end
	UserInfoPage.UpdatePlayerEntityInfo()
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
    keepwork.user.setinfo({
        router_params = {id = UserInfoPage.UserData.id},
        extra = extra,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then return echo("更新玩家实体信息失败") end
        local userinfo = KeepWorkItemManager.GetProfile();
        userinfo.extra = extra;
    end);
end

function UserInfoPage.AddVirtualBagItem(item,bagType,callback)
	SkinManager.GetBagManager().AddItem(bagType, item, nil, function(result, msg)
		if not result then
			_guihelper.MessageBox(L"添加虚拟背包物品失败:"..(msg or ""));
			return
		end
		if callback and type(callback) == "function" then
			callback(result, msg)
		end
	end)
end

function UserInfoPage.GetActivityName(gsid)
    local template = KeepWorkItemManager.GetItemTemplate(gsid);
    if (template and template.desc) then
        return template.desc;
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

function UserInfoPage.CopyUserID()
	if UserInfoPage.UserData then
		local userId = UserInfoPage.UserData.id
		if userId then
			ParaMisc.CopyTextToClipboard(tostring(userId))
			GameLogic.AddBBS(nil,"用户ID已复制到剪贴板")
		end
	end
end

function UserInfoPage.GetUserId()
	if UserInfoPage.UserData then
		return tostring(UserInfoPage.UserData.id)
	end
	return ""
end

function UserInfoPage.OnMouseEnterImp(index,isBg,isPreview)
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

function UserInfoPage.OnMouseLeaveImp(index,isBg,isPreview)
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

function UserInfoPage.OnBgMouseEnter(index)
    UserInfoPage.OnMouseEnterImp(index,true)
end

function UserInfoPage.OnBgMouseLeave(index)
    UserInfoPage.OnMouseLeaveImp(index,true)
end

function UserInfoPage.OnPreviewMouseEnter(index)
    UserInfoPage.OnMouseEnterImp(index,false,true)
end

function UserInfoPage.OnPreviewMouseLeave(index)
    UserInfoPage.OnMouseLeaveImp(index,false,true)
end

function UserInfoPage.ClickFirend()
	local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
	FriendsPage.Show();
end

function UserInfoPage.ClickSign()
	UserInfoPage.OnCheckinToday() 
end

function UserInfoPage.UpdateSignTag() --红点
	local signTagNode = ParaUI.GetUIObject("sign_notice")
	if signTagNode and signTagNode:IsValid() then
		if UserInfoPage.HasCheckedToday() then
			signTagNode.visible = false
		else
			signTagNode.visible = true
		end
	end
end

-- 签到
local sign_gsid = 40004; -- 存储数据
local exchange_beans_list = {{11001,10},{11002,20},{11003,30},{31001,80},{11004,100}}
function UserInfoPage.OnCheckinToday() --签到
    if UserInfoPage.HasCheckedToday() and not System.options.isInternal then
        GameLogic.AddBBS(nil,"今天已经签到过了")
        return
	end
	math.randomseed(os.time())
	local signIndex = math.random(1, #exchange_beans_list);
	local exchanges = exchange_beans_list[signIndex];
	KeepWorkItemManager.DoExtendedCost(exchanges[1], function()
		local beanNum = exchanges[2];
		GameLogic.AddBBS(nil,"签到成功，获得"..beanNum.."知识豆")
		UserInfoPage.SaveToLocal(function()
			UserInfoPage.RefreshPage()
		end)
	end, function (err,msg,data)
		GameLogic.AddBBS(nil,"签到失败，"..err.."，请重试")
	end)
end

function UserInfoPage.GetCheckKey()
	if System.options.isDevMode then
		return ParaGlobal.GetDateFormat("yyyy-M-d");
	end
	local timp_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
	return os.date('%Y-%m-%d',timp_stamp)
end

function UserInfoPage.HasCheckedToday()
	local date = UserInfoPage.GetCheckKey()
	local key = string.format("UserInfo_HasCheckedToday_%s", date);
	local clientData = KeepWorkItemManager.GetClientData(sign_gsid) or {};
	return clientData[key];
end

function UserInfoPage.SaveToLocal(callback)
	local date = UserInfoPage.GetCheckKey()
	local key = string.format("UserInfo_HasCheckedToday_%s", date);
	local clientData = KeepWorkItemManager.GetClientData(sign_gsid) or {};
	clientData[key] = true;
    for k, v in pairs(clientData) do
		if(k ~= key and k:find("UserInfo_HasCheckedToday_")) then
			clientData[k] = nil; -- clear other days
        end
	end
	
	KeepWorkItemManager.SetClientData(sign_gsid, clientData, callback)
end

--自定义角色电影动画
function UserInfoPage.GetAnimationData()
	local allAnimations = PlayerAssetFile:GetAllAnimations()
	if not allAnimations or #allAnimations == 0 then
		return {}
	end
	for k, v in pairs(allAnimations) do
		local isInBag = SkinManager.GetUnLockManager().IsUnlocked(v.id)
		if v and v.id and isInBag then
			v.has = 1
		else
			v.has = 0
		end
		if v.isFree then
			v.isFree = tonumber(v.isFree) or 0
		else
			v.isFree = 0
		end
		if v.isVipFree then
			v.isVipFree = tonumber(v.isVipFree) or 0
		else
			v.isVipFree = 0
		end
	end
	return allAnimations
end

function UserInfoPage.CheckAnimSelected(name)
	if not name or not UserInfoPage.CurAnimations_DS then
		return false
	end
	local index = tonumber(name)
	if index and UserInfoPage.CurAnimations_DS[index] then
		if UserInfoPage.animationIndex and UserInfoPage.animationIndex == index then
			return true
		end
	end
	return false
end

function UserInfoPage.PurchaseAnimItem(name, mcmlNode)
	local param1 = mcmlNode:GetAttribute("param1")
	if not param1 then
		_guihelper.MessageBox(L"购买动作失败，参数错误，请稍后再试");
		return
	end
	local item = param1
	local canUnlock, reason = SkinManager.GetUnLockManager().CanUnlock(item.id)
	if not canUnlock then
		if reason and reason ~= "" then
			_guihelper.MessageBox(reason);
		else
			_guihelper.MessageBox(L"购买动作失败，不满足解锁条件，请稍后再试");
		end
		return
	end
	local BuyConfirm = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/AIGC/BuyConfirm.lua")
    BuyConfirm.ShowPage(item,function(result)
		if result then
			SkinManager.PurchaseSingleSkin(item,function(result,msg)
				if result and result == true then
					GameLogic.AddBBS(nil,L"恭喜你，解锁动作成功:"..item.name)
					SkinManager.GetUnLockManager().UnlockSkin(item.id, item.category)
					UserInfoPage.CurAnimations_DS = UserInfoPage.GetAnimationData()
					UserInfoPage.RefreshPage()
				else
					if msg and msg ~= "" then
						_guihelper.MessageBox(msg);
					end
				end
			end)
		end
	end)
end


function UserInfoPage.CheckShowBuyBtn(name)
	if not name or not UserInfoPage.CurAnimations_DS then
		return false
	end
	local index = tonumber(name)
	if index and UserInfoPage.CurAnimations_DS[index] then
		local animData = UserInfoPage.CurAnimations_DS[index]
		if not animData then
			return false
		end
		if animData.has and tonumber(animData.has) == 1 then
			return false
		end
		if animData and animData.isFree == 1 then
			return false
		end
		if animData and animData.isVipFree == 1 and UserInfoPage.IsCommonVip() then
			return false
		end
	end
	return true
end

function UserInfoPage.OnClickAnimation(name)
	local index = tonumber(name)
	if index and UserInfoPage.CurAnimations_DS[index] then
		UserInfoPage.animationIndex = index
		local animData = UserInfoPage.CurAnimations_DS[index]
		UserInfoPage.RefreshPage()
		UserInfoPage.PlayUIMoviefile(animData)
	end
end

function UserInfoPage.PlayUIMoviefile(animData)
	if not animData then
		return
	end
	local animation_ctl = page:FindControl("UserAnimCanvas")
	if not animation_ctl then
		return
	end
	local module_ctl = page:FindControl("UserInfoPageMyPlayerAnim")
	if module_ctl then
		module_ctl:Show(false)
	end
	local filename = animData.filename
	local animId = tonumber(animData.id)
	local loop_start = animData.loop_start
	local loop_end = animData.loop_end
	animation_ctl:StopMovie("UserAnimCanvasScene")
	CommonCtrl.FileLoader.AsyncLoadAsset(filename, function(bSuccess, filepath)
		if bSuccess and filepath then
			animation_ctl:PlayMovieFile(filepath, 0, -1, 0, 128, 0, false, {skin = UserInfoPage.mainSkin,facing= 1.57})
		end
	end)

	GameLogic.GetFilters():add_filter("Canvas3DMovieEnd",  UserInfoPage.Cavasas3DMovieEnd);
end

function UserInfoPage.Cavasas3DMovieEnd(channelName, resourceName)
	if UserInfoPage.animationIndex and page then
		local animData = UserInfoPage.CurAnimations_DS[UserInfoPage.animationIndex]
		local animation_ctl = page:FindControl("UserAnimCanvas")
		if not animation_ctl or not animData then
			return
		end
		local loop_start = tonumber(animData.loop_start)
		local loop_end = tonumber(animData.loop_end)
		if loop_start and loop_end then
			animation_ctl:PlayMovie(loop_start, loop_end)
		end
	end
	return channelName, resourceName
end

function UserInfoPage.OnClickNewWorld()
	local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
    CreateWorld:CreateNewWorld(nil, function()
        UserInfoPage.RefreshPage(0.01)
    end)
end