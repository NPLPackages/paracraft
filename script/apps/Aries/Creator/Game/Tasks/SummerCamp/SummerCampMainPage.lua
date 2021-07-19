--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
SummerCampMainPage.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local SummerCampMainPage = NPL.export()

local page = nil

local ViewList = {

}

SummerCampMainPage.TypeBtData = {
    {view_file = "SummerCampMainNotice.lua", select_img="Texture/Aries/Creator/keepwork/SummerCamp/bar_1_61x547_32bits.png#0 0 61 547"},  
    {view_file = "SummerCampCoursePage.lua", select_img="Texture/Aries/Creator/keepwork/SummerCamp/bar_2_61x547_32bits.png#0 0 61 547"},       
    {view_file = "SummerCampTaskPage.lua", select_img="Texture/Aries/Creator/keepwork/SummerCamp/bar_3_61x547_32bits.png#0 0 61 547"},    
    {view_file = "SummerCampRewardPage.lua", select_img="Texture/Aries/Creator/keepwork/SummerCamp/bar_4_61x547_32bits.png#0 0 61 547"},   
}

function SummerCampMainPage.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = SummerCampMainPage.OnCreate
end

function SummerCampMainPage.OnCreate()
    -- body
    for k, v in pairs(SummerCampMainPage.TypeBtData) do
        if v.page then
            v.page:Close()
            v.page = nil
        end
    end

    local select_type_data = SummerCampMainPage.TypeBtData[SummerCampMainPage.select_type_index]
    local node = ParaUI.GetUIObject("child_view_node");
    local SummerCampCoursePage = NPL.load(string.format("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/%s", select_type_data.view_file or "SummerCampCoursePage.lua")) 
    select_type_data.page = SummerCampCoursePage.ShowView(node)
end

function SummerCampMainPage.ShowView(index)
    SummerCampMainPage.select_type_index = index or 2

    local view_width = 1107
    local view_height = 715
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.html",
        name = "SummerCampMainPage.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        --app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    SummerCampMainPage.OnSelectType(SummerCampMainPage.select_type_index)
end

function SummerCampMainPage.CloseView()
    if page and page:IsVisible() then
        page:CloseWindow()
    end
end

function SummerCampMainPage.OnSelectType(index)
    SummerCampMainPage.select_type_index = index

    page:Refresh(0)
end

function SummerCampMainPage.GetTypeBgImg(index)
    local select_type_data = SummerCampMainPage.TypeBtData[SummerCampMainPage.select_type_index]
    return select_type_data.select_img
end

function SummerCampMainPage.GetPageCtrl()
    return page
end

function SummerCampMainPage.ClickMap()
    if page then
        page:CloseWindow()
    end

    local SummerCampMapView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMapView.lua") 
    SummerCampMapView.ShowView()
end