--[[
Title: UrlConverter
Author(s): leio
Date: 2020/7/15
Desc:  
Use Lib:
-------------------------------------------------------
local UrlConverter = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/UrlConverter.lua");
local raw_url = "http://yapi.kp-para.cn/mock/32/users/:id/detail/:name";
local input_params = {
    id = 1,
    id2 = 2,
    name = "name",
};
UrlConverter.ToPath(raw_url,input_params);
]]
local UrlConverter = NPL.export();

function UrlConverter.ToPath(raw_url,input_params)
    if(not raw_url or not input_params)then
        return
    end
    for k,v in pairs(input_params) do
        local key = string.format(":%s",k);
        if(string.find(raw_url,key))then
            raw_url = string.gsub(raw_url,key,tostring(v));
        end
    end
    return raw_url
end