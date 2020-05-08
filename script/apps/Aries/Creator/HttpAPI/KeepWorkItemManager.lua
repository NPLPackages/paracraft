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
KeepWorkItemManager.Init(function()
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
function KeepWorkItemManager.Init(callback)
    KeepWorkItemManager.LoadGlobalStore(function()
        KeepWorkItemManager.LoadExtendedCost(function()
            KeepWorkItemManager.LoadBags(function()
                KeepWorkItemManager.LoadItems(function()
                    KeepWorkItemManager.loaded = true;
                    if(callback)then
                        callback();
                    end            
                end)
            end)
        end)
    end)
end
function KeepWorkItemManager.LoadGlobalStore(callback)
    keepwork.globalstore.get({},function(err, msg, data)
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
function KeepWorkItemManager.LoadExtendedCost(callback)
    keepwork.extendedcost.get({},function(err, msg, data)
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
function KeepWorkItemManager.LoadBags(callback)
    keepwork.bags.get({},function(err, msg, data)
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
function KeepWorkItemManager.LoadItems(callback)
    keepwork.items.get({},function(err, msg, data)
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
