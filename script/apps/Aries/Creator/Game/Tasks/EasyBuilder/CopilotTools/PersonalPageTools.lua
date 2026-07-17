--[[
Title: Personal Page Chat Tools
Author: Paracraft Assistant
Date: 2025/01/12
Desc: Registers Personal Page tools for AI chat via ToolRegistry pattern.

uselib:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/PersonalPageTools.lua");
    local PersonalPageTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.PersonalPageTools");
    PersonalPageTools:new():RegisterTools(registry);
]]

local PersonalPageTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.PersonalPageTools"));

function PersonalPageTools:ctor()
end

function PersonalPageTools.GetPersonalStore()
    if not PersonalPageTools.personalStore then
        NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua");
        local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore");
        PersonalPageTools.personalStore = PersonalPageStore
    end
    return PersonalPageTools.personalStore
end

function PersonalPageTools:RegisterTools(registry)
    if not registry then return; end

    registry:RegisterTool("personal_page_load", {
        description = "加载个人页面数据。用于获取用户的持久化数据。当用户询问是什么、有没有、查一下某项信息时使用。",
        parameters = {
            type = "object",
            properties = {
                pageName = {
                    type = "string",
                    description = "数据的逻辑分类名称（Category），用于区分不同模块的数据，例如 'farm_config', 'user_status'。如果不确定分类，可以不传，将检索所有数据。",
                },
                key = {
                    type = "string",
                    description = "分类下的具体属性名（Property）。例如 'level', 'money'。如果不传，则获取Root结构下的所有数据。",
                },
            },
            required = {},
        },
    }, function(params, callback, services)
        PersonalPageTools.GetPersonalStore():LoadPageData(params.pageName, params.key, function(data)
            callback({success = true, llm_result = commonlib.Json.Encode(data)});
        end);
    end, "personal_page");

    registry:RegisterTool("personal_page_save", {
        description = "保存个人页面数据。用于记住、设置或更新用户信息（持久化存储）。\n"
            .. "**数据结构**：`[Root] -> [Category (pageName)] -> [Property (key)]`。\n"
            .. "**使用说明**：\n"
            .. "1. **逻辑分类（必须）**：必须使用 `pageName` 对数据进行分类（如 `farm_config`）。\n"
            .. "2. **保存模式**：单属性模式传入 key+data；全分类模式不传 key，data 为包含多个属性的对象。\n"
            .. "3. **先查后改**：如果不确定当前数据状态，建议先调用 load 工具查询。\n"
            .. "**命名规范**：pageName 和 key 请使用 snake_case。",
        parameters = {
            type = "object",
            properties = {
                pageName = {type = "string", description = "数据的逻辑分类名称"},
                key = {type = "string", description = "分类下的具体属性名"},
                data = {type = "object", description = "要保存的具体内容"},
                bForceFlush = {type = "boolean", description = "是否强制写入磁盘。默认为 true。"},
            },
            required = {"pageName", "data"},
        },
    }, function(params, callback, services)
        local bForceFlush = params.bForceFlush;
        if bForceFlush == nil then bForceFlush = true; end
        PersonalPageTools.GetPersonalStore():SavePageData(params.pageName, params.key, params.data, bForceFlush);
        callback({success = true, llm_result = "Data saved successfully."});
    end, "personal_page");
end

return PersonalPageTools;
end

return PersonalPageTools;
