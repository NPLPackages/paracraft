--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DecoBuilder.lua");
local DecoBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DecoBuilder");
DecoBuilder.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateModelTask.lua");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local DecoBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DecoBuilder");

function DecoBuilder.OnInit()
end

function DecoBuilder.ShowPage(bShow)
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/DecoBuilder.html", 
			name = "DecoBuilder.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			allowDrag = true,
			bShow = bShow,
			directPosition = true,
				align = "_rb",
				x = -260,
				y = -500,
				width = 250,
				height = 400,
		});
end

function DecoBuilder.OnCreateObject(obj_params)
	local task = MyCompany.Aries.Game.Tasks.CreateModel:new({obj_params=obj_params})
	task:Run();
end
