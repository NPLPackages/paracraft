--[[
Title: all controls for user related tags controls.
Author(s): WangTian, LiXizhi
Date: 2008/3/11, refactored 2008.5.4 LXZ
Desc: Displaying user related things such as names, photos, friends, etc. 
NOTE: pe:if-is-friends-with-viewer tag added by andy 2009/5/19
	  pe:else tag added by andy 2009/5/19

---++ pe:name

Renders the name of the user specified, optionally linked to his or her profile.
You can use this tag for both the subject and the object of a sentence describing an action. For example, if a user with the user ID $tagger tags a photo of a user with the user ID $tagee, you could say: 
<verbatim>
<pe:name uid="$tagger" capitalize="true" /> tagged a photo of <pe:name subjectid="$tagger" uid="$tagee" />
</verbatim>
 
---+++ Attributes:

| Required | Name | Type | Description |
| required | uid | uid | The ID of the user or Page whose name you want to show. You can also use "loggedinuser" or "profileowner". |
| required | nid | nid | same as uid for backward-compatible You can also use "loggedinuser" or "profileowner". |
| optional | firstnameonly | bool | Show only the user's first name. (default value is false) |
| | linked | bool | Link to the user's profile. (default value is true) |
| | lastnameonly | bool | Show only the user's last name. (default value is false) |
| | possessive | bool | Make the user's name possessive (e.g. Andy's instead of Andy). (default value is false) |
| | reflexive | bool | Use "yourself" if useyou is true. (default value is false) |
| | shownetwork | bool | Displays the primary network for the uid. (default value is false) |
| | useyou | bool | Use "you" if uid matches the logged in user. (default value is true) |
| | ifcantsee | string | Alternate text to display if the logged in user cannot access the user specified. (default value is [empty string]) |
| | capitalize | bool | Capitalize the text if useyou==true and loggedinuser==uid. (default value is false) |
| | subjectid | uid | The ParaWorld ID of the subject of the sentence where this name is the object of the verb of the sentence. Will use the reflexive when appropriate. When subjectid is used, uid is considered to be the object and uid's name is produced. |
| | a_class | string | the class name to be used with the a tag if linked attribute is true |
| | a_style | string | the style to be used with the a tag if linked attribute is true |
| | a_tooltip | string | tooltip of the inner a link |


---+++ Examples

<verbatim>
<pe:name uid="loggedinuser"/>
<pe:name uid="loggedinuser" useyou="false"/>
<pe:name uid="loggedinuser" useyou="false" linked="false"/>
<pe:name uid="f114ae44-f5e5-4072-9e40-0d792a9cfe7a"/>
</verbatim>

---++ pe:if-is-user
Only renders the content inside the tag if the viewer is one of the specified user(s). 

*Attributes*
| Required | Name |  Type |  Description |
| required | uid   | string   | The user ID of the user that is allowed to see the content. To match multiple users, pass in a comma-delimited list of uids. It can also be "loggedinuser" or "notloggedinuser"|

*Examples*
<verbatim>
	<pe:if-is-user uid="uid1,uid2">Only visible tonumber uid1, uid2!</pe:if-is-user> 
	<pe:if-is-user uid="loggedinuser">Only visible to logged in user</pe:if-is-user> 
	<pe:if-is-user uid="notloggedinuser">Only visible to not logged in user</pe:if-is-user> 
</verbatim>



TODO:
---++ pe:if-is-friends-with-viewer
Displays the enclosed content only if the specified user is friends with the page viewer.

*Attributes*
| Required | Name |  Type |  Description |
| optional | uid   | string   | The user ID to check. (Default value is loggedinuser.) |
| optional | includeself   | bool   | Return true if viewer and uid specified are the same. (Default value is true.)  |

---++ pe:else
Handles the else case inside any pe:if, pe:if-* or pe:is-in-network tag.

Applicable tags include: 
pe:if
pe:if-is-user
pe:if-is-friends-with-viewer


use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_user.lua");
-------------------------------------------------------
]]
local L = CommonCtrl.Locale("IDE");
if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {}; end


----------------------------------------------------------------------
-- pe:name: handles MCML tag <pe:name>
-- it renders the name of the user specified, optionally linked to his or her profile. 
----------------------------------------------------------------------
local pe_name = {};
Map3DSystem.mcml_controls.pe_name = pe_name;

-- pe_name is just a wrapper of button control with user name as text
function pe_name.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid") or mcmlNode:GetAttributeWithCode("uid");
	if(nid == nil or nid=="" or nid == "loggedinuser") then
		-- get current user ID as the nid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil or nid=="")  then return end
	
	-- Show only the user's first name. (default value is false) 
	local firstnameonly = mcmlNode:GetBool("firstnameonly");
	
	-- Show only the user's last name. (default value is false) 
	local lastnameonly = mcmlNode:GetBool("lastnameonly");
	
	-- Link to the user's profile. (default value is true) 
	local linked = mcmlNode:GetBool("linked", true);
	
	-- Make the user's name non-possessive (e.g. Andy instead of Andy's). (default value is false) 
	local possessive = mcmlNode:GetBool("possessive");
	
	-- Use "you" if nid matches the logged in user. (default value is true) 
	local reflexive = mcmlNode:GetBool("reflexive");
	
	-- Displays the primary network for the nid. (default value is false) 
	local shownetwork = mcmlNode:GetBool("shownetwork");
	
	-- Use "you" if nid matches the logged in user. (default value is true) 
	local useyou = mcmlNode:GetBool("useyou", true);
	
	-- Alternate text to display if the logged in user cannot access the user specified. (default value is [empty string]) 
	local ifcantsee = mcmlNode:GetString("ifcantsee", "");
	
	-- Capitalize the text if useyou==true and loggedinuser==nid. (default value is false) 
	local capitalize = mcmlNode:GetBool("capitalize");
	
	-- The ParaWorld ID of the subject of the sentence where this name is the object of the verb of the sentence. 
	-- Will use the reflexive when appropriate. When subjectid is used, nid is considered to be the object and nid's name is produced. 
	local subjectid = mcmlNode:GetString("subjectid");
	
	--
	-- build the user name content: first check the userinfo.nickname if not found, check the profile app's mcml box. 
	--
	-- use the value attribute as name if it exists
	local name = mcmlNode:GetAttributeWithCode("value"); 
	
	if(name==nil) then
		local user_info = Map3DSystem.App.profiles.ProfileManager.GetUserInfoInMemory(nid)
		if(user_info) then
			name = user_info.nickname;
		end
	end

	--自定义name的显示
	local customformat = mcmlNode:GetString("customformat");
	
	if(name==nil) then
		local bLocalVersion = true;
		
		Map3DSystem.App.profiles.ProfileManager.GetUserInfo(nid, "pe:name"..tostring(nid), function(msg)
			if(msg and msg.users and msg.users[1]) then
				local user = msg.users[1];
				local nickname = user.nickname;
				
				local function AutoRefresh(newName)
					if(newName and newName ~= name) then
						-- only refresh if name is different from last
						name = newName;
						
						local pageCtrl = mcmlNode:GetPageCtrl();
						if(pageCtrl) then
							--自定义name的显示样式
							--只支持两个参数 nickname and nid
							--like this: customformat="%s(%s)"
							if(customformat and customformat ~= "")then
								name = string.format(customformat,name,MyCompany.Aries.ExternalUserModule:GetNidDisplayForm(nid));
							end
							-- needs to refresh for newly fetched version.
							mcmlNode:SetAttribute("value", name)
							if(not bLocalVersion) then
								pageCtrl:Refresh();
							end	
						end
					end
				end
				
				if(nickname==nil or nickname=="") then
					-- if no nickname is provided, we will check its username in its profile, instead. 
					local profile = Map3DSystem.App.profiles.ProfileManager.GetProfile(nid);
					if(profile==nil or not profile:getUserInfo()) then
						Map3DSystem.App.profiles.ProfileManager.DownloadMiniProfile(nid, function(nid, appkey, bSucceed)
							local profile = Map3DSystem.App.profiles.ProfileManager.GetProfile(nid);
							if(profile and profile:getUserInfo()) then
								nickname = profile:getFullName() or L"匿名";
								AutoRefresh(nickname);
							end
						end)
					else
						nickname = profile:getFullName() or L"匿名";
						AutoRefresh(nickname);
					end	
				else
					AutoRefresh(nickname);
				end
			end	
		end)
		bLocalVersion = false;
	end
		
	
	-- TODO: each time we will rebuilt child nodes however, we can also reuse previously created ones. 
	mcmlNode:ClearAllChildren();

	if(name) then
		-- fix bug: nid: 227484624 
		-- remove additional newline sign
		name = string.gsub(name, "\n", "");

		-- final name text
		local currentUserNID = Map3DSystem.App.profiles.ProfileManager.GetNID();
		
		if(nid == currentUserID) then
			if(useyou == true) then
				if(subjectid == nid) then
					name = L"你";
				else
					name = L"你";
				end
			end
			--TODO:possessive  reflexive  useyou capitalize  subjectid capitalize 
		else
			if(subjectid == nid) then
				-- get gender in nid's user profile
				if(gender == "female") then
					name = L"她";
				elseif(gender == "male") then
					name = L"他";
				elseif(gender == nil) then
					name = L"它";
				end
			else
			end
			--TODO:possessive reflexive subjectid 
		end
		
		local profile_zorder = mcmlNode:GetNumber("profile_zorder");
		
		-- add a <a> node
		if(linked) then
			local linkNode = Map3DSystem.mcml.new(nil, {name="a"});
			linkNode:SetAttribute("target", "_mcmlblank");
			if(nid) then
				linkNode:SetAttribute("onclick", "Map3DSystem.mcml_controls.pe_name.OnClick");
				linkNode:SetAttribute("param1", nid);
				linkNode:SetAttribute("param2", profile_zorder);
			end	
			local tooltip = mcmlNode:GetAttributeWithCode("a_tooltip") or string.format(L"点击查看%s的个人资料", tostring(name));
			linkNode:SetAttribute("tooltip", tooltip);
			if(mcmlNode:GetAttribute("a_class")) then
				linkNode:SetAttribute("class", mcmlNode:GetAttribute("a_class"));
			end
			local shadowstyle = "";
			if(style) then
				if(style["text-shadow"]) then
					shadowstyle = "text-shadow:true;";
					if(style["shadow-quality"]) then
						shadowstyle = format("%sshadow-quality:%s;", shadowstyle, tostring(style["shadow-quality"]));
					end
					if(style["shadow-color"]) then
						shadowstyle = format("%sshadow-color:%s;", shadowstyle, tostring(style["shadow-color"]));
					end
				end
			end
			if(mcmlNode:GetAttribute("a_style")) then
				linkNode:SetAttribute("style", shadowstyle..mcmlNode:GetAttribute("a_style"));
			elseif(mcmlNode:GetAttribute("style")) then
				linkNode:SetAttribute("style", shadowstyle..("" or mcmlNode:GetAttribute("style")));
			else
				linkNode:SetAttribute("style", "padding-left:3px;padding:0px;height:20px;");
			end
			linkNode:SetInnerText(name);
			mcmlNode:AddChild(linkNode, nil);
			--commonlib.log("TODO: name(%s) NODE added\n", name)
		else
			mcmlNode:SetInnerText(name);
		end
		-- just use the standard style to create the control	
		Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
end

-- private: user clicks on the nid. left mouse button to open its profile page, right mouse button to open contextmenu.
function pe_name.OnClick(nid, profile_zorder)
	Map3DSystem.App.Commands.Call(Map3DSystem.options.ViewProfileCommand, {nid = nid, profile_zorder = profile_zorder, mouse_button = mouse_button});
end

-- get the MCML value on the node
function pe_name.GetValue(mcmlNode)
	--return mcmlNode:GetAttribute("nid");
	return mcmlNode:GetAttribute("value");
end

-- set the MCML value on the node
function pe_name.SetValue(mcmlNode, value)
	--mcmlNode:SetAttribute("nid", value);
	mcmlNode:SetAttribute("value", value); 
	mcmlNode:SetAttribute("fetching", nil); 
end


----------------------------------------------------------------------
-- pe:if-is-user: handles MCML tag <pe:if-is-user>
-- Only renders the content inside the tag if the viewer is one of the specified user(s). 
----------------------------------------------------------------------

local pe_if_is_user = {};
Map3DSystem.mcml_controls.pe_if_is_user = pe_if_is_user;

-- pe_name is just a wrapper of button control with user name as text
function pe_if_is_user.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local isUser;
	local nids = mcmlNode:GetAttributeWithCode("nid");
	local curNID = Map3DSystem.App.profiles.ProfileManager.GetNID();
	if(nids == "loggedinuser") then
		isUser = (curNID and (curNID > 1))
	elseif(nids == "notloggedinuser") then	
		isUser = not (curNID and (curNID > 1))
	elseif(curNID~=nil and type(nids) == "string") then
		local nid;
		for nid in string.gfind(nids, "([%d]+)") do 
			nid = tonumber(nid);
	        if(nid == curNID) then
				isUser = true;
				break;
	        end
		end
	end	
	if(isUser) then
		Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
end

----------------------------------------------------------------------
-- pe:quickaction: handles MCML tag <pe:quickaction>
----------------------------------------------------------------------
local pe_quickaction = {};
Map3DSystem.mcml_controls.pe_quickaction = pe_quickaction;

-- renders the quick action links to specific user in tree view
-- NOTE: quick action links may shown in the profile left bar or the right click menu
function pe_quickaction.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	-- TODO: implementation
	
	-- TODO: traverse through all applications to get the quick action links
	
	-- TODO: links display order
	
	width = parentLayout:GetPreferredSize();
	
	left, top = parentLayout:GetAvailablePos();
	
	local height = 0;
	local i = 0;
	local j; -- TODO: debug purpose
	for j = 1, 4 do
		-- traverse through all the applications that require quick action links
		local actionlink = ParaUI.CreateUIObject("button", "link"..i, "_mt", 0, top + i * 24, 0, 24);
		if(j == 1) then
			actionlink.text = "Super Poke";
		elseif(j == 2) then
			actionlink.text = "View Books";
		elseif(j == 3) then
			actionlink.text = "Send a gift";
		elseif(j == 4) then
			actionlink.text = "Invite to activity";
		end
		actionlink.background = "Texture/3DMapSystem/Profile/QuickActionLinkBG.png: 4 4 4 4";
		_parent:AddChild(actionlink);
		local removeicon = ParaUI.CreateUIObject("button", "removelink"..i, "_rt", -24, top + i * 24, 24, 24);
		removeicon.background = "Texture/3DMapSystem/common/Close.png";
		_parent:AddChild(removeicon);
		
		i = i + 1;
	end
	-- default action links: send message, poke, view friends and add to friends
	local defaultactionlink = ParaUI.CreateUIObject("button", "defaultlink1", "_mt", 0, top + i * 24, 0, 24);
	defaultactionlink.text = "Send him/her a message";
	defaultactionlink.background = "Texture/3DMapSystem/Profile/QuickActionLinkBG.png: 4 4 4 4";
	_parent:AddChild(defaultactionlink);
	i = i + 1;
	local defaultactionlink = ParaUI.CreateUIObject("button", "defaultlink2", "_mt", 0, top + i * 24, 0, 24);
	defaultactionlink.text = "Poke him/her";
	defaultactionlink.background = "Texture/3DMapSystem/Profile/QuickActionLinkBG.png: 4 4 4 4";
	_parent:AddChild(defaultactionlink);
	i = i + 1;
	local bIsFriend;
	bIsFriend = true;
	if(bIsFriend == true) then
		-- between friends
		-- TODO: view the friend list in additional friend profile box
	else
		-- not yet friends
		local defaultactionlink = ParaUI.CreateUIObject("button", "defaultlink3", "_mt", 0, i * 24, 0, 24);
		defaultactionlink.text = "View Friends";
		defaultactionlink.background = "Texture/3DMapSystem/Profile/QuickActionLinkBG.png: 4 4 4 4";
		_parent:AddChild(defaultactionlink);
		i = i + 1;
		local defaultactionlink = ParaUI.CreateUIObject("button", "defaultlink4", "_mt", 0, i * 24, 0, 24);
		defaultactionlink.text = "Add to friends";
		defaultactionlink.background = "Texture/3DMapSystem/Profile/QuickActionLinkBG.png: 4 4 4 4";
		_parent:AddChild(defaultactionlink);
		i = i + 1;
	end
	
	-- reset the container height
	--_parent.height = i * 24;
	
	-- add to parent layout
	parentLayout:AddObject(width, i * 24);
end

----------------------------------------------------------------------
-- pe:onlinestatus: handles MCML tag <pe:onlinestatus>
----------------------------------------------------------------------
local pe_onlinestatus = {};
Map3DSystem.mcml_controls.pe_onlinestatus = pe_onlinestatus;

-- renders the online status to specific user
-- NOTE: online status is synchronized with Chat application
--		Chat application's online status is updated by hooking the profile manager update process
function pe_onlinestatus.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	-- TODO: implementation
	
	local statusWidth = _guihelper.GetTextWidth("I am online now.") + 5;
	
	width = parentLayout:GetPreferredSize();
	if(statusWidth > width) then
		parentLayout:NewLine();
		width = parentLayout:GetMaxSize();
		if(statusWidth > width) then
			statusWidth = width
		end
	end
	
	left, top = parentLayout:GetAvailablePos();
	
	-- get the online status
	local userStatus;
	
	userStatus = Map3DSystem.App.profiles.userStatus.Online; --  TODO: debug purpose

	if(userStatus == Map3DSystem.App.profiles.userStatus.Online) then
		local onlinetext = ParaUI.CreateUIObject("text", "onlinenow", "_lt", left, top + 4, width, 24);
		onlinetext.text = "I am online now.";
		_parent:AddChild(onlinetext);
		local onlineicon = ParaUI.CreateUIObject("container", "onlineicon", "_rt", -40, top, 32, 32);
		onlineicon.background = "Texture/3DMapSystem/IM/online.png";
		_parent:AddChild(onlineicon);
	elseif(userStatus == Map3DSystem.App.profiles.userStatus.Offline) then
		-- TODO: implement the other user status
	end
	
	-- add to parent layout
	parentLayout:AddObject(width, 32);
end

----------------------------------------------------------------------
-- pe:friends: handles MCML tag <pe:friends>
----------------------------------------------------------------------
local pe_friends = {};
Map3DSystem.mcml_controls.pe_friends = pe_friends;

-- show the friends in list/grid/... format
-- NOTE: friends is updated with Chat application, TODO: wait for Lorne's design document
-- NOTE: friends view mode: list, grid, .etc
--		list: view the friends in a list(treeview), grouped in categories
--		grid: view the friends in a grid(gridview), ordered by last login time
--		full/mini: show the friends grid in full mode or mini mode, 
--			the mini mode only shows limited number of friends. default mini mode
--		graph: show the friends in graph, the social graph shows the friends of the user, as well as the 
--			friends relationships among the friends.
function pe_friends.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	--TODO: implementation
	
	width = parentLayout:GetPreferredSize();
	
	if(180 > width) then
		parentLayout:NewLine();
	end
	
	left, top = parentLayout:GetAvailablePos();
	
	-- get current profile application count
	local nCountApp = 16;
	
	-- 5 cell columns grid view
	local rows = math.ceil(nCountApp / 5);
	
	local ctl = CommonCtrl.GetControl("ProfileApplicationGridView");
	if(ctl ~= nil) then
		CommonCtrl.DeleteControl(ctl.name);
	end
	
	NPL.load("(gl)script/ide/GridView.lua");
	ctl = CommonCtrl.GridView:new{
		name = "ProfileApplicationGridView",
		alignment = "_lt",
		container_bg = "Texture/tooltip_text.png",
		left = left, top = top,
		width = 180,
		height = rows * 36,
		cellWidth = 36,
		cellHeight = 36,
		parent = _parent,
		columns = 5,
		rows = rows,
		DrawCellHandler = pe_friends.OwnerDrawFriendsGridCellHandler,
	};

	-- TODO: add the application icons according to the profile application list
	local i;
	for i = 1, 16 do
		local cell = CommonCtrl.GridCell:new{
			GridView = nil,
			name = "app"..i,
			text = "app"..i,
			index = i,
			column = 1,
			row = 1,
			};
		ctl:AppendCell(cell, "Right");
	end

	ctl:Show();

	-- reset the parent container height
	--_parent.height = rows * 36;
	
	-- add to parent layout
	parentLayout:AddObject(180, rows * 36);
end

function pe_friends.OwnerDrawFriendsGridCellHandler(_parent, gridcell)
	if(_parent == nil or gridcell == nil) then
		return;
	end
	
	if(gridcell.text ~= nil) then
		local _this = ParaUI.CreateUIObject("button", gridcell.text, "_fi", 2, 2, 2, 2);
		-- TODO: temp application icon debug purpose
		if(gridcell.index < 10) then
			_this.background = "Texture/face/0"..gridcell.index..".png";
		else
			_this.background = "Texture/face/"..gridcell.index..".png";
		end
		_this.animstyle = 12;
		_this.tooltip = gridcell.text;
		_this.onclick = ";_guihelper.MessageBox(\"".."friend click on:"..gridcell.row.." "..gridcell.column.."\");";
		_parent:AddChild(_this);
	end
end