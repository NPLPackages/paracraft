--[[
Title: AStartQuery
Author(s): yangguiyi
Date: 2021/10/20
Desc: 
Use Lib:
-------------------------------------------------------
local AStartQuery = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/AStartQuery.lua");
AStartQuery.GetPath({19161,4,19195})
--]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GetBlockTemplateByIdx = ParaTerrain.GetBlockTemplateByIdx

local AStartQuery = NPL.export();
local OpenList = {}
local CloseList = {}

local StartPos = nil
local EndPos = nil
local TargetPath = {}

local IsDebug = true
function AStartQuery.GetPath(end_pos)
    if end_pos[1] and end_pos.x == nil then
        end_pos = {x = end_pos[1], y = end_pos[2], z = end_pos[3]}
    end

    local player = EntityManager.GetFocus();
    local x, y, z = player:GetBlockPos();
    StartPos = {x=x, y=y, z=z}
    EndPos = end_pos
    EndPos.y = StartPos.y

    OpenList = {}
    CloseList = {}
    TargetPath = {}

    AStartQuery.AddOpenListItem(AStartQuery.GetListKeyByPos(StartPos), AStartQuery.CreateNodeByPos(StartPos))

    AStartQuery.Search()
    if IsDebug then
        ParaTerrain.DeselectAllBlock(3);
        for key, pos in pairs(TargetPath) do
            ParaTerrain.SelectBlock(pos.x,pos.y,pos.z, true, 3);
        end
    end

    return TargetPath
end

function AStartQuery.Search()
    local next_node = AStartQuery.GetNextNode()
    if not next_node then
        return
    end

    AStartQuery.GetArroundNode(next_node)

    -- ParaTerrain.DeselectAllBlock(3);
    -- ParaTerrain.SelectBlock(next_node.pos.x,next_node.pos.y,next_node.pos.z, true, 3);   
    local next_pos = next_node.pos
    if next_pos.x == EndPos.x and next_pos.y == EndPos.y and next_pos.z == EndPos.z then
        AStartQuery.FindPath(next_node)
    else
    
        -- commonlib.TimerManager.SetTimeout(function()
        --     AStartQuery.Search()
        -- end, 100)

        AStartQuery.Search()
    end
end

function AStartQuery.FindPath(node)
    TargetPath[#TargetPath + 1] = node.pos
    if node.parent then
        AStartQuery.FindPath(node.parent)
    else
        -- if IsDebug then
        --     print("cccccccccccccccc", #TargetPath)
        --     for key, pos in pairs(TargetPath) do
        --         ParaTerrain.SelectBlock(pos.x,pos.y,pos.z, true, 3);
        --     end
           
        -- end
    end
end

function AStartQuery.GetArroundNode(node)
    -- 找出node周围的点
    -- 只考虑二维
    local center_pos = node.pos
    local start_pos = center_pos.x - 1, center_pos.y, center_pos.z + 1
    local end_pos = center_pos.x + 1, center_pos.y, center_pos.z - 1

    for find_x = center_pos.x - 1, center_pos.x + 1 do
        for find_z = center_pos.z - 1, center_pos.z + 1 do
            local pos = {x=find_x, y=center_pos.y, z=find_z}
            local list_key = AStartQuery.GetListKeyByPos(pos)
            if not AStartQuery.CheckCloseList(list_key) then
                local dest_id = GetBlockTemplateByIdx(pos.x, pos.y, pos.z); 
                if dest_id == 0 then
                    -- 看看openlist有没有
                    local check_node = AStartQuery.GetOpenListNode(list_key)
                    if check_node then
                        -- 如果openlist已经存在了 那要比较以当前节点为父节点的g值 跟 原本的g值 看哪个比较小
                        local temp_node = AStartQuery.CreateNodeByPos(pos, node)
                        if temp_node.g < check_node.g then
                            AStartQuery.CopyNode(check_node, temp_node)
                        end
                    else
                        AStartQuery.AddOpenListItem(list_key, AStartQuery.CreateNodeByPos(pos, node))
                    end
                else
                    AStartQuery.AddCloseListItem(list_key)
                end
            end
        end
    end
end


function AStartQuery.GetNodeFValue()
end
-- 从OpenList找出F值最小的
function AStartQuery.GetNextNode()
    -- if #OpenList == 0 then
    --     print(">>>>>>>>>>>>>>>>>>>>>>error, #OpenList == 0")
    --     return
    -- end
    -- print("ttttttttttttt")
    -- echo(OpenList, true)

    local target_node = nil
    local min_value = 999999
    local index
    for k, v in pairs(OpenList) do
        if v and v.f <= min_value then
            min_value = v.f
            index = k
        end
    end

    if index then
        target_node = OpenList[index]
        OpenList[index] = nil
        local target_node_pos = target_node.pos
        AStartQuery.AddCloseListItem(AStartQuery.GetListKeyByPos(target_node.pos))
    end

    return target_node
end

function AStartQuery.AddOpenListItem(key, node)
    
    if OpenList[key] == nil then
        -- print("AStartQuery.AddOpenListItem",OpenList[key], key, node)
        OpenList[key] = node
    end
end

function AStartQuery.GetOpenListNode(key)
    return OpenList[key]
end

function AStartQuery.AddCloseListItem(key)
    if CloseList[key] == nil then
        CloseList[key] = 1
    end
end

function AStartQuery.CheckCloseList(key)
    return CloseList[key] ~= nil
end

function AStartQuery.GetListKeyByPos(pos)
    return string.format("%s_%s_%s", pos.x, pos.y, pos.z)
end

-- F = G + H
-- G 从父节点到当前格子的代价（累计）
-- H 用Manhattan方法计算 也就是从当前格子到目标格子的纵向或者横向距离
function AStartQuery.CreateNodeByPos(pos, parent)
    local node = AStartQuery.GetNode(pos)
    node.parent = parent
    -- 计算g值
    if parent then
        node.g = parent.g + AStartQuery.GetDistance(pos, parent.pos)
    end

    node.h = math.abs(EndPos.x - pos.x) + math.abs(EndPos.z - pos.z)
    node.f = node.g + node.h

    return node
end

function AStartQuery.GetDistance(start_pos, end_pos)
    return (end_pos.x - start_pos.x)^2 + (end_pos.y - start_pos.y)^2 + (end_pos.z - start_pos.z)^2
end

function AStartQuery.GetNode(pos)
    local node = {
        f = 0, 
        g = 0, 
        h = 0, 
        pos = pos, 
        parent = nil,
    }

    return node
end

function AStartQuery.CopyNode(check_node, temp_node)
    check_node.f = temp_node.f
    check_node.g = temp_node.g
    check_node.h = temp_node.h
    check_node.pos = temp_node.pos
    check_node.parent = temp_node.parent
end