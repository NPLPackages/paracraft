--[[
Title: Mobile Log Page
Author(s): ygy
Date: 2023 02 02
Desc: 
Use Lib:
-------------------------------------------------------
local MobileCodeLogPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/CodeBlockWindow/MobileCodeLogPage.lua");
MobileCodeLogPage.Show();
MobileCodeLogPage.CloseWindow()
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local MobileCodeLogPage = NPL.export();
MobileCodeLogPage.LogContent = {}
MobileCodeLogPage.LogDiv = ""
-- page only for surface window. Not the realtime window
local page;

function MobileCodeLogPage.OnInit()
	page = document:GetPageCtrl();
	-- page.OnLoad = MobileCodeLogPage.OnLoad
	page.OnCreate = MobileCodeLogPage.OnCreate
	page.OnClose = MobileCodeLogPage.OnClose
end

function MobileCodeLogPage.Show()
	if page and page:IsVisible() then
		return
	end

	MobileCodeLogPage.LogContent = {}
	MobileCodeLogPage.LogDiv = ""
	MobileCodeLogPage.LogContent[1] = CodeBlockWindow.GetConsoleText()
	MobileCodeLogPage.UpdateLogDiv()

	local params = {
		-- url = path,
		url = "script/apps/Aries/Creator/Game/Mobile/CodeBlockWindow/MobileCodeLogPage.html",
		name = "MobileCodeLogPage.Show", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		enable_esc_key = true,
		cancelShowAnimation = true,
		click_through = true,
		zorder=1,
		--app_key = 0, 
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
	};

	System.App.Commands.Call("File.MCMLWindowFrame", params);

	page = params._page

	GameLogic.GetCodeGlobal():Connect("logAdded", MobileCodeLogPage, MobileCodeLogPage.AddConsoleText, "UniqueConnection");
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	viewport:Connect("sizeChanged", MobileCodeLogPage, function()
		commonlib.TimerManager.SetTimeout(function()		
			MobileCodeLogPage.UpdatePageNodePos()
		end, 10);
		
	end, "UniqueConnection");

	GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow", MobileCodeLogPage.CodeWinChangeVisible, MobileCodeLogPage, "MobileCodeLogPage");

	MobileCodeLogPage.UpdatePageNodePos()
end

function MobileCodeLogPage.OnCreate()
	local page_node = page:FindUIControl("pageNode")
	if page_node then
		if page_node.height > 380 then
			page_node.height = 380
			local log_node = page:FindUIControl("logContentNode")
			if log_node then
				log_node.y = -(log_node.height - page_node.height)-5
			end
		end
	end

	MobileCodeLogPage.UpdatePageNodePos()
end

function MobileCodeLogPage.CloseWindow()
	if page then
		page:CloseWindow()
	end
end

function MobileCodeLogPage.OnClose()
	GameLogic.GetCodeGlobal():Disconnect("logAdded", MobileCodeLogPage, MobileCodeLogPage.AddConsoleText);
	GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow", MobileCodeLogPage.CodeWinChangeVisible, MobileCodeLogPage);

	MobileCodeLogPage.LogContent = {}
	MobileCodeLogPage.LogDiv = ""
	page=nil
end

function MobileCodeLogPage.RefreshPage()
	if(page) then
		page:Refresh(0);
	end
end

function MobileCodeLogPage.UpdateLogDiv()
	-- body
end

function MobileCodeLogPage.UpdatePageNodePos()
	if not page then
		return
	end

	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	-- local bShow = event.bShow
	local viewport = ViewportManager:GetSceneViewport();	
	local view_x,view_y,view_width,view_height = viewport:GetUIRect()

	local page_node = page:FindUIControl("pageNode")
	if page_node then
		page_node.x = view_width/2 - page_node.width/2
	end
	
end

function MobileCodeLogPage.SetConsoleText(text)
	if(page) then
		
		MobileCodeLogPage.LogContent = {}
		MobileCodeLogPage.LogContent[1] = CodeBlockWindow.GetConsoleText()
		MobileCodeLogPage.UpdateLogDiv()
		MobileCodeLogPage.RefreshPage()

		-- page:SetValue("console", CodeBlockWindow.GetConsoleText());
	end
end

function MobileCodeLogPage.AddConsoleText(instance, text)
	if not text then
		return
	end
-- echo(text, true)
	if(page) then
		MobileCodeLogPage.LogContent[#MobileCodeLogPage.LogContent + 1] = text
		MobileCodeLogPage.UpdateLogDiv()
		MobileCodeLogPage.RefreshPage()
	end
end

function MobileCodeLogPage.CodeWinChangeVisible(event)
	if event and not event.bShow then
		MobileCodeLogPage.CloseWindow()
	end
end

function MobileCodeLogPage.UpdateLogDiv()
	MobileCodeLogPage.LogDiv = ""
	if #MobileCodeLogPage.LogContent == 0 then
		return
	end
	for index = 1, #MobileCodeLogPage.LogContent do
		local text = MobileCodeLogPage.LogContent[index]
		local div_text = string.format([[<div style="min-width: 20px;max-width: 280px; min-height: 18px;">%s</div>]], text)
		MobileCodeLogPage.LogDiv = MobileCodeLogPage.LogDiv .. div_text
	end
end

function MobileCodeLogPage.GetLogDiv()
	return MobileCodeLogPage.LogDiv
end