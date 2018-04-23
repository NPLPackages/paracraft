--[[
Title: RegionMonitorPage
Author(s): Leio
Date: 2009/9/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionMonitorPage.lua");
Map3DSystem.App.worlds.RegionMonitorPage.Show();
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionMonitor.lua");
local RegionMonitorPage = {
	page = nil,
	regionMonitor = nil,
	isShow = false;
	
	
} 
commonlib.setfield("Map3DSystem.App.worlds.RegionMonitorPage",RegionMonitorPage);
function RegionMonitorPage.Init()
	local self = RegionMonitorPage;
	self.page = document:GetPageCtrl();
end
function RegionMonitorPage.Show()
	local self = RegionMonitorPage;
	if(not self.isShow)then
		self.ShowPage();
	else
		self.ClosePage();
	end
end
function RegionMonitorPage.ShowPage()
	local self = RegionMonitorPage;
	self.isShow = true;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/kids/3DMapSystemApp/worlds/RegionMonitorPage.html", 
			name = "RegionMonitorPage.ShowPage", 
			--app_key=MyCompany.Aries.app.app_key, 
			app_key=MyCompany.Taurus.app.app_key, 
			isShowTitleBar = true,
			DestroyOnClose = false, -- prevent many ViewProfile pages staying in memory
			--style = CommonCtrl.WindowFrame.ContainerStyle,
			text = "",
			zorder = 1,
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 0,
				width = 600,
				height = 300,
		});
	if(not self.regionMonitor)then
		self.regionMonitor = Map3DSystem.App.worlds.RegionMonitor:new{
			
		};
		self.regionMonitor:AddEventListener("move",RegionMonitorPage.Update_Custom);
		self.regionMonitor:AddEventListener("sound",RegionMonitorPage.Update_Custom);
		self.regionMonitor:AddEventListener("test",RegionMonitorPage.Update_Custom);
	else
		self.regionMonitor:Resume();
	end
end
function RegionMonitorPage.Update_Custom(args)
	local self = RegionMonitorPage;
	if(self.page and args)then
		local type = args.event_type;
		local s = string.format("event_type = %s,argb = %s,r = %s,g = %s,b = %s,a = %s,CurrentRegionFilepath = %s,CurrentRegionName = %s,NumOfRegions = %s",
		args.event_type or "",
		tostring(args.argb) or "",
		tostring(args.r) or "",
		tostring(args.g) or "",
		tostring(args.b) or "",
		tostring(args.a) or "",
		tostring(args.CurrentRegionFilepath) or "",
		tostring(args.CurrentRegionName) or "",
		tostring(args.NumOfRegions) or "");
		if(type == "move")then
			self.page:SetValue("move_ctl",s);
		elseif(type == "sound")then
			self.page:SetValue("sound_ctl",s);
		elseif(type == "test")then
			self.page:SetValue("custom_ctl",s);
		end
	end
end
function RegionMonitorPage.ClosePage()
	local self = RegionMonitorPage;
	self.isShow = false;
	Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name="RegionMonitorPage.ShowPage", 
		app_key=MyCompany.Taurus.app.app_key, 
		bShow = false,bDestroy = false,});
	if(self.regionMonitor)then
		self.regionMonitor:Pause();
	end
end