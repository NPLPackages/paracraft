--[[
Title: SelectColor Task/Command
Author(s): LiXizhi
Date: 2016/8/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectColor/SelectColor.lua");
local SelectColor = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectColor");
local task = SelectColor:new();
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local SelectColor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectColor"));

SelectColor:Signal("colorPicked", function(color) end)

local cur_instance;
function SelectColor:ctor()
end

function SelectColor:Run()
	self.finished = false;
	cur_instance = self;
	self:ShowPage();
end

-- the following is default 20 colors in Windows's painter app.
-- this make sure 8 bits are 16 bits colors are identical.
local colors = {
	-- row1
	{color="#000000"},
	{color="#555555"},
	{color="#aa0000"},
	{color="#ff0000"},
	{color="#ff5500"},
	{color="#ffff00"},
	{color="#00aa55"},
	{color="#00aaff"},
	{color="#0055ff"},
	{color="#aa55aa"},
	-- row2
	{color="#ffffff"},
	{color="#aaaaaa"},
	{color="#aa5555"},
	{color="#ffaaff"},
	{color="#ffaa00"},
	{color="#ffffaa"},
	{color="#aaff00"},
	{color="#aaffff"},
	{color="#55aaaa"},
	{color="#ffaaaa"},
}

function SelectColor.FormalizeColors(colors)
	for _, col in ipairs(colors) do
		col.color = Color.FromValueToStr(Color.convert8_32(Color.convert32_8(Color.ToValue(col.color))))
	end
end
-- SelectColor.FormalizeColors(colors)

function SelectColor.GetColorList()
	return colors
end

function SelectColor.OnClickColor(index)
	self = cur_instance;
	local item = SelectColor.GetColorList()[index];
	if(item and self) then
		local color = Color.ColorStr_TO_DWORD(item.color);
		self:colorPicked(color);
	end
end

function SelectColor:OnExit()
	SelectColor._super.OnExit(self);
	self:Destroy();
	cur_instance = nil;
end


function SelectColor:ShowPage()
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)

	local window = self:CreateGetToolWindow();
	window:Show({
		name="SelectColor", 
		url="script/apps/Aries/Creator/Game/Tasks/SelectColor/SelectColor.html",
		alignment="_ctb", left=0, top=-55, width = 300, height = 64, parent = parent,
	});
end
