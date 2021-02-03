--[[
Title: VersionNotice
Author(s):  big
Date: 2020.01.14
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local VipMakeUp = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipMakeUp.lua")
VipMakeUp.Show()
------------------------------------------------------------
]]
-- service

local QREncode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
local Encoding = commonlib.gettable("System.Encoding");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local QuestCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestCoursePage.lua");

local VipMakeUp = NPL.export()
VipMakeUp.orgs_num = 0
VipMakeUp.learn_day = 0
VipMakeUp.project_num = 0

local page
function VipMakeUp.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = VipMakeUp.OnCreate
end

function VipMakeUp.Show(from)
    VipMakeUp.from = from or "main_icon"
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

            VipMakeUp.learn_day = math.floor((os.time() - create_time_stamp) / (24*3600))
            VipMakeUp.learn_day = VipMakeUp.learn_day == 0 and 1 or VipMakeUp.learn_day
            VipMakeUp.project_num = data.rank and data.rank.project or 0
            keepwork.user.total_orgs({}, function(err, message, data)
                if err == 200 then
                    VipMakeUp.orgs_num = data.data.count or 0
                    VipMakeUp.ShowPage()
                end
            end)
        end
    end)
end

function VipMakeUp.ShowPage()  
    VipMakeUp.InitData()

    local view_width = 1020
	local view_height = 603
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipMakeUp.html",
        name = "VipMakeUp.ShowPage", 
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

function VipMakeUp.OnCreate()
    local parent  = page:GetParentUIObject()
    local qrcode_width = 250
    local qrcode_height = 250
    local block_size = qrcode_width / #VipMakeUp.qrcode

    local qrcode = ParaUI.CreateUIObject("container", "qrcode", "_lt", 385, 176, qrcode_width, qrcode_height);
    qrcode:SetField("OwnerDraw", true); -- enable owner draw paint event
    qrcode:SetField("SelfPaint", true);
    qrcode:SetScript("ondraw", function(test)
        for i = 1, #(VipMakeUp.qrcode) do
            for j = 1, #(VipMakeUp.qrcode[i]) do
                local code = VipMakeUp.qrcode[i][j];
                if (code < 0) then
                    ParaPainter.SetPen("#000000ff");
                    ParaPainter.DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
                end
            end
        end
        
    end);

    parent:AddChild(qrcode);
end

function VipMakeUp.InitData()
    local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
    local qrcode = string.format("%s/p/qr/purchase?userId=%s&from=%s",KeepworkService:GetKeepworkUrl(), Mod.WorldShare.Store:Get('user/userId'), "summercamp_cram");
    local ret;
    ret, VipMakeUp.qrcode = QREncode.qrcode(qrcode)
end

function VipMakeUp.MakeUp()
    if System.User.isVip then
        GameLogic.RunCommand(string.format("/goto  %d %d %d", 19258,14,19134));
        QuestCoursePage.Show(true)
        page:CloseWindow()
    else
        _guihelper.MessageBox("您还不是会员，开通会员后即可补课", nil, nil,nil,nil,nil,nil,{ ok = L"确定"});
        _guihelper.MsgBoxClick_CallBack = function(res)
            if(res == _guihelper.DialogResult.OK) then                
            end
        end
    end
end