--[[
Title: ActGetRewardList
Author(s): yangguiyi
Date: 2020/9/22
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActLuckyDraw/ActGetRewardList.lua").Show();
--]]
local ActLuckyDrawPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActLuckyDraw/ActLuckyDrawPage.lua")
local ActGetRewardList = NPL.export();
local page;
ActGetRewardList.Current_Item_DS = {};

ActGetRewardList.CurSelectIndex = 1
ActGetRewardList.ServerData = {}
-- {
--     -- 第一期
--     {id = 10086, userLotteries = {
--             {id = 1, userId=110, award=1, user={username="我是第一名11", cellphone=1380}},

--             {id = 3, userId=111, award=2, user={username="我是第二名11", cellphone=1381}},
--             {id = 3, userId=112, award=2, user={username="我是第二名22", cellphone=1382}},
--             {id = 4, userId=113, award=2, user={username="我是第二名33", cellphone=1383}},

--             {id = 4, userId=114, award=3, user={username="我是第三名3333", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},
--             {id = 4, userId=114, award=3, user={username="我是第三名33", cellphone=1384}},

--             {id = 4, userId=114, award=4, user={username="我是第四名33", cellphone=1384}},
--             {id = 4, userId=114, award=4, user={username="我是第四名33", cellphone=1384}},
--             {id = 4, userId=114, award=4, user={username="我是第四名33", cellphone=1384}},
--             {id = 4, userId=114, award=4, user={username="我是第四名33", cellphone=1384}},
--         }
--     },
-- }

function ActGetRewardList.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ActGetRewardList.CloseView
end


function ActGetRewardList.Show()

    keepwork.tatfook.lucky_awards({
        activityCode = "nationalDay",
    },function(err, msg, data)

        if err == 200 then
            if #data == 0 then
                GameLogic.AddBBS("statusBar", L"暂无获奖信息", 5000, "0 255 0");
                return
            end

            ActGetRewardList.ServerData = {}
            ActGetRewardList.CurSelectIndex = #data
            for index = #data, 1, -1 do
                ActGetRewardList.ServerData[#ActGetRewardList.ServerData + 1] = data[index]
            end

            -- ActGetRewardList.ServerData = data
            ActGetRewardList.HandleData()
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/ActLuckyDraw/ActGetRewardList.html",
                name = "ActGetRewardList.Show", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                style = CommonCtrl.WindowFrame.ContainerStyle,
                allowDrag = true,
                enable_esc_key = true,
                zorder = -1,
                app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
                directPosition = true,
                
                align = "_ct",
                x = -860/2,
                y = -616/2 - 40,
                width = 860,
                height = 616,
            };
            
            System.App.Commands.Call("File.MCMLWindowFrame", params);
        end

    end)  
        

end

function ActGetRewardList.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function ActGetRewardList.CloseView()
    ActGetRewardList.ClearData()

    ActLuckyDrawPage.Show();
end

function ActGetRewardList.ClearData()
    ActGetRewardList.Current_Item_DS = {}
    ActGetRewardList.CurSelectIndex = 1
end

function ActGetRewardList.GetIcon()
    return ""
end

function ActGetRewardList.HandleData()
    local max_level = 0
    local list = {}
    local last_reward_data = ActGetRewardList.ServerData[ActGetRewardList.CurSelectIndex] or {}
    local userLotteries = last_reward_data.userLotteries or {}
	table.sort(userLotteries, function(a, b)
		return (b.award > a.award)
	end)

    local index = 0
    ActGetRewardList.Current_Item_DS = {}
    for i, v in ipairs(userLotteries) do
        if v.award and list[v.award] == nil then
            index = index + 1
            ActGetRewardList.Current_Item_DS[index] = {is_show_level = true, level = v.award}
            list[v.award] = 0
            index = index + 1
        else
            if ActGetRewardList.Current_Item_DS[index] and ActGetRewardList.Current_Item_DS[index].userList and #ActGetRewardList.Current_Item_DS[index].userList > 4 then
                index = index + 1
            end
        end

        if ActGetRewardList.Current_Item_DS[index] == nil then
            ActGetRewardList.Current_Item_DS[index] = {}
        end

        if ActGetRewardList.Current_Item_DS[index].userList == nil then
            ActGetRewardList.Current_Item_DS[index].userList = {}
            ActGetRewardList.Current_Item_DS[index].is_show_level = false
        end

        local userList = ActGetRewardList.Current_Item_DS[index].userList
        userList[#userList + 1] = {name = v.user.username, award = v.award}
        list[v.award] = list[v.award] + 1
        -- print("sssssssss", v.user.username, index)     
    end

    -- print("gggggggggggggggggg")
    -- commonlib.echo(list, true)


    for k, v in pairs(ActGetRewardList.Current_Item_DS) do
        if v.userList then
            v.mcml_str = ActGetRewardList.GetShowStr(v.userList, list)
        end
    end
end

function ActGetRewardList.GetShowStr(userList, list)
    local mcml_str = ""
    for k, v in pairs(userList) do
        local left_px = "25px"
        local str = string.format('<div style="float: left;margin-left: %s;margin-top:3px;color: #136c5e; font-size:12pt; font-weight:bold; width:100px">%s</div>', left_px, v.name)
        if list[v.award] == 1 then
            left_px = "280px"
            str = string.format('<div style="float: left;margin-left: %s;margin-top:3px;color: #136c5e; font-size:12pt; font-weight:bold; width:100px; text-align:center">%s</div>', left_px, v.name)
        end
        
        mcml_str = mcml_str .. str
    end
    return mcml_str
end

function ActGetRewardList.ChangeItem(index)
    if ActGetRewardList.ServerData[index] == nil then
        GameLogic.AddBBS("statusBar", L"暂无获奖信息", 5000, "0 255 0");
        return
    end
    
    ActGetRewardList.CurSelectIndex = index
    ActGetRewardList.HandleData()
    ActGetRewardList.OnRefresh()
end