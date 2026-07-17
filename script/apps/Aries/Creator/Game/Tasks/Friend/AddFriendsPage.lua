--[[
Title: AddFriendsPage
Author(s): yangguiyi
Date: 2020/9/2
Desc:  
Use Lib:
-------------------------------------------------------
local AddFriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/AddFriendsPage.lua");
AddFriendsPage.Show();
--]]

local AddFriendsPage = NPL.export();
local FriendChatPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendChatPage.lua");
local page;
local DateTool = os.date
AddFriendsPage.Current_Item_DS = {};
local UserData = {}
local FriendList = {}
local SearchIdList = {}

function AddFriendsPage.OnInit()
    page = document:GetPageCtrl();
end

function AddFriendsPage.GetSafeLeft()
	local safeArea = System.Windows.Screen:GetSafeAreaLeft()
	if safeArea > 0 then
		return safeArea + 10
	end
	return 0
end

function AddFriendsPage.Show(user_data)
    UserData = user_data

    local att = ParaEngine.GetAttributeObject();

    local standard_width = 1280
    local standard_height = 720
    local view_width = 560
    local view_height = 207
    local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/Friend/AddFriendsPage.html",
            name = "AddFriendsPage.Show", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = true,
            enable_esc_key = true,
            --app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
            directPosition = true,
            zorder = 1,
            align = "_ct",
            x = - view_width/2 + AddFriendsPage.GetSafeLeft(),
            y = - view_height,
            width = view_width,
            height = view_height,
        };
        
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function AddFriendsPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function AddFriendsPage.SearchFriend(text)

    if text == nil or text == "" then
        GameLogic.AddBBS("statusBar", L"请输入对方账号信息", 5000, "0 255 0");
        return
    end
    local id = tonumber(text)
    if not id or id == 0 then
        GameLogic.AddBBS("statusBar", L"请输入正确的用户ID，可前往商城页面查看", 5000, "0 255 0");
        return
    end
    AddFriendsPage.Current_Item_DS = {}
	keepwork.user.getUsersByIds({
        ids = {id},
	},function(search_err, search_msg, search_data)
        if search_err ~= 200 or not search_data then
            GameLogic.AddBBS("statusBar", L"没有找到符合搜索条件的用户", 5000, "0 255 0");
            return
        end
        SearchIdList = {}
        local index = 0
        for k, v in pairs(search_data) do
            SearchIdList[#SearchIdList + 1] = v.id
        end

        if #search_data == 0 then
            GameLogic.AddBBS("statusBar", L"没有找到符合搜索条件的用户", 5000, "0 255 0");
            AddFriendsPage.Current_Item_DS = {}
            AddFriendsPage.OnRefresh()
            return
        end
        local search_data = search_data[1]
        local userId = search_data.id
        AddFriendsPage.GetUserInfo(userId,function(user_info)
            if user_info and type(user_info) == "table" then
                AddFriendsPage.Current_Item_DS[#AddFriendsPage.Current_Item_DS + 1] = user_info
            end
            AddFriendsPage.UpdataFriendList(function()
                AddFriendsPage.OnRefresh()
            end)
        end)
	end)
end

function AddFriendsPage.GetUserInfo(userId,callback)
    NPL.load("(gl)script/ide/System/Encoding/base64.lua");
	local Encoding = commonlib.gettable("System.Encoding");
	local id = "kp" .. Encoding.base64(commonlib.Json.Encode({userId=userId}));
	keepwork.user.getinfo({
		cache_policy = "access plus 0",
        router_params = {
            id = id,
        }
    },function (err, msg, data)
		if err == 200 then
			if callback and type(callback) == "function" then
				callback(data)
			end
			return
		end
		if callback and type(callback) == "function" then
			callback()
		end
	end)
end

function AddFriendsPage.ToBeFriend(userId)
    local my_userId = Mod.WorldShare.Store:Get("user/userId")
    if userId and my_userId == userId then
        GameLogic.AddBBS("statusBar", L"不能添加自己为好友", 5000, "0 255 0");
        return
    end
    if AddFriendsPage.IsFriend(userId) then
        AddFriendsPage.OnDeleteFriend(userId)
        return
    end
	-- userId = 176382
	keepwork.friend.applyFriend({
		friendId = userId,
		remark = "希望成为您的好友",
	},function(err, msg, data)
		-- print("dwwwwwwwwwwwwwwwFriendsPage.Follow", err, msg)
        -- commonlib.echo(data, true)
        GameLogic.AddBBS("statusBar", L"已向对方发出好友请求，请耐心等待回复。", 5000, "0 255 0");

        local function updata_cb()
            AddFriendsPage.OnRefresh()
        end
        AddFriendsPage.UpdataFriendList(updata_cb)

        -- 刷新好友界面
        local friend_page = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        local is_open = friend_page.GetIsOpen()
        if is_open then
            friend_page.FlushCurDataAndView()
        end
	end)
end

function AddFriendsPage.OnDeleteFriend(userId)
    local chat_user_data = FriendChatPage.GetCurChatUesrData()
	if userId == chat_user_data.id then
		GameLogic.AddBBS("statusBar", L"您与对方正在聊天中，请先关闭聊天窗口", 5000, "0 255 0");
		return
    end
    
	local show_text = "你确定要删除好友吗？\n删除好友后对方将不在好友列表中，且以后不再接收此人的会话消息。"
	_guihelper.MessageBox(show_text, function()
		AddFriendsPage.DeleteFriend(userId)
	end)
end

function AddFriendsPage.DeleteFriend(userId)
	-- userId = 176382
	keepwork.friend.deleteFriend({
		router_params = {
            friendId = userId,
        }
	},function(err, msg, data)
		-- commonlib.echo(data, true)
		if err == 200 then
			GameLogic.AddBBS("statusBar", L"删除好友成功", 5000, "0 255 0");
            local function updata_cb()
                AddFriendsPage.OnRefresh()
            end
            AddFriendsPage.UpdataFriendList(updata_cb)
    
            -- 刷新好友界面
            local friend_page = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
            local is_open = friend_page.GetIsOpen()
            if is_open then
                friend_page.FlushCurDataAndView()
            end

			if FriendChatPage.IsOpen then
				FriendChatPage.FlushCurDataAndView()
			end
		end
	end)
end

function AddFriendsPage.GetIcon(data)
	if data.portrait and data.portrait ~= "" then
        return data.portrait
    end

    return "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png"
end

-- 我是否是某人的好友
function AddFriendsPage.IsFriend(id)
    if FriendList[id] then
        return true
    end

    return false
end

function AddFriendsPage.GetFriendBtText(data)
    -- echo(data)
    print("AddFriendsPage.GetFriendBtText")
    local is_follow = AddFriendsPage.IsFriend(data.id)
    if is_follow then
		return "删除好友"
    end
	
	return "添加好友"
end
function AddFriendsPage.UpdataFriendList(updata_cb)
    keepwork.friend.friendsList({
        objectType = 0,
        objectId = {["$in"] = SearchIdList},
    },function(err, msg, data)
        print("获取好友列表结果", err, msg)
        -- commonlib.echo(data, true)
        FriendList = {}
        if(data) then
            for k, v in pairs(data) do
                if v.status == 1 then --当status不为1时，表示该好友已删除
                    FriendList[v.friendId] = v
                end
            end
        end

        if updata_cb then
            updata_cb()
        end
    end)
end

function AddFriendsPage.CloseView()
    AddFriendsPage.ClearData()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function AddFriendsPage.ClearData()
    AddFriendsPage.Current_Item_DS = {}
    UserData = {}
    FriendList = {}
    SearchIdList = {}
end