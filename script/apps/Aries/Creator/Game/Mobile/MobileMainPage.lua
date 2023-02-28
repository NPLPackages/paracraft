--[[
    author:{pbb}
    time:2022-10-27 17:32:53
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileMainPage.lua")
        local MobileMainPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileMainPage");
        MobileMainPage.ShowPage(true)
]]
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboardIcon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon")
local Color = commonlib.gettable("System.Core.Color");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local Recording =  NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileRecording.lua") 
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local MobileMainPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileMainPage");
MobileMainPage.DirectionKey = {
	Up = {"W"},
	Down ={"S"},
	Left = {"A"},
	Right = {"D"},
	UpLeft = {"W","A"},
	UpRight = {"W","D"},
	DownLeft = {"S","A"},
	DownRight = {"S","D"},
}

-- 摇杆坐标配置 在不同情况下的偏移量
local rockerPosConfig = {
    OnMoviceEdit = {offset_x=-80,offset_y=-100},
}

local key_maps = {
    W = DIK_SCANCODE.DIK_W,
    A = DIK_SCANCODE.DIK_A,
    S = DIK_SCANCODE.DIK_S,
    D = DIK_SCANCODE.DIK_D,
}

MobileMainPage.progress_angle = 0
MobileMainPage.IsRecording = false
MobileMainPage.IsShowCodeWindow = false


local page
function MobileMainPage.OnInit()
    page = document:GetPageCtrl();
    if page then
        page.OnCreate = MobileMainPage.OnCreated
    end
end

function MobileMainPage.IsVisible()
    return page and page:IsVisible()
end

MobileMainPage.bIsShow = false
function MobileMainPage.ShowPage(bShow)
    if not bShow then
        MobileMainPage.ClosePage()
        if MobileMainPage.bIsShow then

        end
        -- GameLogic.DockManager:ShowAllDock();
        MobileMainPage.bIsShow = false
        GameLogic.options:SetEnableMouseLeftDrag(false)
        return 
    end
    MobileMainPage.bIsShow = true
    MobileMainPage.progress_angle = 0
    MobileMainPage.IsRecording = false
    MobileMainPage.IsShowCodeWindow = false
    GameLogic.options:SetEnableMouseLeftDrag(true)
    MobileMainPage.InitContext()
    local params = {
        url = "script/apps/Aries/Creator/Game/Mobile/MobileMainPage.html",
        name = "MobileMainPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = -10,
        directPosition = true,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
        cancelShowAnimation = true,
        click_through=true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if not MobileMainPage.BindEvent then
        GameLogic.GetFilters():add_filter("DesktopModeChanged", function(mode)
            MobileMainPage.OnChangeDesktopMode(mode);
            return mode
        end)
        GameLogic.GetFilters():add_filter("OnPlayerRuleChange", function()
            MobileMainPage.CheckCanFly()
            MobileMainPage.CheckCanJump()
        end)
        GameLogic:Connect("WorldLoaded", MobileMainPage, MobileMainPage.OnWorldLoaded, "UniqueConnection")
        GameLogic:Connect("WorldUnloaded", MobileMainPage, MobileMainPage.OnWorldUnloaded, "UniqueConnection")
        GameLogic.GetFilters():add_filter("Macro_BeginPlay", function()
            MobileMainPage.ShowOperatePanel(false)
        end);
        GameLogic.GetFilters():add_filter("Macro_EndPlay", function()
            MobileMainPage.ShowOperatePanel(true)
        end);
        MobileMainPage.RegisterCodeWindowEvent(true)
        MobileMainPage.BindEvent = true
    end
end

function MobileMainPage.OnChangeDesktopMode(mode)
    if not MobileMainPage.IsVisible() then
        return 
    end
    MobileMainPage.mode = mode
    local btnChange = ParaUI.GetUIObject("btn_change_mode")
    if mode ~= "editor" then
        btnChange.background = "Texture/Aries/Creator/keepwork/Mobile/icon/bianji_56x56_32bits.png;0 0 56 56"
    else
        btnChange.background = "Texture/Aries/Creator/keepwork/Mobile/icon/youxi_56x56_32bits.png;0 0 56 56"
    end
    if mode == "movie" then
        MobileMainPage.ShowOperatePanel(false)
        btnChange.background = "Texture/Aries/Creator/keepwork/Mobile/icon/bianji_56x56_32bits.png;0 0 56 56"
    else
        MobileMainPage.ShowOperatePanel(true)
    end

    MobileMainPage.UpdateRockerPos(mode)
    MobileMainPage.CheckCanFly()
    MobileMainPage.CheckCanJump()
end

-- function MobileMainPage:RegisterEvent()
--     GameLogic.GetFilters():add_filter("CodeBlockEditorOpened",function(codeBlockWindow, entity,codeEntity)

--     end)
-- end

function MobileMainPage.RegisterCodeWindowEvent(bRegister)
    if bRegister then
        GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow",MobileMainPage.ShowCodeBlockWindow,MobileMainPage);
        return 
    end
    GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow",MobileMainPage.ShowCodeBlockWindow,MobileMainPage)
end

function MobileMainPage:ShowCodeBlockWindow(event)
    -- echo(event)
    local bShow = event and event.bShow
    MobileMainPage.UpdateRockerArea(bShow)
    MobileMainPage.IsShowCodeWindow = bShow == true
    MobileMainPage.ShowOperatePanel(not bShow)
    MobileMainPage.UpdateQuickBar(bShow)
    MobileMainPage.ShowRocker(not bShow)
    
end

local preX,preY,bUpdate
function MobileMainPage.UpdateRockerArea(bShow)
    -- mobile_move_button_touch
    local normalW = 300
    local normalH = 270
    local scaleW = 0.5

    local objMoveBtn = ParaUI.GetUIObject("mobile_move_button_touch")
    if objMoveBtn and objMoveBtn:IsValid() then
        -- if bShow then
        --     objMoveBtn.scalingx = scaleW
		-- 	objMoveBtn.scalingy = scaleW
        -- else
        --     objMoveBtn.scalingx = 1
		-- 	objMoveBtn.scalingy = 1
        -- end
        if bShow then
            objMoveBtn.width = normalW*scaleW
			objMoveBtn.height = normalH*scaleW
            if not preX then
                preX = objMoveBtn.x
                preY = objMoveBtn.y
            end
            bUpdate = true
            objMoveBtn.x = preX + 75
            objMoveBtn.y = preY  + 67.5
        else
            objMoveBtn.width = normalW
			objMoveBtn.height = normalH
            if bUpdate then
                objMoveBtn.x = preX
                objMoveBtn.y = preY
            end
            preX = nil
            preY = nil
            bUpdate = false
        end
    end
end

function MobileMainPage.ShowRocker(bShow)
    local rokerBg = ParaUI.GetUIObject("mobile_move_button_img_bg")
    if rokerBg and rokerBg:IsValid() then
        rokerBg.visible = bShow == true
    end
end

function MobileMainPage.UpdateQuickBar(bShow)
    if bShow then
        if QuickSelectBar.IsVisible() then
            MobileMainPage.IsHideQuick = true
            QuickSelectBar.ShowPage(false)
        end
    else
        if MobileMainPage.IsHideQuick then
            QuickSelectBar.ShowPage(true)
            MobileMainPage.IsHideQuick = nil
        end
    end
end

function MobileMainPage.OnWorldLoaded()

end

function MobileMainPage.OnWorldUnloaded()
    MobileMainPage.ClosePage()
    -- MobileMainPage.RegisterCodeWindowEvent()
    MobileMainPage.BindEvent = false
end

function MobileMainPage.InitContext()
    commonlib.TimerManager.SetTimeout(function()  
        if(not MobileMainPage.sceneContext) then
            NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileContext.lua")
            local MobileContext = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileContext");
            MobileMainPage.sceneContext = MobileContext:new():Register("mobile");
            NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobilePlayContext.lua")
            local MobilePlayContext = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobilePlayContext");
            MobileMainPage.scenePlayContext = MobilePlayContext:new():Register("mobile_play");

            MobileMainPage.originalEditContext = AllContext:GetContext("edit")
            MobileMainPage.originalPlayContext = AllContext:GetContext("play")
        end
        AllContext:SetContext("edit", MobileMainPage.sceneContext)
        AllContext:SetContext("play", MobileMainPage.scenePlayContext)
        -- GameLogic.DockManager:HideAllDock();
        Mouse:SetTouchButtonSwapped(false)
    end, 0)
    
end

function MobileMainPage.GetSceneContext()
	return MobileMainPage.sceneContext;
end

local function getRect(node)
    if node and node:IsValid() then
        local rect = {}
        rect.x,rect.y,rect.width,rect.height = node:GetAbsPosition()
        return rect
    end
    return {}
end

function MobileMainPage.RefreshByScreenWidth()
    NPL.load("(gl)script/ide/System/Windows/Screen.lua");
	local Screen = commonlib.gettable("System.Windows.Screen");
	local width ,height = Screen:GetWidth(),Screen:GetHeight()
    if width/height > 2 then
        local ui_name_list = {"mobile_operate_panel", "btn_operate_panel", "mobile_move_button_bg", "mobile_move_button_touch","mobile_operate_tip"}
        for index = 1, #ui_name_list do
            local ui_name = ui_name_list[index]
            local uiObj = ParaUI.GetUIObject(ui_name)
            if uiObj and uiObj:IsValid() then
                uiObj.x = uiObj.x + 60
            end
        end
    end
end

function MobileMainPage.OnCreated()
    MobileMainPage.InitRocker()
    MobileMainPage.btnCnfs = {}
    local btnCnfs = {}
    local objJump = ParaUI.GetUIObject("btn_jump")
    if objJump and objJump:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_jump",node = objJump,rect = getRect(objJump)}
    end

    local objFlyUp = ParaUI.GetUIObject("btn_fly_up")
    if objFlyUp and objFlyUp:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_fly_up",node = objFlyUp,rect = getRect(objFlyUp)}
    end

    local objFlyDown = ParaUI.GetUIObject("btn_fly_down")
    if objFlyDown and objFlyDown:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_fly_down",node = objFlyDown,rect = getRect(objFlyDown)}
    end

    local objRecord = ParaUI.GetUIObject("btn_record_game")
    if objRecord and objRecord:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_record_game",node = objRecord,rect = getRect(objRecord)}
    end

    local objXiqu = ParaUI.GetUIObject("btn_xiqu")
    if objXiqu and objXiqu:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_xiqu",node = objXiqu,rect = getRect(objXiqu)}
    end

    local objJiaohuan = ParaUI.GetUIObject("btn_jiaohuan")
    if objJiaohuan and objJiaohuan:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_jiaohuan",node = objJiaohuan,rect = getRect(objJiaohuan)}
    end

    local objPiliang = ParaUI.GetUIObject("btn_piliang")
    if objPiliang and objPiliang:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_piliang",node = objPiliang,rect = getRect(objPiliang)}
    end

    local objShanchu = ParaUI.GetUIObject("btn_shanchu")
    if objShanchu and objShanchu:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_shanchu",node = objShanchu,rect = getRect(objShanchu)}
    end

    local objXuanze = ParaUI.GetUIObject("btn_xuanze")
    if objXuanze and objXuanze:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_xuanze",node = objXuanze,rect = getRect(objXuanze)}
    end

    local objUndo = ParaUI.GetUIObject("btn_undo")
    if objUndo and objUndo:IsValid() then
        btnCnfs[#btnCnfs + 1] = {name="btn_undo",node = objUndo,rect = getRect(objUndo)}
    end
    
    for k,v in pairs(btnCnfs) do
        local name = v.name
        local node = v.node
        node:SetScript("onmousedown", function() 
            MobileMainPage.OnMouseDown(name)
        end);
        node:SetScript("ontouch", function() 
            MobileMainPage.OnTouch(msg,name)
        end);
        node:SetScript("onmouseup", function() 
            MobileMainPage.OnMouseUp(name)
        end);
        if name == "btn_undo" then
            node.candrag = true;
            node:SetScript("ondragbegin",function()
                
            end)
            node:SetScript("ondragend",function()
                -- GameLogic.AddBBS(nil,"dragEnd============")
                MobileMainPage.OnClickReDo()
            end)
        end
    end
    MobileMainPage.RefreshByScreenWidth()
    MobileMainPage.btnCnfs = btnCnfs
    MobileMainPage.DrawProgressView(objRecord)
    if MobileMainPage.IsRecording then
        MobileMainPage.HideCamera(true)
    end
    MobileMainPage.CheckCanFly()
    MobileMainPage.CheckCanJump()
end

function MobileMainPage.GetBtnCnf(name)
   if MobileMainPage.btnCnfs then
        for k,v in pairs(MobileMainPage.btnCnfs) do
            if v.name == name then
                return v
            end
        end
   end
end

function MobileMainPage.ClosePage()
    if(MobileMainPage.originalEditContext) then
        AllContext:SetContext("edit", MobileMainPage.originalEditContext)
    end
    if MobileMainPage.originalPlayContext then
        AllContext:SetContext("play", MobileMainPage.originalPlayContext)
    end
    MobileMainPage.sceneContext = nil
    MobileMainPage.scenePlayContext = nil
    if MobileMainPage.keyButton and MobileMainPage.keyButton:IsValid() then
        ParaUI.DestroyUIObject(MobileMainPage.keyButton)
    end
    if page then
        page:CloseWindow()
        page = nil;
    end

    NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileBuilderFramePage.lua");
    local MobileBuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileBuilderFramePage");
    MobileBuilderFramePage.ClearData()
end 

function MobileMainPage.IsFlying()
    local entityPlayer = GameLogic.EntityManager.GetFocus();
    local isFly = entityPlayer and entityPlayer:IsFlying() 
    -- print("isFly ======",isFly)
    return isFly == true or isFly == "true"
end

function MobileMainPage.OnClickChangeGameMode()
    if MobileMainPage.mode == "movie" then
        return
    end
    local bChange = GameLogic.ToggleGameMode();
    if bChange then
        -- 换背景
        local editName = MobileMainPage.GetSceneContext().Name
        local curContext = GameLogic.GetSceneContext()
        if curContext.Name == "PlayContext" then

        else  

        end
        print("context name=========",editName,curContext.Name)
    end
end

function MobileMainPage.ActiveMobileContext()
    local curContext = GameLogic.GetSceneContext()
    if curContext.Name == "play" then
    elseif curContext.Name == "edit" then
    elseif curContext.Name == "movie" then
    elseif curContext.Name == "code" then
    end
end

function MobileMainPage.OnClickGameSetting()
    GameLogic.ToggleDesktop("esc");    
end

function MobileMainPage.OnClickSaveGame()
    local dockKey = GameLogic.DockManager:GetDockKey()
    local key = dockKey == "E_DOCK_TUTORIAR" and "commit_work" or "save_world"
    local MobileSaveWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileSaveWorldPage.lua")
    MobileSaveWorldPage.ShowPage(key)
end

function MobileMainPage.OnClickToggleFly()
    if not MobileMainPage.IsFlying() then
        GameLogic.ToggleFly()
        MobileMainPage.UpdateFlyPanel()
        if not MobileMainPage.IsFlying() then
            _guihelper.CloseMessageBox();
            _guihelper.MessageBox(L"此世界禁止飞行哦！");
        end
    end
end

function MobileMainPage.CheckCanFly()
    local isModeFly = GameLogic.GameMode:CanFly()
    local isCanFlyInParaWorld = false
    NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local generatorName = WorldCommon.GetWorldTag("world_generator");
    if generatorName == "paraworld" and GameLogic.IsVip("FlyOnParaWorld") then --这是一个vip的收费点
        isCanFlyInParaWorld = true
    end
    local isCanFly = isModeFly or isCanFlyInParaWorld
    local btnChangeFly = ParaUI.GetUIObject("mobile_change_fly")
    if btnChangeFly:IsValid() then
        btnChangeFly.visible = isCanFly
    end
end

function MobileMainPage.CheckCanJump()
    local isCanJump = GameLogic.options.CanJump
    local isHaveRestrict = GameLogic.GameMode:HasJumpRestriction()
    local isShowJump = not isHaveRestrict or (isHaveRestrict and isCanJump)
    -- print("data========",isHaveRestrict,isCanJump)
    local btn_jump = ParaUI.GetUIObject("btn_jump")
    if btn_jump:IsValid() then
        btn_jump.visible = isShowJump == true
    end
end

function MobileMainPage.OnClickToggleJump()
    if MobileMainPage.IsFlying() then
        GameLogic.ToggleFly()
        MobileMainPage.UpdateFlyPanel()
    end
end

function MobileMainPage.UpdateFlyPanel()
    local panel_fly = ParaUI.GetUIObject("mobile_fly_back")
    local panel_jump = ParaUI.GetUIObject("mobile_jump_back")
    if panel_fly and panel_fly:IsValid() then
        panel_fly.visible = MobileMainPage.IsFlying()
    end
    if panel_jump and panel_jump:IsValid() then
        panel_jump.visible = not MobileMainPage.IsFlying()
    end
end

function MobileMainPage.OnClickFlyUp()
    MobileMainPage.StartJump()
end

function MobileMainPage.OnClickFlyDown()
    
end

function MobileMainPage.OnMouseEnter(btnName)

end

function MobileMainPage.OnMouseLeave(btnName)

end
-- simulate the touch event with id=-1
function MobileMainPage.OnMouseDown(btnName)
	local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
	MobileMainPage.OnTouch(touch,btnName);
end

function MobileMainPage.OnMouseMove(btnName)
    local touch = {type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y, id=-1, time=0};
	MobileMainPage.OnTouch(touch,btnName);
end

-- simulate the touch event
function MobileMainPage.OnMouseUp(btnName)
	local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
	MobileMainPage.OnTouch(touch,btnName);
end

function MobileMainPage.SetUIFocus(uiName)
    local uiObj = commonlib.GetUIObject(uiName)
    if uiObj and uiObj:IsValid() then
        uiObj:Focus()
        uiObj:LostFocus()
    end
end

-- handleTouchEvent 
function MobileMainPage.OnTouch(touch,btnName)
    local touch_session = TouchSession.GetTouchSession(touch);
	if(touch.type == "WM_POINTERDOWN") then
        if btnName == "btn_jump" then
		    MobileMainPage.StartJump()
        elseif btnName == "btn_fly_up" then
            MobileMainPage.FlyUp()
        elseif btnName == "btn_fly_down" then
            MobileMainPage.FlyDown()
        elseif btnName == "btn_xiqu" then
            MobileMainPage.SetContextState(MOBILE_BUTTON_STATE.STATE_DRAW)
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LMENU, true)
        elseif btnName == "btn_jiaohuan" then
            MobileMainPage.SetContextState(MOBILE_BUTTON_STATE.STATE_REPLACE)
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LCONTROL, true)
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LMENU, true)
        elseif btnName == "btn_piliang" then
            MobileMainPage.SetContextState(MOBILE_BUTTON_STATE.STATE_BATCH)
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LSHIFT, true)
        elseif btnName == "btn_shanchu" then
            MobileMainPage.SetContextState(MOBILE_BUTTON_STATE.STATE_DELETE)
        elseif btnName == "btn_xuanze" then
            MobileMainPage.SetContextState(MOBILE_BUTTON_STATE.STATE_SELECT)
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LCONTROL, true)
        elseif btnName == "btn_undo" then
            local cnf = MobileMainPage.GetBtnCnf(btnName)
            if cnf then
                touch_session:SetField("keydownBtn", cnf.node)
            end
        end
        MobileMainPage.ShowOperateTip(btnName)
        MobileMainPage.StartCheckMouse(btnName)
	elseif(touch.type == "WM_POINTERUPDATE") then
		if btnName == "btn_undo" then 
            
        end
	elseif(touch.type == "WM_POINTERUP") then
        if btnName == "btn_jump" then
		    MobileMainPage.StartJump(true)
        elseif btnName == "btn_fly_up" then
            MobileMainPage.FlyUp(true)
        elseif btnName == "btn_fly_down" then
            MobileMainPage.FlyDown(true)
        elseif btnName == "btn_xiqu" then
            MobileMainPage.SetContextState() 
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LMENU, false)
        elseif btnName == "btn_jiaohuan" then
            MobileMainPage.SetContextState()
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LCONTROL, false)
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LMENU, false)
        elseif btnName == "btn_piliang" then
            MobileMainPage.SetContextState()
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LSHIFT, false)
        elseif btnName == "btn_shanchu" then
            MobileMainPage.SetContextState()
        elseif btnName == "btn_xuanze" then
            MobileMainPage.SetContextState()
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_LCONTROL, false)
        elseif btnName == "btn_undo" then
            local keydownBtn = touch_session:GetField("keydownBtn");
            if keydownBtn and keydownBtn.name == btnName then
                -- print("touch_session:GetMaxDragDistance()========",touch_session:GetMaxDragDistance(),keydownBtn.width)
                if touch_session:GetMaxDragDistance() > keydownBtn.width *2 then
                    MobileMainPage.OnClickReDo()
                else
                    MobileMainPage.OnClickUnDo()
                end
            end
        end
        MobileMainPage.ShowOperateTip()
	end
    
    MobileMainPage.UpdateButonState(touch,btnName)
    if btnName == "btn_record_game" then
        MobileMainPage.OnTouchCamera(touch)
    end
end

local operates = {
    btn_xiqu = { title = L"吸取", content=L"按住按钮，然后点击方块吸取一个相同的方块到手上"},
    btn_jiaohuan={ title = L"替换", content=L"按住按钮，然后点击方块替换成选中的方块"},
    btn_piliang={ title = L"批量", content=L"按住按钮，点击新增三个方块，或者填充相同方块；长按方块，删除3x3范围内的方块"},
    btn_shanchu={ title = L"删除", content=L"按住按钮，然后点击方块将方块删除"},
    btn_xuanze={ title = L"选择", content=L"按住按钮，然后点击选中一个方块，或者拖动选中一片区域的方块"},
    btn_undo = { title = L"撤销", content=L"点击撤销按钮，撤销上一步操作；按住撤销按钮右滑，恢复上一步撤销的操作"}
}
function MobileMainPage.ShowOperateTip(btnName)
    local operate_tip = ParaUI.GetUIObject("mobile_operate_tip")
    if not btnName or btnName == "" then
        if operate_tip and operate_tip:IsValid() then
            operate_tip.visible = false
        end
        return 
    end
    if operates[btnName] then
        if operate_tip and operate_tip:IsValid() then
            operate_tip.visible = true
        end
        page:SetValue("operate_tip", operates[btnName].title);
        page:SetValue("operate_tip_content", operates[btnName].content);
        local width = 142
        local text_width = _guihelper.GetTextWidth(operates[btnName].content,"System;14;bold")
        local line = math.floor(text_width/width + 0.5)
        local lineheight = (line + 1) * 18
        if System.os.GetPlatform() =="win32" then
            lineheight = line  * 18 + 14
        end
        local ctl = page:FindUIControl("operate_tip_content")
        if ctl then
            ctl.height =  lineheight
        end
        operate_tip.height = 48 + lineheight
    end
    
end

local colors = {
    normal = "#e6e6e6ff",
    press = "#a0a0a0ff",
    highlight = "#ffffffff",
    disable = "#ffffff80",
}
function MobileMainPage.UpdateButonState(touch,name)
    local type = touch.type
    local objNode = ParaUI.GetUIObject(name)
    if objNode and objNode:IsValid() then
        if type == "WM_POINTERUP" then
            _guihelper.SetUIColor(objNode, colors.normal)
        else
            _guihelper.SetUIColor(objNode, colors.press)
        end
    end
end
-- 移动端处理过touch失效逻辑，不需要检测
function MobileMainPage.StartCheckMouse(btnName)
    if System.os.GetPlatform() ~="win32" then
        return 
    end
    local objNode = ParaUI.GetUIObject(btnName)
    if objNode and objNode:IsValid() then
        MobileMainPage.btnName = btnName
        MobileMainPage.CheckTimer = MobileMainPage.CheckTimer or commonlib.Timer:new({callbackFunc = function(timer)
            local uiMouseX, uiMouseY = ParaUI.GetMousePosition();
            if not MobileMainPage.IsPointInRect1(uiMouseX, uiMouseY,MobileMainPage.btnName) then
                local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
                MobileMainPage.OnTouch(touch,MobileMainPage.btnName);
                timer:Change()
            end
        end})
        MobileMainPage.CheckTimer:Change(0,30);
    end
end

function MobileMainPage.IsPointInRect(rect,x,y)
    local isIn = rect and x > rect.x and x < rect.x + rect.width and y > rect.y and y < rect.y + rect.height
    return isIn
end

function MobileMainPage.IsPointInRect1(x,y,name)
    if name and name ~= "" then
        local objNode = ParaUI.GetUIObject(name)
        local rect = getRect(objNode)
        local isIn = rect and x > rect.x and x < rect.x + rect.width and y > rect.y and y < rect.y + rect.height
        return isIn
    end
    return false
end

function MobileMainPage.CheckCanShow()
    local mode = GameLogic.GetGameMode()
    local isCan = not GameLogic.Macros:IsRecording() and not GameLogic.Macros:IsPlaying() and  mode ~= "movie"
    return isCan
end

function MobileMainPage.ShowOperatePanel(bShow,bIgnoreBtn)
    if not MobileMainPage.CheckCanShow() and bShow then
        return
    end
    local uiObj = ParaUI.GetUIObject("mobile_operate_panel")
    if uiObj and uiObj:IsValid() then
        if MobileMainPage.bShowOperate == nil then
            MobileMainPage.bShowOperate = uiObj.visible
        end
        if bShow == true then
            uiObj.visible = MobileMainPage.bShowOperate
            MobileMainPage.bShowOperate = nil
        else
            uiObj.visible = false
        end
    end
    if not bIgnoreBtn then
        uiObj = ParaUI.GetUIObject("btn_operate_panel")
        if uiObj and uiObj:IsValid() then
            uiObj.visible = bShow == true
        end
    end
end

function MobileMainPage.SetContextState(state)
    if not state then
        if MobileMainPage.sceneContext then
            MobileMainPage.sceneContext:SelectState(MOBILE_BUTTON_STATE.STATE_OTHER)
        end
        return 
    end
    if MobileMainPage.sceneContext then
        MobileMainPage.sceneContext:SelectState(state)
    end
end

function MobileMainPage.StartJump(bStop)
    if bStop then
        if MobileMainPage.JumpTimer then
            MobileMainPage.JumpTimer:Change()
            GameLogic.DoJump()
        end
        return 
    end
    MobileMainPage.JumpTimer = MobileMainPage.JumpTimer or commonlib.Timer:new({callbackFunc = function(timer)
        GameLogic.DoJump()
    end})
    MobileMainPage.JumpTimer:Change(0,100)
end

function MobileMainPage.FlyUp(bStop)
    MobileMainPage.StartJump(bStop)
end

function MobileMainPage.FlyDown(bStop)
    if bStop then
        MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_X, false)
        if MobileMainPage.FlyDownTimer then
            MobileMainPage.FlyDownTimer:Change()
        end
        return 
    end

    if MobileMainPage.IsFlying() then
        MobileMainPage.FlyDownTimer = MobileMainPage.FlyDownTimer or commonlib.Timer:new({callbackFunc = function(timer)
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_X, true)
            MobileMainPage.FlyDownGround()
        end})
        MobileMainPage.FlyDownTimer:Change(0,100)
    end
    
end

function MobileMainPage.FlyDownGround() --判断是否到底了
    local player = GameLogic.EntityManager.GetFocus();
    if(player) then 
        local bx, by, bz = player:GetBlockPos();
        local block = BlockEngine:GetBlock(bx, by-1, bz);
        if(block and block.id ~= 0) then
            player:ToggleFly(false);
            MobileMainPage.UpdateFlyPanel()
            if MobileMainPage.FlyDownTimer then
                MobileMainPage.FlyDownTimer:Change()
            end
            MobileMainPage.SendRawKeyEvent(DIK_SCANCODE.DIK_X, false)
            SoundManager:Vibrate();
            return true
        end
    end
    return false
end

function MobileMainPage.OnClickUnDo()
    local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
    if(GameMode:IsAllowGlobalEditorKey()) then
        local is_done = UndoManager.Undo();
        if is_done then
            GameLogic.AddBBS(nil,L"撤销成功")
            MobileMainPage.PlaySound()
        end
    end
end

function MobileMainPage.OnClickReDo()
    local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
    if(GameMode:IsAllowGlobalEditorKey()) then
        local is_done = UndoManager.Redo();
        if is_done then
            MobileMainPage.PlaySound()
        end
    end
end

function MobileMainPage.PlaySound()
    local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
    local block_template = block_types.get(219);
    if(block_template) then
        block_template:play_create_sound();
    end
end

--[[
    function：轮盘移动
    from:TouchMiniKeyboard.lua
]]

function MobileMainPage.InitRockerData()
    if not MobileMainPage.isInitRocker then
        local rocker_item_bg = ParaUI.GetUIObject("mobile_move_button_bg")
        local rocker_item = ParaUI.GetUIObject("mobile_move_button")
        if rocker_item and rocker_item:IsValid() then
            local x, y, width, height = rocker_item:GetAbsPosition()
            MobileMainPage.rocker_real_point = {x=x+width/2,y=y+height/2}
            MobileMainPage.rocker_point = {x=rocker_item.x,y=rocker_item.y}
            MobileMainPage.rock_operate_point = rocker_item
        end
        if rocker_item_bg and rocker_item_bg:IsValid() then
            MobileMainPage.rock_operate_point_bg = rocker_item_bg
            MobileMainPage.start_x,MobileMainPage.start_y,MobileMainPage.radius = rocker_item_bg:GetAbsPosition()
        end
        MobileMainPage.isInitRocker = true
    end
end
function MobileMainPage.InitRocker()
    MobileMainPage.isInitRocker = false
    local objMoveBtn = ParaUI.GetUIObject("mobile_move_button_touch")
    if objMoveBtn and objMoveBtn:IsValid() then
        objMoveBtn:SetScript("onmousedown", function()
            local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
            MobileMainPage.OnTouchRocker(touch)
        end);
        objMoveBtn:SetScript("ontouch", function() 
            MobileMainPage.OnTouchRocker(msg)
        end);
        objMoveBtn:SetScript("onmouseup", function() 
            local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
            MobileMainPage.OnTouchRocker(touch)
        end);
        objMoveBtn:SetScript("onmousemove", function() 
            local touch = {type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y, id=-1, time=0};
            MobileMainPage.OnTouchRocker(touch)
        end)
    end 
end

function MobileMainPage.ShowKeyButton()
    if not page then
        return
    end
    local obj1 = ParaUI.GetUIObject("mobile_move_button_bg")
    local obj2 = ParaUI.GetUIObject("mobile_move_button_touch")
    obj1.visible = false
    obj2.visible = false
    if not MobileMainPage.keyButton or not MobileMainPage.keyButton:IsValid() then
        local pageRoot = page:GetParentUIObject()
        local rocker_item = ParaUI.GetUIObject("mobile_move_button")
        if rocker_item and rocker_item:IsValid() then
            local x,y,width,height = rocker_item:GetAbsPosition()
            local real_pos = MobileMainPage.rocker_real_point
            local left,right,top,bottom = real_pos.x - width/2,real_pos.x + width/2,real_pos.y - height/2,real_pos.y + height/2
            local _this=ParaUI.CreateUIObject("button","b","_lt", x - 150, y - 90 , 56, 56);
            _this.background = "Texture/Aries/Creator/keepwork/Mobile/icon/jianpan_56x56_32bits.png;0 0 56 56";
            _guihelper.SetUIColor(_this, "255 255 255");
            -- pageRoot:AddChild(_this);
            _this.zorder = 100
            _this:AttachToRoot()
            _this:SetScript("onclick",function()
                TouchVirtualKeyboardIcon = TouchVirtualKeyboardIcon.GetSingleton()
                if TouchVirtualKeyboardIcon then
                    TouchVirtualKeyboardIcon:ShowKeyboard(false)
                    obj1.visible = true
                    obj2.visible = true
                    _this.visible = false
                end
            end)
            MobileMainPage.keyButton = _this
        end
        return
    end
    MobileMainPage.keyButton.visible = true
end

local doubleKeyTime = 220
function MobileMainPage.OnClickRocker(click_x,click_y)
    local rocker_item = ParaUI.GetUIObject("mobile_move_button")
    if rocker_item and rocker_item:IsValid() then
        local x,y,width,height = rocker_item:GetAbsPosition()
        local real_pos = MobileMainPage.rocker_real_point
        local left,right,top,bottom = real_pos.x - width/2,real_pos.x + width/2,real_pos.y - height/2,real_pos.y + height/2
        local offset = 20
        if click_x > left - offset and click_x < right + offset and click_y > top - offset and click_y < bottom + offset then
            if not MobileMainPage.IsClickRocker then
                MobileMainPage.IsClickRocker = true
                if MobileMainPage.delayTimer then
                    MobileMainPage.delayTimer:Change()
                end
                MobileMainPage.delayTimer = commonlib.TimerManager.SetTimeout(function()  
                    MobileMainPage.IsClickRocker = false
                end,doubleKeyTime)
            else
                MobileMainPage.IsClickRocker = false
				TouchVirtualKeyboardIcon = TouchVirtualKeyboardIcon.GetSingleton()
				if TouchVirtualKeyboardIcon then
					local keyboard = TouchVirtualKeyboardIcon:GetKeyBoard()
                    if not keyboard:isVisible() and not TouchVirtualKeyboardIcon:isVisible() then
					    TouchVirtualKeyboardIcon:ShowKeyboard(true)
                        if keyboard:isVisible() then
                            if(keyboard:IsFocusedMode()) then
                                keyboard:SetTransparency(0.85, true);
                            else
                                keyboard:SetTransparency(TouchVirtualKeyboardIcon.default_transparency, true);	
                            end
                        end
                        MobileMainPage.ShowKeyButton()
                    end
					keyboard:Connect("hidden", MobileMainPage, function()
                        if MobileMainPage.keyButton then
                            MobileMainPage.keyButton.visible = false
                            local obj1 = ParaUI.GetUIObject("mobile_move_button_bg")
                            local obj2 = ParaUI.GetUIObject("mobile_move_button_touch")
                            obj1.visible = true
                            obj2.visible = true
                        end
                    end)
                    
				end
            end
        end
    end
end

function MobileMainPage.OnTouchRocker(touch)
    MobileMainPage.SetUIFocus("mobile_move_button_touch")
    MobileMainPage.InitRockerData()
    if not MobileMainPage.touch_move_item then
        MobileMainPage.touch_move_item = ParaUI.GetUIObject("mobile_move_button_touch")
    end
    local x = touch.x
    local y = touch.y
    local type = touch.type
    local touch_session = TouchSession.GetTouchSession(touch);
    if type == "WM_POINTERDOWN" then
        if MobileMainPage.touch_move_item then
            touch_session:SetField("keydownBtn", MobileMainPage.touch_move_item);
            MobileMainPage.touch_move_item.isDragged = nil;
            MobileMainPage.RefreshRocker(x,y,true)
        end
        
    elseif type == "WM_POINTERUPDATE" then
        local keydownBtn = touch_session:GetField("keydownBtn");
		if(keydownBtn and touch_session:IsDragging()) then
            MobileMainPage.RefreshRocker(x,y)
        end
    elseif type == "WM_POINTERUP" then
        MobileMainPage.StopMoveState()
        MobileMainPage.RefreshRocker()
        MobileMainPage.OnClickRocker(x,y)
    end
end

function MobileMainPage.CheckTouchDirectArea(x,y)
    if not MobileMainPage.rocker_real_point or not MobileMainPage.rock_operate_point then
        return 
    end
    local center_x = MobileMainPage.rocker_real_point.x
    local center_y = MobileMainPage.rocker_real_point.y
    local center_width = MobileMainPage.rock_operate_point.width
    local center_height = MobileMainPage.rock_operate_point.height
    local offset = 30

    local disX = x - center_x
    local disY = y - center_y
    local distance = disX^2 + disY^2
    local min_dis = (math.floor(math.abs(disX) - offset - center_width/2))^2 + (math.floor(math.abs(disY) - offset - center_height/2))^2
    local state = MobileMainPage.GetDirectionState({x,y}, {center_x,center_y})
    return state and distance > min_dis
end

function MobileMainPage.CheckTouchPoint(x,y)
    
end

function MobileMainPage.RefreshRocker(x,y,isDown)
    if not x then
        if MobileMainPage.rock_operate_point then
            MobileMainPage.rock_operate_point.x = MobileMainPage.rocker_point.x
            MobileMainPage.rock_operate_point.y = MobileMainPage.rocker_point.y
        end
        return 
    end
    -- and not MobileMainPage.IsShowCodeWindow
    if isDown and (not MobileMainPage.CheckTouchDirectArea(x,y) or (MobileMainPage.IsShowCodeWindow and MobileMainPage.CheckTouchDirectArea(x,y)))then
        return
    end

    local center_pos = {MobileMainPage.rocker_real_point.x,MobileMainPage.rocker_real_point.y}
    MobileMainPage.ChangeMoveState(x, y, center_pos)

    local distance = (center_pos[1] - x)*(center_pos[1] - x) + (center_pos[2] - y)*(center_pos[2] - y)
    local radius = math.floor(MobileMainPage.radius*0.5 + 0.5)
    local max_distance = radius * radius
    
    if MobileMainPage.rock_operate_point then
        local param_y = y - center_pos[2]
        local param_x = x - center_pos[1]
        local rad = math.atan2(-param_y,  param_x) 
        if MobileMainPage.rock_operate_point_bg and distance <= max_distance then
            local left,top = MobileMainPage.start_x or 0,MobileMainPage.start_y or 0
            MobileMainPage.rock_operate_point.x = x - left - MobileMainPage.rock_operate_point.width/2
            MobileMainPage.rock_operate_point.y = y - top -MobileMainPage.rock_operate_point.height/2
        end
    end
end


function MobileMainPage.GetDirectionState(mouse_pos, center_pos)
	local param_x = mouse_pos[1] - center_pos[1]
	local param_y = mouse_pos[2] - center_pos[2]

	local rotation = math.atan2(-param_y,  param_x) * 180/math.pi  
	if rotation < 22.5 and rotation >= -22.5 then
		return "Right"
	elseif rotation < -22.5 and rotation >= -67.5 then
		return "DownRight"
	elseif rotation < -67.5 and rotation >= -112.5 then
		return "Down"
	elseif rotation < -112.5 and rotation >= -157.5 then
		return "DownLeft"
	elseif rotation < -157.5 or rotation >= 157.5 then
		return "Left"
	elseif rotation < 157.5 and rotation >= 112.5 then
		return "UpLeft"
	elseif rotation < 112.5 and rotation >= 67.5 then
		return "Up"
	elseif rotation < 67.5 and rotation >= 22.5 then
		return "UpRight"
	end
end


function MobileMainPage.SendRawKeyEvent(key, isDown)
	if(key and key ~= "") then
		Keyboard:SendKeyEvent(isDown and "keyDownEvent" or "keyUpEvent", key);
	end
end

function MobileMainPage.ChangeMoveState(x, y, center_pos)
	local state = MobileMainPage.GetDirectionState({x, y}, center_pos)
	if state == MobileMainPage.cur_move_state or state == nil then
		return
	end
	MobileMainPage.StopMoveState()
	MobileMainPage.cur_move_state = state
	local key_name_list = MobileMainPage.DirectionKey[MobileMainPage.cur_move_state]
	MobileMainPage.SetKeyListState(key_name_list, true)
end

function MobileMainPage.StopMoveState()
	if MobileMainPage.cur_move_state then
		local last_key_name_list = MobileMainPage.DirectionKey[MobileMainPage.cur_move_state]
		MobileMainPage.SetKeyListState(last_key_name_list, false)
		MobileMainPage.cur_move_state = nil
	end
end

function MobileMainPage.SetKeyListState(key_name_list, state)
	for k, v in pairs(key_name_list) do
        local vKey = key_maps[v]
        if vKey then
            MobileMainPage.SendRawKeyEvent(vKey, state)
        end
	end
end

-------------------------
-- Camera Recorder 
-------------------------

local touch_time = 0
local touch_timer = nil
local progressName = "timePrgress"
local normal = 1.0
local maxScale = 1.25
local max_touch_time = 150
local touch_delta = 10
local curR,curG,curB = 255,251,210
local penColor = "#def2ff"

function MobileMainPage.IsRecord()
	return MobileMainPage.IsRecording
end

function MobileMainPage.StopRecord()
	if not MobileMainPage.IsRecording then
		return 
	end
	MobileMainPage.IsRecording = false
	Recording.CancelRecord()
end

function MobileMainPage.OnTouchCamera(touch)
	-- handle the touch
	local touch_session = TouchSession.GetTouchSession(touch);
	local btnItem = ParaUI.GetUIObject("btn_record_game")
	if(touch.type == "WM_POINTERDOWN") then
        if not MobileMainPage.IsInRecording() and btnItem then
            touch_session:SetField("keydownBtn", btnItem);
			btnItem.isDragged = nil;
			btnItem.scalingx = maxScale
			btnItem.scalingy = maxScale
			_guihelper.SetUIColor(btnItem,"#ffffff")
			if not MobileMainPage.IsRecording then
				MobileMainPage.TouchCamera(true)
			end	
            MobileMainPage.ShowCameraTip(true)
        end
	elseif(touch.type == "WM_POINTERUPDATE") then
		local keydownBtn = touch_session:GetField("keydownBtn");
		if(keydownBtn and touch_session:IsDragging()) then
			
		end
		
	elseif(touch.type == "WM_POINTERUP") then
		_guihelper.SetUIColor(btnItem,"#ffffff")
		btnItem.scalingx = normal
		btnItem.scalingy = normal
		MobileMainPage.TouchCamera(false)
        MobileMainPage.ShowCameraTip(false)
	end
end

function MobileMainPage.ShowCameraTip(bShow)
    local tipCamera = ParaUI.GetUIObject("mobile_camera_tip")
    if tipCamera and tipCamera:IsValid() then
        tipCamera.visible = bShow == true
    end
end

function MobileMainPage.HideCamera(bHide)
    local pnlOperate = ParaUI.GetUIObject("mobiel_operate_right")
	local btnCamera = ParaUI.GetUIObject("btn_record_game")
	if btnCamera then
		_guihelper.SetUIColor(btnCamera,"#ffffff")
		btnCamera.visible = not bHide
        pnlOperate.visible = not bHide
		btnCamera.scalingx = normal
		btnCamera.scalingy = normal
		if bHide then
			MobileMainPage.progress_angle = 0
			curR,curG,curB = 255,251,210
			penColor = "#fffbd2"
            MobileMainPage.ShowCameraTip(false)
		end

	end
end

function MobileMainPage.SetRecord(isRecord)
	MobileMainPage.IsRecording = isRecord
end

function MobileMainPage.DrawProgressView(parent)
	if not parent then
		return 
	end
    local _,_,width,height = parent:GetAbsPosition()
    local _ownerDrawBtn = ParaUI.CreateUIObject("container", "MobileMainPage.touchprogress", "_lt", 0, 0, 56, 56);
	_ownerDrawBtn:SetField("OwnerDraw", true);
    local radius = 35
    local x,y = 28,27
    local ra = 0
    local p_width = 3
    local line_num = 800
	_ownerDrawBtn:GetAttributeObject():SetField("ClickThrough", true)
	_ownerDrawBtn:SetScript("ondraw", function()
        ra = MobileMainPage.progress_angle * line_num
        ParaPainter.SetPen(penColor)
        for i=1,ra do
            local r = i / line_num 
            local dx = x + radius * math.cos(math.rad(r))
            local dy = y + radius * math.sin(math.rad(r))
            local dx1 = x + (radius - p_width) * math.cos(math.rad(r))
            local dy2 = y + (radius - p_width) * math.sin(math.rad(r))
            ParaPainter.DrawLine(dx1, dy2, dx, dy)
        end
    end);
	parent:AddChild(_ownerDrawBtn);
end

function MobileMainPage.UpdatePenColor(timer)
	local disR,disG,disB = MobileMainPage.GetColorDis()
	curR = curR - disR
	curG = curG - disG
	curB = curB - disB
	penColor = Color.ConvertRGBAStringToColor(string.format("%d %d %d", curR , curG, curB))
end

local colorDisR,colorDisG,colorDisB
function MobileMainPage.GetColorDis()
	if not colorDisR then
		local startR,startG,satrtB = 255,251,210
		local endR,endG,endB = 255,204,0
		colorDisR = math.floor((startR - endR)/math.floor(max_touch_time / touch_delta))
		colorDisG = math.floor((startG - endG)/math.floor(max_touch_time / touch_delta))
		colorDisB = math.floor((satrtB - endB)/math.floor(max_touch_time / touch_delta))
	end
	return colorDisR,colorDisG,colorDisB
end

function MobileMainPage.TouchCamera(bTouch)
	if MobileMainPage.IsRecording and bTouch then
		return 
	end
	MobileMainPage.IsRecording = bTouch
	touch_time = 0
	if not bTouch then
		if touch_timer then
			touch_timer:Change()
			touch_timer = nil
		end
		curR,curG,curB = 255,251,210
		penColor = "#fffbd2"
		MobileMainPage.progress_angle = 0
		return
	end
	
	local angle_delta =  (360 / math.floor(max_touch_time / touch_delta))
	touch_timer = commonlib.Timer:new({callbackFunc = function(timer)
		touch_time = touch_time + touch_delta
		MobileMainPage.progress_angle = MobileMainPage.progress_angle + angle_delta
		MobileMainPage.UpdatePenColor(timer)
		if touch_time > max_touch_time then
			MobileMainPage.HideCamera(true)
			local RecordAnimation = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/RecordAnimation.lua") 
    		RecordAnimation.ShowView(function()
				Recording.ShowView()
				Recording.StartRecord()
			end)
			timer:Change()
		end
	end})
	touch_timer:Change(0, touch_delta)
end

function MobileMainPage.ShowShortScreen()
	local MobileRecordFinish = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileRecordFinish.lua") 
    MobileRecordFinish.ShowView()
end

function MobileMainPage.IsInRecording()
    return Recording.IsVisible()
end

function MobileMainPage.UpdateRockerPos(mode)
    local mobile_move_node = ParaUI.GetUIObject("mobile_move_node")

    if not mobile_move_node:IsValid() then
        return
    end
    mobile_move_node.x = 0
    mobile_move_node.y = -mobile_move_node.height
    if mode == "movie" then
        local offset_config = rockerPosConfig.OnMoviceEdit
        mobile_move_node.x = mobile_move_node.x + offset_config.offset_x
        mobile_move_node.y = mobile_move_node.y + offset_config.offset_y
    end
    MobileMainPage.InitRocker()
end

local nodeCnf = {
    _lt = "MobileMainPage.operate_lt",
    _lb = "mobile_move_node",
    _rt = "mobiel_operate_right",
    _rb = "MobileMainPage.operate_rb"
}
function MobileMainPage.ShowButtonsByAlign(align,bShow)
    if align and align ~= "" and nodeCnf[align] then
        local name = nodeCnf[align]
        local align_node = ParaUI.GetUIObject(name)
        if not align_node:IsValid() then
            return
        end
        align_node.visible = bShow == true
    end
end