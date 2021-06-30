--[[
Title: WorldKeyEncodePage
Author(s): yangguiyi
Date: 2021/4/28
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyEncodePage.lua").Show();
--]]
local WorldKeyEncodePage = NPL.export();
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local WorldKeyManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyManager.lua")
local page

WorldKeyEncodePage.DefaultData = {
    encode_nums_text = 100,
    txt_file_name = "激活码",
}

function WorldKeyEncodePage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = WorldKeyEncodePage.CloseView
end

function WorldKeyEncodePage.Show(projectId)
    WorldKeyEncodePage.projectId = projectId or GameLogic.options:GetProjectId()
    local projectId = WorldKeyEncodePage.projectId
    KeepworkServiceProject:GetProject(projectId, function(data, err)

        if type(data) == 'table' then
            if WorldKeyEncodePage.DefaultData.txt_file_path == nil then
                WorldKeyEncodePage.DefaultData.txt_file_path = string.gsub(ParaIO.GetWritablePath().."temp/Key", "/", "\\")
            end

            WorldKeyEncodePage.world_data = data
            WorldKeyEncodePage.ShowView()
        end
    end)
    
end

function WorldKeyEncodePage.ShowView()
    if page and page:IsVisible() then
        return
    end
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyEncodePage.html",
        name = "WorldKeyEncodePage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -510/2,
        y = -384/2,
        width = 510,
        height = 384,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    WorldKeyEncodePage.InitView()
end

function WorldKeyEncodePage.FreshView()
    local parent  = page:GetParentUIObject()
end

function WorldKeyEncodePage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    WorldKeyEncodePage.FreshView()
end

function WorldKeyEncodePage.CloseView()
    WorldKeyEncodePage.ClearData()
end

function WorldKeyEncodePage.ClearData()
end

function WorldKeyEncodePage.InitView()
    local params = WorldKeyEncodePage.world_data or {}
    local extra = params.extra or {}
    local world_encodekey_data = extra.world_encodekey_data or {}
    
    local buy_link_text = world_encodekey_data.buy_link_text
    if buy_link_text then
        page:SetValue("buy_link_text", buy_link_text)
    end

    local title_text = world_encodekey_data.title_text or ""
    page:SetValue("title_text", title_text)

    local projectId = params.id
    local encode_world_data = GameLogic.GetPlayerController():LoadRemoteData("WorldKeyEncodePage.encode_world_data" .. projectId) or {};

    local encode_nums_text = encode_world_data.encode_nums_text or WorldKeyEncodePage.DefaultData.encode_nums_text
    WorldKeyEncodePage.last_encode_nums = encode_nums_text
    page:SetValue("encode_nums_text", encode_nums_text)

    local txt_file_name = encode_world_data.txt_file_name or WorldKeyEncodePage.DefaultData.txt_file_name
    page:SetValue("txt_file_name", txt_file_name)

    local txt_file_path = encode_world_data.txt_file_path or WorldKeyEncodePage.DefaultData.txt_file_path
    txt_file_path = commonlib.Encoding.DefaultToUtf8(txt_file_path)
    page:SetValue("txt_file_path", txt_file_path)
end

function WorldKeyEncodePage.EncodeKey()
    if GameLogic.IsReadOnly() then
        return
    end

    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        GameLogic.AddBBS(nil, L"请先登录", 3000, "255 0 0")
        return
    end

    if not GameLogic.IsVip() then
        local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")
        VipToolNew.Show("worldkey_encode")
        return
    end

    local buy_link_text = page:GetValue("buy_link_text");
    if not buy_link_text or buy_link_text == "" then
        GameLogic.AddBBS(nil, L"请输入激活码淘宝购买链接", 3000, "255 0 0")
        return
    end

    local title_text = page:GetValue("title_text") or ""
    if not title_text or title_text == "" then
        GameLogic.AddBBS(nil, L"请输入标题", 3000, "255 0 0")
        return
    end

    local encode_nums_text = page:GetValue("encode_nums_text");
    encode_nums_text = tonumber(encode_nums_text)
    if not encode_nums_text then
        GameLogic.AddBBS(nil, L"请输入生成数量", 3000, "255 0 0")
        return
    end

    if encode_nums_text > 10000 then
        GameLogic.AddBBS(nil, L"一次生成数量不能超过10000", 3000, "255 0 0")
        return
    end

    local float_num = encode_nums_text - math.floor(encode_nums_text)
    if float_num > 0 then
        GameLogic.AddBBS(nil, L"请输入正确数字", 3000, "255 0 0")
        return
    end

    local txt_file_name = page:GetValue("txt_file_name");
    if not txt_file_name then
        GameLogic.AddBBS(nil, L"请输入生成文件名", 3000, "255 0 0")
        return
    end

    local txt_file_path = page:GetValue("txt_file_path");
    if txt_file_path == "" then
        GameLogic.AddBBS(nil, L"请输入生成文件的存放路径", 3000, "255 0 0")
        return
    end

    txt_file_path = commonlib.Encoding.Utf8ToDefault(txt_file_path)
    if txt_file_path ~= WorldKeyEncodePage.DefaultData.txt_file_path and not ParaIO.DoesFileExist(txt_file_path) then
        GameLogic.AddBBS(nil, L"目标文件夹不存在", 3000, "255 0 0")
        return
    end

    

    local params = {
        extra = {
            world_encodekey_data = {}
        }
    }

    local params = WorldKeyEncodePage.world_data or {}
    local extra = params.extra or {}
    params.extra = extra

    local world_encodekey_data = params.extra.world_encodekey_data or {}
    extra.world_encodekey_data = world_encodekey_data

    world_encodekey_data.buy_link_text = buy_link_text
    world_encodekey_data.title_text = title_text


    -- world_encodekey_data.encode_nums_text = encode_nums_text
    -- world_encodekey_data.txt_file_name = txt_file_name
    -- world_encodekey_data.txt_file_path = txt_file_path
    
    local projectId = WorldKeyEncodePage.projectId
    KeepworkServiceProject:UpdateProject(projectId, params, function(data, err)
        if err == 200 then
            local data = {}
            data.encode_nums_text = encode_nums_text
            data.txt_file_name = txt_file_name
            data.txt_file_path = txt_file_path
            GameLogic.GetPlayerController():SaveRemoteData("WorldKeyEncodePage.encode_world_data" .. projectId, data);

            WorldKeyManager.GenerateActivationCodes(encode_nums_text, System.User.username, projectId, txt_file_name, txt_file_path, function(path)
                -- local desc = string.format("激活码生成成功，是否打开%s.txt文件", txt_file_name)
                local desc = "激活码生成成功，是否打开生成文件夹"
                _guihelper.MessageBox(desc, function(res)
                    if(res == _guihelper.DialogResult.OK) then
                        ParaGlobal.ShellExecute("open", "explorer.exe", txt_file_path, "", 1)
                    end
                end, _guihelper.MessageBoxButtons.OKCancel_CustomLabel,nil,nil,nil,nil,{ ok = L"是", cancel = L"否", title = L"生成激活码", });
            end)
            -- GameLogic.AddBBS(nil, L"设置成功", 3000, "0 255 0")
        end
    end)
end

function WorldKeyEncodePage.SelectFilePath()
    -- local txt_file_path = page:GetValue("txt_file_path");


	NPL.load("(gl)script/ide/OpenFileDialog.lua");
	local filename = CommonCtrl.OpenFileDialog.ShowOpenFolder_Win32()
    
    print("daaaaaaaaaaa", filename, filename ~= WorldKeyEncodePage.DefaultData.txt_file_path and not ParaIO.DoesFileExist(filename))
    if filename ~= WorldKeyEncodePage.DefaultData.txt_file_path and not ParaIO.DoesFileExist(filename) then
        filename = WorldKeyEncodePage.DefaultData.txt_file_path
    end
    filename = commonlib.Encoding.DefaultToUtf8(filename)
    page:SetValue("txt_file_path", filename)
end

function WorldKeyEncodePage.OpenFilePath()
    local txt_file_path = page:GetValue("txt_file_path");
    txt_file_path = commonlib.Encoding.Utf8ToDefault(txt_file_path)
    if txt_file_path == "" or not ParaIO.DoesFileExist(txt_file_path) then
        return
    end

    ParaGlobal.ShellExecute("open", "explorer.exe", txt_file_path, "", 1)
end

function WorldKeyEncodePage.WriteOut()
    local InvalidKeyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/InvalidKeyPage.lua");
    InvalidKeyPage.Show(WorldKeyEncodePage.world_data);
end

function WorldKeyEncodePage.OnEncodeNumChange()
    local encode_nums_text = page:GetValue("encode_nums_text");
    if encode_nums_text == "" then
        return
    end
    local encode_nums_text = tonumber(encode_nums_text)

    local last_num = WorldKeyEncodePage.last_encode_nums or WorldKeyEncodePage.DefaultData.encode_nums_text
    if not encode_nums_text then
        page:SetValue("encode_nums_text", last_num);
        local root = ParaUI.GetUIObject("ui_encode_nums_text");
        root:LostFocus()
        return
    end

    local float_num = encode_nums_text - math.floor(encode_nums_text)
    if float_num > 0 then
        page:SetValue("encode_nums_text", last_num);
        local root = ParaUI.GetUIObject("ui_encode_nums_text");
        root:LostFocus()
        return
    end

    WorldKeyEncodePage.last_encode_nums = encode_nums_text
end