--[[
Title: TatfookUserTakeVipPage
Author(s): 
Date: 2020/9/27
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TatfookUserTakeVipPage.lua").ShowPage();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

local TatfookUserTakeVipPage = NPL.export()
local page

function TatfookUserTakeVipPage.OnInit()
    page = document:GetPageCtrl();
end

function TatfookUserTakeVipPage.ShowPage()
    if(KeepworkServiceSession:IsSignedIn())then
        if(KeepWorkItemManager.IsVip())then
            _guihelper.MessageBox(L"你已经是会员，不需要再领取会员了。");
            return
        end
        TatfookUserTakeVipPage._ShowPage();   
        return
    end
    LoginModal:CheckSignedIn(L"请先登录", function(result)
        if(KeepWorkItemManager.IsVip())then
            _guihelper.MessageBox(L"你已经是会员，不需要再领取会员了。");
            return
        end
        if (result == true)then
            TatfookUserTakeVipPage._ShowPage();   
        end
    end)
end
function TatfookUserTakeVipPage._ShowPage()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/User/TatfookUserTakeVipPage.html",
			name = "TatfookUserTakeVipPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -955/2,
				y = -580/2,
				width = 955,
				height = 580,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
function TatfookUserTakeVipPage.GetPageCtrl()
    return page;
end