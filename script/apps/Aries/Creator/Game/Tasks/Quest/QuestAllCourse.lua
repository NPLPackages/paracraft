--[[
Title: QuestAllCourse
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAllCourse.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local QuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestPage.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/Entity.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local QuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestProvider");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local QuestAllCourse = NPL.export();
local QuestMessageBox = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestMessageBox.lua");
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");

local server_time = 0
local VersionToKey = {
	ONLINE = 1,
	RELEASE = 2,
	LOCAL = 3,
}
QuestAllCourse.AllCourseListData = {}
-- QuestAllCourse.TeacherListData = {}
QuestAllCourse.LevelListData = {}
QuestAllCourse.CourseListData = {}

QuestAllCourse.CourseWorldData = {}
QuestAllCourse.ExidToWorldId = {}

QuestAllCourse.SelectTeacherIndex = 1
QuestAllCourse.SelectLevelIndex = 1
QuestAllCourse.SelectCourseIndex = 0

QuestAllCourse.TeacherListData = {
    {belong_name="teacher_fang", name="方老师", desc="冬令营导师", icon="Texture/Aries/Creator/keepwork/AiCourse/ren1_46X50_32bits.png#0 0 55 55", order = -1,},
    {belong_name="papa", name="帕帕", desc="编程导师", icon="Texture/Aries/Creator/keepwork/AiCourse/ren2_55X55_32bits.png#0 0 55 55", order = -1},
    {belong_name="lala", name="拉拉", desc="建筑导师", icon="Texture/Aries/Creator/keepwork/AiCourse/ren3_55X55_32bits.png#0 0 55 55", order = -1},
    {belong_name="kaka", name="卡卡", desc="动画导师", icon="Texture/Aries/Creator/keepwork/AiCourse/ren4_55X55_32bits.png#0 0 55 55", order = -1},
}

QuestAllCourse.NpcData = {
    teacher_fang = {assetfile="character/CC/02human/paperman/Female_teachers.x",
                    word = {"我是人工智能课方老师，欢迎来到我的课堂。","同学们都开始上课啦，你也别落后哦。","保存学习别偷懒，你就能成为人工智能未来之星啦。", "众多有趣的课程，快跟着我来学习吧。"}},
    papa = {assetfile="character/CC/02human/keepwork/avatar/pp.x",
                    word = {"我是编程导师帕帕，欢迎来到我的课堂。","学好编程就能做出更多有趣的作品哦。","想跟我一起学编程吗？快去上课吧。", "学完我的课程，你就是编程小达人啦。"}},
    lala = {assetfile="character/CC/02human/keepwork/avatar/lala.x",
                    word = {"我是建筑导师拉拉，欢迎来到我的课堂。","想搭建出美丽的家园吗？那就好好学习我的课程吧。","好好学习我的课程，你就能离建筑大师越来越近哦。", "想知道别人都是怎么搭建出漂亮作品的吗？答案就在课程里。"}},
    kaka = {assetfile="character/CC/02human/keepwork/avatar/kk.x",
                    word = {"我是动画导师卡卡，欢迎来到我的课堂。","好的故事可以用好的动画展示出来哦。","别人都在看动画，我来教你做动画吧。", "学会动画，你也是一个小小导演啦。"}},
}

function QuestAllCourse.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = QuestAllCourse.CloseView
end

function QuestAllCourse.GetPageCtrl()
    return page
end

function QuestAllCourse.Show(target_world_id)
    -- if not System.options.isDevMode then
    --     _guihelper.MessageBox("人工智能课程即日开启，敬请期待", nil, nil,nil,nil,nil,nil,{ ok = L"确定"});
    --     return
    -- end
    if target_world_id == nil then
        local client_data = QuestAction.GetClientData()
        local course_world_id = client_data.course_world_id or 0
        course_world_id = tonumber(course_world_id)
        if course_world_id > 0 then
            target_world_id = course_world_id
        end
    end

    QuestAllCourse.target_world_id = target_world_id

    keepwork.user.server_time({}, function(err, msg, data)
        server_time = commonlib.timehelp.GetTimeStampByDateTime(data.now, true)
        QuestAction.SetServerTime(server_time)
        QuestAllCourse.ShowView()
    end)
end

function QuestAllCourse.ShowView()
    if page and page:IsVisible() then
        return
    end

    local open_callback = function()
        QuestAllCourse.RefreshTeacherListData()

        QuestAllCourse.SelectTargetWorld()
        QuestAllCourse.RefreshLevelListData()
        QuestAllCourse.RefreshCourseListData()
        
        local params = {
            url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestAllCourse.html",
            name = "QuestAllCourse.Show", 
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            allowDrag = true,
            enable_esc_key = true,
            zorder = 0,
            app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
            directPosition = true,
            
            align = "_ct",
            x = -926/2,
            y = -562/2,
            width = 926,
            height = 562,
        };
        System.App.Commands.Call("File.MCMLWindowFrame", params);
    end

    QuestAllCourse.RefreshAllData(open_callback)
    
    commonlib.TimerManager.SetTimeout(function()

        if page and page:IsVisible() then
            if QuestAllCourse.target_page then
                local node = page:GetNode("course_list");
                pe_gridview.GotoPage(node, "course_list", QuestAllCourse.target_page);
                QuestAllCourse.target_page = nil
            end

            QuestAllCourse.CreateTeacherNpc()
        end
    end, 100); 

end

function QuestAllCourse.FreshView()
end

function QuestAllCourse.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    QuestAllCourse.FreshView()
end

function QuestAllCourse.CloseView()
    QuestAllCourse.ClearData()
end

function QuestAllCourse.ClearData()
    -- QuestAllCourse.TeacherListData = {}
    QuestAllCourse.LevelListData = {}
    QuestAllCourse.CourseListData = {}
    
    QuestAllCourse.SelectTeacherIndex = 1
    QuestAllCourse.SelectLevelIndex = 1
    QuestAllCourse.SelectCourseIndex = 0
    QuestAllCourse.target_world_id = nil
end

------------------------------------------------------------数据处理------------------------------------------------------------
function QuestAllCourse.RefreshAllData(callback)
    if QuestAllCourse.TeacherTableData == nil then
        QuestAllCourse.TeacherTableData = {}
        local world_id_list = {}
        local quest_datas = QuestProvider:GetInstance().templates_map
        local list_data = {}
        local exid_list = {}
        for i, v in pairs(quest_datas) do
            if exid_list[v.exid] == nil and v.belong ~= nil and v.belong ~= "" then
                v.order = v.order or 0
                list_data[#list_data + 1] = v
                -- for index = 1, 10 do
                --     list_data[#list_data + 1] = v
                -- end
                exid_list[v.exid] = 1
            end
        end

        -- 处理下排序
        table.sort(list_data,function(a,b)
            return a.order < b.order
        end)

        QuestAllCourse.AllCourseListData = list_data

        local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
        local target_index = QuestAction.VersionToKey[httpwrapper_version]
        QuestAllCourse.ExidToWorldId = {}
        for i, v in ipairs(list_data) do
            if QuestAllCourse.TeacherTableData[v.belong] == nil then
                QuestAllCourse.TeacherTableData[v.belong] = {}
                QuestAllCourse.TeacherTableData[v.belong].all_course_data = {}
            end

            local teacher_data = QuestAllCourse.TeacherTableData[v.belong]
            teacher_data.all_course_data[#teacher_data.all_course_data + 1] = v
            
            if teacher_data.order == nil then
                teacher_data.order = v.order or 0
            end
            if v.course_level then
                if teacher_data[v.course_level] == nil then
                    teacher_data[v.course_level] = {}
                end
                table.insert(teacher_data[v.course_level], v)
            end
            
            if v.command and #v.command > 0 then
                local command = v.command[target_index]
                local world_id = command:match("/loadworld[%s]?-s[%s]?-force[%s]?-inplace[%s]?(%d+)")
                world_id = world_id and tonumber(world_id) or 0
                QuestAllCourse.ExidToWorldId[v.exid] = world_id
                world_id_list[#world_id_list + 1] = world_id
            end
        end

        keepwork.world.search({
            type = 1,
            id = {["$in"] = world_id_list},
        },function(err, msg, data)
            -- print("获取关注列表结果", err, msg)
            -- commonlib.echo(data, true)
            if err == 200 then
                for k, v in pairs(data.rows) do
                    if QuestAllCourse.CourseWorldData[v.id] == nil then
                        QuestAllCourse.CourseWorldData[v.id] = {imageUrl = v.extra.imageUrl}
                    end
                end
                
                if callback then
                    callback()
                end
            end
        end)
    else
        if callback then
            callback()
        end
    end
end

function QuestAllCourse.RefreshTeacherListData()
    -- QuestAllCourse.TeacherListData = {}
    -- QuestAllCourse.SelectTeacherIndex = 0
    if QuestAllCourse.TeacherListData[1].order == -1 then
        for index = #QuestAllCourse.TeacherListData, 1, -1 do
            local data = QuestAllCourse.TeacherListData[index]
            
            if QuestAllCourse.TeacherTableData[data.belong_name] == nil then
                
                table.remove(QuestAllCourse.TeacherListData, index)
            else
                data.order = QuestAllCourse.TeacherTableData[data.belong_name].order or 0
            end
        end
    
        table.sort(QuestAllCourse.TeacherListData,function(a,b)
            return a.order < b.order
        end)
    end
end

function QuestAllCourse.RefreshLevelListData()
    QuestAllCourse.SelectLevelIndex = 1
    local select_teacher_data = QuestAllCourse.TeacherListData[QuestAllCourse.SelectTeacherIndex]
    if select_teacher_data == nil then
        return
    end
    local teacher_data = QuestAllCourse.TeacherTableData[select_teacher_data.belong_name]
    if teacher_data == nil then
        return
    end

    QuestAllCourse.LevelListData = {}
    if teacher_data.all_course_data then
        local data = {name = "全部", type_index = "all_course_data", belong_name = select_teacher_data.belong_name}
        QuestAllCourse.LevelListData[#QuestAllCourse.LevelListData + 1] = data
    end

    -- 预定5个
    for level = 1, 5 do
        if teacher_data[level] then
            local level_name = "二级"
            for i, v in ipairs(teacher_data[level]) do
                if v.level_name then
                    level_name = v.level_name
                    break
                end
            end
            
            -- local data = {name = string.format("%s级", level), type_index = level, belong_name = select_teacher_data.belong_name}
            local data = {name = level_name, type_index = level, belong_name = select_teacher_data.belong_name}
            QuestAllCourse.LevelListData[#QuestAllCourse.LevelListData + 1] = data
        end
    end


end

function QuestAllCourse.RefreshCourseListData()
    
    local select_level_data = QuestAllCourse.LevelListData[QuestAllCourse.SelectLevelIndex]
    if select_level_data == nil then
        return
    end

    local teacher_data = QuestAllCourse.TeacherTableData[select_level_data.belong_name]
    local course_data = teacher_data[select_level_data.type_index]
    if course_data == nil then
        return
    end
    local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
    local target_index = QuestAction.VersionToKey[httpwrapper_version]

    QuestAllCourse.SelectCourseIndex = 0
    if QuestAllCourse.TargetCourseIndex then
        QuestAllCourse.SelectCourseIndex = QuestAllCourse.TargetCourseIndex
        QuestAllCourse.TargetCourseIndex = nil
    end
    QuestAllCourse.CourseListData = {}
    for i, v in ipairs(course_data) do
        local data = {}
        local world_id = QuestAllCourse.ExidToWorldId[v.exid]
        world_id = world_id and tonumber(world_id) or 0
        data.imageUrl = ""
        if QuestAllCourse.CourseWorldData[world_id] then
            data.imageUrl = QuestAllCourse.CourseWorldData[world_id].imageUrl
        end
        local exchange_data = KeepWorkItemManager.GetExtendedCostTemplate(v.exid)
        data.name = exchange_data.name
        data.desc = exchange_data.desc
        data.world_id = world_id
        data.exid = v.exid
        if v.command and #v.command > 0 then
            data.command = v.command[target_index]
        end

        QuestAllCourse.CourseListData[#QuestAllCourse.CourseListData + 1] = data
    end

    
    -- echo(QuestAllCourse.CourseListData, true)
    -- QuestAllCourse.CourseListData = course_data
end
----------------------------------------------------------数据处理/end----------------------------------------------------------

------------------------------------------------------------点击事件------------------------------------------------------------

function QuestAllCourse.SelectTeacher(index)
    if index == QuestAllCourse.SelectTeacherIndex then
        return
    end
    QuestAllCourse.SelectTeacherIndex = index

    -- 刷新老师列表控件
    QuestAllCourse.FreshGridView("teacher_list")
    -- 刷新等级列表数据
    QuestAllCourse.RefreshLevelListData()
    
    -- 刷新等级列表控件
    QuestAllCourse.FreshGridView("level_list")
    -- 刷新课程列表数据
    QuestAllCourse.RefreshCourseListData()

    -- 刷新课程列表控件
    QuestAllCourse.FreshGridView("course_list")

    QuestAllCourse.CreateTeacherNpc()
end

function QuestAllCourse.IsSelectTeacher(index)
    return QuestAllCourse.SelectTeacherIndex == index
end

function QuestAllCourse.SelectLevel(index)
    if index == QuestAllCourse.SelectLevelIndex then
        return
    end
    QuestAllCourse.SelectLevelIndex = index
    
    -- 刷新等级列表控件
    QuestAllCourse.FreshGridView("level_list")

    -- 刷新课程列表数据
    QuestAllCourse.RefreshCourseListData()

    -- 刷新课程列表控件
    QuestAllCourse.FreshGridView("course_list")
end

function QuestAllCourse.IsSelectLevel(index)
    return QuestAllCourse.SelectLevelIndex == index
end

function QuestAllCourse.SelectCourse(index)
    -- if index == QuestAllCourse.SelectCourseIndex then
    --     return
    -- end
    QuestAllCourse.SelectCourseIndex = index
    -- 刷新课程列表控件
    QuestAllCourse.FreshGridView("course_list")

    QuestAllCourse.RunCommand(index)
end

function QuestAllCourse.IsSelectCourse(index)
    return QuestAllCourse.SelectCourseIndex == index
end

function QuestAllCourse.RunCommand(index)
    local data = QuestAllCourse.CourseListData[index]

    if data and data.command then
        local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
        if System.User.isVip then
            page:CloseWindow()
            QuestAllCourse.CloseView()
            local client_data = QuestAction.GetClientData()
            client_data.course_world_id = data.world_id
            KeepWorkItemManager.SetClientData(QuestAction.task_gsid, client_data)
            
            GameLogic.QuestAction.SetDailyTaskValue("40044_60047_1",1) 
            CommandManager:RunCommand(data.command)
        else
            local client_data = QuestAction.GetClientData()
            if client_data.play_course_times == nil then
                client_data.play_course_times = 0
            end

            if client_data.play_course_times <= 0 then
                local function sure_callback()
                    page:CloseWindow()
                    QuestAllCourse.CloseView()

                    local client_data = QuestAction.GetClientData()
                    client_data.play_course_times = client_data.play_course_times + 1
                    client_data.course_world_id = data.world_id
                    KeepWorkItemManager.SetClientData(QuestAction.task_gsid, client_data)

                    GameLogic.QuestAction.SetDailyTaskValue("40044_60047_1",1)
                    CommandManager:RunCommand(data.command)
                end

                local desc = string.format('您要消耗今天的次数，学习<div style="float: left; color: #ff0000;">%s</div>？', data.name)
                QuestMessageBox.Show(desc, sure_callback)
            else
                local client_data = QuestAction.GetClientData()
                local course_world_id = client_data.course_world_id or 0
                course_world_id = tonumber(course_world_id)
                -- 使用过之后 如果id相同 则可进入
                if course_world_id == 0 or course_world_id == tonumber(data.world_id) then
                    if course_world_id == 0 then
                        client_data.course_world_id = data.world_id
                        KeepWorkItemManager.SetClientData(QuestAction.task_gsid, client_data)
                    end

                    page:CloseWindow()
                    QuestAllCourse.CloseView()

                    GameLogic.QuestAction.SetDailyTaskValue("40044_60047_1",1)
                    CommandManager:RunCommand(data.command)
                else
                    local function sure_callback()
                        local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")
                        VipToolNew.Show("AI_lesson")
                    end
    
                    local desc = "您已消耗今天的次数。是否开通会员学习？"
                    QuestMessageBox.Show(desc, sure_callback)
                end
            end
        end
    end
end

----------------------------------------------------------点击事件/end----------------------------------------------------------

function QuestAllCourse.SelectTargetWorld()
    if QuestAllCourse.target_world_id then
        -- 默认全部类别
        -- 找到对应课程
        for k, v in pairs(QuestAllCourse.TeacherListData) do
            local all_course_data = QuestAllCourse.TeacherTableData[v.belong_name] and QuestAllCourse.TeacherTableData[v.belong_name].all_course_data or {}
            for k2, v2 in pairs(all_course_data) do
                local world_id = QuestAllCourse.ExidToWorldId[v2.exid] or 0
                
                if world_id == QuestAllCourse.target_world_id then
                    QuestAllCourse.SelectTeacherIndex = k
                    QuestAllCourse.TargetCourseIndex = k2

                    QuestAllCourse.target_page = math.ceil(QuestAllCourse.TargetCourseIndex / 1)
                    break
                end
            end
        end
        
        -- 找到对应页数

        -- 找到对应老师

        QuestAllCourse.target_world_id = nil
    end
    
end

function QuestAllCourse.FreshGridView(name)
    local node = page:GetNode(name);
    pe_gridview.DataBind(node, name, false);
end

function QuestAllCourse.CreateSceneNpc()
    local ob_params = ObjEditor.GetObjectParams(ParaScene.GetPlayer())
    local off_pos_z = - math.sin(ob_params.facing) * 3
    local off_pos_x = math.cos(ob_params.facing) * 3

    local npc_pos_x = ob_params.x + off_pos_x
    local npc_pos_z = ob_params.z + off_pos_z
    local npc_pos_y = ob_params.y

    local facing = math.pi + ob_params.facing
    
    local entity = MyCompany.Aries.Game.EntityManager.Entity:new();
    entity:SetLocationAndAngles(npc_pos_x, npc_pos_y, npc_pos_z, facing, 0)
    entity:CreateInnerObject("character/CC/02human/paperman/Male_teacher.x", true, 0, 1)
    entity:Say("你好呀")
end

function QuestAllCourse.CreateNpcAni()
    local parent  = page:GetParentUIObject()

	local miniSceneName = "pe:player"..ParaGlobal.GenerateUniqueID();

    local left = 0
    local right = 0
    local top = 0
    local bottom = 0
    local left = 0

	local instName = page.mcmlNode:GetInstanceName(page.name);
	NPL.load("(gl)script/ide/Canvas3D.lua");
	local ctl = CommonCtrl.Canvas3D:new{
		name = instName.."_mcplayer",
		alignment = "_lt",
		left = left,
		top = top,
		width = 196,
		height = 196,
		background = "",
		parent = parent,
		IsActiveRendering = true,
		miniscenegraphname = miniSceneName,
		DefaultRotY = 0,
		RenderTargetSize = 256,
		IsInteractive = 0,
		autoRotateSpeed = 0,
		DefaultCameraObjectDist = 7,
		DefaultLiftupAngle = 0.25,
		LookAtHeight =1.5,
		FrameMoveCallback = nil,
	};
	page.mcmlNode.Canvas3D_ctl = ctl;
	page.mcmlNode.control = ctl;
    ctl:Show(true);
    
    local start_path = "character/v5/06quest/JinBi/JinBi_Efx.x"

    local obj_params = ObjEditor.GetObjectParams(ParaScene.GetPlayer());
    obj_params.AssetFile = "character/v5/06quest/JinBi/JinBi_Efx.x"
	obj_params.name = "mc_player";	
	obj_params.facing = 0;
	obj_params.Attribute = 128;
    page.mcmlNode.obj_params = obj_params;
    ctl:ShowModel(obj_params);

    commonlib.TimerManager.SetTimeout(function()  
        local obj_params = ObjEditor.GetObjectParams(ParaScene.GetPlayer());
        obj_params.AssetFile = "character/CC/02human/paperman/Male_teacher.x"
        obj_params.name = "mc_player";	
        obj_params.facing = 1.57;
        obj_params.Attribute = 128;
        page.mcmlNode.obj_params = obj_params;
        ctl:ShowModel(obj_params);
        local obj = ctl:GetObject()
        if(obj and obj:IsValid()) then
            obj:SetField("AnimID", 33);
        end
        local _this = ParaUI.GetUIObject(ctl.name);
        ParaUI.DestroyUIObject(_this)
    end, 1500);
end

function QuestAllCourse.CreateTeacherNpc()
    local assetfile
    assetfile = assetfile or "character/CC/02human/paperman/boy01.x";
    local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
    local editor = VisualSceneLogic.createOrGetEditor()
    if(not editor)then
        return
    end

    local code = [[
        local words = {
            "好好学习，天天向上。",
            "你的作品是最棒的！",
        }
        -- registerClickEvent(function()
        --     local index = math.random(#words)
        --     local word = words[index]
        --     say(word, 2)
        -- end)
        -- local p_x,p_y,p_z = getPos("@p");
        -- local off_pos_z = - math.sin(getFacing("@p")) * 6
        -- local off_pos_x = math.cos(getFacing("@p")) * 6
        -- local npc_pos_x = p_x + off_pos_x
        -- local npc_pos_z = p_z + off_pos_z
        -- local npc_pos_y = p_y
        -- setPos(npc_pos_x,p_y,npc_pos_z)

        local p_x,p_y,p_z = getPos("@p");
        setPos(p_x + 6,p_y,p_z + 6)

        turnTo("@p")
        anim(0)

        local QuestAllCourse = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAllCourse.lua")
        local word_list = QuestAllCourse.GetNpcDataByKey("word")
        local index = math.random(#word_list)
        local word = word_list[index]
        say(word, 3)
        
        local start_x,start_y,start_z = getPos();
        
        while(true) do
            local x,y,z = getPos();
            local diffDistance = math.sqrt((start_x - x)^2 + (start_z - z)^2)
            if diffDistance > 20 then
                hide()
                return
            end
        
            if(((distanceTo("@p")) > (4))) then
                turnTo("@p")
                local p_x,p_y,p_z = getPos("@p");
                setPos(x,p_y,z)
                anim(4)
                moveForward(3, 0.5)
            else
                turnTo("@p")
                anim(0)
            end
        end
        ]]

    local node, code_component, movieclip_component = editor:createOrGetFollowTeacher(code);
    if(node and code_component and movieclip_component)then
        node:stop();
        local assetfile = QuestAllCourse.GetNpcDataByKey("assetfile")
        movieclip_component:changeAssetFile(assetfile);
        node:run();
    end

    -- commonlib.TimerManager.SetTimeout(function()
    --     -- local obj = movieclip_component.actor:GetInnerObject()
    --     -- ParaScene.Delete(obj)
    --     -- node:detach()

    --     movieclip_component.actor:GetEntity():DestroyInnerObject()
    -- end, 2000); 
end

function QuestAllCourse.GetNpcDataByKey(key)
    key = key or "word"
    local select_teacher_data = QuestAllCourse.TeacherListData[QuestAllCourse.SelectTeacherIndex]
    if select_teacher_data == nil or select_teacher_data.belong_name == nil then
        return
    end

    local select_teacher_name = select_teacher_data.belong_name
    local show_npc_data = QuestAllCourse.NpcData[select_teacher_name]
    return show_npc_data[key]
end