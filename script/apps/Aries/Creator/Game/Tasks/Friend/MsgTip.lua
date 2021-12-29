--[[
Title: MsgTip
Author(s): yangguiyi
Date: 2020/9/2
Desc:  
Use Lib:
-------------------------------------------------------
local MsgTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/MsgTip.lua");
MsgTip.Show();
--]]
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
local MsgTip = NPL.export();
local page;
local DateTool = os.date
MsgTip.Current_Item_DS = {};

function MsgTip.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = MsgTip.CloseView
end

function MsgTip.CloseView()
    page = nil
    MsgTip.un_read_num = 0
end

function MsgTip.Show(un_read_num)
    if MsgTip.IsOpen() then
        MsgTip.UpdateNum(un_read_num)
        return
    end

    if not MsgTip.HasBind then
        MsgTip.HasBind = true

        GameLogic.GetFilters():add_filter("update_friend_unread_num", function()
            local nums = FriendsPage.GetAllUnReadMsgNum()
            if nums > 0 then
                MsgTip.Show(nums)
            else
                MsgTip.UpdateNum(nums)
            end
        end);
    end

    MsgTip.un_read_num = un_read_num or 0
    UserData = user_data

    local att = ParaEngine.GetAttributeObject();
    local oldsize = att:GetField("ScreenResolution", {1280,720});

	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Friend/MsgTip.html",
			name = "MsgTip.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = false,
            click_through = true,
			cancelShowAnimation = true,
			-- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			DesignResolutionWidth = 1280,
			DesignResolutionHeight = 720,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
end

function MsgTip.UpdateNum(num)
    MsgTip.un_read_num = num
    if num == 0 then
        MsgTip.ClosePage()
    else
        if page then
            page:Refresh(0)
        end
    end
end

function MsgTip.GetUnReadNum()
    return MsgTip.un_read_num
end

function MsgTip.IsOpen()
    return page and page:IsVisible()
end

function MsgTip.ClosePage()
    if page then
        page:CloseWindow(true)
    end
end

function MsgTip.Check()
    if not GameLogic.GameMode:IsEditor() then
        MsgTip.ClosePage()
        return
    end

	FriendManager:LoadAllUnReadMsgs(function ()
		-- 处理未读消息
        local all_nums = 0
		if FriendManager.unread_msgs and FriendManager.unread_msgs.data then
			for k, v in pairs(FriendManager.unread_msgs.data) do
				if v.unReadCnt and v.unReadCnt > 0 then
                    all_nums = all_nums + v.unReadCnt
				end
			end
		end

        if all_nums > 0 then
            MsgTip.Show(all_nums)
        else
            MsgTip.ClosePage()
        end

        commonlib.TimerManager.SetTimeout(function()
            MsgTip.Check()
        end, 60000);
	end, true);    
end

