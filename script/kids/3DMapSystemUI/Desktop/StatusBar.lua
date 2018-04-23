--[[
Title: Status Bar for paraworld task bar
Author(s): WangTian
Date: 2008/6/23
Desc: Status task bar is docked on the right most of the task bar
	It currently has two distinct function field: Feed and Tasks
	(1) Feed can send notifications to the user. Most feeds are associated with user profile and viewable by both 
	its owner and visitors, thus allowing viral distribution of user goals, contents and actions among its friends.
	Feed shows on the right most of the status bar, with the highest priority.
	(2) Task is a different notification that allows easy management on the application, including two kinds of tasks:
		@ The first kind of task is user specific task, like the chat windows, exchange windows. Usually these windows associate with a 
		specific user(s), and the application wants that activity stay alive in the AppTaskBar.
		@ The second kind of task in application specific task, like server status, toggle minimap, toggle autotips .etc.
		Most of them just keep the application functions easy to manage via single click, not hiden in the toolbar which require application switching.
	But the status bar does't distinguish these two kinds of tasks, user specific and task specific. The status bar only shows the 
	tasks in a priority order. That is the application developer can choose its own position.
	
NOTE: status bar is part of AppTaskBar, which is automaticly shown in AppTaskBar.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/StatusBar.lua");
Map3DSystem.UI.AppTaskBar.StatusBar.Refresh(_parent);
------------------------------------------------------------
]]

local libName = "StatusBar";
local libVersion = "1.0";

local StatusBar = commonlib.LibStub:NewLibrary(libName, libVersion)
Map3DSystem.UI.AppTaskBar.StatusBar = StatusBar;


-- add a status bar task.
-- @param task:
--	{
--		name = "Chat1",
--		icon = "optional icon, usually has it",
--		text = "this is optional",
--		tooltip = "some text",
--		commandName = "",
--	}
-- @param priority: number
--		Priority defines the position of the given command in the status bar. Higher priority shown on the right.
--		For those items with the same priority, the more recent added has lower priority which shows on the left.
-- Here are some default priorities for official applications:
--		ChatWindow: 3, OfficalAppStatus: 8, DefaultPriority: 5
function StatusBar.AddTask(task, priority)
	if(task ~= nil and task.name ~= nil) then
		-- default priority
		priority = priority or 5;
		
		if(Map3DSystem.UI.AppTaskBar.StatusBarNode:GetChildByName(task.name)) then
			log("Command: "..task.name.." already added into the status bar\n");
			return;
		end
		
		StatusBar.Accumulator = StatusBar.Accumulator or 1000;
		StatusBar.Accumulator = StatusBar.Accumulator - 1;
		
		Map3DSystem.UI.AppTaskBar.StatusBarNode:AddChild(CommonCtrl.TreeNode:new({
			Name = task.name, 
			priority = priority,
			comparePriority = priority * 1000 + StatusBar.Accumulator,
			task = task,
			}));
		Map3DSystem.UI.AppTaskBar.StatusBarNode:SortChildren(CommonCtrl.TreeNode.GenerateGreaterCFByField("comparePriority"));
		--Map3DSystem.UI.AppTaskBar.StatusBarNode:SortChildren(CommonCtrl.TreeNode.GenerateLessCFByField("comparePriority"));
		
		-- refresh the status bar
		StatusBar.Refresh();
	end
end

-- remove task from the status bar
-- @param taskName: the task to be removed from the status bar
function StatusBar.RemoveTask(taskName)
	if(Map3DSystem.UI.AppTaskBar.StatusBarNode:GetChildByName(taskName)) then
		Map3DSystem.UI.AppTaskBar.StatusBarNode:RemoveChildByName(taskName);
		
		-- refresh the status bar
		StatusBar.Refresh();
	end
end

-- remove all tasks in status bar
function StatusBar.ClearTasks()
	log("warning: All statusBar commands cleared\n")
	Map3DSystem.UI.AppTaskBar.StatusBarNode:ClearAllChildren();
	
	-- refresh the status bar
	StatusBar.Refresh();
end

function StatusBar.Refresh(_parent)
	--local _bar, _this, _parent;
	--local left,top,width,height;
	
	_parent = _parent or StatusBar.parentUIObj;
	if(_parent == nil) then
		return;
	end
	
	if(_parent:IsValid() == false) then
		log("Invalid parent UI object in StatusBar.Show()\n");
		StatusBar.parentUIObj = nil;
		return;
	end
	
	-- record the _parent for refresh
	StatusBar.parentUIObj = _parent;
	
	-- remove all children, since we will rebuild all. 
	_parent:RemoveAll();
	
	local iconSize = 16;
	local taskHeight = 24;
	local taskWidth = 72;
	local left = 22;
	local iconTop = (taskHeight - iconSize)/2;
	
	_bar = ParaUI.CreateUIObject("container", libName, "_fi", 0, 0, 0, 0);
	_bar.background = "";
	_parent:AddChild(_bar);
	
	--
	-- the right most feed display area
	--
	-- modified a little bit by LXZ 2008.6.22
	--local nCount = table.getn(Map3DSystem.App.ActionFeed.feeds);
	local nCount = 0;
	local _feed = ParaUI.CreateUIObject("button", "FeedPopUpBtn", "_rt", -20, iconTop, iconSize, iconSize);
	if(nCount > 0)then
		_feed.text = tostring(nCount);
	end	
	_feed.tooltip = string.format("你有 %d 条消息", nCount);
	_feed.background = "Texture/3DMapSystem/common/feed.png";
	_feed.animstyle = 13;
	_guihelper.SetUIColor(_feed, "255 255 255");
	_guihelper.SetFontColor(_feed, "255 255 255");
	_bar:AddChild(_feed);
	
	
	--
	-- all other custom buttons added via application interface
	--
	local _,_, maxWidth = _parent:GetAbsPosition();
	maxWidth = maxWidth - 22;
	local bNoSpaceLeft;
	
	local count = 0; -- number of icon created. 
	local index, task;
	for index, task in ipairs(Map3DSystem.UI.AppTaskBar.StatusBarNode.Nodes) do
		--if(task.AppCommand) then	
			local task = task.task;
			-- LiXizhi 2008.6.22, added automatic taskWidth
			taskWidth = 0;
			if(task.icon) then
				taskWidth = taskWidth+iconSize+iconTop;
			end
			if(task.text) then
				taskWidth = taskWidth+_guihelper.GetTextWidth(task.text);
			end
			if(taskWidth == 0) then
				taskWidth = 16;
			end
			
			if((left + taskWidth) < maxWidth) then
			
				local _task = ParaUI.CreateUIObject("container", "Task_"..task.name, "_rt", -(left + taskWidth), 0, taskWidth, taskHeight);
				_task.background = "";
				_bar:AddChild(_task);
				
				local _left = 0
				if(task.icon) then
					local _icon = ParaUI.CreateUIObject("button", "Icon", "_lt", _left, iconTop, iconSize, iconSize);
					_icon.background = task.icon;
					_guihelper.SetUIColor(_icon, "255 255 255");
					_icon.animstyle = 13;
					_icon.onclick = string.format(";Map3DSystem.App.Commands.Call(%q);", task.commandName);
					_task:AddChild(_icon);
					if(task.tooltip) then
						_icon.tooltip = task.tooltip;
					end
					_left = _left+iconSize+iconTop
				end	
				
				if(task.text) then
					local _text = ParaUI.CreateUIObject("button", "Text", "_lt", _left, 0, taskWidth-left, taskHeight);
					_text.background = "";
					_text.text = task.text;
					_text.onclick = string.format(";Map3DSystem.App.Commands.Call(%q);", task.commandName);
					if(task.tooltip) then
						_text.tooltip = task.tooltip;
					end
					_task:AddChild(_text);
				end	
				
				left = left + taskWidth + 2;
			else
				bNoSpaceLeft = true;
			end	
			
			count = count + 1;
			-- 5 is maximum status bar icon number
			if(bNoSpaceLeft) then
				-- show extension button << using a popup menu control.
				StatusBar.ExtensionItemIndex = index;
				
				local _this = ParaUI.CreateUIObject("button", "extBtn", "_rt", -(left + 16), 5, 16, 16)
				_this.background = "Texture/3DMapSystem/Desktop/ext_left.png";
				_this.animstyle = 12;
				_this.onclick = ";Map3DSystem.UI.AppTaskBar.StatusBar.ShowStatusBarExtensionMenu();"
				_bar:AddChild(_this);
				break;
			end
		--end	
	end
	
	-- bring up a context menu for selecting extension items. 
	function Map3DSystem.UI.AppTaskBar.StatusBar.ShowStatusBarExtensionMenu()
		local ctl = CommonCtrl.GetControl("statusbar.ExtensionMenu");
		if(ctl == nil)then
			ctl = CommonCtrl.ContextMenu:new{
				name = "statusbar.ExtensionMenu",
				width = 130,
				height = 150,
				DefaultIconSize = 24,
				DefaultNodeHeight = 26,
				container_bg = "Texture/3DMapSystem/ContextMenu/BG2.png:8 8 8 8",
				onclick = function (node, param1)
						if(node.commandName ~= nil) then
							Map3DSystem.App.Commands.Call(node.commandName);
						end
					end,
				AutoPositionMode = "_lb",
			};
		end
		local _this = Map3DSystem.App.ActionFeed.StatusBar.parentUIObj:GetChild("extBtn");
		if(_this:IsValid()) then
			local x, y, width, height = _this:GetAbsPosition();
			
			ctl.RootNode:ClearAllChildren();
			
			local index, node
			
			local nSize = Map3DSystem.UI.AppTaskBar.StatusBarNode:GetChildCount();
			
			for index = StatusBar.ExtensionItemIndex, nSize do
				ctl.RootNode:AddChild(CommonCtrl.TreeNode:new(CommonCtrl.TreeNode:new({
					Text = Map3DSystem.UI.AppTaskBar.StatusBarNode.Nodes[index].text, 
					Name = Map3DSystem.UI.AppTaskBar.StatusBarNode.Nodes[index].name, 
					commandName = Map3DSystem.UI.AppTaskBar.StatusBarNode.Nodes[index].commandName, 
					Icon = Map3DSystem.UI.AppTaskBar.StatusBarNode.Nodes[index].icon})));
			end
			
			ctl:Show(x, y);
		end	
	end
end