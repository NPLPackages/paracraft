--[[
Title: ActLantern
Author(s): yangguiyi
Date: 2020/9/22
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActLantern/ActLantern.lua").Show();
--]]

local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local ActLantern = NPL.export();
NPL.load("(gl)script/ide/Transitions/Tween.lua");
local page;
ActLantern.Current_Item_DS = {};
ActLantern.draw_bt_enable = true
ActLantern.view_type = {
    start_view = 1,
    question_view = 2,
    success_view = 3,
    fail_view = 4,
}

ActLantern.result_type = {
    success = "success",
    fail = "fail",
}

ActLantern.cur_view_type = ActLantern.view_type.start_view

ActLantern.question_num = 0
ActLantern.id = 0
ActLantern.select_answer_list = {}
ActLantern.question_list = {}
ActLantern.act_data = {}
local ShowQuestionNum = 5
local ActCode = "lamp"

function ActLantern.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ActLantern.CloseView
end

function ActLantern.Show()
    -- ActLantern.cur_view_type = ActLantern.view_type.success_view
    -- ActLantern.cur_view_type = ActLantern.view_type.fail_view

    -- 先判断活动是否结束
    keepwork.tatfook.lucky_lantern_info({
    },function(info_err, info_msg, info_data)
        -- print("ggggggggggggggg", info_err)
        -- commonlib.echo(info_data, true)
        if info_err == 200 then
            local act_start_time_stamp = ActLantern.GetTimeStamp(info_data.startTime)
            local act_end_time_stamp = ActLantern.GetTimeStamp(info_data.endTime)

            keepwork.tatfook.lucky_load({
                activityCode = ActCode,
            },function(err, msg, data)
                if err == 200 then
                    ActLantern.id = data.id
                else
                    ActLantern.id = 0
                end

                local cur_time_stamp = os.time()
                if cur_time_stamp > act_end_time_stamp then
                    GameLogic.AddBBS("statusBar", L"活动已结束", 5000, "0 255 0");
                    return
                end

                if cur_time_stamp < act_start_time_stamp then
                    GameLogic.AddBBS("statusBar", L"活动尚未开始", 5000, "0 255 0");
                    return
                end

                -- 再判断是否公布中奖名单
                keepwork.tatfook.lucky_awards({
                    activityCode = ActCode,
                },function(award_err, award_msg, award_data)
                    -- print("bbbbbbbbbbbbbbbbbbbbbbbb")
                    -- commonlib.echo(award_data)
                    if award_err == 200 then
                        -- ActLantern.RewardData = data
 
                        if #award_data > 0 then
                            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActLantern/ActLanternReward.lua").Show(award_data);
                            return
                        end
                    end

                    -- 再判断用户是否登录了
                    if KeepworkServiceSession:IsSignedIn() then
                        ActLantern.ShowView()
                        return
                    end

                    LoginModal:CheckSignedIn(L"请先登录", function(result)
                        if result == true then
                            Mod.WorldShare.Utils.SetTimeOut(function()
                                if result then
                                    ActLantern.ShowView()
                                end
                            end, 500)
                        end
                    end)
                end)
            end) 
        else
            GameLogic.AddBBS("statusBar", L"活动已结束", 5000, "0 255 0");
        end
    end)  

end

function ActLantern.ShowView()
    local profile = KeepWorkItemManager.GetProfile()
    local id = profile.id or 0
	local filepath = string.format("chat_content/%s_act_data.txt", id)
    local file = ParaIO.open(filepath, "r");
    if(file:IsValid()) then
        local text = file:GetText();
        ActLantern.act_data = commonlib.Json.Decode(text) or {}
        file:close();
    end

    -- 没有说明还没答过题
    local act_data = ActLantern.act_data[ActCode]
    if act_data == nil then
        ActLantern.cur_view_type = ActLantern.view_type.start_view
    else
        if act_data.result == ActLantern.result_type.success then
            ActLantern.cur_view_type = ActLantern.view_type.success_view
        elseif act_data.result == ActLantern.result_type.fail then
            ActLantern.cur_view_type = ActLantern.view_type.fail_view
        end
    end

    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ActLantern/ActLantern.html",
        name = "ActLantern.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = -1,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -700/2,
        y = -662/2,
        width = 700,
        height = 662,
    };
    
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    ActLantern.UpdataDrawBt()
end

function ActLantern.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function ActLantern.CloseView()
    ActLantern.ClearData()
end

function ActLantern.ClearData()
    ActLantern.select_answer_list = {}
    ActLantern.act_data = {}
    ActLantern.id = 0
    -- ActLantern.Current_Item_DS = {}
end

function ActLantern.UpdataDrawBt()
    keepwork.tatfook.lucky_check({
        lotteryId = ActLantern.id,
    },function(err, msg, data)

        if err == 200 then
            commonlib.echo(data, true)
    
            ActLantern.draw_bt_enable = not data.data
            -- true的话说明抽奖成功了 展示抽奖成功界面
            if data.data then
                ActLantern.cur_view_type = ActLantern.view_type.success_view
            end

            ActLantern.OnRefresh()
        end

    end)  
end

function ActLantern.OpenQuestionView()
    if ActLantern.id == 0 then
        GameLogic.AddBBS("statusBar", L"本期活动已结束", 5000, "255 0 0");
        return 
    end

    local profile = KeepWorkItemManager.GetProfile()

    if profile.cellphone == nil or profile.cellphone == "" then
        GameLogic.AddBBS("statusBar", L"未绑定手机号不能参与答题", 5000, "255 0 0");
        return
    end

    ActLantern.cur_view_type = ActLantern.view_type.question_view

    ActLantern.HandleQuestionData()
    ActLantern.OnRefresh()

end

function ActLantern.SelectAnswer(select_index, data)
    data.select_index = select_index
    ActLantern.select_answer_list[data.question_data_index] = data
    ActLantern.OnRefresh()
end

function ActLantern.OnOk(select_index, data)
    if ActLantern.id == 0 then
        GameLogic.AddBBS("statusBar", L"本期活动已结束", 5000, "255 0 0");
        return 
    end

    for index = 1, ShowQuestionNum do
        local answer_data = ActLantern.select_answer_list[index]
        if answer_data == nil then
            GameLogic.AddBBS("statusBar", L"请完成所有答题", 5000, "0 255 0");
            return
        end
    end

    local right_num = 0
    for k, v in pairs(ActLantern.select_answer_list) do
        local data = v.answer_list[v.select_index] or {}
        if data.is_right then
            right_num = right_num + 1
        end
    end


    if ActLantern.act_data[ActCode] == nil then
        ActLantern.act_data[ActCode] = {}
    end
    
    local function save_local_act_data()
        local profile = KeepWorkItemManager.GetProfile()
        local id = profile.id or 0
        local filepath = string.format("chat_content/%s_act_data.txt", id)
        local conten_str = commonlib.Json.Encode(ActLantern.act_data)
        ParaIO.CreateDirectory(filepath);
        local file = ParaIO.open(filepath, "w");
        if(file:IsValid()) then
            file:WriteString(conten_str);
            file:close();
        end
    end
    
    if right_num >= 3 then
        -- 这里要发起抽奖
        -- ActLantern.act_data[ActCode].result = ActLantern.result_type.success
        -- ActLantern.cur_view_type = ActLantern.view_type.success_view
        -- save_local_act_data()

        -- ActLantern.OnRefresh()

        keepwork.tatfook.lucky_push({
            lotteryId = ActLantern.id,
        },function(err, msg, data)
            if err == 200 then
                -- GameLogic.AddBBS("statusBar", L"参与抽奖成功，请静候佳音", 5000, "0 255 0");

                ActLantern.act_data[ActCode].result = ActLantern.result_type.success
                ActLantern.cur_view_type = ActLantern.view_type.success_view
                save_local_act_data()

                ActLantern.OnRefresh()
            elseif err == 400 then
                GameLogic.AddBBS("statusBar", L"未绑定手机号不能参与抽奖", 5000, "255 0 0");
            else
                GameLogic.AddBBS("statusBar", L"本期活动已结束", 5000, "255 0 0");
            end
    
        end) 
        
    else
        ActLantern.cur_view_type = ActLantern.view_type.fail_view
        ActLantern.act_data[ActCode].result = ActLantern.result_type.fail
        save_local_act_data()
        ActLantern.OnRefresh()
    end


    -- data.select_index = select_index
    -- ActLantern.select_answer_list[data.question_index] = data
    -- ActLantern.OnRefresh()
end

function ActLantern.HandleQuestionData()
    if #ActLantern.question_list == 0 then
        NPL.load("(gl)script/ide/XPath.lua");
        local XPath = commonlib.XPath
        local filename = "script/apps/Aries/Creator/Game/Tasks/ActLantern/LanternRiddle.xml"
        local xmlRootNode = ParaXML.LuaXML_ParseFile(filename);
        local node;
        for node in XPath.eachNode(xmlRootNode, "//Worksheet") do
            if node[1] then
                for k, v in pairs(node[1]) do
                    if v and type(v) == "table" and v[1] ~= nil then
                        local data = {}
                        for i2, v2 in ipairs(v) do
                            if v2[1] and v2[1][1] then
                                if i2 == 1 then -- 第一个是问题
                                    ActLantern.question_num = ActLantern.question_num + 1

                                    ActLantern.question_list[ActLantern.question_num] = {}
                                    ActLantern.question_list[ActLantern.question_num].question = {is_question = true, desc = v2[1][1]}
                                end
    
                                if i2 >= 2 then -- 第二个是正确答案
                                    if data.answer_list == nil then
                                        data.answer_list = {}
                                    end
                                    
                                    local answer_data = {}
                                    answer_data.desc = v2[1][1]
                                    answer_data.is_right = i2 == 2
                                    answer_data.sort_num = math.random(100)
    
                                    data.answer_list[#data.answer_list + 1] = answer_data
    
                                    if i2 == #v then
                                        table.sort(data.answer_list, function(a, b)
                                            return (a.sort_num < b.sort_num);
                                        end);
    
                                        data.select_index = 0
                                        data.question_index = ActLantern.question_num

                                        ActLantern.question_list[ActLantern.question_num].answer = data
                                    end
                                end
                            end
                        end
    
                    end
                end
            end
        end
    end

    ActLantern.Current_Item_DS = {}

    local select_index_list = {} -- 用来防止随机到重复
    for index = 1, ShowQuestionNum do
        local data = ActLantern.GetRandomQuestion(select_index_list, 1)
        if data then
            data.question.question_data_index = index
            data.answer.question_data_index = index
            ActLantern.Current_Item_DS[#ActLantern.Current_Item_DS + 1] = data.question
            ActLantern.Current_Item_DS[#ActLantern.Current_Item_DS + 1] = data.answer
        end

    end

end

function ActLantern.GetRandomQuestion(select_index_list, random_times)
    if random_times >= 400 then
        return
    end
    
    local random_index = math.random(1, ActLantern.question_num)

    random_times = random_times + 1
    if select_index_list[random_index] == nil and ActLantern.question_list[random_index] ~= nil then
        select_index_list[random_index] = 1
        return ActLantern.question_list[random_index]
    else
        return ActLantern.GetRandomQuestion(select_index_list, random_times)
    end
end

function ActLantern.IsShowStartView()
    return ActLantern.cur_view_type == ActLantern.view_type.start_view
end

function ActLantern.IsShowQuestionView()
    return ActLantern.cur_view_type == ActLantern.view_type.question_view
end

function ActLantern.IsShowSuccessView()
    return ActLantern.cur_view_type == ActLantern.view_type.success_view
end

function ActLantern.IsShowFailView()
    return ActLantern.cur_view_type == ActLantern.view_type.fail_view
end

function ActLantern.GetTimeStamp(at_time)
    at_time = at_time or ""
    -- at_time = "2020-09-09T06:52:43.000Z"
    local year, month, day, hour, min, sec = at_time:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
    local time_stamp = os.time({day=tonumber(day), month=tonumber(month), year=tonumber(year), hour=tonumber(hour) + 8}) -- 这个时间是带时区的 要加8小时
    time_stamp = time_stamp + min * 60 + sec

    return time_stamp
end