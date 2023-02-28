--[[
Title: ParalifeBagPage
Author(s): hyz
Date: 2022/4/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeBagPage.lua");
local ParalifeBagPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeBagPage");
ParalifeBagPage.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/CharGeosets.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SkinPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTouchController.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local SkinPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SkinPage");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins");
local CharGeosets = commonlib.gettable("MyCompany.Aries.Game.Common.CharGeosets");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local pe_pager = commonlib.gettable("Map3DSystem.mcml_controls.pe_pager")
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local ParalifeBagPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeBagPage");
local Screen = commonlib.gettable("System.Windows.Screen");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local ParaLifeTouchController = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTouchController")
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession")
local _BagUiType = {
    grid = "grid",
    topbar = "topbar",
    bottombar = "bottombar",
}

local page;
ParalifeBagPage.PAGE_SIZE = 18 --每页显示多少个
ParalifeBagPage._curPage = 1
function ParalifeBagPage.OnInit()
	page = document:GetPageCtrl();
	GameLogic:Connect("WorldUnloaded", ParalifeBagPage, ParalifeBagPage.OnWorldUnload, "UniqueConnection");

	GameLogic.GetFilters():add_filter("DesktopModeChanged", ParalifeBagPage.DesktopModeChanged);
	GameLogic.events:AddEventListener("ShowCreatorDesktop", ParalifeBagPage.OnShowBuilderMenu, ParalifeBagPage, "ParalifeBagPage");
    page.OnCreate = ParalifeBagPage.OnCreate

    ParalifeBagPage.curDragedModelValue = {
        AssetFile = nil, IsCharacter=true, x=0, y=0, z=0,
        ReplaceableTextures=nil, CCSInfoStr=nil, CustomGeosets = nil
    }
    Screen:Connect("sizeChanged", ParalifeBagPage, ParalifeBagPage.OnResize, "UniqueConnection")
end

function ParalifeBagPage.onPageBtnClick(name)
    if page==nil then
        return
    end
    if ParalifeBagPage._uiType ~= _BagUiType.grid then
        return
    end
    ParalifeBagPage:GetDataSource()
    local maxPage = math.ceil(#ParalifeBagPage._itemList/ParalifeBagPage.PAGE_SIZE)
    if name=="btn_page_pre" then
        if ParalifeBagPage._curPage<=1 then
            return
        end
        ParalifeBagPage._curPage = ParalifeBagPage._curPage - 1
    elseif name=="btn_page_next" then
        if ParalifeBagPage._curPage>=maxPage then
            return
        end
        ParalifeBagPage._curPage = ParalifeBagPage._curPage + 1
    end
    -- GameLogic.AddBBS(nil,string.format("%s,%s,第%s页",name,maxPage,ParalifeBagPage._curPage))
    ParalifeBagPage.RefreshGrid()
end

function ParalifeBagPage.UpdatePageTxt()
    if page==nil then
        return
    end
    if ParalifeBagPage._uiType ~= _BagUiType.grid then
        return
    end
    local maxPage = math.ceil(#ParalifeBagPage._itemList/ParalifeBagPage.PAGE_SIZE)
    local text_page = page:FindControl("text_page")
    text_page:SetText(string.format("%s/%s",ParalifeBagPage._curPage,maxPage))
end

function ParalifeBagPage:OnResize()
    ParalifeBagPage.posUtils = {} --记录每个列表项的初始坐标
    for i=1,ParalifeBagPage.PAGE_SIZE do
        local name = "item_"..i
        local item = ParaUI.GetUIObject(name)
        if item then
            local x,y,width,height = item:GetAbsPosition();
            ParalifeBagPage.posUtils[i] = {
                idx=i,name=name,
                x=x,y=y,width=width,height=height
            }
        end
    end
    ParalifeBagPage.RefreshGrid()
end

function ParalifeBagPage.OnClosed()
	GameLogic.GetFilters():remove_filter("DesktopModeChanged", ParalifeBagPage.DesktopModeChanged);
	GameLogic.events:RemoveEventListener("ShowCreatorDesktop", ParalifeBagPage.Step6, ParalifeBagPage);
    Screen:Disconnect("sizeChanged", ParalifeBagPage, ParalifeBagPage.OnResize, "UniqueConnection")

    ParalifeBagPage.SaveHistory()
    
    page = nil
end

function ParalifeBagPage:DesktopModeChanged(mode)
	ParalifeBagPage.ShowPage(false)
	return mode
end

function ParalifeBagPage:OnShowBuilderMenu(event)
	if(event.bShow) then
		ParalifeBagPage.ShowPage(false)
	end
end

function ParalifeBagPage.test()
    if true then
        return
    end
	if page then
        
        local ui_draged_canvas3d = page:FindUIControl("draged_canvas3d") --UI界面上的，用来显示拖拽的3d模型
        ui_draged_canvas3d._mcmlNode = page:FindControl("draged_canvas3d")
        local mcmlNode = ui_draged_canvas3d._mcmlNode
        ui_draged_canvas3d.parent.x = 640
        ui_draged_canvas3d.parent.y = 200

        ui_draged_canvas3d.parent.visible = true

        local entity = GameLogic.EntityManager.GetEntity("table_xxx")
        local entity = GameLogic.EntityManager.GetEntity("chair_xxx")
        mcmlNode:ShowModel()
        mcmlNode:Show3dUIWithEntityLiveModel(entity)
    end
end

--根据活动模型显示canvas3d,包含所有的linkchild
function CommonCtrl.Canvas3D:Show3dUIWithEntityLiveModel(_entity)
	if _entity==nil then
		return
	end
    if not _entity:isa(GameLogic.EntityManager.EntityLiveModel) then
        return
    end

    local _xmlInfo = _entity:SaveToXMLNodeWithAllLinkedInfo()

	self:Show3dUIWithEntityLiveModelLinkedXmlInfo(_xmlInfo)
end

function ParalifeBagPage.OnCreate()
    ParalifeBagPage._InitTouchEvent()
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/CreatorDesktop.lua");
	local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
	if(CreatorDesktop.IsExpanded) then
		CreatorDesktop.ShowNewPage(false);
	end

    ParalifeBagPage.RefreshGrid()
end

function ParalifeBagPage.OnWorldUnload()
	GameLogic:Disconnect("WorldUnloaded", ParalifeBagPage, ParalifeBagPage.OnWorldUnload);
	ParalifeBagPage.ShowPage(false)
end

function ParalifeBagPage._InitTouchEvent()
    local ui_draged_canvas3d = page:FindUIControl("draged_canvas3d") --UI界面上的，用来显示拖拽的3d模型
    ui_draged_canvas3d._mcmlNode = page:FindControl("draged_canvas3d")

    local _itemList = ParalifeBagPage.GetDataSource()

    local _xmlDragedIn = nil ----从外边滑进来时，手里拖动的活动模型实体的xmlInfo
    ParalifeBagPage._dragedOutInfo = nil --从里面滑到外边去时，记录的信息 {xmlInfo,realIdx,uiObj}
    ParalifeBagPage.posUtils = {} --记录每个列表项的初始坐标
    for i=1,ParalifeBagPage.PAGE_SIZE do
        local name = "item_"..i
        local item = ParaUI.GetUIObject(name)
        if item then
            local x,y,width,height = item:GetAbsPosition();
            ParalifeBagPage.posUtils[i] = {
                idx=i,name=name,
                x=x,y=y,width=width,height=height
            }
        end
    end

    local on_page_down,on_page_up,on_page_move,on_page_leave,on_page_touch;
    local screen_bg = page:FindControl("screen_bg")
    local page_bg = ParaUI.GetUIObject("page_bg")

    local pageRect = {page_bg:GetAbsPosition()}
    local function _isPosInPage(x,y)
        if x>pageRect[1] and x<pageRect[1]+pageRect[3] and y>pageRect[2] and y<pageRect[2]+pageRect[4] then
            return true
        end
    end

    local function on_screen_down()
        -- local obj = ParaUI.GetUIObject("screen_bg")
        -- obj:GetAttributeObject():SetField("ClickThrough", true);
        local event = MouseEvent:init("mousePressEvent")
        ParaLifeTouchController.handleMouseEvent(event);
        -- local root = page:GetRootUIObject()
        -- root:SetZorder(-1)
    end
    local function on_screen_up()
        if ParalifeBagPage._dragedOutInfo then
            local tempInfo = ParalifeBagPage._dragedOutInfo
            local newEntity = ParalifeBagPage.CreateEntityByXmlNode(ParalifeBagPage._dragedOutInfo.xmlInfo)
            newEntity:GetItemClass():StartDraggingEntity(newEntity)
	        newEntity:GetItemClass():UpdateDraggingEntity(newEntity)
            newEntity:GetItemClass():DropDraggingEntity(newEntity,nil,nil,function()
                commonlib.TimerManager.SetTimeout(function()
                    newEntity:SetDeadWithAllChildren()
                    ParalifeBagPage.CheckInsertValue(tempInfo.realIdx,tempInfo.xmlInfo)
                end,1)
            end);

            ParalifeBagPage.CheckDeleteValue(ParalifeBagPage._dragedOutInfo.realIdx,ParalifeBagPage._dragedOutInfo.xmlInfo)
            ParalifeBagPage._dragedOutInfo = nil
            ParalifeBagPage.SetDragedInfo(nil,ui_draged_canvas3d)
            ParalifeBagPage.ClearMovingHighLight()
        else
            local event = MouseEvent:init("mouseReleaseEvent")
            ParaLifeTouchController.handleMouseEvent(event);
        end
        
    end
    local function on_screen_move()
        if ParalifeBagPage._dragedOutInfo then
            local mouseX, mouseY = ParaUI.GetMousePosition();
            ui_draged_canvas3d.x = mouseX - ui_draged_canvas3d.parent.width*0.5
            ui_draged_canvas3d.y = mouseY - ui_draged_canvas3d.parent.height*0.9
        else
            local event = MouseEvent:init("mouseMoveEvent")
            ParaLifeTouchController.handleMouseEvent(event);
        end
    end

    --兼容移动端（移动端只有ontouch事件）
    local _lastTouching = nil -- "screen"|"page"
    local _isTouchInPage = false
    local function on_screen_ontouch()
        local touch = msg
        local x,y = touch.x,touch.y
        ParaUI.SetMousePosition(x,y)

        local _tType = touch.type
        if _isPosInPage(x,y) then
            if (_tType == "WM_POINTERUPDATE") then
                if on_page_move() == 1 then --从外面拖进去page
                    touch.type = "WM_POINTERUP"
                    ParaLifeTouchController.handleTouchEvent(touch) --模拟松开手
                end
            elseif (_tType == "WM_POINTERUP") then
                on_page_up()
            end
            _lastTouching = "page"
            
            if (_tType == "WM_POINTERUP") then
                _lastTouching = nil
            end
        else
            if _xmlDragedIn then --拖进去page了，可是又拖出来了
                if (_tType == "WM_POINTERUPDATE") then
                    if _lastTouching=="page" then
                        local touchSession = TouchSession.GetTouchSession(touch)
                        local event = MouseEvent:init("mouseMoveEvent")
                        event.x, event.y = touch.x, touch.y
                        event.touchSession = touchSession
                        on_page_leave(nil,event)
                    end
                end
            elseif ParalifeBagPage._dragedOutInfo then --从外面拖出来
                if (_tType == "WM_POINTERUPDATE") then
                    on_screen_move()
                elseif (_tType == "WM_POINTERUP") then
                    on_screen_up()
                end
            else
                ParaLifeTouchController.handleTouchEvent(touch)
            end
            _lastTouching = "screen"
            if (_tType == "WM_POINTERUP") then
                _lastTouching = nil
            end
        end
    end
    
	if(screen_bg) then
		screen_bg:SetScript("onmousedown", on_screen_down);
		screen_bg:SetScript("onmouseup", on_screen_up);
		screen_bg:SetScript("onmousemove", on_screen_move);
        if System.os.GetPlatform() == 'android' or System.os.GetPlatform() == 'ios' then
		    screen_bg:SetScript("ontouch", on_screen_ontouch);
        end
	end

    local function getCurTouchedIdx()
        local mouseX, mouseY = ParaUI.GetMousePosition();
        local touchIdx = nil
        for i=1,ParalifeBagPage.PAGE_SIZE do
            local info = ParalifeBagPage.posUtils[i]
            if mouseX>info.x and mouseX<(info.x+info.width) and mouseY>info.y and (mouseY<info.y+info.height) then
                touchIdx = i;
                break
            end
        end
        if touchIdx then
            local info = ParalifeBagPage.posUtils[touchIdx]
            local realIdx = ParalifeBagPage.getRealIdxByPageIdx(touchIdx)
            return touchIdx,realIdx
        end
    end
    
    local _curHintIdx = nil --在page上滑动时候，当前鼠标在哪一个项上面
    function on_page_down()
        
        local touchIdx,realIdx = getCurTouchedIdx()
        if realIdx then
            local mouseX, mouseY = ParaUI.GetMousePosition();
            local xmlInfo = _itemList[realIdx].xmlInfo
            if not xmlInfo then
                return
            end
            ui_draged_canvas3d.x = mouseX - ui_draged_canvas3d.parent.width*0.5
            ui_draged_canvas3d.y = mouseY - ui_draged_canvas3d.parent.height*0.9

            local pageIdx = touchIdx
            local uiObj = page:FindUIControl("item_canvas3d_"..pageIdx).parent
            local mcmlObj = page:FindControl("item_canvas3d_"..pageIdx)
            uiObj.visible = false
            ParalifeBagPage._dragedOutInfo = {
                xmlInfo = xmlInfo,
                uiObj = uiObj,
                mcmlObj = mcmlObj,
                realIdx = realIdx
            }
            do
                local scene = ParaScene.GetMiniSceneGraph(mcmlObj.resourceName);
                local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
                

                local scene = ParaScene.GetMiniSceneGraph(mcmlObj.resourceName);
                if(scene:IsValid()) then
                    if(not mcmlObj.ExternalSceneName) then
                        local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
                        xmlInfo.attr.temp_facing = fRotY
                    else
                        local obj = scene:GetObject(mcmlObj.miniscenegraphname);
                        if(obj:IsValid()) then
                            local fRotY = obj:GetFacing();
                            xmlInfo.attr.temp_facing = fRotY
                        end
                    end
                end   
            end
            
            ParalifeBagPage.SetDragedInfo(xmlInfo,ui_draged_canvas3d)
        end
        _curHintIdx = nil
    end
    function on_page_up()
        if _xmlDragedIn then
            local touchIdx,realIdx = getCurTouchedIdx()
            if ParalifeBagPage._uiType ~= _BagUiType.grid then
                if ParalifeBagPage.GetRealDataCount()>=ParalifeBagPage.PAGE_SIZE then
                    GameLogic.AddBBS(nil,L"背包已经满了")
                    local recoverEntity = ParalifeBagPage.CreateEntityByXmlNode(_xmlDragedIn)
                    if _xmlDragedIn.dragParams then
                        recoverEntity.restoreDragParams = {pos = _xmlDragedIn.dragParams.pos, facing = _xmlDragedIn.dragParams.facing, linkTo = _xmlDragedIn.dragParams.linkTo }
                    end
                    recoverEntity:GetItemClass():DropDraggingEntity(recoverEntity);
                    recoverEntity:RestoreDragLocation()
                    _xmlDragedIn = nil
                    ParalifeBagPage.SetDragedInfo(nil,ui_draged_canvas3d)
                    _curHintIdx = nil
                    return
                end
                
            end
            if realIdx==nil then
                realIdx = ParalifeBagPage.getRealIdxByPageIdx(ParalifeBagPage.PAGE_SIZE) --没有就按最后一个拖
            end
            if realIdx then
                ParalifeBagPage.CheckInsertValue(realIdx,_xmlDragedIn)
                _xmlDragedIn = nil
            else --落点不是任何一个框
                local recoverEntity = ParalifeBagPage.CreateEntityByXmlNode(_xmlDragedIn)
                recoverEntity:GetItemClass():DropDraggingEntity(recoverEntity);
                _xmlDragedIn = nil
            end
        elseif ParalifeBagPage._dragedOutInfo then
            ParalifeBagPage._dragedOutInfo.mcmlObj.autoRotateSpeed = 0
            ParalifeBagPage._dragedOutInfo.uiObj.visible = true
            ParalifeBagPage._dragedOutInfo = nil
        else
            local event = MouseEvent:init("mouseReleaseEvent")
            ParaLifeTouchController.handleMouseEvent(event);
        end
        ParalifeBagPage.SetDragedInfo(nil,ui_draged_canvas3d)
        _curHintIdx = nil
    end
    function on_page_move()
        local event = MouseEvent:init("mouseMoveEvent")
        local _entity = GameLogic.GetSceneContext():GetMouseCaptureEntity(event)
        local mouseX, mouseY = ParaUI.GetMousePosition();
        if _entity then
            local isHuman = _entity:HasCustomGeosets()
            if isHuman and not ParalifeBagPage._enableHuman then
                _entity = nil
                return
            end
        end
        if _entity then --刚从外部拖动一个活动模型进来
            _xmlDragedIn = _entity:SaveToXMLNodeWithAllLinkedInfo()
            _xmlDragedIn.dragParams = _entity.dragParams
            _entity:SetDeadWithAllChildren()
            
            GameLogic.GetSceneContext():SetMouseCaptureEntity(nil,event)
            
            ParalifeBagPage.SetDragedInfo(_xmlDragedIn,ui_draged_canvas3d,true)
            
            ui_draged_canvas3d.x = mouseX - ui_draged_canvas3d.parent.width*0.5
            ui_draged_canvas3d.y = mouseY - ui_draged_canvas3d.parent.height*0.7

            return 1
        elseif _xmlDragedIn then --拖进来的
            ui_draged_canvas3d.x = mouseX - ui_draged_canvas3d.parent.width*0.5
            ui_draged_canvas3d.y = mouseY - ui_draged_canvas3d.parent.height*0.7
        elseif ParalifeBagPage._dragedOutInfo then --内部拖的
            ui_draged_canvas3d.x = mouseX - ui_draged_canvas3d.parent.width*0.5
            ui_draged_canvas3d.y = mouseY - ui_draged_canvas3d.parent.height*0.9
        else
            local touchIdx,realIdx = getCurTouchedIdx()
            if touchIdx then
                _curHintIdx = touchIdx
                local mcmlObj = page:FindControl("item_canvas3d_".._curHintIdx)
                mcmlObj.autoRotateSpeed = 1.57
            elseif _curHintIdx then
                local mcmlObj = page:FindControl("item_canvas3d_".._curHintIdx)
                mcmlObj.autoRotateSpeed = 0
                _curHintIdx = nil
            end
        end
    end
    function on_page_leave(xxx,event)
        if _curHintIdx then
            -- local mcmlObj = page:FindControl("item_canvas3d_".._curHintIdx)
            -- mcmlObj.autoRotateSpeed = 0
            _curHintIdx = nil
        end
        for i=1,ParalifeBagPage.PAGE_SIZE do
            local pageIdx = i
            local canvas3d_ui = page:FindControl("item_canvas3d_"..pageIdx)
            canvas3d_ui.autoRotateSpeed = 0
        end

        if _xmlDragedIn then --将原本拖进来的活动模型又给拖出去了
            local recoverEntity = ParalifeBagPage.CreateEntityByXmlNode(_xmlDragedIn)

            event = event or MouseEvent:init("mouseMoveEvent")
            xxsseee = recoverEntity
            recoverEntity:GetItemClass():StartDraggingEntity(recoverEntity,event)
            if _xmlDragedIn.dragParams then
                recoverEntity.dragParams = _xmlDragedIn.dragParams
            end

--             recoverEntity:GetItemClass():UpdateDraggingEntity(recoverEntity,event)

            GameLogic.GetSceneContext():SetMouseCaptureEntity(recoverEntity,event)
            recoverEntity:GetItemClass():SetMousePressEntity(recoverEntity,event)
            ParalifeBagPage.SetDragedInfo(nil,ui_draged_canvas3d)
            _xmlDragedIn = nil

            return recoverEntity
        elseif ParalifeBagPage._dragedOutInfo then
            ParalifeBagPage.mousepick_timer = ParalifeBagPage.mousepick_timer or commonlib.Timer:new({callbackFunc = function(timer)
                ParalifeBagPage.DoHighlightWhileMove()
            end})
            ParalifeBagPage.DoHighlightWhileMove()
        end
    end
    function on_page_touch()
        local x,y = msg.x,msg.y
        ParaUI.SetMousePosition(x,y)
        if _isPosInPage(x,y) then
            if (msg.type == "WM_POINTERDOWN") then
                on_page_down()
            elseif (msg.type == "WM_POINTERUPDATE") then
                on_page_move()
            elseif (msg.type == "WM_POINTERUP") then
                on_page_up()
            end
            _lastTouching = "page"
            if (msg.type == "WM_POINTERUP") then
                _lastTouching = nil
            end
        else
            if (msg.type == "WM_POINTERUPDATE") then
                if _lastTouching=="page" then
                    on_page_leave()
                end
                on_screen_move()
            elseif (msg.type == "WM_POINTERUP") then
                on_screen_up()
            end
            _lastTouching = "screen"
            if (msg.type == "WM_POINTERUP") then
                _lastTouching = nil
            end
        end
    end
    
    if page_bg then
        page_bg:SetScript("onmousedown", on_page_down);
		page_bg:SetScript("onmouseup", on_page_up);
		page_bg:SetScript("onmousemove", on_page_move);
		page_bg:SetScript("onmouseleave", on_page_leave);
        if System.os.GetPlatform() == 'android' or System.os.GetPlatform() == 'ios' then
		    page_bg:SetScript("ontouch", on_page_touch);
        end
    end
end

--copy from "BaseContext.CheckMousePick"
function ParalifeBagPage.DoHighlightWhileMove(x,y)
    if ParalifeBagPage._dragedOutInfo==nil then
        ParalifeBagPage.ClearMovingHighLight()
        return
    end

    local x,y = ParaUI.GetMousePosition();
    local context = GameLogic.GetSceneContext()
    local _self = context

    if ParalifeBagPage.mousepick_timer then
        ParalifeBagPage.mousepick_timer:Change(50,nil)
    end
    local result = SelectionManager:MousePickBlock(nil, nil, nil, nil, x, y);

    if(_self:GetEditMarkerBlockId() and result and result.block_id and result.block_id>0 and result.blockX) then
		local y = BlockEngine:GetFirstBlock(result.blockX, result.blockY, result.blockZ, _self:GetEditMarkerBlockId(), 5);
		if(y<0) then
			-- if there is no helper blocks below the picking position, we will return nothing. 
			SelectionManager:ClearPickingResult();
			_self:ClearPickDisplay();
			return;
		end
	end

    if(result.length and result.blockX) then
        if(EntityManager.GetFocus())then
            if(not EntityManager.GetFocus():CanReachBlockAt(result.blockX,result.blockY,result.blockZ)) then
			    SelectionManager:ClearPickingResult();
		    end
        end
	end
    -- highlight the block or terrain that the mouse picked
	if(result.length and result.length<SelectionManager:GetPickingDist() and GameLogic.GameMode:CanSelect()) then
		
		_self:HighlightPickBlock(result);

        -- local old = GameLogic.GameMode.bIsEditor
        -- GameLogic.GameMode.bIsEditor = true
		-- _self:HighlightPickEntity(result);
        -- GameLogic.GameMode.bIsEditor = old
	else
		_self:ClearPickDisplay();
	end
end

--滑动结束以后，清理滑动过程中的高亮物体
function ParalifeBagPage.ClearMovingHighLight()
    local context = GameLogic.GetSceneContext()
    local _self = context

    SelectionManager:ClearPickingResult();
    _self:ClearPickDisplay();

    if ParalifeBagPage.mousepick_timer then
        ParalifeBagPage.mousepick_timer:Change();
    end
end

function ParalifeBagPage.CreateEntityByXmlNode(xmlNode,linkToEntity,mountToIdx,linkInfo)
    local attr = xmlNode.attr
    local name = attr.name
    local linkTo = attr.linkTo
    attr.name = nil; --后边再改名， 不这样操作一下，如果有物理的情况下，会不可点击不可拖动
    attr.linkTo = nil;
    local entity = EntityManager.EntityLiveModel:Create({x=attr.x, y=attr.y, z=attr.z, facing=attr.facing,pitch=attr.pitch,roll=attr.roll}, nil);
    entity:LoadFromXMLNode(xmlNode)
    entity:Refresh();
	entity:Attach();

    local _linkList = xmlNode.linkList or {}
    for k,v in pairs(_linkList) do
        ParalifeBagPage.CreateEntityByXmlNode(v.xmlInfo,entity,v.mountIdx,v.linkInfo)
    end

    if linkToEntity then
        if mountToIdx then
            entity:MountTo(linkToEntity,mountToIdx)
        else
            entity:LinkTo(linkToEntity,linkInfo.boneName,linkInfo.pos,linkInfo.rot)
        end
    end
    if name and GameLogic.EntityManager.GetEntity(name)==nil then
        entity:SetName(name)
    end
    attr.name = entity:GetName(); 
    attr.linkTo = linkTo;
    return entity
end

function ParalifeBagPage.SetDragedInfo(xmlInfo,ui_draged_canvas3d,isMoveIn)
    if ui_draged_canvas3d then
        local attr = xmlInfo and xmlInfo.attr or {}
        local mcmlNode = ui_draged_canvas3d._mcmlNode
        mcmlNode:Show3dUIWithEntityLiveModelLinkedXmlInfo(xmlInfo)
        local obj = mcmlNode:GetObject()
        local camerayaw = GameLogic.RunCommand("/camerayaw")
        if obj then
            local targetFacing
            if isMoveIn and attr.facing then
                targetFacing = camerayaw+1.57
                attr.temp_facing = targetFacing
            elseif attr.temp_facing then
                targetFacing = attr.temp_facing
                
            end
            if targetFacing then
                local scene = ParaScene.GetMiniSceneGraph(mcmlNode.resourceName);
                if(scene:IsValid()) then
                    if(not mcmlNode.ExternalSceneName) then
                        local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
                        scene:CameraSetEyePosByAngle(targetFacing, fLiftupAngle, fCameraObjectDist);
                    else
                        obj:SetFacing(targetFacing)
                    end
                end
            end
        end
    end
    if ui_draged_canvas3d then
        ui_draged_canvas3d.parent.visible = xmlInfo~=nil
    end
end

function ParalifeBagPage.GetDragedModelValue()
	if ParalifeBagPage.curDragedModelValue.AssetFile then
        return ParalifeBagPage.curDragedModelValue
    else
        return nil
    end
end

function ParalifeBagPage.getRealIdxByPageIdx(idx)
    if page==nil then
        return idx
    end
    if ParalifeBagPage._uiType ~= _BagUiType.grid then
        return idx
    end
    local page_index = ParalifeBagPage._curPage
    local realIdx = (page_index-1)*ParalifeBagPage.PAGE_SIZE + idx
    return realIdx
end

function ParalifeBagPage.ShowPage(bShow,count,size)
	if bShow==false then 
		if page then 
			page:CloseWindow()
			page = nil 
		end
		return 
	end

    local html = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeBagPage_grid.html"
    local zorder = -10
    if bShow==_BagUiType.grid or bShow==nil then
        ParalifeBagPage.PAGE_SIZE = 18
        ParalifeBagPage._uiType = _BagUiType.grid
    elseif bShow==_BagUiType.bottombar then
        html = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeBagPage_bottom.html"
        zorder = -14
        ParalifeBagPage.PAGE_SIZE = math.max(math.min(count or 8,12),6)
        ParalifeBagPage.ITEM_SIZE = math.max(math.min(size or 48,80),48)
        ParalifeBagPage._uiType = _BagUiType.bottombar
    elseif bShow==_BagUiType.topbar then
        html = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeBagPage_top.html"
        zorder = -14
        ParalifeBagPage.PAGE_SIZE = math.max(math.min(count or 8,12),6)
        ParalifeBagPage.ITEM_SIZE = math.max(math.min(size or 48,80),48)
        ParalifeBagPage._uiType = _BagUiType.topbar
    end
    ParalifeBagPage.ShowPage(false)

    
    
	ParalifeBagPage.LoadHistory()

	local params = {
			url = html, 
			name = "ParalifeBagPage_grid.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			click_through = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			bShow = true,
			zorder = zorder,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
                align = "_fi",
				x = -0,
				y = -0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = ParalifeBagPage.OnClosed;

    ParalifeBagPage.SetDragedInfo(nil)
    
end

function ParalifeBagPage:OnWorldUnload()
	lastHistoryFilename = nil;
	find_history = {}
end

--根据模型文件名去重
function ParalifeBagPage._checkNeedAdd(arr,filename,skin)
	local filepath = PlayerAssetFile:GetValidAssetByString(filename);
	if not filepath then
		return false 
	end
	
	local contain = false
	for k,v in pairs(arr) do
		if v.attr.filename==filename then 
			if skin then
				if skin==v.attr.skin then 
					contain = true 
					break
				end
			else
				contain = true
				break
			end
		end
	end
	return not contain
end

function ParalifeBagPage.RefreshGrid()
    if not page then
        return
    end
    local pageSize = ParalifeBagPage.PAGE_SIZE
    local _itemList = ParalifeBagPage.GetDataSource()

    local page_index = 1
    local startIdx = 1
    local endIdx = #_itemList
    if ParalifeBagPage._uiType == _BagUiType.grid then
        page_index = ParalifeBagPage._curPage
        startIdx = (page_index-1)*pageSize+1
        endIdx = math.min(startIdx+pageSize-1,#_itemList)
    end
    ParalifeBagPage.UpdatePageTxt()

    for i=1,pageSize do
        local pageIdx = i
        local canvas3d_ui = page:FindUIControl("item_canvas3d_"..pageIdx)
        canvas3d_ui.parent.visible = false
    end
    for i=startIdx,endIdx do
        local pageIdx=  (i-1) % pageSize + 1
        local targetItemUIObj = ParaUI.GetUIObject("item_"..pageIdx)
        local x,y,width,height = targetItemUIObj:GetAbsPosition();
        local canvas3d_mcml = page:FindControl("item_canvas3d_"..pageIdx)
        local canvas3d_ui = page:FindUIControl("item_canvas3d_"..pageIdx)

        local xmlInfo = _itemList[i].xmlInfo
        if xmlInfo then
            canvas3d_mcml.DefaultRotY = xmlInfo.attr.temp_facing
            canvas3d_mcml:Show3dUIWithEntityLiveModelLinkedXmlInfo(xmlInfo)

            canvas3d_ui.parent.x = x
            canvas3d_ui.parent.y = y

            canvas3d_ui.parent.visible = true
        end
    end
end

--拖进来，尝试插入一个数据
function ParalifeBagPage.CheckInsertValue(realIdx,xmlInfo)
    xmlInfo.dragParams = nil
    local insertIdx = nil --真实插入的idx
    ParalifeBagPage.GetDataSource()
    local _itemList = ParalifeBagPage._itemList
    if _itemList[realIdx].xmlInfo then --已经有了 往下挤
        ParalifeBagPage.CheckAddEmptyPage()  --保证最后一位是空的
        for i=#_itemList,realIdx+1,-1 do
            _itemList[i].idx = i
            _itemList[i].xmlInfo = _itemList[i-1].xmlInfo
        end
        _itemList[realIdx].xmlInfo = xmlInfo
        insertIdx = realIdx
    else
        local start = ParalifeBagPage.getRealIdxByPageIdx(1)
        for i=start,start+ParalifeBagPage.PAGE_SIZE-1 do --遍历当前页的18项，找到第一个空的
            if _itemList[i].xmlInfo==nil then
                _itemList[i].xmlInfo = xmlInfo
                insertIdx = i
                break
            end
        end
        ParalifeBagPage.CheckAddEmptyPage()
    end
    ParalifeBagPage.RefreshGrid()
end

--拖出去，尝试减少一个数据
function ParalifeBagPage.CheckDeleteValue(realIdx,xmlInfo)
    ParalifeBagPage.GetDataSource()
    local _itemList = ParalifeBagPage._itemList
    for i=realIdx,#_itemList-1 do
        _itemList[i].xmlInfo = _itemList[i+1].xmlInfo
    end
    if _itemList[#_itemList] then
        _itemList[#_itemList].xmlInfo = nil
    end
    ParalifeBagPage.RefreshGrid()
end

--获取真实数据长度（有些可能是占位置的，实际entity xmlifo为空）
function ParalifeBagPage.GetRealDataCount()
    local _itemList = ParalifeBagPage.GetDataSource()
    local acc = 0;
    for k,v in pairs(_itemList) do
        if v.xmlInfo then
            acc = acc + 1
        end
    end
    return acc
end

function ParalifeBagPage.GetDataSource()
    if ParalifeBagPage._itemList==nil then
        ParalifeBagPage._itemList = {}
    end
    local _itemList = ParalifeBagPage.CheckAddEmptyPage()
    return _itemList
end

--补齐当前页或者添加空白的一页
function ParalifeBagPage.CheckAddEmptyPage()
    local _itemList = ParalifeBagPage._itemList
    local len = #_itemList
    if ParalifeBagPage._uiType == _BagUiType.grid then
        if len==0 or len%ParalifeBagPage.PAGE_SIZE~=0 or _itemList[len].xmlInfo then --每页显示18项，满了则自增一空白页
            local addNum = ParalifeBagPage.PAGE_SIZE - len%ParalifeBagPage.PAGE_SIZE
            for i=1,addNum do 
                local item = {
                    idx = len + i,
                    xmlInfo = nil
                }
                table.insert(_itemList,item)
            end
        end
    else
        if len==0 then
            local addNum = ParalifeBagPage.PAGE_SIZE --只有一页
            for i=1,addNum do 
                local item = {
                    idx = len + i,
                    xmlInfo = nil
                }
                table.insert(_itemList,item)
            end
        end
    end
    return _itemList
end

local find_history_filename = "grid_bag_history.xml";
local lastHistoryFilename = nil;
function ParalifeBagPage.SaveHistory()
    if true then --不需要保存了，一次性用品
        return
    end
	local filename = GameLogic.GetWorldDirectory()..find_history_filename;
	local root = {name='grid_bag_history', attr={file_version="0.1"} }
    ParalifeBagPage.GetDataSource()
    local _itemList = ParalifeBagPage._itemList
    for k,v in ipairs(_itemList) do
        
    end
    for i=1,#_itemList do
        if _itemList[i].xmlInfo then
            root[#root+1] = _itemList[i].xmlInfo;
        end
    end
	local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(xml_data);
		file:close();
		LOG.std(nil, "info", "ParalifeBagPage", "find block history saved to %s", filename);
	else
		LOG.std(nil, "error", "ParalifeBagPage", "failed saved to %s", filename);
	end
	
	return true;
end

function ParalifeBagPage.LoadHistory()
    if true then
        return
    end
    ParalifeBagPage._itemList = {}
    local _itemList = ParalifeBagPage._itemList
	local filename = GameLogic.GetWorldDirectory()..find_history_filename;
	if(lastHistoryFilename ~= filename) then
		lastHistoryFilename = filename;

		local function LoadFromHistoryFile_(filename)
			local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
			if(xmlRoot) then
                local arr = commonlib.XPath.selectNodes(xmlRoot, "/grid_bag_history");
                if arr and arr[1] then
                    local list = arr[1]
                    for k,xmlInfo in pairs(list) do
                        if type(xmlInfo)=="table" and xmlInfo.attr then
                            _itemList[#_itemList+1] = {
                                idx = k,
                                xmlInfo = xmlInfo
                            }
                        end
                    end
                end

                ParalifeBagPage.CheckAddEmptyPage()
			end	
		end
        
		if(GameLogic.isRemote) then
			Files.GetRemoteWorldFile(find_history_filename);
			commonlib.TimerManager.SetTimeout(function()  
				LoadFromHistoryFile_(filename)
				if(page) then
					ParalifeBagPage.FindAll()
				end
			end, 1000)
		else
			LoadFromHistoryFile_(filename)
		end
	end
end

local _scan;
_scan = function(xmlInfo,t)
    table.insert(t,xmlInfo.attr.name)
    if callback then
        callback(xmlInfo.attr.name,xmlInfo)
    end
    for k,v in pairs(xmlInfo.linkList) do
        _scan(v.xmlInfo,t)
    end
end
local function _getAllSubEntityNames(_xmlInfo,callback)
    local arr = {}
    
    _scan(_xmlInfo,arr)
    return arr;
end

local _isContainSameName = function(_xmlInfo)
    local names = _getAllSubEntityNames(_xmlInfo)
    for k,v in pairs(names) do
        if v==name then
            return true
        end
    end
end

--背包里是否已经有同名entity了
function ParalifeBagPage._checkHasEntityWithName(name)
    
    local _itemList = ParalifeBagPage.GetDataSource()
    for k,v in pairs(_itemList) do
        if v.xmlInfo and _isContainSameName(v.xmlInfo) then --子节点是否包含
            return true
        end 
    end
    return false
end

function ParalifeBagPage.SetBagDataWithEntity(entity)
    ParalifeBagPage._itemList = {}
    ParalifeBagPage.AddBagDataWithEntity(entity,{clone=true})
end

--将entity加到背包里
function ParalifeBagPage.AddBagDataWithEntity(entity,param)
    if entity==nil or entity.GetType==nil then
        return
    end
    local _isClone = param and param.clone==true
    local _itemList = ParalifeBagPage.GetDataSource()
    if ParalifeBagPage._uiType ~= _BagUiType.grid then
        if #ParalifeBagPage._itemList>ParalifeBagPage.PAGE_SIZE then
            GameLogic.AddBBS(nil,L"背包已经满,添加失败")
            return
        end
    end
    if entity:GetType() == EntityManager.EntityLiveModel.class_name then
        local _xmlInfo = entity:SaveToXMLNodeWithAllLinkedInfo()
        _getAllSubEntityNames(_xmlInfo,function(name,xml)
            if _isClone or ParalifeBagPage._checkHasEntityWithName(name) then --有同名的，或者是复制的，删除名字
                xml.attr.name = nil
                xml.attr.linkTo = nil
            end
        end)
        local realIdx = ParalifeBagPage.getRealIdxByPageIdx(ParalifeBagPage.PAGE_SIZE) --没有就按最后一个拖
        if realIdx then
            ParalifeBagPage.CheckInsertValue(realIdx,_xmlInfo)
        end
    elseif entity:GetType() == EntityManager.EntityMovieClip.class_name then
        local actor_datas = entity:GetAllActorData()

        for k,v in pairs(actor_datas) do
            local filepath = PlayerAssetFile:GetValidAssetByString(v.assetfile);
            local skin =v.skin
            if filepath=='character/CC/02human/actor/actor.x' then
                filepath = nil
            elseif filepath==GameLogic.GetWorldDirectory() then
                filepath = nil
            end
            if filepath then
                local xml = {
                    attr = {
                        class="LiveModel",
                        filename=filepath,
                        skin=v.skin,
                        scaling = v.scaling,
                        item_id=10074,
                    },
                    name="entity",
                }
                local realIdx = ParalifeBagPage.getRealIdxByPageIdx(ParalifeBagPage.PAGE_SIZE) --没有就按最后一个拖
                if realIdx then
                    ParalifeBagPage.CheckInsertValue(realIdx,xml)
                end
            end
        end
    else
        return
    end
    ParalifeBagPage.RefreshGrid()
    if not _isClone then
        entity:Destroy()
    end
end

ParalifeBagPage._enableHuman = true
function ParalifeBagPage.SetEnableHuman(enable)
    ParalifeBagPage._enableHuman = not (not enable)
end

function ParalifeBagPage.ClearBag()
    local _itemList = ParalifeBagPage.GetDataSource()
    ParalifeBagPage._itemList = {}
    ParalifeBagPage.RefreshGrid()
end