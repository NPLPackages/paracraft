--[[
Title: NplBrowserPlugin
Author(s): pbb
Date: 2023.4.13
Desc: 
use the lib:
------------------------------------------------------------
local NplBrowserDialog = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserDialog.lua");
NplBrowserDialog.ShowPage();
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua")
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin")
local NplBrowserDialog = NPL.export()
local self = NplBrowserDialog
local page

NplBrowserDialog.install_url = "https://keepwork.com/official/open/download/webview2"

function NplBrowserDialog.OnInit()
    page = document:GetPageCtrl()
end

function NplBrowserDialog.ShowPage(callback)
    local width,height = 470,200;
	
    self.callbackFunc = callback
	local params = {
        url = "script/apps/Aries/Creator/Game/NplBrowser/NplBrowserDialog.html", 
        name = "NplBrowserDialog.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
		enable_esc_key = false,
        allowDrag = true,
		isTopLevel = true,
        directPosition = true,
        align = "_ct",
		x = -width * 0.5,
		y = -height * 0.5,
        width = width,
        height = height,
        zorder = 100001,
    }
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    local btnManual = ParaUI.GetUIObject("btn_manual")
    NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
		local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
    if btnManual:IsValid() and NplBrowserLoaderPage.isOnlyInstallCef3 then
        --only install cef3
        btnManual.visible = false
    end
end

function NplBrowserDialog.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
    if self.check_timer then
        self.check_timer:Change()
        self.check_timer = nil
    end
    if self.callbackFunc then
        self.callbackFunc()
    end
end

function NplBrowserDialog.OnClickButton(name)
    if name == "auto" then
		self.SetBtnVisible(false)
		self.ShowText(L"正在下载中 ...")

		NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
		local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
		NplBrowserLoaderPage.InstallNewCef3(function(bSucceed, errMsg)
			if(bSucceed) then
				self.ShowText(L"安装完毕")
                if not NplBrowserLoaderPage.isOnlyInstallCef3 then
				-- also try to install webview2 just once for win10 or above. 
				    NplBrowserPlugin.InstallWin32Webview2()
                end

				-- load with newly installed cef3 or webview
				NplBrowserDialog.OnInstallComplete()
			else
				self.ShowText((errMsg or "") .. " ".. L"安装报错了， 请尝试手工更新")
			end
		end, function(state, text, currentFileSize, totalFileSize)
			if(text) then
				if(state == 0) then
					self.ShowText(text)
				elseif(state == 2) then
					self.ShowText(text .. " ".. L"安装报错了， 请尝试手工更新")
				end
			end
		end)
    elseif name == "manual" then
        GameLogic.RunCommand("/open "..NplBrowserDialog.install_url)
        self.check_and_install = true
        self.StartChecking()
        self.SetBtnVisible(false)
        self.ShowText(L"正在下载中 ...")
    end
end

function NplBrowserDialog.OnInstallComplete()
	if(self.check_timer) then
		self.check_timer:Change()
	end
    if type(self.callbackFunc) == "function" then
        self.callbackFunc(true)
        self.callbackFunc = nil
    end
    self.ClosePage()
end

function NplBrowserDialog.StartChecking()
    if not self.check_and_install then
        NplBrowserPlugin.UpdateWebview2(nil,true)
        self.check_and_install = true
    end
    self.check_timer = self.check_timer or commonlib.Timer:new({callbackFunc = function()
        NplBrowserPlugin.UpdateWebview2(function(msg)
            local cmd = msg and msg["cmd"]
            local isOk = msg and msg["ok"]
            if cmd == "Support" and isOk == true then
                NplBrowserDialog.OnInstallComplete()
            end
        end,false)
    end});
    self.check_timer:Change(1000, 1000)
end

function NplBrowserDialog.ShowText(text)
	if page and text and text ~= "" then
        page:SetValue("show_text", text)
    end
end

function NplBrowserDialog.SetBtnVisible(bShow)
    local btnOperate = ParaUI.GetUIObject("show_button")
    if btnOperate and btnOperate:IsValid() then
        btnOperate.visible = bShow == true
    end
end