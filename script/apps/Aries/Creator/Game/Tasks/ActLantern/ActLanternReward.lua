--[[
Title: ActLanternReward
Author(s): yangguiyi
Date: 2020/9/22
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActLantern/ActLanternReward.lua").Show();
--]]
local ActLantern = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActLantern/ActLantern.lua")
local ActLanternReward = NPL.export();
local page;
ActLanternReward.Current_Item_DS = {};
local ActCode = "lamp"
ActLanternReward.CurSelectIndex = 1
ActLanternReward.ServerData = {}
-- local test_data = {
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

function ActLanternReward.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = ActLanternReward.CloseView
end


function ActLanternReward.Show(data)
    data = data or {}
    ActLanternReward.ServerData = {}
    ActLanternReward.CurSelectIndex = #data
    for index = #data, 1, -1 do
        ActLanternReward.ServerData[#ActLanternReward.ServerData + 1] = data[index]
    end

    -- ActLanternReward.ServerData = data
    ActLanternReward.HandleData()


    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ActLantern/ActLanternReward.html",
        name = "ActLanternReward.Show", 
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
        y = -616/2 - 40,
        width = 700,
        height = 616,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
        

end

function ActLanternReward.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function ActLanternReward.CloseView()
    ActLanternReward.ClearData()
end

function ActLanternReward.ClearData()
    ActLanternReward.Current_Item_DS = {}
    ActLanternReward.CurSelectIndex = 1
end

function ActLanternReward.GetIcon()
    return ""
end

function ActLanternReward.HandleData()
    local max_level = 0
    local list = {}
    local last_reward_data = ActLanternReward.ServerData[ActLanternReward.CurSelectIndex] or {}
    local userLotteries = last_reward_data.userLotteries or {}
	table.sort(userLotteries, function(a, b)
		return (b.award > a.award)
	end)

    local index = 0
    ActLanternReward.Current_Item_DS = {}
    for i, v in ipairs(userLotteries) do
        if v.award and list[v.award] == nil then
            index = index + 1
            ActLanternReward.Current_Item_DS[index] = {is_show_level = true, level = v.award}
            list[v.award] = 0
            index = index + 1
        else
            if ActLanternReward.Current_Item_DS[index] and ActLanternReward.Current_Item_DS[index].userList and #ActLanternReward.Current_Item_DS[index].userList > 4 then
                index = index + 1
            end 
        end

        if ActLanternReward.Current_Item_DS[index] == nil then
            ActLanternReward.Current_Item_DS[index] = {}
        end

        if ActLanternReward.Current_Item_DS[index].userList == nil then
            ActLanternReward.Current_Item_DS[index].userList = {}
            ActLanternReward.Current_Item_DS[index].is_show_level = false
        end

        local userList = ActLanternReward.Current_Item_DS[index].userList
        userList[#userList + 1] = {name = v.user.username, award = v.award}
        list[v.award] = list[v.award] + 1
    end


    for k, v in pairs(ActLanternReward.Current_Item_DS) do
        if v.userList then
            v.mcml_str = ActLanternReward.GetShowStr(v.userList, list)
        end
    end

    -- print("gggggggggggggggggg")
    -- commonlib.echo(list, true)


    for k, v in pairs(ActLanternReward.Current_Item_DS) do
        if v.userList then
            v.mcml_str = ActLanternReward.GetShowStr(v.userList, list)
        end
    end
end

function ActLanternReward.GetShowStr(userList, list)
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

function ActLanternReward.ChangeItem(index)
    if ActLanternReward.ServerData[index] == nil then
        GameLogic.AddBBS("statusBar", L"暂无获奖信息", 5000, "0 255 0");
        return
    end
    
    ActLanternReward.CurSelectIndex = index
    ActLanternReward.HandleData()
    ActLanternReward.OnRefresh()
end