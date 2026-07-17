--[[
Title: MiniGame Profile Page
Author(s): ParaCraft Team
Date: 2024/3/21
Desc: 小游戏主界面，用于展示相互入口ui
Use Lib:
-------------------------------------------------------
local MiniGameUserProfile = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserProfile.lua");
MiniGameUserProfile.ShowPage();
-------------------------------------------------------
]]

-- 统一配置管理：从配置表中自动生成能力映射
local function generateAbilityMap(config)
    local abilityMap = {}
    for categoryKey, categoryData in pairs(config) do
        abilityMap[categoryKey] = {}
        -- 递归遍历配置结构，提取所有叶子节点的能力项
        local function extractAbilities(data, targetMap)
            for key, value in pairs(data) do
                if type(value) == "table" and value.enabled ~= nil then
                    -- 这是一个能力项（叶子节点）
                    targetMap[key] = true
                elseif type(value) == "table" and key ~= "title" and key ~= "english_name" and key ~= "sortIndex" then
                    -- 这是一个子分类，继续递归
                    extractAbilities(value, targetMap)
                end
            end
        end
        extractAbilities(categoryData, abilityMap[categoryKey])
    end
    return abilityMap
end

-- 青少年配置表（8-16岁）
local teenProfileConfig = {
    cognitiveAbilities = {
        title = "认知能力",
        sortIndex = 1,
        memory = {
            title = "记忆力",
            visualMemory = {title = "视觉记忆", enabled = true},
            auditoryMemory = {title = "听觉记忆", enabled = true},
            workingMemory = {title = "工作记忆", enabled = true},
        },
        attention = {
            title = "注意力",
            focusedAttention = {title = "集中性注意力", enabled = true},
            selectiveAttention = {title = "选择性注意力", enabled = true},
            shiftingAttention = {title = "转移性注意力", enabled = true},
            distributedAttention = {title = "分配性注意力", enabled = true},
        },
        thinkingAbility = {
            title = "思维能力",
            deductiveReasoning = {title = "演绎推理能力", enabled = true},
            inductiveReasoning = {title = "归纳推理能力", enabled = true},
            analogicalReasoning  = {title = "类比推理能力", enabled = true},
            verbalComprehension  = {title = "言语理解能力", enabled = true},
            abstractReasoning = {title = "抽象推理能力", enabled = true},
            visualSpatialIntelligence = {title = "视觉空间智能", enabled = true},
        },
    },
    learningStrategy = {
        title = "学习策略",
        sortIndex = 2,
        cognitiveStrategies = {
            title = "认知策略",
            elaborationStrategy = {title = "复述策略", enabled = true},
            detailedProcessingStrategy = {title = "精细加工策略", enabled = true},
            organizationalStrategy = {title = "组织策略", enabled = true},
        },
        metacognitiveStrategies = {
            title = "元认知策略",
            metacognitivePlanning = {title = "元认知计划", enabled = true},
            metacognitiveMonitoring = {title = "元认知监控", enabled = true},
            metacognitiveRegulation = {title = "元认知调节", enabled = true},
        },
        resourceManagement = {
            title = "资源管理",
            effortManagement = {title = "努力管理", enabled = true},
            timeManagement = {title = "时间管理", enabled = true},
            externalResourceUtilization = {title = "外界资源利用", enabled = true}
        },
    },
    learningMotivation = {
        title = "学习动机",
        sortIndex = 3,
        internalMotivation = {
            title = "内部动机",
            growth = {title = "成长", enabled = true},
            autonomy = {title = "自主", enabled = true},
            interaction = {title = "互动", enabled = true},
            interest = {title = "兴趣", enabled = true},
        },
        externalMotivation = {
            title = "外部动机",
            recognition = {title = "认可", enabled = true},
            competition = {title = "竞争", enabled = true},
            materialReward = {title = "物质奖励", enabled = true}
        },
    },
    emotionalIntelligence = {
        title = "情绪智力",
        sortIndex = 4,
        emotionalAwareness = {title = "情绪感知理解", enabled = true},
        emotionalRegulation = {title = "情绪调节表达", enabled = true},
    },
    learningQuality = {
        title = "学习品质",
        sortIndex = 5,
        responsibility = {title = "责任心", enabled = true},
        seriousness = {title = "严谨性", enabled = true},
        perseverance = {title = "坚毅性", enabled = true},
        creativity = {title = "创新性", enabled = true}
    }
}


-- 儿童配置表（5-7岁）
local kidProfileConfig = {
    cognitive_ability = {
        sortIndex = 1,
        title = "认知能力",
        english_name = "Cognitive Ability",
        visual_perception = {title = "视知觉", english_name = "Visual Perception", enabled = true},
        auditory_perception = {title = "听知觉", english_name = "Auditory Perception", enabled = true},
        thinking_ability = {title = "思维能力", english_name = "Thinking Ability", enabled = true},
        visual_motor_integration = {title = "视动统合", english_name = "Visual Motor Integration", enabled = true},
        language_ability = {title = "言语能力", english_name = "Language Ability", enabled = true},
        attention = {title = "注意力", english_name = "Attention", enabled = true}
    },
    learning_quality = {
        sortIndex = 2,
        title = "学习品质",
        english_name = "Learning Quality",
        curiosity = {title = "好奇心", english_name = "Curiosity", enabled = true},
        learning_interest = {title = "学习兴趣", english_name = "Learning Interest", enabled = true},
        initiative = {title = "主动性", english_name = "Initiative", enabled = true},
        persistence = {title = "坚持性", english_name = "Persistence", enabled = true}
    },
    emotional_ability = {
        sortIndex = 3,
        title = "情绪能力",
        english_name = "Emotional Ability",
        emotional_understanding = {title = "情绪理解", english_name = "Emotional Understanding", enabled = true},
        emotional_regulation = {title = "情绪调节", english_name = "Emotional Regulation", enabled = true},
        emotional_expression = {title = "情绪表达", english_name = "Emotional Expression", enabled = true}
    },
    interpersonal_relationship = {
        sortIndex = 4,
        title = "人际交往",
        english_name = "Interpersonal Relationship",
        relationship_building = {title = "建立关系", english_name = "Relationship Building", enabled = true},
        communication = {title = "沟通交流", english_name = "Communication", enabled = true},
        sharing_cooperation = {title = "分享合作", english_name = "Sharing and Cooperation", enabled = true},
        conflict_resolution = {title = "冲突解决", english_name = "Conflict Resolution", enabled = true}
    },
    self_management = {
        sortIndex = 5,
        title = "自我管理",
        english_name = "Self Management",
        self_living = {title = "生活自理", english_name = "Self Living", enabled = true},
        material_management = {title = "物品管理", english_name = "Material Management", enabled = true},
        time_management = {title = "时间管理", english_name = "Time Management", enabled = true},
        self_protection = {title = "自我保护", english_name = "Self Protection", enabled = true}
    },
    motor_coordination = {
        sortIndex = 6,
        title = "运动协调",
        english_name = "Motor Coordination",
        growth_development = {title = "生长发育", english_name = "Growth and Development", enabled = true},
        gross_motor = {title = "粗大运动", english_name = "Gross Motor", enabled = true},
        fine_motor = {title = "精细动作", english_name = "Fine Motor", enabled = true},
        mechanical_control = {title = "器械操控", english_name = "Mechanical Control", enabled = true}
    }
}

-- 统一配置管理
local profileConfigs = {
    teen = teenProfileConfig,
    kids = kidProfileConfig
}

-- 动态生成能力映射表
local allAbilityMap = {
    teen = generateAbilityMap(teenProfileConfig),
    kids = generateAbilityMap(kidProfileConfig)
}
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")

NPL.load("(gl)script/ide/System/Windows/Window.lua");
local Window = commonlib.gettable("System.Windows.Window")
local page
local loadTime = 0
local loadDelay = 300 * 1000
local MiniGameUserProfile = NPL.export()
local storePage = "maisiAI"

local PAGE_ENUM={
    KIDS = "kids",
    TEEN = "teen",
}

MiniGameUserProfile.pageType = PAGE_ENUM.TEEN
MiniGameUserProfile.profileData = nil
local function isemptytable(t) return next(t) == nil end
function MiniGameUserProfile.OnInit()
    page = document:GetPageCtrl();
    if page then
        page.OnCreate = MiniGameUserProfile.OnCreate;
        page.OnClose = MiniGameUserProfile.OnClose;
    end
end

function MiniGameUserProfile.LoadUserData(callback)
    local curTime = ParaGlobal.timeGetTime()
    local loadTimeDistance = curTime - loadTime;
    if MiniGameUserProfile.profileData and not isemptytable(MiniGameUserProfile.profileData) then
        if loadDelay < loadTimeDistance then
            loadTime = curTime
            MiniGameUserProfile.LoadRemoteData(callback)
            return
        end
    end
    MiniGameUserProfile.LoadRemoteData(callback)
end

function MiniGameUserProfile.LoadRemoteData(callback)
    GameLogic.PersonalPageStore:LoadPageData(storePage,nil,function(data)
        MiniGameUserProfile.profileData = {}
        if data and not isemptytable(data) then
            MiniGameUserProfile.profileData = data
        end
        if callback and type(callback) == "function" then
            callback(MiniGameUserProfile.profileData)
        end
    end)
end

function MiniGameUserProfile.UpdateScoreByUserCaps(userCaps)
    if not userCaps then
        return
    end
    local allAbilities = MiniGameUserProfile.GetAllAbilities()
    for k, value in ipairs(allAbilities) do
        for key, item in pairs(userCaps) do
            if value.title == item.quotaName then
                value.score = item.score
                value.level = item.level
                value.levelName = item.levelName
            end
        end
    end
    MiniGameUserProfile.allUserAbilities = allAbilities
    MiniGameUserProfile.UpdateUserData(allAbilities)
end

function MiniGameUserProfile.UpdateUserData(abilities)
    if not abilities then
        return
    end
    local scoreMap = {}
    for k, value in pairs(abilities) do
        scoreMap[value.key] = value.score
    end
    GameLogic.PersonalPageStore:LoadPageData(storePage,nil,function(data)
        MiniGameUserProfile.profileData = {}
        if data and not isemptytable(data) then
            MiniGameUserProfile.profileData = data
        end
        local isNeedUpdate = false
        for key, value in pairs(scoreMap) do
            local profileKeyData = MiniGameUserProfile.profileData[key]
            if not profileKeyData or not profileKeyData.test_score then
                if not profileKeyData then
                    profileKeyData = {}
                    profileKeyData.score = value
                end
                if not profileKeyData.test_score then
                    profileKeyData.test_score = value
                end
                MiniGameUserProfile.profileData[key] = profileKeyData
                isNeedUpdate = true
            end
        end
        print("同步麦斯星球的分数成功==============")
        if isNeedUpdate then
            GameLogic.PersonalPageStore:SaveKeys(storePage,MiniGameUserProfile.profileData)
        end
    end)
end

function MiniGameUserProfile.CreateOrGetRadarWindow()
    if not MiniGameUserProfile.window then
        MiniGameUserProfile.window = Window:new()
    end
    return MiniGameUserProfile.window
end

 local env
if (type(System.os.IsEmscripten) == 'function' and System.os.IsEmscripten()) then
    env = 'asIframeInWebParacraft'
else
    env = 'asWebviewInParacraftClient'
end
local base_url = string.format("https://keepwork.com/public/resource/miniGameProxy.html?projectPath=maisi/maisi/webgames/data&gameName=user_profile&%s=true".."&date="..os.time(),env)

function MiniGameUserProfile.ShowPage()
    MiniGameUserProfile.LoadUserData(function()
        MiniGameMgr:LoadUserInfo(function (data)
            MiniGameUserProfile.UserData = data
            local url = base_url
            local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
            print("url===========",url)
            MiniGamePage.OpenBrowser(url,function()
                
            end)    
        
        end)
    end)
end

function MiniGameUserProfile.IsVip()
    if not MiniGameUserProfile.UserData then
		return false
	end
	return MiniGameUserProfile.UserData.is_vip or MiniGameUserProfile.UserData.is_common_vip
end

function MiniGameUserProfile.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function MiniGameUserProfile.OnScreenSizeChange()
    if page then
        page:Refresh(0.1)
    end
end

function MiniGameUserProfile.OnCreate()
end

function MiniGameUserProfile.OnClose()
end

function MiniGameUserProfile.DestroyRadar()
    local wnd = MiniGameUserProfile.CreateOrGetRadarWindow()
    if wnd then
        wnd:CloseWindow();
        MiniGameUserProfile.window = nil
    end
end

-- 绘制雷达图函数
function MiniGameUserProfile.DrawRadarChart()
    local radarContainer = ParaUI.GetUIObject("profile_radar_container")
    if not radarContainer:IsValid() then
        LOG.std(nil,"info","MiniGameUserProfile","Radar container not found")
        return
    end
    local wnd = MiniGameUserProfile.CreateOrGetRadarWindow()
    if not wnd then
        LOG.std(nil,"info","MiniGameUserProfile","load window failed")
        return
    end
    local minScore = 60
    local maxScore = 90
    local rx,ry, rw, rh = radarContainer:GetAbsPosition();
    wnd:Show("ProfileRadar", radarContainer, "lt",0 ,0 ,rw ,rh, 1);

    local ctx = wnd:getContext();
    
    local centerX = ctx:getWidth() / 2
    local centerY = ctx:getHeight() / 2
    local maxRadius = math.min(centerX, centerY) - 40

    -- 雷达图数据 (0-100的值)
    local radarData = {}
    local labels = {}
    for k, v in pairs(MiniGameUserProfile.radarData) do
        table.insert(radarData, v.score)
        table.insert(labels, v.chinese_name)
    end

    local sides = #radarData

    ctx:clearRect(0, 0, ctx:getWidth(), ctx:getHeight())
    
    -- 设置背景
    -- ctx.fillStyle = "#f0f0f0"
    -- ctx:fillRect(0, 0, ctx:getWidth(), ctx:getHeight())
    
    -- 绘制网格线 (5层)
    ctx.strokeStyle = "#cccccc"
    ctx.lineWidth = 1
    for i = 1, 5 do
        local radius = (maxRadius / 5) * i
        ctx:beginPath()
        for j = 0, sides - 1 do
            local angle = (j * 2 * math.pi / sides) - math.pi / 2
            local x = centerX + radius * math.cos(angle)
            local y = centerY + radius * math.sin(angle)
            if j == 0 then
                ctx:moveTo(x, y)
            else
                ctx:lineTo(x, y)
            end
        end
        ctx:closePath()
        ctx:stroke()
    end
    
    -- 绘制基准线 (黄色60，绿色90)
    -- 黄色基准线 (60)
    ctx.strokeStyle = "#ffcc00"
    ctx.lineWidth = 2
    local yellowRadius = maxRadius * (minScore / 100)
    local yellowPoints = {}
    ctx:beginPath()
    for j = 0, sides - 1 do
        local angle = (j * 2 * math.pi / sides) - math.pi / 2
        local x = centerX + yellowRadius * math.cos(angle)
        local y = centerY + yellowRadius * math.sin(angle)
        yellowPoints[j + 1] = {x = x, y = y}
        if j == 0 then
            ctx:moveTo(x, y)
        else
            ctx:lineTo(x, y)
        end
    end
    ctx:closePath()
    ctx:stroke()
    
    -- 绘制黄色基准点 (空心)
    ctx.strokeStyle = "#ffcc00"
    ctx.fillStyle = "#ffffff"
    ctx.lineWidth = 2
    for i = 1, #yellowPoints do
        ctx:beginPath()
        ctx:arc(yellowPoints[i].x, yellowPoints[i].y, 3, 0, 2 * math.pi)
        ctx:fill()
        ctx:stroke()
    end
    
    -- 绿色基准线 (90)
    ctx.strokeStyle = "#00cc00"
    ctx.lineWidth = 2
    local greenRadius = maxRadius * (maxScore / 100)
    local greenPoints = {}
    ctx:beginPath()
    for j = 0, sides - 1 do
        local angle = (j * 2 * math.pi / sides) - math.pi / 2
        local x = centerX + greenRadius * math.cos(angle)
        local y = centerY + greenRadius * math.sin(angle)
        greenPoints[j + 1] = {x = x, y = y}
        if j == 0 then
            ctx:moveTo(x, y)
        else
            ctx:lineTo(x, y)
        end
    end
    ctx:closePath()
    ctx:stroke()
    
    -- 绘制绿色基准点 (空心)
    ctx.strokeStyle = "#00cc00"
    ctx.fillStyle = "#ffffff"
    ctx.lineWidth = 2
    for i = 1, #greenPoints do
        ctx:beginPath()
        ctx:arc(greenPoints[i].x, greenPoints[i].y, 3, 0, 2 * math.pi)
        ctx:fill()
        ctx:stroke()
    end
    
    -- 绘制坐标轴
    ctx.strokeStyle = "#999999"
    ctx.lineWidth = 1
    for i = 0, sides - 1 do
        local angle = (i * 2 * math.pi / sides) - math.pi / 2
        local x = centerX + maxRadius * math.cos(angle)
        local y = centerY + maxRadius * math.sin(angle)
        ctx:beginPath()
        ctx:moveTo(centerX, centerY)
        ctx:lineTo(x, y)
        ctx:stroke()
        
        -- 绘制标签
        ctx.fillStyle = "#333333"
        ctx.font = "System;12;"
        -- 增加标签偏移距离，让文字显示在圆圈外面
        local labelOffset = maxRadius + 20
        local labelX = math.floor(centerX + labelOffset * math.cos(angle))
        local labelY = math.floor(centerY + labelOffset * math.sin(angle))
        
        -- 根据角度调整文字对齐方式，避免文字重叠
        local text = labels[i + 1]
        if angle >= -math.pi/4 and angle <= math.pi/4 then
            -- 右侧，左对齐
            labelX = labelX  - 20
        elseif angle >= 3*math.pi/4 or angle <= -3*math.pi/4 then
            -- 左侧，右对齐，需要计算文字宽度
            local textWidth = ParaMisc.GetUnicodeCharNum(text) * 6 -- 估算文字宽度
            labelX = labelX - textWidth
        else
            -- 上下方，居中对齐
            local textWidth = ParaMisc.GetUnicodeCharNum(text) * 6 -- 估算文字宽度
            labelX = labelX - textWidth / 2 - 10
        end
        
        -- 垂直方向微调
        if angle >= math.pi/2 - math.pi/6 and angle <= math.pi/2 + math.pi/6 then
            -- 底部
            labelY = labelY - 10
        elseif angle >= -math.pi/2 - math.pi/6 and angle <= -math.pi/2 + math.pi/6 then
            -- 顶部
            labelY = labelY - 5
        end
        
        ctx:fillText(text, labelX, labelY)
    end 
   
    -- 绘制数据多边形
    ctx.strokeStyle = "#0000ff"
    ctx.fillStyle = "#0000ff40"
    ctx.lineWidth = 2
    ctx:beginPath()
    local dataPoints = {}
    for i = 0, sides - 1 do
        local angle = (i * 2 * math.pi / sides) - math.pi / 2
        local value = radarData[i + 1] / 100
        local x = centerX + maxRadius * value * math.cos(angle)
        local y = centerY + maxRadius * value * math.sin(angle)
        dataPoints[i + 1] = {x = x, y = y}
        if i == 0 then
            ctx:moveTo(x, y)
        else
            ctx:lineTo(x, y)
        end
    end
    ctx:closePath()
    ctx.fillStyle = "#0000ff40"
    ctx:fill()
    ctx:stroke()
    
    -- 绘制数据点 (空心)
    ctx.strokeStyle = "#0000ff"
    ctx.fillStyle = "#ffffff"
    ctx.lineWidth = 2
    for i = 1, #dataPoints do
        ctx:beginPath()
        ctx:arc(dataPoints[i].x, dataPoints[i].y, 4, 0, 2 * math.pi)
        ctx:fill()
        ctx:stroke()
    end
end

-- 5 - 7 周岁 儿童
function MiniGameUserProfile.OnInitKids()
    MiniGameUserProfile.HandleSheetData()
end

function MiniGameUserProfile.HandleSheetData() --表格数据
    local allSheet = {}
    local pageType = (MiniGameUserProfile.pageType and MiniGameUserProfile.pageType ~= "") and MiniGameUserProfile.pageType or PAGE_ENUM.TEEN
    local config = profileConfigs[pageType]
    
    for k, v in pairs(config) do
        local temp = {}
        local data = {
            chinese_name = v.title,
            score = MiniGameUserProfile.GetScore(k),
        }
        temp[#temp + 1] = data
        
        -- 递归遍历子能力项
        local function addChildAbilities(parentData)
            for childKey, childValue in pairs(parentData) do
                if type(childValue) == "table" and childValue.enabled then
                    local data2 = {
                        chinese_name = childValue.title,
                        score = MiniGameUserProfile.GetScore(childKey),
                    }
                    temp[#temp + 1] = data2
                end
            end
        end
        
        addChildAbilities(v)
        temp.sortIndex = v.sortIndex or 0
        table.insert(allSheet, temp)
    end
    
    table.sort(allSheet, function(a, b)
        return a.sortIndex < b.sortIndex
    end)
    MiniGameUserProfile.sheetData = allSheet
end

function MiniGameUserProfile.GetDataSheetStyle(index)
    local sheetData = MiniGameUserProfile.sheetData[index]
    local colNum = #sheetData - 1
    local colWidth = math.floor(((860 - 150) / colNum))
    local baseStyle = [[<pe:repeat DataSource='<%=GetSheetData(]]..index..[[)%>'>]]..[[
    <pe:repeatitem style='float: left;'>
        <pe:if condition='<%=Eval("index") == 1 %>'>
            <div style='float: left;width: 150px;height: 100px;'>
                <div style="float: left;width: 150px; height: 51px; background-color: #0000ff00;">
                    <div style="text-align: center; margin-top: 12px; font-size: 18px; base-font-size: 18px; font-weight: bold; color: #82c8f6; shadow-quality:8;shadow-color:#00000088;text-shadow:true; "><%=Eval("chinese_name")%></div>
                </div>
                <div style="float: left;width: 150px; height: 50px; margin-top:2px;">
                    <div style="text-align: center; margin-top: 12px; font-size: 18px; base-font-size: 18px; font-weight: bold;"><%=Eval("score")%></div>
                </div>
            </div>
        </pe:if>]]..[[
        <pe:if condition='<%=Eval("index") > 1 %>'>]]..string.format([[
                <div style='float: left;width: %dpx;height: 100px;'>
                <div style="float: left;width: %dpx; height: 50px;">]],colWidth,colWidth)..[[
                    <div style="text-align: center; margin-top: 12px; font-size: 18px; base-font-size: 18px; font-weight: bold;"><%=Eval("chinese_name")%></div>
                </div>
                ]]..string.format([[<div style="float: left;width: %dpx; height: 50px; margin-top:2px;">]],colWidth)..[[
                    <div style="text-align: center; margin-top: 12px; font-size: 18px; base-font-size: 18px; font-weight: bold;"><%=Eval("score")%></div>
                </div>
            </div>
        </pe:if>
    </pe:repeatitem>
</pe:repeat>
]]
    
    return baseStyle
end


function MiniGameUserProfile.HandleRadarData()
    local radarData = {}
    local pageType = (MiniGameUserProfile.pageType and MiniGameUserProfile.pageType ~= "") and MiniGameUserProfile.pageType or PAGE_ENUM.TEEN
    local config = profileConfigs[pageType]
    
    for k, v in pairs(config) do
        table.insert(radarData, {
            chinese_name = v.title,
            score = MiniGameUserProfile.GetScore(k, true)
        })
    end
    MiniGameUserProfile.radarData = radarData
end


function MiniGameUserProfile.GetAllAbilities()
    if not MiniGameUserProfile.allUserAbilities then
        MiniGameUserProfile.allUserAbilities = {}
        local pageType = (MiniGameUserProfile.pageType and MiniGameUserProfile.pageType ~= "") and MiniGameUserProfile.pageType or PAGE_ENUM.TEEN
        local allAbilities = allAbilityMap[pageType]
        if not allAbilities then
            return MiniGameUserProfile.allUserAbilities
        end
        MiniGameUserProfile.profileData = MiniGameUserProfile.profileData or {}
        for k, v in pairs(allAbilities) do
            if type(v) == "table" then
                for k2, v2 in pairs(v) do
                    if MiniGameUserProfile.profileData[k2] then
                        table.insert(MiniGameUserProfile.allUserAbilities,{key=k2,score=MiniGameUserProfile.profileData[k2].score, title= MiniGameUserProfile.GetTitle(k2)})
                    else
                        table.insert(MiniGameUserProfile.allUserAbilities,{key=k2,score=0, title= MiniGameUserProfile.GetTitle(k2)})
                    end
                end
            end
        end
    end
    return MiniGameUserProfile.allUserAbilities 
end

-- 8-16 青少年
function MiniGameUserProfile.OnInitTeenagers()
    MiniGameUserProfile.profileTeenConfig = profileConfigs.teen
end

-- 获取当前页面类型的配置
function MiniGameUserProfile.GetCurrentConfig()
    local pageType = (MiniGameUserProfile.pageType and MiniGameUserProfile.pageType ~= "") and MiniGameUserProfile.pageType or PAGE_ENUM.TEEN
    return profileConfigs[pageType]
end

-- 标题缓存映射表
local titleCache = {}

-- 构建标题映射表
local function buildTitleCache(pageType)
    if titleCache[pageType] then
        return titleCache[pageType]
    end
    
    local cache = {}
    local config = profileConfigs[pageType]
    
    if not config then
        titleCache[pageType] = cache
        return cache
    end
    
    -- 递归遍历配置，构建key到title的映射
    local function traverseConfig(data, prefix)
        for key, value in pairs(data) do
            if type(value) == "table" then
                if value.title then
                    cache[key] = value.title
                end
                -- 递归遍历子项（排除特殊字段）
                if key ~= "title" and key ~= "english_name" and key ~= "sortIndex" and key ~= "enabled" then
                    traverseConfig(value, prefix and (prefix .. "." .. key) or key)
                end
            end
        end
    end
    
    traverseConfig(config)
    titleCache[pageType] = cache
    return cache
end

-- 清除标题缓存（当配置发生变化时调用）
function MiniGameUserProfile.ClearTitleCache()
    titleCache = {}
end

-- 获取配置项的标题
function MiniGameUserProfile.GetTitle(key)
    local pageType = (MiniGameUserProfile.pageType and MiniGameUserProfile.pageType ~= "") and MiniGameUserProfile.pageType or PAGE_ENUM.TEEN
    local cache = buildTitleCache(pageType)
    
    -- 从缓存中获取标题
    if cache[key] then
        return cache[key]
    end
    
    -- 如果缓存中没有，返回key本身
    return key
end

-- 通用
function MiniGameUserProfile.GetAbilityScore(key)
    local pageType = (MiniGameUserProfile.pageType and MiniGameUserProfile.pageType ~= "") and MiniGameUserProfile.pageType or PAGE_ENUM.TEEN
    local allAbilities = allAbilityMap[pageType]
    local ability = allAbilities[key]
    if not ability then
        return 0
    end
    local score = 0
    local num = 0
    for k, v in pairs(ability) do
        local data = MiniGameUserProfile.profileData[k]
        if data and data.score then
            num = num + 1
            score = score + data.score
        end
    end
    if num == 0 then
        return 0
    end
    local ability_score = math.ceil(score / num)
    if ability_score >= 100 then
        ability_score = 100
    end
    return ability_score
end

function MiniGameUserProfile.IsCategoryKey(key)
    local pageType = (MiniGameUserProfile.pageType and MiniGameUserProfile.pageType ~= "") and MiniGameUserProfile.pageType or PAGE_ENUM.TEEN
    local allAbilities = allAbilityMap[pageType]
    local ability = allAbilities[key]
    if not ability then
        return false
    end
    if type(ability) == "table" then
        return true
    end
    return false
end

function MiniGameUserProfile.GetScore(key,bReturnNumber) --由于只记录末尾 key
    if not MiniGameUserProfile.profileData then
        return bReturnNumber and 0 or "-"
    end
    if MiniGameUserProfile.IsCategoryKey(key) then
        local score = MiniGameUserProfile.GetAbilityScore(key)
        if score <= 0 then
            return bReturnNumber and 0 or "-"
        end
        return bReturnNumber and score or tostring(score)
    end
    local data = MiniGameUserProfile.profileData[key]
    if data and data.score then
        if data.score and data.score > 100 then
            data.score = 100
        end
        return bReturnNumber and data.score or tostring(data.score)
    end
    return bReturnNumber and 0 or "-"
end

function MiniGameUserProfile.GetTestScore(key,bReturnNumber) --由于只记录末尾 key
    if not MiniGameUserProfile.profileData then
        return bReturnNumber and 0 or "-"
    end
    local data = MiniGameUserProfile.profileData[key]
    if data and data.test_score then
        if data.test_score and data.test_score > 100 then
            data.test_score = 100
        end
        return bReturnNumber and data.test_score or tostring(data.test_score)
    end
    return bReturnNumber and 0 or "-"
end

function MiniGameUserProfile.SetPageType(type)
    MiniGameUserProfile.pageType = type
end

function MiniGameUserProfile.GetIframeUrl()
    if MiniGameUserProfile.pageType == PAGE_ENUM.TEEN then
        return "script/apps/Aries/Creator/Game/Tasks/MiniGame/UserProfileTeen.html"
    elseif MiniGameUserProfile.pageType == PAGE_ENUM.KIDS then
        return "script/apps/Aries/Creator/Game/Tasks/MiniGame/UserProfileKids.html"
    else
        return "script/apps/Aries/Creator/Game/Tasks/MiniGame/UserProfileTeen.html"
    end
end

-- 获取推荐能力
function MiniGameUserProfile.GetRecommendedAbilities()
    -- 收集所有子能力数据
    local allAbilities = MiniGameUserProfile.GetAllAbilities()
    -- 没有训练的能力数量
    local untrainedAbilities = {}
    local hasScores = false
    -- 检查是否所有能力都没有分数
    for _, ability in ipairs(allAbilities) do
        if ability.score and ability.score > 0 then
            hasScores = true
        else
            ability.score = 0
            table.insert(untrainedAbilities,ability)
        end
    end
    
    local recommendedAbilities = {}
    
    if not hasScores then
        -- 如果所有能力都没有分数，随机选择3个
        local shuffled = {}
        for i, ability in ipairs(allAbilities) do
            shuffled[i] = ability
        end
        
        -- 简单的随机打乱算法
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end
        
        for i = 1, math.min(3, #shuffled) do
            table.insert(recommendedAbilities, shuffled[i])
        end
        
        LOG.std(nil, "info", "MiniGameUserProfile", "GetRecommendedAbilities: 所有能力都没有分数，随机推荐3个能力")
    else
        -- 按分数排序
        table.sort(allAbilities, function(a, b)
            return a.score > b.score
        end)
        
        -- 选择2个高分能力（前面的）
        local highScoreCount = 0
        for i = 1, #allAbilities do
            if allAbilities[i].score > 0 and highScoreCount < 2 then
                table.insert(recommendedAbilities, allAbilities[i])
                highScoreCount = highScoreCount + 1
            end
        end
        
        -- 选择1个低分能力（后面的，但分数大于0）
        for i = #allAbilities, 1, -1 do
            if  allAbilities[i].score > 0 and #recommendedAbilities < 3 then
                -- 确保不重复选择
                local alreadySelected = false
                for _, selected in ipairs(recommendedAbilities) do
                    if selected.key == allAbilities[i].key then
                        alreadySelected = true
                        break
                    end
                end
                
                if not alreadySelected then
                    table.insert(recommendedAbilities, allAbilities[i])
                    break
                end
            end
        end
        
        -- 如果还不够3个，从剩余的有分数的能力中补充
        if #recommendedAbilities < 3 then
            for i = 1, #allAbilities do
                if allAbilities[i].score > 0 and #recommendedAbilities < 3 then
                    local alreadySelected = false
                    for _, selected in ipairs(recommendedAbilities) do
                        if selected.key == allAbilities[i].key then
                            alreadySelected = true
                            break
                        end
                    end
                    
                    if not alreadySelected then
                        table.insert(recommendedAbilities, allAbilities[i])
                    end
                end
            end
        end
        
        LOG.std(nil, "info", "MiniGameUserProfile", "GetRecommendedAbilities: 根据分数推荐能力训练")
    end
    return recommendedAbilities,untrainedAbilities
end

function MiniGameUserProfile.GenarateProfileByAbility(ability)
    if not ability then
        return nil
    end
    return {
        score = MiniGameUserProfile.GetScore(ability,true),
        test_score = MiniGameUserProfile.GetTestScore(ability,true),
    }
end

-- ========== HTML页面通信功能 ==========

-- 处理来自HTML页面的消息
function MiniGameUserProfile.HandlePageMessage(msg)
    if not msg then
        return
    end
    if msg.type == "requestProfileData" then
        MiniGameUserProfile.SendProfileData()
    elseif msg.type == "updateProfile" then
        MiniGameUserProfile.UpdateProfile(msg)
    end
end

-- 更新个人资料
function MiniGameUserProfile.UpdateProfile(msg)
    if not msg then
        return
    end
    local data = msg.data
    if data.nickname and data.nickname ~= "" then
        local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
        KeepWorkItemManager.LoadItems(nil, function()
			GameLogic.GetFilters():apply_filters("ggs", {action = "UpdateNickName", nickname = data.nickname});
			GameLogic.GetFilters():apply_filters("ggs", {action = "UpdateUserInfo", userinfo = {nickname = data.nickname}});
		end)
    end
end

-- 发送个人资料数据
function MiniGameUserProfile.SendProfileData()    
    -- 确保青少年配置已初始化
    MiniGameUserProfile.OnInitTeenagers()
    local profileData = {
        focusedAttention = MiniGameUserProfile.GenarateProfileByAbility("focusedAttention"),
        selectiveAttention = MiniGameUserProfile.GenarateProfileByAbility("selectiveAttention"),
        shiftingAttention = MiniGameUserProfile.GenarateProfileByAbility("shiftingAttention"),
        distributedAttention = MiniGameUserProfile.GenarateProfileByAbility("distributedAttention"),
        visualMemory = MiniGameUserProfile.GenarateProfileByAbility("visualMemory"),
        auditoryMemory = MiniGameUserProfile.GenarateProfileByAbility("auditoryMemory"),
        workingMemory = MiniGameUserProfile.GenarateProfileByAbility("workingMemory"),
        deductiveReasoning = MiniGameUserProfile.GenarateProfileByAbility("deductiveReasoning"),
        inductiveReasoning = MiniGameUserProfile.GenarateProfileByAbility("inductiveReasoning"),
        analogicalReasoning = MiniGameUserProfile.GenarateProfileByAbility("analogicalReasoning"),
        verbalComprehension = MiniGameUserProfile.GenarateProfileByAbility("verbalComprehension"),
        abstractReasoning = MiniGameUserProfile.GenarateProfileByAbility("abstractReasoning"),
        visualSpatialIntelligence = MiniGameUserProfile.GenarateProfileByAbility("visualSpatialIntelligence"),
        elaborationStrategy = MiniGameUserProfile.GenarateProfileByAbility("elaborationStrategy"),
        detailedProcessingStrategy = MiniGameUserProfile.GenarateProfileByAbility("detailedProcessingStrategy"),
        organizationalStrategy = MiniGameUserProfile.GenarateProfileByAbility("organizationalStrategy"),
        metacognitivePlanning = MiniGameUserProfile.GenarateProfileByAbility("metacognitivePlanning"),
        metacognitiveMonitoring = MiniGameUserProfile.GenarateProfileByAbility("metacognitiveMonitoring"),
        metacognitiveRegulation = MiniGameUserProfile.GenarateProfileByAbility("metacognitiveRegulation"),
        effortManagement = MiniGameUserProfile.GenarateProfileByAbility("effortManagement"),
        timeManagement = MiniGameUserProfile.GenarateProfileByAbility("timeManagement"),
        externalResourceUtilization = MiniGameUserProfile.GenarateProfileByAbility("externalResourceUtilization"),
        growth = MiniGameUserProfile.GenarateProfileByAbility("growth"),
        autonomy = MiniGameUserProfile.GenarateProfileByAbility("autonomy"),
        interaction = MiniGameUserProfile.GenarateProfileByAbility("interaction"),
        interest = MiniGameUserProfile.GenarateProfileByAbility("interest"),
        recognition = MiniGameUserProfile.GenarateProfileByAbility("recognition"),
        competition = MiniGameUserProfile.GenarateProfileByAbility("competition"),
        materialReward = MiniGameUserProfile.GenarateProfileByAbility("materialReward"),
        emotionalAwareness = MiniGameUserProfile.GenarateProfileByAbility("emotionalAwareness"),
        emotionalRegulation = MiniGameUserProfile.GenarateProfileByAbility("emotionalRegulation"),
        responsibility = MiniGameUserProfile.GenarateProfileByAbility("responsibility"),
        seriousness = MiniGameUserProfile.GenarateProfileByAbility("seriousness"),
        perseverance = MiniGameUserProfile.GenarateProfileByAbility("perseverance"),
        creativity = MiniGameUserProfile.GenarateProfileByAbility("creativity"),
    };
    
    local userInfo = {
        userName = MiniGameUserProfile.GetAccountStr(),
        nickName = System.Encoding.base64(MiniGameUserProfile.GetNickName()),
        isVip = MiniGameUserProfile.IsVip(),
    }
    local data = {
        profileData=profileData,
        userInfoData=userInfo,
    }

    local msg = {
        type="setGameConfig",
        data = data
    }

    MiniGameUserProfile.SendMsg(msg)
end

function MiniGameUserProfile.SendMsg(msg)
    GameLogic.MiniGameMgr:SendMessage("user_profile",msg)
end

-- 获取昵称（兼容原有逻辑）
function MiniGameUserProfile.GetNickName()
    local nickname = System.User.NickName
    if(nickname == nil or nickname == "")then
        nickname = System.User.username
    end
    if nickname ~= nil and nickname ~= "" then
        local width = 0
        local name = ""
        for uchar in string.gmatch(nickname, '([%z\1-\127\194-\244][\128-\191]*)') do
            local w = _guihelper.GetTextWidth(uchar, "System;32");
            width = width + tonumber(w)
            if width < 240 then
                name = name.. uchar
            else
                name = name.. "..."
                break
            end
        end
        return name
    end
    return ""
end

-- 获取账号信息字符串
function MiniGameUserProfile.GetAccountStr()
    if not System.User.username then
        return ""
    end
    local username = System.User.username or ""
    return  username
end
