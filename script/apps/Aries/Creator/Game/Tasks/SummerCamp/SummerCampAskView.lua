--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampAskView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampAskView.lua") 
SummerCampAskView.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local SummerCampAskView = NPL.export()

local page = nil
local problems = {
    {answer = "毛泽东", option1 = "毛泽东", option2 = " 邓小平",  questiton = "秋收起义是谁领导的？"},
    {answer = "农村包围城市", option1 = "农村包围城市", option2 = "建立全国统一抗日战线", questiton = "秋收起义确立了以下哪个战略思想？"},
    {answer = "洛川会议", option1 = "洛川会议", option2 = "遵义会议", questiton = "以下哪次会议确立了全面抗战路线？"},
    {answer = "华南战场", option1 = "华北战场", option2 = "华南战场", questiton = "东江纵队是以下哪个战场的武装力量？"},
    {answer = "毛泽东", option1 = "毛泽东", option2 = "刘少奇", questiton = "古田会议是由谁主持召开的？"},

    {answer = "25000里", option1 = "25000里", option2 = "20000里", questiton = "红军长征总共多少里？"},
    {answer = "红井", option1 = "石井", option2 = "红井", questiton = "“吃水不忘挖井人，时刻想念毛主席”中的井后来被人们叫做？"},
    {answer = "刘胡兰", option1 = "江姐", option2 = "刘胡兰", questiton = "毛主席题词“生的伟大，死的光荣”是为了纪念以下哪位烈士？"},
    {answer = "7月1日", option1 = "7月1日", option2 = "8月1日", questiton = "建党节是哪一天？"},
    {answer = "朱德", option1 = "彭德怀", option2 = "朱德", questiton = "毛主席称赞以下那位是“人民的光荣”？"},

    {answer = "中共七大", option1 = "中共四大", option2 = "中共七大", questiton = "周恩来在哪次会议上作出了《论统一战线》的重要讲话？"},
    {answer = "《论联合政府》", option1 = "《论解放区战场》", option2 = "《论联合政府》", questiton = "毛主席在中共七大上提交了以下哪项报告？"},
    {answer = "邓小平", option1 = "周恩来", option2 = "邓小平", questiton = "红八军军部旧址楼前的两棵柏树是由谁亲手栽下的？"},
    {answer = "延安", option1 = "延安", option2 = "西安", questiton = "以下哪个城市被誉为红色革命根据地？"},
    {answer = "瑞金", option1 = "遵义", option2 = "瑞金", questiton = "伟大长征的起点是哪里？"},

    {answer = "激战腊子口", option1 = "激战腊子口", option2 = "淞沪会战", questiton = "以下哪个是长征期间发生的战斗？"},
    {answer = "毛泽东", option1 = "博古", option2 = "毛泽东", questiton = "遵义会议确立了谁的领导地位？"},
    {answer = "中共一大", option1 = "中共一大", option2 = "中共三大", questiton = "党在嘉兴南湖的红船上召开了哪次会议？"},
    {answer = "上海", option1 = "上海", option2 = "南昌", questiton = "中共一大会址所在地在以下哪个城市？"},
    {answer = "1921年", option1 = "1921年", option2 = "1925年", questiton = "中国共产党成立于哪一年？"},
}

local gsid = 70010
function SummerCampAskView.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = SummerCampAskView.OnCreate
end

function SummerCampAskView.ShowView()
    if QuestAction.CheckSummerTaskFinish(gsid) then
        
        _guihelper.MessageBox("您已完成所有答题");
        return
    end

    SummerCampAskView.InitData()
    
    local view_width = 722
    local view_height = 231
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampAskView.html",
        name = "SummerCampAskView.ShowView", 
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
            y = -view_height/2 + 100,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function SummerCampAskView.GetAskDesc()
    local data = problems[SummerCampAskView.ask_index]
    if data then
        return data.questiton
    end
end

function SummerCampAskView.GetButtonDesc(index)
    local data = problems[SummerCampAskView.ask_index]
    local option = data["option" .. index]
    if option then
        return option
    end
end

function SummerCampAskView.OnClickAnswer(index)
    local data = problems[SummerCampAskView.ask_index]
    local button_desc = SummerCampAskView.GetButtonDesc(index)
    if button_desc == data.answer then
        SummerCampAskView.right_num = SummerCampAskView.right_num + 1
    else
        _guihelper.MessageBox("请您再思考一下");
        return
    end

    SummerCampAskView.ask_index = SummerCampAskView.ask_index + 1

    if SummerCampAskView.ask_index > #problems then
        if SummerCampAskView.right_num >= #problems then
            page:CloseWindow()
            GameLogic.AddBBS("summer_ask", L"恭喜你完成所有答题");
            QuestAction.SetSummerTaskProgress(gsid, nil, function()
                GameLogic.GetCodeGlobal():BroadcastTextEvent("openRemainOriginalUI",{name="certiRemainOriginal"})
            end)
        end
        
        return
    end
    page:Refresh(0)
end

function SummerCampAskView.InitData()
    SummerCampAskView.ask_index = 1
    SummerCampAskView.right_num = 0
    SummerCampAskView.error_num = 0
end