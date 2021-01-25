--[[
Title: keepwork
Author(s): wxa
Date: 2020/12/22
Desc: 后端数据语义化
Use Lib: 
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local Keepwork = NPL.export();

-- 获取用户信息
function Keepwork:GetUserInfo()
    return KeepWorkItemManager.GetProfile();
end

-- 是否首次登录
function Keepwork:IsFirstLoginParacraft()
    local bExist = KeepWorkItemManager.HasGSItem(37);
    return not bExist;
end

-- 获取所有玩家模型
function Keepwork:GetAllAssets()
    local bagId, bagNo = 0, 1007;
    local assets = {}; 
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            bagId = bag.id;
            break;
        end
    end

    for _, tpl in ipairs(KeepWorkItemManager.globalstore) do
        -- echo(tpl, true)
        if (tpl.bagId == bagId) then
            table.insert(assets, {
                id = tpl.id,
                gsId = tpl.gsId,
                modelUrl = tpl.modelUrl,
                name = tpl.name,
            });
        end
    end

    return assets;
end

-- 首次登录回调
function Keepwork:FirstLoginCallback()
    local userinfo = self:GetUserInfo();
    userinfo.extra = userinfo.extra or {};
    userinfo.extra.ParacraftPlayerEntityInfo = userinfo.extra.ParacraftPlayerEntityInfo or {};
    userinfo.extra.ParacraftPlayerEntityInfo.asset = userinfo.extra.ParacraftPlayerEntityInfo.asset or "character/CC/02human/paperman/boy01.x";
    -- 本地化主角模型 
    GameLogic.options:SetMainPlayerAssetName(userinfo.extra.ParacraftPlayerEntityInfo.asset);    
    -- 将默认模型提交至服务器
    keepwork.user.setinfo({
        router_params = {id = userinfo.id},
        extra = userinfo.extra,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then 
            LOG.std(nil, "error", "Keepwork", "更新玩家信息失败");
        end
    end);
end

function Keepwork:CheckUserQRCode()
    local userinfo = self:GetUserInfo();
    local wxacodes = userinfo.wxacodes or {};
    userinfo.wxacodes = wxacodes;
    local qrcodes = {BB = "", FY = ""};
    userinfo.qrcodes = qrcodes;

    local function download(qrcode, url)
        local realfilename = string.format("temp/qrcodes/%s.jpg", qrcode);
        local filename = string.format("temp/qrcodes/%s_%s.jpg", userinfo.id, qrcode)
        local file = ParaIO.open(filename, "r");
        if (file:IsValid()) then
            file:close();
            ParaIO.CopyFile(filename, realfilename, true);
        else
            local downloader = FileDownloader:new();
            downloader:SetSilent();
            downloader:Init(nil,  url, filename, function()
                ParaIO.CopyFile(filename, realfilename, true);
            end, "access plus 0");
        end
    end

    for qrcode, _ in pairs(qrcodes) do
        local exist = false;
        for _, wxacode in ipairs(wxacodes) do
            if (qrcode == wxacode.situation) then
                exist = true;
                qrcodes[qrcode] = wxacode.wxacode;
                break;
            end
        end
        if (not exist) then
            keepwork.user.bindWxacode({
                situation = qrcode
            }, function(err, msg, data)

                if (err == 200) then
                    qrcodes[qrcode] = data.wxacode;
                    download(qrcode, qrcodes[qrcode]);
                end
            end);
        else
            download(qrcode, qrcodes[qrcode]);
        end
    end
end

-- 用户登录成功
function Keepwork:OnLogin()
    self.isLogin = true;

    if (self:IsFirstLoginParacraft()) then
        self:FirstLoginCallback();
    end

    self:CheckUserQRCode();
end

-- 用户退出
function Keepwork:OnLogout()
    self.isLogin = false;
end

-- 是否登录
function Keepwork:IsLogin()
    return self.isLogin;
end