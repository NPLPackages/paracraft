--[[
Title: keepwork
Author(s): wxa
Date: 2020/12/22
Desc: 后端数据语义化
Use Lib: 
-------------------------------------------------------
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");


HttpWrapper.Create("keepwork.school.region", "%MAIN%/core/v0/regions/:id", "GET", true);

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
        if (tpl.bagId == bagId and tpl.modelUrl) then
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

    self:Reset();  -- 重置数据

    if (self:IsFirstLoginParacraft()) then
        self:FirstLoginCallback();
    end

    self:CheckUserQRCode();
    -- self:IsPrefectUserInfo();
end

-- 用户退出
function Keepwork:OnLogout()
    self.isLogin = false;
end

-- 是否登录
function Keepwork:IsLogin()
    return self.isLogin;
end

-- 重置数据
function Keepwork:Reset()
    self.isExitPrefectUserInfoItem = false;
    self.isPrefectUserInfo = false;
end

-- 是否领取完善信息奖励
function Keepwork:IsExitPrefectUserInfoItem()
    if (self.isExitPrefectUserInfoItem) then return true end 
    self.isExitPrefectUserInfoItem = KeepWorkItemManager.HasGSItem(60054);
    return self.isExitPrefectUserInfoItem;
end

-- 用户信息是否完善
function Keepwork:IsPrefectUserInfo()
    if (self.isPrefectUserInfo or self.isExitPrefectUserInfoItem) then return true end

    local userinfo = self:GetUserInfo();
    if (not userinfo.schoolId or userinfo.schoolId == 0) then return false end
    if (not userinfo.sex or userinfo.sex == "") then return false end
    if (not userinfo.region or userinfo.region.hasChildren ~= 0) then return false end
    local info = userinfo.info or {};
    if (not info.name or info.name == "") then return false end
    if (not info.mailName or info.mailName == "") then return false end
    if (not info.mailAddress or info.mailAddress == "") then return false end
    if (not info.mailPhone or tostring(info.mailPhone) == "") then return false end
    if (not info.mailRegion or info.mailRegion.hasChildren ~= 0) then return false end

    GameLogic.QuestAction.AchieveTask("40051_60054_1", 1, true);  -- 标记任务完成

    self.isExitPrefectUserInfoItem = true;
    self.isPrefectUserInfo = true;
    return true;
end

function Keepwork:GetSchoolRegionId(callback)
    keepwork.school.region({
        router_params = {
            id = (self:GetUserInfo().school or {}).regionId or 1,
        }
    }, function(err, msg, data)
        if (type(callback) == "function") then
            callback(data and data.info and data.info.state and data.info.state.id);
        end
    end)
end