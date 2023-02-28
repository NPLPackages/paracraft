--[[
Title: HonorPage
Author(s): pbb
Date: 2022/9/20
Desc:  
Use Lib:
-------------------------------------------------------
local HonorPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/HonorPage.lua");
HonorPage.ShowPage();
--]]

local HonorPage = NPL.export()
local page

local widthCnf = {
    [70009] = true,[70010] = true, [70011] = true, [70012] = true,[70014] = true, [70015] = true, [70016] = true,
}
HonorPage.honorInfo = nil
function HonorPage.OnInit()
    page = document:GetPageCtrl();
end

function HonorPage.ShowPage(honorInfo)
    if not honorInfo then
        return 
    end
    HonorPage.honorInfo = honorInfo
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/User/HonorPage.html",
        name = "HonorPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        cancelShowAnimation = true,
        -- DesignResolutionWidth = 1280,
		-- DesignResolutionHeight = 720,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    if(params._page)then
		params._page.OnClose = function()
            HonorPage.honorInfo = nil
        end
	end
end

function HonorPage.IsWidthNickName()
    local gsid = tonumber(HonorPage.honorInfo.gsId)
    return gsid and widthCnf[gsid] or false
end

function HonorPage.TrimNormUtf8TextByWidth(text, maxWidth, fontName)
	if(not text or text=="") then 
		return "" 
	end
	local width = _guihelper.GetTextWidth(text,fontName);
	
	if(width < maxWidth) then return text end
	--  Initialise numbers
	local nSize = ParaMisc.GetUnicodeCharNum(text);
	local iStart,iEnd = 1, nSize
	local curTextWidth = width
	local curText = text
	-- modified binary search
	while (curTextWidth > maxWidth) do
		if curTextWidth > 2*maxWidth then
			iEnd = math.floor((iStart + iEnd)/2)
		else
			iEnd = iEnd - 1
		end
		curText = ParaMisc.UniSubString(curText, iStart, iEnd)
		curTextWidth = _guihelper.GetTextWidth(curText,fontName);
	end
	local otherText = ParaMisc.UniSubString(text, iEnd, nSize)
	return curText,otherText
end