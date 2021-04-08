--[[
Title: QuestWorkCode
Author(s): yangguiyi
Date: 2021/3/3
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestWorkCode.lua").Show();
--]]
local QREncode = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
local Encoding = commonlib.gettable("System.Encoding");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local QuestWorkCode = NPL.export();
local page
local server_time = 0

QuestWorkCode.WorkData = {
    {name = "作业标题", desc = 0,}
}

function QuestWorkCode.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = QuestWorkCode.CloseView
    page.OnCreate = QuestWorkCode.OnCreate
end

function QuestWorkCode.Show(wxcode_url)
    wxcode_url = wxcode_url or ""
    -- wxcode_url = "https://www.baidu.com/"
    -- local ret;
    -- ret, QuestWorkCode.qrcode = QREncode.qrcode(wxcode_url)

    QuestWorkCode.wxcode_img_url = wxcode_url
    QuestWorkCode.ShowView()
end

function QuestWorkCode.ShowView()
    if page and page:IsVisible() then
        return
    end
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestWorkCode.html",
        name = "QuestWorkCode.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -632/2,
        y = -413/2,
        width = 632,
        height = 413,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function QuestWorkCode.CloseView()
    QuestWorkCode.ClearData()
end

function QuestWorkCode.ClearData()
end

function QuestWorkCode.OnCreate()
    -- local parent  = page:GetParentUIObject()
    -- local qrcode_width = 155
    -- local qrcode_height = 155
    -- local block_size = qrcode_width / #QuestWorkCode.qrcode

    -- local qrcode = ParaUI.CreateUIObject("container", "qrcode_quest_code", "_lt", 242, 212, qrcode_width, qrcode_height);
    -- qrcode:SetField("OwnerDraw", true); -- enable owner draw paint event
    -- qrcode:SetField("SelfPaint", true);
    -- qrcode:SetScript("ondraw", function(test)
    --     for i = 1, #(QuestWorkCode.qrcode) do
    --         for j = 1, #(QuestWorkCode.qrcode[i]) do
    --             local code = QuestWorkCode.qrcode[i][j];
    --             if (code < 0) then
    --                 ParaPainter.SetPen("#000000ff");
    --                 ParaPainter.DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
    --             end
    --         end
    --     end
        
    -- end);

    -- parent:AddChild(qrcode);
end