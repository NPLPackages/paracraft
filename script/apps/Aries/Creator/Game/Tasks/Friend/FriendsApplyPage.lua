--[[
Title: FriendsApplyPage
Author(s): yangguiyi
Date: 2020/9/2
Desc:  
Use Lib:
-------------------------------------------------------
local FriendsApplyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsApplyPage.lua");
FriendsApplyPage.Show();
--]]

local FriendsApplyPage = NPL.export();

local page;
local DateTool = os.date
FriendsApplyPage.Current_Item_DS = {};
local UserData = {}
local FollowList = {}
local SearchIdList = {}
local RefuseList = {}

function FriendsApplyPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = FriendsApplyPage.CloseView
    
end

function FriendsApplyPage.Show(user_data)
    UserData = user_data

    local id = UserData.id or 0
	local filepath = string.format("chat_content/%s_refuse_list.txt", id)
    local file = ParaIO.open(filepath, "r");
    if(file:IsValid()) then
        local text = file:GetText();
        RefuseList = commonlib.Json.Decode(text)
        file:close();
    end

    local att = ParaEngine.GetAttributeObject();
    local oldsize = att:GetField("ScreenResolution", {1280,720});

    FriendsApplyPage.FlushData(function (list)
        FriendsApplyPage.Current_Item_DS = list
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/Friend/FriendsApplyPage.html",
            name = "FriendsApplyPage.Show", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = true,
            enable_esc_key = true,
            zorder = -1,
            app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
            directPosition = true,
            
            align = "_lt",
            x = oldsize[1]/2 - 564/2,
            y = oldsize[2]/2 - 324/2,
            width = 564,
            height = 324,
        };
        
        System.App.Commands.Call("File.MCMLWindowFrame", params);
    end)
end

function FriendsApplyPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function FriendsApplyPage.SearchFriend(text)

    if text == nil or text == "" then
        GameLogic.AddBBS("statusBar", L"请输入对方账号", 5000, "0 255 0");
        return
    end

    local search_text = "%" .. text .. "%"

end

function FriendsApplyPage.ToFollow(userId)
	-- userId = 176382
	keepwork.user.follow({
		objectType = 0,
		objectId = userId,
	},function(err, msg, data)
        GameLogic.AddBBS("statusBar", L"关注成功。", 5000, "0 255 0");

        FriendsApplyPage.FlushData(function (list)
            FriendsApplyPage.Current_Item_DS = list
            FriendsApplyPage.OnRefresh()
        end)

        -- 刷新好友界面
        local friend_page = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
        local is_open = friend_page.GetIsOpen()
        if is_open then
            friend_page.FlushCurDataAndView()
        end
	end)
end

function FriendsApplyPage.GetIcon(data)
	if data.portrait and data.portrait ~= "" then
        return data.portrait
    end

    return "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png"
end

-- 我是否已经关注了某人 id 某人的id
function FriendsApplyPage.IsFollow(id)
    if FollowList[id] then
        return true
    end

    return false
end

function FriendsApplyPage.GetFansBtText(data)
    local is_follow = FriendsApplyPage.IsFollow(data.id)
    if is_follow then
		return "已关注"
    end
	
	return "关注"
end
function FriendsApplyPage.UpdataFoucsList(updata_cb)
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

function FriendsApplyPage.CloseView()
    print("FriendsApplyPage.CloseView()")
    FriendsApplyPage.ClearData()
end

function FriendsApplyPage.ClearData()
    FriendsApplyPage.Current_Item_DS = {}
    UserData = {}
    FollowList = {}
    SearchIdList = {}
end

function FriendsApplyPage.Fefuse(data)
    RefuseList[tostring(data.id)] = 1

    local id = UserData.id or 0
	local filepath = string.format("chat_content/%s_refuse_list.txt", id)
	local conten_str = commonlib.Json.Encode(RefuseList)
    ParaIO.CreateDirectory(filepath);
	local file = ParaIO.open(filepath, "w");
	if(file:IsValid()) then
		file:WriteString(conten_str);
		file:close();
    end
    
    FriendsApplyPage.FlushData(function (list)
        FriendsApplyPage.Current_Item_DS = list
        FriendsApplyPage.OnRefresh()
    end)
end

function FriendsApplyPage.FlushData(callback)
    keepwork.user.followers({
        username=search_text,
        headers = {
            ["x-per-page"] = 200,
            ["x-page"] = 1,
        },
        userId = UserData.id,
    },function(err, msg, data)
        commonlib.echo(data, true)
        if err == 200 then
            local list = {}
            
            for index, value in ipairs(data.rows) do
                if not value.isFriend and RefuseList[tostring(value.id)] == nil then
                    list[#list + 1] = value
                end
            end
            
            if callback then
                callback(list)
            end
        end
    end)
end