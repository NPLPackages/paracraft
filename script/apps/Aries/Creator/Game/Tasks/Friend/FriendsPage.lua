--[[
Title: FriendsPage
Author(s): 
Date: 2020/7/3
Desc:  
Use Lib:
-------------------------------------------------------
local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
FriendsPage.Show();
--]]
local FriendsPage = NPL.export();


local page;
local DateTool = os.date

FriendsPage.data_sources = {
    {
        { name = "哈哈", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", nid = "10086", icon="Texture/Aries/Creator/keepwork/items/item_888_32bits.png", time=1598514220},
       { name = "哈哈", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598427820},
       { name = "哈哈", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598427820},
       { name = "哈哈", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598427820},
       { name = "哈哈", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1595749420},
       { name = "哈哈", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1595749420},
       { name = "哈哈", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1564127020},
       { name = "哈哈", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1564127020},
       { name = "哈哈", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1564127020},
    },
    {
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "嘻嘻", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
    },
    {
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "呵呵", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
    },
    {
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
        { name = "哦哦", mouseover_bg = "Texture/Aries/Common/underline_blue_32bits.png", icon="", time=1598514220},
    },
}
FriendsPage.Current_Item_DS = {};
FriendsPage.index = 1;
function FriendsPage.OnInit()
	page = document:GetPageCtrl();
end

function FriendsPage.Show()
    local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.html",
			name = "FriendsPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_lt",
				x = 10,
				y = 10/2,
				width = 300,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
    FriendsPage.OnChange(1);
end
function FriendsPage.OnChange(index)
	index = tonumber(index)
    FriendsPage.index = index;
    FriendsPage.Current_Item_DS = FriendsPage.data_sources[index] or {}
    FriendsPage.OnRefresh()
end
function FriendsPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end
function FriendsPage.ClickItem(index)
    if mouse_button == "left" then
    
    elseif mouse_button == "right" then
        FriendsPage.OpenFriendMenu()
    end
    
end

function FriendsPage.OpenFriendMenu(nid)
    local ctl = CommonCtrl.GetControl("pe_name_aries_ContextMenu");
	if(ctl==nil)then
		NPL.load("(gl)script/ide/ContextMenu.lua");
		ctl = CommonCtrl.ContextMenu:new{
			name = "pe_name_aries_ContextMenu",
			width = if_else(System.options.version=="kids", 120, 120),
			height = 160,
			DefaultNodeHeight = 24,
			style = if_else(System.options.version=="teen", nil, {
				borderTop = 4,
				borderBottom = 4,
				borderLeft = 4,
				borderRight = 4,
				
				fillLeft = 0,
				fillTop = 0,
				fillWidth = 0,
				fillHeight = 0,
				
				titlecolor = "#283546",
				level1itemcolor = "#283546",
				level2itemcolor = "#3e7320",
				
				iconsize_x = 24,
				iconsize_y = 21,
				
				menu_bg = "Texture/Aries/Creator/border_bg_32bits.png:3 3 3 3",
				menu_lvl2_bg = "Texture/Aries/Creator/border_bg_32bits.png:3 3 3 3",
				shadow_bg = nil,
				separator_bg = "Texture/Aries/Dock/menu_separator_32bits.png", -- : 1 1 1 4
				item_bg = "Texture/Aries/Dock/menu_item_bg_32bits.png: 10 6 10 6",
				expand_bg = "Texture/Aries/Dock/menu_expand_32bits.png; 0 0 34 34",
				expand_bg_mouseover = "Texture/Aries/Dock/menu_expand_mouseover_32bits.png; 0 0 34 34",
				
				menuitemHeight = 24,
				separatorHeight = 2,
				titleHeight = 24,
				
				titleFont = "System;12;bold";
			}),
		};
		local node = ctl.RootNode;
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "pe:name", Name = "pe:name", Type = "Group", NodeHeight = 0 });
		if(System.options.version =="teen")then
			node:AddChild(CommonCtrl.TreeNode:new({Text = "邀请加入家族", Name = "InviteToFamily", Type = "Menuitem", onclick = function()
					local manager = FamilyManager.CreateOrGetManager();
					if(manager and ctl.nid)then
						manager:DoInvite(ctl.nid);
					end
				end, Icon = nil,}));
		end
		-- if(System.options.version=="kids") then
		-- 	node:AddChild(CommonCtrl.TreeNode:new({Text = "  投人气", Name = "onvote", Type = "Menuitem", onclick = function()
		-- 			-- NewProfileMain.OnVotePolularity(ctl.nid,true);
		-- 		end, Icon = "Texture/Aries/NewProfile/onvote_32bits.png;0 1 24 23"}));	
		-- 	node:AddChild(CommonCtrl.TreeNode:new({Text = "  加为好友", Name = "addasfriend",Type = "Menuitem", onclick = function()
		-- 			-- NewProfileMain.OnAddAsFriend(ctl.nid);
		-- 		end,  Icon = "Texture/Aries/NewProfile/addasfriend_32bits.png;0 0 24 21"}));	
		-- end
		node:AddChild(CommonCtrl.TreeNode:new({Text = "私信", Name = "chat", Type = "Menuitem", onclick = function()
				-- TeamMembersPage.PrivateLetter(ctl.nid);
			end, Icon = nil,}));

		node:AddChild(CommonCtrl.TreeNode:new({Text = "申请加入项目", Name = "addasfriend",Type = "Menuitem", onclick = function()
			-- NewProfileMain.OnAddAsFriend(ctl.nid);
		end, }));	

		node:AddChild(CommonCtrl.TreeNode:new({Text = "查看资料", Name = "viewprofile", Type = "Menuitem", onclick = function()
			-- NewProfileMain.ShowPage(ctl.nid);
		end, }));


		node:AddChild(CommonCtrl.TreeNode:new({Text = "取消关注", Name = "removefriend", Type = "Menuitem", onclick = function()
			-- NewProfileMain.OnRemoveFriend(ctl.nid);
		end, }));	

	end	
	if(ctl.RootNode) then	
		local node = ctl.RootNode:GetChildByName("pe:name");
		if(node) then
			-- local is_friend_ = NewProfileMain.IsMyFriend(nid);
			local is_myself = (nid == Map3DSystem.User.nid);
			local tmp = node:GetChildByName("addasfriend");
			if(tmp) then
				tmp.Invisible = is_friend_ or is_myself;
			end
		end
	end
	ctl.nid = nid;
	ctl:Show(pos_x, pos_y);
end

-- 时间显示
-- 规则：
-- 今日：   时：分
-- 昨天：   昨天
-- 今年：  月-日
-- 往年：  年-月-日
function FriendsPage.GetTimeDesc(time)
	-- 先获取当前时间
	local cur_time_t = FriendsPage.FormatUnixTime2Date(os.time())
	local target_time_t = FriendsPage.FormatUnixTime2Date(time)

	-- 往年
	if target_time_t.year < cur_time_t.year then
		return DateTool("%Y-%m-%d", time)
	-- 往月
	elseif target_time_t.month < cur_time_t.month then
		return DateTool("%m-%d", time)
	-- 今日
	elseif target_time_t.day == cur_time_t.day then
		return DateTool("%H:%M", time)
	else
		-- 获取当天0点的时间戳
		local temp_time = os.time({day = cur_time_t.day, month = cur_time_t.month, year = cur_time_t.year, hour=0, minute=0, second=0})
		-- 在当天0点的时间戳之前的24小时以内的时间都是昨天
		local limit_sceond = 24 * 60 * 60

		-- 判断是否昨天
		if temp_time - time < limit_sceond then
			return "昨天"
		else
			return DateTool("%m-%d", time)
		end
	end

end

function FriendsPage.FormatUnixTime2Date(unixTime)
    if unixTime and unixTime >= 0 then
        local tb = {}
        tb.year = tonumber(DateTool("%Y",unixTime))
        tb.month =tonumber(DateTool("%m",unixTime))
        tb.day = tonumber(DateTool("%d",unixTime))
        tb.hour = tonumber(DateTool("%H",unixTime))
        tb.minute = tonumber(DateTool("%M",unixTime))
        tb.second = tonumber(DateTool("%S",unixTime))
        return tb
    end
end
