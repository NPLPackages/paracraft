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
local page
local server_time = 0
local VersionToKey = {
	ONLINE = 1,
	RELEASE = 2,
	LOCAL = 3,
}

local SchoolClassIdList = {
    RELEASE = 33,
    ONLINE = 5
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
    -- {belong_name="papa", name="帕帕", desc="编程导师", icon="Texture/Aries/Creator/keepwork/AiCourse/ren2_55X55_32bits.png#0 0 55 55", order = -1},
    -- {belong_name="lala", name="拉拉", desc="建筑导师", icon="Texture/Aries/Creator/keepwork/AiCourse/ren3_55X55_32bits.png#0 0 55 55", order = -1},
    -- {belong_name="kaka", name="卡卡", desc="动画导师", icon="Texture/Aries/Creator/keepwork/AiCourse/ren4_55X55_32bits.png#0 0 55 55", order = -1},
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
    if page and page:IsVisible() then
        return
    end

    local client_data = QuestAction.GetClientData()

    if target_world_id == nil then
        local course_world_id = client_data.course_world_id or 0
        course_world_id = tonumber(course_world_id)
        if course_world_id > 0 then
            target_world_id = course_world_id
        end
    end

    QuestAllCourse.target_world_id = target_world_id
    QuestAllCourse.target_teacher_id = client_data.course_teacher_id
    QuestAllCourse.target_level_id = client_data.course_level_id

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

    keepwork.quest_course_catalogs.get({}, function(err2, msg2, data2)
        if err2 == 200 then
            -- HOME 或者 SCHOOL
            if GameLogic.GetFilters():apply_filters('service.session.get_user_where') == "SCHOOL" then
                local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
                local school_class_id = SchoolClassIdList[httpwrapper_version]
                if school_class_id then
                    QuestAllCourse.target_teacher_id = school_class_id
                    QuestAllCourse.target_level_id = school_class_id
                end
            end

            QuestAllCourse.CatalogsData = data2

            QuestAllCourse.RefreshTeacherListData()
            QuestAllCourse.SetSelectTeacherIndex()
            
            QuestAllCourse.RefreshLevelListData()
            QuestAllCourse.SetSelectLevelIndex()
            
            -- QuestAllCourse.RefreshCourseListData()
            QuestAction.RequestCompleteCourseIdList(function()
                QuestAllCourse.RefreshCourseListData(function()
                    -- 刷新课程列表控件
                    -- QuestAllCourse.FreshGridView("course_list")
                    QuestAllCourse.OnRefresh()
                    commonlib.TimerManager.SetTimeout(function()
                        if page and page:IsVisible() then
                            local mcmlNode = page:GetNode("course_list");
                            if QuestAllCourse.target_page then
                                pe_gridview.GotoPage(mcmlNode, "course_list", QuestAllCourse.target_page);
                                QuestAllCourse.target_page = nil
                            end

                            local tree_view = mcmlNode:GetChild("pe:treeview");
                            local tree_view_control = tree_view.control
                            local _parent = ParaUI.GetUIObject(tree_view_control.name);
                            local main = _parent:GetChild(tree_view_control.mainName);
                            main:SetScript("onmousewheel", function()
                                local page_index = mcmlNode:GetAttribute("pageindex") or 1
                                local target_page = page_index - mouse_wheel
                                pe_gridview.GotoPage(mcmlNode, "course_list", target_page);
                            end)
                        end
                    end, 100); 
                end)
            end)
        end
    end)
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
    QuestAllCourse.TeacherListData = {}
    QuestAllCourse.LevelListData = {}
    QuestAllCourse.CourseListData = {}
    
    QuestAllCourse.SelectTeacherIndex = 1
    QuestAllCourse.SelectLevelIndex = 1
    QuestAllCourse.SelectCourseIndex = 0
    QuestAllCourse.target_world_id = nil
    QuestAllCourse.target_teacher_id = nil
    QuestAllCourse.target_level_id = nil
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
    if QuestAllCourse.CatalogsData == nil then
        return
    end

    QuestAllCourse.TeacherListData = QuestAllCourse.CatalogsData
    -- QuestAllCourse.SelectTeacherIndex = 0

    -- if QuestAllCourse.TeacherListData[1].order == -1 then
    --     for index = #QuestAllCourse.TeacherListData, 1, -1 do
    --         local data = QuestAllCourse.TeacherListData[index]
            
    --         if QuestAllCourse.TeacherTableData[data.belong_name] == nil then
                
    --             table.remove(QuestAllCourse.TeacherListData, index)
    --         else
    --             data.order = QuestAllCourse.TeacherTableData[data.belong_name].order or 0
    --         end
    --     end
    
    --     table.sort(QuestAllCourse.TeacherListData,function(a,b)
    --         return a.order < b.order
    --     end)
    -- end
end

function QuestAllCourse.RefreshLevelListData()
    QuestAllCourse.SelectLevelIndex = 1
    local select_teacher_data = QuestAllCourse.TeacherListData[QuestAllCourse.SelectTeacherIndex]
    if select_teacher_data == nil then
        return
    end
    -- local teacher_data = QuestAllCourse.TeacherTableData[select_teacher_data.belong_name]
    -- if teacher_data == nil then
    --     return
    -- end

    QuestAllCourse.LevelListData = commonlib.copy(select_teacher_data.children)

    local all_course_data = commonlib.copy(select_teacher_data.children[1]) or {}
    all_course_data.name = "全部"
    all_course_data.id = select_teacher_data.id
    table.insert(QuestAllCourse.LevelListData, 1, all_course_data)
end

function QuestAllCourse.RefreshCourseListData(callback)
    QuestAllCourse.CourseListData = {}

    local select_level_data = QuestAllCourse.LevelListData[QuestAllCourse.SelectLevelIndex]
    if select_level_data == nil then
        return
    end

    QuestAllCourse.SelectCourseIndex = 0

    local id = select_level_data.id

    if QuestAllCourse.target_level_id then
        id = QuestAllCourse.target_level_id
        QuestAllCourse.target_teacher_id = nil
        QuestAllCourse.target_level_id = nil
    end
    keepwork.quest_course.get({
        aiCatalogId = id,
    }, function(err, msg, data)
        -- print("bbbbbbbbbbbbbbbbbbbbbbbbbb", id)
        -- echo(data, true)
        if err == 200 then
            QuestAllCourse.CourseListData = data.rows
            local world_id_list = {}
            local level_desc_list = {
                [1] = "低",
                [2] = "中",
                [3] = "高",
            }
            for k, v in pairs(QuestAllCourse.CourseListData) do
                -- 处理有target_world_id
                if v.projectId == QuestAllCourse.target_world_id then
                    QuestAllCourse.SelectCourseIndex = k
                    QuestAllCourse.target_page = math.ceil(QuestAllCourse.SelectCourseIndex / 8)
                    QuestAllCourse.target_world_id = nil
                end

                if v.icon == nil or v.icon == "" then
                    world_id_list[#world_id_list + 1] = v.projectId
                end

                -- 判断是否解锁
                v.IsLock = false
                
                if v.preCourseIds and #v.preCourseIds > 0 then
                    local need_unlock_list = {}
                    
                    for k2, v2 in pairs(v.preCourses) do
                        if not QuestAction.HasCompleteCourse(v2.id) then
                            need_unlock_list[#need_unlock_list + 1] = v2
                        end
                    end

                    v.IsLock = #need_unlock_list > 0

                    if v.IsLock then
                        local name_desc = ""
                        for i, v2 in ipairs(need_unlock_list) do
                            name_desc = name_desc .. string.format("《%s》 ", v2.name)
                        end

                        v.lock_desc = string.format("<div>课程锁定中</div>需要完成%s学习才能解锁此课程哦", name_desc)
                    end
                end

                

                -- 难度
                v.level_desc = ""
                if v.level and v.level ~= "" then
                    -- v.level_desc = string.format("难度: %s", level_desc_list[v.level])
                    v.level_start_div = ""
                    -- v.level = 5
                    v.level_start_desc = string.format('<div style="text-align: center;">课程难度：%s星</div>', v.level)
                    for index = 1, v.level do
                        v.level_start_div = v.level_start_div .. [[
                        <div zorder="1" style="float: left; width: 26px;height: 26px; background:">
                            <div zorder="1" style="position:relative;width: 26px;height: 26px; background:url(Texture/Aries/Creator/keepwork/AiCourse/xing_26X26_32bits.png#0 0 26 26)"></div>
                            <img zorder="4" onclick="SelectCourse" name='<%=Eval("index")%>' class="invalid_mask" style="position:relative;margin-left:0px;margin-top:0px;width:26px;height:26px;" bindtooltip='<%=GetTooltip(Eval("level_start_desc"))%>'/>
                        </div>
                        ]]
                    end
                end

                

                -- 时间
                v.time_desc = ""
                if v.beginAt and v.endAt then
                    local begain_time_stamp = commonlib.timehelp.GetTimeStampByDateTime(v.beginAt)
                    local end_time_stamp = commonlib.timehelp.GetTimeStampByDateTime(v.endAt)

                    local begain_time_desc = os.date("%m月%d日",begain_time_stamp)
                    local end_time_desc = os.date("%m月%d日",end_time_stamp)

                    v.time_desc = string.format("%s-%s", begain_time_desc, end_time_desc)
                end
            end

            QuestAllCourse.CourseWorldData = {}
            if #world_id_list > 0 then
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
    end)
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
    QuestAllCourse.RefreshCourseListData(function()
        -- 刷新课程列表控件
        QuestAllCourse.FreshGridView("course_list")
        local mcmlNode = page:GetNode("course_list");
        pe_gridview.GotoPage(mcmlNode, "course_list", 1);
    end)



    -- QuestAllCourse.CreateTeacherNpc()
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
    QuestAllCourse.RefreshCourseListData(function()
        -- 刷新课程列表控件
        QuestAllCourse.FreshGridView("course_list")
    end)
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

    -- QuestAllCourse.RunCommand(index)
end

function QuestAllCourse.GotoClass(index)
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
    
    if data == nil or data.projectId == nil then
        return
    end

    -- 校园课程 放开次数限制
    local httpwrapper_version = HttpWrapper.GetDevVersion() or "ONLINE"
    local school_class_id = SchoolClassIdList[httpwrapper_version]
    local select_teacher_data = QuestAllCourse.TeacherListData[QuestAllCourse.SelectTeacherIndex]

    local command = string.format("/loadworld -s -force %s", data.projectId)
    local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
    local function enter_world()
        local server_time = GameLogic.QuestAction.GetServerTime()

        if data.beginAt and data.endAt then
            local begain_time_stamp = commonlib.timehelp.GetTimeStampByDateTime(data.beginAt)
            local end_time_stamp = commonlib.timehelp.GetTimeStampByDateTime(data.endAt)
            if server_time < begain_time_stamp then
                _guihelper.MessageBox("还没到上课时间哦，请在上课时间内来学习吧。")
                return
            end

            if server_time > end_time_stamp then
                _guihelper.MessageBox("已错过上课时间，你可以继续做作业，或去学习其他课程。")
                return
            end
        end

        keepwork.quest_complete_course.get({
            aiCourseId = data.id,
        }, function(err2, msg2, data2)
            -- print("ttttttttttttttt", err2, data.id)
            -- echo(data2, true)
            if err2 == 200 then
                local work_data = data.aiHomework or {}
                
                local client_data = QuestAction.GetClientData()
                client_data.course_world_id = data.projectId
                
                -- if client_data.course_world_id_list == nil then
                --     client_data.course_world_id_list = {}
                -- end        

                -- if select_teacher_data.id ~= school_class_id then
                --     client_data.course_world_id_list[tostring(data.projectId)] = 1
                -- end

                local select_teacher_data = QuestAllCourse.TeacherListData[QuestAllCourse.SelectTeacherIndex]
                client_data.course_teacher_id = select_teacher_data.id
    
                local select_level_data = QuestAllCourse.LevelListData[QuestAllCourse.SelectLevelIndex]
                client_data.course_level_id = select_level_data.id

                client_data.course_id = data.id
                client_data.home_work_id = work_data.id or -1
                client_data.is_home_work = false
                
                client_data.course_step = 0
                if data2.userAiCourse and data2.userAiCourse.progress then
                    client_data.course_step = data2.userAiCourse.progress.stepNum or 0
                end
    
                KeepWorkItemManager.SetClientData(QuestAction.task_gsid, client_data)
                
                page:CloseWindow()
                QuestAllCourse.CloseView()
    
                GameLogic.QuestAction.SetDailyTaskValue("40044_60047_1",1)
                CommandManager:RunCommand(command)
            end
        end)
    end

    if System.User.isVip then
        enter_world()
    else
        -- 需要vip才能进
        if data.isVip == 1 then
            -- local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")
            -- VipToolNew.Show("AI_lesson")
            local function sure_callback()
                local VipToolNew = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipToolNew.lua")
                VipToolNew.Show("AI_lesson")
            end

            local desc = "是否开通会员学习？"
            local desc2 = "该课程是vip专属课程，需要vip权限才能学习。"
            QuestMessageBox.Show(desc, sure_callback, desc2)
        else
            local client_data = QuestAction.GetClientData()

            local has_enter = true -- 是否进去过
            -- if client_data.course_world_id_list and client_data.course_world_id_list[tostring(data.projectId)] ~= nil then
            --     has_enter = true
            -- end
            
            -- if school_class_id and select_teacher_data.id == school_class_id then
            --     has_enter = true
            -- end

            if has_enter then
                enter_world()
            else
                local play_course_times = 0
                -- if client_data.course_world_id_list ~= nil then
                --     for k, v in pairs(client_data.course_world_id_list) do
                --         play_course_times = play_course_times + 1
                --     end
                -- end
                
                local limit_course_times = 1

                if play_course_times < limit_course_times then
                    local desc = string.format('您要消耗今天的次数，学习<div style="float: left; color: #ff0000;">%s</div>？', data.name)
                    QuestMessageBox.Show(desc, enter_world, nil, "成为会员即可不受限制学习所有课程。")
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

function QuestAllCourse.SetSelectTeacherIndex()
    if QuestAllCourse.target_teacher_id then
        for k, v in pairs(QuestAllCourse.TeacherListData) do
            if v.id == QuestAllCourse.target_teacher_id then
                QuestAllCourse.SelectTeacherIndex = k
                break
            end
        end
    end
end

function QuestAllCourse.SetSelectLevelIndex()
    if QuestAllCourse.target_level_id then
        for k2, v2 in pairs(QuestAllCourse.LevelListData) do
            if v2.id == QuestAllCourse.target_level_id then
                QuestAllCourse.SelectLevelIndex = k2
            end
        end
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

function QuestAllCourse.GetWorldIconUrl(index)
    local data = QuestAllCourse.CourseListData[index]
    if data == nil then
        return
    end

    if data.icon and data.icon ~= "" then
        return data.icon
    end

    if data.projectId and QuestAllCourse.CourseWorldData[data.projectId] then
        return QuestAllCourse.CourseWorldData[data.projectId].imageUrl
    end

    return ""
end

function QuestAllCourse.HasWork(index)
    local data = QuestAllCourse.CourseListData[index]
    if data == nil then
        return false
    end

    return data.aiHomework ~= nil
end

function QuestAllCourse.ClickWork(index)
    local data = QuestAllCourse.CourseListData[index]
    if data == nil then
        return false
    end

    if data.aiHomework == nil then
        return
    end

    local work_data = data.aiHomework
    -- 判断作业是否激活
    keepwork.quest_complete_homework.get({
        aiHomeworkId = work_data.id,
    },function(err, message, data2)
        if err == 200 then
            local userAiHomework = data2.userAiHomework
            if userAiHomework == nil then
                local desc = string.format("需要先学习完《%s》才能开始作业哦", data.name)
                -- GameLogic.AddBBS(nil, desc, 5000, "255 0 0");
                _guihelper.MessageBox(desc)
                return
            end

            if not GameLogic.GetFilters():apply_filters('service.session.is_real_name') then
                _guihelper.MessageBox("学习人工智能课程需要先完成实名认证，快去认证吧。", function()	
                    GameLogic.GetFilters():apply_filters(
                        'show_certificate',
                        function(result)
                            if (result) then
                                local DockPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockPage.lua");
                                if DockPage.IsShow() then
                                    DockPage.RefreshPage(0.01)
                                end
                                
                                GameLogic.QuestAction.AchieveTask("40006_1", 1, true)
                                QuestAllCourse.ClickWork(index)
                            end
                        end
                    );
                end)
                return
            end

            local server_time = GameLogic.QuestAction.GetServerTime()
            local today_weehours = commonlib.timehelp.GetWeeHoursTimeStamp(server_time)

            -- 入校课程的话 需要每天四点半之后才能做
            if data.isForSchool == 1 then
                local limit_time_stamp = today_weehours + 16 * 60 * 60 + 30 * 60
                if server_time < limit_time_stamp then
                    -- GameLogic.AddBBS(nil, "16:30之后才能做作业哦", 5000, "255 0 0");
                    _guihelper.MessageBox("16:30之后才能做作业哦")
                    return
                end
            end

            local type = work_data.type -- 0：更新世界类型，1：更新家园，2：作业世界
            if type == 0 then
                page:CloseWindow()
                QuestAllCourse.CloseView()
                GameLogic.GetFilters():apply_filters('show_create_page')
            elseif type == 1 then
                local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
        
                NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
                local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
                LocalLoadWorld.CreateGetHomeWorld();
        
                GameLogic.GetFilters():apply_filters('check_and_updated_before_enter_my_home', function()
                    GameLogic.RunCommand("/loadworld home");
                end)
            else
                if work_data.projectId then
                    local command = string.format("/loadworld -s -force %s", work_data.projectId)
                    local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
                    local client_data = QuestAction.GetClientData()
                    client_data.course_world_id = work_data.projectId
                    client_data.course_id = work_data.aiCourseId
                    client_data.home_work_id = work_data.id
                    client_data.is_home_work = true
                    client_data.course_step = 0
                    if userAiHomework and userAiHomework.progress then
                        client_data.course_step = userAiHomework.progress.stepNum or 0
                    end
                    
                    KeepWorkItemManager.SetClientData(QuestAction.task_gsid, client_data)
                    
                    page:CloseWindow()
                    QuestAllCourse.CloseView()
        
                    CommandManager:RunCommand(command)
                end
            end

        end
    end)
end