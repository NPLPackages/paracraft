--[[
    -- 编辑存档点信息逻辑
    -- 支持编辑 actionname、subTag、isAllowEdit、isAllowSetAsHome、recommendModels、spawnRelativePos、spawnFacing 属性
    local EasyEditCheckPoint = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditCheckPoint.lua")
    EasyEditCheckPoint.ShowPage(checkPoint,entity)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityUserPoint.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EntityUserPoint = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityUserPoint");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks")

local EasyEditCheckPoint = NPL.export()

local page
local targetEntity
local spawnPointIndicator  -- EntityUserPoint to visualize spawn location
local editableRegionBorderGroupId = 6  -- Group ID for editable region border highlight

function EasyEditCheckPoint.OnInit()
    page = document:GetPageCtrl();
    page:SetValue("allowEdit", EasyEditCheckPoint.allowEdit)
    page:SetValue("allowSetAsHome", EasyEditCheckPoint.allowSetAsHome)
end

-- Helper function to destroy spawn point indicator
local function DestroySpawnPointIndicator()
    if spawnPointIndicator then
        spawnPointIndicator:Disconnect("dragEnded", EasyEditCheckPoint, EasyEditCheckPoint.OnSpawnIndicatorDragEnded);
        spawnPointIndicator:Destroy();
        spawnPointIndicator = nil;
    end
end

-- Helper function to clear editable region border highlight
local function ClearEditableRegionBorder()
    ParaTerrain.DeselectAllBlock(editableRegionBorderGroupId);
end

-- Helper function to show editable region border highlight
local function ShowEditableRegionBorder(editableRegionStr)
    if not editableRegionStr or editableRegionStr == "" then
        ClearEditableRegionBorder()
        return
    end
    
    if not targetEntity then
        return
    end
    
    -- Parse editable region string: ~x ~y ~z (dx dy dz)
    local parts = {}
    for part in string.gmatch(editableRegionStr, "[^%s]+") do
        table.insert(parts, part)
    end
    
    if #parts ~= 6 then
        return  -- Invalid format
    end
    
    -- Parse relative min position (~x ~y ~z)
    local rel_min_x = tonumber(string.match(parts[1], "~(%-?%d+)"))
    local rel_min_y = tonumber(string.match(parts[2], "~(%-?%d+)"))
    local rel_min_z = tonumber(string.match(parts[3], "~(%-?%d+)"))
    
    if not rel_min_x or not rel_min_y or not rel_min_z then
        return  -- Invalid format
    end
    
    -- Parse dimensions (dx dy dz)
    local dxdydz = parts[4] .. " " .. parts[5] .. " " .. parts[6]
    local dx, dy, dz = string.match(dxdydz, "%((%d+)%s+(%d+)%s+(%d+)%)")
    dx, dy, dz = tonumber(dx), tonumber(dy), tonumber(dz)
    
    if not dx or not dy or not dz then
        return  -- Invalid format
    end
    
    -- Get checkpoint block position
    local cx, cy, cz = targetEntity:GetBlockPos()
    if not cx then
        return
    end
    
    -- Calculate absolute min/max positions
    local min_x = cx + rel_min_x
    local min_y = cy + rel_min_y
    local min_z = cz + rel_min_z
    local max_x = min_x + dx
    local max_y = min_y + dy
    local max_z = min_z + dz
    
    -- Clear previous border
    ClearEditableRegionBorder()
    
    -- Draw border one block bigger than the region in x,z plane
    -- Draw the rectangle at y = min_y (bottom of the region)
    local border_y = min_y
    
    -- Draw bottom border (expand by 1 block in all directions in x,z plane)
    for x = min_x - 1, max_x + 1 do
        for z = min_z - 1, max_z + 1 do
            -- Only draw the border (edges), not fill
            if x == min_x - 1 or x == max_x + 1 or z == min_z - 1 or z == max_z + 1 then
                ParaTerrain.SelectBlock(x, border_y+1, z, true, editableRegionBorderGroupId);
            end
        end
    end
end

-- Handler for when spawn point indicator is dragged
function EasyEditCheckPoint:OnSpawnIndicatorDragEnded(dragLocation)
    if not spawnPointIndicator or not targetEntity or not page then
        return
    end
    
    -- Get new position of spawn indicator
    local spawnX, spawnY, spawnZ = spawnPointIndicator:GetPosition()
    if not spawnX then
        return
    end
    
    -- Get checkpoint position
    local cx, cy, cz = targetEntity:GetPosition()
    if not cx then
        return
    end
    
    -- Calculate relative position
    local dx = spawnX - cx
    local dy = spawnY - cy
    local dz = spawnZ - cz
    
    -- Clamp to 30 meters max
    dx = math.max(-30, math.min(30, dx))
    dy = math.max(-30, math.min(30, dy))
    dz = math.max(-30, math.min(30, dz))
    
    -- Format as string
    local spawnRelativePosStr = string.format("%.2f,%.2f,%.2f", dx, dy, dz)
    
    -- Get facing of spawn indicator
    local facing = spawnPointIndicator:GetFacing() or 0
    -- Convert from radians to degrees and normalize to 0-360
    local facingDegrees = math.deg(facing) % 360
    local spawnFacingStr = string.format("%.1f", facingDegrees)
    
    -- Update UI values
    EasyEditCheckPoint.spawnRelativePos = spawnRelativePosStr
    EasyEditCheckPoint.spawnFacing = spawnFacingStr
    
    -- Refresh the page to show updated values
    if page then
        page:Refresh(0.01)
    end
    
    GameLogic.AddBBS(nil, string.format(L"出生点位置已更新: %s, 朝向: %s°", spawnRelativePosStr, spawnFacingStr), 2000, "0 255 0")
end

-- Helper function to create/update spawn point indicator
function EasyEditCheckPoint.UpdateSpawnPointIndicator()
    if not targetEntity then
        return
    end
    
    -- Parse spawn relative position
    local spawnRelativePosStr = page and page:GetUIValue("spawnRelativePos", "0,0,0") or EasyEditCheckPoint.spawnRelativePos or "0,0,0"
    local parts = {}
    for part in string.gmatch(spawnRelativePosStr, "[^,]+") do
        table.insert(parts, part)
    end
    
    -- Default to 0,0,0 if format is invalid or empty
    local dx = 0
    local dy = 0
    local dz = 0
    
    if #parts == 3 then
        dx = tonumber(parts[1]) or 0
        dy = tonumber(parts[2]) or 0
        dz = tonumber(parts[3]) or 0
    end
    
    -- Get checkpoint position
    local cx, cy, cz = targetEntity:GetPosition()
    if not cx then
        return
    end
    
    -- Calculate spawn position
    local spawnX = cx + dx
    local spawnY = cy + dy
    local spawnZ = cz + dz
    
    -- Parse spawn facing
    local spawnFacingStr = page and page:GetUIValue("spawnFacing", "0") or EasyEditCheckPoint.spawnFacing or "0"
    local facingDegrees = tonumber(spawnFacingStr) or 0
    local facingRadians = math.rad(facingDegrees)
    
    -- Create or update indicator
    if not spawnPointIndicator then
        spawnPointIndicator = EntityUserPoint:new():init()
        if spawnPointIndicator then
            spawnPointIndicator:SetPersistent(false)
            spawnPointIndicator:SetCanDrag(true)
            spawnPointIndicator:SetAutoTurningDuringDragging(true)
            spawnPointIndicator:SetDisplayName(L"出生点")
            spawnPointIndicator:Attach()
            spawnPointIndicator:SetCommand(L"出生点");
            spawnPointIndicator:Refresh()
            
            -- Connect drag ended event to update spawn position and facing
            spawnPointIndicator:Connect("dragEnded", EasyEditCheckPoint, EasyEditCheckPoint.OnSpawnIndicatorDragEnded, "UniqueConnection");
        end
    end
    
    if spawnPointIndicator then
        spawnPointIndicator:SetPosition(spawnX, spawnY, spawnZ)
        spawnPointIndicator:SetFacing(facingRadians)
    end
end

function EasyEditCheckPoint.ShowPage(checkPoint,entity)
    targetEntity = entity
    if not targetEntity then
        _guihelper.MessageBox(L"请先选择一个存档点实体");
        return
    end
    
    
    -- 获取当前存档点的属性
    EasyEditCheckPoint.actionname = targetEntity:GetStaticTag("actionname") or L"存档点"
    EasyEditCheckPoint.subtag = targetEntity:GetStaticTag("subtag") or ""
    EasyEditCheckPoint.allowEdit = targetEntity:GetStaticTag("isAllowEdit") or "true"
    EasyEditCheckPoint.allowSetAsHome = targetEntity:GetStaticTag("isAllowSetAsHome") or "false"
    EasyEditCheckPoint.recommendModels = targetEntity:GetStaticTag("recommendModels") or ""
    local spawnRelativePosStr = targetEntity:GetStaticTag("spawnRelativePos") or "0,0,0"
    EasyEditCheckPoint.spawnRelativePos = spawnRelativePosStr
    local spawnFacingStr = targetEntity:GetStaticTag("spawnFacing") or "0"
    EasyEditCheckPoint.spawnFacing = spawnFacingStr
    local editableRegionStr = targetEntity:GetStaticTag("editableRegion") or ""
    EasyEditCheckPoint.editableRegion = editableRegionStr
    
    -- 显示编辑页面
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditCheckPoint.html",
        name = "EasyEditCheckPoint.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        bToggleShowHide = false, 
        directPosition = true,
        align = "_lt",
        x = 20,
        y = 90,
        width = 460,
        height = 660,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params)

    -- Update spawn point indicator after page is loaded
    EasyEditCheckPoint.UpdateSpawnPointIndicator()
    
    -- Show editable region border if set
    ShowEditableRegionBorder(editableRegionStr)
end

-- 保存存档点属性
function EasyEditCheckPoint.OnSave()
    if not targetEntity then
        return
    end
    local actionname = page:GetUIValue("actionname", "")
    local subtag = page:GetUIValue("subtag", "")
    local isAllowEdit = page:GetUIValue("allowEdit", "true")
    local isAllowSetAsHome = page:GetUIValue("allowSetAsHome", "true")
    local recommendModels = page:GetUIValue("recommendModels", "")
    local spawnRelativePos = page:GetUIValue("spawnRelativePos", "4,0,0")
    local spawnFacing = page:GetUIValue("spawnFacing", "0")
    local editableRegion = page:GetUIValue("editableRegion", "")
    targetEntity:SetTagField("actionname", actionname)
    targetEntity:SetTagField("subtag", subtag)
    targetEntity:SetTagField("isAllowEdit", isAllowEdit)
    targetEntity:SetTagField("isAllowSetAsHome", isAllowSetAsHome)
    targetEntity:SetTagField("recommendModels", recommendModels)
    targetEntity:SetTagField("spawnRelativePos", spawnRelativePos)
    targetEntity:SetTagField("spawnFacing", spawnFacing)
    targetEntity:SetTagField("editableRegion", editableRegion)
    GameLogic.AddBBS(nil, L"存档点属性保存成功", 2000, "0 255 0")
    EasyEditCheckPoint.OnCancel()
end

function EasyEditCheckPoint.OnCancel()
    DestroySpawnPointIndicator()
    ClearEditableRegionBorder()
    if page then
        page:CloseWindow()
    end
end

function EasyEditCheckPoint.OnReset()
    if not targetEntity then
        return
    end
    EasyEditCheckPoint.actionname = L"存档点"
    EasyEditCheckPoint.subtag = ""
    EasyEditCheckPoint.allowEdit = "true"
    EasyEditCheckPoint.allowSetAsHome = "false"
    EasyEditCheckPoint.recommendModels = ""
    EasyEditCheckPoint.spawnRelativePos = "4,0,0"
    EasyEditCheckPoint.spawnFacing = "0"
    EasyEditCheckPoint.editableRegion = ""
    if page then
        page:Refresh(0.1)
    end
    EasyEditCheckPoint.UpdateSpawnPointIndicator()
    ClearEditableRegionBorder()
end

function EasyEditCheckPoint.ValidateInput()
    local actionname = page:GetUIValue("actionname", "")
    if actionname == "" then
        GameLogic.AddBBS(nil, L"存档点名称不能为空", 2000, "255 0 0")
        return false
    end
    local subtag = page:GetUIValue("subtag", "")
    if subtag == "" then
        GameLogic.AddBBS(nil, L"子标签不能为空", 2000, "255 0 0")
        return false
    end
    -- 验证subtag只包含大小写字母、数字和下划线
    if not string.match(subtag, "^[a-zA-Z0-9_]+$") then
        GameLogic.AddBBS(nil, L"子标签只能包含大小写字母、数字和下划线", 2000, "255 0 0")
        return false
    end
    -- 验证spawnRelativePos格式
    local spawnRelativePos = page:GetUIValue("spawnRelativePos", "")
    if spawnRelativePos ~= "" then
        local parts = {}
        for part in string.gmatch(spawnRelativePos, "[^,]+") do
            table.insert(parts, part)
        end
        if #parts ~= 3 then
            GameLogic.AddBBS(nil, L"出生相对位置格式错误，应为: dx,dy,dz (例如: 0,1,0)", 2000, "255 0 0")
            return false
        end
        for i, part in ipairs(parts) do
            local num = tonumber(part)
            if not num then
                GameLogic.AddBBS(nil, L"出生相对位置必须是数字，格式: dx,dy,dz (例如: 0,1,0)", 2000, "255 0 0")
                return false
            end
            -- 验证不超过30米
            if math.abs(num) > 30 then
                GameLogic.AddBBS(nil, L"出生相对位置不能超过30米", 2000, "255 0 0")
                return false
            end
        end
    end
    -- 验证spawnFacing格式
    local spawnFacing = page:GetUIValue("spawnFacing", "")
    if spawnFacing ~= "" then
        local num = tonumber(spawnFacing)
        if not num then
            GameLogic.AddBBS(nil, L"出生朝向必须是数字 (例如: 0, 90, 180, 270)", 2000, "255 0 0")
            return false
        end
    end
    -- 验证editableRegion格式
    local editableRegion = page:GetUIValue("editableRegion", "")
    if editableRegion ~= "" then
        local parts = {}
        for part in string.gmatch(editableRegion, "[^%s]+") do
            table.insert(parts, part)
        end
        if #parts ~= 6 then
            GameLogic.AddBBS(nil, L"可编辑区域格式错误，应为: ~x ~y ~z (dx dy dz) 例如: ~-6 ~-1 ~2 (5 0 2)", 2000, "255 0 0")
            return false
        end
        -- 验证前3个参数是相对坐标(~开头)
        for i = 1, 3 do
            if not string.match(parts[i], "^~%-?%d+$") then
                GameLogic.AddBBS(nil, L"可编辑区域的最小位置必须以~开头，例如: ~-6 ~-1 ~2", 2000, "255 0 0")
                return false
            end
        end
        -- 验证后3个参数在括号内且是正数
        local dxdydz = parts[4] .. " " .. parts[5] .. " " .. parts[6]
        if not string.match(dxdydz, "^%(%s*%d+%s+%d+%s+%d+%s*%)$") then
            GameLogic.AddBBS(nil, L"可编辑区域的大小必须在括号内，例如: (5 0 2)", 2000, "255 0 0")
            return false
        end
    end
    return true
end

-- Called when spawn position input changes
function EasyEditCheckPoint.OnSpawnPosChanged()
    EasyEditCheckPoint.UpdateSpawnPointIndicator()
end

-- Called when editable region input changes
function EasyEditCheckPoint.OnEditableRegionChanged()
    if not page then
        return
    end
    
    local editableRegionStr = page:GetUIValue("editableRegion", "")
    ShowEditableRegionBorder(editableRegionStr)
end

-- 使用选中的方块来设置可编辑区域
function EasyEditCheckPoint.OnClickUseSelectedBlock()
    if not targetEntity then
        GameLogic.AddBBS(nil, L"请先选择一个存档点实体", 2000, "255 0 0")
        return
    end
    
    -- Get currently selected blocks from SelectBlocks task
    local selectTask = SelectBlocks.GetCurrentInstance()
    if not selectTask then
        GameLogic.AddBBS(nil, L"请先选择方块 (Ctrl+左键)", 2000, "255 255 0")
        return
    end
    
    local blocks = SelectBlocks.GetSelectedBlocks()
    if not blocks or #blocks == 0 then
        GameLogic.AddBBS(nil, L"请先选择方块 (Ctrl+左键)", 2000, "255 255 0")
        return
    end
    
    -- Get checkpoint position
    local cx, cy, cz = targetEntity:GetBlockPos()
    if not cx then
        GameLogic.AddBBS(nil, L"无法获取存档点位置", 2000, "255 0 0")
        return
    end
    
    -- Calculate bounding box of selected blocks
    local first_block = blocks[1]
    local min_x, min_y, min_z = first_block[1], first_block[2], first_block[3]
    local max_x, max_y, max_z = min_x, min_y, min_z
    
    for _, b in ipairs(blocks) do
        local x, y, z = b[1], b[2], b[3]
        if x < min_x then min_x = x end
        if y < min_y then min_y = y end
        if z < min_z then min_z = z end
        if x > max_x then max_x = x end
        if y > max_y then max_y = y end
        if z > max_z then max_z = z end
    end
    
    -- Calculate relative position from checkpoint
    local rel_min_x = min_x - cx
    local rel_min_y = min_y - cy
    local rel_min_z = min_z - cz
    
    -- Calculate dimensions (dx, dy, dz)
    local dx = max_x - min_x
    local dy = max_y - min_y
    local dz = max_z - min_z
    
    -- Format as: ~x ~y ~z (dx dy dz)
    local editableRegionStr = string.format("~%d ~%d ~%d (%d %d %d)", 
        rel_min_x, rel_min_y, rel_min_z, dx, dy, dz)
    
    -- Update UI value
    EasyEditCheckPoint.editableRegion = editableRegionStr
    
    -- Clear the selection after using it
    SelectBlocks.CancelSelection()

    -- Refresh the page to show updated values
    if page then
        page:Refresh(0.01)
    end
    
    -- Show the border highlight for the new region
    commonlib.TimerManager.SetTimeout(function()
        ShowEditableRegionBorder(editableRegionStr)
    end, 500)
    
    GameLogic.AddBBS(nil, string.format(L"可编辑区域已更新: %s", editableRegionStr), 2000, "0 255 0")
end