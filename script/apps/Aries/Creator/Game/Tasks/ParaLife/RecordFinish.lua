--[[
    author:{pbb}
    time:2022-01-21 17:25:30
    use lib:
    local RecordFinish = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/RecordFinish.lua") 
    RecordFinish.ShowView()
]]
local RecordFinish = NPL.export()
local page = nil
local file_Path = ParaIO.GetWritablePath().."temp/paralife_screen/"
RecordFinish.index = 1
function RecordFinish.OnInit()
    page = document:GetPageCtrl();
end

function RecordFinish.ShowView()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/RecordFinish.html",
        name = "RecordFinish.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 4,
        directPosition = true,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    commonlib.TimerManager.SetTimeout(function()  
        RecordFinish.PlayCutDown()
    end, 300)
    if ParaIO.DoesFileExist(file_Path) then
        ParaIO.DeleteFile(file_Path)
    end
end



function RecordFinish.PlayCutDown()
    if not page  then
        return 
    end
    local bg_width = 662
    local bg_height = 332
    local pageRoot = page:GetParentUIObject() 
    local blueBg = ParaUI.CreateUIObject("container","blueBg","_ct",-bg_width/2,-bg_height/2,bg_width,bg_height)
    blueBg.background="Texture/Aries/Creator/keepwork/Paralife/record/di_64x64_32bits.png;0 0 64 64:30 30 30 30"
    pageRoot:AddChild(blueBg)
    local scale = 1
    NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");	
    local width = 646
    local height = 315
	local filepath = file_Path.."screenshot_temp"..RecordFinish.index..".jpg"
    RecordFinish.index = RecordFinish.index + 1
    local background = "Texture/Aries/Creator/keepwork/Paralife/main/tanchuang_512x256_32bits.png"
    
    local tipBg = ParaUI.CreateUIObject("container", "record_Bg", "_ct", -width/2, -height/2, width, height);
    tipBg.background = background
    blueBg:AddChild(tipBg)

    local deleteButton = ParaUI.CreateUIObject("button", "deleteButton", "_lt", -10, -10, 71*scale, 71*scale);
    deleteButton.background = "Texture/Aries/Creator/keepwork/Paralife/record/shanchu_71x71_32bits.png;0 0 71 71"
    deleteButton:SetScript("onclick", function()
        RecordFinish.CloseView()
    end)
    blueBg:AddChild(deleteButton);

    local playButton = ParaUI.CreateUIObject("button", "playButton", "_ct", -100*scale/2,-100*scale/2, 100*scale, 100*scale);
    playButton.background = "Texture/Aries/Creator/keepwork/Paralife/record/bofang_100x100_32bits.png;0 0 100 100"
    playButton:SetScript("onclick", function()
        RecordFinish.CloseView()
        RecordFinish.SaveAnPlay()
    end)
    blueBg:AddChild(playButton)

    local shareButton = ParaUI.CreateUIObject("button", "shareButton", "_rt", -71*scale + 10, -10, 71*scale, 71*scale);
    shareButton.background = "Texture/Aries/Creator/keepwork/Paralife/record/zhuanfa_71x71_32bits.png;0 0 71 71"
    shareButton:SetScript("onclick", function()
        RecordFinish.CloseView()
        GameLogic.AddBBS(nil,"保存成功")
        GameLogic.RunCommand("/screenrecorder save")
    end)
    blueBg:AddChild(shareButton);

    if MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(filepath,width,height, false) then
        tipBg.background = filepath
    end
end

function RecordFinish.SaveAnPlay()
    GameLogic.RunCommand("/screenrecorder save")
    commonlib.TimerManager.SetTimeout(function()  
        GameLogic.RunCommand("/screenrecorder play")
    end, 1000)
end

function RecordFinish.CloseView()
    if page then
        page:CloseWindow(true);
        page = nil
    end
    local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua")
    ParalifeLiveModel.SetRecord(false)
    ParalifeLiveModel.HideCamera(false)
    ParalifeLiveModel.HideExitButton(false)    
end