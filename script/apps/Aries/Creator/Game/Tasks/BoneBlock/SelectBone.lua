--[[
Title: SelectBone Task/Command
Author(s): LiXizhi
Date: 2016/8/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BoneBlock/SelectBone.lua");
local SelectBone = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBone");
local task = SelectBone:new();
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local SelectBone = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBone"));

SelectBone:Signal("levelColorSelected", function(level) end)

local cur_instance;
local page

-- the following is default 20 colors in Windows's painter app.
-- this make sure 8 bits are 16 bits colors are identical.
local levelcolors = {
	{color="#ffffff", text=L"普通骨骼"},
	{color="#ffff00", text=L"1级骨骼"},
	{color="#ff0000", text=L"2级骨骼"},
	{color="#00ffff", text=L"3级骨骼"},
	{color="#00ff00", text=L"4级骨骼"},
	{color="#0000ff", text=L"5级骨骼"},
	-- {color="#000000"},
}

function SelectBone:ctor()
end


function SelectBone.OnInit()
	page = document:GetPageCtrl();
end

function SelectBone:Run()
	self.finished = false;
	cur_instance = self;
	self:ShowPage();
end

function SelectBone.GetLevelColorList()
	return levelcolors
end

function SelectBone.OnClickLevelColor(index)
	self = cur_instance;
	local item = SelectBone.GetLevelColorList()[index];
	if(item and self) then
		local color = Color.ColorStr_TO_DWORD(item.color);
		self:SetLevelColor(color)
		self:levelColorSelected(color);
		if(page) then
			page:Refresh(0.01)
		end
	end
end

function SelectBone:OnExit()
	SelectBone._super.OnExit(self);
	self:Destroy();
	cur_instance = nil;
end

function SelectBone.GetInstance()
	return cur_instance
end

function SelectBone:SetLevelColor(color)
	SelectBone.levelcolor = Color.FromValueToStr(color);
end

function SelectBone:GetLevelColor()
	return SelectBone.levelcolor;
end

function SelectBone:ShowPage()
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	local window = self:CreateGetToolWindow();
	if IsMobileUIEnabled then
		window:Show({
			name="SelectBone", 
			url="script/apps/Aries/Creator/Game/Tasks/BoneBlock/SelectBone.html",
			alignment="_ctb", left=38, top= -110, width = 450, height = 84, parent = parent,
		});
		window:SetUIScaling(1.5,1.5)
		return
	end
	window:Show({
		name="SelectBone", 
		url="script/apps/Aries/Creator/Game/Tasks/BoneBlock/SelectBone.html",
		alignment="_ctb", left=0, top= -55, width = 300, height = 56, parent = parent,
	});
end
