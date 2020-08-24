--[[
Title: DockTipPage
Author(s): leio
Date: 2020/8/17
Desc:  
Use Lib:
-------------------------------------------------------
local DockTipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockTipPage.lua");
DockTipPage.GetInstance():PushGsid(888);
DockTipPage.GetInstance():PushGsid(998,100);
DockTipPage.GetInstance():PushGsid(888,10);
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");

NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local DockTipPage = NPL.export();

DockTipPage.timer = nil;
DockTipPage.node_list = {};
DockTipPage.page_name = "DockTipPage.ShowPage";
DockTipPage.page_ctrl = nil;
DockTipPage.page_file = "script/apps/Aries/Creator/Game/Tasks/Dock/DockTipPage.html";
DockTipPage.cur_interval = 0;
DockTipPage.interval = 100;
DockTipPage.duration = 5000;
DockTipPage.timer_enabled = false;
DockTipPage.instance_map = {};
function DockTipPage.GetInstance(name)
	name = name or "docktippage_instance";
	if(not DockTipPage.instance_map[name])then
		DockTipPage.instance_map[name] = DockTipPage:new()
	end
	return DockTipPage.instance_map[name];
end
function DockTipPage:new (o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	o:OnInit();
	return o
end
function DockTipPage:GetParams(name)
	if(not name)then return end
	local k,v;
	for k,v in ipairs(self.pos_list) do	
		if(v.name == name)then
			return v;
		end
	end
end
function DockTipPage:OnInit_GetPageCtrl()
	self.page = document:GetPageCtrl();
end
function DockTipPage:ChangeWorld()
	if(self.timer)then
		self.timer:Change(0, self.interval);
	end
	self.is_showing_node = false;
end
function DockTipPage:GetNodeList()
	return self.node_list;
end
function DockTipPage:GetUserName()
    local User = commonlib.gettable("System.User")
    return User.username or "";
end
function DockTipPage:OnInit()
	self:ChangeWorld();
	if(self.is_init)then
		return
	end
	self.is_init = true;
	self.timer = commonlib.Timer:new();
	self.timer.callbackFunc = DockTipPage.TimerCallBack;
	self.node_list = {};
	self.pending_gsid_list = {};

	self.pos_list = {
		{name = "bag", label = "背包", x = -130, y = -5, title="你获得了新物品！", },
	}
	
	local key = string.format("DockTipPage:SetActiveTimer_%s",DockTipPage:GetUserName());
	self.timer_enabled = GameLogic.GetPlayerController():LoadLocalData(key, false);
	self.timer:Change(0, self.interval);
end
function DockTipPage:IsVisible()
	if(self.page)then
		return self.page:IsVisible();
	end
end
function DockTipPage:RemoveTopNode()
	local len = #self.node_list;
	local node = self.node_list[1];
	if(node)then
		table.remove(self.node_list,1);
	end
	self:HideTip();
	return node;
end
function DockTipPage:ShowTopNode()
	self:HideTip();
	self:BubbleTip();
end
function DockTipPage:HideTip()
	if(self.page)then
		self.page:CloseWindow();
		self.page = nil;
	end
end
function DockTipPage:BubbleTip()
	local node = self:GetFirstNode();
	if(not node or not node.name)then return end
	local name = node.name;
	local params = self:GetParams(name);
	if(params)then
		local obj = DockPage.FindUIControl(name);
        local x = 0;
        local y = 0;
		if(obj and obj:IsValid())then
			local obj_x, obj_y, screen_width, screen_height = obj:GetAbsPosition();
            x = obj_x + params.x;
            y = obj_y + params.y;
        end
		self:CreatePage(x,y,name);
	end
end

function DockTipPage:DoAction(node)
	if(node) then
		local onclick_func = node.onclick;
		local gsid = node.gsid;
		if(onclick_func and DockTipPage[onclick_func])then
			DockTipPage[onclick_func](gsid, node);
		end
	end
end

-- called periodically
function DockTipPage.TimerCallBack(timer)
	if(DockTipPage.instance_map)then
		local k,dock_tip;
		for k,dock_tip in pairs(DockTipPage.instance_map) do
			local max_duration = 3000;
			local pending_time = dock_tip.pending_time or 0
			pending_time = pending_time + dock_tip.interval;
			if(pending_time >= max_duration)then
				dock_tip:CheckAllPendingGsids();				
				dock_tip.pending_time = 0
			else
				dock_tip.pending_time = pending_time;
			end
			if(not dock_tip:HasChildren())then
				return
			end
			local can_show = dock_tip:CheckCanShow();
			if(can_show)then
                
				if(not dock_tip.is_showing_node)then
					dock_tip.cur_interval = 0;
					dock_tip:ShowTopNode();
					dock_tip.is_showing_node = true;
				else
					dock_tip.cur_interval = dock_tip.cur_interval + dock_tip.interval;
					if(dock_tip.cur_interval >= dock_tip.duration)then
						if(dock_tip.timer_enabled)then
							dock_tip.is_showing_node = false;
							local node = dock_tip:RemoveTopNode();
							dock_tip:DoAction(node);
						end
					end
				end
				--逻辑显示 但是窗口没有显示
				if(dock_tip.is_showing_node and not dock_tip:IsVisible())then
					dock_tip:ShowTopNode();
				end
			else
				dock_tip:HideTip();
			end
					
			
		end
	end
	
end

function DockTipPage:SetActiveTimer()
	if(self.timer_enabled)then
		self.timer_enabled = false;
	else
		self.timer_enabled = true
		if(self.is_showing_node)then
			self.cur_interval = 0;
		end
	end
	local key = string.format("DockTipPage:SetActiveTimer_%s",DockTipPage:GetUserName());
	GameLogic.GetPlayerController():SaveLocalData(key, self.timer_enabled);
end
function DockTipPage:TimerIsEnabled()
	return self.timer_enabled;
end
--检查窗口是否在显示，如果显示，隐藏DockTipPage
function DockTipPage:CheckCanShow()
    return DockPage.IsShow();
end

function DockTipPage:GetTipCount()
	return #self.node_list;
end
function DockTipPage:__PushNode(node)
	if(not node or node.animation_only)then return end
	local gsid = node.gsid;
	table.insert(self.node_list,node);
end
function DockTipPage:PushNode(node)
	if(not node)then return end
	if(not self.is_init)then
		return
	end
	self:__PushNode(node);
end
function DockTipPage:Manual_RemoveFirstNode()
	self.is_showing_node = false;
	self:RemoveTopNode();
end
function DockTipPage:GetFirstNode()
	return self.node_list[1];
end
function DockTipPage:HasChildren()
	local len = #self.node_list;
	if(len > 0)then
		return true;
	end
end
function DockTipPage:DeleteNodeByName(name)
	if(not name)then return end
	local node = self:GetFirstNode();
	if(node and node.name and node.name == name)then
		table.remove(self.node_list,1);
	end
end
function DockTipPage:ShowPage()
end
function DockTipPage:CreatePage(x,y,name)
	local url = string.format("%s?name=%s",self.page_file,name or "");
	local params = {
			url = url, 
			name = self.page_name, 
			app_key=MyCompany.Aries.app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			enable_esc_key = false,
			isTopLevel = false,
			allowDrag = false,
			click_through = true, -- allow clicking through
			directPosition = true,
				align = "_lt",
				x = x ,
				y = y - 100,
				width = 200,
				height = 100,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
function DockTipPage:BuildTag(gsid,tag)
	if(not gsid)then
		return
	end
	if(tag)then
		return tag;
	end
	
end
function DockTipPage:RemovePendingGsid(gsid)
	if(not gsid)then
		return
	end
	local k,v;
	for k,v in ipairs(self.pending_gsid_list) do
		if(v.gsid == gsid)then
			table.remove(self.pending_gsid_list,k);
		end
	end
end
function DockTipPage:CheckAllPendingGsids()
	local len = #self.pending_gsid_list;
	if(len > 0)then
		LOG.std("", "info","before DockTipPage:CheckAllPendingGsids one time");
	end
	while(len > 0)do
		local node = self.pending_gsid_list[len];
		if(node)then
			local check_times = node.check_times or 0;
			local gsid = node.gsid;
			local count = node.count;
			local tag = node.tag;
			--尝试3次
			if(check_times < 3)then
				LOG.std("", "info","DockTipPage:CheckAllPendingGsids",node);
				local bHas = KeepWorkItemManager.HasGSItem(gsid);
				LOG.std("", "info","bHas",bHas);

				self:PushGsid(gsid, count, tag);
				check_times = check_times + 1;
				node.check_times = check_times;
			else
				LOG.std("", "info","DockTipPage:CheckAllPendingGsids delete node",node);
				table.remove(self.pending_gsid_list,len);
			end	
		end
		len = len - 1;
	end
	if(len > 0)then
		LOG.std("", "info","after DockTipPage:CheckAllPendingGsids one time");
	end
end
function DockTipPage:GetPendingNode(gsid)
	if(not gsid)then
		return
	end
	local k,v;
	for k,v in ipairs(self.pending_gsid_list) do
		if(v.gsid == gsid)then
			return v;
		end
	end
end
function DockTipPage:PushToPendingList(gsid,tag)
	if(not gsid)then
		return
	end
	local node = self:GetPendingNode(gsid);
	if(node)then
		return
	else
		table.insert(self.pending_gsid_list,{
			gsid = gsid,
			tag = tag,
			check_times = 0,
		});
	end
end
function DockTipPage:PushGsid(gsid, count, tag)
	if(not self.is_init)then
		return
	end

	if(not gsid)then return end
    count = count or 1;
	LOG.std("", "info","DockTipPage:PushGsid",{gsid = gsid, count = count, });
	local node = { name = "bag", gsid = gsid, count = count, title = L"你获得了新物品！", animation_only = false};
	self:PushNode(node);
end



