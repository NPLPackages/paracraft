--[[
Title: ActLuckyDrawPage
Author(s): yangguiyi
Date: 2020/9/22
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActLuckyDraw/ActLuckyDrawPage.lua").Show();
--]]

local ActLuckyDrawPage = NPL.export();
NPL.load("(gl)script/ide/Transitions/Tween.lua");
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local page;
ActLuckyDrawPage.Current_Item_DS = {};
ActLuckyDrawPage.draw_bt_enable = true
ActLuckyDrawPage.id = 0
ActLuckyDrawPage.ActInfo = {}
ActLuckyDrawPage.RewardData = {}

ActLuckyDrawPage.ActState = {
    not_start = 1,
    ongoing = 2,
    has_ended = 3,
}
function ActLuckyDrawPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ActLuckyDrawPage.CloseView
end

function ActLuckyDrawPage.Show()

    local function openView()
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/ActLuckyDraw/ActLuckyDrawPage.html",
            name = "ActLuckyDrawPage.Show", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = true,
            enable_esc_key = true,
            zorder = -1,
            app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
            directPosition = true,
            
            align = "_ct",
            x = -730/2,
            y = -401/2,
            width = 730,
            height = 401,
        };
        
        System.App.Commands.Call("File.MCMLWindowFrame", params);

        ActLuckyDrawPage.UpdataDrawBt()
    end

    keepwork.tatfook.lucky_info({
    },function(info_err, info_msg, info_data)
        -- print("rrrrrrrrrrrrrrrrrrrrrrrr", info_err, info_msg)
        -- commonlib.echo(info_data, true)
        if info_err == 200 then
            -- info_data = {
            --     code="nationalDay",
            --     createdAt="2020-09-23T00:00:00.000Z",
            --     endTime="2020-11-01T00:00:00.000Z",
            --     id=1,
            --     name="中秋国庆抽奖活动",
            --     periodCount=5,
            --     startTime="2020-09-23T00:00:00.000Z",
            --     type=1,
            --     updatedAt="2020-09-23T00:00:00.000Z" 
            --   }
            ActLuckyDrawPage.ActInfo = info_data
            ActLuckyDrawPage.ActInfo.act_start_time_stamp = ActLuckyDrawPage.GetTimeStamp(info_data.startTime)
            ActLuckyDrawPage.ActInfo.act_end_time_stamp = ActLuckyDrawPage.GetTimeStamp(info_data.endTime)

            keepwork.tatfook.lucky_load({
                activityCode = "nationalDay",
            },function(err, msg, data)
                if err == 200 then
                    ActLuckyDrawPage.id = data.id
                else
                    ActLuckyDrawPage.id = 0
                end

                local cur_time_stamp = os.time()
                if cur_time_stamp > ActLuckyDrawPage.ActInfo.act_end_time_stamp then
                    GameLogic.AddBBS("statusBar", L"活动已结束", 5000, "0 255 0");
                    return
                end

                keepwork.tatfook.lucky_awards({
                    activityCode = "nationalDay",
                },function(award_err, award_msg, award_data)
            
                    if err == 200 then
                        ActLuckyDrawPage.RewardData = data
                        print("aaaaaaaaaaaaaaaaaaaaaa", #ActLuckyDrawPage.RewardData)
                    end
                    openView()
                end)
            end) 
        else
            GameLogic.AddBBS("statusBar", L"活动已结束", 5000, "0 255 0");
        end
    end)  



    -- openView()
end

function ActLuckyDrawPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function ActLuckyDrawPage.CloseView()
    ActLuckyDrawPage.ClearData()
end

function ActLuckyDrawPage.ClearData()
    ActLuckyDrawPage.Current_Item_DS = {};
    ActLuckyDrawPage.draw_bt_enable = true
    ActLuckyDrawPage.id = 0
    ActLuckyDrawPage.ActInfo = {}
    ActLuckyDrawPage.RewardData = {}
end

function ActLuckyDrawPage.LuckyDraw()
    local draw_cb = function ()
        if not ActLuckyDrawPage.draw_bt_enable then
            GameLogic.AddBBS("statusBar", L"您已许愿，请等待结果", 5000, "0 255 0");
            return
        end

        local profile = KeepWorkItemManager.GetProfile()

        if profile.cellphone == nil or profile.cellphone == "" then
            GameLogic.AddBBS("statusBar", L"未绑定手机号不能参与抽奖", 5000, "255 0 0");
            return
        end
    
        ActLuckyDrawPage.draw_bt_enable = false
    
        keepwork.tatfook.lucky_push({
            lotteryId = ActLuckyDrawPage.id,
        },function(err, msg, data)
            if err == 200 then
                ActLuckyDrawPage.UpdataDrawBt()
                GameLogic.AddBBS("statusBar", L"参与抽奖成功，请静候佳音", 5000, "0 255 0");
            elseif err == 400 then
                GameLogic.AddBBS("statusBar", L"未绑定手机号不能参与抽奖", 5000, "255 0 0");
                ActLuckyDrawPage.draw_bt_enable = true
            else
                GameLogic.AddBBS("statusBar", L"您已许愿，请等待结果", 5000, "255 0 0");
            end
    
        end) 
    end

    if(KeepworkServiceSession:IsSignedIn())then
        draw_cb()
        return
    end
    LoginModal:CheckSignedIn(L"请先登录", function(result)
        if result == true then
            ActLuckyDrawPage.UpdataDrawBt()
            -- Mod.WorldShare.Utils.SetTimeOut(function()
            --     if result then
			-- 		draw_cb()
            --     end
            -- end, 500)
        end
	end)    
end

function ActLuckyDrawPage.OpenRewardList()
    local ActGetRewardList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActLuckyDraw/ActGetRewardList.lua");
    ActGetRewardList.Show();

    page:CloseWindow(0)
    ActLuckyDrawPage.ClearData()
end

function ActLuckyDrawPage.UpdataDrawBt()
    keepwork.tatfook.lucky_check({
        lotteryId = ActLuckyDrawPage.id,
    },function(err, msg, data)
        if err == 200 then    
            ActLuckyDrawPage.draw_bt_enable = not data.data
            ActLuckyDrawPage.OnRefresh()
        else
            ActLuckyDrawPage.draw_bt_enable = true
        end
    end)  
end

function ActLuckyDrawPage.GetActState()
    if ActLuckyDrawPage.ActInfo == nil or ActLuckyDrawPage.ActInfo.act_start_time_stamp == nil or ActLuckyDrawPage.ActInfo.act_end_time_stamp == nil then
        return ActLuckyDrawPage.ActState.has_ended
    end

    local cur_time_stamp = os.time()
    if cur_time_stamp < ActLuckyDrawPage.ActInfo.act_start_time_stamp then
        return ActLuckyDrawPage.ActState.not_start
    end

    if cur_time_stamp >= ActLuckyDrawPage.ActInfo.act_start_time_stamp and cur_time_stamp <= ActLuckyDrawPage.ActInfo.act_end_time_stamp then

        -- 这里显示的活动结束其实不是真的活动结束 而是要用期数去判断 例如总期数5期 然后现在也是第五期了

        local all_times = ActLuckyDrawPage.ActInfo.periodCount or 5
        local cur_times = #ActLuckyDrawPage.RewardData
        if cur_times >= all_times then
            return ActLuckyDrawPage.ActState.has_ended
        end

        return ActLuckyDrawPage.ActState.ongoing
    end
    
    return ActLuckyDrawPage.ActState.has_ended
end

function ActLuckyDrawPage.GetTimeStamp(at_time)
    at_time = at_time or ""
    -- at_time = "2020-09-09T06:52:43.000Z"
    local year, month, day, hour, min, sec = at_time:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
    local time_stamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour) + 8}) -- 这个时间是带时区的 要加8小时
    time_stamp = time_stamp + min * 60 + sec

    return time_stamp
end
