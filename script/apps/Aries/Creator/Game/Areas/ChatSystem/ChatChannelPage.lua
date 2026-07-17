--[[
Title: ChatChannelPage
Author(s): 
Date: 2024/11/14
Desc:  
Use Lib:
-------------------------------------------------------
--频道聊天界面
local ChatChannelPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatChannelPage.lua");
ChatChannelPage.ShowPage()
--]]
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local ChatManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatManager.lua");
local FriendChatPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendChatPage.lua");
local ChatChannelPage = NPL.export()
local page
local isRegisterEvent = false
local baseTexturePath = "Texture/Aries/Creator/keepwork/Community/community_chat_32bits.png#"
local chatChanels = {
    Local ={text=L"地图", name="Local" , icon= baseTexturePath.."168 100 20 20", icon1= baseTexturePath.."192 100 20 20", chanel =ChatChannel.EnumChannels.KpNearBy},
    Private ={text=L"私聊", name="Private" , icon= baseTexturePath.."206 72 20 20", icon1= baseTexturePath.."198 178 20 20", chanel =ChatChannel.EnumChannels.KpPrivate}, -- "KpPrivate" 27
    Blacklist ={text=L"黑名单", name="Blacklist" , icon= baseTexturePath.."186 124 20 20", icon1= baseTexturePath.."210 124 20 20" , chanel = -1},
    Team ={text=L"组队", name="Team" , icon= baseTexturePath.."196 46 22 20", icon1= baseTexturePath.."158 126 22 20", chanel = ChatChannel.EnumChannels.KpTeam},
}
ChatChannelPage.chatChanels = {}
local ChatUserData
ChatChannelPage.selectedPrivateUserIndex = -1
ChatChannelPage.selectedChatChanelIndex = -1
ChatChannelPage.privateUsers = {}
ChatChannelPage.tempPrivateUsers = {}
ChatChannelPage.members = {}
ChatChannelPage.privateChatData = {}

ChatChannelPage.privateSearchText = ""
ChatChannelPage.blacklistSearchText = ""
ChatChannelPage.groupchatInputText = ""
ChatChannelPage.privatechatInputText = ""


function ChatChannelPage.OnInit()
    page = document:GetPageCtrl()
    page.OnCreate = ChatChannelPage.OnCreate
end

function ChatChannelPage.ShowPage(chatChanel)
    GameLogic.CheckSignedIn(L"请登录", function(result)
        if result then
            ChatChannelPage.RegisterEvent()
            ChatChannelPage.InitChatChannel()
            ChatChannelPage.OnShow()
        end
    end)
end

function ChatChannelPage.CloseSmiley()
    local NewSmileyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/NewSmileyPage.lua");
    NewSmileyPage.ClosePage()
end

function ChatChannelPage.OnShow()
    ChatUserData = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua").GetProfile()
    local params = {
		url = "script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatChannelPage.html", 
		name = "ChatChannelPage.ShowPage", 
		app_key=MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1,
		enable_esc_key = true,
		isTopLevel = false,
		allowDrag = false,
		directPosition = true,
        cancelShowAnimation = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
	};

    -- ChatChannelPage.mytimer = ChatChannelPage.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
	-- 	local x, y = ParaUI.GetMousePosition();
	-- 	local temp = ParaUI.GetUIObjectAtPoint(x, y);
	-- 	print("xxxxxxxxxxxxxxxx",temp.name,temp.id,temp.uiname,temp.parent.name,temp.parent.id,temp.parent.uiname,x, y)
	-- end})
	-- ChatChannelPage.mytimer:Change(0, 200);

	System.App.Commands.Call("File.MCMLWindowFrame", params);
    ChatChannelPage.CloseSmiley()
    ChatChannelPage.ChangeChanelTabview(1)
end

function ChatChannelPage.InitChatChannel(isJoinWorld)
    ChatChannelPage.selectedChatChanelIndex = -1
    ChatChannelPage.selectedPrivateUserIndex = -1
    ChatChannelPage.privateUsers = {}
    ChatChannelPage.members = {}
    ChatChannelPage.privateChatData = {}
    ChatChannelPage.isShowMemberList = false
    ChatChannelPage.blackList = {}
    ChatChannelPage.isAddBlackList = {}
    ChatChannelPage.chatChanels = {}
    local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
    if KpChatChannel.IsInWorld() and KpChatChannel.worldId_pending > 0 then
        ChatChannelPage.chatChanels[#ChatChannelPage.chatChanels +1] = chatChanels.Local
    end
    ChatChannelPage.chatChanels[#ChatChannelPage.chatChanels +1] = chatChanels.Private
    ChatChannelPage.chatChanels[#ChatChannelPage.chatChanels +1] = chatChanels.Blacklist
    if ChatManager.HasJoinedTeam() then
        ChatChannelPage.chatChanels[#ChatChannelPage.chatChanels +1] = chatChanels.Team
    end
end

function ChatChannelPage.SetTextAfterRefresh()
    if not page then
        return
    end
    if ChatChannelPage.privateSearchText and ChatChannelPage.privateSearchText ~= "" then
        page:SetValue("private_search_content", ChatChannelPage.privateSearchText)
    end
    if ChatChannelPage.blacklistSearchText and ChatChannelPage.blacklistSearchText ~= "" then
        page:SetValue("blacklist_search_content", ChatChannelPage.blacklistSearchText)
    end
    if ChatChannelPage.groupchatInputText and ChatChannelPage.groupchatInputText ~= "" then
        page:SetValue("group_chat_words", ChatChannelPage.groupchatInputText)
    end
    if ChatChannelPage.privatechatInputText and ChatChannelPage.privatechatInputText ~= "" then
        page:SetValue("private_chat_words", ChatChannelPage.privatechatInputText)
    end
end

function ChatChannelPage.RegisterEvent()
    if not isRegisterEvent then
        GameLogic.GetFilters():remove_filter("send_world_msg", ChatChannelPage.OnResolveWorldMsg); --加入世界频道
	    GameLogic.GetFilters():add_filter("send_world_msg", ChatChannelPage.OnResolveWorldMsg)

        Screen:Connect("sizeChanged", ChatChannelPage, ChatChannelPage.RefreshPage, "UniqueConnection");
        
        GameLogic.GetFilters():remove_filter("process_chat_msg", ChatChannelPage.OnProcessMsg);
	    GameLogic.GetFilters():add_filter("process_chat_msg", ChatChannelPage.OnProcessMsg)

        GameLogic:Disconnect("WorldLoaded", ChatChannelPage, ChatChannelPage.OnWorldLoaded, "UniqueConnection");
        GameLogic:Connect("WorldLoaded", ChatChannelPage, ChatChannelPage.OnWorldLoaded, "UniqueConnection");

        isRegisterEvent = true
    end
end

function ChatChannelPage.GetChatContentHeight()
    local Screen = commonlib.gettable("System.Windows.Screen")
    local height = Screen:GetHeight()
    height = height - 56*2
    return height
end

function ChatChannelPage.OnWorldLoaded()
    ChatChannelPage.tempPrivateUsers = {}
end

function ChatChannelPage.ChangeChanelTabview(name,chat_user_id)
    local index = tonumber(name)
    if not index then
        return
    end
    if index == ChatChannelPage.selectedChatChanelIndex then
        return
    end
    ChatChannelPage.ClearInputText()
    ChatChannelPage.isShowMemberList = false
    ChatChannelPage.selectedChatChanelIndex = index
    ChatChannelPage.selectedPrivateUserIndex = -1
    if ChatChannelPage.IsSelectBlackListMenu() then
        ChatChannelPage.LoadBlackList(function()
            ChatChannelPage.RefreshPage()
        end)
    elseif ChatChannelPage.IsSelectPrivateMenu() then
        ChatChannelPage.LoadPrivateUsers(chat_user_id)
    else
        ChatChannelPage.LoadChannelUsers()
    end
    ChatChannelPage.RefreshPage()
end

function ChatChannelPage.ChangeChannelTab(channelName,private_chat_user_id)
    if not channelName or channelName == "" then
        return
    end
    for i, channel in ipairs(ChatChannelPage.chatChanels) do
        if channel.name == channelName then
            local is_private = (channel.name == "Private")
            ChatChannelPage.ChangeChanelTabview(i,is_private and private_chat_user_id or nil)
            break
        end
    end
end

function ChatChannelPage.ClearInputText()
    ChatChannelPage.privateSearchText = ""
    ChatChannelPage.blacklistSearchText = ""
    ChatChannelPage.groupchatInputText = ""
    ChatChannelPage.privatechatInputText = ""
end

function ChatChannelPage.IsSelectBlackListMenu()
    local channel = ChatChannelPage.GetSelectedChatChanel()
    return channel and channel.name == "Blacklist"
end

function ChatChannelPage.IsSelectPrivateMenu()
    local channel = ChatChannelPage.GetSelectedChatChanel()
    return channel and channel.name == "Private"
end

function ChatChannelPage.GetSelectedChatChanel()
    local index = ChatChannelPage.selectedChatChanelIndex
    if not index then
        return nil
    end
    local channel = ChatChannelPage.chatChanels[index]
    if not channel then
        return nil
    end
    return channel
end

function ChatChannelPage.GetChannelByName(name)
    for i, channel in ipairs(ChatChannelPage.chatChanels) do
        if channel.name == name then
            return channel
        end
    end
    return nil
end

function ChatChannelPage.OnResolveWorldMsg(result)
    ChatChannelPage.InitChatChannel()
    ChatChannelPage.RefreshPage()
    return result
end

function ChatChannelPage.RefreshPage()
    if not page then
        return
    end
    print("RefreshPage")
    page:Refresh(0)
end

function ChatChannelPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
    ChatChannelPage.CloseSmiley()
end

function ChatChannelPage.IsVisible()
    return page and page:IsVisible()
end


function ChatChannelPage.HandleMsgData(msgData)
    if not msgData then
        return
    end

    if msgData.ChannelIndex ~= 21 then
        return msgData
    end
    local my_userId = Mod.WorldShare.Store:Get("user/userId")
    local temp = {
        ChannelIndex=21,
        channelname="本地",
        color="ffffff",
        is_keepwork=true,
        chatContent = msgData.words,
        userId = msgData.kp_from_id,
        username = msgData.kp_username,
        nickname = msgData.kp_from_name,
        vip = msgData.vip,
    }
    if msgData.userId == my_userId then
        temp.ifmyself = true
    else
        temp.ifmyself = false
    end
    return temp
end

function ChatChannelPage.OnProcessMsg(msgdata)
    echo("ChatChannelPage.OnProcessMsg==========")
    -- echo(msgdata,true)
    if ChatChannelPage.IsVisible() then
        if ChatChannelPage.IsSelectBlackListMenu() then
            -- ChatChannelPage.LoadBlackList(function()
            --     ChatChannelPage.RefreshPage()
            -- end)
        elseif ChatChannelPage.IsSelectPrivateMenu() then
            ChatChannelPage.LoadPrivateUsers()
        else
            ChatChannelPage.LoadChannelUsers()
        end
        ChatChannelPage.RefreshPage()
    end
    return msgdata
end

function ChatChannelPage.IsShowPrivateChatContent()
    if not ChatChannelPage.IsSelectPrivateMenu() then
        return false
    end
    if ChatChannelPage.selectedPrivateUserIndex == -1 then
        return false
    end
    local index = ChatChannelPage.selectedPrivateUserIndex
    if not index or index < 1 or index > #ChatChannelPage.privateUsers or not ChatChannelPage.privateUsers[index] then
        return false
    end
    return true
end

function ChatChannelPage.GetRoomByChannel()
    local channel = ChatChannelPage.GetSelectedChatChanel()
    if not channel then
        return nil
    end
    if channel.name == "Local" then
        return NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua").GetRoom()
    end
    if channel.name == "Team" then
        return ChatManager.GetTeamRoom()
    end
end

function ChatChannelPage.GetChatData(select_chanel)
    local channel = select_chanel or ChatChannelPage.GetSelectedChatChanel()
    if not channel then
        return {}
    end
    local chatData = ChatManager.GetChatDataByChannel(channel.chanel)
    return chatData
end

function ChatChannelPage.GetChannelName()
    local channel = ChatChannelPage.GetSelectedChatChanel()
    if not channel then
        return ""
    end
    return channel.name
end

function ChatChannelPage.LoadChannelChatData() --本地和组队
    local chatData = ChatChannelPage.GetChatData()
    if not chatData then
        return
    end
    local channelName = ChatChannelPage.GetChannelName()
    local tempChatData = {}
    local my_userId = Mod.WorldShare.Store:Get("user/userId")
    for _, data in ipairs(chatData) do
        if channelName == "Local" then
            data = ChatChannelPage.HandleMsgData(data)
        end
        data.ifmyself = (data.userId == my_userId)
        table.insert(tempChatData, data)
    end
    ChatChannelPage.groupChatData = tempChatData
    ChatChannelPage.RefreshPage()
end

function ChatChannelPage.IsShowMemberList()
    return ChatChannelPage.isShowMemberList
end 

function ChatChannelPage.OnChangeMemberListStatus()
    ChatChannelPage.isShowMemberList = not ChatChannelPage.isShowMemberList
    ChatChannelPage.RefreshPage()
end

function ChatChannelPage.GetGroupChatData()
    return ChatChannelPage.groupChatData
end

function ChatChannelPage.LoadChannelUsers() --组队和本地
    local roomName = ChatChannelPage.GetRoomByChannel()
    print("LoadChannelUsers ===roomName==========",roomName)
    if not roomName then
        return
    end
    keepwork.chat.roomMembers({
        room = roomName, 
     },function(err,msg,data)
         print("roomMembers=========",err)
         if(err ~= 200 or not data)then
             LOG.std(nil,"info","ChatChannelPage","加载成员失败,房间名称是"..(roomName or "")..",错误码是"..(err or ""))
            --  echo(data)
             return
         end
        --  echo(data,true)
         print("加载成员成功")
         ChatChannelPage.members = data;

        local loadFunc = nil
        loadFunc = function(index)
            if index > #ChatChannelPage.members then
                print("加载群聊用户数据完成=============")
                -- echo(ChatChannelPage.members, true)
                ChatChannelPage.LoadChannelChatData()
                ChatChannelPage.RefreshPage()
                return 
            end
            if not ChatChannelPage.members[index] or ChatChannelPage.members[index].userInfo ~= nil then
                index = index + 1
                loadFunc(index)
            else
                local userId = ChatChannelPage.members[index].userId
                ChatChannelPage.LoadUserInfo(userId, function(userinfo)
                    if userinfo then
                        if ChatChannelPage.members[index] then
                            ChatChannelPage.members[index].userInfo = userinfo
                        end
                        index = index + 1
                    else
                        index = index + 1
                    end
                    loadFunc(index)
                end)
            end
        end
        loadFunc(1)
     end)
end

function ChatChannelPage.GetIcon(data)
    if not data then
        return ""
    end
    local userInfo = data.userInfo or {}
    if userInfo.portrait and userInfo.portrait ~= "" then
        return userInfo.portrait
    end

    return "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png#0 0 51 57"
end

function ChatChannelPage.IsItemSelect(index)
    return ChatChannelPage.selectedPrivateUserIndex == index
end

function ChatChannelPage.IsMyself(data)
    if not data then
        return false
    end
    local my_userId = Mod.WorldShare.Store:Get("user/userId")
    local userInfo = data.userInfo
    if userInfo and userInfo.userId == my_userId then
        return true
    end
    return false
end

function ChatChannelPage.GetName(data)
    if not data then
        return ""
    end
    local userInfo = data.userInfo or {}
    local showName = ""
    if userInfo.nickname and userInfo.nickname ~= "" then
        showName = userInfo.nickname
    else
        showName = userInfo.username
    end
    showName = showName --..("(ID:"..data.userId..")")
    return showName
end

function ChatChannelPage.GetPrivateChatName()
    local index = ChatChannelPage.selectedPrivateUserIndex
    if not index or index < 1 or index > #ChatChannelPage.privateUsers then
        return ""
    end
    local userInfo = ChatChannelPage.privateUsers[index].userInfo or {}
    local showName = ""
    if userInfo.nickname and userInfo.nickname ~= "" then
        showName = userInfo.nickname
    else
        showName = userInfo.username
    end
    showName = showName..("(ID:"..ChatChannelPage.privateUsers[index].userId..")")
    return showName
end

function ChatChannelPage.SortChatUserById(user_id)
    if not user_id or type(user_id) ~= "number" or user_id < 1 then
        return false
    end
    local isTempChat = false
    for i , item in ipairs(ChatChannelPage.tempPrivateUsers) do
        if item.userId == user_id then
            table.insert(ChatChannelPage.privateUsers,1,item)
            isTempChat = true
        else
            table.insert(ChatChannelPage.privateUsers,item)
        end
    end
    if not isTempChat then
        local chatIndex = -1
        for i , item in ipairs(ChatChannelPage.privateUsers) do
            if item.userId == user_id then
                chatIndex = i
                break
            end
        end
        local temp = ChatChannelPage.privateUsers[1]
        ChatChannelPage.privateUsers[1] = ChatChannelPage.privateUsers[chatIndex]
        ChatChannelPage.privateUsers[chatIndex] = temp
    end
end

function ChatChannelPage.LoadPrivateUsers(chat_user_id) -- 私聊用户列表和私聊用户聊天记录内容构建
    local chatData = ChatChannelPage.GetChatData()
    if not chatData then
        return
    end
    local preSelectIndex = ChatChannelPage.selectedPrivateUserIndex
    ChatChannelPage.selectedPrivateUserIndex = -1
    local tempChatData = {}
    local tempUsers = {}
    local my_userId = Mod.WorldShare.Store:Get("user/userId")
    for _, data in ipairs(chatData) do
        local relevantUserId = ((data.msgUserId == my_userId) and tonumber(data.toUserId)) or ((tonumber(data.toUserId) == my_userId) and data.msgUserId)
        relevantUserId = tonumber(relevantUserId)
        if relevantUserId then
            if not tempChatData[relevantUserId] then
                tempChatData[relevantUserId] = {}
            end
            if ChatChannelPage.IsPrivareNewUser(relevantUserId) then
                ChatChannelPage.AddPrivateUser(relevantUserId)
            end
            data.ifmyself = (data.msgUserId == my_userId)
            table.insert(tempChatData[relevantUserId], data) -- 将聊天记录添加到对应用户的聊天记录中
        end
    end
    ChatChannelPage.privateChatData = tempChatData
    echo("加载私聊用户成功=================")
    
    local function loadedUser()
        local selectIndex = preSelectIndex > 0 and preSelectIndex or 1
        if chat_user_id and tonumber(chat_user_id) > 0 then
            ChatChannelPage.SortChatUserById(chat_user_id)
            selectIndex = 1
        end
        echo("加载私聊用户数据完成=============")
        ChatChannelPage.ClickItem(selectIndex)
        ChatChannelPage.RefreshPage()
    end

    if ChatChannelPage.IsAllPrivateUserInfoLoaded() then
        loadedUser()
        return
    end
    local loadFunc = nil
    loadFunc = function(index)
        if index > #ChatChannelPage.privateUsers then
            
            loadedUser()
            return 
        end
        if not ChatChannelPage.privateUsers[index] or ChatChannelPage.privateUsers[index].userInfo ~= nil then
            index = index + 1
            loadFunc(index)
        else
            local userId = ChatChannelPage.privateUsers[index].userId
            ChatChannelPage.LoadUserInfo(userId, function(userinfo)
                if userinfo then
                    ChatChannelPage.privateUsers[index].userInfo = userinfo
                    index = index + 1
                else
                    index = index + 1
                end
                loadFunc(index)
            end)
        end
    end
    loadFunc(1)
end

function ChatChannelPage.IsAllPrivateUserInfoLoaded()
    local isAllLoaded = true
    for _, item in ipairs(ChatChannelPage.privateUsers) do
        if not item.userInfo then
            isAllLoaded = false
            break
        end
    end
    return isAllLoaded
end

function ChatChannelPage.IsPrivareNewUser(userId)
    local isNewUser = true
    for _, item in ipairs(ChatChannelPage.privateUsers) do
        if item.userId == userId then
            isNewUser = false
            break
        end
    end
    return isNewUser
end

function ChatChannelPage.AddPrivateUser(userId)
    local isNewUser = ChatChannelPage.IsPrivareNewUser(userId)
    if isNewUser then
        local temp = {userId = userId, userInfo = nil}
        table.insert(ChatChannelPage.privateUsers, 1, temp)
    end
end

function ChatChannelPage.SelectPrivateUser(index)
    local num = #ChatChannelPage.privateUsers
    print("选择私聊用户列表========",index,num)
    if not index or index < 1 or index > num then
        return
    end
    ChatChannelPage.selectedPrivateUserIndex = index
    ChatChannelPage.RefreshPage()
end

function ChatChannelPage.GetSelectPrivateChat()
    local index = ChatChannelPage.selectedPrivateUserIndex
    if not index or index < 1 or index > #ChatChannelPage.privateUsers then
        return 
    end
    local userId = ChatChannelPage.privateUsers[index].userId
    local chatData = ChatChannelPage.privateChatData[userId]
    return chatData
end

function ChatChannelPage.ClickItem(index)
    local num = #ChatChannelPage.privateUsers
    if not index or index < 1 or index > num then
        return
    end
    if ChatChannelPage.selectedPrivateUserIndex == index then
        return
    end
    ChatChannelPage.selectedPrivateUserIndex = index
    ChatChannelPage.SelectPrivateUser(index)
end

function ChatChannelPage.LoadUserInfo(userId,callback) -- 加载用户信息
    NPL.load("(gl)script/ide/System/Encoding/base64.lua");
	local Encoding = commonlib.gettable("System.Encoding");
	if userId and tonumber(userId) > 0 then
		local id = "kp" .. Encoding.base64(commonlib.Json.Encode({userId=userId}));
        keepwork.user.getinfo({
            cache_policy = "access plus 0",
            router_params = {
                id = id,
            }
        },function (err, msg, data)
            if err == 200 then
                if callback and type(callback) == "function" then
                    local userInfo = {}
                    local extra = data.extra or {}
                    local ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo
                    if ParacraftPlayerEntityInfo then
                        userInfo.modelUrl = ParacraftPlayerEntityInfo.asset
                        userInfo.skin = ParacraftPlayerEntityInfo.skin
                        userInfo.modelScale = ParacraftPlayerEntityInfo.scale
                    end
                    userInfo.userId = data.id
                    userInfo.username = data.username
                    userInfo.nickname = data.nickname
                    userInfo.portrait = data.portrait
                    userInfo.vip = data.vip == 1
                    userInfo.commonVip = data.commonVip == 1
                    if callback and type(callback) == "function" then
                        callback(userInfo)
                    end
                end
                return
            end
            if callback and type(callback) == "function" then
                callback()
            end
        end)
    else
        if callback and type(callback) == "function" then
            callback()
        end
	end
end

function ChatChannelPage.LoadBlackList(callback)
    keepwork.friend.getBlacklist({},function(err, msg, data)
        if err ~= 200 then
            print("load black list failed "..err)
            if callback and type(callback) == "function" then
                callback()
            end
            return
        end
        ChatChannelPage.blackList = data
        ChatChannelPage.isAddBlackList = {}
        for _, item in ipairs(ChatChannelPage.blackList) do
            local friendId = item.friendId
            if friendId and tonumber(friendId) > 0 then
                ChatChannelPage.isAddBlackList[friendId] = true
            end
        end
        -- echo(ChatChannelPage.blackList, true)
        echo("load black list success "..err)
        local tempList = {}
        for _, item in ipairs(ChatChannelPage.blackList) do
            item.userInfo = item.friend
            item.userId = item.friendId
            item.friend = nil
            item.friendId = nil
            table.insert(tempList, item)
        end
        ChatChannelPage.blackList = tempList
        -- echo(ChatChannelPage.blackList, true)
        if callback and type(callback) == "function" then
            callback()
        end
    end)
end

function ChatChannelPage.AddBlackList(chatdata)
    if ChatChannelPage.IsMyself(chatdata) then
        GameLogic.AddBBS(nil, L"不能添加自己到黑名单")
        return
    end
    if not chatdata or type(chatdata) ~= "table" then
        GameLogic.AddBBS(nil, L"数据错误")
        return
    end
    ChatChannelPage.LoadBlackList(function()
        local friendId = chatdata.userId
        if ChatChannelPage.isAddBlackList[friendId] then
            GameLogic.AddBBS(nil, L"当前用户已经在黑名单中")
            return
        end
        keepwork.friend.addBlacklist({friendId = friendId},
            function(err, msg, data)
                if err == 200 then
                    print("添加黑名单成功")
                    GameLogic.AddBBS(nil, L"添加黑名单成功")
                else
                    GameLogic.AddBBS(nil, L"添加黑名单失败,请重试~")
                    print("添加黑名单失败")
                end
            end
        )
    end)
end

function ChatChannelPage.RemoveBlackList(chatdata)
    if chatdata and type(chatdata) == "table" then
        local friendId = chatdata.userId
        keepwork.friend.removeBlacklist({
            router_params={
                friendId = friendId
            }
        },function(err, msg, data)
                if err == 200 then
                    print("移除黑名单成功")
                    GameLogic.AddBBS(nil, L"移除黑名单成功")
                    ChatManager.RemoveBlackList(chatdata)
                    ChatChannelPage.LoadBlackList(function()
                        ChatChannelPage.RefreshPage()
                    end)
                else
                    GameLogic.AddBBS(nil, L"移除黑名单失败,请重试~")
                    print("移除黑名单失败")
                end
            end
        )
    end
end

function ChatChannelPage.AddFriend(chatdata)
    print("添加好友")
    -- echo(chatdata, true)
    if ChatChannelPage.IsMyself(chatdata) then
        GameLogic.AddBBS(nil, L"不能添加自己为好友")
        return
    end
    if chatdata and type(chatdata) == "table" then
        local friendId = chatdata.userId
        ChatManager.ApplyFriend(friendId,function(err, msg, data)
            ChatChannelPage.RefreshPage()
        end)
    end
end


function ChatChannelPage.DeleteFriend(chatdata)
    if ChatChannelPage.IsMyself(chatdata) then
        GameLogic.AddBBS(nil, L"不能删除自己")
        return
    end
    if chatdata and type(chatdata) == "table" then
        local friendId = chatdata.userId
        keepwork.friend.deleteFriend({
            router_params={
                friendId = friendId
            }
        },function(err, msg, data)
                if err == 200 then
                    print("删除好友成功")
                    GameLogic.AddBBS(nil, L"删除好友成功")
                    ChatChannelPage.RefreshPage()
                else
                    GameLogic.AddBBS(nil, L"删除好友失败,请重试~")
                    print("删除好友失败")
                end
            end
        )
    end
end

function ChatChannelPage.StartPrivateChat(data)
    if ChatChannelPage.IsMyself(data) then
        GameLogic.AddBBS(nil, L"不能与自己私聊")
        return
    end
    if data and type(data) == "table" then
        ChatChannelPage.AddTempPrivateChat(data)
    end
end

function ChatChannelPage.CheckHasPrivateChat(data)
    local tempUsers = {}
    local tempChatData = {}
    local is_temp_chat = false
    local my_userId = Mod.WorldShare.Store:Get("user/userId")
    local privateChannel = ChatChannelPage.GetChannelByName("Private")
    local chatData = ChatChannelPage.GetChatData(privateChannel)
    if chatData then
        for _, data in ipairs(chatData) do
            local relevantUserId = ((data.msgUserId == my_userId) and tonumber(data.toUserId)) or ((tonumber(data.toUserId) == my_userId) and data.msgUserId)
            relevantUserId = tonumber(relevantUserId)
            if relevantUserId then
                if not tempChatData[relevantUserId] then
                    tempChatData[relevantUserId] = {}
                    table.insert(tempUsers, {userId = relevantUserId, userInfo = nil})
                end
                data.ifmyself = (data.msgUserId == my_userId)
                table.insert(tempChatData[relevantUserId], data) -- 将聊天记录添加到对应用户的聊天记录中
            end
        end
    end
    local has_private_chat = false
    local private_user_id = data.userId
    if private_user_id and private_user_id > 0 and tempChatData[private_user_id] then
        has_private_chat = true
    end

    -- 更新临时聊天列表
    local tempNum = #ChatChannelPage.tempPrivateUsers
    for i=tempNum,1,-1 do
        local item = ChatChannelPage.tempPrivateUsers[i]
        if tempChatData[item.userId] then
            table.remove(ChatChannelPage.tempPrivateUsers, i)
        end
    end

    -- 判断当前选中用户是否有临时私聊聊天列表
    if not has_private_chat then
        local temp_private_users = {}
        for _,item in ipairs(ChatChannelPage.tempPrivateUsers) do
            if item.userId == private_user_id then
                has_private_chat = true
                is_temp_chat = true
                break
            end
        end
    end
    return has_private_chat, is_temp_chat
end


function ChatChannelPage.AddTempPrivateChat(data)
    print("添加临时私聊")
    echo(data, true)
    if not data or type(data) ~= "table" then
        return
    end
    local has_private_chat, is_temp_chat = ChatChannelPage.CheckHasPrivateChat(data)
    local chat_user_id = data.userId
    if has_private_chat then
        if is_temp_chat then
            print("当前用户已经在临时私聊列表中") 
        else
            print("当前用户已经在私聊列表中")
        end
    else
        local temp_user = {
            userId = data.userId,
            userInfo = data.userInfo,
        }
        table.insert(ChatChannelPage.tempPrivateUsers, temp_user)
    end
    ChatChannelPage.ChangeChannelTab("Private",chat_user_id)
end

function ChatChannelPage.DrawChatNodeHandler(_parent, treeNode)
	if(_parent == nil or treeNode == nil) then
		return;
	end
	local _this;
	local height = 20; -- just big enough
	local nodeWidth = treeNode.TreeView.ClientWidth;
	local oldNodeHeight = treeNode:GetHeight();

	treeNode.portrait = treeNode.ifmyself and ChatUserData.portrait or treeNode.portrait
	local icon = "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png#0 0 51 57"

	if treeNode.ifmyself then
		if ChatUserData.portrait and ChatUserData.portrait ~= "" then
			icon = ChatUserData.portrait
		end
	elseif treeNode.portrait and treeNode.portrait ~= "" then
		icon = treeNode.portrait
	end
	local name = ""
	if treeNode.ifmyself then
		name = "我"
	else
		name = treeNode.nickname or treeNode.username
	end

	local content_text = treeNode.Text or ""
	
	local mcmlStr = ""
	local content_font_size = 14
	local text_width = 340 

	local lenth, allcount, str_list = FriendChatPage.GetStringCharCount(content_text, content_font_size, text_width)
    local emojiText , isFindEmoji = ChatManager.CreateMcmlStrByText(content_text, content_font_size)
	-- print("kkkkkkkkkkkkkkkkkkkkkkkkkkkk",#str_list,lenth, allcount)
	-- commonlib.echo(str_list)
	local content_text_width = allcount * content_font_size	
	-- if content_text_width - math.floor(content_text_width) > 0.5 then
	-- 	content_text_width = content_text_width + 1
	-- end
	local is_more_line = #str_list > 1

	local bg_width = content_text_width + 18
	local margin_top = 4
	local bg_height = 32

	if is_more_line then
		bg_width = text_width + 12
		margin_top = 0

		local line_num = #str_list
		local line_inerval = 7
		bg_height = line_num * content_font_size + (line_num - 1) * line_inerval + 10
		height_str = string.format("height:%s", bg_height)
	end

	if bg_width < 32 then
		bg_width = 32
	end
    local height_dis = 10
	height_str = string.format("height:%s", bg_height)
	local text_singleline = is_more_line and "true" or "false"
	if treeNode.ifmyself then
		local margin_left = is_more_line and 0 or (text_width - bg_width + 10)
        local text_margin_left = 6
        local align_type = "left"

        local html_str = ""
        if isFindEmoji then
            html_str = html_str .. string.format([[
                <div style="float:left; margin-top:%s;margin-left:%s;width:%s;font-size:%s;color:#404BF5;">
                    %s
                </div>	
            ]], margin_top, text_margin_left, text_width, content_font_size, emojiText)
        else
            for index, v in ipairs(str_list) do
                html_str = html_str .. string.format([[
                    <div style="margin-top:%s;margin-left:%s;width:%s;font-size:%s;color:#404BF5;text-align:%s;text-singleline:%s;">
                        %s
                    </div>	
                ]], margin_top, text_margin_left, text_width, content_font_size, align_type,tostring(is_more_line), v)
            end
        end
        mcmlStr = string.format([[
            <div style="margin-left:0px;margin-top:0px;padding-left:48px;padding-top:2px;width:460px; ">
                <div style="float: left;margin-top:0px;width:345px;color:#ffffff;text-align:right;">
                    %s
                </div>
                <div name="item_bg" style="float: left;margin-top:0px;margin-left:%s;width:%s;%s;background-color: #C2C4E4; background: url(Texture/Aries/Creator/keepwork/community_32bits.png#188 6 32 32:14 14 14 14);">
                    %s
                </div>
                <div style="float: left;margin-left:8px;margin-top:6px;">
                    <img zorder="0" src='%s'width="46" height="46"/>
                </div>
            </div>
            ]] , name, margin_left - 6, bg_width ,height_str, html_str, icon);
	else

		local html_str = ""
        if isFindEmoji then
            html_str = html_str .. string.format([[
                <div style="float:left; margin-top:%s;margin-left:12px;width:%s;font-size:%s;color:#FFFFFF;">
                    %s
                </div>	
            ]], margin_top, text_width, content_font_size, emojiText)
        else
            for index, v in ipairs(str_list) do
                html_str = html_str .. string.format([[
                    <div style="margin-top:%s;margin-left:12px;width:%s;font-size:%s;color:#FFFFFF;text-singleline:%s;">
                        %s
                    </div>	
                ]], margin_top, text_width, content_font_size,tostring(is_more_line), v)
            end
        end

        mcmlStr = string.format([[
            <div style="margin-left:12px;margin-top:10px;padding-left:5px;padding-top:2px;width:460px;">
                <div style="float: left;margin-left:0px;margin-top:5px;">
                    <img zorder="0" src='%s'width="46" height="46"/>
                </div>
                <div style="float: left;margin-left: 8px; ">
                    <div style="margin-top:0px;width:360px;margin-left: 2px;color:#B9BABC">
                        %s
                    </div>
                    <div name="item_bg" style="margin-top:0px; width:%s;%s;background-color: #262626; background: url(Texture/Aries/Creator/keepwork/community_32bits.png#188 6 32 32:14 14 14 14);">
                        %s
                    </div>

                </div>
            </div>
            ]], icon , name, bg_width, height_str, html_str);
	end


	if(mcmlStr ~= nil) then
		local xmlRoot = ParaXML.LuaXML_ParseString(mcmlStr);
		if(type(xmlRoot)=="table" and table.getn(xmlRoot)>0) then
			local xmlRoot = Map3DSystem.mcml.buildclass(xmlRoot);
			local control = xmlRoot:GetControl()
							
			local myLayout = Map3DSystem.mcml_controls.layout:new();
			myLayout:reset(0, 0, nodeWidth-5, height);
			-- print("aaaaaaaaaaaaaaaa",height,height_str)
			Map3DSystem.mcml_controls.create("chat_chanel_item_page", xmlRoot, nil, _parent, 0, 0, nodeWidth-5, height,nil, myLayout);
			local usedW, usedH = myLayout:GetUsedSize()

			local item_bg = xmlRoot:GetChildWithAttribute("item_bg")
			-- print("nnnnnnnnnnnnnnnnnnnnn", usedH, xmlRoot:GetUIControl())
			-- commonlib.echo(xmlRoot:GetControl(), true)
			if(usedH>height) then
				return usedH+height_dis;
			end
		end
	end
end

function ChatChannelPage.OnCreate()
    ChatChannelPage.SetTextAfterRefresh()
    if ChatChannelPage.IsSelectBlackListMenu() then -- 黑名单菜单
        return
    end
    if ChatChannelPage.IsSelectPrivateMenu() then -- 私聊菜单
        ChatChannelPage.CreatePrivateChatContentView()
        return
    end
    ChatChannelPage.CreateGroupChatContentView() -- 群聊内容视图,本地和组队
end

function ChatChannelPage.CreateGroupChatContentView()
    local chatData = ChatChannelPage.GetGroupChatData()
    if not chatData or not page then
        return
    end
    local name = "group_chat_content";
	local chat_content = ParaUI.GetUIObject(name)
    if not chat_content or not chat_content:IsValid() then
        print("群聊内容视图不存在")
        return
    end
    local ctl = CommonCtrl.TreeView:new{
		name = "group_chat_TreeView",
		alignment = "_fi",
		left = 0,
		top = 0,
		width = 0,
		height = 0,
		parent = chat_content,
		container_bg = "",
		DefaultIndentation = 5,
		DefaultNodeHeight = 22,
		VerticalScrollBarStep = 22,
		DrawNodeHandler = ChatChannelPage.DrawChatNodeHandler,
	};
	local node = ctl.RootNode;
	ctl:Show();

    -- echo(chatData, true)
    print("创建群聊内容视图==============")

    for index = 1, #chatData do
        local chat_data = chatData[index]
        local show_data = {}
        show_data.Text = chat_data.chatContent
        show_data.ifmyself = chat_data.ifmyself
        if show_data.ifmyself == false then
            show_data.nickname = chat_data.nickname or chat_data.username
            show_data.portrait = ChatChannelPage.GetIconByChatData(chat_data)
        end
        ctl.RootNode:AddChild(CommonCtrl.TreeNode:new(show_data));

    end

	ctl:Update(true);
end

function ChatChannelPage.GetIconByChatData(chatData,isPrivate)
    if not chatData then
        return "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png#0 0 51 57"
    end
    if isPrivate then
        local msgUserId = chatData.msgUserId
        print("获取私聊头像",msgUserId)
        -- echo(chatData, true)
        -- echo(ChatChannelPage.privateUsers, true)
        for i,v in ipairs(ChatChannelPage.privateUsers) do
            if v.userId == msgUserId and v.userInfo then
                return v.userInfo.portrait 
            end
        end
        return "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png#0 0 51 57"
    end
    local userId = chatData.userId
    if not userId or userId == "" then
        return "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png#0 0 51 57"
    end
    for i,v in ipairs(ChatChannelPage.members) do
        if v.userId == userId and v.userInfo then
            return v.userInfo.portrait 
        end
    end
    return "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png#0 0 51 57"
end

function ChatChannelPage.CreatePrivateChatContentView()
    local chatData = ChatChannelPage.GetSelectPrivateChat()
    if not chatData or not page then
        return
    end
    local name = "private_chat_content";
	local chat_content = ParaUI.GetUIObject(name)
    if not chat_content or not chat_content:IsValid() then
        print("私聊内容视图不存在")
        return
    end
	local ctl = CommonCtrl.TreeView:new{
		name = "private_chat_TreeView",
		alignment = "_fi",
		left = 0,
		top = 0,
		width = 0,
		height = 0,
		parent = chat_content,
		container_bg = "",
		DefaultIndentation = 5,
		DefaultNodeHeight = 22,
		VerticalScrollBarStep = 22,
		DrawNodeHandler = ChatChannelPage.DrawChatNodeHandler,
	};
	local node = ctl.RootNode;
	ctl:Show();

    -- echo(chatData, true)
    print("创建私聊内容视图==============")

    for index = 1, #chatData do
        local chat_data = chatData[index]
        local show_data = {}
        show_data.Text = chat_data.chatContent
        show_data.ifmyself = chat_data.ifmyself
        if show_data.ifmyself == false then
            show_data.nickname = chat_data.msgNickname or chat_data.msgUsername
            show_data.portrait = ChatChannelPage.GetIconByChatData(chat_data,true)
        end
        ctl.RootNode:AddChild(CommonCtrl.TreeNode:new(show_data));

    end

	ctl:Update(true);
end

function ChatChannelPage.OnPrivateChatKeyUp()
    if(virtual_key == Event_Mapping.EM_KEY_RETURN or virtual_key == Event_Mapping.EM_KEY_NUMPADENTER) then
        ChatChannelPage.OnClickSendChat()
    end
end

function ChatChannelPage.OnClickSendChat()
    if not page then
        return 
    end
    local channel = ChatChannelPage.GetSelectedChatChanel()
    if not channel then
        return
    end
    local chat_content = ""
    if channel and channel.name == "Private" then
        chat_content = page:GetValue("private_chat_words")
    end
    if channel and (channel.name == "Team" or channel.name == "Local") then
        chat_content = page:GetValue("group_chat_words")
    end
    if chat_content == "" then
        return
    end
    ChatChannelPage.privatechatInputText = ""
    ChatChannelPage.groupchatInputText = ""
    page:SetValue("private_chat_words","")
    page:SetValue("group_chat_words","")
    if channel.name == "Private" then
        local index = ChatChannelPage.selectedPrivateUserIndex
        if not index or index < 1 or index > #ChatChannelPage.privateUsers then
            return ""
        end
        local userInfo = ChatChannelPage.privateUsers[index].userInfo or {}
        local userId = userInfo.userId or ""
        ChatManager.SendPrivateMessage(userId,chat_content)
        return
    end
    local channel_value = channel.chanel
    print("ChatChannelPage========发送消息", channel_value, chat_content)
    if channel.name == "Team" then
        ChatManager.SendMessage(channel_value,chat_content)
        return
    end
    if channel.name == "Local" then
        ChatChannel.SendMessage(channel_value, nil, nil, chat_content)
    end
end

function ChatChannelPage.GetInputControl()
    local channel = ChatChannelPage.GetSelectedChatChanel()
    if not channel or not page then
        return
    end
    local control = nil
    if channel and channel.name == "Private" then
        control = page:FindUIControl("private_chat_words")
    end
    if channel and (channel.name == "Team" or channel.name == "Local") then
        control = page:FindUIControl("group_chat_words")
    end
    print("获取输入控件",channel.name)
    return control
end

function ChatChannelPage.GetCurCaretPosition()
    local _editbox = ChatChannelPage.GetInputControl();
    if(_editbox) then
        local pos = _editbox:GetCaretPosition();
        return pos;
    end
end

function ChatChannelPage.InsertStringAt(s,emot_str,index)
	if(not s or not emot_str)then return end
	index = index or 0;
	local len = ParaMisc.GetUnicodeCharNum(s);
	index = math.max(index,0);
	index = math.min(index,len);
	local start_str = ParaMisc.UniSubString(s, 1, index) or "";
	local end_str = ParaMisc.UniSubString(s, index+1, -1) or "";
	local str = start_str..emot_str..end_str;
	return str,index;
end

function ChatChannelPage.InsertSymbol(s,caret_pos, replace_text)
	if(not s)then return end
	local len = ParaMisc.GetUnicodeCharNum(s);
	local _editbox = ChatChannelPage.GetInputControl();
    if(_editbox) then
        if(replace_text) then
            replace_map = replace_map or {};
            replace_map[replace_text] = s;
        end

        local text = _editbox.text or "";
        if(not caret_pos)then
            caret_pos = ParaMisc.GetUnicodeCharNum(text);
        end
        text,caret_pos = ChatChannelPage.InsertStringAt(text, replace_text or s,caret_pos)
        _editbox.text = text or "";
        _editbox:Focus();
        caret_pos = caret_pos + len;
        _editbox:SetCaretPosition(caret_pos);
    end
end

function ChatChannelPage.OnGroupChatKeyUp()
    if(virtual_key == Event_Mapping.EM_KEY_RETURN or virtual_key == Event_Mapping.EM_KEY_NUMPADENTER) then
        ChatChannelPage.OnClickSendChat()
    end
end

function ChatChannelPage.OnPrivateSearchChange(name,mcmlNode)
    if not page then
        return
    end
    ChatChannelPage.privateSearchText = page:GetValue("private_search_content")
end

function ChatChannelPage.OnBlackListSearchChange(name,mcmlNode)
    if not page then
        return
    end
    ChatChannelPage.blacklistSearchText = page:GetValue("blacklist_search_content")
end

function ChatChannelPage.OnPrivateChatChange(name,mcmlNode)
    if not page then
        return
    end
    ChatChannelPage.privatechatInputText = page:GetValue("private_chat_words")
end

function ChatChannelPage.OnGroupChatTextChange(name,mcmlNode)
    if not page then
        return
    end
    ChatChannelPage.groupchatInputText = page:GetValue("group_chat_words")
end

function ChatChannelPage.OnPrivateSearch()
    if not page then
        return
    end
    local private_search_content = page:GetValue("private_search_content")
    if private_search_content == "" then
        return
    end

end

function ChatChannelPage.OnBlackListSearch()
    if not page then
        return
    end
    local blacklist_search_content = page:GetValue("blacklist_search_content")
    if blacklist_search_content == "" then
        return
    end

end


