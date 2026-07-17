--[[
Title: MallApi
Author(s): pbb
Date: 2023/12/4
Desc: paracraft mall api
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallApi.lua");
local MallApi = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallApi");
-------------------------------------------------------
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");


local cache_1year_policy = System.localserver.CachePolicy:new("access plus 1 year");
local cache_1month_policy = System.localserver.CachePolicy:new("access plus 1 month");
local cache_1day_policy = System.localserver.CachePolicy:new("access plus 1 day");
local cache_1hour_policy = System.localserver.CachePolicy:new("access plus 1 hour");
local cache_1min_policy = System.localserver.CachePolicy:new("access plus 1 minutes");

local MallApi = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallApi"));

function MallApi:ctor()

end

function MallApi.getInstance()
	if not MallApi.sInstance then
		MallApi.sInstance = MallApi:new();
	end
	
	return MallApi.sInstance;
end

function MallApi:LoadMallMenuList(callbackFunc)
	keepwork.mall.menus.get({
        platform = 1, 
    },function(err,msg,data)
        if type(callbackFunc) == "function" then
            callbackFunc(err,data);
        end
    end)
end

function MallApi:LoadMallColletIdList(callbackFunc)
	keepwork.mall.getstarIds({},function(err,msg,data)
        if type(callbackFunc) == "function" then
            callbackFunc(err,data);
        end
    end)
end

function MallApi:LoadMallCollectList(page,sortName,sortType,keyword,callbackFunc)
    print("MallApi===============",page)
    local x_order = ""
    if sortName and sortName ~= "" and sortType and sortType ~= "" then
        x_order = sortName.. "-".. sortType
    end

    local params = {
        ["x-order"] = x_order,
        ["x-per-page"] = 40,
        ["x-page"] = page or 1,
    }
    if keyword and keyword ~= "" then
        params.q = keyword
    end
    echo(params,true)
    keepwork.mall.starlist(params,function(err,msg,data)
        print("LoadMallCollectList ----err===============",err)
        
        if type(callbackFunc) == "function" then
            callbackFunc(err,data);
        end
    end)
end

function MallApi:CollectMallGoods(goodsId,callbackFunc)
    keepwork.mall.star({
        mProductId = goodsId
    },function(err,msg,data)
        if type(callbackFunc) == "function" then
            callbackFunc(err,data);
        end
    end)
end

function MallApi:UnCollectMallGoods(goodsId,callbackFunc)
    keepwork.mall.unstar({
        router_params = {mProductId = goodsId},
    },function(err,msg,data)
        if type(callbackFunc) == "function" then
            callbackFunc(err,data);
        end
    end)
end


function MallApi:LoadMineModelList(curpage,sortName,sortOrder,keyword,callbackFunc)
    print("LoadMineModelList curpage==========",curpage,sortName,sortOrder,keyword)
    
    if sortName and sortName:find("name") then
        sortName = "namePinyin"
    end
    local x_order = ""
    if sortName and sortName ~= "" and sortOrder and sortOrder ~= "" then
        x_order = sortName.. "-".. sortOrder
    end
    local params = {
        ["x-order"] = x_order,
        ["x-per-page"] = 40,
        ["x-page"] = curpage or 1,
    }
    if keyword and keyword ~= "" then
        params.name = keyword
    end
    echo(params)
    print("LoadMineModelList==============================")
    keepwork.mall.modelList(params,function(err,msg,data)
        -- print("err====================",err)
        -- echo(data)
        if type(callbackFunc) == "function" then
            callbackFunc(err,data);
        end
    end)
end

function MallApi:AddMineModel(model_name,model_type,model_size,model_url,callbackFunc)
    if model_name == nil or model_type == nil or model_size == nil or model_url == nil then
        return;
    end
    keepwork.mall.addModel({
        name = model_name,	
        modelUrl = model_url,
        size = model_size,
        modelType = model_type,
    },function(err,msg,data)
        if type(callbackFunc) == "function" then
            callbackFunc(err,data);
        end
    end)
end

function MallApi:DeleteModel(model_id,callbackFunc)
    if type(model_id) ~= "number" then
        return;
    end
    keepwork.mall.deleteModel({
        router_params = {id = model_id},
    },function(err,msg,data)
        if type(callbackFunc) == "function" then
            callbackFunc(err,data);
        end
    end)
end

function MallApi:UpdateModel(model_id,model_name,callbackFunc)
    if type(model_id) ~= "number" or type(model_name) ~= "string" then
        return;
    end
    keepwork.mall.updateModel({
        router_params = {id = model_id},
        name = model_name,
    },function(err,msg,data)
        if callbackFunc then
            callbackFunc(err,data);
        end
    end)
end

function MallApi:UpdateModelUrl(model_id,model_url,callbackFunc)
    if type(model_id) ~= "number" or type(model_url) ~= "string" then
        return;

    end
    keepwork.mall.updateModel({
        router_params = {id = model_id},
        modelUrl = model_url,
    },function(err,msg,data)
        if callbackFunc then
            callbackFunc(err,data);
        end
    end)
end

