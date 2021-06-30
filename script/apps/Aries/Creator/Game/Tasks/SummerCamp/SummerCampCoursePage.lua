--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampCoursePage.lua") 
SummerCampCoursePage.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local SummerCampCoursePage = NPL.export()

local page = nil

function SummerCampCoursePage.OnInit()
    page = document:GetPageCtrl();
end

function SummerCampCoursePage.ShowView(parent)
    local view_width = 1035
    local view_height = 623

    page = Map3DSystem.mcml.PageCtrl:new({ 
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampCoursePage.html" ,
        click_through = false,
    } );
    SummerCampCoursePage._root = page:Create("SummerCampCoursePage.ShowView", parent, "_lt", 0, 0, view_width, view_height)
    SummerCampCoursePage._root.visible = true

    return page
end

function SummerCampCoursePage.CloseView()
    -- body
end

function SummerCampCoursePage.GoTo()
    if true then
        GameLogic.AddBBS("summer_course", L"尚未到开课时间，敬请期待");
        return
    end

    local SummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampMainPage.lua") 
    SummerCampMainPage.CloseView()
    local world_id_list = {
        ONLINE = 69109,
        RELEASE = 20666,
    }
    local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local world_id = world_id_list[httpwrapper_version]

	local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
	CommandManager:RunCommand(string.format('/loadworld -force -s %s', world_id))
end