--[[
Title: Code UI
Author(s): LiXizhi
Date: 2018/6/17
Desc: all code blocks share the same code UI. This is also a paracraft mod.
Code UI contains an array list of Code UI Items, which are layed out in the given order unless explicitly specified. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeUI.lua");
local CodeUI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUI");
CodeUI:ShowGlobalData("test", "testTile")
CodeUI:ShowGlobalData("test1")
CodeUI:Show()
GameLogic.GetCodeGlobal():SetGlobal("test", "hello")
GameLogic.GetCodeGlobal():SetGlobal("test1", "world")
CodeUI:Clear()
CodeUI:ShowOverlayPickingBuffer()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeUIItem.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeGlobals.lua");
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModBase.lua");
NPL.load("(gl)script/ide/System/Scene/Overlays/OverlayPicking.lua");
local OverlayPicking = commonlib.gettable("System.Scene.Overlays.OverlayPicking");
local Window = commonlib.gettable("System.Windows.Window")
local CodeGlobals = commonlib.gettable("MyCompany.Aries.Game.Code.CodeGlobals");
local CodeUIItem = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUIItem");

local CodeUI = commonlib.inherit(commonlib.gettable("Mod.ModBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeUI"));

CodeUI:Property({"pickingPointSize", 8});

function CodeUI:ctor()
	-- mapping from name to CodeUIItem
	self.items = {};
	self.itemList = commonlib.OrderedArraySet:new();
	self.entityOverlays = {};
end

function CodeUI:GetName()
	return "CodeUI"
end

function CodeUI:GetDesc()
	return "CodeUI is a plugin in paracraft"
end

function CodeUI:init()
	LOG.std(nil, "info", "CodeUI", "plugin initialized");
end

-- static function
function CodeUI.InstallMod()
	local ModManager = commonlib.gettable("Mod.ModManager");
	if(not ModManager:IsModLoaded(CodeUI)) then
		ModManager:AddMod("CodeBlockUI", CodeUI)
	end
end

function CodeUI:Clear()
	self.items = {};
	self.itemList:clear();
	self.entityOverlays = {};
	if(self.window) then
		self.window:Destroy();
	end
end

function CodeUI:GetItem(name)
	return self.items[name];
end

function CodeUI:RemoveItem(name)
	local lastItem = self:GetItem(name);
	if(lastItem) then
		self.items[name] = nil;
		self.itemList:removeByValue(lastItem);
		self:RefreshLayout();
	end
end

function CodeUI:AddItem(item)
	local lastItem = self:GetItem(item.name);
	if(lastItem) then
		if(lastItem~=item) then
			self:RemoveItem(item.name);
		else
			return;
		end
	end
	self.items[item.name] = item;
	self.itemList:add(item);
	self:RefreshLayout();
end

function CodeUI:GetItemNameForGlobalData(name)
	return "g_"..name;
end

function CodeUI:ShowGlobalData(name, title, color, fontSize)
	local itemName = self:GetItemNameForGlobalData(name)
	local item = self:GetItem(itemName)
	if(not item) then
		item = CodeUIItem:new():Init(itemName, self);
		item:SetGlobalVariableName(name);
		self:AddItem(item);
	end
	if(item) then
		item:SetTitle(title or name);
		if(color) then
			item:SetColor(color);
		end
		if(fontSize) then
			item:SetFontSize(tonumber(fontSize));
		end
	end
	return item;
end

function CodeUI:HideGlobalData(name)
	self:RemoveItem(self:GetItemNameForGlobalData(name));
end

function CodeUI:GetWindow()
	local window = self.window;
	if(not window) then
		window = Window:new();
		self.window = window;
	end
	return window;
end

function CodeUI:Show()
	local window = self:GetWindow();
	if(not window:isVisible()) then
		window:Show("__codeUI__", nil, "_fi", 0, 0, 0, 0);
		window:SetEnabled(false);
	end
end

function CodeUI:RefreshLayoutImp()
	local window = self:GetWindow();
	window:deleteChildren();

	local x, y, width, height = 10, 140, 400, 24;
	for i, item in ipairs(self.itemList) do
		item:SetParent(window);
		item:setGeometry(x, y, width, height);
		y = y + height;
	end

	if(#self.itemList > 0) then
		local window = self:GetWindow();
		window:Show();
	end
end

function CodeUI:RefreshLayout()
	self.refrehTimer = self.refrehTimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:RefreshLayoutImp();
	end})
	self.refrehTimer:Change(100, nil);
end

-- @param event: see MouseEvent 
function CodeUI:handleMouseEvent(event)
	if(event:isAccepted()) then
		return
	end

	local pickingName;
	for entity, _ in pairs(self.entityOverlays) do
		if(not pickingName) then
			pickingName = 0;
			-- TODO: only set dirty when overlay has changed since last pick call. 
			OverlayPicking:SetResultDirty(true);
			OverlayPicking:Pick(nil, nil, self.pickingPointSize, self.pickingPointSize)
			pickingName = OverlayPicking:GetActivePickingName() or 0;
			if(pickingName == 0) then
				return
			end
		end
		if(entity:IsVisible() and entity:HasPickingName(pickingName)) then
			entity:event(event);
			if(event:isAccepted()) then
				return true;
			end
			break;
		end
	end
end

function CodeUI:AddEntityOverlay(entity)
	self.entityOverlays[entity] = true;
end

function CodeUI:RemoveEntityOverlay(entity)
	self.entityOverlays[entity] = nil;
end


function CodeUI:ShowOverlayPickingBuffer()
	OverlayPicking:DebugShow("_lt", 10, 10, 128, 128);
end

CodeUI:InitSingleton();