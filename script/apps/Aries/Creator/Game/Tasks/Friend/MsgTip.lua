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
local msgDockCfg = {name="msg_tip", align="_rt",  width = 100,height = 90,bg="Texture/Aries/Creator/keepwork/dock/xiaoxi_98x93_32bits.png#0 0 100 90"}
local FriendManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendManager.lua");
local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
local MsgTip = NPL.export();
MsgTip.IsOpenPage = false
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
    MsgTip.IsOpenPage = false
end

function MsgTip.Show(un_read_num)
    -- if MsgTip.IsOpenPage then
    --     MsgTip.UpdateNum(un_read_num)
    --     return
    -- end

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
    MsgTip.IsOpenPage = true
    MsgTip.un_read_num = un_read_num or 0
    if MsgTip.un_read_num > 0 then
        MsgTip.AddMsgDock()
    end
end

function MsgTip.AddMsgDock()
    local dock = GameLogic.DockManager:AddNewDock(msgDockCfg)
    dock:Connect("onclickEvent",function()
        local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        FriendsPage.Show()
    end)
    GameLogic.DockManager:RePosition()

    if MsgTip.un_read_num > 0 then
        local redParams = {
            width = 12,
            height = 12,
            x_offset = 70,
            y_offset = 6,
        }
        dock:AddRedTip(redParams)
    else
        dock:RemoveRedTip()
    end
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
    return MsgTip.IsOpenPage
end

function MsgTip.ClosePage()
    MsgTip.IsOpenPage = false
    GameLogic.DockManager:RemoveDock("msg_tip")
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

