--[[
Title: an unknown item
Author(s): LiXizhi
Date: 2009/2/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/Item_App.lua");
local dummyItem = Map3DSystem.Item.Item_App:new({appkey=Map3DSystem.App.appkeys["Creator"]});
Map3DSystem.Item.ItemManager:AddItem(dummyItem);
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemData/ItemBase.lua");

local Item_App = commonlib.inherit(Map3DSystem.Item.ItemBase, {type=Map3DSystem.Item.Types.App});
commonlib.setfield("Map3DSystem.Item.Item_App", Item_App)

---------------------------------
-- functions
---------------------------------

-- Get the Icon of this object
-- @param callbackFunc: function (filename) end. if nil, it will return the icon texture path. otherwise it will use the callback,since the icon may not be immediately available at call time.  
function Item_App:GetIcon(callbackFunc)
	if(self.icon) then
		return self.icon;
	elseif(self.appkey or self.app) then
		
		self.app = self.app or Map3DSystem.App.AppManager.GetApp(self.appkey);
		if(self.app) then
			self.icon = self.app.icon or self.app.Icon;
			return self.icon;
		end	
	else
		return Map3DSystem.Item.ItemBase:GetIcon(callbackFunc);
	end
end

-- When this item is clicked
function Item_App:OnClick(mouseButton)
	Map3DSystem.App.Commands.Call(Map3DSystem.options.SwitchAppCommand, self.appkey);
end

-- Get the tooltip of this object
-- @param callbackFunc: function (text) end. if nil, it will return the text. otherwise it will use the callback,since the icon may not be immediately available at call time.  
function Item_App:GetTooltip(callbackFunc)
	if(self.tooltip) then
		return self.tooltip;
	elseif(self.appkey or self.app) then
		self.app = self.app or Map3DSystem.App.AppManager.GetApp(self.appkey);
		if(self.app) then
			self.tooltip = self.app.Title;
			return self.tooltip;
		end	
	else
		return Map3DSystem.Item.ItemBase:GetTooltip(callbackFunc);
	end
end

function Item_App:GetSubTitle()
	if(self.subtitle) then
		return self.subtitle;
	elseif(self.appkey or self.app) then
		
		self.app = self.app or Map3DSystem.App.AppManager.GetApp(self.appkey);
		if(self.app) then
			self.subtitle = self.app.SubTitle;
			return self.subtitle;
		end	
	else
		return Map3DSystem.Item.ItemBase:GetSubTitle(callbackFunc);
	end
end