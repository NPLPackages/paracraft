--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampSignAnim = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignAnim.lua") 
SummerCampSignAnim.ShowView()
]]
NPL.load("(gl)script/ide/Transitions/Tween.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local SummerCampSignAnim = NPL.export()

SummerCampSignAnim.OnceAinmTime = 2000 -- 毫秒
SummerCampSignAnim.TiemrUpdataTime = 10 -- 毫秒
SummerCampSignAnim.TextToScale = 2
local page = nil
function SummerCampSignAnim.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = SummerCampSignAnim.OnCreate
    page.OnClose = SummerCampSignAnim.CloseView
end

function SummerCampSignAnim.ShowView(movice_name)
    SummerCampSignAnim.movice_name = movice_name
    keepwork.sign_wall.get_greetings({}, function(err, message, data)
        -- print("vzzzzzzzzzzzzzzzzzzzzzzzzzzzz", err)
        -- echo(data, true)
        if err == 200 then
            SummerCampSignAnim.greeting_data = data.rows
            SummerCampSignAnim.InitData()
            local view_width = 572
            local view_height = 445
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignAnim.html",
                name = "SummerCampSignAnim.ShowView", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                style = CommonCtrl.WindowFrame.ContainerStyle,
                allowDrag = false,
                enable_esc_key = true,
                zorder = 0,
                app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
                directPosition = true,
                ClickThrough = true,
                align = "_fi",
                    x = 0,
                    y = 0,
                    width = 0,
                    height = 0,
            };
            System.App.Commands.Call("File.MCMLWindowFrame", params);
            SummerCampSignAnim.AttrObject = ParaEngine.GetAttributeObject();
            
        end
    end)

end

function SummerCampSignAnim.OnCreate()
    local parent  = ParaUI.GetUIObject("summer_sign_ani_text1")
    local _this = ParaUI.CreateUIObject("text","sign_text","_lt",0,0,360,200);
    _this.text = ""
    _this.textscale = 1 
    _this.visible = false
    _guihelper.SetFontColor(_this, "#ffffff")
    parent:AddChild(_this);

    SummerCampSignAnim.AnimData = {}
    local data = {}
    data.object = parent
    data.text_object = _this
    SummerCampSignAnim.AnimData[#SummerCampSignAnim.AnimData + 1] = data

    _this = ParaUI.CreateUIObject("text","sign_text2","_lt",0,0,360,200);
    _this.text = ""
    _this.textscale = 1 
    _this.visible = false
    _guihelper.SetFontColor(_this, "#ffffff")
    parent:AddChild(_this);
    data = {}
    data.text_object = _this
    SummerCampSignAnim.AnimData[#SummerCampSignAnim.AnimData + 1] = data

    commonlib.TimerManager.SetTimeout(function()  
        SummerCampSignAnim.PlayAnim(1)
        commonlib.TimerManager.SetTimeout(function()  
            SummerCampSignAnim.PlayAnim(2)
        end, 1500);
    end, 500);
end

function SummerCampSignAnim.CloseView()
    SummerCampSignAnim.ClearTimer()
end

function SummerCampSignAnim.ClearTimer()
    if SummerCampSignAnim.AnimData then
        for key, v in pairs(SummerCampSignAnim.AnimData) do
            if v.tween_x then
                v.tween_x:Stop()
                v.tween_y:Stop()
                v.tween_scale:Stop()
                v.tween_x = nil
                v.tween_y = nil
                v.tween_scale = nil
            end
        end
    end
end

function SummerCampSignAnim.GetRandomX(flag)
    local screen_size = SummerCampSignAnim.AttrObject:GetField("ScreenResolution", {1280,720});
    local mid_width = screen_size[1]/2
    if flag == 0 then
        return math.random()
    end
end

function SummerCampSignAnim.PlayAnim(index)
    local channel = MovieManager.movieChannels[SummerCampSignAnim.movice_name]
    if channel == nil then
        SummerCampSignAnim.Close()
        return
    end

    if not channel:IsPlaying() then
        SummerCampSignAnim.Close()
        return
    end
    -- if SummerCampSignAnim.timer == nil then
    --     local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
    --         SummerCampSignAnim.UpdateAnim()
    --     end})
    --     -- delay loading for some seconds. 
    --     mytimer:Change(0, SummerCampSignAnim.TiemrUpdataTime);
    
    --     SummerCampSignAnim.timer = mytimer
    -- end
    if page == nil then
        return
    end

    local AnimData = SummerCampSignAnim.AnimData[index]
    local att = ParaEngine.GetAttributeObject();
    local screen_size = att:GetField("ScreenResolution", {1280,720});
    local mid_width = screen_size[1]/2 - 100
    local mid_height = screen_size[2]/2 - 100

    local start_pos = {}
    local end_pos = {}
    if SummerCampSignAnim.random_num == nil then
        SummerCampSignAnim.random_num = math.random(0, 1)
    else
        SummerCampSignAnim.random_num = 1 - SummerCampSignAnim.random_num
    end
    
    local random_num = SummerCampSignAnim.random_num
    local start_random_x_1 = mid_width * random_num
    local start_random_x_2 = start_random_x_1 + mid_width
    start_pos.x = math.random(start_random_x_1, start_random_x_2)

    random_num = 1 - math.random(0, 1)
    local end_random_x_1 = mid_width * random_num
    local end_random_x_2 = mid_width * (random_num + 1)
    end_pos.x = math.random(end_random_x_1, end_random_x_2)

    local start_random_y_1 = mid_height * random_num
    local start_random_y_2 = mid_height * (random_num + 1)
    start_pos.y = math.random(start_random_y_1, start_random_y_2)

    random_num = 1 - random_num
    local end_random_y_1 = mid_height * random_num
    local end_random_y_2 = mid_height * (random_num + 1)
    end_pos.y = math.random(end_random_y_1, end_random_y_2)

    
    -- AnimData.start_pos = start_pos
    -- AnimData.end_pos = end_pos

    -- local times = SummerCampSignAnim.OnceAinmTime / SummerCampSignAnim.TiemrUpdataTime
    -- AnimData.MoveSpeedX = (end_pos.x - start_pos.x) / times
    -- AnimData.MoveSpeedY = (end_pos.y - start_pos.y) / times

    local object = AnimData.text_object
    object.text = SummerCampSignAnim.GetRandomText()
    object.visible = true
    object.x = start_pos.x
    object.y = start_pos.y
    AnimData.tween_x=CommonCtrl.Tween:new{
			obj=object,
			prop="x",
			begin=start_pos.x,
			change=end_pos.x - start_pos.x,
			duration=2}

	AnimData.tween_x.func=CommonCtrl.TweenEquations.easeNone;
	AnimData.tween_x:Start();

    AnimData.tween_scale=CommonCtrl.Tween:new{
			obj=object,
			prop="textscale",
			begin=0.1,
			change=1.9,
			duration=2}

	AnimData.tween_scale.func=CommonCtrl.TweenEquations.easeNone;
	AnimData.tween_scale:Start();

    AnimData.tween_y=CommonCtrl.Tween:new{
		obj=object,
		prop="y",
		begin=start_pos.y,
		change=end_pos.y - start_pos.y,
		duration=2,
		MotionFinish = function()
			AnimData.tween_x:Stop()
			AnimData.tween_y:Stop()
            AnimData.tween_scale:Stop()
			AnimData.tween_x = nil
			AnimData.tween_y = nil
            AnimData.tween_scale = nil
            SummerCampSignAnim.PlayAnim(index)
		end
	}

	AnimData.tween_y.func=CommonCtrl.TweenEquations.easeNone;
	AnimData.tween_y:Start();
end

function SummerCampSignAnim.InitData()

end

function SummerCampSignAnim.GetRandomText()
    local list = SummerCampSignAnim.greeting_data
    if #list == 0 then
        local SummerCampSignView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignView.lua") 
        local list = SummerCampSignView.GetTeacherText()
        return list[math.random(1, #list)]
    end

    local data = list[math.random(1, #list)]
    local text = data.content
    local name_desc = "——"
    if data.user.school then
        local school = data.user.school
        name_desc = name_desc .. school.name .. " "
    end
    name_desc = name_desc .. data.user.username
    text = data.content .. "\r\n" .. name_desc
    return text
end

function SummerCampSignAnim.GetDesc()
    if SummerCampSignAnim.greeting_data then
        return SummerCampSignAnim.greeting_data.content
    end

    return ""
end

function SummerCampSignAnim.OpenSignView()
    page:CloseWindow()
    SummerCampSignAnim.CloseView()

    local SummerCampSignView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignView.lua") 
    SummerCampSignView.ShowView()
end

function SummerCampSignAnim.Close()
    if page then
        page:CloseWindow()
        SummerCampSignAnim.CloseView()
    end
end
function SummerCampSignAnim.UpdateAnim()
    local anim_data = SummerCampSignAnim.AnimData
    local object = anim_data.object

    local start_pos = anim_data.start_pos
    local end_pos = anim_data.end_pos


    if anim_data.start then
        if test_time == nil then
            test_time = 0
        end

        test_time = test_time + 1
        object.x = object.x + anim_data.MoveSpeedX

        if start_pos.x > end_pos.x then
            if object.x < end_pos.x then
                anim_data.start = false
            end
        else
            if object.x > end_pos.x then
                anim_data.start = false
            end
        end

        object.y = object.y + anim_data.MoveSpeedY

        if start_pos.y > end_pos.y then
            if object.y < end_pos.y then
                anim_data.start = false
            end
        else
            if object.y > end_pos.y then
                anim_data.start = false
            end
        end
    end
end