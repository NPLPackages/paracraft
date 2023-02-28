--[[
author:{ygy}
time:2022-11-3

local MobileScreenshotPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileScreenshotPage.lua")
MobileScreenshotPage.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local MobileScreenshotPage = NPL.export()
-- local filePath = "Texture/Aries/Creator/keepwork/Mobile/help/"
MobileScreenshotPage.default_desc = ""
MobileScreenshotPage.desc_upload = true


local page
function MobileScreenshotPage.OnInit()
    page = document:GetPageCtrl();  
    page.OnCreate = MobileScreenshotPage.OnCreate
    page.OnClose = MobileScreenshotPage.OnClose
    -- if(MobileScreenshotPage.image_filepath) then
	-- 	page:SetValue("WorldImage", MobileScreenshotPage.image_filepath);
	-- end    
end

function MobileScreenshotPage.OnClose()
    local MobileSaveWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileSaveWorldPage.lua")
    MobileSaveWorldPage.ShowPage(MobileSaveWorldPage.button_type)
end

-- MobileScreenshotPage.page_type: "show_screenshot", "to_screenshot"
function MobileScreenshotPage.ShowPage()
    MobileScreenshotPage.page_type = "to_screenshot"    
    local params = {
        url = "script/apps/Aries/Creator/Game/Mobile/MobileScreenshotPage.html",
        name = "MobileScreenshotPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
        click_through = true,
        directPosition = true,
            align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    -- MobileScreenshotPage.TakeImage(true);    
end

function MobileScreenshotPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function MobileScreenshotPage.RefreshPage()
	if page then
		page:Refresh(0)
	end
end

function MobileScreenshotPage.OnCreate()
    if MobileScreenshotPage.image_filepath then
        page:SetUIValue("WorldImage", MobileScreenshotPage.image_filepath);
    end
end


function MobileScreenshotPage.TakeImage(bTakeIfFileDoesNotExist)
	--local page = MobileScreenshotPage.sharepage;
	local filepath = MobileScreenshotPage.GetPreviewImagePath("preview_big.jpg");
	MobileScreenshotPage.image_filepath = filepath;
	
	local function SaveAsWorldPreview()
		NPL.load("(gl)script/ide/System/Util/ScreenShot.lua");
		local ScreenShot = commonlib.gettable("System.Util.ScreenShot");
		if(ScreenShot.TakeSnapshot(filepath,900,600, false)) then
            if MobileScreenshotPage.image_filepath then
                page:SetUIValue("WorldImage", MobileScreenshotPage.image_filepath);
            end
		end
	end
	
	if(ParaIO.DoesFileExist(filepath, true)) then
		if(not bTakeIfFileDoesNotExist) then
			SaveAsWorldPreview();
		else
		end
	else
		SaveAsWorldPreview();
	end
end


function MobileScreenshotPage.OnScreenshoot()
    MobileScreenshotPage.page_type = "show_screenshot"    
    MobileScreenshotPage.TakeImage()
    MobileScreenshotPage.RefreshPage()
end

function MobileScreenshotPage.OnScreenshootAgain()
    MobileScreenshotPage.page_type = "to_screenshot"    
    MobileScreenshotPage.RefreshPage()
end

function MobileScreenshotPage.OnSure()
    local little_filepath = MobileScreenshotPage.GetPreviewImagePath("preview.jpg");
    NPL.load("(gl)script/ide/System/Util/ScreenShot.lua");
    local ScreenShot = commonlib.gettable("System.Util.ScreenShot");
    if condition then
        -- body
    end
    ScreenShot.TakeSnapshot(little_filepath,300,200, false)
   
    local filepath = MobileScreenshotPage.GetPreviewImagePath("preview_big.jpg");
    if(ParaIO.DoesFileExist(filepath, false)) then
        ParaIO.DeleteFile(filepath)
    end

    MobileScreenshotPage.ClosePage()
end

function MobileScreenshotPage.GetPreviewImagePath(img_name)
    if not ParaWorld.GetWorldDirectory() then
        return ''
    end

    if System.os.GetPlatform() ~= 'win32' then
        return ParaIO.GetWritablePath() .. ParaWorld.GetWorldDirectory() .. img_name
    else
        return ParaWorld.GetWorldDirectory() .. img_name
    end
end