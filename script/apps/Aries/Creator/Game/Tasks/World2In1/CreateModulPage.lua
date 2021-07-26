--[[
Title: CreateModulPage
Author(s): yangguiyi
Date: 2021/6/18
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CreateModulPage.lua").Show();
local CreateModulPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CreateModulPage.lua")
--]]
local CreateModulPage = NPL.export();
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local server_time = 0
local page

local all_projects_data = {
    {type="全部", name="空白模板", project_name = "empty", id = 73347, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20824/raw#emptyTemplate.jpg", is_recommend=false, is_vip_use=false, pos={19200,11,19200}},
    {type="全部", name="长征", project_name = "changzheng", id = 69076, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20825/raw#qilvchangzheng.jpg", is_recommend=true, is_vip_use=false},

    {type="跑酷", name="跑酷模板1", project_name = "paoku1", id = 72030, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20807/raw#paoku1.jpg", is_recommend=false, is_vip_use=true, pos={19162,11,19206}},
    {type="跑酷", name="跑酷模板2", project_name = "paoku2", id = 72001, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20805/raw#paoku2.jpg", is_recommend=false, is_vip_use=true, pos={19162,11,19206}},

    -- 过山车
    {type="过山车", name="过山车模板", project_name = "guoshanche", id = 72012, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20808/raw#guoshanche.jpg", is_recommend=false, is_vip_use=true, pos={19162,11,19206}},
    {type="过山车", name="过山车模板2", project_name = "guoshanche2", id = 73304, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20820/raw#guoshanche2.jpg", is_recommend=false, is_vip_use=true, pos={19162,11,19206}},

    {type="动画", name="秋收起义", project_name = "qiushouqiyi", id = 71758, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20742/raw#秋收起义.jpg", is_recommend=false, is_vip_use=true, pos={19248,11,19200}},
    {type="动画", name="洛川会议", project_name = "luochuanhuiyi", id = 71756, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20740/raw#洛川会议.jpg", is_recommend=false, is_vip_use=true, pos={19207,11,19248}},
    {type="动画", name="东江纵队", project_name = "dongjiangzongdui", id = 71759, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20736/raw#东江纵队.jpg", is_recommend=false, is_vip_use=true, pos={19232,11,19152}},
    {type="动画", name="毛泽东故居", project_name = "maozedongguju", id = 71760, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20741/raw#毛泽东故居.jpg", is_recommend=false, is_vip_use=true, pos={19189,11,19148}},
    {type="动画", name="中共七大", project_name = "zhonggongqida", id = 71761, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20744/raw#中共七大.jpg", is_recommend=false, is_vip_use=true, pos={19159,11,19249}},
    {type="动画", name="红八军", project_name = "hongbajun", id = 71762, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20738/raw#红八军总部.jpg", is_recommend=false, is_vip_use=true, pos={19176,11,19238}},

    {type="动画", name="古田会议", project_name = "gutianhuiyi", id = 71764, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20737/raw#古田会议.jpg", is_recommend=false, is_vip_use=true, pos={19225,11,19147}},
    {type="动画", name="红井", project_name = "hongjing", id = 71765, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20739/raw#红井.jpg", is_recommend=false, is_vip_use=true, pos={19199,11,19224}},
    {type="动画", name="朱德故居", project_name = "zhudeguju", id = 71763, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20745/raw#朱德故居.jpg", is_recommend=false, is_vip_use=true, pos={19239,11,19246}},
    {type="动画", name="瓦窑堡", project_name = "wayaobu", id = 70874, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20743/raw#瓦窑堡.jpg", is_recommend=false, is_vip_use=true, pos={19175,11,19247}},

    {type="解密", name="闯关冒险", project_name = "chuangguan", id = 72015, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20806/raw#chuangguan.jpg", is_vip_use=true, pos={19162,11,19206}},
    {type="解密", name="逃出山庄", project_name = "taochushanzhuang", id = 72171, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20810/raw#yuhangyuan.png", is_vip_use=true, pos={19176,12,19205}},
    {type="解密", name="星光", project_name = "xingguang", id = 71023, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20809/raw#littleGril.png", is_vip_use=true, pos={19209,12,19164}},

    {type="单人游戏", name="球赛模板", project_name = "qiusai", id = 72003, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20804/raw#qiusai.jpg", is_vip_use=true, pos={19162,11,19206}},
    {type="单人游戏", name="保护羊群", project_name = "baohu", id = 73307, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20819/raw#baohu.jpg", is_vip_use=true, pos={19162,11,19206}},

    {type="教学", name="建设乐园", project_name = "leyuan", id = 73305, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20821/raw#leyuan.jpg", is_vip_use=true, pos={19162,11,19206}},
}

CreateModulPage.TypeData = {
    ["全部"] = {name="全部", background="Texture/Aries/Creator/keepwork/World2In1/zi1_32X32_32bits.png#0 0 108 36", project_list = {}},
    ["跑酷"] = {name="跑酷", background="Texture/Aries/Creator/keepwork/World2In1/zi3_32X32_32bits.png#0 0 108 36", project_list = {}},
    ["过山车"] = {name="过山车", background="Texture/Aries/Creator/keepwork/World2In1/zi8_62X15_32bits.png#0 0 108 36", project_list = {}},
    ["动画"] = {name="动画", background="Texture/Aries/Creator/keepwork/World2In1/zi2_31X15_32bits.png#0 0 108 36", project_list = {}},
    ["解密"] = {name="解密", background="Texture/Aries/Creator/keepwork/World2In1/zi4_32X32_32bits.png#0 0 108 36", project_list = {}},
    ["单人游戏"] = {name="单人游戏", background="Texture/Aries/Creator/keepwork/World2In1/zi6_62X15_32bits.png#0 0 108 36", project_list = {}},
    ["射击"] = {name="射击", background="Texture/Aries/Creator/keepwork/World2In1/zi9_31X15_32bits.png#0 0 108 36", project_list = {}},
    ["教学"] = {name="教学", background="Texture/Aries/Creator/keepwork/World2In1/zi10_31X15_32bits.png#0 0 108 36", project_list = {}},
    ["多人游戏"] = {name="多人游戏", background="Texture/Aries/Creator/keepwork/World2In1/zi7_62X15_32bits.png#0 0 108 36", project_list = {}},
}

local worldid_to_projects = {
    [73104] = {type={"动画"}, id_list={}},
    [72945] = {is_all= true},
}

CreateModulPage.AllData = {}
CreateModulPage.WorldDataList = {}

-- local quanbu_defalu_num = #CreateModulPage.TypeData[1].project_list
function CreateModulPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = CreateModulPage.CloseView
    page.OnCreate = CreateModulPage.OnCreate
end

function CreateModulPage.OnCreate()
    if page and page:IsVisible() then
        local mcmlNode = page:GetNode("module_list");
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
end
function CreateModulPage.CloseView()
    CreateModulPage.WorldListData = nil
    if CreateModulPage.close_cb then
        CreateModulPage.close_cb()
        CreateModulPage.close_cb = nil
    end
end

function CreateModulPage.Show(create_project_name, parent_id, close_cb)
    CreateModulPage.close_cb = close_cb
    CreateModulPage.parent_id = parent_id
    CreateModulPage.create_project_name = create_project_name
    CreateModulPage.ShowView()
end

function CreateModulPage.ShowView()
    if page and page:IsVisible() then
        return
    end

	if not CreateModulPage.BindFilter then
		GameLogic.GetFilters():add_filter("became_vip", function()
            if page then
                CreateModulPage.HandleData()
                page:Refresh(0)
            end
        end);
		CreateModulPage.BindFilter = true
	end

    CreateModulPage.select_type_index = 1
    CreateModulPage.select_module_index = 1
    CreateModulPage.HandleData(nil, true)
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/CreateModulPage.html",
        name = "CreateModulPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        directPosition = true,
        
        align = "_ct",
        x = -854/2,
        y = -573/2,
        width = 854,
        height = 573,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    if not CreateModulPage.not_bind then
        CreateModulPage.not_bind = true
        GameLogic.GetFilters():add_filter("save_world_info", function()
            if CreateModulPage.to_path then
                local to_path = CreateModulPage.to_path
                CreateModulPage.to_path = nil

                if page and page:IsVisible() then
                    CreateModulPage.close_cb = nil
                    page:CloseWindow()
                    CreateModulPage.CloseView()
                end
               
                if to_path then
                    GameLogic.RunCommand(string.format('/loadworld %s', to_path))
                end
            end
        end);
    end

    CreateModulPage.FlushGridView()
end

function CreateModulPage.HandleData(cb)
    CreateModulPage.AllData = {}
    CreateModulPage.WorldDataList = {}

    -------------------------------------
    local world_id = CreateModulPage.parent_id
    local wrold_type_data = worldid_to_projects[world_id]
    local is_all = true
    local project_list = {}
    if wrold_type_data then
        if wrold_type_data.is_all then
            is_all = true
        else
            is_all = false
            if wrold_type_data.type then
                for i, v in ipairs(wrold_type_data.type) do
                    for i2, v2 in ipairs(all_projects_data) do
                        if v2.type == "全部" or v2.type == v then
                            project_list[#project_list + 1] = v2
                        end
                    end
                end
            end

        end
    end

    if is_all then
        project_list = all_projects_data
    end

    local type_to_world = {}
    for i, v in ipairs(project_list) do
        if type_to_world[v.type] == nil then
            type_to_world[v.type] = 1
            local type_data = CreateModulPage.TypeData[v.type]
            type_data.project_list = {}
            CreateModulPage.AllData[#CreateModulPage.AllData + 1] = type_data
        end

        local type_data = CreateModulPage.AllData[#CreateModulPage.AllData]
        type_data.project_list[#type_data.project_list + 1] = v
    end

    local select_type_data = CreateModulPage.AllData[CreateModulPage.select_type_index]
    local is_select_recommend = false
    if select_type_data.name == "全部" then
        is_select_recommend = true
        for i, v in ipairs(CreateModulPage.AllData) do
            if v.name ~= "全部" then
                for i2, v2 in ipairs(v.project_list) do
                    select_type_data.project_list[#select_type_data.project_list + 1] = v2
                end
            end
        end
    end

    local id_list = {}
    local id_to_data = {}
    local project_list = select_type_data.project_list
    local defalu_recommend_index = nil
    for index, v in ipairs(project_list) do
        v.is_show_vip_lock = v.is_vip_use and not GameLogic.IsVip()

        if v.is_recommend and is_select_recommend and defalu_recommend_index == nil then
            defalu_recommend_index = index
        end
    end
    
    CreateModulPage.WorldDataList = project_list
    local select_module_data = CreateModulPage.WorldDataList[1]
    if select_module_data.is_show_vip_lock then
        CreateModulPage.select_module_index = 0
    else
        CreateModulPage.select_module_index = defalu_recommend_index or 1
    end
    
    -- page:Refresh(0)
    if cb then
        cb()
    end    
end

function CreateModulPage.GetDesc1()
    return "欢迎来到创作区，你可以选择下面模板快速创建属于你的迷你地块，并入驻至课程世界与其他同学PK哦！"
end

function CreateModulPage.OnClickCreate()
    local project_name = page:GetValue("project_text") or ""
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
        _guihelper.MessageBox(L"您尚未登录，只能创建普通的迷你世界", function()
            page:CloseWindow()
            CreateModulPage.close_cb = nil
            CreateModulPage.CloseView()
    
            local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
            CreateNewWorld.CreateWorldByName(project_name, "paraworldMini")
        end);

        return
    end

    if CreateModulPage.select_module_index == nil or CreateModulPage.select_module_index == 0 then
        GameLogic.AddBBS("create_module", L"请先选择模板", 5000, "255 0 0");
        return
    end

    local select_module_data = CreateModulPage.WorldDataList[CreateModulPage.select_module_index]
    if select_module_data == nil then
        return
    end

    local parent_id = CreateModulPage.parent_id or 0
    local region_id = select_module_data.id

    if HttpWrapper.GetDevVersion() == "RELEASE" then
        region_id = 20692 -- rls七律长征
    end

    if parent_id == 0 and select_module_data.project_name == "empty" then
        page:CloseWindow()
        CreateModulPage.close_cb = nil
        CreateModulPage.CloseView()

        local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
        CreateNewWorld.CreateWorldByName(project_name, "paraworldMini")
        return
    end

    if string.find(project_name, "*") then
        GameLogic.AddBBS("create_module", string.format("含有敏感词，请修改", world), 5000, "255 0 0");
        return
    end
    
    if project_name == "" then
        GameLogic.AddBBS("create_module", L"请输入项目名称", 5000, "255 0 0");
        return
    end

    if string.len(project_name) > 40 then
        GameLogic.AddBBS("create_module", L"世界名字太长了, 请重新输入", 5000, "255 0 0");
        return
    end
    if CreateModulPage.project_file_path == nil then
        CreateModulPage.project_file_path = ParaIO.GetWritablePath() .. "worlds/DesignHouse/"
    end

    local function to_world2in1_region()
        World2In1.SetCreatorWorldName(project_name)
        CreateModulPage.close_cb = nil
        page:CloseWindow()
        CreateModulPage.CloseView()
        
        CommandManager:RunCommand(format([[/createworld -name "%s" -parentProjectId %d -update -fork %d]], project_name, parent_id,region_id))
    end
    
    local name = commonlib.Encoding.Utf8ToDefault(project_name)
    local world_path = CreateModulPage.project_file_path .. name
    if parent_id ~= 0 then
        if ParaIO.DoesFileExist(world_path, true) then
            _guihelper.MessageBox("模板已经存在了，是否直接使用该模板，否则请修改项目名称", function()	
                to_world2in1_region()
            end)
        else
            to_world2in1_region()
        end
    else

        if ParaIO.DoesFileExist(world_path, true) then
            _guihelper.MessageBox("世界已经存在了，是否直接进入该世界", function()	
                page:CloseWindow()
                CreateModulPage.close_cb = nil
                CreateModulPage.CloseView()
                local path = "worlds/DesignHouse/" .. name
                GameLogic.RunCommand(string.format('/loadworld %s', path))
                
            end)
            return
        else
            CreateModulPage.to_path = "worlds/DesignHouse/" .. project_name
            CommandManager:RunCommand(format([[/createworld -name "%s" -parentProjectId %d -update -fork %d]], project_name, parent_id,region_id))
        end
    end
    -- CommandManager:RunCommand(format([[/createworld -name "%s" -fork %d]], project_name,region_id))
end

function CreateModulPage.SelectType(index)
    CreateModulPage.select_type_index = index
    page:Refresh(0)

    CreateModulPage.HandleData(function()
        CreateModulPage.FlushGridView()
        local mcmlNode = page:GetNode("module_list");
        pe_gridview.GotoPage(mcmlNode, "module_list", 1);
    end)
end

function CreateModulPage.GetIsRecommendModule(id)
    return true
end

function CreateModulPage.GetIsVipModule(id)
    return false
end

function CreateModulPage.GetHasUsed(id)
    return true
end

function CreateModulPage.GetIsCompetitionModule(id)
    return true
end

function CreateModulPage.SelectModule(index)
    local select_module_data = CreateModulPage.WorldDataList[index]
    if select_module_data == nil then
        return
    end

    if select_module_data.is_show_vip_lock then
        _guihelper.MessageBox("对不起，需要开通会员才能使用此模板。立即加入会员，所有模板随心使用！", function()	
            GameLogic.IsVip("create_module_page", true, function(result)
                if result then
                    --Page:Refresh(0)
                end
            end);  
        end)
        return
    end

    CreateModulPage.select_module_index = index
    if CreateModulPage.create_project_name then
        CreateModulPage.create_project_name = page:GetValue("project_text")
    end
    CreateModulPage.FlushGridView()
end

function CreateModulPage.FlushGridView()
    local node = page:GetNode("module_list");
    pe_gridview.DataBind(node, "module_list", false);

    local select_module_data = CreateModulPage.WorldDataList[CreateModulPage.select_module_index]
    if select_module_data == nil then
        page:SetValue("project_text", "")
        return
    end

    local project_name = ""
    if select_module_data then
        project_name  = string.format("%s_%s_", System.User.username or "", select_module_data.project_name)
    end
    
    if CreateModulPage.create_project_name then
        project_name = CreateModulPage.create_project_name
        -- CreateModulPage.create_project_name = nil
    end

    page:SetValue("project_text", project_name)
end

function CreateModulPage.GetAllProjects()
    return all_projects_data
end

function CreateModulPage.GetOneProjectData(id)
    for k, v in pairs(all_projects_data) do
        if v.id == id then
            return v
        end
    end
end