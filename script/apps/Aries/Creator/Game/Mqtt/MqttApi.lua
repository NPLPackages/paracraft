--[[
Title: mqtt api
Author(s): pbb
Date: 2023/12/29
Desc: 
Use Lib:
-------------------------------------------------------
local MqttApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttApi.lua")
-------------------------------------------------------
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");


local MqttApi = NPL.export()

function MqttApi.InitMqttApi()
    if not MqttApi.InitApi then

        --mqtt连接鉴权
        --http://yapi.kp-para.cn/project/32/interface/api/7733
        --[[
            名称	     类型	是否必须
            appid	    string	必须
            username	string	必须
            password	string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.connectAuth", "%MAIN%/core/v0/mqtt/emqx/auth", "POST", true)


        --mqtt主题鉴权
        --http://yapi.kp-para.cn/project/32/interface/api/7739
        --[[
            名称	     类型	是否必须
            clientid    string	必须
            username	string	必须
            topic	    string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.topicAuth", "%MAIN%/core/v0/mqtt/emqx/acl", "POST", true)

        --mqtt创建项目
        --http://yapi.kp-para.cn/project/32/interface/api/7745
        --[[
            名称	     类型	是否必须
            name        string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.createProject", "%MAIN%/core/v0/iotProjects", "POST", true)

        --mqtt修改项目
        --http://yapi.kp-para.cn/project/32/interface/api/7751
        --[[路径 参数名称	     类型	是否必须
                id          string	必须
        ]]
        --[[
            名称	     类型	是否必须
            name        string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.updateProject", "%MAIN%/core/v0/iotProjects/:id", "PUT", true)

        --mqtt删除项目
        --http://yapi.kp-para.cn/project/32/interface/api/7757
        --[[路径 参数名称	     类型	是否必须
                id          string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.deleteProject", "%MAIN%/core/v0/iotProjects/:id", "DELETE", true)

        --mqtt查看项目
        --http://yapi.kp-para.cn/project/32/interface/api/7763
        --[[
            名称	     类型	是否必须
            name        string	否
        ]]
        HttpWrapper.Create("keepwork.mqtt.getProjects", "%MAIN%/core/v0/iotProjects", "GET", true)

        --新建主题
        --http://yapi.kp-para.cn/project/32/interface/api/7769
        --[[
            名称	             类型	是否必须
            iotProjectId        number	必须
            desc                string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.createTopic", "%MAIN%/core/v0/iotTopics", "POST", true)

        --修改主题
        --http://yapi.kp-para.cn/project/32/interface/api/7775
        --[[路径 参数名称	     类型	是否必须
                id          string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.updateTopic", "%MAIN%/core/v0/iotTopics/:id", "PUT", true)

        --删除主题
        --http://yapi.kp-para.cn/project/32/interface/api/7781
        --[[路径 参数名称	     类型	是否必须
                id          string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.deleteTopic", "%MAIN%/core/v0/iotTopics/:id", "DELETE", true)

        --查看主题
        --http://yapi.kp-para.cn/project/32/interface/api/7787
        --[[
            名称	             类型	是否必须
            iotProjectId        number	必须
        ]] 
        HttpWrapper.Create("keepwork.mqtt.getTopics", "%MAIN%/core/v0/iotTopics", "GET", true)        

        --清空主题
        --http://yapi.kp-para.cn/project/32/interface/api/7793
        --[[路径 参数名称	     类型	是否必须
                id          string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.clearTopic", "%MAIN%/core/v0/iotTopics/:id/messages", "DELETE", true)

        --查看主题数据
        --http://yapi.kp-para.cn/project/32/interface/api/7799
        --[[路径 参数名称	     类型	是否必须
                id          string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.getTopicData", "%MAIN%/core/v0/iotTopics/:id/messages", "GET", true)

        --新建设备
        --http://yapi.kp-para.cn/project/32/interface/api/7805
        --[[
            名称	             类型	是否必须
            iotProjectId        number	必须
            desc                string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.createDevice", "%MAIN%/core/v0/iotDevices", "POST", true)

        --删除设备
        --http://yapi.kp-para.cn/project/32/interface/api/7811
        --[[路径 参数名称	     类型	是否必须
                id          string	必须
        ]]
        HttpWrapper.Create("keepwork.mqtt.deleteDevice", "%MAIN%/core/v0/iotDevices/:id", "DELETE", true)

        --查看设备
        --http://yapi.kp-para.cn/project/32/interface/api/7817
        HttpWrapper.Create("keepwork.mqtt.getDevices", "%MAIN%/core/v0/iotDevices", "GET", true)

        MqttApi.InitApi = true
    end
end

function MqttApi.ConnectAuth(params, callback)
    keepwork.mqtt.connectAuth(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.TopicAuth(params, callback)
    keepwork.mqtt.topicAuth(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.CreateProject(params, callback)
    keepwork.mqtt.createProject(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.UpdateProject(params, callback)
    keepwork.mqtt.updateProject(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.DeleteProject(params, callback)
    keepwork.mqtt.deleteProject(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.GetProjects(params, callback)
    keepwork.mqtt.getProjects(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.CreateTopic(params, callback)
    keepwork.mqtt.createTopic(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.DeleteTopic(params, callback)
    keepwork.mqtt.deleteTopic(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.UpdateTopic(params, callback)
    keepwork.mqtt.updateTopic(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.GetTopics(params, callback)
    keepwork.mqtt.getTopics(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.ClearTopic(params, callback)
    keepwork.mqtt.clearTopic(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.GetTopicData(params, callback)
    keepwork.mqtt.getTopicData(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.CreateDevice(params, callback)
    keepwork.mqtt.createDevice(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.DeleteDevice(params, callback)
    keepwork.mqtt.deleteDevice(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

function MqttApi.GetDevices(params, callback)
    keepwork.mqtt.getDevices(params, function(err,msg,data)
        if callback and type(callback) == "function" then
            callback(err,data)
        end    
    end)
end

MqttApi.InitMqttApi()