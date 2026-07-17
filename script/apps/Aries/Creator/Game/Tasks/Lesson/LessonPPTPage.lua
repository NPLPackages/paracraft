--[[
    author:{pbb}
    time:2022-10-12 09:41:53
    Desc:
    use lib:
    local LessonPPTPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/LessonPPTPage.lua") 
    --LessonPPTPage.ShowView()
    local isGet = LessonPPTPage.GetPPTDataByFile()
    if(not isGet) then
        LessonPPTPage.GetPPTData(ppt_url,true)
    end
]]
NPL.load("(gl)script/ide/math/StringUtil.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local StringUtil = commonlib.gettable("mathlib.StringUtil");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
local LessonPPTPage = NPL.export()
local ppt_file_path = "currentPPT.md"
local ppt_url = "https://api.keepwork.com/core/v0/repos/lesson9527%2FcodeLessons/files/lesson9527%2FcodeLessons%2FcodelessonL1%2F01_%E5%BC%80%E5%90%AF%E6%8E%A2%E7%B4%A2%E4%B9%8B%E6%97%85_PPT.md"
local pptIndex = 1
local cachePath = "temp/pptpage/"
local pptData = nil
local page = nil
function LessonPPTPage.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = LessonPPTPage.OnCreated;
end

function LessonPPTPage.ShowView()
    local view_width = 0
    local view_height = 0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Lesson/LessonPPTPage.html",
        name = "LessonPPTPage.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = 0,
        directPosition = true,
        align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    Screen:Connect("sizeChanged", LessonPPTPage, LessonPPTPage.OnResize, "UniqueConnection")
end

function LessonPPTPage.CloseView()
    if page then
        page:CloseWindow()
        page = nil
    end
    pptIndex = 1
    pptData = nil
end

function LessonPPTPage.OnCreated()
    if not page then
        return 
    end
    local progress_fg = ParaUI.GetUIObject("pptpage_fg")
    if progress_fg and progress_fg:IsValid() then
        progress_fg.width = LessonPPTPage.GetImageWidth()
        progress_fg.height = LessonPPTPage.GetImageHeight()
    end

    --没啥用的代码
    local progress_bg = ParaUI.GetUIObject("ppt_page_bg")
    if progress_bg and progress_bg:IsValid() then
        commonlib.TimerManager.SetTimeout(function()  
            progress_bg:Focus();
        end, 1500)
    end
end

function LessonPPTPage.OnResize()
    if page then
        LessonPPTPage.HideBrowser()
        LessonPPTPage.RefreshUI()
    end
end

function LessonPPTPage.GetImageWidth()
    return Screen:GetWidth()
end
function LessonPPTPage.GetImageHeight()
    return Screen:GetHeight()
end

function LessonPPTPage.OnClickNextPage()
    if pptIndex >= #pptData then
        return
    end
    LessonPPTPage.HideBrowser()
    pptIndex = pptIndex + 1
    -- LessonPPTPage.DownLoadFile()
    LessonPPTPage.RefreshUI()
end

function LessonPPTPage.OnClickPrePage()
    if pptIndex <= 1 then
        return 
    end
    LessonPPTPage.HideBrowser()
    pptIndex = pptIndex - 1
    -- LessonPPTPage.DownLoadFile()
    LessonPPTPage.RefreshUI()
end

function LessonPPTPage.HideBrowser()
    if LessonPPTPage.IsNPLBrowserVisible() then
        page:CallMethod("nplbrowser_pptpage","SetVisible",false)
        page:CallMethod("nplbrowser_pptpage","Reload", NplBrowserPlugin.about_blank_url);
    end
end

function LessonPPTPage.RefreshUI()
    if page then
        page:Refresh(0)
    end
end

function LessonPPTPage.IsNPLBrowserVisible()
    return LessonPPTPage.GetCurDataType() == "videos"
end

local function strings_split(str, sep) 
    local list = {}
    local str = str .. sep
    for word in string.gmatch(str, '([^' .. sep .. ']*)' .. sep) do
        list[#list+1] = word
    end
    return list
end

function LessonPPTPage.updatePPTData(data)
    if(type(data) == "string" and data~= "") then
        local results = strings_split(data,"\n");
        local index = 1
        local pptDt = {}
        for i=1,#results  do
            results[i] = StringUtil.trim(results[i])
        end
        
        for i=1,#results  do
            local str =results[i]
            if(string.find(str,"downloadUrl: ")) then
                pptDt[index] = {}
                pptDt[index].downloadUrl = str:gsub("downloadUrl: ",""):gsub("'","")
                index = index + 1
            end
        end
        index = 1
        for i=1,#results  do
            local str =results[i]
            if(string.find(str,"type: ")) then
                pptDt[index].type = string.gsub(str,"type: ","")
                index = index + 1
            end
        end
        
        index = 1
        for i=1,#results  do
            local str =results[i]
            if(string.find(str,"filename: ")) then
                pptDt[index].filename = string.gsub(str,"filename: ","")
                index = index + 1
            end
        end
        return pptDt
    end
end


function LessonPPTPage.GetPPTData(url,tokenRequired,callback)
    GameLogic.AddBBS(nil,"正在获取远程ppt数据")
    pptIndex = 1
    local eTag = nil
    local input = {
        url = url or ppt_url,
        headers = {
            ["If-None-Match"] = eTag
        }
    }
    if tokenRequired then
        local token = commonlib.getfield("System.User.keepworktoken")
        input.headers["Authorization"] = string.format("Bearer %s",token or "");
        input.json=true
        input.method="GET"
    end
    System.os.GetUrl(input, function(err, msg, data)
        print("err============",err)
        if err==200 then
            -- echo(data,true)
            pptData = LessonPPTPage.updatePPTData(data)
            if pptData and #pptData > 0 then
                LessonPPTPage.PreDownFile(callback)
                
            end
        else
            GameLogic.AddBBS(nil,"获取远程ppt数据异常")
        end
    end)
end

function LessonPPTPage.GetPPTDataByFile(ppt_file,callback)
    pptIndex = 1
    local filepath = GameLogic.GetWorldDirectory()..((ppt_file and ppt_file ~= "") and ppt_file or ppt_file_path)
    local file = ParaIO.open(filepath, "r");
    local strContent
    if(file and file:IsValid()) then
        strContent = file:GetText(0,-1)
    end
    if(strContent and strContent ~= "") then
        pptData = LessonPPTPage.updatePPTData(strContent)
        if pptData and #pptData > 0 then
            LessonPPTPage.PreDownFile(callback)
        end
        return true
    end
    return false
end

function LessonPPTPage.GetCurDataType()
    local curData = pptData and pptData[pptIndex] or nil
    return curData and curData.type
end

function LessonPPTPage.GetDataUrl()
    local curData = pptData and pptData[pptIndex] or nil
    local bLocal,filepath = LessonPPTPage.CheckUserLocalPicture(curData)
    if bLocal then
        return filepath
    end
    return curData and curData.downloadUrl
end

function LessonPPTPage.CheckUserLocalPicture(data)
    if data then
        local filename = data.filename or ""
        local filepath = cachePath.."pic/"..commonlib.Encoding.Utf8ToDefault(filename)
        if ParaIO.DoesFileExist(filepath) then
            -- print("locval================",filepath)
            return true,filepath
        end
    end
    return false
end

function LessonPPTPage.DownLoadFile()
    local curData = pptData and pptData[pptIndex] or nil
    if not curData or curData.type ~= "images" then
        return 
    end
    local filename = curData.filename or ""
    local filepath = cachePath.."pic/"..commonlib.Encoding.Utf8ToDefault(filename)
    if ParaIO.DoesFileExist(filepath) then
        return 
    end
    local url = curData.downloadUrl or ""
    local filename = curData.filename or ""
    local input = {
        url = url,
    }
    System.os.GetUrl(input, function(err, msg, data)
        if err == 200  then
            local filename = commonlib.Encoding.Utf8ToDefault(filename) 
            local filepath = cachePath.."pic/"..filename
            if not ParaIO.DoesFileExist(filepath) and data and #data > 0 then
                ParaIO.CreateDirectory(filepath)
                local file = ParaIO.open(filepath, "wb");
                if(file:IsValid()) then
                    file:WriteString(data,#data);
                    file:close();
                end
            end
        else
            print("err===",err,url,filepath)
        end
    end)
end

function LessonPPTPage.PreLoadTexture()
    NPL.load("(gl)script/ide/AssetPreloader.lua");
    local loader = commonlib.AssetPreloader:new({
        callbackFunc = function(nItemsLeft, loader)
            --loader:Stop()
            --tip("电影图片加载中"..nItemsLeft)
        end
    });
    local num = #pptData
    for i=1,num do
        local curData = pptData and pptData[i] or nil
        if curData and curData.type == "images" then
            local filename = curData.filename or ""
            local filepath = cachePath.."pic/"..commonlib.Encoding.Utf8ToDefault(filename)
            local ext = ParaIO.GetFileExtension(filename);
            if string.lower(ext) == "jpg" or string.lower(ext) == "png" then
                loader:AddAssets(ParaAsset.LoadTexture("", filepath, 1));
            end
        end
    end
    loader:Start();
end

function LessonPPTPage.PreDownFile(callback)
    local downIndex = 1
    if pptData and #pptData > 0 then
        downFile = function (index)
            if index > #pptData then
                GameLogic.AddBBS(nil,L"资源下载完成,正在加载资源,请等待片刻")
                if callback then
                    callback()
                end
                return 
            end
            print("down index==========",index)
            if downIndex == 3 then
                
            end
            local curData = pptData and pptData[downIndex] or nil
            if not curData or curData.type ~= "images" then
                downIndex = downIndex + 1
                downFile(downIndex)
                return 
            end
            local filename = curData.filename or ""
            local filepath = cachePath.."pic/"..commonlib.Encoding.Utf8ToDefault(filename)
            if ParaIO.DoesFileExist(filepath) then
                downIndex = downIndex + 1
                downFile(downIndex)
                return 
            end
            local url = curData.downloadUrl or ""
            local filename = curData.filename or ""
            local input = {
                url = url,
            }
            System.os.GetUrl(input, function(err, msg, data)
                if err == 200  then
                    local filename = commonlib.Encoding.Utf8ToDefault(filename) 
                    local filepath = cachePath.."pic/"..filename
                    if data and #data > 0 then
                        ParaIO.CreateDirectory(filepath)
                        local file = ParaIO.open(filepath, "wb");
                        if(file:IsValid()) then
                            file:WriteString(data,#data);
                        end
                    end
                    downIndex = downIndex + 1
                    downFile(downIndex)
                else
                    print("err===",err,url,filepath)
                    downIndex = downIndex + 1
                    downFile(downIndex)
                end
            end)
        end
        downFile(downIndex)
    end
end