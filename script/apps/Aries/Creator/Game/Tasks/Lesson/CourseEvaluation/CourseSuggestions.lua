--[[
    author:{author}
    time:2022-05-10 14:11:31
    use lib:
        local CourseSuggestions = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/CourseEvaluation/CourseSuggestions.lua") 
        CourseSuggestions.ShowView()
]]
local CourseSuggestions = NPL.export()

local page = nil
function CourseSuggestions.OnInit()
    page = document:GetPageCtrl();
end

function CourseSuggestions.ShowView()
    local view_width = 570
    local view_height = 390
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Lesson/CourseEvaluation/CourseSuggestions.html",
        name = "CourseSuggestions.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 4,
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

function CourseSuggestions.GetSuggestText()
    if page then
        local text = page:GetUIValue("suggest") or "";
        text = string.gsub(text,"^[\r\n]+" , "") 
        text = string.gsub(text,"^[%s]+", "")
        text = string.gsub(text,"[%s]+$", "")
        return text
    end
    return ""
end

function CourseSuggestions.OnSubmit()
    local suggestText = CourseSuggestions.GetSuggestText()
    local len = ParaMisc.GetUnicodeCharNum(suggestText);
	if(len > 128) then
		_guihelper.MessageBox(L"你输入的文字太多了，请缩短一点吧");
		return;
	end
    local CourseEvaluation = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/CourseEvaluation/CourseEvaluation.lua") 
    keepwork.courses.doCourseEvaluations({
        courseId = CourseEvaluation.courseId,
        isFinished = CourseEvaluation.IsFinished,
        interestLevel = CourseEvaluation.InterstValue,
        difficultyLevel = CourseEvaluation.DifficultyValue,
        masteryLevel = CourseEvaluation.KnowwellValue,
        feedback = suggestText,
        sectionIndex = CourseEvaluation.courseIndex
    },function (err, msg, data)
        echo(data)
        echo(err)
        if err == 200 then
            GameLogic.AddBBS(nil ,L"提交评价成功")
            CourseSuggestions.CloseCoursePage()
        end
    end)
end

function CourseSuggestions.CloseCoursePage()
    local CourseEvaluation = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Lesson/CourseEvaluation/CourseEvaluation.lua") 
    CourseEvaluation.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

