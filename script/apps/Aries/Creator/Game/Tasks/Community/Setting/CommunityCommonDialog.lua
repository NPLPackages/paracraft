--[[
    --@author  pbb
    --@date    2024/07/08
    --@desc    CommunityCommonDialog
    --uselib:
        local CommunityCommonDialog = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Setting/CommunityCommonDialog.lua")
        CommunityCommonDialog.Show(description, callback,{confirm_text=L"点击开通",cancel_text=L"取消"})
]]

local CommunityCommonDialog = NPL.export()

local self = CommunityCommonDialog
local page
CommunityCommonDialog.dialog_description = nil
CommunityCommonDialog.dialog_callback = nil
CommunityCommonDialog.options = nil
function CommunityCommonDialog.OnInit()
    page = document:GetPageCtrl()
end

function CommunityCommonDialog.Show(description, callback,options)
    if page or (page and page:IsVisible()) then
        page:CloseWindow()
        page = nil
    end
    self.dialog_description = description
    self.dialog_callback = callback
    self.options = options
    self.dialog_cancel_callback = options and options.cancel_callback or nil
    local view_width = 0
	local view_height = 0
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Community/Setting/CommunityCommonDialog.html",
			name = "CommunityCommonDialog.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			zorder = 11,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isTopLevel = true,
            cancelShowAnimation = true,
			directPosition = true,
				align = "_fi",
				x = -view_width/2,
				y = -view_height/2,
				width = view_width,
				height = view_height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CommunityCommonDialog.OnClose()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function CommunityCommonDialog.OnConfirmClick()
    CommunityCommonDialog.OnClose()
    if self.dialog_callback then
        self.dialog_callback()
    end
end

function CommunityCommonDialog.OnCloseClick()
    CommunityCommonDialog.OnClose()
    if self.dialog_cancel_callback and type(self.dialog_cancel_callback) == "function" then
        self.dialog_cancel_callback()
    end
end