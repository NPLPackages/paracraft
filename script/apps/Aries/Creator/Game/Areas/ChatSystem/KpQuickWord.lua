--[[
Title: The quick word menu for keepwork
Author(s): leio
Date: 2020/5/6
Desc:  
Use Lib:
-------------------------------------------------------
local KpQuickWord = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpQuickWord.lua");
KpQuickWord.OnQuickword();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatEdit.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");

local KpQuickWord = NPL.export();
function KpQuickWord.OnQuickword(x,y, width, height)
	local ctl = CommonCtrl.GetControl("Aries_BattleChat_Quickword");
	if(ctl == nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "Aries_BattleChat_Quickword",
			width = 260,
			subMenuWidth = 300,
			height = 350, -- add 30(menuitemHeight) for each new line. 
			AutoPositionMode = "_lt",
			--style = CommonCtrl.ContextMenu.DefaultStyleThick,
			{
				borderTop = 4,
				borderBottom = 4,
				borderLeft = 18,
				borderRight = 10,
				
				fillLeft = 0,
				fillTop = -15,
				fillWidth = 0,
				fillHeight = -24,
				
				titlecolor = "#e1ccb6",
				level1itemcolor = "#e1ccb6",
				level2itemcolor = "#ffffff",
				
				-- menu_bg = "Texture/Aries/Chat/newbg1_32bits.png;0 0 128 192:40 41 20 17",
				menu_bg = "Texture/Aries/Chat/newbg2_32bits.png;0 0 195 349:17 41 8 9",
				menu_lvl2_bg = "Texture/Aries/Chat/newbg2_32bits.png;0 0 195 349:17 41 8 9",
				shadow_bg = nil,
				separator_bg = "", -- : 1 1 1 4
				item_bg = "Texture/Aries/Chat/fontbg1_32bits.png;0 0 103 26: 1 1 1 1",
				expand_bg = "Texture/Aries/Chat/arrowup_32bits.png; 0 0 15 16",
				expand_bg_mouseover = "Texture/Aries/Chat/arrowon_32bits.png; 0 0 15 16",
				
				menuitemHeight = 30,
				separatorHeight = 2,
				titleHeight = 26,
				
				titleFont = "System;14;bold";
			},
		};

		KpQuickWord.RefreshQuickword();
	end
	
	if(not x or not width) then
		x,y,width, height = ParaUI.GetUIObject("BattleChatBtn"):GetAbsPosition();
	end
	-- Note: 2009.9.29. Xizhi: if u ever added new menu items, please modify the height of the menu item, because animation only support "_lt" alignment. 
	ctl:Show(x+width, y+0);
end

-- @param filename: if nil, it will defaults to "config/Aries/Paracraft.Quickword.xml"
-- return XML root object of the quick words
function KpQuickWord.GetQuickWordFromFile(filename)
	filename = filename or "config/Aries/Paracraft.Quickword.xml";
	KpQuickWord.xmlRoot = KpQuickWord.xmlRoot or ParaXML.LuaXML_ParseFile(filename);
	return KpQuickWord.xmlRoot;
end

-- as array of strings
function KpQuickWord.GetQuickWordAsArray()
	local xmlRoot = KpQuickWord.GetQuickWordFromFile()
	if(not xmlRoot) then 
		return 
	end
	local out = {};
	-- read attributes of npl worker states
	local node_sentence;
	for node_sentence in commonlib.XPath.eachNode(xmlRoot, "//node") do
		out[#out+1] = node_sentence.attr.sentence;
	end
	return out;
end

function KpQuickWord.RefreshQuickword()
	
	local xmlRoot = KpQuickWord.GetQuickWordFromFile()
	if(not xmlRoot) then 
		return 
	end
	local ctl = CommonCtrl.GetControl("Aries_BattleChat_Quickword");
	if(ctl) then
		local node = ctl.RootNode;
		-- clear all children first
		node:ClearAllChildren();
		
		local subNode;
		-- name node: for displaying name of the selected object. Click to display property
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "快捷语言", Name = "name", Type="Title", NodeHeight = 26 });
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "----------------------", Name = "titleseparator", Type="separator", NodeHeight = 4 });
		-- by categories
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "Quickwords", Name = "actions", Type = "Group", NodeHeight = 0 });
		
		-- read attributes of npl worker states
		local node_category;
		for node_category in commonlib.XPath.eachNode(xmlRoot, "/quickwords/category") do
			if(node_category.attr and node_category.attr.name) then
				subNode = node:AddChild(CommonCtrl.TreeNode:new{Text = node_category.attr.name, Name = "looped", Type = "Menuitem"});
				local node_sentence;
				for node_sentence in commonlib.XPath.eachNode(node_category, "/node") do
					subNode:AddChild(CommonCtrl.TreeNode:new({Text = node_sentence.attr.sentence, Name = "xx", Type = "Menuitem", RawNode = node_sentence,  onclick = KpQuickWord.SendQuickword, }));
				end
			end	
		end
		local node_sentence;
		for node_sentence in commonlib.XPath.eachNode(xmlRoot, "/quickwords/node") do
			node:AddChild(CommonCtrl.TreeNode:new({Text = node_sentence.attr.sentence, Name = "xx", Type = "Menuitem", RawNode = node_sentence,  onclick = KpQuickWord.SendQuickword, }));
		end
	end
end

-- send quick word
function KpQuickWord.SendQuickword(node)
    if(KpChatChannel.worldId)then
        local channel;
        if(node.RawNode and node.RawNode.attr and node.RawNode.attr.channel)then
            channel = ChatChannel.EnumChannels[node.RawNode.attr.channel] or channel;
        end
        local txt;
        if(channel == ChatChannel.EnumChannels.KpBroadCast)then

            KpQuickWord.ShowPage(node.Text,function(id)
                txt = string.format("%sID:%s",node.Text,tostring(id));
	            ChatChannel.SendMessage(channel, nil, nil, txt, false, ChatChannel.InputTypes.FromQuickWord);
            end)
        else
            txt = string.format("%s",node.Text);
	        ChatChannel.SendMessage(ChatChannel.EnumChannels.KpNearBy, nil, nil, txt, false, ChatChannel.InputTypes.FromQuickWord);
        end
    end
end
function KpQuickWord.ShowPage(words,callback)
    KpQuickWord.words = words;
    KpQuickWord.project_id = nil;
    KpQuickWord.callback = callback;
    local params = {
			url = "script/apps/Aries/Creator/Game/Areas/ChatSystem/KpQuickWord.html",
			name = "KpQuickWord.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -400/2,
				y = -300/2,
				width = 400,
				height = 300,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end