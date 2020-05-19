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
KeepWorkItemManager.Load(function()
    commonlib.echo("=====KeepWorkItemManager.globalstore");
    commonlib.echo(KeepWorkItemManager.globalstore);
    commonlib.echo("=====KeepWorkItemManager.extendedcost");
    commonlib.echo(KeepWorkItemManager.extendedcost);
    commonlib.echo("=====KeepWorkItemManager.bags");
    commonlib.echo(KeepWorkItemManager.bags);
    commonlib.echo("=====KeepWorkItemManager.items");
    commonlib.echo(KeepWorkItemManager.items);
end)
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkAPI.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local KeepWorkItemManager = NPL.export()

KeepWorkItemManager.globalstore = {};
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
	GameLogic.GetFilters():add_filter("OnKeepWorkLogin", function(res)
        if(res)then
            KeepWorkItemManager.Load(function()
                commonlib.echo("=====KeepWorkItemManager.globalstore");
                commonlib.echo(KeepWorkItemManager.globalstore);
                commonlib.echo("=====KeepWorkItemManager.extendedcost");
                commonlib.echo(KeepWorkItemManager.extendedcost);
                commonlib.echo("=====KeepWorkItemManager.bags");
                commonlib.echo(KeepWorkItemManager.bags);
                commonlib.echo("=====KeepWorkItemManager.items");
                commonlib.echo(KeepWorkItemManager.items);
            end)            
        end
    end);
	GameLogic.GetFilters():add_filter("OnKeepWorkLogout", function(res)
        KeepWorkItemManager.Clear();
    end)
end
function KeepWorkItemManager.Clear()
    KeepWorkItemManager.globalstore = {};
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
function KeepWorkItemManager.GetItemTemplate(gsid)
    gsid = tonumber(gsid)
    for k,v in ipairs(KeepWorkItemManager.globalstore) do
        if( v.gsId == gsid)then
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
function KeepWorkItemManager.Load(callback)
    if(KeepWorkItemManager.IsLoaded())then
        if(callback)then
            callback();
        end            
        return
    end
    if(LOG.level ~= "debug")then
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
