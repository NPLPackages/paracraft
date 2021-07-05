--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampMapView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMapView.lua") 
SummerCampMapView.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local SummerCampMapView = NPL.export()

SummerCampMapView.IconData = {
    {name = "延安营地", to_pos = {18866,11,19263}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_1_166x21_32bits.png#0 0 166 21", icon_pos={326, 100}, desc="红色夏令营的出生地，周边众多精美课程以及地下纪念馆等你探索~"},
    {name = "一大会址展馆", to_pos = {18883,11,19190}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_2_166x21_32bits.png#0 0 166 21", icon_pos={503, 107}, desc="还原一大会址旧址，可以在这里开启夏令营3D动画编程课~"},
    {name = "重走长征路起点", to_pos = {19195,50,19204}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_3_166x21_32bits.png#0 0 166 21", icon_pos={485, -12}, desc="重走长征路活动的起点瑞金，伟大长征路从这里开始~"},
    {name = "梦回摇篮集合点", to_pos = {18671,11,19264}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_4_166x21_32bits.png#0 0 166 21", icon_pos={68, 255}, desc="梦回摇篮活动的红色建筑之一，可以从这里开始重温红色记忆~"},
    {name = "瑞金广场", to_pos = {18929,14,19264}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_5_166x21_32bits.png#0 0 166 21", icon_pos={382, 25}, desc="趣味交互式编程课《征程》展馆，可以在这里了解《征程》相关信息~"},
    {name = "圣火广场", to_pos = {18955,11,19358}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_6_166x21_32bits.png#0 0 166 21", icon_pos={296, 40}, desc="夏令营开营仪式的举行场地，可以在这里乘坐红军第一架飞机《列宁号》游览长征路~"},
    {name = "红船广场", to_pos = {18801,11,19264}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_7_166x21_32bits.png#0 0 166 21", icon_pos={232, 141}, desc="再现百年前中国共产党诞生地——南湖红船，广场上可以看到夏令营相关排行榜~"},
    {name = "抗疫学习场", to_pos = {18687,11,19508}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_8_166x21_32bits.png#0 0 166 21", icon_pos={20, 88}, desc="预防新冠，不能掉以轻心，在这里学习预防新冠相关知识吧~"},
    {name = "周公馆", to_pos = {18984,11,19156}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_9_166x21_32bits.png#0 0 166 21", icon_pos={505, 47}, desc="还原红色建筑周公馆，这里曾是周总理在上海的居所，一同去参观吧~"},
    {name = "遵义会议展馆", to_pos = {18894,14,19345}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_10_166x21_32bits.png#0 0 166 21", icon_pos={261, 63}, desc="还原红色建筑遵义会议旧址，这里曾是党的命运转折点，上二楼有惊喜哟~"},
    {name = "优秀作品排行榜I", to_pos = {18698,11,19337}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_11_166x21_32bits.png#0 0 166 21", icon_pos={119, 118}, desc="讲好中国故事优秀作品作者排行榜，快去参加活动，加油上榜吧~"},
    {name = "优秀作品排行榜II", to_pos = {18742,11,19191}, bg_img="Texture/Aries/Creator/keepwork/SummerCamp/map_bt_12_166x21_32bits.png#0 0 166 21", icon_pos={462, 270}, desc="人工智能大赛优秀作品作者排行榜，快去参加活动，加油上榜吧~"},   
}

local page = nil
function SummerCampMapView.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = SummerCampMapView.OnCreate
end

function SummerCampMapView.ShowView()
    SummerCampMapView.InitData()
    local view_width = 912
    local view_height = 515
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMapView.html",
        name = "SummerCampMapView.ShowView", 
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


function SummerCampMapView.InitData()

end

function SummerCampMapView.OnCreate()
    local x, y, z = EntityManager.GetPlayer():GetPosition()
    x, y, z = BlockEngine:block_float(x, y, z);
    local my_pos = {x, y, z}
    local min_distance = -1
    local target_index = 1
    for i, v in ipairs(SummerCampMapView.IconData) do
        local distance = SummerCampMapView.GetDistanceSq(my_pos, v.to_pos)
        
        if min_distance == -1 then
            min_distance = distance
        end

        if distance < min_distance then
            min_distance = distance
            target_index = i
        end
    end
    
    local target_data = SummerCampMapView.IconData[target_index]
    local icon_pos = target_data.icon_pos
    
    local head_icon_object = ParaUI.GetUIObject("map_head_icon");
    
    head_icon_object.x, head_icon_object.y = icon_pos[1], icon_pos[2]

end

function SummerCampMapView.GetDistanceSq(pos1, pos2)
    -- return (pos1[1]-pos2[1])^2 + (pos1[2]-pos2[2])^2 + (pos1[3]-pos2[3])^2;

    local dx = pos1[1] - pos2[1];
    local dy = pos1[2] - pos2[2];
    local dz = pos1[3] - pos2[3];
    return math.sqrt(dx * dx + dy * dy + dz * dz);
end

function SummerCampMapView.ToPos(index)
    local target_data = SummerCampMapView.IconData[index]
    local to_pos = target_data.to_pos
    GameLogic.RunCommand(string.format("/goto %s %s %s", to_pos[1], to_pos[2], to_pos[3]))
    page:Refresh(0)
end

function SummerCampMapView.OnMouseEnter(index)
    local value = SummerCampMapView.GetMapInfo(index)
    page:SetValue("map_info_lable", value)
end

function SummerCampMapView.OnMouseLeave(index)
    page:SetValue("map_info_lable", '')
end

function SummerCampMapView.GetMapInfo(index)
    local target_data = SummerCampMapView.IconData[index]
    if target_data then
        return target_data.desc
    end

    return ""
end