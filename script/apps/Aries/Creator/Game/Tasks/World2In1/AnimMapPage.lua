--[[
Title: AnimMapPage
Author(s): yangguiyi
Date: 2021/6/18
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/AnimMapPage.lua").Show();
--]]
local AnimMapPage = NPL.export();
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local page
function AnimMapPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = AnimMapPage.CloseView
    page.OnCreate = AnimMapPage.OnCreate
end

function AnimMapPage.CloseView()
    AnimMapPage.WorldListData = nil

    if AnimMapPage.tween_x then
        AnimMapPage.tween_x:Stop()
        AnimMapPage.tween_y:Stop()
        AnimMapPage.tween_scale_width:Stop()
        AnimMapPage.tween_scale_height:Stop()
        AnimMapPage.tween_x = nil
        AnimMapPage.tween_y = nil
        AnimMapPage.tween_scale_width = nil
        AnimMapPage.tween_scale_height = nil
    end
end

function AnimMapPage.Show()
    AnimMapPage.ShowView()
end

function AnimMapPage.ShowView()
    if page and page:IsVisible() then
        return
    end
    AnimMapPage.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/AnimMapPage.html",
        name = "AnimMapPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        cancelShowAnimation = true,
        
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    AnimMapPage.StartAnim()
end

function AnimMapPage.HandleData()
    -- body
end

function AnimMapPage.GetDesc1()
    local world_name = WorldCommon.GetWorldTag("name")
    
    return string.format("请选择你要入驻至《%s》课程世界的迷你地块", world_name)
end

function AnimMapPage.OnClickCreate()
end

function AnimMapPage.OnCreate()
    --ParaUI.SetUIScale(0.8, 0.8);
    local ui_object = ParaUI.GetUIObject("text_root");
    local screen_size = ParaUI.GetUIObject("root"):GetAttributeObject():GetField("BackBufferSize", {1280, 720});
    local mid_width = screen_size[1]/2
    local mid_height = screen_size[2]/2

    ui_object.x = mid_width - 200
    ui_object.y = mid_height - 190
    ui_object.visible = false
end

function AnimMapPage.StartAnim()
    local ui_object = ParaUI.GetUIObject("world_2in1_anim_map");
    local scale = 0.82
    local end_width = 256
    local end_height = 256

    local begain_width = end_width * scale
    local begain_hieght = end_height * scale

    -- local att = ParaEngine.GetAttributeObject()
    -- local screen_size = att:GetField("ScreenResolution", {1280,720});
    local screen_size = ParaUI.GetUIObject("root"):GetAttributeObject():GetField("BackBufferSize", {1280, 720});
    local mid_width = screen_size[1]/2
    local mid_height = screen_size[2]/2

    local start_pos = {x = screen_size[1] - begain_width, y = 0}
    local end_pos = {x = mid_width - end_width/2, y = mid_height - end_height/2}

    local object = ui_object
    object.visible = true
    -- object.width = begain_width
    -- object.height = begain_hieght
    AnimMapPage.tween_x=CommonCtrl.Tween:new{
			obj=object,
			prop="x",
			begin=start_pos.x,
			change= end_pos.x - start_pos.x,
			duration=1}

	AnimMapPage.tween_x.func=CommonCtrl.TweenEquations.easeNone;
	AnimMapPage.tween_x:Start();

    AnimMapPage.tween_scale_width=CommonCtrl.Tween:new{
			obj=object,
			prop="width",
			begin=begain_width,
			change=end_width - begain_width,
			duration=1}

	AnimMapPage.tween_scale_width.func=CommonCtrl.TweenEquations.easeNone;
	AnimMapPage.tween_scale_width:Start();

    AnimMapPage.tween_scale_height=CommonCtrl.Tween:new{
        obj=object,
        prop="height",
        begin=begain_hieght,
        change=end_height - begain_hieght,
        duration=1}

    AnimMapPage.tween_scale_height.func=CommonCtrl.TweenEquations.easeNone;
    AnimMapPage.tween_scale_height:Start();

    AnimMapPage.tween_y=CommonCtrl.Tween:new{
		obj=object,
		prop="y",
		begin=start_pos.y,
		change=end_pos.y - start_pos.y,
		duration=1,
		MotionFinish = function()
			AnimMapPage.tween_x:Stop()
			AnimMapPage.tween_y:Stop()
            AnimMapPage.tween_scale_width:Stop()
            AnimMapPage.tween_scale_height:Stop()
			AnimMapPage.tween_x = nil
			AnimMapPage.tween_y = nil
            AnimMapPage.tween_scale_width = nil
            AnimMapPage.tween_scale_height = nil
            AnimMapPage.AnimEnd()
            --SummerCampSignAnim.PlayAnim(index)
		end
	}

	AnimMapPage.tween_y.func=CommonCtrl.TweenEquations.easeNone;
	AnimMapPage.tween_y:Start();
end

function AnimMapPage.AnimEnd()
    local ui_object = ParaUI.GetUIObject("text_root");
    ui_object.visible = true
end

function AnimMapPage.GetDesc1()
    local name = WorldCommon.GetWorldTag("name") or ""
    return string.format("点击红色区域入驻《%s》课程世界创作区", name)
end

function AnimMapPage.OnClickTop()
    AnimMapPage.Close()
    World2In1.OnEnterSchoolRegion()
end

function AnimMapPage.OnClickLeft()
    AnimMapPage.Close()
    World2In1.OnEnterAllRegion()
end

function AnimMapPage.OnClickToCreate()
    AnimMapPage.Close()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/WorldCreatePage.lua").Show();
end

function AnimMapPage.OnClickRight()
    AnimMapPage.Close()
    World2In1.OnEnterGradeRegion()
end

function AnimMapPage.OnClickBottom()
    AnimMapPage.Close()
    World2In1.OnEnterCourseRegion()
end

function AnimMapPage.Close()
    if page then
        page:CloseWindow()
        AnimMapPage.CloseView()
    end
end
