--[[
    author:pbb
    date:2022-05-10 14:10:30
    Desc:
    use lib:
    local CourseEvaluation = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/CourseEvaluation/CourseEvaluation.lua") 
    CourseEvaluation.ShowView()
]]
local CourseEvaluation = NPL.export()
CourseEvaluation.InterstValue = -1
CourseEvaluation.DifficultyValue = -1
CourseEvaluation.KnowwellValue = -1
CourseEvaluation.courseIndex = 1
CourseEvaluation.courseId = -1
CourseEvaluation.IsFinished = 0
CourseEvaluation.IsSubmitSuggest = false
local page = nil
function CourseEvaluation.OnInit()
    page = document:GetPageCtrl();
end

function CourseEvaluation.ShowView(callback,isFinished)
    if  System.options.channelId_431 or System.options.isPapaAdventure then
        if callback then
            callback()
        end
        return
    end
    CourseEvaluation.RegisterEvent()
    local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
    local courseData = RedSummerCampPPtPage.GetLastCourseData()
    local projectId = courseData and courseData.ppt_to_projectid
    local curPorjectId = GameLogic.options:GetProjectId()
    if not courseData or tonumber(projectId) ~= curPorjectId or not Game.is_started then
        if callback then
            callback()
        end
        return 
    end
    CourseEvaluation.courseId = courseData.id or -1
    CourseEvaluation.courseIndex = courseData.ppt_index or -1
    if CourseEvaluation.courseIndex <= 0 or CourseEvaluation.courseId <= 0 then
        if callback then
            callback()
        end
        return 
    end
    if callback == nil then
        CourseEvaluation.IsFinished = 1
    else
        CourseEvaluation.IsFinished = isFinished~= nil and isFinished or 0
    end
     
    local params = {}
    if CourseEvaluation.IsFinished == 1 then
        params = {isFinished = 1,courseId = CourseEvaluation.courseId,sectionIndex =CourseEvaluation.courseIndex }
    else
        params = {courseId = CourseEvaluation.courseId, sectionIndex = CourseEvaluation.courseIndex}
    end
    keepwork.courses.getCourseEvaluations(params,function(err, msg, data)
        if err == 200 then
            if type(data) == "table" and #data > 0 then
                if callback then
                    callback()
                end
                return 
            end
        end
        CourseEvaluation.ShowPage(callback)
    end)
end

function CourseEvaluation.RegisterEvent()
    if not CourseEvaluation.register then
        GameLogic:Connect("WorldUnloaded", nil, function()
            CourseEvaluation.InterstValue = 10
            CourseEvaluation.DifficultyValue = 10
            CourseEvaluation.KnowwellValue = 10
            CourseEvaluation.courseIndex = 1
            CourseEvaluation.courseId = -1
            CourseEvaluation.IsFinished = 0
        end);
        CourseEvaluation.register = true
    end
end

function CourseEvaluation.ShowPage(callback)
    CourseEvaluation.IsSubmitSuggest = false
    CourseEvaluation.InterstValue = -1
    CourseEvaluation.DifficultyValue = -1
    CourseEvaluation.KnowwellValue = -1
    local view_width = 570
    local view_height = 540
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Lesson/CourseEvaluation/CourseEvaluation.html",
        name = "CourseEvaluation.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 4,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        -- DesignResolutionWidth = 1280,
		-- DesignResolutionHeight = 720,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    params._page.OnClose = function ()
        if callback then
            callback()
        end
    end
end

function CourseEvaluation.OnClickInterst(value)
    CourseEvaluation.InterstValue = value and tonumber(value) or 10
end

function CourseEvaluation.OnClickDifficulty(value)
    CourseEvaluation.DifficultyValue = value and tonumber(value) or 10
end

function CourseEvaluation.OnClicKnowwell(value)
    CourseEvaluation.KnowwellValue = value and tonumber(value) or 10
end

function CourseEvaluation.GetSuggestText()
    if page then
        local text = page:GetUIValue("suggest") or "";
        text = string.gsub(text,"^[\r\n]+" , "") 
        text = string.gsub(text,"^[%s]+", "")
        text = string.gsub(text,"[%s]+$", "")
        return text
    end
    return ""
end

function CourseEvaluation.OnClickSubmit()
    local suggestText = CourseEvaluation.GetSuggestText()
    local len = ParaMisc.GetUnicodeCharNum(suggestText);
	if(len > 150) then
		_guihelper.MessageBox(L"你输入的文字太多了，请缩短一点吧")
		return;
	end
    if CourseEvaluation.InterstValue <= 0 or CourseEvaluation.DifficultyValue <= 0 or CourseEvaluation.KnowwellValue <= 0 then
        _guihelper.MessageBox(L"请选择你的选项")
        return
    end

    keepwork.courses.doCourseEvaluations({
        courseId = CourseEvaluation.courseId,
        isFinished = CourseEvaluation.IsFinished,
        interestLevel = CourseEvaluation.InterstValue,
        difficultyLevel = CourseEvaluation.DifficultyValue,
        masteryLevel = CourseEvaluation.KnowwellValue,
        feedback = suggestText,
        sectionIndex = CourseEvaluation.courseIndex
    },function (err, msg, data)
        if err == 200 then
            GameLogic.AddBBS(nil ,L"提交评价成功")
            CourseEvaluation.ClosePage()
        end
    end)
end

function CourseEvaluation.OnClickSuggestion()
    -- local CourseSuggestions = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/CourseEvaluation/CourseSuggestions.lua") 
    -- CourseSuggestions.ShowView()
    if not CourseEvaluation.IsSubmitSuggest then
        CourseEvaluation.IsSubmitSuggest = true
        if page then
            page:Refresh(0)
            CourseEvaluation.SetUIValue()
        end
    end
end

function CourseEvaluation.SetUIValue()
    if CourseEvaluation.KnowwellValue > 0 then
        page:SetValue("knowwell", tostring(CourseEvaluation.KnowwellValue))
    end

    if CourseEvaluation.InterstValue > 0 then
        page:SetValue("interst", tostring(CourseEvaluation.InterstValue))
    end

    if CourseEvaluation.DifficultyValue > 0 then
        page:SetValue("difficulty", tostring(CourseEvaluation.DifficultyValue))
    end
end

function CourseEvaluation.SetKnowwell()
    if CourseEvaluation.KnowwellValue > 0 then
        page:SetValue("knowwell", tostring(CourseEvaluation.KnowwellValue))
    end
end

function CourseEvaluation.SetInterst()
    if CourseEvaluation.InterstValue > 0 then
        page:SetValue("interst", tostring(CourseEvaluation.InterstValue))
    end
end

function CourseEvaluation.SetDifficulty()
    if CourseEvaluation.DifficultyValue > 0 then
        page:SetValue("difficulty", tostring(CourseEvaluation.DifficultyValue))
    end
end

function CourseEvaluation.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end