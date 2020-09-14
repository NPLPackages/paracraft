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
local FollowList = {}
local SearchIdList = {}

function AddFriendsPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = AddFriendsPage.CloseView
end

function AddFriendsPage.Show(user_data)
    UserData = user_data

    local att = ParaEngine.GetAttributeObject();
    local oldsize = att:GetField("ScreenResolution", {1280,720});

    local standard_width = 1280
    local standard_height = 720
    local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/Friend/AddFriendsPage.html",
            name = "AddFriendsPage.Show", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = true,
            enable_esc_key = true,
            zorder = -1,
            app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
            directPosition = true,
            
            align = "_lt",
            x = oldsize[1]/2 - 560/2,
            y = oldsize[2]/2 - 207/2,
            width = 560,
            height = 207,
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
        GameLogic.AddBBS("statusBar", L"请输入对方账号", 5000, "0 255 0");
        return
    end

    local search_text = "%" .. text .. "%"
	keepwork.user.search({
        ["$or"] = {username = {["$like"]=search_text}, cellphone = text}
	},function(search_err, search_msg, search_data)
        commonlib.echo(search_data, true)

        SearchIdList = {}
        local index = 0
        for k, v in pairs(search_data.rows) do
            SearchIdList[#SearchIdList + 1] = v.id
        end

        local function updata_cb()
            AddFriendsPage.Current_Item_DS = search_data.rows
            AddFriendsPage.OnRefresh()
        end

        if #search_data.rows == 0 then
            GameLogic.AddBBS("statusBar", L"没有找到符合搜索条件的用户", 5000, "0 255 0");
            updata_cb()
            return
        end

        AddFriendsPage.UpdataFoucsList(updata_cb)
	end)
end

function AddFriendsPage.ToFollow(userId)
    if AddFriendsPage.IsFollow(userId) then
        AddFriendsPage.OnCancelFollow(userId)
        return
    end
    print("AddFriendsPage.ToFollow", userId)
	-- userId = 176382
	keepwork.user.follow({
		objectType = 0,
		objectId = userId,
	},function(err, msg, data)
		print("dwwwwwwwwwwwwwwwFriendsPage.Follow", err, msg)
        commonlib.echo(data, true)
        GameLogic.AddBBS("statusBar", L"已向对方发出好友请求，请耐心等待回复。", 5000, "0 255 0");

        local function updata_cb()
            AddFriendsPage.OnRefresh()
        end
        AddFriendsPage.UpdataFoucsList(updata_cb)

        -- 刷新好友界面
        local friend_page = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        local is_open = friend_page.GetIsOpen()
        if is_open then
            friend_page.FlushCurDataAndView()
        end
	end)
end

function AddFriendsPage.OnCancelFollow(userId)
    local chat_user_data = FriendChatPage.GetCurChatUesrData()
	if userId == chat_user_data.id then
		GameLogic.AddBBS("statusBar", L"您与对方正在聊天中，请先关闭聊天窗口", 5000, "0 255 0");
		return
    end
    
	local show_text = "你确定要取消关注吗？\n取消关注后对方将不在好友列表中，且以后不再接收此人的会话消息。"
	_guihelper.MessageBox(show_text, function()
		AddFriendsPage.UnFollow(userId)
	end)
end

function AddFriendsPage.UnFollow(userId)
	-- userId = 176382
	keepwork.user.unfollow({
		objectType = 0,
		objectId = userId,
	},function(err, msg, data)
		-- commonlib.echo(data, true)
		if err == 200 then
			GameLogic.AddBBS("statusBar", L"取消关注成功", 5000, "0 255 0");
            local function updata_cb()
                AddFriendsPage.OnRefresh()
            end
            AddFriendsPage.UpdataFoucsList(updata_cb)
    
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

-- 我是否已经关注了某人 id 某人的id
function AddFriendsPage.IsFollow(id)
    if FollowList[id] then
        return true
    end

    return false
end

function AddFriendsPage.GetFansBtText(data)
    local is_follow = AddFriendsPage.IsFollow(data.id)
    if is_follow then
		return "已关注"
    end
	
	return "关注"
end
function AddFriendsPage.UpdataFoucsList(updata_cb)
    keepwork.user.focus({
        userId = UserData.id,
        objectType = 0,
        objectId = {["$in"] = SearchIdList},
    },function(err, msg, data)
        print("获取关注列表结果", err, msg)
        commonlib.echo(data, true)
        FollowList = {}
        for k, v in pairs(data.rows) do
            FollowList[v.objectId] = v
        end

        if updata_cb then
            updata_cb()
        end
    end)
end

function AddFriendsPage.CloseView()
    print("AddFriendsPage.CloseView()")
    AddFriendsPage.ClearData()
end

function AddFriendsPage.ClearData()
    AddFriendsPage.Current_Item_DS = {}
    UserData = {}
    FollowList = {}
    SearchIdList = {}
end