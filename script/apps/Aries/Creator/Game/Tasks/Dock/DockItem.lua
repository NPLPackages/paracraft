--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-05-27 15:42:02
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockItem.lua") 
        local DockItem = commonlib.gettable("MyCompany.Aries.Game.Dock.DockItem")
]]
local DockItem = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Game.Dock.DockItem"))
DockItem:Signal("onclickEvent" , function(mouse_button) end);
DockItem:Signal("onMouseEnter");
DockItem:Signal("onMouseLeave");
DockItem:Signal("onMouseUp");
DockItem:Signal("onMouseDown");
DockItem:Signal("onTouchEvent");
DockItem:Signal("onFrameEvent")
DockItem:Signal("onItemShow",function (bShow) end)
DockItem:Property({"width", nil, "GetWidth", "SetWidth"});
DockItem:Property({"height", nil, "GetHeight", "SetHeight"});
DockItem:Property({"name", nil, "GetName", "SetName"});

function DockItem:ctor()
    self.uiObj = nil
    self.parent = nil
    self.type = nil
    self.isframemove = false
    self.children_cfg = {}
    self.opcatity = 1
    self.redParams = nil
    self.red_tip_obj = nil
end

function DockItem:InitItem(objParams,parent)
    if type(objParams) == "table" then
        self.type = objParams.type or "button"
        local width = objParams.width or 100
        local height = objParams.height or 90
        local x = objParams.x or 0
        local y = objParams.y or 0
        self.width = width
        self.height = height
        local name = objParams.name or ParaGlobal.GenerateUniqueID()
        self.name = name
        self.isframemove = objParams.isframemove or false
        if self.type == "button" then
            if not parent or not parent:IsValid() then
                print("parent node is not valid",objParams and objParams.name or "")
                return false
            end
            self.parent = parent
            if objParams.name then
                local node = ParaUI.GetUIObject(objParams.name)
                if node and node:IsValid() then
                    ParaUI.DestroyUIObject(node)
                end
            end
            
            local background = objParams.bg or objParams.background
            if string.find(background,"#") then
                background = string.gsub(background,"#",";")
            end
            self.uiObj = ParaUI.CreateUIObject("button", name, "_lt", x, y, width, height);
            self.uiObj.background = background
            self.parent:AddChild(self.uiObj)
            if objParams.tooltip and objParams.tooltip~="" then
                self.uiObj.tooltip =objParams.tooltip
            end
            if objParams.text and objParams.text ~="" then
                self.uiObj.text = objParams.text
            end
            self.uiObj:SetScript("onclick",function()
                self:OnClick(objParams)
            end)

            self.uiObj:SetScript("onmousedown", function() 
                self:onMouseDown()
            end);

            self.uiObj:SetScript("onmouseup", function() 
                self:onMouseUp()
            end);

            self.uiObj:SetScript("onmouseenter",function()
                self:onMouseEnter()
            end)    
            self.uiObj:SetScript("onmouseleave",function()
                self:onMouseLeave()
            end)

            self.uiObj:SetScript("onframemove", function()
                if self.isframemove then
                    self:onFrameEvent()
                end
			end);
        else
            self:Show(true)
        end 
    end
    return true
end

function DockItem:OnClick(objParams)
    if objParams and objParams.onclick then
        if type(objParams.onclick) == "function" then
            objParams.onclick(self.name)
        else
            NPL.DoString(string.format(objParams.onclick,self.name))
        end
        
    else
        self:onclickEvent()
    end
end

function DockItem:Show(bShow)
    if self.type ~= "special" then
        return 
    end
    self:onItemShow(bShow)
end

function DockItem:RemoveSelf()
    LOG.std(nil, "debug", "DockItem", "remove item "..(self.name or "name"));
    if self.type == "special" then
        self:Show(false)
        return 
    end
    self:RemoveRedTip()
    if self:IsValid() then
        ParaUI.DestroyUIObject(self.uiObj)
        ParaUI.Destroy(self.name)
        if self.children_cfg and #self.children_cfg > 0 then --删除子节点
            for k,v in pairs(self.children_cfg) do
                ParaUI.DestroyUIObject(v.node)
                ParaUI.Destroy(v.name)
            end
        end
        self.children_cfg = {}
        self.uiObj = nil
    end
end

function DockItem:GetItemObj()
    return self.uiObj
end

function DockItem:GetItemParent()
    return self.parent
end

function DockItem:IsValid()
    return self.uiObj and self.uiObj:IsValid()
end

--添加一个C++对象的子节点
function DockItem:AddChild(pNode,x,y,name)
    if pNode and pNode:IsValid() and self:IsValid() and self.type ~= "special" then
        local posx,posy = self:GetPosition()
        posx = posx + x
        posy = posy + y
        pNode.x = posx
        pNode.y = posy
        self.parent:AddChild(pNode)
        pNode.visible = self:IsVisible()
        local colorMask = "255 255 255 " .. math.floor(self:GetOpcatity()*255)
        _guihelper.SetColorMask(pNode,colorMask)
        self.children_cfg[#self.children_cfg + 1] = {offsetX = x,offsetY=y,name = name,node = pNode}

    end
end

function DockItem:GetChildByName(name)
    if self:IsValid() and self.type ~= "special" then
        local node = ParaUI.GetUIObject(name)
        for k,v in pairs(self.children_cfg) do
            if node and node:IsValid() and node == v.node and name == v.name then
                return node
            end
        end
    end
end

function DockItem:UpdateChildren()
    for k,v in pairs(self.children_cfg) do
        local x = v.offsetX
        local y = v.offsetY
        local name = v.name
        local node = ParaUI.GetUIObject(name)
        if node and node:IsValid() then
            local posx,posy = self:GetPosition()
            posx = posx + x
            posy = posy + y
            node.x = posx
            node.y = posy
        end
    end
end

function DockItem:SetBackground(imgBg)
    if self:IsValid() then
        self.uiObj.background = imgBg
    end
end

function DockItem:SetPosition(x,y)
    if self:IsValid() then
        self.uiObj.x = x or 0
        self.uiObj.y = y or 0
        self:UpdateRedTip()
        self:UpdateChildren()
    end
end

function DockItem:GetPosition()
    if self:IsValid() then
        return self.uiObj.x ,self.uiObj.y
    end
end

function DockItem:GetAbsPosition()
    if self:IsValid() then
        return self.uiObj:GetAbsPosition()
    end
end

function DockItem:SetScaling(scalingX,scalingY)
    if self:IsValid() then
        self.uiObj.scalingx = scalingX or 1
        self.uiObj.scalingy = scalingY or 1
    end
end

function DockItem:GetScaling()
    if self:IsValid() then
        return self.uiObj.scalingx ,self.uiObj.scalingy
    end
end

function DockItem:SetOpcatity(opcatity)
    if self:IsValid() then
        local opcatity = opcatity or 1
        local colorMask = "255 255 255 " .. math.floor(opcatity*255)
        _guihelper.SetColorMask(self.uiObj,colorMask)
        self.opcatity = opcatity

        for k,v in pairs(self.children_cfg) do
            _guihelper.SetColorMask(v.node,colorMask)
        end

        local redTip = self:GetRedTip()
        if redTip then
            _guihelper.SetColorMask(redTip,colorMask)
        end
    end
end

function DockItem:GetOpcatity()
    return self.opcatity
end

function DockItem:SetVisible(bIsVisible)
    if self.type == "special" then
        self:Show(bIsVisible == true)
        return 
    end
    if self:IsValid() then
        if bIsVisible ~= true then
            self.uiObj.visible = false
            self:SetRedTipVisible(false)
            self:SetChildrenVisible(false)
            return
        end
        self.uiObj.visible = true
        self:SetRedTipVisible(true)
        self:SetChildrenVisible(true)
    end
end

function DockItem:IsVisible()
    return self:IsValid() and self.uiObj.visible or false
end

function DockItem:SetRedTipVisible(bIsVisible)
    if self.red_tip_obj and self.red_tip_obj:IsValid() then
        self.red_tip_obj.visible = bIsVisible
    end
end

function DockItem:SetChildrenVisible(bIsVisible)
    if self.children_cfg then
        for k,v in pairs(self.children_cfg) do
            local name = v.name
            local node = ParaUI.GetUIObject(name)
            if node and node:IsValid() then
                node.visible = bIsVisible
            end
        end
    end
end

function DockItem:AddRedTip(redParams)
    if type(redParams) == "table" and self:IsValid() then
        if not self.redParams then
            self.redParams = redParams
            local name = self.name.."red_tip"
            local width = self.redParams.width
            local height = self.redParams.height
            local x_offset = self.redParams.x_offset
            local y_offset = self.redParams.y_offset
            local posX,posY = self:GetPosition()
            self.red_tip_obj = ParaUI.CreateUIObject("container", name, "_lt", posX + x_offset, posY + y_offset, width, height);
            self.red_tip_obj:GetAttributeObject():SetField("ClickThrough", true)
            self.red_tip_obj.background = "Texture/Aries/Creator/keepwork/friends/xiaoxishu_19x19_32bits.png;0 0 19 19"
            self.red_tip_obj.zorder = 2
            self.parent:AddChild(self.red_tip_obj)
            self.red_tip_obj.visible = self:IsVisible()
            local colorMask = "255 255 255 " .. math.floor(self:GetOpcatity()*255)
            _guihelper.SetColorMask(self.red_tip_obj,colorMask)
        else
            self:UpdateRedTip()
        end
    end
end

function DockItem:UpdateRedTip(redParams)
    if type(self.redParams) == "table" and self.red_tip_obj and self.red_tip_obj:IsValid() then
        local width = self.redParams.width
        local height = self.redParams.height
        local x_offset = self.redParams.x_offset
        local y_offset = self.redParams.y_offset
        local posX,posY = self:GetPosition()
        self.red_tip_obj.x = posX + x_offset
        self.red_tip_obj.y = posY + y_offset
    end
end

function DockItem:RemoveRedTip()
    if self.red_tip_obj and self.red_tip_obj:IsValid() then
        ParaUI.DestroyUIObject(self.red_tip_obj)
        self.redParams = nil
        self.red_tip_obj = nil
    end
end

function DockItem:GetRedTip()
    local uiname = self.name.."red_tip"
    local redTip = ParaUI.GetUIObject(uiname)
    if redTip and redTip:IsValid() then
        return redTip
    end
end



