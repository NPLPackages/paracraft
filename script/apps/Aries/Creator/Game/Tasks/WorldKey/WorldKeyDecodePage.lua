--[[
Title: WorldKeyDecodePage
Author(s): yangguiyi
Date: 2021/4/28
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyDecodePage.lua").Show();
--]]
local WorldKeyManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyManager.lua")
local WorldKeyDecodePage = NPL.export();
local QREncode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
local page
function WorldKeyDecodePage.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = WorldKeyDecodePage.OnCreate
    page.OnClose = WorldKeyDecodePage.CloseView
end

function WorldKeyDecodePage.Show(world_data, enter_cb)

    -- 判断是否进入解密过这个世界
    local project_id = world_data.id or 0
    local hasActivate = WorldKeyManager.HasActivate(project_id)
    if hasActivate then
        enter_cb()
        return
    end

    WorldKeyDecodePage.enter_cb = enter_cb
    WorldKeyDecodePage.world_data = world_data
    WorldKeyDecodePage.ShowView()
end

function WorldKeyDecodePage.ShowView()
    if page and page:IsVisible() then
        return
    end
    
    WorldKeyDecodePage.InitData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyDecodePage.html",
        name = "WorldKeyDecodePage.Show", 
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
        y = -345/2,
        width = 510,
        height = 345,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function WorldKeyDecodePage.OnCreate()
    local parent  = ParaUI.GetUIObject("decode_wxcode_root")
    
    local qrcode_width = 100
    local qrcode_height = 100
    local block_size = qrcode_width / #WorldKeyDecodePage.qrcode

    local qrcode = ParaUI.CreateUIObject("container", "qrcode_vip_tool", "_lt", 5, 5, qrcode_width, qrcode_height);
    qrcode:SetField("OwnerDraw", true); -- enable owner draw paint event
    qrcode:SetField("SelfPaint", true);
    qrcode:SetScript("ondraw", function(test)
        for i = 1, #(WorldKeyDecodePage.qrcode) do
            for j = 1, #(WorldKeyDecodePage.qrcode[i]) do
                local code = WorldKeyDecodePage.qrcode[i][j];
                if (code < 0) then
                    ParaPainter.SetPen("#000000ff");
                    ParaPainter.DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
                end
            end
        end
        
    end);

    parent:AddChild(qrcode);

    -- WorldKeyDecodePage.key_remind  = ParaUI.GetUIObject("key_remind")
    -- WorldKeyDecodePage.ShowKeyRemind(false)
end

function WorldKeyDecodePage.ShowKeyRemind(is_show)
    
    WorldKeyDecodePage.key_remind.visible = is_show
end

function WorldKeyDecodePage.InitData()
    local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
	local userid = Mod.WorldShare.Store:Get('user/userId')
    local qrcode;
	if(userid) then
		qrcode = string.format("%s/p/qr/purchase?userId=%s&from=%s",KeepworkService:GetKeepworkUrl(), userid, "worldkey_activate");
	else
		qrcode = string.format("%s/p/qr/buyFor?from=%s",KeepworkService:GetKeepworkUrl(), "worldkey_activate");
	end

    local ret;
    ret, WorldKeyDecodePage.qrcode = QREncode.qrcode(qrcode)

    local params = WorldKeyDecodePage.world_data or {}
    local extra = params.extra or {}
    local world_encodekey_data = extra.world_encodekey_data or {}
    local name = params.username or ""    

    WorldKeyDecodePage.buy_link_text = world_encodekey_data.buy_link_text or ""
    WorldKeyDecodePage.title_text = WorldKeyDecodePage.GetLimitLabel(world_encodekey_data.title_text) or ""
    name = WorldKeyDecodePage.GetLimitLabel(name)
    WorldKeyDecodePage.desc = string.format("*此内容由世界的作者%s提供， 定价和内容均与帕拉卡无关，一个激活码只能被一个用户使用，使用他人的激活码， 会被加入黑名单。", name)
end

function WorldKeyDecodePage.FreshView()
    local parent  = page:GetParentUIObject()
end

function WorldKeyDecodePage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    WorldKeyDecodePage.FreshView()
end

function WorldKeyDecodePage.CloseView()
    WorldKeyDecodePage.ClearData()
end

function WorldKeyDecodePage.ClearData()
end

function WorldKeyDecodePage.Paste()
    local text = ParaMisc.GetTextFromClipboard() or "";
    page:SetValue("key_text", text)
end

function WorldKeyDecodePage.DecodeWorld()
    local code = page:GetValue("key_text") or ""
    if code == "" then
        GameLogic.AddBBS(nil, L"请输入激活码", 3000, "255 0 0")
        return
    end

    local isValidActivationCode = WorldKeyManager.isValidActivationCode(code, WorldKeyDecodePage.world_data)

    if not isValidActivationCode then
        GameLogic.AddBBS(nil, L"激活码无效，请确认你填写的激活码是否正确", 3000, "255 0 0")
        return
    end
    -- WorldKeyDecodePage.ShowKeyRemind(not isValidActivationCode)
    if isValidActivationCode and WorldKeyDecodePage.enter_cb then
        page:CloseWindow(0)
        WorldKeyDecodePage.CloseView()
        WorldKeyDecodePage.enter_cb()
    end
end

function WorldKeyDecodePage.ToBuy()
    if WorldKeyDecodePage.buy_link_text == nil or WorldKeyDecodePage.buy_link_text == "" then
        GameLogic.AddBBS(nil, L"暂无购买链接", 3000, "255 0 0")
        return
    end

    ParaGlobal.ShellExecute("open", WorldKeyDecodePage.buy_link_text, "", "", 1); 
end

function WorldKeyDecodePage.OnTextChange()
end

function WorldKeyDecodePage.GetLimitLabel(text, maxCharCount)
    if text == nil or text == "" then
        return
    end
    maxCharCount = maxCharCount or 18;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end