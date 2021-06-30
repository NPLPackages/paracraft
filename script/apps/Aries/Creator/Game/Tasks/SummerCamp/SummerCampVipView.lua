--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampVipView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampVipView.lua") 
SummerCampVipView.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local SummerCampVipView = NPL.export()

local page = nil
function SummerCampVipView.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = SummerCampVipView.OnCreate
end

function SummerCampVipView.ShowView()
    SummerCampVipView.InitData()
    local view_width = 1024
    local view_height = 629
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampVipView.html",
        name = "SummerCampVipView.ShowView", 
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
end

function SummerCampVipView.OnCreate()
    local parent  = ParaUI.GetUIObject("summer_decode_wxcode_root")
    
    local qrcode_width = 100
    local qrcode_height = 100
    local block_size = qrcode_width / #SummerCampVipView.qrcode

    local qrcode = ParaUI.CreateUIObject("container", "qrcode_vip_tool", "_lt", 5, 5, qrcode_width, qrcode_height);
    qrcode:SetField("OwnerDraw", true); -- enable owner draw paint event
    qrcode:SetField("SelfPaint", true);
    qrcode:SetScript("ondraw", function(test)
        for i = 1, #(SummerCampVipView.qrcode) do
            for j = 1, #(SummerCampVipView.qrcode[i]) do
                local code = SummerCampVipView.qrcode[i][j];
                if (code < 0) then
                    ParaPainter.SetPen("#000000ff");
                    ParaPainter.DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
                end
            end
        end
        
    end);

    parent:AddChild(qrcode);
end

function SummerCampVipView.InitData()
    local QREncode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
    local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
	local userid = Mod.WorldShare.Store:Get('user/userId')
    local qrcode;
	if(userid) then
		qrcode = string.format("%s/p/qr/purchase?userId=%s&from=%s&source=paracraftTwo",KeepworkService:GetKeepworkUrl(), userid, "summer_vip_view");
	else
		qrcode = string.format("%s/p/qr/buyFor?from=%s&source=paracraftTwo",KeepworkService:GetKeepworkUrl(), "summer_vip_view");
	end

    local ret;
    ret, SummerCampVipView.qrcode = QREncode.qrcode(qrcode)
end