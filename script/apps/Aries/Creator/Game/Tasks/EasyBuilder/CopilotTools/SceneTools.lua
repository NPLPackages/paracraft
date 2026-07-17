--[[
Title: SceneTools
Author(s): copilot
Date: 2026/03/18
Desc: Scene query tools — decoupled from BackgroundAgent.
Registers tools for querying 3D scene entities and context.

Category: "scene_query"

Usage:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/SceneTools.lua");
    local SceneTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.SceneTools");
    local tools = SceneTools:new();
    tools:RegisterTools(registry);
]]

local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local SceneTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.SceneTools"));

function SceneTools:ctor()
end

--[[
    Register all scene query tools on a ToolRegistry.
    @param registry: ToolRegistry instance
]]
function SceneTools:RegisterTools(registry)
    if not registry then return; end

    -- Tool: Query entities in area
    registry:RegisterTool("query_entities", {
        description = "Query entities in a specific area",
        parameters = {
            type = "object",
            properties = {
                center_x = {type = "number", description = "Center X coordinate"},
                center_y = {type = "number", description = "Center Y coordinate"},
                center_z = {type = "number", description = "Center Z coordinate"},
                radius = {type = "number", description = "Search radius in blocks"},
            },
            required = {"center_x", "center_y", "center_z"},
        },
    }, function(params, callback, services)
        local cx, cy, cz = params.center_x, params.center_y, params.center_z;
        local radius = params.radius or 20;
        local entities = EntityManager.GetEntitiesByMinMax(
            cx - radius, cy, cz - radius,
            cx + radius, cy + radius, cz + radius
        );

        local results = {};
        if entities then
            for _, entity in ipairs(entities) do
                local ex, ey, ez = entity:GetBlockPos();
                table.insert(results, {
                    type = entity.class_name or "Unknown",
                    name = entity:GetDisplayName() or nil,
                    position = {x = ex, y = ey, z = ez},
                });
            end
        end

        callback({
            success = true,
            llm_result = string.format("Found %d entities: %s", #results, commonlib.serialize_compact(results) or "[]"),
        });
    end, "scene_query");

    -- Tool: get_scene_context — on-demand scene context retrieval for LLM
    registry:RegisterTool("get_scene_context", {
        description = "Get the current 3D scene context including recent screenshots and scene descriptions. "
            .. "Use this when you need to understand what the student is looking at or doing in the 3D world "
            .. "but the scene context was not automatically included in the prompt.",
        parameters = {
            type = "object",
            properties = {
                detail_level = {
                    type = "string",
                    enum = {"brief", "full"},
                    description = "'brief' for a short summary (1 screenshot), 'full' for complete scene history. Default: 'full'.",
                },
            },
        },
    }, function(params, callback, services)
        local sceneCtx = services and services:Get("scene_context");
        if not sceneCtx then
            callback({success = true, llm_result = "No scene context service available."});
            return;
        end

        local detailLevel = params.detail_level or "full";
        local isFullMode = (detailLevel == "full");

        local sceneContext = sceneCtx:GetSceneTextContext();
        local formatted = sceneCtx:FormatSceneContextAsMarkdown(sceneContext, false, isFullMode);

        -- Also include latest vision summary
        local contextSummary = sceneCtx:GetContextHistorySummary();

        local result = "";
        if contextSummary and contextSummary ~= "" then
            result = result .. contextSummary .. "\n";
        end
        if formatted and formatted ~= "" then
            result = result .. formatted;
        end

        if result == "" then
            result = "No scene context available at the moment.";
        end

        callback({
            success = true,
            llm_result = result,
        });
    end, "scene_query");
end
