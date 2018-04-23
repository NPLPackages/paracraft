--[[
Title: autotips in paraworld
Author(s): LiXizhi
Date: 2008.6.17
Desc:
---++ overview
Any application can call autotips to display some hints to the user at the top of the screen in highlighted text. 
To globally enable or disable this feature call. 
<verbatim>
	autotips.Show(bShow);
</verbatim>

Tips are categoried, the default one is "UI". Tips inside a given category are mutually exclusive. To add a tip, call below
<verbatim>
	autotips.AddTips(category, text, priority);
	-- add default one 
	autotips.AddTips(nil, "This is a tip");
</verbatim>
Tips are not immediately displayed, a timer is used to refresh tip text. The text may contain mcml data.
If there have been no tips to display, it will automatically loop pick from a pool of idle tips to display every few seconds.

To force update the tip text, call autotips.Refresh()

---++ idle tips
idle tips are displayed one after another when there are nothing to display
all idle tips are removed when application desktop switched. An application can usually add several Idle Tips
in its OnActivateDesktop function, such as prompting the user with tips specific to that application. 
<verbatim>
	autotips.AddIdleTips(text)
</verbatim>

---++ message tips
sometimes, we want to display text that are too strong to use a popup message box, but still too week to use an ordinary tip box. 
Hence, we can use something in the middle called message tips. Message tips are displayed only for a specified period but 
is displayed with a more highlighted color. Multiple message tips can be displayed at the same time until the specified time period passed. 
<verbatim>
	autotips.AddMessageTips("You can not take control of this character.")
</verbatim>

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/autotips.lua");
autotips.Show();
autotips.AddTips("nextaction", "press Ctrl key to sit!", 0);
-------------------------------------------------------
]]

-- common control library
NPL.load("(gl)script/ide/common_control.lua");
if(not autotips) then autotips={}; end
autotips.tips = {};
autotips.idleTips = {};
autotips.idleTipIndex = 0;
autotips.tipAEMenu = nil;
-- container name
autotips.Name = "_autotip_";
autotips.state = "message" -- message or idle

--@param bShow: boolean to show or hide. if nil, it will toggle current setting. 
--@param x: position to display or nil
--@param y: position to display or nil
--@param return: bShow
function autotips.Show(bShow, x, y)
	-- TODO: ensure x,y is inside window area. 
	local _this,_parent;
	_this=ParaUI.GetUIObject(autotips.Name);
	if(_this:IsValid() == false) then
		if(bShow == false) then return	end
		bShow = true;
		_this = ParaUI.CreateUIObject("container", autotips.Name, "_ctt", x or 0, y or 50, 512, 64)
		_this.background = "";
		_this.enabled = false;
		_this.zorder = -1;
		_this:AttachToRoot();
		_parent = _this;
		--if(autotips.MyPage == nil) then
			--autotips.MyPage = Map3DSystem.mcml.PageCtrl:new({url="script/kids/3DMapSystemUI/Desktop/autotipsPage.html"});
		--end	
		--autotips.MyPage:Create("autotip", _parent, "_fi", 0, 0, 0, 0)
		
		if(autotips.tipAEMenu ==nil)then
			NPL.load("(gl)script/ide/Motion/AnimativeMenu/TipMenu.lua");
			autotips.tipAEMenu =  CommonCtrl.Motion.AnimativeMenu.TipAEMenu:new{
				alignment = "_lt",
				left = 0,
				top =  0,
				width = 512,
				height = 64, 
				parent = _parent,
				textfont = "System;14;bold", 
				textcolor = "0 0 0 0",
			}
			autotips.tipAEMenu.DeleteNodeEvent = autotips.DeleteNodeEvent;
		else
			autotips.tipAEMenu.parent = _parent;
		end
		autotips.tipAEMenu:Show(bShow);
		_this = _parent;
	else
		if(bShow == nil) then
			bShow = not _this.visible;
		end
		_this.visible = bShow;
	end
	-- Update Value
	if (x) then
		_this.x = x;
	end	
	if (y) then
		_this.y = y;
	end	
	autotips.is_shown = bShow;
	return bShow;
end
function autotips.Clear()
	local tipAEMenu = autotips.tipAEMenu;
	if(tipAEMenu)then
		local rootNode = tipAEMenu.RootNode;
		if(rootNode)then
			rootNode:ClearAllChildren();
		end
		autotips.tips = {};
		autotips.idleTips = {};
		autotips.idleTipIndex = 0;
		autotips.tipAEMenu = nil;
		autotips.state = "message"
	end
end
function autotips.DeleteNodeEvent(node)
	local tipAEMenu = autotips.tipAEMenu;
	local len;
	if(tipAEMenu == nil) then
		len = 0;
	else
		len = tipAEMenu.RootNode:GetChildCount();
	end
	
	if(len == 0 )then
		if(autotips.state =="message")then
			autotips.state = "idle";		
		end
		autotips.startAutoPlay();
	end
end

function autotips.Refresh()
end
-- destory the control
function autotips.OnDestory()
	ParaUI.Destroy(autotips.Name);
end
function autotips.startAutoPlay()
	local idleLen = table.getn(autotips.idleTips);
	autotips.idleTipIndex = autotips.idleTipIndex + 1;
	if(autotips.idleTipIndex > idleLen)then
		autotips.idleTipIndex = 1;
	end
	local txt = autotips.idleTips[autotips.idleTipIndex];
	
	if(txt)then
		if(autotips.tipAEMenu ~= nil) then
			local index = autotips.tipAEMenu.RootNode:GetChildCount() - table.getn(autotips.tips);
			if(index ==0)then index = 1; end		
			autotips.addNode(txt,index,false)
		end
	end
end
function autotips.DoResume()
	local tipAEMenu = autotips.tipAEMenu;
	if(not tipAEMenu)then return; end
	tipAEMenu:DoResume();
end
function autotips.DoPause()
	local tipAEMenu = autotips.tipAEMenu;
	if(not tipAEMenu)then return; end
	tipAEMenu:DoPause();
end
function autotips.DoDisable()
	local tipAEMenu = autotips.tipAEMenu;
	if(not tipAEMenu)then return; end
	tipAEMenu:DoPause();
	tipAEMenu:Show(false);
end
function autotips.DoEnable()
	local tipAEMenu = autotips.tipAEMenu;
	if(not tipAEMenu)then return; end
	tipAEMenu:DoResume();
	tipAEMenu:Show(true);
end
-- remove all idle tips or a given tip.
-- all idle tips are removed when application desktop switched. An application can usually add several Idle Tips
-- in its OnActivateDesktop function. 
-- @param text: if nil it will remove all of them. otherwise it is just the text to remove. 
--function autotips.RemoveIdeTips(text)
	--if(not text) then
		--commonlib.resize(autotips.idleTips, 0);
	--else
		---- TODO: remove a given one.
	--end
--end

-- idle tips are displayed one after another when there are nothing to display
-- it will switch the current idle tip index to the given text. 
function autotips.AddIdleTips(text)
	table.insert(autotips.idleTips,text);
	if(table.getn(autotips.idleTips) ==1 )then
		autotips.startAutoPlay();
	end
end
-- sometimes, we want to display text that are too strong to use a popup message box, but still too week to use an ordinary tip box. 
-- Hence, we can use something in the middle called message tips. Message tips are displayed only for a specified period but 
-- is displayed with a more highlighted color.
function autotips.AddMessageTips(text)
	if(not autotips.tipAEMenu) then  return end
	if(not text or text =="")then return end;
	if(not autotips.is_shown) then
		return;
	end
	autotips.state ="message";
	local len = autotips.tipAEMenu.RootNode:GetChildCount() 
	--local index = len - table.getn(autotips.tips);
	local index = len
	index = index + 1
	autotips.addNode(text,index,false)
end

-- add a tip to a given category, there can only be one text in any category at a given time. 
-- a tip in a given category is only displayed if it has higher priority than the one in the table
-- @param category: string or nil. default to "UI"
-- @param text: string or nil, it will clear whatever in the category.
-- @param priority: number or nil. the larger the higher. default is 0.
function autotips.AddTips(category, text, priority)
	local tipAEMenu = autotips.tipAEMenu;	
	if(not tipAEMenu) then  return end
	if(not category) then  category = "UI"; end
	if(not priority) then priority = 0; end
	
	if(text)then				
			local rootnode = tipAEMenu.RootNode;
			local k,len = 1,rootnode:GetChildCount();
			for k =1,len do
				local node = rootnode:GetChild(k);
				if(node.category and node.category == category)then
					if(node.Text ~= text)then
						node.Text = text;
						node.mc:Reset();
						tipAEMenu:RebornMotion(node);
					end
					return;
				end
			end
			local obj = {category = category,text = text,priority = priority }
			table.insert(autotips.tips,obj);

			local len = autotips.tipAEMenu.RootNode:GetChildCount() 
			local index = len
			index = index + 1
			autotips.addNode(text,index,true,category,priority);
			
	else
			autotips.ClearTip(category);
	end	
end
function autotips.addNode(txt,index,isStaticTop,category,priority)
	local tipAEMenu = autotips.tipAEMenu;	
	local rootnode = tipAEMenu.RootNode;
	local node = CommonCtrl.TreeNode:new({Text = txt});
	if(category)then node.category = category; end
	if(priority)then node.priority = priority; end
	local alive,child = tipAEMenu:NodeAlive(node)
	if(alive and child and not category )then
		tipAEMenu:RebornMotion(child);
	else
		rootnode:AddChild(node,index);
		tipAEMenu:BoundMotion(node);
		if(isStaticTop)then
			local engine = node.mc.animatorEngine;
			-- if this is 0, it will repeat infinitly. 
			engine.repeatCount = 0;
		end
	end	
	
end
function autotips.ClearTip(category)
	if(not category) then return; end
	local k,obj;
	for k,obj in ipairs(autotips.tips) do
		if(obj.category == category)then
			table.remove(autotips.tips,k);
			break;
		end
	end
	
	local tipAEMenu = autotips.tipAEMenu;	
	if(not autotips.tipAEMenu) then  return end
	local rootnode = tipAEMenu.RootNode;
	local k,len = 1,rootnode:GetChildCount();
	for k =1,len do
		local node = rootnode:GetChild(k);
		if(node.category and node.category == category)then
			tipAEMenu:UnBoundMotion(node);
			break;
		end
	end
	
end
