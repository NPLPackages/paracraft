--[[
Title: DockLayer
Author(s): pengbinbin
Date: 2022-05-23 09:54:50
Desc: 
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockLayer.lua")
local DockLayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.DockLayer")
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockItem.lua") 
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockLayer.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileMainPage.lua")
local MobileMainPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileMainPage");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Screen = commonlib.gettable("System.Windows.Screen");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local DockItem = commonlib.gettable("MyCompany.Aries.Game.Dock.DockItem") 
local DockConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockConfig.lua") 
local DockLayer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Game.Tasks.DockLayer"))

function DockLayer:ctor()
    self.m_current_dockkey = ""
    self.m_bShowEsc = nil
	self.m_dockNames = {}
	self.m_tblShowDocks = {};
end

function DockLayer:OnInit()
    self:RegisterEvent()
end

function DockLayer:RegisterEvent()
    GameLogic.GetFilters():add_filter("update_dock", function(bShow)
        self:ShowEsc(not bShow)
    end);

    GameLogic.GetFilters():add_filter("esc_view_show", function(bShow) --把透明度变成1
        self:ChangeDockAlpha()
    end);

    GameLogic.GetFilters():add_filter("DesktopModeChanged", function(mode)
        local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
        if not IsMobileUIEnabled then
            self:OnChangeDesktopMode(mode);
        end
        return mode
    end);
    GameLogic.GetFilters():add_filter("Macro_BeginPlay", function()
        self:ShowEsc(false)
    end);
    GameLogic.GetFilters():add_filter("Macro_EndPlay", function()
        self:ShowEsc(true)
    end);
    GameLogic.GetFilters():add_filter("OnWorldTageChange", function(tagName)
        if tagName and tagName == "isHomeWorkWorld" and not System.options.isPapaAdventure then
            local dockKey = self:GetDockCfgKeyByWorldInfo()
            self:ChangeCfgKey(dockKey)
        end
    end);
end

function DockLayer:OnChangeDesktopMode(mode)
    if self.mode == nil or self.mode ~= mode then
        self.mode = mode
        if(mode == "movie") then
            self:HideAllDock()
            if GameLogic.IsReadOnly() then
                GameLogic.RunCommand("/hide quickselectbar")
            end
        else
            self:ShowAllDock()
            self:ChangeDockAlpha(true)
        end
    end
end

function DockLayer:ChangeDockAlpha(bChangeMode)
    if not self:IsNeedUpDockAlpha() then
        return 
    end
    self.max_alpha = 1
    self.min_alpha = 0.3
    self.cur_alpha = 1
    if self.mode == "editor" and bChangeMode then
        self.cur_alpha = 0.3
    end
    self.delay_time = self.mode == "editor" and 0 or 10
    if not bChangeMode then
        self.delay_time = 3
    end
    if self.dock_delay_timer then
        self.dock_delay_timer:Change()
    end
    if self.dock_timer then
        self.dock_timer:Change()
    end
    -- print("self.delay_time======",self.delay_time,self.mode)
    self:SetAllDockOpcatity(self.cur_alpha)
    self:UpdateDockAlpha()
end

function DockLayer:UpdateDockAlpha()
    if self.cur_alpha == self.min_alpha then
            return 
    end
    self.dock_delay_timer = commonlib.TimerManager.SetTimeout(function()
        self:StartUpDockAlpha()
    end,self.delay_time * 1000)
end

function DockLayer:StartUpDockAlpha()
    local timeDelta = 30
    local alphaDelta = (self.max_alpha - self.min_alpha) / math.floor(3000/timeDelta + 0.5)
    self.dock_timer = self.dock_timer or commonlib.Timer:new({callbackFunc = function()
        if self.cur_alpha >= self.min_alpha then
            self.cur_alpha = self.cur_alpha - alphaDelta
        else
            self.cur_alpha = self.min_alpha
            self.dock_timer:Change()
        end
        self:SetAllDockOpcatity(self.cur_alpha)
    end})
    self.dock_timer:Change(0,timeDelta)
end

function DockLayer:ShowEsc(bShow,bCommand)
    if self:IsIgnoreCommandAndFilter() then
        return 
    end
    if bCommand == true then
        if bShow == true then
            self.m_bShowEsc = true
        else
            self.m_bShowEsc = false
        end
        self:SetAllDockVisible(self.m_bShowEsc)
    else
        if bShow then
            if self.m_bShowEsc then
                self:SetAllDockVisible(true)
            end
        else
            self:SetAllDockVisible(false)
        end
    end    
end

function DockLayer:IsShowEsc()
    return self.m_bShowEsc and self.m_bShowEsc == true
end

function DockLayer:ShowDockPage(bShow,align)
    local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
    if IsMobileUIEnabled then
        MobileMainPage.ShowButtonsByAlign(align,bShow)
        return
    end
    if not self:IsShowDockPage() then
        return 
    end
    if align and align ~= "" then
        self:SetDockItemsVisivleByAlign(align,bShow)
    else
        self:SetAllDockVisible(bShow)
    end
end

function DockLayer:OnWorldLoaded()
    commonlib.TimerManager.SetTimeout(function()
        self.m_bShowEsc = true;
        self.m_current_dockkey = self:GetDockCfgKeyByWorldInfo();
        local dockCfg = _G.DOCK_CONFIG[self.m_current_dockkey];

        if (System.User.isAnonymousWorld) then
            dockCfg = {
                {
                    name = "mini_map",
                    width = 210,
                    enabled = true,
                    height = 248,
                    type = "special"
                }
            };
        end

        if (dockCfg) then
            local curDockCfg = commonlib.copy(dockCfg);

            if (self.m_current_dockkey == "E_DOCK_TUTORIAR" and
                GameLogic.IsReadOnly()) then
                for k,v in pairs (curDockCfg) do
                    if (v and v.name == "save") then
                        v.enabled = false;
                    end
                end
            end

            DockLayer:ShowDockByCfg(curDockCfg);
        end    
    end, 1000);
end

function DockLayer:OnWorldUnloaded()
    self.m_current_dockkey = ""
    self:RemoveAllDock()
    self.m_tblDockCfg = nil
end

function DockLayer.IsPapaCreate()
    local PapaUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaUtils.lua");
	return PapaUtils.IsPapaCreate()
end

function DockLayer:ShowDockByCfg(dockCfg)
    if not dockCfg then
        return
    end

    if System.options.isPapaAdventure then
        local isHomeWorkWorld = WorldCommon.GetWorldTag("isHomeWorkWorld");
        if (isHomeWorkWorld and not GameLogic.IsReadOnly()) or DockLayer.IsPapaCreate() then
            return
        end
    end

    if self.m_current_dockkey == "E_DOCK_LESSON" and System.options.channelId_431 then
        dockCfg = commonlib.filter(dockCfg,function (item)
            return item.name ~= "create_spage"
        end)
    end
    local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
    if IsMobileUIEnabled and self.m_current_dockkey ~= "E_DOCK_TUTORIAR" then
        return
    end
    if self.m_tblDockCfg then
        self:RemoveAll()
        self.m_tblDockCfg = nil
    end
    self.m_tblShowDocks = {}
    self.m_dockNames = {}
    local cfg = DockConfig.FilterConfigByProjectId(dockCfg)
    if System.os.IsMobilePlatform() then
        cfg = DockConfig.FilterByMobilePlatform(cfg,self.m_current_dockkey)
    end
    if IsMobileUIEnabled and self.m_current_dockkey == "E_DOCK_TUTORIAR" then
        for k,v in pairs(cfg) do
            if v then
                if v.name == "save" then
                    v.enabled = false
                end
                if v.name == "lesson" then
                    v.width = 124
                    v.height = 70
                end
            end
        end
    end
   
    self.m_tblDockCfg = cfg
    for k,v in pairs(self.m_tblDockCfg) do
        if v and v.enabled then
            self:AddNewDock(v)
        end
    end
    self:StartPositionTimer()
    if self.m_current_dockkey == "E_DOCK_MINI" or self.m_current_dockkey == "E_DOCK_NORMAL" and self.m_tblDockCfg and #self.m_tblDockCfg > 0 then
        commonlib.TimerManager.SetTimeout(function()
            DockConfig.SetIconData()
        end,200)
    end
end

function DockLayer:StartPositionTimer()
    self.pos_timer = self.pos_timer or commonlib.Timer:new({callbackFunc = function()
        self:RePosition()
    end})
    self.pos_timer:Change(0,500)
end

function DockLayer:OnDockMouseEnter(name)
    if self:IsNeedUpDockAlpha() then
        self:ChangeDockAlpha()
    end
end

function DockLayer:IsNeedUpDockAlpha()
    return self.m_current_dockkey == "E_DOCK_MINI" or self.m_current_dockkey == "E_DOCK_NORMAL" or self.m_current_dockkey == "E_DOCK_LESSON"
end

function DockLayer:IsIgnoreCommandAndFilter()
    local project_id = GameLogic.options:GetProjectId()
    return DockConfig.IsWinterCampWorld(project_id) or  DockConfig.IsParaWorld()
end

function DockLayer:GetDockCfgKeyByWorldInfo()
    local project_id = GameLogic.options:GetProjectId()
    if System.options.isPapaAdventure then
        return "E_DOCK_PAPA"
    end
    if DockConfig.IsWinterCampWorld(project_id) then
        return "E_DOCK_DONGAO"
    end

    if DockConfig.IsParaWorld() then
        return "E_DOCK_PARA"
    end

    if DockConfig.IsMiniWorld() then
        if System.options.channelId_431 then
            return "E_DOCK_NORMAL"
        end
        return "E_DOCK_MINI"
    end
    if DockConfig.IsTutorialUser() then
        return "E_DOCK_TUTORIAR"
    end
    return "E_DOCK_NORMAL"
end

function DockLayer:ChangeCfgKey(cfgkey)
    local dockCfg = _G.DOCK_CONFIG[cfgkey]
    if self.m_current_dockkey ~= cfgkey and dockCfg ~= nil and #dockCfg > 0 then
        self.m_current_dockkey = cfgkey
        self:RemoveAllDock()
        self.m_tblDockCfg = nil
        DockLayer:ShowDockByCfg(commonlib.copy(dockCfg))
    end
end

function DockLayer:ShowDockByKey(cfgKey)
    self:ChangeCfgKey(cfgKey)
end

function DockLayer:GetCurKey()
    return self.m_current_dockkey
end

function DockLayer:CloseLayer()
    
end

function DockLayer:RefreshLayer()
   self:RePosition()
end

function DockLayer:IsShowDockPage()
    return DockConfig.IsShowDockPage() 
end

function DockLayer:RemoveAll()
    if self.parent and self.parent:IsValid() then
        self.parent:RemoveAll()
    end
    if self.dock_delay_timer then
        self.dock_delay_timer:Change()
    end
    if self.dock_timer then
        self.dock_timer:Change()
    end
    if self.pos_timer then
        self.pos_timer:Change()
    end
end

function DockLayer:GetParentLayer()
    self.parent = ParaUI.GetUIObject("DockLayer.bgContainer")
    if self.parent and self.parent:IsValid() then
        return self.parent
    end
    self.parent  = ParaUI.CreateUIObject("container", "DockLayer.bgContainer", "_fi", 0, 0, 0, 0);
    self.parent.background = "";
    self.parent:GetAttributeObject():SetField("ClickThrough", true);
    self.parent.zorder = -3;
    self.parent:AttachToRoot()
    return self.parent
end

function DockLayer:ShowMiniUserInfo()
    local MiniWorldUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/MiniWorldUserInfo.lua");
    MiniWorldUserInfo.ShowInMiniWorld();
end

function DockLayer:CloseMiniUserInfo()
    local MiniWorldUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/MiniWorldUserInfo.lua");
    MiniWorldUserInfo.ClosePage()
end

function DockLayer:ShowMiniMap()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.lua");
	local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
	ParaWorldMinimapWnd:Show();

	local ParaWorldSites = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSites.lua");
	ParaWorldSites.Reset();
end

function DockLayer:CloseMiniMap()
	local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
	ParaWorldMinimapWnd:Close();
end

function DockLayer:AddNewDock(objParams)
    local name = ""
    if type(objParams) == "string" then
        name = objParams
    elseif type(objParams) == "table" then
        name = objParams.name
    end
    if self.m_dockNames and not self.m_dockNames[name] then
        self.m_dockNames[name] = true
        if name == "mini_map" then
            self:AddMiniMapDock(name)
            return 
        end
        if name == "mini_userinfo" then
            self:AddUserInfoDock(name)
            return 
        end
        if type(objParams) == "table" then
            local itemName = name or  ParaGlobal.GenerateUniqueID()
            local align = objParams.align or "_rt"
            local sortIndex = objParams.sortIndex or 1
            objParams.name = itemName
            local curDockItem = DockItem:new()
            curDockItem.align = align
            local isInit = curDockItem:InitItem(objParams,self:GetParentLayer())
            if isInit then
                self:AddDockData({align = align,name = itemName, sortindex = sortIndex,dockItem = curDockItem})
                curDockItem:Connect("onMouseEnter",function()
                    self:OnDockMouseEnter(name)
                end)
                return curDockItem
            end
        end
    else
        return self:GetDockByName(name)
    end
end

function DockLayer:AddMiniMapDock(name)
    if name == "mini_map" then
        local curDockItem = DockItem:new()
        local objParams = {name=name,width=210,height=248,type="special"}
        local sortIndex = objParams.sortIndex or 1
        curDockItem:Connect("onItemShow",function(bShow)
            if bShow == true then
                self:ShowMiniMap()
                self.showmap = true
            else
                self:CloseMiniMap()
                self.showmap = false
            end
        end)
        curDockItem:InitItem(objParams)
        self:AddDockData({align = "_rt",name = name,type="special", sortindex = sortIndex,dockItem = curDockItem})
    end
end

function DockLayer:AddUserInfoDock(name)
    if name == "mini_userinfo" then
        local curDockItem = DockItem:new()
        local objParams = {name=name,width=363,height=100,type="special"}
        local sortIndex = objParams.sortIndex or 1
        curDockItem:Connect("onItemShow",function(bShow)
            if bShow == true then
                self:ShowMiniUserInfo()
            else
                self:CloseMiniUserInfo()
            end
        end)
        curDockItem:InitItem(objParams)
        self:AddDockData({align = "_rt",name = name,type="special",sortindex = sortIndex,dockItem = curDockItem})
    end
end

function DockLayer:AddDockData(data)
    if data then
        self.m_tblShowDocks[#self.m_tblShowDocks + 1] = data
        table.sort(self.m_tblShowDocks,function(a,b)
            return a.sortindex > b.sortindex
        end)
        self:RePosition()
    end
end

function DockLayer:RemoveDockByIndex(index)
    if index > 0 and index <= #self.m_tblShowDocks then
        table.remove(self.m_tblShowDocks,index)
    end
    
end

function DockLayer:RemoveDock(name)
    if self.m_dockNames and not self.m_dockNames[name] then
        return false
    end
    print("remove name=============",name)
    local dockItem = self:GetDockByName(name)
    if dockItem then
        dockItem:RemoveSelf()
    end

    local dockIndex = self:GetIndexByName(name)
    if dockIndex then
        self:RemoveDockByIndex(dockIndex)
        self.m_dockNames[name] = nil
    end
    self:RePosition()
end

function DockLayer:GetDockByName(name)
    if not self.m_tblShowDocks then
        return 
    end
    for k,v in pairs(self.m_tblShowDocks) do
        if name and v.name == name then
            return v.dockItem
        end
    end
end

function DockLayer:GetIndexByName(name)
    if not self.m_tblShowDocks then
        return 
    end
    for i,v in ipairs(self.m_tblShowDocks) do
        if name and v.name == name then
            return i
        end
    end
end

function DockLayer:GetItemsByAlign(align)
    if not self.m_tblShowDocks then
        return 
    end
    if type(align) == "string" then
        local temp = {}
        for k,v in pairs(self.m_tblShowDocks) do
            if v.align == align and v.type == nil  then
                temp[#temp + 1] = v.dockItem
            end
        end
        return temp
    end
end

function DockLayer:GetAllButtonDocks()
    if not self.m_tblShowDocks then
        return 
    end
    local temp = {}
    for k,v in pairs(self.m_tblShowDocks) do
        if  v.type == nil  then
            temp[#temp + 1] = v.dockItem
        end
    end
    return temp
end

function DockLayer:RePosition()
    local screen_width = Screen:GetWidth()
    local screen_height = Screen:GetHeight()
    --右上角
    local posX = self.showmap == true and screen_width - 210 or screen_width
    local posY = 10
    local dockItems = self:GetItemsByAlign("_rt")
    if dockItems then
        for i,v in ipairs(dockItems) do           
            if i <= 5 then 
                v:SetPosition(posX - i*v.width , posY)
            else
                v:SetPosition(posX - (i - 5)*v.width , posY + v.height + 20)
            end
        end
    end

    --左上角
    posX = 10
    posY = 10
    dockItems = self:GetItemsByAlign("_lt")
    if dockItems then
        for i,v in ipairs(dockItems) do           
            v:SetPosition(posX + (i - 1)*v.width , posY)
        end
    end
    --居中下
    posX = screen_width/2
    posY = screen_height
    dockItems = self:GetItemsByAlign("_ctb")
    if dockItems then
        local itemNum = #dockItems
        local totalWidth = 0
        for i = 1,itemNum do
            totalWidth = totalWidth + dockItems[i].width
        end
        posX = posX - totalWidth / 2
        for i,v in ipairs(dockItems) do
            local width = v.width
            local height = v.height
            v:SetPosition(posX + (i - 1)*width , posY - v.height - 20)
        end
    end
    --右下
    posX = screen_width - 20
    posY = screen_height
    dockItems = self:GetItemsByAlign("_rb")
    if dockItems then
        local itemNum = #dockItems
        for i =itemNum,1,-1 do
            local dock = dockItems[i]
            dock:SetPosition(posX - i *(dock.width) , posY - dock.height - 20)
        end
    end

    --左下
    local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
    local offset_y = 36
    if IsMobileUIEnabled then
        offset_y = 22
    end
    posX = 40
    posY = screen_height
    dockItems = self:GetItemsByAlign("_lb")
    if dockItems then
        local itemNum = #dockItems
        for i =itemNum,1,-1 do
            local dock = dockItems[i]
            dock:SetPosition(posX + (i - 1) *width  , posY - dock.height - offset_y)
        end
    end
    self:ChangeDockAlpha()
end

function DockLayer:SetDockVisible(name,bIsVisible)
    local dockItem = self:GetDockByName(name)
    if dockItem then
        dockItem:SetVisible(bIsVisible == true)
    end
end

function DockLayer:SetAllDockVisible(bIsVisible)
    local isHomeWorkWorld = WorldCommon.GetWorldTag("isHomeWorkWorld");
    local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
    local dockItems = self:GetAllButtonDocks()
    local bShow = bIsVisible == true
    if IsMobileUIEnabled and bIsVisible and not isHomeWorkWorld then
        bShow = false
    end
    if dockItems then
        for k,v in pairs(dockItems) do
            v:SetVisible(bShow)
        end
    end
end

function DockLayer:SetDockItemsVisivleByAlign(align,bIsVisible)
    if type(align) == "string" then
        local items = self:GetItemsByAlign(align)
        if items then
            for k,v in pairs(items) do
                v:SetVisible(bIsVisible == true)
            end
        end
    end
end

function DockLayer:HideAllDock()
    local parent = self:GetParentLayer()
    if parent and parent:IsValid() then
        parent.visible = false
    end
end

function DockLayer:ShowAllDock()
    local parent = self:GetParentLayer()
    if parent and parent:IsValid() then
        parent.visible = true
    end
end

function DockLayer:SetAllDockOpcatity(opcatity)
    if not self.m_tblShowDocks then
        return
    end
    for k,v in pairs(self.m_tblShowDocks) do
        if v.dockItem  then
            v.dockItem:SetOpcatity(opcatity)
        end
    end
end

function DockLayer:RemoveAllDock()
    if not self.m_tblShowDocks then
        return
    end
    for k,v in pairs(self.m_tblShowDocks) do
        if v.dockItem then
            v.dockItem:RemoveSelf()
        end
    end
    self.m_tblShowDocks = {}
    self.m_dockNames = {}
    self:RemoveAll()
end

function DockLayer:AddRedTip(name,redParams)
    local dockItem = self:GetDockByName(name)
    if dockItem then
        dockItem:AddRedTip(redParams)
    end
end

function DockLayer:RemoveRedTip(name)
    local dockItem = self:GetDockByName(name)
    if dockItem then
        dockItem:RemoveRedTip()
    end
end

DockLayer:InitSingleton()



