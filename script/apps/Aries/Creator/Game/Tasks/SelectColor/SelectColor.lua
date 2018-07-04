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
local colors = {
	-- row1
	{color="#000000"},
	{color="#7f7f7f"},
	{color="#880015"},
	{color="#ed1c24"},
	{color="#ff7f27"},
	{color="#fff200"},
	{color="#22b14c"},
	{color="#00a2e8"},
	{color="#3f48cc"},
	{color="#a349a4"},
	-- row2
	{color="#ffffff"},
	{color="#c3c3c3"},
	{color="#b97a57"},
	{color="#ffaec9"},
	{color="#ffc90e"},
	{color="#efe4b0"},
	{color="#b5e61d"},
	{color="#99d9ea"},
	{color="#7092be"},
	{color="#c8bfe7"},
}

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
	local window = self:CreateGetToolWindow();
	window:Show({
		name="SelectColor", 
		url="script/apps/Aries/Creator/Game/Tasks/SelectColor/SelectColor.html",
		alignment="_ctb", left=0, top=-55, width = 300, height = 64,
	});
end
