--[[
Title: mqtt page
Author: pbb
CreateDate: 2024.1.2
Desc: 
use the lib:
------------------------------------------------------------
local MqttDetailPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttDetailPage.lua')
MqttDetailPage.ShowPage(data)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");
local MqttDetailPage = NPL.export()
local page

MqttDetailPage.mqttProjectData = nil
MqttDetailPage.mqttTopicList = {}
MqttDetailPage.mqttDeviceList = {}
MqttDetailPage.curTopicPage = 1
MqttDetailPage.curTopicPageCount = 0
MqttDetailPage.curDevicePageCount = 0
MqttDetailPage.curDevicePage = 1
MqttDetailPage.menuConfig = {
    {name="topic",title=L"主题管理"},
    {name="device",title=L"设备管理"}
}
MqttDetailPage.select_tab_index = -1
function MqttDetailPage.OnInit()
    page = document:GetPageCtrl()
end

function MqttDetailPage.ShowPage(data)
    if not data then
        return
    end
    MqttDetailPage.mqttProjectData = data
    MqttDetailPage.ShowView()
end

function MqttDetailPage.ShowView()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Mqtt/MqttDetailPage.html",
        name = "MqttDetailPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        align = "_fi",
        x = -view_width/2,
        y = -view_height/2,
        width = view_width,
        height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    params._page.OnClose = function()
        MqttDetailPage.mqttProjectData = nil
        MqttDetailPage.mqttTopicList = {}
        MqttDetailPage.mqttDeviceList = {}
        MqttDetailPage.curTopicPage = 1
        MqttDetailPage.curTopicPageCount = 0
        MqttDetailPage.curDevicePageCount = 0
        MqttDetailPage.curDevicePage = 1
        MqttDetailPage.select_tab_index = -1
    end
    MqttDetailPage.mqttTopicList = {}
    MqttDetailPage.ChangeMenu(1)
    -- MqttDetailPage.LoadProjectList()
end

function MqttDetailPage.ChangeMenu(index)
    local index = tonumber(index)
    if index and index == MqttDetailPage.select_tab_index then
        return
    end
    MqttDetailPage.select_tab_index = index
    MqttDetailPage.RefreshPage()
    if index == 1 then
        MqttDetailPage.mqttTopicList = {}
        MqttDetailPage.curTopicPageCount = 0
        MqttDetailPage.curTopicPage = 1
        MqttDetailPage.LoadTopicList()
        return
    end
    if index == 2 then
        MqttDetailPage.mqttDeviceList = {}
        MqttDetailPage.curDevicePage = 1
        MqttDetailPage.curDevicePageCount = 0
        MqttDetailPage.LoadDeviceList()
    end
end

function MqttDetailPage.RefreshPage(delay)
    if page then
        page:Refresh(delay or 0)
    end
end

function MqttDetailPage.LoadTopicList(bRefresh)
    if not MqttDetailPage.mqttProjectData then
        return
    end
    if bRefresh == true then
        MqttDetailPage.mqttTopicList = {}
        MqttDetailPage.curTopicPage = 1
        MqttDetailPage.curTopicPageCount = 0
    end
    local iotProjectId = MqttDetailPage.mqttProjectData.id

    MqttManager.getInstance():LoadTopicList(MqttDetailPage.curTopicPage,iotProjectId,function(result,data)
        if result == true then
            -- echo(data,true)
            print("topic list load success==========")
            if MqttDetailPage.curTopicPageCount == 0 then
                MqttDetailPage.curTopicPageCount = data.count
            end
            if data and data.count and data.count > 0 then
                local mqttList = data.rows or {}
                for k,v in ipairs(mqttList) do
                    table.insert(MqttDetailPage.mqttTopicList,v)
                end
                -- echo(MqttDetailPage.mqttTopicList,true)
                print("topic list load success====-------=========")
            end
            MqttDetailPage.RefreshPage()  
            return
        end
        GameLogic.AddBBS(nil,L"暂无数据")
    end)
end

function MqttDetailPage.LoadTopicMore(index)
    if (not index or type(tonumber(index)) ~= "number" or not MqttDetailPage.mqttTopicList) then
        return;
    end

    index = tonumber(index);
    local dataLength = #MqttDetailPage.mqttTopicList;
    if (index >= dataLength and dataLength < MqttDetailPage.curTopicPageCount) then
        if MqttDetailPage.lastLoadIndex ~= index then
            MqttDetailPage.lastLoadIndex = index;
            MqttDetailPage.curTopicPage = MqttDetailPage.curTopicPage + 1
            MqttDetailPage.LoadTopicList()
        end
    end
end

function MqttDetailPage.OnClickNewTopic()
    if not MqttDetailPage.mqttProjectData then
        return
    end
    local iotProjectId = MqttDetailPage.mqttProjectData.id
    local MqttCreateTopic = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttCreateTopic.lua')
    MqttCreateTopic.ShowPage(iotProjectId)
end

function MqttDetailPage.OnClickTopicCopy(index)
    local data = MqttDetailPage.mqttTopicList[index]
    if data then
        local name = data.name
        ParaMisc.CopyTextToClipboard(name); 
        GameLogic.AddBBS(nil,L"复制成功")
    end
end

function MqttDetailPage.OnClickTopicEdit(index)
    local data = MqttDetailPage.mqttTopicList[index]
    if data then
        local MqttUpdateTopic = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttUpdateTopic.lua')
        MqttUpdateTopic.ShowPage(data)
    end
end

function MqttDetailPage.OnClickTopicDetail(index)
    local data = MqttDetailPage.mqttTopicList[index]
    if data then
        local MqttTopicDetailPage = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/MqttTopicDetailPage.lua')
        MqttTopicDetailPage.ShowPage(MqttDetailPage.mqttProjectData,data)
    end
end

function MqttDetailPage.OnClickTopicClear(index)
    local data = MqttDetailPage.mqttTopicList[index]
    if data then
        local MqttClearTopic = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttClearTopic.lua')
        MqttClearTopic.ShowPage(data)
    end
end

function MqttDetailPage.OnClickTopicDelete(index)
    local data = MqttDetailPage.mqttTopicList[index]
    if data then
        local MqttDeleteTopic = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttDeleteTopic.lua')
        MqttDeleteTopic.ShowPage(data)
    end
end

function MqttDetailPage.LoadDeviceList(bRefresh)
    if not MqttDetailPage.mqttProjectData then
        return
    end
    if bRefresh == true then
        MqttDetailPage.mqttDeviceList = {}
        MqttDetailPage.curDevicePage = 1
        MqttDetailPage.curDevicePageCount = 0
    end
    local iotProjectId = MqttDetailPage.mqttProjectData.id

    MqttManager.getInstance():LoadDeviceList(MqttDetailPage.curDevicePage,iotProjectId,function(result,data)
        if result == true then
            -- echo(data,true)
            print("Device list load success==========")
            if MqttDetailPage.curDevicePageCount == 0 then
                MqttDetailPage.curDevicePageCount = data.count
            end
            if data and data.count and data.count > 0 then
                local mqttList = data.rows or {}
                for k,v in ipairs(mqttList) do
                    table.insert(MqttDetailPage.mqttDeviceList,v)
                end
                -- echo(MqttDetailPage.mqttDeviceList,true)
                print("Device list load success====-------=========")
            end
            MqttDetailPage.RefreshPage() 
            return
        end
        GameLogic.AddBBS(nil,L"暂无数据")
    end)
end

function MqttDetailPage.LoadDeviceMore(index)
    if (not index or type(tonumber(index)) ~= "number" or not MqttDetailPage.mqttDeviceList) then
        return;
    end

    index = tonumber(index);
    local dataLength = #MqttDetailPage.mqttDeviceList;
    if (index >= dataLength and dataLength < MqttDetailPage.curDevicePageCount) then
        if MqttDetailPage.lastLoadIndex ~= index then
            MqttDetailPage.lastLoadIndex = index;
            MqttDetailPage.curDevicePage = MqttDetailPage.curDevicePage + 1
            MqttDetailPage.LoadDeviceList()
        end
    end
end

function MqttDetailPage.OnClickNewDevice()
    if not MqttDetailPage.mqttProjectData then
        return
    end
    local iotProjectId = MqttDetailPage.mqttProjectData.id
    local MqttCreateDevice = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttCreateDevice.lua')
    MqttCreateDevice.ShowPage(iotProjectId)
end

function MqttDetailPage.OnClickDevicePassWordCopy(index)
    local data = MqttDetailPage.mqttDeviceList[index]
    if data then
        local password = data.password
        ParaMisc.CopyTextToClipboard(password); 
        GameLogic.AddBBS(nil,L"复制成功")
    end
end

function MqttDetailPage.OnClickDeviceUserNameCopy(index)
    local data = MqttDetailPage.mqttDeviceList[index]
    if data then
        local username = data.username
        ParaMisc.CopyTextToClipboard(username); 
        GameLogic.AddBBS(nil,L"复制成功")
    end
end

function MqttDetailPage.OnClickDeviceClientIdCopy(index)
    local data = MqttDetailPage.mqttDeviceList[index]
    if data then
        local clientid = data.clientid
        ParaMisc.CopyTextToClipboard(clientid); 
        GameLogic.AddBBS(nil,L"复制成功")
    end
end

function MqttDetailPage.OnClickDeviceDelete(index)
    local data = MqttDetailPage.mqttDeviceList[index]
    if data then
        local MqttDeleteDevice = NPL.load('(gl)script/apps/Aries/Creator/Game/Mqtt/Dialog/MqttDeleteDevice.lua')
        MqttDeleteDevice.ShowPage(data)
    end
end

