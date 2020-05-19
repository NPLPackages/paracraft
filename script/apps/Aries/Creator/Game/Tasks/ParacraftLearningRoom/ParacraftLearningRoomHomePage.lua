--[[
Title: ParacraftLearningRoomHomePage
Author(s): leio
Date: 2020/5/15
Desc:  
the home page for learning paracraft
Use Lib:
-------------------------------------------------------
local ParacraftLearningRoomHomePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomHomePage.lua");
ParacraftLearningRoomHomePage.ShowPage();
--]]
local ParacraftLearningRoomHomePage = NPL.export()

local page;

ParacraftLearningRoomHomePage.Current_Item_DS = {
    { title  = L"第一期", desc  = L"基础操作", exid = 18, gsid = 10001, } ,
    { title  = L"第二期", desc  = L"中级操作", exid = 18, gsid = 10001, } ,
    { title  = L"第三期", desc  = L"高级操作", exid = 18, gsid = 10001, } ,
    { title  = L"第四期", desc  = L"初级编程", exid = 18, gsid = 10001, } ,
    { title  = L"第五期", desc  = L"中级编程", exid = 18, gsid = 10001, } ,
    { title  = L"第六期", desc  = L"高级编程", exid = 18, gsid = 10001, } ,
}
function ParacraftLearningRoomHomePage.OnInit()
	page = document:GetPageCtrl();
end

function ParacraftLearningRoomHomePage.ShowPage()
    local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomHomePage.html",
			name = "ParacraftLearningRoomHomePage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -800/2,
				y = -500/2,
				width = 800,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end