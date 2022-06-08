--[[
Title: KeepWorkItemManager
Author(s): leio
Date: 2020/4/24
Desc:  
use the lib:

using cmd parameter "kpitem_enabled" to debug:
local kpitem_enabled = ParaEngine.GetAppCommandLineByParam("kpitem_enabled", false);

KeepWorkItemManager for an authorized user
please login first
-------------------------------------------------------
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
KeepWorkItemManager.Load(true, function()
    commonlib.echo("=====KeepWorkItemManager.globalstore");
    commonlib.echo(KeepWorkItemManager.globalstore);
    commonlib.echo("=====KeepWorkItemManager.extendedcost");
    commonlib.echo(KeepWorkItemManager.extendedcost);
    commonlib.echo("=====KeepWorkItemManager.bags");
    commonlib.echo(KeepWorkItemManager.bags);
    commonlib.echo("=====KeepWorkItemManager.items");
    commonlib.echo(KeepWorkItemManager.items);
end)

echo(KeepWorkItemManager.GetItemTemplate(10004),true)

local bags_number = KeepWorkItemManager.SearchBagsNoFromExid(10001)
echo("==========bags_number");
echo(bags_number);

KeepWorkItemManager.DoExtendedCost(10001)
KeepWorkItemManager.LoadItems({1001,1002})
KeepWorkItemManager.ReLoadItems({10001,10002});


KeepWorkItemManager.GetUserInfo(nil,function(err,msg,data)
    echo("==========userinfo");
    echo(data);
end)

local gsItem = KeepWorkItemManager.GetItemTemplate(gsid);


KeepWorkItemManager.GetFilter():apply_filters("KeepWorkItemManager_LoadProfile");
KeepWorkItemManager.GetFilter():apply_filters("KeepWorkItemManager_LoadItems");


-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
local Encoding = commonlib.gettable("System.Encoding");
NPL.load("(gl)script/ide/System/Core/Filters.lua");
local Filters = commonlib.gettable("System.Core.Filters");

NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkAPI.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");

local KeepWorkItemManager = NPL.export()

KeepWorkItemManager.globalstore_map = {};
KeepWorkItemManager.globalstore = {};
KeepWorkItemManager.extendedcost_map = {};
KeepWorkItemManager.extendedcost = {};
KeepWorkItemManager.bags = {};
KeepWorkItemManager.bags_map = {};
KeepWorkItemManager.items = {};
KeepWorkItemManager.profile = {};
KeepWorkItemManager.loaded = false;
KeepWorkItemManager.filter = nil;
KeepWorkItemManager.is_init = false;
KeepWorkItemManager.exid_preload_items = 11000; --preload item after login

KeepWorkItemManager.page_size = 10000;
function KeepWorkItemManager.TestMsg(gsid)
    gsid = gsid or 1000;
    _guihelper.MessageBox(gsid);
end
function KeepWorkItemManager.IsEnabled()
    return true;
end

function KeepWorkItemManager.StaticInit()
    if(not KeepWorkItemManager.IsEnabled())then
        return
    end
    if(KeepWorkItemManager.is_init)then
        return
    end
    KeepWorkItemManager.is_init = true;
	LOG.std(nil, "info", "KeepWorkItemManager", "StaticInit");
    if(not KeepWorkItemManager.filter)then
        KeepWorkItemManager.filter = Filters:new();
    end
    GameLogic.GetFilters():add_filter("OnKeepWorkLogin", KeepWorkItemManager.OnKeepWorkLogin_Callback);
	GameLogic.GetFilters():add_filter("OnKeepWorkLogout", KeepWorkItemManager.OnKeepWorkLogout_Callback)
    GameLogic.GetFilters():add_filter("on_start_login", function()
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
        local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
        QuestAction.OnClickLogin()
    end);
	
    KeepWorkItemManager.GetFilter():add_filter("KeepWorkItemManager_LoadItems", function()
        KeepWorkItemManager.LoadItems(nil, function()
                KeepWorkItemManager.GetFilter():apply_filters("KeepWorkItemManager_LoadItems_Finished");
        end)
    end);

    KeepWorkItemManager.GetFilter():add_filter("KeepWorkItemManager_LoadProfile", function()
        KeepWorkItemManager.LoadProfile(true, function()
             KeepWorkItemManager.GetFilter():apply_filters("KeepWorkItemManager_LoadProfile_Finished");
        end)
    end);
end
function KeepWorkItemManager.OnGGSMsg(msg)
    msg = msg or {};
    local action = msg.action;
    -- for changing nickname
    if(action == "UpdateNickName")then
        -- force load profile
        KeepWorkItemManager.LoadProfile(true);
    end

end
function KeepWorkItemManager.GetFilter()
    return KeepWorkItemManager.filter;
end
function KeepWorkItemManager.OnKeepWorkLogin_Callback(res)
	LOG.std(nil, "info", "KeepWorkItemManager", "OnKeepWorkLogin_Callback");
    
    -- 强制退出当前用户
    KeepWorkItemManager.OnKeepWorkLogout_Callback();

    KeepWorkItemManager.Load(true, function()
	    LOG.std(nil, "debug", "KeepWorkItemManager.globalstore", KeepWorkItemManager.globalstore);
	    LOG.std(nil, "debug", "KeepWorkItemManager.extendedcost", KeepWorkItemManager.extendedcost);
	    LOG.std(nil, "debug", "KeepWorkItemManager.bags", KeepWorkItemManager.bags);
	    LOG.std(nil, "debug", "KeepWorkItemManager.items", KeepWorkItemManager.items);
	    LOG.std(nil, "debug", "KeepWorkItemManager.profile", KeepWorkItemManager.profile);

        Keepwork:OnLogin();  -- 用户登录成功 数据准备就绪

        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestProvider.lua");
        local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
        QuestProvider:Clear()
        QuestProvider:OnInit();

		GameLogic.ResetABPath();

        -- 皮肤检测 检测用户皮肤是否可以继续用
        local CheckSkin = NPL.load("(gl)Mod/GeneralGameServerMod/UI/Vue/Page/User/CheckSkin.lua");
        if CheckSkin and CheckSkin.CheckUserSkin then
            CheckSkin.CheckUserSkin()
        end
    end)            
    return res;
end
function KeepWorkItemManager.OnKeepWorkLogout_Callback(res)
    LOG.std(nil, "info", "KeepWorkItemManager", "OnKeepWorkLogout_Callback");
    
    Keepwork:OnLogout();  -- 用户登录成功 数据准备就绪

    KeepWorkItemManager.Clear();
    UserPermission.ClearUserRoles()
    return res;
end

function KeepWorkItemManager.Clear()
    KeepWorkItemManager.globalstore_map = {};
    KeepWorkItemManager.globalstore = {};
    KeepWorkItemManager.extendedcost_map = {};
    KeepWorkItemManager.extendedcost = {};
    KeepWorkItemManager.bags = {};
    KeepWorkItemManager.bags_map = {};
    KeepWorkItemManager.items = {};
    KeepWorkItemManager.profile = {};
    KeepWorkItemManager.loaded = false;
end
function KeepWorkItemManager.GetToken()
    local User = commonlib.gettable('System.User');
    return System.User.keepworktoken;
end
--[[
{
  createdAt="2020-04-24T01:29:46.000Z",
  desc="222",
  endTime="2020-05-28T16:00:00.000Z",
  exId=11,
  exchangeCosts={
    {
      amount=3,
      goods={
        bagId=1,
        canHandsel=true,
        canTrade=true,
        canUse=true,
        coins=1111,
        createdAt="2020-03-13T02:43:32.000Z",
        dayMax=11,
        deleted=false,
        desc="23123",
        destoryAfterUse=true,
        expiredRules=1,
        gsId=5,
        icon="http://www.baidu.com",
        id=2,
        max=11,
        name="物品",
        price=111,
        stackable=true,
        typeId=3,
        updatedAt="2020-03-13T02:43:32.000Z",
        weekMax=11 
      },
      id=2 
    } 
  },
  exchangeTargets={
    {
      goods={
        {
          amount=1,
          goods={ bagId=2, id=4, ... },
          id=4 
        } 
      },
      probability=100 
    } 
  },
  greedy=true,
  id=10,
  name="22",
  preconditions={
    {
      amount=4,
      goods={ ... },
      id=2,
      op="lt" 
    } 
  },
  startTime="2020-04-22T16:00:00.000Z",
  storage=3,
  updatedAt="2020-04-24T01:29:55.000Z" 
}
--]]
function KeepWorkItemManager.GetExtendedCostTemplate(exid)
    if(not exid)then
        return
    end
    exid = tonumber(exid)
    local template = KeepWorkItemManager.extendedcost_map[exid];
    if(template)then
        return template;
    end
    for k,v in ipairs(KeepWorkItemManager.extendedcost) do
        if( v.exId == exid)then
            KeepWorkItemManager.extendedcost_map[exid] = v;
            return v;
        end
    end
end

-- get conditions in a extendedcost
-- @param exid: the id of extendedcost 
-- return precondition,cost,goal
function KeepWorkItemManager.GetConditions(exid)
    local precondition = KeepWorkItemManager.GetPrecondition(exid);
    local cost = KeepWorkItemManager.GetCost(exid);
    local goal = KeepWorkItemManager.GetGoal(exid);
    return precondition,cost,goal
end
--[[
{
  {
    amount=6,
    goods={
      bagId=4,
      beans=20,
      canHandsel=false,
      canTrade=false,
      canUse=true,
      coins=98,
      createdAt="2020-06-01T07:48:30.000Z",
      dayMax=9999999999,
      deleted=false,
      desc="用于在世界频道中广播，每条消息消耗1个。",
      destoryAfterUse=true,
      expiredRules=1,
      expiredSeconds=0,
      gsId=10001,
      holdingLimit=8888888888,
      icon="0",
      id=12,
      max=9999999999,
      name="世界喇叭",
      stackable=true,
      typeId=8,
      updatedAt="2020-06-01T08:28:43.000Z",
      weekMax=9999999999 
    },
    id=12,
    op="gte" 
  } 
}
--]]
function KeepWorkItemManager.GetPrecondition(exid)
    local template = KeepWorkItemManager.GetExtendedCostTemplate(exid);
    if(template)then
        return template.preconditions;
    end
end
function KeepWorkItemManager.GetCost(exid)
    local template = KeepWorkItemManager.GetExtendedCostTemplate(exid);
    if(template)then
        return template.exchangeCosts;
    end
end
--[[
{
  {
    goods={
      {
        amount=1,
        goods={
          animationUrl="",
          bagId=5,
          beans=9999999999,
          canHandsel=false,
          canTrade=false,
          canUse=false,
          coins=9999999999,
          createdAt="2020-10-28T10:05:52.000Z",
          dayMax=1,
          deleted=false,
          desc="任务系统记录用",
          destoryAfterUse=false,
          expiredRules=1,
          fileType="",
          gifUrl="",
          gsId=40002,
          holdingLimit=1,
          icon="0",
          id=131,
          max=1,
          modelUrl="",
          name="任务系统记录用",
          stackable=true,
          typeId=9,
          updatedAt="2020-10-28T10:05:52.000Z",
          weekMax=1 
        },
        id=131 
      } 
    },
    probability=100 
  } 
}
]]
function KeepWorkItemManager.GetGoal(exid)
    local template = KeepWorkItemManager.GetExtendedCostTemplate(exid);
    if(template)then
        return template.exchangeTargets;
    end
end

--[[
{
  bagId=2,
  canHandsel=false,
  canTrade=false,
  canUse=true,
  coins=999999999999,
  createdAt="2020-05-21T06:54:00.000Z",
  dayMax=1,
  deleted=false,
  desc="免费入场券",
  destoryAfterUse=true,
  expiredRules=1,
  expiredSeconds=0,
  gsId=10004,
  icon="Texture/Aries/Item/1022_LargeLollipop.png",
  id=13,
  max=7,
  name="免费入场券",
  price=999999999999,
  stackable=true,
  typeId=3,
  updatedAt="2020-05-21T06:54:00.000Z",
  weekMax=2 
}
--]]
function KeepWorkItemManager.GetItemTemplate(gsid)
    gsid = tonumber(gsid)
    local template = KeepWorkItemManager.globalstore_map[gsid];
    if(template)then
        return template;
    end
    for k,v in ipairs(KeepWorkItemManager.globalstore) do
        if( v.gsId == gsid)then
            KeepWorkItemManager.globalstore_map[gsid] = v;
            return v;
        end
    end
end
function KeepWorkItemManager.GetItem(guid)
    guid = tonumber(guid)
    for k,v in ipairs(KeepWorkItemManager.items) do
        if( v.id == guid)then
            return v;
        end
    end
end
function KeepWorkItemManager.IsLoaded()
    return KeepWorkItemManager.loaded;
end
function KeepWorkItemManager.Load(bForced, callback)
    if(not bForced and KeepWorkItemManager.IsLoaded())then
        if(callback)then
            callback();
        end            
        return
    end

    KeepWorkItemManager.GetFilter():apply_filters("loading", L"加载GlobalStore");
    KeepWorkItemManager.LoadGlobalStore(false, function()
        KeepWorkItemManager.GetFilter():apply_filters("loading", L"加载ExtendedCost");
        KeepWorkItemManager.LoadExtendedCost(false, function()
            KeepWorkItemManager.GetFilter():apply_filters("loading", L"加载背包");
            KeepWorkItemManager.LoadBags(true, function()
                KeepWorkItemManager.GetFilter():apply_filters("loading", L"加载物品");
                KeepWorkItemManager.LoadItems(nil, function()
                    KeepWorkItemManager.GetFilter():apply_filters("loading", L"加载人物信息");
                    KeepWorkItemManager.LoadProfile(true, function()
                        KeepWorkItemManager.GetFilter():apply_filters("loading", L"加载学校信息");
                        KeepWorkItemManager.LoadSchool(true, function()

                            UserPermission.LoadUserRoles()
                            KeepWorkItemManager.LoadItemsFromStaticExId(function()
                                KeepWorkItemManager.loaded = true;
                                if(callback)then
                                    callback();
                                end  
                                KeepWorkItemManager.LoadMutingInfo(true)

                                KeepWorkItemManager.GetFilter():apply_filters("loading", L"加载完成");
                                KeepWorkItemManager.GetFilter():apply_filters("loaded_all");
                            end)
                            
                            
                        end)
                        
                    end)
                end)
            end)
        end)
    end)
end

-- create or load items from a static exid, these item are used to read/save client data in common
function KeepWorkItemManager.LoadItemsFromStaticExId(callback)
    local goals = KeepWorkItemManager.GetGoal(KeepWorkItemManager.exid_preload_items);
    local loaded = false;
    if(goals)then
        loaded = true;
        for k,v in ipairs(goals) do
            local goods = v.goods;
            for kk,vv in ipairs(goods) do
                if(vv.goods)then
                    local gsId = vv.goods.gsId;
                    local amount = vv.amount;
                    local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(gsId)
                    if(not bOwn or copies < amount)then
                        loaded = false;
                        break
                    end
                end
            end
        end
    end
    if(loaded)then
	    LOG.std(nil, "info", "KeepWorkItemManager.LoadItemsFromStaticExId ignored", KeepWorkItemManager.exid_preload_items);
        if(callback)then
            callback();
        end
        return
    end
	LOG.std(nil, "info", "KeepWorkItemManager.LoadItemsFromStaticExId", KeepWorkItemManager.exid_preload_items);
    KeepWorkItemManager.DoExtendedCost(KeepWorkItemManager.exid_preload_items,function()
        if(callback)then
            callback();
        end
    end,function()
        if(callback)then
            callback();
        end
    end)
end
function KeepWorkItemManager.LoadGlobalStore(bForced, callback)
    local cache_policy;
    if(bForced)then
        cache_policy = "access plus 0";
    end
    keepwork.globalstore.get({
        cache_policy = cache_policy,
        ["x-per-page"] = KeepWorkItemManager.page_size,
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data and data.data and data.data.rows)then
            KeepWorkItemManager.globalstore = data.data.rows;

            if(callback)then
                callback();
            end
        end
    end)
end

function KeepWorkItemManager.LoadExtendedCost(bForced, callback)
    local cache_policy;
    if(bForced)then
        cache_policy = "access plus 0";
    end
    keepwork.extendedcost.get({
        cache_policy = cache_policy,
        ["x-per-page"] = KeepWorkItemManager.page_size,
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data and data.data and data.data.rows)then
            KeepWorkItemManager.extendedcost = data.data.rows;

            if(callback)then
                callback();
            end
        end
    end)
end
--[[
{
  data={
    count=2,
    rows={
      {
        bagNo=1001,
        createdAt="2020-06-01T07:14:07.000Z",
        deleted=false,
        desc="对用户显示内容与数量的物品",
        id=4,
        name="显示物品",
        updatedAt="2020-06-01T07:14:25.000Z" 
      },
      {
        bagNo=1002,
        createdAt="2020-06-01T07:15:07.000Z",
        deleted=false,
        desc="不对用户显示的标记类物品",
        id=5,
        name="隐藏物品",
        updatedAt="2020-06-01T07:15:07.000Z" 
      } 
    } 
  },
  message="请求成功" 
}
--]]
-- NOTE: apply_filters("LoadBags_Finished") after loaded
function KeepWorkItemManager.LoadBags(bForced, callback)
    local cache_policy;
    if(bForced)then
        cache_policy = "access plus 0";
    end
    keepwork.bags.get({
        cache_policy = cache_policy,
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data and data.data and data.data.rows)then
            KeepWorkItemManager.bags = data.data.rows;

            for k,v in ipairs(KeepWorkItemManager.bags) do
                KeepWorkItemManager.bags_map[v.id] = v;
            end
            KeepWorkItemManager.GetFilter():apply_filters("LoadBags_Finished");

            if(callback)then
                callback();
            end
        end
    end)
end
-- reload item's data by gsid

-- @param {table} gsid_list
function KeepWorkItemManager.ReLoadItems(gsid_list, callback, error_callback)
    gsid_list = gsid_list or {};
    local bagNos = KeepWorkItemManager.SearchBagsNoFromGsids(gsid_list);
    KeepWorkItemManager.LoadItems(bagNos, callback, error_callback)
end
--[[
{
    "message": "璇锋眰鎴愬姛",
    "data": [
        {
            "id": 477,
            "userId": 238,
            "goodsId": 19,
            "expireTime": "9999-12-31T23:59:59.000Z",
            "clientData": null,
            "serverData": null,
            "copies": 1,
            "gsId": 10,
            "bagId": 5
        }
    ]
}
--]]
-- NOTE: apply_filters("LoadItems_Finished") after loaded
-- @param bagNos: nil to load all, "{1001,1002}" to load specific bags by bag number
function KeepWorkItemManager.LoadItems(bagNos, callback, error_callback)
    bagNos = bagNos or {};
    local len = #bagNos;
    local bagNos_str
    if(len > 0)then
        bagNos_str = "";
        for k,v in ipairs(bagNos) do
            if(bagNos_str == "")then
                bagNos_str = v;
            else
                bagNos_str = string.format("%s,%s",bagNos_str,v);
            end
        end
    end
    keepwork.items.get({
        bagNos = bagNos_str,
        cache_policy = "access plus 0", -- no cache
    },function(err, msg, data)
        if(err ~= 200)then
            if(error_callback)then
                error_callback(err, msg, data)
            end
            return
        end
        if(data and data.data)then
            local new_items = data.data;
            KeepWorkItemManager.items = KeepWorkItemManager.UnionItems(KeepWorkItemManager.items, new_items)
            KeepWorkItemManager.GetFilter():apply_filters("LoadItems_Finished");
            LOG.std(nil, 'info', 'KeepWorkItemManager.items', KeepWorkItemManager.items);
            if(callback)then
                callback();
            end
        end
    end)
end
-- union new_items to items, updated existed item and insert new item
-- @param {array} items:the items which be updated 
-- @param {array} new_items: new items
-- @return {array} items 
function KeepWorkItemManager.UnionItems(items, new_items)
    if(not items or not new_items)then
        return
    end
    local updated_items_map = {};
    for k,v in ipairs(new_items) do
        for kk,vv in ipairs(items) do
            if(v.id == vv.id)then
                -- updated item
                items[kk] = v;
                updated_items_map[v.id] = true
            end
        end    
    end
    for k,v in ipairs(new_items) do
        if(not updated_items_map[v.id])then
            -- insert item
            table.insert(items,v);
        end
    end
    return items;
end

function KeepWorkItemManager.GetMutingInfo()
    return KeepWorkItemManager.mutings;
end
function KeepWorkItemManager.LoadMutingInfo(bForced, callback)
    local cache_policy;
    if(bForced)then
        cache_policy = "access plus 0";
    end
    keepwork.user.mutings({
        cache_policy = cache_policy,
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data)then
            KeepWorkItemManager.mutings = data;
            if(callback)then
                callback(err, msg, data);
            end
        end
    end)
end
--[[
{
  channel=0,
  createdAt="2020-06-03T06:57:52.000Z",
  extra={  },
  id=763,
  nickname="zhangleio3",
  orgAdmin=0,
  roleId=0,
  student=0,
  tLevel=0,
  updatedAt="2020-06-03T06:57:52.000Z",
  username="zhangleio3",
  vip=0 
}
--]]
-- http://yapi.kp-para.cn/project/32/interface/api/492               
function KeepWorkItemManager.GetProfile()
    return KeepWorkItemManager.profile or {};
end
-- load profile of logined user
function KeepWorkItemManager.LoadProfile(bForced, callback)
    local cache_policy;
    if(bForced)then
        cache_policy = "access plus 0";
    end
    keepwork.user.profile({
        cache_policy = cache_policy,
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data)then
			if (data.extra and data.extra.ParacraftPlayerEntityInfo and data.extra.ParacraftPlayerEntityInfo.skin) then
				GameLogic.options:SetMainPlayerSkins(data.extra.ParacraftPlayerEntityInfo.skin);
			end
            KeepWorkItemManager.profile = data;
            if(callback)then
                callback(err, msg, data);
            end
        end
    end)
end

function KeepWorkItemManager.GetUserInfoExtraSkinFromDataBase(callback)
    local cache_policy = "access plus 0";
    keepwork.user.profile({
        cache_policy = cache_policy,
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end

        if(data and data.extra and data.extra.ParacraftPlayerEntityInfo and data.extra.ParacraftPlayerEntityInfo.skin)then
            if(callback)then
                local skinIds = commonlib.split(data.extra.ParacraftPlayerEntityInfo.skin, ";");
                callback(skinIds);
            else
                callback(nil)
            end;
        end
    end)
end

--[[
{
  createdAt="2020-07-19T17:49:25.000Z",
  id=273168,
  name="清华大学",
  region={
    city={ id=215, name="北京市" },
    country={ id=1, name="中国" },
    county={ id=223, name="海淀区" },
    state={ id=214, name="北京市" } 
  },
  regionId=223,
  type="大学",
  updatedAt="2020-07-19T17:49:25.000Z" 
}
]]
-- http://yapi.kp-para.cn/project/32/interface/api/2477
function KeepWorkItemManager.GetSchool()
    return KeepWorkItemManager.school or {};
end
-- load school of logined user
function KeepWorkItemManager.LoadSchool(bForced, callback)
    local cache_policy;
    if(bForced)then
        cache_policy = "access plus 0";
    end
    keepwork.user.school({
        cache_policy = cache_policy,
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data)then
            KeepWorkItemManager.school = data;
            if(callback)then
                callback(err, msg, data);
            end
        end
    end)
end

-- check if the user has the global store item in inventory
-- @param {number} gsid: global store id
-- @return bOwn, guid, bag, copies, item
function KeepWorkItemManager.HasGSItem(gsid)
    if(not gsid)then
        return
    end
    gsid = tonumber(gsid)
    if(gsid > 0)then
        for k,v in ipairs(KeepWorkItemManager.items) do
            if( v.gsId == gsid)then
                local copies = v.copies or 0;
                local bOwn = false;
                if(copies > 0)then
                    bOwn = true;
                end
                return bOwn, v.id, v.bagId, copies, v;
            end    
        end
    end
end
-- union copies in gsid_list
function KeepWorkItemManager.UnionCopies(gsid_list)
    gsid_list = gsid_list or {};
    local copies_all = 0;
    for k,v in ipairs(gsid_list) do
        local gsid = v.gsid;
		local hasItem, guid, bag, copies = KeepWorkItemManager.HasGSItem(gsid);
        copies = copies or 0;
        copies_all = copies_all + copies;
    end
    return copies_all;
end

function KeepWorkItemManager.DoExtendedCost(exid, callback, error_callback)
    if(not exid)then
        return
    end
    local profile = KeepWorkItemManager.GetProfile()
    local userId = profile.id;
	LOG.std(nil, "info", "KeepWorkItemManager.DoExtendedCost", "before DoExtendedCost userId = %s, exid = %s", tostring(userId), tostring(exid));
    keepwork.items.exchange({
        userId = userId, 
        exId = exid,
    },function(err, msg, data)
	    LOG.std(nil, "info", "KeepWorkItemManager.DoExtendedCost", "after DoExtendedCost userId = %s, exid = %s", tostring(userId), tostring(exid));
	    LOG.std(nil, "info", "KeepWorkItemManager.DoExtendedCost err", err);
	    LOG.std(nil, "info", "KeepWorkItemManager.DoExtendedCost msg", msg);
	    LOG.std(nil, "info", "KeepWorkItemManager.DoExtendedCost data", data);
        if(err == 200)then

            local bags_number = KeepWorkItemManager.SearchBagsNoFromExid(exid);
            local len = #bags_number;
            if(len > 0)then
                -- reload items data 
                KeepWorkItemManager.LoadItems(bags_number,callback, error_callback)
                return
            end
            if(callback)then
                callback();
            end
        else
            if(error_callback)then
                error_callback(err, msg, data);
            end
        end
    end)
end

function KeepWorkItemManager.CheckExchange(exid, callback, error_callback)
	if (not exid) then
		return
	end
    local profile = KeepWorkItemManager.GetProfile()
    local userId = profile.id;
    keepwork.items.checkExchange({
        userId = userId, 
        exId = exid,
    },function(err, msg, data)
        if(err == 200)then
            if(callback)then
                callback(data);
            end
        else
            if(error_callback)then
                error_callback(err, msg, data);
            end
        end
    end)
end

function KeepWorkItemManager.GetClientData(gsid)
    local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(gsid)
    if(not item)then
        return
    end
    return item.clientData;
end
function KeepWorkItemManager.SetClientData(gsid, clientData, callback, error_callback)
    local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(gsid)
    if(not bOwn)then
        return
    end
    clientData = clientData or {};
	LOG.std(nil, "info", "KeepWorkItemManager.setClientData", "before setClientData userGoodsId = %s", tostring(guid));
	LOG.std(nil, "info", "KeepWorkItemManager.setClientData clientData", clientData);
    keepwork.items.setClientData({
        userGoodsId = guid,
        clientData = clientData,
    },function(err, msg, data)
	    LOG.std(nil, "info", "KeepWorkItemManager.setClientData", "after setClientData userGoodsId = %s", tostring(guid));
        LOG.std(nil, "info", "KeepWorkItemManager.setClientData err", err);
	    LOG.std(nil, "info", "KeepWorkItemManager.setClientData msg", msg);
	    LOG.std(nil, "info", "KeepWorkItemManager.setClientData data", data);
        if(err == 200)then
            --synchronize data to memory 
            item.clientData = clientData;
            if(callback)then
                callback();
            end
        else
            if(error_callback)then
                error_callback(err, msg, data);
            end
        end
    end)
end
-- search bag number by gsid
-- @param {table} gsid_list
-- @return bags_id
function KeepWorkItemManager.SearchBagsNoFromGsids(gsid_list)
    if(not gsid_list)then
        return
    end
    local bags_id = {};
    local bags_id_map = {};
    for k,v in ipairs(gsid_list) do
        local template = KeepWorkItemManager.GetItemTemplate(v);
        if(template)then
            local bagId = template.bagId;
            local bagNo = KeepWorkItemManager.SearchBagNo(bagId)
            if(not bags_id_map[bagNo])then
                bags_id_map[bagNo] = true;
                table.insert(bags_id,bagNo);
            end
        end
    end
    return bags_id;
end
-- search all bag number in a extendedcost for update item data
-- NOTE: bagNo isn't bagId
function KeepWorkItemManager.SearchBagsNoFromExid(exid)
    if(not exid)then
        return
    end
    local bags_id = {};
    local bags_id_map = {};
    local function read_ids(data)
        if(data)then
            for k,v in ipairs(data) do
                if(v.goods and v.goods.bagId)then
                    local bagId = v.goods.bagId;
                    local bagNo = KeepWorkItemManager.SearchBagNo(bagId)
                    bags_id_map[bagNo] = bagNo;
                end
            end 
        end
    end
    local precondition,cost,goal = KeepWorkItemManager.GetConditions(exid);
    read_ids(precondition)
    read_ids(cost)
    if(goal)then
        for k,v in ipairs(goal) do
            read_ids(v.goods)
        end
    end
    for k,v in pairs(bags_id_map) do
        table.insert(bags_id,v);
    end
    return bags_id;
end
function KeepWorkItemManager.SearchBagNo(bagId)
    if(not bagId)then
        return
    end
    local bag = KeepWorkItemManager.bags_map[bagId];
    if(bag)then
        return bag.bagNo; 
    end
end
-- get userinfo
-- if input = nil, or input.username = nil, getting login user info
-- @param input
-- @param input.username
-- @param input.cache_policy
function KeepWorkItemManager.GetUserInfo(input,callback)
    input = input or {};
    local username = input.username;
    local cache_policy = input.cache_policy;
    if(not username or username == commonlib.getfield("System.User.username"))then
        KeepWorkItemManager.LoadProfile(false, callback)
        return
    end
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
    -- this request is by router path
    keepwork.user.getinfo({
        cache_policy = cache_policy,
        router_params = {
            id = id,
        }
    },function(err, msg, data)
        if(callback)then
            callback(err, msg, data);
        end
    end)
end
function KeepWorkItemManager.GetUserTag(user_info)
    if(not user_info)then
        return
    end
    local tag;
    local vip = user_info.vip;
    local tLevel = user_info.tLevel;
    local student = user_info.student;
    local orgAdmin = user_info.orgAdmin;
    if(tLevel == 1)then
        if(vip == 1)then
            tag = "VT";
        else
            tag = "T";
        end
    elseif(student == 1 or orgAdmin == 1)then
        if(vip == 1)then
            tag = "V";
        end
    else
        if(vip == 1)then
            tag = "V";
        end
    end
    return tag;
end

function KeepWorkItemManager.GetItemTemplateById(id)
    if nil == KeepWorkItemManager.globalstore then
        return nil
    end
    
    for k,v in pairs(KeepWorkItemManager.globalstore) do
        if id == v.id then
            return v
        end
    end
end
function KeepWorkItemManager.IsVip()
	local gsid = 10;
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(gsid)
	return (copies and copies > 0) or (System and System.User and System.User.isVip);
end

-- 是否为机构会员
function KeepWorkItemManager.IsOrgVip()
	local profile = KeepWorkItemManager.GetProfile();
    return (profile.student == 1) or (profile.orgAdmin == 1) or (profile.tLevel == 1)
end

-- 是否为机构学生会员
function KeepWorkItemManager.IsOrgStudentVip()
	local profile = KeepWorkItemManager.GetProfile();
    return (profile.student == 1);
end