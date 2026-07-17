--[[
    Desc: mqtt manager
    Last Modified: 2024-01-2 10:56
    Modified By: pbb
    Version: 1.0
    Company: palaka
    Use Lib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
        local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
        MqttManager:StaticInit()

]]
local MqttApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttApi.lua")
local MqttManager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager"));
local perPage = 20
function MqttManager:ctor()
    self:RegisterEvent()
end

function MqttManager:StaticInit()
    MqttManager.getInstance()
end

function MqttManager:RegisterEvent()
    GameLogic:Disconnect("WorldLoaded", MqttManager, MqttManager.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldLoaded", MqttManager, MqttManager.OnWorldLoaded, "UniqueConnection");

    GameLogic:Disconnect("WorldUnloaded", MqttManager, MqttManager.OnWorldUnload, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", MqttManager, MqttManager.OnWorldUnload, "UniqueConnection");
end

function MqttManager.OnWorldLoaded()
    local self = MqttManager.getInstance()
    self.world_loaded = true
    self.is_mqtt_connected = false
    self.is_manual_closed = false
    self.mqttSubscribes = {} --订阅列表数据
    self:StartMqttListener()
end

function MqttManager.OnWorldUnload()
    local self = MqttManager.getInstance()
    self.world_loaded = false
    self.is_mqtt_connected = false
    self.is_manual_closed = true
    self.is_net_connected = nil
    self.mqttSubscribes = {}
    self:StopMqttListener()
end

function MqttManager:StartMqttListener()
    if not self.world_loaded then
        return
    end
    GameLogic.GetFilters():remove_filter("beforeMqttClosed",  MqttManager.OnBeforeMqttClientClosed);
    GameLogic.GetFilters():add_filter("beforeMqttClosed",  MqttManager.OnBeforeMqttClientClosed);

    GameLogic.GetFilters():remove_filter("mqttClosed",  MqttManager.OnMqttClientClosed);
    GameLogic.GetFilters():add_filter("mqttClosed",  MqttManager.OnMqttClientClosed);

    GameLogic.GetFilters():remove_filter("mqttConnected",  MqttManager.OnMqttClientConnected);
    GameLogic.GetFilters():add_filter("mqttConnected",  MqttManager.OnMqttClientConnected);

    --mqttSubscribed
    GameLogic.GetFilters():remove_filter("mqttSubscribed",  MqttManager.OnMqttClientSubscribed);
    GameLogic.GetFilters():add_filter("mqttSubscribed",  MqttManager.OnMqttClientSubscribed);

    GameLogic.GetFilters():remove_filter("net_status",  MqttManager.OnNetStatus);
    GameLogic.GetFilters():add_filter("net_status", MqttManager.OnNetStatus);
end

function MqttManager.OnMqttClientSubscribed(subscribeParams,mqttClient)
    local self = MqttManager.getInstance()
    if not subscribeParams or type(subscribeParams) ~= "table" then
        return
    end
    if not self.HasSubscribed(subscribeParams) then
        table.insert(self.mqttSubscribes, subscribeParams)
    end
end

function MqttManager.HasSubscribed(params)
    local self = MqttManager.getInstance()
    for i,v in ipairs(self.mqttSubscribes) do
        if v.topic == params.topic and v.qos == params.qos then
            return true
        end
    end
    return false
end

function MqttManager.ReSubscribeAll()
    local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
    if not mqttClient  then
        LOG.std(nil,"warn","MqttManager","mqtt client is nil")
        return
    end
    local self = MqttManager.getInstance()
    if not self.mqttSubscribes or #self.mqttSubscribes == 0 then
        return
    end
    echo(self.mqttSubscribes)
    for i,v in ipairs(self.mqttSubscribes) do
        mqttClient:subscribe(v)
    end
end

function MqttManager.OnNetStatus(msg)
    local self = MqttManager.getInstance()
    if msg and msg.status == "closed" then
        if Game.is_started then
            GameLogic.AddBBS(nil,"网络已断开",3000,"255 0 0")
        end
        self.is_net_connected = false
    end
    if msg and msg.status == "connected" then
        if self.is_net_connected == nil or self.is_net_connected == true then --初次进入或者重启世界
            return
        end
        if Game.is_started then
            GameLogic.AddBBS(nil,"网络已连接",3000,"0 255 0")
        end
        self.is_net_connected = true
        _guihelper.CloseMessageBox()
        commonlib.TimerManager.SetTimeout(function()
            self:ReconnectMqtt()
        end, 1000)
        
    end
    return msg
end

function MqttManager.OnBeforeMqttClientClosed(mqttClient)
    local self = MqttManager.getInstance()
    self.is_manual_closed = true
    self.mqttSubscribes = {}
end

function MqttManager.OnMqttClientClosed(result,mqtt_client)
    local self = MqttManager.getInstance()
    print("OnMqttClientClosed================")
    if not self.is_mqtt_connected then
        LOG.std(nil,"info","MqttManager","mqtt client connect error")
        return
    end
    local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
    print("xxxxxxxxxxxxxxxxxxxxx",mqttClient,mqtt_client)
    if self.is_manual_closed then
        LOG.std(nil,"info","MqttManager","mqtt client closed when closeed the code block")
        return
    end
    GameLogic.AddBBS("mqtt", "连接到MQTT服务器已断开", 3000, "255 0 0")
    LOG.std(nil,"info","MqttManager","mqtt client closed")
    self:ShowMqttReconnectDialog()
end

function MqttManager:ShowMqttReconnectDialog(msg)
    local tipStr = (msg and msg ~= "") and msg or "Mqtt服务已断开，是否重连？"
	_guihelper.MessageBox(tipStr,function(res)
        if res and res == _guihelper.DialogResult.Yes then
            self:CheckCanReconnect(function(reconnect)
                if reconnect then
                    local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
                    KpChatChannel.TryToConnect()
                else
                    self:ShowMqttReconnectDialog(L"Mqtt服务重连失败，是否重试。")
                end
            end)
        else
            GameLogic.AddBBS("mqtt", "重连到MQTT服务器已取消", 3000, "255 0 0")
        end
    end,
    _guihelper.MessageBoxButtons.YesNo,nil,nil,nil,nil,{ ok = L"确定", cancel = L"取消", title = L"mqtt服务连接提示", }
	)
end

function MqttManager:CheckCanReconnect(callback)
    local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
    if not mqttClient then
        print("MqttManager:CheckCanReconnect mqttClient is nil")
    end
    keepwork.app.availableHost({},function(err, msg, data)
        if(err == 200 and data)then
            if callback and type(callback) == "function" then
                callback(true) 
            end
        else
            if callback and type(callback) == "function" then
                callback(false) 
            end
            LOG.std(nil, "warn", "MqttManager.CheckCanReconnect err code", err);
            LOG.std(nil, "warn", "MqttManager.CheckCanReconnect msg", msg);
            LOG.std(nil, "warn", "MqttManager.CheckCanReconnect data", data);
        end
    end)
end

function MqttManager:ReconnectMqtt()
    if not self.is_mqtt_connected or self.is_manual_closed then
        return
    end
    local mqttClient = GameLogic.GetCodeGlobal():GetGlobal("mqtt")
    print("MqttManager:ReconnectMqtt======================",mqttClient)
    if mqttClient then
        GameLogic.AddBBS(nil,"mqtt服务重新连接中...",3000,"0 255 0")
        mqttClient:start_connecting(function(bConnected)
            if bConnected then
                LOG.std(nil, "info", "MqttManager", "reconnected to %s", mqttClient.args.uri or "")
                MqttManager.ReSubscribeAll()
            else
                LOG.std(nil, "info", "MqttManager", "reconnect failed to %s", mqttClient.args.uri or "")
            end
        end)
    end
end

function MqttManager.OnMqttClientConnected(result,mqttClient)
    print("OnMqttClientConnected====================")
    local self = MqttManager.getInstance()
    self.is_mqtt_connected = true
    self.is_manual_closed = false
    return result,mqttClient
end

function MqttManager:StopMqttListener()
    GameLogic.GetFilters():remove_filter("mqttConnected",  MqttManager.OnMqttClientConnected);
    GameLogic.GetFilters():remove_filter("beforeMqttClosed",  MqttManager.OnBeforeMqttClientClosed);
    GameLogic.GetFilters():remove_filter("mqttClosed",  MqttManager.OnMqttClientClosed);
end

function MqttManager.getInstance()
	if not MqttManager.sInstance then
		MqttManager.sInstance = MqttManager:new();
	end
	return MqttManager.sInstance;
end

function MqttManager:AddProject(name,callback)
    MqttApi.CreateProject({
        name = name
    }, function(err,data)
        self:PrintApiInfo("AddProject",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:LoadProjectList(callback)
    MqttApi.GetProjects({}, function(err,data)
        self:PrintApiInfo("LoadProjectList",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:DeleteProject(id,callback)
    MqttApi.DeleteProject({
        router_params = {id = id},
    }, function(err,data)
        self:PrintApiInfo("DeleteProject",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:UpdateProject(id,name,callback)
    MqttApi.UpdateProject({
        router_params = {id = id},
        name = name
    }, function(err,data)
        self:PrintApiInfo("UpdateProject",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:LoadTopicList(curPage,iotProjectId,callback)
    MqttApi.GetTopics({
        ["x-per-page"] = perPage,
		["x-page"] = curPage or 1,
        iotProjectId = iotProjectId,
    }, function(err,data)
        self:PrintApiInfo("LoadTopicList",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:AddTopic(iotProjectId,desc,callback)
    MqttApi.CreateTopic({
        iotProjectId = iotProjectId,
        desc = desc
    }, function(err,data)
        self:PrintApiInfo("AddTopic",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:DeleteTopic(topicId,callback)
    MqttApi.DeleteTopic({
        router_params = {id = topicId},
    }, function(err,data)
        self:PrintApiInfo("DeleteTopic",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:UpdateTopic(topicId,desc,callback)
    MqttApi.UpdateTopic({
        router_params = {id = topicId},
        desc = desc
    }, function(err,data)
        self:PrintApiInfo("UpdateTopic",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:ClearTopic(topicId,callback)
    MqttApi.ClearTopic({
        router_params = {id = topicId},
    }, function(err,data)
        self:PrintApiInfo("ClearTopic",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

--device
function MqttManager:LoadDeviceList(curPage,iotProjectId,callback)
    MqttApi.GetDevices({
        ["x-per-page"] = perPage,
		["x-page"] = curPage or 1,
        iotProjectId = iotProjectId,
    }, function(err,data)
        self:PrintApiInfo("LoadDeviceList",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:AddDevice(iotProjectId,name,callback)
    print("AddDevice===========",iotProjectId,name)
    MqttApi.CreateDevice({
        iotProjectId = iotProjectId,
        desc = name
    }, function(err,data)
        self:PrintApiInfo("AddDevice",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:DeleteDevice(deviceId,callback)
    MqttApi.DeleteDevice({
        router_params = {id = deviceId},
    }, function(err,data)
        self:PrintApiInfo("DeleteDevice",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:LoadTopicDataList(topicId,callback)
    MqttApi.GetTopicData({
        router_params = {id = topicId},
    }, function(err,data)
        self:PrintApiInfo("LoadTopicDataList",err,data)
        if err == 200 then
            if callback then
                callback(true,data)
            end
            return
        end
        if callback then
            callback(false)
        end
    end)
end

function MqttManager:PrintApiInfo(name,err,data)
    if not System.options.isDevMode then
        return
    end
    print("PrintApiInfo=====",(name or ""))
    print("PrintApiInfo1=========",err)
    echo(data,true)
end

--Mqtt客户端重连逻辑
function MqttManager:MqttReconnect()

end