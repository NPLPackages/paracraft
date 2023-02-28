--[[
    author:{pbb}
    time:2022-02-17 14:24:52
    use lib:
    local MobileRecording = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileRecording.lua") 
    MobileRecording.ShowView()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileMainPage.lua")
local MobileMainPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileMainPage");
local MobileRecording = NPL.export()
local record_url = "Texture/Aries/Creator/keepwork/Paralife/record/"
local page = nil
local record_time = 0
local record_detal = 100
local max_record_time = 120000
local record_timer
local angle = 0
MobileRecording.IsRecording = false
function MobileRecording.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = MobileRecording.OnCreate
end

function MobileRecording.ShowView()
	if MobileRecording.IsRecording then
		return 
	end
    local view_width = 310
    local view_height = 100
    local params = {
        url = "script/apps/Aries/Creator/Game/Mobile/MobileRecording.html",
        name = "MobileRecording.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        align = "_rt",
		x = -view_width,
		y = 0,
		width = view_width,
		height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function MobileRecording.OnCreate()
	angle = 0
    MobileRecording.ShowMobileRecordingUI()
end

function MobileRecording.ShowMobileRecordingUI()
	if page then
		local pageRoot = page:GetParentUIObject() 
		local tipBg = ParaUI.CreateUIObject("container", "record_Bg", "_rt", -310, 20, 300, 80);
		tipBg.background = record_url.."beijing_308x88_32bits0.png;0 0 308 88"; 
		pageRoot:AddChild(tipBg)

		local _stdBtn = ParaUI.CreateUIObject("button", "stdButton", "_lt", 220, 8, 64, 64);
		_stdBtn.background = record_url.."zantinganniu_55x55_32bits.png;0 0 55 55"
		_stdBtn:SetScript("onclick", function()
			MobileRecording.StopRecord()
			MobileRecording.ClosePage()
		end)
		tipBg:AddChild(_stdBtn);

		local btnBg = ParaUI.CreateUIObject("button", "btn_Bg", "_lt", 190, 0, 120, 120);
		btnBg.background = ""
		btnBg:SetScript("onclick", function()
			MobileRecording.StopRecord()
			MobileRecording.ClosePage()
		end)
		pageRoot:AddChild(btnBg)

		local record_dot = ParaUI.CreateUIObject("button", "record_dot", "_lt", 20, 25, 31, 31)
		record_dot.background = record_url.."hongdian_31x31_32bits.png;0 0 31 31"
		record_dot:SetScript("onclick", function()
			MobileRecording.StopRecord()
			MobileRecording.ClosePage()
		end)
		tipBg:AddChild(record_dot);

		local time_text = ParaUI.CreateUIObject("text", "text_time", "_lt", 70,15, 220, 20)
		time_text.text= "00:00"
		time_text.font = "System;40;bold";
		_guihelper.SetFontColor(time_text,"#000000")
		tipBg:AddChild(time_text);

		MobileRecording.DrawProgressView(tipBg)
	end
end

function MobileRecording.IsVisible()
	return page and page:IsVisible()
end

function MobileRecording.DrawProgressView(parent)
	if not parent then
		return 
	end
    local _ownerDrawBtn = ParaUI.CreateUIObject("container", "canvas", "_lt", 232, 20, 50, 50);
	_ownerDrawBtn:SetField("OwnerDraw", true);
    local radius = 33
    local x,y = 20,20
    local ra = 0
    local width = 6
	_ownerDrawBtn:GetAttributeObject():SetField("ClickThrough", true);
	_ownerDrawBtn:SetScript("ondraw", function()
        ra = angle * 1000
        ParaPainter.SetPen("#000000")
        for i=1,ra do
            local r = i / 1000 
            local dx = x + radius * math.cos(math.rad(r))
            local dy = y + radius * math.sin(math.rad(r))
            local dx1 = x + (radius - width) * math.cos(math.rad(r))
            local dy2 = y + (radius - width) * math.sin(math.rad(r))
            ParaPainter.DrawLine(dx1, dy2, dx, dy)
        end
    end);
	parent:AddChild(_ownerDrawBtn);
end

function MobileRecording.StartRecord()
	if MobileRecording.IsRecording then
		return 
	end
	record_time = 0
	local index = 0
	local count = 0
	MobileRecording.IsRecording = true
	GameLogic.RunCommand("/screenrecorder start")
	local angle_delta =  (360 / math.floor(max_record_time / record_detal)) --math.floor
	record_timer = commonlib.Timer:new({callbackFunc = function(timer)
		record_time = record_time + record_detal
		local h,m,s = commonlib.timehelp.SecondsToHMS(record_time/1000);
		local strTime = string.format("%.2d:%.2d", m,math.floor(s));
		local time_text = ParaUI.GetUIObject("text_time")
		time_text.text= strTime
		--小红点
		local record_dot = ParaUI.GetUIObject("record_dot")
		index = index + 1
		angle = angle + angle_delta
		if index > 5 then
			count = count + 1
			local color = count % 2 == 0 and "#ffffff" or "#888888"
			_guihelper.SetUIColor(record_dot,color)
			index = 0
		end
		if record_time > max_record_time then
			MobileRecording.StopRecord()
            MobileRecording.ClosePage()
		end
	end})
	record_timer:Change(0, record_detal);
end

function MobileRecording.StopRecord()
	if not MobileRecording.IsRecording then
		return
	end
	if record_timer then
		record_timer:Change()
		record_timer = nil
		MobileMainPage.ShowShortScreen()
		MobileRecording.IsRecording = false
		-- GameLogic.AddBBS(nil,"录制已结束，显示录制结果界面")
		GameLogic.RunCommand("/screenrecorder stop")
	end
end

function MobileRecording.CancelRecord()
	if not MobileRecording.IsRecording then
		return
	end
	if record_timer then
		record_timer:Change()
		record_timer = nil
		MobileMainPage.SetRecord(false)
		MobileMainPage.HideCamera(false)
		MobileRecording.IsRecording = false
		GameLogic.RunCommand("/screenrecorder stop")
		MobileRecording.ClosePage()
	end
end

function MobileRecording.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end