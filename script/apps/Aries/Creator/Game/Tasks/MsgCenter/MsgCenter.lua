--[[
Title: MsgCenter
Author(s): yangguiyi
Date: 2020/10/10
Desc:  
Use Lib:
-------------------------------------------------------
local MsgCenter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MsgCenter/MsgCenter.lua");
MsgCenter.Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local MsgCenter = NPL.export();
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
commonlib.setfield("MyCompany.Aries.Creator.Game.MsgCenter.MsgCenter", MsgCenter);
local page;
MsgCenter.isOpen = false
MsgCenter.server_data = {}

-- 与服务器的类型对应
MsgCenter.MsgType = {
	all = 0,
	organization = 1,
	system = 2,
	interaction = 3,
}
-- 与服务器的类型对应
MsgCenter.InteractionType = {
	fans = 1, 				--粉丝关注
	comment = 2, 			--评论
	like = 3, 				--点赞
	collect = 4, 			--收藏
	jion = 5, 				--加入项目
}

MsgCenter.ButtonData = {
	{name = "全部", msg_type = MsgCenter.MsgType.all, word_div = [[<div style="width: 32px;height: 16px;margin-left: 37px;margin-top: 10px; background: url(Texture/Aries/Creator/keepwork/MsgCenter/zi_quanbu_32X32_32bits.png#0 0 32 16);"></div>]]},
	{name = "互动消息", msg_type = MsgCenter.MsgType.interaction, word_div = [[<div style="width: 64px;height: 16px;margin-left: 22px;margin-top: 10px; background: url(Texture/Aries/Creator/keepwork/MsgCenter/zi_hudongxiaoxi_32X32_32bits.png#0 0 64 16);"></div>]]},
	{name = "机构消息", msg_type = MsgCenter.MsgType.organization, word_div = [[<div style="width: 64px;height: 16px;margin-left: 22px;margin-top: 10px; background: url(Texture/Aries/Creator/keepwork/MsgCenter/zi_jigouxiaoxi_62X15_32bits.png#0 0 64 16);"></div>]]},
	{name = "系统消息", msg_type = MsgCenter.MsgType.system, word_div = [[<div style="width: 64px;height: 16px;margin-left: 22px;margin-top: 10px; background: url(Texture/Aries/Creator/keepwork/MsgCenter/zi_xitongxiaoxi_32X32_32bits.png#0 0 64 16);"></div>]]},
}

MsgCenter.MsgList = {
	-- {msg_content1 = "希望小学的 ", msg_content2 = " 关注了你", msg_type = MsgCenter.MsgType.guan_zhu, time = 0, color_name = " 啊啊 "},
}

local interaction_type_desc = {
	[MsgCenter.InteractionType.fans] = "关注了你",
	[MsgCenter.InteractionType.comment] = "评论了你的《%s》",
	[MsgCenter.InteractionType.like] = "觉得你的《%s》很赞", 	
	[MsgCenter.InteractionType.collect] = "收藏了你的《%s》", 
	[MsgCenter.InteractionType.jion] = "申请加入项目《%s》", 	
}

-- <div style="line-height:14px;font-size:12px;color:#fced4b;" class='bordertext'>
--     <div style="width: 300;margin-top: 300;margin-left: 100;">
--         <div onclick="test" style="float:left;margin-left:0px;">[公告]恭喜啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊<a style="margin-left:0px;float:left;height:12px;background:url()" name="x" 
--             tooltip="左键私聊, 右键查看" onclick="test" param1='577584263:♚情义☆小宝'>
--                 <div style="float:left;margin-top:-2px;color:#f9f7d4">♚情义☆小宝</div>
--             </a>在【怪物军团(悬赏上古宝藏)】中时运爆发获得了
--             <input tooltip="page://script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid=17577" type="button" style="float:left;margin-top:2px;height:16px;color:#f8f8f8;background:;" value="[残破不堪的木制宝箱]" class='bordertext'/>
--             </div>
--     </div>

-- </div>

MsgCenter.select_button_index = 1

local FollowList = {}
local ProjectList = {}
local MsgStateList = {}
function MsgCenter.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = MsgCenter.CloseView
end

function MsgCenter.Show()
    if(GameLogic.GetFilters():apply_filters('is_signed_in'))then
        MsgCenter.ShowView()
        return
	end
	
	GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                if result then
					MsgCenter.ShowView()
                end
            end, 500)
        end
	end)
end

function MsgCenter.ShowView()
	MsgCenter.InitData()
	local view_width = 640
	local view_height = 613
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/MsgCenter/MsgCenter.html",
			name = "MsgCenter.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -view_width/2,
				y = -view_height/2,
				width = view_width,
				height = view_height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	
	MsgCenter.isOpen = true
	MsgCenter.RequestAllMsg()
	
end

function MsgCenter.InitData()
	FollowList = {}
	ProjectList = {}
	MsgStateList = {}
	MsgCenter.server_data = {}
	MsgCenter.select_button_index = 1
end

function MsgCenter.FlushView(only_refresh_grid)
	if only_refresh_grid then
		local gvw_name = "item_gridview";
		local node = page:GetNode(gvw_name);
		pe_gridview.DataBind(node, gvw_name, false);
	else
		MsgCenter.OnRefresh()
	end
end

function MsgCenter.OnRefresh()
    if(page)then
        page:Refresh(0.1);
    end
end

function MsgCenter.ClickItem(index)
	if index == MsgCenter.select_button_index then
		return
	end
	
	MsgCenter.select_button_index = index
	local click_data = MsgCenter.ButtonData[MsgCenter.select_button_index]

	if click_data.msg_type == MsgCenter.MsgType.all then
		MsgCenter.RequestAllMsg()
	else
		MsgCenter.RequestMsgByType(click_data.msg_type)
	end
end

function MsgCenter.CloseView()
	MsgCenter.isOpen = false
end

function MsgCenter.RequestAllMsg()
	keepwork.msgcenter.all({
	}, function(err, msg, data)
		if err == 200 then
			MsgCenter.server_data = data.data
			
			MsgCenter.HandleData(MsgCenter.server_data, function()
				MsgCenter.FlushView()
				MsgCenter.ChangeMsgState()
			end)
        end
	end)  
end

function MsgCenter.RequestMsgByType(type)
	keepwork.msgcenter.byType({
		msgType = type,
		-- orgId = 0,
	},function(err, msg, data)
		MsgCenter.server_data = data.data
		MsgCenter.HandleData(MsgCenter.server_data, function()
			MsgCenter.FlushView()
			MsgCenter.ChangeMsgState()
		end)
	end)
end
-- {
-- 	createdAt="2020-11-24T02:13:11.000Z",
-- 	id=30,
-- 	msg={ nickname="yang1", userId=704, username="yang1" },
-- 	msgType=3,
-- 	readStatus=0,
-- 	toUserId=623,
-- 	type=1,
-- 	updatedAt="2020-11-24T02:13:11.000Z" 
--   },
-- {
-- 	all=1,
-- 	createdAt="2020-11-19T08:16:41.000Z",
-- 	id=8,
-- 	msg={ text="<p>test-2</p>", type=0 },
-- 	msgType=2,
-- 	readStatus=0,
-- 	receivers="",
-- 	updatedAt="2020-11-19T08:16:41.000Z",
-- 	username="chen" 
--   },
--   {
-- 	all=1,
-- 	createdAt="2020-11-19T08:00:53.000Z",
-- 	id=6,
-- 	msg={ text="<p>test</p>", type=0 },
-- 	msgType=2,
-- 	readStatus=0,
-- 	receivers="",
-- 	updatedAt="2020-11-19T08:00:53.000Z",
-- 	username="chen" 
--   } 
function MsgCenter.HandleData(data, updata_cb)
	if data == nil then
		return
	end
	MsgCenter.MsgList = {}

	local click_data = MsgCenter.ButtonData[MsgCenter.select_button_index] or {}
	local msg_type = click_data.msg_type or 1
	local search_id_list = {}
	local pro_id_list = {}
	local profile = KeepWorkItemManager.GetProfile();
	local name = profile.nickname or profile.username
	for i, v in ipairs(data.rows) do
		local msg_data = {}
		msg_data.msg_type = v.msgType
		msg_data.time_desc = MsgCenter.GetTimeDescByAtTime(v.createdAt)
		msg_data.server_data = v
		local msg = v.msg or {}
		if v.msgType == MsgCenter.MsgType.interaction then
			local interaction_type = v.type

			msg_data.msg_content1 = msg.schoolName and string.format("%s的", msg.schoolName) or ""
			local name = msg.nickname or msg.username
			msg_data.color_name = name or ""	
			msg_data.interaction_type = interaction_type

			msg_data.msg_content2 = interaction_type_desc[interaction_type] or ""	
			local bt_value = '回关'
			local bt_bg = "Texture/Aries/Creator/keepwork/MsgCenter/btn_lan_32X32_32bits.png#0 0 32 32:8 8 8 8"

			-- 如果是关注消息 要判断是否相互关注
			if interaction_type == MsgCenter.InteractionType.fans then
				search_id_list[#search_id_list + 1] = msg.userId
			else
				msg_data.msg_content2 = msg.projectName and string.format(interaction_type_desc[interaction_type], msg.projectName) or ""

				if interaction_type == MsgCenter.InteractionType.jion then
					pro_id_list[#pro_id_list + 1] = msg.projectId
				end
			end

			
		else
			-- 新注册用户信息 前端特殊处理
			if v.msgType == MsgCenter.MsgType.system and msg.type == 1 then
				
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
		
		MsgCenter.MsgList[#MsgCenter.MsgList + 1] = msg_data
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

function MsgCenter.GetTimeDescByAtTime(at_time)
	at_time = at_time or ""
	-- at_time = "2020-09-09T06:52:43.000Z"
	local year, month, day, hour, min, sec = at_time:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
	local time_stamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour) + 8}) -- 这个时间是带时区的 要加8小时
	time_stamp = time_stamp + min * 60 + sec

	local date_desc = os.date("%Y-%m-%d", time_stamp)
	local time_desc = os.date("%H:%M", time_stamp)

	local desc = string.format("%s %s", date_desc, time_desc)
	return desc
end

function MsgCenter.GetDivBtnDesc(data)

	if nil == data then
		return ""
	end
	local desc = ""
	-- 要判断是否互关
	local id = data.server_data.msg.userId or 0
	if data.interaction_type == MsgCenter.InteractionType.fans then
		
		local is_follow = MsgCenter.IsFollow(id)

		desc = 	[[<input type="button" value='关注' name = '<%=XPath("this") %>' onclick="<%=OnClickFollow%>" param1='<%=Eval("index") %>' 
		style="float: left;margin-left: 18px; margin-top:32px;width:70px;height:28px;
		background:url(Texture/Aries/Creator/keepwork/MsgCenter/btn_lan_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]

		if is_follow then
			data.is_friend = true

			desc = 	[[<input type="button" value='互相关注' name = '<%=XPath("this") %>' onclick="<%=OnClickCancelFollow%>" param1='<%=Eval("index") %>' 
			style="float: left;margin-left: 18px; margin-top:32px;width:70px;height:28px;
			background:url(Texture/Aries/Creator/keepwork/MsgCenter/btn_lan_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
		end
	elseif data.interaction_type == MsgCenter.InteractionType.comment then
		desc = 	[[<input type="button" value='查看' name = '<%=XPath("this") %>' onclick="<%=OnCommentCheck%>" param1='<%=Eval("index") %>' 
		style="float: left;margin-left: 18px; margin-top:32px;width:70px;height:28px;
		background:url(Texture/Aries/Creator/keepwork/MsgCenter/btn_hui_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
	elseif data.interaction_type == MsgCenter.InteractionType.jion then
		desc = 	[[<input type="button" value='允许' name = '<%=XPath("this") %>' onclick="OnClickAllowJoin" param1='<%=Eval("index") %>' 
		style="float: left;margin-left: 18px; margin-top:32px;width:70px;height:28px;
		background:url(Texture/Aries/Creator/keepwork/MsgCenter/btn_lv_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]

		-- 要判断是否已允许
		local pro_id = data.server_data.msg.projectId or 0
		local msg_id = data.server_data.msg.id
		local pro_data = MsgCenter.GetProjectData(pro_id, id, msg_id)
		if pro_data.state == 1 then
			desc = 	[[<input type="button" value='已允许' name = '<%=XPath("this") %>' onclick="" enabled="false" param1='<%=Eval("index") %>' 
			style="float: left;margin-left: 18px; margin-top:32px;width:70px;height:28px;
			background:url(Texture/Aries/Creator/keepwork/MsgCenter/btn_lv_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
		elseif pro_data.state == 2 then
			desc = 	[[<input type="button" value='已拒绝' name = '<%=XPath("this") %>' onclick="" enabled="false" param1='<%=Eval("index") %>' 
			style="float: left;margin-left: 18px; margin-top:32px;width:70px;height:28px;
			background:url(Texture/Aries/Creator/keepwork/MsgCenter/btn_lv_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
		elseif pro_data.state == nil then
			desc = 	[[<input type="button" value='已拒绝' name = '<%=XPath("this") %>' onclick="" enabled="false" param1='<%=Eval("index") %>' 
			style="float: left;margin-left: 18px; margin-top:32px;width:70px;height:28px;
			background:url(Texture/Aries/Creator/keepwork/MsgCenter/btn_lv_32X32_32bits.png#0 0 32 32:8 8 8 8);" />]]
		end	
	end
	return desc
end

function MsgCenter.OnClickCancelFollow(data)
	local userId = data.server_data.msg.userId or 0
	_guihelper.MessageBox("你确定要取消关注吗？", function()
		keepwork.user.unfollow({
			objectType = 0,
			objectId = userId,
		},function(err, msg, data)
			if err == 200 then
				GameLogic.AddBBS("statusBar", L"取消关注成功", 5000, "0 255 0");
				MsgCenter.HandleData(MsgCenter.server_data, function()
					MsgCenter.FlushView(true)
				end)
			end
		end)
	end)
end

function MsgCenter.OnClickFollow(data)
	local userId = data.server_data.msg.userId or 0
	keepwork.user.follow({
		objectType = 0,
		objectId = userId,
	},function(err, msg, data)
		if err == 200 then
			GameLogic.AddBBS("statusBar", L"关注成功", 5000, "0 255 0");
			MsgCenter.HandleData(MsgCenter.server_data, function()
				MsgCenter.FlushView(true)
			end)
		end
	end)
end

function MsgCenter.OnCommentCheck(data)
	local pro_id = data.server_data.msg.projectId or 0
    local httpwrapper_version = HttpWrapper.GetDevVersion();
	local url = GameLogic.GetFilters():apply_filters('get_keepwork_url');
	url = url .. "/pbl/project/" .. pro_id;
	GameLogic.GetFilters():apply_filters('open_keepwork_url', url);
end

function MsgCenter.OnClickAllowJoin(data)
	local msg = data.server_data.msg or {}
	local msg_id = msg.id
	HttpWrapper.Create("keepwork.msgcenter.jion", "%MAIN%/core/v0/applies/" .. msg_id , "PUT", true)
	keepwork.msgcenter.jion({
		id = msg_id,
		state = 1, --1同意 2拒绝
	}, function(err, msg, data)
		if err == 200 then
			MsgCenter.HandleData(MsgCenter.server_data, function()
				MsgCenter.FlushView(true)
			end)
		end
	end)
end

-- 我是否已经关注了某人 id 某人的id
function MsgCenter.IsFollow(id)
    if FollowList[id] then
        return true
    end

    return false
end

-- 我是否已经关注了某人 id 某人的id
function MsgCenter.GetProjectData(pro_id, userId, msg_id)
	for key, v in pairs(ProjectList) do
		if v.objectId == pro_id and v.userId == userId and v.id == msg_id then
			return v
		end
	end

	return {}
end

function MsgCenter.ChangeMsgState()
	if #MsgStateList == 0 then
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

function MsgCenter.IsVisible()
	return page:IsVisible()
end