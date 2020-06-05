--[[
Title: The Chat Channels 
Author(s): zrf, refactored by LiXizhi
Date: 2011/3/8
Desc:  
Use Lib:
-------------------------------------------------------
ChannelIndex对应的频道:
	1		附近
	2		小队
	3		单聊
	4		家族
	5		团队
	6		地区
	7		组队
	8		交易
	9		系统广播
	10		喇叭
	11		NPC
	12		BecomeOnline
	13		ItemObtain
	14		Lobby (create or join or exit)

msgdata结构:
	ChannelIndex	number	频道索引
	from			number	发送者nid
	fromname		string	发送者名字
	fromisvip		bool	发送者是否会员
	fromschool		string	发送者魔法属性
	to				number	接受者nid
	toname			string	接受者名字
	toisvip			bool	接受者是否会员
	toschool		string	接受者魔法属性
	words			string	消息内容
	bHideTooltip	bool	隐藏名字tooltip
	bHideColon		bool	隐藏:
	is_direct_mcml  bool    直接使用mcml(慎用)
	bHideSubject    bool    隐藏主语 只有当from和to都是nil的时候生效 一般配合is_direct_mcml 如掉落ItemObtain的提示

NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
ChatChannel.AppendChat({ChannelIndex=ChatChannel.EnumChannels.NearBy, from=nid, words="text"});
commonlib.echo( ChatChannel.GetChat(ChatChannel.EnumChannels.Team) );
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/Encoding.lua");
local ExternalUserModule = commonlib.gettable("MyCompany.Aries.ExternalUserModule");
local BattlefieldClient = commonlib.gettable("MyCompany.Aries.Battle.BattlefieldClient");
local MsgHandler = commonlib.gettable("MyCompany.Aries.Combat.MsgHandler");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local ChatMessage = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatMessage");
local Combat = commonlib.gettable("MyCompany.Aries.Combat");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local Encoding = commonlib.gettable("commonlib.Encoding");
local VIP = commonlib.gettable("MyCompany.Aries.VIP");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local Chat = commonlib.gettable("MyCompany.Aries.Chat");
local Friends = MyCompany.Aries.Friends;
local FamilyChatWnd = commonlib.gettable("MyCompany.Aries.Chat.FamilyChatWnd");
local ChatWnd = commonlib.gettable("MyCompany.Aries.Chat.ChatWnd");

local ProfileManager = commonlib.gettable("Map3DSystem.App.profiles.ProfileManager");
local SmileyPage = commonlib.gettable("MyCompany.Aries.ChatSystem.SmileyPage");
local Combat = commonlib.gettable("MyCompany.Aries.Combat");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");

ChatChannel.channels = {
--{name=""},
{name="附近",bshow=true,color="f9f7d4",},
{name="小队",bshow=true,color="00dcff",},
{name="单聊",bshow=true,color="fe74ff", default_channel_text="@ "},
{name="家族",bshow=true,color="44e71e",},
{name="团队",bshow=true,color="ffa74f",},
{name="全服",bshow=true,color="fced4b",},
{name="组队",bshow=true,color="00dcff",},
{name="交易",bshow=true,color="ff89be",},
{name="系统",bshow=true,color="fced4b",},
{name="全区",bshow=true,color="fced4b",}, --10
{name="",bshow=true,color="fda000",}, -- "NPC" 11
{name="",bshow=true,color="fee11c",}, --"BecomeOnline" 12
{name="",bshow=true,color="fbea77",}, -- "ItemObtain" 13
{name="副本",bshow=true,color="fee11c",}, -- "Lobby create or join or exit" 14
{name="",bshow=true,color="fda000",}, -- "empty" 15
{name="",bshow=true,color="fda000",}, -- "empty" 16
{name="",bshow=true,color="fda000",}, -- "empty" 17
{name="",bshow=true,color="fda000",}, -- "empty" 18
{name="",bshow=true,color="fda000",}, -- "empty" 19
{name="",bshow=true,color="fda000",}, -- "empty" 20

{name="本地",bshow=true,color="ffffff",}, -- "KpNearBy" 21
{name="全局",bshow=true,color="fced4b",}, -- "KpBroadCast" 22
{name="官方公告",bshow=true,color="fced4b",}, -- "KpSystem" 23
};

ChatChannel.channels_theme_kids = ChatChannel.channels;

-- mapping from string to channel index
local EnumChannels = {
	All= 0,
	NearBy = 1,
	Team = 2,
	Private = 3,
	Home = 4,
	Class = 5,
	Region = 6,
	AllTeam = 7,
	Trade = 8,
	System = 9,
	BroadCast = 10,
	NPC = 11,
	BecomeOnline = 12,
	ItemObtain = 13,
	Lobby = 14,

	KpNearBy = 21,
	KpBroadCast = 22,
	KpSystem = 23,
    KpMax = 29,
}
ChatChannel.EnumChannels = EnumChannels;
ChatChannel.chatmaxcount = 200;
ChatChannel.chatdata = ChatChannel.chatdata or {};
ChatChannel.JID_Buffer = ChatChannel.JID_Buffer or {};
-- do not perform vip field check when sending message. 
local ignore_vip = true;

function ChatChannel.Init()
	if(ChatChannel.is_init) then
		return
	end
	if(not System.options.mc) then
		NPL.load("(gl)script/apps/Aries/Chat/FamilyChatWnd.lua");
		NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatMessage.lua");
		NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/SmileyPage.lua");
		NPL.load("(gl)script/apps/Aries/Combat/MsgHandler.lua");
		NPL.load("(gl)script/apps/Aries/Login/ExternalUserModule.lua");
		NPL.load("(gl)script/apps/Aries/Chat/ChatWnd.lua");
	end

	ChatChannel.is_init = true;

	if(ChatChannel.AppendFilter==nil)then
		ChatChannel.AppendFilter = {};
		local i;
		for i=1,#(ChatChannel.channels) do
			table.insert( ChatChannel.AppendFilter, true );
		end
	end

	if(System.options.version == "kids") then
		ChatChannel.channels = ChatChannel.channels_theme_kids;
	end

	if(ChatChannel.ChannelIndexAssemble==nil)then
		ChatChannel.SetAppendEventCallbackFilter({1,2,3,4,5,6,7,8,9,11,12,13,14,21,22,23});
	end

	NPL.load("(gl)script/ide/Network/StreamRateController.lua");
	local StreamRateController = commonlib.gettable("commonlib.Network.StreamRateController");
	ChatChannel.streamRateCtrler = StreamRateController:new({name="ChatChannel", history_length = 5, max_msg_rate=0.3})

	NPL.load("(gl)script/ide/Network/StreamRateController.lua");
	local StreamRateController = commonlib.gettable("commonlib.Network.StreamRateController");
	ChatChannel.region_talk_rate_ctler = StreamRateController:new({name="ChatChannel.region", history_length = 40, max_msg_rate=0.001})
end

-- set the UI callback function that should be called whenever a new message is received. 
-- @param callback: callback of function(msg_data, bNeedRefresh) end
function ChatChannel.SetAppendEventCallback(callback)
	ChatChannel.callback = callback;
end
--added by leio,used for lobby chat
function ChatChannel.SetAppendEventCallback_LobbyChat(callback)
	ChatChannel.callback_lobbychat = callback;
end
-- Get channel name by index
function ChatChannel.GetChannelName(index)
	return ChatChannel.channels[index].name;
end

-- get channel by index
function ChatChannel.GetChannel(index)
	return ChatChannel.channels[index];
end


-- 设置消息发送的过滤器,用户发送消息时会根据AddFilter的顺序来依次调用回调函数
-- @param callback: function(msgdata) end, return nil, if the message should not be sent or displayed, 
--  return true if processed by the command filter itself, such as slash commands. 
--  or return the original or modified msgdata to be sent.
-- @param filter_name: it ensures that only one filter is enabled per filter name. if nil, it will be the filter index
function ChatChannel.AddFilter(callback, filter_name)
	if(type(callback)~="function")then
		commonlib.echo("error: callback 必须是个回调函数 in ChatChannel.AddFilter");
		return;
	end

	if(ChatChannel.WordsFilter== nil)then
		ChatChannel.WordsFilter = {};
	end
	if(filter_name) then
		if(ChatChannel.WordsFilterNameMap== nil)then
			ChatChannel.WordsFilterNameMap = {};
		end
		local last_filter = ChatChannel.WordsFilterNameMap[filter_name];
		ChatChannel.WordsFilterNameMap[filter_name] = callback;
		if(last_filter) then
			local i, filter_callback;
			for i, filter_callback in ipairs(ChatChannel.WordsFilter) do
				if(filter_callback == last_filter) then
					-- if there is already the callback, we will replace it. 
					ChatChannel.WordsFilter[i] = callback;
					return;
				end
			end
		end
	end
	
	local _, filter_callback;
	for _, filter_callback in ipairs(ChatChannel.WordsFilter) do
		if(filter_callback == callback) then
			-- if there is already the callback, we will remove it. 
			return;
		end
	end
	table.insert( ChatChannel.WordsFilter, callback );
end



--[[---------------------------------------------------------------------------------------------------
设置聊天记录有新消息时的回调函数的过滤器,只有接受到指定频道的新消息才会触发SetAppendEventCallback设置的回调函数

-- @param ChannelIndexAssemble:	nil		无过滤器,任何新消息都会触发
	table	包含多个频道的数组,只有该数组包含的频道新消息才会触发,如{2,3,4}
	number	指定单个频道,只有该频道新消息能触发回调
--]]---------------------------------------------------------------------------------------------------
function ChatChannel.SetAppendEventCallbackFilter(ChannelIndexAssemble)
	ChatChannel.ChannelIndexAssemble = ChannelIndexAssemble;
	local i;

	if(ChannelIndexAssemble==nil)then
		for i=1,#(ChatChannel.AppendFilter) do
			ChatChannel.AppendFilter[i] = true;
		end		
	elseif(type(ChannelIndexAssemble)=="number")then
		for i=1,#(ChatChannel.AppendFilter) do
			if(ChannelIndexAssemble == i)then
				ChatChannel.AppendFilter[i] = true;
			else
				ChatChannel.AppendFilter[i] = false;
			end
		end	
	elseif(type(ChannelIndexAssemble)=="table")then
		for i=1,#(ChatChannel.AppendFilter) do
			ChatChannel.AppendFilter[i] = false;
		end		
		for i=1,#(ChannelIndexAssemble) do
			ChatChannel.AppendFilter[ChannelIndexAssemble[i]] = true;
		end		
	end
end


--[[---------------------------------------------------------------------------------------------------
往消息记录中追加新消息, 如果本消息在SetAppendEventCallbackFilter中被指定, 
将会执行SetAppendEventCallback设置的回调函数并将该消息当做参数传递进去
-- @param msgdata: compressed string or msg_data table 
-- @param bIgnoreSelf: true if ignore message from self. 
-- @nid: this is from network message. 
--]]---------------------------------------------------------------------------------------------------
function ChatChannel.AppendChat( msgdata, bIgnoreSelf, nid )
	ChatChannel.Init();
	if(type(msgdata) == "string") then
		LOG.std(nil, "debug", "chat", "received chat:"..msgdata);
		msgdata = ChatMessage.DecompressMsg(msgdata);
	end
	if(type(msgdata)~="table") then
		return;
	end

	if(nid) then
		-- Note: only near by message can be send in this way, all other message should have nid set to 0 or nil. 
		nid = tonumber(nid);
		if(nid > 0 and (tonumber(msgdata.from) ~= nid or msgdata.ChannelIndex ~= EnumChannels.NearBy)) then
			LOG.std(nil, "debug", "ChatChannel", "drop msg ebecause it is invalid channel index", tostring(msgdata.ChannelIndex));
			return;
		end
	end

	--commonlib.echo(msgdata);
	local channel = ChatChannel.channels[msgdata.ChannelIndex];
	if(channel == nil)then
		LOG.std(nil, "error", "ChatChannel", "wrong channel index %s in ChatChannel.AppendChat", tostring(msgdata.ChannelIndex));
		return;
	end

	if(bIgnoreSelf and msgdata.from == System.App.profiles.ProfileManager.GetNID()) then
		return;
	end
	
	if(msgdata.from and msgdata.from~="0" and ExternalUserModule and ExternalUserModule.CanViewUser) then
		if(msgdata.ChannelIndex == EnumChannels.BroadCast and not ExternalUserModule:CanViewUser(msgdata.from)) then
			return;
		end
	end

	ChatChannel.ValidateMsg(msgdata, ChatChannel.OnProcessMsg);
end

-- process the received message, and invoke the callback function associated with its channel. 
function ChatChannel.OnProcessMsg(msgdata)
	ChatChannel.Init();
	local channel = ChatChannel.channels[msgdata.ChannelIndex];
	msgdata.channelname = channel.name;
	msgdata.color = channel.color;
	table.insert( ChatChannel.chatdata, msgdata );

	local is_skip_msg;
	--if( msgdata.words and msgdata.words:match("^<") ) then
		--local xmlRoot = ParaXML.LuaXML_ParseString(msgdata.words);
		--if(xmlRoot) then
			--is_skip_msg = true;
		--end
	--end

	if(#(ChatChannel.chatdata) > ChatChannel.chatmaxcount)then
		table.remove( ChatChannel.chatdata, 1 ); 
	end

	if(msgdata.from and ( msgdata.ChannelIndex == EnumChannels.NearBy or msgdata.ChannelIndex == EnumChannels.Region) )then
		player = ParaScene.GetObject(tostring(msgdata.from));
		if(player:IsValid() and player:DistanceToCameraSq()<3600) then
			local words = msgdata.words;
			
			local world_info = WorldManager:GetCurrentWorld()
			if(world_info.disable_arena_talk) then
				local player_side = BattlefieldClient:GetPlayerSide(msgdata.from);
				if(player_side) then
					-- battle field 
				else
					-- pvp world
					if(Player.IsInCombat()) then
						if(MsgHandler.IsUserInSameArenaSide(msgdata.from)) then
							words = words;
						else
							if(not words:match("^%$%d+$")) then
								-- we will skip smiley here. 
								words = "(低语中)..."
								-- do not display this as required by user
								is_skip_msg = true; 
							end
						end
					end
				end
			end
			local pure_text = commonlib.Encoding.EncodeStr(words);
			if(pure_text~=words) then
				pure_text = format("<div>%s</div>", pure_text)
			end
			if(not System.options.mc) then
				words = SmileyPage.ChangeToMcml(pure_text, 64);
			end
			headon_speech.Speek(player.name, words, 5, true);
		end
	end

	if(not is_skip_msg) then
		if(ChatChannel.callback and type(ChatChannel.callback)=="function" and (ChatChannel.AppendFilter[msgdata.ChannelIndex] or msgdata.ChannelIndex == EnumChannels.BroadCast  ))then
			ChatChannel.callback(msgdata,true);
		end
		--NOTE:added by leio,used for lobby chat
		if((msgdata.ChannelIndex == EnumChannels.AllTeam or msgdata.ChannelIndex == EnumChannels.BroadCast or msgdata.ChannelIndex == EnumChannels.Lobby) and ChatChannel.callback_lobbychat and type(ChatChannel.callback_lobbychat)=="function")then
			ChatChannel.callback_lobbychat(msgdata,true);
		end
	end
end


--[[---------------------------------------------------------------------------------------------------
获取指定频道的消息记录

	ChannelIndexAssemble:	nil		获取所有消息
							table	包含多个频道的数组,只获取数组中的包含的频道消息,如{2,3,4}
							number	指定单个频道,只获取该频道消息
--]]---------------------------------------------------------------------------------------------------
function ChatChannel.GetChat(ChannelIndexAssemble)
	local result = {};
	local i;

	if(type(ChannelIndexAssemble)==nil)then
		for i=1,#(ChatChannel.chatdata) do
			local chat = ChatChannel.chatdata[i];
			table.insert(result, chat );
		end		
	elseif(type(ChannelIndexAssemble)=="number")then
		for i=1,#(ChatChannel.chatdata) do
			local chat = ChatChannel.chatdata[i];
			if(chat.ChannelIndex == ChannelIndexAssemble)then
				table.insert(result, chat );
			end
		end 
	elseif(type(ChannelIndexAssemble)=="table")then
		for i=1,#(ChatChannel.channels) do
			ChatChannel.channels[i].bshow = false;
		end
		for i=1,#(ChannelIndexAssemble) do
			ChatChannel.channels[ChannelIndexAssemble[i]].bshow = true;
		end

		for i=1,#(ChatChannel.chatdata) do
			local chat = ChatChannel.chatdata[i];
			if(ChatChannel.channels[chat.ChannelIndex].bshow==true)then
				table.insert( result, chat );
			end
		end	
	end

	return result;
end

function ChatChannel.SendMessage_Keepwork( ChannelIndex, to, toname, words)
    local msgdata = KpChatChannel.CreateMessage( ChannelIndex, to, toname, words);
    if(not msgdata)then
        return
    end
    
	if(ChatChannel.WordsFilter)then
		local i;
		for i=1,#(ChatChannel.WordsFilter) do
			local filter_func = ChatChannel.WordsFilter[i];
			if(filter_func and type(filter_func)=="function")then
				msgdata = filter_func(msgdata);
				if(msgdata == true) then
					return true;
				elseif(msgdata==nil or msgdata.words == nil or msgdata.words == "" )then
					return;
				end
			end
		end
	end
    if(msgdata.ChannelIndex == EnumChannels.KpBroadCast) then
        local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
		local stone_name = "喇叭";
		local purchase_exid = 0;
        local gsItem = KeepWorkItemManager.GetItemTemplate(10001);
		if(gsItem) then
			stone_name = gsItem.name;
		end
        gsid_list = {
            { gsid = 10002, },
            { gsid = 10001, },
        }
        local copies = KeepWorkItemManager.UnionCopies(gsid_list);

		if(copies == 0) then
            _guihelper.MessageBox(format("你没有%s，不能广播！", stone_name),nil,nil,nil,nil,nil,nil,{ title = L"温馨提示", });
			return;
        else
            if(copies < 100) then
				_guihelper.MessageBox(format("发送一条喇叭消息,需要消耗一个%s,确定要发送? 你现在还有%d个%s", stone_name, copies or 0, stone_name),function(result)
					if(result == _guihelper.DialogResult.OK)then
						ChatChannel.ValidateMsg(msgdata,KpChatChannel.SendToServer);
					end
				end,_guihelper.MessageBoxButtons.OKCancel);
			else
				ChatChannel.ValidateMsg(msgdata,KpChatChannel.SendToServer);
			end
		end
    else
	    ChatChannel.ValidateMsg(msgdata,KpChatChannel.SendToServer);
    end
    return true;
end
-- send a chat message
-- @param ChannelIndex	频道索引
-- @param to				接受者nid
-- @param toname			接受者名字,可为nil
-- @param words			消息内容
-- @return true if succeed. or false if speaking too fast or does not pass a given filter
function ChatChannel.SendMessage( ChannelIndex, to, toname, words, bSilentMode )
    if(ChatChannel.Is_Keepwork_Channel(ChannelIndex))then
        return ChatChannel.SendMessage_Keepwork(ChannelIndex, to, toname, words)
    end
	if(not ChatChannel.streamRateCtrler:AddMessage()) then
		return
	elseif( ChannelIndex == EnumChannels.Region)then
		-- TODO: player level, 
		if(not bSilentMode) then
			if(System.options.version == "teen") then
				if(Player.GetLevel() < 10) then
					_guihelper.MessageBox("需要人物到10级才能全服喊话");
				elseif(Player.GetMyJoybeanCount() < 500) then
					_guihelper.MessageBox(format("全服喊话需要500%s, 你的%s不够", System.options.haqi_GameCurrency, System.options.haqi_GameCurrency));
				else
					_guihelper.MessageBox(format("使用全服频道需要消耗500%s, 是否发送？", System.options.haqi_GameCurrency), function(res)
						if(res and res == _guihelper.DialogResult.Yes) then
							-- pressed YES
							ChatChannel.SendMessage( ChannelIndex, to, toname, words, true )
						end
					end, _guihelper.MessageBoxButtons.YesNo);
				end
				return;
			end
		end
		if(not ChatChannel.region_talk_rate_ctler:AddMessage()) then
			_guihelper.MessageBox("全服喊话40秒后才能说下一句");
			return;
		end
	end

	local nid = 0;
	local name = "";
	local fromisvip;
	if(not System.options.mc) then
		nid = System.App.profiles.ProfileManager.GetNID();
		local userinfo = ProfileManager.GetUserInfoInMemory(nid)
		if(userinfo) then
			name = userinfo.nickname or "";
		end
		if(VIP.IsVIPAndActivated) then
			fromisvip = VIP.IsVIPAndActivated();
		end
	end
	local msgdata = { ChannelIndex = ChannelIndex, from = nid, fromname = name, to = to, fromisvip=fromisvip, toname = toname, words = words, };

	if(ChatChannel.WordsFilter)then
		local i;
		for i=1,#(ChatChannel.WordsFilter) do
			local filter_func = ChatChannel.WordsFilter[i];
			if(filter_func and type(filter_func)=="function")then
				msgdata = filter_func(msgdata);
				if(msgdata == true) then
					return true;
				elseif(msgdata==nil or msgdata.words == nil or msgdata.words == "" )then
					return;
				end
			end
		end
	end
	ChatChannel.ValidateMsg(msgdata,ChatChannel.SendToServer);
	return true;
end

--[[---------------------------------------------------------------------------------------------------
检验并完善用户信息
如果有发送者的nid号,但是没有发送者其它用户信息(名字,是否会员,魔法属性等),则会自动调用API获取信息并填充,填充
成功后执行success_callback函数
-- @param success_callback: function(msgdata) end to be called when data is validated. 
--]]---------------------------------------------------------------------------------------------------
function ChatChannel.ValidateMsg(msgdata,success_callback)
	if(not System.options.mc) then
		if(msgdata.from)then
			if(msgdata.fromname == nil)then
				Map3DSystem.App.profiles.ProfileManager.GetUserInfo(msgdata.from, "ChatChannelValidateMsg", function(msg)
					if(msg and msg.users and msg.users[1]) then
						local name = msg.users[1].nickname;
						if(name)then			
							msgdata.fromname = name;
							ChatChannel.ValidateMsg(msgdata,success_callback);
						end
					end	
				end, "access plus 1 hour");
				return;
			elseif(not ignore_vip and msgdata.fromisvip == nil)then
				if(msgdata.from == System.App.profiles.ProfileManager.GetNID())then
					msgdata.fromisvip = VIP.IsVIPAndActivated();
					ChatChannel.ValidateMsg(msgdata,success_callback);
					return;
				else
					System.App.profiles.ProfileManager.GetUserInfo(msgdata.from, "UpdateUserInfoInMemoryAfterSellItem", 
						function(msg) 
							local myInfo = ProfileManager.GetUserInfoInMemory(msgdata.from);
							if(myInfo and myInfo.energy) then
								msgdata.fromisvip = myInfo.energy > 0;
							else
								msgdata.fromisvip = false;
							end
							ChatChannel.ValidateMsg(msgdata,success_callback);
						end, "access plus 1 hour");
					return;
				end
			elseif(msgdata.fromschool == nil)then
				if(msgdata.ChannelIndex ~=  EnumChannels.BroadCast) then
					if(msgdata.from == System.App.profiles.ProfileManager.GetNID())then
						msgdata.fromschool = Combat.GetSchool();
					else
						msgdata.fromschool = Combat.GetSchool(msgdata.from);
					end
					ChatChannel.ValidateMsg(msgdata,success_callback);
					return;
				end
			end
		end

		if(msgdata.to)then
			if(msgdata.toname == nil)then
				Map3DSystem.App.profiles.ProfileManager.GetUserInfo(msgdata.to, "ChatChannelValidateMsg", function(msg)
					if(msg and msg.users and msg.users[1]) then
						local name = msg.users[1].nickname;
						if(name)then			
							msgdata.toname = name;
							ChatChannel.ValidateMsg(msgdata,success_callback);
						end
					end	
				end, "access plus 20 minutes");

				return;
			elseif(not ignore_vip and msgdata.toisvip == nil)then
				if(msgdata.to == System.App.profiles.ProfileManager.GetNID())then
					msgdata.toisvip = VIP.IsVIPAndActivated();
					ChatChannel.ValidateMsg(msgdata,success_callback);
					return;
				else
					System.App.profiles.ProfileManager.GetUserInfo(msgdata.to, "UpdateUserInfoInMemoryAfterSellItem", 
						function(msg) 
							local myInfo = ProfileManager.GetUserInfoInMemory(msgdata.to);
							if(myInfo and myInfo.energy) then
								msgdata.toisvip = myInfo.energy > 0;
							else
								msgdata.toisvip = false;
							end
							ChatChannel.ValidateMsg(msgdata,success_callback);
						end, "access plus 1 hour");
					return;
				end
			elseif(msgdata.toschool == nil)then
				if(msgdata.to == System.App.profiles.ProfileManager.GetNID())then
					msgdata.toschool = Combat.GetSchool();
				else
					msgdata.toschool = Combat.GetSchool(msgdata.to);
				end
				ChatChannel.ValidateMsg(msgdata,success_callback);
				return;
			end
		end
	end

	if(success_callback and type(success_callback)=="function")then
		success_callback(msgdata);
	end
end

local apply_msg_template = {
	ChannelIndex = EnumChannels.Region,
	words = "申请发送中...",
}
local msg_send_succeed_template = {
	ChannelIndex = EnumChannels.Region,
	words = "发送成功",
}
--[[---------------------------------------------------------------------------------------------------
根据消息类型分别发送至服务器
--]]---------------------------------------------------------------------------------------------------
function ChatChannel.SendToServer(msgdata)
	if(System.options.mc) then
		-- disable chat in paracraft
		ChatChannel.AppendChat( msgdata );
		return
	end

	if (msgdata.ChannelIndex == EnumChannels.NearBy or msgdata.ChannelIndex == EnumChannels.Region) then
		local msg_str = ChatMessage.CompressMsg(msgdata)
		LOG.std(nil, "debug", "chat", "send chat:"..(msg_str or ""));
		if(msgdata.ChannelIndex == EnumChannels.Region) then
			Map3DSystem.GSL_client:SendChat(msg_str, nil, function()
				ChatChannel.AppendChat( msgdata );
			end);
			return;
		else
			Map3DSystem.GSL_client:AddRealtimeMessage({name="chat", value=msg_str,});
		end
	elseif(msgdata.ChannelIndex == EnumChannels.AllTeam)then
		NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClientServicePage.lua");
		local LobbyClientServicePage = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClientServicePage");
		LobbyClientServicePage.SentChatMessage(msgdata);
	elseif(msgdata.ChannelIndex == EnumChannels.Private) then
		if(tostring(msgdata.to) == tostring(System.User.nid)) then
			return;
		end
		if(msgdata.to)then
			local buffer = ChatChannel.JID_Buffer[msgdata.to];
			if(not buffer)then
				buffer = {};
				ChatChannel.JID_Buffer[msgdata.to] = buffer;
			end

			if(buffer.jid and buffer.chatwnd )then
				buffer.chatwnd:SendMSGToServer(msgdata.words);
			else
				System.App.profiles.ProfileManager.GetJID(msgdata.to, function(jid)
					if(jid)then
						ChatChannel.JID_Buffer[msgdata.to].jid = jid;
						local param = {[1] = jid};
						local chatwnd = ChatWnd:CreateGetWnd(param);
						ChatChannel.JID_Buffer[msgdata.to].chatwnd = chatwnd;
						chatwnd:SendMSGToServer(msgdata.words);
					end
				end);
			end
		end
	elseif(msgdata.ChannelIndex == EnumChannels.Team or msgdata.ChannelIndex == EnumChannels.Trade)then
		-- for team message
		MyCompany.Aries.Team.TeamClientLogics:SendTeamChatMessage(msgdata.words);
		-- since we will receive a message via the IM server, we will not append the chat text locally. 
		return;
	elseif(msgdata.ChannelIndex == EnumChannels.Home)then
		-- for home group message
		FamilyChatWnd.SendMSG(msgdata.words);
	elseif(msgdata.ChannelIndex == EnumChannels.System) then
	
	elseif(msgdata.ChannelIndex == EnumChannels.BroadCast) then
		if(msgdata.words and string.match(msgdata.words,"lobby|(.+)|lobby"))then
			local gsid = 12049;
			local hasItem,guid = ItemManager.IfOwnGSItem(gsid);
			if(not hasItem)then
				return;
			end
			local msg_str = ChatMessage.CompressMsg(msgdata);
			Map3DSystem.GSL_client:SendChat(msg_str, true, function()
				ChatChannel.AppendChat( msgdata );
			end);
			return
		end
		if(msgdata.words) then
			msgdata.words = SmileyPage.RemoveSmiley(msgdata.words);
			if(_guihelper.GetTextWidth(msgdata.words) > 250) then
				_guihelper.MessageBox("广播消息只能单行, 您输入的消息太长了");
				return;
			end
		end
		local msg_str = ChatMessage.CompressMsg(msgdata);
		local broadcast_stone_gsid;
		local purchase_exid;
		local stone_name = "传音石";
		if(System.options.version == "kids" ) then
			broadcast_stone_gsid = 12023;
			local hasItem = ItemManager.IfOwnGSItem(12022);
			if(hasItem) then
				broadcast_stone_gsid = 12022;
			end
			--purchase_exid = 1494;
		else
			broadcast_stone_gsid = 12018;
		end
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(broadcast_stone_gsid);
		if(gsItem) then
			stone_name = gsItem.template.name;
		end

		-- local n = ChatChannel.GetBroadCast_Tip_Num();
		local function to_send()
			LOG.std(nil, "debug", "chat", "send chat:"..(msg_str or ""));
			--NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClient.lua");
			--local LobbyClient = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClient");
			--LobbyClient:SendServerChatMessage(msg_str);
			--ChatChannel.AppendChat( msgdata );
			
			--消耗传音石
			local hasItem,guid = ItemManager.IfOwnGSItem(broadcast_stone_gsid);
			if(not hasItem)then
				return;
			end
			
			-- TODO: we may need to do this on server side instead of client side. 
			--ItemManager.DestroyItem(guid, 1, function(msg) 
				--if(msg.issuccess) then
					Map3DSystem.GSL_client:SendChat(msg_str, true, function()
						ChatChannel.AppendChat( msgdata );
					end);
				--end
			--end);
		end
		--检测传音石
		local hasItem,guid,_,stone_copies  = ItemManager.IfOwnGSItem(broadcast_stone_gsid);
		if(not hasItem)then
			_guihelper.Custom_MessageBox(format("你没有%s，不能广播！", stone_name),function(result)
				if(result == _guihelper.DialogResult.Yes)then
					local command = System.App.Commands.GetCommand("Profile.Aries.PurchaseItemWnd");
					if(command) then
						command:Call({gsid = broadcast_stone_gsid, exid=purchase_exid});
					end
				end
			end,_guihelper.MessageBoxButtons.YesNo,{show_label = true, yes = "立即购买", no = "以后再说"});
			return;
		else
			if(stone_copies and stone_copies < 100) then
				NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
				_guihelper.Custom_MessageBox(format("发送一条喇叭消息,需要消耗一个%s,确定要发送? 你现在还有%d个%s", stone_name, stone_copies or 0, stone_name),function(result)
					if(result == _guihelper.DialogResult.Yes)then
						to_send();
						--ChatChannel.SetBroadCast_Tip_Num(n+1);
					end
				end,_guihelper.MessageBoxButtons.YesNo,{show_label = true, yes = "立即发送", no = "取消"});
			else
				to_send();
			end
		end
		return

		
	else
		return;
	end

	ChatChannel.AppendChat( msgdata );
end
function ChatChannel.SetBroadCast_Tip_Num(n)
	local nid = Map3DSystem.User.nid;
	local key = string.format("ChatChannel.GetBroadCast_Tip_Num_%d",nid);
	local v = MyCompany.Aries.Player.SaveLocalData(key, n or 0);
end
function ChatChannel.GetBroadCast_Tip_Num()
	local nid = Map3DSystem.User.nid;
	local key = string.format("ChatChannel.GetBroadCast_Tip_Num_%d",nid);
	local v = MyCompany.Aries.Player.LoadLocalData(key, 0);
	return v;
end
function ChatChannel.Is_Keepwork_Channel(index)
    if(index ~= nil and index >= ChatChannel.EnumChannels.KpNearBy and index <= ChatChannel.EnumChannels.KpMax)then
        return true;
    end
end

