--[[
    author:pbb
    date:2021/02/04
    Desc:冬令营第一名学校活动
    use lib:
     local MacroCodeCampAward = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampAward.lua");
     MacroCodeCampAward.ShowView()
]]
local QREncode = commonlib.gettable("MyCompany.Aries.Game.Movie.QREncode")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local MacroCodeCampActIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampActIntro.lua");

local MacroCodeCampAward = NPL.export()
local page = nil
function MacroCodeCampAward.OnInit()
    page = document:GetPageCtrl();
end

function MacroCodeCampAward.CheckCanShow()
    -- if not System.options.isDevMode then
    --     return false
    -- end
--    local school = KeepWorkItemManager.GetSchool()
--    if (string.find(name, "柴桑小学") and string.find(name, "柴桑小学") > 0) or school.id == 133053 then
--        return true
--    end
    return false
end

function MacroCodeCampAward.ShowView()
    if not MacroCodeCampAward.CheckCanShow() then
        LOG.std(nil, "debug", "MacroCodeCampAward", "不是柴桑小学的学生");
        return 
    end
    local view_width = 780
    local view_height = 512
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampAward.html",
        name = "MacroCodeCampAward.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 4,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    MacroCodeCampAward.InitQRCode()
end

function MacroCodeCampAward.GetQRCodeUrl()
    local urlbase = GameLogic.GetFilters():apply_filters("get_keepwork_url");
	local uerid = GameLogic.GetFilters():apply_filters("store_get",'user/userId');
    local url = string.format("%s/p/qr/vipDouble?userId=%s&from=%s",urlbase, uerid, "chaisang");
    return url
end

function MacroCodeCampAward.InitQRCode()
    local parent  = page:GetParentUIObject()
    local qrcode_width = 92
    local qrcode_height = 92
    local _,qrcodedata = QREncode.qrcode(MacroCodeCampAward.GetQRCodeUrl())
    local block_size = qrcode_width / #qrcodedata

    local qrcode = ParaUI.CreateUIObject("container", "qrcode", "_lt", 340, 378, qrcode_width, qrcode_height);
    qrcode:SetField("OwnerDraw", true); -- enable owner draw paint event
    qrcode:SetField("SelfPaint", true);
    qrcode:SetScript("ondraw", function(test)
        for i = 1, #(qrcodedata) do
            for j = 1, #(qrcodedata[i]) do
                local code = qrcodedata[i][j];
                if (code < 0) then
                    ParaPainter.SetPen("#000000ff");
                    ParaPainter.DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
                end
            end
        end
        
    end);

    parent:AddChild(qrcode);
end

function MacroCodeCampAward.CloseView()
    if page then
        page:CloseWindow()
        page = nil
    end
    if MacroCodeCampAward.CheckCanShow() then
        MacroCodeCampActIntro.ShowView()
    end
end