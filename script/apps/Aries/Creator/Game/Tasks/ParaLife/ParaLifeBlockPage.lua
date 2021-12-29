--[[
    author:{pbb}
    time:2021-12-16 10:54:38
    use lib:
    local ParaLifeBlockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBlockPage.lua") 
    ParaLifeBlockPage.ShowView()
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local ParaLifeBlockPage = NPL.export()
ParaLifeBlockPage.blockIds = {
    {id=52,},{id=17,},{id=5,},{id=51,},
    {id=4,},{id=171,},{id=26,},{id=62,},
    {id=55,},{id=13,},{id=174,},{id=28,},
    {id=159,},{id=155,},{id=56,},{id=123,},
    {id=124,},{id=18,},{id=87,},{id=16,},
    {id=2,},{id=145,},{id=130,},{id=147,},
    {id=131,},{id=151,},{id=150,},{id=146,},
    {id=125,},{id=158,},{id=12,},{id=53,},
    {id=85,},{id=86,},{id=91,},{id=129,},
    {id=92,},{id=82,},{id=126,},{id=128,},
    {id=98,},{id=99,}, {id=149,},{id=152,},
    {id=139,},{id=81,},{id=95,},{id=144,},
    {id=140,},{id=138,},{id=59,},{id=58,},
    {id=68,},{id=66,},{id=70,},{id=69,},
    {id=154,},{id=8,},{id=170,},{id=89,},
    {id=110,},{id=144,},{id=80,},{id=133,},
    {id=135,},{id=23,},{id=96,},{id=94,},
    {id=27,},{id=93,},{id=137,},{id=20,},
    {id=21,},{id=19,},{id=25,},{id=24,},
    {id=136,},{id=134,},{id=71,},{id=142,},
    {id=143,},{id=148,},{id=156,},{id=97,},
    {id=157,},{id=215,},{id=186,},{id=90,},
    {id=6,},{id=220,},{id=153,},{id=6,},
    {id=220,},{id=87,},{id=82,},{id=23,},
    {id=90,},{id=80,},{id=186,},{id=84,},{id=165,},}

local page = nil
function ParaLifeBlockPage.OnInit()
    page = document:GetPageCtrl();
end

function ParaLifeBlockPage.ShowView()
    local view_width = 230
    local view_height = 480
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBlockPage.html",
        name = "ParaLifeBlockPage.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=true, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        -- enable_esc_key = true,
        zorder = -1,
        refresh = true,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ctr",
            x = 0,
            y = 0,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaLifeBlockPage.GetBackground(block_id,block_data)
    local block_item = ItemClient.GetItem(block_id);
    if block_id > 0 and block_item ~= nil then
        local background = block_item:GetIcon(block_data):gsub(";", "#");
        local name = block_item:GetStatName()
        if background then
            return background
        end
    end
    return ""
end

function ParaLifeBlockPage.GetBlockName(block_id)
    local block_item = ItemClient.GetItem(block_id);
    if block_id > 0 and block_item ~= nil then
        local name = block_item:GetStatName()
        return name..",id:"..block_id
    end
    return ""
end

function ParaLifeBlockPage.SelectBlock(id)
    local playerEntity = GameLogic.EntityManager.GetPlayer()
    if(playerEntity and playerEntity.inventory and playerEntity.inventory) then
        local item = ItemStack:new():Init(id, 1, serverdata);
        if(playerEntity.SetBlockInRightHand) then
            playerEntity:SetBlockInRightHand(item);
        end
    end
end