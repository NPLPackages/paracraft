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
task:ShowDialogPage(function(colorDWORD)   end);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local SelectColor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectColor"));

SelectColor:Signal("colorPicked", function(color) end)

local cur_instance;
local page
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
		self.lastSelectedColor = color;
		self:colorPicked(color);
	end
end

function SelectColor:OnExit()
	SelectColor._super.OnExit(self);
	self:Destroy();
	if(page) then
		page:CloseWindow();
		page = nil;
	end
	cur_instance = nil;
end

function SelectColor.GetInstance()
	return cur_instance;
end

function SelectColor:ShowPage()
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	local window = self:CreateGetToolWindow();
	if IsMobileUIEnabled then
		window:Show({
			name="SelectColor", 
			url="script/apps/Aries/Creator/Game/Tasks/SelectColor/SelectColor.html",
			alignment="_ctb", left=38, top= -110, width = 450, height = 96, parent = parent,
		});
		window:SetUIScaling(1.5,1.5)
	else
		window:Show({
			name="SelectColor", 
			url="script/apps/Aries/Creator/Game/Tasks/SelectColor/SelectColor.html",
			alignment="_ctb", left=0, top= -55, width = 300, height = 64, parent = parent,
		});
	end
	window:EnableSelfPaint(true);
end

function SelectColor:ShowDialogPage(callback)
	self.finished = false;
	cur_instance = self;
	
	local width, height = 512, 256;
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SelectColor/SelectColor.dialog.html",
        name = "EasyModel.Colors.ShowPage", 
        isShowTitleBar = false,
		isTopLevel = true,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        enable_esc_key = true,
        allowDrag = false,
        click_through = false, 
        bShow = true,
        SelfPaint = true,
        directPosition = true,
            align = "_ct",
            x = width * -0.5,
            y = height * -0.5,
            width = width,
            height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
	if(params._page) then
		page = params._page;
		params._page.OnClose = function()
			page = nil;
			if(callback) then
				callback(self.lastSelectedColor);
			end
		end
	end
end


function SelectColor.OnClickColorAndClose(index)
	SelectColor.OnClickColor(index);
	SelectColor.OnClose();
end

function SelectColor.OnClose()
	if(cur_instance) then
		cur_instance:OnExit();
	end
end
