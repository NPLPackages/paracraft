--[[
Title: FriendsProjectPage
Author(s): yangguiyi
Date: 2020/9/2
Desc:  
Use Lib:
-------------------------------------------------------
local FriendsProjectPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsProjectPage.lua");
FriendsProjectPage.Show();
--]]

local FriendsProjectPage = NPL.export();

local page;
local DateTool = os.date

FriendsProjectPage.Current_Item_DS = {};
FriendsProjectPage.select_item_index = 0
local UserData = {}
local FollowList = {}
local SearchIdList = {}

function FriendsProjectPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = FriendsProjectPage.CloseView
end

-- choicenessNo=0,
-- classifyTags="|",
-- comment=0,
-- createdAt="2020-09-04T06:26:04.000Z",
-- description="",
-- extend={  },
-- extra={
--   imageUrl="http://qiniu-dev.keepwork.com/1103-8243c1ec-9c1f-409c-9334-dcc6cc2c9760.jpg?e=1599287174&token=LYZsjH0681n9sWZqCM4E2KmU6DsJOE7CAM4O3eJq:ywHHm6-MB9Mib2D-2DLLN8ljm1Q=" 
-- },
-- favorite=0,
-- hotNo=0,
-- id=1255,
-- lastComment=0,
-- lastStar=0,
-- lastVisit=0,
-- memberCount=1,
-- name="test",
-- privilege=0,
-- rate=0,
-- rateCount=0,
-- star=0,
-- stars={  },
-- status=0,
-- tags="",
-- type=1,
-- updatedAt="2020-09-04T06:26:15.000Z",
-- user={
--   nickname="yang3",
--   orgAdmin=0,
--   student=0,
--   tLevel=0,
--   userId=1103,
--   username="yang3",
--   vip=0 
-- },
-- userId=1103,
-- visibility=0,
-- visit=0 

function FriendsProjectPage.Show(UserData, userId)
    -- UserData 自己的数据
    -- userId 查看的人的id
    UserData = UserData

    local att = ParaEngine.GetAttributeObject();
    local oldsize = att:GetField("ScreenResolution", {1280,720});
	keepwork.user.projects({
        userId = userId,
        type = 1,               -- 取世界项目
        ["x-per-page"] = 1000,  -- 先取全部后续优化
        ["x-order"] = "updatedAt-desc", -- 按更新时间降序
    },function(err, msg, data)
		commonlib.echo(data, true)
		if err == 200 then
            FriendsProjectPage.Current_Item_DS = data
            print("ccccccccccccccccccc")
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/Friend/FriendsProjectPage.html",
                name = "FriendsProjectPage.Show", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                style = CommonCtrl.WindowFrame.ContainerStyle,
                allowDrag = true,
                enable_esc_key = true,
                zorder = -1,
                app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
                directPosition = true,
                
                align = "_ct",
                x = -630/2,
                y = -432/2,
                width = 630,
                height = 432,
            };
            
            System.App.Commands.Call("File.MCMLWindowFrame", params);
		end
	end)

end

function FriendsProjectPage.OnRefresh()
    if(page)then
        page:Refresh(0.1);
    end
end

function FriendsProjectPage.SearchFriend(text)

    if text == nil or text == "" then
        GameLogic.AddBBS("statusBar", L"请输入对方账号", 5000, "0 255 0");
        return
    end

    local search_text = "%" .. text .. "%"

end

function FriendsProjectPage.ToFollow(userId)
    print("FriendsProjectPage.ToFollow", userId)
	-- userId = 176382
	keepwork.user.follow({
		objectType = 0,
		objectId = userId,
	},function(err, msg, data)
		print("dwwwwwwwwwwwwwwwFriendsPage.Follow", err, msg)
        commonlib.echo(data, true)
        GameLogic.AddBBS("statusBar", L"已向对方发出好友请求，请耐心等待回复。", 5000, "0 255 0");

        local function updata_cb()
            FriendsProjectPage.OnRefresh()
        end
        FriendsProjectPage.UpdataFoucsList(updata_cb)

        -- 刷新好友界面
        local friend_page = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        local is_open = friend_page.GetIsOpen()
        if is_open then
            friend_page.FlushCurDataAndView()
        end
	end)
end

function FriendsProjectPage.GetIcon(data)
	if data.portrait and data.portrait ~= "" then
        return data.portrait
    end

    return "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png"
end

-- 我是否已经关注了某人 id 某人的id
function FriendsProjectPage.IsFollow(id)
    if FollowList[id] then
        return true
    end

    return false
end

function FriendsProjectPage.GetFansBtText(data)
    local is_follow = FriendsProjectPage.IsFollow(data.id)
    if is_follow then
		return "已关注"
    end
	
	return "关注"
end
function FriendsProjectPage.UpdataFoucsList(updata_cb)
    keepwork.user.focus({
        userId = UserData.id,
        objectType = 0,
        objectId = {["$in"] = SearchIdList},
    },function(err, msg, data)
        print("获取关注列表结果", err, msg)
        commonlib.echo(data, true)
        FollowList = {}
        for k, v in pairs(data.rows) do
            FollowList[v.objectId] = v
        end

        if updata_cb then
            updata_cb()
        end
    end)
end

function FriendsProjectPage.CloseView()
    print("FriendsProjectPage.CloseView()")
    FriendsProjectPage.ClearData()
end

function FriendsProjectPage.ClearData()
    FriendsProjectPage.Current_Item_DS = {}
    FriendsProjectPage.select_item_index = 0
    UserData = {}
    FollowList = {}
    SearchIdList = {}
end

-- 注册时间
function FriendsProjectPage.GetRegisterTimeStr(at_time)
    local year, month, day, hour, min = at_time:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)")
    print("GetRegisterTimeStr", year, month, day, hour, min)
    return tostring(year) .. "-" .. tostring(month) .. "-" .. tostring(day) .. "   " .. hour .. ":" .. min;
end

function FriendsProjectPage.ClickItem(item_index)
    FriendsProjectPage.select_item_index = item_index
    FriendsProjectPage.OnRefresh()
end

function FriendsProjectPage.IsItemSelect(item_index)
    return FriendsProjectPage.select_item_index == item_index
end