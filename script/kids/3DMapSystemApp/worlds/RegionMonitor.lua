--[[
Title: RegionMonitor
Author(s): Leio
Date: 2009/9/26
Desc: 
 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionMonitor.lua");
local regionMonitor = Map3DSystem.App.worlds.RegionMonitor:new();
--regionMonitor:AddEventListener("moveable",function(args)
	--commonlib.echo(args);
--end);
--regionMonitor:AddEventListener("sound",function(args)
	--commonlib.echo(args);
--end);
regionMonitor:AddEventListener("custom",function(args)
	commonlib.echo(args);
end);

------------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
local RegionMonitor = commonlib.gettable("Map3DSystem.App.worlds.RegionMonitor");
RegionMonitor.duration = 500;

function RegionMonitor:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self;
	o:Init();
	return o
end
function RegionMonitor:Pause()
	if(self.timer)then
		self.timer:Change();
	end
end
function RegionMonitor:Resume()
	if(self.timer)then
		self.timer:Change(0,self.duration);
	end
end
function RegionMonitor:Init()
	self.events = {};
	self.timer = commonlib.Timer:new{callbackFunc = Map3DSystem.App.worlds.RegionMonitor.Timer_CallBackFunc,};
	self.timer.monitor = self;
	
	 self:Resume();
end
function RegionMonitor.Timer_CallBackFunc(t)
	if(t and t.monitor)then
		local self = t.monitor;
		local x, _, y = ParaScene.GetPlayer():GetPosition();
		self:Update(x,y);
	end
end
function RegionMonitor:AddEventListener(event_type,func)
	self.events[event_type] = {func = func,};
end
function RegionMonitor:DispatchEvent(event_type,args)
	local func_table = self.events[event_type];
	if(func_table)then
		local func = func_table.func;
		if(func and type(func) == "function")then
			func(args);
		end
	end
end

function RegionMonitor:Update(x,y)
	local event_type,func_table;
	for event_type,func_table in pairs(self.events) do
		local filter = func_table.filter or self.COLOR_DEFAULT;
		--自定义标签
		local argb = ParaTerrain.GetRegionValue(event_type, x, y);
		local r,g,b,a = _guihelper.DWORD_TO_RGBA(argb);
		local att = ParaTerrain.GetAttributeObjectAt(x,y);
		local NumOfRegions;
		local CurrentRegionName;
		local CurrentRegionFilepath;
		if(att)then
			att:SetField("CurrentRegionName", event_type  or "move");
			NumOfRegions = att:GetField("NumOfRegions", 0);
			CurrentRegionName = att:GetField("CurrentRegionName", "");
			CurrentRegionFilepath = att:GetField("CurrentRegionFilepath", "");
		end
		local args = {event_type = event_type,
						argb = argb,
						r = r,
						g = g,
						b = b,
						a = a,
						NumOfRegions = NumOfRegions,
						CurrentRegionName = CurrentRegionName,
						CurrentRegionFilepath = CurrentRegionFilepath,
					};
		self:DispatchEvent(event_type,args)
	end

end
