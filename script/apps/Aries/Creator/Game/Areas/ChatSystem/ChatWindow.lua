--[[
Title: Multi-functional Chat Window 
Author(s): zrf, refactored by LiXizhi
Date: 2011/3/9
Desc:  the chat window is comprised of the chat log page and the chat edit page. 
 1. The log page displays all the history messages in several categories. 
 2. The edit page allows the user to post text and actions to any specified channel. 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
MyCompany.Aries.ChatSystem.ChatWindow.ShowAllPage();
MyCompany.Aries.ChatSystem.ChatWindow.HideAll();
-------------------------------------------------------
]]
if(not System.options.mc) then
	NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatWindow.lua");
	return
end

NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatEdit.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/SmileyPage.lua");

local Scene = commonlib.gettable("MyCompany.Aries.Scene");
local MsgHandler = commonlib.gettable("MyCompany.Aries.Combat.MsgHandler");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local BattlefieldClient = commonlib.gettable("MyCompany.Aries.Battle.BattlefieldClient");
local Encoding = commonlib.gettable("commonlib.Encoding");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local ChatWindow = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatWindow");
local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");
local SmileyPage = commonlib.gettable("MyCompany.Aries.ChatSystem.SmileyPage");
local Player = commonlib.gettable("MyCompany.Aries.Player");

-- max number of broadcast message to display
local max_broadcast_message = 3;
-- we will clear the broadcast message from the ui after this amount of time. 
local max_broadcast_msg_show_time = 60000;
-- the default show positions.
ChatWindow.DefaultUIPos = {
	RestoreBtn = {alignment = "_lb", left = 2, top = -254+75, width = 21, height = 24, background = "Texture/Aries/ChatSystem/jiahao_32bits.png;0 0 21 24"},
	LogWnd = {alignment = "_lb", left = 2, top = -330, width = 320, height = 300},
	EditWnd = {alignment = "_lb", left = 2, top = -30, width = 700, height = 30},
	ParentWnd = {alignment = "_lb", left = 2, top = -335, width = 700, height = 330},
}

-- public: call this once at init time. 
function ChatWindow.InitSystem()
	if(ChatWindow.IsInited) then
		return
	end
	if(System.options.IsMobilePlatform) then
		ChatWindow.DefaultUIPos = {
			RestoreBtn = {alignment = "_lb", left = 2, top = -254+75, width = 21, height = 24, background = "Texture/Aries/ChatSystem/jiahao_32bits.png;0 0 21 24"},
			EditWnd = {alignment = "_lb", left = 2, top = -45, width = 700, height = 50},
			LogWnd = {alignment = "_lb", left = 2, top = -330, width = 700, height = 280},
			ParentWnd = {alignment = "_lb", left = 2, top = -335, width = 700, height = 330},
		}
	end
	ChatWindow.BeShowAll = false;
	ChatWindow.IsInited = true;
	ChatWindow.minimized = false; -- start minimized. 
	ChatChannel.SetAppendEventCallback(ChatWindow.AppendChatMessage);
	ChatChannel.AddFilter(ChatWindow.BadWordsFilter);
	ChatChannel.AddFilter(ChatWindow.ChatCommandFilter);
	-- ChatChannel.AddFilter(ChatWindow.BattleFieldFilter);
end

-- show the chat log page and the edit box page
-- @param bSetFocus: default to false. if true, the editbox will have the focus. 
function ChatWindow.ShowAllPage(bSetFocus)
	if(System.options.IsMobilePlatform) then
		MyCompany.Aries.Creator.Game.Desktop.ShowMobileDesktop(false);
	end
	ChatWindow.BeShowAll = if_else(bSetFocus,true,false);
	ChatWindow.ShowChatLogPage();
	ChatWindow.ShowEditPage(bSetFocus);
	ChatWindow.isshow = true;
	local _parentwnd = ChatWindow.CreateGetParentWnd();
	if(_parentwnd) then
		_parentwnd.visible = true;
	end
	ChatWindow.CreateGetRestoreBtn().visible = false;
	ChatWindow.minimized = false;
end

-- show without toggling. 
function ChatWindow.Show()
	if(not ChatWindow.isshow) then
		if(ChatWindow.minimized) then
			ChatWindow.CreateGetRestoreBtn().visible = true;
		else
			ChatWindow.ShowAllPage();
		end
	end
end

--[[---------------------------------------------------------------------------------------------------
隐藏所有聊天窗口
--]]---------------------------------------------------------------------------------------------------
function ChatWindow.HideAll()
	ChatWindow.HideChatLog();
	ChatWindow.HideEdit();
	ChatWindow.isshow = false;
	local _parentwnd = ChatWindow.CreateGetParentWnd();
	if(_parentwnd) then
		_parentwnd.visible = false;
	end
	ChatWindow.CreateGetRestoreBtn().visible = false;
end

-- hide only the chat edit page
function ChatWindow.HideEdit()
	ChatEdit.Hide();
end

-- hide only the chat log page
function ChatWindow.HideChatLog()
	local _parent = ParaUI.GetUIObject("ChatLogPage");
	if(_parent and _parent:IsValid()) then
		_parent.visible = false;
	end
	ChatWindow.is_shown = false;	
	ChatWindow.is_fade_out = true;
end

-- return true if page is shown after switch
function ChatWindow.ShowSwitch()
	if(ChatWindow.is_shown == true)then
		ChatWindow.HideChatLog()
		return false;
	else
		ChatWindow.ShowChatLogPage();
		ChatWindow.RefreshTreeView();
		return true;
	end
end

-- different size mode
local size_modes = {
	250,
	350,
	520,
}
function ChatWindow.ToggleChatWindowSize(send_msg,words)
	--ChatWindow.size_mode = ((ChatWindow.size_mode or 0) + 1) % (#size_modes);
	--local new_height = size_modes[ChatWindow.size_mode+1];
--
	--local params = ChatWindow.DefaultUIPos.ParentWnd;
	--params.top = params.top - (new_height - params.height);
	--params.height = new_height;
	--local _parentwnd = ChatWindow.CreateGetParentWnd();
	--_parentwnd:Reposition(params.alignment, params.left, params.top, params.width, params.height);
	--if(ChatWindow.page) then
		--ChatWindow.page:Refresh(0.01);
		--local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			--ChatWindow.RefreshScrollBar();
		--end})
		--mytimer:Change(500, nil);
	--end
	local params = ChatWindow.DefaultUIPos.ParentWnd;
	local new_height = 0;
	if(send_msg) then
		local rows = ChatWindow.GetMsgNeedRows(words);
		new_height = rows*14;
	else
		new_height = params.height;
	end

	params.top = params.top - (new_height - params.height);
	params.height = new_height;
	local _parentwnd = ChatWindow.CreateGetParentWnd();
	_parentwnd:Reposition(params.alignment, params.left, params.top, params.width, params.height);
	if(ChatWindow.page) then
		ChatWindow.page:Refresh(0.01);
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			ChatWindow.RefreshScrollBar();
		end})
		mytimer:Change(500, nil);
	end
end

-- return true if page is shown after switch
function ChatWindow.ToggleShow()
	if(ChatWindow.is_shown) then
		ChatWindow.OnClickWndMinimize();
		return false;
	else
		ChatWindow.OnClickWndRestore();
		return true;
	end
end


function ChatWindow.CreateGetParentWnd()
	if(ChatWindow.DefaultUIPos.ParentWnd) then
		local _parent = ParaUI.GetUIObject("ChatAreaParentWnd");
		if(not _parent:IsValid()) then
			_parent = ParaUI.CreateUIObject("container", "ChatAreaParentWnd", ChatWindow.DefaultUIPos.ParentWnd.alignment, ChatWindow.DefaultUIPos.ParentWnd.left, ChatWindow.DefaultUIPos.ParentWnd.top, ChatWindow.DefaultUIPos.ParentWnd.width, ChatWindow.DefaultUIPos.ParentWnd.height);
			_parent.background = "";
			_parent.zorder = -1;
			_parent:GetAttributeObject():SetField("ClickThrough", true);
			--_parent.ondragbegin = [[;ParaUI.AddDragReceiver("root");]];
			--_parent.candrag = true;
			_parent:AttachToRoot();
		end
		return _parent;
	end
end

-- create get the restore chat window button
function ChatWindow.CreateGetRestoreBtn()
	local _parent = ParaUI.GetUIObject("RestoreChatWndBtn");
	if(not _parent:IsValid()) then

		_parent = ParaUI.CreateUIObject("button", "RestoreChatWndBtn", ChatWindow.DefaultUIPos.RestoreBtn.alignment, ChatWindow.DefaultUIPos.RestoreBtn.left, ChatWindow.DefaultUIPos.RestoreBtn.top, ChatWindow.DefaultUIPos.RestoreBtn.width, ChatWindow.DefaultUIPos.RestoreBtn.height);
		_parent.background = ChatWindow.DefaultUIPos.RestoreBtn.background;
		_parent.onclick = ";MyCompany.Aries.ChatSystem.ChatWindow.OnClickWndRestore();"
		_parent.tooltip = "打开聊天窗口(Enter键)";
		_parent.zorder = -1;
		_parent:AttachToRoot();
	end
	return _parent;
end

-- user clicks to minimize the chat window to a single button
function ChatWindow.OnClickWndMinimize()
	ChatWindow.HideAll();
	ChatWindow.CreateGetRestoreBtn().visible = true;
	ChatWindow.minimized = true;
end

-- onclick restore game window
function ChatWindow.OnClickWndRestore()
	ChatWindow.ShowAllPage();
	local _parentwnd = ChatWindow.CreateGetParentWnd();
	if(_parentwnd) then
		-- restore to old position. 
		_parentwnd.visible = true;
		if(ChatWindow.DefaultUIPos.ParentWnd) then
			_parentwnd:Reposition(ChatWindow.DefaultUIPos.ParentWnd.alignment, ChatWindow.DefaultUIPos.ParentWnd.left, ChatWindow.DefaultUIPos.ParentWnd.top, ChatWindow.DefaultUIPos.ParentWnd.width, ChatWindow.DefaultUIPos.ParentWnd.height)
		end
	end
end

--[[---------------------------------------------------------------------------------------------------
切换显示
当前已经显示的话,则隐藏,反之则显示
--]]---------------------------------------------------------------------------------------------------
function ChatWindow.SwitchShow()
	if(ChatWindow.isshow)then
		ChatWindow.HideAll();
	else
		ChatWindow.ShowAllPage();
	end
end

function ChatWindow.HasFocus()
	return ChatEdit.HasFocus();
end

-- show the chat log page. 
-- e.g. ChatWindow.ShowChatLogPage(true, "_lb", 0, -420, 450, 300)
function ChatWindow.ShowChatLogPage(bForceRefreshPage, alignment, left, top, width, height)
	if(bForceRefreshPage or not ChatWindow.page) then
		ChatWindow.page = Map3DSystem.mcml.PageCtrl:new({
			url="script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.html", 
			click_through=true});
	end
	
	if(bForceRefreshPage) then
		ParaUI.Destroy("ChatLogPage");
	end
	local _parent = ParaUI.GetUIObject("ChatLogPage");

	if(not _parent or not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container", "ChatLogPage", alignment or ChatWindow.DefaultUIPos.LogWnd.alignment, left or ChatWindow.DefaultUIPos.LogWnd.left, top or ChatWindow.DefaultUIPos.LogWnd.top, width or ChatWindow.DefaultUIPos.LogWnd.width, height or ChatWindow.DefaultUIPos.LogWnd.height);
		_parent.background = "";
		_parent.visible=false;
		_parent.zorder = -3;
		_parent:GetAttributeObject():SetField("ClickThrough", true);

		local _parentwnd = ChatWindow.CreateGetParentWnd();
		if(_parentwnd) then
			_parentwnd:AddChild(_parent);
		else
			_parent:AttachToRoot();
		end

		ChatWindow.page:Create("ChatWindow.page", _parent, "_fi", 0, 0, 0, 0);
		ChatWindow.is_fade_out = nil;
	end

	_parent.visible = true;
	ChatWindow.is_shown = true;
end

function ChatWindow.FadeIn(animSeconds)
	if(ChatWindow.is_fade_out) then
		ChatWindow.is_fade_out = false;
		if(ChatWindow.page) then
			local _parent = ChatWindow.page:FindControl("canvas");
			--local _parent = ParaUI.GetUIObject("ChatLogPage");
			UIAnimManager.ChangeAlpha("Aries.ChatWindow", _parent, 255, 256/(animSeconds or 0.5))
		end
	end
end

function ChatWindow.FadeOut(animSeconds)
	if(not ChatWindow.is_fade_out) then
		ChatWindow.is_fade_out = true;
		if(ChatWindow.page) then
			local _parent = ChatWindow.page:FindControl("canvas");
			--local _parent = ParaUI.GetUIObject("ChatLogPage");
			UIAnimManager.ChangeAlpha("Aries.ChatWindow", _parent, if_else(System.options.version == "teen", 0, 0), 256/(animSeconds or 4))
		end
	end
end

-- show the edit page
-- @param bSetFocus: default to false. if true, the editbox will have the focus. 
function ChatWindow.ShowEditPage(bSetFocus)
	ChatEdit.ShowPage();
	if(bSetFocus) then
		ChatEdit.SetFocus();
		local ctl = ChatWindow.GetTreeView();
		ctl.height = ChatWindow.DefaultUIPos.LogWnd.height;
	end
end

-- only called by ChatWindow.html
function ChatWindow.Init()
	ChatWindow.page = document:GetPageCtrl();
	ChatChannel.Init();
	ChatWindow.InitSystem();
end

function ChatWindow.CreateDragger(param, mcmlNode)
	local _this = ParaUI.CreateUIObject("container", "ChatWindow_Dragger","_lt", param.left,param.top,param.width,param.height);
	_this.background = param.background or "";
	_this.candrag = true;
	_this.tooltip = "拖动可移动窗口";

	_this:SetScript("ondragmove", function(ui_obj)
		local x, y = ui_obj:GetAbsPosition();
		local _parentwnd = ChatWindow.CreateGetParentWnd();
		if(x<0) then x=0; end
		if(y<0) then y=0; end
		_parentwnd:Reposition("_lt", x, y-(ChatWindow.DefaultUIPos.dragger_top or 49), ChatWindow.DefaultUIPos.ParentWnd.width, ChatWindow.DefaultUIPos.ParentWnd.height)
	end);
	_this:SetScript("ondragend", function(ui_obj)
		local x, y = ui_obj:GetAbsPosition();
		local _parentwnd = ChatWindow.CreateGetParentWnd();
		if(x<0) then x=0; end
		if(y<0) then y=0; end
		_parentwnd:Reposition("_lt", x, y-(ChatWindow.DefaultUIPos.dragger_top or 49), ChatWindow.DefaultUIPos.ParentWnd.width, ChatWindow.DefaultUIPos.ParentWnd.height)
	end);
	param.parent:AddChild(_this);
end

-- create the scroll bar
function ChatWindow.CreateTreeViewScrollBar(param, mcmlNode)
	local vscrollbar = ParaUI.CreateUIObject("scrollbar", "ChatWindow_CreateTreeView_VScrollBar","_lt", param.left,param.top,param.width,param.height);
	vscrollbar.visible = true;
	vscrollbar:SetPageSize(param.height);
	vscrollbar.onchange = ";MyCompany.Aries.ChatSystem.ChatWindow.OnScrollBarChange()";

	--[[
	local states = {[1] = "highlight", [2] = "pressed", [3] = "disabled", [4] = "normal"};
	local i;
	for i = 1, 4 do
		vscrollbar:SetCurrentState(states[i]);
		texture=vscrollbar:GetTexture("track");
		texture.texture="Texture/Aries/ChatSystem/gundongtiaobg_32bits.png;0 0 16 32";
		texture=vscrollbar:GetTexture("up_left");
		texture.texture="Texture/Aries/ChatSystem/arrow1_32bits.png;6 6 16 16";
		texture=vscrollbar:GetTexture("down_right");
		texture.texture="Texture/Aries/ChatSystem/arrow2_32bits.png;6 6 16 20";
		texture=vscrollbar:GetTexture("thumb");
		texture.texture="Texture/Aries/ChatSystem/arrow3_32bits.png;0 0 16 31";
	end]]
	param.parent:AddChild(vscrollbar);
end

-- create the treeview for log display
function ChatWindow.CreateTreeView(param, mcmlNode)
    local _container = ParaUI.CreateUIObject("container", "chatwindow_tvcon", "_lt", param.left,param.top,param.width,param.height);
	_container.background = "";
	_container:GetAttributeObject():SetField("ClickThrough", true);
	param.parent:AddChild(_container);
	
	-- create get the inner tree view
	local ctl = ChatWindow.GetTreeView(nil, _container, 0, 0, param.width, param.height);
	ctl:Show(true, nil, true);
	local _parentctl = ParaUI.GetUIObject(ctl.name);
	_parentctl:GetChild("main").onmousewheel = string.format(";MyCompany.Aries.ChatSystem.ChatWindow.OnTreeViewMouseWheel()");
end

function ChatWindow.OnTreeViewMouseWheel()
	--commonlib.echo("!!:OnTreeViewMouseWheel");
	CommonCtrl.TreeView.OnTreeViewMouseWheel("ChatWindow.TreeView");
	ChatWindow.RefreshScrollBar();
end

function ChatWindow.OnScrollBarChange()
	local ctl = ChatWindow.GetTreeView();
	local vscrollbar = ParaUI.GetUIObject("ChatWindow_CreateTreeView_VScrollBar");
	if(ctl and vscrollbar:IsValid())then
		ctl.ClientY = vscrollbar.value;
		ctl:RefreshUI();
	end
end

function ChatWindow.RefreshScrollBar()
	local ctl = ChatWindow.GetTreeView();
	local vscrollbar = ParaUI.GetUIObject("ChatWindow_CreateTreeView_VScrollBar");
	if(ctl and vscrollbar:IsValid())then
		local TreeViewHeight = ctl.height;
		-- update track range and thumb location.
		vscrollbar:SetTrackRange( 0, ctl.RootNode.LogicalBottom );
		if( ctl.VerticalScrollBarStep > ( ctl.RootNode.LogicalBottom - TreeViewHeight ) / 2 ) then
			vscrollbar:SetStep( ( ctl.RootNode.LogicalBottom - TreeViewHeight ) / 2 );
		else
			vscrollbar:SetStep( ctl.VerticalScrollBarStep );
		end		

		vscrollbar.value = ctl.ClientY;
		vscrollbar.scrollbarwidth = ctl.VerticalScrollBarWidth;
	end 
end

-- filter known http:// url in words, and change them to mcml string
function ChatWindow.FilterURL(words)
	if(words) then
		local url = words:match("(http://%S+)");
		if(url) then
			local nid, slot_id = url:match("visit_url=(%d+)@?(.*)$");
			if(nid and slot_id) then
				words = words:gsub("(http://%S+)", format("<pe:mcworld nid='%s' slot='%s' class='linkbutton_yellow'/>", nid, slot_id));
			end
		end
	end
	return words;
end

-- render callback for each text node in tree view. 
function ChatWindow.DrawTextNodeHandler(_parent, treeNode)
	if(_parent == nil or treeNode == nil) then
		return;
	end
	local _this;
	local height = 12; -- just big enough
	local nodeWidth = treeNode.TreeView.ClientWidth;
	local oldNodeHeight = treeNode:GetHeight();
	local chatdata = treeNode.chatdata;
	if(type(chatdata) == "string") then
		mcmlStr = string.format([[<div style="float:left;">%s</div>]],"");
		if(mcmlStr ~= nil) then
			local xmlRoot = ParaXML.LuaXML_ParseString(mcmlStr);
			if(type(xmlRoot)=="table" and table.getn(xmlRoot)>0) then
				local xmlRoot = Map3DSystem.mcml.buildclass(xmlRoot);
							
				local myLayout = Map3DSystem.mcml_controls.layout:new();
				myLayout:reset(0, 0, nodeWidth-5, height);
				Map3DSystem.mcml_controls.create("bbs_lobby", xmlRoot, nil, _parent, 0, 0, nodeWidth-5, height,nil, myLayout);
				local usedW, usedH = myLayout:GetUsedSize()
				if(usedH>height) then
					return usedH;
				end
				return;
			end
		end
	end
	local fromvip = "";
	local tovip = "";
	local fromschool = "";
	local toschool="";
	local words = Encoding.EncodeStr(chatdata.words or "");
	words = words:gsub("\n", "<br/>")
	local fromname = Encoding.EncodeStr(chatdata.fromname or "");
	local toname = Encoding.EncodeStr(chatdata.toname or "");
	local from = chatdata.from;

	if(not System.options.mc) then
		--转换表情符号
		words = SmileyPage.ChangeToMcml(words);
	end
	words = ChatWindow.FilterURL(words);
	if(chatdata.is_direct_mcml) then
		words = chatdata.words or "";
	end
	
	local world_info = WorldManager:GetCurrentWorld()
	if(world_info.disable_arena_talk) then
		local player_side = BattlefieldClient:GetPlayerSide(chatdata.from);
		if(player_side) then
			if(chatdata.ChannelIndex ~= ChatChannel.EnumChannels.BroadCast) then
				-- battle field 
				if(BattlefieldClient:GetMySide() == player_side) then
					words = words;
					chatdata.color = "#00cc00";
				else
					words = "(低语中)..."
					chatdata.color = "#cc0000";
				end
			end
		else
			-- pvp world
			if(Player.IsInCombat() and chatdata.ChannelIndex == ChatChannel.EnumChannels.NearBy) then
				if(MsgHandler.IsUserInSameArenaSide(chatdata.from)) then
					words = words;
					chatdata.color = "#00cc00";
				else
					fromname = "对面";
					from = nil;
					words = "(低语中)...";
					chatdata.color = "#cc0000";
				end
			end
		end
	end

	--if(chatdata.fromisvip)then
		--fromvip = [[<img src="Texture/Aries/Friends/MagicStarSmall_32bits.png; 0 0 22 22" style="width:16px;height:17px;"/>]];
	--end
	--if(chatdata.toisvip)then
		--tovip = [[<img src="Texture/Aries/Friends/MagicStarSmall_32bits.png; 0 0 22 22" style="width:16px;height:17px;"/>]];
	--end

	
	local nid = 0;
	if(not System.options.mc) then
		nid = System.App.profiles.ProfileManager.GetNID();
	end

	local is_from_mine = (from==nid);

	fromschool = ""
	toschool = ""
	if(is_from_mine) then
		fromname = L"我";
	else
		fromname = L"系统消息";
	end

	--if(System.options.mc) then
		--fromschool = ""
		--toschool = ""
		--if(is_from_mine) then
			--fromname = "我";
		--else
			--fromname = "系统消息";
		--end
	--else
		--if(from and chatdata.fromschool )then
			--fromschool = string.format([[<img src="Texture/Aries/Combat/HPSlots/%s_32bits.png; 0 0 24 24" style="width:16px;height:16px;"/>]], chatdata.fromschool );
		--end
--
		--if(chatdata.to and chatdata.toschool )then
			--toschool = string.format([[<img src="Texture/Aries/Combat/HPSlots/%s_32bits.png; 0 0 24 24" style="width:16px;height:16px;"/>]], chatdata.toschool );
		--end
	--end
	
	local use_shadow = "class='bordertext'"; -- @note: replace this if one wants to use shadow: "class='bordertext'"
	if(chatdata.ChannelIndex == ChatChannel.EnumChannels.BroadCast) then
		if(not chatdata.from) then
			use_shadow = "class='bbs_sys_text'"; 
		else
			use_shadow = "class='bbs_text'"; 
		end
	end

	-- GM color is disabled since users can fake GM nid
	--if(from and Scene.IsGMAccount(from)) then
		--chatdata.fromschool = nil;
		--use_shadow = "class='bbs_sys_text'"; 
	--end

	local bEmptyChannelName = (chatdata.channelname == "");

	local nid = 0;
	if(not System.options.mc) then
		nid = System.App.profiles.ProfileManager.GetNID();
	end
	if(from==nid and chatdata.to)then
		mcmlStr = string.format([[<div style="line-height:14px;font-size:12px;color:#%s;" %s>%s<div style="float:left;">你对[%s%s<a 
				tooltip="%s" style="margin-left:0px;float:left;height:12px;background:url()" name="x"
				onclick="MyCompany.Aries.ChatSystem.ChatWindow.OnClickName" param1='%s'>
				<div style="float:left;margin-top:-2px;color:#%s;">%s</div></a><span>%s</span></div></div>]],
				chatdata.color, use_shadow, if_else(bEmptyChannelName, chatdata.channelname, "["..chatdata.channelname.."]"), toschool, tovip,
				if_else(chatdata.bHideTooltip, "", "左键私聊, 右键查看"), 
				tostring(chatdata.to)..":"..toname,chatdata.color, toname.."]"..if_else(chatdata.bHideColon, "", "："), words);
	elseif(from and chatdata.to==nil)then
		--mcmlStr = string.format([[<div style="color:#%s;text-shadow:true;">【%s】<pe:name nid='%s' value='%s' a_style="color:#ffffff;text-shadow:false;"/>对你说:%s</div>]],chatdata.color,chatdata.channelname,chatdata.from,chatdata.fromname, chatdata.words);
		if(fromschool ~= "") then
			mcmlStr = string.format([[<div style="line-height:14px;font-size:12px;color:#%s;" %s>%s<div style="float:left;">[%s%s<a 
				tooltip="%s" style="margin-left:0px;float:left;height:12px;background:url()" name="x" 
				onclick="MyCompany.Aries.ChatSystem.ChatWindow.OnClickName" param1='%s'>
				<div style="float:left;margin-top:-2px;color:#%s;">%s</div></a><span style="margin-left:0px;">%s</span></div></div>]],
				chatdata.color, use_shadow, if_else(bEmptyChannelName, chatdata.channelname, "["..chatdata.channelname.."]"), fromschool, fromvip,
				if_else(chatdata.bHideTooltip, "", "左键私聊, 右键查看"), 
				tostring(chatdata.from)..":"..fromname,chatdata.color, fromname.."]"..if_else(chatdata.bHideColon, "", "："), words);	
		else
			mcmlStr = string.format([[<div style="float:left;color:#%s">%s</div><span><font color="ffffff">%s</font></span>]],
					if_else(is_from_mine,"ff0000","eeee00"),fromname..if_else(chatdata.bHideColon, "", "："), words);
			
		end
				
	elseif(from and chatdata.to )then
		--mcmlStr = string.format([[<div style="color:#%s;text-shadow:true;">【%s】<pe:name nid='%s' value='%s' a_style="color:#ffffff;text-shadow:false;"/>对<pe:name nid='%s' value='%s' a_style="color:#ffffff;text-shadow:false;"/>说:%s</div>]],chatdata.color,chatdata.channelname,chatdata.from,chatdata.fromname,chatdata.to,chatdata.toname,chatdata.words);
		mcmlStr = string.format([[<div style="line-height:14px;font-size:12px;color:#%s;" %s>%s<div style="float:left;margin-left:%dpx;">[%s%s<a 
				tooltip="%s" style="margin-left:0px;float:left;height:12px;background:url()" name="x" 
				onclick="MyCompany.Aries.ChatSystem.ChatWindow.OnClickName" param1='%s'>
				<div style="float:left;margin-top:-2px;color:#%s;">%s</div>
				</a><div style="float:left;">]对[</div>%s%s<a style="margin-left:0px;float:left;height:12px;background:url()" name="x" 
				tooltip="%s" onclick="MyCompany.Aries.ChatSystem.ChatWindow.OnClickName" param1='%s'>
				<div style="float:left;margin-top:-2px;color:#%s;">%s</div></a><span>%s</span></div></div>]],
				chatdata.color, use_shadow, if_else(bEmptyChannelName, chatdata.channelname, "["..chatdata.channelname.."]"), if_else(bEmptyChannelName, 0,-5), fromschool, fromvip,
				if_else(chatdata.bHideTooltip, "", "左键私聊, 右键查看"), 
				tostring(chatdata.from)..":"..fromname,chatdata.color, fromname, toschool, tovip,
				if_else(chatdata.bHideTooltip, "", "左键私聊, 右键查看"), 
				tostring(chatdata.to)..":"..toname,chatdata.color, toname.."]"..if_else(chatdata.bHideColon, "", "："), words);
				
	elseif(not chatdata.from and not chatdata.to and chatdata.bHideSubject and chatdata.is_direct_mcml) then
		--mcmlStr = string.format([[<div style="color:#%s;text-shadow:true;">【%s】<pe:name nid='%s' value='%s' a_style="color:#ffffff;text-shadow:false;"/>对你说:%s</div>]],chatdata.color,chatdata.channelname,chatdata.from,chatdata.fromname, chatdata.words);
		mcmlStr = string.format([[<div style="line-height:14px;font-size:12px;color:#%s;" %s><div style="float:left;margin-left:0px;">%s</div></div>]],
				chatdata.color, use_shadow, words);
	else
		mcmlStr = string.format([[<div style="line-height:14px;font-size:12px;color:#%s;" %s>[%s]%s</div>]],chatdata.color,use_shadow,chatdata.channelname, words);
	end
	--echo("2222222222");
	--echo(_guihelper.GetTextWidth(fromname..":"..words))
	if(mcmlStr ~= nil) then
		local xmlRoot = ParaXML.LuaXML_ParseString(mcmlStr);
		if(type(xmlRoot)=="table" and table.getn(xmlRoot)>0) then
			local xmlRoot = Map3DSystem.mcml.buildclass(xmlRoot);
							
			local myLayout = Map3DSystem.mcml_controls.layout:new();
			myLayout:reset(0, 0, nodeWidth-5, height);
			Map3DSystem.mcml_controls.create("bbs_lobby", xmlRoot, nil, _parent, 0, 0, nodeWidth-5, height,nil, myLayout);
			local usedW, usedH = myLayout:GetUsedSize()
			if(usedH>height) then
				return usedH;
			end
		end
	end
end

function ChatWindow.GetTreeView(name, parent, left, top, width, height, NoClipping)
	name = name or "ChatWindow.TreeView"
	local ctl = CommonCtrl.GetControl(name);
	if(not ctl)then
		ctl = CommonCtrl.TreeView:new{
			name = name,
			alignment = "_lt",
			left = left or 0,
			top = top or 0,
			width = width or 350,
			height = height or 200,
			parent = parent,
			container_bg = nil,
			DefaultIndentation = 2,
			NoClipping = NoClipping==true,
			ClickThrough = true,
			DefaultNodeHeight = 14,
			VerticalScrollBarStep = 14,
			VerticalScrollBarPageSize = 14 * 5,
			VerticalScrollBarWidth = 10,
			HideVerticalScrollBar = true,
			IsExternalScrollBar = true,
			DrawNodeHandler = ChatWindow.DrawTextNodeHandler,
		};
	elseif(parent)then
		ctl.parent = parent;
	end

	if(width)then
		ctl.width = width;
	end

	if(height)then
		ctl.height= height;
	end

	if(left)then
		ctl.left= left;
	end

	if(top)then
		ctl.top = top;
	end
	return ctl;
end

function ChatWindow.AddBroadCastLine(chatdata)
	local use_treeview_broadcast = true;
	if(use_treeview_broadcast) then
		local ctl = ChatWindow.GetTreeView("BroadCast.TreeView");
		local rootNode = ctl.RootNode;
				
		if(rootNode:GetChildCount() >= max_broadcast_message) then
			rootNode:RemoveChildByIndex(1);
		end

		rootNode:AddChild(CommonCtrl.TreeNode:new({
				Name = "text", 
				chatdata = chatdata,
			}));

		local parent = ParaUI.GetUIObject("broadcast_tvcon");
		if(parent:IsValid())then
			ctl.parent = parent;
			ctl:Update(true);
		end

		ChatWindow.bbs_timer = ChatWindow.bbs_timer or commonlib.Timer:new({callbackFunc = function(timer)
			local ctl = ChatWindow.GetTreeView("BroadCast.TreeView");
			local rootNode = ctl.RootNode;
			rootNode:RemoveChildByIndex(1);

			local parent = ParaUI.GetUIObject("broadcast_tvcon");
			if(parent:IsValid())then
				ctl.parent = parent;
				ctl:Update(true);
			end
			if(rootNode:GetChildCount() == 0) then
				timer:Change();
			end
		end})
		ChatWindow.bbs_timer:Change(max_broadcast_msg_show_time, max_broadcast_msg_show_time);
	else
		-- the old scrolling broadcast
		if(ChatWindow.sysmsg==nil)then
			ChatWindow.sysmsg = {};
		end
		local channelname = chatdata.channelname or "喇叭"
		local words = Encoding.EncodeStr(chatdata.words or "");
		local from = Encoding.EncodeStr(chatdata.from or "");
		local fromname = Encoding.EncodeStr(chatdata.fromname or "");
		local str = string.format("【%s】%s(%s)说:%s", channelname, fromname, from, words );
		table.insert( ChatWindow.sysmsg, {ChannelIndex=chatdata.ChannelIndex, words=str,state=0,} );
		ChatWindow.CheckSysMsg();
	end
end

-- callback function whenever ChatChannel received a message. 
-- @param chatdata: 参见ChatChannel.lua中的msgdata结构
-- @param needrefresh: bool	如为true,则会刷新聊天记录中的treeview
--]]---------------------------------------------------------------------------------------------------
function ChatWindow.AppendChatMessage(chatdata, needrefresh)
	if(chatdata==nil or type(chatdata)~="table")then
		commonlib.echo("error: chatdata 不可为空 in ChatWindow.AppendChatMessage");
		return;
	end

	--commonlib.echo("!!:AppendChatMessage");
	if(chatdata.ChannelIndex == ChatChannel.EnumChannels.BroadCast)then
		
		if(chatdata.words and string.match(chatdata.words,"lobby|(.+)|lobby"))then
			NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClientServicePage.lua");
			local LobbyClientServicePage = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClientServicePage");
			local words = LobbyClientServicePage.GetLobbyCallMsg(chatdata.from,chatdata.words);
			if(not words)then
				return
			end
			chatdata.ChannelIndex = ChatChannel.EnumChannels.Lobby;
			chatdata.channelname = ChatChannel.channels[ChatChannel.EnumChannels.Lobby].name;
			chatdata.color = ChatChannel.channels[ChatChannel.EnumChannels.Lobby].color;
			chatdata.words = words;
			chatdata.is_direct_mcml = true;
		else
			if(needrefresh) then
				ChatWindow.AddBroadCastLine(chatdata);
			end
			if(not ChatChannel.AppendFilter[chatdata.ChannelIndex]) then
				return;
			end
		end
	end
	

	local ctl = ChatWindow.GetTreeView();
	local rootNode = ctl.RootNode;
	
	if(rootNode:GetChildCount() > 200) then
		rootNode:RemoveChildByIndex(1);
	end

	rootNode:AddChild(CommonCtrl.TreeNode:new({
			Name = "text", 
			chatdata = chatdata,
		}));

	if(needrefresh)then
		ChatWindow.RefreshTreeView();
	end
	
end

function ChatWindow.GetMsgNeedRows(chatdata)
	local from = chatdata.from;
	local msg="";
	local nid = 0;
	if(not System.options.mc) then
		nid = System.App.profiles.ProfileManager.GetNID();
	end
	if(from==nid) then
		msg = L"我";
	else
		msg = L"系统消息";
	end
	msg = msg..":"..chatdata.words;
	local length = _guihelper.GetTextWidth(msg);
	local rows = math.ceil(length/306);
	return rows;
end

-- user clicks the tab to switch the channel
function ChatWindow.OnSwitchChannelDisplay(name)
	local channel_index = tonumber(name);
	local chatdata;
	if(channel_index==ChatChannel.EnumChannels.All)then
		-- exclude = 10(broadcast)
		local channels = {1,2,3,4,5,6,7,8,9,11,12,13,14}
		chatdata = ChatChannel.GetChat(channels);
		ChatChannel.SetAppendEventCallbackFilter(channels);
	elseif(channel_index==ChatChannel.EnumChannels.Region or channel_index==ChatChannel.EnumChannels.BroadCast)then
		local channels = {ChatChannel.EnumChannels.Region,ChatChannel.EnumChannels.BroadCast, ChatChannel.EnumChannels.Private}
		chatdata = ChatChannel.GetChat(channels);
		ChatChannel.SetAppendEventCallbackFilter(channels);
	else
		local channels = {channel_index, }
		if(channel_index~=ChatChannel.EnumChannels.Private) then
			channels[#channels+1] = ChatChannel.EnumChannels.Private; 
		end
		chatdata = ChatChannel.GetChat(channels);
		ChatChannel.SetAppendEventCallbackFilter(channels);
	end

	local ctl = CommonCtrl.GetControl("ChatWindow.TreeView");
	if(ctl and ctl.RootNode and ctl.RootNode:GetChildCount()>0 )then
		ctl.RootNode:ClearAllChildren();
	end

	local i;
	for i=1,#chatdata do
		local tmp = chatdata[i];
		ChatWindow.AppendChatMessage(tmp);
	end

	ChatWindow.RefreshTreeView();

	if(channel_index~=ChatChannel.EnumChannels.All)then
		local bIgnoreText = ChatEdit.selected_channel ~= ChatChannel.EnumChannels.Private and channel_index ~= ChatChannel.EnumChannels.Private;
		ChatEdit.SelectChannel(channel_index, bIgnoreText);
	end
end

-- refresh the tree view. 
-- TODO: only refresh whenever the tree view is visible, otherwise we will postpone until it is visible again. 
function ChatWindow.RefreshTreeView()
	if (ChatWindow.page) then
		local ctl = ChatWindow.GetTreeView();
		if(ctl) then
			local parent = ParaUI.GetUIObject("chatwindow_tvcon");
			if(parent:IsValid())then
				ctl.parent = parent;
				ctl:Update(true);
			end
		end

		ChatWindow.RefreshScrollBar();
	end
end

-- create a treeview to display broadcast message. 
function ChatWindow.CreateBroadTreeView(param, mcmlNode)
	local _container = ParaUI.CreateUIObject("container", "broadcast_tvcon", "_lt", param.left,param.top,param.width,param.height);
	_container.background = "";
	_container:GetAttributeObject():SetField("ClickThrough", true);
	param.parent:AddChild(_container);
	
	-- create get the inner tree view
	local ctl = ChatWindow.GetTreeView("BroadCast.TreeView", _container, 0, 0, param.width, param.height, true);
	ctl:Show(true, nil, true);
end

-- create the broadcast view on top of the chat window for the most important messages. 
function ChatWindow.CreateBroadView(param, mcmlNode)
	local name = "ChatWindow_CreateBroadView_" .. mcmlNode:GetString("id");
    local _this = ParaUI.CreateUIObject("container", name, "_lt", param.left,param.top,param.width,param.height);
	_this.background = "";
	_this.fastrender= false;
	_this:GetAttributeObject():SetField("ClickThrough", true);
	param.parent:AddChild(_this);

	local _text = ParaUI.CreateUIObject("text", name .. "_text", "_lt", param.width, 3, param.width, param.height);
	_text.background = nil;
	_text.text = "";
	_guihelper.SetFontColor(_text, "255 255 0");
	_text.font = System.DefaultBoldFontString;
	_text.shadow = true;
	_this:AddChild(_text);

	ChatWindow.CheckSysMsg();
end

-- TODO: optimize timer
function ChatWindow.BeginBroadViewScoll(id,msgdata)
	local name = "ChatWindow_CreateBroadView_" .. id;
	local _con = ParaUI.GetUIObject(name);
	if(_con)then
		local _text = ParaUI.GetUIObject(name .. "_text");
		if(_text)then
			_text.text = msgdata.words;
			_text:GetFont("text").format = 36+256; -- center and no clip
			_text.x = _con.width;
			_text.width = _text:GetTextLineSize();

			local scroll_timer = commonlib.Timer:new({callbackFunc = function(timer)
				local _broadcon = ParaUI.GetUIObject(name);
				if(_broadcon)then
					local _broadtext = ParaUI.GetUIObject(name .. "_text");
					if(_broadtext )then
						local x = _broadtext.x + _broadtext.width;
						if( x >= 0 )then
							_broadtext.x = _broadtext.x - 3;
						else
							timer:Change();
							msgdata.state = msgdata.state + 1;
							ChatWindow.EndBroadViewScoll(id,msgdata);
						end
					end
				end
			end});
			scroll_timer:Change(20,20);
			ChatWindow.isanimating = true;
		end
	end
end

-- TODO: optimize timer
function ChatWindow.EndBroadViewScoll(id,msgdata)
	local text_delay_timer = commonlib.Timer:new({callbackFunc = function(timer)
		timer:Change();
		if(msgdata.state == 1)then
			ChatWindow.BeginBroadViewScoll(id,msgdata);
		elseif(msgdata.state == 2)then
			msgdata.state = 3;
			ChatWindow.isanimating = false;
			ChatWindow.CheckSysMsg();
		end
	end});
	text_delay_timer:Change(1000);
end

function ChatWindow.CheckSysMsg()
	if(ChatWindow.sysmsg and #(ChatWindow.sysmsg) > 0 )then
		if(ChatWindow.sysmsg[1].state == 0 and not ChatWindow.isanimating)then
			ChatWindow.BeginBroadViewScoll(1,ChatWindow.sysmsg[1]);
		elseif(ChatWindow.sysmsg[1].state == 3)then
			table.remove( ChatWindow.sysmsg, 1 );
			ChatWindow.CheckSysMsg();
		end
	end
end


function ChatWindow.BadWordsFilter(msgdata)
	if(msgdata and msgdata.words and not System.options.mc)then
		msgdata.words = MyCompany.Aries.Chat.BadWordFilter.FilterString(msgdata.words);
	end
	return msgdata;
end

local nid_name_map = {};
local name_nid_map = {};

-- add to temporary nid name map
function ChatWindow.AddNidName(nid, name)
	nid_name_map[nid] = name;
	nid_name_map[name] = nid;
end

function ChatWindow.GetNidByName(name)
	return nid_name_map[name];
end


-- NOT Used: filter commands. this function will be called by ChatChannel.lua
-- @param msgdata: message data
-- @param return true if processed. 
function ChatWindow.BattleFieldFilter(msgdata)
	if(msgdata.ChannelIndex == ChatChannel.EnumChannels.NearBy or msgdata.ChannelIndex == ChatChannel.EnumChannels.All) then
		if(msgdata.words) then
			local my_side = BattlefieldClient:GetMySide();
			if(my_side) then
				msgdata.words = format("<bf side='%d'/>", my_side)..msgdata.words;
			end
		end
	end
	return msgdata;
end

-- filter commands. this function will be called by ChatChannel.lua
-- @param msgdata: message data
-- @param return true if processed. 
function ChatWindow.ChatCommandFilter(msgdata)
	if(msgdata and msgdata.words )then
		-- internally it will run all GM commands. 
		local lastText = msgdata.words;
		local sentText, bSendMessage = SlashCommand.GetSingleton():Run(lastText);
		if(not bSendMessage) then
			return true;
		end

		if(string.sub(msgdata.words,1,1)=="@")then
			-- private chat
			local command, words = string.match(msgdata.words, "^@(%d+)%s+(.*)$" );
			if(not command or not words) then
				command, words = string.match(msgdata.words, "^@([^:]+):(.*)$" );
				if(command and words)then
					command = ChatWindow.GetNidByName(command);
				end
			end
			
			if(command and words)then
				msgdata.to = command;
				msgdata.words = words;
				msgdata.ChannelIndex = ChatChannel.EnumChannels.Private;
				return msgdata;
			end
		elseif(msgdata.ChannelIndex == ChatChannel.EnumChannels.Private)then
			return;
		elseif(string.sub(msgdata.words,1,1)=="#")then
			msgdata.words = string.sub(msgdata.words,2,-1);
			-- 这里添加#开头的命令行解析代码
		else
			return msgdata;
		end
	end
end


-- user clicks on the name. 
-- @param strNidName: a string of "[nid]:[name]"
function ChatWindow.OnClickName(strNidName)
	local nid, name = strNidName:match("^([%d]+):?(.*)$");
	nid = tonumber(nid);
	if(nid and nid ~= 0 and name) then
		if(mouse_button == "left") then
			local channel = ChatChannel.GetChannel(ChatChannel.EnumChannels.Private);
			if(channel) then
				-- use temporary name nid map
				ChatWindow.AddNidName(nid, name);
				channel.default_channel_text = "@"..name..":";

				-- this is another way
				-- channel.default_channel_text = "@"..tostring(nid).." ";
			end
	
			-- MyCompany.Aries.ChatSystem.ChatEdit.SetEditorText();
			MyCompany.Aries.ChatSystem.ChatEdit.SelectChannel(ChatChannel.EnumChannels.Private);
		elseif(mouse_button == "right") then
			NPL.load("(gl)script/apps/Aries/NewProfile/NewProfileMain.lua");
			MyCompany.Aries.NewProfileMain.OnShowContextMenu(nid);
		end
	end
end

