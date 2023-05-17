--[[
    author:{author}
    time:2022-05-23 09:55:14
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockManager.lua") 
        local DockManager = commonlib.gettable("MyCompany.Aries.Game.DockManager")
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockManager.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockItem.lua") 
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockLayer.lua")
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local DockItem = commonlib.gettable("MyCompany.Aries.Game.Dock.DockItem") 
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Screen = commonlib.gettable("System.Windows.Screen");
local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
local DockLayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.DockLayer")
local DockManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Game.DockManager"))
DockItem:Property({"showmap", nil, "IsShowMap", "SetShowMap"});
local viewport = ViewportManager:GetSceneViewport()

function DockManager:OnInit()
    self:RegisterEvent()
    DockLayer:OnInit()
end

function DockManager:RegisterEvent()
    GameLogic.GetFilters():add_filter("show", DockManager.ShowCommandFilter);
    GameLogic.GetFilters():add_filter("hide", DockManager.HideCommandFilter);
    GameLogic:Connect("WorldLoaded", DockManager, DockManager.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", DockManager, DockManager.OnWorldUnloaded, "UniqueConnection");
    Screen:Connect("sizeChanged",DockManager,DockManager.ScreenChanged,"UniqueConnection")
    viewport:Connect("sizeChanged", DockManager, DockManager.RefreshPosition, "UniqueConnection");
end

function DockManager.ShowCommandFilter(name)
    local self = DockManager
    LOG.std(nil, "debug", "DockManager", "ShowCommandFilter--------------name: %s",name)
    if name == "esc" then
        self:ShowEsc(true,true)
        return 
    end
    if name == "dock" then
        self:ShowDockPage(true)
        return 
    end
    if name == "dock_left_top" then
        self:ShowDockPage(true,"_lt")
        return 
    end
    if name == "dock_left_bottom" then
        self:ShowDockPage(true,"_lb")
        return 
    end
    if name == "dock_right_top" then
        self:ShowDockPage(true,"_rt")
        return 
    end
    if name == "dock_center_bottom" then
        self:ShowDockPage(true,"_ctb")
        return 
    end
    if name == "dock_right_bottom" then
        self:ShowDockPage(true,"_rb")
        return 
    end
    if name == "map" then
        self:AddNewDock("mini_map")
        return 
    end
    if name == "miniuserinfo" then
        self:AddNewDock("mini_userinfo")
        return 
    end
    if name == "quickselectbar" or name == "desktop" then
        self:ShowEsc(true,true)
    end
    return name
end

function DockManager.HideCommandFilter(name)
    local self = DockManager
    LOG.std(nil, "debug", "DockManager", "HideCommandFilter--------------name: %s",name)
    if name == "esc" then
        self:ShowEsc(false,true)
        return
    end
    if name == "map" then
        self:RemoveDock("mini_map")
        return 
    end
    if name == "miniuserinfo" then
        self:RemoveDock("mini_userinfo")
        return 
    end
    if name == "dock" then
        self:ShowDockPage(false)
        return 
    end
    if name == "dock_left_top" then
        self:ShowDockPage(false,"_lt")
        return 
    end
    if name == "dock_left_bottom" then
        self:ShowDockPage(false,"_lb")
        return 
    end
    if name == "dock_right_top" then
        self:ShowDockPage(false,"_rt")
        self:ShowEsc(false,true)
        return 
    end
    if name == "dock_center_bottom" then
        self:ShowDockPage(false,"_ctb")
        return 
    end
    if name == "dock_right_bottom" then
        self:ShowDockPage(false,"_rb")
        return 
    end
    if name == "quickselectbar" or name == "desktop" then
        self:ShowEsc(false,true)
    end
    return name
end

function DockManager:ShowEsc(bShow,bCommand)
    DockLayer:ShowEsc(bShow,bCommand)
end

function DockManager:IsShowEsc()
    return DockLayer:IsShowEsc()
end

function DockManager:ShowDockPage(bShow,align) --并行世界
    DockLayer:ShowDockPage(bShow,align)
end

function DockManager:ScreenChanged()
    self:RePosition()
end

function DockManager:OnWorldLoaded()
    DockLayer:OnWorldLoaded()
end

function DockManager:OnWorldUnloaded()
    DockLayer:OnWorldUnloaded()
end

function DockManager:RemoveDockByIndex(index)
    DockLayer:RemoveDockByIndex(index)
end

function DockManager:RemoveDock(name)
    DockLayer:RemoveDock(name)
end

function DockManager:GetDockByName(name)
    return DockLayer:GetDockByName(name)
end

function DockManager:GetIndexByName(name)
    return DockLayer:GetIndexByName(name)
end

function DockManager:GetItemsByAlign(align)
    return DockLayer:GetItemsByAlign(align)
end

function DockManager:GetAllButtonDocks()
    return DockLayer:GetAllButtonDocks()
end

function DockManager:GetDockKey()
    return DockLayer:GetCurKey()
end

function DockManager:RePosition()
    DockLayer:RePosition()
end

function DockManager.RefreshPosition()
    DockLayer:RePosition()
end

function DockManager:SetDockVisible(name,bIsVisible)
    DockLayer:SetDockVisible(name,bIsVisible)
end

function DockManager:SetAllDockVisible(bIsVisible)
    DockLayer:SetAllDockVisible(bIsVisible)
end

function DockManager:SetDockItemsVisibleByAlign(align,bIsVisible)
    DockLayer:SetDockItemsVisivleByAlign(align,bIsVisible)
end

function DockManager:DebugDockInfo()
    print("DockManager:DebugDockInfo================")
    echo(DockLayer.m_dockNames,true)
end

function DockManager:AddNewDock(objParams)
    return DockLayer:AddNewDock(objParams)
end

function DockManager:HideAllDock()
    DockLayer:HideAllDock()
end

function DockManager:ShowAllDock()
    DockLayer:ShowAllDock()
end

function DockManager:RemoveAllDock()
    DockLayer:RemoveAllDock()
end

function DockManager:SetAllDockOpcatity(opcatity)
    DockLayer:SetAllDockOpcatity(opcatity)
end

function DockManager:GetCurKey()
    return DockLayer:GetCurKey()
end

function DockManager:AddRedTip(name,redParams)
    DockLayer:AddRedTip(name,redParams)
end

function DockManager:RemoveRedTip(name)
    DockLayer:RemoveRedTip(name)
end

function DockManager:ShowDockByKey(cfgKey)
    DockLayer:ShowDockByKey(cfgKey)
end

--处理图片相关
function DockManager.GetImageInfo(filename)
	return ParaMovie.GetImageInfo(filename)
end

function DockManager.ResizeImage(filename,width,height,destFile)
    local ext = string.lower(commonlib.Files.GetFileExtension(filename))
    if ext and ext == "jpg" or ext == "png" then
        return ParaMovie.ResizeImage(filename,width,height,destFile)
    end
end

-- 
local time = 0
local info = {}
local engine_attr = ParaEngine.GetAttributeObject();
function DockManager.StartTimer()
    DockManager.dock_timer = DockManager.dock_timer or commonlib.Timer:new({callbackFunc = DockManager.GenerateInfoStr})
	DockManager.dock_timer:Change(300, 300);
end

function DockManager.EndTimer(isWorldUnLoad)
    if DockManager.dock_timer then
        DockManager.dock_timer:Change()
        DockManager.dock_timer = nil
    end
    if isWorldUnLoad then
        time = 0
        info = {}
    end
end

function DockManager:GetWorldName()
    return WorldCommon.GetWorldTag("name")
end

function DockManager.WriteInfo()
    local worldName = DockManager:GetWorldName()
    local guid = ParaGlobal.GenerateUniqueID()
    DockManager.EndTimer()
    time = 0
    local filename = "temp/profile/"..commonlib.Encoding.Utf8ToDefault(worldName).."_"..tostring(ParaGlobal.timeGetTime())..".txt"
	if(not ParaIO.DoesFileExist(filename)) then
        ParaIO.CreateDirectory(filename);
    end
	local out = ParaIO.open(filename, "w");
    out:WriteString(table.concat(info));
    out:close();
    info = {}
end

function DockManager.GenerateInfoStr(timer)
	time = time + timer:GetDelta()
	if math.floor(time/1000) >= 1 then
		local entityPlayer = GameLogic.EntityManager.GetFocus();
		if(not entityPlayer) then
			return;
		end
		local x, y, z = entityPlayer:GetBlockPos();
		local dir = Direction.directions[Direction.GetDirection2DFromCamera()];
		info[#info + 1] = ParaGlobal.GetDateFormat("yyyy-MM-dd").."_"..ParaGlobal.GetTimeFormat("HH:mm:ss")..",".. string.format("position:%d %d %d:%s,", x, y, z, dir or "") .. string.format("FPS:%.0f, Draw:%d ,Tri:%d, Mem:%d, VB:%d \r\n", engine_attr:GetField("FPS", 0), engine_attr:GetField("DrawCallCount", 0), engine_attr:GetField("TriangleCount", 0),engine_attr:GetField("CurrentMemoryUse", 0)/1048576, engine_attr:GetField("VertexBufferPoolTotalBytes", 0)/1048576)

		time = 0
	end
end


