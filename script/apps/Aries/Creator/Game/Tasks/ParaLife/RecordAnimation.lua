--[[
    author:{pbb}
    time:2022-01-21 17:25:30
    use lib:
    local RecordAnimation = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/RecordAnimation.lua") 
    RecordAnimation.ShowView()
]]
local RecordAnimation = NPL.export()

local page = nil
function RecordAnimation.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = RecordAnimation.OnCreate
end

function RecordAnimation.ShowView(OnCloseFunc)
    if RecordAnimation.IsVisible() then
        return
    end
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/RecordAnimation.html",
        name = "RecordAnimation.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 4,
        directPosition = true,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    params._page.OnClose = function()
		if(OnCloseFunc) then
			OnCloseFunc()
		end
	end;
end

function RecordAnimation.IsVisible()
    return page and page:IsVisible()
end

function RecordAnimation.OnCreate()
    local record_back = ParaUI.GetUIObject("record_back")
    if record_back and record_back:IsValid() then
        RecordAnimation.PlayCutDown(record_back)
    end
end

function RecordAnimation.PlayCutDown(parent)
    local startIndex = 3
    local tipBg = ParaUI.CreateUIObject("container", "tipBg", "_lt", -231/2, -329/2, 231, 329);
    tipBg.background = "Texture/Aries/Creator/keepwork/Paralife/record/num3_207X329_32bits.png;0 0 231 329"; 
    parent:AddChild(tipBg)

    local touch_timer = commonlib.Timer:new({callbackFunc = function(timer)
        startIndex = startIndex - 1
        if timer and startIndex < 1 then
			timer:Change()
            ParaUI.DestroyUIObject(tipBg)
            RecordAnimation.PlayRecord(parent)
            return
		end
        tipBg.background = string.format("Texture/Aries/Creator/keepwork/Paralife/record/num%d_207X329_32bits.png;0 0 231 329",startIndex)
	end})
	touch_timer:Change(1000, 1000);
end

function RecordAnimation.PlayRecord(parent)
    local startIndex = 2
    local cameraBg = ParaUI.CreateUIObject("button", "cameraBg", "_lt", -512/2, -512/2, 512, 512);
    cameraBg.background = "Texture/Aries/Creator/keepwork/Paralife/record/dakai_395x452_32bits.png;0 0 512 512"; 
    parent:AddChild(cameraBg)

    local touch_timer = commonlib.Timer:new({callbackFunc = function(timer)
        startIndex = startIndex - 1
        if timer and startIndex < 1 then
			timer:Change()
            RecordAnimation.CloseView()
            return
		end
        cameraBg.background = "Texture/Aries/Creator/keepwork/Paralife/record/guanbi_376x318_32bits.png;0 0 512 512"
	end})
	touch_timer:Change(500, 500);
end

function RecordAnimation.CloseView()
    if page then
        page:CloseWindow()
        page = nil
    end
end