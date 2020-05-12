--[[
Title: KeepWorkItemManager
Author(s): leio
Date: 2020/4/24
Desc:  
use the lib:
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

local KeepWorkItemManager = NPL.export()

KeepWorkItemManager.globalstore = {};
KeepWorkItemManager.extendedcost = {};
KeepWorkItemManager.bags = {};
KeepWorkItemManager.items = {};
KeepWorkItemManager.loaded = false;

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
    KeepWorkItemManager.LoadGlobalStore(true, function()
        KeepWorkItemManager.LoadExtendedCost(true, function()
            KeepWorkItemManager.LoadBags(true, function()
                KeepWorkItemManager.LoadItems(true, function()
                    KeepWorkItemManager.loaded = true;
                    if(callback)then
                        callback();
                    end            
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
