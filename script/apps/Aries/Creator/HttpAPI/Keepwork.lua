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
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
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

    local userinfo = self:GetUserInfo();
    LOG.std(nil, 'info', 'GetUserInfo', userinfo);
    userinfo.extra = userinfo.extra or {};
    userinfo.extra.ParacraftPlayerEntityInfo = userinfo.extra.ParacraftPlayerEntityInfo or {};
    local old_skin = userinfo.extra.ParacraftPlayerEntityInfo.skin or "";
    self:SetUserSkin(self:GetUserSkin());
    local new_skin = self:GetUserSkin() or "";
    LOG.std(nil, 'info', 'new_skin', self:GetUserSkin());
    
    if (old_skin ~= new_skin and new_skin == "" and userinfo.extra.ParacraftPlayerEntityInfo.asset == CustomCharItems.defaultModelFile) then  
        userinfo.extra.ParacraftPlayerEntityInfo.asset = "character/CC/02human/paperman/boy01.x" 
    end 
    
    GameLogic.options:SetMainPlayerAssetName(userinfo.extra.ParacraftPlayerEntityInfo.asset);  
    GameLogic.options:SetMainPlayerSkins(userinfo.extra.ParacraftPlayerEntityInfo.skin or "");  

    local player = EntityManager.GetPlayer();
    if (player) then 
        player:SetSkin(userinfo.extra.ParacraftPlayerEntityInfo.skin);
        player:SetMainAssetPath(userinfo.extra.ParacraftPlayerEntityInfo.asset);
    end

    if (old_skin ~= new_skin) then
        keepwork.user.setinfo({
            router_params = {id = userinfo.id},
            extra = userinfo.extra,
        }, function(status, msg, data) 
            if (status < 200 or status >= 300) then 
                LOG.std(nil, "error", "Keepwork", "更新玩家信息失败");
            end
        end);
    end
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

function Keepwork:IsExperienceVipCloth()
    for k,v in ipairs(KeepWorkItemManager.items) do
        if(11000 < v.gsId and v.gsId <= 11999) then
            local tpl = KeepWorkItemManager.GetItemTemplate(v.gsId);
            if ((v.copies or 0) > 0 and tpl and (tpl.extra or {}).VIP_cloth_7days) then return true end 
        end    
    end
    return false;
end

function Keepwork:IsVip()
    return self:GetUserInfo().vip == 1;
end

function Keepwork:GetUserSkin()
    return self:GetUserInfo().extra.ParacraftPlayerEntityInfo.skin;
end

function Keepwork:SetUserSkin(skin)
    local userinfo = self:GetUserInfo();
    userinfo.extra.ParacraftPlayerEntityInfo.skin = skin;
end

-- 对后端数据源的skin再做一层vip逻辑处理，VIP逻辑会有变动，这个方法弃用掉
function Keepwork:CheckSkin(skin)
    LOG.std(nil, 'info', 'Keepwork:CheckSkin:Input:Skin', skin);

    skin = skin or self:GetUserSkin();
    if (not skin) then return skin end
    local itemIds = commonlib.split(skin, ";");
    if (not itemIds or #itemIds == 0) then return skin end
    local isVip = self:IsExperienceVipCloth() or self:IsVip();

    CustomCharItems:Init();

    for _, id in ipairs(itemIds) do
        local data = CustomCharItems:GetItemById(id);
        local isOwned = true;
        if (data) then
            if (isVip) then 
                if (data.gsid and not KeepWorkItemManager.HasGSItem(data.gsid)) then isOwned = false end
            else
                if (not data.gsid or (data.gsid and not KeepWorkItemManager.HasGSItem(data.gsid))) then isOwned = false end 
            end

            if (not isOwned) then skin = CustomCharItems:RemoveItemInSkin(skin, id) end
        end
    end

    LOG.std(nil, 'info', 'Keepwork:CheckSkin:Return:Skin', skin);
    return skin;
end


function Keepwork:GetUserName()
    return self:GetUserInfo().username;
end

function Keepwork:GetNickName()
    return self:GetUserInfo().nickname;
end

local Grades = {"一年级", "二年级", "三年级", "四年级", "五年级", "六年级", "七年级", "八年级", "九年级", "高一", "高二", "高三", "往届学生", "教师"};
function Keepwork:GetGradeClassName()
    local class = self:GetUserInfo().class;
    if (not class or not class.grade) then return "" end 
    local gradeNo = tonumber(class.grade);
    gradeNo = math.max(gradeNo, 1);
    gradeNo = math.min(#Grades, gradeNo);
    return Grades[gradeNo] .. (class.classNo and (class.classNo .. "班" or ""));
end

function Keepwork:GetCurrentWorldID()
    return GameLogic.options:GetProjectId();
end

function Keepwork:GetCurrentWorldName()
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
    return WorldCommon.GetWorldTag("name");
end
