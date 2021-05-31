--[[
Title: Email
Author(s): yangguiyi,pbb
Date: 2020/10/10 2021.3.24
Desc:  
Use Lib:
-------------------------------------------------------
local Email = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/Email.lua");
Email.Show();
--]]

local Email = NPL.export();
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
local EmailManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Email/EmailManager.lua");
local page;
Email.isOpen = false
Email.email_list = {}
Email.server_data = {}
Email.conten_data = {{},}
-- 与服务器的类型对应
Email.MsgType = {
	all = 0,
	organization = 1,
	system = 2,
	interaction = 3,
	email = 4,
}
-- 与服务器的类型对应
Email.InteractionType = {
	fans = 1, 				--粉丝关注
	comment = 2, 			--评论
	like = 3, 				--点赞
	collect = 4, 			--收藏
	jion = 5, 				--加入项目
}

Email.ButtonData = {
	{name = "邮件", msg_type = Email.MsgType.email, word_div = [[<div style="width: 64px;height: 16px;margin-left: 22px;margin-top: 10px; background: url(Texture/Aries/Creator/keepwork/Email/zi1_61X15_32bits.png#0 0 64 16);"></div>]]},
	{name = "互动消息", msg_type = Email.MsgType.interaction, word_div = [[<div style="width: 64px;height: 16px;margin-left: 22px;margin-top: 10px; background: url(Texture/Aries/Creator/keepwork/Email/zi2_61X15_32bits.png#0 0 64 16);"></div>]]},
	{name = "机构消息", msg_type = Email.MsgType.organization, word_div = [[<div style="width: 64px;height: 16px;margin-left: 22px;margin-top: 10px; background: url(Texture/Aries/Creator/keepwork/Email/zi3_61X15_32bits.png#0 0 64 16);"></div>]]},
	{name = "系统消息", msg_type = Email.MsgType.system, word_div = [[<div style="width: 64px;height: 16px;margin-left: 22px;margin-top: 10px; background: url(Texture/Aries/Creator/keepwork/Email/zi4_61X15_32bits.png#0 0 64 16);"></div>]]},
}

Email.MsgList = {
	-- {msg_content1 = "希望小学的 ", msg_content2 = " 关注了你", msg_type = Email.MsgType.guan_zhu, time = 0, color_name = " 啊啊 "},
}

local interaction_type_desc = {
	[Email.InteractionType.fans] = "关注了你",
	[Email.InteractionType.comment] = "评论了你的《%s》",
	[Email.InteractionType.like] = "觉得你的《%s》很赞", 	
	[Email.InteractionType.collect] = "收藏了你的《%s》", 
	[Email.InteractionType.jion] = "申请加入项目《%s》", 	
}


Email.select_button_index = 1

local FollowList = {}
local ProjectList = {}
local MsgStateList = {}
local UnReadMsgData = {}
function Email.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = Email.CloseView
end

function Email.GetPageCtrl()
	return page
end

function Email.Show()
    if(GameLogic.GetFilters():apply_filters('is_signed_in'))then
        Email.ShowView()
        return
	end
	
	GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                if result then
					Email.ShowView()
                end
            end, 500)
        end
	end)
end

function Email.ShowView()
	Email.InitData()
	local view_width = 1040
	local view_height = 620
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Email/Email.html",
			name = "Email.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -view_width/2,
				y = -view_height/2,
				width = view_width,
				height = view_height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	
	Email.isOpen = true
	--Email.RequestAllMsg()
	Email.GetUnReadMsg()
	EmailManager.Init()
end

function Email.IsShowEmail()
	return Email.select_button_index == 1
end

function Email.InitData()
	FollowList = {}
	ProjectList = {}
	MsgStateList = {}
	Email.server_data = {}
	Email.select_button_index = 1
end

function Email.FlushView(only_refresh_grid)
	if only_refresh_grid then
		local gvw_name = "item_gridview";
		local node = page:GetNode(gvw_name);
		pe_gridview.DataBind(node, gvw_name, false);
	else
		Email.OnRefresh()
	end
end

function Email.OnRefresh()
    if(page)then
        page:Refresh(0.1);
    end
end

function Email.ClickItem(index)
	if index == Email.select_button_index then
		return
	end
	
	Email.select_button_index = index
	local click_data = Email.ButtonData[Email.select_button_index]

	if click_data.msg_type == Email.MsgType.all then
		Email.RequestAllMsg()
	elseif click_data.msg_type == Email.MsgType.email then
		Email.select_email_idx = EmailManager.email_list[1] and EmailManager.email_list[1].id or -1
		Email.ClickEmailItem(Email.select_email_idx)
	else
		Email.RequestMsgByType(click_data.msg_type)
	end
end

function Email.CloseView()
	Email.isOpen = false
end

function Email.RequestAllMsg()
	keepwork.msgcenter.all({
	}, function(err, msg, data)
		if err == 200 then
			Email.server_data = data.data
			
			Email.HandleData(Email.server_data, function()
				Email.FlushView()
				Email.ChangeMsgState()
			end)
        end
	end)  
end

function Email.GetUnReadMsg()
	keepwork.msgcenter.unReadCount({
    },function(err, msg, data)
        if err == 200 then
			local msgdata = data.data
            UnReadMsgData.orgMsgCount = msgdata.orgMsgCount
			UnReadMsgData.sysMsgCount = msgdata.sysMsgCount
			UnReadMsgData.interactionMsgCount = msgdata.interactionMsgCount
        end
    end)
end

function Email.UpdateUnReadMsg(type)
	if type == Email.MsgType.interaction then
		UnReadMsgData.interactionMsgCount = 0
	elseif type == Email.MsgType.organization then
		UnReadMsgData.orgMsgCount = 0
	elseif type == Email.MsgType.system then
		UnReadMsgData.sysMsgCount = 0
	end
end

function Email.GetUnReadMsgWithType(type)
	if type == Email.MsgType.interaction then
		return UnReadMsgData.interactionMsgCount or 0
	elseif type == Email.MsgType.organization then
		return UnReadMsgData.orgMsgCount or 0
	elseif type == Email.MsgType.system then
		return UnReadMsgData.sysMsgCount or 0
	elseif type == Email.MsgType.email then
		return 0
	end
end

function Email.RequestMsgByType(type)
	keepwork.msgcenter.byType({
		msgType = type,
		-- orgId = 0,
	},function(err, msg, data)
		Email.server_data = data.data
		Email.UpdateUnReadMsg(type)
		Email.HandleData(Email.server_data, function()
			Email.FlushView()
			Email.ChangeMsgState()
		end)
	end)
end

function Email.HandleData(data, updata_cb)
	if data == nil then
		return
	end
	Email.MsgList = {}

	local click_data = Email.ButtonData[Email.select_button_index] or {}
	local msg_type = click_data.msg_type or 1
	local search_id_list = {}
	local pro_id_list = {}
	local profile = KeepWorkItemManager.GetProfile();
	local name = profile.nickname or profile.username
	for i, v in ipairs(data.rows) do
		local msg_data = {}
		msg_data.msg_type = v.msgType
		msg_data.time_desc = Email.GetTimeDescByAtTime(v.createdAt)
		msg_data.server_data = v
		local msg = v.msg or {}
		if v.msgType == Email.MsgType.interaction then
			local interaction_type = v.type

			msg_data.msg_content1 = msg.schoolName and string.format("%s的", msg.schoolName) or ""
			local name = msg.nickname or msg.username
			msg_data.color_name = name or ""	
			msg_data.interaction_type = interaction_type

			msg_data.msg_content2 = interaction_type_desc[interaction_type] or ""	
			local bt_value = '回关'
			local bt_bg = "Texture/Aries/Creator/keepwork/Email/btn_lan_32X32_32bits.png#0 0 32 32:8 8 8 8"

			-- 如果是关注消息 要判断是否相互关注
			if interaction_type == Email.InteractionType.fans then
				search_id_list[#search_id_list + 1] = msg.userId
			else
				msg_data.msg_content2 = msg.projectName and string.format(interaction_type_desc[interaction_type], msg.projectName) or ""

				if interaction_type == Email.InteractionType.jion then
					pro_id_list[#pro_id_list + 1] = msg.projectId
				end
			end

			
		else
			-- 新注册用户信息 前端特殊处理
			if v.msgType == Email.MsgType.system and msg.type == 1 then
				
				msg_data.msg_content1 = string.format([[欢迎来到Paracraft，<div style="float:left;color:#16be3d; text-singleline:true">%s</div>：<br />
				我们很荣幸有你的参与！通过Paracraft，你可以创建自己的3D动画项目、编程项目、网站项目，并将你的作品分享给大家。<br />
				接下来呢？快去创造及探索Paracraft精彩3D世界吧！]], name)

				
			else
				msg_data.msg_content1 = msg.text or ""
			end
		end
		
		-- msgId: 46, msgType: 3
		-- 未读
		if v.readStatus == 0 then
			MsgStateList[#MsgStateList + 1] = {msgId = v.id, msgType = v.msgType}
		end
		
		Email.MsgList[#Email.MsgList + 1] = msg_data
	end
	local profile = KeepWorkItemManager.GetProfile();
	local userId = profile.id;
	keepwork.user.focus({
		userId = userId,
		objectType = 0,
		objectId = {["$in"] = search_id_list},
	},function(err, msg, data)
		FollowList = {}
		for k, v in pairs(data.rows) do
			FollowList[v.objectId] = v
		end

		keepwork.msgcenter.pro_search({
			objectId = {["$in"] = pro_id_list},
		},function(info_err, info_msg, info_data)
			if info_err == 200 then
				ProjectList = info_data.rows

				if updata_cb then
					updata_cb()
				end
			end
			
		end

		)
	end)
end

function Email.GetTimeDescByAtTime(at_time)
	at_time = at_time or ""
	local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(at_time)
	local date_desc = os.date("%Y-%m-%d", time_stamp)
	local time_desc = os.date("%H:%M", time_stamp)
	local desc = string.format("%s %s", date_desc, time_desc)
	return desc
end

function Email.GetDivBtnDesc(data)

	if nil == data then
		return ""
	end
	local desc = ""
	-- 要判断是否互关
	local id = data.server_data.msg.userId or 0
	if data.interaction_type == Email.InteractionType.fans then
		
		local is_follow = Email.IsFollow(id)

		desc = 	[[<input type="button" value='关注' name = '<%=XPath("this") %>' onclick="<%=OnClickFollow%>" param1='<%=Eval("index") %>' 
		style="float: left;margin-left: -10px; margin-top:32px;width:70px;height:28px;
		background:url(Texture/Aries/Creator/keepwork/Email/btn_lan_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]

		if is_follow then
			data.is_friend = true

			desc = 	[[<input type="button" value='互相关注' name = '<%=XPath("this") %>' onclick="<%=OnClickCancelFollow%>" param1='<%=Eval("index") %>' 
			style="float: left;margin-left: -10px; margin-top:32px;width:70px;height:28px;
			background:url(Texture/Aries/Creator/keepwork/Email/btn_lan_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
		end
	elseif data.interaction_type == Email.InteractionType.comment then
		desc = 	[[<input type="button" value='查看' name = '<%=XPath("this") %>' onclick="<%=OnCommentCheck%>" param1='<%=Eval("index") %>' 
		style="float: left;margin-left: -10px; margin-top:32px;width:70px;height:28px;
		background:url(Texture/Aries/Creator/keepwork/Email/btn_hui_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
	elseif data.interaction_type == Email.InteractionType.jion then
		desc = 	[[<input type="button" value='允许' name = '<%=XPath("this") %>' onclick="OnClickAllowJoin" param1='<%=Eval("index") %>' 
		style="float: left;margin-left: -10px; margin-top:32px;width:70px;height:28px;
		background:url(Texture/Aries/Creator/keepwork/Email/btn_lv_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]

		-- 要判断是否已允许
		local pro_id = data.server_data.msg.projectId or 0
		local msg_id = data.server_data.msg.id
		local pro_data = Email.GetProjectData(pro_id, id, msg_id)
		if pro_data.state == 1 then
			desc = 	[[<input type="button" value='已允许' name = '<%=XPath("this") %>' onclick="" enabled="false" param1='<%=Eval("index") %>' 
			style="float: left;margin-left: -10px; margin-top:32px;width:70px;height:28px;
			background:url(Texture/Aries/Creator/keepwork/Email/btn_lv_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
		elseif pro_data.state == 2 then
			desc = 	[[<input type="button" value='已拒绝' name = '<%=XPath("this") %>' onclick="" enabled="false" param1='<%=Eval("index") %>' 
			style="float: left;margin-left: -10px; margin-top:32px;width:70px;height:28px;
			background:url(Texture/Aries/Creator/keepwork/Email/btn_lv_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
		elseif pro_data.state == nil then
			desc = 	[[<input type="button" value='已拒绝' name = '<%=XPath("this") %>' onclick="" enabled="false" param1='<%=Eval("index") %>' 
			style="float: left;margin-left: -10px; margin-top:32px;width:70px;height:28px;
			background:url(Texture/Aries/Creator/keepwork/Email/btn_lv_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
		end	
	end
	return desc
end

function Email.OnClickCancelFollow(data)
	local userId = data.server_data.msg.userId or 0
	_guihelper.MessageBox("你确定要取消关注吗？", function()
		keepwork.user.unfollow({
			objectType = 0,
			objectId = userId,
		},function(err, msg, data)
			if err == 200 then
				GameLogic.AddBBS("statusBar", L"取消关注成功", 5000, "0 255 0");
				Email.HandleData(Email.server_data, function()
					Email.FlushView(true)
				end)
			end
		end)
	end)
end

function Email.OnClickFollow(data)
	local userId = data.server_data.msg.userId or 0
	keepwork.user.follow({
		objectType = 0,
		objectId = userId,
	},function(err, msg, data)
		if err == 200 then
			GameLogic.AddBBS("statusBar", L"关注成功", 5000, "0 255 0");
			Email.HandleData(Email.server_data, function()
				Email.FlushView(true)
			end)
		end
	end)
end

function Email.OnCommentCheck(data)
	local pro_id = data.server_data.msg.projectId or 0
    local httpwrapper_version = HttpWrapper.GetDevVersion();
	local url = GameLogic.GetFilters():apply_filters('get_keepwork_url');
	url = url .. "/pbl/project/" .. pro_id;
	GameLogic.GetFilters():apply_filters('open_keepwork_url', url);
end

function Email.OnClickAllowJoin(data)
	local msg = data.server_data.msg or {}
	local msg_id = msg.id
	HttpWrapper.Create("keepwork.msgcenter.jion", "%MAIN%/core/v0/applies/" .. msg_id , "PUT", true)
	keepwork.msgcenter.jion({
		id = msg_id,
		state = 1, --1同意 2拒绝
	}, function(err, msg, data)
		if err == 200 then
			Email.HandleData(Email.server_data, function()
				Email.FlushView(true)
			end)
		end
	end)
end

-- 我是否已经关注了某人 id 某人的id
function Email.IsFollow(id)
    if FollowList[id] then
        return true
    end

    return false
end

-- 我是否已经关注了某人 id 某人的id
function Email.GetProjectData(pro_id, userId, msg_id)
	for key, v in pairs(ProjectList) do
		if v.objectId == pro_id and v.userId == userId and v.id == msg_id then
			return v
		end
	end

	return {}
end

function Email.ChangeMsgState()
	if #MsgStateList == 0 then
		DockPage.HandMsgCenterMsgData()
		return
	end
	keepwork.msgcenter.status({
		data = MsgStateList,
	}, function(err, msg, data)
		if err == 200 then
			DockPage.HandMsgCenterMsgData()
		end
	end)
end

function Email.IsVisible()
	return page:IsVisible()
end

function Email.ClickEmailItem(index)
	if index < 0 then
		Email.OnRefresh()
		return
	end
	-- if index == Email.select_email_idx then
	-- 	return 
	-- end
	Email.select_email_idx = index
	EmailManager.SetEamilReaded(index)
	EmailManager.ReadEamil(index)
end


function Email.OnClickDeleteAll()
	_guihelper.MessageBox(L"是否需要删除全部邮件，删除后不可找回", function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			local ids = EmailManager.GetAllEmailIds()
			EmailManager.DeleteEmail(ids)
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

local isgetall = false
function Email.OnClickGetAll()
	if not isgetall then
		local ids = EmailManager.GetAllUnGetRewardEmailIds()
		EmailManager.GetEmailReward(ids)
		EmailManager.SetEamilReaded(ids)
		isgetall = true
	end
	commonlib.TimerManager.SetTimeout(function()
		isgetall = false
	end, 500)
end


function Email.OnClickDelete()
	_guihelper.MessageBox(L"是否需要删除当前邮件，删除后不可找回", function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			local id = Email.select_email_idx
			EmailManager.DeleteEmail(id)
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

local isget = false
function Email.OnClickGet()
	if not isget then
		local id = Email.select_email_idx
		if EmailManager.IsHaveReward(id) then
			EmailManager.GetEmailReward(id)
		else
			GameLogic.AddBBS(nil,"此邮件奖励已经领取过了~")
		end		
		isget = true
	end
	commonlib.TimerManager.SetTimeout(function()
		isget = false
	end, 500)
end

function Email.SetEmailList(email_list)
	Email.email_list = email_list
end

function Email.GetStrWithLength(str,length)
	--print("GetStrWithLength=====",str,length)
	local length = length or 0
	local str = str or ""
	local nStrLength = ParaMisc.GetUnicodeCharNum(str);
	if nStrLength > length then
		return ParaMisc.UniSubString(str, 1, length).."...";
	else
		return str;
	end
	
end

function Email.GetEmailContent(str)
	-- print(str)
	local str = string.gsub(str,"<br>","<br />")
	str = string.gsub(str,"&nbsp"," ")
	str = string.gsub(str,"<p>","")
	str = string.gsub(str,"</p>","")
	str = string.gsub(str,";","")
	str = string.gsub(str,"&lt","<")
	str = string.gsub(str,"&gt",">")
	str = string.gsub(str,"\\"," ")
	--print(str)
	return str
end