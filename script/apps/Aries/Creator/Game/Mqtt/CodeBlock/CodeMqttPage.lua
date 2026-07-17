--[[
    author: pbb
    description: This is the detail page of MQTT useed in code block.
    use lib:
        local CodeMqttPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/CodeBlock/CodeMqttPage.lua")
        CodeMqttPage.Show(block)
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/MqttManager.lua")
local MqttManager = commonlib.gettable("MyCompany.Aries.Creator.Game.MqttManager");

local CodeMqttPage = NPL.export()
CodeMqttPage.page_type = 1 -- 1 for device, 2 for topic
CodeMqttPage.page_step = 1 -- 1 for project, 2 for device or topic

CodeMqttPage.mqttProjectData = nil
CodeMqttPage.mqttTopicList = {}
CodeMqttPage.mqttDeviceList = {}
CodeMqttPage.curTopicPage = 1
CodeMqttPage.curTopicPageCount = 0
CodeMqttPage.curDevicePageCount = 0
CodeMqttPage.curDevicePage = 1

CodeMqttPage.curDeviceData = nil
CodeMqttPage.curTopicData = nil
CodeMqttPage.mqttServerList = {}

local page
function CodeMqttPage.OnInit()
    page = document:GetPageCtrl()
    
end

function CodeMqttPage.Show(block)
    if not block then
        return
    end
    CodeMqttPage.HandleBlockData(block)
    CodeMqttPage.curBlock = block   
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        CodeMqttPage.ShowView()
        return
    end

    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                CodeMqttPage.ShowView()
            end, 1000)
        end
    end)
end

local function get_block_type(block)
    local blockType = (block and type(block.GetType) == "function") and block:GetType() or ""
    if blockType == "mqtt" or blockType == "mqtt.subscribe" or blockType == "mqtt.publish" then
        return "python"
    end
    if blockType == "NPL_mqtt_connect" or blockType == "NPL_mqtt_subscribe" or blockType == "NPL_mqtt_publish" then
        return "npl"
    end 
end

function CodeMqttPage.HandleBlockData(block)
    local blockType = (block and type(block.GetType) == "function") and block:GetType() or ""
    if blockType == "mqtt" or blockType == "NPL_mqtt_connect" then
        CodeMqttPage.page_type = 1
        local client_id = block:GetFieldValue("client_id");
        local username = (block:GetFieldValue("username") or block:GetFieldValue("user")) or "";
        local password = block:GetFieldValue("password");
        CodeMqttPage.page_params = {client_id=client_id,username=username,password=password}
    end
    if blockType == "mqtt.subscribe" or blockType == "mqtt.publish" or blockType == "NPL_mqtt_subscribe" or blockType == "NPL_mqtt_publish" then
        CodeMqttPage.page_type = 2
        CodeMqttPage.page_params = {name=block:GetFieldValue("topic") or ""}
    end
    CodeMqttPage.page_step = 1
end

function CodeMqttPage.RefreshBlock()
    if not CodeMqttPage.curBlock then
        return
    end
    local block = CodeMqttPage.curBlock
    local blockType = get_block_type(block)
    if CodeMqttPage.page_type == 1 then
        if not CodeMqttPage.curDeviceData then
            return
        end
        local client_id = CodeMqttPage.curDeviceData.clientid
        local username = CodeMqttPage.curDeviceData.username or "";
        local password = CodeMqttPage.curDeviceData.password;
       
        if blockType == "python" then
            block:SetFieldValue("client_id",client_id)
            block:SetFieldValue("username",username)
            block:SetFieldValue("server",CodeMqttPage.GetMqttServer())
            block:SetFieldValue("port",CodeMqttPage.GetMqttPort())
        else
            block:SetFieldValue("clientid",client_id)
            block:SetFieldValue("user",username)
            block:SetFieldValue("server",CodeMqttPage.GetMqttServer())
            block:SetFieldValue("port",CodeMqttPage.GetMqttPort())
        end
        block:SetFieldValue("password",password)
        block:GetTopBlock():UpdateLayout();
    end
    if CodeMqttPage.page_type == 2 then
        if not CodeMqttPage.curTopicData then
            return 
        end
        local topic_name = CodeMqttPage.curTopicData.name
        block:SetFieldValue("topic",topic_name)
        block:GetTopBlock():UpdateLayout();
    end
end

function CodeMqttPage.LoadProjectList(callback)
    MqttManager.getInstance():LoadProjectList(function(result,data)
        if result == true and data and data.count and data.count > 0 then
            local mqttList = data.rows or {}
            CodeMqttPage.mqttServerList = mqttList
            if callback and type(callback) == "function" then
                callback()
            end
            return
        end
        CodeMqttPage.mqttServerList = {}
        if callback and type(callback) == "function" then
            callback()
        end
        GameLogic.AddBBS(nil,L"暂无数据")
    end)
end

function CodeMqttPage.ShowView()
    CodeMqttPage.LoadProjectList(function()
        local view_width = 0
        local view_height = 0
        local params = {
            url = "script/apps/Aries/Creator/Game/Mqtt/CodeBlock/CodeMqttPage.html",
            name = "CodeMqttPage.ShowView", 
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
            CodeMqttPage.RefreshBlock()
            CodeMqttPage.curDeviceData = nil
            CodeMqttPage.curTopicData = nil
            CodeMqttPage.mqttProjectData = nil
            CodeMqttPage.mqttTopicList = {}
            CodeMqttPage.mqttDeviceList = {}
            CodeMqttPage.curTopicPage = 1
            CodeMqttPage.curTopicPageCount = 0
            CodeMqttPage.curDevicePageCount = 0
            CodeMqttPage.curDevicePage = 1
        end
    end)
end

function CodeMqttPage.RefreshPage() 
    if page then
        page:Refresh(0.1)
    end
end

function CodeMqttPage.OnClickProject(name)
    local select_index = tonumber(name)
    if select_index and select_index > 0 and select_index <= #CodeMqttPage.mqttServerList then
        CodeMqttPage.mqttProjectData = CodeMqttPage.mqttServerList[select_index]
        CodeMqttPage.page_step = 2
        if CodeMqttPage.page_type == 1 then
            CodeMqttPage.mqttDeviceList = {}
            CodeMqttPage.curDevicePageCount = 0
            CodeMqttPage.curDevicePage = 1
            CodeMqttPage.LoadDeviceList()
        else
            CodeMqttPage.curTopicPage = 1
            CodeMqttPage.curTopicPageCount = 0
            CodeMqttPage.mqttTopicList = {}
            CodeMqttPage.LoadTopicList()
        end
    end
end

function CodeMqttPage.LoadDeviceList(bRefresh)
    if not CodeMqttPage.mqttProjectData then
        return
    end
    if bRefresh == true then
        CodeMqttPage.mqttDeviceList = {}
        CodeMqttPage.curDevicePage = 1
        CodeMqttPage.curDevicePageCount = 0
    end
    local iotProjectId = CodeMqttPage.mqttProjectData.id

    MqttManager.getInstance():LoadDeviceList(CodeMqttPage.curDevicePage,iotProjectId,function(result,data)
        if result == true then
            if CodeMqttPage.curDevicePageCount == 0 then
                CodeMqttPage.curDevicePageCount = data.count
            end
            if data and data.count and data.count > 0 then
                local mqttList = data.rows or {}
                for k,v in ipairs(mqttList) do
                    table.insert(CodeMqttPage.mqttDeviceList,v)
                end
            end
            CodeMqttPage.RefreshPage() 
            return
        end
        GameLogic.AddBBS(nil,L"暂无数据")
    end)
end

function CodeMqttPage.LoadDeviceMore(index)
    if (not index or type(tonumber(index)) ~= "number" or not CodeMqttPage.mqttDeviceList) then
        return;
    end

    index = tonumber(index);
    local dataLength = #CodeMqttPage.mqttDeviceList;
    if (index >= dataLength and dataLength < CodeMqttPage.curDevicePageCount) then
        if CodeMqttPage.lastLoadIndex ~= index then
            CodeMqttPage.lastLoadIndex = index;
            CodeMqttPage.curDevicePage = CodeMqttPage.curDevicePage + 1
            CodeMqttPage.LoadDeviceList()
        end
    end
end

function CodeMqttPage.LoadTopicList(bRefresh)
    if not CodeMqttPage.mqttProjectData then
        return
    end
    if bRefresh == true then
        CodeMqttPage.mqttTopicList = {}
        CodeMqttPage.curTopicPage = 1
        CodeMqttPage.curTopicPageCount = 0
    end
    local iotProjectId = CodeMqttPage.mqttProjectData.id

    MqttManager.getInstance():LoadTopicList(CodeMqttPage.curTopicPage,iotProjectId,function(result,data)
        if result == true then
            if CodeMqttPage.curTopicPageCount == 0 then
                CodeMqttPage.curTopicPageCount = data.count
            end
            if data and data.count and data.count > 0 then
                local mqttList = data.rows or {}
                for k,v in ipairs(mqttList) do
                    table.insert(CodeMqttPage.mqttTopicList,v)
                end
            end
            CodeMqttPage.RefreshPage()  
            return
        end
        GameLogic.AddBBS(nil,L"暂无数据")
    end)
end

function CodeMqttPage.LoadTopicMore(index)
    if (not index or type(tonumber(index)) ~= "number" or not CodeMqttPage.mqttTopicList) then
        return;
    end

    index = tonumber(index);
    local dataLength = #CodeMqttPage.mqttTopicList;
    if (index >= dataLength and dataLength < CodeMqttPage.curTopicPageCount) then
        if CodeMqttPage.lastLoadIndex ~= index then
            CodeMqttPage.lastLoadIndex = index;
            CodeMqttPage.curTopicPage = CodeMqttPage.curTopicPage + 1
            CodeMqttPage.LoadTopicList()
        end
    end
end

function CodeMqttPage.OnClickDevice(name)
    local select_index = tonumber(name)
    if select_index and select_index > 0 and select_index <= #CodeMqttPage.mqttDeviceList then
        CodeMqttPage.curDeviceData = CodeMqttPage.mqttDeviceList[select_index]
        CodeMqttPage.ClosePage()
    end
end

function CodeMqttPage.IsDeviceSelected(index)
    local select_index = tonumber(index)
    if select_index and select_index > 0 and select_index <= #CodeMqttPage.mqttDeviceList then
        local client_id = CodeMqttPage.page_params.client_id or -1
        if client_id == CodeMqttPage.mqttDeviceList[select_index].clientid then
            return true
        end
    end
    return false
end

function CodeMqttPage.OnClickTopic(name)
    local select_index = tonumber(name)
    if select_index and select_index > 0 and select_index <= #CodeMqttPage.mqttTopicList then
        CodeMqttPage.curTopicData = CodeMqttPage.mqttTopicList[select_index]
        CodeMqttPage.ClosePage()
    end
end

function CodeMqttPage.IsTopicSelected(index)
    local select_index = tonumber(index)
    if select_index and select_index > 0 and select_index <= #CodeMqttPage.mqttTopicList then
        local topic_name = CodeMqttPage.page_params.name or ""
        if topic_name and topic_name ~= "" and topic_name == CodeMqttPage.mqttTopicList[select_index].name then
            return true
        end
    end
    return false
end

function CodeMqttPage.ClosePage()
    if page then
        page:CloseWindow()
    end
end
function CodeMqttPage.OnClickClose()
    CodeMqttPage.ClosePage()
end

function CodeMqttPage.OnClickBack()
    if CodeMqttPage.page_step == 2 then
        CodeMqttPage.page_step = 1
        CodeMqttPage.mqttProjectData = nil
        CodeMqttPage.RefreshPage()
    end
end

local mqtt_server = {
	STAGE="mqtt-dev.kp-para.cn",
	RELEASE="mqtt-rls.kp-para.cn",
	ONLINE="mqtt.keepwork.com",
}
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local defaultEnv = HttpWrapper.GetDevVersion()
function CodeMqttPage.GetMqttServer()
	return mqtt_server[defaultEnv] or "mqtt.keepwork.com";
end

function CodeMqttPage.GetMqttPort()
	if defaultEnv == "STAGE" or defaultEnv == "RELEASE" then
		return "1883"
	end
	return "18883"
end

