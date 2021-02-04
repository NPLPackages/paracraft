--[[
Title: VersionNotice
Author(s):  big
Date: 2020.01.14
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")
VipToolNew.Show()
------------------------------------------------------------
]]
-- service

local QREncode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
local Encoding = commonlib.gettable("System.Encoding");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local VipToolNew = NPL.export()
VipToolNew.orgs_num = 0
VipToolNew.learn_day = 0
VipToolNew.project_num = 0

local page
function VipToolNew.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = VipToolNew.OnCreate
end

function VipToolNew.Show(from)
    VipToolNew.from = from or "main_icon"
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        return
    end
    local username = commonlib.getfield("System.User.username")
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
    keepwork.user.getinfo({
        cache_policy = System.localserver.CachePolicy:new("access plus 1 hour"),
        router_params = {
            id = id,
        }
    },function(err, msg, data)
        if err == 200 then
            local create_time_stamp = commonlib.timehelp.GetTimeStampByDateTime(data.createdAt)
            local create_time_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(create_time_stamp)
            local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(os.time())

            VipToolNew.learn_day = math.floor((os.time() - create_time_stamp) / (24*3600))
            VipToolNew.learn_day = VipToolNew.learn_day == 0 and 1 or VipToolNew.learn_day
            VipToolNew.project_num = data.rank and data.rank.project or 0
            keepwork.user.total_orgs({}, function(err, message, data)
                if err == 200 then
                    VipToolNew.orgs_num = data.data.count or 0
                    VipToolNew.ShowPage()
                end
            end)
        end
    end)
end

function VipToolNew.ShowPage()  
    VipToolNew.InitData()

    local view_width = 746
	local view_height = 530
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.html",
        name = "VipToolNew.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
            align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.vip_popup')
    
end

function VipToolNew.OnCreate()
    local parent  = page:GetParentUIObject()
    local qrcode_width = 140
    local qrcode_height = 140
    local block_size = qrcode_width / #VipToolNew.qrcode

    local qrcode = ParaUI.CreateUIObject("container", "qrcode", "_lt", 553, 147, qrcode_width, qrcode_height);
    qrcode:SetField("OwnerDraw", true); -- enable owner draw paint event
    qrcode:SetField("SelfPaint", true);
    qrcode:SetScript("ondraw", function(test)
        for i = 1, #(VipToolNew.qrcode) do
            for j = 1, #(VipToolNew.qrcode[i]) do
                local code = VipToolNew.qrcode[i][j];
                if (code < 0) then
                    ParaPainter.SetPen("#000000ff");
                    ParaPainter.DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
                end
            end
        end
        
    end);

    parent:AddChild(qrcode);
end

function VipToolNew.InitData()
    local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
    local qrcode = string.format("%s/p/qr/purchase?userId=%s&from=%s",KeepworkService:GetKeepworkUrl(), Mod.WorldShare.Store:Get('user/userId'), VipToolNew.from);
    local ret;
    ret, VipToolNew.qrcode = QREncode.qrcode(qrcode)
end

function VipToolNew.GetDesc1()
    return string.format("%s所学校、机构正在使用帕拉卡学习！", VipToolNew.orgs_num)
end

function VipToolNew.GetDesc2()
    local nickname = KeepWorkItemManager.GetProfile().nickname or ""
    return string.format('<div style="color: #ffff00;float: left;">%s</div>已学习了<div style="color: #ffff00;float: left;">%s</div>天动画编程，拥有<div style="color: #ffff00;float: left;">%s</div>部作品', nickname, VipToolNew.learn_day, VipToolNew.project_num)
end