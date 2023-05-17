--[[
Title: SwitchTo430ChannelPage.html code-behind script
Author(s): LiPeng, LiXizhi
Date: 2014/4/1
Desc: select the default global modules for the game, and the modules for every world.
Simply put plugin zip file or mod folder to ./Mod folder. 
The plugin zip file must contain a file called "Mod/[plugin_name]/main.lua" 
in order to be considered as a valid plugin zip file. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/SwitchTo430ChannelPage.lua");
local SwitchTo430ChannelPage = commonlib.gettable("MyCompany.Aries.Game.MainLogin.SwitchTo430ChannelPage")
SwitchTo430ChannelPage.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
NPL.load("(gl)script/ide/System/Encoding/crc32.lua");
local Encoding = commonlib.gettable("System.Encoding");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local SwitchTo430ChannelPage = commonlib.gettable("MyCompany.Aries.Game.MainLogin.SwitchTo430ChannelPage")

local launcherExeName = System.options.launcherExeName or "ParaCraft.exe"

SwitchTo430ChannelPage.page = nil;

function SwitchTo430ChannelPage.OnInit()
	SwitchTo430ChannelPage.page = document:GetPageCtrl();
end

-- show page
function SwitchTo430ChannelPage.ShowPage(callback)
    SwitchTo430ChannelPage.callback = callback
	local params = {
        url = "script/apps/Aries/Creator/Game/Login/SwitchTo430ChannelPage.html", 
        name = "SwitchTo430ChannelPage", 
        isShowTitleBar = false,
        enable_esc_key = true,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 0,
        allowDrag = false,
        isTopLevel = true,
        
        directPosition = true,
            align = "_ct",
            x = -488/2,
            y = -310/2,
            width = 488,
            height = 310,
        cancelShowAnimation = true,
    };
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	
end

function SwitchTo430ChannelPage.MakeRepairBat()
    local filename = ParaIO.GetWritablePath().."repair.bat"
    local file = ParaIO.open(filename, "w")
    if(file:IsValid()) then
        local str = [[
            start %s isFixMode=true
        ]]
        str = string.format(str,launcherExeName)
        file:WriteString(str);
        file:close();
    end
end

function SwitchTo430ChannelPage:download430launcher(callback)
    local launchanerUrl = string.format("https://cdn.keepwork.com/paracraft/win32/%s",launcherExeName);
    print("launchanerUrl",launchanerUrl)
    local fileDownloader = FileDownloader:new();
    fileDownloader.isSilent = true;

    GameLogic.GetFilters():apply_filters("cellar.common.msg_box.show", L"正在下载校园版启动器...", 120000, nil, 350);

    local exeFile = ParaIO.GetWritablePath()..launcherExeName ;
    local exeFilebak = ParaIO.GetWritablePath()..string.format("temp/%s.bak",launcherExeName);
    local exeFileTmp = ParaIO.GetWritablePath()..string.format("%s.tmp",launcherExeName);
    ParaIO.DeleteFile(exeFileTmp)
    commonlib.TimerManager.SetTimeout(function()
        fileDownloader:Init(nil, launchanerUrl, exeFileTmp, function(result)
            if (result) then
                fileDownloader:DeleteCacheFile();

                ParaIO.CopyFile(exeFile,exeFilebak,true)
                local bool = ParaIO.MoveFile(exeFileTmp,exeFile)

                GameLogic.GetFilters():apply_filters("cellar.common.msg_box.close");

                if (callback and type(callback) == "function") then
                    callback(bool);
                end
            else
                callback(false);
                GameLogic.GetFilters():apply_filters("cellar.common.msg_box.close");
            end
        end)
    end, 500);
    
end

function SwitchTo430ChannelPage.WriteConfigTxt()
    local filename = ParaIO.GetWritablePath().."config.txt"

    local str = ""
    local oldText = CommonLib.GetFileText(filename)
    if oldText then
        local tab = commonlib.split(oldText,"\r\n")
        if tab and #tab>0 then
            for i=1,#tab do
                local v = tab[i]
                if string.match(v,"cmdline") then
                    v = string.gsub(v,"channelId","channelId_xx")
                    tab[i] = v..' channelId="430"'
                end
            end
            str = table.concat(tab,"\r\n")
            print("==========old config:",oldText)
            print("==========new config:",str)
        end
    else
        str = string.format([[cmdline=noupdate="true" debug="main" mc="true" bootstrapper="script/apps/Aries/main_loop.lua" channelId="430"]])
    end

    local file = ParaIO.open(filename, "w")
    if(file:IsValid()) then
        file:WriteString(str);
        file:close();
    end

--     local config_dir = ParaIO.GetWritablePath().."config/"
--     filename = config_dir..string.format("channel_option_%s.ini",430)
--     local file = ParaIO.open(filename, "w")
--     if(file:IsValid()) then
--         local str = string.format([[
-- -- channel options for 430.

-- world_enter_cmds = /shader 1;/renderdist 32; /lod on; /property -scene MaxCharTriangles 50000;
-- enable_npl_brower = false
-- is_resolution_locked = true
-- IgnoreWindowSizeChange = true
-- LockWindowSize = true
-- FPS = 30
--         ]])
--         file:WriteString(str);
--         file:close();

        -- System.options.InitChannelOptions(true)
    -- end
end

function SwitchTo430ChannelPage.OnBtnSwitch()
    SwitchTo430ChannelPage:download430launcher(function(success)
        if success then
            System.options.channelId = "430"
            System.options.isChannel_430 = (System.options.channelId=="430")
            if System.options.isChannel_430 then
                System.options.isHideVip = true;
            end
            SwitchTo430ChannelPage.WriteConfigTxt()
            SwitchTo430ChannelPage.MakeRepairBat()
            GameLogic.AddBBS(nil,L"已经切换到校园版")
            if SwitchTo430ChannelPage.callback then
                SwitchTo430ChannelPage.callback()
            end
        else
            GameLogic.AddBBS(nil,L"切换失败")
            if SwitchTo430ChannelPage.callback then
                SwitchTo430ChannelPage.callback()
            end
        end
    end)
end