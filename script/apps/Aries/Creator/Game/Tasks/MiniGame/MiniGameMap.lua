--[[
    Title: MiniGame Map Page
    Author(s): ParaCraft Team
    Date: 2025/6/13
    Desc: 小游戏地图界面
    Use Lib:
    -------------------------------------------------------
    local MiniGameMap = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMap.lua");
    MiniGameMap.ShowPage();
]]
local NPC_config = {}
local mapConfig = {}
local MapAreas = {
    {
        id = 1,
        name = "perseverance",
        showname = "恒心树屋岛",
        description = "负责训练学习品质的区域",
        pos = {x=19208,y=6,z=19114},
        color="#9d4e9a",
    },
    {
        id = 2,
        name = "wisdom",
        showname = "智慧方舟岛",
        description = "负责训练认知能力的区域",
        pos = {x=19108,y=6,z=19062},
        color="#2d6fb6",
    },
    {
        id = 3,
        name = "friend",
        showname = "友谊协作岛",
        description = "负责训练人际交往的区域",
        pos = {x=19175,y=6,z=18967},
        color="#58da2e",
    },
    {
        id = 4,
        name = "emotion",
        showname = "情感光球岛",
        description = "负责训练情绪智力的区域",
        pos = {x=19302,y=6,z=18915},
        color="#df6d26",
    },
    {
        id = 6,
        name = "strategy",
        showname = "策略解密岛",
        description = "负责训练学习策略的区域",
        pos = {x=19317,y=6,z=19057},
        color="#e3af30",
    },
}
--[[
{
        id = 5,
        name = "motivation",
        showname = "动力广场",
        description = "负责训练学习动机的区域",
        pos = {x=19225,y=6,z=19305},
        color="#e2cb6c",
    },
]]

local MiniGameMap = NPL.export()
local page
local parent_root
function MiniGameMap:OnInit()
    page = document:GetPageCtrl() 
    if page then
        parent_root  = page:GetParentUIObject()
        page.OnCreate = MiniGameMap.OnCreated
    end   
end

function MiniGameMap.GetAllMaps()
    return MapAreas;
end

function MiniGameMap.OnCreated()
    MiniGameMap.ShowNpcMaker()

    -- print("map==============",x,y,width,height)
end

function MiniGameMap.ShowNpcMaker()
    if not MiniGameMap.ShowNpcMakerImp then

        MiniGameMap.ShowNpcMakerImp = commonlib.debounce(function()
            MiniGameMap.ShowMapMarkers()
        end, 200)
    end
    MiniGameMap.ShowNpcMakerImp()
end

function MiniGameMap.PlayTeleportEffect(variable)
    NPL.load("(gl)script/apps/Aries/Scene/EffectManager.lua");
    local EffectManager = MyCompany.Aries.EffectManager;
    local play_end_callback = variable.end_callback;
    local start_params = {
        asset_file = "character/v5/09effect/Move/MoveStart.x",
        binding_obj_name = "localuser",
        start_position = nil,
        duration_time = 800,
        force_name = "TeleportStart"..ParaGlobal.GenerateUniqueID(),
        begin_callback = function() end,
        end_callback = function() 
            local mapPos = variable.pos;
            if mapPos then
                local cmdStr = string.format("/goto %d %d %d", mapPos.x, mapPos.y, mapPos.z);
                GameLogic.RunCommand(cmdStr);
            end
            if play_end_callback and type(play_end_callback) == "function" then
                play_end_callback()
            end

            local params = {
                asset_file = "character/v5/09effect/Move/MoveEnd.x",
                binding_obj_name = "localuser",
                start_position = nil,
                duration_time = 360,
                force_name = "TeleportFinish"..ParaGlobal.GenerateUniqueID(),
                begin_callback = function() end,
                end_callback = function() end,
            };
            EffectManager.CreateEffect(params);
        end,
    }
    EffectManager.CreateEffect(start_params);
end

function MiniGameMap.GetMapConfig()
    local sceneConfig = GameLogic.MiniGameMgr:GetMapList() or {}
    mapConfig = commonlib.deepcopy(sceneConfig)
    local player = GameLogic.EntityManager.GetFocus()
    if player then
        local bx,by,bz = player:GetBlockPos()
        table.insert(mapConfig, {
            displayName = L"我的位置",
            entityName = player:GetName(),
            name = player:GetName(),
            dialog = "",
            pos = {x = bx, y = by, z = bz},
            isMine = true,
        })
    end
    return mapConfig
end

function MiniGameMap.ShowPage()
    local delay = 0
    if not MiniGameMap.loadTexture then
        Mod.WorldShare.MsgBox:Wait(10000,L"地图信息加载中.....")
        ParaAsset.LoadTexture("","Texture/Aries/WorldMaps/Teen/map_bg.png",1);
        ParaAsset.LoadTexture("","Texture/Aries/Creator/keepwork/minigame/map_512x512_32bits.png",1);
        delay = 1500
        MiniGameMap.loadTexture = true
    end

    commonlib.TimerManager.SetTimeout(function()
        MiniGameMap.GetMapConfig()
        NPC_config = GameLogic.MiniGameMgr:GetNpcList() or {}
        MiniGameMap.HandleCategoryDatas()
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMap.html",
            name = "MiniGameMap",
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = false,
            enable_esc_key = true,
            cancelShowAnimation = true,
            zorder = 0,
            directPosition = true,
            align = "_ct",
            x = -450,
            y = -320,
            width = 900,
            height = 512,
        };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
        Mod.WorldShare.MsgBox:Close()
    end,delay)
end

--中心 19249,9,19035 边界 19249,9,19035 ；19270,8,18766 ；19482,4,19034 ；18994,7,19068

-- 关闭页面
function MiniGameMap.ClosePage()
    if page then
        page:CloseWindow();
        page = nil;
    end
end

function MiniGameMap.OnClickMap(name)
    local index = tonumber(name)
    if index then
        local map = MapAreas[index]
        if map and map.pos then
            MiniGameMap.ClosePage()
            MiniGameMap:TeleportToPos(map.pos)
        end
    end
end

-- NPC位置映射算法 - 基于ParaWorldMinimapSurface简化版
function MiniGameMap:MapNPCsTo2D(forceRefresh)
    -- 缓存机制，避免重复计算
    NPC_config = GameLogic.MiniGameMgr:GetNpcList() or {}
    if MiniGameMap.mappedNPCs and not forceRefresh then
        return MiniGameMap.mappedNPCs
    end
    
    local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
    local mappedNPCs = {}
    
    local mapBg = ParaUI.GetUIObject("map")
    if not mapBg or not mapBg:IsValid() then
        print("Map UI not found")
        return nil
    end
    local uiX, uiY, uiWidth, uiHeight = mapBg:GetAbsPosition()
    MiniGameMap:InitMapParams(uiWidth, uiHeight)
    
    local existingPositions = {}
    
    for i, npc in ipairs(NPC_config) do
        if npc.entityName and npc.entityName ~= "" then
            -- 通过entityName获取实体的3D位置
            local entity = EntityManager.GetEntity(npc.entityName)
            if entity then
                local worldX, worldY, worldZ = entity:GetBlockPos()
                if worldX and worldY and worldZ then
                    -- 使用简化的坐标转换算法
                    local mapX, mapY = MiniGameMap:WorldToMapPos(worldX, worldZ, uiWidth, uiHeight)
                    if mapX and mapY then
                        -- 转换为UI坐标
                        local uiPosX = uiX + mapX
                        local uiPosY = uiY + mapY
                        
                        -- 防重叠处理
                        local finalPos = MiniGameMap:FindNonOverlappingPosition(uiPosX, uiPosY, existingPositions)
                        table.insert(existingPositions, {x = finalPos.x, y = finalPos.y})
                        
                        -- 创建映射结果
                        local mappedNPC = {
                            name = npc.name,
                            entityName = npc.entityName,
                            pos3D = {x = worldX, y = worldY, z = worldZ},
                            pos2D = {x = finalPos.x - uiX, y = finalPos.y - uiY}, -- 相对于地图的坐标
                            dialog = npc.dialog,
                            games = npc.games,
                            actions = npc.actions
                        }
                        
                        table.insert(mappedNPCs, mappedNPC)
                    end
                else
                    print("Invalid position for entity:", npc.entityName)
                end
            else
                print("Entity not found:", npc.entityName)
            end
        end
    end
    
    if #mappedNPCs == 0 then
        print("No valid NPCs found for mapping")
        return nil
    end
    
    MiniGameMap.mappedNPCs = mappedNPCs
    return MiniGameMap.mappedNPCs
end

-- 初始化地图参数 - 参考ParaWorldMinimapSurface
function MiniGameMap:InitMapParams(uiWidth, uiHeight)
    -- 固定地图中心点（不变，支持岛屿扩展）
    MiniGameMap.centerX = 19249
    MiniGameMap.centerZ = 19035
    
    -- 地图半径（可根据需要调整以支持更多岛屿）
    MiniGameMap.mapRadius = 256  -- 增大半径使NPC分布更分散，覆盖更大范围
    
    -- 计算地图边界（参考ParaWorldMinimapSurface的SetMapCenter逻辑）
    MiniGameMap.map_left = MiniGameMap.centerX - MiniGameMap.mapRadius
    MiniGameMap.map_top = MiniGameMap.centerZ - MiniGameMap.mapRadius
    MiniGameMap.map_width = MiniGameMap.mapRadius * 2
    MiniGameMap.map_height = MiniGameMap.mapRadius * 2
    
    -- 存储UI尺寸用于分辨率适配
    MiniGameMap.ui_width = uiWidth
    MiniGameMap.ui_height = uiHeight
    
    if MiniGameMap.debugMode then
        print(string.format("地图参数初始化: 中心(%d,%d) 半径%d UI尺寸(%dx%d)", 
            MiniGameMap.centerX, MiniGameMap.centerZ, MiniGameMap.mapRadius, uiWidth, uiHeight))
        print(string.format("地图边界: left=%d top=%d width=%d height=%d", 
            MiniGameMap.map_left, MiniGameMap.map_top, MiniGameMap.map_width, MiniGameMap.map_height))
    end
end

-- 简化的3D到2D坐标转换 - 直接参考ParaWorldMinimapSurface
-- @param worldX: 3D世界X坐标
-- @param worldZ: 3D世界Z坐标  
-- @param uiWidth: UI宽度
-- @param uiHeight: UI高度
-- @return mapX, mapY: 2D地图坐标（相对于地图UI的像素位置）或 nil
function MiniGameMap:WorldToMapPos(worldX, worldZ, uiWidth, uiHeight)
    if not MiniGameMap.map_left or not MiniGameMap.map_top then
        return nil
    end
    
    -- 计算相对于地图边界的位置（参考ParaWorldMinimapSurface逻辑）
    local mapX, mapZ = worldX - MiniGameMap.map_left, worldZ - MiniGameMap.map_top
    
    -- 检查是否在地图范围内
    if mapX >= 0 and mapX < MiniGameMap.map_width and mapZ >= 0 and mapZ < MiniGameMap.map_height then
        -- 转换为像素坐标（参考ParaWorldMinimapSurface的WorldToMapPos）
        local pixelX = math.floor(uiWidth - mapZ / MiniGameMap.map_height * uiWidth)
        local pixelY = math.floor(uiHeight - mapX / MiniGameMap.map_width * uiHeight)
        
        -- 确保坐标在UI范围内
        pixelX = math.max(0, math.min(pixelX, uiWidth))
        pixelY = math.max(0, math.min(pixelY, uiHeight))
        
        if MiniGameMap.debugMode then
            print(string.format("坐标转换: 世界(%d,%d) -> 地图相对(%d,%d) -> 像素(%d,%d)", 
                worldX, worldZ, mapX, mapZ, pixelX, pixelY))
        end
        
        return pixelX, pixelY
    end
    
    return nil
end

-- 设置地图半径（支持岛屿扩展）
function MiniGameMap:SetMapRadius(radius)
    MiniGameMap.mapRadius = math.max(200, math.min(radius, 800))  -- 限制在合理范围内
    
    -- 重新计算地图边界
    if MiniGameMap.centerX and MiniGameMap.centerZ then
        MiniGameMap.map_left = MiniGameMap.centerX - MiniGameMap.mapRadius
        MiniGameMap.map_top = MiniGameMap.centerZ - MiniGameMap.mapRadius
        MiniGameMap.map_width = MiniGameMap.mapRadius * 2
        MiniGameMap.map_height = MiniGameMap.mapRadius * 2
        
        if MiniGameMap.debugMode then
            print(string.format("地图半径更新为: %d, 新边界: left=%d top=%d width=%d height=%d", 
                MiniGameMap.mapRadius, MiniGameMap.map_left, MiniGameMap.map_top, MiniGameMap.map_width, MiniGameMap.map_height))
        end
    end
end

-- 获取地图半径
function MiniGameMap:GetMapRadius()
    return MiniGameMap.mapRadius or 600
end


-- 简化的防重叠位置查找算法
-- @param baseX: 基础X坐标
-- @param baseY: 基础Y坐标
-- @param existingPositions: 已存在的位置列表
-- @return 不重叠的位置坐标
function MiniGameMap:FindNonOverlappingPosition(baseX, baseY, existingPositions)
    local minDistance = 20  -- 最小间距（像素）
    
    -- 检查位置是否与现有位置重叠
    local function isOverlapping(x, y)
        for _, pos in ipairs(existingPositions) do
            local distance = math.sqrt((x - pos.x)^2 + (y - pos.y)^2)
            if distance < minDistance then
                return true
            end
        end
        return false
    end
    
    -- 如果基础位置不重叠，直接返回
    if not isOverlapping(baseX, baseY) then
        return {x = baseX, y = baseY}
    end
    
    -- 简单的偏移策略：向右下方偏移
    local offsetStep = 15
    for i = 1, 5 do
        local newX = baseX + i * offsetStep
        local newY = baseY + i * offsetStep
        
        if not isOverlapping(newX, newY) then
            return {x = newX, y = newY}
        end
    end
    
    -- 如果还是重叠，返回基础位置
    return {x = baseX, y = baseY}
end

-- 获取地图背景UI对象
function MiniGameMap:GetMapBackground()
    return ParaUI.GetUIObject("map")
end

function MiniGameMap:ShowMapMarkers()
    MiniGameMap:ClearMapMarkers()

    local mapBg = MiniGameMap:GetMapBackground()
    if not mapBg or not mapBg:IsValid() then
        return
    end

    local uiX, uiY, uiWidth, uiHeight = mapBg:GetAbsPosition()
    MiniGameMap:InitMapParams(uiWidth, uiHeight)
    local existingPositions = {}
    for _, markerCfg in ipairs(mapConfig or {}) do
        local pos = markerCfg.pos
        if pos and pos.x and pos.z then
            local mapX, mapY = MiniGameMap:WorldToMapPos(pos.x, pos.z, uiWidth, uiHeight)
            if mapX and mapY then
                local uiPosX = uiX + mapX
                local uiPosY = uiY + mapY
                local finalPos = MiniGameMap:FindNonOverlappingPosition(uiPosX, uiPosY, existingPositions)
                table.insert(existingPositions, {x = finalPos.x, y = finalPos.y})

                local marker = {
                    name = markerCfg.name or (markerCfg.entityName or "marker"),
                    displayName = markerCfg.displayName or markerCfg.name or "标记",
                    entityName = markerCfg.entityName,
                    subTag = markerCfg.subTag,
                    pos3D = {x = pos.x, y = pos.y or 7, z = pos.z},
                    pos2D = {x = finalPos.x - uiX, y = finalPos.y - uiY},
                    dialog = markerCfg.dialog,
                }
                if markerCfg.isMine then
                    marker.isMine = true
                end
                MiniGameMap:CreateOrUpdateMapMarker(marker, mapBg)
            end
        end
    end
end

function MiniGameMap:GetMakerBg(marker)
    if not marker then
        return "Texture/Aries/Creator/keepwork/minigame/map_tip1_32bits.png",""
    end
    if marker.subTag then
        local CheckPointManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CheckPointManager.lua");
        local occupiedData = CheckPointManager.GetOccupiedDataBySubtag(marker.subTag)
        if occupiedData  and #occupiedData > 0 then
            return "Texture/Aries/Creator/keepwork/minigame/map_tip3_32bits.png","已被占用"
        end
    end
    if marker.isMine then
        return "Texture/Aries/Creator/keepwork/Avatar/icons/80001_head01.png",""
    end

    if marker.entityName and marker.entityName ~= "" then
        return "Texture/Aries/Creator/keepwork/minigame/map_tip4_32bits.png",""
    end

    return "Texture/Aries/Creator/keepwork/minigame/map_tip1_32bits.png",""
end
-- 创建或更新地图标记
function MiniGameMap:CreateOrUpdateMapMarker(marker, mapBg)
    if not marker or not marker.pos2D or not mapBg then
        return
    end

    local markerName = "map_marker_" .. (marker.name or "unknown")
    local uiMarker = ParaUI.GetUIObject(markerName)
    local width, height = 48, 48

    if not uiMarker or not uiMarker:IsValid() then
        uiMarker = ParaUI.CreateUIObject("button", markerName, "_lt",marker.pos2D.x - width, marker.pos2D.y - height, width, height)
        local bg,extTooltip = MiniGameMap:GetMakerBg(marker)
        uiMarker.background = bg
        uiMarker.tooltip = (marker.displayName or marker.name or "标记") .. (marker.dialog and ("\n" .. marker.dialog) or "")..extTooltip
        if not marker.isMine then
            uiMarker:SetScript("onclick", function()
                MiniGameMap:OnMapMarkerClick(marker)
            end)
            uiMarker.zorder = 101
        else
            uiMarker.zorder = 100
        end
        mapBg:AddChild(uiMarker)
    else
        uiMarker.x = marker.pos2D.x - width / 2
        uiMarker.y = marker.pos2D.y - height / 2
        uiMarker.visible = true
    end
end

-- 清理地图标记
function MiniGameMap:ClearMapMarkers()
    for _, markerCfg in ipairs(mapConfig or {}) do
        local name = markerCfg.name or markerCfg.entityName
        if name and name ~= "" then
            local markerName = "map_marker_" .. name
            local uiMarker = ParaUI.GetUIObject(markerName)
            if uiMarker and uiMarker:IsValid() then
                uiMarker:Destroy()
            end
        end
    end
end

-- 地图标记点击事件：有 entityName 时按朝向前方传送，否则随机安全位置
function MiniGameMap:OnMapMarkerClick(marker)
    if not marker then
        return
    end

    if marker.entityName and marker.entityName ~= "" then
        MiniGameMap:TeleportNpcImp({ entityName = marker.entityName, pos3D = marker.pos3D })
    else
        local safePos = MiniGameMap.RandomSafeTeleportNear(marker.pos3D, 3, 8)
        MiniGameMap:TeleportToPos(safePos, marker.pos3D)
    end

    MiniGameMap.ClosePage()
end

-- 随机安全传送到某位置附近
function MiniGameMap.RandomSafeTeleportNear(pos, minDist, maxDist)
    local minD = minDist or 3
    local maxD = maxDist or 8
    local angle = math.random() * math.pi * 2
    local dist = minD + math.random() * (maxD - minD)
    local offsetX = math.cos(angle) * dist
    local offsetZ = math.sin(angle) * dist

    local target = {
        x = math.floor((pos.x or 0) + offsetX),
        y = pos.y or 7,
        z = math.floor((pos.z or 0) + offsetZ),
    }
    return MiniGameMap.FindSafeTeleportPosition(target)
end

function MiniGameMap:GetSceneMaps()
    local maps = {}
    local npcMaps = GameLogic.MiniGameMgr:GetMapList() or {}
    for _, cfg in ipairs(npcMaps) do
        table.insert(maps, {
            pos3D = cfg.pos,
            name = (cfg.displayName or "Unknown Map"),
            entityName = cfg.name,
            dialog = "",
        })
    end
    return maps
end


-- 获取场景中的所有NPC
function MiniGameMap:GetSceneNPCs()
    local npcs = {}
    local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
    NPC_config = GameLogic.MiniGameMgr:GetNpcList() or {}
    for _, npcConfig in ipairs(NPC_config) do
        if npcConfig.entityName and npcConfig.entityName ~= "" then
            local entity = EntityManager.GetEntity(npcConfig.entityName)
            if entity then
                local x, y, z = entity:GetBlockPos()
                table.insert(npcs, {
                    entityName = npcConfig.entityName,
                    name = npcConfig.name or "Unknown NPC",
                    pos3D = {x = x, y = y, z = z},
                    dialog = npcConfig.dialog
                })
            end
        end
    end
    
    return npcs
end

-- 提供 NPC 列表数据给左侧滚动列表
function MiniGameMap.GetNPCs()
    local items = {}
    local npcs = MiniGameMap:GetSceneNPCs() or {}
    MiniGameMap.npcItems = {}
    for _, npc in ipairs(npcs) do
        local item = {
            showname = npc.name or npc.entityName or "NPC",
            color = "#518ade",
            entityName = npc.entityName,
        }
        table.insert(items, item)
        table.insert(MiniGameMap.npcItems, item)
    end
    return items
end

function MiniGameMap.OnClickNPC(name)
    local index = tonumber(name)
    if not index or not MiniGameMap.npcItems or not MiniGameMap.npcItems[index] then
        return
    end
    local item = MiniGameMap.npcItems[index]
    if item and item.entityName then
        MiniGameMap:TeleportNpcImp({ entityName = item.entityName })
        MiniGameMap.ClosePage()
    end
end

function MiniGameMap:TeleportNpcImp(npc)
    if not npc then
        print("Error: Invalid NPC data")
        return
    end
    
    if not npc.pos3D then --外部调用
        local npcs = MiniGameMap:GetSceneNPCs()
        if not npcs or #npcs == 0 then
            return
        end
        for _, data in ipairs(npcs) do
            if data.entityName == npc.entityName then
                npc = data
                break
            end
        end
    end
    
    local teleportPos, npcPos = MiniGameMap:CalculateTeleportPosition(npc)

    if teleportPos then
        MiniGameMap.PlayTeleportEffect({
            end_callback = function()
                local cmdStr = string.format("/goto %d %d %d", teleportPos.x, teleportPos.y, teleportPos.z)
                GameLogic.RunCommand(cmdStr)
        
                local lookatStr = string.format("/lookat %d %d %d", npcPos.x, npcPos.y, npcPos.z)
                GameLogic.RunCommand(lookatStr)
            end
        })
        print("Teleported to position in front of NPC:", npc.name)
    else
        -- 如果无法计算朝向，则传送到NPC位置
        local cmdStr = string.format("/goto %d %d %d", npc.pos3D.x, npc.pos3D.y, npc.pos3D.z)
        GameLogic.RunCommand(cmdStr)
        print("Teleported to NPC position:", npc.name)
    end
end

function MiniGameMap:TeleportToPos(pos, lookatPos)
    if pos and pos.x then
        MiniGameMap.PlayTeleportEffect({
            end_callback = function()
                local cmdStr = string.format("/goto %d %d %d", pos.x, pos.y, pos.z)
                GameLogic.RunCommand(cmdStr)
                if lookatPos then
                    local lookatStr = string.format("/lookat %d %d %d", lookatPos.x, lookatPos.y, lookatPos.z)
                    GameLogic.RunCommand(lookatStr)
                end
            end
        })
    end
end

-- 计算传送位置（NPC前7格距离）
function MiniGameMap:CalculateTeleportPosition(npc)
    if not npc or not npc.entityName or not npc.pos3D then
        return nil
    end
    
    -- 获取NPC实体
    local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
    local entity = EntityManager.GetEntity(npc.entityName)
    if not entity then
        print("Warning: Cannot find NPC entity:", npc.entityName)
        return nil
    end
    
    local bx, by, bz = entity:GetBlockPos()
    local npcPos = {
        x = bx,
        y = by,
        z = bz,
    }
    
    -- 获取NPC朝向
    local facing = entity:GetFacing()
    if not facing then
        print("Warning: Cannot get NPC facing:", npc.entityName)
        return nil
    end
    
    -- 计算NPC前5格距离的位置
    local distance = 5  -- 距离NPC5格
    facing = facing + 0.57
    local offsetX = math.cos(facing) * distance
    local offsetZ = -math.sin(facing) * distance  -- Z轴方向相反
    
    local teleportPos = {
        x = math.floor(npc.pos3D.x + offsetX),  -- 四舍五入到整数坐标
        y = npc.pos3D.y,  -- 保持相同高度
        z = math.floor(npc.pos3D.z + offsetZ)   -- 四舍五入到整数坐标
    }
    
    -- 确保传送位置是安全的（检查是否在地面上）
    teleportPos = MiniGameMap.FindSafeTeleportPosition(teleportPos)
    
    return teleportPos, npcPos
end

-- 寻找安全的传送位置
function MiniGameMap.FindSafeTeleportPosition(pos)
    if not pos then
        return nil
    end
    
    -- 检查当前位置是否安全
    NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
    local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
    local blockEngine = BlockEngine
    if blockEngine then
        -- 检查脚下是否有方块支撑
        local groundBlockId = blockEngine:GetBlockId(pos.x, pos.y - 1, pos.z)
        local currentBlockId = blockEngine:GetBlockId(pos.x, pos.y, pos.z)
        local headBlockId = blockEngine:GetBlockId(pos.x, pos.y + 1, pos.z)
        
        -- 如果脚下有方块且当前位置和头部位置是空气，则位置安全
        if groundBlockId and groundBlockId ~= 0 and 
           (not currentBlockId or currentBlockId == 0) and 
           (not headBlockId or headBlockId == 0) then
            return pos
        end
        
        -- 如果当前位置不安全，尝试向上寻找安全位置（最多向上3格）
        for i = 1, 3 do
            local testPos = {
                x = pos.x,
                y = pos.y + i,
                z = pos.z
            }
            
            local testGroundId = blockEngine:GetBlockId(testPos.x, testPos.y - 1, testPos.z)
            local testCurrentId = blockEngine:GetBlockId(testPos.x, testPos.y, testPos.z)
            local testHeadId = blockEngine:GetBlockId(testPos.x, testPos.y + 1, testPos.z)
            
            if testGroundId and testGroundId ~= 0 and 
               (not testCurrentId or testCurrentId == 0) and 
               (not testHeadId or testHeadId == 0) then
                return testPos
            end
        end
    end
    
    -- 如果无法找到安全位置，返回原位置并增加1格高度作为保险
    return {
        x = pos.x,
        y = pos.y + 1,
        z = pos.z
    }
end


-- 计算二维距离（平方）
function MiniGameMap.Distance2DSq(p1, p2)
    if not p1 or not p2 then return math.huge end
    local dx = (p1.x or 0) - (p2.x or 0)
    local dz = (p1.z or 0) - (p2.z or 0)
    return dx * dx + dz * dz
end

-- 将场景 NPC 分配到距离最近的 MapArea
function MiniGameMap.DistributeNPCsToAreas()
    local areaMap = {}
    for _, area in ipairs(MapAreas or {}) do
        areaMap[area.id] = {}
    end
    local npcs = MiniGameMap:GetSceneNPCs() or {}
    for _, npc in ipairs(npcs) do
        local bestAreaId, bestDist = nil, math.huge
        for _, area in ipairs(MapAreas or {}) do
            local dist = MiniGameMap.Distance2DSq(npc.pos3D, area.pos)
            if dist < bestDist then
                bestDist = dist
                bestAreaId = area.id
            end
        end
        if bestAreaId then
            table.insert(areaMap[bestAreaId], npc)
        end
    end
    return areaMap
end

MiniGameMap.menu_node_data = {}
MiniGameMap.menu_data_sources = {}
MiniGameMap.type_node_list = {}
MiniGameMap.level_to_index = {}
MiniGameMap.menu_item_index = 0
MiniGameMap.cur_select_level = 1
MiniGameMap.cur_select_type_index = 1

function MiniGameMap.HandleCategoryDatas()
    -- reset state
    MiniGameMap.level_to_index = {}
    MiniGameMap.menu_item_index = 0
    MiniGameMap.menu_node_data = {}
    MiniGameMap.type_node_list = {}

    local areaMap = MiniGameMap.DistributeNPCsToAreas()
    local sources = {}

    for _, area in ipairs(MapAreas or {}) do
        local category = {
            name = area.showname or area.name,
            id = area.id,
            pos = area.pos,
            color = area.color,
            children = {},
        }
        local children = areaMap[area.id] or {}
        for _, npc in ipairs(children) do
            category.children[#category.children + 1] = {
                name = npc.name or npc.entityName or "NPC",
                server_data = npc,
            }
        end
        sources[#sources + 1] = category
    end

    MiniGameMap.menu_data_sources = sources

    local root = {}
    MiniGameMap.HandleMenuData(root, sources, 1)
    MiniGameMap.menu_node_data = root
end

-- 递归构建树形展示数据
function MiniGameMap.HandleMenuData(parent_t, data, level)
    if not MiniGameMap.level_to_index[level] then
        MiniGameMap.level_to_index[level] = 0
    end

    for k, v in ipairs(data or {}) do
        local temp_t = {}
        temp_t.name = (v.children == nil or #v.children == 0) and "item" or "type"
        temp_t.attr = {}
        temp_t.attr.server_data = v
        temp_t.attr.text = v.name
        temp_t.attr.level = level

        -- 该层的索引（用于展开/折叠）
        MiniGameMap.level_to_index[level] = (MiniGameMap.level_to_index[level] or 0) + 1
        if temp_t.name == "type" then
            temp_t.attr.index = MiniGameMap.level_to_index[level]
        end

        -- 有子节点则递归构建
        if v.children and #v.children > 0 then
            local next_level = level + 1
            MiniGameMap.HandleMenuData(temp_t, v.children, next_level)
        else
            -- 叶子项（NPC），分配 menu_item_index
            MiniGameMap.menu_item_index = (MiniGameMap.menu_item_index or 0) + 1
            temp_t.attr.menu_item_index = MiniGameMap.menu_item_index
        end

        parent_t[k] = temp_t

        -- 记录所有 type 节点，便于快速切换展开态
        if temp_t.name == "type" then
            MiniGameMap.type_node_list[#MiniGameMap.type_node_list + 1] = temp_t
        end
    end
end

-- DataSource 供 pe:treeview 使用
function MiniGameMap.TreeItems()
    if not MiniGameMap.menu_node_data or #MiniGameMap.menu_node_data == 0 then
        MiniGameMap.HandleCategoryDatas()
    end
    return MiniGameMap.menu_node_data
end

function MiniGameMap.TypeBeExpand(expanded)
    return expanded == true
end

-- 切换分类展开状态（与 KeepWorkMallPage.ChangeMenuType 对齐）
function MiniGameMap.ChangeMenuType(level, index)
    -- ensure numeric types from MCML params
    level = tonumber(level) or level
    index = tonumber(index) or index

    MiniGameMap.cur_select_level = level
    MiniGameMap.cur_select_type_index = index
    MiniGameMap.changeMenuNodeType(MiniGameMap.menu_node_data, level, index)
    MiniGameMap.OnRefresh()
end

function MiniGameMap.changeMenuNodeType(data, level, index)
    for _, node in ipairs(MiniGameMap.type_node_list or {}) do
        if node.attr and node.attr.level == level and node.attr.index == index then
            node.attr.expanded = not node.attr.expanded
        end
    end
end

function MiniGameMap.ExpandedNode(data, level, index)
    for _, node in ipairs(MiniGameMap.type_node_list or {}) do
        if node.attr then
            node.attr.expanded = (node.attr.level == level and node.attr.index == index)
        end
    end
    return true
end

function MiniGameMap.ChangeMenuItem(node, menu_item_index)
    MiniGameMap.cur_select_menu_item_index = menu_item_index
    local server_data = node and node.server_data and node.server_data.server_data
    if not server_data then return end
    if server_data.entityName and server_data.entityName ~= "" then
        MiniGameMap:TeleportNpcImp({ entityName = server_data.entityName })
        MiniGameMap.ClosePage()
        return
    end
    if server_data.pos then
        MiniGameMap:TeleportToPos(server_data.pos)
        MiniGameMap.ClosePage()
        return
    end
end

function MiniGameMap.OnRefresh()
    if page then page:Refresh(0) end
end

