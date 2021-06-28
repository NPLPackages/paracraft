--[[
Title: Rank
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/Rank.lua").Show();
--]]
local page
local Rank = NPL.export();
local pe_treeview = commonlib.gettable("Map3DSystem.mcml_controls.pe_treeview");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
-- {
--     name: '院校综合榜',
--     code: 'orgComprehensive',
-- },
-- {
--     name: '院校势力榜',
--     code: 'orgPower',
-- },
-- {
--     name: '院校创作力',
--     code: 'orgCreate',
-- },
-- {
--     name: '好学校园榜',
--     code: 'orgStudy',
-- },
-- {
--     name: '顶流大牛榜',
--     code: 'personTop',
-- },
-- {
--     name: '作品榜',
--     code: 'personWorld',
-- },
-- {
--     name: '热门作品榜',
--     code: 'projectHot',
-- },

Rank.RankDescList = {
    ["orgComprehensive"] = "院校综合排行是结合院校学生数量、学习情况、作品情况等多方面因素综合考虑并评分的榜单，学生数量越多、学习课程越多、作品越多得分越高，每月1号重新计算",
    ["orgPower"] = "院校势力榜是激活学生数量的排名，完成注册并实名认证的该校学生人数，每有1人记1分，每月1号重新计算",
    ["orgCreate"] = "院校创作力为该院校作品总数，该校所有学生的作品总和，每有一个作品记1分，每月1号重新计算",
    ["orgStudy"] = "好学校园榜为该校所有学生完成的课程学习总数，每完成一节课程记1分，相同课程不再记录，每月1号重新计算",
    ["personTop"] = "用户所有作品的累计访问量总和，每次访问记1分，每月1号重新计算",
    ["personWorld"] = "用户所有作品累计点赞数量总和，每点赞一次记1分，每月1号重新计算",
    ["projectHot"] = "单一作品的访问量，每次访问记1分，每月1号重新计算",
}

Rank.RankData = {
    -- {rank = 1, name = "我是超长的名字", score = 996, icon_type = "rise"},
    -- {rank = 2, name = "我是超长的名字2", score = 998, icon_type = "low"},
    -- {rank = 3, name = "我是超长的名字2", score = 998, icon_type = "none"},
    -- {rank = 4, name = "我是超长的名字2", score = 998, icon_type = "new"},
    -- {rank = 5, name = "我是超长的名字2", score = 998, icon_type = "new"},
}

local modele_bag_id = 0

function Rank.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = Rank.CloseView
end

function Rank.Show()
    Rank.ShowView()
end

function Rank.ShowView()
    if page and page:IsVisible() then
        return
    end
    Rank.InitData()
    local bagNo = 1007;
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            modele_bag_id = bag.id;
            break;
        end
    end

    Rank.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Rank/Rank.html",
        name = "Rank.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -958/2,
        y = -585/2,
        width = 958,
        height = 585,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    Rank.GetRankListData(function()
        Rank.OnRefresh()
    end)
end

function Rank.FreshView()
    local parent  = page:GetParentUIObject()
end

function Rank.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    Rank.FreshView()
end

function Rank.CloseView()
    Rank.InitData()
end

function Rank.InitData()
    Rank.RankTypeData = {
        {
            name="type",attr={img="Texture/Aries/Creator/keepwork/rank/zi3_30X15_32bits.png", expanded = true},
            {
                name="item",attr={name="院校综合榜",code="orgComprehensive", exid = 31000},
            },
            {
                name="item",attr={name="院校人数榜", code="orgPower", exid = 31010},
            },
            {
                name="item",attr={name="院校创作榜", code="orgCreate", exid = 31020},
            },
            {
                name="item",attr={name="院校学习榜", code="orgStudy", exid = 31030},
            },
        },
        {
            name="type",attr={img="Texture/Aries/Creator/keepwork/rank/zi4_30X15_32bits.png"},
            {
                name="item",attr={name="作品达人榜", code="personTop", exid = 31040},
            },
            {
                name="item",attr={name="作品点赞榜", code="personWorld", exid = 31050},
            },
        },
        {
            name="type",attr={img="Texture/Aries/Creator/keepwork/rank/zi5_30X15_32bits.png"},
            {
                name="item",attr={name="热门作品榜", code="projectHot", exid = 31060},
            },
        },
    }

    Rank.cur_select_type_index = 1
    Rank.cur_select_item_index = 101
    Rank.cur_select_item_data = {}
    Rank.server_list_data = {}
    Rank.SelfRankData = {}
    Rank.RewardData = {}

    Rank.is_show_last_rank = false
end

function Rank.HandleData()
    for k, v in pairs(Rank.RankTypeData) do
        if type(v) == "table" then
            v.attr.index = k
            for k2, v2 in pairs(v) do
                if v2.attr then
                    v2.attr.index = v.attr.index * 100 + k2
                    if v2.attr.index == Rank.cur_select_item_index then
                        Rank.cur_select_item_data = v2.attr
                    end
                end
            end
        end
    end
end

function Rank.HandleRankData(data)
    if Rank.server_list_data.boardRanks == nil then
        return
    end
    local selfRank = Rank.server_list_data.selfRank

    Rank.RankData = {}
    for i, v in ipairs(Rank.server_list_data.boardRanks) do
        local data = {}
        data.rank = v.rank
        data.tool_name = ""
        data.is_my_rank = selfRank and selfRank.rank == data.rank
        
        if v.object then
            if v.object.name then
                data.tool_name = v.object.name
            elseif v.object.nickname then
                data.tool_name = v.object.nickname
            elseif v.object.username then
                data.tool_name = v.object.username
            end
            data.object = v.object
            data.portrait = v.object.portrait
            data.username = v.object.username
        end
        data.name = Rank.GetLimitLabel(data.tool_name)
        
        data.score = v.score
        if data.score and data.score > 10000 then
            data.tool_score = tostring(data.score)
        end

        data.icon_type = "none"
        if v.isNew == 1 then
            data.icon_type = "new"
        elseif v.comparedRank > 0 then
            data.icon_type = "rise"
        elseif v.comparedRank < 0 then
            data.icon_type = "low"
        end

        Rank.RankData[#Rank.RankData + 1] = data
    end

    local MyData = {}

    local profile = KeepWorkItemManager.GetProfile()
    MyData.portrait = profile.portrait
    if selfRank then
        MyData.rank = selfRank.rank
        MyData.tool_name = ""
        if selfRank.object then
            if selfRank.object.name then
                MyData.tool_name = selfRank.object.name
            elseif selfRank.object.nickname then
                MyData.tool_name = selfRank.object.nickname
            elseif selfRank.object.username then
                MyData.tool_name = selfRank.object.username
            end
        end
        MyData.name = Rank.GetLimitLabel(MyData.tool_name)
        MyData.score = selfRank.score
        if MyData.score and MyData.score > 10000 then
            MyData.tool_score = tostring(MyData.score)
        end
        MyData.icon_type = "none"
        if selfRank.isNew == 1 then
            MyData.icon_type = "new"
        elseif selfRank.comparedRank > 0 then
            MyData.icon_type = "rise"
        elseif selfRank.comparedRank < 0 then
            MyData.icon_type = "low"
        end
    else
        MyData.rank = "1000+"
        MyData.name = "-"
        
        if Rank.GetSelectItemTypeIndex() == 1 then
            MyData.name = profile.school and profile.school.name or "-"
        elseif Rank.GetSelectItemTypeIndex() == 2 then
            MyData.name = profile.nickname or profile.username
        end
        MyData.tool_name = MyData.name
        MyData.name = Rank.GetLimitLabel(MyData.name)
        MyData.score = "-"
        MyData.icon_type = "none"
    end
    Rank.SelfRankData = MyData

    Rank.RewardData = {}

    for index = 1, 3 do
        local exid = Rank.cur_select_item_data.exid + index - 1
        local exchange_data = KeepWorkItemManager.GetExtendedCostTemplate(exid)
        
        if exchange_data and exchange_data.exchangeTargets and exchange_data.exchangeTargets[1] then
            for i2, v2 in ipairs(exchange_data.exchangeTargets[1].goods) do
                if i2 <= 3 and #Rank.RewardData < 6 then
                    Rank.RewardData[#Rank.RewardData + 1] = v2
                end
            end
        end
    end

end

function Rank.ChangeMenuType(index)
	Rank.changeMenuNodeType(index)
	Rank.cur_select_type_index = index
    local gvw_name = "rank_menu";
    local node = page:GetNode(gvw_name);
    -- pe_treeview.DataBind(node, gvw_name, true)
    pe_treeview.Refresh(node,gvw_name, true)
	-- Rank.OnRefresh()
end

function Rank.ChangeItem(data)
    Rank.cur_select_item_data = data
	Rank.cur_select_item_index = data.index
    Rank.is_show_last_rank = false
    -- print("ooooooooooooooooo")
    -- echo(exchange_data, true)
    Rank.GetRankListData(function()
        Rank.OnRefresh()
    end)
end

-- 切换到某个类别的时候不会自动收起其他的展开的类别 但能收起当前类别
function Rank.changeMenuNodeType(index)
    local gvw_name = "rank_menu";
    local node = page:GetNode(gvw_name);
    local last_select_menu = Rank.RankTypeData[Rank.cur_select_type_index]
    if last_select_menu and last_select_menu.attr then
        if Rank.cur_select_type_index == index then
            last_select_menu.attr.expanded = not last_select_menu.attr.expanded
        else
            last_select_menu.attr.expanded = false
        end
        
    end

    -- pe_treeview.DataBind(node, gvw_name, true)

    if Rank.cur_select_type_index ~= index then
        local cur_select_menu = Rank.RankTypeData[index]
        if cur_select_menu and cur_select_menu.attr then
            cur_select_menu.attr.expanded = true
        end
    end
end

function Rank.GetRankListData(cb)
    local select_item_data = Rank.cur_select_item_data
    if select_item_data == nil or select_item_data.code == nil then
        return
    end

    keepwork.rank.ranklist({
        boardCode = select_item_data.code,
        last = Rank.is_show_last_rank,
        ["x-per-page"] = 1000,
        ["x-page"] = 1,
    },function(err, msg, data)
        Rank.server_list_data = data
        -- print("cccccccc")
        -- echo(data, true)
        Rank.HandleRankData()

        if err == 200 then
            if cb then
                cb()
            end
        end
    end)
end

function Rank.IsRoleModel(item_data)
	if item_data and item_data.bagId == modele_bag_id then
		return true
	end

	return false
end

function Rank.GetLimitLabel(text, maxCharCount)
    maxCharCount = maxCharCount or 13;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end

function Rank.GetPageCtrl()
	return page 
end

function Rank.GetSelectItemTypeIndex()
    local select_item_data = Rank.cur_select_item_data
    if select_item_data == nil or select_item_data.index == nil then
        return
    end

    return math.floor(select_item_data.index / 100) 
end

function Rank.ShowLastRank()
    Rank.is_show_last_rank = not Rank.is_show_last_rank
    Rank.GetRankListData(function()
        Rank.OnRefresh()
    end)
end

function Rank.GetRankDesc()
    local select_item_data = Rank.cur_select_item_data
    if select_item_data == nil then
        return
    end

    local code = select_item_data.code
    local desc = Rank.RankDescList[code] or ""
    return desc
end

function Rank.GetRecudedNumberDesc(number)
    if number == nil then
        return
    end
    local num = tonumber(number)
    if num == nil then
        return number
    end

    if num < 10000 then
        return number
    end

    local int_num = math.floor(num/10000)
    local float_num = math.floor((num - int_num * 10000)/1000)
    return string.format("%s.%s万", int_num, float_num)
end

function Rank.ToWorld(index)
    local data = Rank.RankData[index]
    local id = data.object and data.object.id
    CommandManager:RunCommand(format('/loadworld -force %d', id))
end

function Rank.ShowReward()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/RankReward.lua").Show(Rank.cur_select_item_data.exid);
end

function Rank.ShowRankHelp()
    local data = Rank.cur_select_item_data
    local code = data.code or "orgComprehensive"
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/RankHelp.lua").Show(code);
end