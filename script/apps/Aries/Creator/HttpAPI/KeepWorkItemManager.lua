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
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkAPI.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local KeepWorkItemManager = NPL.export()

KeepWorkItemManager.globalstore_map = {};
KeepWorkItemManager.globalstore = {};
KeepWorkItemManager.extendedcost_map = {};
KeepWorkItemManager.extendedcost = {};
KeepWorkItemManager.bags = {};
KeepWorkItemManager.items = {};
KeepWorkItemManager.profile = {};
KeepWorkItemManager.loaded = false;

function KeepWorkItemManager.IsEnabled()
    local kpitem_enabled = ParaEngine.GetAppCommandLineByParam("kpitem_enabled", false);
    return kpitem_enabled;
end

function KeepWorkItemManager.StaticInit()
    if(not KeepWorkItemManager.IsEnabled())then
        return
    end
	LOG.std(nil, "info", "KeepWorkItemManager", "StaticInit");

    GameLogic.GetFilters():remove_filter("OnKeepWorkLogin", KeepWorkItemManager.OnKeepWorkLogin_Callback);
    GameLogic.GetFilters():remove_filter("OnKeepWorkLogout", KeepWorkItemManager.OnKeepWorkLogout_Callback);
    GameLogic.GetFilters():add_filter("OnKeepWorkLogin", KeepWorkItemManager.OnKeepWorkLogin_Callback);
	GameLogic.GetFilters():add_filter("OnKeepWorkLogout", KeepWorkItemManager.OnKeepWorkLogout_Callback)
end
function KeepWorkItemManager.OnKeepWorkLogin_Callback(res)
	LOG.std(nil, "info", "KeepWorkItemManager", "OnKeepWorkLogin_Callback");
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
    return res;
end
function KeepWorkItemManager.OnKeepWorkLogout_Callback(res)
	LOG.std(nil, "info", "KeepWorkItemManager", "OnKeepWorkLogout_Callback");
    KeepWorkItemManager.Clear();
    return res;
end

function KeepWorkItemManager.Clear()
    KeepWorkItemManager.globalstore_map = {};
    KeepWorkItemManager.globalstore = {};
    KeepWorkItemManager.extendedcost_map = {};
    KeepWorkItemManager.extendedcost = {};
    KeepWorkItemManager.bags = {};
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
        name="祖宗物品",
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
        if( v.goodsId == guid)then
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
    KeepWorkItemManager.LoadGlobalStore(true, function()
        KeepWorkItemManager.LoadExtendedCost(true, function()
            KeepWorkItemManager.LoadBags(true, function()
                KeepWorkItemManager.LoadItems(true, function()
                    KeepWorkItemManager.LoadProfile(true, function()
                        KeepWorkItemManager.loaded = true;
                        if(callback)then
                            callback();
                        end            
                    end)
                end)
            end)
        end)
    end)
end
function KeepWorkItemManager.LoadGlobalStore(bForced, callback)
    local cache_policy;
    if(bForced)then
        cache_policy = "access plus 0";
    end
    keepwork.globalstore.get({
        cache_policy = "access plus 0";
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

            if(callback)then
                callback();
            end
        end
    end)
end
function KeepWorkItemManager.LoadItems(bForced, callback)
    local cache_policy;
    if(bForced)then
        cache_policy = "access plus 0";
    end
    keepwork.items.get({
        cache_policy = cache_policy,
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data and data.data and data.data.rows)then
            KeepWorkItemManager.items = data.data.rows;

            if(callback)then
                callback();
            end
        end
    end)
end
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
            KeepWorkItemManager.profile = data;
            if(callback)then
                callback();
            end
        end
    end)
end
-- @param bag: only check the bag
-- @param excludebag: 
-- @return bOwn, guid, bag, copies: if own the gs item, and the guid, bag and copies of the item if own
-- check if the user has the global store item in inventory
function KeepWorkItemManager.HasGSItem(gsid, bag, excludebag)
    if(not gsid)then
        return
    end

    gsid = tonumber(gsid)
    
    if(gsid > 0)then
        for k,v in ipairs(KeepWorkItemManager.items) do
            if( v.gsId == gsid)then
                return true, v.goodsId, v.bagId, v.amount;
            end    
        end
    end
end
