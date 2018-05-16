--[[
Title: CodeBlockWindow
Author(s): LiXizhi
Date: 2018/5/16
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Window.lua")
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Window = commonlib.gettable("System.Windows.Window")

function CodeBlockWindow.RefreshPage()
    -- echo("Refresh")
	if(CodeBlockWindow.page) then
        -- echo("Refresh chenggong")
		CodeBlockWindow.page:Refresh(0.1)
	end
end

function CodeBlockWindow.ShowPage(entity)
	local window = Window:new()
	url = "script/apps/Aries/Creator/Game/Code/CodeBlockWindow.html"
	window:Show({
		url = url,
		alignment = "_fi",
		left = 0,
		top = 0,
		width = 0,
		height = 0
	})

	CodeBlockWindow.mEntity = entity
	CodeBlockWindow.page:SetValue("words2", CodeBlockWindow.mEntity.mCode)
end


function CodeBlockWindow.Close()
	CodeBlockWindow.mEntity = nil
	CodeBlockWindow.mPageKey = nil
	CodeBlockWindow.page:CloseWindow()
end

function CodeBlockWindow.Init()
	CodeBlockWindow.page = document:GetPageCtrl()
end

function CodeBlockWindow.execute(addr)
	CodeBlockWindow.OpenBlocklyInBrowser(addr)
	CodeBlockWindow.mProgrammingCommandQueue = ProgrammingCommandQueue:new()
end

function CodeBlockWindow.OpenBlocklyInBrowser(addr)
	_guihelper.MessageBox(
	"About to switch to your default browser, sure?",
	function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			CommandManager:RunCommand("/open " .. addr .. "blockly")
		end
	end,
	_guihelper.MessageBoxButtons.YesNo
	)
end

local count = 0
function CodeBlockWindow.CheckServerStarted(addr)
	commonlib.TimerManager.SetTimeout(
	function()
		local addr = WebServer:site_url()
		if(addr) then
			CodeBlockWindow.execute(addr)
		else
			count = count + 1
                -- try 5 times in 5 seconds
			if(count < 5) then
				CodeBlockWindow.CheckServerStarted(addr)
			end
		end
	end,
	1000
	)
end

function CodeBlockWindow.onClick_EditWithBlockly()
	NPL.load("(gl)script/apps/WebServer/WebServer.lua")

	local addr = WebServer:site_url()
	if(not addr) then
		CommandManager:RunCommand("/webserver")
		addr = WebServer:site_url()
		if(not addr) then
			count = 0
			CodeBlockWindow.CheckServerStarted(addr)
			return
		end
	else
		CodeBlockWindow.execute(addr)
	end
end

function CodeBlockWindow.setCode(code)
	CodeBlockWindow.mEntity:setCode(code)
end
