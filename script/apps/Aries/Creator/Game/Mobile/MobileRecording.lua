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
local ScreenRecorderHandler = commonlib.gettable("MyCompany.Aries.Game.Mobile.ScreenRecorderHandler");

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
		_stdBtn.background = record_url.."zanting_128x128_32bits.png"
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

		MobileRecording.CreateProgressView(tipBg)
	end
end

function MobileRecording.IsVisible()
	return page and page:IsVisible()
end

function MobileRecording.CreateProgressView(parent)
	if not parent then
		return 
	end
	local x,y,width,height = parent:GetAbsPosition()
	local zorder = parent.zorder
    local _ownerDrawBtn = ParaUI.CreateUIObject("container", "recording_progress", "_rt", -310, 20, 300, 100);
	_ownerDrawBtn.background = ""
	_ownerDrawBtn.zorder = 1
	_ownerDrawBtn:GetAttributeObject():SetField("ClickThrough", true);
	for i=1,4 do 
		local circle_sp = ParaUI.CreateUIObject("container", "circle_sp"..i, "_lt", 220 , 8, 64, 64);
		circle_sp.zorder=12-(i - 1)*2;
		circle_sp.rotation = math.rad(i*90 - 90)
		circle_sp.background = "Texture/Aries/Creator/keepwork/Paralife/record/record_prgress_32x32_32bits.png";
		circle_sp:GetAttributeObject():SetField("ClickThrough", true);
		_ownerDrawBtn:AddChild(circle_sp);
	end
	_ownerDrawBtn:AttachToRoot();
	
	MobileRecording.sp_progresses = {}
	for i=1,4 do
		local circle_sp_progress = ParaUI.CreateUIObject("container", "circle_sp_progress", "_lt", 220 , 8, 64, 64);
		circle_sp_progress.rotation = math.rad(i*90 - 90)
		circle_sp_progress.zorder = 11-(i - 1) * 2
		if i == 4 then
			circle_sp_progress.zorder = 13
			circle_sp_progress.visible = false
		end
		_guihelper.SetUIColor(circle_sp_progress,"0 0 0")
		circle_sp_progress.background = "Texture/Aries/Creator/keepwork/Paralife/record/record_prgress_32x32_32bits.png";
		circle_sp_progress:GetAttributeObject():SetField("ClickThrough", true);
		_ownerDrawBtn:AddChild(circle_sp_progress);
		MobileRecording.sp_progresses[#MobileRecording.sp_progresses + 1] = circle_sp_progress
	end
end

function MobileRecording.SetPercent(percent)
	if percent > 100 then
		percent = 100

	end
	local playIndex = math.ceil(percent/25)
	for i = 1,4 do
		if i == playIndex then
			if playIndex == 4 then				
				MobileRecording.sp_progresses[i].visible = true 
			end
			local angle = (i - 1)*90 + 90*((percent - (i - 1) * 25))/25
			MobileRecording.sp_progresses[i].rotation = math.rad(angle)
		elseif i > playIndex then
			local angle = i*90 - 90
			MobileRecording.sp_progresses[i].rotation = math.rad(angle)
			if i == 4 then
				MobileRecording.sp_progresses[i].visible = false
			end
		elseif i < playIndex then
			local angle = i*90
			MobileRecording.sp_progresses[i].rotation = math.rad(angle)
			if i == 4 then
				MobileRecording.sp_progresses[i].visible = false
			end
		end
	end	
end

function MobileRecording.StartRecordImp()
	if MobileRecording.IsRecording then
		return 
	end
	record_time = 0
	local index = 0
	local count = 0
	local percent = 0
	MobileRecording.IsRecording = true

	local startFunc = function()
		local angle_delta =  (360 / math.floor(max_record_time / record_detal)) --math.floor
		local percent_delta = (100 / math.floor(max_record_time / record_detal)) 
		record_timer = commonlib.Timer:new({callbackFunc = function(timer)
			record_time = record_time + record_detal
			local h,m,s = commonlib.timehelp.SecondsToHMS(record_time/1000);
			local strTime = string.format("%.2d:%.2d", m,math.floor(s));
			local time_text = ParaUI.GetUIObject("text_time")
			time_text.text= strTime
			--小红点
			local record_dot = ParaUI.GetUIObject("record_dot")
			index = index + 1
			-- will cause dropped frames
			-- angle = angle + angle_delta
			percent = percent + percent_delta
			MobileRecording.SetPercent(percent)
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

	if (System.os.CompareParaEngineVersion('1.5.1.0')) then
		ScreenRecorderHandler.SetStartedCallbackFunc(function()
			startFunc();
		end)
	else
		startFunc();
	end

	GameLogic.RunCommand("/screenrecorder start")
end

function MobileRecording.StartRecord()
	local MobilePermissionPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobilePermissionPage.lua")
	MobilePermissionPage.ShowPage(function()
		MobileRecording.StartRecordImp()
	end,function()
		if record_timer then
			record_timer:Change()
			record_timer = nil
		end
		MobileMainPage.SetRecord(false)
		MobileMainPage.HideCamera(false)
		MobileRecording.IsRecording = false
		MobileRecording.ClosePage()
	end)
end

function MobileRecording.StopRecord()
	if not MobileRecording.IsRecording then
		return
	end
	if record_timer then
		record_timer:Change()
		record_timer = nil
		MobileRecording.IsRecording = false
		-- 录制已结束，显示录制结果界面
		if (System.os.CompareParaEngineVersion('1.5.1.0')) then
			GameLogic.RunCommand("/screenrecorder stop");
			Mod.WorldShare.MsgBox:Show(L"正在转码，请稍候...", 120000);
			ScreenRecorderHandler.SetRecordFinishedCallbackFunc(function(savedPath)
				Mod.WorldShare.MsgBox:Close();
				MobileMainPage.ShowShortScreen();
			end);
		else
			GameLogic.RunCommand("/screenrecorder stop");
			MobileMainPage.ShowShortScreen();
		end
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

		ParaUI.Destroy("recording_progress")
    end
end